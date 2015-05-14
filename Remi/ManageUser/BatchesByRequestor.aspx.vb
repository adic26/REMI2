Imports REMI.Bll
Imports REMI.BusinessEntities
Imports REMI.Contracts

Partial Class ManageUser_BatchesByRequestor
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            lblUserNameTitle.Text = UserManager.GetCurrentUser.FullName
            Dim bs As New BatchSearch
            bs.Requestor = UserManager.GetCurrentValidUserLDAPName
            bs.ExcludedStatus = BatchStatus.Rejected + BatchStatus.Complete

            bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, False, False, False, 0, False, False, False, False, False))
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
            Dim bs As New BatchSearch
            bs.Requestor = u.UserName
            bs.ExcludedStatus = BatchStatus.Rejected + BatchStatus.Complete

            bscMain.SetBatches(BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, False, False, False, 0, False, False, False, False, False))
        End If
    End Sub
End Class