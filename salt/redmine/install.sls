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
  gem.installed:
    - ruby: {{vars['rubyversion']}}

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

{{ vars['rootdir'] }}/config/configuration.yml:
  file.managed:
    - source: salt://redmine/config/configuration.yml
    - template: jinja
    - require:
      - svn: clone-redmine-repo

bundle-install-gems:
  cmd.run:
    - name: rbenv exec bundle install --without development test
    - cwd: {{ vars['rootdir'] }}
    - env:
      - RBENV_ROOT: /usr/local/rbenv
    - require:
      - {{ vars['rootdir'] }}/config/database.yml

bundle-generate-secret:
  cmd.run:
    - name: rbenv exec rake generate_secret_token && echo 1 > {{vars['rootdir']}}/secret.txt
    - unless: grep 1 {{vars['rootdir']}}/secret.txt
    - cwd: {{ vars['rootdir'] }}
    - env:
      - RBENV_ROOT: /usr/local/rbenv
    - require:
      - {{ vars['rootdir'] }}/config/database.yml
      - cmd: bundle-install-gems

bundle-db-init-schema:
  cmd.run:
    - name: rbenv exec rake db:migrate && echo 1 > {{vars['rootdir']}}/db-schema.txt
    - unless: grep 1 {{vars['rootdir']}}/db-schema.txt
    - cwd: {{ vars['rootdir'] }}
    - env:
      - RBENV_ROOT: /usr/local/rbenv
      - RAILS_ENV: production
    - require:
      - {{ vars['rootdir'] }}/config/database.yml
      - cmd: bundle-install-gems
      - cmd: bundle-generate-secret

bundle-db-init-data:
  cmd.run:
    - name: echo "" | rbenv exec rake redmine:load_default_data && echo 1 > {{vars['rootdir']}}/db-data.txt
    - unless: grep 1 {{vars['rootdir']}}/db-data.txt
    - cwd: {{ vars['rootdir'] }}
    - env:
      - RBENV_ROOT: /usr/local/rbenv
      - RAILS_ENV: production
    - require:
      - {{ vars['rootdir'] }}/config/database.yml
      - cmd: bundle-install-gems
      - cmd: bundle-generate-secret
      - cmd: bundle-db-init-schema

{% for dir in [ 'files', 'log', 'tmp', 'public/plugin_assets' ] %}
{{ vars['rootdir'] }}/{{dir}}:
  file.directory:
    - mode: 755
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - mode
    - require:
      - svn: clone-redmine-repo
      - pkg: passenger
{% endfor %}
