#!/sw/bin/awk

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

# Possible uses:

# SNMP get to XML gateway

# if the query was sent to a web server a CGI-BIN program could run the SNMPGET query
# and return the result as XML

# eg. http://snmp.gateway/cgi-bin/snmpget?community=public&host=10.0.0.1&oid=ifInOctets.1

# snmpget -v2c -c$community -OXf $host $oid | ./pc-snmp2xml.sh

# Usage:

# 1. get snmp data

# MUST use -OXf
# X to make it easy to process tables by collecting values within []
# f to include full MIB OID names/path

# example

# snmpbulkwalk -v2c -cpublic -OXf 10.1.1.251 tcp > time-capsule-tcp.snmpwalk
# snmpwalk -v2c -cpublic -OXf 10.1.1.251 > time-capsule.snmpwalk

# 2. use this to convert to XML

# example

# awk -f pc-snmp2xml.awk time-capsule-tcp.snmpwalk > time-capsule-tcp.snmpwalk.xml
# awk -f pc-snmp2xml.awk time-capsule.snmpwalk > time-capsule.snmpwalk.xml

# 3. run some query on the data

# example

# xpath time-capsule.snmpwalk.xml "//ifTable/*"
# xpath time-capsule.snmpwalk.xml "/data/iso/org/dod/internet/mgmt/mib-2/tcp" | xmllint --format -

# BASH pipe example

# convert to xml, re-format it for no real reason, re-generate the original
# cat time-capsule.snmpwalk | awk -f pc-snmp2xml.awk | xmllint --format - | saxon pc-xml2snmp.xsl > time-capsule.snmpwalk.xml.snmpwalk

# split records on = only

# Use case:
# Process this
# .iso.org.dod.internet.mgmt.mib-2.tcp.tcpConnTable.tcpConnEntry.tcpConnState[10.68.8.251][548][10.68.8.7][51998] = INTEGER: established(5)

# into
# ...
# <tcpConnTable>
# <tcpConnEntry>
# <tcpConnState>
# <value oid="tcpConnState" type="INTEGER" index1="10.68.8.251" index2="548" index3="10.68.8.7" index4="51998" enum="5">established</value>
# </tcpConnState>
# ...

# substitute XML escape sequinces for certain characters
function pc_xml_escape( s ){
	# you need to use \\ to escape the special behavious or & in the replacement string
	#print "[" s ":" length(s) "]"
	gsub( "\\&"	, "\\&amps;"	, s ) # replace & first since the XML escapes use &
	gsub( "\""	, "\\&quot;"	, s ) # remove quotes
	gsub( "<"	, "\\&lt;"	, s )
	gsub( ">"	, "\\&gt;"	, s )
	gsub( "'"	, "\\&apos;"	, s )
	return s
}

# find position of right-most delimiter such that up to this delimiter
# a = b
function pc_find_common( a , b ) {
	if ( a == b ) return length(b)		# all oids matched up to the last delimiter

	f = 1;
	for ( i=1 ; i<=length(b) ; i++ )	# process string b
		if ( substr(b,i,1) == "." )	# delimiter found
			if ( substr(a,1,i) != substr(b,1,i) )
				return f	# done if a and b are different
			else
				f = i		# matched up to this delimiter
	return f	# position of last matching delimiter
}

# split OID string and return the index of the last common delimiter
# eg. .a.b.c.d[10.1.2.3][123] -> .a.b.c.d , 10.1.2.3] , 123]
function pc_get_common_delimiter( this ){
	split( this , thisOIDs_array , "[" )
	split( LAST , lastOIDs_array , "[" )
	return pc_find_common( thisOIDs_array[1] , lastOIDs_array[1] )	# find the last common delimiter
}

# relative to the last line, close the unique elements from the last line
function pc_close_previous_oids( this ){
	k = pc_get_common_delimiter( this )
	# not used: lastCommon = substr( LAST , 1 , k-1 )	# get the common part
	lastUnique = substr( lastOIDs_array[1] , k )			# get unique part of OID - the last k characters
	n = split( lastUnique , oid_array , "." )			# split OID which is in unique
	# close previous normal OID elements
	for ( i=n ; i>=2 ; i-- )				# don't process the first '.'
		# normally the last oid is a number. eg. a.b.c.0
		if ( match( oid_array[i] , "[0-9].*" ) != 1 )		# ignore these numeric oids
			printf "</%s>\n", oid_array[i]
}

