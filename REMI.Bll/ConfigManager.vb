Imports System.Linq
Imports System.Transactions
Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class ConfigManager
        Inherits REMIManagerBase

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetConfig(ByVal Name As String, ByVal version As Version, ByVal mode As Int32, ByVal type As Int32) As String
            Dim xml As String = String.Empty

            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim ver As String = version.ToString()
                Dim config As REMI.Entities.Configuration = (From c In instance.Configurations Where c.Name = Name And c.ModeID = mode And c.ConfigTypeID = type And c.Version = ver Select c).FirstOrDefault()
                
                If (config IsNot Nothing) Then
                    xml = config.Definition
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return xml
        End Function

        Public Shared Function SaveConfig(ByVal Name As String, ByVal version As Version, ByVal mode As Int32, ByVal type As Int32, ByVal definition As String) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim ver As String = version.ToString()
                Dim config As REMI.Entities.Configuration = (From c In instance.Configurations Where c.Name = Name And c.ModeID = mode And c.ConfigTypeID = type And c.Version = ver Select c).FirstOrDefault()

                If (config Is Nothing And mode > 0 And type > 0) Then
                    config = New REMI.Entities.Configuration
                    config.Definition = definition
                    config.Name = Name
                    config.ModeID = mode
                    config.ConfigTypeID = type
                    config.Version = version.ToString()

                    instance.AddToConfigurations(config)
                Else
                    config.Definition = definition
                End If

                instance.SaveChanges()

                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function DuplicateConfigMode(ByVal Name As String, ByVal version As Version, ByVal fromMode As Int32, ByVal type As Int32, ByVal toMode As Int32) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim ver As String = version.ToString()
                Dim config As REMI.Entities.Configuration = (From c In instance.Configurations Where c.Name = Name And c.ModeID = fromMode And c.ConfigTypeID = type And c.Version = ver Select c).FirstOrDefault()

                If (config IsNot Nothing And toMode > 0) Then
                    Dim newConfig = New REMI.Entities.Configuration
                    newConfig.Definition = config.Definition
                    newConfig.Name = config.Name
                    newConfig.ModeID = toMode
                    newConfig.ConfigTypeID = config.ConfigTypeID
                    newConfig.Version = config.Version

                    instance.AddToConfigurations(newConfig)
                    instance.SaveChanges()

                    Return True
                Else
                    Return False
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function DuplicateConfigVersion(ByVal Name As String, ByVal fromVersion As Version, ByVal mode As Int32, ByVal type As Int32, ByVal toVersion As Version) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim fromVer As String = fromVersion.ToString()
                Dim toVer As String = toVersion.ToString()
                Dim config As REMI.Entities.Configuration = (From c In instance.Configurations Where c.Name = Name And c.ModeID = mode And c.ConfigTypeID = type And c.Version = fromVer Select c).FirstOrDefault()

                If (config IsNot Nothing And Not String.IsNullOrEmpty(toVer)) Then
                    Dim newConfig = New REMI.Entities.Configuration
                    newConfig.Definition = config.Definition
                    newConfig.Name = config.Name
                    newConfig.ModeID = config.ModeID
                    newConfig.ConfigTypeID = config.ConfigTypeID
                    newConfig.Version = toVer

                    instance.AddToConfigurations(newConfig)
                    instance.SaveChanges()

                    Return True
                Else
                    Return False
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
        End Function
    End Class
End Namespace