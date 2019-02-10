Import-Module -Force $PSScriptRoot\PiHomeControl.psm1
Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, System.Core, WindowsFormsIntegration
import-module C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Npgsql\*\Npgsql.dll
Add-Type -Path C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Npgsql\*\Npgsql.dll
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Forms") | Out-Null
function Set-Focus
{
    $CenterOfScreenWidth = (Get-WmiObject -Class Win32_DesktopMonitor | Select-Object ScreenWidth).ScreenWidth / 2
    $CenterOfScreenHeight = (Get-WmiObject -Class Win32_DesktopMonitor | Select-Object ScreenWidth).ScreenWidth / 2
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($CenterOfScreenWidth,$CenterOfScreenHeight)
    $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
        $syncHash.Hidden.Visibility="Visible"
        $syncHash.Hidden.Focus()
        $syncHash.Hidden.Visibility="Hidden"
        }))
}

function RoomButtonClicked
{
    Param(
        [Parameter(Mandatory=$true)][STRING]$Room
        )
    Write-Host "Clicked: $Room"
    $syncHash.RoomClicked = "Clicked: $Room"
}
$syncHash = [hashtable]::Synchronized(@{})
$syncHash.RoomTemps = @{}
$RoomNumber = 1
$syncHash.Rooms = @()
foreach ($EQ3Thermostat in (Read-FromPostgreSQL -DBServer 192.168.50.150 -DBName homecontrol -DBUser dbuser -DBPassword dbuserpwd123 -Query 'select * from eq3thermostats ORDER BY eq3macaddress')) 
{ 
    if ($EQ3Thermostat.currenttemperature.GetType().Name -ne 'DBNull')
    {
        #[DECIMAL]$SyncHash.Temperature1 = $syncHash.RoomTemps.(($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).MACAddress)
        $Temp = ($EQ3Thermostat.currenttemperature / 2) -as [decimal]
        $RoomInfo = [PSCustomObject]@{
        RoomNumber = "Room" + ($RoomNumber++)
        MACAddress = $EQ3Thermostat.eq3macaddress
        FriendlyName = $EQ3Thermostat.friendlyname
        CurrentTemperature = $Temp
        }
        $syncHash.Rooms += $RoomInfo
        $syncHash.RoomTemps.Add($EQ3Thermostat.eq3macaddress,$Temp)
        #  $syncHash.RoomTemps.($EQ3Thermostat.eq3macaddress) = $EQ3Thermostat.currenttemperature
    }
}

