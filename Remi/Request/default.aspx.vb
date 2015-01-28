Imports REMI.Bll
Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.BusinessEntities

Public Class ReqDefault
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If (Not Page.IsPostBack) Then
            ddlRequestType.DataSource = RequestManager.GetRequestTypes()
            ddlRequestType.DataBind()

            Dim requestType As String = IIf(Request.QueryString.Item("rt") Is Nothing, String.Empty, Request.QueryString.Item("rt"))

            If (requestType.Trim().Length > 0) Then
                ddlRequestType.Items.FindByText(requestType).Selected = True
            End If

            If (ddlRequestType.Items.Count > 0 And ddlRequestType.SelectedIndex = -1) Then
                ddlRequestType.SelectedIndex = 0
            End If

            UpdateLinks()
        End If

    End Sub

    Protected Sub ddlRequestType_SelectedIndexChanged(sender As Object, e As EventArgs)
        UpdateLinks()
    End Sub

    Private Sub UpdateLinks()
        lblRequest.Text = ddlRequestType.SelectedItem.Text

        If ((From dr As DataRow In UserManager.GetCurrentUser.RequestTypes.Rows Where dr.Field(Of Boolean)("IsAdmin") = True And dr.Field(Of Int32)("RequestTypeID") = ddlRequestType.SelectedItem.Value).FirstOrDefault() IsNot Nothing) Then
            Dim myMenu As WebControls.Menu
            Dim mi As New MenuItem
            myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

            mi = New MenuItem
            mi.Text = "Admin"
            mi.Target = "_blank"
            mi.NavigateUrl = String.Format("/Request/Admin.aspx?rt={0}&id={1}", ddlRequestType.SelectedItem.Text, ddlRequestType.SelectedItem.Value)
            myMenu.Items(0).ChildItems.Add(mi)
            hypAdmin.Visible = True
            hypAdmin.NavigateUrl = String.Format("/Request/Admin.aspx?rt={0}&id={1}", ddlRequestType.SelectedItem.Text, ddlRequestType.SelectedItem.Value)
        End If

        srcRequest.RequestType = ddlRequestType.SelectedItem.Value
        srcRequest.Visible = True
        hypNew.NavigateUrl = String.Format("/Request/Request.aspx?type={0}", ddlRequestType.SelectedItem.Text)
    End Sub
End Class
