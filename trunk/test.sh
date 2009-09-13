#!/bin/bash

######################################################################
# Copyright (C) 2009 Phil Colbourn. All rights reserved.

# This file is part of snmp2xml.

#    snmp2xml is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    snmp2xml is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
######################################################################

# This script tests the snmp2xml conversion
# it cleans-up the snmp output, converts it, re-generates it and 
# compares the output with the original (cleaned-up) version

# allow execution with a single input file or stdin
IN=$1
OUT=$1
if [ "$IN" == "" ]; then
	echo "Usage: $0 [file.snmp | -]"
	echo "where: - takes input from stdin"
	echo
	echo "example: $0 switch-output.snmpwalk"
	echo "example: cat switch-output.snmpwalk | $0 -"
	exit 1
fi

if [ "$IN" == "-" ]; then
	IN="/dev/stdin"
	OUT="stdin"
fi

# fix dodgy snmp output
cat $IN | awk -f fix-snmp-output.awk | uniq > $OUT.fixed

# convert to xml and re-format for printing
cat $OUT.fixed | awk -f snmp2xml-2.awk | xmllint --format - > $OUT.xml

# and back to snmp to 'prove' the conversion
cat $OUT.xml | saxon - xml2snmp.xsl > $OUT.xml.snmpwalk

# should match the original
diff -s $OUT.fixed $OUT.xml.snmpwalk
