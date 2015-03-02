Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core
Imports System.Xml.Serialization

Namespace REMI.BusinessEntities
    <Serializable()> _
    Public Class BatchBase
        Inherits LoggedItemBase
        Implements IBatch
        Implements ICommentedItem

#Region "Declarations"
        Private _status As BatchStatus
        Private _testStageName As String
        Private _hasBatchSpecificExceptions As Boolean
        Private _comments As List(Of IBatchCommentView)
        Private _reqData As RequestFieldsCollection
        Private _jobName As String
        Private _requestor As String
        Private _continueOnFailures As Boolean
        Private _requestNumber As String
        Private _orientation As IOrientation
        Private _testStageCompletionStatus As TestStageCompletionStatus
        Private _jobWILocation As String
        Private _activeTaskAssignee As String
        Private _testStageID As Int32
        Private _sampleSize As Int32
        Private _jobID As Int32
        Private _estTSCompletionTime As Double
        Private _estJobCompletionTime As Double
        Private _testStageTimeLeftGrid As Dictionary(Of String, Double)
        Private _testStageIDTimeLeftGrid As Dictionary(Of String, Int32)
        Private _orientationID As Int32
        Private _orientationXML As String
        Private _requestLink As String
        Private _productGroup As String
        Private _productType As String
        Private _accessoryGroup As String
        Private _reportingRequiredBy As DateTime
        Private _testCenterLocation As String
        Private _purpose As String
        Private _purposeID As Int32
        Private _numberOfUnits As Integer
        Private _productTypeID As Int32
        Private _accessoryGroupID As Int32
        Private _dateCreated As DateTime
        Private _priorityID As Int32
        Private _Priority As String
        Private _executiveSummary As String
        Private _cprNumber As String
        Private _mechanicalTools As String
        Private _department As String
        Private _departmentID As Int32
        Private _productID As Int32
        Private _hasUnitsRequiredToBeReturnedToRequestor As Boolean
        Private _hasUnitsNotReturnedToRequestor As Boolean
        Private _testCenterLocationID As Int32
        Private _dateReportApproved As DateTime
        Private _outOfDate As Boolean
#End Region

