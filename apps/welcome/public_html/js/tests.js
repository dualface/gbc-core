
var State = {
    IDLE: 0,
    SIGNIN: 1,
    CONNECTING: 2,
    CONNECTED: 3
};

var tests = {
    opts: {
        server_addr: null,
        http_entry: "welcome_api",
        http_server_addr: null,
        websocket_entry: "welcome_socket",
        websocket_server_addr: null
    },

    status: {
        state: State.IDLE,

        username: null,
        session_id: null,
        connect_tag: null,

        socket: null,
        msg_id: 0,
        callbacks: {}
    },

    events: {
        allusers: function(data) {
            var users = data["users"];
            if (users) {
                var online_users_select = $("#online_users_select");
                online_users_select.empty();
                for (var i = 0; i < users.length; ++i) {
                    var user = users[i];
                    var username = $("<div/>").text(user.username).html();
                    online_users_select.append($("<option></option>").val(user.tag).text(user.username));
                }
                online_users_select.prop("selectedIndex", -1);
            }
        },

        adduser: function(data) {
            var online_users_select = $("#online_users_select");
            online_users_select.append($("<option></option>").val(data.tag).text(data.username));
        },

        removeuser: function(data) {
            var online_users_select_options = $("#online_users_select > option");
            online_users_select_options.each(function() {
                if ($(this).text() == data.username) {
                    $(this).remove();
                    // tests.on_destuserchanged();
                    return;
                }
            });
        }
    },

    prepare: function() {
        var self = this;
        $("#server_addr_input").val(document.location.host);

        $("#sign_button").click(function() {
            if (self.status.state == State.IDLE) {
                self.signin();
            } else {
                self.signout();
            }
            return false;
        });

        $("#add_counter_button").click(function() {
            self.add_counter();
            return false;
        });

        $("#online_users_select").change(function() {
            if (this.selectedIndex >= 0) {
                $("#dest_connect_tag_input").val(this.options[this.selectedIndex].value);
            } else {
                $("#dest_connect_tag_input").val("");
            }
        });
        $("#send_message_button").click(function() {
            var tag = $("#dest_connect_tag_input").val();
            var message = $("#message_input").val();
            if (tag == "") {
                self.show_error("Please enter Connect Tag, or choose user from Online Users list.");
                return;
            }
            if (message == "") {
                self.show_error("Please enter message.");
                return;
            }

            self.send_message(tag, message);
        });

        $("#clear_logs_button").click(function() {
            log.clear();
            return false;
        });
        $("#insert_mark_button").click(function() {
            log.add_mark();
            return false;
        })

        self.update_ui();
    },

    update_ui: function() {
        var self = this;

        var state = self.status.state;
        $("#server_addr_input").prop("disabled", state != State.IDLE);
        $("#username_input").prop("disabled", state != State.IDLE);

        if (state != State.CONNECTING && state != State.CONNECTED) {
            $("#session_id_input").val("");
            $("#connect_tag_input").val("");
            $("#counter_value_input").val("");
            $("#online_users_select").empty();
            $("#dest_connect_tag_input").val("");
        }

        $("#add_counter_button").prop("disabled", state != State.CONNECTED);
        $("#online_users_select").prop("disabled", state != State.CONNECTED);
        $("#dest_connect_tag_input").prop("disabled", state != State.CONNECTED);
        $("#message_input").prop("disabled", state != State.CONNECTED);
        $("#send_message_button").prop("disabled", state != State.CONNECTED);

        if (state == State.IDLE) {
            $("#sign_button").text("Sign In").prop("disabled", false);
        } else if (state == State.SIGNIN || state == State.CONNECTING) {
            $("#sign_button").text("Connecting").prop("disabled", true);
        } else if (state == State.CONNECTED) {
            $("#sign_button").text("Sign Out").prop("disabled", false);
        } else {
            $("#sign_button").text("-").prop("disabled", true);
        }
    },

    cleanup: function() {
        var self = this;
        var opts = self.opts;
        opts.http_server_addr = null;
        opts.websocket_server_addr = null;

        var status = self.status;
        status.state = State.IDLE;
        status.username = null;
        status.session_id = null;
        status.connect_tag = null;
        status.socket = null;
        status.msg_id = 0;
        status.callbacks = {};
    },

    signin: function() {
        var self = this;
        if (self.status.state != State.IDLE) {
            return;
        }

        var username = $("#username_input").val();
        if (username === "") {
            self.show_error("PLEASE ENTER username");
            return;
        }

        var opts = self.opts;
        opts.server_addr = $("#server_addr_input").val();
        opts.http_server_addr = "http://" + opts.server_addr + "/" + opts.http_entry
        opts.websocket_server_addr = "ws://" + opts.server_addr + "/" + opts.websocket_entry

        var status = self.status;
        status.state = State.SIGNIN;
        status.username = username;

        self.update_ui();

        var data = {"username": username}
        log.add_mark();
        log.add("SIGN IN");
        self.http_request("user.login", data, function(res) {
            if (!self.validate_result(res, ["sid", "tag", "count"])) {
                status.state = State.IDLE;
            } else {
                status.state = State.CONNECTING;
                status.session_id = res["sid"].toString();
                status.connect_tag = res["tag"].toString();
                log.add("GET SESSION ID: " + status.session_id);

                var count = parseInt(res["count"]);
                log.add("count = " + count.toString());
                $("#session_id_input").val(status.session_id);
                $("#connect_tag_input").val(status.connect_tag);
                $("#counter_value_input").val(count);

                self.connect_websocket();
            }

            self.update_ui();
        }, function() {
            status.state = State.IDLE;
            self.update_ui();
        });
    },

    signout: function() {
        var self = this;
        var status = self.status;
        if (status.session_id === null) {
            log.add("ALREADY SIGN OUT");
            return;
        }

        log.add_mark();
        log.add("SIGN OUT");

        self.http_request("user.logout", {"sid": status.session_id}, function(res) {
            if (status.socket) {
                // will call cleanup() and update_ui()
                status.socket.close();
            } else {
                self.cleanup();
                self.update_ui();
            }
        });
    },

    add_counter: function() {
        var self = this;
        var status = self.status;

        if (status.session_id === null) {
            log.add("SIGN IN FIRST");
            return;
        }

        self.http_request("user.count", {"sid": status.session_id}, function(res) {
            if (!self.validate_result(res, ["count"])) return;

            var count = parseInt(res["count"]);
            log.add("count = " + count.toString());
            $("#counter_value_input").val(count.toString());
        });
    },

    send_message: function(tag, message) {
        var self = this;

        tag = tag.toString();
        message = message.toString();

        var data = {
            "action": "chat.sendmessage",
            "tag": tag,
            "message": message
        };
        self.send_data(data);
    },

    show_error: function(message) {
        var modal = UIkit.modal("#alert_dialog");
        modal.show();
        $("#error_alert").text(message);
    },

    validate_result: function(res, fields) {
        var err = res["err"];
        if (typeof err !== "undefined") {
            return false;
        }

        for (var i = 0; i < fields.length; i++) {
            var field = fields[i];
            var v = res[field];
            if (typeof v === "undefined") {
                return false;
            }
        }
        return true;
    },

    http_request: function(action, data, callback, fail) {
        var self = this;
        var opts = self.opts;
        var url = opts.http_server_addr + "?action=" + action;
        log.add("HTTP: " + url);
        $.post(url, data, function(res) {
            if (res.err) {
                var err = "ERR: " + res.err;
                self.show_error(err);
                log.add(err);
            }
            callback(res);
        }, "json")
            .fail(function() {
                log.add("HTTP: " + url + " FAILED");
                if (fail) {
                    fail();
                }
            });
    },

    connect_websocket: function() {
        var self = this;
        var opts = self.opts;
        var status = self.status;

        if (status.socket !== null) {
            log.add("ALREADY CONNECTED");
            return;
        }

        if (status.session_id === null) {
            log.add("SIGN IN FIRST");
            return;
        }

        var protocol = "quickserver-" + status.session_id;
        log.add("CONNECT WEBSOCKET with PROTOCOL: " + protocol.toString());

        var socket = new WebSocket(opts.websocket_server_addr, protocol);
        socket.onopen = function() {
            log.add("WEBSOCKET CONNECTED");
            status.state = State.CONNECTED;
            self.update_ui();
        };
        socket.onerror = function(error) {
            if (!(error instanceof Event)) {
                log.add("ERR: " + error.toString());
            }
        };
        socket.onmessage = function(event) {
            log.add("WEBSOCKET RECV: " + event.data.toString());
            var data = JSON.parse(event.data);
            if (data["__id"]) {
                var msgid = data["__id"].toString();
                if (typeof status.callbacks[msgid] !== "undefined") {
                    var callback = status.callbacks[msgid];
                    status.callbacks[msgid] = null;
                    callback(data);
                }
            } else if (data["name"]) {
                var events = self.events;
                var name = data["name"].toString();
                if (isfunction(events[name])) {
                    events[name](data);
                }
            }
        };
        socket.onclose = function() {
            log.add("WEBSOCKET DISCONNECTED");
            self.cleanup();
            self.update_ui();
        };

        status.socket = socket;
    },

    send_data: function(data, callback) {
        var self = this;
        var status = self.status;

        if (status.socket === null) {
            log.add("NOT CONNECTED");
            return;
        }

        status.msg_id++;
        data["__id"] = status.msg_id;
        var json_str = JSON.stringify(data);

        if (isfunction(callback)) {
            status.callbacks[status.msg_id.toString()] = callback;
        }

        status.socket.send(json_str);
        log.add("WEBSOCKET SEND: " + json_str);
    }
};

