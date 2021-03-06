{% from "virl.jinja" import virl with context %}

include:
  - virl.routervms.virl-core-sync

{% if virl.server and virl.serverpref %}

UbuntuServertrusty:
  glance.image_present:
  - profile: virl
  - name: 'server'
  - container_format: bare
  - min_disk: 3
  - min_ram: 0
  - is_public: True
  - checksum: c334f496411ec30a2bdb043e5dcfea02
  - protected: False
  - disk_format: qcow2
  - copy_from: salt://images/salt/ubuntu-14.04-server-cloudimg-amd64-disk1.img
  - property-hw_disk_bus: virtio
  - property-release: 14.04.2
  - property-serial: 1
  - property-subtype: server

UbuntuServertrusty flavor delete:
  cmd.run:
    - name: 'source /usr/local/bin/virl-openrc.sh ;nova flavor-delete "server"'
    - onlyif: source /usr/local/bin/virl-openrc.sh ;nova flavor-show "server"
    - onchanges:
      - glance: UbuntuServertrusty

UbuntuServertrusty flavor create:
  module.run:
    - name: nova.flavor_create
    - m_name: 'server'
    - ram: 512
    - disk: 0
    - vcpus: 1
  {% if virl.mitaka %}
    - profile: virl
  {% endif %}
    - onchanges:
      - glance: UbuntuServertrusty
    - require:
      - cmd: UbuntuServertrusty flavor delete

{% else %}

UbuntuServertrusty gone:
  glance.image_absent:
  - profile: virl
  - name: 'server'

UbuntuServertrusty flavor absent:
  cmd.run:
    - name: 'source /usr/local/bin/virl-openrc.sh ;nova flavor-delete "server"'
    - onlyif: source /usr/local/bin/virl-openrc.sh ;nova flavor-list | grep -w "server"
{% endif %}
