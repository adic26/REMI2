Imports REMI.Validation
Imports System.Web
Imports REMI.Core
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' <para>This class represents a Device Tracking Log. A log is created here each time a device is scanned at a tracking location</para>
    ''' </summary>

    <Serializable()> _
    Public Class DeviceTrackingLog
        Inherits BusinessBase

#Region "Private variables"
        Private _testUnitID As Integer
        Private _trackingLocationID As Integer

        Private _inTime As DateTime
        Private _outTime As DateTime
        Private _inUser As String
        Private _outUser As String

        Private _TrackingLocationName As String
        Private _testUnitQRANumber As String
        Private _testUnitBatchUnitNumber As Integer
#End Region

#Region "Constructor(s)"

        Public Sub New()

        End Sub

        Public Sub New(ByVal testUnitId As Integer, ByVal BatchUnitNumber As Integer, ByVal QRANumber As String, ByVal trackingLocation As TrackingLocation, ByVal userName As String, ByVal fillOutFields As Boolean)
            _testUnitID = testUnitId
            _trackingLocationID = trackingLocation.ID
            _TrackingLocationName = trackingLocation.DisplayName
            _testUnitBatchUnitNumber = BatchUnitNumber
            _testUnitQRANumber = QRANumber
            _inUser = userName
            _inTime = DateTime.UtcNow
            If fillOutFields Then
                _outUser = userName
                _outTime = DateTime.UtcNow
            End If
        End Sub

#End Region

#Region "Public Properties"
        ''' <summary>
        ''' Gets and sets the Id of the test unit being logged.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidIDNumber(key:="w52")> _
        Public Property TestUnitID() As Integer
            Get
                Return _testUnitID
            End Get
            Set(ByVal value As Integer)
                _testUnitID = value
            End Set
        End Property

        ''' <summary>
        ''' Gets and sets the ID of the tracking location the unit is being logged at.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidIDNumber(key:="w53")> _
        Public Property TrackingLocationID() As Integer
            Get
                Return _trackingLocationID
            End Get
            Set(ByVal value As Integer)
                _trackingLocationID = value
            End Set
        End Property
        ''' <summary>
        ''' The name of the tracking location for this tracking log
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidStringLength(MaxLength:=800, key:="w15")> _
        Public Property TrackingLocationName() As String
            Get
                Return _TrackingLocationName
            End Get
            Set(ByVal value As String)
                _TrackingLocationName = value
            End Set
        End Property
        ''' <summary>
        ''' The barcode prefix required in the barcode to select this tracking location
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property TrackingLocationBarcodePrefix() As Integer
            Get
                Return _trackingLocationID
            End Get
        End Property

        ''' <summary>
        ''' gets or sets the time the test unit was logged in to the location.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property InTime() As DateTime
            Get
                Return _inTime
            End Get
            Set(ByVal value As DateTime)
                _inTime = value
            End Set
        End Property

        ''' <summary>
        ''' gets or sets the time the unit was logged out of the location.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property OutTime() As DateTime
            Get
                Return _outTime
            End Get
            Set(ByVal value As DateTime)
                _outTime = value
            End Set
        End Property

        ''' <summary>
        ''' gets or sets the user that logged in the test unit.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property InUser() As String
            Get
                Return _inUser
            End Get
            Set(ByVal value As String)
                _inUser = value
            End Set
        End Property

        ''' <summary>
        ''' gets or sets the user that logged out the test unit.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property OutUser() As String
            Get
                Return _outUser
            End Get
            Set(ByVal value As String)
                _outUser = value
            End Set
        End Property
        Public Property TestUnitBatchUnitNumber() As Integer
            Get
                Return _testUnitBatchUnitNumber
            End Get
            Set(ByVal value As Integer)
                _testUnitBatchUnitNumber = value
            End Set
        End Property
        Public Property TestUnitQRANumber() As String
            Get
                Return _testUnitQRANumber
            End Get
            Set(ByVal value As String)
                _testUnitQRANumber = value
            End Set
        End Property
        ''' <summary>
        ''' Returns the http link to the tracking location information page for this tracking location.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property TrackingLocationLink() As String
            Get
                Return REMIWebLinks.GetTrackingLocationInfoLink(TrackingLocationBarcodePrefix.ToString)
            End Get
        End Property
        ''' <summary>
        ''' The http link for the batch information page for the batch associated with this tracking log.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property BatchInfoLink() As String
            Get
                Return REMIWebLinks.GetBatchInfoLink(TestUnitQRANumber)
            End Get
        End Property
#End Region

#Region "Public Functions"

        ''' <summary>
        ''' This function checks the records that are filled for the tracking log and interprets this as representing the last scan direction
        ''' If there is no out scan then the last scan was an inward scan
        ''' if there is inward and otward scans the direction was an outward scan
        ''' if there is no in or out scans the direction is not set
        ''' </summary>
        ''' <returns>the last direction of scan.</returns>
        ''' <remarks></remarks>
        Public Function LastScanDirection() As ScanDirection
            If _
                String.IsNullOrEmpty(OutUser) And OutTime = DateTime.MinValue And (Not String.IsNullOrEmpty(InUser)) And _
                (Not InTime = DateTime.MinValue) Then
                Return ScanDirection.Inward
            ElseIf _
                (Not String.IsNullOrEmpty(OutUser)) And (Not OutTime = DateTime.MinValue) And _
                (Not String.IsNullOrEmpty(InUser)) And (Not InTime = DateTime.MinValue) Then
                Return ScanDirection.Outward
            ElseIf _
                (String.IsNullOrEmpty(OutUser)) And (OutTime = DateTime.MinValue) And (String.IsNullOrEmpty(InUser)) And _
                (InTime = DateTime.MinValue) Then
                'This means that this device tracking log is new with nothing set
                Return ScanDirection.NotSet
            End If
            Return ScanDirection.NotSet
        End Function
        Public Function NextScanDirection() As ScanDirection
            Select Case LastScanDirection()
                Case ScanDirection.Inward
                    Return ScanDirection.Outward
                Case ScanDirection.Outward
                    Return ScanDirection.Inward
                Case ScanDirection.NotSet
                    'this means that there were no logs found for this device and this is the first time the device has been scanned.
                    Return ScanDirection.Inward
                Case Else
                    Return ScanDirection.NotSet
            End Select
        End Function
        ''' <summary>
        ''' Overrides the default tostring to return the tracking location name.
        ''' </summary>
        ''' <returns>The tracking location name</returns>
        ''' <remarks></remarks>
        Public Overrides Function ToString() As String
            If String.IsNullOrEmpty(TrackingLocationName) Then
                Return String.Empty
            Else
                Return TrackingLocationName
            End If
        End Function

        Public Function TrackingTimeSpan() As TimeSpan
            If OutTime > DateTime.MinValue Then
                Return OutTime.Subtract(InTime)
            Else
                Return DateTime.UtcNow.Subtract(InTime)
            End If
        End Function

        ''' <summary>
        ''' Sets the out user property to the current user and sets the out time to the current UTC time
        ''' This sets these properties in one go.
        ''' </summary>
        ''' <remarks></remarks>
        Public Sub SetOutUser(ByVal Username As String)
            _outUser = Username
            _outTime = DateTime.UtcNow
        End Sub

#End Region
    End Class
End Namespace
