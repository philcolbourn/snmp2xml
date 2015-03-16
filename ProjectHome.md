This code can be used as-is or perhaps as part of an SNMP to XML gateway or HTTP CGI web service (an example CGI script is included).

The output from `snmpget`, `snmpwalk` or `snmpbulkwalk` is first filtered to correct for SNMP agent flaws and then processed into XML.

This XML can be passed through `xmllint` to tidy it up or it can be processed by an XQuery or XSLT processor.

The XML output represents all the SNMP data such that the original SNMP output can be re-produced if desired with an XSLT stylesheet (also included).

The `snmp2xml` converter has been tested on 7 SNMP agents:

  * Apple OS-X and Time Capsule
  * Billion ADSL router
  * Huawei S9306 switch
  * Foundry/Brocade CES and MLX-4 switches
  * Nortel 425 switch

I have almost exhausted all the SNMP agents that I have access to.