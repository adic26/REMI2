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

    <WebMethod(EnableSession:=True, Description:="Returns a list of the Jobs (Test Types) available. Represented as a list of strings. This method can be used to populate lists.")> _
    Public Function GetJobs(ByVal userIdentification As String, ByVal requestTypeID As Int32) As String()
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Dim jobs As String() = (From j As Job In JobManager.GetJobListDT(requestTypeID) Select j.Name).ToArray
                Return jobs
            End If
        Catch ex As Exception
            JobManager.LogIssue("REMI Internal Get jobs", "e3", NotificationType.Errors, ex)
        End Try
        Return Nothing
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

    <WebMethod(EnableSession:=True, Description:="")> _
    Public Function customSearch(ByVal requestTypeID As Int32, ByVal fields As List(Of String), ByVal userID As Int32) As String
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

            Dim results As DataTable = ReportManager.Search(requestTypeID, dt, userID)

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

    <WebMethod(EnableSession:=True, Description:="")> _
    Public Function colSearch(ByVal requestTypeID As Int32, ByVal fields As List(Of String), ByVal userID As Int32) As String
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

            Dim results As DataTable = ReportManager.Search(requestTypeID, dt, userID)

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
    Public Function GetAllStages(ByVal requestTypeID As Int32) As String
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

    <System.Web.Services.WebMethod()> _
    Public Function UpdateComment(ByVal value As String, ByVal ID As Int32, ByVal passFailOverride As Boolean, ByVal currentPassFail As Boolean, ByVal passFailText As String) As Boolean
        Return RelabManager.ModifyResult(value, ID, passFailOverride, currentPassFail, passFailText, UserManager.GetCurrentUser.UserName)
    End Function

    <System.Web.Services.WebMethod()> _
    Public Function GetSlides(ByVal contextKey As String) As AjaxControlToolkit.Slide()
        Dim dt As New DataTable
        Dim photos(dt.Rows.Count) As AjaxControlToolkit.Slide

        If (contextKey <> "0") Then
            dt = RelabManager.MeasurementFiles(contextKey, 0)

            For i = 0 To dt.Rows.Count - 1
                Dim imageDataURL As String = String.Format("http://{0}:{1}/Handlers/ImageHandler.ashx?img={2}&width=1024&height=768", System.Web.HttpContext.Current.Request.ServerVariables("SERVER_Name"), System.Web.HttpContext.Current.Request.ServerVariables("SERVER_PORT"), dt.Rows(i)("ID"))
                Dim downloadURL As String = String.Format("http://{0}:{1}/Handlers/Download.ashx?img={2}", System.Web.HttpContext.Current.Request.ServerVariables("SERVER_Name"), System.Web.HttpContext.Current.Request.ServerVariables("SERVER_PORT"), dt.Rows(i)("ID"))
                Dim fileName As String = dt.Rows(i)("FileName").ToString().Substring(dt.Rows(i)("FileName").ToString().Replace("/", "\").LastIndexOf("\") + 1)

                If (Helpers.IsRecognisedImageFile(fileName)) Then
                    photos(i) = New AjaxControlToolkit.Slide(imageDataURL, fileName, "<a href='" + downloadURL + "'>Download</a>")
                Else
                    Select Case (IO.Path.GetExtension(fileName).ToUpper)
                        Case "CSV"
                            photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/csv_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
                        Case "XLS"
                        Case "XLSX"
                            photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/xls_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
                        Case "XML"
                            photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/xml_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
                        Case "PPT"
                        Case "PPTX"
                            photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/ppt_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
                        Case "PDF"
                            photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/pdf_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
                        Case "TXT"
                            photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/txt_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
                        Case Else
                            photos(i) = New AjaxControlToolkit.Slide("../Design/Icons/png/128x128/txt_file.png", fileName, "<a href='" + downloadURL + "'>Download</a>")
                    End Select
                End If
            Next
        End If

        Return photos
    End Function
End Class