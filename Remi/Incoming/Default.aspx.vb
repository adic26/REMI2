Imports REMI.Bll
Imports REMI.BusinessEntities
Imports System.Data
Imports REMI.Validation

Partial Class Incoming_Default
    Inherits System.Web.UI.Page

    Protected Sub lnkAddAction_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkAddAction.Click
        notMain.Clear()
        Dim bc As DeviceBarcodeNumber

        If (Page.IsValid) Then

            If (txtRequestUnit.Text.Trim().Length > 0) Then
                bc = New DeviceBarcodeNumber(Helpers.CleanInputText(BatchManager.GetReqString(txtRequestUnit.Text), 30))

                If bc.Validate Then
                    If bc.HasTestUnitNumber Then
                        Dim batch = (From b In New Remi.Dal.Entities().Instance().Batches Where b.QRANumber = bc.BatchNumber Select b.DepartmentID, b.Product.Values).FirstOrDefault()

                        If (UserManager.GetCurrentUser.HasEditItemAuthority(batch.Values, batch.DepartmentID)) Then
                            Dim bsn As Long
                            Dim isChanged As Boolean = False
                            Dim tu As TestUnit = TestUnitManager.GetUnit(bc.BatchNumber, bc.UnitNumber)
                            Long.TryParse(txtBSN.Text, bsn)

                            If (bsn > 0) Then
                                tu.BSN = bsn
                                isChanged = True
                            Else
                                notMain.Notifications.AddWithMessage("BSN Will Not Be Updated As It Is Empty!", Remi.Validation.NotificationType.Warning)
                            End If

                            If (txtIMEI.Text.Trim().Length > 0) Then
                                tu.IMEI = txtIMEI.Text
                                isChanged = True
                            Else
                                notMain.Notifications.AddWithMessage("IMEI Will Not Be Updated As It Is Empty!", Remi.Validation.NotificationType.Warning)
                            End If

                            If (isChanged) Then
                                tu.LastUser = UserManager.GetCurrentUser.UserName
                            End If

                            If (TestUnitManager.Save(tu) > 0) Then
                                notMain.Add(String.Format("{0} was saved successfully!", bc.ToString), Remi.Validation.NotificationType.Information)
                            Else
                                notMain.Notifications.AddWithMessage(String.Format("{0} was not saved successfully!", bc.ToString), Remi.Validation.NotificationType.Errors)
                            End If
                        Else
                            notMain.Notifications.AddWithMessage("The Request Isn't Part Of Your Department!", Remi.Validation.NotificationType.Errors)
                        End If
                    Else
                        notMain.Notifications.AddWithMessage("You must provide a unit number with the Request Number.", Remi.Validation.NotificationType.Warning)
                    End If
                Else
                    notMain.Notifications.Add(bc.Notifications)
                End If
            End If

            If (txtQRANumber.Text.Trim().Length > 0) Then
                bc = New DeviceBarcodeNumber(Helpers.CleanInputText(BatchManager.GetReqString(txtQRANumber.Text), 30))

                If bc.Validate Then
                    If BatchManager.MoveBatchForward(bc.BatchNumber, UserManager.GetCurrentUser.UserName) = True Then
                        notMain.Notifications.AddWithMessage(String.Format("{0} Updated From Request!", bc.BatchNumber), NotificationType.Information)
                    Else
                        notMain.Notifications.AddWithMessage(String.Format("{0} Updated Failed!", bc.BatchNumber), NotificationType.Errors)
                    End If
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