$Template = @"
<toast>
  <visual>
    <binding template='ToastGeneric'>
      <text>Title Here</text>
      <text>Body text goes here with more details.</text>
    </binding>
  </visual>
  <actions>
    <action
      content="Retry"
      arguments="retry"
      activationType="foreground"/>
    <action
      content="Cancel"
      arguments="cancel"
      activationType="foreground"/>
  </actions>
</toast>
"@

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
$Xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$Xml.LoadXml($Template)
$Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShellScript")
$Toast = [Windows.UI.Notifications.ToastNotification]::new($Xml)
$Notifier.Show($Toast)