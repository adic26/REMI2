Imports REMI.BusinessEntities
Imports REMI.Bll

Partial Class ManageTestStations_ScannerCodes
    Inherits System.Web.UI.Page
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then

            Dim id As String = Request.QueryString.Get("ID")
            If Not String.IsNullOrEmpty(id) Then
                ProcessID(id)
            End If
        End If
    End Sub
    Protected Sub ProcessID(ByVal Id As Integer)
        Dim tl As TrackingLocation = TrackingLocationManager.GetTrackingLocationByID(Id)
        If tl IsNot Nothing Then
            lblTrackingLocationName.Text = tl.Name
            rptBarcode.DataSource = tl.GetProgrammingData
            rptBarcode.DataBind()
        End If
    End Sub

End Class
