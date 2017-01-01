{% set oscodename = grains.get('oscodename')|lower %}
{% set vars = pillar['redmine'] %}

apt-transport-https:
  pkg.installed

passenger-ppa:
  pkgrepo.managed:
    - name: deb https://oss-binaries.phusionpassenger.com/apt/passenger {{oscodename}} main
    - file: /etc/apt/sources.list.d/passenger.list
    - keyserver: keyserver.ubuntu.com
    - keyid: 561F9B9CAC40B2F7
    - clean_file: True
    - require:
      - pkg: apt-transport-https
  pkg.installed:
    - pkgs:
      - nginx-extras
      - passenger
    - require:
      - pkgrepo: passenger-ppa
  service.running:
    - name: nginx
    - enable: True
    - watch:
      - /etc/nginx/sites-available/*
      - /etc/nginx/sites-enabled/*
      - /etc/nginx/nginx.conf
    - require:
      - /etc/nginx/sites-available/{{grains['fqdn']}}
      - /etc/nginx/sites-enabled/{{grains['fqdn']}}

/etc/nginx/sites-enabled/default:
  file.absent:
    - require:
      - pkg: passenger-ppa

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://redmine/etc/nginx/nginx.conf
    - require:
      - pkg: passenger-ppa
      - /etc/nginx/passenger.conf

/etc/nginx/passenger.conf:
  file.managed:
    - source: salt://redmine/etc/nginx/passenger.conf
    - template: jinja
    - default:
      user: {{vars['user']}}

/etc/nginx/sites-available/{{grains['fqdn']}}:
  file.managed:
    - source: salt://redmine/etc/nginx/sites-available/site.conf
    - template: jinja
    - default:
      vhost: {{grains['fqdn']}}
      rootdir: {{vars['rootdir']}}
      rbenv_dir: {{vars['rbenv_dir']}}
      rubyversion: {{vars['rubyversion']}}
      logdir: {{vars['logdir']}}
    - require:
      - pkg: passenger-ppa

/etc/nginx/sites-enabled/{{grains['fqdn']}}:
  file.symlink:
    - target: /etc/nginx/sites-available/{{grains['fqdn']}}
    - require:
      - /etc/nginx/sites-available/{{grains['fqdn']}}
