xquery version "1.0";
declare namespace pc = "private:pc:data";
declare variable $doc	:= doc('/dev/stdin');

<html>
	<head>
		<title>Routing Table</title>
		<link rel="stylesheet" type="text/css" href="snmp2xml.css" />

	</head>
	<body>
		<h1>{$doc//sysDescr/value/text()}</h1>
		<h2>Routing Table</h2>
		<table border="1">
			<thead>
			<tr>
				<th>Route	</th>
				<th>Mask	</th>
				<th>Type	</th>
				<th>Next Hop	</th>
				<th>If	</th>
				<th>Offset	</th>
				<th>Interface	</th>
				<th>MAC	</th>
				<th>MTU<br/>Bytes	</th>
				<th>Speed<br/>Mbps	</th>
				<th>In Octets<br/>MBytes	</th>
				<th>Out Octets<br/>MBytes	</th>
				<th>Admin	</th>
				<th>Oper	</th>
			</tr>
			</thead>
			<tbody>
			{
			let $rt		:= $doc//ip/ipRouteTable/ipRouteEntry
			let $it		:= $doc//interfaces/ifTable/ifEntry 
			(: some SNMP agents provide wrong ipRouteIfIndex values :)
			(: determine ip interface offset :)
			let $ipIndex		:= $rt/ipRouteIfIndex/value[ @index1 = '127.0.0.1' ]
			let $loIndex		:= $it/ifType/value[ @enum = '24' ]/@index1
			let $offset		:= number($ipIndex) - number($loIndex)

			for $rIndex at $row in $rt/ipRouteDest/value/text()
			let $r			:= $rt//value[	@index1 = $rIndex	]
			let $ifIndex		:= $r[ @oid = 'ipRouteIfIndex' ]/text()
			let $if			:= $it//value[	@index1 = string( number($ifIndex) - $offset )	] 
			let $ifAdminStatus	:= $if[	@oid = 'ifAdminStatus'	]/text()
			let $ifOperStatus	:= $if[	@oid = 'ifOperStatus'	]/text()
			return
			<tr class="{if(($row mod 2) = 0) then "even" else "odd"}">
				<td>{$rIndex}</td>
				<td>{$r[	@oid = 'ipRouteMask'	]/text()}</td>
				<td>{$r[	@oid = 'ipRouteType'	]/text()}</td>
				<td>{$r[	@oid = 'ipRouteNextHop'	]/text()}</td>
				<td>{$ifIndex}</td>
				<td style="color:{if($offset = 0) then 'palegreen' else 'pink'};">{$offset}</td>
				<td>{$if[	@oid = 'ifDescr'	]/text()}</td>
				<td>{$if[	@oid = 'ifPhysAddress'	]/text()}</td>
				<td>{$if[	@oid = 'ifMtu'		]/text()}</td>
				<td>{$if[	@oid = 'ifSpeed' 	]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifInOctets'	]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifOutOctets'	]/text() idiv 1000000}</td>
				<td class="{ $ifAdminStatus	}">{$ifAdminStatus}</td>
				<td class="{ $ifOperStatus	}">{$ifOperStatus}</td>
			</tr>
			}
			</tbody> 
		</table>

		<br/>
		<h2>Interfaces</h2>
		<table border="1">
			<tr>
				<th>Index	</th>
				<th>Interface<br/>Offset	</th>
				<th>Descr	</th>
				<th>Type	</th>
				<th>MAC		</th>
				<th>MTU<br/>Bytes	</th>
				<th>Speed<br/>Mbps	</th>
				<th>In Octets<br/>MBytes	</th>
				<th>Out Octets<br/>MBytes	</th>
				<th>Admin	</th>
				<th>Oper	</th>
				<th>Routes	</th>
			</tr>
			{
			let $rt	:= $doc//ip/ipRouteTable/ipRouteEntry
			let $it	:= $doc//interfaces/ifTable/ifEntry 
			(: determine ip interface offset :)
			let $ipIndex		:= $rt/ipRouteIfIndex/value[ @index1 = '127.0.0.1' ]
			let $loIndex		:= $it/ifType/value[ @enum = '24' ]/@index1
			let $offset		:= number($ipIndex) - number($loIndex)

			for $ifIndex at $row in $it/ifIndex/value/text()
			let $if		:= $it//value[	@index1 = $ifIndex	] 
			let $r		:= $rt/ipRouteIfIndex/value[ text() = string( number($ifIndex) + $offset ) ]/@index1
			let $ifAdminStatus	:= $if[	@oid = 'ifAdminStatus'	]/text()
			let $ifOperStatus	:= $if[	@oid = 'ifOperStatus'	]/text()
			return
			<tr class="{if(($row mod 2) = 0) then "even" else "odd"}">
				<td>{$ifIndex}</td>
				<td style="color:{if($offset = 0) then 'palegreen' else 'pink'};">{$offset}</td>
				<td>{$if[	@oid = 'ifDescr'		]/text()}</td>
				<td>{$if[	@oid = 'ifType'			]/text()}</td>
				<td>{$if[	@oid = 'ifPhysAddress'		]/text()}</td>
				<td>{$if[	@oid = 'ifMtu'			]/text()}</td>
				<td>{$if[	@oid = 'ifSpeed' 		]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifInOctets'		]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifOutOctets'		]/text() idiv 1000000}</td>
				<td style="background-color:{if($ifAdminStatus = 'up') then 'palegreen' else 'pink'};">{$ifAdminStatus}</td>
				<td style="background-color:{if($ifOperStatus = 'up') then 'palereen' else 'pink'};">{$ifOperStatus}</td>
				<td>
				{
				for $d in $r
				return
					(string($d),<br/>)
				}
				</td>
			</tr>
			} 
		</table>

		<br/>
		<h2>Interfaces Stats</h2>
		<table border="1">
			<tr>
				<th>Index</th>
				<th>Descr</th>
				<th>Type</th>
				<th>Speed<br/>Mbps</th>
				<th>In Oct<br/>MBytes</th>
				<th>Out Oct<br/>MBytes</th>
				<th>In UC</th>
				<th>Out UC</th>
				<th>In Non-UC</th>
				<th>Out Non-UC</th>
				<th>In Dis</th>
				<th>Out Dis</th>
				<th>In Err</th>
				<th>Out Err</th>
				<th>In Proto<br/>Unknown</th>
				<th>Out QLen</th>
			</tr>
			{
			let $it	:= $doc//interfaces/ifTable/ifEntry 
			for $ifIndex at $row in $it/ifIndex/value/text()
			let $if		:= $it//value[	@index1 = $ifIndex	] 
			return
			<tr class="{if(($row mod 2) = 0) then "even" else "odd"}">
				<td>{$ifIndex}</td>
				<td>{$if[	@oid = 'ifDescr'		]/text()}</td>
				<td>{$if[	@oid = 'ifType'			]/text()}</td>
				<td>{$if[	@oid = 'ifSpeed' 		]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifInOctets'		]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifOutOctets'		]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifInUcastPkts'		]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifOutUcastPkts'		]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifInNUcastPkts'		]/text() idiv 1000000}</td>
				<td>{$if[	@oid = 'ifOutNUcastPkts'	]/text() idiv 1000000}</td>
				<td style="background-color:pink">{$if[	@oid = 'ifInDiscards'	]/text()}</td>
				<td style="background-color:pink">{$if[	@oid = 'ifOutDiscards'	]/text()}</td>
				<td style="background-color:pink">{$if[	@oid = 'ifInErrors'	]/text()}</td>
				<td style="background-color:pink">{$if[	@oid = 'ifOutErrors'	]/text()}</td>
				<td>{$if[	@oid = 'ifInUnknownProtos'	]/text()}</td>
				<td>{$if[	@oid = 'ifOutQLen'		]/text()}</td>
			</tr>
			} 
		</table>

		<br/>
		<table border="0" style="width:100%; background-color: white;">
		<tr>
		<td valign="top">
		<h2>TCP Connection Table</h2>
		<table border="1">
			<tr>
				<th>Local IP	</th>
				<th>Local Port	</th>
				<th>Remote IP	</th>
				<th>Remote Port	</th>
				<th>State	</th>
			</tr>
			{
			let $tcp	:= $doc//tcp/tcpConnTable/tcpConnEntry 
			for $tcpConnState at $row in $tcp/tcpConnState/value
			return
			<tr class="{if(($row mod 2) = 0) then "even" else "odd"}">
				<td>{string(	$tcpConnState/@index1 )}</td>
				<td>{string(	$tcpConnState/@index2 )}</td>
				<td>{string(	$tcpConnState/@index3 )}</td>
				<td>{string(	$tcpConnState/@index4 )}</td>
				<td>{		$tcpConnState/text()	}</td>
			</tr>
			} 
		</table>

		<h2>SNMP Statistics</h2>
		<table border="1">
			<tr>
				<th>In Packets	</th>
				<th>Out Packets	</th>
				<th>In Requests	</th>
				<th>In Get Nexts	</th>
				<th>Out Get Responses	</th>
			</tr>
			{
			let $snmp	:= $doc//snmp 
			return
			<tr class="odd">
				<td>{ $snmp/snmpInPkts/value		}</td>
				<td>{ $snmp/snmpOutPkts/value		}</td>
				<td>{ $snmp/snmpInTotalReqVars/value	}</td>
				<td>{ $snmp/snmpInGetNexts/value	}</td>
				<td>{ $snmp/snmpOutGetResponses/value	}</td>
			</tr>
			} 
		</table>

		<h2>UDP Statistics</h2>
		<table border="1">
			<tr>
				<th>In DGrams	</th>
				<th>Out DGrams	</th>
				<th>No Ports	</th>
				<th>In Errors	</th>
			</tr>
			{
			let $udp	:= $doc//udp 
			return
			<tr class="odd">
				<td>{ $udp/udpInDatagrams/value		}</td>
				<td>{ $udp/udpOutDatagrams/value	}</td>
				<td>{ $udp/udpNoPorts/value		}</td>
				<td>{ $udp/udpInErrors/value		}</td>
			</tr>
			} 
		</table>
		<h2>TCP Statistics</h2>
		<table border="1">
			<tr>
				<th>In Segments		</th>
				<th>Out Segments	</th>
				<th>Retrans		</th>
				<th>In Errors		</th>
				<th>RTO Algorithm	</th>
				<th>RTO Min		</th>
				<th>RTO Max		</th>
				<th>Active Opens	</th>
				<th>Passive Opens	</th>
				<th>Attempt Fails	</th>
				<th>Estab Resets	</th>
				<th>Out Rsts		</th>
			</tr>
			{
			let $tcp	:= $doc//tcp 
			return
			<tr class="odd">
				<td>{ $tcp/tcpInSegs/value		}</td>
				<td>{ $tcp/tcpOutSegs/value		}</td>
				<td>{ $tcp/tcpRetransSegs/value		}</td>
				<td>{ $tcp/tcpInErrs/value		}</td>
				<td>{ $tcp/tcpRtoAlgorithm/value	}</td>
				<td>{ $tcp/tcpRtoMin/value		}</td>
				<td>{ $tcp/tcpRtoMax/value		}</td>
				<td>{ $tcp/tcpActiveOpens/value		}</td>
				<td>{ $tcp/tcpPassiveOpens/value	}</td>
				<td>{ $tcp/tcpAttemptFails/value	}</td>
				<td>{ $tcp/tcpEstabResets/value		}</td>
				<td>{ $tcp/tcpOutRsts/value		}</td>
			</tr>
			} 
		</table>

		</td>

		<td valign="top">
		<h2>UDP Open Ports</h2>
		<table border="1">
			<tr>
				<th>Local IP	</th>
				<th>Local Port	</th>
			</tr>
			{
			let $udp	:= $doc//udp/udpTable/udpEntry 
			for $udpLocalAddress at $row in $udp/udpLocalAddress/value
			return
			<tr class="{if(($row mod 2) = 0) then "even" else "odd"}">
				<td>{		$udpLocalAddress		}</td>
				<td>{string(	$udpLocalAddress/@index2 )	}</td>
			</tr>
			} 
		</table>
		</td>
		</tr>
		</table>
	</body>
</html>
