{% for each in 'ank','files','images/salt','images/vmware','std','vmm' %}
/srv/virl/{{ each }}:
  file.recurse:
    - source: 'salt://{{each}}/'
    - order: 1
    - clean: True
    - user: virl
    - makedirs: True
    - group: virl
    - exclude_pat: .git/*
    - file_mode: 755
    - include_empty: True

{% endfor %}
