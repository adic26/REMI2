
Partial Class TestHarness_Default2
    Inherits System.Web.UI.Page
    Public Sub pageload() Handles Button1.Click
        ResolveHostName(TextBox1.Text)
    End Sub

    Public Function ResolveHostName(ByVal IPAddress As String) As String
        Dim hostName As String = String.Empty
        Dim hostNamesRealIP As String

        Response.Write(Request.Headers.Item("HOST").ToString)
        Dim retries As Integer = 5
        For i As Integer = 1 To retries
            'get host split on . and take the first part (xxxxx.rim.net -> xxxxx)
            Dim x As System.Net.IPHostEntry = System.Net.Dns.GetHostEntry(IPAddress)

            For Each s As System.Net.IPAddress In x.AddressList
                Response.Write("<br />")
                Response.Write(s.AddressFamily)
            Next

            Response.Write("<br />")
            Response.Write(x.HostName)

            For Each s As String In x.Aliases
                Response.Write("<br />")
                Response.Write("alias:" + s)
            Next
            hostName = System.Net.Dns.GetHostEntry(IPAddress).HostName.Split("."c)(0).ToLower
            'get the ip for the first returned hostname
            hostNamesRealIP = System.Net.Dns.GetHostEntry(hostName).AddressList(0).ToString
            'check if it matches
            If Not IPAddress.Equals(hostNamesRealIP) Then
                'if not get the next one
                hostName = String.Empty
            Else
                Exit For
            End If
        Next

        Return hostName
    End Function
End Class
