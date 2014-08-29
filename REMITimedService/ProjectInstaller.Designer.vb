<System.ComponentModel.RunInstaller(True)> Partial Class ProjectInstaller
    Inherits System.Configuration.Install.Installer

    'Installer overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Component Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Component Designer
    'It can be modified using the Component Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.mainServiceProcessInstaller = New System.ServiceProcess.ServiceProcessInstaller
        Me.mainServiceInstaller = New System.ServiceProcess.ServiceInstaller
        '
        'mainServiceProcessInstaller
        '
        Me.mainServiceProcessInstaller.Account = System.ServiceProcess.ServiceAccount.NetworkService
        Me.mainServiceProcessInstaller.Password = Nothing
        Me.mainServiceProcessInstaller.Username = Nothing
        '
        'mainServiceInstaller
        '
        Me.mainServiceInstaller.ServiceName = "REMITimedService"
        Me.mainServiceInstaller.StartType = System.ServiceProcess.ServiceStartMode.Automatic
        '
        'ProjectInstaller
        '
        Me.Installers.AddRange(New System.Configuration.Install.Installer() {Me.mainServiceProcessInstaller, Me.mainServiceInstaller})

    End Sub
    Friend WithEvents mainServiceProcessInstaller As System.ServiceProcess.ServiceProcessInstaller
    Friend WithEvents mainServiceInstaller As System.ServiceProcess.ServiceInstaller

End Class
