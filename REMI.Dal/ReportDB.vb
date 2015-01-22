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

        Public Shared Function Search(ByVal requestTypeID As Int32, ByVal SearchFields As DataTable) As DataTable
            Dim dt As New DataTable("Search")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Req.RequestSearch", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@RequestTypeID", requestTypeID)

                    Dim parameter As SqlParameter
                    parameter = myCommand.Parameters.AddWithValue("@tv", SearchFields)
                    parameter.SqlDbType = SqlDbType.Structured
                    parameter.TypeName = "dbo.SearchFields"

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "Search"
                End Using
            End Using

            Return dt
        End Function
    End Class
End Namespace