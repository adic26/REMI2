Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.BusinessEntities
    ''' <summary>
    ''' This class represents a Request in the relab request system.
    ''' It can be used to composite other classes from its parameters.
    ''' It stores the 3 parameters common to the TRS items and stores the rest as parameters which can be accessed from the other classes
    ''' </summary>
    ''' <remarks></remarks>
    <Serializable()> _
    Public Class RequestBase
        Inherits ValidationBase
        Implements IQRARequest

#Region "Private Variables"
        Private _requestStatus As String = String.Empty
        Private _req As RequestNumber
        Private _requestProperties As Dictionary(Of String, String)
        Private _fieldMapping As Dictionary(Of String, String)
        Private _affectsUnits As List(Of Integer)
#End Region

#Region "Constructor"
        Public Sub New()
            _req = New RequestNumber()
            _requestProperties = New Dictionary(Of String, String)
            _fieldMapping = New Dictionary(Of String, String)
            _affectsUnits = New List(Of Integer)
        End Sub

        Public Sub New(ByVal reqNumber As RequestNumber)
            _requestProperties = New Dictionary(Of String, String)
            _req = reqNumber
            _affectsUnits = New List(Of Integer)
            _fieldMapping = New Dictionary(Of String, String)
        End Sub
#End Region

#Region "Public properties"
        Public Property RequestProperties() As Dictionary(Of String, String) Implements IQRARequest.RequestProperties
            Get
                Return _requestProperties
            End Get
            Set(ByVal value As Dictionary(Of String, String))
                _requestProperties = value
            End Set
        End Property

        Public Property FieldMapping() As Dictionary(Of String, String) Implements IQRARequest.FieldMapping
            Get
                Return _fieldMapping
            End Get
            Set(ByVal value As Dictionary(Of String, String))
                _fieldMapping = value
            End Set
        End Property

        Public Property RequestNumber() As String Implements IQRARequest.RequestNumber
            Get
                If _req IsNot Nothing Then
                    Return _req.Number
                Else
                    Return String.Empty
                End If
            End Get
            Set(value As String)
                _req.Number = value
            End Set
        End Property

        Public ReadOnly Property Requestor() As String Implements IQRARequest.Requestor
            Get
                Dim req As String = GetProperty("Requestor")

                If Not String.IsNullOrEmpty(req) Then
                    Dim tmpStr As String = GetSamAccountNameFromFullName(req)
                    If Not String.IsNullOrEmpty(tmpStr) Then
                        req = tmpStr
                    End If
                End If

                Return req
            End Get
        End Property

        <ValidIDNumber(Message:="The RQID property for this request must be greater than 0.")> _
        Public ReadOnly Property RQID() As Integer Implements IQRARequest.RQID
            Get
                Dim val As Integer
                Integer.TryParse(GetProperty("RQID"), val)
                Return val
            End Get
        End Property

        Public ReadOnly Property RequestStatus() As String Implements IQRARequest.RequestStatus
            Get
                Return GetProperty("RequestStatus")
            End Get
        End Property

        Public ReadOnly Property TRSLink() As String Implements IQRARequest.TRSLink
            Get
                Return REMIWebLinks.GetTRSLink(Me.RQID)
            End Get
        End Property

        Public ReadOnly Property RequestType() As String Implements IQRARequest.RequestType
            Get
                Return _req.Type
            End Get
        End Property

        Public ReadOnly Property SampleSize() As Integer Implements IQRARequest.SampleSize
            Get
                Dim val As Integer
                Integer.TryParse(GetProperty("SampleSize"), val)
                Return val
            End Get
        End Property

        Public ReadOnly Property AssemblyRevision() As String Implements IQRARequest.AssemblyRevision
            Get
                Return GetProperty("AssemblyRevision")
            End Get
        End Property

        Public ReadOnly Property AssemblyNumber() As String Implements IQRARequest.AssemblyNumber
            Get
                Return GetProperty("AssemblyNumber")
            End Get
        End Property

        Public ReadOnly Property CPRNumber() As String Implements IQRARequest.CPRNumber
            Get
                Return GetProperty("CPRNumber")
            End Get
        End Property

        Public ReadOnly Property HWRevision() As String Implements IQRARequest.HWRevision
            Get
                Return "Not Available"
            End Get
        End Property

        Public ReadOnly Property JobId() As Integer Implements IQRARequest.JobId
            Get
                Dim val As Integer
                Integer.TryParse(GetProperty("JobId"), val)
                Return val
            End Get
        End Property

        Public ReadOnly Property DateCreated() As DateTime Implements IQRARequest.DateCreated
            Get
                Dim val As DateTime
                DateTime.TryParse(GetProperty("DateCreated"), val)
                Return val
            End Get
        End Property

        Public ReadOnly Property RequestPurpose() As String Implements IQRARequest.RequestPurpose
            Get
                Return GetProperty("RequestPurpose")
            End Get
        End Property

        Public ReadOnly Property RequestedTest() As String Implements IQRARequest.RequestedTest
            Get
                Return GetProperty("RequestedTest")
            End Get
        End Property

        Public ReadOnly Property TestCenterLocation() As String Implements IQRARequest.TestCenterLocation
            Get
                'Dim testcenter As String = GetProperty("Test Center Location").Trim()

                'If (Not String.IsNullOrEmpty(testcenter)) Then
                '    Return GetProperty("Test Center Location") 'fa
                'Else
                '    Return GetProperty("test centre location")
                'End If

                Return GetProperty("TestCenterLocation")
            End Get
        End Property

        Public ReadOnly Property ProductGroup() As String Implements IQRARequest.ProductGroup
            Get
                Return GetProperty("ProductGroup")
            End Get
        End Property

        Public ReadOnly Property ProductType() As String Implements IQRARequest.ProductType
            Get
                Return GetProperty("ProductType")
            End Get
        End Property

        Public ReadOnly Property AccessoryGroup() As String Implements IQRARequest.AccessoryGroup
            Get
                Return GetProperty("AccessoryGroup")
            End Get
        End Property

        Public ReadOnly Property Priority() As String Implements IQRARequest.Priority
            Get
                Return GetProperty("Priority")
            End Get
        End Property

        Public ReadOnly Property PercentComplete() As String Implements IQRARequest.PercentComplete
            Get
                Return GetProperty("PercentComplete")
            End Get
        End Property

        Public ReadOnly Property ReportType() As String Implements IQRARequest.ReportType
            Get
                Return GetProperty("ReportType")
            End Get
        End Property

        Public ReadOnly Property DateReportApproved() As DateTime Implements IQRARequest.DateReportApproved
            Get
                Dim dt As DateTime
                DateTime.TryParse(GetProperty("DateReportApproved"), dt)
                Return dt
            End Get
        End Property

        Public ReadOnly Property IsReportRequired() As Boolean Implements IQRARequest.IsReportRequired
            Get
                Dim isRequired As Boolean

                Select Case GetProperty("IsReportRequired").ToLower.Trim
                    Case "yes"
                        isRequired = True
                    Case "no"
                        isRequired = False
                    Case Else
                        Boolean.TryParse(GetProperty("IsReportRequired"), isRequired)
                End Select

                Return isRequired
            End Get
        End Property

        Public ReadOnly Property IncludeInTempo() As Boolean Implements IQRARequest.IncludeInTempo
            Get
                Dim isRequired As Boolean

                Select Case GetProperty("IncludeInTempo").ToLower.Trim
                    Case "yes"
                        isRequired = True
                    Case "no"
                        isRequired = False
                    Case Else
                        Boolean.TryParse(GetProperty("IncludeInTempo"), isRequired)
                End Select

                Return isRequired
            End Get
        End Property

        Public ReadOnly Property ReportRequiredBy() As DateTime Implements IQRARequest.ReportRequiredBy
            Get
                Dim dt As DateTime
                'returns datetime.minvalue if it can't convert
                DateTime.TryParse(GetProperty("ReportRequiredBy"), dt)
                Return dt
            End Get
        End Property

        Public ReadOnly Property HasSpecialInstructions() As Boolean Implements IQRARequest.HasSpecialInstructions
            Get
                If Not String.IsNullOrEmpty(GetProperty("HasSpecialInstructions")) Then
                    Return True
                End If

                Return False
            End Get
        End Property

        Public Function GetSpecialInstructions() As String Implements IQRARequest.GetSpecialInstructions
            Dim str As New System.Text.StringBuilder()
            If Not String.IsNullOrEmpty(GetProperty("HasSpecialInstructions")) Then
                str.AppendLine("PM Notes: " + GetProperty("HasSpecialInstructions"))
            End If
            Return str.ToString()
        End Function

        Public ReadOnly Property PartName() As String Implements IQRARequest.PartName
            Get
                Return GetProperty("PartName")
            End Get
        End Property

        Public ReadOnly Property ReasonForRequest() As String Implements IQRARequest.ReasonForRequest
            Get
                Return GetProperty("ReasonForRequest")
            End Get
        End Property

        Public ReadOnly Property BoardRevisionMinor() As String Implements IQRARequest.BoardRevisionMinor
            Get
                Return GetProperty("BoardRevisionMinor")
            End Get
        End Property

        Public ReadOnly Property MechanicalToolsRevisionMajor() As String Implements IQRARequest.MechanicalToolsRevisionMajor
            Get
                Return GetProperty("MechanicalToolsRevisionMajor")
            End Get
        End Property

        Public ReadOnly Property MechanicalToolsRevisionMinor() As String Implements IQRARequest.MechanicalToolsRevisionMinor
            Get
                Return GetProperty("MechanicalToolsRevisionMinor")
            End Get
        End Property

        Public ReadOnly Property POPNumber() As String Implements IQRARequest.POPNumber
            Get
                Return GetProperty("POPNumber")
            End Get
        End Property

        Public ReadOnly Property BoardRevision() As String Implements IQRARequest.BoardRevision
            Get
                Return GetProperty("BoardRevision")
            End Get
        End Property

        Public ReadOnly Property SampleAvailableDate() As DateTime Implements IQRARequest.SampleAvailableDate
            Get
                Dim dt As DateTime
                DateTime.TryParse(GetProperty("SampleAvailableDate").ToString(), dt)
                Return dt
            End Get
        End Property

        Public ReadOnly Property ActualStartDate() As DateTime Implements IQRARequest.ActualStartDate
            Get
                Dim dt As DateTime
                DateTime.TryParse(GetProperty("ActualStartDate").ToString(), dt)
                Return dt
            End Get
        End Property

        Public ReadOnly Property ActualEndDate() As DateTime Implements IQRARequest.ActualEndDate
            Get
                Dim dt As DateTime
                DateTime.TryParse(GetProperty("ActualEndDate").ToString(), dt)
                Return dt
            End Get
        End Property

        Public ReadOnly Property MechanicalTools() As String Implements IQRARequest.MechanicalTools
            Get
                Return GetProperty("MechanicalTools")
            End Get
        End Property

        Public ReadOnly Property ExecutiveSummary() As String Implements IQRARequest.ExecutiveSummary
            Get
                Return GetProperty("ExecutiveSummary")
            End Get
        End Property

        Public ReadOnly Property Department() As String Implements IQRARequest.Department
            Get
                Return GetProperty("Department")
            End Get
        End Property

        Public ReadOnly Property MQual() As Boolean Implements IQRARequest.MQual
            Get
                Dim isMQualString As String = GetProperty("MQual").ToString()

                Return If(isMQualString.ToLower() = "yes", True, False)
            End Get
        End Property

        Public ReadOnly Property RequestorRequiresUnitsReturned() As Boolean Implements IQRARequest.RequestorRequiresUnitsReturned
            Get
                Dim doReturn As Boolean

                Select Case GetProperty("RequestorRequiresUnitsReturned").ToLower.Trim
                    Case "yes"
                        doReturn = True
                    Case "no"
                        doReturn = False
                    Case Else
                        Boolean.TryParse(GetProperty("RequestorRequiresUnitsReturned"), doReturn)
                End Select

                Return doReturn
            End Get
        End Property

        Public Overloads Overrides Function Validate() As Boolean Implements IQRARequest.Validate
            Return MyBase.Validate
        End Function

