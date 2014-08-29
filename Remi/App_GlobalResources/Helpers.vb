Imports System.Data.SqlClient
Imports System.Data
Imports System.Collections.Generic
Imports System.Data.Common
Imports System.Reflection
Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Validation
Imports System
Imports System.Configuration
Imports System.IO
Imports System.Web
Imports System.Web.Security
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Web.UI.WebControls.WebParts
Imports System.Web.UI.HtmlControls
Imports REMI.Contracts

Public Class Helpers
    Public Shared Function GetCurrentUserLDAPName() As String
        Return UserManager.GetCurrentValidUserLDAPName
    End Function

    Public Shared Function GetDateTimeFileName(ByVal text As String, ByVal suffix As String) As String
        text = text.Trim
        If text.Length > 250 Then
            text = text.Remove(250, text.Length - 250)
        End If
        If String.IsNullOrEmpty(suffix) Then
            suffix = "txt"
        End If
        text = Regex.Replace(text, "[^\w\.-]", "_")
        Return String.Format("{0}_{1:yyyy-MM-dd_hh-mm-ss-tt}.{2}", text, DateTime.Now, suffix)
    End Function

    Public Shared Function GetAsyncPostBackControlID(ByVal page As Page) As String
        Dim smUniqueId As String = ScriptManager.GetCurrent(page).UniqueID
        Dim smFieldValue As String = page.Request.Form(smUniqueId)

        If Not [String].IsNullOrEmpty(smFieldValue) AndAlso smFieldValue.Contains("|"c) Then
            Return smFieldValue.Split("|"c)(1)
        End If

        Return [String].Empty
    End Function


    Public Shared Function GetPostBackControl(page As Page) As Control
        Dim control As Control = Nothing
        Dim ctrlname As String = page.Request.Params.[Get]("__EVENTTARGET")
        If ctrlname IsNot Nothing AndAlso ctrlname <> [String].Empty Then
            control = page.FindControl(ctrlname)
        Else
            For Each ctl As String In page.Request.Form
                Dim c As Control = page.FindControl(ctl)
                If TypeOf c Is System.Web.UI.WebControls.Button Then
                    control = c
                    Exit For
                ElseIf TypeOf c Is System.Web.UI.WebControls.ImageButton Then
                    control = c
                    Exit For
                End If
            Next
        End If
        Return control
    End Function

    Public Shared Function GetStringMaxLength(text As String, maxLength As Integer) As String
        If String.IsNullOrEmpty(text) Then
            Return String.Empty
        End If

        If text.Length > maxLength Then
            Return text.Substring(0, maxLength)
        End If

        Return text
    End Function

    Public Shared Sub ExportToXML(ByVal fileName As String, ByVal xml As XDocument)
        Dim response As HttpResponse = HttpContext.Current.Response
        response.Clear()
        response.ClearContent()
        response.ClearHeaders()
        response.Charset = "UTF-8"
        response.ContentType = "application/text"
        response.AddHeader("Content-Disposition", "attachment;filename=""" & fileName & """")
        response.CacheControl = "no-cache"

        Using sw As New StringWriter()
            Using htw As New HtmlTextWriter(sw)
                Dim dg As New Label
                dg.Text = xml.ToString()
                dg.ID = "test"
                dg.RenderControl(htw)
                response.Write(sw.ToString())
                response.Flush()
                response.End()
            End Using
        End Using
    End Sub

    Public Shared Sub ExportToExcel(ByVal fileName As String, ByVal dt As DataTable)
        Dim response As HttpResponse = HttpContext.Current.Response
        response.Clear()
        response.ClearContent()
        response.ClearHeaders()
        response.Charset = "UTF-8"
        response.ContentType = "application/x-msexcel"
        response.AddHeader("Content-Disposition", "attachment;filename=""" & fileName & """")
        response.CacheControl = "no-cache"

        Using sw As New StringWriter()
            Using htw As New HtmlTextWriter(sw)
                Dim dg As New DataGrid()
                dg.ID = "test"
                dg.DataSource = dt
                dg.DataBind()
                dg.RenderControl(htw)
                response.Write(sw.ToString())
                response.Flush()
                response.End()
            End Using
        End Using
    End Sub

    Public Shared Sub ExportToExcel(ByVal fileName As String, ByVal gv As GridView)
        HttpContext.Current.Response.Clear()
        HttpContext.Current.Response.AddHeader("content-disposition", String.Format("attachment; filename={0}", fileName))
        HttpContext.Current.Response.ContentType = "application/ms-excel"
        Dim sw As StringWriter = New StringWriter
        Dim htw As HtmlTextWriter = New HtmlTextWriter(sw)
        '  Create a form to contain the grid
        Dim table As Table = New Table
        table.GridLines = gv.GridLines
        '  add the header row to the table
        If (Not (gv.HeaderRow) Is Nothing) Then
            PrepareControlForExport(gv.HeaderRow)
            table.Rows.Add(gv.HeaderRow)
        End If
        '  add each of the data rows to the table
        For Each row As GridViewRow In gv.Rows
            For Each c As TableCell In row.Cells
                If c.Controls.Count = 0 Then
                    Regex.Replace(c.Text, "<a[^>]+>([^<]+)</a>", "")
                End If
            Next
            PrepareControlForExport(row)
            table.Rows.Add(row)
        Next
        '  add the footer row to the table
        If (Not (gv.FooterRow) Is Nothing) Then
            PrepareControlForExport(gv.FooterRow)
            table.Rows.Add(gv.FooterRow)
        End If
        '  render the table into the htmlwriter
        table.RenderControl(htw)
        '  render the htmlwriter into the response
        HttpContext.Current.Response.Write(sw.ToString)
        HttpContext.Current.Response.End()
    End Sub

    ' Replace any of the contained controls with literals
    Private Shared Sub PrepareControlForExport(ByVal control As Control)
        Dim i As Integer = 0
        Do While (i < control.Controls.Count)
            Dim current As Control = control.Controls(i)
            If (TypeOf current Is LinkButton) Then
                control.Controls.Remove(current)
                control.Controls.AddAt(i, New LiteralControl(CType(current, LinkButton).Text))
            ElseIf (TypeOf current Is ImageButton) Then
                control.Controls.Remove(current)
                control.Controls.AddAt(i, New LiteralControl(CType(current, ImageButton).AlternateText))
            ElseIf (TypeOf current Is HyperLink) Then
                control.Controls.Remove(current)
                control.Controls.AddAt(i, New LiteralControl(CType(current, HyperLink).Text))
            ElseIf (TypeOf current Is DropDownList) Then
                control.Controls.Remove(current)
                control.Controls.AddAt(i, New LiteralControl(CType(current, DropDownList).SelectedItem.Text))
            ElseIf (TypeOf current Is CheckBox) Then
                control.Controls.Remove(current)
                control.Controls.AddAt(i, New LiteralControl(CType(current, CheckBox).Checked))
            End If

            If current.HasControls Then
                PrepareControlForExport(current)
            End If
            i = (i + 1)
        Loop
    End Sub

    ''' <summary>
    ''' This function gets the current filename of the aspx web page used for creating links back to the current page to refresh the page.
    ''' </summary>
    ''' <returns>the current filename of the aspx web page</returns>
    ''' <remarks></remarks>
    Public Shared Function GetCurrentPageName() As String
        Dim sPath As String = System.Web.HttpContext.Current.Request.Url.AbsolutePath
        Dim oInfo As System.IO.FileInfo = New System.IO.FileInfo(sPath)
        Dim sRet As String = oInfo.Name
        Return sRet
    End Function

    'same with the method below
    ''' <summary>
    ''' This function is used to have the render engine generate tables in an accessable manner (and to match the css standard compliance) so that the
    ''' headers are rendered using <code><thead> </thead></code> and then this can be styled by the css.
    ''' </summary>
    ''' <param name="tmpGridview">The gridview to make accessable</param>
    ''' <remarks></remarks>
    Public Shared Sub MakeAccessable(ByVal tmpGridview As GridView)
        If tmpGridview.Rows.Count > 0 Then
            tmpGridview.UseAccessibleHeader = True
            tmpGridview.HeaderRow.TableSection = TableRowSection.TableHeader
        End If
    End Sub

    ''' <summary>
    ''' Searches a gridviews columns for a name and returns the index of the last column with that name found.
    ''' </summary>
    ''' <param name="columnName">The name of the column to search for.</param>
    ''' <param name="gvw">the grdview to search in.</param>
    ''' <returns>The index of the column with the specified name.</returns>
    ''' <remarks></remarks>
    Public Shared Function TryGetColumnIndexByColumnName(ByVal columnName As String, ByVal gvw As GridView, ByRef colIndex As Integer) As Boolean
        For i As Integer = 0 To gvw.Columns.Count - 1
            If gvw.Columns(i).HeaderText = columnName Then
                colIndex = i
                Return True
            End If
        Next
        Return False
    End Function

    Public Shared Function GetExceptionMessages(ByVal ex As Exception) As NotificationCollection
        Dim n As New NotificationCollection
        If ex IsNot Nothing Then
            n.AddWithMessage(String.Format("REMI Error. Contact remi@blackberry.com ({0})", ex.Message), NotificationType.Errors)
            Return n
        End If
        Return Nothing
    End Function

#Region "Text cleanup methods for displaying database data"
    ''' <summary>
    ''' Cleans up the input text that a user enters and checks that the length is ok before trying to save any of it back.
    ''' this will remove html tags, extra spaces and other html related problematic characters.
    ''' </summary>
    ''' <param name="text">The string to clean</param>
    ''' <param name="maxLength">The length of the string</param>
    ''' <returns>Cleaned up text</returns>
    Public Shared Function CleanInputText(ByVal text As String, ByVal maxLength As Integer) As String
        text = text.Trim
        If (String.IsNullOrEmpty(text)) Then
            Return String.Empty
        End If
        If (text.Length > maxLength) Then
            text = text.Substring(0, maxLength)
        End If
        text = Regex.Replace(text, "[\s]{2,}", " ")    'two or more spaces
        Return text
    End Function

    ''' <summary>
    ''' converts a string from camel case to include spaces.
    ''' </summary>
    ''' <param name="camelCase">the camel case string</param>
    ''' <returns>the string returned with spaces.</returns>
    ''' <remarks></remarks>
    Public Shared Function FromCamelCase(ByVal camelCase As String) As String
        If String.IsNullOrEmpty(camelCase) Then
            Return String.Empty
        End If

        Dim sb As StringBuilder = New StringBuilder(camelCase.Length + 10)
        Dim first As Boolean = True
        Dim lastChar As Char = vbNullChar
        Dim nextChar As Char = vbNullChar
        Dim currentChar As Char = vbNullChar

        For i As Integer = 0 To camelCase.Length - 1
            currentChar = camelCase.Chars(i)
            If i <= camelCase.Length - 2 Then
                nextChar = camelCase.Chars(i + 1)
            End If

            If (Not (first) AndAlso (Char.IsUpper(currentChar) AndAlso (Char.IsLower(nextChar) Or Char.IsLower(lastChar))) Or (Char.IsDigit(currentChar) AndAlso Not (Char.IsDigit(lastChar)))) Then
                sb.Append(" "c)
            End If

            sb.Append(currentChar)
            first = False
            lastChar = currentChar
        Next

        Return sb.ToString()
    End Function

    ''' <summary>
    ''' Formats the username to remove the "RIMNET/" String
    ''' </summary>
    ''' <param name="tmpObj">The username string to format</param>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Shared Function UserNameformat(ByVal tmpObj As Object) As String
        Dim returnVal As String = String.Empty
        If Not IsDBNull(tmpObj) Then
            If Not tmpObj Is Nothing Then
                Dim tmpName As String = DirectCast(tmpObj, String)
                If tmpName.StartsWith("RIMNET\") Then
                    returnVal = tmpName.Remove(0, 7)
                Else
                    returnVal = tmpName
                End If
            End If
        End If
        Return returnVal
    End Function

    ''' <summary>
    ''' Formats a datetime to convert it from UTC to the local time. this is required becuase of the global nature of the application.
    ''' </summary>
    ''' <param name="tmpObject">The utc time to display in local time.</param>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Shared Function DateTimeformat(ByVal tmpObject As Object) As String
        Dim tmpDateTime As DateTime
        If tmpObject IsNot Nothing AndAlso DateTime.TryParse(tmpObject.ToString, tmpDateTime) Then
            If (tmpDateTime = DateTime.MinValue) Then
                Return String.Empty
            Else
                Return String.Format(System.Globalization.CultureInfo.CurrentCulture, "{0:g}", tmpDateTime.ToLocalTime)
            End If
        Else
            If tmpObject Is Nothing Or tmpObject Is DBNull.Value Then
                Return String.Empty
            Else
                Return tmpObject
            End If
        End If
    End Function

    ''' <summary>
    ''' Formats a datetime to convert it to a date only.
    ''' </summary>
    ''' <param name="tmpObject">The utc time to display in local time.</param>
    ''' <returns></returns>
    ''' <remarks></remarks>
    Public Shared Function DateFormat(ByVal tmpObject As Object) As String
        Dim tmpDateTime As DateTime
        If tmpObject IsNot Nothing AndAlso DateTime.TryParse(tmpObject.ToString, tmpDateTime) Then
            If (tmpDateTime = DateTime.MinValue) Then
                Return String.Empty
            Else
                Return String.Format("{0:d}", tmpDateTime)
            End If
        Else
            Return tmpObject
        End If
    End Function

    ''' <summary>
    ''' Formats the duration field in to a string representing days hours and minutes
    ''' </summary>
    ''' <param name="duration">the duration to represent</param>
    ''' <returns>A string of {0}d {1}h {2}m</returns>
    ''' <remarks></remarks>
    Public Shared Function DurationFormat(ByVal duration As TimeSpan) As String
        Dim durstring As String = String.Format("{0}h", duration.TotalHours)
        Return durstring
    End Function

    Public Shared Function TrueFalseToYesNo(ByVal inStr As String) As String
        If inStr.ToLower = "true" Then
            Return "Yes"
        ElseIf inStr.ToLower = "false" Then
            Return "No"
        Else
            Return inStr
        End If
    End Function

    Public Shared Function FormatBatchStatus(ByVal bs As BatchStatus) As String
        If bs = BatchStatus.NotSet Then
            Return String.Empty
        Else
            Return bs.ToString
        End If
    End Function

    'Public Shared Function FormatRequestPurpose(ByVal rp As RequestPurpose) As String
    '    If rp = RequestPurpose.NotSet Then
    '        Return String.Empty
    '    Else
    '        Return rp.ToString
    '    End If
    'End Function
#End Region

#Region "Enum Section: Returns the enum lists without the ""NotSet"" option for times when this is not appropriate(e.g. Value is required)"
    ''' <summary> 
    ''' Gets a list of items from the TrackingLocationFunction enum for a DropDownList. 
    ''' </summary> 
    Public Shared Function GetTrackingLocationFunctions() As List(Of ListItem)
        Return GetEnumMembers(GetType(TrackingLocationFunction))
    End Function

    Public Shared Function GetTrackingLocationStatus() As List(Of ListItem)
        Return GetEnumMembers(GetType(TrackingLocationStatus))
    End Function

    ''' <summary> 
    ''' Gets a list of items from the TestType enum for a DropDownList. 
    ''' </summary> 
    Public Shared Function GetTestTypes() As List(Of ListItem)
        Return GetEnumMembers(GetType(TestType))
    End Function

    ''' <summary> 
    ''' Gets a list of items from the BatchStatus enum for a DropDownList. 
    ''' </summary> 
    Public Shared Function GetBatchStatus() As List(Of ListItem)
        Return GetEnumMembers(GetType(BatchStatus))
    End Function

    ''' <summary> 
    ''' Gets a list of items from the BatchStatus enum for a DropDownList. 
    ''' </summary> 
    'Public Shared Function GetRequestPurposeList() As List(Of ListItem)
    '    Return GetEnumMembers(GetType(RequestPurpose))
    'End Function

    ''' <summary> 
    ''' Gets a list of items from the TestStageType enum for a DropDownList. 
    ''' </summary> 
    Public Shared Function GetTestStageTypes() As List(Of ListItem)
        Return GetEnumMembers(GetType(TestStageType))
    End Function

    ''' <summary> 
    ''' Gets a list of items from the final Test Result enum for a DropDownList. 
    ''' </summary> 
    Public Shared Function GetFinalTestResultFields() As List(Of ListItem)
        Return GetEnumMembers(GetType(FinalTestResult))
    End Function

    ''' <summary> 
    ''' Helper method to get items from an enum. 
    ''' Code inspired by http://www.codeproject.com/cs/miscctrl/enumedit.asp 
    ''' </summary> 
    ''' <param name="theType">The type of the enum for which the items are retrieved.</param> 
    Private Shared Function GetEnumMembers(ByVal theType As Type) As List(Of ListItem)
        Dim myList As New List(Of ListItem)()
        Dim myEnumFields As FieldInfo() = theType.GetFields()
        For Each myField As FieldInfo In myEnumFields
            If Not myField.IsSpecialName AndAlso myField.Name.ToLower() <> "notset" AndAlso myField.Name.ToLower() <> "notsavedtoremi" Then
                myList.Add(New ListItem(myField.Name, myField.Name))
            End If
        Next
        Return myList
    End Function

    ''' <summary> 
    ''' Helper method to get items from test record status enum but exclude the ones
    ''' that should not be set manually.
    ''' Code inspired by http://www.codeproject.com/cs/miscctrl/enumedit.asp 
    ''' </summary> 
    Public Shared Function GetTestRecordStatusList() As List(Of ListItem)
        Dim myList As New List(Of ListItem)()
        Dim myEnumFields As FieldInfo() = GetType(TestRecordStatus).GetFields()
        For Each myField As FieldInfo In myEnumFields
            If Not myField.IsSpecialName AndAlso myField.Name.ToLower() <> "notset" Then
                myList.Add(New ListItem(myField.Name, myField.Name))
            End If
        Next
        Return myList
    End Function
#End Region

End Class