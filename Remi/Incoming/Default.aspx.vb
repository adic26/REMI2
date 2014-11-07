Imports REMI.Bll
Imports REMI.BusinessEntities
Imports System.Data
Imports REMI.Validation

Partial Class Incoming_Default
    Inherits System.Web.UI.Page

    Protected Sub lnkAddAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddAction.Click
        notMain.Clear()

        If (Page.IsValid) Then
            Dim bc As New DeviceBarcodeNumber(Helpers.CleanInputText(BatchManager.GetReqString(txtRequestUnit.Text), 30))

            If bc.Validate Then
                If bc.HasTestUnitNumber Then
                    Dim batch = (From b In New REMI.Dal.Entities().Instance().Batches Where b.QRANumber = bc.BatchNumber Select b.DepartmentID, b.Product.ProductGroupName).FirstOrDefault()

                    If (UserManager.GetCurrentUser.HasEditItemAuthority(batch.ProductGroupName, batch.DepartmentID)) Then
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
                        notMain.Notifications.AddWithMessage("The Request Isn't Part Of Your Department!", REMI.Validation.NotificationType.Errors)
                    End If
                Else
                    notMain.Notifications.AddWithMessage("You must provide a unit number with the Request Number.", REMI.Validation.NotificationType.Warning)
                End If
            Else
                notMain.Notifications.Add(bc.Notifications)
            End If

            If (txtQRANumber.Text.Trim().Length > 0) Then
                If BatchManager.UpdateBatchFromTRS(txtQRANumber.Text.Trim()) > 0 Then
                    notMain.Add("Batch Updated From Request!", NotificationType.Information)
                Else
                    notMain.Add("Batch Updated Failed!", NotificationType.Errors)
                End If
            End If
        End If
    End Sub

    Protected Sub lnkCancelAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkCancelAction.Click
        txtBSN.Text = 0
        txtRequestUnit.Text = String.Empty
        txtQRANumber.Text = String.Empty
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            txtBSN.Text = 0
            txtRequestUnit.Text = String.Empty
            txtQRANumber.Text = String.Empty
        End If
    End Sub

    Sub Validation(ByVal source As Object, ByVal arguments As ServerValidateEventArgs)
        Select Case DirectCast(source, System.Web.UI.WebControls.CustomValidator).ControlToValidate
            Case "txtQRANumber"
                Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(txtQRANumber.Text))

                If (bc.DetailAvailable() = QRANumberType.BatchOnly) Then
                    arguments.IsValid = True
                    DirectCast(source, CustomValidator).ErrorMessage = ""
                Else
                    arguments.IsValid = False
                    DirectCast(source, CustomValidator).ErrorMessage = "You Must Enter A Request Number!"
                End If
            Case "txtRequestUnit"
                Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(txtRequestUnit.Text))

                If (bc.DetailAvailable() = QRANumberType.BatchAndUnit) Then
                    arguments.IsValid = True
                    DirectCast(source, CustomValidator).ErrorMessage = ""
                Else
                    arguments.IsValid = False
                    DirectCast(source, CustomValidator).ErrorMessage = "You Must Enter A Request Number With Unit!"
                End If
        End Select
    End Sub
End Class