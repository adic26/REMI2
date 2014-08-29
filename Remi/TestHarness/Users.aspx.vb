Imports REMI.Bll
Imports REMI.BusinessEntities
Imports REMI.Core
Partial Class TestHarness_Users
    Inherits System.Web.UI.Page

    Protected Sub btnUserIsInAD_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnUserIsInAD.Click
        Dim u As New User
        u.LDAPName = txtUserName.Text
        'Response.Write(usermanager..UserExistsInAD)
    End Sub

    Protected Sub Button1_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles Button1.Click
        Dim u As New User
        u.LDAPName = txtUserName.Text
        Response.Write(u.FullName + "<br/>")
        Response.Write(u.JobTitle + "<br/>")
        Response.Write(u.EmailAddress + "<br/>")
        Response.Write(u.Extension + "<br/>")
    End Sub

    Protected Sub txtGetFullProperties_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles txtGetFullProperties.Click
        Dim u As New User
        u.LDAPName = txtUserName.Text

    End Sub

    Protected Sub btnSearch_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSearch.Click
        Dim userNames As New List(Of String)
        Dim de As New System.DirectoryServices.DirectoryEntry
        de.Path = REMIConfiguration.ADConnectionString
        de.Username = REMIConfiguration.REMIAccountName
        de.Password = REMIConfiguration.REMIAccountPassword

        Using deSearch As System.DirectoryServices.DirectorySearcher = New System.DirectoryServices.DirectorySearcher()
            deSearch.Filter = "(&(&(objectCategory=person)(objectClass=user))(|(givenname=" + txtUserName.Text + "*)(sn=" + txtUserName.Text + "*)(smaaccountname=RIMNET\" + txtUserName.Text + "*)))"
            deSearch.Sort.PropertyName = "displayname"
            deSearch.Sort.Direction = SortDirection.Ascending
            deSearch.SizeLimit = 25
            Dim adUsers As System.DirectoryServices.SearchResultCollection = deSearch.FindAll
            If adUsers IsNot Nothing Then
                For i As Integer = 0 To adUsers.Count - 1
                    Response.Write(adUsers.Item(i).Properties("displayname")(0).ToString + "<br/>")
                Next
            End If
        End Using
        de.dispose()

    End Sub

End Class
