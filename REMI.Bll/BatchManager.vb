Imports System.Linq
Imports System.Security
Imports System.Security.Permissions
Imports System.Transactions
Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class BatchManager
        Inherits REMIManagerBase

#Region "remstar methods"
        Private Shared Function AddNewBatchAsMaterialToRemstar(ByVal myMaterial As remstarMaterial) As NotificationCollection
            Dim nc As New NotificationCollection
            Dim qraNumber As String = CStr(IIf(myMaterial Is Nothing, "No Request Number", myMaterial.QRAnumber.ToString()))

            Try
                If RemstarDB.AddMaterial(myMaterial) > 0 Then
                    nc.AddWithMessage("Batch added to remstar database.", NotificationType.Information)
                Else
                    nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, Nothing, "(remstar incoming) Request:" + myMaterial.QRAnumber))
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, qraNumber))
            End Try

            Return nc
        End Function

        Public Shared Function PickBatchFromREMSTAR(ByVal barcode As String, ByRef shelfNumber As String) As NotificationCollection
            Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(barcode.Trim()))
            Dim nc As New NotificationCollection

            Try
                If bc.Validate Then
                    Dim b As BatchView = DirectCast(GetViewBatch(bc.BatchNumber), BatchView)

                    If b IsNot Nothing Then
                        If bc.HasTestUnitNumber Then
                            RemstarDB.ScanDevice(bc.BatchNumber, bc.UnitNumber, UserManager.GetCurrentValidUserLDAPName, ScanDirection.Outward, String.Empty)
                        Else
                            For Each tu As TestUnit In b.TestUnits
                                RemstarDB.ScanDevice(tu.QRANumber, tu.BatchUnitNumber, UserManager.GetCurrentValidUserLDAPName, ScanDirection.Outward, String.Empty)
                            Next
                        End If

                        If (RemstarDB.IsInRemStar(bc.BatchNumber, bc.UnitNumber)) Then
                            shelfNumber = RemstarDB.GetShelfNumbers(bc.BatchNumber)
                        End If

                        nc.AddWithMessage(String.Format("The batch {0} has been added as PICK order to Remstar. Please wait up to 15 seconds for this order to appear in the order management window.", bc.BatchNumber), NotificationType.Information)
                        nc.AddWithMessage(String.Format("Batch {0} is located on shelf(ves): {1}", bc.BatchNumber, shelfNumber), NotificationType.Information)
                    Else
                        nc.AddWithMessage(String.Format("Unable to locate batch {0}. Try adding the material.", bc.BatchNumber), NotificationType.Errors)
                    End If
                Else
                    nc.Add(bc.Notifications)
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e26", NotificationType.Errors, ex, "Request:" + barcode))
            End Try

            Return nc
        End Function

        Public Shared Function PutBatchToREMSTAR(ByVal barcode As String, ByVal remstarNumber As Integer) As NotificationCollection
            'set the barcode
            Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(barcode.Trim()))
            Dim nc As New NotificationCollection
            Dim binName As String

            Try
                If bc.Validate Then
                    Dim b As BatchView = DirectCast(GetViewBatch(bc.BatchNumber), BatchView)

                    If b IsNot Nothing Then
                        If b.IsCompleteInRequest Then
                            binName = "Cell(445x600x600)"
                        Else
                            binName = "SMALL-REM" + remstarNumber.ToString
                        End If

                        If bc.HasTestUnitNumber Then
                            RemstarDB.ScanDevice(bc.BatchNumber, bc.UnitNumber, UserManager.GetCurrentValidUserLDAPName, ScanDirection.Inward, binName)
                        Else
                            For Each tu As TestUnit In b.TestUnits
                                RemstarDB.ScanDevice(tu.QRANumber, tu.BatchUnitNumber, UserManager.GetCurrentValidUserLDAPName, ScanDirection.Inward, binName)
                            Next
                        End If

                        nc.AddWithMessage(String.Format("The batch {0} has been added as PUT order to Remstar. Please wait up to 15 seconds for this order to appear in the order management window.", bc.BatchNumber), NotificationType.Information)
                    Else
                        nc.AddWithMessage(String.Format("Unable to locate batch {0}. Try adding the material.", bc.BatchNumber), NotificationType.Errors)
                    End If
                Else
                    nc.Add(bc.Notifications)
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e25", NotificationType.Errors, ex, "Request:" + barcode))
            End Try
            Return nc
        End Function
