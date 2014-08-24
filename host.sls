{% set neutronpassword = salt['grains.get']('password', 'password') %}
{% set ospassword = salt['grains.get']('password', 'password') %}
{% set domain = salt['grains.get']('domain', 'cisco.com') %}
{% set hostname = salt['grains.get']('hostname', 'virl') %}
{% set publicport = salt['grains.get']('public_port', 'eth0') %}
{% set dhcp = salt['grains.get']('using dhcp on the public port?', True ) %}
{% set public_ip = salt['grains.get']('static ip', '127.0.0.1' ) %}
{% set public_gateway = salt['grains.get']('public_gateway', '172.16.6.1' ) %}
{% set public_netmask = salt['grains.get']('public_netmask', '255.255.255.0' ) %}
{% set l2_port = salt['grains.get']('l2_port', 'eth1' ) %}
{% set l2_address = salt['grains.get']('l2_address', '172.16.1.254' ) %}
{% set l2_address2 = salt['grains.get']('l2_address2', '172.16.2.254' ) %}
{% set l3_address = salt['grains.get']('l3_address', '172.16.3.254' ) %}
{% set l2_port2 = salt['grains.get']('l2_port2', 'eth2' ) %}
{% set l2_port2_enabled = salt['grains.get']('l2_port2_enabled', 'True' ) %}
{% set l3_port = salt['grains.get']('l3_port', 'eth3' ) %}
{% set fdns = salt['grains.get']('first nameserver', '8.8.8.8' ) %}
{% set sdns = salt['grains.get']('second nameserver', '8.8.4.4' ) %}
{% set int_ip = salt['grains.get']('internalnet ip', '172.16.10.250' ) %}
{% set int_port = salt['grains.get']('internalnet_port', 'eth4' ) %}
{% set int_mask = salt['grains.get']('internalnet_netmask', '255.255.255.0' ) %}

system:
  network.system:
    - enabled: False
    - hostname: {{hostname}}.{{domain}}
    - gatewaydev: {{ publicport }}

eth0:
  network.managed:
    - order: 1
    - name: {{ publicport }}
    - enabled: True
    - type: eth
{% if dhcp == True %}
    - proto: dhcp
{% else %}
    - proto: static
    - ipaddr: {{ public_ip }}
    - netmask: {{ public_netmask }}
    - gateway: {{ public_gateway }}
    - dns:
      - {{ fdns }}
      - {{ sdns }}
{% endif %}


{{ int_port }}:
  network.managed:
    - ipaddr: {{ int_ip }}
    - proto: static
    - netmask: {{ int_mask }}
    - type: eth
    - enabled: True


loop0:
  network.managed:
    - order: 1
    - enabled: True
    - name: 'lo'
    - type: eth
    - enabled: True
    - proto: loopback

loop1:
  network.managed:
    - order: 1
    - enabled: True
    - name: 'lo:1'
    - ipaddr: 127.0.1.1
    - netmask: 255.255.255.0
    - type: eth
    - enabled: True
    - proto: loopback

{{ l2_port }}:
  network.managed:
    - order: 1
    - enabled: True
    - proto: manual
    - type: eth
    - ipaddr: 0.0.0.1
    - netmask: 255.255.255.255
    - promisc: on

{% if l2_port2_enabled == True %}
{{ l2_port2 }}:
  network.managed:
    - order: 1
    - enabled: True
    - proto: manual
    - type: eth
    - ipaddr: 0.0.0.2
    - netmask: 255.255.255.254
    - promisc: on

man-flat2-address:
  file.replace:
    - order: 2
    - name: /etc/network/interfaces
    - pattern: 'address 0.0.0.2'
    - repl: 'up ifconfig {{ l2_port2 }} {{ l2_address2 }} up'

man-flat2-promis:
  file.replace:
    - order: 2
    - name: /etc/network/interfaces
    - pattern: 'netmask 255.255.255.254'
    - repl: 'up ip link set {{l2_port2}} promisc on'

{% endif %}

{{ l3_port }}:
  network.managed:
    - order: 1
    - name: {{ l3_port }}
    - enabled: True
    - proto: manual
    - type: eth
    - ipaddr: 0.0.0.3
    - netmask: 255.255.255.253
    - promisc: on

man-flat-address:
  file.replace:
    - order: 2
    - name: /etc/network/interfaces
    - pattern: 'address 0.0.0.1'
    - repl: 'up ifconfig {{ l2_port }} {{ l2_address }} up'


man-snat-address:
  file.replace:
    - order: 2
    - name: /etc/network/interfaces
    - pattern: 'address 0.0.0.3'
    - repl: 'up ifconfig {{ l3_port }} {{ l3_address }} up'

man-flat-promis:
  file.replace:
    - order: 2
    - name: /etc/network/interfaces
    - pattern: 'netmask 255.255.255.255'
    - repl: 'up ip link set {{l2_port}} promisc on'


man-snat-promis:
  file.replace:
    - order: 2
    - name: /etc/network/interfaces
    - pattern: 'netmask 255.255.255.253'
    - repl: 'up ip link set {{l3_port}} promisc on'

vhost:
  host.present:
    - name: {{ hostname }}.{{domain}}
    - ip: {{ public_ip }}

vhostloop:
  host.present:
    - name: {{ hostname }}
    - ip: 127.0.1.1

vhostname:
  file.managed:
    - name: /etc/hostname
    - contents: {{ hostname }}

/etc/init/failsafe.conf:
  file.managed:
    - file_mode: 644
    - source: "salt://files/failsafe.conf"