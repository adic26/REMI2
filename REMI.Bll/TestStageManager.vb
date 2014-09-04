Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.Transactions
Imports System.ComponentModel
Imports REMI.Contracts

Namespace REMI.Bll
    ''' <summary> 
    ''' The TestStageManager class is responsible for managing <see cref="TestStage">BusinessEntities.TestStage</see> objects in the system. 
    ''' </summary> 
    <DataObjectAttribute()> _
    Public Class TestStageManager
        Inherits REMIManagerBase

        <DataObjectMethod(DataObjectMethodType.[Select], True)> _
        Public Shared Function GetTestStage(ByVal ID As Integer) As TestStage
            Try
                Return TestStageDB.GetItem(ID, String.Empty, String.Empty)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestStageID: {0}", ID))
                Return Nothing
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetListOfNamesForChambers(ByVal jobName As String) As List(Of String)
            Try
                Return TestStageDB.GetListOfNamesForChambers(jobName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("JobName: {0}", jobName))
                Return New List(Of String)
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTestStage(ByVal Name As String, ByVal jobName As String) As TestStage
            Try
                Return TestStageDB.GetItem(0, Name, jobName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestStage: {0} JobName: {1}", Name, jobName))
                Return Nothing
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTestStagesNameByBatch(ByVal batchID As Int32) As Dictionary(Of String, String)
            Try
                Return (From ts In New REMI.Dal.Entities().Instance().vw_GetTaskInfo Where ts.BatchID = batchID And ts.IsArchived = False And ts.TestIsArchived = False And ts.processorder > -1 Select ts).OrderBy(Function(o) o.processorder).ToDictionary(Function(k) k.TestStageID.ToString(), Function(v) v.tsname)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("BatchID: {0}", batchID))
                Return New Dictionary(Of String, String)
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetAllTestStages() As TestStageCollection
            Try
                Return TestStageDB.GetList(TestStageType.NotSet, String.Empty)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New TestStageCollection
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetListOfNames() As List(Of String)
            Try
                Return TestStageDB.GetListOfNames()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New List(Of String)
            End Try
        End Function

#Region "Task Assignments"
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetListOfTaskAssignments(ByVal qraNumber As String) As List(Of REMI.BaseObjectModels.TaskAssignment)
            Try
                Return TestStageDB.GetTaskAssignments(qraNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New List(Of REMI.BaseObjectModels.TaskAssignment)
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.Update, False)> _
        Public Shared Function AddUpdateTaskAssignment(ByVal qraNumber As String, ByVal taskId As Integer, ByVal assignedTo As String) As Boolean
            Try
                If REMI.Bll.UserManager.UserExists(assignedTo) Then
                    Return TestStageDB.AddUpdateTaskAssignment(qraNumber, taskId, assignedTo, UserManager.GetCurrentValidUserLDAPName())
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return False
            End Try
            Return False
        End Function

        <DataObjectMethod(DataObjectMethodType.Delete, False)> _
        Public Shared Function RemoveTaskAssignment(ByVal qraNumber As String, ByVal taskId As Integer) As Boolean
            Try
                Return TestStageDB.RemoveTaskAssignment(qraNumber, taskId)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return False
            End Try
        End Function
#End Region

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetList(ByVal type As TestStageType, ByVal jobName As String) As TestStageCollection
            Try
                Return TestStageDB.GetList(type, jobName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("JobName: {0}", jobName))
                Return New TestStageCollection
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Insert], True)> _
        Public Shared Function SaveTestStage(ByVal testStage As TestStage) As Integer
            Dim currentUser As String = UserManager.GetCurrentValidUserLDAPName
            Dim returnVal As Integer
            Try
                If UserManager.GetCurrentUser.IsAdmin Then
                    Using t As New TransactionScope
                        'save the test if nessecary
                        If testStage.TestStageType = TestStageType.EnvironmentalStress Then 'does this yts need an environmental test
                            testStage.Tests.Item(0).LastUser = currentUser 'set the user for logging

                            If testStage.Tests.Item(0).Validate Then
                                testStage.Tests.Item(0).ID = TestManager.SaveTest(testStage.Tests.Item(0))
                                testStage.TestID = testStage.Tests.Item(0).ID 'set the id to the test stage for saving
                            Else
                                testStage.Notifications.Add(testStage.Tests.Item(0).Notifications) 'add any errors to the ts
                            End If
                        End If

                        testStage.LastUser = currentUser 'username for logging

                        If testStage.Validate Then
                            testStage.ID = TestStageDB.Save(testStage)
                            t.Complete() 'done finish the trans

                            testStage.Notifications.Add("i2", NotificationType.Information)
                            returnVal = testStage.ID
                        End If
                    End Using
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                End If
            Catch sqlEx As SqlClient.SqlException When sqlEx.Number = 2601
                testStage.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e5", NotificationType.Errors, sqlEx))
            Catch ex As Exception
                testStage.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex))
            End Try
            Return returnVal
        End Function

        <DataObjectMethod(DataObjectMethodType.[Delete], True)> _
        Public Shared Function DeleteTestStage(ByVal ID As Integer) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                If UserManager.GetCurrentUser.IsAdmin Then
                    If TestStageDB.Delete(ID, UserManager.GetCurrentValidUserLDAPName) > 0 Then
                        nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "i1", NotificationType.Information, String.Format("Test Stage ID: {0}", ID.ToString)))
                    End If
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex, "Test Stage ID: " + ID.ToString))
            End Try
            Return nc
        End Function
    End Class
End Namespace