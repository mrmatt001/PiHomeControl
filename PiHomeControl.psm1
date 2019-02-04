function Get-EQ3Temperature
{
    param (
    $MACAddress
    )
    process
    {
        modprobe btusb
        systemctl start bluetooth
        get-job | Remove-Job -Force
        $scriptBlock = [scriptblock]::Create("gatttool -b " + $MACAddress + ' --char-write-req -a "0x0411" -n "03" --listen')
        $Job = (Start-Job -Name $MACAddress -ScriptBlock $scriptBlock -ArgumentList $MACAddress)
        $JobStartTime = (Get-Date)
        do
        {
            start-sleep -milliseconds 500
            $JobOutput = Get-Job -id $Job.Id -ErrorAction SilentlyContinue | Receive-Job -Keep
        }
        until (($JobOutput -match 'Characteristic') -or (((Get-Date).AddSeconds(-30) -gt $JobStartTime)))
        
        if ($JobOutput -match 'Characteristic')
        {
            $TempOutput = Get-Job -id $Job.ID | Receive-Job
            $null = Get-Job -id $Job.Id | Remove-Job -Force
            foreach ($Line in $TempOutput)
            {
                if ($Line -match 'Notification handle\s+\=\s+\dx\d+\svalue:\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s[a-zA-Z0-9]+\s(?<Temp>[a-zA-Z0-9]+)') 
                { 
                    return ([Convert]::ToInt64(($Matches.Temp),16)/2)
                }
            }
        }
        else 
        {
            return "Request timed out"    
        }
    }
}

function Get-EQ3Thermostats
{
    modprobe btusb
    systemctl start bluetooth
    "scan on" | bluetoothctl
    Start-Sleep -seconds 10
    $MACAddresses = @()
    foreach ($Device in ("devices" | bluetoothctl)) { if ($Device -match 'CC-RT-M-BLE') { if ($Device -match '(?<MACAddress>[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+\:[0-9A-Z]+)') { $MACAddresses += $Matches.MACAddress } } }
    return ($MACAddresses | Sort-Object -Unique)
}

function Set-EQ3Temperature
{
    param (
        $MACAddress,
        $Temperature
        )
    process
    {
        modprobe btusb
        systemctl start bluetooth
        $Temp2 = $Temperature * 2
        if ($Temperature -match '^(?<TEMPHex>[0-3][0-9]).[5]') { $Temp2 = (([INT32]$Matches.TEMPHex * 2) + 1) }
        if ($Temperature -match '^(?<TEMPHex>[0-3][0-9]).[0]') { $Temp2 = (([INT32]$Matches.TEMPHex * 2)) }
        $TemperatureHex = '{0:x}' -f $Temp2
        $SetTemp = (gatttool -b $MACAddress --char-write-req -a "0x0411" -n "41$TemperatureHex")
    }     
}

function Get-AllowedEQ3Commands
{
    param(
        [STRING]$ReceivedText
    )
    
    #if ($receivedText -match '^Set-EQ3Temperature\s-MACAddress\s(?<MACAddress>[a-fA-F0-9:]+)\s-Temperature\s(?<Temperature>[0-9]+)')
    if ($receivedText -match '^Set-EQ3Temperature\s-MACAddress\s(?<MACAddress>[a-fA-F0-9:]+)')
    {
        return "Valid"
    }
    
    if ($receivedText -match '^Get-EQ3Temperature\s-MACAddress\s(?<MACAddress>[a-fA-F0-9:]+)')
    {
        return "Valid"
    }
    
    if ($receivedText -match '^Get-EQ3Thermostats')
    {
        return "Valid"
    }
}

function Install-Postgres
{
    sudo apt-get install postgresql libpq-dev postgresql-client postgresql-client-common -y
    (Get-Content /etc/postgresql/9.6/main/pg_hba.conf).replace("host    all             all             127.0.0.1/32            md5", "host    all             all             0.0.0.0/0            md5") | Set-Content /etc/postgresql/9.6/main/pg_hba.conf
    (Get-Content /etc/postgresql/9.6/main/postgresql.conf).replace("#listen_addresses = 'localhost'", "listen_addresses = '*'") | Set-Content /etc/postgresql/9.6/main/postgresql.conf
    (Get-Content /etc/postgresql/9.6/main/postgresql.conf).replace("ssl = true","ssl = false") | Set-Content /etc/postgresql/9.6/main/postgresql.conf
    sudo service postgresql restart
    Register-PackageSource -Name "nugetv2" -ProviderName NuGet -Location "http://www.nuget.org/api/v2/"
    Install-Package NpgSQL -Force| Out-Null
}

