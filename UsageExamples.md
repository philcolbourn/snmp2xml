# Usage Examples #

SNMP data can be collected from a host using `snmpwalk`. To simplify processing, the `-OXf` flags are used to output the full OID list and to group table indexes.

```
-Of to include the full list of MIB objects when displaying an OID, and
-OX to display table indexes in a more "program like" output, imitating a traditional array-style index format.
```

# Step 1 #

Get the SNMP data.

```
snmpbulkwalk -v2c -cpublic -OXf 10.68.8.251 tcp > time-capsule-tcp.snmpwalk

snmpwalk -v2c -cpublic -OXf 10.68.8.251 > time-capsule.snmpwalk
```

# Step 2 #
Use `snmp2xml` to convert the SNMP output to XML.

```
awk -f snmp2xml.awk time-capsule-tcp.snmpwalk > time-capsule-tcp.snmpwalk.xml

awk -f snmp2xml.awk time-capsule.snmpwalk > time-capsule.snmpwalk.xml
```

# Step 3 #

Run some query on the XML data.

```
xpath time-capsule.snmpwalk.xml "//ifTable/*"

xpath time-capsule.snmpwalk.xml "/data/iso/org/dod/internet/mgmt/mib-2/tcp" | xmllint --format -
```


# BASH Pipe Example #

Instead of creating lots of intermediate files that you might not want, you can pipe the output of each stage into the next.

```
snmpwalk -v2c -cpublic -OXf 10.68.8.251 | awk -f snmp2xml.awk | xmllint --format -
```

`xmllint` can do a lot. In this case I use it to take an XML file and format it for readability.

# Closeing the Loop #

To assist with debugging, and to ensure that `snmp2xml` was accurately converting all the information without loss, the `xml2snmp` script can be used to re-generate the original SNMP output.

This can then be compared with the original data: `snmp2xml` is **not** working correctly if the re-generated output is different to the original.

The `diff` utility can be used to compare the files and `saxon` can be used to convert the XML data back into SNMP output.

```
snmpwalk -v2c -cpublic -OXf 10.68.8.251 > host.snmpwalk
awk -f snmp2xml.awk | xmllint --format - | saxon xml2snmp.xsl > host.snmpwalk.xml.snmpwalk

diff host.snmpwalk host.snmpwalk.xml.snmpwalk
```