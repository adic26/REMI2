﻿Imports System.Linq
Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports REMI.Contracts
Imports REMI.Core

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

        Public Shared Function GetRequestSetupInfo(ByVal productID As Int32, ByVal jobID As Int32, ByVal batchID As Int32, ByVal testStageType As Int32, ByVal blankSelected As Int32) As DataTable
            Try
                Return RequestDB.GetRequestSetupInfo(productID, jobID, batchID, testStageType, blankSelected)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("RequestSetupInfo")
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
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e4", NotificationType.Errors, ex)
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
                        currentSetupList = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Job.ID = jobID And rs.Product.ID = productID And rs.TestStage.TestStageType = TestStageType Select rs).ToList()
                    ElseIf (chk = 3) Then 'Job
                        currentSetupList = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Job.ID = jobID And rs.TestStage.TestStageType = TestStageType And rs.Product Is Nothing And rs.Batch Is Nothing Select rs).ToList()
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
                            saveSetup = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Job.ID = jobID And rs.Product.ID = productID And rs.Test.ID = testID And rs.TestStage.ID = testStageID And rs.TestStage.TestStageType = TestStageType).FirstOrDefault()
                        ElseIf (chk = 3) Then 'Job
                            saveSetup = (From rs In instance.RequestSetups.Include("Batch").Include("Test").Include("TestStage").Include("Job") Where rs.Job.ID = jobID And rs.Test.ID = testID And rs.TestStage.ID = testStageID And rs.TestStage.TestStageType = TestStageType And rs.Product Is Nothing And rs.Batch Is Nothing).FirstOrDefault()
                        End If

                        If (saveSetup Is Nothing) Then
                            saveSetup = New REMI.Entities.RequestSetup()

                            If (chk = 1) Then
                                saveSetup.Batch = (From b In instance.Batches Where b.ID = batchID Select b).FirstOrDefault()
                            ElseIf (chk = 2) Then
                                saveSetup.Product = (From p In instance.Products Where p.ID = productID Select p).FirstOrDefault()
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
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e4", NotificationType.Errors, ex)
            End Try

            Return nc
        End Function

        Public Shared Function GetRequest(ByVal reqNumber As String) As RequestFieldsCollection
            Try
                Return RequestDB.GetRequest(reqNumber, UserManager.GetCurrentUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return Nothing
        End Function

        Public Shared Function GetRequestFieldSetup(ByVal requestName As String, ByVal includeArchived As Boolean, ByVal requestNumber As String) As RequestFieldsCollection
            Try
                Return RequestDB.GetRequestFieldSetup(requestName, includeArchived, requestNumber, UserManager.GetCurrentUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return Nothing
        End Function

        Public Shared Function SaveRequest(ByVal requestName As String, ByRef request As RequestFieldsCollection, ByVal userIdentification As String) As Boolean
            Dim saved As Boolean = False
            Try
                saved = RequestDB.SaveRequest(requestName, request, userIdentification)

                If (saved) Then
                    BatchManager.GetItem(request(0).RequestNumber, userIdentification, False, True, False)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                saved = False
            End Try

            Return saved
        End Function
    End Class
End Namespace