// ----

var f2num = function(n, l) {
    if (typeof l == "undefined") l = 2;
    while (n.length < l) {
        n = "0" + n;
    }
    return n;
}

var isfunction = function(functionToCheck) {
    var getType = {};
    return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
}

var log = {
    opts: {
        lasttime: 0
    },

    add: function(message) {
        var self = this;
        var opts = self.opts;

        var log = $("#log");
        var now = new Date();
        var nowtime = now.getTime();
        if (opts.lasttime > 0 && nowtime - opts.lasttime > 10000) { // 10s
            $("#log").prepend("-------------------------\n");
        }
        opts.lasttime = nowtime;

        var time = f2num(now.getHours().toString())
                 + ":" + f2num(now.getMinutes().toString())
                 + ":" + f2num(now.getSeconds().toString());
        message = $("<div/>").text(message).html();
        message = message.replace("\n", "<br />\n");
        log.prepend("[<strong>" + time + "</strong>] " + message + "\n");
        log.scrollTop(log.prop("scrollHeight"));
    },

    add_mark: function() {
        var self = this;
        var log = $("#log");
        log.prepend("<strong>--------<strong>\n");
        log.scrollTop(log.prop("scrollHeight"));
    },

    clear: function() {
        $('#log').empty();
    }
}

// ----

$(document).ready(function() {
    tests.prepare();
});

