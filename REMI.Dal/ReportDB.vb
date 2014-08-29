Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core
Imports System.Reflection

Namespace REMI.Dal
    Public Class ReportDB

        Public Shared Function GetKPI(ByVal type As Int32, ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal testCenterID As Int32) As DataTable
            Dim dt As New DataTable()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispKPIReports", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@StartDate", startDate)
                    myCommand.Parameters.AddWithValue("@EndDate", endDate)
                    myCommand.Parameters.AddWithValue("@Type", type)
                    myCommand.Parameters.AddWithValue("@TestCenterID", testCenterID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "KPIReport"
                End Using
            End Using

            If (type = 1) Then
                Dim r As DataRow = dt.NewRow
                r.Item("QRANumber") = "Summary"
                r.Item("JobName") = String.Empty
                r.Item("LostMinutes") = dt.AsEnumerable().Sum(Function(dr) dr.Field(Of Double)("LostMinutes"))

                dt.Rows.Add(r)
            End If

            Return dt
        End Function
    End Class
End Namespace