Namespace REMI.BusinessEntities
    Public Class ExceptionSearch
        Private _testID As Int32
        Private _testStageID As Int32
        Private _accessoryID As Int32
        Private _productTypeID As Int32
        Private _productID As Int32
        Private _jobName As String
        Private _includeBatches As Int32
        Private _requestReason As Int32
        Private _isMQual As Boolean
        Private _TestCenterID As Int32
        Private _qraNumber As String

        Public Property IncludeBatches() As Int32
            Get
                Return _includeBatches
            End Get
            Set(value As Int32)
                _includeBatches = value
            End Set
        End Property

        Public Property IsMQual() As Boolean
            Get
                Return _isMQual
            End Get
            Set(value As Boolean)
                _isMQual = value
            End Set
        End Property

        Public Property TestCenterID() As Int32
            Get
                Return _TestCenterID
            End Get
            Set(value As Int32)
                _TestCenterID = value
            End Set
        End Property

        Public Property JobName() As String
            Get
                Return _jobName
            End Get
            Set(value As String)
                _jobName = value
            End Set
        End Property

        Public Property RequestReason() As Int32
            Get
                Return _requestReason
            End Get
            Set(value As Int32)
                _requestReason = value
            End Set
        End Property

        Public Property TestID() As Int32
            Get
                Return _testID
            End Get
            Set(value As Int32)
                _testID = value
            End Set
        End Property

        Public Property TestStageID() As Int32
            Get
                Return _testStageID
            End Get
            Set(value As Int32)
                _testStageID = value
            End Set
        End Property

        Public Property AccessoryGroupID() As Int32
            Get
                Return _accessoryID
            End Get
            Set(value As Int32)
                _accessoryID = value
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

        Public Property ProductID() As Int32
            Get
                Return _productID
            End Get
            Set(value As Int32)
                _productID = value
            End Set
        End Property

        Public Property QRANumber() As String
            Get
                Return _qraNumber
            End Get
            Set(value As String)
                _qraNumber = value
            End Set
        End Property
    End Class
End Namespace