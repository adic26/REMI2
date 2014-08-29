Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports System.Configuration
Imports System.Text.RegularExpressions
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core
Imports System.Reflection

Namespace REMI.Dal
    Public Class SecurityDB

        Public Shared Function AddRemovePermission(ByVal permission As String, ByVal role As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispAddRemovePermissiontoRole", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@Permission", permission)
                    myCommand.Parameters.AddWithValue("@Role", role)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function GetRolesPermissionsGrid() As DataTable
            Dim dt As New DataTable()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispRolePermissions", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "PermissionsGrid"
                End Using
            End Using

            Return dt
        End Function
    End Class
End Namespace
