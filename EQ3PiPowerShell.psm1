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
    Param(
        [Parameter(Mandatory=$true)][STRING]$DBUser,
        [Parameter(Mandatory=$true)][SecureString]$DBPassword
        )
    $UnsecurePassword = (New-Object PSCredential "user",$DBPassword).GetNetworkCredential().Password
    sudo apt-get install postgresql libpq-dev postgresql-client postgresql-client-common -y
    sudo -u postgres psql -c 'CREATE DATABASE homecontrol;'
    sudo -u postgres psql homecontrol -c "create role $DBUser with login password '$UnsecurePassword';"
    Remove-Variable -Name UnsecurePassword -ErrorAction SilentlyContinue
    sudo -u postgres psql homecontrol -c 'CREATE TABLE IF NOT EXISTS pidevices(piid SERIAL PRIMARY KEY,pihostname VarChar(15) NOT NULL,ostype VarChar(10));'
    sudo -u postgres psql homecontrol -c 'CREATE TABLE IF NOT EXISTS eq3thermostats(eq3id SERIAL PRIMARY KEY,eq3macaddress VarChar(17) NOT NULL);'
    sudo -u postgres psql homecontrol -c 'CREATE TABLE IF NOT EXISTS pitoeq3(pihostname VarChar(15) NOT NULL,eq3macaddress VarChar(17) NOT NULL);'
    sudo -u postgres psql homecontrol -c "GRANT ALL ON pidevices TO $DBUser;"
    sudo -u postgres psql homecontrol -c "GRANT ALL ON eq3thermostats TO $DBUser;"
    sudo -u postgres psql homecontrol -c "GRANT ALL ON pitoeq3 TO $DBUser;"
    sudo -u postgres psql homecontrol -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO $DBUser;"
    (Get-Content /etc/postgresql/9.6/main/pg_hba.conf).replace("host    all             all             127.0.0.1/32            md5", "host    all             all             0.0.0.0/0            md5") | Set-Content /etc/postgresql/9.6/main/pg_hba.conf
    (Get-Content /etc/postgresql/9.6/main/postgresql.conf).replace("#listen_addresses = 'localhost'", "listen_addresses = '*'") | Set-Content /etc/postgresql/9.6/main/postgresql.conf
    (Get-Content /etc/postgresql/9.6/main/postgresql.conf).replace("ssl = true","ssl = false") | Set-Content /etc/postgresql/9.6/main/postgresql.conf
    sudo service postgresql restart
    Register-PackageSource -Name "nugetv2" -ProviderName NuGet -Location "http://www.nuget.org/api/v2/"
    Install-Package NpgSQL | Out-Null
}

function Remove-Postgres
{
    sudo apt-get remove postgresql libpq-dev postgresql-client postgresql-client-common -y
    sudo -u postgres psql -c 'DROP TABLE control;'
    sudo -u postgres psql -c 'DROP TABLE brews;'
    sudo -u postgres psql -c 'DROP ROLE dbuser;'
    sudo -u postgres psql -c 'DROP DATABASE brewery;'
}
