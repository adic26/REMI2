Imports REMI.Dal
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports System.Web
Imports System.Transactions
Imports REMI.Contracts

Namespace REMI.Bll
    Public Class ScanManager
        Inherits REMIManagerBase

        Public Shared Function Scan(ByVal QRANumber As String, ByVal resultSource As TestResultSource, Optional ByVal testStageName As String = "", Optional ByVal testName As String = "", Optional ByVal ResultString As String = "", Optional ByVal locationIdentification As String = "", Optional ByVal trackingLocationname As String = "", Optional ByVal binType As String = "SMALL-REM2", Optional ByVal jobName As String = "", Optional ByVal productGroup As String = "") As ScanReturnData
            Dim ReturnData As New ScanReturnData(QRANumber)
            Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
            Dim scanData As FastScanData

            If (barcode.BatchNumber.Contains("XX-TEST")) Then
                Dim instance = New REMI.Dal.Entities().Instance()
                scanData = New FastScanData
                scanData.ApplicableTests = Nothing
                scanData.ApplicableTestStages = Nothing
                scanData.JobName = jobName
                scanData.ScanSuccess = True
                scanData.SelectedTestName = testName
                scanData.SelectedTestStage = testStageName
                scanData.Barcode = barcode
                scanData.ProductGroupName = productGroup

                If Not String.IsNullOrEmpty(productGroup) Then
                    scanData.ProductID = (From l In instance.Lookups Where l.Values = productGroup Select l.LookupID).FirstOrDefault()
                End If

                scanData.SelectedTrackingLocationName = trackingLocationname

                If Not String.IsNullOrEmpty(trackingLocationname) Then
                    scanData.SelectedTrackingLocationID = (From t In instance.TrackingLocations Where t.TrackingLocationName = trackingLocationname Select t.ID).FirstOrDefault()
                End If

                scanData.TestID = (From t In instance.Tests Where t.TestName = testName And t.IsArchived = False Select t.ID).FirstOrDefault()

                scanData.SetReturnDataValues(ReturnData)
            Else
                If barcode.Validate Then
                    Dim reqStatus As String = String.Empty

                    Try
                        reqStatus = (From rf In RequestDB.GetRequest(barcode.BatchNumber, UserManager.GetCurrentUser, Nothing) Where rf.IntField = "RequestStatus" Select rf.Value).FirstOrDefault()
                    Catch
                    End Try

                    'set up the Scan Data with all of the objects we need from the database
                    If String.IsNullOrEmpty(locationIdentification) Then
                        scanData = TestUnitDB.GetFastScanData(barcode, REMI.Core.REMIHttpContext.GetCurrentHostname, testStageName, testName, CStr(IIf(String.IsNullOrEmpty(trackingLocationname), String.Empty, trackingLocationname)))
                    Else
                        scanData = TestUnitDB.GetFastScanData(barcode, locationIdentification, testStageName, testName, trackingLocationname)
                    End If

                    If scanData IsNot Nothing Then
                        scanData.SetCurrentTestRecordStatus()
                        scanData.SetSelectedTestRecordStatus()
                        scanData.TRSStatus = reqStatus.ToLower()
                        scanData.CurrentUserName = UserManager.GetCurrentUser.UserName

                        'Check that we were able to get all of the objects we require and that they are all valid
                        If scanData.Validate() Then
                            'if they are then go ahead and process the scan
                            scanData.ScanSuccess = (TestUnitDB.SaveFastScanData(scanData, resultSource) = 0)

                            If scanData.ScanSuccess AndAlso scanData.SelectedTrackingLocationFunction = TrackingLocationFunction.REMSTAR Then
                                scanData.Notifications.Add(ScanUnitForRemstarThroughREMI(scanData.Barcode.BatchNumber, scanData.Barcode.UnitNumber, scanData.BatchStatus = BatchStatus.Complete, scanData.CurrentUserName, binType))
                            End If
                        End If

                        ReturnData.BatchData = BatchManager.GetBatchView(QRANumber, True, False, True, False, True, False, True, True, False, False)
                        scanData.SetReturnDataValues(ReturnData)
                    Else
                        ReturnData.Notifications.AddWithMessage("This batch or unit could not be found.", NotificationType.Errors)
                    End If
                Else
                    ReturnData.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e15", NotificationType.Errors, "Request: " + QRANumber))
                    ReturnData.Notifications.Add(barcode.Notifications)
                End If
            End If

            If (REMI.Core.REMIConfiguration.Debug) Then
                EmailScanData(QRANumber, testStageName, testName, ResultString, UserManager.GetCurrentValidUserLDAPName(), UserManager.GetCurrentValidUserLDAPName(), ReturnData, trackingLocationname)
            End If

            Return ReturnData
        End Function

        Private Shared Sub EmailScanData(ByVal qraNumber As String, ByVal testStageName As String, ByVal testName As String, ByVal overallTestResult As String, _
                                    ByVal userIdentification As String, ByVal userName As String, ByVal returnData As ScanReturnData, ByVal trackingLocationname As String)
            Dim str As New System.Text.StringBuilder
            str.Append(String.Format("RequestNumber: {0}", qraNumber))
            str.Append(Environment.NewLine)
            str.Append(String.Format("testStageName: {0}", testStageName))
            str.Append(Environment.NewLine)
            str.Append(String.Format("testName: {0}", testName))
            str.Append(Environment.NewLine)
            str.Append(String.Format("overallTestResult: {0}", overallTestResult))
            str.Append(Environment.NewLine)
            str.Append(String.Format("userIdentification: {0}", userIdentification))
            str.Append(Environment.NewLine)
            str.Append(String.Format("host: {0}", REMI.Core.REMIHttpContext.GetCurrentHostname))
            str.Append(Environment.NewLine)
            str.Append(Environment.NewLine)
            str.Append("RETURN DATA")
            str.Append(Environment.NewLine)
            str.Append(Environment.NewLine)
            str.Append("applicable tests: ")
            If returnData.ApplicableTests IsNot Nothing Then
                str.Append(String.Join(", ", returnData.ApplicableTests))
            End If
            str.Append(Environment.NewLine)
            str.Append("applicable test stages: ")
            If returnData.ApplicableTestStages IsNot Nothing Then
                str.Append(String.Join(",", returnData.ApplicableTestStages))
            End If
            str.Append(Environment.NewLine)
            str.Append(String.Format("BSN: {0}", returnData.BSN))
            str.Append(Environment.NewLine)
            str.Append(String.Format("Direction: {0}", returnData.Direction.ToString))
            str.Append(Environment.NewLine)
            str.Append(String.Format("Jobname: {0}", returnData.JobName))
            str.Append(Environment.NewLine)
            str.Append(String.Format("Jobwilink: {0}", returnData.JobWILink))
            str.Append(Environment.NewLine)
            str.Append(String.Format("Notifications: {0}", returnData.Notifications.ToString))
            str.Append(Environment.NewLine)
            str.Append(String.Format("PG: {0}", returnData.ProductGroup))
            str.Append(Environment.NewLine)
            str.Append(String.Format("Request: {0}", returnData.QRANumber))
            str.Append(Environment.NewLine)
            str.Append(String.Format("success: {0}", returnData.ScanSuccess))
            str.Append(Environment.NewLine)
            str.Append(String.Format("sel test: {0}", returnData.SelectedTestName))
            str.Append(Environment.NewLine)
            str.Append(String.Format("sel test stage: {0}", returnData.TestStageName))
            str.Append(Environment.NewLine)
            str.Append(String.Format("test wi: {0}", returnData.TestWILink))
            str.Append(Environment.NewLine)
            str.Append(String.Format("tracking loc manual: {0}", returnData.TrackingLocationManualLocation))
            str.Append(Environment.NewLine)
            str.Append(String.Format("tracking loc Name: {0}", returnData.TrackingLocationName))
            str.Append(Environment.NewLine)
            str.Append(String.Format("unit num: {0}", returnData.UnitNumber))
            str.Append(Environment.NewLine)
            str.Append(String.Format("Environment"))
            str.Append(Environment.NewLine)
            str.Append(Environment.NewLine)
            str.Append(String.Format("currentusername: {0}", userName))
            str.Append(Environment.NewLine)
            str.Append(Environment.NewLine)
            str.AppendLine(String.Format("Passed-in trackingLocationname: {0}", trackingLocationname))
            REMI.Core.Emailer.SendErrorEMail("Scan Attempted", str.ToString, REMI.Validation.NotificationType.Information, Nothing)
        End Sub

        Public Shared Function ScanUnitForRemstarThroughREMI(ByVal batchQRANumber As String, ByVal UnitNumber As Integer, ByVal IsCompleteInTRS As Boolean, ByVal userName As String, ByVal binType As String) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                If RemstarDB.ScanDevice(batchQRANumber, UnitNumber, userName, ScanDirection.Inward, binType) > 0 Then
                    nc.AddWithMessage(String.Format("{0}-{1:d3}{2}", batchQRANumber, UnitNumber, " added to put order. Please wait up to 15 seconds for the order to appear in remstar."), NotificationType.Information)
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e15", NotificationType.Errors, String.Format("{0}-{1:d3}", batchQRANumber, UnitNumber)))
            End Try
            Return nc
        End Function
    End Class
End Namespace
