﻿Imports System.Linq
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
    Public Class CalibrationManager
        Inherits REMIManagerBase

        Public Shared Function HasCalibrationConfigurationXML(ByVal productID As Int32, ByVal hostID As Int32, ByVal testID As Int32) As Boolean
            Try
                Dim record = (From xml In New REMI.Dal.Entities().Instance().Calibrations Where xml.HostID = hostID And xml.Test.ID = testID And xml.Product.ID = productID Select xml).FirstOrDefault()
                If (record Is Nothing) Then
                    Return False
                Else
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function GetAllCalibrationConfigurationXML(ByVal productID As Int32, ByVal hostID As Int32, ByVal testID As Int32) As CalibrationCollection
            Try
                Return CalibrationDB.GetAllCalibrationConfigurationXML(productID, hostID, testID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return New CalibrationCollection
        End Function

        Public Shared Function SaveCalibrationConfigurationXML(ByVal productID As Int32, ByVal hostID As Int32, ByVal testID As Int32, ByVal name As String, ByVal xml As String) As Boolean
            Try
                Dim xmlDoc As XDocument
                xmlDoc = XDocument.Parse(xml)

                Return CalibrationDB.SaveCalibrationConfigurationXML(productID, hostID, testID, name, xmlDoc, UserManager.GetCurrentUser.UserName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

    End Class
End Namespace