Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.Transactions
Imports System.ComponentModel
Namespace REMI.Bll
    ''' <summary>
    ''' The tracking location manager will handle the creation and population of physical locations in the remi system.
    ''' </summary>
    ''' <remarks></remarks>
    <DataObjectAttribute()> _
    Public Class TrackingLocationManager
        Inherits REMIManagerBase

#Region "User Permissions"
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetUserPermissionList(ByVal username As String) As TrackingLocationTypePermissionCollection
            Try
                Return TrackingLocationTypeDB.GetUserPermissionList(username)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New TrackingLocationTypePermissionCollection(username)
        End Function

        <DataObjectMethod(DataObjectMethodType.[Insert], False)> _
        Public Shared Function SaveUserPermissions(ByVal userPermissions As TrackingLocationTypePermissionCollection) As Boolean
            Try
                If UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                    'get the old collection
                    Dim oldCollection As TrackingLocationTypePermissionCollection = GetUserPermissionList(userPermissions.Username)
                    Dim modifiedCollection As New TrackingLocationTypePermissionCollection(userPermissions.Username)
                    'compare each item in the old collection with the new collection
                    For Each singlePermission In oldCollection
                        'if the currentPermissions don't match then add this permission
                        'to the modified collection.

                        Dim trackingLocationTypeID As Int32 = singlePermission.TrackingLocationTypeID
                        Dim equivelantNewPermission As TrackingLocationTypePermission = (From up In userPermissions Where up.TrackingLocationTypeID = trackingLocationTypeID Select up).FirstOrDefault

                        If equivelantNewPermission IsNot Nothing AndAlso equivelantNewPermission.CurrentPermissions <> singlePermission.CurrentPermissions Then
                            singlePermission.CurrentPermissions = equivelantNewPermission.CurrentPermissions
                            modifiedCollection.Add(singlePermission)
                        End If
                    Next

                    'save the modified collection
                    TrackingLocationTypeDB.SavePermissions(modifiedCollection, UserManager.GetCurrentValidUserLDAPName)
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e4", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetUserPermission(ByVal username As String, ByVal hostname As String, ByVal trackingLocationName As String) As Integer
            Try
                Return TrackingLocationTypeDB.GetUserPermission(username, hostname, trackingLocationName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return 1
        End Function
#End Region

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetList(Optional ByVal TestCenterLocationID As Int32 = 0, Optional ByVal onlyActive As Int32 = 0) As TrackingLocationCollection
            Dim sCriteria As New TrackingLocationCriteria
            sCriteria.GeoLocationID = TestCenterLocationID

            Try
                Return TrackingLocationDB.SearchFor(sCriteria, onlyActive)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New TrackingLocationCollection
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetLocationsWithoutHost(Optional ByVal TestCenterLocationID As Int32 = 0, Optional ByVal onlyActive As Int32 = 0) As TrackingLocationCollection
            Dim sCriteria As New TrackingLocationCriteria
            sCriteria.GeoLocationID = TestCenterLocationID

            Try
                Return TrackingLocationDB.SearchFor(sCriteria, onlyActive, 1)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New TrackingLocationCollection
            End Try
        End Function

        Public Shared Function GetSpecificLocationForCurrentUsersTestCenter(ByVal StationName As String, ByVal lastUser As String) As Integer
            Try
                Return TrackingLocationDB.GetSpecificLocationForUsersTestCenter(StationName, lastUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e4", NotificationType.Errors, ex)
            End Try
            Return 0
        End Function

        Public Shared Function GetTrackingLocationID(ByVal trackingLocationName As String, ByVal testCenterID As Int32) As Int32
            Try
                Return TrackingLocationDB.GetTrackingLocationID(trackingLocationName, testCenterID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return 0
            End Try
        End Function

        Public Shared Function GetHostID(ByVal computerName As String, ByVal trackingLocationID As Int32) As Int32
            Try
                Return TrackingLocationDB.GetHostID(computerName, trackingLocationID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return 0
            End Try
        End Function

        Public Shared Function CheckStatus(ByVal hostName As String) As TrackingLocationStatus
            Dim _status As TrackingLocationStatus
            If _status <> TrackingLocationStatus.UnderMaintenance Then
                If Not String.IsNullOrEmpty(hostName) Then
                    Dim tmpP As New System.Net.NetworkInformation.Ping
                    Try
                        Dim host As System.Net.IPHostEntry = System.Net.Dns.GetHostEntry(hostName.Trim())
                        Dim ip As System.Net.IPAddress() = host.AddressList
                        Dim tmpReply As System.Net.NetworkInformation.PingReply = tmpP.Send(ip(0), 50)

                        If tmpReply.Status = Net.NetworkInformation.IPStatus.Success Then
                            _status = TrackingLocationStatus.Available
                        Else
                            _status = TrackingLocationStatus.UnAvailable
                        End If
                    Catch
                        _status = TrackingLocationStatus.UnAvailable
                    End Try
                Else
                    _status = TrackingLocationStatus.Unknown
                End If
            End If
            Return _status
        End Function

        <DataObjectMethod(DataObjectMethodType.[Delete], False)> _
        Public Shared Function DeletePlugin(ByVal ID As Integer) As NotificationCollection
            Dim nc As New NotificationCollection

            Try
                If UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim plugin = (From tlp In instance.TrackingLocationsPlugins Where tlp.ID = ID Select tlp).FirstOrDefault()
                    instance.DeleteObject(plugin)
                    instance.SaveChanges()

                    nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "i1", NotificationType.Information))
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to delete a plugin.")
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex, String.Format("Plugin ID: {0}", ID)))
            End Try

            Return nc
        End Function

        <DataObjectMethod(DataObjectMethodType.[Delete], False)> _
        Public Shared Function DeleteHost(ByVal ID As Integer, ByVal HostName As String) As NotificationCollection
            Dim nc As New NotificationCollection

            Try
                If UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                    If TrackingLocationDB.DeleteHost(ID, HostName, UserManager.GetCurrentValidUserLDAPName) > 0 Then
                        nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "i1", NotificationType.Information))
                    End If
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to delete a host.")
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex, String.Format("TrackingLocationID: {0} Host: {1}", ID, HostName)))
            End Try

            Return nc
        End Function

        <DataObjectMethod(DataObjectMethodType.[Delete], False)> _
        Public Shared Function Delete(ByVal ID As Integer) As NotificationCollection
            Dim nc As New NotificationCollection

            Try
                If UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                    If TrackingLocationDB.Delete(ID, UserManager.GetCurrentValidUserLDAPName) > 0 Then
                        nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "i1", NotificationType.Information))
                    End If
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex, String.Format("TrackingLocationID: {0}", ID)))
            End Try

            Return nc
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTrackingLocationHostsByID(ByVal ID As Integer) As TrackingLocationCollection
            Try
                Dim tlc As New TrackingLocationCriteria
                tlc.ID = ID
                Return GetTrackingLocationHosts(tlc)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TrackingLocationID: {0}", ID))
            End Try
            Return Nothing
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTrackingLocationByID(ByVal ID As Integer) As TrackingLocation
            Try
                Dim tlc As New TrackingLocationCriteria
                tlc.ID = ID
                Return GetSingleItem(tlc)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TrackingLocationID: {0}", ID))
            End Try
            Return Nothing
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTrackingLocationsByHostName(ByVal HostName As String, ByVal trackingLocationType As String, ByVal onlyActive As Int32, ByVal showHostsNamedAll As Int32, ByVal testCenter As Int32) As TrackingLocationCollection
            Dim tlc As New TrackingLocationCriteria
            tlc.HostName = HostName

            If (trackingLocationType <> String.Empty) Then
                tlc.TrackingLocTypeName = trackingLocationType
            End If

            If (testCenter > 0) Then
                tlc.GeoLocationID = testCenter
            End If

            Return TrackingLocationDB.SearchFor(tlc, onlyActive, 0, showHostsNamedAll)

        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetMultipleTrackingLocationByHostNameAndType(ByVal HostName As String, ByVal trackingLocationType As String) As TrackingLocationCollection
            Dim tlColl As TrackingLocationCollection
            Try
                tlColl = GetTrackingLocationsByHostName(HostName, trackingLocationType, 1, 0, 0)

                Select Case tlColl.Count
                    Case Is < 1
                        LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "w67", NotificationType.Errors, "HostName: " + HostName)
                        Return Nothing
                    Case Is > 0
                        Return tlColl
                End Select
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetMultipleTrackingLocationByHostName(ByVal HostName As String) As TrackingLocationCollection
            Dim tlColl As TrackingLocationCollection
            Try
                tlColl = GetTrackingLocationsByHostName(HostName, String.Empty, 1, 0, 0)

                Select Case tlColl.Count
                    Case Is < 1
                        LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "w67", NotificationType.Errors, "HostName: " + HostName)
                        Return Nothing
                    Case Is > 0
                        Return tlColl
                End Select
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function

        <Obsolete("Don't use this routine any more. Use GetMultipleTrackingLocationByHostName instead."), _
        DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetSingleTrackingLocationByHostName(ByVal HostName As String) As TrackingLocation
            Dim tlColl As TrackingLocationCollection
            Try
                tlColl = GetTrackingLocationsByHostName(HostName, String.Empty, 1, 0, 0)
                'count the ones that are not hostname = 'all'
                Select Case (From tl As TrackingLocation In tlColl Where (Not tl.HostName.ToLower.Equals("all")) Select tl).Count
                    Case Is < 1
                        LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "w67", NotificationType.Errors, "HostName: " + HostName)
                        Return Nothing
                    Case 1
                        Return (From tl As TrackingLocation In tlColl Where (Not tl.HostName.ToLower.Equals("all")) Select tl).FirstOrDefault
                    Case Is > 1
                        Return (From tl As TrackingLocation In tlColl Where (Not tl.HostName.ToLower.Equals("all")) Select tl).Take(1).FirstOrDefault
                End Select
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("HostName: {0}", HostName))
            End Try
            Return Nothing
        End Function

        <DataObjectMethod(DataObjectMethodType.[Insert], False)> _
        Public Shared Function SaveHostStatus(ByVal hostName As String, ByVal lastUser As String, ByVal status As TrackingLocationStatus) As Boolean
            If UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                Try
                    Dim statusID As Int32 = status
                    Dim instance = New REMI.Dal.Entities().Instance()
                    Dim collection As List(Of Int32) = (From t In instance.TrackingLocationsHosts Where t.HostName = hostName And t.Status <> statusID Select t.ID).ToList()

                    If (collection.Count > 0) Then
                        For Each tlh In collection
                            Dim tlhUpdate = (From r In instance.TrackingLocationsHosts Where r.ID = tlh).FirstOrDefault()
                            tlhUpdate.Status = status
                        Next
                        instance.SaveChanges()
                    End If
                Catch ex As Exception
                    LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                    Return False
                End Try
            End If
            Return True
        End Function

        <DataObjectMethod(DataObjectMethodType.[Insert], False)> _
        Public Shared Function SaveTrackingLocationPlugin(ByVal trackingLocationID As Int32, ByVal pluginName As String) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                If UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                    Dim instance = New REMI.Dal.Entities().Instance()

                    Dim tlp As New REMI.Entities.TrackingLocationsPlugin()
                    tlp.TrackingLocation = (From tl In instance.TrackingLocations Where tl.ID = trackingLocationID Select tl).FirstOrDefault()
                    tlp.PluginName = pluginName
                    instance.AddToTrackingLocationsPlugins(tlp)
                    instance.SaveChanges()

                    nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "i2", NotificationType.Information))
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to update a host.")
                End If
            Catch sqlEx As SqlClient.SqlException When sqlEx.Number = 2601
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e5", NotificationType.Errors, sqlEx, String.Format("TrackingLocationID: {0} PluginName: {1}", trackingLocationID, pluginName)))
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("TrackingLocationID: {0} PluginName: {1}", trackingLocationID, pluginName)))
            End Try

            Return nc
        End Function

        <DataObjectMethod(DataObjectMethodType.[Insert], False)> _
        Public Shared Function SaveTrackingLocationHost(ByVal id As Int32, ByVal hostName As String) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                If UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                    If TrackingLocationDB.SaveHost(id, hostName, UserManager.GetCurrentValidUserLDAPName, TrackingLocationManager.CheckStatus(hostName)) > 0 Then
                        nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "i2", NotificationType.Information))
                    End If
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to update a host.")
                End If
            Catch sqlEx As SqlClient.SqlException When sqlEx.Number = 2601
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e5", NotificationType.Errors, sqlEx, String.Format("TrackingLocationID: {0} Host: {1}", id, hostName)))
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("TrackingLocationID: {0} Host: {1}", id, hostName)))
            End Try

            Return nc
        End Function

        <DataObjectMethod(DataObjectMethodType.[Insert], False)> _
        Public Shared Function SaveTrackingLocation(ByVal trackingCollection As TrackingLocationCollection) As Integer
            Try
                If UserManager.GetCurrentUser.IsAdmin Or UserManager.GetCurrentUser.IsTestCenterAdmin Then
                    trackingCollection(0).LastUser = UserManager.GetCurrentValidUserLDAPName

                    If trackingCollection.Validate Then
                        Using tr As New TransactionScope
                            trackingCollection(0).ID = TrackingLocationDB.Save(trackingCollection(0))

                            For Each tl In trackingCollection
                                TrackingLocationDB.SaveHost(tl.ID, tl.HostName, UserManager.GetCurrentValidUserLDAPName, CheckStatus(tl.HostName))
                            Next
                            tr.Complete()
                        End Using

                        trackingCollection(0).Notifications.Add("i2", NotificationType.Information)
                        Return trackingCollection(0).ID
                    End If
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a Tracking Location.")
                End If
            Catch sqlEx As SqlClient.SqlException When sqlEx.Number = 2601
                trackingCollection(0).Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e5", NotificationType.Errors, sqlEx, String.Format("TrackingLocationID: {0}", trackingCollection(0).ID)))
            Catch ex As Exception
                trackingCollection(0).Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("TrackingLocationID: {0}", trackingCollection(0).ID)))
            End Try

            Return 0
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Private Shared Function GetTrackingLocationHosts(ByVal tlc As TrackingLocationCriteria) As TrackingLocationCollection
            Try
                Dim tlColl As TrackingLocationCollection = TrackingLocationDB.SearchFor(tlc)
                If tlColl IsNot Nothing Then
                    Return tlColl
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetSingleItem(ByVal tlc As TrackingLocationCriteria) As TrackingLocation
            Try
                Dim tlColl As TrackingLocationCollection = TrackingLocationDB.SearchFor(tlc)
                If tlColl IsNot Nothing AndAlso tlColl.Count > 0 Then
                    Return tlColl.Item(0)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function