#Region "Constructors"
        Private Sub SharedInitialisation()
            _priorityID = 0
            _status = BatchStatus.NotSet
            _testStageCompletionStatus = TestStageCompletionStatus.NotSet
            _purpose = "NotSet"
            _comments = New List(Of IBatchCommentView)
        End Sub

        ''' <summary>
        ''' Initializes a new instance of the Batch class. 
        ''' </summary>
        Public Sub New()
            SharedInitialisation()
        End Sub

        ''' <summary>
        ''' Initializes a new instance of the Batch class. 
        ''' </summary>
        Public Sub New(ByVal QRAnumber As String)
            SharedInitialisation()
            If Not String.IsNullOrEmpty(QRAnumber) Then
                _requestNumber = QRAnumber.Trim()
            Else
                Throw New ArgumentNullException("The QRA number given to the batch constructor was null.")
            End If
        End Sub

        ''' <summary>
        ''' Used to create a new batch
        ''' </summary>
        ''' <param name="reqData"></param>
        ''' <remarks></remarks>
        Public Sub New(ByVal reqData As RequestFieldsCollection)
            SharedInitialisation()
            If reqData Is Nothing Then
                Me.Notifications.AddWithMessage("Unable to locate request.", NotificationType.Errors)
            End If
            Me.ReqData = reqData
            _requestNumber = reqData(0).RequestNumber
            If Status = BatchStatus.NotSet Then
                Status = BatchStatus.NotSavedToREMI
            End If
        End Sub
#End Region

#Region "Public Properties"
        <XmlIgnore()> _
        Public Property ActiveTaskAssignee() As String Implements IBatch.ActiveTaskAssignee
            Get
                Return _activeTaskAssignee
            End Get
            Set(ByVal value As String)
                _activeTaskAssignee = value
            End Set
        End Property

        <NotNullOrEmpty(Key:="w8")> _
        <ValidRequestString(Key:="w9")> _
        Public Property QRANumber() As String Implements IBatch.RequestNumber
            Get
                Return _requestNumber
            End Get
            Set(ByVal value As String)
                If Not String.IsNullOrEmpty(value) Then
                    _requestNumber = value.Trim()
                End If
            End Set
        End Property

        <XmlIgnore()> _
        Public Property EstJobCompletionTime() As Double Implements IBatch.EstJobCompletionTime
            Set(value As Double)
                _estJobCompletionTime = value
            End Set
            Get
                Return _estJobCompletionTime
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property GetJoinedComments() As String
            Get
                Return (String.Join(Environment.NewLine, (From c In Me.Comments Select c.Text).ToArray()))
            End Get
        End Property

        Public Property OutOfDate() As Boolean
            Get
                Return _outOfDate
            End Get
            Set(value As Boolean)
                _outOfDate = value
            End Set
        End Property

        Public Property OrientationID() As Int32 Implements IBatch.OrientationID
            Get
                Return _orientationID
            End Get
            Set(ByVal value As Int32)
                _orientationID = value
            End Set
        End Property

        Public Property OrientationXML() As String Implements IBatch.OrientationXML
            Get
                Return _orientationXML
            End Get
            Set(ByVal value As String)
                _orientationXML = value
            End Set
        End Property

        <XmlIgnore()> _
        Public Property TestStageIDTimeLeftGrid() As Dictionary(Of String, Int32) Implements IBatch.TestStageIDTimeLeftGrid
            Set(value As Dictionary(Of String, Int32))
                _testStageIDTimeLeftGrid = value
            End Set
            Get
                Return _testStageIDTimeLeftGrid
            End Get
        End Property

        <XmlIgnore()> _
        Public Property TestStageTimeLeftGrid() As Dictionary(Of String, Double) Implements IBatch.TestStageTimeLeftGrid
            Set(value As Dictionary(Of String, Double))
                _testStageTimeLeftGrid = value
            End Set
            Get
                Return _testStageTimeLeftGrid
            End Get
        End Property

        <XmlIgnore()> _
        Public Property EstTSCompletionTime() As Double Implements IBatch.EstTSCompletionTime
            Set(value As Double)
                _estTSCompletionTime = value
            End Set
            Get
                Return _estTSCompletionTime
            End Get
        End Property

        Public Property TestStageID() As Int32 Implements IBatch.TestStageID
            Get
                Return _testStageID
            End Get
            Set(ByVal value As Int32)
                _testStageID = value
            End Set
        End Property

        <XmlIgnore()> _
        Public Property ContinueOnFailures() As Boolean Implements IBatch.ContinueOnFailures
            Get
                Return _continueOnFailures
            End Get
            Set(ByVal value As Boolean)
                _continueOnFailures = value
            End Set
        End Property

        Public Property JobID() As Int32 Implements IBatch.JobID
            Get
                Return _jobID
            End Get
            Set(ByVal value As Int32)
                _jobID = value
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the test stage the batch is at.
        ''' </summary>
        Public Property TestStageName() As String Implements IBatch.TestStageName
            Get
                Return _testStageName
            End Get
            Set(ByVal value As String)
                _testStageName = value
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets whether the batch has exceptions
        ''' </summary>
        <XmlIgnore()> _
        Public Property HasBatchSpecificExceptions() As Boolean Implements IBatch.hasBatchSpecificExceptions
            Get
                Return _hasBatchSpecificExceptions
            End Get
            Set(ByVal value As Boolean)
                _hasBatchSpecificExceptions = value
            End Set
        End Property

        ''' <summary>
        ''' Any comments associated with this batch.
        ''' </summary>
        <XmlIgnore()> _
        <ValidStringLength(MaxLength:=800, key:="w33")> _
        Public Property Comments() As List(Of IBatchCommentView) Implements ICommentedItem.Comments
            Get
                Return _comments
            End Get
            Set(ByVal value As List(Of IBatchCommentView))
                _comments = value
            End Set
        End Property

        <XmlIgnore()> _
        Public Property Orientation() As IOrientation Implements IBatch.Orientation
            Get
                Return _orientation
            End Get
            Set(ByVal value As IOrientation)
                If value IsNot Nothing Then
                    _orientation = value
                End If
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the current status of the batch. 
        ''' </summary> 
        <EnumerationSet(Key:="w13")> _
        Public Property Status() As BatchStatus Implements IBatch.Status
            Get
                If (_status = BatchStatus.NotSet) Then
                    _status = BatchStatus.NotSavedToREMI
                ElseIf (_status = BatchStatus.Received And RequestStatus = "Assigned") Then
                    _status = BatchStatus.InProgress
                ElseIf (RequestStatus = "Assigned" And Not (_status = BatchStatus.NotSet Or _status = BatchStatus.NotSavedToREMI)) Then
                    _status = BatchStatus.InProgress
                End If

                Return _status
            End Get
            Set(ByVal value As BatchStatus)
                _status = value
            End Set
        End Property

        ''' <summary>
        ''' The REMI link for the batch information
        ''' </summary>
        <XmlIgnore()> _
        Public ReadOnly Property BatchInfoLink() As String Implements IBatch.BatchInfoLink
            Get
                Return REMIWebLinks.GetBatchInfoLink(QRANumber)
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property RequestorRequiresUnitsReturned() As Boolean Implements IBatch.RequestorRequiresUnitsReturned
            Get
                Dim rur As Boolean = False
                Boolean.TryParse((From rd In ReqData Where rd.IntField = "RequestorRequiresUnitsReturned" Select rd.Value).FirstOrDefault(), rur)

                Return rur
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property HasUnitsRequiredToBeReturnedToRequestor() As Boolean Implements IBatch.HasUnitsRequiredToBeReturnedToRequestor
            Get
                Return HasUnitsNotReturnedToRequestor AndAlso RequestorRequiresUnitsReturned
            End Get
        End Property

        <XmlIgnore()> _
        Public Property HasUnitsNotReturnedToRequestor() As Boolean Implements IBatch.HasUnitsNotReturnedToRequestor
            Get
                Return _hasUnitsNotReturnedToRequestor
            End Get
            Set(ByVal value As Boolean)
                _hasUnitsNotReturnedToRequestor = value
            End Set
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property HasUnitsRequiredToBeReturnedToRequestorString() As String Implements IBatch.HasUnitsRequiredToBeReturnedToRequestorString
            Get
                If HasUnitsNotReturnedToRequestor Then
                    Return "Yes"
                Else
                    Return String.Empty
                End If
            End Get
        End Property

        ''' <summary>
        ''' Returns the number of test unit objects that are part of the batch.
        ''' </summary>
        Public Property NumberOfUnits() As Integer Implements IBatch.NumberofUnits
            Get
                Return _numberOfUnits
            End Get
            Set(ByVal value As Integer)
                _numberOfUnits = value
            End Set
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property IsForDisposal() As Boolean Implements IBatch.IsForDisposal
            Get
                'dates returned by trs data are in eastern time. no utc here.
                If Me.ReportApprovedDate <> DateTime.MinValue AndAlso Me.ReportApprovedDate.AddYears(3) < DateTime.Now Then
                    Return True
                End If
                Return False
            End Get
        End Property

        ''' <summary>
        ''' the location of the work instruction on livelink or similar for the job this batch is currently doing.
        ''' </summary>
        <XmlIgnore()> _
        Public Property JobWILocation() As String Implements IBatch.JobWILocation
            Get
                Return _jobWILocation
            End Get
            Set(ByVal value As String)
                _jobWILocation = value
            End Set
        End Property

        <XmlIgnore()> _
        Public Property TestStageCompletion() As TestStageCompletionStatus Implements IBatch.TestStageCompletion
            Get
                Return _testStageCompletionStatus
            End Get
            Set(ByVal value As TestStageCompletionStatus)
                _testStageCompletionStatus = value
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the associated product group of the batch. 
        ''' </summary> 
        <NotNullOrEmpty(Key:="w11")> _
        Public Property ProductID() As Int32 Implements IBatch.ProductID
            Get
                Return _productID
            End Get
            Set(ByVal value As Int32)
                _productID = value
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the associated product type of the batch. 
        ''' </summary> 
        Public Property ProductTypeID() As Int32 Implements IBatch.ProductTypeID
            Get
                Return _productTypeID
            End Get
            Set(ByVal value As Int32)
                _productTypeID = value
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the associated accessory group of the batch. 
        ''' </summary> 
        Public Property AccessoryGroupID() As Int32 Implements IBatch.AccessoryGroupID
            Get
                Return _accessoryGroupID
            End Get
            Set(ByVal value As Int32)
                _accessoryGroupID = value
            End Set
        End Property

        Public Property RequestPurposeID() As Int32 Implements IBatch.RequestPurposeID
            Get
                Return _purposeID
            End Get
            Set(ByVal value As Int32)
                _purposeID = value
            End Set
        End Property

        Public Property PriorityID() As Int32 Implements IBatch.PriorityID
            Get
                Return _priorityID
            End Get
            Set(ByVal value As Int32)
                _priorityID = value
            End Set
        End Property

        Public Property TestCenterLocationID() As Int32 Implements IBatch.TestCenterLocationID
            Get
                Return _testCenterLocationID
            End Get
            Set(ByVal value As Int32)
                _testCenterLocationID = value
            End Set
        End Property

        Public Property DepartmentID() As Int32 Implements IBatch.DepartmentID
            Get
                Return _departmentID
            End Get
            Set(ByVal value As Int32)
                _departmentID = value
            End Set
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property NeedsToBeSaved() As Boolean Implements IBatch.NeedsToBeSaved
            Get
                Return Me.Status = BatchStatus.NotSavedToREMI
            End Get
        End Property

        Public Property ReqData() As RequestFieldsCollection
            Get
                Return _reqData
            End Get
            Set(value As RequestFieldsCollection)
                _reqData = value
            End Set
        End Property

        ''' <summary>
        ''' indicates if a batch is complete in the request
        ''' </summary>
        <XmlIgnore()> _
        Public ReadOnly Property IsCompleteInRequest() As Boolean Implements IBatch.IsCompleteInRequest
            Get
                If (From rd In ReqData Where rd.IntField = "RequestStatus" Select rd.Value).FirstOrDefault() IsNot Nothing Then
                    Select Case (From rd In ReqData Where rd.IntField = "RequestStatus" Select rd.Value).FirstOrDefault().ToLower
                        Case "completed", "canceled", "closed - pass", "closed - fail", "closed - no result"
                            Return True
                        Case Else
                            Return False
                    End Select
                End If
                Return False
            End Get
        End Property

