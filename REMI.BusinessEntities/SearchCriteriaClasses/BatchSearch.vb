Imports REMI.Contracts
Namespace REMI.BusinessEntities

    Public Class BatchSearch
        Private _job As String
        Private _stage As String
        Private _revision As String
        Private _requestor As String
        Private _jobID As Int32
        Private _geoLocationID As Int32
        Private _trackingLocationTypeID As Int32
        Private _requestReason As Int32
        Private _productID As Int32
        Private _productTypeID As Int32
        Private _accessoryGroupID As Int32
        Private _testStageID As Int32
        Private _testID As Int32
        Private _userID As Int32
        Private _trackingLocationID As Int32
        Private _priority As Int32
        Private _status As BatchStatus
        Private _excludedStatus As Int32
        Private _departmentID As Int32
        Private _batchStart As DateTime = Nothing
        Private _batchEnd As DateTime = Nothing
        Private _testStageType As TestStageType
        Private _excludedTestStageType As Int32
        Private _trackingLocationFunction As TrackingLocationFunction
        Private _notInTrackingLocationFunction As TrackingLocationFunction

        Public Property NotInTrackingLocationFunction() As TrackingLocationFunction
            Get
                Return _notInTrackingLocationFunction
            End Get
            Set(value As TrackingLocationFunction)
                _notInTrackingLocationFunction = value
            End Set
        End Property

        Public Property TrackingLocationFunction() As TrackingLocationFunction
            Get
                Return _trackingLocationFunction
            End Get
            Set(value As TrackingLocationFunction)
                _trackingLocationFunction = value
            End Set
        End Property

        Public Property ExcludedTestStageType() As Int32
            Get
                Return _excludedTestStageType
            End Get
            Set(value As Int32)
                _excludedTestStageType = value
            End Set
        End Property

        Public Property TestStageType() As TestStageType
            Get
                Return _testStageType
            End Get
            Set(value As TestStageType)
                _testStageType = value
            End Set
        End Property

        Public Property BatchStart() As DateTime
            Get
                Return _batchStart
            End Get
            Set(value As DateTime)
                _batchStart = value
            End Set
        End Property

        Public Property BatchEnd() As DateTime
            Get
                Return _batchEnd
            End Get
            Set(value As DateTime)
                _batchEnd = value
            End Set
        End Property

        Public Property GeoLocationID() As Int32
            Get
                Return _geoLocationID
            End Get
            Set(value As Int32)
                _geoLocationID = value
            End Set
        End Property

        Public Property DepartmentID() As Int32
            Get
                Return _departmentID
            End Get
            Set(value As Int32)
                _departmentID = value
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

        Public Property JobName() As String
            Get
                Return _job
            End Get
            Set(value As String)
                _job = value
            End Set
        End Property

        Public Property JobID() As Int32
            Get
                Return _jobID
            End Get
            Set(value As Int32)
                _jobID = value
            End Set
        End Property

        Public Property Priority() As Int32
            Get
                Return _priority
            End Get
            Set(value As Int32)
                _priority = value
            End Set
        End Property

        Public Property Status() As BatchStatus
            Get
                Return _status
            End Get
            Set(value As BatchStatus)
                _status = value
            End Set
        End Property

        Public Property ExcludedStatus() As Int32
            Get
                Return _excludedStatus
            End Get
            Set(value As Int32)
                _excludedStatus = value
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

        Public Property ProductTypeID() As Int32
            Get
                Return _productTypeID
            End Get
            Set(value As Int32)
                _productTypeID = value
            End Set
        End Property

        Public Property AccessoryGroupID() As Int32
            Get
                Return _accessoryGroupID
            End Get
            Set(value As Int32)
                _accessoryGroupID = value
            End Set
        End Property

        Public Property TestStage() As String
            Get
                Return _stage
            End Get
            Set(value As String)
                _stage = value
            End Set
        End Property

        Public Property Revision() As String
            Get
                Return _revision
            End Get
            Set(value As String)
                _revision = value
            End Set
        End Property

        Public Property Requestor() As String
            Get
                Return _requestor
            End Get
            Set(value As String)
                _requestor = value
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

        Public Property TestID() As Int32
            Get
                Return _testID
            End Get
            Set(value As Int32)
                _testID = value
            End Set
        End Property

        Public Property UserID() As Int32
            Get
                Return _userID
            End Get
            Set(value As Int32)
                _userID = value
            End Set
        End Property

        Public Property TrackingLocationTypeID() As Int32
            Get
                Return _trackingLocationTypeID
            End Get
            Set(value As Int32)
                _trackingLocationTypeID = value
            End Set
        End Property

        Public Property TrackingLocationID() As Int32
            Get
                Return _trackingLocationID
            End Get
            Set(value As Int32)
                _trackingLocationID = value
            End Set
        End Property
    End Class
End Namespace