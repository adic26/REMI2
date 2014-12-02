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

        Public Shared Function GetPermissions() As DataTable
            Dim dt As New DataTable("Permissions")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("aspnet_GetPermissions", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ApplicationName", "/")
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "Permissions"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetRolesPermissionsGrid() As DataTable
            Dim dt As New DataTable("PermissionsGrid")
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

        Public Shared Function GetMenuAccessByDepartment(ByVal pageName As String, ByVal departmentID As Int32) As DataTable
            Dim dt As New DataTable("MenuAccess")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispMenuAccessByDepartment", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@Name", pageName)
                    myCommand.Parameters.AddWithValue("@DepartmentID", departmentID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "MenuAccess"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetMenu() As DataTable
            Dim dt As New DataTable("Menu")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispMenu", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "Menu"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetServices() As DataTable
            Dim dt As New DataTable("Services")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetServices", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "Services"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetServicesAccess(ByVal departmentID As Int32) As DataTable
            Dim dt As New DataTable("ServicesAccess")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetServicesAccessByID", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@LookupID", departmentID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ServicesAccess"
                End Using
            End Using

            Return dt
        End Function
    End Class
End Namespace