#Region "Linked Fields Required By System From Request"
        ''' <summary>
        ''' The name of the Job that this batch is currently doing.
        ''' </summary>
        <NotNullOrEmpty(Key:="w10")> _
        Public Property JobName() As String Implements IBatch.JobName
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "RequestedTest" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "RequestedTest" Select rd.Value).FirstOrDefault()
                End If

                If (_jobName = val) Then
                    val = _jobName
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _jobName = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "RequestedTest" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "RequestedTest" Select rd.Value).FirstOrDefault()
                End If

                If (_jobName <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the associated product group of the batch. 
        ''' </summary> 
        <NotNullOrEmpty(Key:="w11")> _
        Public Property ProductGroup() As String Implements IBatch.ProductGroup
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "ProductGroup" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "ProductGroup" Select rd.Value).FirstOrDefault()
                End If

                If (_productGroup = val) Then
                    val = _productGroup
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _productGroup = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "ProductGroup" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "ProductGroup" Select rd.Value).FirstOrDefault()
                End If

                If (_productGroup <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        Public Property CPRNumber() As String Implements IBatch.CPRNumber
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "CPRNumber" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "CPRNumber" Select rd.Value).FirstOrDefault()
                End If

                If (_cprNumber = val) Then
                    val = _cprNumber
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _cprNumber = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "CPRNumber" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "CPRNumber" Select rd.Value).FirstOrDefault()
                End If

                If (_cprNumber <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        <XmlIgnore()> _
        Public Property ExecutiveSummary() As String Implements IBatch.ExecutiveSummary
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "ExecutiveSummary" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "ExecutiveSummary" Select rd.Value).FirstOrDefault()
                End If

                If (_executiveSummary = val) Then
                    val = _executiveSummary
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _executiveSummary = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "ExecutiveSummary" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "ExecutiveSummary" Select rd.Value).FirstOrDefault()
                End If

                If (_executiveSummary <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the associated product type of the batch. 
        ''' </summary> 
        Public Property ProductType() As String Implements IBatch.ProductType
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "ProductType" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "ProductType" Select rd.Value).FirstOrDefault()
                End If

                If (_productType = val) Then
                    val = _productType
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _productType = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "ProductType" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "ProductType" Select rd.Value).FirstOrDefault()
                End If

                If (_productType <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the associated accessory group of the batch. 
        ''' </summary> 
        Public Property AccessoryGroup() As String Implements IBatch.AccessoryGroup
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "AccessoryGroup" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "AccessoryGroup" Select rd.Value).FirstOrDefault()
                End If

                If (_accessoryGroup = val) Then
                    val = _accessoryGroup
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _accessoryGroup = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "AccessoryGroup" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "AccessoryGroup" Select rd.Value).FirstOrDefault()
                End If

                If (_accessoryGroup <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        ''' <summary>
        ''' Gets and sets the request purpose for the batch.
        ''' </summary>
        ''' <value>requestpurpose</value>
        ''' <returns>requestpurpose</returns>
        Public Property RequestPurpose() As String Implements IBatch.RequestPurpose
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "RequestPurpose" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "RequestPurpose" Select rd.Value).FirstOrDefault()
                End If

                If (_purpose = val) Then
                    val = _purpose
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _purpose = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "RequestPurpose" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "RequestPurpose" Select rd.Value).FirstOrDefault()
                End If

                If (_purpose <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        ''' <summary>
        ''' The location of the current test
        ''' </summary>
        Public Property TestCenterLocation() As String Implements IBatch.TestCenterLocation
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "TestCenterLocation" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "TestCenterLocation" Select rd.Value).FirstOrDefault()
                End If

                If (_testCenterLocation = val) Then
                    val = _testCenterLocation
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _testCenterLocation = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "TestCenterLocation" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "TestCenterLocation" Select rd.Value).FirstOrDefault()
                End If

                If (_testCenterLocation <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the priority of the batch as set by Ops Manager
        ''' </summary> 
        Public Property Priority() As String Implements IBatch.Priority
            Get
                Dim val As String = String.Empty
                val = _Priority

                If ((From rd In ReqData Where rd.IntField = "Priority" Select rd.Value) IsNot Nothing And (_Priority = String.Empty Or _Priority = "NotSet")) Then
                    val = (From rd In ReqData Where rd.IntField = "Priority" Select rd.Value).FirstOrDefault()
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _Priority = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "Priority" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "Priority" Select rd.Value).FirstOrDefault()
                End If

                If (_Priority <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        Public ReadOnly Property RequestStatus() As String
            Get
                Return (From rd In ReqData Where rd.IntField = "RequestStatus" Select rd.Value).FirstOrDefault()
            End Get
        End Property

        Public Property MechanicalTools() As String Implements IBatch.MechanicalTools
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "MechanicalTools" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "MechanicalTools" Select rd.Value).FirstOrDefault()
                End If

                If (_mechanicalTools = val) Then
                    val = _mechanicalTools
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _mechanicalTools = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "MechanicalTools" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "MechanicalTools" Select rd.Value).FirstOrDefault()
                End If

                If (_mechanicalTools <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        Public Property Department() As String Implements IBatch.Department
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "Department" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "Department" Select rd.Value).FirstOrDefault()
                End If

                If (_department = val) Then
                    val = _department
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _department = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "Department" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "Department" Select rd.Value).FirstOrDefault()
                End If

                If (_department <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        Public Property RequestLink() As String Implements IBatch.RequestLink
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "RequestLink" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "RequestLink" Select rd.Value).FirstOrDefault()
                End If

                If (_requestLink = val) Then
                    val = _requestLink
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _requestLink = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "RequestLink" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "RequestLink" Select rd.Value).FirstOrDefault()
                End If

                If (_requestLink <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        Public Property NumberOfUnitsExpected() As Int32 Implements IBatch.NumberOfUnitsExpected
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "SampleSize" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "SampleSize" Select rd.Value).FirstOrDefault()
                End If

                If (_sampleSize.ToString() = val) Then
                    val = _sampleSize.ToString()
                End If

                Dim unitCount As Int32
                Int32.TryParse(val, unitCount)

                Return unitCount
            End Get
            Set(ByVal data As Int32)
                _sampleSize = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "SampleSize" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "SampleSize" Select rd.Value).FirstOrDefault()
                End If

                If (_sampleSize.ToString() <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        Public Property Requestor() As String Implements IBatch.Requestor
            Get
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "Requestor" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "Requestor" Select rd.Value).FirstOrDefault()
                End If

                If (_requestor = val) Then
                    val = _requestor
                End If

                Return val
            End Get
            Set(ByVal data As String)
                _requestor = data
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "Requestor" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "Requestor" Select rd.Value).FirstOrDefault()
                End If

                If (_requestor <> val) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        <XmlIgnore()> _
        Public Property DateCreated() As DateTime Implements IBatch.DateCreated
            Get
                Dim createdDate As DateTime
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "DateCreated" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "DateCreated" Select rd.Value).FirstOrDefault()
                End If

                DateTime.TryParse(val, createdDate)

                If (_dateCreated = createdDate) Then
                    createdDate = _dateCreated
                End If

                Return createdDate
            End Get
            Set(ByVal data As DateTime)
                _dateCreated = data
                Dim createdDate As DateTime
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "DateCreated" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "DateCreated" Select rd.Value).FirstOrDefault()
                End If

                DateTime.TryParse(val, createdDate)

                If (_dateCreated <> createdDate) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        <XmlIgnore()> _
        Public Property ReportRequiredBy() As DateTime Implements IBatch.ReportRequiredBy
            Get
                Dim reportDate As DateTime
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "ReportRequiredBy" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "ReportRequiredBy" Select rd.Value).FirstOrDefault()
                End If

                DateTime.TryParse(val, reportDate)

                If (_reportingRequiredBy = reportDate) Then
                    reportDate = _reportingRequiredBy
                End If

                Return reportDate
            End Get
            Set(ByVal data As DateTime)
                _reportingRequiredBy = data
                Dim reportDate As DateTime
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "ReportRequiredBy" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "ReportRequiredBy" Select rd.Value).FirstOrDefault()
                End If

                DateTime.TryParse(val, reportDate)

                If (_reportingRequiredBy <> reportDate) Then
                    OutOfDate = True
                End If
            End Set
        End Property

        <XmlIgnore()> _
        Public Property ReportApprovedDate() As DateTime Implements IBatch.ReportApprovedDate
            Get
                Dim approveDate As DateTime
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "DateReportApproved" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "DateReportApproved" Select rd.Value).FirstOrDefault()
                End If

                DateTime.TryParse(val, approveDate)

                If (_dateReportApproved = approveDate) Then
                    approveDate = _dateReportApproved
                End If

                Return approveDate
            End Get
            Set(ByVal data As DateTime)
                _dateReportApproved = data
                Dim approveDate As DateTime
                Dim val As String = String.Empty

                If ((From rd In ReqData Where rd.IntField = "DateReportApproved" Select rd.Value) IsNot Nothing) Then
                    val = (From rd In ReqData Where rd.IntField = "DateReportApproved" Select rd.Value).FirstOrDefault()
                End If

                DateTime.TryParse(val, approveDate)

                If (_dateReportApproved <> approveDate) Then
                    OutOfDate = True
                End If
            End Set
        End Property
#End Region
#End Region

#Region "HTTP Links"
        <XmlIgnore()> _
        Public ReadOnly Property RelabResultLink() As String Implements IBatch.RelabResultLink
            Get
                Return REMIWebLinks.GetRelabResultLink(ID)
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property TestRecordsLink() As String
            Get
                Return REMIWebLinks.GetTestRecordsLink(QRANumber, String.Empty, String.Empty, String.Empty, 0)
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property TestRecordsAddNewLink() As String
            Get
                Return REMIWebLinks.GetTestRecordsAddLink(QRANumber)
            End Get
        End Property

        ''' <summary>
        ''' The REMI link for editing the exceptions for this batch.
        ''' </summary>
        <XmlIgnore()> _
        Public ReadOnly Property ExceptionManagerLink() As String
            Get
                Return REMIWebLinks.GetEditExceptionsLink(QRANumber)
            End Get
        End Property

        ''' <summary>
        ''' The REMI link for editing the status for this batch.
        ''' </summary>
        <XmlIgnore()> _
        Public ReadOnly Property SetStatusManagerLink() As String
            Get
                Return REMIWebLinks.GetSetBatchStatusLink(QRANumber)
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property SetTestDurationsManagerLink() As String
            Get
                Return REMIWebLinks.GetSetBatchSpecificTestDurationsLink(QRANumber)
            End Get
        End Property

        ''' <summary>
        ''' The REMI link for editing the test stage for this batch.
        ''' </summary>
        <XmlIgnore()> _
        Public ReadOnly Property SetTestStageManagerLink() As String
            Get
                Return REMIWebLinks.GetSetBatchTestStageLink(QRANumber)
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property ExecutiveSummaryLink() As String
            Get
                Return REMIWebLinks.GetExecutiveSummaryLink(QRANumber)
            End Get
        End Property

        ''' <summary>
        ''' The REMI link for editing the priority for this batch.
        ''' </summary>
        <XmlIgnore()> _
        Public ReadOnly Property SetPriorityManagerLink() As String
            Get
                Return REMIWebLinks.GetSetBatchPriorityLink(QRANumber)
            End Get
        End Property

        ''' <summary>
        ''' The REMI product group information page for this batch.
        ''' </summary>
        <XmlIgnore()> _
        Public ReadOnly Property ProductGroupLink() As String Implements IBatch.ProductGroupLink
            Get
                Return REMIWebLinks.GetProductInfoLink(ProductID)
            End Get
        End Property

        <XmlIgnore()> _
        Public ReadOnly Property JobLink() As String Implements IBatch.JobLink
            Get
                Return REMIWebLinks.GetJobLink(Me.JobID)
            End Get
        End Property

        Public Overridable Function GetTestOverviewCellString(ByVal jobName As String, ByVal testStageName As String, ByVal TestName As String, ByVal hasEditAuthority As Boolean, ByVal isTestCenterAdmin As Boolean, ByVal rqResults As DataTable, ByVal hasBatchSetupAuthority As Boolean, ByVal showHyperlinks As Boolean) As String Implements IBatch.GetTestOverviewCellString
            Return String.Empty
        End Function
#End Region

    End Class
End Namespace