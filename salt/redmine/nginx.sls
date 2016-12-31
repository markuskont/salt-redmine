{% set oscodename = grains.get('oscodename')|lower %}

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
