{% set ank = salt['grains.get']('ank', '19401') %}
{% set virltype = salt['grains.get']('virl_type', 'stable') %}
{% set proxy = salt['grains.get']('proxy', 'False') %}
{% set httpproxy = salt['grains.get']('http_proxy', 'https://proxy-wsa.esl.cisco.com:80/') %}

/var/cache/virl/ank:
  file.recurse:
    - order: 1
    - user: virl
    - group: virl
    - file_mode: 755
    {% if grains['cml'] == True %}
    - source: "salt://ank/release/cml/"
    {% elif virltype == 'stable' %}
    - source: "salt://ank/stable/"
    {% elif virltype == 'testing' %}
    - source: "salt://ank/qa/"
    {% endif %}

ank_init:
  file.managed:
    - order: 2
    - name: /etc/init.d/ank-webserver
    - source: "salt://files/ank-webserver.init"
    - mode: 0755

/root/.autonetkit/autonetkit.cfg:
  file.managed:
    - order: 3
    - makedirs: True
    - source: "salt://files/autonetkit.cfg"
    - mode: 0755

/etc/rc2.d/S98ank-webserver:
  file.symlink:
    - target: /etc/init.d/ank-webserver
    - mode: 0755

ank_prereq:
  pip.installed:
    {% if grains['proxy'] == true %}
    - proxy: {{ httpproxy }}
    {% endif %}
    - names:
      - lxml
      - configobj
      - six
      - Mako
      - MarkupSafe
      - certifi
      - backports.ssl_match_hostname
      - netaddr
      - networkx
      - PyYAML
      - tornado == 3.0.1

autonetkit:
  pip.installed:
    - order: 2
    - upgrade: True
    - use_wheel: True
    - no_index: True
    - find_links: "file:///var/cache/virl/ank"
    - require:
      - pip: ank_prereq
  cmd.wait:
    - names:
      - wheel install-scripts autonetkit
      - service ank-webserver start
    - watch:
      - pip: autonetkit

autonetkit_cisco:
  pip.installed:
    - order: 3
    - upgrade: True
    - use_wheel: True
    - no_index: True
    - find_links: "file:///var/cache/virl/ank"
    - require:
      - pip: autonetkit


autonetkit_cisco_webui:
  pip.installed:
    - order: 4
    - upgrade: True
    - use_wheel: True
    - no_index: True
    - name: autonetkit_cisco_webui
    - find_links: "file:///var/cache/virl/ank"
    - require:
      - pip: autonetkit_cisco

/etc/init.d/ank-webserver:
  file.replace:
    - pattern: portnumber
    - repl: {{ ank }}

rootank:
  file.replace:
    - name: /root/.autonetkit/autonetkit.cfg
    - pattern: portnumber
    - repl: {{ ank }}

ank-webserver:
  service:
    - running
    - enable: True
    - restart: True
    - watch:
      - pip: autonetkit


# {% if grains['cml'] == True %}
# /usr/local/lib/python2.7/dist-packages/autonetkit_cisco.so:
#   file.managed:
#     - order: 3
#     - source: salt://files/ank/release/cml/autonetkit_cisco_cml.so
#     - mode: 755
# {% else %}
# autonetkit_cisco:
#   file.managed:
#     - order: 3
#     - source: salt://files/ank/release/stable/autonetkit_cisco.so
#     - name: /usr/local/lib/python2.7/dist-packages/autonetkit_cisco.so
#     - require:
#       - pip: autonetkit
# {% endif %}
