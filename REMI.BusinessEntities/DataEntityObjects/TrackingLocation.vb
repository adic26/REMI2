Imports REMI.Core
Imports REMI.Validation
Imports REMI.Contracts
Imports System.Xml.Serialization

Namespace REMI.BusinessEntities
    ''' <summary>
    ''' <para>The tracking location class represents any location where a tracking gun is present.</para>
    ''' </summary>
    ''' <remarks></remarks>
    <Serializable()> _
    Public Class TrackingLocation
        Inherits LoggedItemBase

#Region "Private Variables"
        Private _name As String
        Private _geoLocationName As String
        Private _trackingLocationType As TrackingLocationType
        Private _status As TrackingLocationStatus
        Private _locationStatus As TrackingStatus
        Private _currentUnitCount As Integer
        Private _geoLocationID As Int32
        Private _comment As String
        Private _hostName As String
        Private _canDelete As Boolean
        Private _currentTestName As String
        Private _decommissioned As Boolean
        Private _isMultiDeviceZone As Boolean
        Private _hostID As Int32
        Private _lastPingTime As DateTime
#End Region

#Region "Constructor(s)"
        ''' <summary>
        ''' This is the default constructor for the class.
        ''' </summary>
        ''' <remarks></remarks>
        Public Sub New()
            _status = TrackingLocationStatus.NotSet
            _trackingLocationType = New TrackingLocationType
            _locationStatus = TrackingStatus.Functional
            _hostName = String.Empty
            _canDelete = False
            _decommissioned = False
            _isMultiDeviceZone = False
        End Sub
#End Region

#Region "Public Properties"
        Public Property TrackingLocationType() As TrackingLocationType
            Get
                Return _trackingLocationType
            End Get
            Set(ByVal value As TrackingLocationType)
                If value IsNot Nothing Then
                    _trackingLocationType = value
                End If
            End Set
        End Property

        Public Property IsMultiDeviceZone() As Boolean
            Get
                Return _isMultiDeviceZone
            End Get
            Set(ByVal value As Boolean)
                _isMultiDeviceZone = value
            End Set
        End Property

        <XmlIgnore()> _
        Public Property Decommissioned() As Boolean
            Get
                Return _decommissioned
            End Get
            Set(ByVal value As Boolean)
                _decommissioned = value
            End Set
        End Property

        Public Property HostID() As Int32
            Get
                Return _hostID
            End Get
            Set(ByVal value As Int32)
                _hostID = value
            End Set
        End Property

        <XmlIgnore()> _
        Public Property CanDelete() As Boolean
            Get
                Return _canDelete
            End Get
            Set(ByVal value As Boolean)
                _canDelete = value
            End Set
        End Property

        Public Property HostName() As String
            Get
                If Not String.IsNullOrEmpty(_hostName) Then
                    Return _hostName.ToLower
                Else
                    Return String.Empty
                End If
            End Get
            Set(ByVal value As String)
                _hostName = value
            End Set
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property DisplayName() As String
            Get
                Return _name + " - " + GeoLocationName
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property DisplayNameHost() As String
            Get
                Return String.Format("{0}: {1} - {2}", _name, HostName, GeoLocationName)
            End Get
        End Property

        ''' <summary>
        ''' Gets or sets the name of the tracking location.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <NotNullOrEmpty(Key:="w14")> _
        <ValidStringLength(Key:="w15", MaxLength:=400)> _
        Public Property Name() As String
            Get
                Return _name
            End Get
            Set(ByVal value As String)
                _name = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the geographical location of the tracking location.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <NotNullOrEmpty(Key:="w16")> _
        Public Property GeoLocationName() As String
            Get
                Return _geoLocationName
            End Get
            Set(ByVal value As String)
                _geoLocationName = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the geographical location of the tracking location.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <NotNullOrEmpty(Key:="w16")> _
        Public Property GeoLocationID() As Int32
            Get
                Return _geoLocationID
            End Get
            Set(ByVal value As Int32)
                _geoLocationID = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the barcode prefix of the gun located at the tracking location.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <XmlIgnore()> _
        Public ReadOnly Property BarcodePrefix() As String
            Get
                Return ID.ToString("d5")
            End Get
        End Property

        ''' <summary>
        ''' Gets or sets the status of the tracking host.
        ''' </summary>
        <EnumerationSet(Key:="w17")> _
        <XmlIgnore()> _
        Public Property Status() As TrackingLocationStatus
            Get
                Return _status
            End Get
            Set(ByVal value As TrackingLocationStatus)
                _status = value
            End Set
        End Property

        <EnumerationSet(Key:="w17")> _
        <XmlIgnore()> _
        Public Property LocationStatus() As TrackingStatus
            Get
                Return _locationStatus
            End Get
            Set(ByVal value As TrackingStatus)
                _locationStatus = value
            End Set
        End Property

        <XmlIgnore()> _
        Private Property LAstPingTime() As DateTime
            Get
                Return _lastPingTime
            End Get
            Set(ByVal value As DateTime)
                _lastPingTime = value
            End Set
        End Property
        ''' <summary>
        ''' Gets or sets the current number of units at this location.
        ''' </summary>
        ''' 
        <ValidRange(Message:="The number of current units must be greater than 0.", Max:=999999, Min:=0)> _
        <XmlIgnore()> _
        Public Property CurrentUnitCount() As Integer
            Get
                Return _currentUnitCount
            End Get
            Set(ByVal value As Integer)
                _currentUnitCount = value
            End Set
        End Property

        <ValidStringLength(MaxLength:=1000, key:="w33")> _
        <XmlIgnore()> _
        Public Property Comment() As String
            Get
                Return _comment
            End Get
            Set(ByVal value As String)
                _comment = value
            End Set
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property ProgrammingLink() As String
            Get
                Return REMIWebLinks.GetScannerProgrammingLink(ID)
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property TrackingLocationLink() As String
            Get
                Return REMIWebLinks.GetTrackingLocationInfoLink(ID.ToString)
            End Get
        End Property

        ''' <summary>
        ''' Overrides the default tostring to return the tracking location name.
        ''' </summary>
        ''' <returns>The Name of the tracking location</returns>
        ''' <remarks></remarks>
        Public Overrides Function ToString() As String
            If String.IsNullOrEmpty(DisplayName) Then
                Return String.Empty
            Else
                Return DisplayName
            End If
        End Function

        <ValidIDNumber(Key:="w18")> _
        Public Property TrackingLocationTypeID() As Integer
            Get
                Return _trackingLocationType.ID
            End Get
            Set(ByVal value As Integer)
                _trackingLocationType.ID = value
            End Set
        End Property
