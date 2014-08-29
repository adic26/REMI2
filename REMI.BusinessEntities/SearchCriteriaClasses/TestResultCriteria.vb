Namespace REMI.BusinessEntities
    Public Class TestResultCriteria
        Private _testID As Integer
        Private _id As Integer
        Private _testUnitID As Integer
        Private _jobID As Integer
        Private _testStageID As Integer
        Private _result As FinalTestResult
        Private _reviewsBeforeTime As DateTime
        Private _reviewsAfterTime As DateTime
        Private _resultsBeforeTime As DateTime
        Private _resultsAfterTime As DateTime
        Private _reviewUser As String
        Private _resultUser As String
        Private _LocationBarcodePrefix As Integer
        Private _trackingLocationId As Integer
        Private _batchID As Integer
        Private _qraNumber As String
        Public Sub New()

        End Sub

        Public Sub New(ByVal ID As Integer)
            Me.ID = ID
        End Sub
#Region "Constructors"
        Public Sub New(ByVal testUnitID As Integer, ByVal result As FinalTestResult)
            _testUnitID = testUnitID
            _result = result
        End Sub

        Public Sub New(ByVal testUnitID As Integer, ByVal jobID As Integer, ByVal testStageID As Integer)
            _testUnitID = testUnitID
            _jobID = jobID
            _testStageID = testStageID
        End Sub
#End Region
#Region "Public Properties"
        Public Property Result() As FinalTestResult
            Get
                Return _result
            End Get
            Set(ByVal value As FinalTestResult)
                _result = value
            End Set
        End Property

        Public Property ID() As Integer
            Get
                Return _id
            End Get
            Set(ByVal value As Integer)
                _id = value
            End Set
        End Property
        Public Property JobID() As Integer
            Get
                Return _jobID
            End Get
            Set(ByVal value As Integer)
                _jobID = value
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

        Public Property TestID() As Integer
            Get
                Return _testID
            End Get
            Set(ByVal value As Integer)
                _testID = value
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
        Public Property BatchID() As Integer
            Get
                Return _batchID
            End Get
            Set(ByVal value As Integer)
                _batchID = value
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
        Public Property ReviewsBeforeTime() As DateTime
            Get
                Return _reviewsBeforeTime
            End Get
            Set(ByVal value As DateTime)
                _reviewsBeforeTime = value
            End Set
        End Property

        Public Property ReviewsAfterTime() As DateTime
            Get
                Return _reviewsAfterTime
            End Get
            Set(ByVal value As DateTime)
                _reviewsAfterTime = value
            End Set
        End Property

        Public Property ResultsAfterTime() As DateTime
            Get
                Return _resultsAfterTime
            End Get
            Set(ByVal value As DateTime)
                _resultsAfterTime = value
            End Set
        End Property

        Public Property ResultsBeforeTime() As DateTime
            Get
                Return _resultsBeforeTime
            End Get
            Set(ByVal value As DateTime)
                _resultsBeforeTime = value
            End Set
        End Property

        Public Property ResultUser() As String
            Get
                Return _resultUser
            End Get
            Set(ByVal value As String)
                _resultUser = value
            End Set
        End Property

        Public Property ReviewUser() As String
            Get
                Return _reviewUser
            End Get
            Set(ByVal value As String)
                _reviewUser = value
            End Set
        End Property

        Public Property LocationBarcodePrefix() As Integer
            Get
                Return _LocationBarcodePrefix
            End Get
            Set(ByVal value As Integer)
                _LocationBarcodePrefix = value
            End Set
        End Property

        Public Property TrackingLocationID() As Integer
            Get
                Return _trackingLocationId
            End Get
            Set(ByVal value As Integer)
                _trackingLocationId = value
            End Set
        End Property

#End Region

    End Class
End Namespace