$syncHash.HotterBase64 = "iVBORw0KGgoAAAANSUhEUgAAAEEAAAA/CAYAAAHI2JViAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAAD2EAAA9hAag/p2kAAAYnSURBVGhD5ZtLaCRVFIbbx2j7bvDVOqiNo2NQlPhuFMb4QKKixEFl8DG042t8gBkHJaI4jaIRQeJCCLjwIggjCAYE0YVQyyx7mWWWWWbZy+P576MeqVOd2923OtXxh4901z333FN3um7dc6qmJmjR/i0WXVkj+1EW3Vkjhz2UVbvBjfMJM5fkDYlO5MFx01yrHWP0Afo8wR2z7YlolQ0s9lBe9CcbWOyh0eRiEJWem7xRel6APWwkzQmwzbFLaT5ArPRcZBqc0vMgGkiqN4xx3XwdXkStBHw3h/20vHU/d3woz+a92tGyMSsW0Yu7AztjnlWfPmSDIUE/010W0Xd5cNw0+4no1zw4bpr9RHOzeXDcNE9YY428hQXMLmJb5pC/2mvXcGf7C1VXaSdt0+Sh+jncMbU6AhyzzbtK/HkDtBmTYmWWFQnYGNO8etK1IAFb0yVR88zd3CisWxKLd2gnTdPVSLx4BoE+pqv5kCF9w0gj2TI5daWrEqDNmAxWN303SoM2YzJYXemSBmgzJoPVTd/q0qDNmAxWV1oPANqMSTjNM3CMv3siauDCvdT8xXdzeDJSDPWbHMB1CdvXxoGgvTThVk7zvD+j24ppXxQHM/Ktv0ibDNF9/sDe9htbMwytHmbHjw7P8s1xMPAzkrQDem58nC849RVSAdp4lh28Eo7e03Egu6Ya1LqMO50sj+bFxbMSMbTUrtGZh4uhT/yR+jswDsaz43oLSy3RV/7A3vYLJhPED/7A3vYLJhPEz/7A3vYLJhPE7/7A3vYLJhPEP/7A3vYLJh3ECAQNorJyZ7sn2mBcAPg8Uel7yiYvuxvJ0rt7ySmQWgwt88AuA1xKNi5oK100cz4PnNrGgdZ5cRClCpWGTIElDdqsTSnSd1Np7+jo8y4LNtY2qHSpsHcrD7Qj997J+qE4iGz5cAw1GFrk7bq0WZXomKoCQN+xRc0D7FgoGgyiwT9U9DUuRtc2I+6OfUBf62MkrTHUf5KdCdUOH7Yfj4OAr6Gkk9YI0ylsx4dh7YE4CO8EWKdtCwfZgVCiGYW5q+MgvFI8alzAHYX9/zjUPVdKVPXE2lII4NuOIWqVoe3X2VhIOEKwdTwOAmNlhFIknX2KDYWiWEhWjsRBZMqfVOeFQ8pwHJvvsAMhO5LodWQfDoxn0UofKCR6jZ0L1T8Jxcmv5KMAL1GEH5KQmkmoo8M59xFF+CcQypcS6qUyAviAnQt5oYR6uYwATrFzof4qoZLLLZgowi9cSEol1BtlBPAZOxcKyBLq7TIC6LJzISOWUO+XEcDX7FyogEsoXvHQx3QNI4pwiQnpuIQ6XUIAs7fky/dFzNxYQgAjUnm54sf/o5ixQ0ik9a4/Bb5PJMGugs4y+sTb5/Jmrc7XTvLQCKB932qOiU82wnOjKxLWkpqPA/b7RsiM1hl9cgsX8knjZYEC5jhBcra2X/CHZ5PWSUafUIN/+ht4ZHnD7vTYzr4E4YCfqRPeWNBPK8ESXnE7NDyLfJk4H9Zf5k2IKmuF0YG3DnAGjLre7aOzdbhGzaQIBeC/sppldIUVqJv4JPDOSyBWDmYmAuNgvErpb0YHOHd5jfp4Fe/B8MDvbPYugnH3XAuMDqjOC98675fpSPlEd2UmAiCOiQtV6vihUud6Du6JybOQFCgB4glSPffREqMHbvDCt/kYB/TM3rHxiInDxWTjK02Z/f4KHqQ8Xx2WkqdKoJQ8JN7vz2DhQ738WPXYPsq3ZfOavSNIHoL9e3zbW8Nzm+PVR2Vrx4h/pDwks9+fx3b2remif4KzVM5F3DnY8/HOQzqM7ognMz381FDZnVLWX8g8YQI4v0Jl9vuL97CTj/YPHfMWtkPMQ+L9fggiPOP7NDyKb4nSeGMQ5yF48oWFY1z0G74g6nDQKIwHRi1kTgDjSXEMi/9/fPBQ/MZY9CYH/U14FF/fbgw7XuWUTMJ7HPT34VG8SLsx7HiVUzIJeNj8Y3jUq9M0Cac56J/Co3itcWPY8SqnZBKwmv8SHsVrjRvDjlc5JZPwBQf9W3jUu9M0CV9y0H+ER/EO0I1hx6uckkn4loP+Kzzq1DRNAm5p/4ZHfTxFkzAhAk1CrfYfi0s0GXHtqVQAAAAASUVORK5CYII="
# Create a streaming image by streaming the base64 string to a bitmap streamsource
$syncHash.HotterIcon = New-Object System.Windows.Media.Imaging.BitmapImage
$syncHash.HotterIcon.BeginInit()
$syncHash.HotterIcon.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($syncHash.HotterBase64)
$syncHash.HotterIcon.EndInit()
$syncHash.HotterIcon.Freeze()

