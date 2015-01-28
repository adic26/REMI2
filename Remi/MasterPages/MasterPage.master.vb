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
        If (Not Page.IsPostBack) Then
            Dim s As String = HttpContext.Current.Request.FilePath.ToLower
            hlUser.Text = UserManager.GetCurrentUser.UserName

            If (s.ToLower.Contains("es/default.aspx") Or s.ToLower.Contains("badgeaccess/default.aspx")) Then
                imgUserName.Visible = False
                hlUser.Visible = False
                lnkLogout.Visible = False

                pnlHead.Enabled = False
                pnlLeftNav.CssClass = "leftSidebarES"
                pnlContent.CssClass = "contentExpandedES"
                pnlExpColLefNav.Style.Add("Display", "none")
                pnlLeftNavContent.Width = 75
                menuHeader.Enabled = False
            End If

            If (menuHeader.FindItem("admin") IsNot Nothing) Then
                If Not (UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Or UserManager.GetCurrentUser.HasAdminReadOnlyAuthority) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("admin"))
                End If

                If (UserManager.GetCurrentUser.HasAdminReadOnlyAuthority And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                    menuHeader.FindItem("admin").NavigateUrl = "~/Admin/Jobs.aspx"
                ElseIf (UserManager.GetCurrentUser.IsTestCenterAdmin And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                    menuHeader.FindItem("admin").NavigateUrl = "~/Admin/TrackingLocations.aspx"
                End If
            End If

            If Not UserManager.GetCurrentUser.IsDeveloper Then
                If (menuHeader.FindItem("developer") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("developer"))
                End If
            End If

            'You are a relab role or your role has permission to view relab
            If Not (UserManager.GetCurrentUser.HasRelabAuthority() And UserManager.GetCurrentUser.HasRelabAccess()) Then
                If (menuHeader.FindItem("Results") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Results"))
                End If

                If (menuHeader.FindItem("Results") IsNot Nothing) Then
                    menuHeader.FindItem("Results").ChildItems.Remove(menuHeader.FindItem("Results/ResultsSearch"))
                End If
                'ResultsSearch
                If (menuHeader.FindItem("Search") IsNot Nothing) Then
                    menuHeader.FindItem("Search").ChildItems.Remove(menuHeader.FindItem("Search/ResultsSearch"))
                End If
            End If

            If Not (UserManager.GetCurrentUser.IsIncomingSpecialist OrElse UserManager.GetCurrentUser.IsMaterialsManagementSpecialist) Then
                If (menuHeader.FindItem("incoming") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("incoming"))
                End If
            End If

            If (REMIAppCache.GetMenuAccess(UserManager.GetCurrentUser.DepartmentID) Is Nothing) Then
                REMIAppCache.SetMenuAccess(UserManager.GetCurrentUser.DepartmentID, SecurityManager.GetMenuAccessByDepartment(String.Empty, UserManager.GetCurrentUser.DepartmentID))
            End If

            Dim dtMenuAccess As DataTable = REMIAppCache.GetMenuAccess(UserManager.GetCurrentUser.DepartmentID)

            If (REMIAppCache.GetUserServiceAccess(UserManager.GetCurrentUser.ID) Is Nothing) Then
                REMIAppCache.SetUserServiceAccess(UserManager.GetCurrentUser.ID, UserManager.GetCurrentUser.Services)
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Overview").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Overview") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Overview"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Search").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Search") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Search"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Scan Device").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Scan") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Scan"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Batch Info").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Batch") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Batch"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Product Info").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Product") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Product"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Tracking Location").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Tracking") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Tracking"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Timeline").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Timeline") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Timeline"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Incoming").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Incoming") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Incoming"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Inventory").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Inventory") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Inventory"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "User").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("User") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("User"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Results").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Results") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Results"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Result Search").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Results") IsNot Nothing) Then
                    menuHeader.FindItem("Results").ChildItems.Remove(menuHeader.FindItem("Results/ResultsSearch"))
                End If
                'ResultsSearch
                If (menuHeader.FindItem("Search") IsNot Nothing) Then
                    menuHeader.FindItem("Search").ChildItems.Remove(menuHeader.FindItem("Search/ResultsSearch"))
                End If
            End If

            If (Not (From ma In dtMenuAccess.AsEnumerable() Where ma.Field(Of String)("Name") = "Requests").FirstOrDefault() IsNot Nothing) Then
                If (menuHeader.FindItem("Requests") IsNot Nothing) Then
                    menuHeader.Items.Remove(menuHeader.FindItem("Requests"))
                End If
            End If
        End If
    End Sub
End Class