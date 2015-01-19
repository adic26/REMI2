﻿Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Bll
Imports log4net
Imports Remi.Contracts
Imports System.Data
Imports System.Web.Script.Services

<System.Web.Services.WebService(Name:="REMIInternal", Namespace:="http://go/remi/")> _
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<ToolboxItem(False)> _
<ScriptService()> _
Public Class REMIInternal
    Inherits System.Web.Services.WebService

    <WebMethod(EnableSession:=False, Description:="")> _
    Public Function Search(ByVal requestTypeID As Int32, ByVal type As String) As SearchFieldResponseDefinition
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

    <WebMethod(EnableSession:=False, Description:="")> _
    Public Function customSearch(ByVal requestTypeID As Int32, ByVal fields As List(Of String)) As String
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

    <System.Web.Services.WebMethod()> _
    Public Shared Function colSearch(ByVal requestTypeID As Int32, ByVal fields As List(Of String)) As String
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
        Dim theads As New StringBuilder()

        theads.Append("<thead><tr>")

        For Each dc As DataColumn In results.Columns
            theads.Append("<th>" + dc.ColumnName + "</th>")
        Next
        theads.Append("</tr></thead>")

        Return theads.ToString()
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