function Install-HomeControlDB
{
    Param(
        [Parameter(Mandatory=$true)][STRING]$DBUser,
        [Parameter(Mandatory=$true)][SecureString]$DBPassword
        )
    $UnsecurePassword = (New-Object PSCredential "user",$DBPassword).GetNetworkCredential().Password
    sudo -u postgres psql -c 'CREATE DATABASE homecontrol;'
    sudo -u postgres psql homecontrol -c "create role $DBUser with login password '$UnsecurePassword';"
    Remove-Variable -Name UnsecurePassword -ErrorAction SilentlyContinue
    sudo -u postgres psql homecontrol -c 'CREATE TABLE IF NOT EXISTS pidevices(piid SERIAL PRIMARY KEY,pihostname VarChar(15) NOT NULL,ostype VarChar(10));'
    sudo -u postgres psql homecontrol -c 'CREATE TABLE IF NOT EXISTS eq3thermostats(eq3id SERIAL PRIMARY KEY,eq3macaddress VarChar(17) UNIQUE NOT NULL,friendlyname VarChar(50),currenttemperature INT);'
    sudo -u postgres psql homecontrol -c 'CREATE TABLE IF NOT EXISTS pitoeq3(pihostname VarChar(15) NOT NULL,eq3macaddress VarChar(17) NOT NULL);'
    sudo -u postgres psql homecontrol -c "GRANT ALL ON pidevices TO $DBUser;"
    sudo -u postgres psql homecontrol -c "GRANT ALL ON eq3thermostats TO $DBUser;"
    sudo -u postgres psql homecontrol -c "GRANT ALL ON pitoeq3 TO $DBUser;"
    sudo -u postgres psql homecontrol -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $DBUser;"
}

function Remove-Postgres
{
    sudo apt-get remove postgresql libpq-dev postgresql-client postgresql-client-common -y
    sudo -u postgres psql homecontrol -c 'DROP TABLE pidevices;'
    sudo -u postgres psql homecontrol -c 'DROP TABLE eq3thermostats;'
    sudo -u postgres psql homecontrol -c 'DROP TABLE pitoeq3;'
    sudo -u postgres psql -c 'DROP ROLE dbuser;'
    sudo -u postgres psql -c 'DROP DATABASE homecontrol;'
}

function Read-FromPostgreSQL
{
    Param(
        [Parameter(Mandatory=$true)][STRING]$DBServer,
        [Parameter(Mandatory=$true)][STRING]$DBName,
        [Parameter(Mandatory=$true)][STRING]$DBUser,
        [Parameter(Mandatory=$true)][String]$DBPassword,
        [Parameter(Mandatory=$true)][String]$Query,
        [STRING]$WhereClause
        )
    #$UnsecurePassword = (New-Object PSCredential "user",$DBPassword).GetNetworkCredential().Password
    if ($IsLinux) { import-module /usr/local/share/PackageManagement/NuGet/Packages/Npgsql.4.0.4/lib/net45/Npgsql.dll }
    if ($IsWindows) 
    { 
        import-module C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Npgsql\*\Npgsql.dll
        Add-Type -Path C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Npgsql\*\Npgsql.dll 
    }
    $query = $query -f $WhereClause
    $connection = new-object Npgsql.NpgsqlConnection
    $connection.ConnectionString = "Server={0};Port={1};Database={2};User Id={3};Password={4}" -f $DBServer, $DBPort, $DBName, $DBUser, $DBPassword
    $DBCommand = $connection.CreateCommand()
    $DBCommand.CommandText = $query
    $table = new-object system.data.datatable
    $Adapter = New-Object Npgsql.NpgsqlDataAdapter ($DBCommand)
    try
    {
        $Adapter.Fill($table) | Out-Null
    }
    catch {}
    $connection.Close() 
    Return $Table   
}

function Write-ToPostgreSQL([STRING]$Statement,[STRING]$DBServer,[STRING]$DBName,[STRING]$WhereClause,[STRING]$DBPort,[STRING]$DBUser,[STRING]$DBPassword)
{
    if ($IsLinux) { import-module /usr/local/share/PackageManagement/NuGet/Packages/Npgsql.4.0.4/lib/net45/Npgsql.dll }
    if ($IsWindows) { import-module C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Npgsql\v4.0_4.0.4.0__5d8b90d52f46fda7\Npgsql.dll }
    $Connection = new-object Npgsql.NpgsqlConnection
    $Connection.ConnectionString = "Server={0};Port={1};Database={2};User Id={3};Password={4}" -f $DBServer, $DBPort, $DBName, $DBUser, $DBPassword
    try
    {
        $Connection.open() 
        $DBCommand = $connection.CreateCommand()
        $DBCommand.CommandText = $Statement
        $DBCommand.ExecuteNonQuery() | Out-Null 
        $Success = $true
    }
    catch
    {
        $Success = $false
    }
    $Connection.Close()
    Return $Success
}

