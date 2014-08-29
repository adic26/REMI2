Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports System.Configuration
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Core

Namespace REMI.Dal
    ''' <summary>
    ''' The UserDB class is responsible for interacting with the database to retrieve and store information 
    ''' about User objects.
    ''' </summary>
    Public Class UserDB

#Region "Public Methods"

        ''' <summary>Gets an instance of User from the underlying datasource.</summary> 
        ''' <param name="UserName">The unique username of the User in the database.</param> 
        ''' <returns>A User if the ID was found in the database, or Nothing otherwise.</returns> 
        Public Shared Function GetItem(ByVal UserName As String, Optional ByVal userID As Int32 = 0) As User
            Dim myUser As User = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispUsersSelectSingleItemByUserName", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    If (userID = 0) Then
                        myCommand.Parameters.AddWithValue("@LDAPLogin", UserName)
                    Else
                        myCommand.Parameters.AddWithValue("@UserID", userID)
                    End If
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.Read() Then
                            myUser = FillDataRecord(myReader, 1)
                        End If
                    End Using
                End Using
            End Using

            Return myUser
        End Function

        ''' <summary>Gets an instance of User from the underlying datasource.</summary> 
        ''' <param name="Badgenumber">The unique badgenumber of the User in the database.</param> 
        ''' <returns>A User if the ID was found in the database, or Nothing otherwise.</returns> 
        Public Shared Function GetItem(ByVal badgeNumber As Integer) As User
            Dim myUser As User = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispUsersSelectSingleItemBybadgenumber", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BadgeNumber", badgeNumber)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.Read() Then
                            myUser = FillDataRecord(myReader, 1)
                        End If
                    End Using
                End Using
            End Using

            Return myUser
        End Function

        Public Shared Function GetListByLocation(ByVal testLocation As Int32, ByVal includeInActive As Int32, ByVal loadTraining As Int32, ByVal determineDelete As Int32) As UserCollection
            Dim tempList As New UserCollection

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispUsersSelectListByTestCentre", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestLocation", testLocation)
                    myCommand.Parameters.AddWithValue("@IncludeInActive", includeInActive)
                    myCommand.Parameters.AddWithValue("@determineDelete", determineDelete)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            tempList = New UserCollection()
                            While myReader.Read()
                                tempList.Add(FillDataRecord(myReader, loadTraining))
                            End While
                        End If
                    End Using
                End Using
            End Using

            Return tempList
        End Function

        Public Shared Function GetTraining(ByVal userID As Int32, ByVal ShowTrainedOnly As Int32) As DataTable
            Dim dt As New DataTable

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetUserTraining", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@UserID", userID)
                    myCommand.Parameters.AddWithValue("@ShowTrainedOnly", ShowTrainedOnly)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "Training"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetRemiUserNameList(ByVal determinCanDelete As Int32) As List(Of String)
            Dim tempList As List(Of String) = REMIAppCache.GetListOfRemiUsernames()

            If tempList Is Nothing Then
                Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                    Using myCommand As New SqlCommand("remispUsersSelectList", myConnection)
                        myCommand.CommandType = CommandType.StoredProcedure
                        myCommand.Parameters.AddWithValue("@startRowIndex", -1)
                        myCommand.Parameters.AddWithValue("@maximumRows", -1)
                        myCommand.Parameters.AddWithValue("@determineDelete", determinCanDelete)
                        myConnection.Open()
                        Using myReader As SqlDataReader = myCommand.ExecuteReader()
                            If myReader.HasRows Then
                                tempList = New List(Of String)
                                While myReader.Read()
                                    tempList.Add(myReader.GetString(myReader.GetOrdinal("LDAPLogin")))
                                End While
                            End If
                        End Using
                    End Using

                    REMIAppCache.SetListOfRemiUsernames(tempList)
                End Using
            End If

            Return tempList
        End Function

        ''' <summary>Saves an instance of the <see cref="User" /> in the database.</summary> 
        ''' <param name="myUser">The User instance to save.</param> 
        ''' <returns>Returns true when the object was saved successfully, or false otherwise.</returns> 
        Public Shared Function Save(ByVal MyUser As User) As Integer
            If Not MyUser.Validate() Then
                Throw New InvalidSaveOperationException("Can't save a User in an Invalid state. Make sure that IsValid() returns true before you call Save().")
            End If

            Dim Result As Integer = 0

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispUsersInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@LDAPLogin", MyUser.LDAPName)
                    If MyUser.BadgeNumber > 0 Then
                        myCommand.Parameters.AddWithValue("@BadgeNumber", MyUser.BadgeNumber)
                    End If
                    If MyUser.TestCentreID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestCentreID", MyUser.TestCentreID)
                    End If
                    myCommand.Parameters.AddWithValue("@IsActive", MyUser.IsActive)
                    myCommand.Parameters.AddWithValue("@ByPassProduct", MyUser.ByPassProduct)
                    myCommand.Parameters.AddWithValue("@DefaultPage", MyUser.DefaultPage)
                    Helpers.SetSaveParameters(myCommand, MyUser)
                    myConnection.Open()
                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()

                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("Can't update the User as it has been updated by someone else.")
                    End If

                    MyUser.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)
                    Result = Helpers.GetBusinessBaseId(myCommand)
                End Using
            End Using

            REMIAppCache.ClearListOfRemiUsernames()
            Return Result
        End Function

        ''' <summary>Deletes a User from the database.</summary> 
        Public Shared Function Delete(ByVal userIDToDelete As Int32, ByVal userID As Int32, ByVal userNameToDelete As String) As Integer
            Dim Result As Integer = 0

            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispUsersDeleteSingleItem", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@userIDToDelete", userIDToDelete)
                    myCommand.Parameters.AddWithValue("@userID", userID)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using

                'becuase we are using the asp.net role manager we should also remove this user from the aspnet roles.
                System.Web.Security.Roles.RemoveUserFromRoles(userNameToDelete, System.Web.Security.Roles.GetRolesForUser(userNameToDelete))
            End Using

            Return Result
        End Function

        Public Shared Function UserSearch(ByVal us As UserSearch, ByVal showAllGrid As Boolean) As DataTable
            Dim dt As New DataTable

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispUsersSearch", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@showAllGrid", showAllGrid)

                    For Each p As System.Reflection.PropertyInfo In us.GetType().GetProperties()
                        If p.CanRead Then
                            If (p.GetValue(us, Nothing) IsNot Nothing) Then
                                If (p.GetValue(us, Nothing).ToString().ToLower() <> "all" And p.GetValue(us, Nothing).ToString().ToLower() <> "0" And p.GetValue(us, Nothing).ToString().ToLower() <> "notset") Then
                                    myCommand.Parameters.AddWithValue("@" + p.Name, p.GetValue(us, Nothing))
                                End If
                            End If
                        End If
                    Next

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "UsersSearch"
                End Using
            End Using

            Return dt
        End Function
