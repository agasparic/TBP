CREATE CONSTRAINT device_hostname_unique IF NOT EXISTS
FOR (d:Device)
REQUIRE d.hostname IS UNIQUE;

CREATE CONSTRAINT vlan_id_unique IF NOT EXISTS
FOR (v:VLAN)
REQUIRE v.id IS UNIQUE;

CREATE CONSTRAINT dhcp_name_unique IF NOT EXISTS
FOR (p:DHCPPool)
REQUIRE p.name IS UNIQUE;

CREATE CONSTRAINT acl_name_unique IF NOT EXISTS
FOR (a:AccessList)
REQUIRE a.name IS UNIQUE;

CREATE INDEX interface_mode_idx IF NOT EXISTS
FOR (i:Interface)
ON (i.mode);

CREATE INDEX interface_dot1q_idx IF NOT EXISTS
FOR (i:Interface)
ON (i.dot1q);

CREATE INDEX device_role_idx IF NOT EXISTS
FOR (d:Device)
ON (d.role);

CREATE CONSTRAINT interface_per_device_unique IF NOT EXISTS
FOR (i:Interface)
REQUIRE i.device_iface IS UNIQUE;



MERGE (r1:Device {hostname:'R1'}) 
SET r1.role='router';

MERGE (r2:Device {hostname:'R2'}) 
SET r2.role='router';

MERGE (sw1:Device {hostname:'SW1'}) 
SET sw1.role='switch';

MERGE (sw2:Device {hostname:'SW2'}) 
SET sw2.role='switch';



MERGE (v10:VLAN {id:'10'}) SET v10.name='USERS';
MERGE (v20:VLAN {id:'20'}) SET v20.name='SERVERS';
MERGE (v30:VLAN {id:'30'}) SET v30.name='MANAGEMENT';



UNWIND [
  {hostname:'R1', iface:'GigabitEthernet1/0', ip:'10.10.10.1 255.255.255.0'},
  {hostname:'R1', iface:'GigabitEthernet1/1', ip:'192.168.1.1 255.255.255.0'},
  {hostname:'R2', iface:'GigabitEthernet1/0', ip:'10.10.20.1 255.255.255.0'},
  {hostname:'R2', iface:'GigabitEthernet1/1', ip:'192.168.2.1 255.255.255.0'}
] AS row
MATCH (r:Device {hostname: row.hostname})
MERGE (i:Interface {name: row.iface, deviceHostname: row.hostname})
SET i.description = 'Router Port ' + toString(row.iface),
    i.ip = row.ip,
    i.device_iface = row.hostname + '_' + row.iface
MERGE (r)-[:HAS_INTERFACE]->(i);



UNWIND range(1,24) AS gi
MATCH (sw:Device) WHERE sw.hostname IN ['SW1','SW2']
MERGE (i:Interface {name: 'GigabitEthernet0/' + toString(gi), deviceHostname: sw.hostname})
SET i.description = 'Switch Port ' + toString(gi),
    i.mode = 'access',
    i.dot1q = CASE 
                WHEN gi <= 8 THEN '10'
                WHEN gi <= 16 THEN '20'
                ELSE '30'
              END,
    i.device_iface = sw.hostname + '_GigabitEthernet0/' + toString(gi)
MERGE (sw)-[:HAS_INTERFACE]->(i)
WITH i
WHERE i.dot1q IS NOT NULL
MATCH (v:VLAN {id: i.dot1q})
MERGE (i)-[:MEMBER_OF]->(v);



MATCH (r1i:Interface {name:'GigabitEthernet1/0', deviceHostname:'R1'}),
      (sw1i:Interface {name:'GigabitEthernet0/1', deviceHostname:'SW1'})
MERGE (r1i)-[:CONNECTED_TO]->(sw1i);

MATCH (r2i:Interface {name:'GigabitEthernet1/1', deviceHostname:'R2'}),
      (sw2i:Interface {name:'GigabitEthernet0/2', deviceHostname:'SW2'})
MERGE (r2i)-[:CONNECTED_TO]->(sw2i);



MATCH (r1:Device {hostname:'R1'})
MERGE (p1:DHCPPool {name:'VLAN10_POOL_R1'})
SET p1.network='10.10.10.0 255.255.255.0', p1.defaultRouter='10.10.10.1'
MERGE (r1)-[:HAS_DHCPPOOL]->(p1);

MATCH (r2:Device {hostname:'R2'})
MERGE (p2:DHCPPool {name:'VLAN20_POOL_R2'})
SET p2.network='10.10.20.0 255.255.255.0', p2.defaultRouter='10.10.20.1'
MERGE (r2)-[:HAS_DHCPPOOL]->(p2);