# relative to the last line, get the new oids and write out oid elements
function pc_open_new_oids( this ){
	k = pc_get_common_delimiter( this )
	# get just the unique OIDs - ignore the OIDs that are in common with the last line
	unique = substr( thisOIDs_array[1] , k )
	n = split( unique , oid_array , "." )				# make an array of OIDs eg. ( "" , e , f )
	# make normal OID elements
	for ( i=2 ; i<=n ; i++ )				# don't process the leading '.'
		if ( match( oid_array[i] , "[0-9].*" ) != 1 ){	# only process non-numeric OIDs
			printf "<%s>\n", oid_array[i]
			LASTOID = oid_array[i]
		}
}

# if there are indexes, write them as attributes
function pc_write_index_attributes( oid ){
	# split on eg. .a.b.c.d[10.1.2.3][456] -> .a.b.c.d 10.1.2.3] 456]
	c = split( oid , part_array , "[" )

	# write each index attribute
	for ( i=2 ; i<=c ; i++ ){	# ignore the OIDs part
		col = part_array[i]
		gsub( "]" , "" , col )	# remove ]
		printf " index%s=\"%s\"", (i-1), pc_xml_escape( col )
	}
}

# if there are numerical indexes, write them as a single attribute
function pc_write_oid_attribute( oid ){
	# start with .a.b.c.d[1.2][3].0 -> .a.b.c.d.0
	gsub( /\[.*\]/ , "" , oid)	# remove indexes - everything in [ ]
	# split .a.b.c.d.0 -> a b c d 0	
	c = split( oid , part_array , "[.]" )	# OIDs are separated by .

	# build a single value
	oidIndex = ""
	for ( i=1 ; i<=c ; i++ ){
		if ( match( part_array[i] , "[0-9].*" ) == 1 ){ # only process numeric OIDs
			oidIndex = oidIndex "." part_array[i]
		}
	}	
	if ( oidIndex != "" ) printf " oid-index=\"%s\"", oidIndex
}

# write the oid attribute and the index attributes
function pc_write_oid_attributes( oid ){
	pc_write_oid_attribute( oid )
	pc_write_index_attributes( oid )
}

# write an attribute
function pc_write_attribute( att , value ){
	if ( value != "" ) printf " %s=\"%s\"", att, pc_xml_escape( value )
}

# write a copy of the source line with the rule and rule name that processed it
function pc_write_source( rule , ruleName ){
	printf "<source rule=\"%s\" rule-name=\"%s\"><![CDATA[%s]]></source>\n", rule, ruleName, $0
}

# begin a value element tag with the key OID name, OID data type and the raw value before processing
function pc_write_value_open( type , raw ){
	#print "[" raw ":" length(raw) "]"
	printf "<value oid=\"%s\" type=\"%s\" raw=\"%s\"", LASTOID, pc_xml_escape( type ), pc_xml_escape( raw )
}

# close the value element start tag, write a value and close the value element
function pc_write_value( value ){
	printf "><![CDATA[%s]]></value>\n", value
}

# this closes unique elements from the previous line,
# opens new elements for this line
# and saves this line for the next line to be processed
function pc_setup_element( type , ruleName ){
	pc_close_previous_oids( $1 )
	pc_open_new_oids( $1 )
	LAST = $1			# save this OID to work out how many elements to close
	pc_write_source( type , ruleName )	# comment out if you donh't want source elements
}

# for pc_left_of and pc_right_of, the delimiter is a regex so use match instead of index.
# substr can not handle \xff so use sub instead
function pc_left_of( s , d ){
	#p = match( s , d )		# get position of first delimiter
	p = index( s , d )		# get position of first delimiter
	if (p == 0 ) return s
	l = substr( s , 1 , p-1 )	# get left of the delimiter
	return l
}

# this demonstrates that substr does not like \xff characters
# echo "" | awk '{ print substr( "hello\xff" , 1) }' | hexdump

