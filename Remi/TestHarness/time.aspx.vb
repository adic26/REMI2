
Partial Class TestHarness_time
    Inherits System.Web.UI.Page
    Protected Sub pageload() Handles Me.Load
        Response.Write(String.Format(System.Globalization.CultureInfo.CurrentCulture, "{0:g}", DateTime.UtcNow.AddHours(19.07).ToLocalTime))
    End Sub
End Class
