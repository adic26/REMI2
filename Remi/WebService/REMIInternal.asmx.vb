Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
Imports REMI.Validation
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports log4net
Imports REMI.Contracts
Imports System.Data
Imports System.Drawing
Imports System.IO
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

    <WebMethod(EnableSession:=False, Description:="")> _
    Public Function GetEnum(ByVal type As String) As SearchFieldResponseDefinition
        Dim response As New SearchFieldResponseDefinition()
        Dim myList As New List(Of SearchFieldResponse)
        Try
            Dim base As Type

            Select Case type
                Case "BatchSearchBatchStatus"
                    base = GetType(BatchSearchBatchStatus)
            End Select

            Dim myEnumFields As Reflection.FieldInfo() = base.GetFields()
            For Each myField As Reflection.FieldInfo In myEnumFields
                If Not myField.IsSpecialName AndAlso myField.Name.ToLower() <> "notset" AndAlso myField.Name.ToLower() <> "notsavedtoremi" Then
                    Dim id As Int32 = DirectCast(System.Enum.Parse(base, myField.Name), Int32)

                    myList.Add(New SearchFieldResponse(myField.Name, type, id))
                End If
            Next
            response.Results = myList
            response.Success = True
        Catch ex As Exception
            ReportManager.LogIssue("REMIInternal GetEnum", "e3", NotificationType.Errors, ex, String.Format("Type: {0} ", type))
        End Try
        Return response
    End Function

    <WebMethod(Description:="Given a job name this function returns all the known stages of the job.")> _
    Public Function GetJobStages(ByVal jobID As Int32) As TestStageCollection
        Try
            Return TestStageManager.GetList(TestStageType.NotSet, String.Empty, False, jobID)
        Catch ex As Exception
            JobManager.LogIssue("REMI Internal GetJobStages", "e3", NotificationType.Errors, ex, String.Format("jobID: {0}", jobID.ToString()))
        End Try
        Return Nothing
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns a list of the Jobs (Test Types) available. Represented as a list of strings. This method can be used to populate lists.")> _
    Public Function GetJobs(ByVal userIdentification As String, ByVal requestTypeID As Int32) As JobCollection
        Try
            If UserManager.SetUserToSession(userIdentification) Then
                Return JobManager.GetJobListDT(requestTypeID, UserManager.GetCurrentUser.ID, 0)
            End If
        Catch ex As Exception
            JobManager.LogIssue("REMI Internal GetJobs", "e3", NotificationType.Errors, ex, String.Format("requestTypeID: {0} userIdentification: {1} ", requestTypeID, userIdentification))
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

            ReportManager.LogIssue("REMIInternal customSearch", "e3", NotificationType.Errors, ex, String.Format("requestTypeID: {0} Fields: {1} userID: {2}", requestTypeID, response, userID))
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

            ReportManager.LogIssue("REMIInternal colSearch", "e3", NotificationType.Errors, ex, String.Format("requestTypeID: {0} Fields: {1} userID: {2}", requestTypeID, response, userID))
        End Try

        Return theads.ToString()
    End Function

    <System.Web.Services.WebMethod()> _
    Public Function UpdateComment(ByVal value As String, ByVal ID As Int32, ByVal passFailOverride As Boolean, ByVal currentPassFail As Boolean, ByVal passFailText As String) As Boolean
        Return RelabManager.ModifyResult(value, ID, passFailOverride, currentPassFail, passFailText, UserManager.GetCurrentUser.UserName)
    End Function

    <System.Web.Services.WebMethod()> _
    <System.Web.Script.Services.ScriptMethod()> _
    Public Function GetSlidesJS(ByVal contextKey As String) As List(Of String)
        Dim dt As New DataTable
        Dim lnkBuilder As New List(Of String)

        If (contextKey <> "0") Then
            dt = RelabManager.MeasurementFiles(contextKey, 0)

            For i = 0 To dt.Rows.Count - 1
                Dim imageDataURL As String = String.Format("http://{0}:{1}/Handlers/ImageHandler.ashx?img={2}&width=1024&height=768", System.Web.HttpContext.Current.Request.ServerVariables("SERVER_Name"), System.Web.HttpContext.Current.Request.ServerVariables("SERVER_PORT"), dt.Rows(i)("ID"))
                Dim downloadURL As String = String.Format("http://{0}:{1}/Handlers/Download.ashx?img={2}", System.Web.HttpContext.Current.Request.ServerVariables("SERVER_Name"), System.Web.HttpContext.Current.Request.ServerVariables("SERVER_PORT"), dt.Rows(i)("ID"))
                Dim fileName As String = dt.Rows(i)("FileName").ToString().Substring(dt.Rows(i)("FileName").ToString().Replace("/", "\").LastIndexOf("\") + 1)

                If (Helpers.IsRecognisedImageFile(fileName)) Then
                    lnkBuilder.Add(imageDataURL.ToString())
                Else
                    lnkBuilder.Add(downloadURL.ToString())
                End If

            Next
        End If

        Return lnkBuilder
    End Function
End Class