# sub is happy with \xff
# echo "" | awk '{ s="hello\xff" ; sub("hello","",s) ; print s }' | hexdump

function pc_right_of( s , d ){
	#p = match( s , d )		# get position of first delimiter
	p = index( s , d )		# get position of first delimiter
	if (p == 0 ) return ""
	split( "" , c_array , "" )	# blank array
#	print "r[1" s "]" p
	n = split( s , c_array , "" )
	r=""
	for( i=p+length(d) ; i<=n ; i++){
		r=r c_array[i]
#		printf "[%d,%c]", i, c_array[i]
	}
	#l = substr( s , 1 , p+length(d)-1 )	# get delimiter and all to the left
	#sub( l , "" , s )		# cant use substr as it ignores \xff characters
#	print "r[2" r "]"
	return r
}

# close/open elements, write the value, add attributes, and write value
function pc_write_element( rule , ruleName , type , raw , rawOID , attName , attValue , value ){
	#print "[" $0 ":" value "]"
	pc_setup_element( rule , ruleName )
	pc_write_value_open( type , raw )
	pc_write_oid_attributes( rawOID )
	if ( attName != "" ) pc_write_attribute( attName , attValue )
	pc_write_value( value )
}

# all lines have an OID part and a value part
# line = rawOID = rawValue
function pc_decode_common(){
	# added to be able to process newline characters in value field
	#print "$0>" $0
	#print "$1>" $1
	$0	= "." $0	# the new RS consumes the '.' so we add it back
	# NB: ths updates the other field variables too!
	#print "$0=" $0
	#print "$1=" $1
	# FIXME: or redo the code to take this into account
	rawOID	= pc_left_of(	$0 , " = "	)
	rawValue= pc_right_of(	$0 , " = "	)
	#print "rawOID	=" rawOID
	#print "rawValue	=" rawValue
	type	= ""
	data	= rawValue
	#print "type	=" type
	#print "data	=" data
}

# most lines have a type and some sort of data
# value = type: data
function pc_decode_type(){
	pc_decode_common()
	#print "rawOID	=" rawOID
	#print "rawValue	=" rawValue
	#print "type	=" type
	#print "data	=" data
	type	= pc_left_of(	rawValue , ": "	)
	data	= pc_right_of(	rawValue , ": "	)
	#print "rawOID	=" rawOID
	#print "rawValue	=" rawValue
	#print "type	=" type
	#print "data	=" data
}

# some types have numbers in braces
# {data     }
#  ({rawEnum}
#   {enum}) }
function pc_decode_enum(){
	rawEnum	= pc_right_of(	data	, "("	)
	enum	= pc_left_of(	rawEnum	, ")"	)
	#print "rawEnum	=" rawEnum
	#print "enum	=" enum
}

# test awk script to investigate newline processing
# cat s9306.snmpwalk | awk -F"( = )" 'BEGIN{RS="\\."}/^$/{RS="\\n\\.";next}{print "[." $0 "]"; RS="\\n\\."}' | less

BEGIN{
	# FIXME: why was this F?
	FS	= "( = )"				# must set FS here and other variables too
	# added to be able to process newline characters in value field
	RS	= "\\n\\."				# split lines on newline + '.'
	LAST	= ""
	# NB: the first line will keep it '.'
	# these regex variables will get passed twice so double the slashes
	# these are loose to allow minor MIB errors to get through (if any)
	# FIXME: we don't handle BITS well enough I think
	reOID	= "[-a-zA-Z0-9.]+"			# OID name like '.iso.Mib-2.interface'
	reIndex	= "(\\[)[-a-zA-Z0-9_: .]+(\\])"		# like '[10.1.1.1][String: _hello][etc.]..'
	reType	= "[a-zA-Z][-a-zA-Z0-9 ]*"		# SNMP type like 'INTEGER' or 'Network Address'
	reNumber= "-?[0-9]+[\\n\\r]*"			# like -12 or 34
	reLabel	= "[a-zA-Z][-a-zA-Z0-9]*[\\n\\r]*"	# like 'disabled' FIXME: should be a-z
	reEnum	= "[(][0-9]+[)][\\n\\r]*"		# like '(123)'
	reTEnum	= "[(][0-9]+[)]"			# like '(5434123)'
	reUnits	= "[a-zA-Z][-a-zA-Z0-9]*[\\n\\r]*"	# like 'milliseconds'
	reTime	= "[0-9][a-zA-Z0-9:, \\.]*[\\n\\r]*"	# like '7 days, 12:23:12.09' FIXME: other formats?
	reString= ".*"					# any set of characters
	print "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>"
}

