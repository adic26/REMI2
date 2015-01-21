Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports log4net
Imports REMI.Contracts
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
            ReportManager.LogIssue("REMIInternal Search", "e3", NotificationType.Errors, ex, String.Format("requestTypeID: {0} type: {1} ", requestTypeID, type))
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
        Dim tableTags As New StringBuilder()

        Try
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

            tableTags.Append("<thead><tr>")

            For Each dc As DataColumn In results.Columns
                tableTags.Append(String.Format("<th>{0}</th>", dc.ColumnName))
            Next

            tableTags.Append("</tr></thead>")
            tableTags.Append("<tbody>")

            For Each dr As DataRow In results.Rows
                tableTags.Append("<tr>")
                For Each d In dr.ItemArray

                    If (d.ToString = dr.ItemArray(0).ToString()) Then
                        tableTags.Append(String.Format("<td> <a href='http://go/requests/{0}' target='_blank'>{0}</a></td>", d.ToString()))
                    Else
                        If (d.ToString().StartsWith("http") Or d.ToString().StartsWith("www")) Then
                            tableTags.Append(String.Format("<td> <a href='{0}' target='_blank'>Link</a></td>", d.ToString()))
                        Else
                            tableTags.Append(String.Format("<td>{0}</td>", d.ToString()))
                        End If
                    End If
                Next
                tableTags.Append("</tr>")
            Next
            tableTags.Append("</tbody>")
        Catch ex As Exception
            Dim response As New StringBuilder()

            For Each str As String In fields
                response.AppendLine(str)
            Next

            ReportManager.LogIssue("REMIInternal Search", "e3", NotificationType.Errors, ex, String.Format("requestTypeID: {0} Fields: {1} ", requestTypeID, response))
        End Try

        Return tableTags.ToString()
    End Function

    <System.Web.Services.WebMethod()> _
    Public Shared Function colSearch(ByVal requestTypeID As Int32, ByVal fields As List(Of String)) As String
        Dim myList As New List(Of String)()
        Dim theads As New StringBuilder()

        Try
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

            theads.Append("<thead><tr>")

            For Each dc As DataColumn In results.Columns
                theads.Append("<th>" + dc.ColumnName + "</th>")
            Next
            theads.Append("</tr></thead>")
        Catch ex As Exception
            Dim response As New StringBuilder()

            For Each str As String In fields
                response.AppendLine(str)
            Next

            ReportManager.LogIssue("REMIInternal Search", "e3", NotificationType.Errors, ex, String.Format("requestTypeID: {0} Fields: {1} ", requestTypeID, response))
        End Try

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