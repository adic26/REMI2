Imports REMI.BusinessEntities
Imports REMI.Validation
''' <summary>
''' This control displays messages to the user on the web pages.
''' </summary>
''' <remarks></remarks>
Partial Class Controls_Notifications
    Inherits System.Web.UI.UserControl

    Private WithEvents _notifications As NotificationCollection

    Public Sub New()
        _notifications = New NotificationCollection
    End Sub

    Public Property Notifications() As NotificationCollection
        Get
            Return _notifications
        End Get
        Set(ByVal value As NotificationCollection)
            _notifications = value
            UpdateAllLists()
        End Set
    End Property

    Public Sub Add(ByVal message As String, ByVal type As NotificationType)
        Notifications.Add(Message, type)
    End Sub

    Public Sub RefreshOnNewRule(ByVal Type As NotificationType) Handles _notifications.ItemAdded
        Select Case Type
            Case NotificationType.Errors
                UpdateErrorsList()
            Case NotificationType.Information
                UpdateInformationList()
            Case NotificationType.NotSet
                UpdateAllLists()
            Case NotificationType.Warning
                UpdateWarningsList()
        End Select
    End Sub

    Public ReadOnly Property Count() As Integer
        Get
            Return Notifications.Count
        End Get
    End Property

    Public Sub UpdateAllLists()
        UpdateInformationList()
        UpdateErrorsList()
        UpdateWarningsList()
    End Sub

    Public ReadOnly Property HasErrors() As Boolean
        Get
            Return Notifications.HasErrors
        End Get
    End Property

    Public Sub Clear()
        Notifications = New NotificationCollection
        UpdateAllLists()
    End Sub

    Protected Sub Repeater_databinding(ByVal sender As Object, ByVal e As System.EventArgs) Handles rptErrorList.DataBinding, rptInformation.DataBinding, rptWarningList.DataBinding
        Dim rptControl As Repeater = DirectCast(sender, Repeater)
        If rptControl.DataSource IsNot Nothing Then
            If rptControl.DataSource.Count > 0 Then
                rptControl.Visible = True
            Else
                rptControl.Visible = False
            End If
        Else
            rptControl.Visible = False
        End If
    End Sub

#Region "Update the lists"
    Private Sub UpdateInformationList()
        rptInformation.DataSource = Notifications.FindByType(NotificationType.Information)
        rptInformation.DataBind()
    End Sub

    Private Sub UpdateErrorsList()
        rptErrorList.DataSource = Notifications.FindByType(NotificationType.Errors)
        rptErrorList.DataBind()
    End Sub

    Private Sub UpdateWarningsList()
        rptWarningList.DataSource = Notifications.FindByType(NotificationType.Warning)
        rptWarningList.DataBind()
    End Sub
#End Region

End Class