# strip leading '.' from the first line
/^\./{
	#print "Strip '.'"
	if( NR == 1 ) sub( /^\./ , "" , $0 )
}

# This could be used to get remove the last OID when using -Cc
# but it would break the test script
#/(It is past the end of the MIB tree)/{
#	next
#}

# this is not required
#/^$/{
#	RS	= "\\n\\."
#	next
#}

# debug each lline
{
	#print "LA:" LAST
	#print "$0:" $0
	#print "$1:" $1
}

( "." $1 == LAST ){ # ignore adjacent duplicate lines - stupid billion
	#print "Duplicate"
	#pc_write_source( "LAST" , $1 ) # comment out if you donh't want source elements
	next
}

# for all rules the following initial line variables are either
# $1 if no = appears (this should not happen)
# $1 = $2

# rule NU - numbers with units eg INTEGER, Counter32, Counter64, Gauge32
# ^.a.b.c.d.0 = Counter32: 123 bits-per-6-seconds$
# {rawOID} = {rawValue              }
#            {type}: {data          }
#                    {number} {units}
$0 ~ "^" reOID "(" reIndex ")*" " = " reType ": " reNumber "( " reUnits ")?" "$"{
	pc_decode_type()
	number	= pc_left_of(	data , " " )
	units	= pc_right_of(	data , " " )
	pc_write_element( "NU" , "numbers with optional units" , type , data , rawOID , "units" , units , number )
	next
}

# rule NE - enumerated values
# ^.a.b.c.d[String: test][123] = INTEGER: meaning-name2(123)$
# {rawOID} = {rawValue            }
#            {type}: {data        }
#                    {name}({enum})
$0 ~ "^" reOID "(" reIndex ")*" " = " reType ": " reLabel reEnum "$"{
	pc_decode_type()
	name	= pc_left_of(	data	, "(" )
	pc_decode_enum()
	pc_write_element( "NE" , "enumerated numbers" , type , data , rawOID , "enum" , enum , name )
	next
}

# rule TT - Timeticks
# ^.a.b.c.d[2][123] = Timeticks: (61234567) 7 days, 12:44:23.21$
# {rawOID} = {rawValue                       }
#            {type=Timeticks}: {data         }
#                              ({enum}) {time}
$0 ~ "^" reOID "(" reIndex ")*" " = Timeticks: " reTEnum " " reTime "$"{
	pc_decode_type()
	pc_decode_enum()
	time	= pc_right_of(	data	, ") "	)
	pc_write_element( "TT" , "timeticks" , type , data , rawOID , "enum" , enum , time )
	next
}

# rule S - STRINGS
# ^.a.b.c.d[2][123] = STRING: any text. or data can go here$
# {rawOID} = {rawValue      }
#            {type}: {data  }
#                    {string}
$0 ~ "^" reOID "(" reIndex ")*" " = " reType ": " reString "$"{
	pc_decode_type()
	string	= data
	#print "[" data "]"
	pc_write_element( "S" , "strings" , type , data , rawOID , "" , "" , string )
	next
}

# rule NT - No Type
# ^.a.b.c.d[2][123] = anything$
# {rawOID} = {rawValue}
#            {data    }
#            {value   }
$0 ~ "^" reOID "(" reIndex ")*" " = " reString "$"{
	pc_decode_common()
	value	= data
	pc_write_element( "NT" , "no type" , type , data , rawOID , "" , "" , value )
	next
}

#rule Z - unprocessed oids
# {rawOID} = {rawValue}
#            {data    }
#            {value   }
{
	pc_decode_common()
	value	= data
	pc_write_element( "Z" , "unprocessed" , type , data , rawOID , "" , "" , value )
	next
}

END{
	pc_close_previous_oids( "" )
}
