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
                Dim config As REMI.Entities.Configuration = (From c In instance.Configurations Where c.Name = Name And c.ModeID = mode And c.ConfigTypeID = type And c.Version = version.ToString() Select c).FirstOrDefault()
                
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
                Dim config As REMI.Entities.Configuration = (From c In instance.Configurations Where c.Name = Name And c.ModeID = mode And c.ConfigTypeID = type And c.Version = version.ToString() Select c).FirstOrDefault()

                If (config Is Nothing) Then
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
    End Class
End Namespace