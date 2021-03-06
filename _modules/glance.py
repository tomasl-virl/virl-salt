# -*- coding: utf-8 -*-
'''
Module for handling openstack glance calls.

:optdepends:    - glanceclient Python adapter
:configuration: This module is not usable until the following are specified
    either in a pillar or in the minion's config file::

        keystone.user: admin
        keystone.password: verybadpass
        keystone.tenant: admin
        keystone.tenant_id: f80919baedab48ec8931f200c65a50df
        keystone.insecure: False   #(optional)
        keystone.auth_url: 'http://127.0.0.1:5000/v2.0/'

    If configuration for multiple openstack accounts is required, they can be
    set up as different configuration profiles:
    For example::

        openstack1:
          keystone.user: admin
          keystone.password: verybadpass
          keystone.tenant: admin
          keystone.tenant_id: f80919baedab48ec8931f200c65a50df
          keystone.auth_url: 'http://127.0.0.1:5000/v2.0/'

        openstack2:
          keystone.user: admin
          keystone.password: verybadpass
          keystone.tenant: admin
          keystone.tenant_id: f80919baedab48ec8931f200c65a50df
          keystone.auth_url: 'http://127.0.0.2:5000/v2.0/'

    With this configuration in place, any of the keystone functions can make
    use of a configuration profile by declaring it explicitly.
    For example::

        salt '*' glance.image_list profile=openstack1
'''

import logging

log = logging.getLogger(__name__)


# Import third party libs
HAS_GLANCE = False
try:
    from glanceclient import client
    import glanceclient.v1.images
    HAS_GLANCE = True
except ImportError:
    pass


def __virtual__():
    '''
    Only load this module if glance
    is installed on this minion.
    '''
    if HAS_GLANCE:
        return 'glance'
    return False

__opts__ = {}


def _auth(profile=None, **connection_args):
    '''
    Set up keystone credentials
    '''
    kstone = __salt__['keystone.auth'](profile, **connection_args)
    token = kstone.auth_token
    endpoint = kstone.service_catalog.url_for(
        service_type='image',
        endpoint_type='publicURL',
        )

    return client.Client('1', endpoint, token=token)


def image_resolve_properties(properties, kwargs):
    '''
    Merge dict properties argument with additional properties defined in kwargs
    in the form "property_foo" or "property-bar".

    '''
    if not isinstance(properties, dict):
        properties = {}
    else:
        properties = dict(properties)  # copy
    prefix = 'property_'
    prefix_alt = 'property-'
    add_props = {
        key[len(prefix):]: value
        for key, value in kwargs.items()
        if key.startswith(prefix) or key.startswith(prefix_alt)
    }
    properties.update(add_props)
    return properties


def image_create(profile=None, **connection_args):
    '''
    Create an image (glance image-create)

    CLI Example:

    .. code-block:: bash

        salt '*' glance.image_create name=f16-jeos is_public=true \\
                 disk_format=qcow2 container_format=ovf \\
                 copy_from=http://berrange.fedorapeople.org/images/ \\
                 2012-02-29/f16-x86_64-openstack-sda.qcow2

    For all possible values, run ``glance help image-create`` on the minion.
    '''
    nt_ks = _auth(profile, **connection_args)
    fields = dict(
        filter(
            lambda x: x[0] in glanceclient.v1.images.CREATE_PARAMS,
            connection_args.items()
        )
    )
    if 'properties' in glanceclient.v1.images.CREATE_PARAMS:
        properties = image_resolve_properties(fields.get('properties'),
                                              connection_args)
        if properties:
            fields['properties'] = properties

    img_path = connection_args.pop('file', None)
    copy_from = fields.get('copy_from')
    if copy_from and copy_from.startswith('salt://'):
        fields.pop('copy_from')
        if img_path:
            log.warning('Ignoring copy_from=%s, using local file' % copy_from)
        else:
            # Store to cache and get path
            img_path = __salt__['cp.cache_file'](copy_from)
            if not img_path:
                raise Exception('Could not find %s' % copy_from)

    if img_path:
        with open(img_path) as img_data:
            fields['data'] = img_data
            image = nt_ks.images.create(**fields)
    else:
        image = nt_ks.images.create(**fields)
    return image_show(id=str(image.id), profile=profile, **connection_args)


