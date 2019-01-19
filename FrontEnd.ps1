$WorkingPath = "C:\Programdata\CC\DMLUC"

Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, System.Core, WindowsFormsIntegration
$syncHash = [hashtable]::Synchronized(@{})

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
        Name="Window" 
        Width = "1270" Height = "730" Top = "0" Left = "0" ShowInTaskbar = "True" Background="#24387f" ResizeMode="CanMinimize" WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="5" />
            <ColumnDefinition Width="12" />
            <ColumnDefinition Width="145" />
            <ColumnDefinition Width="24" />
            <ColumnDefinition Width="180" />
            <ColumnDefinition Width="5" />
            <ColumnDefinition Width="5" />
            <ColumnDefinition Width="5" />
            <ColumnDefinition Width="520" />
            <ColumnDefinition Width="5"/>
            <ColumnDefinition Width="150"/>
            <ColumnDefinition Width="*" />
            <ColumnDefinition Width="150" />
            <ColumnDefinition Width="5" />
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="25" />
            <RowDefinition Height="11" />
            <RowDefinition Height="5" />
            <RowDefinition Height="22" />
            <RowDefinition Height="5" />
            <RowDefinition Height="35" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="5" />
            <RowDefinition Height="26" />
            <RowDefinition Height="10" />
        </Grid.RowDefinitions>
        <Border Grid.Row="5" Grid.Column="1"  Background="White" Grid.ColumnSpan="5" Grid.RowSpan="38"/>
        <Border Grid.Row="5" Grid.Column="7"  Background="White" Grid.ColumnSpan="6" Grid.RowSpan="12"/>
        <Border Grid.Row="18" Grid.Column="7"  Background="White" Grid.ColumnSpan="3" Grid.RowSpan="21"/>
        <Border Grid.Row="40" Grid.Column="7"  Background="White" Grid.ColumnSpan="3" Grid.RowSpan="3"/>
        <Label Grid.Row="0" Grid.RowSpan="2" Foreground="White" FontSize="20" Content="Data Migration Lookup Utility Console" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalAlignment="Center" FontWeight="Bold" Width="580" Height="40" Grid.ColumnSpan="15" Grid.Column="1"/>
        <Label Name="Version_Label" Content="v" Grid.Row="0" Grid.RowSpan="1" Foreground="White" FontSize="12" HorizontalAlignment="Right" HorizontalContentAlignment="Right" VerticalAlignment="Bottom"  Grid.ColumnSpan="1" Grid.Column="12"/>
        <Label Grid.Row="5" Grid.ColumnSpan="4" Foreground="#009ddc" FontSize="18" Content="Information" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalAlignment="Center" Height="35" FontWeight="Bold" Grid.Column="1"/>
        <TextBox Name="SearchTextBox" Grid.Row="3" Grid.Column="2" TextWrapping="Wrap" FontStyle="Italic"/>
        <Button Name="Search_Button" IsDefault="True" Grid.Column="4" Content="Search" Grid.Row="3" HorizontalAlignment="Left" VerticalAlignment="Center" Width="75"/>
        <Label Name="AdminUserNameLabel" Grid.Row="3" Foreground="#009ddc" Content="Admin User Name:" HorizontalAlignment="Left" VerticalAlignment="Top" VerticalContentAlignment="Top" HorizontalContentAlignment="Right" FontWeight="Bold" Height="26" Grid.Column="8" Width="400"/>
        <TextBox Name="UsernameTextBox" Grid.Row="3" Grid.Column="8" Grid.ColumnSpan="1" HorizontalAlignment="Right" Width="120" TextWrapping="Wrap" FontStyle="Italic"/>
        <Label Name="AdminPWDLabel" Grid.Row="3" Foreground="#009ddc" Content="Password:" HorizontalAlignment="Left" VerticalAlignment="Top" VerticalContentAlignment="Top" HorizontalContentAlignment="Right" FontWeight="Bold" Height="26" Grid.Column="10" Width="93"/>
        <PasswordBox Name="PasswordTextBox" Grid.Row="3" Grid.Column="10" Grid.ColumnSpan="2" HorizontalAlignment="Right" Width="100" FontStyle="Italic"/>
        <Button Name="CredsAddedButton" Grid.Column="12" Grid.ColumnSpan="1" Content="Admin Credentials" Grid.Row="3" HorizontalAlignment="Center" VerticalAlignment="Center" Width="125"/>
        <Label Grid.Row="40" Foreground="#009ddc" FontSize="22" Content="Messages" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalAlignment="Center" FontWeight="Bold" Height="40" Grid.Column="8"/>
        <TextBox Name="InformationBox" Grid.Row="42" Grid.Column="8" TextWrapping="Wrap" Text="" Visibility="Visible" IsReadOnly="True" Height="18"/>
        <Label Name="SourceComputer_Label" Grid.Row="6" FontSize="12" Content="Windows 7 PC: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Button Name="SourceComputerCopy_Button" Content="C" Grid.Column="3" HorizontalAlignment="Center" Grid.Row="6" VerticalAlignment="Center" Width="23" Height="20" BorderThickness="0" Visibility="Hidden"/>
        <Label Name="SourceComputer_Label_Content" Grid.Row="6" FontSize="12" Grid.Column="4"/>
        <Label Name="TargetComputer_Label" Grid.Row="8" FontSize="12" Content="Windows 10 PC: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Button Name="TargetComputerCopy_Button" Content="C" Grid.Column="3" HorizontalAlignment="Center" Grid.Row="8" VerticalAlignment="Center" Width="23" Height="20" BorderThickness="0" Visibility="Hidden"/>
        <Label Name="TargetComputer_Label_Content" Grid.Row="8" FontSize="12" Grid.Column="4"/>
        <Label Name="CaptureLocation_Label" Grid.Row="10" FontSize="12" Content="Capture Location: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="CaptureLocation_Label_Content" Grid.Row="10" FontSize="12" Grid.Column="4"/>
        <Label Name="AllowedCaptureDate_Label" Grid.Row="12" FontSize="12" Content="Capture Start Date: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="AllowedCaptureDate_Label_Content" Grid.Row="12" FontSize="12" Grid.Column="4"/>
        <Label Name="AllowedRestoreDate_Label" Grid.Row="14" FontSize="12" Content="Deployment Date: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Button Name="AllowedRestoreDate_Button" Content="Set" Grid.Column="3" HorizontalAlignment="Center" Grid.Row="14" VerticalAlignment="Center" Width="25" Height="20" BorderThickness="0" Visibility="Hidden"/>
        <Label Name="AllowedRestoreDate_Label_Content" Grid.Row="14" FontSize="12" Grid.Column="4"/>
        <Label Name="Description_Label" Grid.Row="16" FontSize="12" Content="Deployment Group: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="Description_Label_Content" Grid.Row="16" FontSize="12" Grid.Column="4"/>
        <Label Name="DeploymentStatus_Label" Grid.Row="18" FontSize="12" Content="Deployment Status: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="DeploymentStatus_Label_Content" Grid.Row="18" FontSize="12" Grid.Column="4"/>
        <Label Name="LastFullSyncDate_Label" Grid.Row="20" FontSize="12" Content="Last Full Backup: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="LastFullSyncDate_Label_Content" Grid.Row="20" FontSize="12" Grid.Column="4"/>
        <Label Name="RestoreCompletion_Label" Grid.Row="22" FontSize="12" Content="Restore Completed: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="RestoreCompletion_Label_Content" Grid.Row="22" FontSize="12" Grid.Column="4"/>
        <Label Name="TotalSize_Label" Grid.Row="24" FontSize="12" Content="Data Size (GB): " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="TotalSize_Label_Content" Grid.Row="24" FontSize="12" Grid.Column="4"/>
        <Label Name="ScriptVersion_Label" Grid.Row="26" FontSize="12" Content="Script Version: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="ScriptVersion_Label_Content" Grid.Row="26" FontSize="12" Grid.Column="4"/>
        <Label Name="FirstSeen_Label" Grid.Row="28" FontSize="12" Content="First Seen: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="FirstSeen_Label_Content" Grid.Row="28" FontSize="12" Grid.Column="4"/>
        <Label Name="LastSeen_Label" Grid.Row="30" FontSize="12" Content="Most Recently Seen: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="LastSeen_Label_Content" Grid.Row="30" FontSize="12" Grid.Column="4"/>
        <Label Name="TimesSeen_Label" Grid.Row="32" FontSize="12" Content="Times Seen: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="TimesSeen_Label_Content" Grid.Row="32" FontSize="12" Grid.Column="4"/>
        <Label Name="Email_Label" Grid.Row="34" FontSize="12" Content="E-mail Address: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="Email_Label_Content" Grid.Row="34" FontSize="12" Grid.Column="4"/>
        <Label Name="UserName_Label" Grid.Row="36" FontSize="12" Content="User Name: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="UserName_Label_Content" Grid.Row="36" FontSize="12" Grid.Column="4"/>
        <Label Name="Phone_Label" Grid.Row="38" FontSize="12" Content="Phone Number: " Grid.Column="2" HorizontalContentAlignment="Left" FontWeight="Bold"/>
        <Label Name="Phone_Label_Content" Grid.Row="38" FontSize="12" Grid.Column="4"/>
        <Label Grid.Row="5" Foreground="#009ddc" FontSize="18" Content="Capture Logs" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalAlignment="Center" FontWeight="Bold" Height="35" Grid.Column="8" Grid.ColumnSpan="5"/>
        <ListView Name="CaptureReportDataGrid" Grid.Column="8" HorizontalAlignment="Left" Grid.Row="6" VerticalAlignment="Top" Grid.RowSpan="11" Grid.ColumnSpan="5" FontSize="9"  Height="176">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header ="Date" DisplayMemberBinding ="{Binding Date2}" Width="93" />
                    <GridViewColumn Header ="IP Subnet" DisplayMemberBinding ="{Binding IPSubnet}" Width="73" />
                    <GridViewColumn Header ="Space Required" DisplayMemberBinding ="{Binding SpaceRequired}" Width="83"/>
                    <GridViewColumn Header ="USB Space" DisplayMemberBinding ="{Binding FreeSpaceOnUSB}" Width="73"/>
                    <GridViewColumn Header ="Target Path" DisplayMemberBinding ="{Binding TargetPath}" Width="108"/>
                    <GridViewColumn Header ="PC Data Copied" DisplayMemberBinding ="{Binding UnstructuredCopied}" Width="113"/>
                    <GridViewColumn Header ="User Data Copied" DisplayMemberBinding ="{Binding StructuredNonLAFToODCopied}" Width="107"/>
                    <GridViewColumn Header ="LostandFound Copied" DisplayMemberBinding ="{Binding StructuredLAFCopied}" Width="112"/>
                    <GridViewColumn Header ="Time Taken" DisplayMemberBinding ="{Binding CopyTimeSeconds}" Width="72"/>
                </GridView>
            </ListView.View>
        </ListView>
        <Label Grid.Row="18" Foreground="#009ddc" FontSize="22" Content="Status Messages" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalAlignment="Center" FontWeight="Bold" Height="40" Grid.Column="8"/>
        <Button Name="Populate7" Content="Windows 7 PC" Grid.Column="8" HorizontalAlignment="Center" Grid.Row="20" VerticalAlignment="Center" Width="150" Height="26" Margin="0,0,200,0" FontWeight="Bold" FontSize="18" Foreground="#FFABB1B4" Background="White" BorderThickness="0,0,0,0"/>
        <Button Name="Populate10" Content="Windows 10 PC" Grid.Column="8" HorizontalAlignment="Center" Grid.Row="20" VerticalAlignment="Center" Width="150" Height="26" Margin="0,0,-200,0" FontWeight="Bold" FontSize="18" Foreground="#FFABB1B4" Background="White" BorderThickness="0,0,0,0"/>
        <ListView Name="StatusMessageImportDataGrid" Grid.Column="8" HorizontalAlignment="Left" Grid.Row="22" VerticalAlignment="Top" Grid.RowSpan="17" Height="270">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header ="Date" DisplayMemberBinding ="{Binding Date2}" Width="125" />
                    <GridViewColumn Header ="Level" DisplayMemberBinding ="{Binding Level}" Width="80"/>
                    <GridViewColumn Header ="Message" DisplayMemberBinding ="{Binding Message}" Width="305" />
                </GridView>
            </ListView.View>
        </ListView>
        <Label Grid.Row="18" Foreground="White" FontSize="19" Content="Windows 7 PC" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalAlignment="Center" FontWeight="Bold" Height="40" Grid.Column="10" Grid.ColumnSpan="1"/>
        <Button Name="Win7PCCheck" Content="Check" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="18" VerticalAlignment="Center" Width="25" Height="20" Visibility="Hidden"/>
        <Button Name="RDP7" Content="Remote Desktop" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="20" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="SCCMTools7" Content="SCCM Remote" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="20" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="ComputerManagement7" Content="Computer Mgmt" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="22" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="CaptureLog7" Content="DM-Capture Log" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="22" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="InstallScript7" Content="Install Script" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="24" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Label Name="InstallScript7Label" Grid.Row="24" Foreground="White" FontSize="19" Content="Installing" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalAlignment="Center" Height="40" Grid.Column="10" Grid.ColumnSpan="1" Visibility="Hidden"/>
        <Button Name="ForceBackup7" Content="Trigger Backup" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="24" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="UnlockUSB7" Content="Unlock USB" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="26" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="PSExec7" Content="PSExec" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="26" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="DataMigrationFolder7" Content="DM Folder" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="28" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="UsersFolder7" Content="Users Folder" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="28" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Label Grid.Row="32" Foreground="White" FontSize="19" Content="Windows 10 PC" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalAlignment="Center" FontWeight="Bold" Height="40" Grid.Column="10" Grid.ColumnSpan="1"/>
        <Button Name="Win10PCCheck" Content="Check" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="32" VerticalAlignment="Center" Width="25" Height="20" Visibility="Hidden"/>
        <Button Name="RDP10" Content="Remote Desktop" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="34" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="SCCMTools10" Content="SCCM Remote" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="34" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="ComputerManagement10" Content="Computer Mgmt" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="36" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="RestoreLog10" Content="DM-Restore Log" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="36" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="InstallScript10" Content="Install Script" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="38" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Label Name="InstallScript10Label" Grid.Row="38" Foreground="White" FontSize="19" Content="Installing" HorizontalAlignment="Center" HorizontalContentAlignment="Center" VerticalAlignment="Center" Height="40" Grid.Column="10" Grid.ColumnSpan="1" Visibility="Hidden"/>
        <Button Name="EnableRestore10" Content="Re-enable Restore" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="38" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="UnlockUSB10" Content="Unlock USB" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="40" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="PSExec10" Content="PSExec" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="40" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="DataMigrationFolder10" Content="DM Folder" Grid.Column="10" HorizontalAlignment="Center" Grid.Row="42" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
        <Button Name="UsersFolder10" Content="Users Folder" Grid.Column="12" HorizontalAlignment="Center" Grid.Row="42" VerticalAlignment="Center" Width="120" Visibility="Hidden"/>
    </Grid>
