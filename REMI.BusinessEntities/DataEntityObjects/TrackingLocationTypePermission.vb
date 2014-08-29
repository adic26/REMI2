Imports REMI.Contracts
Namespace REMI.BusinessEntities
    Public Class TrackingLocationTypePermission
        'this is 1 as default becuase everyone starts off with basic permissions.
        Private _permissions As Integer = 1
        Public Property CurrentPermissions() As Integer
            Get
                Return _permissions
            End Get
            Set(ByVal value As Integer)
                _permissions = value
            End Set
        End Property
        Public Property HasBasicAccess() As Boolean
            Get
                Return ((Me.CurrentPermissions And TrackingLocationUserAccessPermission.BasicTestAccess) = TrackingLocationUserAccessPermission.BasicTestAccess)
            End Get
            Set(ByVal value As Boolean)
                If value Then
                    'make sure it's turned on
                    Me.CurrentPermissions = Me.CurrentPermissions Or REMI.Contracts.TrackingLocationUserAccessPermission.BasicTestAccess
                Else
                    'make sure it's turned off
                    Me.CurrentPermissions = Me.CurrentPermissions And (Not REMI.Contracts.TrackingLocationUserAccessPermission.BasicTestAccess)
                End If
            End Set
        End Property
        Public Property HasModifiedAccess() As Boolean
            Get
                Return ((Me.CurrentPermissions And TrackingLocationUserAccessPermission.ModifiedTestAccess) = TrackingLocationUserAccessPermission.ModifiedTestAccess)
            End Get
            Set(ByVal value As Boolean)
                If value Then
                    'make sure it's turned on
                    Me.CurrentPermissions = Me.CurrentPermissions Or REMI.Contracts.TrackingLocationUserAccessPermission.ModifiedTestAccess
                Else
                    'make sure it's turned off
                    Me.CurrentPermissions = Me.CurrentPermissions And (Not REMI.Contracts.TrackingLocationUserAccessPermission.ModifiedTestAccess)
                End If
            End Set
        End Property
        Public Property HasCalibrationAccess() As Boolean
            Get
                Return ((Me.CurrentPermissions And TrackingLocationUserAccessPermission.CalibrationAccess) = TrackingLocationUserAccessPermission.CalibrationAccess)
            End Get
            Set(ByVal value As Boolean)
                If value Then
                    'make sure it's turned on
                    Me.CurrentPermissions = Me.CurrentPermissions Or REMI.Contracts.TrackingLocationUserAccessPermission.CalibrationAccess
                Else
                    'make sure it's turned off
                    Me.CurrentPermissions = Me.CurrentPermissions And (Not REMI.Contracts.TrackingLocationUserAccessPermission.CalibrationAccess)
                End If
            End Set
        End Property

        Private _trackingLocationTypeID As Integer
        Public Property TrackingLocationTypeID() As Integer
            Get
                Return _trackingLocationTypeID
            End Get
            Set(ByVal value As Integer)
                _trackingLocationTypeID = value
            End Set
        End Property

        Private _trackingLocationType As String
        Public Property TrackingLocationType() As String
            Get
                Return _trackingLocationType
            End Get
            Set(ByVal value As String)
                _trackingLocationType = value
            End Set
        End Property

        Private _concurrencyID As Byte()
        Public Property ConcurrencyID() As Byte()
            Get
                Return _concurrencyID
            End Get
            Set(ByVal value As Byte())
                _concurrencyID = value
            End Set
        End Property
    End Class
End Namespace