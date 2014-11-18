Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports System.Transactions
Imports REMI.Contracts

Namespace REMI.Bll
    ''' <summary> 
    ''' The TestManager class is responsible for managing <see cref=" Test">BusinessEntities.Test</see>  objects in the system. 
    ''' </summary> 
    <DataObjectAttribute()> _
    Public Class TestManager
        Inherits REMIManagerBase

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTests(ByVal trackingLocationID As Int32, ByVal jobID As Int32) As List(Of String)
            Try
                Return TestDB.GetTests(trackingLocationID, jobID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New List(Of String)
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], True)> _
        Public Shared Function GetTest(ByVal ID As Integer) As Test
            Try
                Return TestDB.GetItem(ID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("Test: {0}", ID))
                Return Nothing
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], True)> _
        Public Shared Function GetTestByName(ByVal name As String, ByVal parametricOnly As Boolean) As Test
            Try
                Return TestDB.GetItemByName(name, parametricOnly)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("Test: {0}", name))
                Return Nothing
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetEditableTests(ByVal includeArchived As Boolean, ByVal testType As String) As TestCollection
            Try
                Dim testTypeID As TestType = DirectCast(System.Enum.Parse(GetType(Contracts.TestType), testType), Contracts.TestType)
                Dim tl As TestCollection = GetTestsByType(testTypeID, includeArchived)
                Return tl
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New TestCollection
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTestsByType(ByVal Type As TestType, ByVal includeArchived As Boolean) As TestCollection
            Try
                Return TestDB.GetListByTestType(Type, -1, -1, includeArchived)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestType: {0}", Type.ToString()))
                Return New TestCollection
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTestsByBatchStage(ByVal batchID As Int32, ByVal testStage As String, ByVal removeParametrice As Boolean) As Dictionary(Of String, String)
            Try
                If (removeParametrice And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                    Return (From t In New REMI.Dal.Entities().Instance().vw_GetTaskInfo Where t.BatchID = batchID And t.IsArchived = False And t.TestIsArchived = False And (t.teststagetype = 2 Or t.teststagetype = 3 Or t.teststagetype = 4 Or t.teststagetype = 5 Or t.TestID = 1280 Or t.TestID = 1073) And t.tsname = testStage And t.processorder > -1 Select t).OrderBy(Function(o) o.tname).ToDictionary(Function(k) k.TestID.ToString(), Function(v) v.tname)
                Else
                    Return (From t In New REMI.Dal.Entities().Instance().vw_GetTaskInfo Where t.BatchID = batchID And t.IsArchived = False And t.TestIsArchived = False And t.tsname = testStage And t.processorder > -1 Select t).OrderBy(Function(o) o.tname).ToDictionary(Function(k) k.TestID.ToString(), Function(v) v.tname)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestStage: {0} BatchID: {1}", testStage, batchID))
                Return New Dictionary(Of String, String)
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTestsByBatch(ByVal batchID As Int32) As DataTable
            Try
                Dim var = (From t In New REMI.Dal.Entities().Instance().vw_GetTaskInfo Where t.BatchID = batchID And t.IsArchived = False And t.TestIsArchived = False And t.processorder > -1 Select t.TestID, t.tname, t.testtype).Distinct().ToList()
                Dim dt As New DataTable("TestsByBatch")    
                dt.Columns.Add("TestID", System.Type.GetType("System.Int32"))
                dt.Columns.Add("tname", System.Type.GetType("System.String"))
                dt.Columns.Add("testtype", System.Type.GetType("System.Int32"))

                var.ForEach(Function(p) dt.Rows.Add(p.TestID, p.tname, p.testtype))

                Return dt
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("BatchID: {0}", batchID))
                Return New DataTable("TestsByBatch")
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Insert], True)> _
        Public Shared Function SaveTest(ByVal test As Test) As Integer
            Try
                If UserManager.GetCurrentUser.IsAdmin Then
                    test.LastUser = UserManager.GetCurrentValidUserLDAPName
                    If test.Validate Then
                        Using t As New TransactionScope 'transactioned for test types
                            test.ID = TestDB.Save(test)
                            SaveApplicableTLTypes(test.TrackingLocationTypes, test.ID)
                            t.Complete()
                        End Using
                        test.Notifications.Add("i2", NotificationType.Information)
                        Return test.ID
                    End If
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                End If
            Catch sqlEx As SqlClient.SqlException When sqlEx.Number = 2601
                test.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e5", NotificationType.Errors, sqlEx, String.Format("test: {0}", test.ID)))
            Catch ex As Exception
                test.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("test: {0}", test.ID)))
            End Try
            Return 0
        End Function

        Public Shared Function SaveApplicableTLTypes(ByVal newList As TrackingLocationTypeCollection, ByVal testID As Integer) As NotificationCollection
            Dim oldList As TrackingLocationTypeCollection = TestDB.GetApplicableTLTypes(testID)
            Dim nc As New NotificationCollection
            Dim tmpName As String = String.Empty

            Try
                If UserManager.GetCurrentUser.IsAdmin Then
                    For Each tlType As TrackingLocationType In newList 'add new ones
                        Dim tlt As TrackingLocationType = (From otlt In oldList Where otlt.ID = tlType.ID And otlt.Name = tlType.Name Select otlt).FirstOrDefault()

                        If (tlt Is Nothing) Then
                            TestDB.AddApplicableTrackingLocationType(testID, tlType)
                        End If
                    Next

                    For Each tltype As TrackingLocationType In oldList
                        Dim tlt As TrackingLocationType = (From ntlt In newList Where ntlt.ID = tltype.ID And ntlt.Name = tltype.Name Select ntlt).FirstOrDefault()

                        If (tlt Is Nothing) Then
                            TestDB.DeleteApplicableTrackingLocationType(testID, tltype)
                        End If
                    Next
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("TestID: {0}", testID)))
            End Try

            Return nc
        End Function

        <DataObjectMethod(DataObjectMethodType.[Delete], True)> _
        Public Shared Function DeleteTest(ByVal ID As Integer) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                If UserManager.GetCurrentUser.IsAdmin Then
                    If TestDB.Delete(ID, UserManager.GetCurrentValidUserLDAPName) > 0 Then
                        nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "i1", NotificationType.Information))
                    End If
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex, String.Format("TestID: {0}", ID)))
            End Try
            Return nc
        End Function
    End Class
End Namespace