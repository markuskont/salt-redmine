{% set vars = pillar['redmine'] %}

rbenv:
  pkg.latest:
    - refresh: True

rbenv-deps:
  pkg.installed:
    - pkgs:
      - bash
      - git
      - openssl
      - libssl-dev
      - make
      - curl
      - autoconf
      - bison
      - build-essential
      - libssl-dev
      - libyaml-dev
      - libreadline6-dev
      - zlib1g-dev
      - libncurses5-dev

ruby-{{vars['rubyversion']}}:
  rbenv.installed:
    - default: True
    - require:
      - pkg: rbenv-deps

bundler:
  gem.installed

{{ vars['rootdir'] }}:
  file.directory:
    - mode: 755

clone-redmine-repo:
  svn.latest:
    - name: http://svn.redmine.org/redmine/branches/{{vars['version']}}-stable
    - target: {{ vars['rootdir'] }}
    - require:
      - {{ vars['rootdir'] }}

{{ vars['rootdir'] }}/config/database.yml:
  file.managed:
    - source: salt://redmine/config/database.yml
    - template: jinja
    - default:
      database: {{ salt['pillar.get']('mysql:app_user') }}
      username: {{ salt['pillar.get']('mysql:app_user') }}
      password: {{ salt['pillar.get']('mysql:app_pw') }}
    - require:
      - svn: clone-redmine-repo

bundle-install-gems:
  cmd.run:
    - name: /usr/local/rbenv/versions/{{vars['rubyversion']}}/bin/bundle install --without development test
    - cwd: {{ vars['rootdir'] }}
    - require:
      - {{ vars['rootdir'] }}/config/database.yml
