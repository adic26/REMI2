Imports Remi.Bll
Imports Remi.BusinessEntities

Partial Class ManageUser_Default
    Inherits System.Web.UI.Page
    Protected Sub Page_PreRender() Handles Me.PreRender
        Helpers.MakeAccessable(grdDetail)
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Dim username As String = String.Empty
        Dim userID As Int32 = -1

        If UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
            Dim lookup As String = Contracts.LookupType.TestCenter.ToString()

            Dim us As New UserSearch()
            us.TestCenterID = UserManager.GetCurrentUser.TestCentreID

            Dim uc As UserCollection
            uc = UserManager.UserSearchList(us, False, False, False, False, False)

            ddlUsers.DataSource = uc
            ddlUsers.DataBind()
            ddlUsers.Visible = True
            lblUsers.Visible = True
        End If

        If Request.QueryString IsNot Nothing AndAlso Not String.IsNullOrEmpty(Request.QueryString.Get("username")) Then
            username = Request.QueryString.Get("username")
            userID = UserManager.GetUser(username, 0).ID

            If (userID = 0) Then
                username = UserManager.GetCurrentValidUserLDAPName
                userID = UserManager.GetCurrentUser().ID
            End If
        ElseIf Request.QueryString IsNot Nothing AndAlso Not String.IsNullOrEmpty(Request.QueryString.Get("userid")) Then
            Int32.TryParse(Request.QueryString.Get("userid").ToString(), userID)
            If (userID > 0) Then
                username = UserManager.GetUser(String.Empty, userID).LDAPName
            Else 'If the userid is not valid then revert back to the logged in user.
                username = UserManager.GetCurrentValidUserLDAPName
                userID = UserManager.GetCurrentUser().ID
            End If
        ElseIf (Request.Form(ddlUsers.UniqueID) IsNot Nothing) Then
            Int32.TryParse(Request.Form(ddlUsers.UniqueID).ToString(), userID)
            username = ddlUsers.Items.FindByValue(Request.Form(ddlUsers.UniqueID)).Text
        Else
            username = UserManager.GetCurrentValidUserLDAPName
            userID = UserManager.GetCurrentUser().ID
        End If

        ddlUsers.SelectedValue = userID
        lblUserNameTitle.Text = username

        If (userID > 0) Then
            grdDetail.DataSource = REMI.Bll.TestUnitManager.GetUsersUnits(userID, chkIncludeCompleted.Checked)
            grdDetail.DataBind()
        End If
    End Sub
End Class