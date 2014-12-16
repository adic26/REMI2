Imports System.Configuration
Namespace REMI.Core
    ''' <summary>
    ''' This class contains the various configuration settings for the application
    ''' </summary>
    ''' <remarks></remarks>
    Public Class REMIConfiguration
        Public Shared ReadOnly Property SmtpAddress() As String
            Get
                Return "smtp-ca.rim.net"
            End Get
        End Property

        Public Shared ReadOnly Property DefaultUrlScheme() As String
            Get
                Return "http"
            End Get
        End Property

        Public Shared ReadOnly Property DefaultRemstarLocationName() As String
            Get
                Return "remstar 1"
            End Get
        End Property
        Public Shared ReadOnly Property REMIAccountPassword() As String
            Get
                Return ConfigurationManager.AppSettings("REMIAccountPassword")
            End Get
        End Property
        Public Shared ReadOnly Property REMIAccountName() As String
            Get
                Return ConfigurationManager.AppSettings("REMIAccountName")
            End Get
        End Property
        Public Shared ReadOnly Property ADConnectionString() As String
            Get
                Return ConfigurationManager.AppSettings("ADConnectionString")
            End Get
        End Property
        Public Shared ReadOnly Property DefaultRedirectPage() As String
            Get
                Return ConfigurationManager.AppSettings("DefaultRedirectPage")
            End Get
        End Property
        Public Shared ReadOnly Property DefaultRequestNumber() As String
            Get
                Return ConfigurationManager.AppSettings("DefaultRequestNumber")
            End Get
        End Property
        Public Shared ReadOnly Property TRSLinkCreationString() As String
            Get
                Return ConfigurationManager.AppSettings("TRSLinkCreationString")
            End Get
        End Property
        Public Shared ReadOnly Property REMITestRecordsLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiTestRecordsLink")
            End Get
        End Property
        Public Shared ReadOnly Property REMITestRecordsAddLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiTestRecordsAddLink")
            End Get
        End Property
        Public Shared ReadOnly Property BaseTRSLink() As String
            Get
                Return ConfigurationManager.AppSettings("BaseTRSLink")
            End Get
        End Property
        Public Shared ReadOnly Property MfgWebLink() As String
            Get
                Return ConfigurationManager.AppSettings("MfgWebLink")
            End Get
        End Property
        Public Shared ReadOnly Property ConnectionStringReq(ByVal connectName As String) As String
            Get
                Return ConfigurationManager.ConnectionStrings(connectName).ConnectionString
            End Get
        End Property

        Public Shared ReadOnly Property ConnectionStringREMI() As String
            Get
                Return ConfigurationManager.ConnectionStrings("REMIDBConnectionString").ConnectionString
            End Get
        End Property

        Public Shared ReadOnly Property ConnectionStringREMIEntity() As String
            Get
                Return ConfigurationManager.ConnectionStrings("REMIEntities").ConnectionString
            End Get
        End Property
        Public Shared ReadOnly Property ConnectionStringREMSTAR() As String
            Get
                Return ConfigurationManager.ConnectionStrings("REMSTARDBConnectionString").ConnectionString
            End Get
        End Property
       
        Public Shared ReadOnly Property REMIBatchInfoLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiBatchInfoLink")
            End Get
        End Property
        Public Shared ReadOnly Property REMIBatchCommentsEditLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetBatchCommentsLink")
            End Get
        End Property
        
        Public Shared ReadOnly Property REMIProductGroupLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiProductGroupLink")
            End Get
        End Property

        Public Shared ReadOnly Property REMIJobLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiJobLink")
            End Get
        End Property

        Public Shared ReadOnly Property REMIUnitInfoLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiUnitInfoLink")
            End Get
        End Property

        Public Shared ReadOnly Property RemiExceptionsLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiExceptionsLink")
            End Get
        End Property

        Public Shared ReadOnly Property RemiSetBatchStatusLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetBatchStatusLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiSetTestUnitExceptionsLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetTestUnitExceptionsLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiSetProductSettingsLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetProductSettingsLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiSetProductConfigLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetProductConfigLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiSetStationConfigLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetStationConfigLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiSetProductExceptionsLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetProductExceptionsLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiTestRecordsDetailLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiTestRecordsEditDetailLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiSetBatchPriorityLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetBatchPriorityLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiUserScanBadgeLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiUserScanBadgeLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiSetBatchTestStageLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetBatchTestStageLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiSetBatchSpecificTestDurationLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiSetBatchSpecificTestDurationsLink")
            End Get
        End Property
        Public Shared ReadOnly Property REMIScannerProgrammingLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiScannerProgrammingLink")
            End Get
        End Property
        Public Shared ReadOnly Property RemiTrackingLocationInfoLink() As String
            Get
                Return ConfigurationManager.AppSettings("RemiTrackingLocationInfoLink")
            End Get
        End Property
        Public Shared ReadOnly Property Debug() As Boolean
            Get
                Dim debugRemi As Boolean
                Boolean.TryParse(ConfigurationManager.AppSettings("Debug").ToString(), debugRemi)

                Return debugRemi
            End Get
        End Property
        Public Shared ReadOnly Property EnableFA100Message() As Boolean
            Get
                Dim enableFA100 As Boolean
                Boolean.TryParse(ConfigurationManager.AppSettings("EnableFA100Message").ToString(), enableFA100)

                Return enableFA100
            End Get
        End Property
    End Class
End Namespace