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
    ''' The DeviceTrackingLogDB class is responsible for interacting with the database to retrieve and store information 
    ''' about DeviceTrackingLog objects.
    ''' </summary>
    Public Class DeviceTrackingLogDB
#Region "Public Methods"
        ''' <summary>Gets the instance of device tracking log for the given id.</summary> 
        ''' <param name="ID">The unique ID of the device tracking log in the database.</param> 
        ''' <returns>A DeviceTrackingLog if the ID was found in the database, or Nothing otherwise.</returns> 
        Public Shared Function GetLogByID(ByVal ID As Integer) As DeviceTrackingLog
            Dim myDeviceTrackingLog As DeviceTrackingLog = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.Read() Then
                            myDeviceTrackingLog = FillDataRecord(myReader)
                        End If

                        myReader.Close()

                    End Using
                End Using
            End Using
            Return myDeviceTrackingLog
        End Function

        Public Shared Function GetLogsByTestRecordID(ByVal trID As Integer) As DeviceTrackingLogCollection
            Dim myDeviceTrackingLogCol As DeviceTrackingLogCollection = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectListByTestRecordID", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@testrecordID", trID)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.HasRows Then
                            myDeviceTrackingLogCol = New DeviceTrackingLogCollection()
                            While myReader.Read()
                                myDeviceTrackingLogCol.Add(FillDataRecord(myReader))
                            End While
                        End If

                        myReader.Close()
                    End Using
                End Using
            End Using

            Return myDeviceTrackingLogCol
        End Function
        ''' <summary>Gets the last instance of DeviceTrackingLog from the underlying datasource for a specific device.</summary> 
        ''' <param name="testunitid">The unique ID of the Test Unit in the database.</param> 
        ''' <returns>A DeviceTrackingLog if the TestUnitID was found in the database, or Nothing otherwise.</returns> 
        Public Shared Function GetLastLog(ByVal TestUnitID As Integer) As DeviceTrackingLog
            Dim myDeviceTrackingLog As DeviceTrackingLog = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectLastLogByTestUnitID", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestUnitID", TestUnitID)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.Read() Then
                            myDeviceTrackingLog = FillDataRecord(myReader)
                        End If

                        myReader.Close()
                    End Using
                End Using
            End Using

            Return myDeviceTrackingLog
        End Function

        Public Shared Function GetLastLog(ByVal TestUnitID As Integer, ByVal myconnection As SqlConnection) As DeviceTrackingLog
            Dim myDeviceTrackingLog As DeviceTrackingLog = Nothing

            Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectLastLogByTestUnitID", myconnection)
                myCommand.CommandType = CommandType.StoredProcedure
                myCommand.Parameters.AddWithValue("@TestUnitID", TestUnitID)

                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                    If myReader.Read() Then
                        myDeviceTrackingLog = FillDataRecord(myReader)
                    End If

                    myReader.Close()
                End Using
            End Using

            Return myDeviceTrackingLog
        End Function

        ''' <summary>Gets the last instance of DeviceTrackingLog from the underlying datasource for a specific device.</summary> 
        ''' <param name="Barcode">The barcode of the scanned Test Unit.</param> 
        ''' <returns>A DeviceTrackingLog if the TestUnitID was found in the database, or Nothing otherwise.</returns> 
        Public Shared Function GetLastLog(ByVal Barcode As DeviceBarcodeNumber) As DeviceTrackingLog
            Dim myDeviceTrackingLog As DeviceTrackingLog = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectLastLogByBarcodeInformation", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", Barcode.BatchNumber)
                    myCommand.Parameters.AddWithValue("@BatchUnitNumber", Barcode.UnitNumber)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.Read() Then
                            myDeviceTrackingLog = FillDataRecord(myReader)
                        End If
                    End Using
                End Using
            End Using
            Return myDeviceTrackingLog
        End Function

        ''' <summary>Saves an instance of the <see cref="DeviceTrackingLog" /> in the database.</summary> 
        ''' <param name="myDeviceTrackingLog">The DeviceTrackingLog instance to save.</param> 
        ''' <returns>Returns true when the object was saved successfully, or false otherwise.</returns> 
        Public Shared Function Save(ByVal MyDeviceTrackingLog As DeviceTrackingLog) As Integer
            If Not MyDeviceTrackingLog.Validate() Then
                Throw New InvalidSaveOperationException("Can't save a DeviceTrackingLog in an Invalid state. Make sure that IsValid() returns true before you call Save().")
            End If

            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeviceTrackingLogInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestUnitID", MyDeviceTrackingLog.TestUnitID)
                    myCommand.Parameters.AddWithValue("@TrackinglocationID", MyDeviceTrackingLog.TrackingLocationID)
                    myCommand.Parameters.AddWithValue("@InTime", MyDeviceTrackingLog.InTime)
                    myCommand.Parameters.AddWithValue("@InUser", MyDeviceTrackingLog.InUser)

                    ' adds the return parameter to each of the commands that use this sub
                    Dim returnValue As DbParameter = myCommand.CreateParameter()
                    returnValue.Direction = ParameterDirection.ReturnValue
                    myCommand.Parameters.Add(returnValue)
                    'sets the concurrency id of the object to the database parameter
                    Dim RowVersion As DbParameter = myCommand.CreateParameter()
                    RowVersion.ParameterName = "@ConcurrencyID"
                    RowVersion.Direction = ParameterDirection.InputOutput
                    RowVersion.DbType = DbType.Binary
                    RowVersion.Size = 8
                    If MyDeviceTrackingLog.ConcurrencyID Is Nothing Then
                        RowVersion.Value = DBNull.Value
                    Else
                        RowVersion.Value = MyDeviceTrackingLog.ConcurrencyID
                    End If
                    myCommand.Parameters.Add(RowVersion)
                    'the Id parameter
                    Dim IDParam As DbParameter = myCommand.CreateParameter()
                    IDParam.DbType = DbType.Int32
                    IDParam.Direction = ParameterDirection.InputOutput
                    IDParam.ParameterName = "@ID"
                    If MyDeviceTrackingLog.ID = 0 Then
                        IDParam.Value = DBNull.Value
                    Else
                        IDParam.Value = MyDeviceTrackingLog.ID
                    End If
                    myCommand.Parameters.Add(IDParam)
                    myConnection.Open()
                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()
                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("Can't update the DeviceTrackingLog as it has been updated by someone else.")
                    End If

                    MyDeviceTrackingLog.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)

                    Result = Helpers.GetBusinessBaseId(myCommand)
                    If Result > 0 Then
                        MyDeviceTrackingLog.ID = Result
                    End If
                End Using
            End Using
            Return Result
        End Function

        ''' <summary> 
        ''' Returns a list with DeviceTrackingLog objects. 
        ''' </summary> 
        ''' <param name="startRowIndex">The index of the first record to retrieve.</param> 
        ''' <param name="maximumRows">The maximum number of records to be returned.</param> 
        ''' <returns> 
        ''' A DeviceTrackingLogCollection. 
        ''' </returns> 
        Public Shared Function GetListByBarcodeInfo(ByVal QRANumber As String, ByVal BatchUnitNumber As Integer, ByVal startRowIndex As Integer, ByVal maximumRows As Integer) As DeviceTrackingLogCollection

            Dim tempList As DeviceTrackingLogCollection = Nothing
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectListByQRANumberUnitNumber", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", QRANumber)
                    myCommand.Parameters.AddWithValue("@BatchUnitNumber", BatchUnitNumber)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.HasRows Then
                            tempList = New DeviceTrackingLogCollection()
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
        ''' Returns a list with DeviceTrackingLog objects. 
        ''' </summary> 
        ''' <returns> 
        ''' A DeviceTrackingLogCollection. 
        ''' </returns> 
        Public Shared Function GetListByLocationDate(ByVal ID As Integer, ByVal OldestDate As DateTime) As DeviceTrackingLogCollection
            Dim tempList As DeviceTrackingLogCollection = Nothing
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectListByLocationDate", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TrackingLocationID", ID)
                    myCommand.Parameters.AddWithValue("@Date", OldestDate)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.HasRows Then
                            tempList = New DeviceTrackingLogCollection()
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
        ''' Returns a list with DeviceTrackingLog objects. 
        ''' </summary> 
        ''' <returns> 
        ''' A DeviceTrackingLogCollection. 
        ''' </returns> 
        Public Shared Function GetListByProductDate(ByVal lookupid As Int32, ByVal OldestDate As DateTime) As DeviceTrackingLogCollection
            Dim tempList As DeviceTrackingLogCollection = Nothing
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectListByProductDate", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@Lookupid", lookupid)
                    myCommand.Parameters.AddWithValue("@Date", OldestDate)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            tempList = New DeviceTrackingLogCollection()
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
        ''' Returns a list of Tracking records for a specific testunit before a specified date
        ''' </summary>
        ''' <param name="OldestDate"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetListByTestUnitIDDate(ByVal testUnitID As Integer, ByVal OldestDate As DateTime) As DeviceTrackingLogCollection
            Dim tempList As DeviceTrackingLogCollection = Nothing
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectListByTestUnitIDDate", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestUnitID", testUnitID)
                    myCommand.Parameters.AddWithValue("@Date", OldestDate)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            tempList = New DeviceTrackingLogCollection()
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
        ''' Returns a list with DeviceTrackingLog objects. 
        ''' </summary> 
        ''' <returns> 
        ''' A DeviceTrackingLogCollection. 
        ''' </returns> 
        Public Shared Function GetListByBarcodeDate(ByVal QRANumber As String, ByVal OldestDate As DateTime) As DeviceTrackingLogCollection
            Dim tempList As DeviceTrackingLogCollection = Nothing
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeviceTrackingLogSelectListByQRANumberDate", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", QRANumber)
                    myCommand.Parameters.AddWithValue("@Date", OldestDate)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            tempList = New DeviceTrackingLogCollection()
                            While myReader.Read()
                                tempList.Add(FillDataRecord(myReader))
                            End While
                        End If
                    End Using
                End Using
            End Using

            Return tempList
        End Function

        ''' <summary>Deletes a DeviceTrackingLog from the database.</summary> 
        ''' <param name="id">The ID of the DeviceTrackingLog to delete.</param> 
        ''' <returns>Returns <c>true</c> when the object was deleted successfully, or <c>false</c> otherwise.</returns> 
        Public Shared Function Delete(ByVal ID As Integer) As Boolean
            Dim Result As Integer = 0
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeviceTrackingLogDeleteSingleItem", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using

            Return CBool(Result)
        End Function
