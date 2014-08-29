Imports System.ComponentModel
Imports REMI.Validation
Imports REMI.Dal

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class VersionManager
        Inherits REMIManagerBase

        Public Shared Function GetProductConfigXMLByAppVersion(ByVal application As String, ByVal versionNumber As String, ByVal productID As Int32, ByVal testID As Int32, ByVal pcName As String) As Int32
            Dim instance = New REMI.Dal.Entities().Instance()
            Dim tstId As Int32 = (From t In instance.Tests Where t.TestName = application Select t.ID).FirstOrDefault()

            If (tstId > 0) Then
                Dim appID As Int32 = (From a In instance.Applications Where a.ApplicationName = application Select a.ID).FirstOrDefault()
                Dim appVersion As Int32 = (From a In instance.ApplicationVersions Where a.Application.ID = appID And a.VerNum = versionNumber Select a.ID).FirstOrDefault()

                If (appVersion = 0) Then
                    appVersion = (From a In instance.ApplicationVersions Where a.Application.ID = appID And a.ApplicableToAll = True Order By a.ID Descending Select a.ID).FirstOrDefault()
                End If

                Dim pvs As Int32 = (From pv In instance.ApplicationProductVersions Where pv.ApplicationVersion.ID = appVersion And pv.ProductConfigurationVersion.ProductConfigurationUpload.PCName = pcName Select pv.ProductConfigurationVersion.ID).FirstOrDefault()

                Return pvs
            Else
                Return -1
            End If
        End Function

        Public Shared Function SaveVersion(ByVal id As Int32, ByVal versionNumber As String, ByVal applicableToAll As Int32) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim app = (From a In instance.ApplicationVersions Where a.Application.ID = id And a.VerNum = versionNumber).FirstOrDefault()

                If (applicableToAll = 1) Then
                    app.ApplicableToAll = True
                Else
                    app.ApplicableToAll = False
                End If

                instance.SaveChanges()

                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
                Return False
            End Try
        End Function

        Public Shared Function SaveVersionProductLink(ByVal apvID As Int32, ByVal pcvID As Int32, ByVal avID As Int32) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()

                If (apvID = 0) Then
                    Dim apv As New REMI.Entities.ApplicationProductVersion()
                    apv.ProductConfigurationVersion = (From pv In instance.ProductConfigurationVersions Where pv.ID = pcvID).FirstOrDefault()
                    apv.ApplicationVersion = (From av In instance.ApplicationVersions Where av.ID = avID).FirstOrDefault()
                    instance.AddToApplicationProductVersions(apv)
                ElseIf (apvID > 0 And avID > 0) Then

                    Dim app2 = (From a In instance.ApplicationProductVersions Where a.ID = apvID).FirstOrDefault()
                    app2.ProductConfigurationVersion = (From pv In instance.ProductConfigurationVersions Where pv.ID = pcvID).FirstOrDefault()
                End If

                instance.SaveChanges()
                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
                Return False
            End Try
        End Function

        Public Shared Function CheckVersion(ByVal ApplicationName As String, ByVal VersionNumber As String) As Int32
            Try
                Dim version As DataTable = VersionDB.GetVersions(ApplicationName)

                Return DoUpdate(VersionNumber, version)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return 0
        End Function

        Public Shared Function remispVersionProductLink(ByVal ApplicationName As String, ByVal pcNameID As Int32) As DataTable
            Try
                Return VersionDB.remispVersionProductLink(ApplicationName, pcNameID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return New DataTable()
        End Function

        Private Shared Function DoUpdate(ByVal versionNumber As String, ByVal availableVersions As DataTable) As Int32
            Dim result As Integer = 0
            Dim major As Int32
            Dim minor As Int32
            Dim build As Int32
            Dim revision As Int32

            Int32.TryParse(availableVersions.Rows(0).Item("major").ToString(), major)
            Int32.TryParse(availableVersions.Rows(0).Item("minor").ToString(), minor)
            Int32.TryParse(availableVersions.Rows(0).Item("build").ToString(), build)
            Int32.TryParse(availableVersions.Rows(0).Item("revision").ToString(), revision)

            Dim v As New Version(major, minor, build, revision)
            result = New Version(versionNumber).CompareTo(v)

            Return CInt(IIf(result < 0, 1, 0))
        End Function
    End Class
End Namespace
