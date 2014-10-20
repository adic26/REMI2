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
Imports REMI.Contracts

Namespace REMI.Dal
    ''' <summary>
    ''' The TestDB class is responsible for interacting with the database to retrieve and store information 
    ''' about Test objects.
    ''' </summary>
    Public Class TestDB

#Region "Public Methods"

        ''' <summary>Gets an instance of Test from the underlying datasource.</summary> 
        ''' <param name="id">The unique ID of the Test in the database.</param> 
        ''' <returns>A Test if the ID was found in the database, or Nothing otherwise.</returns> 
        Public Shared Function GetItem(ByVal ID As Integer) As Test
            Dim myTest As Test = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTestsSelectSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.Read() Then
                            myTest = FillDataRecord(myReader)
                        End If
                        myReader.Close()
                    End Using
                End Using

                'If myTest IsNot Nothing Then
                '    myTest.TrackingLocationTypes = GetApplicableTLTypes(myTest.ID, myConnection)
                'End If
            End Using
            Return myTest
        End Function

        Public Shared Function GetItemByName(ByVal name As String, ByVal parametricOnly As Boolean) As Test
            Dim myTest As Test = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTestsSelectSingleItemByName", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@Name", name)

                    If (parametricOnly) Then
                        myCommand.Parameters.AddWithValue("@ParametricOnly", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ParametricOnly", 0)
                    End If

                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.Read() Then
                            myTest = FillDataRecord(myReader)
                        End If
                        myReader.Close()
                    End Using
                End Using
                'If myTest IsNot Nothing Then
                '    myTest.TrackingLocationTypes = GetApplicableTLTypes(myTest.ID, myConnection)
                'End If
            End Using
            Return myTest
        End Function

        Public Shared Function GetListOfBatchSpecificTestDurations(ByVal qraNumber As String, ByVal myconnection As SqlConnection) As Dictionary(Of Integer, Double)

            Dim tempList As New Dictionary(Of Integer, Double)

            Using myCommand As New SqlCommand("remispBatchSpecificTestDurationsGetList", myconnection)
                myCommand.CommandType = CommandType.StoredProcedure

                myCommand.Parameters.AddWithValue("@qranumber", qraNumber)

                If myconnection.State <> ConnectionState.Open Then
                    myconnection.Open()
                End If
                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                    If myReader.HasRows Then
                        While myReader.Read()
                            tempList.Add(myReader.GetInt32(myReader.GetOrdinal("testid")), myReader.GetFloat(myReader.GetOrdinal("duration")))
                        End While
                    End If

                End Using
            End Using

            Return tempList
        End Function

        ''' <summary> 
        ''' Returns a list with Test objects. 
        ''' </summary> 
        ''' <param name="TestType">The test type to filter for.</param>
        ''' <param name="startRowIndex">The index of the first record to retrieve.</param> 
        ''' <param name="maximumRows">The maximum number of records to be returned.</param> 
        ''' <returns> 
        ''' A TestCollection. 
        ''' </returns> 
        Public Shared Function GetListByTestType(ByVal TestType As TestType, ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal includeArchived As Boolean) As TestCollection

            Dim tempList As New TestCollection
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestsSelectListByType", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestType", TestType)
                    myCommand.Parameters.AddWithValue("@IncludeArchived", includeArchived)
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

        ''' <summary> 
        ''' Returns a list with Test objects. 
        ''' </summary>
        ''' <param name="TestStageID">The unique id of the teststage to get tests for</param>
        ''' <returns> 
        ''' A TestCollection. 
        ''' </returns> 
        Public Shared Function GetListByTestStageID(ByVal TestStageID As Integer) As TestCollection
            Dim tempList As New TestCollection
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTestsSelectListByTestStageID", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestStageID", TestStageID)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                tempList.Add(FillDataRecord(myReader))
                            End While
                        End If
                        myReader.Close()
                    End Using
                End Using
            End Using
            Return tempList
        End Function

        Public Shared Function GetTestsByBatchUnitStage(ByVal requestNumber As String, ByVal unitNumber As Int32, ByVal TestStageID As Integer) As TestCollection
            Dim tempList As New TestCollection
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTestsSelectByBatchUnitStage", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@RequestNumber", requestNumber)
                    myCommand.Parameters.AddWithValue("@BatchUnitNumber", unitNumber)
                    myCommand.Parameters.AddWithValue("@TestStageID", TestStageID)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                tempList.Add(FillDataRecord(myReader))
                            End While
                        End If
                        myReader.Close()
                    End Using
                End Using
            End Using
            Return tempList
        End Function

        Public Shared Function AddApplicableTrackingLocationType(ByVal testID As Integer, ByVal trackingLocationType As TrackingLocationType) As Boolean
            Dim Result As Integer = 0
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTestsAddTrackingLocationForTest", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@TrackingLocationTypeID", trackingLocationType.ID)

                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using

            End Using
            If Result > 0 Then
                'messy clear the whole cache
                'must do this becuase there is no graph of which batches will be affected by the test update.
                REMIAppCache.ClearCache()
            End If
            Return Result > 0
        End Function
        Public Shared Function DeleteApplicableTrackingLocationType(ByVal testID As Integer, ByVal trackingLocationType As TrackingLocationType) As Boolean
            Dim Result As Integer = 0
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTestsRemoveTrackingLocationForTest", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@TrackingLocationTypeID", trackingLocationType.ID)

                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using

            End Using
            If Result > 0 Then
                'messy clear the whole cache
                'must do this becuase there is no graph of which batches will be affected by the update.
                REMIAppCache.ClearCache()
            End If
            Return Result > 0
        End Function
        'Public Shared Function GetApplicableTLTypes(ByVal testId As Integer) As TrackingLocationTypeCollection
        '    Dim tempList As New TrackingLocationTypeCollection
        '    Using myconnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
        '        Using myCommand As New SqlCommand("remispTestSelectApplicableTrackingLocationTypes", myconnection)
        '            myCommand.CommandType = CommandType.StoredProcedure
        '            myCommand.Parameters.AddWithValue("@testid", testId)

        '            myconnection.Open()
        '            Using myReader As SqlDataReader = myCommand.ExecuteReader()
        '                If myReader.HasRows Then
        '                    While myReader.Read()
        '                        Dim tlt As New TrackingLocationType
        '                        tlt.ID = myReader.GetInt32(0)
        '                        tlt.Name = myReader.GetString(1)

        '                        tempList.Add(tlt)
        '                    End While
        '                End If

        '            End Using
        '        End Using
        '    End Using

        '    Return tempList
        'End Function

        Public Shared Function GetApplicableTLTypes(ByVal testID As Integer) As TrackingLocationTypeCollection
            Dim tempList As New TrackingLocationTypeCollection

            Using myconnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestSelectApplicableTrackingLocationTypes", myconnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@testID", testID)
                    myconnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                Dim tlt As New TrackingLocationType
                                tlt.ID = myReader.GetInt32(0)
                                tlt.Name = myReader.GetString(1)
                                tlt.TrackingLocationFunction = DirectCast(System.Enum.Parse(GetType(TrackingLocationFunction), myReader.GetInt32(2).ToString()), TrackingLocationFunction)
                                
                                If Not myReader.IsDBNull(3) Then
                                    tlt.Comment = myReader.GetString(3)
                                End If

                                If Not myReader.IsDBNull(4) Then
                                    tlt.WILocation = myReader.GetString(4)
                                End If

                                If Not myReader.IsDBNull(5) Then
                                    tlt.UnitCapacity = myReader.GetInt32(5)
                                End If

                                tlt.LastUser = myReader.GetString(7)

                                tempList.Add(tlt)
                            End While
                        End If

                    End Using
                End Using
            End Using

            Return tempList
        End Function

        Structure TLType
            Dim TLTypeId As Integer
            Dim testId As Integer
            Dim TLName As String
        End Structure

        'Public Shared Function GetApplicableTLTypesByTestType(ByVal testTypeID As Integer, ByVal myconnection As SqlConnection) As TrackingLocationTypeCollection
        'Dim tempList As New List(Of TLType)

        'Using myCommand As New SqlCommand("SELECT t.id, tlt.id, tlt.TrackingLocationTypeName FROM trackinglocationtypes as tlt, TrackingLocationsForTests as tlfort, Tests as t where(tlfort.testid = t.id And tlt.ID = tlfort.TrackingLocationtypeID)	 and t.TestType = @TestType	 order by tlt.TrackingLocationTypeName asc", myconnection)
        '    myCommand.CommandType = CommandType.Text
        '    myCommand.Parameters.AddWithValue("@testType", testTypeID)

        '    Using myReader As SqlDataReader = myCommand.ExecuteReader()
        '        If myReader.HasRows Then
        '            While myReader.Read()
        '                Dim tlt As New TLType
        '                tlt.testId = myReader.GetInt32(0)
        '                tlt.TLTypeId = myReader.GetInt32(1)
        '                tlt.TLName = myReader.GetString(2)
        '                tempList.Add(tlt)
        '            End While
        '        End If

        '    End Using
        'End Using

        'Return tempList

        'End Function
        ''' <summary>Saves an instance of the <see cref="Test" /> in the database.</summary> 
        ''' <param name="myTest">The Test instance to save.</param> 
        ''' <returns>Returns the id when the object was saved successfully, or 0 otherwise.</returns> 
        Public Shared Function Save(ByVal MyTest As Test) As Integer
            If Not MyTest.Validate() Then
                Throw New InvalidSaveOperationException("Can't save a Test in an Invalid state. Make sure that IsValid() returns true before you call Save().")
            End If

            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTestsInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestName", MyTest.Name)
                    myCommand.Parameters.AddWithValue("@Duration", MyTest.TotalHours)
                    myCommand.Parameters.AddWithValue("@TestType", MyTest.TestType)
                    myCommand.Parameters.AddWithValue("@Comment", MyTest.Comments)
                    myCommand.Parameters.AddWithValue("@ResultBasedOnTime", MyTest.ResultIsTimeBased)
                    myCommand.Parameters.AddWithValue("@WILocation", MyTest.WorkInstructionLocation)
                    myCommand.Parameters.AddWithValue("@IsArchived", MyTest.IsArchived)
                    myCommand.Parameters.AddWithValue("@Owner", MyTest.Owner)
                    myCommand.Parameters.AddWithValue("@Trainee", MyTest.Trainee)
                    myCommand.Parameters.AddWithValue("@DegradationVal", MyTest.Degradation)
                    Helpers.SetSaveParameters(myCommand, MyTest)
                    myConnection.Open()
                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()
                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("Can't update the Test as it has been updated by someone else.")
                    End If

                    MyTest.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)
                    Result = Helpers.GetBusinessBaseId(myCommand)
                End Using

            End Using
            If Result > 0 Then
                'messy clear the whole cache
                'must do this becuase there is no graph of which batches will be affected by the update.
                REMIAppCache.ClearCache()
            End If
            Return Result
        End Function

        ''' <summary>Deletes a Test from the database.</summary> 
        ''' <param name="id">The ID of the Test to delete.</param> 
        Public Shared Function Delete(ByVal ID As Integer, ByVal UserName As String) As Integer
            Dim Result As Integer = 0
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTestsDeleteSingleItem", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myCommand.Parameters.AddWithValue("@UserName", UserName)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using

            End Using
            If Result > 0 Then
                'messy clear the whole cache
                'must do this becuase there is no graph of which batches will be affected by the test update.
                REMIAppCache.ClearCache()
            End If
            Return Result
        End Function

