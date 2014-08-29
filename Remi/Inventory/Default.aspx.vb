Imports REMI.Bll
Imports REMI.BusinessEntities

Partial Class Inventory_FastPick
    Inherits System.Web.UI.Page

    Protected Sub page_load() Handles Me.Load
        Response.Redirect("InventoryReport.aspx")

        'If Not Page.IsPostBack Then
        'Dim litTitle As Literal = Master.FindControl("litPageTitle")
        'If litTitle IsNot Nothing Then
        'litTitle.Text = "REMI - Pick - " + UserManager.GetCurrentValidUserLDAPName
        'End If
        'txtBarcodeReading.Focus()
        'End If
    End Sub

    'Protected Sub btnSubmit_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSubmit.Click
    '   notMain.Clear()
    '   notMain.Notifications.Add(BatchManager.PickBatchFromREMSTAR(txtBarcodeReading.Text))
    '   txtBarcodeReading.Focus()
    'End Sub
End Class
