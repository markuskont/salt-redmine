{% set vars = pillar['redmine'] %}
/etc/ssl/redmine:
  file.directory:
    - mode: 0700
    - user: root
    - group: root

python-m2crypto:
  pkg.installed

/etc/ssl/redmine/key.pem:
  x509.private_key_managed:
    - bits: 4096
    - require:
      - pkg: python-m2crypto
      - /etc/ssl/redmine

/etc/ssl/redmine/cert.pem:
  x509.certificate_managed:
    - signing_private_key: /etc/ssl/redmine/key.pem
    - CN: {{vars['tls']['common_name']}}
    - C: 'Estonia'
    - ST: 'Harjumaa'
    - L: 'Tallinn'
    - days_valid: 3650
    - days_remaining: 90
    - require:
      - /etc/ssl/redmine
      - /etc/ssl/redmine/key.pem
      - pkg: python-m2crypto

/etc/nginx/redmine:
  file.directory:
    - mode: 0755
    - user: root
    - group: root
    - require:
      - pkg: passenger-ppa

/etc/nginx/redmine/key.pem:
  file.managed:
    - mode: 0600
    - user: root
    - group: root
    - source: /etc/ssl/redmine/key.pem
    - require:
      - /etc/nginx/redmine
      - /etc/ssl/redmine/key.pem

/etc/nginx/redmine/cert.pem:
  file.managed:
    - mode: 0644
    - user: root
    - group: root
    - source: /etc/ssl/redmine/cert.pem
    - require:
      - /etc/nginx/redmine
      - /etc/nginx/redmine/key.pem