$syncHash.ColderBase64 = "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"
# Create a streaming image by streaming the base64 string to a bitmap streamsource
$syncHash.ColderIcon = New-Object System.Windows.Media.Imaging.BitmapImage
$syncHash.ColderIcon.BeginInit()
$syncHash.ColderIcon.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($syncHash.ColderBase64)
$syncHash.ColderIcon.EndInit()
$syncHash.ColderIcon.Freeze()

$formRunspace = [runspacefactory]::CreateRunspace()
$formRunspace.ApartmentState = "STA"
$formRunspace.ThreadOptions = "ReuseThread"         
$formRunspace.Open()
$formRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
$psCmd = [PowerShell]::Create().AddScript( {   
        [xml]$xaml = '
<Window
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Name="Window"  WindowStyle="None"
            Width = "750" Height = "650" Top = "0" Left = "0" ShowInTaskbar = "False" Background="#000000" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" >
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="5"></ColumnDefinition>
            <ColumnDefinition Width="150"></ColumnDefinition>
            <ColumnDefinition Width="*"></ColumnDefinition>
            <ColumnDefinition Width="100"></ColumnDefinition>
            <ColumnDefinition Width="100"></ColumnDefinition>
            <ColumnDefinition Width="100"></ColumnDefinition>
            <ColumnDefinition Width="100"></ColumnDefinition>
            <ColumnDefinition Width="*"></ColumnDefinition>
            <ColumnDefinition Width="150"></ColumnDefinition>
            <ColumnDefinition Width="5"></ColumnDefinition>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="50" />
            <RowDefinition Height="10" />
            <RowDefinition Height="*" />
            <RowDefinition Height="10" />
        </Grid.RowDefinitions>
        <TextBox Name="RoomSelection" Grid.Column="3" Grid.ColumnSpan="4" Grid.Row="1" FontSize="30" Foreground="#FFCFCF00" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" VerticalAlignment="Center" FontWeight="Bold" Background="Black" BorderBrush="Black" />
        <TextBox Name="Hidden" Grid.Column="1" Grid.ColumnSpan="1" Grid.Row="1" Visibility="Hidden"/>
        <Button Name="Room1" Grid.Column="1" Grid.Row="3" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room2" Grid.Column="8" Grid.Row="3" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room3" Grid.Column="1" Grid.Row="5" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room4" Grid.Column="8" Grid.Row="5" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room5" Grid.Column="1" Grid.Row="7" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room6" Grid.Column="8" Grid.Row="7" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room7" Grid.Column="1" Grid.Row="9" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room8" Grid.Column="8" Grid.Row="9" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room9" Grid.Column="1" Grid.Row="11" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room10" Grid.Column="8" Grid.Row="11" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room11" Grid.Column="1" Grid.Row="13" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room12" Grid.Column="8" Grid.Row="13" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room13" Grid.Column="1" Grid.Row="15" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room14" Grid.Column="8" Grid.Row="15" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room15" Grid.Column="1" Grid.Row="17" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="Room16" Grid.Column="8" Grid.Row="17" HorizontalAlignment="Left" VerticalAlignment="Center" Width="150" Height="48" Background="Black" Foreground="#FF99E999" FontSize="17" Visibility="Hidden"/>
        <Button Name="TempPlus" Grid.Column="4" Grid.ColumnSpan="2" Grid.Row="9" HorizontalAlignment="Center" VerticalAlignment="Center" Width="66" Height="50" Background="Black" Foreground="Red" Content="+" BorderBrush="Black" Visibility="Hidden"/>
        <Button Name="TempMinus" Grid.Column="4" Grid.ColumnSpan="2" Grid.Row="17" HorizontalAlignment="Center" VerticalAlignment="Center" Width="66" Height="50" Background="Black" Foreground="Blue" Content="-" BorderBrush="Black" Visibility="Hidden"/>
        <Label Name="SetTemperature" Grid.Column="3" Grid.ColumnSpan="4" Grid.Row="10" Grid.RowSpan="7" FontSize="121" Foreground="#FF2C73F1" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" VerticalAlignment="Center"/>
        <Label Name="Clock" Grid.Column="8" Grid.ColumnSpan="1" Content="Blahblah" Grid.Row="21" Grid.RowSpan="1" FontSize="15" Foreground="WhiteSmoke" HorizontalContentAlignment="Center" VerticalContentAlignment="Center" VerticalAlignment="Center" Visibility="Hidden"/>
    </Grid>
</Window>
    '
    $syncHash.SubmitPressed = $false
    $syncHash.CalendarPressed = $false
    $syncHash.CurrentActionPressed = $false
    $syncHash.RoomSelectionLostFocus = $false
    $syncHash.RoomSelectionGotFocus = $false
    $syncHash.RoomButtonClicked = $false
    $SyncHash.EndScript = $False

    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $syncHash.Window = [Windows.Markup.XamlReader]::Load( $reader )
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object { $syncHash.($_.Name) = $syncHash.Window.FindName($_.Name) }   ### This line grabs all the names and binds them as properties of $syncHash
     
    $syncHash.Window.Add_Closing( {
        $syncHash.EndScript = $true
        $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
            $syncHash.Window.Close()
            }))
        })

    # This is the TempPlus icon 
    $syncHash.TempPlusImage = New-Object System.Windows.Controls.Image
    $syncHash.TempPlusImage.Source = $syncHash.HotterIcon
    $syncHash.TempPlusImage.Stretch = 'Fill'
    $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
        $syncHash.TempPlus.Content = $syncHash.TempPlusImage
        }))

    # This is the TempMinus icon 
    $syncHash.TempMinusImage = New-Object System.Windows.Controls.Image
    $syncHash.TempMinusImage.Source = $syncHash.ColderIcon
    $syncHash.TempMinusImage.Stretch = 'Fill'
    $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
        $syncHash.TempMinus.Content = $syncHash.TempMinusImage
        }))

    # This is the toolbar icon and description
    $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
        $syncHash.window.Icon = $syncHash.imageSource
        $syncHash.window.TaskbarItemInfo.Overlay = $syncHash.imagesource
        $syncHash.window.TaskbarItemInfo.Description = $window.Title
        }))

    ### Logic to trigger buttons during DO loop later on
    $syncHash.Search_Button.add_click({ $syncHash.SearchPressed = $true })
    $syncHash.TempPlus.add_click({ $syncHash.TempPlusPressed = $true })
    $syncHash.TempMinus.add_click({ $syncHash.TempMinusPressed = $true })

    foreach ($Room in $syncHash.Rooms) 
    { 
        $syncHash.CurrentRoom = $Room.RoomNumber
        $syncHash.CurrentRoomLabel = $Room.MACAddress
        if ($Room.FriendlyName -match '^[0-9a-zA-Z]') { $syncHash.CurrentRoomLabel = $Room.FriendlyName }
        $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create({
            $syncHash.($syncHash.CurrentRoom).Visibility = "Visible"
            $syncHash.($syncHash.CurrentRoom).Content = $syncHash.CurrentRoomLabel
            }))
    }

    $syncHash.RoomSelection.add_GotFocus({ $syncHash.RoomSelectionGotFocus = $true })
    $syncHash.RoomSelection.add_LostFocus({ $syncHash.RoomSelectionLostFocus = $true})
    $syncHash.RoomSelection.add_KeyUp({ $syncHash.RoomSelectionKeyPressed = $true })
    $syncHash.RoomSelectionKeyPressedDate = $false
    
    $syncHash.Room1.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room1"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room1"
        }
        })

    $syncHash.Room2.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room2"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room2"
        }
        })
    
    $syncHash.Room3.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room3"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room3"
        }
        })
    
    $syncHash.Room4.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room4"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room4"
        }
        })
    
    $syncHash.Room5.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room5"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room5"
        }
        })
    
    $syncHash.Room6.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room6"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room6"
        }
        })
    
    $syncHash.Room7.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room7"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room7"
        }
        })
    
    $syncHash.Room8.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room8"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room8"
        }
        })
    
    $syncHash.Room9.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room9"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room9"
        }
        })
    
    $syncHash.Room10.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room10"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room10"
        }
        })
    
    $syncHash.Room11.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room11"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room11"
        }
        })

    $syncHash.Room12.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room12"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room12"
        }
        })

    $syncHash.Room13.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room13"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room13"
        }
        })

    $syncHash.Room14.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room14"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room14"
        }
        })

    $syncHash.Room15.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room15"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room15"
        }
        })

    $syncHash.Room16.add_click({ 
        if ($SyncHash.CanChangeRoom)
        {
            $syncHash.ChangeToFutureRoom = $false
            $syncHash.RoomChanged = $true
            $syncHash.RoomButtonClicked = "Room16"
        }
        else 
        { 
            $syncHash.ChangeToFutureRoom = $true
            $syncHash.FutureRoomSelection = "Room16"
        }
        })

    $syncHash.CanChangeRoom = $true
    $SyncHash.MaxTemperature = 26
    $SyncHash.MinTemperature = 16
    
    $appContext = New-Object System.Windows.Forms.ApplicationContext 
    [void][System.Windows.Forms.Application]::Run($appContext)
    $syncHash.Error = $Error
    })
