Imports REMI.Bll
Imports REMI.BusinessEntities
Imports System.Data
Imports REMI.Validation
Partial Class Incoming_UpdateBatch
    Inherits System.Web.UI.Page

    Protected Sub btnUpdate_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnUpdate.Click
        If (Page.IsValid) Then
            NotificationList1.Clear()
            If BatchManager.UpdateBatchFromTRS(txtQRANumber.Text.Trim()) > 0 Then
                NotificationList1.Add("Batch updated", NotificationType.Information)
            Else
                NotificationList1.Add("Unable to update batch", NotificationType.Errors)
            End If
        End If
    End Sub

    Sub QRAValidation(ByVal source As Object, ByVal arguments As ServerValidateEventArgs)
        If (txtQRANumber.Text.Trim().Length = 0) Then
            arguments.IsValid = False
            DirectCast(source, CustomValidator).ErrorMessage = "You Must Enter A QRA Number!"
        Else
            DirectCast(source, CustomValidator).ErrorMessage = ""
            arguments.IsValid = True
        End If
    End Sub
End Class
