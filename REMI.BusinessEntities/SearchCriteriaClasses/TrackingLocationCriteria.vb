Imports System.ComponentModel
Imports REMI.Validation
Namespace REMI.BusinessEntities
    Public Class TrackingLocationCriteria

#Region "Private Variables"

        Private _id As Integer
        Private _trackingLocName As String
        Private _geoLocationName As String
        Private _geoLocationID As Int32
        Private _status As TrackingLocationStatus
        Private _TrackingLocationFunction As TrackingLocationFunction
        Private _trackingLocTypeID As Integer
        Private _trackingLocTypeName As String
        Private _hostName As String
#End Region

#Region "Constructor(s)"

        ''' <summary>
        ''' This is the default constructor for the class.
        ''' </summary>
        ''' <remarks></remarks>
        Public Sub New()
            _TrackingLocationFunction = BusinessEntities.TrackingLocationFunction.NotSet
            _status = TrackingLocationStatus.NotSet
            _hostName = String.Empty
        End Sub

#End Region

#Region "Public Properties"

        ''' <summary>
        ''' Gets or sets the unique database ID for the tracking location.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>

        <DataObjectField(True, True, False)> _
        Public Property ID() As Integer
            Get
                Return _id
            End Get
            Set(ByVal value As Integer)
                _id = value
            End Set
        End Property


        Public Property HostName() As String
            Get
                If _hostName IsNot Nothing Then
                    Return _hostName.ToLower
                Else
                    Return String.Empty
                End If
            End Get
            Set(ByVal value As String)
                _hostName = value
            End Set
        End Property

        Public Property TrackingLocName() As String
            Get
                Return _trackingLocName
            End Get
            Set(ByVal value As String)
                _trackingLocName = value
            End Set
        End Property
        Public Property GeoLocationName() As String
            Get
                Return _geoLocationName
            End Get
            Set(ByVal value As String)
                _geoLocationName = value
            End Set
        End Property

        Public Property GeoLocationID() As Integer
            Get
                Return _geoLocationID
            End Get
            Set(ByVal value As Integer)
                _geoLocationID = value
            End Set
        End Property

        Public Property TrackingLocationTypeID() As Integer
            Get
                Return _trackingLocTypeID
            End Get
            Set(ByVal value As Integer)
                _trackingLocTypeID = value
            End Set
        End Property

        Public Property TrackingLocationFunction() As TrackingLocationFunction
            Get
                Return _TrackingLocationFunction
            End Get
            Set(ByVal value As TrackingLocationFunction)
                _TrackingLocationFunction = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the status of the tracking location.
        ''' </summary>
        Public Property Status() As TrackingLocationStatus
            Get
                Return _status
            End Get
            Set(ByVal value As TrackingLocationStatus)
                _status = value
            End Set
        End Property

        Public Property TrackingLocTypeName() As String
            Get
                Return _trackingLocTypeName
            End Get
            Set(ByVal value As String)
                _trackingLocTypeName = value
            End Set
        End Property
#End Region
    End Class
End Namespace