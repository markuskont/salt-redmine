debconf-utils:
  pkg.installed

mysql_setup:
  debconf.set:
    - name: mysql-server
    - data:
        'mysql-server/root_password': {'type': 'password', 'value': '{{ salt['pillar.get']('mysql:root_pw', '') }}' }
        'mysql-server/root_password_again': {'type': 'password', 'value': '{{ salt['pillar.get']('mysql:root_pw', '') }}' }
    - require:
      - pkg: debconf-utils

mysql-server:
  pkg.installed:
    - require:
      - debconf: mysql-server

redmine-db:
  mysql_user.present:
    - host: localhost
    - name: {{ salt['pillar.get']('mysql:app_user') }}
    - password: {{ salt['pillar.get']('mysql:app_pw') }}
    - connection_user: root
    - connection_pass: {{ salt['pillar.get']('mysql:root_pw') }}
    - connection_charset: utf8
    - saltenv:
      - LC_ALL: "en_US.utf8"
    - require:
      - pkg: mysql-server
  mysql_database.present:
    - host: localhost
    - name: {{ salt['pillar.get']('mysql:app_user') }}
    - connection_user: root
    - connection_pass: {{ salt['pillar.get']('mysql:root_pw') }}
    - connection_charset: utf8
    - saltenv:
      - LC_ALL: "en_US.utf8"
    - require:
      - pkg: mysql-server
  mysql_grants.present:
    - grant: all privileges
    - database: {{ salt['pillar.get']('mysql:app_user') }}.*
    - user: {{ salt['pillar.get']('mysql:app_user') }}
    - connection_user: root
    - connection_pass: {{ salt['pillar.get']('mysql:root_pw') }}
    - connection_charset: utf8
    - saltenv:
      - LC_ALL: "en_US.utf8"
    - require:
      - mysql_user: redmine-db
      - mysql_database: redmine-db
