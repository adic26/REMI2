Imports System.Web
Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.DirectoryServices
Imports System.Web.Script.Services
Imports Remi.Core

' To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line.
<System.Web.Script.Services.ScriptService()> _
<WebService(Namespace:="http://go/remi/AutoComplete")> _
<WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Public Class AutoCompleteService
    Inherits System.Web.Services.WebService

    <WebMethod()> _
    <System.Web.Script.Services.ScriptMethod()> _
    Public Function GetActiveDirectoryNames(ByVal prefixText As String, ByVal count As Integer) As String()
        Dim userNames As New List(Of String)
        Using de As DirectoryEntry = GetDirectoryEntry()
            Using deSearch As DirectorySearcher = New DirectorySearcher()
                deSearch.Filter = "(&(|(objectClass=user)(objectClass=group))(mail=*)(|(displayName=" + prefixText + "*)(sn=" + prefixText + "*)(samaccountname=" + prefixText + "*)(email=" + prefixText + "*)))"
                deSearch.PropertiesToLoad.Add("distinguishedName")
                deSearch.PropertiesToLoad.Add("name")
                deSearch.PropertiesToLoad.Add("samaccountname")

                deSearch.Sort.PropertyName = "samaccountname"
                deSearch.Sort.Direction = SortDirection.Ascending
                deSearch.SizeLimit = count
                Dim adUsers As SearchResultCollection = deSearch.FindAll
                If adUsers IsNot Nothing Then
                    For i As Integer = 0 To adUsers.Count - 1
                        userNames.Add(adUsers.Item(i).Properties("samaccountname")(0).ToString)
                    Next
                End If
            End Using
        End Using
        Return userNames.ToArray
    End Function

    '<WebMethod()> _
    '<System.Web.Script.Services.ScriptMethod()> _
    'Public Function GetREMIUsers(ByVal prefixText As String, ByVal count As Integer) As String()
    '    Return (From x In Remi.Bll.UserManager.GetRemiUsernameList(0) Where x.StartsWith(prefixText) Select x).Take(count).ToArray()
    'End Function

    Private Function GetDirectoryEntry() As DirectoryEntry
        Dim de As New DirectoryEntry
        de.Path = REMIConfiguration.ADConnectionString
        de.Username = REMIConfiguration.REMIAccountName
        de.Password = REMIConfiguration.REMIAccountPassword
        Return de
    End Function
End Class