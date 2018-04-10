$data = @'
Loc.USN                           Originating DSA  Org.USN  Org.Time/Date        Ver Attribute
=======                           =============== ========= =============        === =========
   {[int]LocalUSN*:8201} {OrigDSA:9dea5320-9c83-4838-bbb6-fca0ca93f752}  {[int]OrigUSN:8196} {[datetime]OrigTime:2016-10-18 12:47:42} {[int]Version:1} {[string]Attribute:objectClass}
   {[int]LocalUSN*:8201} {OrigDSA:Default-First-Site-Name\TOR-DC1}       {[int]OrigUSN:8201} {[datetime]OrigTime:2018-04-09 23:11:54} {[int]Version:1} {[string]Attribute:cn}
   {[int]LocalUSN*:8201} {OrigDSA:9dea5320-9c83-4838-bbb6-fca0ca93f752}  {[int]OrigUSN:8196} {[datetime]OrigTime:2016-10-18 12:47:42} {[int]Version:1} {[string]Attribute:description}
   {[int]LocalUSN*:8201} {OrigDSA:9dea5320-9c83-4838-bbb6-fca0ca93f752}  {[int]OrigUSN:8196} {[datetime]OrigTime:2016-10-18 12:47:42} {[int]Version:2} {[string]Attribute:descriptionA}
   {[int]LocalUSN*:1234} {OrigDSA:9dea5320-9c83-4838-bbb6-fca0ca93f752}  {[int]OrigUSN:345}  {[datetime]OrigTime:2016-10-18 12:47:42} {[int]Version:3} {[string]Attribute:descriptionB}
0 entries.
Type    Attribute     Last Mod Time                            Originating DSA  Loc.USN Org.USN Ver
======= ============  =============                           ================= ======= ======= ===
        Distinguished Name
        =============================
'@

$RepAdminRaw = repadmin /showobjmeta tor-dc1 "cn=administrator,cn=users,dc=adatum,dc=com"
$RepAdminRaw |  ConvertFrom-String -TemplateContent $data -ErrorAction SilentlyContinue 