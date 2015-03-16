# HTML Table Headings #

HTML headings are generally written like this:

```
<table border="1">
  <tr>
    <th>ID</th>
    <th>MAC Address</th>
  </tr>
</table>
```

which produces something like this:

<table border='1'>
<blockquote><tr>
<blockquote><th>ID</th>
<th>MAC Address</th>
</blockquote></tr>
</table></blockquote>

But sometimes you want a multi-line heading so the table columns are not too wide. To do this you might write something like this:

```
<table border="1">
  <tr>
    <th>ID</th>
    <th>MAC</th>
  </tr>
  <tr>
    <th></th>
    <th>Address</th>
  </tr>
</table>
```

which produces something like this:

<table border='1'>
<blockquote><tr>
<blockquote><th>ID</th>
<th>MAC</th>
</blockquote></tr>
<tr>
<blockquote><th></th>
<th>Address</th>
</blockquote></tr>
</table></blockquote>

or you might prefer this:

```
<table border="1">
  <tr>
    <th rowspan="2">ID</th>
    <th>MAC</th>
  </tr>
  <tr>
    <th>Address</th>
  </tr>
</table>
```

which produces something like this:

<table border='1'>
<blockquote><tr>
<blockquote><th>ID</th>
<th>MAC</th>
</blockquote></tr>
<tr>
<blockquote><th>Address</th>
</blockquote></tr>
</table></blockquote>

# An Easier Way #

While working on the `SNMP2HTML` XQuery example I experimented with developing a function to generate nice looking table headings using XQuery. The technique could easily be ported to any web scripting language if desired.

## How It Works ##

The idea is to describe the column headings as a list using a simple syntax. In the list each column heading is an element and each element consists of rows separated by `'-'` and each row is divided into columns with a `'|'`. These delimiters could be changed to suit specific needs.

### Example ###

```
local:pc-make-table-headings( ( 'Route','Mask','Type','Next-Hop','If','If-Offset','Interface','MAC-Address','MTU-Bytes','Speed-Mbps','
Octets-In|Out-MBytes|MBytes','State-Admin|Oper' ) )
```

This generates the following table heading rows:

<table border='1'>
<blockquote><tr>
<blockquote><th>Route</th>
<th>Mask</th>
<th>Type</th>
<th>Next</th>
<th>If</th>
<th>If</th>
<th>Interface</th>
<th>MAC</th>
<th>MTU</th>
<th>Speed</th>
<th>Octets</th>
<th>State</th>
</blockquote></tr>
<tr>
<blockquote><th>In</th>
<th>Out</th>
</blockquote></tr>
<tr>
<blockquote><th>Hop</th>
<th>Offset</th>
<th>Address</th>
<th>Bytes</th>
<th>Mbps</th>
<th>MBytes</th>
<th>MBytes</th>
<th>Admin</th>
<th>Oper</th>
</blockquote></tr>
</table></blockquote>

I hope you agree that the headings look good and that it is far easier to make well laid-out headings.

# The Code #

The code is included as an XQuery function in `snmp2html-example.xq` and listed below:

```
declare function local:pc-make-table-headings( $headings ){
        let $maxRows    := max( for $h in $headings                             return count( tokenize($h, '-') ) )     (: determine most rows :)
        let $maxCols    := max( for $h in $headings, $r in tokenize($h,'-')     return count( tokenize($r,'\|') ) )     (: determine most columns :) 

        for $row in 1 to $maxRows                                                                               (: step through each row :)
        return
        <tr row="{ $row }">
                {
                for $h in $headings                                                                             (: for each heading :)
                        let $rows       := count( tokenize($h,'-') )                                            (: determine rows :)
                        let $maxCols    := max( for $r in tokenize($h,'-') return count( tokenize($r,'\|') ) )  (: determine most columns for this heading :) 
                        let $base       := $maxRows idiv $rows                                                  (: calc min rowspan :)
                        let $rem        := $maxRows mod $rows                                                   (: keep remainder :)
                        (:      start at heading index 1                                                        :)
                        (:      heading index increments at a slower rate                                       :)
                        (:      the rate is the number of heading rows for this column / maximum heading rows   :)
                        let $this       := 1 + floor( ($row - 1) * ($rows div $maxRows) )                       (: increment heading row at a rate that matches 
the  :)
                        let $last       := 1 + floor( ($row - 2) * ($rows div $maxRows) )
                        let $r          := tokenize($h,'-')[ $this ]                                            (: get the heading for this row :)
                        let $cols       := count( tokenize($r,'\|') )                                           (: determine columns :)
                        let $rowSpan    := $base + (if( $this <= $rem ) then 1 else 0)                          (: rowspan is the base plus 1 for the top rows :
)
                        let $colSpan    := $maxCols div $cols                                                   (: FIXME: may not work for 3 div 2 for example :
)
                        for $c in tokenize($r,'\|')                                                             (: split row into columns :)
                        return
                                if( $this != $last ) then                                                       (: if the heading index different to the
 last one :)
                <th rowspan="{ $rowSpan }" colspan="{ $colSpan }">{ $c }</th>                                   (: output column heading:)
                                else ()
                }
        </tr>
};


```