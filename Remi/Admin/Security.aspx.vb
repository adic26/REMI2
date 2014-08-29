Imports Remi.Bll
Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Contracts

Public Class Security
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not (Page.IsPostBack) Then
            If Not UserManager.GetCurrentUser.IsAdmin Then
                Response.Redirect("~/")
            End If
            gvwSecurity.DataSource = SecurityManager.GetRolesPermissionsGrid()
            gvwSecurity.DataBind()
        End If

    End Sub

    Protected Sub SetGvwHeader() Handles gvwSecurity.PreRender
        Helpers.MakeAccessable(gvwSecurity)
    End Sub

    Protected Sub btnAddRole_OnClick(ByVal sender As Object, ByVal e As System.EventArgs)
        SecurityManager.AddNewRole(txtNewRole.Text)
        txtNewRole.Text = String.Empty
        gvwSecurity.DataSource = SecurityManager.GetRolesPermissionsGrid()
        gvwSecurity.DataBind()
    End Sub

    Protected Sub gvwSecurity_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles gvwSecurity.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            e.Row().Cells(0).CssClass = "removeStyle"

            For i As Integer = 1 To e.Row().Cells.Count - 1
                Dim chk As New CheckBox()
                If (e.Row().Cells(i).Text = "1") Then
                    chk.Checked = True
                End If
                chk.InputAttributes.Add("onclick", "EnableDisablePermission_Click('" & e.Row().Cells(0).Text & "', '" & gvwSecurity.HeaderRow.Cells(i).Text & "');")


                e.Row().Cells(i).Controls.Add(chk)
            Next
        End If
    End Sub

    <System.Web.Services.WebMethod()> _
    Public Shared Function AddRemovePermission(ByVal permission As String, ByVal role As String) As Boolean
        Dim success As Boolean = SecurityManager.AddRemovePermission(permission, role)

        If (success) Then
            REMIAppCache.RemovePermission(permission)
        End If

        Return success
    End Function
End Class