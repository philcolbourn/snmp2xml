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

# This script simplifies the execution of saxon XQuery 

SAXON_HOME=/Applications/saxonsa9-1-0-6j/saxon9.jar
java -cp $SAXON_HOME net.sf.saxon.Query $@
