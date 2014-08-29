Imports REMI.Bll
Imports REMI.BusinessEntities
Partial Class Inventory_BatchesNotInREMIReport
    Inherits System.Web.UI.Page

    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.PreRender
        Helpers.MakeAccessable(grdMain)
    End Sub
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        Me.lblDate.Text = DateTime.Now.ToString()
    End Sub


End Class
