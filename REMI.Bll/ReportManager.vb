Imports System.Linq
Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class ReportManager
        Inherits REMIManagerBase

        Public Shared Function GetKPI(ByVal type As Int32, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal testCenterID As Int32) As DataTable
            Try
                Return ReportDB.GetKPI(type, startDate, endDate, testCenterID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable
        End Function
    End Class
End Namespace