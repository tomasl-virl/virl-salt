{% from "virl.jinja" import virl with context %}

include:
  - virl.routervms.virl-core-sync

{% if virl.iolpref %}

iol prereq pkgs:
  pkg.installed:
{% if virl.packet %}
    - refresh: True
{% endif %}
    - pkgs:
      - libc6:i386

iol:
  virl_core.lxc_image_present:
  - subtype: IOL
  - release: {{ salt['pillar.get']('version:iol')}}

{% else %}

iol gone:
  virl_core.lxc_image_absent:
  - subtype: IOL

{% endif %}
