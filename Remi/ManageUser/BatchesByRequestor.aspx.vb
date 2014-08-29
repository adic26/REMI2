Imports REMI.Bll
Imports REMI.BusinessEntities

Partial Class ManageUser_BatchesByRequestor
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            lblUserNameTitle.Text = UserManager.GetCurrentUser.FullName
            bscMain.SetBatches(BatchManager.GetActiveBatches(UserManager.GetCurrentValidUserLDAPName))
        End If
    End Sub

    Protected Sub btnSearch_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSearch.Click
        Dim username As String = txtUserName.Text

        If (String.IsNullOrEmpty(username)) Then
            username = UserManager.GetCurrentUser.UserName
        End If

        Dim u As User = UserManager.GetUser(username)

        If u.UserName = txtUserName.Text Then
            lblUserNameTitle.Text = u.FullName
            bscMain.SetBatches(BatchManager.GetActiveBatches(u.UserName))
        End If
    End Sub
End Class