#End Region

#Region "Private Methods"
        ''' <summary>
        ''' Initializes a new instance of the DeviceTrackingLog class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the DeviceTrackingLog produced by a select query</param>
        ''' <returns>A DeviceTrackingLog object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord) As DeviceTrackingLog
            Dim dtl As New DeviceTrackingLog

            dtl.TestUnitID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestUnitID"))
            dtl.TrackingLocationID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TrackingLocationID"))
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("InTime")) Then
                dtl.InTime = myDataRecord.GetDateTime(myDataRecord.GetOrdinal("InTime"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TrackingLocationName")) Then
                dtl.TrackingLocationName = myDataRecord.GetString(myDataRecord.GetOrdinal("TrackingLocationName"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("QRANumber")) Then
                dtl.TestUnitQRANumber = myDataRecord.GetString(myDataRecord.GetOrdinal("QRANumber"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("BatchUnitNumber")) Then
                dtl.TestUnitBatchUnitNumber = myDataRecord.GetInt32(myDataRecord.GetOrdinal("BatchUnitNumber"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("InUser")) Then
                dtl.InUser = myDataRecord.GetString(myDataRecord.GetOrdinal("InUser"))
            Else
                dtl.InUser = String.Empty
            End If

            dtl.ID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID"))


            dtl.ConcurrencyID = DirectCast(myDataRecord.GetValue(myDataRecord.GetOrdinal("ConcurrencyID")), Byte())
            Return dtl
        End Function
#End Region

    End Class
End Namespace