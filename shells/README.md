#some tools for quick-server

- start\_quick\_server.sh function list:
    - start the whole Quick Server.
    - start redis sever.
    - start mysql server.
    - start a cleaner for index tables in mysql.

- stop\_quick\_server.sh function list:
    - stop nginx process.
    - stop the cleaner for index tables.

- status\_quick\_server.sh function list:
    - show nginx process.
    - show redis process.
    - show mysql process.
    - show the cleaner process.

- restart\_nginx\_only.sh function list:
    - reload ngxin conf file and restart nginx only.

- start.sh, stop.sh and reload.sh function:
    - command "nginx" is encapsulated in these shells.
