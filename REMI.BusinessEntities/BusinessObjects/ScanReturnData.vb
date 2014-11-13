Imports REMI.Validation
Imports System.Xml.Serialization

Namespace REMI.BusinessEntities
    ''' <summary>
    ''' This class represents the data returned by a scan in to a test station or at a  tracking location
    ''' </summary>
    ''' <remarks></remarks>
    <Serializable()> _
    Public Class ScanReturnData
        Inherits ValidationBase

        Private _direction As ScanDirection
        Private _testStationManualLocation As String
        Private _JobWILocationLink As String
        Private _jobName As String
        Private _testStageName As String
        Private _qraNumber As String
        Private _productGroup As String
        Private _productID As Int32
        Private _trackingLocationID As Int32
        Private _trackingLocationName As String
        Private _applicableTests As String()
        Private _applicableTestStages As String()
        Private _scanSuccess As Boolean
        Private _testWILink As String
        Private _selectedTestName As String
        Private _BSN As String
        Private _testUnitNumber As Integer
        Private _cprNumber As String
        Private _hwRevision As String
        Private _testID As Int32
        Private _NoBSN As Boolean
        Private _productType As String
        Private _accessoryType As String
        Private _productTypeID As Int32
        Private _accessoryTypeID As Int32
        Private _batchData As BatchView

        Public Sub New()
            _direction = ScanDirection.NotSet
        End Sub

        Public Sub New(ByVal qraNumber As String)
            _qraNumber = qraNumber
            _direction = ScanDirection.NotSet
        End Sub

        Public Property CPRNumber() As String
            Get
                Return _cprNumber
            End Get
            Set(ByVal value As String)
                _cprNumber = value
            End Set
        End Property

        Public Property HWRevision() As String
            Get
                Return _hwRevision
            End Get
            Set(ByVal value As String)
                _hwRevision = value
            End Set
        End Property

        Public Property BSN() As String
            Get
                Return _BSN
            End Get
            Set(ByVal value As String)
                _BSN = value
            End Set
        End Property

        Public Property TrackingLocationID() As Int32
            Get
                Return _trackingLocationID
            End Get
            Set(ByVal value As Int32)
                _trackingLocationID = value
            End Set
        End Property

        Public Property TrackingLocationName() As String
            Get
                Return _trackingLocationName
            End Get
            Set(ByVal value As String)
                _trackingLocationName = value
            End Set
        End Property

        Public Property ProductType As String
            Get
                Return _productType
            End Get
            Set(value As String)
                _productType = value
            End Set
        End Property

        Public Property AccessoryType As String
            Get
                Return _accessoryType
            End Get
            Set(value As String)
                _accessoryType = value
            End Set
        End Property

        Public Property ProductTypeID() As Int32
            Get
                Return _productTypeID
            End Get
            Set(value As Int32)
                _productTypeID = value
            End Set
        End Property

        Public Property AccessoryTypeID() As Int32
            Get
                Return _accessoryTypeID
            End Get
            Set(value As Int32)
                _accessoryTypeID = value
            End Set
        End Property

        Public Property JobWILink() As String
            Get
                Return _JobWILocationLink
            End Get
            Set(ByVal value As String)
                _JobWILocationLink = value
            End Set
        End Property

        Public Property ScanSuccess() As Boolean
            Get
                Return _scanSuccess
            End Get
            Set(ByVal value As Boolean)
                _scanSuccess = value
            End Set
        End Property

        Public Property NoBSN() As Boolean
            Get
                Return _NoBSN
            End Get
            Set(ByVal value As Boolean)
                _NoBSN = value
            End Set
        End Property

        Public Property TestWILink() As String
            Get
                Return _testWILink
            End Get
            Set(value As String)
                _testWILink = value
            End Set
        End Property

        Public Property TrackingLocationManualLocation() As String
            Get
                Return _testStationManualLocation
            End Get
            Set(ByVal value As String)
                _testStationManualLocation = value
            End Set
        End Property

        Public Property ProductGroup() As String
            Get
                Return _productGroup
            End Get
            Set(ByVal value As String)
                _productGroup = value
            End Set
        End Property

        Public Property ProductID() As Int32
            Get
                Return _productID
            End Get
            Set(ByVal value As Int32)
                _productID = value
            End Set
        End Property

        Public Property QRANumber() As String
            Get
                Return _qraNumber
            End Get
            Set(ByVal value As String)
                _qraNumber = value
            End Set
        End Property

        Public Property TestStageName() As String
            Get
                Return _testStageName
            End Get
            Set(ByVal value As String)
                _testStageName = value
            End Set
        End Property

        Public Property JobName() As String
            Get
                Return _jobName
            End Get
            Set(ByVal value As String)
                _jobName = value
            End Set
        End Property

        Public Property Direction() As ScanDirection
            Get
                Return _direction
            End Get
            Set(ByVal value As ScanDirection)
                _direction = value
            End Set
        End Property

        Public Property ApplicableTestStages() As String()
            Get
                Return _applicableTestStages
            End Get
            Set(ByVal value As String())
                _applicableTestStages = value
            End Set
        End Property

        Public Property ApplicableTests() As String()
            Get
                Return _applicableTests
            End Get
            Set(ByVal value As String())
                _applicableTests = value
            End Set
        End Property

        Public Property UnitNumber() As Integer
            Get
                Return _testUnitNumber
            End Get
            Set(ByVal value As Integer)
                _testUnitNumber = value
            End Set
        End Property

        Public Property TestID() As Int32
            Get
                Return _testID
            End Get
            Set(ByVal value As Int32)
                _testID = value
            End Set
        End Property

        Public Property SelectedTestName() As String
            Get
                Return _selectedTestName
            End Get
            Set(ByVal value As String)
                _selectedTestName = value
            End Set
        End Property

        Private _isBBX As Boolean
        Public Property IsBBX() As Boolean
            Get
                Return _isBBX
            End Get
            Set(ByVal value As Boolean)
                _isBBX = value
            End Set
        End Property

        Public Property BatchData() As BatchView
            Get
                Return _batchData
            End Get
            Set(ByVal value As BatchView)
                _batchData = value
            End Set
        End Property
    End Class
End Namespace