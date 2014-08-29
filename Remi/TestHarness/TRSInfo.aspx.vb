Imports REMI.BusinessEntities
Imports REMI.Bll
Partial Class TestHarness_TRSInfo
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub

    Protected Sub btnGetProducts_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnGetProducts.Click
        For Each p As DataRow In Remi.Bll.ProductGroupManager.GetProductList(UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, False).Rows
            Response.Write(p("productgroupname"))
        Next
    End Sub
End Class
