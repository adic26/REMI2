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
        End If

        If (ddlRequestType.Items.Count > 0 And ddlRequestType.SelectedIndex = -1) Then
            ddlRequestType.SelectedIndex = 0
        End If

        lblRequest.Text = ddlRequestType.SelectedItem.Text
        hypAdmin.NavigateUrl = String.Format("/Request/Admin.aspx?rt={0}&id={1}", ddlRequestType.SelectedItem.Text, ddlRequestType.SelectedItem.Value)
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

    <System.Web.Services.WebMethod()> _
    Public Shared Function Search(ByVal requestTypeID As Int32, ByVal type As String) As SearchFieldResponseDefinition
        Dim response As New SearchFieldResponseDefinition()
        Try
            response.Results = Search_FieldResponse(requestTypeID)
            response.Success = True
        Catch ex As Exception
            Console.WriteLine(ex.Message)
        End Try

        Return response
    End Function

    Public Shared Function Search_FieldResponse(ByVal requestTypeID As Int32) As List(Of SearchFieldResponse)
        Dim st As DataTable = ReportManager.SearchTree(requestTypeID)
        Dim myList As New List(Of SearchFieldResponse)()

        For Each row As DataRow In st.Rows
            Dim searchfieldResponse As New SearchFieldResponse()
            searchfieldResponse.TestID = row("ID")
            searchfieldResponse.Name = row("Name")
            searchfieldResponse.Type = row("Type")
            myList.Add(searchfieldResponse)
        Next

        Return myList
    End Function


    <System.Web.Services.WebMethod()> _
    Public Shared Function customSearch(ByVal requestTypeID As Int32, ByVal fields As List(Of String)) As String
        Dim myList As New List(Of String)()

        Dim dt As New DataTable("fields")
        dt.Columns.Add("TableType", GetType(String))
        dt.Columns.Add("ID", GetType(Int32))
        dt.Columns.Add("SearchTerm", GetType(String))
        dt.Columns.Add("ColumnName", GetType(String))

        For Each Str As String In fields
            Dim splittingStr() As String = Str.Split(","c)

            Dim r As DataRow = dt.NewRow
            r("TableType") = splittingStr(0)
            r("ID") = splittingStr(1)
            r("SearchTerm") = splittingStr(2)
            r("ColumnName") = String.Empty
            dt.Rows.Add(r)
        Next

        Dim results As DataTable = ReportManager.Search(requestTypeID, dt)
        Dim tableTags As New StringBuilder()

        tableTags.Append("<thead><tr>")

        For Each dc As DataColumn In results.Columns
            tableTags.Append("<th>" + dc.ColumnName + "</th>")
        Next

        tableTags.Append("</tr></thead>")
        tableTags.Append("<tbody>")

        For Each dr As DataRow In results.Rows
            tableTags.Append("<tr>")
            For Each d In dr.ItemArray
                tableTags.Append("<td>" + d.ToString() + "</td>")
            Next
            tableTags.Append("</tr>")
        Next
        tableTags.Append("</tbody>")

        Return tableTags.ToString()
    End Function
End Class

