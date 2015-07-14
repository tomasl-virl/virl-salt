# vim: tabstop=4 shiftwidth=4 softtabstop=4
#
# Copyright 2012 Cisco Systems, Inc.  All rights reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
# @author: Sumit Naiksatam, Cisco Systems, Inc.
# @author: Rohit Agarwalla, Cisco Systems, Inc.

from oslo.config import cfg

from neutron.agent.common import config

DEFAULT_VLAN_RANGES = []
DEFAULT_INTERFACE_MAPPINGS = []
DEFAULT_VXLAN_GROUP = '224.0.0.1'


vlan_opts = [
    cfg.StrOpt('tenant_network_type', default='local',
               help=_("Network type for tenant networks "
                      "(local, vlan, or none)")),
    cfg.ListOpt('network_vlan_ranges',
                default=DEFAULT_VLAN_RANGES,
                help=_("List of <physical_network>:<vlan_min>:<vlan_max> "
                       "or <physical_network>")),
]

vxlan_opts = [
    cfg.BoolOpt('enable_vxlan', default=False,
                help=_("Enable VXLAN on the agent. Can be enabled when "
                       "agent is managed by ml2 plugin using linuxbridge "
                       "mechanism driver")),
    cfg.IntOpt('ttl',
               help=_("TTL for vxlan interface protocol packets.")),
    cfg.IntOpt('tos',
               help=_("TOS for vxlan interface protocol packets.")),
    cfg.StrOpt('vxlan_group', default=DEFAULT_VXLAN_GROUP,
               help=_("Multicast group for vxlan interface.")),
    cfg.StrOpt('local_ip', default='',
               help=_("Local IP address of the VXLAN endpoints.")),
    cfg.BoolOpt('l2_population', default=False,
                help=_("Extension to use alongside ml2 plugin's l2population "
                       "mechanism driver. It enables the plugin to populate "
                       "VXLAN forwarding table.")),
]

bridge_opts = [
    cfg.ListOpt('physical_interface_mappings',
                default=DEFAULT_INTERFACE_MAPPINGS,
                help=_("List of <physical_network>:<physical_interface>")),
]

agent_opts = [
    cfg.IntOpt('polling_interval', default=2,
               help=_("The number of seconds the agent will wait between "
                      "polling for local device changes.")),
    cfg.BoolOpt('rpc_support_old_agents', default=False,
                help=_("Enable server RPC compatibility with old agents")),
]

extra_opts = [
    cfg.IntOpt('network_bridge_ageing', default=None,
               help=_("Bridge MAC learning timeout (0 = disable)")),
    cfg.IntOpt('network_bridge_multicast_snooping', default=None,
               help=_("Bridge multicast snooping (0 = disable)")),
]


cfg.CONF.register_opts(vlan_opts, "VLANS")
cfg.CONF.register_opts(vxlan_opts, "VXLAN")
cfg.CONF.register_opts(bridge_opts, "LINUX_BRIDGE")
cfg.CONF.register_opts(agent_opts, "AGENT")
cfg.CONF.register_opts(extra_opts)
config.register_agent_state_opts_helper(cfg.CONF)
config.register_root_helper(cfg.CONF)
