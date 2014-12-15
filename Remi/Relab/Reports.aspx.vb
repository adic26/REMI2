Imports Remi.Bll
Imports Remi.Validation
Imports REMI.Contracts
Imports REMI.BusinessEntities

Public Class Reports
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

            ddlTests.Items.Clear()
            Dim tests As List(Of Test) = TestManager.GetTestsByType(TestType.Parametric, False)
            tests.Insert(0, New Test())
            ddlTests.DataSource = tests
            ddlTests.DataValueField = "ID"
            ddlTests.DataTextField = "Name"
            ddlTests.DataBind()
        End If

        If (ddlRequestType.Items.Count > 0 And ddlRequestType.SelectedIndex = -1) Then
            ddlRequestType.SelectedIndex = 0
        End If
        Dim dt As DataTable = ReportManager.SearchTree(ddlRequestType.SelectedValue)
    End Sub

    Protected Sub SetGvwHeader() Handles grdRequestSearch.PreRender
        Helpers.MakeAccessable(grdRequestSearch)
    End Sub

    Protected Sub btnSave_Click(ByVal sender As Object, ByVal e As EventArgs)
        If (txtSearchTerm.Text.Trim.Length > 0) Then
            lstSearchTerms.Items.Add(New ListItem(String.Format("Request:{0} ", txtSearchTerm.Text), ddlSearchField.SelectedItem.Value))
            txtSearchTerm.Text = String.Empty
        End If

        Dim testID As Int32
        Int32.TryParse(ddlTests.SelectedValue.ToString(), testID)

        If (testID > 0) Then
            lstSearchTerms.Items.Add(New ListItem(String.Format("Test:{0} ", ddlTests.SelectedItem.Text), testID))
            ddlTests.SelectedValue = 0
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
            Dim splitField As String() = field.Text.Split(":"c)

            dr("TableType") = splitField(0).Replace(":", String.Empty).Trim()
            dr("ID") = field.Value
            dr("SearchTerm") = splitField(1).Trim()
            dr("ColumnName") = String.Empty

            searchFields.Rows.Add(dr)
        Next

        grdRequestSearch.DataSource = ReportManager.Search(ddlRequestType.SelectedItem.Value, searchFields)
        grdRequestSearch.DataBind()
    End Sub


    <System.Web.Services.WebMethod()> _
    Public Shared Function Search(ByVal requestTypeID As Int32) As DataTable
        Return ReportManager.SearchTree(requestTypeID)
    End Function

End Class