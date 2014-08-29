Imports System.Data.SqlClient
Imports REMI.Core

Namespace REMI.Dal
    Public Class VersionDB
        Public Shared Function GetVersions(ByVal application As String) As DataTable
            Dim result As New DataTable
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispCheckVersion", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@application", application)
                    MyConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(result)
                    result.TableName = "Versions"
                End Using
            End Using
            Return result
        End Function

        Public Shared Function remispVersionProductLink(ByVal ApplicationName As String, ByVal pcNameID As Int32) As DataTable
            Dim result As New DataTable
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispVersionProductLink", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@application", ApplicationName)
                    myCommand.Parameters.AddWithValue("@PCNameID", pcNameID)
                    MyConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(result)
                    result.TableName = "VersionsProduct"
                End Using
            End Using
            Return result
        End Function
    End Class
End Namespace