def image_delete(id=None, name=None, profile=None, **connection_args):  # pylint: disable=C0103
    '''
    Delete an image (glance image-delete)

    CLI Examples:

    .. code-block:: bash

        salt '*' glance.image_delete c2eb2eb0-53e1-4a80-b990-8ec887eae7df
        salt '*' glance.image_delete id=c2eb2eb0-53e1-4a80-b990-8ec887eae7df
        salt '*' glance.image_delete name=f16-jeos
    '''
    nt_ks = _auth(profile, **connection_args)
    if name:
        for image in nt_ks.images.list():
            if image.name == name:
                id = image.id  # pylint: disable=C0103
                continue
    if not id:
        return {'Error': 'Unable to resolve image id'}
    nt_ks.images.delete(id)
    ret = 'Deleted image with ID {0}'.format(id)
    if name:
        ret += ' ({0})'.format(name)
    return ret


def image_show(id=None, name=None, profile=None, **connection_args):  # pylint: disable=C0103
    '''
    Return details about a specific image (glance image-show)

    CLI Example:

    .. code-block:: bash

        salt '*' glance.image_get
    '''
    nt_ks = _auth(profile, **connection_args)
    ret = {}
    if name:
        for image in nt_ks.images.list():
            if image.name == name:
                id = image.id  # pylint: disable=C0103
                break
    if not id:
        return {'Error': 'Unable to resolve image id'}
    image = nt_ks.images.get(id)
    ret[image.name] = {'id': image.id,
                       'name': image.name,
                       'checksum': getattr(image, 'checksum', 'Creating'),
                       'container_format': image.container_format,
                       'created_at': image.created_at,
                       'deleted': image.deleted,
                       'disk_format': image.disk_format,
                       'is_public': image.is_public,
                       'min_disk': image.min_disk,
                       'min_ram': image.min_ram,
                       'owner': image.owner,
                       'properties': image.properties,
                       'protected': image.protected,
                       'size': image.size,
                       'status': image.status,
                       'updated_at': image.updated_at}
    return ret


def image_list(profile=None, **connection_args):  # pylint: disable=C0103
    '''
    Return a list of available images (glance image-list)

    CLI Example:

    .. code-block:: bash

        salt '*' glance.image_list
    '''
    nt_ks = _auth(profile, **connection_args)
    ret = {}
    for image in nt_ks.images.list():
        ret[image.name] = {'id': image.id,
                           'name': image.name,
                           'checksum': getattr(image, 'checksum', 'Creating'),
                           'container_format': image.container_format,
                           'created_at': image.created_at,
                           'deleted': image.deleted,
                           'disk_format': image.disk_format,
                           'is_public': image.is_public,
                           'min_disk': image.min_disk,
                           'min_ram': image.min_ram,
                           'owner': image.owner,
                           'properties': image.properties,
                           'protected': image.protected,
                           'size': image.size,
                           'status': image.status,
                           'updated_at': image.updated_at}
    return ret


def _item_list(profile=None, **connection_args):
    '''
    Template for writing list functions
    Return a list of available items (glance items-list)

    CLI Example:

    .. code-block:: bash

        salt '*' glance.item_list
    '''
    nt_ks = _auth(profile, **connection_args)
    ret = []
    for item in nt_ks.items.list():
        ret.append(item.__dict__)
        # ret[item.name] = {
        #        'name': item.name,
        #    }
    return ret

# The following is a list of functions that need to be incorporated in the
# glance module. This list should be updated as functions are added.

# image-download      Download a specific image.
# image-update        Update a specific image.
# member-create       Share a specific image with a tenant.
# member-delete       Remove a shared image from a tenant.
# member-list         Describe sharing permissions by image or tenant.
