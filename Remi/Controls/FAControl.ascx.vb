Imports REMI.BusinessEntities

Public Class FAControl
    Inherits System.Web.UI.UserControl

    Private _emptyDataText As String

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub

    Public Sub SetDataSource(ByVal dt As DataTable)
        grdFAs.EmptyDataText = _emptyDataText
        grdFAs.DataSource = dt
        grdFAs.DataBind()
    End Sub

    Protected Sub gvwWHeaders(ByVal sender As Object, ByVal e As System.EventArgs) Handles grdFAs.PreRender
        Helpers.MakeAccessable(grdFAs)
    End Sub

    Public Property EmptyDataText() As String
        Get
            Return _emptyDataText
        End Get
        Set(ByVal value As String)
            _emptyDataText = value
        End Set
    End Property
End Class