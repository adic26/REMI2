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
Imports REMI.Contracts.Enumerations

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
        Public Shared Function GetItem(ByVal search As String, ByVal type As SearchType) As User
            Dim myUser As User = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetUser", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    myCommand.Parameters.AddWithValue("@SearchBy", type)
                    myCommand.Parameters.AddWithValue("@SearchStr", search)

                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.Read() Then
                            myUser = FillDataRecord(myReader, False, False, False)

                            myReader.NextResult()

                            'UserDetails
                            Using myDataTable As New DataTable
                                myDataTable.Load(myReader)
                                myUser.UserDetails = myDataTable
                            End Using

                            'UserTraining
                            Using myDataTable As New DataTable
                                myDataTable.Load(myReader)
                                myUser.Training = myDataTable

                                For Each row As DataRow In myUser.Training.Rows
                                    If (row.Item("DateAdded") IsNot Nothing And row.Item("DateAdded") IsNot DBNull.Value) Then
                                        myUser.TrainingNames.Add(row.Item("TrainingOption").ToString())
                                    End If
                                Next row
                            End Using

                            'UserProducts
                            Using myDataTable As New DataTable
                                myDataTable.Load(myReader)
                                myUser.ProductGroups = myDataTable

                                For Each row As DataRow In myUser.ProductGroups.Rows
                                    myUser.ProductGroupsNames.Add(row.Item("ProductGroupName").ToString())
                                Next row
                            End Using
                        End If
                    End Using
                End Using
            End Using

            Return myUser
        End Function

        Public Shared Function GetTraining(ByVal userID As Int32, ByVal ShowTrainedOnly As Int32) As DataTable
            Dim dt As New DataTable("Training")

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

        Public Shared Function GetDetails(ByVal userID As Int32) As DataTable
            Dim dt As New DataTable("UserDetails")

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetUserDetails", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@UserID", userID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "UserDetails"
                End Using
            End Using

            Return dt
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

        Public Shared Function UserSearchList(ByVal us As UserSearch, ByVal showAllGrid As Boolean, ByVal determineDelete As Boolean, ByVal loadTraining As Boolean, ByVal loadProducts As Boolean, ByVal includeInActive As Boolean) As UserCollection
            Dim uc As New UserCollection

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispUsersSearch", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@showAllGrid", showAllGrid)
                    myCommand.Parameters.AddWithValue("@DetermineDelete", determineDelete)

                    If (includeInActive) Then
                        myCommand.Parameters.AddWithValue("@IncludeInActive", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@IncludeInActive", 0)
                    End If

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

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                uc.Add(FillDataRecord(myReader, loadTraining, loadProducts, True))
                            End While
                        End If
                    End Using
                End Using
            End Using

            Return uc
        End Function

        Public Shared Function UserSearch(ByVal us As UserSearch, ByVal showAllGrid As Boolean, ByVal determineDelete As Boolean, ByVal includeInActive As Boolean) As DataTable
            Dim dt As New DataTable

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispUsersSearch", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@showAllGrid", showAllGrid)
                    myCommand.Parameters.AddWithValue("@DetermineDelete", determineDelete)

                    If (includeInActive) Then
                        myCommand.Parameters.AddWithValue("@IncludeInActive", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@IncludeInActive", 0)
                    End If

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
        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord, ByVal loadTraining As Boolean, ByVal loadProducts As Boolean, ByVal loadDetails As Boolean) As User
            Dim myUser As New User()

            myUser.LDAPName = myDataRecord.GetString(myDataRecord.GetOrdinal("LDAPLogin"))

            If (Helpers.HasColumn(myDataRecord, "BadgeNumber")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("BadgeNumber")) Then
                    myUser.BadgeNumber = myDataRecord.GetInt32(myDataRecord.GetOrdinal("BadgeNumber"))
                End If
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

            If (loadProducts = True) Then
                myUser.ProductGroups = ProductGroupDB.GetUserProductGroupList(myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID")))

                For Each row As DataRow In myUser.ProductGroups.Rows
                    myUser.ProductGroupsNames.Add(row.Item("ProductGroupName").ToString())
                Next row
            End If

            If (loadTraining = True) Then
                myUser.Training = UserDB.GetTraining(myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID")), 0)

                For Each row As DataRow In myUser.Training.Rows
                    If (row.Item("DateAdded") IsNot Nothing And row.Item("DateAdded") IsNot DBNull.Value) Then
                        myUser.TrainingNames.Add(row.Item("TrainingOption").ToString())
                    End If
                Next row
            End If

            If (loadDetails = True) Then
                myUser.UserDetails = UserDB.GetDetails(myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID")))

                If (myUser.UserDetails IsNot Nothing) Then
                    For Each row As DataRow In myUser.UserDetails.Rows
                        myUser.DetailsNames.Add(String.Format("{0}: {1}", row.Item("Name").ToString(), row.Item("Values").ToString()))
                    Next row
                End If
            End If

            Helpers.FillObjectParameters(myDataRecord, myUser)
            myUser.ExistsInREMI = True
            Return myUser
        End Function
#End Region

    End Class
End Namespace