Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Contracts
Namespace REMI.BusinessEntities
    <Serializable()> _
    Public Class TestException
        Inherits LoggedItemBase
#Region "Private Variables"
        Private _testStageID As Integer
        Private _unitNumber As Integer
        Private _qraNumber As String
        Private _productGroup As String
        Private _testName As String
        Private _testStageName As String
        Private _reasonForRequest As String
        Private _reasonForRequestID As Int32
        Private _jobName As String
        Private _testCenter As String
        Private _testUnitID As Integer
        Private _accessoryGroupName As String
        Private _productType As String
        Private _productID As Int32
        Private _accessoryGroupID As Int32
        Private _productTypeID As Int32
        Private _testID As Int32
        Private _isMQual As Int32
        Private _testCenterID As Int32
#End Region

#Region "Constructors"
        Public Sub New()
        End Sub

        Public Sub New(ByVal qraNumber As String, ByVal UnitNumber As Integer, ByVal testName As String)
            _qraNumber = qraNumber
            _unitNumber = UnitNumber
            _testName = testName
            _productGroup = String.Empty
            _testStageName = String.Empty
            _reasonForRequest = "NotSet"
            _jobName = String.Empty
        End Sub

        Public Sub New(ByVal qraNumber As String, ByVal UnitNumber As Integer, ByVal testName As String, ByVal testStageName As String)
            _qraNumber = qraNumber
            _unitNumber = UnitNumber
            _testName = testName
            _jobName = String.Empty
            _productGroup = String.Empty
            _testStageName = testStageName
            _reasonForRequest = "NotSet"
        End Sub

        Public Sub New(ByVal productID As Int32, ByVal testName As String, Optional ByVal reasonForRequest As String = "NotSet")
            _productID = productID
            _testName = testName
            _qraNumber = String.Empty
            _jobName = String.Empty
            _testStageName = String.Empty
            _reasonForRequest = "NotSet"
        End Sub

        Public Sub New(ByVal productID As Int32, ByVal testName As String, ByVal testStageName As String, ByVal jobName As String, Optional ByVal reasonForRequest As String = "NotSet")
            _productID = productID
            _testName = testName
            _testStageName = testStageName
            _qraNumber = String.Empty
            _jobName = String.Empty
            _reasonForRequest = "NotSet"
        End Sub

        Public Sub New(ByVal qraNumber As String)
            _qraNumber = qraNumber
        End Sub
#End Region

#Region "Public Properties"
        Public Property UnitNumber() As Integer
            Get
                Return _unitNumber
            End Get
            Set(ByVal value As Integer)
                _unitNumber = value
            End Set
        End Property

        Public Property TestCenter() As String
            Get
                Return _testCenter
            End Get
            Set(ByVal value As String)
                _testCenter = value
            End Set
        End Property

        Public Property QRAnumber() As String
            Get
                Return _qraNumber
            End Get
            Set(ByVal value As String)
                _qraNumber = value
            End Set
        End Property

        Public Property ProductID As Int32
            Get
                Return _productID
            End Get
            Set(value As Int32)
                _productID = value
            End Set
        End Property

        Public Property IsMQual As Int32
            Get
                Return _isMQual
            End Get
            Set(value As Int32)
                _isMQual = value
            End Set
        End Property

        Public Property TestCenterID As Int32
            Get
                Return _testCenterID
            End Get
            Set(value As Int32)
                _testCenterID = value
            End Set
        End Property

        Public Property TestID As Int32
            Get
                Return _testID
            End Get
            Set(value As Int32)
                _testID = value
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

        Public Property ProductType() As String
            Get
                Return _productType
            End Get
            Set(ByVal value As String)
                _productType = value
            End Set
        End Property

        Public Property ProductTypeID() As Int32
            Get
                Return _productTypeID
            End Get
            Set(ByVal value As Int32)
                _productTypeID = value
            End Set
        End Property

        Public Property AccessoryGroupName() As String
            Get
                Return _accessoryGroupName
            End Get
            Set(ByVal value As String)
                _accessoryGroupName = value
            End Set
        End Property

        Public Property AccessoryGroupID() As Int32
            Get
                Return _accessoryGroupID
            End Get
            Set(ByVal value As Int32)
                _accessoryGroupID = value
            End Set
        End Property

        Public Property TestName() As String
            Get
                Return _testName
            End Get
            Set(ByVal value As String)
                _testName = value
            End Set
        End Property

        Public Property ReasonForRequest() As String
            Get
                Return _reasonForRequest
            End Get
            Set(ByVal value As String)
                _reasonForRequest = value
            End Set
        End Property

        Public Property ReasonForRequestID() As Int32
            Get
                Return _reasonForRequestID
            End Get
            Set(ByVal value As Int32)
                _reasonForRequestID = value
            End Set
        End Property

        Public Property TestUnitID() As Integer
            Get
                Return _testUnitID
            End Get
            Set(ByVal value As Integer)
                _testUnitID = value
            End Set
        End Property

        Public Property TestStageID() As Integer
            Get
                Return _testStageID
            End Get
            Set(ByVal value As Integer)
                _testStageID = value
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
#End Region

        Public Overrides Function Validate() As Boolean
            Dim valid As Boolean = True
            'valid product exception
            If (Me.TestStageName = "All" AndAlso Me.TestName = "All") OrElse (String.IsNullOrEmpty(Me.TestName) AndAlso String.IsNullOrEmpty(Me.TestStageName)) Then
                valid = False
                Me.Notifications.AddWithMessage("There must be a test or test stage selected for the exception.", NotificationType.Warning)
            End If
            Return valid
        End Function
    End Class
End Namespace