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

        Public Shared Function Search(ByVal requestTypeID As Int32, ByVal SearchFields As DataTable, ByVal userID As Int32) As DataTable
            Try
                Return ReportDB.Search(requestTypeID, SearchFields, userID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("Search")
        End Function

        Public Shared Function ESResultSummary(ByVal requestNumber As String) As DataTable
            Try
                Return ReportDB.ESResultSummary(requestNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("ESResultSummary")
        End Function

        Public Shared Function SearchTree(ByVal requestTypeID As Int32) As DataTable
            Try
                Dim dt As New DataTable("SearchTree")
                dt.Columns.Add("Type", GetType(String))
                dt.Columns.Add("Name", GetType(String))
                dt.Columns.Add("ID", GetType(Int32))


                For Each dr As DataRow In RequestManager.GetRequestParent(requestTypeID, False, False).Rows
                    Dim newRQRow As DataRow = dt.NewRow
                    newRQRow("Type") = "Request"
                    newRQRow("Name") = dr("Name")
                    newRQRow("ID") = dr("ReqFieldSetupID")

                    dt.Rows.Add(newRQRow)
                Next

                For Each rec As Test In TestManager.GetTestsByType(TestType.Parametric, False)
                    Dim newTestRow As DataRow = dt.NewRow
                    newTestRow("Type") = "Test"
                    newTestRow("Name") = rec.Name
                    newTestRow("ID") = rec.ID

                    dt.Rows.Add(newTestRow)
                Next

                Return dt
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("SearchTree")
        End Function
    End Class
End Namespace