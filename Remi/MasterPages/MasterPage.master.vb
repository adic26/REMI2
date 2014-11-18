Imports System.Web
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Core

Partial Class MasterPages_MasterPage
    Inherits System.Web.UI.MasterPage

    Protected Sub lnkLogout_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles lnkLogout.Click
        UserManager.LogUserOut()
        Response.Redirect(REMIConfiguration.DefaultRedirectPage)
    End Sub

    Protected Sub page_prerender() Handles Me.PreRender
        Dim hlUser As HyperLink = Me.FindControl("hlUser")
        Dim lnkLogOut As LinkButton = Me.FindControl("lnkLogout")
        Dim imgUserName As Image = Me.FindControl("imgUserName")
        Dim s As String = HttpContext.Current.Request.FilePath.ToLower

        If (s.ToLower.Contains("es/default.aspx") Or s.ToLower.Contains("badgeaccess/default.aspx")) Then
            pnlLogged.Visible = False
            For Each c In (From ctrl In pnlHead.Controls Where TypeOf ctrl Is HtmlControl Select ctrl)
                If (TypeOf c Is HtmlControls.HtmlAnchor) Then
                    DirectCast(c, HtmlAnchor).HRef = String.Empty
                    c.Disabled = True
                ElseIf (TypeOf c Is HtmlControls.HtmlGenericControl) Then
                    DirectCast(c, HtmlGenericControl).Disabled = False

                    For Each ct In (From ctrl In DirectCast(c, HtmlGenericControl).Controls Where TypeOf ctrl Is HtmlControl Select ctrl)
                        If (TypeOf ct Is HtmlControls.HtmlAnchor) Then
                            DirectCast(ct, HtmlAnchor).HRef = String.Empty
                            ct.Disabled = True
                        End If
                    Next
                End If
            Next
        End If

        If Not UserManager.GetCurrentUser.IsAdmin Then
            adminLink.Visible = False
        End If

        If (UserManager.GetCurrentUser.HasAdminReadOnlyAuthority And Not (UserManager.GetCurrentUser.IsAdmin)) Then
            adminLink.Visible = True
            A7.HRef = "~/Admin/Jobs.aspx"
        ElseIf (UserManager.GetCurrentUser.IsTestCenterAdmin And Not (UserManager.GetCurrentUser.IsAdmin)) Then
            adminLink.Visible = True
            A7.HRef = "~/Admin/TrackingLocations.aspx"
        End If

        If UserManager.GetCurrentUser.IsDeveloper Then
            logLink.Visible = True
        Else
            logLink.Visible = False
        End If

        'You are a relab role or your role has permission to view relab
        If UserManager.GetCurrentUser.HasRelabAuthority() Or UserManager.GetCurrentUser.HasRelabAccess() Then
            Results.Visible = True
        Else
            Results.Visible = False
        End If

        If Not (UserManager.GetCurrentUser.IsIncomingSpecialist OrElse UserManager.GetCurrentUser.IsMaterialsManagementSpecialist) Then
            Incoming.Visible = False
        End If

        imgUserName.CssClass = "Pass"
        lnkLogOut.Visible = True

        If hlUser IsNot Nothing Then
            hlUser.Text = UserManager.GetCurrentUser.UserName
        End If

        If (REMIAppCache.GetMenuAccess(UserManager.GetCurrentUser.DepartmentID) Is Nothing) Then
            REMIAppCache.SetMenuAccess(UserManager.GetCurrentUser.DepartmentID, SecurityManager.GetMenuAccessByDepartment(String.Empty, UserManager.GetCurrentUser.DepartmentID))
        End If

        Dim dtMenuAccess As DataTable = REMIAppCache.GetMenuAccess(UserManager.GetCurrentUser.DepartmentID)

        Overview.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Overview").FirstOrDefault() IsNot Nothing, True, False)
        Search.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Search").FirstOrDefault() IsNot Nothing, True, False)
        ScanDevice.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Scan Device").FirstOrDefault() IsNot Nothing, True, False)
        BatchInfo.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Batch Info").FirstOrDefault() IsNot Nothing, True, False)
        ProductInfo.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Product Info").FirstOrDefault() IsNot Nothing, True, False)
        TrackingLocation.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Tracking Location").FirstOrDefault() IsNot Nothing, True, False)
        Timeline.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Timeline").FirstOrDefault() IsNot Nothing, True, False)
        Incoming.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Incoming").FirstOrDefault() IsNot Nothing, True, False)
        Inventory.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Inventory").FirstOrDefault() IsNot Nothing, True, False)
        user.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "User").FirstOrDefault() IsNot Nothing, True, False)
        Results.Visible = If((From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Results").FirstOrDefault() IsNot Nothing, True, False)
    End Sub
End Class