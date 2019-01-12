get-job | Remove-Job -Force
#$GattCommand = "'
$sb = {param($p1,$p2) $OFS=','; "p1 is $p1, p2 is $p2, rest of args: $args"}

$ScriptBlock = {param($1) gatttool -b $1 --char-write-req -a 0x0411 -n 03 --listen}
$JobList = @()
Write-Host "Waiting for job to finish on $MACAddress"
$Job = (Start-Job -ScriptBlock $ScriptBlock -Name $MACAddress)

$ScriptBlock = {param($1) gatttool -b $1 --char-write-req -a 0x0411 -n 03 --listen}

