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
        Private _completionPriorityID As Int32
        Private _completionPriority As String
        Private _testStageName As String
        Private _hasBatchSpecificExceptions As Boolean
        Private _comments As List(Of IBatchCommentView)
        Private _trsData As IQRARequest
        Private _jobName As String
        Private _continueOnFailures As Boolean
        Private _qraNumber As String
        Private _isMQual As Boolean
        Private _orientation As IOrientation
        Private _assemblyNumber As String
        Private _assemblyRevision As String
        Private _testCenterLocationID As Int32
        Private _dateReportApproved As DateTime
        Private _testStageCompletionStatus As TestStageCompletionStatus
        Private _productGroup As String
        Private _productType As String
        Private _accessoryGroup As String
        Private _reportingRequiredBy As DateTime
        Private _testCenterLocation As String
        Private _purpose As String
        Private _purposeID As Int32
        Private _numberOfUnits As Integer
        Private _jobWILocation As String
        Private _hasUnitsRequiredToBeReturnedToRequestor As Boolean
        Private _hasUnitsNotReturnedToRequestor As Boolean
        Private _activeTaskAssignee As String
        Private _cprNumber As String
        Private _mechanicalTools As String
        Private _hwRevision As String
        Private _productID As Int32
        Private _testStageID As Int32
        Private _productTypeID As Int32
        Private _jobID As Int32
        Private _accessoryGroupID As Int32
        Private _rqID As Int32
        Private _estTSCompletionTime As Double
        Private _estJobCompletionTime As Double
        Private _partName As String
        Private _dateCreated As DateTime
        Private _testStageTimeLeftGrid As Dictionary(Of String, Double)
        Private _testStageIDTimeLeftGrid As Dictionary(Of String, Int32)
        Private _executiveSummary As String
        Private _orientationID As Int32
        Private _orientationXML As String
#End Region

