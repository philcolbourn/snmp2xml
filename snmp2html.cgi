#!/usr/bin/perl

use strict;
use warnings;

use CGI::Minimal;

print "Content-type: text/html\n\n";

my $cgi = CGI::Minimal->new;

my $b = "../../svn/snmp2xml";
my $host = $cgi->param('host');
my $community = $cgi->param('community');

my $snmp = `/sw/bin/snmpbulkwalk -v2c -c$community -OXf $host mib-2 | /sw/bin/awk -f $b/snmp2xml-2.awk | $b/saxonb-xquery.sh $b/snmp2html-example.xq`;
print $snmp;
