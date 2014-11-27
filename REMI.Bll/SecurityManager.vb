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

#Region "Roles/Permission"
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

        Public Shared Function GetRolesPermissionsGrid() As DataTable
            Try
                Return SecurityDB.GetRolesPermissionsGrid()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("PermissionsGrid")
        End Function

        Public Shared Function GetPermissions() As DataTable
            Try
                Return SecurityDB.GetPermissions()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("Permissions")
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

        Public Shared Function AddNewRole(ByVal roleName As String, ByVal permissionID As String) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim r As REMI.Entities.aspnet_Roles = (From role In instance.aspnet_Roles Where role.RoleName = roleName Select role).FirstOrDefault()

                    If (r Is Nothing) Then
                        Dim roleID As Guid = Guid.NewGuid()
                        Dim role As New REMI.Entities.aspnet_Roles()
                        role.aspnet_Applications = (From app In instance.aspnet_Applications Select app).FirstOrDefault()
                        role.LoweredRoleName = roleName.ToLower()
                        role.RoleName = roleName
                        role.RoleId = roleID

                        Dim permID As Guid
                        Guid.TryParse(permissionID, permID)

                        role.aspnet_Permissions.Add((From p In instance.aspnet_Permissions Where p.PermissionID = permID Select p).FirstOrDefault())

                        instance.AddToaspnet_Roles(role)
                        instance.SaveChanges()
                    End If

                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function
#End Region

#Region "Menu"
        Public Shared Function GetMenuAccessByDepartment(ByVal pageName As String, ByVal departmentID As Int32) As DataTable
            Try
                Return SecurityDB.GetMenuAccessByDepartment(pageName, departmentID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("MenuAccess")
        End Function

        Public Shared Function GetMenu() As DataTable
            Try
                Return SecurityDB.GetMenu()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("Menu")
        End Function

        Public Shared Function AddMenuAccess(ByVal menuID As Int32, ByVal departmentID As Int32) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin And menuID > 0) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim md As REMI.Entities.MenuDepartment = (From a In instance.MenuDepartments Where a.MenuID = menuID And a.DepartmentID = departmentID Select a).FirstOrDefault()

                    If (md Is Nothing) Then
                        Dim newAccess As New REMI.Entities.MenuDepartment()
                        newAccess.Menu = (From em In instance.Menus Where em.MenuID = menuID Select em).FirstOrDefault()
                        newAccess.DepartmentID = departmentID

                        instance.AddToMenuDepartments(newAccess)
                    End If

                    instance.SaveChanges()
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function EditMenu(ByVal menuID As Int32, ByVal pageName As String, ByVal url As String) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin And menuID > 0) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim m As REMI.Entities.Menu = (From r In instance.Menus Where r.MenuID = menuID Select r).FirstOrDefault()

                    If (m IsNot Nothing) Then
                        m.Name = pageName
                        m.Url = url
                    End If

                    instance.SaveChanges()
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function DeleteMenuAccess(ByVal menuDepartmentID As Int32) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin And menuDepartmentID > 0) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim md As REMI.Entities.MenuDepartment = (From a In instance.MenuDepartments Where a.MenuDepartmentID = menuDepartmentID Select a).FirstOrDefault()

                    If (md IsNot Nothing) Then
                        instance.DeleteObject(md)
                    End If

                    instance.SaveChanges()
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function
#End Region

#Region "Service"
        Public Shared Function GetServices() As DataTable
            Try
                Return SecurityDB.GetServices()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("Services")
        End Function

        Public Shared Function GetServicesAccess(ByVal departmentID As Int32) As DataTable
            Try
                Return SecurityDB.GetServicesAccess(departmentID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ServicesAccess")
        End Function

        Public Shared Function AddNewService(ByVal serviceName As String) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin And serviceName.Trim().Length > 0) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim s As REMI.Entities.Service = (From ser In instance.Services Where ser.ServiceName = serviceName Select ser).FirstOrDefault()

                    If (s Is Nothing) Then
                        Dim newService As New REMI.Entities.Service()
                        newService.ServiceName = serviceName
                        newService.IsActive = True

                        instance.AddToServices(newService)
                    End If

                    instance.SaveChanges()
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function AddServiceAccess(ByVal departmentID As Int32, ByVal serviceID As Int32) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin And serviceID > 0) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim sa As REMI.Entities.ServicesAccess = (From a In instance.ServicesAccesses Where a.ServiceID = serviceID And a.LookupID = departmentID Select a).FirstOrDefault()

                    If (sa Is Nothing) Then
                        Dim newAccess As New REMI.Entities.ServicesAccess()
                        newAccess.Service = (From s In instance.Services Where s.ServiceID = serviceID Select s).FirstOrDefault()
                        newAccess.LookupID = departmentID

                        instance.AddToServicesAccesses(newAccess)
                    End If

                    instance.SaveChanges()
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function EditService(ByVal serviceID As Int32, ByVal serviceName As String, ByVal isactive As Boolean) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin And serviceID > 0) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim s As REMI.Entities.Service = (From ser In instance.Services Where ser.ServiceID = serviceID Select ser).FirstOrDefault()

                    If (s IsNot Nothing) Then
                        s.ServiceName = serviceName
                        s.IsActive = isactive
                    End If

                    instance.SaveChanges()
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function DeleteServiceAccess(ByVal serviceAccessID As Int32) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin And serviceAccessID > 0) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim sa As REMI.Entities.ServicesAccess = (From a In instance.ServicesAccesses Where a.ServiceAccessID = serviceAccessID Select a).FirstOrDefault()

                    If (sa IsNot Nothing) Then
                        instance.DeleteObject(sa)
                    End If

                    instance.SaveChanges()
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function
#End Region
    End Class
End Namespace