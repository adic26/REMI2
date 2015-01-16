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

            ddlSearchField.DataSource = RequestManager.GetRequestParent(ddlRequestType.SelectedItem.Value)
            ddlSearchField.DataBind()
            If (ddlRequestType.Items.Count > 0 And ddlRequestType.SelectedIndex = -1) Then
                ddlRequestType.SelectedIndex = 0
            End If

            UpdateLinks()
        End If

    End Sub

    Protected Sub SetGvwHeader() Handles grdRequestSearch.PreRender
        Helpers.MakeAccessable(grdRequestSearch)
    End Sub

    Protected Sub btnSave_Click(ByVal sender As Object, ByVal e As EventArgs)
        If (txtSearchTerm.Text.Trim.Length > 0) Then
            lstSearchTerms.Items.Add(New ListItem(txtSearchTerm.Text, ddlSearchField.SelectedItem.Value))
        End If
    End Sub

    Protected Sub btnSearch_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim searchFields As New DataTable("SearchFields")
        searchFields.Columns.Add("TableType", GetType(String))
        searchFields.Columns.Add("ID", GetType(Int32))
        searchFields.Columns.Add("SearchTerm", GetType(String))
        searchFields.Columns.Add("ColumnName", GetType(String))

        For Each field As ListItem In lstSearchTerms.Items
            Dim dr As DataRow = searchFields.NewRow
            dr("TableType") = "Request"
            dr("ID") = field.Value
            dr("SearchTerm") = field.Text
            dr("ColumnName") = String.Empty

            searchFields.Rows.Add(dr)
        Next

        grdRequestSearch.DataSource = ReportManager.Search(ddlRequestType.SelectedItem.Value, searchFields)
        grdRequestSearch.DataBind()
    End Sub

    Protected Sub ddlRequestType_SelectedIndexChanged(sender As Object, e As EventArgs)
        UpdateLinks()
    End Sub

    Private Sub UpdateLinks()
        Dim myMenu As WebControls.Menu
        Dim mi As New MenuItem
        myMenu = CType(Master.FindControl("menuHeader"), WebControls.Menu)

        mi = New MenuItem
        mi.Text = "Admin"
        mi.Target = "_blank"
        mi.NavigateUrl = String.Format("/Request/Admin.aspx?rt={0}&id={1}", ddlRequestType.SelectedItem.Text, ddlRequestType.SelectedItem.Value)
        myMenu.Items(0).ChildItems.Add(mi)

        lblRequest.Text = ddlRequestType.SelectedItem.Text
        hypAdmin.NavigateUrl = String.Format("/Request/Admin.aspx?rt={0}&id={1}", ddlRequestType.SelectedItem.Text, ddlRequestType.SelectedItem.Value)
    End Sub
End Class