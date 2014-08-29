Imports REMI.Bll
Imports REMI.BusinessEntities
Partial Class Inventory_CountOrders
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub

    Protected Sub btnGetReport_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnGetReport.Click
        notMain.Clear()
        If BatchManager.GenerateBatchCountOrderInREMSTAR Then
            notMain.Add("Order created OK.", REMI.Validation.NotificationType.Information)
        Else
            notMain.Add("Could not create the order. Please try again or contact support.", REMI.Validation.NotificationType.Errors)
        End If
    End Sub
 
End Class
