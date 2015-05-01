Imports REMI.Dal
Imports REMI.BusinessEntities
Imports System.ComponentModel
Imports REMI.Validation
Imports REMI.Contracts
Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class TestRecordManager
        Inherits REMIManagerBase

        Public Shared Function Delete(ByVal id As Int32) As NotificationCollection
            Dim nc As New NotificationCollection

            Try
                If (UserManager.GetCurrentUser.IsDeveloper) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim record As IQueryable(Of REMI.Entities.TestRecord)
                    record = (From tr In instance.TestRecords Where tr.ID = id Select tr)

                    If (record.FirstOrDefault() IsNot Nothing) Then 'Record exists
                        Dim recordTracking = (From trt In instance.TestRecordsXTrackingLogs Where trt.TestRecord.ID = id Select trt).ToList()

                        For Each rec In recordTracking
                            instance.DeleteObject(rec)
                        Next

                        instance.DeleteObject(record.FirstOrDefault())
                        instance.SaveChanges()

                        nc.AddWithMessage("Successfully Deleted Test Record", NotificationType.Information)
                    End If
                Else
                    nc.AddWithMessage("You do not have the accses to delete test records", NotificationType.Warning)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex)
            End Try

            Return nc
        End Function

        Public Shared Function Save(ByVal testRecord As TestRecord) As Integer
            Dim returnVal As Integer

            Try
                'check if it is valid and save
                testRecord.LastUser = UserManager.GetCurrentValidUserLDAPName
                If testRecord.Validate Then
                    returnVal = TestRecordDB.Save(testRecord)

                    If returnVal > 0 Then
                        testRecord.Notifications.AddWithMessage("Saved OK.", NotificationType.Information)
                        testRecord = GetItemByID(returnVal)
                        InsertRelabRecord(testRecord)
                    Else
                        testRecord.Notifications.AddWithMessage("Didn't Save Successfully. It's possible someone else saved it while you saved.", NotificationType.Errors)
                    End If
                End If
            Catch ex As Exception
                testRecord.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("TestRecord: {0}", testRecord.ID)))
            End Try

            Return returnVal
        End Function

        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetItemByID(ByVal ID As Integer) As TestRecord
            Try
                Return TestRecordDB.GetItemByID(ID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestRecord: {0}", ID))
            End Try
            Return Nothing
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTestRecordAuditLogs(ByVal TestRecordID As Int32) As DataTable
            Try
                Dim dtTRA As DataTable = BusinessEntities.Helpers.EQToDataTable((From tra In New REMI.Dal.Entities().Instance().vw_TestRecordAudit Where tra.TestRecordID = TestRecordID Select tra).ToList, "TestRecordAudit")
                Return dtTRA
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, TestRecordID.ToString())
            End Try
            Return New DataTable("TestRecordAudit")
        End Function

        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetFailDocs(ByVal qranumber As String, ByVal trID As Int32) As List(Of Dictionary(Of String, String))
            Dim trsDocList As New List(Of Dictionary(Of String, String))

            Try
                Dim docNumbers As List(Of String) = New List(Of String)
                Dim tr As TestRecord = TestRecordManager.GetItemByID(trID)

                If Not String.IsNullOrEmpty(qranumber) Then
                    Dim t As RequestFieldsCollection = RequestDB.GetRequest(qranumber, UserManager.GetCurrentUser)
                    docNumbers.AddRange(RequestDB.GetFANumberList(qranumber))

                    If docNumbers IsNot Nothing Then
                        Dim req As Dictionary(Of String, String)

                        For Each trsDocNumber In docNumbers
                            req = RequestDB.GetExternalRequestNotLinked(trsDocNumber, "Oracle")

                            Dim faList As List(Of String) = (From f In tr.FailDocs Select f.Item("RequestNumber")).ToList()

                            If (Not faList.Contains(req.Item("RequestNumber"))) Then
                                trsDocList.Add(req)
                            End If
                        Next
                    End If
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return trsDocList
        End Function

        Public Shared Function AddCaterDocument(ByVal trID As Integer, ByVal documentNumber As String, ByVal comments As String, ByVal updateSimilarTestRecords As Boolean) As NotificationCollection
            Dim returnNotes As NotificationCollection = New NotificationCollection
            Dim trColl As New TestRecordCollection

            Try
                Dim tr As TestRecord = GetItemByID(trID)

                If updateSimilarTestRecords Then
                    Dim b As Batch = BatchManager.GetItem(tr.QRANumber)
                    trColl.Add((From testRec In b.TestRecords Where testRec.JobName.Equals(tr.JobName) AndAlso _
                                                         testRec.TestStageName.Equals(tr.TestStageName) AndAlso testRec.TestName.Equals(tr.TestName) AndAlso testRec.Status.Equals(tr.Status) Select testRec).ToList)
                Else
                    trColl.Add(tr)
                End If

                For Each testRec As TestRecord In trColl
                    returnNotes.Add(AddCaterDocumentSingleTestRecord(testRec, documentNumber, comments))
                Next
            Catch ex As Exception
                returnNotes.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, "Docuemnt Number: " + documentNumber))
            End Try

            Return returnNotes
        End Function

        Public Shared Function RemoveCaterDocument(ByVal trID As Integer, ByVal documentNumber As String, ByVal comments As String, ByVal updateSimilarTestRecords As Boolean) As NotificationCollection
            Dim returnNotes As NotificationCollection = New NotificationCollection
            Dim trColl As New TestRecordCollection

            Try
                Dim tr As TestRecord = GetItemByID(trID)

                If updateSimilarTestRecords Then
                    Dim b As Batch = BatchManager.GetItem(tr.QRANumber)
                    trColl.Add((From testRec In b.TestRecords Where testRec.JobName.Equals(tr.JobName) AndAlso _
                                                         testRec.TestStageName.Equals(tr.TestStageName) AndAlso testRec.TestName.Equals(tr.TestName) AndAlso testRec.Status.Equals(tr.Status) Select testRec).ToList)
                Else
                    trColl.Add(tr)
                End If

                For Each testRec As TestRecord In trColl
                    returnNotes.Add(RemoveCaterDocumentSingleTestRecord(testRec, documentNumber, comments))
                Next
            Catch ex As Exception
                returnNotes.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex, String.Format("Docuemnt Number: {0}", documentNumber)))
            End Try
            Return returnNotes
        End Function

        Public Shared Function InsertRelabRecordMeasurement(ByVal testID As Int32, ByVal testStageID As Int32, ByVal testUnitID As Int32, ByVal lookupID As Int32, ByVal passFail As Boolean, ByVal isFunctional As Boolean) As Boolean
            Try
                If (isFunctional) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim result As IQueryable(Of REMI.Entities.Result)
                    result = (From r In instance.Results Where r.TestUnit.ID = testUnitID And r.Test.ID = testID And r.TestStage.ID = testStageID Select r)

                    If (result.FirstOrDefault() IsNot Nothing) Then 'Record exists
                        Dim record = (From r In instance.Results Where r.TestUnit.ID = testUnitID And r.Test.ID = testID And r.TestStage.ID = testStageID Select r).FirstOrDefault()
                        record.PassFail = passFail

                        Dim resultmeasurement As IQueryable(Of REMI.Entities.ResultsMeasurement)
                        resultmeasurement = (From rm In instance.ResultsMeasurements Where rm.Result.ID = result.FirstOrDefault().ID And rm.Lookup.LookupID = lookupID Select rm)

                        If (resultmeasurement.FirstOrDefault() IsNot Nothing) Then
                            Dim recordMeasurement = (From rm In instance.ResultsMeasurements Where rm.Result.ID = result.FirstOrDefault().ID And rm.Lookup.LookupID = lookupID Select rm).FirstOrDefault()
                            record.PassFail = passFail
                        Else
                            Dim lookup As IQueryable(Of REMI.Entities.Lookup)
                            lookup = (From l In instance.Lookups Where l.LookupID = lookupID Select l)

                            Dim rm As New REMI.Entities.ResultsMeasurement()
                            rm.PassFail = passFail
                            rm.Lookup = lookup.FirstOrDefault()
                            rm.Archived = False
                            rm.LowerLimit = "N/A"
                            rm.UpperLimit = "N/A"
                            rm.MeasurementValue = passFail.ToString()
                            rm.ReTestNum = 1
                            rm.Result = result.FirstOrDefault()

                            instance.AddToResultsMeasurements(rm)
                        End If

                        instance.SaveChanges()
                    End If
                End If

                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
                Return False
            End Try
        End Function

        Public Shared Function InsertRelabRecord(ByVal tr As TestRecord) As Boolean
            Try
                'Only insert Relab record for non test systems (IE: MFI Functional, SFI Functional, Visual Inspection)
                If ((tr.TestID = 1073 Or tr.FunctionalType <> 0) And tr.TestStageID > 0) Then
                    If (tr.Status = TestRecordStatus.Complete Or tr.Status = TestRecordStatus.CompleteFail Or tr.Status = TestRecordStatus.CompleteKnownFailure Or tr.Status = TestRecordStatus.FARaised Or tr.Status = TestRecordStatus.FARequired) Then
                        Dim instance = New REMI.Dal.Entities().Instance()
                        Dim result As IQueryable(Of REMI.Entities.Result)
                        result = (From r In instance.Results Where r.TestUnit.ID = tr.TestUnitID And r.Test.ID = tr.TestID And r.TestStage.ID = tr.TestStageID Select r)

                        If (result.FirstOrDefault() Is Nothing) Then 'Record doesn't exist so create it
                            Dim r As New REMI.Entities.Result()
                            r.Test = (From t In instance.Tests Where t.ID = tr.TestID Select t).FirstOrDefault()
                            r.TestStage = (From ts In instance.TestStages Where ts.ID = tr.TestStageID Select ts).FirstOrDefault()
                            r.TestUnit = (From u In instance.TestUnits Where u.ID = tr.TestUnitID Select u).FirstOrDefault()

                            If (tr.Status = TestRecordStatus.Complete) Then
                                r.PassFail = True
                            ElseIf (tr.Status = TestRecordStatus.CompleteFail) Then
                                r.PassFail = False
                            ElseIf (tr.Status = TestRecordStatus.CompleteKnownFailure) Then
                                r.PassFail = False
                            ElseIf (tr.Status = TestRecordStatus.FARaised) Then
                                r.PassFail = False
                            ElseIf (tr.Status = TestRecordStatus.FARequired) Then
                                r.PassFail = False
                            End If

                            instance.AddToResults(r)
                        Else 'record exists but pass/fail was updated
                            Dim record = (From r In instance.Results Where r.TestUnit.ID = tr.TestUnitID And r.Test.ID = tr.TestID And r.TestStage.ID = tr.TestStageID Select r).FirstOrDefault()

                            If (tr.Status = TestRecordStatus.Complete) Then
                                record.PassFail = True
                            ElseIf (tr.Status = TestRecordStatus.CompleteFail) Then
                                record.PassFail = False
                            ElseIf (tr.Status = TestRecordStatus.CompleteKnownFailure) Then
                                record.PassFail = False
                            ElseIf (tr.Status = TestRecordStatus.FARaised) Then
                                record.PassFail = False
                            ElseIf (tr.Status = TestRecordStatus.FARequired) Then
                                record.PassFail = False
                            End If
                        End If

                        instance.SaveChanges()
                    End If
                End If
                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function UpdateStatus(ByVal trID As Integer, ByVal status As TestRecordStatus, ByVal comments As String, ByVal updateSimilarTestRecords As Boolean) As NotificationCollection
            Dim returnNotes As NotificationCollection = New NotificationCollection
            Dim trColl As New TestRecordCollection

            Try
                Dim tr As TestRecord = GetItemByID(trID)

                If updateSimilarTestRecords Then
                    Dim b As Batch = BatchManager.GetItem(tr.QRANumber)
                    trColl.Add((From testRec In b.TestRecords Where testRec.JobName.Equals(tr.JobName) AndAlso _
                                                         testRec.TestStageName.Equals(tr.TestStageName) AndAlso testRec.TestName.Equals(tr.TestName) AndAlso testRec.Status.Equals(tr.Status) Select testRec).ToList)
                Else
                    trColl.Add(tr)
                End If

                For Each testRec As TestRecord In trColl
                    returnNotes.Add(UpdateSingleTestRecordStatus(testRec, status, comments))
                Next
            Catch ex As Exception
                returnNotes.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("TestRecordID: {0} Status: {1}", trID, status.ToString())))
            End Try

            Return returnNotes
        End Function

        Public Shared Function DTATTAUpdateUnitTestStatus(ByVal qranumber As String, ByVal testStage As String, ByVal test As String, ByVal userIdentification As String, ByVal result As FinalTestResult) As Boolean
            Dim returnValue As Boolean

            Try
                Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(qranumber))

                If barcode.Validate() Then
                    Dim b As Batch = BatchManager.GetItem(barcode.BatchNumber)
                    Dim tu As TestUnit = b.TestUnits.FindByBatchUnitNumber(barcode.UnitNumber)

                    If b IsNot Nothing And tu IsNot Nothing Then
                        Dim testStageRecord As TestStage = TestStageManager.GetTestStage(testStage, b.JobName)

                        Dim processOrder As Int32 = 0

                        If (testStageRecord IsNot Nothing) Then
                            processOrder = testStageRecord.ProcessOrder
                        Else
                            For Each ts As TestStage In (From tsttsg In b.Job.TestStages Where tsttsg.IsArchived = False Select tsttsg Order By tsttsg.ProcessOrder)
                                If (ts.Name.Contains("Post ")) Then
                                    Dim tsNum As Int32 'Current test stage drop/tumble number
                                    Dim num As Int32 = 0 'Loop test stage drop/tumble number

                                    Int32.TryParse(testStage.Replace(" Drops", String.Empty).Replace(" Drop", String.Empty).Replace("Post ", String.Empty).ToString(), tsNum)  'Gets the current test stage drop/tumble number
                                    Int32.TryParse(ts.Name.Replace(" Drops", String.Empty).Replace(" Drop", String.Empty).Replace("Post ", String.Empty).ToString(), num)      'Gets the loop test stage drop/tumble number

                                    If (num > tsNum) Then ' If current drop/tumble number is 5 and the first drop/tumble number is 10 then set the processorder equal to this test stages processorder
                                        processOrder = ts.ProcessOrder
                                        Exit For
                                    End If
                                End If
                            Next
                        End If

                        Dim tr As TestRecord = b.TestRecords.FindByTestStageTest(b.JobName, testStage, test).FirstOrDefault()

                        If tr Is Nothing Then
                            If (testStageRecord Is Nothing) Then
                                tr = New TestRecord(b.QRANumber, tu.BatchUnitNumber, b.JobName, testStage, test, tu.ID, userIdentification, Nothing, Nothing)
                            Else
                                tr = New TestRecord(b.QRANumber, tu.BatchUnitNumber, b.JobName, testStage, test, tu.ID, userIdentification, Nothing, testStageRecord.ID)
                            End If
                        End If

                        If result = FinalTestResult.Fail Then
                            returnValue = TestRecordManager.UpdateSingleTestRecordStatus(tr, TestRecordStatus.CompleteFail, "Unit was removed from test at the DTATTA software").FirstOrDefault(Function(x) x.Type = NotificationType.Errors) Is Nothing
                        Else
                            returnValue = TestRecordManager.UpdateSingleTestRecordStatus(tr, TestRecordStatus.Complete, "Unit was added back to test at the DTATTA software").FirstOrDefault(Function(x) x.Type = NotificationType.Errors) Is Nothing
                        End If
                    End If
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return returnValue
        End Function

        Private Shared Function UpdateSingleTestRecordStatus(ByVal tr As TestRecord, ByVal status As TestRecordStatus, ByVal comments As String) As NotificationCollection
            Try
                Dim oldStatus As String

                If tr IsNot Nothing Then
                    'set the status
                    oldStatus = tr.Status.ToString
                    tr.SetStatus(status, comments, UserManager.GetCurrentValidUserLDAPName)

                    If Save(tr) > 0 Then
                        tr.Notifications.AddWithMessage(String.Format("Status for {0}-{1:d3} set to: {2} (Was: {3})", tr.QRANumber, tr.BatchUnitNumber, status.ToString, oldStatus), NotificationType.Information)
                    End If
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return tr.Notifications
        End Function

        Private Shared Function AddCaterDocumentSingleTestRecord(ByVal tr As TestRecord, ByVal docNumber As String, ByVal comments As String) As NotificationCollection
            Try
                If tr IsNot Nothing Then
                    'add any new docs
                    Dim failDoc As Dictionary(Of String, String) = RequestDB.GetExternalRequestNotLinked(docNumber, "Oracle")

                    If failDoc IsNot Nothing AndAlso Not tr.FailDocs.Contains(failDoc) Then
                        tr.AddFailDoc(failDoc, comments, UserManager.GetCurrentValidUserLDAPName)
                        Save(tr)
                        tr.Notifications.AddWithMessage(tr.QRANumber + " assigned to test record for " + tr.TestIdentificationString + ".", NotificationType.Information)
                    Else
                        tr.Notifications.AddWithMessage(docNumber + " cannot be loaded or is already assigned.", NotificationType.Information)
                    End If
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return tr.Notifications
        End Function

        Private Shared Function RemoveCaterDocumentSingleTestRecord(ByVal tr As TestRecord, ByVal docNumber As String, ByVal comments As String) As NotificationCollection
            Try
                If tr IsNot Nothing Then
                    'add any new docs
                    tr.RemoveFailDoc(docNumber, UserManager.GetCurrentValidUserLDAPName, comments)
                    Save(tr)
                    tr.Notifications.AddWithMessage(docNumber + " removed from to test record for " + tr.TestIdentificationString + ".", NotificationType.Information)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex)
            End Try

            Return tr.Notifications
        End Function

        Public Shared Function CheckBatchForResultUpdates(ByVal b As Batch, ByVal ignoreCurrentBatchStatus As Boolean) As Integer
            Try
                If b IsNot Nothing Then
                    If ((b.Status = BatchStatus.InProgress OrElse b.Status = BatchStatus.Received) Or ignoreCurrentBatchStatus) AndAlso (b.TestStage IsNot Nothing) AndAlso b.Job IsNot Nothing Then
                        Dim bcoll As New BatchCollection
                        bcoll.Add(b)
                        Return TestRecordDB.SetResultsForBatchCollection(bcoll, UserManager.GetCurrentValidUserLDAPName)
                    End If
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return 0
        End Function
    End Class
End Namespace