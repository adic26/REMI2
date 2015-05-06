Imports System.Linq
Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports REMI.Contracts
Imports REMI.Core
Imports System.Reflection
Imports System.Text

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class RequestManager
        Inherits REMIManagerBase

        Public Shared Function GetRequestsNotInREMI(ByVal searchStr As String) As DataTable
            Try
                Return RequestDB.GetRequestsNotInREMI(searchStr)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("Requests")
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetRequestAuditLogs(ByVal requestNumber As String) As DataTable
            Try
                Return RequestDB.GetRequestAuditLogs(requestNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, requestNumber)
            End Try
            Return New DataTable("RequestAudit")
        End Function

        Public Shared Function GetRequestsForDashBoard(ByVal searchStr As String) As DataTable
            Try
                Return RequestDB.GetRequestsForDashBoard(searchStr)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("RequestsDashboard")
        End Function

        Public Shared Function GetRequestTypes() As DataTable
            Try
                Return RequestDB.GetRequestTypes(UserManager.GetCurrentValidUserLDAPName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("RequestTypes")
        End Function

        Public Shared Function GetRequestSetupInfo(ByVal productID As Int32, ByVal jobID As Int32, ByVal batchID As Int32, ByVal testStageType As Int32, ByVal blankSelected As Int32, ByVal RequestTypeID As Int32, ByVal userID As Int32) As DataTable
            Try
                Return RequestDB.GetRequestSetupInfo(productID, jobID, batchID, testStageType, blankSelected, userID, RequestTypeID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("RequestSetupInfo")
        End Function

        Public Shared Function GetRequestParent(ByVal requestTypeID As Int32, ByVal includeArchived As Boolean, ByVal includeSelect As Boolean) As DataTable
            Try
                If (includeSelect) Then
                    Dim list = (From t In New String() {String.Empty} Select New With {.Name = "Select...", .ReqFieldSetupID = 0}).Union((From r In New REMI.Dal.Entities().Instance().ReqFieldSetups Where r.RequestTypeID = requestTypeID And (r.Archived = False Or (includeArchived)) Select New With {.Name = r.Name, .ReqFieldSetupID = r.ReqFieldSetupID}).OrderBy(Function(map) map.Name).Distinct.ToList())

                    Return REMI.BusinessEntities.Helpers.EQToDataTable(list, "RequestSetupParent")
                Else
                    Dim fields = (From r In New REMI.Dal.Entities().Instance().ReqFieldSetups Where r.RequestTypeID = requestTypeID And (r.Archived = False Or (includeArchived)) Select New With {.Name = r.Name, .ReqFieldSetupID = r.ReqFieldSetupID}).ToList()

                    Return REMI.BusinessEntities.Helpers.EQToDataTable(fields.OrderBy(Function(r) r.Name), "RequestSetupParent")
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("RequestSetupParent")
        End Function

        Public Shared Function GetRequestMappingFields() As DataTable
            Try
                Dim list = (From t In New String() {String.Empty} Select New With {.IntField = "Select..."}).Union((From m In New REMI.Dal.Entities().Instance().ReqFieldMappings Select New With {.IntField = m.IntField}).OrderBy(Function(map) map.IntField).Distinct.ToList())

                Return REMI.BusinessEntities.Helpers.EQToDataTable(list, "RequestMappingFields")
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("RequestMappingFields")
        End Function

        Public Shared Function SaveRequestHeaderSetup(ByVal hasREMIIntegration As Boolean, ByVal isExternal As Boolean, ByVal hasDistribution As Boolean, ByVal requestTypeID As Int32) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim requestType As REMI.Entities.RequestType = (From rt In instance.RequestTypes Where rt.RequestTypeID = requestTypeID Select rt).FirstOrDefault()

                If requestType IsNot Nothing Then
                    requestType.HasIntegration = hasREMIIntegration
                    requestType.HasDistribution = hasDistribution
                    requestType.IsExternal = isExternal
                End If
                instance.SaveChanges()
                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function SaveFieldSetup(ByVal requestTypeID As Int32, ByVal fieldSetupID As Int32, ByVal name As String, ByVal fieldTypeID As Int32, ByVal fieldValidationID As Int32, ByVal isRequired As Boolean, ByVal isArchived As Boolean, ByVal optionsTypeID As Int32, ByVal category As String, ByVal parentFieldID As Int32, ByVal intField As String, ByVal description As String, ByVal defaultValue As String, ByVal defaultDisplayNum As Int32, ByVal maxDisplayNum As Int32) As Boolean
            Try
                Dim oldName As String = String.Empty
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim setup As REMI.Entities.ReqFieldSetup = (From fs In instance.ReqFieldSetups Where fs.ReqFieldSetupID = fieldSetupID Select fs).FirstOrDefault()

                If (setup IsNot Nothing) Then
                    oldName = setup.Name
                    setup.Name = name
                    setup.FieldTypeID = fieldTypeID
                    setup.FieldValidationID = fieldValidationID
                    setup.IsRequired = isRequired
                    setup.Archived = isArchived
                    setup.OptionsTypeID = optionsTypeID
                    setup.Category = category
                    setup.ParentReqFieldSetupID = parentFieldID
                    setup.Description = description
                    setup.DefaultValue = defaultValue

                    Dim requestType As REMI.Entities.RequestType = (From rt In instance.RequestTypes Where rt.RequestTypeID = requestTypeID Select rt).FirstOrDefault()
                    Dim requestFieldMapping As REMI.Entities.ReqFieldMapping = (From fm In instance.ReqFieldMappings Where fm.ExtField = oldName Select fm).FirstOrDefault()

                    If (requestFieldMapping IsNot Nothing) Then
                        If (Not String.IsNullOrEmpty(intField)) Then
                            requestFieldMapping.ExtField = name
                            requestFieldMapping.IntField = intField
                        Else
                            instance.DeleteObject(requestFieldMapping)
                        End If
                    Else
                        Dim rfm As New REMI.Entities.ReqFieldMapping
                        rfm.IntField = intField
                        rfm.ExtField = name
                        rfm.RequestTypeID = requestTypeID
                        rfm.IsActive = True

                        instance.AddToReqFieldMappings(rfm)
                    End If

                    Dim sibling As REMI.Entities.ReqFieldSetupSibling = (From s In instance.ReqFieldSetupSiblings Where s.ReqFieldSetupID = fieldSetupID Select s).FirstOrDefault()

                    If (sibling IsNot Nothing) Then
                        If (maxDisplayNum = 1) Then
                            instance.DeleteObject(sibling)
                        Else
                            sibling.DefaultDisplayNum = defaultDisplayNum
                            sibling.MaxDisplayNum = maxDisplayNum
                        End If
                    Else
                        If (maxDisplayNum > 1) Then
                            sibling = New REMI.Entities.ReqFieldSetupSibling
                            sibling.DefaultDisplayNum = defaultDisplayNum
                            sibling.MaxDisplayNum = maxDisplayNum
                            sibling.ReqFieldSetupID = fieldSetupID

                            instance.AddToReqFieldSetupSiblings(sibling)
                        End If
                    End If

                Else
                    Dim rfs As New REMI.Entities.ReqFieldSetup()
                    rfs.Name = name
                    rfs.Archived = isArchived
                    rfs.IsRequired = isRequired
                    rfs.Category = category
                    rfs.FieldTypeID = fieldTypeID
                    rfs.FieldValidationID = fieldValidationID
                    rfs.ParentReqFieldSetupID = parentFieldID
                    rfs.OptionsTypeID = optionsTypeID
                    rfs.RequestTypeID = requestTypeID
                    rfs.ColumnOrder = 1
                    rfs.DisplayOrder = 999
                    rfs.Description = description
                    rfs.DefaultValue = defaultValue

                    instance.AddToReqFieldSetups(rfs)

                    If (intField.Trim().Length > 0) Then
                        Dim rfm As New REMI.Entities.ReqFieldMapping
                        rfm.IntField = intField
                        rfm.ExtField = name
                        rfm.RequestTypeID = requestTypeID
                        rfm.IsActive = True

                        instance.AddToReqFieldMappings(rfm)
                    End If

                    If (maxDisplayNum > 1) Then
                        instance.SaveChanges()
                        Dim Sibling As New REMI.Entities.ReqFieldSetupSibling
                        Sibling.DefaultDisplayNum = defaultDisplayNum
                        Sibling.MaxDisplayNum = maxDisplayNum
                        Sibling.ReqFieldSetupID = fieldSetupID

                        instance.AddToReqFieldSetupSiblings(Sibling)
                    End If
                End If

                instance.SaveChanges()
                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function AddRequestFieldData(ByVal requestTypeID As Int32, ByVal requestID As Int32, ByVal fieldName As String, ByVal fieldValue As String) As Boolean
            Dim success As Boolean = False

            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim field As REMI.Entities.ReqFieldSetup = (From f In instance.ReqFieldSetups Where f.Name = fieldName And f.RequestTypeID = requestTypeID Select f).FirstOrDefault()

                If (field IsNot Nothing) Then
                    Dim data As List(Of REMI.Entities.ReqFieldData) = (From d In instance.ReqFieldDatas Where d.RequestID = requestID And d.ReqFieldSetupID = field.ReqFieldSetupID Select d).ToList()
                    Dim newData As REMI.Entities.ReqFieldData

                    If (data.Count = 0) Then
                        newData = New REMI.Entities.ReqFieldData
                        newData.InstanceID = 1
                        newData.LastUser = UserManager.GetCurrentValidUserLDAPName
                        newData.InsertTime = DateTime.Now
                        newData.ReqFieldSetupID = field.ReqFieldSetupID
                        newData.RequestID = requestID
                        newData.Value = fieldValue
                        instance.AddToReqFieldDatas(newData)
                        success = True
                    ElseIf (data.Count = 1 And String.IsNullOrEmpty(data(0).Value)) Then
                        newData = (From nd In instance.ReqFieldDatas Where nd.RequestID = requestID And nd.ReqFieldSetupID = field.ReqFieldSetupID Select nd).FirstOrDefault()
                        newData.Value = fieldValue
                        success = True
                    Else
                        Dim sib As REMI.Entities.ReqFieldSetupSibling = (From s In instance.ReqFieldSetupSiblings Where s.ReqFieldSetupID = field.ReqFieldSetupID Select s).FirstOrDefault()

                        If (sib IsNot Nothing) Then
                            Dim maxInstanceID As Int32
                            Int32.TryParse((From i As REMI.Entities.ReqFieldData In data Select i.InstanceID).Max().ToString(), maxInstanceID)

                            If (maxInstanceID < sib.MaxDisplayNum) Then
                                newData = New REMI.Entities.ReqFieldData
                                newData.InstanceID = maxInstanceID + 1
                                newData.LastUser = UserManager.GetCurrentValidUserLDAPName
                                newData.InsertTime = DateTime.Now
                                newData.ReqFieldSetupID = field.ReqFieldSetupID
                                newData.RequestID = requestID
                                newData.Value = fieldValue
                                instance.AddToReqFieldDatas(newData)

                                success = True
                            End If
                        End If
                    End If

                    instance.SaveChanges()
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
                success = False
            End Try

            Return success
        End Function

        Public Shared Function SaveRequestSetupBatchOnly(ByVal productID As Int32, ByVal jobID As Int32, ByVal batchID As Int32, ByVal TestStageType As Int32, ByVal setupInfo As List(Of String)) As NotificationCollection
            Dim nc As New NotificationCollection

            Try
                Dim instance = New REMI.Dal.Entities().Instance()

                If (batchID > 0) Then
                    Dim currentSetupList As New List(Of REMI.Entities.RequestSetup)
                    Dim NewSetupList As New List(Of REMI.Entities.RequestSetup)
                    currentSetupList = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Batch.ID = batchID And rs.TestStage.TestStageType = TestStageType Select rs).ToList()

                    For Each rec As String In setupInfo
                        Dim saveSetup As New REMI.Entities.RequestSetup()
                        Dim splitNode As String() = rec.Split("/"c)

                        Dim testID As Int32
                        Dim testStageID As Int32
                        Int32.TryParse(splitNode(1).ToString(), testID)
                        Int32.TryParse(splitNode(0).ToString(), testStageID)

                        saveSetup = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Batch.ID = batchID And rs.Test.ID = testID And rs.TestStage.ID = testStageID And rs.TestStage.TestStageType = TestStageType).FirstOrDefault()

                        If (saveSetup Is Nothing) Then
                            saveSetup = New REMI.Entities.RequestSetup()
                            saveSetup.Batch = (From b In instance.Batches Where b.ID = batchID Select b).FirstOrDefault()
                            saveSetup.Test = (From t In instance.Tests Where t.ID = testID Select t).FirstOrDefault()
                            saveSetup.TestStage = (From ts In instance.TestStages Where ts.ID = testStageID Select ts).FirstOrDefault()
                            saveSetup.LastUser = UserManager.GetCurrentUser.UserName
                        End If

                        NewSetupList.Add(saveSetup)
                    Next

                    If (currentSetupList IsNot Nothing And currentSetupList.Count > 0) Then
                        Dim removedSetup = currentSetupList.AsEnumerable().Except(NewSetupList.AsEnumerable())

                        If (removedSetup IsNot Nothing) Then
                            For Each sp In removedSetup
                                Dim recordExists = (From tr In instance.TestRecords.Include("TestUnit").Include("Test").Include("TestStage") Where tr.TestUnit.Batch.ID = batchID And tr.Test.ID = sp.Test.ID And tr.TestStage.ID = sp.TestStage.ID).FirstOrDefault()

                                If (recordExists Is Nothing) Then
                                    instance.DeleteObject(sp)
                                Else
                                    nc.AddWithMessage(String.Format("Removal of Test '{0}' for Stage '{1}' already has test record created. It cannot be removed.", sp.Test.TestName, sp.TestStage.TestStageName), NotificationType.Warning)
                                End If
                            Next
                        End If
                    End If
                Else
                    nc.AddWithMessage("This Save Is Only Used For Batch Setup Save!", NotificationType.Warning)
                End If

                instance.SaveChanges()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return nc
        End Function

        Public Shared Function SaveRequestSetup(ByVal productID As Int32, ByVal jobID As Int32, ByVal batchID As Int32, ByVal saveOptions As List(Of Int32), ByRef tnc As Web.UI.WebControls.TreeNodeCollection, ByVal TestStageType As Int32, ByVal orientationID As Int32) As NotificationCollection
            Dim nc As New NotificationCollection

            Try
                Dim instance = New REMI.Dal.Entities().Instance()

                If (batchID > 0 And TestStageType = Contracts.TestStageType.EnvironmentalStress) Then
                    Dim batch As New REMI.Entities.Batch()
                    batch = (From b In instance.Batches Where b.ID = batchID Select b).FirstOrDefault()

                    If (batch IsNot Nothing) Then
                        batch.JobOrientation = (From o In instance.JobOrientations Where o.ID = orientationID Select o).FirstOrDefault()
                    End If
                End If

                For Each chk In saveOptions 'Loop through the save options
                    Dim currentSetupList As New List(Of REMI.Entities.RequestSetup)
                    Dim NewSetupList As New List(Of REMI.Entities.RequestSetup)

                    If (chk = 1) Then 'Batch
                        currentSetupList = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Batch.ID = batchID And rs.TestStage.TestStageType = TestStageType Select rs).ToList()
                    ElseIf (chk = 2) Then 'Product
                        currentSetupList = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Job.ID = jobID And rs.LookupID = productID And rs.TestStage.TestStageType = TestStageType Select rs).ToList()
                    ElseIf (chk = 3) Then 'Job
                        currentSetupList = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Job.ID = jobID And rs.TestStage.TestStageType = TestStageType And rs.Lookup Is Nothing And rs.Batch Is Nothing Select rs).ToList()
                    End If

                    For Each node As Web.UI.WebControls.TreeNode In tnc
                        Dim saveSetup As New REMI.Entities.RequestSetup()
                        Dim parentNode As Web.UI.WebControls.TreeNode = node.Parent
                        Dim testID As Int32
                        Dim testStageID As Int32
                        Int32.TryParse(node.Value, testID)
                        Int32.TryParse(parentNode.Value, testStageID)

                        If (chk = 1) Then 'Batch
                            saveSetup = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Batch.ID = batchID And rs.Test.ID = testID And rs.TestStage.ID = testStageID And rs.TestStage.TestStageType = TestStageType).FirstOrDefault()
                        ElseIf (chk = 2) Then 'Product
                            saveSetup = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Job.ID = jobID And rs.LookupID = productID And rs.Test.ID = testID And rs.TestStage.ID = testStageID And rs.TestStage.TestStageType = TestStageType).FirstOrDefault()
                        ElseIf (chk = 3) Then 'Job
                            saveSetup = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Job.ID = jobID And rs.Test.ID = testID And rs.TestStage.ID = testStageID And rs.TestStage.TestStageType = TestStageType And rs.Lookup Is Nothing And rs.Batch Is Nothing).FirstOrDefault()
                        End If

                        If (saveSetup Is Nothing) Then
                            saveSetup = New REMI.Entities.RequestSetup()

                            If (chk = 1) Then
                                saveSetup.Batch = (From b In instance.Batches Where b.ID = batchID Select b).FirstOrDefault()
                            ElseIf (chk = 2) Then
                                saveSetup.Lookup = (From l In instance.Lookups Where l.LookupID = productID Select l).FirstOrDefault()
                                saveSetup.Job = (From j In instance.Jobs Where j.ID = jobID Select j).FirstOrDefault()
                            ElseIf (chk = 3) Then
                                saveSetup.Job = (From j In instance.Jobs Where j.ID = jobID Select j).FirstOrDefault()
                            End If

                            saveSetup.Test = (From t In instance.Tests Where t.ID = testID Select t).FirstOrDefault()
                            saveSetup.TestStage = (From ts In instance.TestStages Where ts.ID = testStageID Select ts).FirstOrDefault()
                            saveSetup.LastUser = UserManager.GetCurrentUser.UserName
                        End If

                        NewSetupList.Add(saveSetup)
                    Next

                    If (currentSetupList IsNot Nothing And currentSetupList.Count > 0) Then
                        Dim removedSetup = currentSetupList.AsEnumerable().Except(NewSetupList.AsEnumerable())

                        If (removedSetup IsNot Nothing) Then
                            For Each sp In removedSetup
                                Dim recordExists = (From tr In instance.TestRecords.Include("TestUnit").Include("Test").Include("TestStage") Where tr.TestUnit.Batch.ID = batchID And tr.Test.ID = sp.Test.ID And tr.TestStage.ID = sp.TestStage.ID).FirstOrDefault()

                                If (recordExists Is Nothing) Then
                                    instance.DeleteObject(sp)
                                Else
                                    nc.AddWithMessage(String.Format("Removal of Test '{0}' for Stage '{1}' already has test record created. It cannot be removed.", sp.Test.TestName, sp.TestStage.TestStageName), NotificationType.Warning)
                                End If
                            Next
                        End If
                    End If
                Next

                instance.SaveChanges()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return nc
        End Function

        Public Shared Function GetRequest(ByVal reqNumber As String) As RequestFieldsCollection
            Try
                Return RequestDB.GetRequest(reqNumber, UserManager.GetCurrentUser, Nothing)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return Nothing
        End Function

        Public Shared Function GetRequestFieldSetup(ByVal requestName As String, ByVal includeArchived As Boolean, ByVal requestNumber As String) As RequestFieldsCollection
            Try
                Return RequestDB.GetRequestFieldSetup(requestName, includeArchived, requestNumber, UserManager.GetCurrentUser, Nothing)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return Nothing
        End Function

        Public Shared Function GetRequestDistribution(ByVal requestID As Int32) As List(Of String)
            Try
                Dim instance = New REMI.Dal.Entities().Instance()

                Return (From dist In instance.ReqDistributions Where dist.RequestID = requestID Select dist.UserName).ToList()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return Nothing
        End Function

        Public Shared Function SaveRequest(ByVal requestName As String, ByRef request As RequestFieldsCollection, ByVal userIdentification As String, ByVal distribution As List(Of String)) As Boolean
            Dim saved As Boolean = False

            Try
                If (request IsNot Nothing) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim requestTypeID As Int32 = request(0).RequestTypeID
                    Dim requestNumber As String = request(0).RequestNumber
                    Dim requestType As REMI.Entities.RequestType = (From rt In instance.RequestTypes Where rt.RequestTypeID = requestTypeID Select rt).FirstOrDefault()
                    saved = RequestDB.SaveRequest(requestName, request, userIdentification)

                    REMIAppCache.ClearAllBatchData(requestNumber)
                    Dim req As REMI.Entities.Request = (From r In instance.Requests Where r.RequestNumber = requestNumber Select r).FirstOrDefault()

                    If (saved And requestType.HasIntegration) Then
                        Dim b As BatchView = BatchManager.GetBatchView(request(0).RequestNumber, True, True, True, True, True, True, True, True, True, True)

                        If (b.OutOfDate) Then
                            BatchManager.Save(b)
                        End If

                        If (req.BatchID Is Nothing) Then
                            req.BatchID = b.ID
                            instance.SaveChanges()
                        End If
                    End If

                    If (request(0).HasDistribution) Then
                        If (distribution IsNot Nothing) Then
                            For Each d In distribution
                                Dim rd As REMI.Entities.ReqDistribution = (From dist In instance.ReqDistributions Where dist.RequestID = req.RequestID And dist.UserName = d Select dist).FirstOrDefault()

                                If (rd Is Nothing) Then
                                    rd = New REMI.Entities.ReqDistribution
                                    rd.UserName = d
                                    rd.RequestID = req.RequestID
                                    instance.AddToReqDistributions(rd)
                                    instance.SaveChanges()
                                End If
                            Next
                        End If

                        If (saved And distribution.Count > 0) Then
                            Dim sb As New StringBuilder
                            sb.AppendLine(String.Format("<a href='{0}{1}' target='_blank'>To Edit Or View This Item Click Here</a>", REMIConfiguration.RequestGoLink, requestNumber))
                            sb.AppendLine(String.Format("<br/>Submitted: {0}", (From rd In request Where rd.IntField = "DateCreated" Select rd.Value).FirstOrDefault()))
                            sb.AppendLine(String.Format("<br/>Requestor: {0}", (From rd In request Where rd.IntField = "Requestor" Select rd.Value).FirstOrDefault()))
                            sb.AppendLine(String.Format("<br/>Test Center: {0}", (From rd In request Where rd.IntField = "TestCenterLocation" Select rd.Value).FirstOrDefault()))
                            sb.AppendLine(String.Format("<br/>Department: {0}", (From rd In request Where rd.IntField = "Department" Select rd.Value).FirstOrDefault()))
                            sb.AppendLine(String.Format("<br/>Reason: {0}", (From rd In request Where rd.IntField = "ReasonForRequest" Select rd.Value).FirstOrDefault()))
                            sb.AppendLine(String.Format("<br/>Product: {0}", (From rd In request Where rd.IntField = "ProductGroup" Select rd.Value).FirstOrDefault()))
                            sb.AppendLine(String.Format("<br/>Product Type: {0}", (From rd In request Where rd.IntField = "ProductType" Select rd.Value).FirstOrDefault()))

                            REMI.Core.Emailer.SendMail(String.Join(",", New List(Of String)(distribution).ToArray()), "remi@blackberry.com", String.Format("{0} Has Been Updated!", requestNumber), sb.ToString(), True, String.Empty)
                        End If
                    End If
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
                saved = False
            End Try

            Return saved
        End Function
    End Class
End Namespace