</Window>


    '
$syncHash.SubmitPressed = $false
$syncHash.CalendarPressed = $false
$syncHash.CurrentActionPressed = $false

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


    # This is the pic in the middle
$syncHash.imagesource = "\\RMGRHHAH02\DM$\DMLUC\Untitled.ico"
# This is the icon in the upper left hand corner of the app

# This is the toolbar icon and description
$syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
    $syncHash.window.Icon = $syncHash.imageSource
    $syncHash.window.TaskbarItemInfo.Overlay = $syncHash.imagesource
    $syncHash.window.TaskbarItemInfo.Description = $window.Title
    }))

### Logic to trigger buttons during DO loop later on
$syncHash.Search_Button.add_click({ $syncHash.SearchPressed = $true })

$appContext = New-Object System.Windows.Forms.ApplicationContext 
[void][System.Windows.Forms.Application]::Run($appContext)
$syncHash.Error = $Error
})
$psCmd.Runspace = $formRunspace
$data = $psCmd.BeginInvoke()

do { start-sleep -MilliSeconds 100 } until ($syncHash.Window.IsVisible -eq $False)
 
$syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
    [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($syncHash.window)
    $syncHash.window.Add_MouseLeftButtonDown({
        $_.Handled = $true
        $syncHash.window.DragMove()
        })
    $SyncHash.window.Show()
    $SyncHash.window.Activate()
    $syncHash.SearchTextBox.Focus() | out-null 
    
    }))

$CredentialsEntered = $false
do
{
    $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
        $syncHash.SearchTextBoxText = $syncHash.SearchTextBox.Text.Trim()
        }))
        
    ################ Credentials

    
    Start-Sleep -Milliseconds 100
}Until (($syncHash.SubmitPressed -eq $true) -or ($syncHash.EndScript -eq $true))