Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="TrackingLocationTypePermission">Tracking Location Type Permissions</see>.
    ''' </summary>
    Public Class TrackingLocationTypePermissionCollection
        Inherits List(Of TrackingLocationTypePermission)

        Public Sub New(ByVal username As String)
            _username = username
        End Sub
        Private _username As String
        Public ReadOnly Property Username() As String
            Get
                Return _username
            End Get

        End Property

    End Class
End Namespace