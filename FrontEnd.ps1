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
        Name="Window"  WindowStyle="None"
        Width = "750" Height = "550" Top = "0" Left = "0" ShowInTaskbar = "False" Background="#000000" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" >
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="10"></ColumnDefinition>
            <ColumnDefinition Width="50"></ColumnDefinition>
            <ColumnDefinition Width="10"></ColumnDefinition>
            <ColumnDefinition Width="*"></ColumnDefinition>
            <ColumnDefinition Width="10"></ColumnDefinition>
            <ColumnDefinition Width="60"></ColumnDefinition>
            <ColumnDefinition Width="10"></ColumnDefinition>
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
            <RowDefinition Height="*" />
            <RowDefinition Height="10" />
        </Grid.RowDefinitions>
        <Button Name="Search_Button" IsDefault="True" Grid.Column="1" Grid.Row="3" HorizontalAlignment="Left" VerticalAlignment="Center" Width="48" Height="48" Background="Black" Foreground="Green" Content="Room 1"/>
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
$null = $psCmd.BeginInvoke()

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

do
{
    $syncHash.Window.Dispatcher.invoke("Normal", [action][scriptblock]::create( {
        $syncHash.SearchTextBoxText = $syncHash.SearchTextBox.Text.Trim()
        }))
        
    
    Start-Sleep -Milliseconds 100
}Until (($syncHash.SubmitPressed -eq $true) -or ($syncHash.EndScript -eq $true))