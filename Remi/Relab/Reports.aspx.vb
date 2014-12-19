Imports Remi.Bll
Imports Remi.Validation
Imports REMI.Contracts
Imports Remi.BusinessEntities
Imports System.Web.Script.Serialization
Imports System.Web
Imports System.Linq

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

            'ddlSearchField.DataSource = RequestManager.GetRequestParent(ddlRequestType.SelectedItem.Value)
            'ddlSearchField.DataBind()

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
    End Sub

    Protected Sub SetGvwHeader() Handles grdRequestSearch.PreRender
        Helpers.MakeAccessable(grdRequestSearch)
    End Sub

    Protected Sub btnSave_Click(ByVal sender As Object, ByVal e As EventArgs)
        If (txtSearchTerm.Text.Trim.Length > 0) Then
            'lstSearchTerms.Items.Add(New ListItem(String.Format("Request:{0} ", txtSearchTerm.Text), ddlSearchField.SelectedItem.Value))
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


    Public Shared Function Search_FieldResponse(ByVal requestTypeID As Int32, ByVal type As String) As List(Of SearchFieldResponse)
        'Return ReportManager.SearchTree(requestTypeID)
        Dim st As DataTable = ReportManager.SearchTree(requestTypeID)
        Dim myQuery As New List(Of SearchFieldResponse)()
        Dim myList As New List(Of SearchFieldResponse)()
        Dim q

        For Each row As DataRow In st.Rows
            Dim searchfieldResponse As New SearchFieldResponse()
            searchfieldResponse.TestID = row("ID")
            searchfieldResponse.Name = row("Name")
            searchfieldResponse.Type = row("Type")
            myList.Add(searchfieldResponse)
        Next

            q = From x In myList
                  Where x.Type = type
                  Select x

        For Each item In q
            myQuery.Add(CType(item, SearchFieldResponse))
        Next

        Return myQuery
    End Function

    Public Shared Function Search_FieldResponse(ByVal requestTypeID As Int32) As List(Of SearchFieldResponse)
        'Return ReportManager.SearchTree(requestTypeID)
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
        'Return myList.GetRange(0, myList.Count - 1)
        'Return myList

    End Function

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
        'Return True
    End Function

    <System.Web.Services.WebMethod()> _
    Public Shared Function GetAllStages(ByVal requestTypeID As Int32) As String
        Dim searchField As New SearchFieldResponseDefinition()
        Try
            searchField.Results = Search_FieldResponse(requestTypeID)
            searchField.Success = True
        Catch ex As Exception
            Console.WriteLine(ex.Message)
        End Try

        Dim query = From x In searchField.Results
                    Where x.Type = "Stage"
                    Select "<option>" + x.Name + "</option>"

        Dim responseBuilder As New StringBuilder()

        For Each x As String In query
            responseBuilder.Append(x)
        Next

        Return responseBuilder.ToString()
    End Function





End Class