MATCH (n)
DETACH DELETE n;

DROP CONSTRAINT interface_per_device_unique IF EXISTS;
DROP CONSTRAINT device_hostname_unique IF EXISTS;
DROP CONSTRAINT vlan_id_unique IF EXISTS;
DROP CONSTRAINT dhcp_name_unique IF EXISTS;
DROP CONSTRAINT acl_name_unique IF EXISTS;

DROP INDEX interface_mode_idx IF EXISTS;
DROP INDEX interface_dot1q_idx IF EXISTS;
DROP INDEX device_role_idx IF EXISTS;

