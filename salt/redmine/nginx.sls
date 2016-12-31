{% set oscodename = grains.get('oscodename')|lower %}
{% set vars = pillar['redmine'] %}

apt-transport-https:
  pkg.installed

passenger:
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
      - pkgrepo: passenger
  service.running:
    - name: nginx
    - enable: True
    - watch:
      - /etc/nginx/sites-available/*
      - /etc/nginx/sites-enabled/*
    - require:
      - /etc/nginx/sites-available/{{grains['fqdn']}}
      - /etc/nginx/sites-enabled/{{grains['fqdn']}}

/etc/nginx/sites-enabled/default:
  file.absent:
    - require:
      - pkg: passenger

/etc/nginx/sites-available/{{grains['fqdn']}}:
  file.managed:
    - source: salt://redmine/config/nginx.conf
    - template: jinja
    - default:
      vhost: {{grains['fqdn']}}
      rootdir: {{vars['rootdir']}}
      rbenv_dir: {{vars['rbenv_dir']}}
      rubyversion: {{vars['rubyversion']}}
      logdir: {{vars['logdir']}}
    - require:
      - pkg: passenger

/etc/nginx/sites-enabled/{{grains['fqdn']}}:
  file.symlink:
    - target: /etc/nginx/sites-available/{{grains['fqdn']}}
    - require:
      - /etc/nginx/sites-available/{{grains['fqdn']}}