#End Region

#Region "Public Data Access Methods"
        ''' <summary>
        ''' This function adds a batch to remi when a new batch is detected.
        ''' </summary>
        ''' <remarks></remarks>
        Private Shared Sub AddNewBatchToREMI(ByVal bc As DeviceBarcodeNumber, ByRef b As Batch)
            Try
                If b IsNot Nothing Then
                    If b.NeedsToBeSaved Then
                        b.LastUser = UserManager.GetCurrentValidUserLDAPName

                        If b.ID <= 0 AndAlso b.Validate Then
                            'set the test stage to the first possible one
                            b.Job = JobManager.GetJob(b.JobName)
                            b.TestStageName = (From ts In b.Job.TestStages Where ts.ProcessOrder >= 0 And ts.IsArchived = False Order By ts.ProcessOrder Ascending Select ts.Name).FirstOrDefault()

                            'check if this is a legacy batch, remstar inventory from pre remi days
                            b.SetNewBatchStatus()

                            'indicate if batch is really old
                            If b.IsForDisposal Then
                                b.Notifications.AddWithMessage("This batch is older than three years and can be disposed of.", NotificationType.Information)
                            End If

                            'save it
                            Try
                                b.ID = Save(b)
                                'the following method adds this batch to the remstar table. This will be parsed by the remstar application and the
                                'batch will get added to remstar automatically.
                                b.Notifications.Add(AddNewBatchAsMaterialToRemstar(b.GetRemstarMaterial()))
                            Catch ex As Exception
                                b.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, b.QRANumber))
                            End Try
                        End If
                    End If
                    'If the batch was saved OK then we need to add all of the test units to the batch or add any missing units.

                    If b.ID > 0 Then
                        'add the correct number of units.

                        For i As Integer = 1 To b.NumberOfUnitsExpected
                            Dim tu As TestUnit = b.GetUnit(i)
                            If tu IsNot Nothing AndAlso Not tu.IsSavedInREMI Then
                                tu.LastUser = UserManager.GetCurrentValidUserLDAPName
                                If tu.Validate Then
                                    TestUnitManager.Save(tu)
                                    b.NumberOfUnits += 1
                                Else
                                    b.Notifications.AddWithMessage("Unable to save test unit " + i.ToString, NotificationType.Warning)
                                End If
                            Else
                                b.Notifications.Add(tu.Notifications)
                            End If

                        Next
                    Else
                        b.Notifications.AddWithMessage("Unable to save batch.", NotificationType.Errors)
                    End If
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e9", NotificationType.Errors, ex)
            End Try
        End Sub

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function BatchUpdateOrientation(ByVal requestNumber As String, ByVal orientationID As Int32) As Boolean
            Try
                Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(requestNumber))

                If barcode.Validate() And orientationID > 0 Then
                    Dim instance = New REMI.Dal.Entities().Instance()

                    Dim bjo = (From b In instance.Batches Where b.QRANumber = barcode.BatchNumber Select b).FirstOrDefault()

                    If (bjo IsNot Nothing) Then
                        bjo.JobOrientation = (From jo In instance.JobOrientations Where jo.ID = orientationID Select jo).FirstOrDefault()
                    End If

                    instance.SaveChanges()

                    Return True
                Else
                    Return False
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetBatchUnitsInStage(ByVal requestNumber As String) As DataTable
            Try
                Return BatchDB.GetBatchUnitsInStage(requestNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, requestNumber.ToString())
            End Try
            Return New DataTable("BatchUnitsInStage")
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetBatchDocuments(ByVal requestNumber As String) As DataTable
            Try
                Return BatchDB.GetBatchDocuments(requestNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, requestNumber.ToString())
            End Try
            Return New DataTable("BatchDocuments")
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetBatchJIRA(ByVal batchID As Int32, ByVal showEmptyRecord As Boolean) As DataTable
            Try
                Dim dt As DataTable = BatchDB.GetBatchJIRA(BatchID)

                If ShowEmptyRecord = False And dt.Rows.Count > 0 Then
                    dt.Rows(0).Delete()
                    dt.AcceptChanges()
                End If

                Return dt
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, BatchID.ToString())
            End Try
            Return New DataTable("BatchJIRA")
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetReqString(ByVal number As String) As String
            Return GetReqString(Number, False)
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetReqString(ByVal number As String, ByVal byPassUserCheck As Boolean) As String
            Try
                Dim isValid As Boolean = Number.Split("-"c).Length - 1 > 0
                Dim userID As Int32 = UserManager.GetCurrentUser.ID
                Dim departments As List(Of Int32) = (From d In New REMI.Dal.Entities().Instance().UserDetails.Include("Lookup").Include("Lookup.LookupType") Where d.UserID = userID And d.Lookup.LookupType.Name = "Department" Select d.LookupID).ToList()

                If (Number.Contains("XX-TEST")) Then
                    isValid = False
                End If

                Select Case Number.Length
                    Case 4
                        Number = String.Format("{0}-{1}", DateTime.Now.Year.ToString().Substring(2), Number)
                        Return (From b In New REMI.Dal.Entities().Instance().Batches Where b.QRANumber.Contains(number.Trim()) And (departments.Contains(b.Department.LookupID) Or byPassUserCheck Or b.Department.LookupID = 0) Select b.QRANumber).FirstOrDefault()
                    Case 7
                        If (isValid) Then
                            If ((From b In New REMI.Dal.Entities().Instance().Batches Where b.QRANumber.Contains(number.Trim()) And (departments.Contains(b.Department.LookupID) Or byPassUserCheck Or b.Department.LookupID = 0) Select b.QRANumber).FirstOrDefault() IsNot Nothing) Then
                                Return (From b In New REMI.Dal.Entities().Instance().Batches Where b.QRANumber.Contains(number.Trim()) And (departments.Contains(b.Department.LookupID) Or byPassUserCheck Or b.Department.LookupID = 0) Select b.QRANumber).FirstOrDefault()
                            ElseIf ((From b In New REMI.Dal.Entities().Instance().Batches Where b.QRANumber.Contains(number.Trim()) Select b.QRANumber).FirstOrDefault() Is Nothing) Then
                                Return number.Trim()
                            Else
                                Return String.Empty
                            End If
                        Else
                            Return Number.Trim()
                        End If
                    Case 11, 15, 21
                        Dim reqNum As String = Number.Substring(0, 11).ToString().Trim()

                        If (isValid) Then
                            If ((From b In New REMI.Dal.Entities().Instance().Batches Where b.QRANumber = reqNum And (departments.Contains(b.Department.LookupID) Or byPassUserCheck Or b.Department.LookupID = 0) Select b.QRANumber).FirstOrDefault() IsNot Nothing) Then
                                Return number
                            ElseIf ((From b In New REMI.Dal.Entities().Instance().Batches Where b.QRANumber = reqNum Select b.QRANumber).FirstOrDefault() Is Nothing) Then
                                Return number
                            Else
                                Return String.Empty
                            End If
                        End If

                        Return Number.Trim()
                    Case Else
                        Return (From b In New REMI.Dal.Entities().Instance().Batches Where b.QRANumber = number.Trim() And (departments.Contains(b.Department.LookupID) Or byPassUserCheck Or b.Department.LookupID = 0) Select b.QRANumber).FirstOrDefault()
                End Select
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, Number.ToString())
            End Try

            Return Number
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetBatchAuditLogs(ByVal requestNumber As String) As Object
            Try
                Return (From ba In New REMI.Dal.Entities().Instance().vw_BatchAudit Where ba.QRANumber = requestNumber Select ba).ToList
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, requestNumber.ToString())
            End Try
            Return New DataTable
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetListAtLocation(ByVal barcodePrefix As Integer, ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal sortExpression As String) As BatchCollection
            Try
                Dim bc As BatchCollection = BatchDB.GetListAtLocation(barcodePrefix, startRowIndex, MaximumRows, sortExpression, UserManager.GetCurrentUser)
                Return bc
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, barcodePrefix.ToString)
            End Try
            Return New BatchCollection
        End Function

        ''' <summary> 
        ''' Gets the batches in environmental chambers
        ''' </summary> 
        ''' <returns></returns>
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetBatchesInChamber(ByVal testCentreLocation As Int32, ByVal byPass As Boolean, ByVal userID As Int32) As BatchCollection
            Try
                Return BatchDB.GetListInChambers(testCentreLocation, -1, -1, String.Empty, byPass, UserManager.GetCurrentUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("Test Center Location: {0}", testCentreLocation))
                Return New BatchCollection
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function AddEditJira(ByVal batchID As Int32, ByVal jiraID As Int32, ByVal displayName As String, ByVal link As String, ByVal title As String) As Boolean
            Try
                If (batchID > 0) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim bjira As REMI.Entities.BatchesJira = (From j In instance.BatchesJiras Where j.BatchID = batchID And j.JIRAID = jiraID Select j).FirstOrDefault()

                    If (bjira Is Nothing) Then
                        bjira = New REMI.Entities.BatchesJira()
                        bjira.BatchID = batchID
                        bjira.DisplayName = displayName
                        bjira.Title = title
                        bjira.Link = link

                        instance.AddToBatchesJiras(bjira)
                    Else
                        bjira.Title = title
                        bjira.Link = link
                        bjira.DisplayName = displayName
                    End If

                    instance.SaveChanges()

                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("batchID: {0} jiraID: {1} displayName: {2} link: {3} title: {4}", batchID, jiraID, displayName, link, title))
            End Try

            Return False
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function SaveBatchComment(ByVal requestNumber As String, ByVal userIdentification As String, ByVal comment As String) As Boolean
            Try
                Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(requestNumber))
                If barcode.Validate() Then
                    Dim instance = New REMI.Dal.Entities().Instance()

                    Dim bc As New REMI.Entities.BatchComment()
                    bc.Batch = (From b In instance.Batches Where b.QRANumber = barcode.BatchNumber Select b).FirstOrDefault()
                    bc.LastUser = userIdentification
                    bc.Text = comment
                    bc.DateAdded = Date.Now
                    bc.Active = True
                    instance.AddToBatchComments(bc)
                    instance.SaveChanges()

                    Return True
                Else
                    Return False
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request Number: {0} comment: {1}", requestNumber, comment))
                Return False
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function SaveExecutiveSummary(ByVal requestNumber As String, ByVal userIdentification As String, ByVal summary As String) As Boolean
            Try
                If (Not String.IsNullOrEmpty(summary.Trim())) Then
                    Dim barcode As New DeviceBarcodeNumber(BatchManager.GetReqString(requestNumber))
                    If barcode.Validate() Then
                        Dim instance = New REMI.Dal.Entities().Instance()

                        Dim result = (From b In instance.Batches Where b.QRANumber = requestNumber Select b).FirstOrDefault()

                        If (result IsNot Nothing) Then
                            result.ExecutiveSummary = summary
                        End If

                        Dim requestType As Int32 = (From rt In instance.RequestTypes Where rt.Lookup.Values = barcode.Type Select rt.RequestTypeID).FirstOrDefault()
                        Dim request As Int32 = (From r In instance.Requests Where r.RequestNumber = requestNumber Select r.RequestID).FirstOrDefault()
                        Dim map As String = (From m In instance.ReqFieldMappings Where m.RequestTypeID = requestType And m.IntField = "ExecutiveSummary" Select m.ExtField).FirstOrDefault()
                        Dim setupID As Int32 = (From s In instance.ReqFieldSetups Where s.RequestTypeID = requestType And s.Name = map Select s.ReqFieldSetupID).FirstOrDefault()

                        If (setupID > 0) Then
                            Dim data As REMI.Entities.ReqFieldData = (From d In instance.ReqFieldDatas Where d.ReqFieldSetupID = setupID And d.RequestID = request Select d).FirstOrDefault()
                            If (data IsNot Nothing) Then
                                data.Value = summary
                            Else
                                data = New REMI.Entities.ReqFieldData
                                data.InsertTime = DateTime.Now
                                data.InstanceID = 1
                                data.LastUser = userIdentification
                                data.RequestID = request
                                data.ReqFieldSetupID = setupID
                                data.Value = summary
                                instance.AddToReqFieldDatas(data)
                            End If
                        End If

                        instance.SaveChanges()

                        Return True
                    Else
                        Return False
                    End If
                Else
                    Return False
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request Number: {0} summary: {1}", requestNumber, summary))
                Return False
            End Try
        End Function

        ''' <summary> 
        ''' Gets the number of daily list batches in the database
        ''' </summary> 
        ''' <returns></returns>
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function CountListAtLocation(ByVal barcodePrefix As Integer) As Integer
            Try
                Return BatchDB.CountBatchesInTrackingLocation(barcodePrefix)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TrackingLocationID: {0}", BarcodePrefix))
                Return -1
            End Try
        End Function

        Public Shared Function GetRAWBatchInformation(ByVal requestNumber As String) As REMI.Entities.Batch
            Try
                Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(requestNumber))
                If bc.Validate Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim batch As REMI.Entities.Batch = (From b In instance.Batches.Include("TestCenter").Include("AccessoryGroup").Include("ProductType").Include("Purpose").Include("Department") Where b.QRANumber = bc.BatchNumber Select b).FirstOrDefault()

                    Return batch
                Else
                    Return Nothing
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function

        Public Shared Function GenerateBatchCountOrderInREMSTAR() As Boolean
            Try
                Dim qras As List(Of String) = BatchDB.GetRandomCountQraNumbers()
                If qras.Count = 5 Then
                    Return RemstarDB.AddCountOrder(qras, UserManager.GetCurrentValidUserLDAPName)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e26", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetYourActiveBatchesDataTable(ByVal byPass As Boolean, ByVal year As Int32, ByVal onlyShowQRAWithResults As Boolean) As DataTable
            Try
                Return BatchDB.GetYourActiveBatchesDataTable(UserManager.GetCurrentUser.ID, byPass, year, onlyShowQRAWithResults)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetActiveBatches() As BatchCollection
            Try
                Return BatchDB.GetActiveBatches(-1, -1, False, UserManager.GetCurrentUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New BatchCollection
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetActiveBatches(ByVal requestor As String) As BatchCollection
            Try
                Return BatchDB.GetActiveBatches(requestor, -1, -1, UserManager.GetCurrentUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("requestor: {0}", requestor))
            End Try
            Return New BatchCollection
        End Function

        Public Shared Function MoveBatchForward(ByVal requestNumber As String, ByVal userIdentification As String) As Boolean
            REMIAppCache.ClearAllBatchData(requestNumber)
            Dim b As Batch = BatchManager.GetItem(requestNumber, False, True, True)
            TestRecordManager.CheckBatchForResultUpdates(b, False)

            Return BatchDB.MoveBatchForward(requestNumber, userIdentification)
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function BatchSearch(ByVal bs As BatchSearch, ByVal byPass As Boolean, ByVal userID As Int32, Optional loadTestRecords As Boolean = False, Optional loadDurations As Boolean = False, Optional loadTSRemaining As Boolean = True, Optional OnlyHasResults As Int32 = 0) As BatchCollection
            Try
                Return BatchDB.BatchSearch(bs, byPass, userID, loadTestRecords, loadDurations, loadTSRemaining, UserManager.GetCurrentUser, OnlyHasResults)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Empty)
                Return New BatchCollection
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function BatchSearchBase(ByVal bs As BatchSearch, ByVal byPass As Boolean, ByVal userID As Int32, Optional loadTestRecords As Boolean = False, Optional loadDurations As Boolean = False, Optional loadTSRemaining As Boolean = True, Optional OnlyHasResults As Int32 = 0) As List(Of BatchView)
            Try
                Return BatchDB.BatchSearchBase(bs, byPass, userID, loadTestRecords, loadDurations, loadTSRemaining, UserManager.GetCurrentUser, OnlyHasResults)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Empty)
                Return New List(Of BatchView)
            End Try
        End Function

        Public Shared Function GetBatchView(ByVal batchQRANumber As String) As BatchView
            Try
                Return BatchDB.GetSlimBatchByQRANumber(batchQRANumber, UserManager.GetCurrentUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("Request: {0}", batchQRANumber))
            End Try

            Return Nothing
        End Function

        Public Shared Function GetViewBatch(ByVal requestNumber As String) As IBatch
            Try
                'becuase we are running two batch models side by side
                'If the batch is not already in remi, I must use the older type batch getitem method
                'so as to got through the initial batch setup process.
                Dim b As IBatch = BatchDB.GetSlimBatchByQRANumber(requestNumber, UserManager.GetCurrentUser)
                If b IsNot Nothing Then
                    Return b
                End If
                'ok we don't have this in the database so get the 'full' older model.
                Return GetItem(requestNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return Nothing
        End Function

        ''' <summary>
        ''' Attempts to retrieve batch from REMI DB, If that fails it attempts to retrieve a batch from the TRS. 
        ''' </summary>
        ''' <param name="batchQRANumber">The QRA number of the batch.</param>
        ''' <returns>A batch</returns>
        ''' <remarks>This function always returns an object. Check the ID for a null batch!</remarks>
        Public Shared Function GetItem(ByVal requestNumber As String, Optional ByVal getFailParams As Boolean = False, Optional ByVal cacheRetrievedData As Boolean = True, Optional ByVal refreshCache As Boolean = False) As Batch
            Dim b As Batch

            If refreshCache Then
                REMIAppCache.ClearAllBatchData(requestNumber)
            End If

            Try
                Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(requestNumber))
                If bc.Validate Then
                    b = BatchDB.GetBatchByQRANumber(requestNumber, UserManager.GetCurrentUser, cacheRetrievedData)

                    If b Is Nothing Then
                        b = New Batch(RequestDB.GetRequest(bc.BatchNumber, UserManager.GetCurrentUser))

                        AddNewBatchToREMI(bc, b)
                    End If

                    'if the batch is valid but the correct number of units are not available, then add the extra units.
                    If b IsNot Nothing AndAlso b.NumberOfUnits < b.NumberOfUnitsExpected Then
                        AddNewBatchToREMI(bc, b)
                    End If
                Else
                    b = New Batch(requestNumber)
                    b.Notifications.Add(bc.Notifications)
                End If
            Catch ex As Exception
                b = New Batch(requestNumber)
                b.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, requestNumber))
            End Try

            Return b
        End Function

        ''' <summary> 
        ''' Saves a batch in the database. 
        ''' </summary> 
        ''' <param name="myBatch">The Batch instance to save.</param> 
        ''' <returns>The new ID if the Batch is new in the database or the existing ID when an item was updated.</returns> 
        <DataObjectMethod(DataObjectMethodType.Update, True)> _
        Public Shared Function Save(ByVal myBatch As Batch) As Int32
            Dim currentUser As String = UserManager.GetCurrentValidUserLDAPName
            Try
                myBatch.LastUser = currentUser
                myBatch.ID = BatchDB.Save(myBatch)
                myBatch.Notifications.AddWithMessage(String.Format("{0} saved OK!", myBatch.QRANumber), NotificationType.Information)
                Return myBatch.ID
            Catch ex As Exception
                myBatch.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, myBatch.QRANumber))
                Return 0
            End Try
        End Function
#End Region

#Region "Manage Batches Methods"
        Public Shared Function RevertBatchSpecificTestDuration(ByVal requestNumber As String, ByVal teststageid As Integer, ByVal comment As String) As Notification
            Dim n As New Notification

            If BatchDB.DeleteBatchSpecificTestDuration(requestNumber, teststageid, comment, UserManager.GetCurrentValidUserLDAPName) Then
                n.Message = "Duration reverted to default ok."
                n.Type = NotificationType.Information
            Else
                n.Message = "Unable to revert the duration to default. This may be the default duration for this batch."
                n.Type = NotificationType.Errors
            End If

            Return n
        End Function

        Public Shared Function ModifyBatchSpecificTestDuration(ByVal requestNumber As String, ByVal teststageid As Integer, ByVal duration As Double, ByVal comment As String) As Notification
            Dim n As New Notification

            If BatchDB.ModifyBatchSpecificTestDuration(requestNumber, teststageid, duration, comment, UserManager.GetCurrentValidUserLDAPName) Then
                n.Message = "Duration saved ok."
                n.Type = NotificationType.Information
            Else
                n.Message = "Unable to save duration."
                n.Type = NotificationType.Errors
            End If

            Return n
        End Function

        Public Shared Function GetUnitInStages(ByVal requestNumber As String) As DataTable
            Try
                Dim ds As DataSet = BatchDB.GetStagesNeedingCompletionByUnit(requestNumber, 0)
                Dim unitNum As Int32 = 1
                Dim dt As New DataTable("UnitsInStage")
                dt.Columns.Add("Unit", Type.GetType("System.Int32"))
                dt.Columns.Add("Stage", Type.GetType("System.String"))
                dt.Columns.Add("Status", Type.GetType("System.String"))

                For Each tbl As DataTable In ds.Tables
                    Dim row As DataRow = dt.NewRow

                    If (tbl.Rows.Count = 0) Then
                        row("Unit") = unitNum
                        row("Stage") = String.Empty
                        row("Status") = "Completed"
                    Else
                        row("Unit") = unitNum
                        row("Stage") = tbl.Rows(0).Field(Of Int32)("TestStageName")
                        row("Status") = "In Progress"
                    End If

                    dt.Rows.Add(row)
                    unitNum = unitNum + 1
                Next

                Return dt
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return New DataTable("UnitsInStage")
        End Function

        Public Shared Function GetStagesNeedingCompletionByUnit(ByVal requestNumber As String, ByVal unitNumber As Int32) As DataSet
            Try
                Return BatchDB.GetStagesNeedingCompletionByUnit(requestNumber, unitNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return New DataSet
        End Function

        Public Shared Function SetPriority(ByVal requestNumber As String, ByVal priorityID As Int32, ByVal priority As String) As NotificationCollection
            Dim b As Batch
            Try
                b = BatchManager.GetItem(requestNumber)
                If b IsNot Nothing Then
                    If b.Validate Then
                        b.PriorityID = priorityID
                        b.Priority = priority

                        If b.Validate Then
                            BatchManager.Save(b)
                            If (REMI.Core.REMIConfiguration.Debug) Then
                                b.Notifications.Add(LogIssue("SetPriority", "i14", NotificationType.Information, String.Format("Request Number: {0} Priority: {1}", requestNumber, priority)))
                            End If
                        End If
                    End If
                Else
                    b = New Batch
                    b.Notifications.AddWithMessage(String.Format("The batch {0} could not be found.", requestNumber), NotificationType.Warning)
                End If
            Catch ex As Exception
                b = New Batch
                b.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} Priority: {1}", requestNumber, priority)))
            End Try
            Return b.Notifications
        End Function

        Public Shared Function SetStatus(ByVal requestNumber As String, ByVal status As BatchStatus) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                If BatchDB.SetBatchStatus(requestNumber, status, UserManager.GetCurrentValidUserLDAPName) Then
                    If (REMI.Core.REMIConfiguration.Debug) Then
                        nc.Add(LogIssue("SetBatchStatus", "i8", NotificationType.Information, String.Format("Request Number: {0} Status: {1}", requestNumber, status)))
                    End If
                Else
                    nc.Add(LogIssue("SetBatchStatus", "e18", NotificationType.Errors, String.Format("Request Number: {0} Status: {1}", requestNumber, status)))
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} status: {1}", requestNumber, status.ToString))
            End Try
            Return nc
        End Function

#Region "Batch Comments"
        Public Shared Function AddNewComment(ByVal requestNumber As String, ByVal comment As String) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                Dim b As Batch = BatchManager.GetItem(requestNumber)
                If b IsNot Nothing Then
                    If Not BatchDB.AddBatchComment(b.ID, comment, UserManager.GetCurrentValidUserLDAPName) Then
                        nc.Add(LogIssue("AddNewComment", "e27", NotificationType.Errors, String.Format("Request Number: {0} comment: {1}", requestNumber, comment)))
                    End If
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, "Request: " + requestNumber + " comment to add:" + comment)
            End Try
            Return nc
        End Function

        Public Shared Function DeactivateComment(ByVal commentId As Integer) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                BatchDB.DeactivateBatchComment(commentId)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex, "comment ID:" + commentId.ToString())
            End Try
            Return nc
        End Function

        Public Shared Function GetBatchComments(ByVal requestNumber As String) As List(Of IBatchCommentView)
            Return BatchDB.GetBatchComments(requestNumber)
        End Function
#End Region

        Public Shared Function DNPParametricForBatch(ByVal requestNumber As String, ByVal userIdentification As String, ByVal unitNumber As Int32) As Boolean
            Try
                Return BatchDB.DNPParametricForBatch(requestNumber, userIdentification, unitNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, requestNumber.ToString())
            End Try
            Return False
        End Function

        ''' <summary>
        ''' Changes the current test stage that a batch is at. Does not change the test units.
        ''' </summary>
        ''' <param name="qraNumber"></param>
        ''' <param name="testStageName"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function ChangeTestStage(ByVal requestNumber As String, ByVal testStageName As String) As NotificationCollection
            Dim b As Batch
            Try
                b = BatchManager.GetItem(requestNumber)
                If b IsNot Nothing Then
                    If b.Validate Then
                        'validate that the teststageid is part of this job
                        If b.SetTestStage(testStageName) Then
                            If b.Validate Then
                                BatchManager.Save(b)
                                If (REMI.Core.REMIConfiguration.Debug) Then
                                    b.Notifications.AddWithMessage("The test stage was changed ok.", NotificationType.Information)
                                End If
                            End If
                        Else
                            b.Notifications.AddWithMessage(String.Format("The given test stage (Name: {0}) is not part of {1} (Job:{2}.", testStageName, b.QRANumber, b.JobName), NotificationType.Warning)
                        End If
                    End If
                Else
                    b = New Batch
                    b.Notifications.AddWithMessage(String.Format("The batch {0} could not be found.", requestNumber), NotificationType.Warning)
                End If
            Catch ex As Exception
                b = New Batch
                b.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e4", NotificationType.Errors, ex, String.Format("Request: {0} TestStage: {1}", requestNumber, testStageName)))
            End Try
            Return b.Notifications
        End Function
#End Region

    End Class
End Namespace