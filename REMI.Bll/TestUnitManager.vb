Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports System.Transactions

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class TestUnitManager
        Inherits REMIManagerBase

#Region "Persistance Functions"
        Public Shared Function GetUnitAssignedTo(ByVal QRANumber As String, ByVal batchUnitNumber As Int32) As String
            Try
                Dim testUnit As REMI.Entities.TestUnit = TestUnitManager.GetRAWUnitInformation(QRANumber, batchUnitNumber)

                If testUnit IsNot Nothing Then
                    Return testUnit.AssignedTo
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} BSN: {1}", QRANumber, batchUnitNumber))
            End Try
            Return Nothing
        End Function

        Public Shared Function GetUnitBSN(ByVal QRANumber As String, ByVal batchUnitNumber As Int32) As Int32
            Try
                Dim testUnitID As Int32
                Dim testUnit As REMI.Entities.TestUnit = TestUnitManager.GetRAWUnitInformation(QRANumber, batchUnitNumber)

                If testUnit IsNot Nothing Then
                    Int32.TryParse(testUnit.BSN.ToString(), testUnitID)

                    Return testUnitID
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} BSN: {1}", QRANumber, batchUnitNumber))
            End Try
            Return Nothing
        End Function

        Public Shared Function GetUnit(ByVal QRANumber As String, ByVal batchUnitNumber As Int32) As TestUnit
            Try
                Return TestUnitDB.GetUnit(QRANumber, batchUnitNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} BSN: {1}", QRANumber, batchUnitNumber))
            End Try
            Return Nothing
        End Function

        Public Shared Function GetUnitID(ByVal QRANumber As String, ByVal batchUnitNumber As Int32) As Int32
            Try
                Dim testUnit As REMI.Entities.TestUnit = TestUnitManager.GetRAWUnitInformation(QRANumber, batchUnitNumber)

                If testUnit IsNot Nothing Then
                    Return testUnit.ID
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Request: {0} BSN: {1}", QRANumber, batchUnitNumber))
            End Try
            Return Nothing
        End Function

        Public Shared Function Save(ByVal testUnit As TestUnit) As Integer
            Dim returnVal As Integer
            Try
                If testUnit.Validate Then
                    returnVal = TestUnitDB.Save(testUnit)
                End If
            Catch ex As Exception
                testUnit.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("testUnit: {0}", testUnit.ID)))
            End Try
            Return returnVal
        End Function
#End Region

#Region "Public Settings and Status Functions"
        ''' <summary>
        ''' Returns a list of test units that are currently assigned to the logged in user.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetCurrentUsersUnits() As TestUnitCollection
            Return GetUsersUnits(UserManager.GetCurrentValidUserID, False)
        End Function

        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetAvailableUnits(ByVal QRANumber As String, ByVal excludedUnitNumber As Int32) As List(Of String)
            Try
                Return TestUnitDB.GetAvailableUnits(QRANumber, excludedUnitNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return New List(Of String)
        End Function

        ''' <summary>
        ''' Returns a list of test units that are currently assigned to the logged in user.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetUsersUnits(ByVal userID As Int32, Optional ByVal includeCompletedQRA As Boolean = False) As TestUnitCollection
            Try
                Return TestUnitDB.GetUsersUnits(userID, includeCompletedQRA)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e4", NotificationType.Errors, ex)
            End Try

            Return Nothing
        End Function

        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetTestUnitsNotInREMI() As List(Of SimpleTestUnit)
            Try
                Return TestUnitDB.GetTestUnitsNotInREMSTAR()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return New List(Of SimpleTestUnit)
        End Function

        Public Shared Function DeleteUnit(ByVal testUnitID As Int32) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsTestCenterAdmin Or UserManager.GetCurrentUser.IsAdmin) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim u = (From tu In instance.TestUnits Where tu.ID = testUnitID Select tu).FirstOrDefault()
                    instance.DeleteObject(u)
                    instance.SaveChanges()

                    Return True
                Else
                    Return False
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetNumOfUnits(ByVal QRANumber As String) As Int32
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Return (From tu In instance.TestUnits Where tu.Batch.QRANumber = QRANumber Select tu).Count()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return 0
        End Function

        <DataObjectMethod(DataObjectMethodType.Select, False)> _
        Public Shared Function GetRAWUnitInformation(ByVal QRANumber As String, ByVal batchUnitNumber As Int32) As REMI.Entities.TestUnit
            Try
                Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
                If (bc.Validate) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim testUnit As REMI.Entities.TestUnit = (From tu In instance.TestUnits Where tu.Batch.QRANumber = bc.BatchNumber And tu.BatchUnitNumber = batchUnitNumber Select tu).FirstOrDefault()

                    Return testUnit
                Else
                    Return Nothing
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function
#End Region
    End Class
End Namespace