#End Region

#Region "TL Type Properties"
        <XmlIgnore()> _
        Public ReadOnly Property WILocation() As String
            Get
                If TrackingLocationType IsNot Nothing Then
                    Return TrackingLocationType.WILocation
                Else
                    Return String.Empty
                End If
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property UnitCapacity() As Integer
            Get
                Return TrackingLocationType.UnitCapacity
            End Get
        End Property

        Public ReadOnly Property TrackingLocationTypeName() As String
            Get
                Return TrackingLocationType.Name
            End Get
        End Property

        Public ReadOnly Property TrackingLocationFunction() As TrackingLocationFunction
            Get
                Return TrackingLocationType.TrackingLocationFunction
            End Get
        End Property
#End Region

        Public Function GetProgrammingData() As List(Of String)
            Dim barcodeLocation As String = "~/Images/Barcodes/"
            Dim requiredASCIIString As String
            Dim barcodeNumber As String = BarcodePrefix
            Dim bcList As New List(Of String)
            'first add the code to delete all the suffixes
            bcList.Add(barcodeLocation + "clear_suffixes.jpg")
            'code to add a new one
            bcList.Add(barcodeLocation + "add_suffix.jpg")
            ' 99 represents to add the suffix to all code symbologies
            '2D adds the "-" to the number
            ' 0D adds the Carriage Return symbol to the end.

            Dim sValue As String
            Dim sHex As String = ""
            For i As Integer = 0 To barcodeNumber.Length - 1
                'get the next character , converts it to an integer, then to a hex value
                sValue = Conversion.Hex(Strings.Asc(barcodeNumber.Chars(i)))
                'append the hex value to the the hex value string
                sHex = String.Concat(sHex, sValue)
            Next
            requiredASCIIString = String.Format("992D{0}0D", sHex)
            'add the hex values to the barcode image list
            For i As Integer = 0 To requiredASCIIString.Length - 1
                bcList.Add(String.Format("{0}{1}.jpg", barcodeLocation, requiredASCIIString.Chars(i)))
            Next
            bcList.Add(barcodeLocation + "save.jpg")
            Return bcList
        End Function

        Public Function IsTestingLocation() As Boolean
            Return Me.TrackingLocationType.TrackingLocationFunction = BusinessEntities.TrackingLocationFunction.Testing
        End Function

    End Class
End Namespace