#Region "SCM"
        Public ReadOnly Property EquipmentAffected() As String Implements IQRARequest.EquipmentAffected
            Get
                Return GetProperty("Equipment/System")
            End Get
        End Property

        Public ReadOnly Property Description() As String Implements IQRARequest.Description
            Get
                Return GetProperty("Description")
            End Get
        End Property
#End Region

#Region "RIT"
        Public ReadOnly Property IssueCategory() As String Implements IQRARequest.IssueCategory
            Get
                Return GetProperty("Issue Category")
            End Get
        End Property

        Public ReadOnly Property IssueDetails() As String Implements IQRARequest.IssueDetails
            Get
                Return GetProperty("Issue Details")
            End Get
        End Property

        Public ReadOnly Property Severity() As String Implements IQRARequest.Severity
            Get
                Return GetProperty("Severity")
            End Get
        End Property
        Public ReadOnly Property IssueEnvironment() As String Implements IQRARequest.IssueEnvironment
            Get
                Return GetProperty("Issue Environment")
            End Get
        End Property
        Public ReadOnly Property FailureSymptoms() As String Implements IQRARequest.FailureSymptoms
            Get
                Return GetProperty("Failure Symptom(s)")
            End Get
        End Property
#End Region

#Region "FA"
        Public Overridable ReadOnly Property Summary() As String Implements IQRARequest.Summary
            Get
                Dim summaryString As New System.Text.StringBuilder

                If (Not String.IsNullOrEmpty(FailureDescription)) Then
                    summaryString.Append("<b>Failure: </b> ")
                    summaryString.Append(FailureDescription)
                    summaryString.Append("<br />")
                    summaryString.Append("<b>Affected Units:</b> ")

                    If AffectsUnits.Count >= 1 Then
                        summaryString.Append(AffectsUnits(0).ToString)
                    End If
                    If AffectsUnits.Count > 1 Then
                        For Each i As Integer In AffectsUnits
                            summaryString.Append(", " + i.ToString)
                        Next
                    End If
                    summaryString.Append("<br />")

                    If (Not String.IsNullOrEmpty(TopLevel)) Then
                        summaryString.Append(String.Format("<b>Top Level:</b> {0}<br />", TopLevel))
                    End If

                    If (Not String.IsNullOrEmpty(SecondLevel)) Then
                        summaryString.Append(String.Format("<b>2nd Level:</b> {0}<br />", SecondLevel))
                    End If

                    If (Not String.IsNullOrEmpty(ThirdLevel)) Then
                        summaryString.Append(String.Format("<b>3rd Level:</b> {0}<br />", ThirdLevel))
                    End If
                End If

                Return summaryString.ToString
            End Get
        End Property

        Public Property AffectsUnits() As List(Of Integer) Implements IQRARequest.AffectsUnits
            Get
                Return _affectsUnits
            End Get
            Set(ByVal value As List(Of Integer))
                _affectsUnits = value
            End Set
        End Property

        Public ReadOnly Property FACompleteInTRS() As Boolean Implements IQRARequest.FACompleteInTRS
            Get
                Select Case Me.RequestStatus.ToLower
                    Case "closed", "cancelled"
                        Return True
                End Select
                Return False
            End Get
        End Property

        Public ReadOnly Property ActionTaken() As String Implements IQRARequest.ActionTaken
            Get
                Return GetProperty("ActionTaken")
            End Get
        End Property

        Public ReadOnly Property QRANumberRelatedTo() As String Implements IQRARequest.QRANumberRelatedTo
            Get
                Return GetProperty("QRANumberRelatedTo")
            End Get
        End Property

        Public ReadOnly Property TestType() As String Implements IQRARequest.TestType
            Get
                Return GetProperty("TestType")
            End Get
        End Property

        Public ReadOnly Property TestStage() As String Implements IQRARequest.TestStage
            Get
                Return GetProperty("TestStage")
            End Get
        End Property
        Public ReadOnly Property FailureDescription() As String Implements IQRARequest.FailureDescription
            Get
                Return GetProperty("FailureDescription")
            End Get
        End Property
        Public ReadOnly Property TestObservations() As String Implements IQRARequest.TestObservations
            Get
                Return GetProperty("TestObservations")
            End Get
        End Property
        Public ReadOnly Property TriageGroup() As String Implements IQRARequest.TriageGroup
            Get
                Return GetProperty("TriageGroup")
            End Get
        End Property
        Public ReadOnly Property TriageScore() As String Implements IQRARequest.TriageScore
            Get
                Return GetProperty("TriageScore")
            End Get
        End Property
        Public ReadOnly Property RootCause() As String Implements IQRARequest.RootCause
            Get
                Return GetProperty("RootCause")
            End Get
        End Property
        Public ReadOnly Property TopLevel() As String Implements IQRARequest.TopLevel
            Get
                Return GetProperty("TopLevel")
            End Get
        End Property
        Public ReadOnly Property SecondLevel() As String Implements IQRARequest.SecondLevel
            Get
                Return GetProperty("SecondLevel")
            End Get
        End Property
        Public ReadOnly Property ThirdLevel() As String Implements IQRARequest.ThirdLevel
            Get
                Return GetProperty("ThirdLevel")
            End Get
        End Property
        Public ReadOnly Property QRAPriority() As String Implements IQRARequest.QRAPriority
            Get
                Return GetProperty("QRA Priority")
            End Get
        End Property
