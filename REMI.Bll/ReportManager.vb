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

        Public Shared Function Search(ByVal requestTypeID As Int32, ByVal SearchFields As DataTable) As DataTable
            Try
                Return ReportDB.Search(requestTypeID, SearchFields)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("Search")
        End Function

        Public Shared Function SearchTree(ByVal requestTypeID As Int32) As DataTable
            Try
                Dim dt As New DataTable("SearchTree")
                dt.Columns.Add("Type", GetType(String))
                dt.Columns.Add("Name", GetType(String))
                dt.Columns.Add("ID", GetType(Int32))


                For Each dr As DataRow In RequestManager.GetRequestParent(requestTypeID).Rows
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

                For Each rec As TestStage In TestStageManager.GetAllTestStages()
                    Dim newStageRow As DataRow = dt.NewRow
                    newStageRow("Type") = "Stage"
                    newStageRow("Name") = String.Format("{0}: {1}", rec.JobName, rec.Name)
                    newStageRow("ID") = rec.ID

                    dt.Rows.Add(newStageRow)
                Next

                Dim newtRow As DataRow = dt.NewRow
                newtRow("Type") = "Unit"
                newtRow("Name") = "Enter Unit"
                newtRow("ID") = 0
                dt.Rows.Add(newtRow)

                newtRow = dt.NewRow
                newtRow("Type") = "BSN"
                newtRow("Name") = "Enter BSN"
                newtRow("ID") = 0
                dt.Rows.Add(newtRow)

                newtRow = dt.NewRow
                newtRow("Type") = "IMEI"
                newtRow("Name") = "Enter IMEI"
                newtRow("ID") = 0
                dt.Rows.Add(newtRow)

                newtRow = dt.NewRow
                newtRow("Type") = "ResultArchived"
                newtRow("Name") = "Display Archived Results"
                newtRow("ID") = 0
                dt.Rows.Add(newtRow)

                newtRow = dt.NewRow
                newtRow("Type") = "ResultInfoArchived"
                newtRow("Name") = "Display Archived Information"
                newtRow("ID") = 0
                dt.Rows.Add(newtRow)

                newtRow = dt.NewRow
                newtRow("Type") = "TestRunStartDate"
                newtRow("Name") = "Select Start Date"
                newtRow("ID") = 0
                dt.Rows.Add(newtRow)

                newtRow = dt.NewRow
                newtRow("Type") = "TestRunEndDate"
                newtRow("Name") = "Select End Date"
                newtRow("ID") = 0
                dt.Rows.Add(newtRow)

                newtRow = dt.NewRow
                newtRow("Type") = "Measurement"
                newtRow("Name") = "Enter Measurement"
                newtRow("ID") = 0
                dt.Rows.Add(newtRow)

                Return dt
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("SearchTree")
        End Function
    End Class
End Namespace