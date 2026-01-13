Get-NetAdapter | Where-Object {$_.InterfaceDescription -Match "Cisco AnyConnect"} | Set-NetIPInterface -InterfaceMetric 4000

Get-NetIPInterface -InterfaceAlias "vEthernet (FSE HostVnic)" | Set-NetIPInterface -InterfaceMetric 1