#Region "tracking Location Types"
        <DataObjectMethod(DataObjectMethodType.[Insert], False)> _
        Public Shared Function SaveTLType(ByVal tlType As TrackingLocationType) As Integer
            tlType.LastUser = UserManager.GetCurrentValidUserLDAPName
            If tlType.Validate Then
                Try
                    If UserManager.GetCurrentUser.IsAdmin Then
                        tlType.ID = TrackingLocationTypeDB.Save(tlType)
                        tlType.Notifications.Clear()
                        tlType.Notifications.Add("i2", NotificationType.Information)
                        Return tlType.ID
                    Else
                        Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                    End If
                Catch sqlEx As SqlClient.SqlException When sqlEx.Number = 2601
                    tlType.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e5", NotificationType.Errors, sqlEx))
                Catch ex As Exception
                    tlType.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex))
                End Try
            End If
            Return 0
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTrackingLocationTypeByID(ByVal ID As Integer) As TrackingLocationType
            Try
                Return TrackingLocationTypeDB.GetItem(ID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)

            End Try
            Return Nothing
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTrackingLocationTypes() As TrackingLocationTypeCollection
            Try
                Return TrackingLocationTypeDB.GetList(TrackingLocationFunction.NotSet)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New TrackingLocationTypeCollection
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetTrackingLocationTypesByFunction(ByVal tltFunction As TrackingLocationFunction) As TrackingLocationTypeCollection
            Try
                Return TrackingLocationTypeDB.GetList(tltFunction)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New TrackingLocationTypeCollection
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Delete], False)> _
        Public Shared Function DeleteTLType(ByVal ID As Integer) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                If UserManager.GetCurrentUser.IsAdmin Then
                    If TrackingLocationTypeDB.Delete(ID, UserManager.GetCurrentValidUserLDAPName) > 0 Then
                        nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "i1", NotificationType.Information))
                    End If
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex))
            End Try
            Return nc
        End Function

        Public Shared Function GetStationConfigurationXML(ByVal hostID As Int32, ByVal profileName As String) As XDocument
            Try
                Return TrackingLocationDB.GetStationConfigurationXML(hostID, profileName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return New XDocument()
        End Function

        Public Shared Function GetStationConfigurationHeader(ByVal hostID As Int32, ByVal profileID As Int32) As DataTable
            Try
                Return TrackingLocationDB.GetStationConfigurationHeader(hostID, profileID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return New DataTable()
        End Function

        Public Shared Function GetStationConfigurationDetails(ByVal hostConfigID As Int32) As DataTable
            Try
                Return TrackingLocationDB.GetStationConfigurationDetails(hostConfigID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return New DataTable()
        End Function

        Public Shared Function SaveStationConfiguration(ByVal hostConfigID As Int32, ByVal parentID As Int32, ByVal ViewOrder As Int32, ByVal NodeName As String, ByVal hostID As Int32, ByVal lastUser As String, ByVal pluginID As Int32) As Boolean
            Try
                Return TrackingLocationDB.SaveStationConfiguration(hostConfigID, parentID, ViewOrder, NodeName, hostID, lastUser, pluginID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function SaveStationConfigurationDetails(ByVal hostConfigID As Int32, ByVal configID As Int32, ByVal lookupID As Int32, ByVal lookupValue As String, ByVal hostID As Int32, ByVal lastUser As String, ByVal isAttribute As Boolean) As Boolean
            Try
                Return TrackingLocationDB.SaveStationConfigurationDetails(hostConfigID, configID, lookupID, lookupValue, hostID, lastUser, isAttribute)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function GetSimilarStationConfigurations(ByVal hostID As Int32) As DataTable
            Try
                Return TrackingLocationDB.GetSimilarStationConfigurations(hostID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return New DataTable()
        End Function

        Public Shared Function StationConfigurationProcess() As Boolean
            Try
                Return TrackingLocationDB.StationConfigurationProcess()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function CopyStationConfiguration(ByVal hostID As Int32, ByVal copyFromHostID As Int32, ByVal lastUser As String, ByVal profileID As Int32) As Boolean
            Try
                Return TrackingLocationDB.CopyStationConfiguration(hostID, copyFromHostID, lastUser, profileID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function DeleteStationConfiguration(ByVal hostID As Int32, ByVal lastUser As String, ByVal pluginID As Int32) As Boolean
            Try
                Return TrackingLocationDB.DeleteStationConfiguration(hostID, lastUser, pluginID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function DeleteStationConfigurationDetail(ByVal configID As Int32, ByVal lastUser As String) As Boolean
            Try
                Return TrackingLocationDB.DeleteStationConfigurationDetail(configID, lastUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function DeleteStationConfigurationHeader(ByVal hostConfigID As Int32, ByVal lastUser As String, ByVal profileID As Int32) As Boolean
            Try
                Return TrackingLocationDB.DeleteStationConfigurationHeader(hostConfigID, lastUser, profileID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function StationConfigurationUpload(ByVal hostID As Int32, ByVal xml As XDocument, ByVal LastUser As String, ByVal pluginID As Int32) As Boolean
            Try
                Return TrackingLocationDB.StationConfigurationUpload(hostID, xml, LastUser, pluginID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function GetTrackingTypeTestsGrid(ByVal testType As String, ByVal includeArchived As Boolean, ByVal trackType As String) As DataTable
            Try
                Dim testTypeID As Int32 = DirectCast(System.Enum.Parse(GetType(Contracts.TestType), testType), Contracts.TestType)
                Dim trackTypeID As Int32 = DirectCast(System.Enum.Parse(GetType(TrackingLocationFunction), trackType), TrackingLocationFunction)
                Return TrackingLocationTypeDB.GetTrackingTypeTestsGrid(testTypeID, includeArchived, trackTypeID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable
        End Function

        Public Shared Function AddRemoveTypetoTest(ByVal trackingType As String, ByVal testName As String) As Boolean
            Try
                Return TrackingLocationTypeDB.AddRemoveTypetoTest(trackingType, testName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function GetTrackingLocationPlugins(ByVal trackingLocationID As Int32) As DataTable
            Try
                Return TrackingLocationTypeDB.GetTrackingLocationPlugins(trackingLocationID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable
        End Function

        Public Shared Function GetTestsByStation(ByVal trackingLocationID As Int32) As String()
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim trackinglocationType As Int32 = (From tl In instance.TrackingLocations Where tl.ID = trackingLocationID Select tl.TrackingLocationType.ID).FirstOrDefault()
                Return (From t In instance.TrackingLocationsForTests.Include("Test").Include("TrackingLocationTypes") Where t.TrackingLocationType.ID = trackinglocationType And t.Test.IsArchived = False Select t.Test.TestName).ToList().ToArray()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function
#End Region
    End Class
End Namespace