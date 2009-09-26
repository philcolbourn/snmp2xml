xquery version "1.0";
declare namespace pc = "private:pc:data";
declare variable $doc	:= doc('/dev/stdin');

declare function local:pc-make-table-headings( $headings ){
	let $maxRows	:= max( for $h in $headings				return count( tokenize($h, '-') ) )	(: determine most rows :)
	let $maxCols	:= max( for $h in $headings, $r in tokenize($h,'-')	return count( tokenize($r,'\|') ) )	(: determine most columns :) 

	for $row in 1 to $maxRows										(: step through each row :)
	return
	<tr row="{ $row }">
		{
		for $h in $headings										(: for each heading :)
			let $rows	:= count( tokenize($h,'-') )						(: determine rows :)
			let $maxCols	:= max( for $r in tokenize($h,'-') return count( tokenize($r,'\|') ) )	(: determine most columns for this heading :) 
			let $base	:= $maxRows idiv $rows							(: calc min rowspan :)
			let $rem	:= $maxRows mod $rows							(: keep remainder :)
			(:	start at heading index 1							:)
			(:	heading index increments at a slower rate					:)
			(:	the rate is the number of heading rows for this column / maximum heading rows	:)
			let $this	:= 1 + floor( ($row - 1) * ($rows div $maxRows) )			(: increment heading row at a rate that matches the  :)
			let $last	:= 1 + floor( ($row - 2) * ($rows div $maxRows) )
			let $r		:= tokenize($h,'-')[ $this ]						(: get the heading for this row :)
			let $cols	:= count( tokenize($r,'\|') )						(: determine columns :)
			let $rowSpan	:= $base + (if( $this <= $rem ) then 1 else 0)				(: rowspan is the base plus 1 for the top rows :)
			let $colSpan	:= $maxCols div $cols							(: FIXME: may not work for 3 div 2 for example :)
			for $c in tokenize($r,'\|')								(: split row into columns :)
			return
				if( $this != $last ) then								(: if the heading index different to the last one :)
		<th rowspan="{ $rowSpan }" colspan="{ $colSpan }">{ $c }</th>					(: output column heading:)
				else ()
		}
	</tr>
};

(: NOTE: can not easily put all parameters into the fn attrubute :)

(: add attributes to current element :)
(: '"' can not appear in attribute values so they can be used as delimiters :)
(: WARNING: this assumes that attribute statements are space separated :)

declare function local:make-attributes( $att ){
	for $a in tokenize( $att , '["]\s+' )						(: for each attribute - split on quote space :)
		let $rawname	:= substring-before( $a , '=' )				(: get raw name before the '=' :)
		let $rawvalue	:= substring-after( $a , '=' )				(: get raw value after '=' :)
		let $name	:= replace( $rawname	, '\s'			, '' )	(: remove spaces :)
		let $value	:= replace( $rawvalue	, '^\s*["]|["]$'	, '' )	(: remove leading space and surrounding quotes :)
	return attribute {$name} {$value}
};

(: make a td element from an actual value :)
(: eg 10 returns <td>10</td> :)

declare function local:td( $att , $value ){
	<td fn="local:td(a,v)">
		{ local:make-attributes( $att ) }
		{ $value }
	</td>
};

(: make a td element from an attribute of an element :)
(: eg <element a="10">20</element> returns <td>10</td> :)

declare function local:td-att( $att , $element , $attName ){
	<td fn="local:td-att(a,e,{$attName})">
		{ local:make-attributes( $att ) }
		{ string( $element/@*[ local-name() = $attName ] ) }
	</td>
};

(: make a td element from the text of a value element :)
(: eg <base><value a="10">20</value></base> returns <td>20</td> :)

declare function local:td-value( $att , $base ){
	<td fn="local:td-value(b)">
		{ local:make-attributes( $att ) }
		{ $base/value/text() }
	</td>
};

(: make a td element from the text of a value element of a child element :)
(: eg <base><child><value a="10">20</value></child></base> returns <td>20</td> :)

