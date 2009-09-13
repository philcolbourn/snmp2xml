#!awk

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

# This script converts snmp output like this:

# .iso.org.dod.internet.mgmt.mib-2.host.hrSWRun.hrSWRunTable.hrSWRunEntry.hrSWRunName[4592] = Hex-STRING: 6A 61 76 61 00 00 00 00 00 00 00 00 00 00 00 00 
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
# 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 

# into this:

# .iso.org.dod.internet.mgmt.mib-2.host.hrSWRun.hrSWRunTable.hrSWRunEntry.hrSWRunName[4592] = Hex-STRING: 6A 61 76 61 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 

# where multiple lines of data are converted into a single line by eliminating the new-line characters

# process expected OID lines that start with .
/^(\.).*/{
  if ( FNR > 1 ) printf "\n"	# terminate last OID bu not the first line
  printf "%s", $0		# start this OID but don't write a new-line yet
  next
}

# process other lines that we assume are actually part of previous OID
{
  printf "%s", $0		# continue previous line
}

# terminate the last OID
END{
  printf "\n"			# terminate last OID
}  