function Register-PiDevice
{
    Param(
        [Parameter(Mandatory=$true)][STRING]$DBServer,
        [Parameter(Mandatory=$true)][STRING]$DBName,
        [Parameter(Mandatory=$true)][STRING]$DBUser,
        [Parameter(Mandatory=$true)][String]$DBPassword
        )
    $hostname = (hostname)
    $insert = "INSERT INTO pidevices (pihostname, ostype) SELECT '$hostname', 'linux'";
    $upsert = "UPDATE pidevices SET ostype='linux' WHERE pihostname='$hostname'";
    $Statement = "WITH upsert AS ($upsert RETURNING *) $insert WHERE NOT EXISTS (SELECT * FROM upsert)"
    Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword
    <#
    foreach ($MACAddress in Get-EQ3Thermostats)
    {
        if (!(Read-FromPostgreSQL -Query "Select * from eq3thermostats" -DBServer localhost -DBName localhost -dbuser dbuser -DBPassword Password123)) 
        { 
            Write-Host ("$MACAddress currently set at " + (Get-EQ3Temperature -MACAddress $MACAddress)) 
            $ThermostatFriendlyName = Read-Host "Enter a friendly name for the thermostat"
            $Statement = "INSERT INTO eq3thermostats (eq3macaddress,friendlyname) VALUES ('$MACAddress','$ThermostatFriendlyName')";
            Write-ToPostgreSQL -Statement $Statement -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $DBPassword
        }
    }
    #>
}

function Set-EQ3FriendlyName
{
    Param(
        [Parameter(Mandatory=$true)][STRING]$DBServer,
        [Parameter(Mandatory=$true)][STRING]$DBName,
        [Parameter(Mandatory=$true)][STRING]$DBUser,
        [Parameter(Mandatory=$true)][String]$DBPassword,
        [Parameter(Mandatory=$true)][STRING]$EQ3MACAddress,
        [Parameter(Mandatory=$true)][STRING]$FriendlyName
        )
    $Statement = "UPDATE eq3thermostats SET friendlyname='$FriendlyName' WHERE eq3macaddress='$EQ3MACAddress'"
    Write-ToPostgreSQL -DBServer $DBServer -DBName $DBName -DBUser $DBUser -DBPassword $DBPassword -Statement $Statement
}

function Read-RegisteredPiDevices
{
    Param(
        [Parameter(Mandatory=$true)][STRING]$DBServer,
        [Parameter(Mandatory=$true)][STRING]$DBName,
        [Parameter(Mandatory=$true)][STRING]$DBUser,
        [Parameter(Mandatory=$true)][SecureString]$DBPassword
        )
    $UnsecurePassword = (New-Object PSCredential "user",$DBPassword).GetNetworkCredential().Password
    Read-FromPostgreSQL -DBServer $DBServer -DBName $DBName -DBPort 5432 -DBUser $DBUser -DBPassword $UnsecurePassword -Query 'select pihostname from pidevices'
}

function Install-AccessPoint([STRING]$SSID,[STRING]$SSIDPassword)
{
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install dnsmasq hostapd samba winbind -y
    sudo systemctl stop dnsmasq
    sudo systemctl stop hostapd
    Add-Content -Path /etc/dhcpcd.conf -Value "interface wlan0"
    Add-Content -Path /etc/dhcpcd.conf -Value "    static ip_address=192.168.150.1/24"
    sudo service dhcpcd restart
    Rename-Item -Path /etc/dnsmasq.conf -NewName dnsmasq.conf.orig
    Add-Content -Path /etc/dnsmasq.conf -Value "interface=wlan0      # Use the require wireless interface - usually wlan0"
    Add-Content -Path /etc/dnsmasq.conf -Value "  dhcp-range=192.168.150.100,192.168.150.120,255.255.255.0,24h"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "interface=wlan0"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "driver=nl80211"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "ssid=$SSID"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "hw_mode=g"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "channel=7"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wmm_enabled=0"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "macaddr_acl=0"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "auth_algs=1"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "ignore_broadcast_ssid=0"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wpa=2"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wpa_passphrase=$SSIDPassword"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wpa_key_mgmt=WPA-PSK"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wpa_pairwise=TKIP"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "rsn_pairwise=CCMP"
    (Get-Content /etc/default/hostapd).replace('#DAEMON_CONF=""','DAEMON_CONF="/etc/hostapd/hostapd.conf"') | Set-Content /etc/default/hostapd
    sudo service hostapd start  
    sudo service dnsmasq start  
    (Get-Content /etc/sysctl.conf).replace('#net.ipv4.ip_forward=1','net.ipv4.ip_forward=1') | Set-Content /etc/sysctl.conf
    sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
    sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
    (Get-Content /etc/rc.local).replace('exit 0','iptables-restore < /etc/iptables.ipv4.nat') | Set-Content /etc/rc.local
    Add-Content -Path /etc/rc.local -Value "exit 0"
}