#End Region

#End Region

#Region "Private Functions"
        Protected Function GetProperty(ByVal name As String) As String
            Dim returnVal As String = String.Empty
            Dim extField As String = String.Empty

            If FieldMapping.ContainsKey(name) Then
                FieldMapping.TryGetValue(name, extField)
            End If

            If RequestProperties.ContainsKey(extField) Then
                RequestProperties.TryGetValue(extField, returnVal)
            End If

            Return returnVal
        End Function

        Public Function GetSamAccountNameFromFullName(ByVal fullname As String) As String
            Dim retStr As String = String.Empty
            Using de As System.DirectoryServices.DirectoryEntry = New System.DirectoryServices.DirectoryEntry(REMIConfiguration.ADConnectionString, REMIConfiguration.REMIAccountName, REMIConfiguration.REMIAccountPassword)
                Using deSearch As System.DirectoryServices.DirectorySearcher = New System.DirectoryServices.DirectorySearcher()
                    deSearch.SearchRoot = de
                    deSearch.Filter = "displayName=" + fullname
                    Dim adUser As System.DirectoryServices.SearchResult = deSearch.FindOne
                    If adUser IsNot Nothing Then
                        Dim propertySearchResults As System.DirectoryServices.ResultPropertyValueCollection = adUser.Properties("sAMAccountName")
                        If propertySearchResults IsNot Nothing AndAlso propertySearchResults.Count > 0 Then
                            retStr = propertySearchResults(0).ToString
                        End If
                    End If
                End Using
            End Using
            Return retStr
        End Function
#End Region

    End Class
End Namespace