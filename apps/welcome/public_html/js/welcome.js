
var dashboard = {
    opts: {
        interval: 10,
        interval_60s_steps: 6,
        update_last60s_busy: false,

        chart_opts: {
            axisX: {
                showLabel: true,
                offset: 20
            },
            axisY: {
                showLabel: true,
                offset: 30,
                scaleMinSpace: 30
            },
            showArea: true,
            height: 200,
            showPoint: false,
            lineSmooth: false,
            low: 0,
            high: 99,
            fullWidth: true
        },

        last60s_data_base: {
            labels: [],
            series: [[]]
        }
    },

    server_data: {
        cpu_cores: null,
        mem_total: null,
        disk_total: null,
        interval: null
    },

    data: {
    },

    charts: {
    },

    init: function() {
        $("#init_alert").show();
        $("#error_alert").hide();

        var self = this;

        $.getJSON(dashboard.admin_url + "&time_span=1s", function(data) {
            self.server_data.cpu_cores = parseInt(data.cpu_cores);
            self.server_data.mem_total = parseInt(data.mem_total);
            self.server_data.disk_total = parseInt(data.disk_total);
            self.server_data.interval = parseInt(data.interval);

            var last60s_cpu_title = $("#last60s_cpu_title");
            last60s_cpu_title.text(last60s_cpu_title.text() + " (" + self.server_data.cpu_cores.toString() + " cores)");

            var last60s_mem_title = $("#last60s_mem_title");
            last60s_mem_title.text(last60s_mem_title.text() + " (" + Math.ceil(self.server_data.mem_total / 1024).toString() + " MB)");

            self.prepare_charts();
            self.update_last60s();
            window.setInterval(function() {
                self.update_last60s();
            }, 1000 * self.server_data.interval);

            $("#chart_last60s_1").show();
            $("#chart_last60s_2").show();
            $("#init_alert").hide();
        })
        .fail(function() {
            $("#init_alert").hide();
            $("#error_alert").show();
        });
    },

    prepare_charts: function() {
        var self = this;

        var interval = self.server_data.interval;
        var interval_60s_steps = Math.ceil(60 / interval);
        var last60s_data_base = self.opts.last60s_data_base;
        for (var i = 0; i < interval_60s_steps; ++i) {
            last60s_data_base.labels[i] = ((i * interval) % 10 == 0) ? (60 - (i * interval)).toString() + "s" : "";
        }

        // last60s_cpu
        var last60s_cpu_data = $.extend(true, {}, last60s_data_base);
        self.data.last60s_cpu_data = last60s_cpu_data;

        var last60s_cpu_opts = $.extend(true, {}, self.opts.chart_opts);
        last60s_cpu_opts.axisY.labelInterpolationFnc = function(value) {
            return value + '%';
        };

        // last60s_mem
        var last60s_mem_data = $.extend(true, {}, last60s_data_base);
        self.data.last60s_mem_data = last60s_mem_data;

        var last60s_mem_opts = $.extend(true, {}, self.opts.chart_opts);
        last60s_mem_opts.high = Math.ceil(self.server_data.mem_total / 1024);
        last60s_mem_opts.axisY.labelInterpolationFnc = function(value) {
            return value + 'M';
        };

        // last60s_connects
        var last60s_connects_data = $.extend(true, {}, last60s_data_base);
        self.data.last60s_connects_data = last60s_connects_data;

        var last60s_connects_opts = $.extend(true, {}, self.opts.chart_opts);
        last60s_connects_opts.high = null;

        // last60s_jobs
        var last60s_jobs_data = $.extend(true, {}, last60s_data_base);
        self.data.last60s_jobs_data = last60s_jobs_data;

        var last60s_jobs_opts = $.extend(true, {}, self.opts.chart_opts);
        last60s_jobs_opts.high = null;

        // create charts
        self.charts.last60s_cpu_chart = new Chartist.Line('#last60s_cpu', last60s_cpu_data, last60s_cpu_opts);
        self.charts.last60s_mem_chart = new Chartist.Line('#last60s_mem', last60s_mem_data, last60s_mem_opts);
        self.charts.last60s_connects_chart = new Chartist.Line('#last60s_connects', last60s_connects_data, last60s_connects_opts);
        self.charts.last60s_jobs_chart = new Chartist.Line('#last60s_jobs', last60s_jobs_data, last60s_jobs_opts);
    },

    update_last60s: function() {
        var self = this;

        if (self.opts.update_last60s_busy) {
            return;
        }

        $.getJSON(dashboard.admin_url + "&time_span=60s", function(data) {
            // CPU
            var cores = self.server_data.cpu_cores;
            var interval = self.server_data.interval;
            var interval_60s_steps = Math.ceil(60 / interval);

            var last60s_cpu_data = self.data.last60s_cpu_data;
            var last60s_mem_data = self.data.last60s_mem_data;
            var last60s_connects_data = self.data.last60s_connects_data;
            var last60s_jobs_data = self.data.last60s_jobs_data;

            var loads = {nginx: [], redis: [], beanstalkd: []};
            var mems = {nginx: 0, redis: 0};
            var connects = {nginx: [], redis: []};
            var jobs = {beanstalkd: []};

            var redis_data = data["REDIS_SERVER"];
            var beanstalkd_data = data["BEANSTALKD"];
            for (var index = 0; index < interval_60s_steps; ++index) {
                var nginx_data = self.calc_ngx_data_at_index(data, "last_60s", index);
                if (nginx_data === false) {
                    break;
                }
                loads.nginx[index] = nginx_data.load;
                loads.redis[index] = parseFloat(redis_data.cpu.last_60s[index]);
                loads.beanstalkd[index] = parseFloat(beanstalkd_data.cpu.last_60s[index]);

                mems.nginx = nginx_data.mem;
                mems.redis = parseInt(data["REDIS_SERVER"].mem.last_60s[index]);

                connects.nginx[index] = parseInt(data["NGINX_MASTER"].conn_num.last_60s[index]);
                connects.redis[index] = parseInt(data["REDIS_SERVER"].conn_num.last_60s[index]);

                jobs.beanstalkd[index] = parseInt(data["BEANSTALKD"].total_jobs.last_60s[index]);
            }

            var length = loads.nginx.length;
            var offset = interval_60s_steps - length;

            if (offset > 0) {
                for (var index = 0; index < offset; ++index) {
                    last60s_cpu_data.series[0][index] = 0;
                    last60s_mem_data.series[0][index] = 0;
                    last60s_connects_data.series[0][index] = 0;
                    last60s_jobs_data.series[0][index] = 0;
                }
            }

            for (var index = 0; index < length; ++index) {
                var idx = offset + index;
                var load = (loads.beanstalkd[index] + loads.redis[index] + loads.nginx[index]) / cores;
                if (load > 100) {
                    load = 100;
                }
                last60s_cpu_data.series[0][idx] = load;
                last60s_mem_data.series[0][idx] = Math.ceil((mems.nginx + mems.redis) / 1024);

                last60s_connects_data.series[0][idx] = connects.nginx[index];
                last60s_jobs_data.series[0][idx] = jobs.beanstalkd[index];
            }
            self.charts.last60s_cpu_chart.update(last60s_cpu_data);
            self.charts.last60s_mem_chart.update(last60s_mem_data);
            self.charts.last60s_connects_chart.update(last60s_connects_data);
            self.charts.last60s_jobs_chart.update(last60s_jobs_data);

            // MEM
            self.opts.update_last60s_busy = false;
            $("#error_alert").hide();
        })
        .fail(function() {
            $("#error_alert").show();
        });
    },


    calc_ngx_data_at_index: function(data, timetype, index) {
        if (!data["NGINX_MASTER"]) {
            return false;
        }
        var cpu_set = data["NGINX_MASTER"].cpu[timetype];
        var mem_set = data["NGINX_MASTER"].mem[timetype];

        var load = cpu_set[index];
        if (load === undefined) {
            return false;
        }

        load = parseFloat(load);
        var mem = parseInt(mem_set[index]);

        for (var ngx_index = 1; ngx_index < 100; ++ngx_index) {
            var key = "NGINX_WORKER_#" + ngx_index;
            var set = data[key];
            if (set === undefined) {
                break;
            }
            load = load + parseFloat(set.cpu[timetype][index]);
            mem = mem + parseInt(set.mem[timetype][index]);
        }

        return {load: load, mem: mem};
    }
};

$(document).ready(function() {
    var l = document.location;
    dashboard.admin_url = "http://" + l.host + "/admin?action=monitor.getdata"
    dashboard.init();
});