declare function local:td-child-value( $att , $base , $child ){
	<td fn="local:td-child-value(a,b,{$child})">
		{ local:make-attributes( $att ) }
		{ $base/*[ local-name() = $child ]/value/text() }
	</td>
};

(: make a td element from an oid attribute of a value element :)
(: eg <value oid="ifIndex">20</value> returns <td>10</td> :)

declare function local:td-oid( $att , $base , $oid ){
	let $d := $base[ @oid = $oid ]/text()
	return
		<td fn="td-att-oid(a,b,{$oid})">
			{ local:make-attributes( $att ) }
			{ $d }
		</td>
};

declare function local:td-oid-scale( $att , $base , $oid , $scale ){
	let $d := $base[ @oid = $oid ]/text() idiv $scale
	return
		<td fn="td-oid-scale(a,b,{$oid},{$scale})">
			{ local:make-attributes( $att ) }
			{ $d }
		</td>
};

(: CSV versions of the td functions :)
(: these take a comma separated list of names or values and return multiple td elements :)

declare function local:td-oidCSV( $att , $base , $oidCSV ){
	for $oid in tokenize( $oidCSV , ',' )
	return
		local:td-oid( $att , $base , $oid )
};

declare function local:td-attCSV( $att , $base , $attNameCSV ){
	for $attName in tokenize( $attNameCSV , ',' )
	return
		local:td-att( $att , $base , $attName )
};

declare function local:td-childCSV-value( $att , $base , $childCSV ){
	for $child in tokenize( $childCSV , ',' )
	return
		local:td-child-value( $att , $base , $child )
};

declare function local:td-oidCSV-scale( $att , $base , $oidCSV , $scale ){
	for $oid in tokenize( $oidCSV , ',' )
	return
		local:td-oid-scale( $att , $base , $oid , $scale )
};

(: some SNMP agents provide wrong ipRouteIfIndex values	:)
(: return the ip MIB ifIndex offset to the interfaces MIB ifIndex :)
declare function local:get-offset(){
	let $rt		:= $doc//ip/ipRouteTable/ipRouteEntry						(: all of the routing table entries :)
	let $it		:= $doc//interfaces/ifTable/ifEntry						(: all of the interface entries :)

	let $ipIndex	:= $rt/ipRouteIfIndex/value	[ @index1	= '127.0.0.1'	]		(: get the interface used for loopback route :)
	let $loIndex	:= $it/ifType/value		[ @enum		= '24'		]/@index1	(: get the loopback interfce :)
	let $offset	:= number($ipIndex) - number($loIndex)						(: the difference is the offset :)
	return $offset
};

declare function local:class( $name ){
	concat( 'class="' , $name , '"' )
};


<html>
	<head>
		<title>Routing Table</title>
		<link rel="stylesheet" type="text/css" href="snmp2xml.css" />

	</head>
	<body>
		<h1>{ $doc//sysDescr/value/text() }</h1>
		<h2>Routing Table</h2>
		<table border="1">
			{ local:pc-make-table-headings( ( 'Route','Mask','Type','Next-Hop','If','If-Offset','Interface','MAC-Address','MTU-Bytes','Speed-Mbps','Octets-In|Out-MBytes|MBytes','State-Admin|Oper' ) ) }
			{
			let $rt			:= $doc//ip/ipRouteTable/ipRouteEntry						(: all of the routing table entries :)
			let $it			:= $doc//interfaces/ifTable/ifEntry						(: all of the interface entries :)
			let $offset		:= local:get-offset()

			for $rIndex at $row in $rt/ipRouteDest/value/text()							(: for each route destination :)
				let $r			:= $rt//value	[ @index1	= $rIndex		]		(: get all the details for this route :)
				let $ifIndex		:= $r		[ @oid		= 'ipRouteIfIndex'	]/text()	(: get the route interface :)
				let $iIndex		:= string( number($ifIndex) - $offset )					(: adjust it if required :)
				let $if			:= $it//value	[ @index1	= $iIndex		]		(: get all the interface details for this route :)
				let $ifAdminStatus	:= $if		[ @oid		= 'ifAdminStatus'	]/text()
				let $ifOperStatus	:= $if		[ @oid		= 'ifOperStatus'	]/text()
				let $offsetColor	:= concat( 'style="color:' , if($offset=0) then '#009000' else '#900000' , '"' )
			return
			<tr class="{ if(($row mod 2) = 0) then 'even' else 'odd' }">
				{(
				local:td( 		''				, $rIndex )
				,local:td-oidCSV(	''				, $r 		, 'ipRouteMask,ipRouteType,ipRouteNextHop' )
				,local:td(		''				, $ifIndex )
				,local:td(		$offsetColor			, $offset )
				,local:td-oidCSV( 	''				, $if 		, 'ifDescr,ifPhysAddress,ifMtu' )
				,local:td-oidCSV-scale(	''				, $if 		, 'ifSpeed,ifInOctets,ifOutOctets' , 1000000 )
				,local:td(		local:class( $ifAdminStatus )	, $ifAdminStatus )
				,local:td(		local:class( $ifOperStatus )	, $ifOperStatus )
				)}
			</tr>
			}
		</table>

		<br/>

		<h2>Interfaces</h2>
		<table border="1">
			<!-- WARNING: without tr, &#10; works as a newline character in th headings. with tr it becomes a space in th headings! -->
			{ local:pc-make-table-headings( ( 'Index','Interface-Offset','Descr','Type','MAC-Address','MTU-Bytes','Speed-Mbps','Octets-In|Out-MBytes|MBytes','State-Admin|Oper','Routes' ) ) }
			{
			let $rt			:= $doc//ip/ipRouteTable/ipRouteEntry
			let $it			:= $doc//interfaces/ifTable/ifEntry 
			let $offset		:= local:get-offset()

			for $ifIndex at $row in $it/ifIndex/value/text()									(: for each interface :)
				let $rIndex		:= string( number($ifIndex) + $offset )
				let $if			:= $it//value			[ @index1	= $ifIndex		]		(: get all values for this interface :) 
				let $r			:= $rt/ipRouteIfIndex/value	[ text()	= $rIndex		]/@index1	(: ? :)
				let $ifAdminStatus	:= $if				[ @oid		= 'ifAdminStatus'	]/text()
				let $ifOperStatus	:= $if				[ @oid		= 'ifOperStatus'	]/text()
				let $offsetColor	:= concat( 'style="color:' , if($offset=0) then '#009000' else '#900000' , '"' )
				let $routes		:= for $d in $r return ( string($d) , <br/> )
			return
			<tr class="{ if(($row mod 2) = 0) then 'even' else 'odd' }">
				{(
				local:td(		''				, $ifIndex )
				,local:td(		$offsetColor			, $offset )
				,local:td-oidCSV(	''				, $if			, 'ifDescr,ifType,ifPhysAddress,ifMtu' )
				,local:td-oidCSV-scale(	''				, $if			, 'ifSpeed,ifInOctets,ifOutOctets'	, 1000000 )
				,local:td(		local:class( $ifAdminStatus )	, $ifAdminStatus )
				,local:td(		local:class( $ifOperStatus )	, $ifOperStatus )
				,local:td(		''				, $routes )
				)}	
			</tr>
			} 
		</table>

		<br/>

		<h2>Interfaces Stats</h2>
		<table border="1">
			{ local:pc-make-table-headings( ( 'Index','Descr','Type','Speed-Mbps','Octets-In|Out-MBytes|MBytes','Unicasts-In|Out','Non-Unicasts-In|Out','Discards-In|Out','Errors-In|Out','Protocol-Unknown-In','Queue-Length-Out' ) ) }
			{
			let $it		:= $doc//interfaces/ifTable/ifEntry				(:  :)
			let $red	:= 'style="color:#900000"'
			for $ifIndex at $row in $it/ifIndex/value/text()				(: for each interface :)
				let $if	:= $it//value	[ @index1 = $ifIndex ]				(: get all the entries for this interface :)
			return
			<tr class="{ if(($row mod 2) = 0) then 'even' else 'odd' }">
				{(
				local:td(		''	, $ifIndex )
				,local:td-oidCSV(	''	, $if		, 'ifDescr,ifType' )
				,local:td-oidCSV-scale(	''	, $if		, 'ifSpeed,ifInOctets,ifOutOctets,ifInUcastPkts,ifOutUcastPkts,ifInNUcastPkts,ifOutNUcastPkts'	, 1000000 )
				,local:td-oidCSV(	$red	, $if		, 'ifInDiscards,ifOutDiscards,ifInErrors,ifOutErrors' )
				,local:td-oidCSV(	''	, $if		, 'ifInUnknownProtos,ifOutQLen' )
				)}
			</tr>
			} 
		</table>

		<br/>

		<table border="0" style="width:100%; background-color: white;">		<!-- split into two columns -->
			<tr>
				<td valign="top">
					<h2>TCP Connection Table</h2>
					<table border="1">
						{ local:pc-make-table-headings( ( 'Local-IP|Port' , 'Remote-IP|Port' , 'State' ) ) }
						{
						let $tcp	:= $doc//tcp/tcpConnTable/tcpConnEntry
						for $tcpConnState at $row in $tcp/tcpConnState/value
						return
						<tr class="{ if(($row mod 2) = 0) then 'even' else 'odd' }">
							{(
							local:td-attCSV(	''	, $tcpConnState	, 'index1,index2,index3,index4' )
							,local:td(		''	, $tcpConnState/text() )
							)}
						</tr>
						} 
					</table>

					<h2>SNMP Statistics</h2>
					<table border="1">
						{ local:pc-make-table-headings( ( 'Packets-In|Out' , 'Requests-In' , 'Get-Nexts|Responses-In|Out' ) ) }
						<tr class="odd">
							{
							local:td-childCSV-value( '' , $doc//snmp , 'snmpInPkts,snmpOutPkts,snmpInTotalReqVars,snmpInGetNexts,snmpOutGetResponses' )
							}
						</tr>
					</table>

					<h2>IP Media Table</h2>
					<table border="1">
						{ local:pc-make-table-headings( ( 'Interface' , 'MAC-Address' , 'IP Address' , 'Media-Type' , 'Current-Connections' ) ) }
						{
						let $ipNet	:= $doc//ipNetToMediaTable/ipNetToMediaEntry					(: get all the media table entries :)
						let $tcp	:= $doc//tcp/tcpConnTable/tcpConnEntry
						let $offset	:= local:get-offset()

						for $ip at $row in $ipNet/ipNetToMediaNetAddress/value/text()					(: for each ip address :)
							let $e		:= $ipNet//value	[ @index2 = $ip ]				(: get the OIDs for each entry :)
							let $iIndex	:= string( number( $e[ @oid = 'ipNetToMediaIfIndex' ] ) - $offset )	(: adjust it if required :)
						return
						<tr class="{ if(($row mod 2) = 0) then 'even' else 'odd' }">				<!-- shade row -->
							{(
							local:td( 		''	, $iIndex )
							,local:td-oidCSV( 	''	, $e	, 'ipNetToMediaPhysAddress' )
							,local:td(		''	, $ip )
							,local:td-oidCSV(	''	, $e	, 'ipNetToMediaType' )
							)}
							<td>
							{
							if( $tcp/tcpConnState/value[ @index3 = $ip ] ) then
							<table border="1">
								{ local:pc-make-table-headings( ( 'Local-IP|Port' , 'Remote-Port' , 'Status' ) ) }
								{
								for $tcpConnState at $row in $tcp/tcpConnState/value[ @index3 = $ip ]
								return
								<tr class="{ if(($row mod 2) = 0) then 'even' else 'odd' }">
									{(
									local:td-attCSV(	''	, $tcpConnState		, 'index1,index2,index4' )
									,local:td(		''	, $tcpConnState/text() )
									)}
								</tr>
								} 
							</table>
							else ()
							}
							</td>
						</tr>
						} 
					</table>

					<h2>UDP Statistics</h2>
					<table border="1">
						{ local:pc-make-table-headings( ( 'Datagrams-In|Out' , 'No-Ports' , 'Errors-In' ) ) }
						<tr class="odd">
							{
							local:td-childCSV-value( '' , $doc//udp , 'udpInDatagrams,udpOutDatagrams,udpNoPorts,udpInErrors' )
							}
						</tr>
					</table>

					<h2>TCP Statistics</h2>
					<table border="1">
						{ local:pc-make-table-headings( ( 'Segments-In|Out' , 'Retrans' , 'Errors-In' , 'RTO-Algorithm|Min|Max' , 'Opens-Active|Passive' , 'Attempt-Fails' , 'Estab-Resets' , 'Rsts-Out' ) ) }
						<tr class="odd">
							{
							local:td-childCSV-value( '' , $doc//tcp , 'tcpInSegs,tcpOutSegs,tcpRetransSegs,tcpInErrs,tcpRtoAlgorithm,tcpRtoMin,tcpRtoMax,tcpActiveOpens,tcpPassiveOpens,tcpAttemptFails,tcpEstabResets,tcpOutRsts' )
							}
						</tr>
					</table>
				</td>
				<td valign="top">

					<h2>UDP Open Ports</h2>
					<table border="1">
						{ local:pc-make-table-headings( ( 'Local-IP|Port' ) ) }
						{
						let $udp	:= $doc//udp/udpTable/udpEntry
						for $udpLocalAddress at $row in $udp/udpLocalAddress/value
						return
						<tr class="{ if(($row mod 2) = 0) then 'even' else 'odd' }">
							{(
							local:td(	''	, $udpLocalAddress/text() )
							,local:td(	''	, string( $udpLocalAddress/@index2 ) )
							)}
						</tr>
						} 
					</table>
				</td>
			</tr>
		</table>
	</body>
</html>
