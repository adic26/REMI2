Imports REMI.Bll
Imports REMI.BusinessEntities
Imports System.Data
Imports REMI.Validation

Partial Class Incoming_Default
    Inherits System.Web.UI.Page

    Protected Sub lnkAddAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddAction.Click
        notMain.Clear()
        Dim bc As New DeviceBarcodeNumber(Helpers.CleanInputText(BatchManager.GetReqString(txtQRANumber.Text), 30))

        If bc.Validate Then
            If bc.HasTestUnitNumber Then
                Dim bsn As Long
                If String.IsNullOrEmpty(Helpers.CleanInputText(txtBSN.Text, 30)) Then
                    notMain.Notifications.AddWithMessage("The BSN cannot be empty.", REMI.Validation.NotificationType.Warning)
                Else
                    If Long.TryParse(txtBSN.Text, bsn) Then
                        If TestUnitManager.SetUnitBSN(bc.ToString, bsn, UserManager.GetCurrentUser.BadgeNumber) Then
                            notMain.Add(String.Format("{0} was saved successfully with BSN:{1}.", bc.ToString, bsn), REMI.Validation.NotificationType.Information)
                        Else
                            notMain.Notifications.AddWithMessage("The BSN was not saved. Review the data and try again.", REMI.Validation.NotificationType.Errors)
                        End If
                    End If
                End If
            Else
                notMain.Notifications.AddWithMessage("You must provide a unit number with the Request Number.", REMI.Validation.NotificationType.Warning)
            End If
        Else
            notMain.Notifications.Add(bc.Notifications)
        End If
    End Sub

    Protected Sub lnkCancelAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkCancelAction.Click
        txtBSN.Text = 0
        txtQRANumber.Text = String.Empty
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            txtBSN.Text = 0
            txtQRANumber.Text = String.Empty
        End If
    End Sub
End Class