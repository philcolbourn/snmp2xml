# Tested SNMP Agents #

The following SNMP agents have been tested with `snmp2xml':

| **Device** | **Version Details** |
|:-----------|:--------------------|
| Apple Time-capsule | 7.4.2 |
| Billion ADSL router | BiPAC 7404VNPX. H/W: USB/ADSL-M/WN/VOS v1.00 / Solos 461x CSP v1.0 F/W: 5.53.s5.dge (09 June 2009) |
|Apple OS-X snmpd | 10.5.8 |
|Foundry/Brocade CES | NetIron CES, IronWare Version V3.9.0T183 Compiled on Jul 23 2009 at 14:18:43 labeled as V3.9.00 |
| Huawei S9306 L3 switch | Quidway S9306 Huawei VRP V5.50 |
| Nortel 425-24T switch | HW:06 FW:3.5.0.2 SW:v3.5.0.06 BN:6 |
| Foundry/Brocade MLX-4 | NetIron MLX, IronWare Version V4.0.0eT163 Compiled on Aug 27 2009 at 21:16:23 labeled as V4.0.00e|

# Results #

| **SNMP Agent** | **-OXf** | **OIDs Increase** | **Unique OIDs** | **snmp2xml Issues** |
|:---------------|:---------|:------------------|:----------------|:--------------------|
| Apple Time-Capsule | PASS | YES | PASS | ipRouteIfIndex off by 1 |
| Billion ADSL router | PASS | YES | All Duplicated | Removes duplicates, xml2snmp does not re-generate duplicates |
| OS-X Leopard 10.5.8 | PASS | YES | PASS | Outputs strings of hex FF |
| Brocade CES | PASS | ? | PASS |
| Huawei S9306 | PASS | FAIL (-Cc required) | PASS | New-lines and carriage-returns handled ok |
| Nortel 425-24T | PASS | PASS | PASS |  |
| Brocade MLX-4 | PASS | PASS | PASS |  |