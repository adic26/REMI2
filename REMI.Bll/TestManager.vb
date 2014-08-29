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
        Public Shared Function GetTestsByBatchStage(ByVal batchID As Int32, ByVal testStage As String, ByVal removeParametrice As Boolean) As Object
            Try
                If (removeParametrice And Not (UserManager.GetCurrentUser.IsAdmin)) Then
                    Return (From t In New REMI.Dal.Entities().Instance().vw_GetTaskInfo Where t.BatchID = batchID And t.IsArchived = False And t.TestIsArchived = False And (t.teststagetype = 2 Or t.teststagetype = 3 Or t.teststagetype = 4 Or t.teststagetype = 5 Or t.TestID = 1280 Or t.TestID = 1073) And t.tsname = testStage And t.processorder > -1 Select t.tname, t.TestID Distinct Order By tname).ToList()
                Else
                    Return (From t In New REMI.Dal.Entities().Instance().vw_GetTaskInfo Where t.BatchID = batchID And t.IsArchived = False And t.TestIsArchived = False And t.tsname = testStage And t.processorder > -1 Select t.tname, t.TestID Distinct Order By tname).ToList()
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestStage: {0} BatchID: {1}", testStage, batchID))
                Return New List(Of String)
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

        Public Shared Function SaveApplicableTLTypes(ByVal newList As SerializableDictionary(Of Integer, String), ByVal testID As Integer) As NotificationCollection
            Dim oldList As SerializableDictionary(Of Integer, String) = TestDB.GetApplicableTLTypes(testID)
            Dim nc As New NotificationCollection
            Dim tmpName As String = String.Empty

            Try
                If UserManager.GetCurrentUser.IsAdmin Then
                    For Each tlTypeID As Integer In newList.Keys 'add new ones
                        If Not oldList.ContainsKey(tlTypeID) Then
                            TestDB.AddApplicableTrackingLocationType(testID, tlTypeID)
                        End If
                    Next
                    For Each tltypeID As Integer In oldList.Keys
                        If Not newList.TryGetValue(tltypeID, tmpName) Then 'delete old ones
                            TestDB.DeleteApplicableTrackingLocationType(testID, tltypeID)
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