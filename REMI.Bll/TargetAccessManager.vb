Imports REMI.Dal
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports System.Web
Imports System.Transactions
Imports REMI.Contracts

Namespace REMI.Bll
    Public Class TargetAccessManager
        Inherits REMIManagerBase

        Public Shared Function GetAllAccessByWorkstation(ByVal workstationName As String, ByVal getGlobalAccess As Boolean) As List(Of String)
            Dim taList As New List(Of String)

            Try
                taList = (From t In New REMI.Dal.Entities().Instance().TargetAccesses Where t.WorkstationName = workstationName Or (getGlobalAccess = True) Select t.TargetName).Distinct.ToList
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return taList
        End Function

        Public Shared Function HasAccess(ByVal targetAccess As String, ByVal workstationName As String) As Boolean
            Dim turnedOn As List(Of Boolean)
            Try
                turnedOn = (From t In New REMI.Dal.Entities().Instance().TargetAccesses Where t.TargetName = targetAccess And (t.WorkstationName = workstationName Or t.WorkstationName Is Nothing) Select t.DenyAccess).ToList()

                If (turnedOn.Contains(True)) Then
                    Return False
                Else
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
                Return False
            End Try
        End Function

        Public Shared Function ChangeAccess(ByVal targetAccessID As Int32, ByVal hasAccess As Boolean) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim t = (From ta In instance.TargetAccesses Where ta.ID = targetAccessID Select ta).FirstOrDefault()

                    t.DenyAccess = hasAccess
                    instance.SaveChanges()

                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function DeleteTargetAccess(ByVal targetAccessID As Int32) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin) Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim t = (From ta In instance.TargetAccesses Where ta.ID = targetAccessID Select ta).FirstOrDefault()
                    instance.DeleteObject(t)
                    instance.SaveChanges()

                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function AddTargetAccess(ByVal targetName As String, ByVal workstationName As String, ByVal denyAccess As Boolean) As Boolean
            Try
                If (UserManager.GetCurrentUser.IsAdmin) Then
                    Dim instance = New REMI.Dal.Entities().Instance()

                    Dim t = (From ta In instance.TargetAccesses Where ta.WorkstationName = workstationName And ta.TargetName = targetName Select ta).FirstOrDefault()

                    If (t Is Nothing) Then
                        Dim ta As New REMI.Entities.TargetAccess()
                        ta.DenyAccess = denyAccess
                        ta.TargetName = targetName
                        ta.WorkstationName = workstationName
                        instance.AddToTargetAccesses(ta)
                    Else
                        t.DenyAccess = denyAccess
                    End If

                    instance.SaveChanges()
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function
    End Class
End Namespace