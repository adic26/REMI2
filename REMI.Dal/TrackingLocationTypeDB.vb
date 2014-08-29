Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports System.Configuration
Imports REMI.Core
Imports REMI.BusinessEntities
Imports REMI.Validation

Namespace REMI.Dal
    ''' <summary> 
    ''' The TestStationTypeDB class is responsible for interacting with the database to retrieve and store information 
    ''' about TestStationType objects. 
    ''' </summary> 
    Public Class TrackingLocationTypeDB

#Region "User Permissions"

        ''' <summary>
        ''' This method returns the user permissions for a user at a specific test station.
        ''' </summary>
        ''' <param name="username"></param>
        ''' <param name="hostname"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetUserPermission(ByVal username As String, ByVal hostname As String, Optional ByVal trackingLocationname As String = "") As Integer
            Dim userPermissions As Integer = 1

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationTypePermissionsGetForUserAtLocation", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@username", username)
                    myCommand.Parameters.AddWithValue("@hostname", hostname)

                    If (Not String.IsNullOrEmpty(trackingLocationname)) Then
                        myCommand.Parameters.AddWithValue("@trackinglocationname", trackingLocationname)
                    End If

                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.Read() Then
                            If Not myReader.IsDBNull(0) Then
                                userPermissions = myReader.GetInt32(0)
                            End If
                        End If
                    End Using
                End Using
            End Using

            Return userPermissions
        End Function

        Public Shared Function GetUserPermissionList(ByVal username As String) As TrackingLocationTypePermissionCollection
            Dim userPermissions As New TrackingLocationTypePermissionCollection(username)

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationTypePermissionsSelectListForUser", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@username", username)
                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            Dim currentPermission As TrackingLocationTypePermission

                            While myReader.Read()
                                currentPermission = New TrackingLocationTypePermission
                                If Not myReader.IsDBNull(myReader.GetOrdinal("ConcurrencyID")) Then
                                    currentPermission.ConcurrencyID = DirectCast(myReader.GetValue(myReader.GetOrdinal("ConcurrencyID")), Byte())
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("PermissionBitMask")) Then
                                    currentPermission.CurrentPermissions = myReader.GetInt32(myReader.GetOrdinal("PermissionBitMask"))
                                End If

                                currentPermission.TrackingLocationType = myReader.GetString(myReader.GetOrdinal("TrackingLocationTypeName"))
                                currentPermission.TrackingLocationTypeID = myReader.GetInt32(myReader.GetOrdinal("TrackingLocationTypeID"))
                                userPermissions.Add(currentPermission)
                            End While
                        End If
                    End Using
                End Using
            End Using

            Return userPermissions
        End Function

        Public Shared Function SavePermissions(ByVal permissionCollection As TrackingLocationTypePermissionCollection, ByVal currentLoggedInUser As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationTypePermissionsInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myConnection.Open()

                    For Each tltp As TrackingLocationTypePermission In permissionCollection
                        myCommand.Parameters.AddWithValue("@TrackingLocationTypeID", tltp.TrackingLocationTypeID)
                        myCommand.Parameters.AddWithValue("@PermissionBitMask", tltp.CurrentPermissions)
                        myCommand.Parameters.AddWithValue("@Username", permissionCollection.Username)
                        myCommand.Parameters.AddWithValue("@LastUser", currentLoggedInUser)
                        myCommand.Parameters.AddWithValue("@ConcurrencyID", tltp.ConcurrencyID)

                        Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()

                        If NumberOfRecordsAffected = 0 Then
                            Throw New DBConcurrencyException("Can't update the user permission as it has been updated by someone else.")
                        End If

                        tltp.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)
                        myCommand.Parameters.Clear()
                    Next
                End Using
            End Using

            Return True
        End Function
#End Region

#Region "Public Methods"
        ''' <summary>Gets an instance of TestStationType from the underlying datasource.</summary> 
        ''' <param name="id">The unique ID of the TestStationType in the database.</param> 
        ''' <returns>A TestStationType if the ID was found in the database, or Nothing otherwise.</returns> 
        Public Shared Function GetItem(ByVal ID As Integer) As TrackingLocationType
            Dim myTestStationType As TrackingLocationType = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationTypesSelectSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.Read() Then
                            myTestStationType = FillDataRecord(myReader)
                        End If
                    End Using
                End Using
            End Using

            Return myTestStationType
        End Function

        ''' <summary> 
        ''' Returns a list with TestStationType objects. 
        ''' </summary> 
        ''' <returns> 
        ''' A TestStationTypeCollection. 
        ''' </returns> 
        Public Shared Function GetList(ByVal tltFunction As TrackingLocationFunction) As TrackingLocationTypeCollection
            Dim tempList As New TrackingLocationTypeCollection

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationTypesSelectList", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    If tltFunction <> TrackingLocationFunction.NotSet Then
                        myCommand.Parameters.AddWithValue("@Function", tltFunction)
                    End If

                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                tempList.Add(FillDataRecord(myReader))
                            End While
                        End If

                    End Using
                End Using
            End Using

            Return tempList
        End Function

        ''' <summary>Saves an instance of the tracking location type in the database.</summary> 
        ''' <returns>Returns true when the object was saved successfully, or false otherwise.</returns> 
        Public Shared Function Save(ByVal MyTrackingLocationType As TrackingLocationType) As Integer
            If Not MyTrackingLocationType.Validate() Then
                Throw New InvalidSaveOperationException(String.Format("Can't save a TrackingLocationType in an Invalid state. Make sure that IsValid() returns true before you call Save(). Errors: {0}", MyTrackingLocationType.Notifications.ToString))
            End If

            Dim Result As Integer = 0

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationTypesInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TrackingLocationTypeName", MyTrackingLocationType.Name)
                    myCommand.Parameters.AddWithValue("@TrackingLocationTypeFunction", MyTrackingLocationType.TrackingLocationFunction)
                    myCommand.Parameters.AddWithValue("@UnitCapacity", MyTrackingLocationType.UnitCapacity)

                    If Not String.IsNullOrEmpty(MyTrackingLocationType.WILocation) Then
                        myCommand.Parameters.AddWithValue("@WILocation", MyTrackingLocationType.WILocation)
                    End If

                    If Not String.IsNullOrEmpty(MyTrackingLocationType.Comment) Then
                        myCommand.Parameters.AddWithValue("@Comment", MyTrackingLocationType.Comment)
                    End If

                    Helpers.SetSaveParameters(myCommand, MyTrackingLocationType)

                    myConnection.Open()

                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()

                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("Can't update the Tracking Location type as it has been updated by someone else.")
                    End If

                    MyTrackingLocationType.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)
                    Result = Helpers.GetBusinessBaseId(myCommand)
                End Using
            End Using

            Return Result
        End Function

        ''' <summary>Deletes a TestStationType from the database.</summary> 
        ''' <param name="id">The ID of the TestStationType to delete.</param> 
        ''' <returns>Returns <c>true</c> when the object was deleted successfully, or <c>false</c> otherwise.</returns> 
        Public Shared Function Delete(ByVal ID As Integer, ByVal userName As String) As Integer
            Dim Result As Integer = 0

            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationTypesDeleteSingleItem", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myCommand.Parameters.AddWithValue("@UserName", userName)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using

            Return Result
        End Function

        Public Shared Function GetTrackingTypeTestsGrid(ByVal testTypeID As Int32, ByVal includeArchived As Boolean, ByVal trackTypeID As Int32) As DataTable
            Dim dt As New DataTable()

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingTypesTests", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestTypeID", testTypeID)
                    myCommand.Parameters.AddWithValue("@IncludeArchived", includeArchived)
                    myCommand.Parameters.AddWithValue("@TrackTypeID", trackTypeID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "TrackingTypesTestsGrid"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function AddRemoveTypetoTest(ByVal trackingType As String, ByVal testName As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispAddRemoveTypeToTest", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestName", testName)
                    myCommand.Parameters.AddWithValue("@TrackingType", trackingType)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function GetTrackingLocationPlugins(ByVal trackingLocationID As Int32) As DataTable
            Dim dt As New DataTable()

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationPlugins", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TrackingLocationID", trackingLocationID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "remispTrackingLocationPlugins"
                End Using
            End Using

            Return dt
        End Function
#End Region

#Region "Private Methods"
        ''' <summary>
        ''' Initializes a new instance of the TrackingLocation class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the TrackingLocation produced by a select query</param>
        ''' <returns>A test station type object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord) As TrackingLocationType
            Dim myTrackingLocationType As New TrackingLocationType()

            myTrackingLocationType.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("TrackingLocationTypeName"))
            myTrackingLocationType.TrackingLocationFunction = DirectCast(myDataRecord.GetInt32(myDataRecord.GetOrdinal("TrackingLocationFunction")), TrackingLocationFunction)
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Comment")) Then
                myTrackingLocationType.Comment = myDataRecord.GetString(myDataRecord.GetOrdinal("Comment"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("WILocation")) Then
                myTrackingLocationType.WILocation = myDataRecord.GetString(myDataRecord.GetOrdinal("WILocation"))
            End If

            myTrackingLocationType.UnitCapacity = myDataRecord.GetInt32(myDataRecord.GetOrdinal("UnitCapacity"))

            If (Helpers.HasColumn(myDataRecord, "CanDelete")) Then
                myTrackingLocationType.CanDelete = myDataRecord.GetInt32(myDataRecord.GetOrdinal("CanDelete"))
            End If

            Helpers.FillObjectParameters(myDataRecord, myTrackingLocationType)

            Return myTrackingLocationType
        End Function
#End Region

    End Class
End Namespace