#End Region

#Region "Private Methods"
        ''' <summary>
        ''' Initializes a new instance of the Test class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the Test produced by a select query</param>
        ''' <returns>A Test object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord) As Test
            Dim myTest As New Test()

            'Non nullable data records
            myTest.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("TestName"))
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Duration")) Then
                myTest.Duration = TimeSpan.FromHours(myDataRecord.GetFloat(myDataRecord.GetOrdinal("Duration")))
            End If
            myTest.TestType = DirectCast(myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestType")), TestType)
            myTest.ID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID"))

            'Nullable data records

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("WILocation")) Then
                myTest.WorkInstructionLocation = myDataRecord.GetString(myDataRecord.GetOrdinal("WILocation"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Comment")) Then
                myTest.Comments = myDataRecord.GetString(myDataRecord.GetOrdinal("Comment"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ResultBasedOntime")) Then
                myTest.ResultIsTimeBased = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("ResultBasedOntime"))
            End If

            If (Helpers.HasColumn(myDataRecord, "CanDelete")) Then
                myTest.CanDelete = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("CanDelete"))
            End If

            If (Helpers.HasColumn(myDataRecord, "IsArchived")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("IsArchived")) Then
                    myTest.IsArchived = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("IsArchived"))
                End If
            End If

            If (Helpers.HasColumn(myDataRecord, "TestStage")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestStage")) Then
                    myTest.TestStage = myDataRecord.GetString(myDataRecord.GetOrdinal("TestStage"))
                End If
            End If

            If (Helpers.HasColumn(myDataRecord, "JobName")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("JobName")) Then
                    myTest.JobName = myDataRecord.GetString(myDataRecord.GetOrdinal("JobName"))
                End If
            End If

            If (Helpers.HasColumn(myDataRecord, "Owner")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Owner")) Then
                    myTest.Owner = myDataRecord.GetString(myDataRecord.GetOrdinal("Owner"))
                End If
            End If

            If (Helpers.HasColumn(myDataRecord, "Trainee")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Trainee")) Then
                    myTest.Trainee = myDataRecord.GetString(myDataRecord.GetOrdinal("Trainee"))
                End If
            End If

            If (Helpers.HasColumn(myDataRecord, "DegradationVal")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("DegradationVal")) Then
                    myTest.Degradation = myDataRecord.GetDecimal(myDataRecord.GetOrdinal("DegradationVal"))
                End If
            End If

            myTest.TrackingLocationTypes = GetApplicableTLTypes(myTest.ID)

            Helpers.FillObjectParameters(myDataRecord, myTest)

            Return myTest
        End Function

#End Region

    End Class


End Namespace



