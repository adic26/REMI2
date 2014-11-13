Imports REMI.BusinessEntities
Imports REMI.Contracts
Imports REMI.Validation
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' In this class 'current*' is the test/testrecord etc that the unit is at before the scan
    ''' 'selected*' is the test stage etc that has been requested but is not stored in the DB until save data is called.
    ''' 
    ''' old and new respectively would be another way to name these. you might not like it but it is consistent:)
    ''' </summary>
    ''' <remarks></remarks>
    Public Class FastScanData
        Inherits REMI.Validation.ValidationBase

        Public Sub New()
            _lastTrackingLog = New DeviceTrackingLog
            _selectedTestRecordStatus = TestRecordStatus.NotSet
            _batchStatus = BatchStatus.NotSet
            _selectedTestType = TestType.NotSet
        End Sub

        Public Sub New(ByVal test As String, ByVal teststage As String, ByVal bc As DeviceBarcodeNumber)
            Me.New()
            _selectedTestName = test
            _selectedTestStage = teststage
            _barcode = bc
        End Sub

#Region "private vars"
        'these all come as part of the required scan information. from the operator/user
        Private _barcode As DeviceBarcodeNumber
        Private _currentUserName As String
        Private _selectedResult As FinalTestResult
        Private _selectedTestName As String
        Private _selectedTestStage As String
        Private _NoBSN As Boolean
        Private _trsStatus As String
        Private _scanSuccess As Boolean
        Private _selectedTestRecordStatusModified As Boolean
        Private _currentTestRecordStatusModified As Boolean
        Private _testID As Int32
        Private _ProductID As Int32
        Private _testWILink As String
        Private _lastTrackingLog As DeviceTrackingLog
        Private _currentTestStage As String
        Private _currentTestName As String
        Private _currentTestRecordStatus As TestRecordStatus
        Private _currentTestRecordID As Integer
        Private _currentTestRequiredTestTime As TimeSpan
        Private _currentTestTotalTestTime As TimeSpan
        Private _currentTestIsTimed As Boolean
        Private _currentTestType As TestType
        Private _batchStatus As BatchStatus
        Private _isInFA As Boolean
        Private _productGroupName As String
        Private _jobWI As String
        Private _jobName As String
        Private _bsn As Long
        Private _cprNumber As String
        Private _hwRevision As String
        Private _selectedTrackingLocationCapacityRemaining As Integer
        Private _selectedTrackingLocationName As String
        Private _selectedTrackingLocationID As Integer
        Private _selectedTestStageIsValidForJob As Boolean
        Private _selectedTestIsValidForTestStage As Boolean
        Private _selectedTestIsDNP As Boolean
        Private _selectedTestType As TestType
        Private _selectedTrackingLocationCurrentTestName As String
        Private _selectedTestRecordStatus As TestRecordStatus
        Private _selectedTrackingLocationWI As String
        Private _selectedTrackingLocationFunction As TrackingLocationFunction
        Private _selectedTestRecordID As Integer
        Private _selectedTestIsValidForTrackingLocation As Boolean
        Private _selectedTestIsTimed As Boolean
        Private _selectedTestNumberOfScans As Integer
        Private _selectedTestRequiredTestTime As TimeSpan
        Private _selectedTestTotalTestTime As TimeSpan
        Private _applicableTestStages As String()
        Private _applicableTests As String()
        Private _productType As String
        Private _accessoryType As String
        Private _productTypeID As Int32
        Private _accessoryTypeID As Int32
#End Region

#Region "public props"
        Private _isBBX As Boolean
        Public Property TRSStatus() As String
            Get
                Return _trsStatus
            End Get
            Set(value As String)
                _trsStatus = value
            End Set
        End Property

        Public Property IsBBX() As Boolean
            Get
                Return _isBBX
            End Get
            Set(ByVal value As Boolean)
                _isBBX = value
            End Set
        End Property

        Public Property TestWILink As String
            Get
                Return _testWILink
            End Get
            Set(value As String)
                _testWILink = value
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

        Public Property Barcode() As DeviceBarcodeNumber
            Get
                Return _barcode
            End Get
            Set(ByVal value As DeviceBarcodeNumber)
                _barcode = value
            End Set
        End Property

        <NotNullOrEmpty(key:="w35")> _
        Public Property CurrentUserName() As String
            Get
                Return _currentUserName
            End Get
            Set(ByVal value As String)
                _currentUserName = value
            End Set
        End Property

        Public Property SelectedResults() As FinalTestResult
            Get
                Return _selectedResult
            End Get
            Set(ByVal value As FinalTestResult)
                _selectedResult = value
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

        Public Property ProductID() As Int32
            Get
                Return _ProductID
            End Get
            Set(value As Int32)
                _ProductID = value
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

        Public Property TestID() As Int32
            Get
                Return _testID
            End Get
            Set(ByVal value As Int32)
                _testID = value
            End Set
        End Property
        Public Property SelectedTestStage() As String
            Get
                Return _selectedTestStage
            End Get
            Set(ByVal value As String)
                _selectedTestStage = value
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

        Public Property CPRNumber() As String
            Get
                Return _cprNumber
            End Get
            Set(ByVal value As String)
                _cprNumber = value
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

        Public Property SelectedTestRecordStatusModified() As Boolean
            Get
                Return _selectedTestRecordStatusModified
            End Get
            Set(ByVal value As Boolean)
                _selectedTestRecordStatusModified = value
            End Set
        End Property

        Public Property CurrentTestRecordStatusModified() As Boolean
            Get
                Return _currentTestRecordStatusModified
            End Get
            Set(ByVal value As Boolean)
                _currentTestRecordStatusModified = value
            End Set
        End Property

        Public Property LastTrackingLog() As DeviceTrackingLog
            Get
                Return _lastTrackingLog
            End Get
            Set(ByVal value As DeviceTrackingLog)
                _lastTrackingLog = value
            End Set
        End Property

        Public Property CurrentTestStage() As String
            Get
                Return _currentTestStage
            End Get
            Set(ByVal value As String)
                _currentTestStage = value
            End Set
        End Property

        Public Property CurrentTestName() As String
            Get
                Return _currentTestName
            End Get
            Set(ByVal value As String)
                _currentTestName = value
            End Set
        End Property

        Public Property CurrentTestRecordStatus() As TestRecordStatus
            Get
                Return _currentTestRecordStatus
            End Get
            Set(ByVal value As TestRecordStatus)
                _currentTestRecordStatus = value
            End Set
        End Property

        Public Property CurrentTestRecordID() As Integer
            Get
                Return _currentTestRecordID
            End Get
            Set(ByVal value As Integer)
                _currentTestRecordID = value
            End Set
        End Property

        Public Property CurrentTestRequiredTestTime() As TimeSpan
            Get
                Return _currentTestRequiredTestTime
            End Get
            Set(ByVal value As TimeSpan)
                _currentTestRequiredTestTime = value
            End Set
        End Property

        Public Property CurrentTestTotalTestTime() As TimeSpan
            Get
                Return _currentTestTotalTestTime
            End Get
            Set(ByVal value As TimeSpan)
                _currentTestTotalTestTime = value
            End Set
        End Property

        Public Property CurrentTestIsTimed() As Boolean
            Get
                Return _currentTestIsTimed
            End Get
            Set(ByVal value As Boolean)
                _currentTestIsTimed = value
            End Set
        End Property

        Public Property CurrentTestType() As TestType
            Get
                Return _currentTestType
            End Get
            Set(ByVal value As TestType)
                _currentTestType = value
            End Set
        End Property

        <EnumerationSet(key:="w13")> _
        Public Property BatchStatus() As BatchStatus
            Get
                Return _batchStatus
            End Get
            Set(ByVal value As BatchStatus)
                _batchStatus = value
            End Set
        End Property

        Public Property IsInFA() As Boolean
            Get
                Return _isInFA
            End Get
            Set(ByVal value As Boolean)
                _isInFA = value
            End Set
        End Property

        <NotNullOrEmpty(key:="w11")> _
                Public Property ProductGroupName() As String
            Get
                Return _productGroupName
            End Get
            Set(ByVal value As String)
                _productGroupName = value
            End Set
        End Property

        Public Property JobWI() As String
            Get
                Return _jobWI
            End Get
            Set(ByVal value As String)
                _jobWI = value
            End Set
        End Property

        <NotNullOrEmpty(key:="w10")> _
        Public Property JobName() As String
            Get
                Return _jobName
            End Get
            Set(ByVal value As String)
                _jobName = value
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

        Public Property BSN() As Long
            Get
                Return _bsn
            End Get
            Set(ByVal value As Long)
                _bsn = value
            End Set
        End Property

        Public Property SelectedTrackingLocationCapacityRemaining() As Integer
            Get
                Return _selectedTrackingLocationCapacityRemaining
            End Get
            Set(ByVal value As Integer)
                _selectedTrackingLocationCapacityRemaining = value
            End Set
        End Property

        <NotNullOrEmpty(key:="w14")> _
                Public Property SelectedTrackingLocationName() As String
            Get
                Return _selectedTrackingLocationName
            End Get
            Set(ByVal value As String)
                _selectedTrackingLocationName = value
            End Set
        End Property

        <ValidIDNumber(key:="w69")> _
                Public Property SelectedTrackingLocationID() As Integer
            Get
                Return _selectedTrackingLocationID
            End Get
            Set(ByVal value As Integer)
                _selectedTrackingLocationID = value
            End Set
        End Property

        Public Property SelectedTestStageIsValidForJob() As Boolean
            Get
                Return _selectedTestStageIsValidForJob
            End Get
            Set(ByVal value As Boolean)
                _selectedTestStageIsValidForJob = value
            End Set
        End Property

        Public Property SelectedTestIsValidForTestStage() As Boolean
            Get
                Return _selectedTestIsValidForTestStage
            End Get
            Set(ByVal value As Boolean)
                _selectedTestIsValidForTestStage = value
            End Set
        End Property

        Public Property SelectedTestIsDNP() As Boolean
            Get
                Return _selectedTestIsDNP
            End Get
            Set(ByVal value As Boolean)
                _selectedTestIsDNP = value
            End Set
        End Property
        Public Property SelectedTestType() As TestType
            Get
                Return _selectedTestType
            End Get
            Set(ByVal value As TestType)
                _selectedTestType = value
            End Set
        End Property
        Public Property SelectedTrackingLocationCurrentTestName() As String
            Get
                Return _selectedTrackingLocationCurrentTestName
            End Get
            Set(ByVal value As String)
                _selectedTrackingLocationCurrentTestName = value
            End Set
        End Property
        Public Property SelectedTestRecordStatus() As TestRecordStatus
            Get
                Return _selectedTestRecordStatus
            End Get
            Set(ByVal value As TestRecordStatus)
                _selectedTestRecordStatus = value
            End Set
        End Property
        Public Property SelectedTrackingLocationWI() As String
            Get
                Return _selectedTrackingLocationWI
            End Get
            Set(ByVal value As String)
                _selectedTrackingLocationWI = value
            End Set
        End Property
        <EnumerationSet(key:="w68")> _
                Public Property SelectedTrackingLocationFunction() As TrackingLocationFunction
            Get
                Return _selectedTrackingLocationFunction
            End Get
            Set(ByVal value As TrackingLocationFunction)
                _selectedTrackingLocationFunction = value
            End Set
        End Property
        Public Property SelectedTestRecordID() As Integer
            Get
                Return _selectedTestRecordID
            End Get
            Set(ByVal value As Integer)
                _selectedTestRecordID = value
            End Set
        End Property
        Public Property SelectedTestIsValidForTrackingLocation() As Boolean
            Get
                Return _selectedTestIsValidForTrackingLocation
            End Get
            Set(ByVal value As Boolean)
                _selectedTestIsValidForTrackingLocation = value
            End Set
        End Property
        Public Property SelectedTestIsTimed() As Boolean
            Get
                Return _selectedTestIsTimed
            End Get
            Set(ByVal value As Boolean)
                _selectedTestIsTimed = value
            End Set
        End Property
        Public Property SelectedTestNumberOfScans() As Integer
            Get
                Return _selectedTestNumberOfScans
            End Get
            Set(ByVal value As Integer)
                _selectedTestNumberOfScans = value
            End Set
        End Property
        Public Property SelectedTestRequiredTestTime() As TimeSpan
            Get
                Return _selectedTestRequiredTestTime
            End Get
            Set(ByVal value As TimeSpan)
                _selectedTestRequiredTestTime = value
            End Set
        End Property
        Public Property SelectedTestTotalTestTime() As TimeSpan
            Get
                Return _selectedTestTotalTestTime
            End Get
            Set(ByVal value As TimeSpan)
                _selectedTestTotalTestTime = value
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
#End Region

        Public Overrides Function Validate() As Boolean
            Dim baseValid As Boolean = MyBase.Validate
            Dim barcodeValid As Boolean = Barcode.Validate
            Dim lastTrackingLogValid As Boolean = True 'LastTrackingLog.Validate
            Dim localValid As Boolean = True
            If Not (baseValid AndAlso barcodeValid AndAlso lastTrackingLogValid) Then
                Me.Notifications.Add(LastTrackingLog.Notifications)
                Me.Notifications.Add(Barcode.Notifications)
                localValid = False
            End If

            If localValid Then
                If SelectedTrackingLocationCapacityRemaining < 0 Then
                    Notifications.Add("i4", NotificationType.Information)
                End If
            End If

            'check the user is set ok
            If String.IsNullOrEmpty(CurrentUserName) Then
                Notifications.Add("w70", NotificationType.Errors)
                localValid = False
            End If

            If (SelectedTrackingLocationName IsNot Nothing) Then
                If (Not (SelectedTrackingLocationName.ToLower().Contains("remstar"))) Then
                    If (TRSStatus.ToLower = REMI.Contracts.TRSStatus.Received.ToString().ToLower() Or TRSStatus.ToLower = REMI.Contracts.TRSStatus.Submitted.ToString().ToLower() Or TRSStatus.ToLower = REMI.Contracts.TRSStatus.Verified.ToString()) Then
                        Notifications.Add("w81", NotificationType.Errors, "Scan Attempt Rejected Due to Batch Not Ready For Testing in TRS.")
                        localValid = False
                    End If
                End If
            End If

            If localValid AndAlso TestingScanRequested() Then
                'check the batch is not quarantined/held/complete/rejected
                If localValid Then
                    Select Case BatchStatus
                        Case BatchStatus.Quarantined
                            Notifications.Add(String.Format("i5", Barcode.BatchNumber), NotificationType.Information)
                        Case BatchStatus.Held
                            Notifications.Add("w58", NotificationType.Information)
                        Case BatchStatus.InProgress, BatchStatus.Received, BatchStatus.TestingComplete
                            'ok, do nothing
                        Case BatchStatus.Complete, BatchStatus.Rejected 'should not be tested
                            Notifications.Add("i9", NotificationType.Information, "Status: " + BatchStatus.ToString)
                        Case BatchStatus.NotSavedToREMI, BatchStatus.NotSet 'cannot be tested
                            Notifications.Add("w59", NotificationType.Warning, "Status: " + BatchStatus.ToString)
                    End Select
                End If
                'test stage is not part of this job
                If localValid AndAlso Not SelectedTestStageIsValidForJob Then
                    Notifications.Add("w60", NotificationType.Errors)
                    Notifications.AddWithMessage("The following are valid test stages for this job: " + String.Join(",", ApplicableTestStages), NotificationType.Information)
                    localValid = False
                End If

                'test stage is set but test is not
                If localValid AndAlso Not SelectedTestIsValidForTestStage Then
                    Notifications.Add("w62", NotificationType.Errors)
                    Notifications.AddWithMessage("The following are valid tests for this location: " + String.Join(",", ApplicableTests), NotificationType.Information)
                    localValid = False
                End If

                'both are valid but test is not appropriate for thsi location
                If localValid AndAlso Not SelectedTestIsValidForTrackingLocation Then
                    Notifications.Add("e16", NotificationType.Errors)
                    localValid = False
                End If
                If localValid AndAlso SelectedTestIsDNP Then
                    Notifications.Add("e17", NotificationType.Errors)
                    localValid = False
                End If

                If SelectedTestRecordID > 0 Then
                    If SelectedTestNumberOfScans >= 3 AndAlso SelectedTestType = TestType.Parametric Then
                        Notifications.Add("i7", NotificationType.Information, String.Format("Test: {0} Unit: {1}", SelectedTestName, SelectedTestNumberOfScans))
                    End If
                    Select Case Me.SelectedTestRecordStatus
                        Case TestRecordStatus.Complete
                            'If the unit has already completed this test and has passed then there is no need to test it again.
                            Notifications.Add("w49", NotificationType.Information)
                        Case TestRecordStatus.CompleteKnownFailure
                            'If the unit has already completed this test and has failed and has been reviewed as a known failure then there is no need to test it again.
                            Notifications.Add("w50", NotificationType.Information)
                    End Select
                End If

                'check the current test name is valid for this location / mixing tests
                If localValid AndAlso Not String.IsNullOrEmpty(SelectedTrackingLocationCurrentTestName) AndAlso SelectedTrackingLocationCurrentTestName <> SelectedTestName Then
                    Notifications.Add("e20", NotificationType.Information)
                    'Notifications.Add(GetAltTLNotification)
                End If
                If IsInFA Then
                    Notifications.Add("i6", NotificationType.Information)
                End If
            End If

            Return localValid AndAlso baseValid AndAlso barcodeValid AndAlso lastTrackingLogValid
        End Function

        Public Sub SetCurrentTestRecordStatus()
            'check if the old test result should be set
            'currently only environmental tests are set here. 
            'All other records come from relab
            If Me.CurrentTestType = TestType.EnvironmentalStress Then
                If Me.CurrentTestIsTimed Then
                    If CurrentTestTotalTestTime >= CurrentTestRequiredTestTime Then
                        If Me.CurrentTestRecordStatus <> TestRecordStatus.Complete Then
                            Me.CurrentTestRecordStatus = TestRecordStatus.Complete
                            Me.CurrentTestRecordStatusModified = True
                        End If
                    Else
                        If Me.CurrentTestRecordStatus <> TestRecordStatus.TestingSuspended Then
                            Me.CurrentTestRecordStatus = TestRecordStatus.TestingSuspended
                            Me.CurrentTestRecordStatusModified = True
                        End If
                    End If
                Else
                    If Me.CurrentTestRecordStatus <> TestRecordStatus.Complete Then
                        Me.CurrentTestRecordStatus = TestRecordStatus.Complete
                        Me.CurrentTestRecordStatusModified = True
                    End If
                End If
            Else
                If Me.CurrentTestType = TestType.IncomingEvaluation OrElse Me.CurrentTestType = TestType.Parametric Then
                    If Me.CurrentTestRecordStatus = TestRecordStatus.InProgress Then
                        Me.CurrentTestRecordStatus = TestRecordStatus.WaitingForResult
                        Me.CurrentTestRecordStatusModified = True
                    End If
                End If
            End If
        End Sub

        Public Sub SetSelectedTestRecordStatus()
            'only set the result if the unit is not in fa.
            If Not Me.IsInFA Then
                Me.SelectedTestRecordStatus = TestRecordStatus.InProgress
                Me.SelectedTestRecordStatusModified = True
            End If
        End Sub

        Private Function TestingScanRequested() As Boolean
            Return SelectedTrackingLocationFunction = BusinessEntities.TrackingLocationFunction.EnvironmentalStressing OrElse _
            SelectedTrackingLocationFunction = BusinessEntities.TrackingLocationFunction.IncomingLabeling OrElse _
            SelectedTrackingLocationFunction = BusinessEntities.TrackingLocationFunction.Testing OrElse _
            (Not (String.IsNullOrEmpty(SelectedTestName) Or String.IsNullOrEmpty(SelectedTestStage)))
        End Function

        Public Sub SetReturnDataValues(ByVal returnData As ScanReturnData)
            returnData.Direction = ScanDirection.Inward
            returnData.ScanSuccess = Me.ScanSuccess
            returnData.UnitNumber = Me.Barcode.UnitNumber
            returnData.ApplicableTestStages = ApplicableTestStages
            returnData.ApplicableTests = ApplicableTests
            returnData.SelectedTestName = Me.SelectedTestName
            returnData.TestStageName = Me.SelectedTestStage
            returnData.BSN = Me.BSN.ToString
            returnData.QRANumber = Barcode.Number
            returnData.IsBBX = Me.IsBBX
            returnData.TrackingLocationManualLocation = Me.SelectedTrackingLocationWI
            returnData.TrackingLocationName = Me.SelectedTrackingLocationName
            returnData.TrackingLocationID = Me.SelectedTrackingLocationID
            returnData.TestID = Me.TestID
            returnData.TestWILink = Me.TestWILink
            returnData.NoBSN = Me.NoBSN

            If (returnData.BatchData IsNot Nothing) Then
                returnData.CPRNumber = returnData.BatchData.CPRNumber
                'returnData.HWRevision = returnData.BatchData.HWRevision
                returnData.ProductID = returnData.BatchData.ProductID
                returnData.ProductType = returnData.BatchData.ProductType
                returnData.ProductTypeID = returnData.BatchData.ProductTypeID
                returnData.AccessoryType = returnData.BatchData.AccessoryGroup
                returnData.AccessoryTypeID = returnData.BatchData.AccessoryGroupID
                returnData.JobName = returnData.BatchData.JobName
                returnData.ProductGroup = returnData.BatchData.ProductGroup
                returnData.JobWILink = returnData.BatchData.JobWILocation
            Else
                returnData.CPRNumber = Me.CPRNumber
                returnData.HWRevision = Me.HWRevision
                returnData.ProductID = Me.ProductID
                returnData.ProductType = Me.ProductType
                returnData.ProductTypeID = Me.ProductTypeID
                returnData.AccessoryType = Me.AccessoryType
                returnData.AccessoryTypeID = Me.AccessoryTypeID
                returnData.JobName = Me.JobName
                returnData.ProductGroup = Me.ProductGroupName
                returnData.JobWILink = Me.JobWI
            End If

            If ScanSuccess Then
                returnData.Notifications.AddWithMessage(String.Format("{0} scanned in successfully", Barcode.ToString), NotificationType.Information)
            End If

            returnData.Notifications.Add(Me.Notifications)
        End Sub
    End Class
End Namespace