Imports System.Linq
Imports System.Security
Imports System.Security.Permissions
Imports System.Transactions
Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class SecurityManager
        Inherits REMIManagerBase

        Public Shared Function AddRemovePermission(ByVal permission As String, ByVal role As String) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin) Then
                    Return SecurityDB.AddRemovePermission(permission, role)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function GetMenuAccessByDepartment(ByVal name As String, ByVal departmentID As Int32) As DataTable
            Try
                Return SecurityDB.GetMenuAccessByDepartment(name, departmentID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("MenuAccess")
        End Function

        Public Shared Function GetRolesPermissionsGrid() As DataTable
            Try
                Return SecurityDB.GetRolesPermissionsGrid()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("PermissionsGrid")
        End Function

        Public Shared Function RemoveRole(ByVal roleName As String) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim role = (From r In instance.aspnet_Roles Where r.RoleName = roleName Select r).FirstOrDefault()
                    instance.DeleteObject(role)
                    instance.SaveChanges()

                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function RemoveRole(ByVal roleName As String) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim role = (From r In instance.aspnet_Roles Where r.RoleName = roleName Select r).FirstOrDefault()
                    instance.DeleteObject(role)
                    instance.SaveChanges()

                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function AddNewRole(ByVal roleName As String) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim role As New REMI.Entities.aspnet_Roles()
                    role.aspnet_Applications = (From app In instance.aspnet_Applications Select app).FirstOrDefault()
                    role.LoweredRoleName = roleName.ToLower()
                    role.RoleName = roleName
                    role.RoleId = Guid.NewGuid()
                    instance.AddToaspnet_Roles(role)
                    instance.SaveChanges()
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function
    End Class
End Namespace