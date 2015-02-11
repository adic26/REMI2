Imports System.Web

Namespace REMI.Core
    Public Class REMIWebLinks

        Private Shared _applicationPath As String = REMIConfiguration.DefaultUrlScheme + "://" + IIf(System.Net.Dns.GetHostName().Contains("CI0000001593275") Or System.Net.Dns.GetHostName().Contains("CI0000003603796"), "localhost:81", System.Net.Dns.GetHostName()) + "/"
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

        Public Shared Function GetFailDocLink(ByVal reqid As Integer) As String
            If reqid > 0 Then
                Return String.Format("{0}{1}", REMIConfiguration.TRSLinkCreationString, reqid)
            Else
                Return "http://go/fa/"
            End If
        End Function
#Region "TRS Page Links"
        Public Shared Function GetMfgWebLink(ByVal BSN As String) As String
            Return REMIConfiguration.MfgWebLink + BSN
        End Function
        'Public Shared Function GetRelabResultLink2(ByVal RelabResultJobID As Integer) As String
        'Return REMIConfiguration.RelabResultLink + String.Format("?jobid={0}&stages=1&ordered=TEST&ad=a", RelabResultJobID)
        'End Function
        Public Shared Function GetRelabResultLink(ByVal batchID As Integer) As String
            Return String.Format("/Relab/Results.aspx?Batch={0}", batchID)
        End Function
#End Region
#Region "REMI Page Links"
        Public Shared Function GetProductInfoLink(ByVal productID As Int32) As String
            Return _applicationPath + REMIConfiguration.REMIProductGroupLink + "?Name=" + productID.ToString()
        End Function
        Public Shared Function GetJobLink(ByVal jobID As Int32) As String
            Return _applicationPath + REMIConfiguration.REMIJobLink + "?JobID=" + JobID.ToString()
        End Function
        Public Shared Function GetBatchInfoLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.REMIBatchInfoLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetEditExceptionsLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.RemiExceptionsLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetTestRecordsAddLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.REMITestRecordsAddLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetBatchSchedulingLink(ByVal qraNumber As String) As String
            Return _applicationPath + "ManageBatches/ViewTestStageSchedule.aspx?RN=" + qraNumber
        End Function
        Public Shared Function GetSetBatchStatusLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.RemiSetBatchStatusLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetSetBatchCommentsLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.REMIBatchCommentsEditLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetSetBatchTestStageLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.RemiSetBatchTestStageLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetSetBatchSpecificTestDurationsLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.RemiSetBatchSpecificTestDurationLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetSetBatchPriorityLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.RemiSetBatchPriorityLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetTestRecordsEditDetailLink(ByVal trId As Integer) As String
            Return _applicationPath + REMIConfiguration.RemiTestRecordsDetailLink + "?trID=" + trId.ToString
        End Function
        Public Shared Function GetTestUnitExceptionsLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.RemiSetTestUnitExceptionsLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetSetProductExceptionsLink(ByVal productID As Int32) As String
            Return _applicationPath + REMIConfiguration.RemiSetProductExceptionsLink + "?product=" + productID.ToString()
        End Function
        Public Shared Function GetSetProductSettingsLink(ByVal productID As Int32) As String
            Return _applicationPath + REMIConfiguration.RemiSetProductSettingsLink + "?product=" + productID.ToString()
        End Function
        Public Shared Function GetSetProductConfigurationLink(ByVal productID As Int32) As String
            Return _applicationPath + REMIConfiguration.RemiSetProductConfigLink + "?product=" + productID.ToString()
        End Function
        Public Shared Function GetSetStationConfigurationLink(ByVal trackingLocationID As Int32) As String
            Return _applicationPath + REMIConfiguration.RemiSetStationConfigLink + "?BarcodeSuffix=" + trackingLocationID.ToString()
        End Function
        Public Shared Function GetUnitInfoLink(ByVal QRANumber As String) As String
            Return _applicationPath + REMIConfiguration.REMIUnitInfoLink + "?RN=" + QRANumber
        End Function
        Public Shared Function GetScannerProgrammingLink(ByVal TrackingLocationID As Integer) As String
            Return _applicationPath + REMIConfiguration.REMIScannerProgrammingLink + "?ID=" + TrackingLocationID.ToString
        End Function
        Public Shared Function GetTrackingLocationInfoLink(ByVal barcodeSuffix As String) As String
            Return _applicationPath + REMIConfiguration.RemiTrackingLocationInfoLink + "?BarcodeSuffix=" + barcodeSuffix
        End Function
        Public Shared Function GetUserBadgeScanLink(ByVal redirectPage As String) As String
            Return _applicationPath + REMIConfiguration.RemiUserScanBadgeLink + "?redirectPage=" + redirectPage
        End Function
        Public Shared Function GetTestRecordsLink(ByVal qraNumber As String, ByVal testName As String, ByVal testStageName As String, ByVal jobName As String, ByVal testUnitID As Int32) As String
            Dim str As New Text.StringBuilder
            str.Append(_applicationPath)
            str.Append(REMIConfiguration.REMITestRecordsLink)
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
