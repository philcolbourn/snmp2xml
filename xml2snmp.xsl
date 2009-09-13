<?xml version="1.0" encoding="ISO-8859-1"?>

<!--
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
-->

<xsl:stylesheet
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:pc	= "private:pc:xsl:functions"
	version		= "2.0"
>
	<xsl:output method="text" indent="no" encoding="iso-8859-1"/>

	<xsl:function name="pc:full-oid-path">
		<xsl:param name="node"/>
		<xsl:value-of select="	concat( '.' , string-join( for $d in $node return name($d) , '.' ) )	"/>
	</xsl:function>

	<!-- ignore these elements since they should not be in the snmp.xml file anyway -->
	<xsl:template match="text() | comment() | processing-instruction()"/>
	<xsl:template match="source"/>

	<xsl:template match="value">					<!-- just process 'value' elements -->
		<xsl:value-of select="pc:full-oid-path(ancestor::*)"/>	<!-- write OID -->

		<xsl:choose>						<!-- write OID indexes or numerical OIDs -->
		<xsl:when test=" @index1 ">				<!-- re-create .oid[index1][index2]... = type: value -->
			<xsl:for-each select="@*">			<!-- process each attribute -->
				<xsl:if test="starts-with( name() , 'index'  )">	<!-- only process 'index*' attributes -->
					<xsl:value-of select="concat( '[' , string(.) , ']' )"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:when>
		<xsl:otherwise>						<!-- re-create .oid.oid-index = type: value -->
			<xsl:value-of select="string( @oid-index )"/>
		</xsl:otherwise>
		</xsl:choose>

		<xsl:value-of select="string( ' = ' )"/>
		
		<xsl:if test=" @type != '' ">				<!-- if type, write 'type: ' -->
			<xsl:value-of select="concat( @type , ': ' )"/>
		</xsl:if>

		<!-- Timeticks is a special case -->
		<xsl:choose>
		<xsl:when test=" @type = 'Timeticks' ">
			<xsl:value-of select="concat( '(' , string(@enum) , ') ' )"/>
			<xsl:value-of select="text()"/>			<!-- write the value -->
		</xsl:when>
		<xsl:otherwise>
			<xsl:value-of select="text()"/>			<!-- write the value -->
			<xsl:if test=" @enum ">
				<xsl:value-of select="concat( '(' , string(@enum) , ')' )"/>
			</xsl:if>
		</xsl:otherwise>
		</xsl:choose>

		<xsl:if test=" @units != '' ">				<!-- write units -->
			<xsl:value-of select="concat( ' ' , string(@units) )"/>
		</xsl:if>

		<xsl:value-of select="concat( '&#10;' , '' )"/>
	</xsl:template>

	<xsl:template match="*">
		<xsl:apply-templates/>
	</xsl:template>

</xsl:stylesheet>