$psCmd.Runspace = $formRunspace
$null = $psCmd.BeginInvoke()

do { start-sleep -MilliSeconds 100 } until ($syncHash.Window.IsVisible -eq $False)

$syncHash.ButtonPressed = $false
$syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
    [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($syncHash.window)
    $SyncHash.window.Show()
    $SyncHash.window.Activate()
    $syncHash.Clock.Visibility = "Visible"
    $syncHash.SearchTextBox.Focus() | out-null 
    }))

$syncHash.LockTemps = $false
$LastOnlineCheckDate = (Get-Date).AddSeconds(-30)
do
{
    if ($syncHash.LockTemps -eq $false)
    {
        foreach ($EQ3Thermostat in (Read-FromPostgreSQL -DBServer 192.168.50.150 -DBName homecontrol -DBUser dbuser -DBPassword dbuserpwd123 -Query 'select * from eq3thermostats ORDER BY eq3macaddress')) 
        { 
            if ($EQ3Thermostat.currenttemperature.GetType().Name -ne 'DBNull')
            {
                [decimal]$Temp = ($EQ3Thermostat.currenttemperature / 2) -as [decimal]
                $syncHash.RoomTemps.($EQ3Thermostat.eq3macaddress) = $Temp
                $syncHash.RoomTemps
            }
        }
    }
    
    if ($LastOnlineCheckDate.AddSeconds(30) -lt (Get-Date))
    {
        if (!(Read-FromPostgreSQL -DBServer 192.168.50.150 -DBName homecontrol -DBUser dbuser -DBPassword dbuserpwd123 -Query 'select * from eq3thermostats')) 
        { 
            $SystemOnline = $false 
        }
        else
        {
            $SystemOnline = $true
        }    
        $LastOnlineCheckDate = (Get-Date)
    }
    
    if ($SystemOnline)
    {
        if ($syncHash.RoomButtonClicked -ne $false)
        {
            $RoomSelected = $syncHash.RoomButtonClicked
            $syncHash.RoomSelected = $syncHash.RoomButtonClicked
            $syncHash.RoomButtonClicked = $false
            $TempMACAddress = ($syncHash.Rooms | Where-Object { $_.RoomNumber -eq $syncHash.RoomSelected }).MACAddress
            #Get MAC Address for roomselected
            $syncHash.CurrentRoomLabel = ((Read-FromPostgreSQL -DBServer 192.168.50.150 -DBName homecontrol -DBUser dbuser -DBPassword dbuserpwd123 -Query "select * from eq3thermostats where eq3macaddress = '$TempMACAddress'")).eq3macaddress 
            if ((((Read-FromPostgreSQL -DBServer 192.168.50.150 -DBName homecontrol -DBUser dbuser -DBPassword dbuserpwd123 -Query "select * from eq3thermostats where eq3macaddress = '$TempMACAddress'")).friendlyname) -match '^[0-9a-zA-Z]') { $syncHash.CurrentRoomLabel = (($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).FriendlyName) }
            $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create({
                $syncHash.RoomSelection.Text = $syncHash.CurrentRoomLabel
                }))
        }

        if ($null -ne $syncHash.RoomButtonClicked)    
        {
            [DECIMAL]$SyncHash.Temperature1 = $syncHash.RoomTemps.(($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).MACAddress)
            if (($SyncHash.Temperature1 -ge 16) -and ($SyncHash.Temperature1 -lt 17)) { $TempColour = "#0000ff" }
            if (($SyncHash.Temperature1 -ge 17) -and ($SyncHash.Temperature1 -lt 18)) { $TempColour = "#69a1bd" }
            if (($SyncHash.Temperature1 -ge 18) -and ($SyncHash.Temperature1 -lt 19)) { $TempColour = "#B9C6B5" }
            if (($SyncHash.Temperature1 -ge 19) -and ($SyncHash.Temperature1 -lt 20)) { $TempColour = "#ecdda9" }
            if (($SyncHash.Temperature1 -ge 20) -and ($SyncHash.Temperature1 -lt 21)) { $TempColour = "#ffc000" }
            if (($SyncHash.Temperature1 -ge 21) -and ($SyncHash.Temperature1 -lt 22)) { $TempColour = "#ff9000" }
            if (($SyncHash.Temperature1 -ge 22) -and ($SyncHash.Temperature1 -lt 23)) { $TempColour = "#ff8900" }
            if (($SyncHash.Temperature1 -ge 23) -and ($SyncHash.Temperature1 -lt 24)) { $TempColour = "#ff6000" }
            if (($SyncHash.Temperature1 -ge 24) -and ($SyncHash.Temperature1 -lt 25)) { $TempColour = "#ff3000" }
            if (($SyncHash.Temperature1 -ge 25) -and ($SyncHash.Temperature1 -lt 26)) { $TempColour = "#ff0000" }
            $syncHash.TempColour = $TempColour
    
            $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
                $syncHash.SetTemperature.Foreground = $syncHash.TempColour
                $syncHash.Clock.Content = (Get-Date -Format HH:mm:ss)
                }))
        }

        if ($syncHash.RoomSelectionKeyPressed -eq $true)
        {
            $syncHash.RoomSelectionKeyPressed = $false
            $syncHash.RoomSelectionKeyPressedDate = (Get-Date)
        }

        if ($syncHash.RoomSelectionKeyPressedDate)
        {
            if ((Get-Date) -gt (($syncHash.RoomSelectionKeyPressedDate).AddSeconds(1.5)))
            {
                $syncHash.RoomSelectionKeyPressedDate = $false
                $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
                    $syncHash.RoomSelectionText = $syncHash.RoomSelection.Text.Trim()
                    $syncHash.($syncHash.RoomSelected).Content = $syncHash.RoomSelectionText
                    }))
                Set-Focus
                $TempMACAddress = (($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).MACAddress)
                Set-EQ3FriendlyName -DBServer 192.168.50.150 -DBName homecontrol -DBUser dbuser -DBPassword dbuserpwd123 -EQ3MACAddress $TempMACAddress -FriendlyName $syncHash.RoomSelectionText
            }
        }

        if ($syncHash.RoomSelectionGotFocus -eq $true)
        {
            $syncHash.RoomSelectionGotFocus = $false
            $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
            $syncHash.RoomSelection.SelectAll()
            }))
        }
    
        if ($syncHash.RoomChanged -eq $true)
        {
            $syncHash.RoomSelected
            $syncHash.RoomChanged = $false
            [decimal]$SyncHash.Temperature = $syncHash.RoomTemps.(($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).MACAddress)
            $syncHash.DisplayTemp = $SyncHash.Temperature.ToString() + "ºC"
            $syncHash.DisplayTemp
            $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
                $syncHash.TempPlus.Visibility = "Visible"
                $syncHash.TempMinus.Visibility = "Visible"
                $syncHash.SetTemperature.Content = $syncHash.DisplayTemp
                }))
        
        }
        
        if ($SyncHash.TempPlusPressed -eq $true)
        {
            $SyncHash.TempPlusPressed = $false
            [decimal]$SyncHash.Temperature = $syncHash.RoomTemps.(($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).MACAddress)
            $SyncHash.CanChangeRoom = $false
            if ($syncHash.Temperature -ne $syncHash.MinTemperature)
            {
                $syncHash.Temperature = $syncHash.Temperature + 0.5
                $syncHash.LockTemps = $true
                $syncHash.RoomTemps.(($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).MACAddress) = $syncHash.Temperature
                $syncHash.DisplayTemp = ($syncHash.Temperature.ToString() + "ºC")
                $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
                    $syncHash.SetTemperature.Content = $SyncHash.DisplayTemp
                    $syncHash.Hidden.Focus()
                    }))
                $syncHash.ButtonPressed = (Get-Date)
            }
        }
    
        if ($SyncHash.TempMinusPressed -eq $true)
        {
            $SyncHash.TempMinusPressed = $false
            [decimal]$SyncHash.Temperature = $syncHash.RoomTemps.(($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).MACAddress)
            $SyncHash.CanChangeRoom = $false
            if ($syncHash.Temperature -ne $syncHash.MinTemperature)
            {
                $syncHash.Temperature = $syncHash.Temperature - 0.5
                $syncHash.LockTemps = $true
                $syncHash.RoomTemps.(($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).MACAddress) = $syncHash.Temperature
                $syncHash.DisplayTemp = ($syncHash.Temperature.ToString() + "ºC")
                $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
                    $syncHash.SetTemperature.Content = $SyncHash.DisplayTemp
                    $syncHash.Hidden.Focus()
                    }))
                $syncHash.ButtonPressed = (Get-Date)
            }
        }
    
        if ($syncHash.ButtonPressed)
        {
            if ((Get-Date) -gt (($syncHash.ButtonPressed).AddSeconds(1.5)))
            {
                $syncHash.ButtonPressed = $false
                [decimal]$SyncHash.Temperature = $syncHash.RoomTemps.(($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $RoomSelected}).MACAddress)
                $SyncHash.Temperature
                Write-Host ("$RoomSelected is set to: " + $SyncHash.Temperature.ToString() + "ºC")
                $syncHash.LockTemps = $false
                $syncHash.LockTemps
                $SyncHash.CanChangeRoom = $true
                if ($syncHash.ChangeToFutureRoom)
                {
                    $syncHash.RoomChanged = $true
                    $syncHash.RoomButtonClicked = $syncHash.FutureRoomSelection
                    $syncHash.CurrentRoomLabel = ($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $FutureRoomSelection}).MACAddress
                    if ((($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $FutureRoomSelection}).FriendlyName) -match '^[0-9a-zA-Z]') { $syncHash.CurrentRoomLabel = (($syncHash.Rooms | Where-Object {$_.RoomNumber -eq $FutureRoomSelection}).FriendlyName) }
                    $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create({
                        $syncHash.RoomSelection.Text = $syncHash.CurrentRoomLabel
                        }))
                }
            }
        }
    }
    else
    {
        $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create({
            $syncHash.Hidden.Visibility = "Visible"
            $syncHash.Hidden.Text = "System offline"
            }))
    }
    Start-Sleep -Milliseconds 100
}Until (($syncHash.SubmitPressed -eq $true) -or ($syncHash.EndScript -eq $true))
#>