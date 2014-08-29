Imports System.Linq
Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class ExceptionManager
        Inherits REMIManagerBase

        Public Shared Function SaveExceptions(ByVal newList As Dictionary(Of String, Boolean), ByVal qraNumber As String, ByVal testStageName As String, ByVal testStageID As Int32) As NotificationCollection
            Dim oldVal As Boolean
            Dim newVal As Boolean
            Dim oldList As IDictionary(Of String, Boolean) = GetExceptionTable(qraNumber, testStageName, testStageID)
            Dim nc As New NotificationCollection

            Try
                For Each testName As String In newList.Keys
                    newVal = newList.Item(testName)
                    oldVal = oldList.Item(testName)
                    If newVal And Not oldVal Then
                        nc.Add(AddException(qraNumber, testName))
                    ElseIf Not newVal And oldVal Then
                        nc.Add(DeleteException(qraNumber, testName))
                    End If
                Next
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} TestStage: {1}", qraNumber, testStageName)))
            End Try
            Return nc
        End Function

        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetExceptions(ByVal qraNumber As String) As TestExceptionCollection
            Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(qraNumber))
            Try
                If bc.Validate Then
                    Return TestExceptionDB.GetExceptionsForBatch(bc.BatchNumber)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0}", qraNumber))
            End Try
            Return New TestExceptionCollection
        End Function

        Public Shared Function GetExceptionTable(ByVal qraNumber As String, ByVal testStageName As String, ByVal testStageID As Int32) As Dictionary(Of String, Boolean)
            Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(qraNumber))
            Try
                If bc.Validate Then
                    Return TestExceptionDB.GetExceptionsTableForTestUnit(bc.BatchNumber, bc.UnitNumber, testStageName, testStageID)
                Else
                    Return New Dictionary(Of String, Boolean)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} TestStage: {1}", qraNumber, testStageName))
                Return New Dictionary(Of String, Boolean)
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetExceptionsExcludingProductLevel(ByVal qraNumber As String) As TestExceptionCollection
            Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(qraNumber))
            Try
                If bc.Validate Then
                    Return TestExceptionDB.GetExceptionsForBatch(bc.BatchNumber)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0}", qraNumber))
            End Try
            Return New TestExceptionCollection
        End Function

        <DataObjectMethod(DataObjectMethodType.Delete, False)> _
        Public Shared Function DeleteException(ByVal ID As Integer) As Notification
            Try
                Dim n As New Notification
                If TestExceptionDB.DeleteException(ID, UserManager.GetCurrentValidUserLDAPName) > 0 Then
                    n.Message = "Exception deleted."
                    n.Type = NotificationType.Information
                Else
                    n.Message = "Unable to delete exception."
                    n.Type = NotificationType.Errors
                End If
                Return n
            Catch ex As Exception
                Return LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("ExceptionID: {0}", ID))
            End Try
        End Function

        Public Shared Function AddException(ByVal qraNumber As String, ByVal testName As String, Optional ByVal testStageName As String = "", Optional ByVal userIdentifciation As String = "") As Notification
            Dim nc As Notification

            Try
                Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(qraNumber))

                If bc.Validate And bc.HasTestUnitNumber Then
                    Dim tuEx As New TestException(bc.BatchNumber, bc.UnitNumber, testName, testStageName)

                    If TestExceptionDB.AddTestUnitException(tuEx, UserManager.GetUser(userIdentifciation, 0).LDAPName) Then
                        nc = New Notification
                        nc.Message = (qraNumber + " DNP " + testName + " saved ok.")
                        nc.Type = NotificationType.Information
                    Else
                        nc = New Notification
                        nc.Message = (qraNumber + " DNP " + testName + " not saved.")
                        nc.Type = NotificationType.Errors
                    End If
                Else
                    nc = New Notification
                    nc.Message = ("Invalid barcode error.")
                    nc.Type = NotificationType.Information
                End If
            Catch ex As Exception
                nc = LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} TestName: {1} TestStageName: {2}", qraNumber, testName, testStageName))
            End Try

            Return nc
        End Function

        Public Shared Function AddException(ByVal tex As TestException) As Notification
            Dim nc As Notification
            Try
                If tex.Validate Then
                    nc = New Notification
                    If TestExceptionDB.AddTestUnitException(tex, UserManager.GetCurrentValidUserLDAPName) Then
                        nc.Message = "Exception saved ok."
                        nc.Type = NotificationType.Information
                    Else
                        nc.Message = "Unable to save exception"
                        nc.Type = NotificationType.Errors
                    End If
                Else
                    nc = tex.Notifications(0)
                End If
            Catch ex As Exception
                nc = LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return nc
        End Function

        Public Shared Function DeleteException(ByVal qraNumber As String, ByVal testName As String, ByVal testStageName As String, ByVal testUnitID As Int32) As Notification
            Dim nc As Notification
            Try
                Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(qraNumber))

                If bc.Validate And bc.HasTestUnitNumber Then
                    Dim tuEx As TestException

                    If (String.IsNullOrEmpty(testStageName)) Then
                        tuEx = New TestException(bc.BatchNumber, bc.UnitNumber, testName)
                        tuEx.TestUnitID = testUnitID
                    Else
                        tuEx = New TestException(bc.BatchNumber, bc.UnitNumber, testName, testStageName)
                        tuEx.TestUnitID = testUnitID
                    End If

                    If TestExceptionDB.DeleteTestUnitException(tuEx, UserManager.GetCurrentValidUserLDAPName) Then
                        nc = New Notification
                        nc.Message = (qraNumber + " DNP " + testName + " deleted ok.")
                        nc.Type = NotificationType.Information
                    Else
                        nc = New Notification
                        nc.Message = (qraNumber + " DNP " + testName + " not deleted!")
                        nc.Type = NotificationType.Errors
                    End If
                Else
                    nc = New Notification
                    nc.Message = ("Invalid barcode error.")
                    nc.Type = NotificationType.Information
                End If
            Catch ex As Exception
                nc = LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} TestName: {1}", qraNumber, testName))
            End Try
            Return nc
        End Function

        Public Shared Function DeleteException(ByVal qraNumber As String, ByVal testName As String) As Notification
            Return DeleteException(qraNumber, testName, String.Empty, 0)
        End Function
    End Class
End Namespace