Imports REMI.BusinessEntities
Imports System.Web.Security
Imports System.Security.Permissions
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports System.DirectoryServices.AccountManagement
Imports System.Web
Imports RIM.ReliabilityEngineering.ActiveDirectoryServices
Imports System.Configuration
Imports REMI.Contracts.Enumerations

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class UserManager
        Inherits REMIManagerBase

        Private Shared _userSessionVariableName As String = "CurrentUser"

        Public Shared Function GetTraining(ByVal userID As Int32, ByVal ShowTrainedOnly As Int32) As DataTable
            Try
                Return UserDB.GetTraining(userID, ShowTrainedOnly)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return New DataTable("Training")
        End Function

        Public Shared Function GetSimiliarTraining(ByVal trainingID As Int32) As Object
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim userID As Int32 = GetCurrentValidUserID()
                Return (From r In instance.UserTrainings.Include("Lookup").Include("Lookup1").Include("User") Where r.User.ID <> userID And r.Lookup.LookupID = trainingID And r.Lookup1.Values <> "Trainer" And r.User.IsActive = 1 Order By r.User.LDAPLogin Select New With {.User = r.User.LDAPLogin, .UserID = r.User.ID, .LevelID = r.Lookup1.LookupID, .ID = r.ID}).ToList()

            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return Nothing
        End Function

        Public Shared Function UserSearch(ByVal us As UserSearch, ByVal showAllGrid As Boolean, ByVal determineDelete As Boolean, ByVal includeInActive As Boolean) As DataTable
            Try
                Return UserDB.UserSearch(us, showAllGrid, determineDelete, includeInActive)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return New DataTable("UserSearch")
        End Function

        Public Shared Function UserSearchList(ByVal us As UserSearch, ByVal showAllGrid As Boolean, ByVal determineDelete As Boolean, ByVal loadTraining As Boolean, ByVal loadAD As Boolean, ByVal includeInActive As Boolean) As UserCollection
            Try
                Dim uc As UserCollection = UserDB.UserSearchList(us, showAllGrid, determineDelete, loadTraining, includeInActive)

                If (loadAD) Then
                    For Each u As User In uc
                        If (u.IsActive = 1) Then
                            FillUserFromActiveDirectory(u, False)
                        End If
                    Next
                End If

                Return uc
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return Nothing
        End Function

        Public Shared Function SaveTrainingConfirmation(ByVal userID As Int32, ByVal id As Int32, ByVal levelID As Int32, ByVal updateConfirmDate As Boolean) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()

                Dim train = (From r In instance.UserTrainings Where r.User.ID = userID And r.ID = id).FirstOrDefault()

                If (train.ConfirmDate Is Nothing And updateConfirmDate) Then
                    train.ConfirmDate = DateTime.Now
                End If

                train.Lookup1 = (From l In instance.Lookups Where l.LookupID = levelID Select l).FirstOrDefault()

                If (String.IsNullOrEmpty(train.UserAssigned) Or train.UserAssigned Is Nothing) Then
                    train.UserAssigned = GetCurrentUser.UserName
                End If

                instance.SaveChanges()

                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function Save(ByVal u As User, ByVal saveTraining As Boolean, ByVal saveRequestAccess As Boolean, ByVal validateIsRIMNET As Boolean) As Integer
            Try
                Dim validationPassed As Boolean = True

                If Not RIM.ReliabilityEngineering.ActiveDirectoryServices.RIMAuthenticationProvider.UserOrGroupExistsInGAL(u.LDAPName) And validateIsRIMNET Then
                    validationPassed = False
                    u.Notifications.Add("w35", NotificationType.Warning)
                End If

                If (validationPassed) Then
                    u.LastUser = UserManager.GetCurrentValidUserLDAPName

                    If u.Validate Then
                        'save the user
                        Dim userID As Integer = UserDB.Save(u)
                        Dim instance = New REMI.Dal.Entities().Instance()

                        'Get existing set of UserDetails for user
                        Dim userDetailsTestCenter = (From ud In instance.UserDetails _
                                    Where ud.User.ID = u.ID And ud.Lookup.LookupType.Name = "TestCenter" _
                                    Select New With {.LookupID = ud.LookupID, .isDefault = ud.IsDefault}).ToList()

                        Dim userDetailsDepartment = (From ud In instance.UserDetails _
                                    Where ud.User.ID = u.ID And ud.Lookup.LookupType.Name = "Department" _
                                    Select New With {.LookupID = ud.LookupID, .isDefault = ud.IsDefault}).ToList()

                        Dim userDetailsProducts = (From ud In instance.UserDetails _
                                    Where ud.User.ID = u.ID And ud.Lookup.LookupType.Name = "Products" _
                                    Select New With {.LookupID = ud.LookupID, .isDefault = ud.IsDefault}).ToList()

                        'Get new set of UserDetails for user
                        Dim userDetailsNewTestCenter = (From ud In u.UserDetails Where DirectCast(ud.Item("Name"), String) = "TestCenter" _
                                Select New With {.LookupID = DirectCast(ud.Item("LookupID"), Int32), .isDefault = DirectCast(ud.Item("isDefault"), Boolean)}).ToList()

                        Dim userDetailsNewDepartment = (From ud In u.UserDetails Where DirectCast(ud.Item("Name"), String) = "Department" _
                                Select New With {.LookupID = DirectCast(ud.Item("LookupID"), Int32), .isDefault = DirectCast(ud.Item("isDefault"), Boolean)}).ToList()

                        Dim userDetailsNewProducts = (From ud In u.UserDetails Where DirectCast(ud.Item("Name"), String) = "Products" _
                                Select New With {.LookupID = DirectCast(ud.Item("LookupID"), Int32), .isProductManager = DirectCast(ud.Item("IsProductManager"), Boolean), .isTSDContact = DirectCast(ud.Item("IsTSDContact"), Boolean)}).ToList()

                        For Each udd In userDetailsNewDepartment
                            Dim ud As REMI.Entities.UserDetail = (From d In instance.UserDetails Where d.User.ID = u.ID And d.LookupID = udd.LookupID Select d).FirstOrDefault()

                            If (ud Is Nothing) Then
                                ud = New REMI.Entities.UserDetail
                                ud.User = (From usr In instance.Users Where usr.ID = u.ID Select usr).FirstOrDefault()
                                ud.Lookup = (From l In instance.Lookups Where l.LookupID = udd.LookupID Select l).FirstOrDefault()
                                ud.IsDefault = udd.isDefault
                                ud.IsAdmin = False

                                instance.AddToUserDetails(ud)
                            Else
                                ud.IsAdmin = False
                                ud.IsDefault = udd.isDefault
                            End If
                        Next

                        For Each udtc In userDetailsNewTestCenter
                            Dim ud As REMI.Entities.UserDetail = (From d In instance.UserDetails Where d.User.ID = u.ID And d.LookupID = udtc.LookupID Select d).FirstOrDefault()

                            If (ud Is Nothing) Then
                                ud = New REMI.Entities.UserDetail
                                ud.User = (From usr In instance.Users Where usr.ID = u.ID Select usr).FirstOrDefault()
                                ud.Lookup = (From l In instance.Lookups Where l.LookupID = udtc.LookupID Select l).FirstOrDefault()
                                ud.IsDefault = udtc.isDefault
                                ud.IsAdmin = False

                                instance.AddToUserDetails(ud)
                            Else
                                ud.IsAdmin = False
                                ud.IsDefault = udtc.isDefault
                            End If
                        Next

                        For Each udtc In userDetailsNewProducts
                            Dim ud As REMI.Entities.UserDetail = (From d In instance.UserDetails Where d.User.ID = u.ID And d.LookupID = udtc.LookupID Select d).FirstOrDefault()

                            If (ud Is Nothing) Then
                                ud = New REMI.Entities.UserDetail
                                ud.User = (From usr In instance.Users Where usr.ID = u.ID Select usr).FirstOrDefault()
                                ud.Lookup = (From l In instance.Lookups Where l.LookupID = udtc.LookupID Select l).FirstOrDefault()
                                ud.IsDefault = False
                                ud.IsAdmin = False
                                ud.IsProductManager = udtc.isProductManager
                                ud.IsTSDContact = udtc.isTSDContact

                                instance.AddToUserDetails(ud)
                            Else
                                ud.IsDefault = False
                                ud.IsAdmin = False
                                ud.IsProductManager = udtc.isProductManager
                                ud.IsTSDContact = udtc.isTSDContact
                            End If
                        Next

                        For Each udr In userDetailsDepartment
                            If (From d In u.UserDetails Where DirectCast(d.Item("LookupID"), Int32) = udr.LookupID Select d).FirstOrDefault() Is Nothing Then
                                Dim up As REMI.Entities.UserDetail = (From ud In instance.UserDetails Where ud.User.ID = u.ID And ud.LookupID = udr.LookupID Select ud).FirstOrDefault()
                                instance.DeleteObject(up)
                            End If
                        Next

                        For Each udr In userDetailsTestCenter
                            If (From d In u.UserDetails Where DirectCast(d.Item("LookupID"), Int32) = udr.LookupID Select d).FirstOrDefault() Is Nothing Then
                                Dim up As REMI.Entities.UserDetail = (From ud In instance.UserDetails Where ud.User.ID = u.ID And ud.LookupID = udr.LookupID Select ud).FirstOrDefault()
                                instance.DeleteObject(up)
                            End If
                        Next

                        For Each udr In userDetailsProducts
                            If (From d In u.UserDetails Where DirectCast(d.Item("LookupID"), Int32) = udr.LookupID Select d).FirstOrDefault() Is Nothing Then
                                Dim up As REMI.Entities.UserDetail = (From ud In instance.UserDetails Where ud.User.ID = u.ID And ud.LookupID = udr.LookupID Select ud).FirstOrDefault()
                                instance.DeleteObject(up)
                            End If
                        Next

                        'check for previous roles and remove
                        Dim tmpRoles As String() = System.Web.Security.Roles.GetRolesForUser(u.LDAPName)

                        If tmpRoles IsNot Nothing AndAlso tmpRoles.Length > 0 Then
                            System.Web.Security.Roles.RemoveUserFromRoles(u.LDAPName, tmpRoles)
                        End If
                        'add new roles.
                        If u.RolesList IsNot Nothing AndAlso u.RolesList.Count > 0 Then
                            System.Web.Security.Roles.AddUserToRoles(u.UserName, u.RolesList.ToArray) 'add user to roles
                        End If

                        instance.SaveChanges()

                        If (saveRequestAccess) Then
                            For Each dr As DataRow In u.RequestTypes.Rows
                                Dim userDetailsID As Int32 = 0
                                Dim typeID As Int32 = 0
                                Dim isAdmin As Boolean = False
                                Int32.TryParse(dr("UserDetailsID").ToString(), userDetailsID)
                                Int32.TryParse(dr("TypeID").ToString(), typeID)
                                Boolean.TryParse(dr("IsAdmin").ToString(), isAdmin)

                                If ((From d In instance.UserDetails Where d.UserDetailsID = userDetailsID).FirstOrDefault() IsNot Nothing) Then
                                    Dim urd As REMI.Entities.UserDetail = (From d In instance.UserDetails Where d.UserDetailsID = userDetailsID).FirstOrDefault()
                                    urd.IsAdmin = isAdmin
                                Else
                                    Dim ud As New REMI.Entities.UserDetail
                                    ud.LookupID = typeID
                                    ud.UserID = u.ID
                                    ud.IsDefault = False
                                    ud.IsAdmin = isAdmin

                                    instance.AddToUserDetails(ud)
                                End If
                            Next

                            instance.SaveChanges()
                        End If

                        If (saveTraining) Then
                            Dim newTraining = (From t In u.Training Where t.Item("ID") IsNot Nothing And t.Item("ID") IsNot DBNull.Value _
                                    Select New With _
                                        { _
                                            .ID = If(t.Item("ID") Is Nothing Or t.Item("ID") Is DBNull.Value, 0, CType(t.Item("ID"), Integer)), _
                                            .LevelLookupID = If(t.Item("LevelLookupID") Is Nothing Or t.Item("LevelLookupID") Is DBNull.Value, 0, CType(t.Item("LevelLookupID"), Integer)), _
                                            .LookupID = DirectCast(t.Item("LookupID"), Int32), _
                                            .DateAdded = If(t.Item("DateAdded") Is Nothing Or t.Item("DateAdded") Is DBNull.Value, DateTime.MinValue, DirectCast(t.Item("DateAdded"), DateTime)), _
                                            .TrainingOption = t.Item("TrainingOption").ToString(), _
                                            .UserID = If(t.Item("UserID") Is Nothing Or t.Item("UserID") Is DBNull.Value, 0, CType(t.Item("UserID"), Integer)), _
                                            .UserAssigned = If(t.Item("UserAssigned") Is Nothing Or t.Item("UserAssigned") Is DBNull.Value, String.Empty, CType(t.Item("UserAssigned"), String)) _
                                        }).ToList()

                            'Get all the DB values for training
                            Dim training = (From ut In instance.UserTrainings.Include("Lookup").Include("Lookup1").Include("User") _
                                            Where ut.User.ID = u.ID _
                                            Select New With _
                                                    { _
                                                        .ID = ut.ID, _
                                                        .LevelLookupID = If(ut.Lookup1 Is Nothing, 0, CType(ut.Lookup1.LookupID, Integer)), _
                                                        .LookupID = ut.Lookup.LookupID, _
                                                        .DateAdded = ut.DateAdded, _
                                                        .TrainingOption = ut.Lookup.Values, _
                                                        .UserID = ut.User.ID, _
                                                        .UserAssigned = CType(ut.UserAssigned, String) _
                                                    }).ToList()

                            For Each t In newTraining
                                If (training.Select(Function(r) r.ID).Contains(t.ID)) Then
                                    Dim id As Int32 = t.ID
                                    Dim levelID As Int32 = t.LevelLookupID
                                    Dim train As REMI.Entities.UserTraining = (From r In instance.UserTrainings.Include("User").Include("Lookup").Include("Lookup1") Where r.ID = id).FirstOrDefault()

                                    If (train.Lookup1 IsNot Nothing) Then
                                        If (train.Lookup1.LookupID <> levelID) Then
                                            train.ConfirmDate = Nothing
                                        End If
                                    ElseIf (train.Lookup1 Is Nothing And levelID > 0) Then
                                        train.ConfirmDate = Nothing
                                    End If

                                    train.Lookup1 = (From l In instance.Lookups Where l.LookupID = levelID Select l).FirstOrDefault()

                                    If (Not String.IsNullOrEmpty(t.UserAssigned)) Then
                                        train.UserAssigned = t.UserAssigned
                                    Else
                                        train.UserAssigned = GetCurrentUser.UserName
                                    End If
                                Else
                                    Dim id As Int32 = t.LookupID
                                    Dim levelID As Int32 = t.LevelLookupID
                                    Dim ut As New REMI.Entities.UserTraining()
                                    ut.DateAdded = t.DateAdded
                                    ut.User = (From usr In instance.Users Where usr.ID = u.ID Select usr).FirstOrDefault()
                                    ut.Lookup = (From l In instance.Lookups Where l.LookupID = id Select l).FirstOrDefault()
                                    ut.Lookup1 = (From l In instance.Lookups Where l.LookupID = levelID Select l).FirstOrDefault()

                                    If (Not String.IsNullOrEmpty(t.UserAssigned)) Then
                                        ut.UserAssigned = t.UserAssigned
                                    End If

                                    instance.AddToUserTrainings(ut)
                                End If
                            Next

                            instance.SaveChanges()
                        End If

                        If (UserManager.GetCurrentUser.ID = u.ID) Then
                            UserManager.LogUserOut()
                            UserManager.SetUserToSession(u)
                        End If

                        Return userID
                    End If
                End If
            Catch sqlEx As SqlClient.SqlException When sqlEx.Number = 2601
                u.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e5", NotificationType.Errors, sqlEx))
            Catch ex As Exception
                u.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex))
            End Try

            Return 0
        End Function

        Public Shared Function UserExists(ByVal userName As String, ByVal badge As Int32) As Boolean
            Try
                Dim u As User = Nothing

                If (badge > 0) Then
                    u = UserDB.GetItem(badge.ToString(), Contracts.Enumerations.SearchType.Badge)
                Else
                    u = UserDB.GetItem(userName.ToLower, Contracts.Enumerations.SearchType.UserName)
                End If

                If u IsNot Nothing Then
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        ''' <summary>
        ''' Gets a single user from the Users table.
        ''' </summary>
        ''' <param name="userName">the LDAP username of the user to retreive.</param>
        ''' <returns>A user if the user is found or else nothing</returns>
        Private Shared Function GetItem(ByVal search As String, ByVal type As SearchType) As User
            Try
                'try to get the user from the remi database
                Dim u As User = UserDB.GetItem(search, type)
                If u Is Nothing Then
                    'if there is not user just create a new one and set it up
                    u = New User With {.LDAPName = search.ToLower, .LastUser = "remi", .IsActive = 1, .DefaultPage = "/default.aspx", .ByPassProduct = 0}
                End If
                'now get any info we can about the user from the active directory
                FillUserFromActiveDirectory(u, True)
                Return u
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex, String.Format("UserName: {0}", search))
            End Try
            Return Nothing
        End Function

        ''' <summary>
        ''' Gets a user principal from the AD and clones a couple of properties from this to a remi user object
        ''' </summary>
        ''' <param name="u"></param>
        ''' <param name="evaluateREMIPageViewAuthority"></param>
        ''' <remarks></remarks>
        Private Shared Sub FillUserFromActiveDirectory(ByRef u As User, ByVal evaluateREMIPageViewAuthority As Boolean)
            Dim adUser As UserPrincipal = RIMAuthenticationProvider.GetUser(u.UserName)
            If (Not adUser Is Nothing) Then
                u.FullName = adUser.DisplayName
                u.LDAPName = adUser.SamAccountName
                u.Extension = adUser.VoiceTelephoneNumber
                u.EmailAddress = adUser.EmailAddress

                'fill the roles too
                u.RolesList = System.Web.Security.Roles.GetRolesForUser(u.LDAPName).ToList
            End If
        End Sub

        ''' <summary>
        ''' Add a user to the database.
        ''' </summary>
        Public Shared Function ConfirmUserCredentialsAndSave(ByVal password As String, ByVal hasPasswordRequirement As Boolean, ByVal u As User) As NotificationCollection
            Dim returnNotifications As New NotificationCollection

            Try
                If (hasPasswordRequirement) Then
                    hasPasswordRequirement = RIMAuthenticationProvider.AuthenticateCredentials(u.LDAPName, password)
                Else
                    hasPasswordRequirement = True
                End If

                If hasPasswordRequirement Then
                    u.ID = Save(u, False, False, True)

                    If u.ID > 0 Then 'if the user was saved then
                        HttpContext.Current.Session.Add(_userSessionVariableName, u) 'save it to the session
                    Else
                        returnNotifications.AddWithMessage("User verified ok but there was a database error. Unable to save.", NotificationType.Information)
                    End If
                Else
                    returnNotifications.Add(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, u.LDAPName)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try

            Return returnNotifications
        End Function

        ''' <summary>
        ''' Deletes a single user from the users table
        ''' </summary>
        ''' <returns>true if the user was deleted, false otherwise</returns>
        Public Shared Function Delete(ByVal userIDToDelete As Int32, ByVal userID As Int32) As NotificationCollection
            Dim nc As New NotificationCollection
            Try
                Dim userNameToDelete As String = (From u In New REMI.Dal.Entities().Instance().Users Where u.ID = userIDToDelete Select u.LDAPLogin).FirstOrDefault()

                If UserDB.Delete(userIDToDelete, userID, userNameToDelete) > 0 Then
                    nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "i1", NotificationType.Information))
                End If
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex, String.Format("userIDToDelete: {0}", userIDToDelete)))
            End Try
            Return nc
        End Function

        ''' <summary>
        ''' Gets a list of all possible roles in the system.
        ''' </summary>
        ''' <returns>A list of the roles in the system.</returns>
        Public Shared Function GetRoles() As List(Of String)
            Try
                Dim roles As List(Of String) = System.Web.Security.Roles.GetAllRoles.ToList

                If (UserManager.GetCurrentUser.IsDeveloper) Then
                    roles.Add("Developer")
                End If

                Return roles
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function

        Public Shared Function SessionUserIsSet() As Boolean
            Return HttpContext.Current.Session(_userSessionVariableName) IsNot Nothing
        End Function

        Private Shared Function UserIsInSession(ByVal userIdentification As String) As Boolean
            'check if they are already set in the session.
            If HttpContext.Current.Session(_userSessionVariableName) IsNot Nothing Then
                Dim u As REMI.BusinessEntities.User = DirectCast(HttpContext.Current.Session(_userSessionVariableName), User)

                If (u.RequiresSuppAuth()) Then
                    Return False
                End If

                Dim badgenumber As Integer
                If Integer.TryParse(userIdentification, badgenumber) Then
                    If u.BadgeNumber > 0 AndAlso u.BadgeNumber = badgenumber Then
                        Return True
                    End If
                Else
                    'try treating it as a string
                    If userIdentification.ToLower.Contains("@"c) Then
                        If u.UserName = userIdentification.ToLower.Split("@"c)(0) Then
                            Return True
                        End If
                    Else
                        If u.UserName = userIdentification Then
                            Return True
                        End If
                    End If
                End If
            End If
            Return False
        End Function

        Public Shared Function SetUserToSession(ByVal u As User) As Boolean
            If u IsNot Nothing Then 'if the user was found by their badge number or email then everything is ok otherwise the user could not be found
                If (u.RequiresSuppAuth()) Then
                    Return False
                Else
                    HttpContext.Current.Session.Add(_userSessionVariableName, u)
                    Return True
                End If
            End If
            Throw New ArgumentException("The user given cannot be set to the session in this context becuase they do not have the correct permissions.")
        End Function

        ''' <summary>
        ''' Saves the user to the current session. This does not redirect the request if the auth fails. It just returns a bool
        ''' Use the authenticate method if you want to redirect the user to the badge scan page.
        ''' </summary>
        Public Shared Function SetUserToSession(ByVal userID As String) As Boolean
            Try
                If UserIsInSession(userID) Then
                    Return True
                Else
                    'they're not already set. get the user and set it.
                    Dim u As User = UserManager.GetUser(userID, 0)
                    If u IsNot Nothing Then 'if the user was found by their badge number or email then everything is ok otherwise the user could not be found
                        If (u.ExistsInREMI = False) Then
                            Return False
                        End If

                        If (u.RequiresSuppAuth()) Then
                            Return False
                        End If

                        HttpContext.Current.Session.Add(_userSessionVariableName, u)
                        Return True
                    End If
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex, String.Format("userID: {0}", userID))
            End Try
            Return False
        End Function

        ''' <summary>
        ''' Returns the user currently set to the session.
        ''' empty user if they cannot be set
        ''' </summary>
        Public Shared Function GetCurrentUser() As User
            'is there a user stored in the session return that
            If HttpContext.Current.Session IsNot Nothing AndAlso HttpContext.Current.Session.Item(_userSessionVariableName) IsNot Nothing Then 'is the user there
                Return DirectCast(HttpContext.Current.Session.Item(_userSessionVariableName), REMI.BusinessEntities.User)
            End If

            Dim windowsUser As User = UserManager.GetItem(GetCleanedHttpContextCurrentUserName, SearchType.UserName)

            If windowsUser IsNot Nothing Then
                If HttpContext.Current.Session IsNot Nothing Then
                    'try to put the user in the session so we don;t have to go to the database each time.
                    SetUserToSession(windowsUser)
                End If

                Return windowsUser
            End If

            Return Nothing
        End Function

        Public Shared Function GetUser(ByVal userIdentification As String, Optional ByVal userID As Int32 = 0) As User
            Try
                If Not String.IsNullOrEmpty(userIdentification) Then
                    Dim badgeNumber As Integer

                    'try to parse it as an integer - badge scan
                    If Integer.TryParse(userIdentification.ToLower, badgeNumber) Then
                        If badgeNumber > 0 Then
                            Return UserManager.GetItem(badgeNumber.ToString(), SearchType.Badge)
                        End If
                    Else
                        'its most likely a string
                        Dim username As String = userIdentification
                        If userIdentification.ToLower.Contains("@"c) Then
                            'this is an email address type username so try to get the user using it
                            'the dta/tta application sends email addresses rather than badge numbers.
                            username = userIdentification.ToLower.Split("@"c)(0)
                        End If

                        Return UserManager.GetItem(username, SearchType.UserName)
                    End If
                ElseIf userID > 0 Then
                    Return UserManager.GetItem(userID.ToString(), SearchType.UserID)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e22", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function

        ''' <summary>
        ''' Removes a user from the current session
        ''' </summary>
        Public Shared Sub LogUserOut()
            HttpContext.Current.Session.Clear()
            HttpContext.Current.Session.RemoveAll()
            HttpContext.Current.Session.Abandon()
        End Sub

        ''' <summary>
        ''' Gets the valid username for the current user. "doriordan" for example. Will return the windows username if the badge numebr has not been used
        ''' to authenticate the user.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetCurrentValidUserLDAPName() As String
            Return GetCurrentUser().LDAPName
        End Function

        Public Shared Function GetCurrentValidUserID() As Int32
            Return GetCurrentUser().ID
        End Function

        ''' <summary>
        ''' Cleans "RIMNET" from the windows username if it is present
        ''' </summary>
        Public Shared Function GetCleanedHttpContextCurrentUserName() As String
            If HttpContext.Current IsNot Nothing AndAlso HttpContext.Current.User IsNot Nothing Then
                Return CleanRIMNETUserName(HttpContext.Current.User.Identity.Name)
            Else
                Return "User Not Set"
            End If
        End Function

        ''' <summary>
        ''' Removes the domain prefix from the ldap usernames returned by the IIdentity
        ''' </summary>
        Private Shared Function CleanRIMNETUserName(ByVal username As String) As String
            If Not String.IsNullOrEmpty(username) Then
                username = username.Trim()
                If username.StartsWith("RIMNET") Then
                    Return username.Remove(0, 7)
                Else
                    Return username
                End If
            End If
            Return String.Empty
        End Function
    End Class
End Namespace