Imports System.Web
Imports System.Net

Namespace REMI.Core
    Public Class REMIWebLinks

        ''' <summary>
        ''' Returns the name of the "username" to associate with the application itself updating records.
        ''' For example when a test result is added automatically the this is the username that gets associated with
        ''' that result.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetREMIUserName() As String
            Return "RIMNET\remi"
        End Function

        Public Shared Function GetCurrentHostName() As String
            Return System.Net.Dns.GetHostName()
        End Function

        ''' <summary>
        ''' Used to be a custom hostname function that cycled through the old hostname records in the rimnet dns system
        ''' </summary>
        ''' <param name="IPAddress"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function ResolveHostName(ByVal IPAddress As String) As String
            Dim hostName As String = String.Empty
            Dim hostNamesRealIP As String

            Try
                Dim tries As Integer = 1
                For i As Integer = 1 To tries
                    'get host split on . and take the first part (xxxxx.rim.net -> xxxxx)
                    hostName = System.Net.Dns.GetHostEntry(IPAddress).HostName.Split("."c)(0).ToLower

                    'get the ip for the first returned hostname
                    hostNamesRealIP = System.Net.Dns.GetHostEntry(IIf(IPAddress = "::1", "localhost", hostName)).AddressList(0).ToString
                    'check if it matches
                    If Not IPAddress.Equals(hostNamesRealIP) Then
                        'if not get the next one
                        hostName = String.Empty
                    Else
                        Exit For
                    End If
                Next
            Catch exe As Exception
                hostName = String.Empty
            End Try

            Return hostName
        End Function

#Region "REMI Page Links"
        Public Shared Function GetMfgWebLink(ByVal BSN As String) As String
            Return REMIConfiguration.MfgWebLink + BSN
        End Function
        Public Shared Function GetRelabResultLink(ByVal batchID As Integer) As String
            Return String.Format("/Relab/Results.aspx?Batch={0}", batchID)
        End Function
        Public Shared Function GetProductInfoLink(ByVal productID As Int32) As String
            Return String.Format("/{0}?Name={1}", REMIConfiguration.REMIProductGroupLink, productID.ToString())
        End Function
        Public Shared Function GetJobLink(ByVal jobID As Int32) As String
            Return String.Format("/{0}?JobID={1}", REMIConfiguration.REMIJobLink, jobID.ToString())
        End Function
        Public Shared Function GetBatchInfoLink(ByVal QRANumber As String) As String
            Return String.Format("/{0}?RN={1}", REMIConfiguration.REMIBatchInfoLink, QRANumber)
        End Function
        Public Shared Function GetEditExceptionsLink(ByVal QRANumber As String) As String
            Return String.Format("/{0}?RN={1}", REMIConfiguration.RemiExceptionsLink, QRANumber)
        End Function
        Public Shared Function GetTestRecordsAddLink(ByVal QRANumber As String) As String
            Return String.Format("/{0}?RN={1}", REMIConfiguration.REMITestRecordsAddLink, QRANumber)
        End Function
        Public Shared Function GetSetBatchStatusLink(ByVal QRANumber As String) As String
            Return String.Format("/{0}?RN={1}", REMIConfiguration.RemiSetBatchStatusLink, QRANumber)
        End Function
        Public Shared Function GetSetBatchTestStageLink(ByVal QRANumber As String) As String
            Return String.Format("/{0}?RN={1}", REMIConfiguration.RemiSetBatchTestStageLink, QRANumber)
        End Function
        Public Shared Function GetSetBatchSpecificTestDurationsLink(ByVal QRANumber As String) As String
            Return String.Format("/{0}?RN={1}", REMIConfiguration.RemiSetBatchSpecificTestDurationLink, QRANumber)
        End Function
        Public Shared Function GetSetBatchPriorityLink(ByVal QRANumber As String) As String
            Return String.Format("/{0}?RN={1}", REMIConfiguration.RemiSetBatchPriorityLink, QRANumber)
        End Function
        Public Shared Function GetTestRecordsEditDetailLink(ByVal trId As Integer) As String
            Return String.Format("/{0}?trID={1}", REMIConfiguration.RemiTestRecordsDetailLink, trId.ToString)
        End Function
        Public Shared Function GetTestUnitExceptionsLink(ByVal QRANumber As String) As String
            Return String.Format("/{0}?RN={1}", REMIConfiguration.RemiSetTestUnitExceptionsLink, QRANumber)
        End Function
        Public Shared Function GetSetProductSettingsLink(ByVal productID As Int32) As String
            Return String.Format("/{0}?product={1}", REMIConfiguration.RemiSetProductSettingsLink, productID.ToString())
        End Function
        Public Shared Function GetSetProductConfigurationLink(ByVal productID As Int32) As String
            Return String.Format("/{0}?product={1}", REMIConfiguration.RemiSetProductConfigLink, productID.ToString())
        End Function
        Public Shared Function GetSetStationConfigurationLink(ByVal trackingLocationID As Int32) As String
            Return String.Format("/{0}?BarcodeSuffix={1}", REMIConfiguration.RemiSetStationConfigLink, trackingLocationID.ToString())
        End Function
        Public Shared Function GetUnitInfoLink(ByVal QRANumber As String) As String
            Return String.Format("/{0}?RN={1}", REMIConfiguration.REMIUnitInfoLink, QRANumber)
        End Function
        Public Shared Function GetScannerProgrammingLink(ByVal TrackingLocationID As Integer) As String
            Return String.Format("/{0}?ID={1}", REMIConfiguration.REMIScannerProgrammingLink, TrackingLocationID.ToString)
        End Function
        Public Shared Function GetTrackingLocationInfoLink(ByVal barcodeSuffix As String) As String
            Return String.Format("/{0}?BarcodeSuffix={1}", REMIConfiguration.RemiTrackingLocationInfoLink, barcodeSuffix)
        End Function
        Public Shared Function GetUserBadgeScanLink(ByVal redirectPage As String) As String
            Return String.Format("/{0}?redirectPage={1}", REMIConfiguration.RemiUserScanBadgeLink, redirectPage)
        End Function
        Public Shared Function GetExecutiveSummaryLink(ByVal requestNumber As String) As String
            Return String.Format("/Reports/ES/Default.aspx?RN={0}", requestNumber)
        End Function
        Public Shared Function GetTestRecordsLink(ByVal qraNumber As String, ByVal testName As String, ByVal testStageName As String, ByVal jobName As String, ByVal testUnitID As Int32) As String
            Dim str As New Text.StringBuilder
            str.Append(String.Format("/{0}", REMIConfiguration.REMITestRecordsLink))
            str.Append("?RN=")
            str.Append(qraNumber)
            If Not String.IsNullOrEmpty(testName) Then
                str.Append("&testname=")
                str.Append(testName)
            End If
            If Not String.IsNullOrEmpty(testStageName) Then
                str.Append("&testStageName=")
                str.Append(testStageName)
            End If
            If Not String.IsNullOrEmpty(jobName) Then
                str.Append("&jobName=")
                str.Append(jobName)
            End If
            If testUnitID > 0 Then
                str.Append("&testUnitID=")
                str.Append(testUnitID)
            End If
            Return str.ToString
        End Function
#End Region
    End Class
End Namespace