#Region "Constructors"
        Private Sub SharedInitialisation()
            _completionPriorityID = 0
            _status = BatchStatus.NotSet
            _testStageCompletionStatus = TestStageCompletionStatus.NotSet
            _purpose = "NotSet"
            _comments = New List(Of IBatchCommentView)
            _trsData = New RequestBase()
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
                _qraNumber = QRAnumber.Trim()
            Else
                Throw New ArgumentNullException("The QRA number given to the batch constructor was null.")
            End If
        End Sub

        ''' <summary>
        ''' Used to create a new batch
        ''' </summary>
        ''' <param name="trsData"></param>
        ''' <remarks></remarks>
        Public Sub New(ByVal trsData As IQRARequest)
            SharedInitialisation()
            If trsData Is Nothing Then
                Me.Notifications.AddWithMessage("Unable to locate request.", NotificationType.Errors)
            End If
            Me.TRSData = trsData
            If Status = BatchStatus.NotSet Then
                Status = BatchStatus.NotSavedToREMI
            End If
        End Sub
#End Region

#Region "Public Properties"
        Public Property ActiveTaskAssignee() As String Implements IBatch.ActiveTaskAssignee
            Get
                Return _activeTaskAssignee
            End Get
            Set(ByVal value As String)
                _activeTaskAssignee = value
            End Set
        End Property

        <NotNullOrEmpty(Key:="w8")> _
        <ValidTRSRequestString(Key:="w9")> _
        Public Property QRANumber() As String Implements IBatch.QRANumber
            Get
                If Not String.IsNullOrEmpty(_qraNumber) Then
                    Return _qraNumber
                Else
                    Return _trsData.RequestNumber
                End If
            End Get
            Set(ByVal value As String)
                If Not String.IsNullOrEmpty(value) Then
                    _qraNumber = value.Trim()
                End If
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the associated product group of the batch. 
        ''' </summary> 
        <NotNullOrEmpty(Key:="w11")> _
        Public Property ProductGroup() As String Implements IBatch.ProductGroup
            Get
                If Not String.IsNullOrEmpty(_productGroup) Then
                    Return _productGroup
                Else
                    Return _trsData.ProductGroup
                End If
            End Get
            Set(ByVal value As String)
                _productGroup = value
            End Set
        End Property

        Public Property EstJobCompletionTime() As Double Implements IBatch.EstJobCompletionTime
            Set(value As Double)
                _estJobCompletionTime = value
            End Set
            Get
                Return _estJobCompletionTime
            End Get
        End Property

        Public ReadOnly Property GetJoinedComments() As String
            Get
                Return (String.Join(Environment.NewLine, (From c In Me.Comments Select c.Text).ToArray()))
            End Get
        End Property

        Public Property PartName() As String Implements IBatch.PartName
            Get
                If Not String.IsNullOrEmpty(_partName) Then
                    Return _partName
                Else
                    Return _trsData.PartName
                End If
            End Get
            Set(ByVal value As String)
                _partName = value
            End Set
        End Property

        Public Property CPRNumber() As String Implements IBatch.CPRNumber
            Get
                If Not String.IsNullOrEmpty(_cprNumber) Then
                    Return _cprNumber
                Else
                    Return _trsData.CPRNumber
                End If
            End Get
            Set(ByVal value As String)
                _cprNumber = value
            End Set
        End Property

        Public Property ExecutiveSummary() As String Implements IBatch.ExecutiveSummary
            Get
                If Not String.IsNullOrEmpty(_executiveSummary) Then
                    Return _executiveSummary
                Else
                    Return _trsData.ExecutiveSummary
                End If
            End Get
            Set(ByVal value As String)
                _executiveSummary = value
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

        Public Property EstTSCompletionTime() As Double Implements IBatch.EstTSCompletionTime
            Set(value As Double)
                _estTSCompletionTime = value
            End Set
            Get
                Return _estTSCompletionTime
            End Get
        End Property

        Public Property ReqID() As Integer Implements IBatch.ReqID
            Set(value As Integer)
                _rqID = value
            End Set
            Get
                If _rqID < 0 Then
                    Return _rqID
                Else
                    Return _trsData.RQID
                End If
            End Get
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
        Public Property ProductType() As String Implements IBatch.ProductType
            Get
                If Not String.IsNullOrEmpty(_productType) Then
                    Return _productType
                Else
                    Return _trsData.ProductType
                End If
            End Get
            Set(ByVal value As String)
                _productType = value
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

        Public Property TestStageID() As Int32 Implements IBatch.TestStageID
            Get
                Return _testStageID
            End Get
            Set(ByVal value As Int32)
                _testStageID = value
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

        Public Property IsMQual() As Boolean Implements IBatch.IsMQual
            Get
                Return _isMQual
            End Get
            Set(ByVal value As Boolean)
                _isMQual = value
            End Set
        End Property

        Public ReadOnly Property IsMQualString() As String Implements IBatch.IsMQualString
            Get
                If IsMQual Then
                    Return "Yes"
                Else
                    Return String.Empty
                End If
            End Get
        End Property

        ''' <summary> 
        ''' Gets or sets the associated accessory group of the batch. 
        ''' </summary> 
        Public Property AccessoryGroup() As String Implements IBatch.AccessoryGroup
            Get
                If Not String.IsNullOrEmpty(_accessoryGroup) Then
                    Return _accessoryGroup
                Else
                    Return _trsData.AccessoryGroup
                End If
            End Get
            Set(ByVal value As String)
                _accessoryGroup = value
            End Set
        End Property

        ''' <summary>
        ''' The name of the Job that this batch is currently doing.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        ''' 
        <NotNullOrEmpty(Key:="w10")> _
        Public Property JobName() As String Implements IBatch.JobName
            Get
                If String.IsNullOrEmpty(_jobName) Then
                    Return _trsData.RequestedTest()
                Else
                    Return _jobName
                End If
            End Get
            Set(ByVal value As String)
                _jobName = value
            End Set
        End Property

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
        Public Property HasBatchSpecificExceptions() As Boolean Implements IBatch.hasBatchSpecificExceptions
            Get
                Return _hasBatchSpecificExceptions
            End Get
            Set(ByVal value As Boolean)
                _hasBatchSpecificExceptions = value
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets the priority of the batch as set by Ops Manager
        ''' </summary> 
        Public Property CompletionPriority() As String Implements IBatch.CompletionPriority
            Get
                If Not String.IsNullOrEmpty(Me._completionPriority) Then
                    Return _completionPriority
                Else
                    Return _trsData.Priority
                End If
            End Get
            Set(ByVal value As String)
                _completionPriority = value
            End Set
        End Property

        Public Property CompletionPriorityID() As Int32 Implements IBatch.CompletionPriorityID
            Get
                Return _completionPriorityID
            End Get
            Set(ByVal value As Int32)
                _completionPriorityID = value
            End Set
        End Property

        ''' <summary>
        ''' Any comments associated with this batch.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
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

        ''' <summary> 
        ''' Gets or sets the current status of the batch. 
        ''' </summary> 
        <EnumerationSet(Key:="w13")> _
        Public Property Status() As BatchStatus Implements IBatch.Status
            Get
                Return _status
            End Get
            Set(ByVal value As BatchStatus)
                _status = value
            End Set
        End Property

        Public ReadOnly Property IsForDisposal() As Boolean
            Get
                'dates returned by trs data are in eastern time. no utc here.
                If Me.ReportApprovedDate <> DateTime.MinValue AndAlso Me.ReportApprovedDate.AddYears(3) < DateTime.Now Then
                    Return True
                End If
                Return False
            End Get
        End Property

        ''' <summary>
        ''' The REMI link for the batch information
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property BatchInfoLink() As String Implements IBatch.BatchInfoLink
            Get
                Return REMIWebLinks.GetBatchInfoLink(QRANumber)
            End Get
        End Property

        Public ReadOnly Property HasUnitsRequiredToBeReturnedToRequestor() As Boolean Implements IBatch.HasUnitsRequiredToBeReturnedToRequestor
            Get
                Return _hasUnitsNotReturnedToRequestor AndAlso _trsData.RequestorRequiresUnitsReturned
            End Get
        End Property

        Public Property HasUnitsNotReturnedToRequestor() As Boolean Implements IBatch.HasUnitsNotReturnedToRequestor
            Get
                Return _hasUnitsNotReturnedToRequestor
            End Get
            Set(ByVal value As Boolean)
                _hasUnitsNotReturnedToRequestor = value
            End Set
        End Property

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
        ''' Gets and sets the request purpose for the batch.
        ''' </summary>
        ''' <value>requestpurpose</value>
        ''' <returns>requestpurpose</returns>
        ''' <remarks></remarks>
        Public Property RequestPurpose() As String Implements IBatch.RequestPurpose
            Get
                If Me._purpose <> "NotSet" Then
                    Return Me._purpose
                Else
                    Return _trsData.RequestPurpose
                End If
            End Get
            Set(ByVal value As String)
                _purpose = value
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

        ''' <summary>
        ''' Returns the number of test unit objects that are part of the batch.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property NumberOfUnits() As Integer Implements IBatch.NumberofUnits
            Get
                Return _numberOfUnits
            End Get
            Set(ByVal value As Integer)
                _numberOfUnits = value
            End Set
        End Property

        ''' <summary>
        ''' The location of the current test
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property TestCenterLocation() As String Implements IBatch.TestCenterLocation
            Get
                If Not String.IsNullOrEmpty(Me._testCenterLocation) Then
                    Return _testCenterLocation
                Else
                    Return _trsData.TestCenterLocation
                End If
            End Get
            Set(ByVal value As String)
                _testCenterLocation = value
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

        ''' <summary>
        ''' the location of the work instruction on livelink or similar for the job this batch is currently doing.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property JobWILocation() As String Implements IBatch.JobWILocation
            Get
                Return _jobWILocation
            End Get
            Set(ByVal value As String)
                _jobWILocation = value
            End Set
        End Property

        Public Property MechanicalTools() As String Implements IBatch.MechanicalTools
            Get
                If Not String.IsNullOrEmpty(_mechanicalTools) Then
                    Return _mechanicalTools
                Else
                    Return _trsData.MechanicalTools
                End If
            End Get
            Set(value As String)
                _mechanicalTools = value
            End Set
        End Property

        Public Property AssemblyNumber() As String Implements IBatch.AssemblyNumber
            Get
                If Not String.IsNullOrEmpty(_assemblyNumber) Then
                    Return _assemblyNumber
                Else
                    Return _trsData.AssemblyNumber
                End If
            End Get
            Set(value As String)
                _assemblyNumber = value
            End Set
        End Property

        Public Property AssemblyRevision() As String Implements IBatch.AssemblyRevision
            Get
                If Not String.IsNullOrEmpty(_assemblyRevision) Then
                    Return _assemblyRevision
                Else
                    Return _trsData.AssemblyRevision
                End If
            End Get
            Set(value As String)
                _assemblyRevision = value
            End Set
        End Property

        Public Property HWRevision() As String Implements IBatch.HWRevision
            Get
                If Not String.IsNullOrEmpty(_hwRevision) Then
                    Return _hwRevision
                Else
                    Return _trsData.HWRevision
                End If
            End Get
            Set(value As String)
                _hwRevision = value
            End Set
        End Property

        Public Property ReportRequiredBy() As DateTime Implements IBatch.ReportRequiredBy
            Get
                If _reportingRequiredBy <> DateTime.MinValue Then
                    Return _reportingRequiredBy
                Else
                    Return _trsData.ReportRequiredBy
                End If
            End Get
            Set(value As DateTime)
                _reportingRequiredBy = value
            End Set
        End Property

        Public Property DateCreated() As DateTime Implements IBatch.DateCreated
            Get
                If _dateCreated <> DateTime.MinValue Then
                    Return _dateCreated
                Else
                    Return _trsData.DateCreated
                End If
            End Get
            Set(value As DateTime)
                _dateCreated = value
            End Set
        End Property

        Public Property ReportApprovedDate() As DateTime Implements IBatch.ReportApprovedDate
            Get
                If _dateReportApproved <> DateTime.MinValue Then
                    Return _dateReportApproved
                Else
                    Return _trsData.DateReportApproved
                End If
            End Get
            Set(value As DateTime)
                _dateReportApproved = value
            End Set
        End Property

        Public Property TestStageCompletion() As TestStageCompletionStatus Implements IBatch.TestStageCompletion
            Get
                Return _testStageCompletionStatus
            End Get
            Set(ByVal value As TestStageCompletionStatus)
                _testStageCompletionStatus = value
            End Set
        End Property
#End Region

#Region "REMI Out Of Date"
        ''' <summary>
        ''' checks if a field in remi si out of date compared to TRS. This should be changed to an attribute really.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Private ReadOnly Property REMIIsOutOfDate() As Boolean
            Get
                Return (Me._trsData.RequestPurpose <> "NotSet" AndAlso Me._purpose <> Me._trsData.RequestPurpose) _
                    OrElse (Me._trsData.TestCenterLocation <> String.Empty AndAlso Me._testCenterLocation <> Me._trsData.TestCenterLocation) _
                     OrElse (Me._trsData.ProductGroup <> String.Empty AndAlso Me._productGroup <> Me._trsData.ProductGroup) _
                     OrElse (Me._trsData.CPRNumber <> String.Empty AndAlso Me._cprNumber <> Me._trsData.CPRNumber) _
                     OrElse (Me._trsData.HWRevision <> String.Empty AndAlso Me.HWRevision <> Me._trsData.HWRevision) _
                     OrElse (Me._trsData.AccessoryGroup <> String.Empty AndAlso Me.AccessoryGroup <> Me._trsData.AccessoryGroup) _
                     OrElse (Me._trsData.PartName <> String.Empty AndAlso Me.PartName <> Me._trsData.PartName) _
                     OrElse (Me._trsData.AssemblyNumber <> String.Empty AndAlso Me.AssemblyNumber <> Me._trsData.AssemblyNumber) _
                     OrElse (Me._trsData.AssemblyRevision <> String.Empty AndAlso Me.AssemblyRevision <> Me._trsData.AssemblyRevision) _
                     OrElse (Me._trsData.ReportRequiredBy <> DateTime.MinValue AndAlso Me.ReportRequiredBy <> Me._trsData.ReportRequiredBy) _
                     OrElse (Me._trsData.DateReportApproved <> DateTime.MinValue AndAlso Me.ReportApprovedDate <> Me._trsData.DateReportApproved) _
                     OrElse (Me._trsData.ProductType <> String.Empty AndAlso Me.ProductType <> Me._trsData.ProductType) _
                     OrElse (Me.IsMQual <> Me._trsData.MQual)
            End Get
        End Property

        Public Function CheckForTRSUpdates() As Boolean
            If REMIIsOutOfDate Then
                _purpose = _trsData.RequestPurpose

                If (Not String.IsNullOrEmpty(_trsData.TestCenterLocation)) Then
                    _testCenterLocation = _trsData.TestCenterLocation
                End If

                If (Not String.IsNullOrEmpty(_trsData.ProductGroup)) Then
                    _productGroup = _trsData.ProductGroup
                End If

                If (Not String.IsNullOrEmpty(_trsData.CPRNumber)) Then
                    _cprNumber = _trsData.CPRNumber
                End If

                If (Not String.IsNullOrEmpty(_trsData.ProductType)) Then
                    _productType = _trsData.ProductType
                End If

                If (_trsData.DateReportApproved <> DateTime.MinValue) Then
                    _dateReportApproved = _trsData.DateReportApproved
                End If

                If (_trsData.ReportRequiredBy <> DateTime.MinValue) Then
                    _reportingRequiredBy = _trsData.ReportRequiredBy
                End If

                If (Not String.IsNullOrEmpty(_trsData.HWRevision)) Then
                    _hwRevision = _trsData.HWRevision
                End If

                If (Not String.IsNullOrEmpty(_trsData.AssemblyRevision)) Then
                    _assemblyRevision = _trsData.AssemblyRevision
                End If

                If (IsMQual <> Me._trsData.MQual) Then
                    _isMQual = _trsData.MQual
                End If

                If (Not String.IsNullOrEmpty(_trsData.AssemblyNumber)) Then
                    _assemblyNumber = _trsData.AssemblyNumber
                End If

                If (Not String.IsNullOrEmpty(_trsData.PartName)) Then
                    _partName = _trsData.PartName
                End If

                If (Not String.IsNullOrEmpty(_trsData.AccessoryGroup)) Then
                    _accessoryGroup = _trsData.AccessoryGroup
                End If

                Return True
            End If
            Return False
        End Function

        Public ReadOnly Property NeedsToBeSaved() As Boolean
            Get
                Return Me.Status = BatchStatus.NotSavedToREMI
            End Get
        End Property
#End Region

#Region "TRS Data Properties"
        ''' <summary>
        ''' Gets and sets the TRS data associated with this batch.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        ''' 
        <XmlIgnore()> _
        Public Property TRSData() As IQRARequest Implements IBatch.TRSData
            Get
                Return _trsData
            End Get
            Set(ByVal value As IQRARequest)
                If value IsNot Nothing Then
                    _trsData = value
                End If
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
        ''' The Job ID of this batch in the QA/Relab Databases.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property RelabJobID() As Integer Implements IBatch.RelabJobID
            Get
                Return _trsData.JobId
            End Get
        End Property

        ''' <summary>
        ''' indicates if a batch is complete in the trs
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property IsCompleteInTRS() As Boolean Implements IBatch.IsCompleteInTRS
            Get
                If _trsData.RequestStatus IsNot Nothing Then
                    Select Case _trsData.RequestStatus.ToLower
                        Case "completed", "canceled", "closed - pass", "closed - fail", "closed - no result"
                            Return True
                        Case Else
                            Return False
                    End Select
                End If
                Return False
            End Get
        End Property

        ''' <summary>
        ''' Gets the request id of the batch in the QA databases database. This is used to create the TRS http link for the batch.
        ''' </summary>
        ''' <value>integer</value>
        ''' <returns>integer</returns>
        ''' <remarks></remarks>
        Public ReadOnly Property NumberOfUnitsExpected() As Integer Implements IBatch.NumberOfUnitsExpected
            Get
                Return _trsData.SampleSize
            End Get
        End Property

        Public ReadOnly Property Requestor() As String
            Get
                Return _trsData.Requestor
            End Get
        End Property

        Public ReadOnly Property TRSStatus() As String
            Get
                Return _trsData.RequestStatus
            End Get
        End Property
#End Region

#Region "HTTP Links"
        'Public ReadOnly Property RelabResultLink2() As String Implements IBatch.RelabResultLink2
        '    Get
        '        Return REMIWebLinks.GetRelabResultLink2(RelabJobID)
        '    End Get
        'End Property

        Public ReadOnly Property RelabResultLink() As String Implements IBatch.RelabResultLink
            Get
                Return REMIWebLinks.GetRelabResultLink(ID)
            End Get
        End Property
        ''' <summary>
        ''' Returns the TRS link for the QRA in the batch.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property TRSLink() As String Implements IBatch.TRSLink
            Get
                Return REMIWebLinks.GetTRSLink(ReqID)
            End Get
        End Property
        Public ReadOnly Property DropTestWebAppLink() As String Implements IBatch.DropTestWebAppLink
            Get
                Return REMIWebLinks.GetDropTestWebAppLink(RelabJobID)
            End Get
        End Property
        Public ReadOnly Property TumbleTestWebAppLink() As String Implements IBatch.TumbleTestWebAppLink
            Get
                Return REMIWebLinks.GetTumbleTestWebAppLink(RelabJobID)
            End Get
        End Property
        Public ReadOnly Property TestRecordsLink() As String
            Get
                Return REMIWebLinks.GetTestRecordsLink(QRANumber, String.Empty, String.Empty, String.Empty, 0)
            End Get
        End Property
        Public ReadOnly Property TestRecordsAddNewLink() As String
            Get
                Return REMIWebLinks.GetTestRecordsAddLink(QRANumber)
            End Get
        End Property

        ''' <summary>
        ''' The REMI link for editing the exceptions for this batch.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property ExceptionManagerLink() As String
            Get
                Return REMIWebLinks.GetEditExceptionsLink(QRANumber)
            End Get
        End Property
        ''' <summary>
        ''' The REMI link for editing the status for this batch.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property SetStatusManagerLink() As String
            Get
                Return REMIWebLinks.GetSetBatchStatusLink(QRANumber)
            End Get
        End Property
        Public ReadOnly Property SetCommentsManagerLink() As String
            Get
                Return REMIWebLinks.GetSetBatchCommentsLink(QRANumber)
            End Get
        End Property
        Public ReadOnly Property SetTestDurationsManagerLink() As String
            Get
                Return REMIWebLinks.GetSetBatchSpecificTestDurationsLink(QRANumber)
            End Get
        End Property
        ''' <summary>
        ''' The REMI link for editing the test stage for this batch.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property SetTestStageManagerLink() As String
            Get
                Return REMIWebLinks.GetSetBatchTestStageLink(QRANumber)
            End Get
        End Property
        ''' <summary>
        ''' The REMI link for editing the priority for this batch.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property SetPriorityManagerLink() As String
            Get
                Return REMIWebLinks.GetSetBatchPriorityLink(QRANumber)
            End Get
        End Property

        ''' <summary>
        ''' The REMI product group information page for this batch.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property ProductGroupLink() As String Implements IBatch.ProductGroupLink
            Get
                Return REMIWebLinks.GetProductInfoLink(ProductID)
            End Get
        End Property

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