#End Region

#Region "Private Methods"
        ''' <summary>
        ''' Initializes a new instance of the User class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the User produced by a select query</param>
        ''' <returns>A User object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord, ByVal loadTraining As Int32) As User
            Dim myUser As New User()
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestCentre")) Then
                myUser.TestCentre = myDataRecord.GetString(myDataRecord.GetOrdinal("TestCentre"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestCentreID")) Then
                myUser.TestCentreID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestCentreID"))
            End If
            myUser.LDAPName = myDataRecord.GetString(myDataRecord.GetOrdinal("LDAPLogin"))
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("BadgeNumber")) Then
                myUser.BadgeNumber = myDataRecord.GetInt32(myDataRecord.GetOrdinal("BadgeNumber"))
            End If

            If (Helpers.HasColumn(myDataRecord, "IsActive")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("IsActive")) Then
                    myUser.IsActive = myDataRecord.GetInt32(myDataRecord.GetOrdinal("IsActive"))
                End If
            End If

            If (Helpers.HasColumn(myDataRecord, "ByPassProduct")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ByPassProduct")) Then
                    myUser.ByPassProduct = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ByPassProduct"))
                End If
            End If

            If (Helpers.HasColumn(myDataRecord, "CanDelete")) Then
                myUser.CanDelete = myDataRecord.GetInt32(myDataRecord.GetOrdinal("CanDelete"))
            End If

            If (Helpers.HasColumn(myDataRecord, "DefaultPage")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("DefaultPage")) Then
                    myUser.DefaultPage = myDataRecord.GetString(myDataRecord.GetOrdinal("DefaultPage"))
                End If
            End If

            myUser.ProductGroups = ProductGroupDB.GetUserProductGroupList(myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID")))

            For Each row As DataRow In myUser.ProductGroups.Rows
                myUser.ProductGroupsNames.Add(row.Item("ProductGroupName").ToString())
            Next row

            If (loadTraining = 1) Then
                myUser.Training = UserDB.GetTraining(myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID")), 0)
                For Each row As DataRow In myUser.Training.Rows
                    If (row.Item("DateAdded") IsNot Nothing And row.Item("DateAdded") IsNot DBNull.Value) Then
                        myUser.TrainingNames.Add(row.Item("TrainingOption").ToString())
                    End If
                Next row
            End If

            Helpers.FillObjectParameters(myDataRecord, myUser)
            myUser.ExistsInREMI = True
            Return myUser
        End Function
#End Region

    End Class
End Namespace