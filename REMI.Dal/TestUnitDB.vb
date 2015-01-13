Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports System.Configuration
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.Dal
    ''' <summary>
    ''' The TestUnitDB class is responsible for interacting with the database to retrieve and store information 
    ''' about TestUnit objects.
    ''' </summary>
    Public Class TestUnitDB
#Region "Public Methods"
        Public Shared Function GetFastScanData(ByVal bc As DeviceBarcodeNumber, ByVal hostname As String, ByVal testStage As String, ByVal test As String, Optional ByVal trackingLocationName As String = "") As FastScanData
            Dim fsd As FastScanData = New FastScanData(test, testStage, bc)

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispScanGetData", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", bc.BatchNumber)
                    myCommand.Parameters.AddWithValue("@unitnumber", bc.UnitNumber)

                    If bc.TrackingLocationNumberAsInteger > 0 Then
                        myCommand.Parameters.AddWithValue("@selectedTrackingLocationID", bc.TrackingLocationNumberAsInteger)
                    End If

                    If Not String.IsNullOrEmpty(testStage) Then
                        myCommand.Parameters.AddWithValue("@selectedTestStageName", testStage)
                    End If

                    If Not String.IsNullOrEmpty(test) Then
                        myCommand.Parameters.AddWithValue("@selectedTestName", test)
                    End If

                    If Not String.IsNullOrEmpty(hostname) Then
                        myCommand.Parameters.AddWithValue("@hostname", hostname)
                    End If

                    If Not String.IsNullOrEmpty(trackingLocationName) Then
                        myCommand.Parameters.AddWithValue("@trackingLocationName", trackingLocationName)
                    End If

                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentDtlID")) Then
                                    fsd.LastTrackingLog.ID = myReader.GetInt32(myReader.GetOrdinal("currentDtlID"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("testunitid")) Then
                                    fsd.LastTrackingLog.TestUnitID = myReader.GetInt32(myReader.GetOrdinal("testunitid"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentDtlInTime")) Then
                                    fsd.LastTrackingLog.InTime = myReader.GetDateTime(myReader.GetOrdinal("currentDtlInTime"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentDtlOutTime")) Then
                                    fsd.LastTrackingLog.OutTime = myReader.GetDateTime(myReader.GetOrdinal("currentDtlOutTime"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentDtlInUser")) Then
                                    fsd.LastTrackingLog.InUser = myReader.GetString(myReader.GetOrdinal("currentDtlInUser"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentDtlOutUser")) Then
                                    fsd.LastTrackingLog.InUser = myReader.GetString(myReader.GetOrdinal("currentDtlOutUser"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentDtlTrackingLocationName")) Then
                                    fsd.LastTrackingLog.TrackingLocationName = myReader.GetString(myReader.GetOrdinal("currentDtlTrackingLocationName"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentDtlTrackingLocationID")) Then
                                    fsd.LastTrackingLog.TrackingLocationID = myReader.GetInt32(myReader.GetOrdinal("currentDtlTrackingLocationID"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestID")) Then
                                    fsd.TestID = Convert.ToInt32(myReader.GetInt32(myReader.GetOrdinal("selectedTestID")))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("ProductID")) Then
                                    fsd.ProductID = Convert.ToInt32(myReader.GetInt32(myReader.GetOrdinal("ProductID")))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("isBBX")) Then
                                    fsd.IsBBX = Convert.ToBoolean(myReader.GetString(myReader.GetOrdinal("isBBX")))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentTeststage")) Then
                                    fsd.CurrentTestStage = myReader.GetString(myReader.GetOrdinal("currentTeststage"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentTest")) Then
                                    fsd.CurrentTestName = myReader.GetString(myReader.GetOrdinal("currentTest"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentTestRecordStatus")) Then
                                    fsd.CurrentTestRecordStatus = DirectCast(myReader.GetInt32(myReader.GetOrdinal("currentTestRecordStatus")), TestRecordStatus)
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentTestRecordID")) Then
                                    fsd.CurrentTestRecordID = myReader.GetInt32(myReader.GetOrdinal("currentTestRecordID"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentTestRequiredTestTime")) Then
                                    fsd.CurrentTestRequiredTestTime = TimeSpan.FromHours(myReader.GetDouble(myReader.GetOrdinal("currentTestRequiredTestTime")))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("currentTestTotaltestTime")) Then
                                    fsd.CurrentTestTotalTestTime = TimeSpan.FromMinutes(myReader.GetDouble(myReader.GetOrdinal("currentTestTotaltestTime")))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("CurrentTestIsTimed")) Then
                                    fsd.CurrentTestIsTimed = myReader.GetBoolean(myReader.GetOrdinal("CurrentTestIsTimed"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("CurrentTestType")) Then
                                    fsd.CurrentTestType = DirectCast(myReader.GetInt32(myReader.GetOrdinal("CurrentTestType")), TestType)
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("batchStatus")) Then
                                    fsd.BatchStatus = DirectCast(myReader.GetInt32(myReader.GetOrdinal("batchStatus")), BatchStatus)
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("infa")) Then
                                    fsd.IsInFA = myReader.GetBoolean(myReader.GetOrdinal("infa"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("productgroup")) Then
                                    fsd.ProductGroupName = myReader.GetString(myReader.GetOrdinal("productgroup"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("jobWILocation")) Then
                                    fsd.JobWI = myReader.GetString(myReader.GetOrdinal("jobWILocation"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("jobName")) Then
                                    fsd.JobName = myReader.GetString(myReader.GetOrdinal("jobName"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("BSN")) Then
                                    fsd.BSN = myReader.GetInt64(myReader.GetOrdinal("BSN"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTLCapacityRemaining")) Then
                                    fsd.SelectedTrackingLocationCapacityRemaining = myReader.GetInt32(myReader.GetOrdinal("selectedTLCapacityRemaining"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTrackingLocationName")) Then
                                    fsd.SelectedTrackingLocationName = myReader.GetString(myReader.GetOrdinal("selectedTrackingLocationName"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTrackingLocationID")) Then
                                    fsd.SelectedTrackingLocationID = myReader.GetInt32(myReader.GetOrdinal("selectedTrackingLocationID"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestStageIsValid")) Then
                                    fsd.SelectedTestStageIsValidForJob = myReader.GetBoolean(myReader.GetOrdinal("selectedTestStageIsValid"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestIsValid")) Then
                                    fsd.SelectedTestIsValidForTestStage = myReader.GetBoolean(myReader.GetOrdinal("selectedTestIsValid"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestIsMarkedDoNotProcess")) Then
                                    fsd.SelectedTestIsDNP = myReader.GetBoolean(myReader.GetOrdinal("selectedTestIsMarkedDoNotProcess"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestType")) Then
                                    fsd.SelectedTestType = DirectCast(myReader.GetInt32(myReader.GetOrdinal("selectedTestType")), TestType)
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTrackinglocationCurrentTestName")) Then
                                    fsd.SelectedTrackingLocationCurrentTestName = myReader.GetString(myReader.GetOrdinal("selectedTrackinglocationCurrentTestName"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestRecordStatus")) Then
                                    fsd.SelectedTestRecordStatus = DirectCast(myReader.GetInt32(myReader.GetOrdinal("selectedTestRecordStatus")), TestRecordStatus)
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTrackingLocationWILocation")) Then
                                    fsd.SelectedTrackingLocationWI = myReader.GetString(myReader.GetOrdinal("selectedTrackingLocationWILocation"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTrackingLocationFunction")) Then
                                    fsd.SelectedTrackingLocationFunction = DirectCast(myReader.GetInt32(myReader.GetOrdinal("selectedTrackingLocationFunction")), TrackingLocationFunction)
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestRecordID")) Then
                                    fsd.SelectedTestRecordID = myReader.GetInt32(myReader.GetOrdinal("selectedTestRecordID"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestIsValidForLocation")) Then
                                    fsd.SelectedTestIsValidForTrackingLocation = myReader.GetBoolean(myReader.GetOrdinal("selectedTestIsValidForLocation"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestIsTimed")) Then
                                    fsd.SelectedTestIsTimed = myReader.GetBoolean(myReader.GetOrdinal("selectedTestIsTimed"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedLocationNumberOfScans")) Then
                                    fsd.SelectedTestNumberOfScans = myReader.GetInt32(myReader.GetOrdinal("selectedLocationNumberOfScans"))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestRequiredTestTime")) Then
                                    fsd.SelectedTestRequiredTestTime = TimeSpan.FromHours(myReader.GetDouble(myReader.GetOrdinal("selectedTestRequiredTestTime")))
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestTotaltestTime")) Then
                                    fsd.SelectedTestTotalTestTime = TimeSpan.FromMinutes(myReader.GetDouble(myReader.GetOrdinal("selectedTestTotaltestTime")))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("CPRNumber")) Then
                                    fsd.CPRNumber = myReader.GetString(myReader.GetOrdinal("CPRNumber"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("selectedTestWILocation")) Then
                                    fsd.TestWILink = myReader.GetString(myReader.GetOrdinal("selectedTestWILocation"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("HWrevision")) Then
                                    fsd.HWRevision = myReader.GetString(myReader.GetOrdinal("HWrevision"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("ApplicableTestStages")) Then
                                    fsd.ApplicableTestStages = myReader.GetString(myReader.GetOrdinal("ApplicableTestStages")).Split(","c)
                                End If
                                If Not myReader.IsDBNull(myReader.GetOrdinal("ApplicableTests")) Then
                                    fsd.ApplicableTests = myReader.GetString(myReader.GetOrdinal("ApplicableTests")).Split(","c)
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("NoBSN")) Then
                                    fsd.NoBSN = myReader.GetBoolean(myReader.GetOrdinal("NoBSN"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("AccessoryTypeID")) Then
                                    fsd.AccessoryTypeID = myReader.GetInt32(myReader.GetOrdinal("AccessoryTypeID"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("ProductTypeID")) Then
                                    fsd.ProductTypeID = myReader.GetInt32(myReader.GetOrdinal("ProductTypeID"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("AccessoryType")) Then
                                    fsd.AccessoryType = myReader.GetString(myReader.GetOrdinal("AccessoryType"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("ProductType")) Then
                                    fsd.ProductType = myReader.GetString(myReader.GetOrdinal("ProductType"))
                                End If
                            End While
                        End If
                    End Using
                End Using
            End Using
            Return fsd
        End Function

        Public Shared Function GetTestUnitsNotInREMSTAR() As List(Of SimpleTestUnit)
            Dim results As List(Of SimpleTestUnit) = New List(Of SimpleTestUnit)
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesSelectBatchesNotInREMSTAR", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                results.Add(New SimpleTestUnit(myReader.GetString(0), myReader.GetInt32(1), myReader.GetString(2), myReader.GetString(4), myReader.GetDateTime(3)))
                            End While
                        End If
                    End Using
                End Using
            End Using
            Return results
        End Function

        Public Shared Function SaveFastScanData(ByVal scanData As FastScanData) As Integer
            Dim result As Integer = -1

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispScanSaveData", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    If scanData.Barcode.UnitNumber > 0 Then
                        myCommand.Parameters.AddWithValue("@unitnumber", scanData.Barcode.UnitNumber)
                    End If
                    If Not String.IsNullOrEmpty(scanData.Barcode.BatchNumber) Then
                        myCommand.Parameters.AddWithValue("@qranumber", scanData.Barcode.BatchNumber)
                    End If
                    If scanData.SelectedTrackingLocationID > 0 Then
                        myCommand.Parameters.AddWithValue("@selectedTrackingLocationID", scanData.SelectedTrackingLocationID)
                    End If
                    If Not String.IsNullOrEmpty(scanData.SelectedTestStage) Then
                        myCommand.Parameters.AddWithValue("@selectedTestStageName", scanData.SelectedTestStage)
                    End If
                    If Not String.IsNullOrEmpty(scanData.JobName) Then
                        myCommand.Parameters.AddWithValue("@jobName", scanData.JobName)
                    End If
                    If Not String.IsNullOrEmpty(scanData.SelectedTestName) Then
                        myCommand.Parameters.AddWithValue("@selectedTestName", scanData.SelectedTestName)
                    End If
                    If Not String.IsNullOrEmpty(scanData.CurrentUserName) Then
                        myCommand.Parameters.AddWithValue("@username", scanData.CurrentUserName)
                    End If
                    myCommand.Parameters.AddWithValue("@currentTestRecordStatusModified", scanData.CurrentTestRecordStatusModified)
                    If scanData.CurrentTestRecordStatusModified Then
                        myCommand.Parameters.AddWithValue("@currentTestRecordStatus", scanData.CurrentTestRecordStatus)
                        myCommand.Parameters.AddWithValue("@currentTestRecordID", scanData.CurrentTestRecordID)
                    End If
                    myCommand.Parameters.AddWithValue("@selectedTestRecordStatusModified", scanData.SelectedTestRecordStatusModified)
                    If scanData.SelectedTestRecordStatus <> TestRecordStatus.NotSet Then
                        myCommand.Parameters.AddWithValue("@selectedTestRecordStatus", scanData.SelectedTestRecordStatus)
                    End If
                    If scanData.SelectedTestRecordID > 0 Then
                        myCommand.Parameters.AddWithValue("@selectedTestRecordID", scanData.SelectedTestRecordID)
                    End If

                    Dim returnValue As New SqlParameter("ReturnValue", SqlDbType.Int)
                    returnValue.Direction = ParameterDirection.ReturnValue
                    myCommand.Parameters.Add(returnValue)

                    myConnection.Open()
                    myCommand.ExecuteScalar()
                    result = Convert.ToInt32(returnValue.Value)

                    If (scanData.CurrentTestRecordStatusModified OrElse scanData.SelectedTestRecordStatusModified) Then
                        REMIAppCache.ClearAllBatchData(scanData.Barcode.BatchNumber)
                    End If
                End Using
            End Using
            Return result
        End Function

        Public Shared Function GetAvailableUnits(ByVal QRANumber As String, ByVal excludedUnitNumber As Int32) As List(Of String)
            Dim units As New List(Of String)

            Using myconnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                myconnection.Open()
                Using myCommand As New SqlCommand("remispTestUnitsAvailable", myconnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", QRANumber)

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                If (myReader("BatchUnitNumber").ToString() <> excludedUnitNumber.ToString()) Then
                                    units.Add(myReader("BatchUnitNumber").ToString())
                                End If
                            End While
                        End If
                    End Using
                End Using
            End Using

            Return units
        End Function

        Public Shared Function GetUsersUnits(ByVal userID As Int32, Optional ByVal includeCompletedQRA As Boolean = False) As TestUnitCollection
            Dim tempList As TestUnitCollection = Nothing
            Using myconnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                myconnection.Open()

                Using myCommand As New SqlCommand("remispTestUnitsSelectListByLastUser", myconnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    If userID > 0 Then
                        myCommand.Parameters.AddWithValue("@UserID", userID)
                    End If

                    myCommand.Parameters.AddWithValue("@includeCompletedQRA", includeCompletedQRA)

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            tempList = New TestUnitCollection()
                            While myReader.Read()
                                tempList.Add(FillDataRecord(myReader))
                            End While
                        End If
                    End Using
                End Using
            End Using
            If tempList IsNot Nothing Then
                Return tempList
            Else
                Return New TestUnitCollection
            End If
        End Function

        Public Shared Function UnitSearch(ByVal us As TestUnitCriteria) As DataTable
            Dim dt As New DataTable

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispUnitSearch", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

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
                    dt.TableName = "UnitSearch"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetUnit(ByVal qraNumber As String, ByVal unitNumber As Int32) As TestUnit
            Dim unit As TestUnit = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestUnitsSearchFor", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    If Not String.IsNullOrEmpty(qraNumber) Then
                        myCommand.Parameters.AddWithValue("@QRANumber", qraNumber)
                    End If

                    If unitNumber > 0 Then
                        myCommand.Parameters.AddWithValue("@UnitNumber", unitNumber)
                    End If

                    If myConnection.State <> ConnectionState.Open Then
                        myConnection.Open()
                    End If

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            myReader.Read()
                            unit = FillDataRecord(myReader)
                        End If
                    End Using
                End Using
            End Using

            Return unit
        End Function

        Public Shared Function GetBatchUnits(ByVal qraNumber As String, ByVal myconnection As SqlConnection) As TestUnitCollection
            Dim tempList As TestUnitCollection = Nothing

            Using myCommand As New SqlCommand("remispTestUnitsSearchFor", myconnection)
                myCommand.CommandType = CommandType.StoredProcedure

                If Not String.IsNullOrEmpty(qraNumber) Then
                    myCommand.Parameters.AddWithValue("@QRANumber", qraNumber)
                End If

                If myconnection.State <> ConnectionState.Open Then
                    myconnection.Open()
                End If

                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                    If myReader.HasRows Then
                        tempList = New TestUnitCollection()
                        While myReader.Read()
                            tempList.Add(FillDataRecord(myReader))
                        End While
                    End If
                End Using
            End Using

            If tempList IsNot Nothing Then
                Return tempList
            Else
                Return New TestUnitCollection
            End If
        End Function

        ''' <summary>Sets the BSN for a test unit.</summary> 
        ''' <param name="QRANumber">The QRA Number of the batch to save.</param> 
        ''' <param name="UnitNumber">The unit number of the test unit to save.</param>
        ''' <param name="BSN">The BSN of the test unit to save.</param>
        ''' <returns>Returns true when the BSN was set successfully, or false otherwise.</returns> 
        Public Shared Function SaveBSN(ByVal QRANumber As String, ByVal UnitNumber As Integer, ByVal BSN As Long, ByVal UpdateUser As String) As Boolean
            Dim NumberOfRecordsAffected As Integer

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestUnitsSetBSN", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", QRANumber)
                    myCommand.Parameters.AddWithValue("@UnitNumber", UnitNumber)
                    myCommand.Parameters.AddWithValue("@BSN", BSN)
                    myCommand.Parameters.AddWithValue("@UpdateUser", UpdateUser)
                    myConnection.Open()
                    NumberOfRecordsAffected = myCommand.ExecuteNonQuery()
                End Using
            End Using

            If NumberOfRecordsAffected = 0 Then
                Return False
            Else
                Return True
            End If
        End Function

        ''' <summary>Saves an instance of the <see cref="TestUnit" /> in the database.</summary> 
        ''' <param name="myTestUnit">The TestUnit instance to save.</param> 
        ''' <returns>Returns the id when the object was saved successfully, or 0 otherwise.</returns> 
        Public Shared Function Save(ByVal MyTestUnit As TestUnit) As Integer
            If Not MyTestUnit.Validate() Then
                Throw New InvalidSaveOperationException("Can't save a TestUnit in an Invalid state. Make sure that IsValid() returns true before you call Save().")
            End If

            Dim Result As Integer = 0

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestUnitsInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", MyTestUnit.QRANumber)
                    myCommand.Parameters.AddWithValue("@BatchUnitNumber", MyTestUnit.BatchUnitNumber)
                    myCommand.Parameters.AddWithValue("@BSN", MyTestUnit.BSN)

                    If Not String.IsNullOrEmpty(MyTestUnit.AssignedTo) Then
                        myCommand.Parameters.AddWithValue("@AssignedTo", MyTestUnit.AssignedTo)
                    End If

                    If MyTestUnit.CurrentTestStage IsNot Nothing AndAlso Not String.IsNullOrEmpty(MyTestUnit.CurrentTestStage.Name) Then
                        myCommand.Parameters.AddWithValue("@CurrentTestStageName", MyTestUnit.CurrentTestStage.Name)
                    End If

                    If String.IsNullOrEmpty(MyTestUnit.AssignedTo) Then
                        MyTestUnit.AssignedTo = String.Empty
                    End If

                    If MyTestUnit.CurrentTest IsNot Nothing AndAlso Not String.IsNullOrEmpty(MyTestUnit.CurrentTest.Name) Then
                        myCommand.Parameters.AddWithValue("@CurrentTestName", MyTestUnit.CurrentTest.Name)
                    End If

                    If MyTestUnit.Comments IsNot Nothing AndAlso Not String.IsNullOrEmpty(MyTestUnit.Comments) Then
                        myCommand.Parameters.AddWithValue("@Comment", MyTestUnit.Comments)
                    End If

                    myCommand.Parameters.AddWithValue("@IMEI", MyTestUnit.IMEI)

                    Helpers.SetSaveParameters(myCommand, MyTestUnit)
                    myConnection.Open()

                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()

                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("Can't update the TestUnit as it has been updated by someone else.")
                    End If

                    MyTestUnit.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)

                    Result = Helpers.GetBusinessBaseId(myCommand)
                    If MyTestUnit.ID = 0 Then
                        MyTestUnit.ID = Result
                    End If
                End Using
            End Using

            Return Result
        End Function

        ''' <summary>
        ''' Adds a test unit to a batch.
        ''' </summary>
        ''' <remarks></remarks>
        Public Shared Sub AddNewUnitToBatch(ByVal tu As TestUnit)
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestUnitsAddUnitToBatch", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", tu.QRANumber)
                    myCommand.Parameters.AddWithValue("@BatchUnitNumber", tu.BatchUnitNumber)
                    myCommand.Parameters.AddWithValue("@BSN", 0)
                    myCommand.Parameters.AddWithValue("@LastUser", tu.LastUser)
                    myCommand.Parameters.AddWithValue("@ID", 0)
                    myCommand.Parameters.AddWithValue("@TestStageName", tu.CurrentTestStageName)
                    myCommand.Parameters("@ID").Direction = ParameterDirection.Output
                    myConnection.Open()

                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()
                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("The test unit could not be saved.")
                    End If

                    tu.ID = Helpers.GetBusinessBaseId(myCommand)
                End Using
            End Using
        End Sub
#End Region

#Region "Private Methods"
        ''' <summary>
        ''' Initializes a new instance of the TestUnit class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the TestUnit produced by a select query</param>
        ''' <returns>A TestUnit object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Public Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord) As TestUnit
            Dim myTestUnit As New TestUnit()

            'Get the non nullable records
            myTestUnit.QRANumber = myDataRecord.GetString(myDataRecord.GetOrdinal("QRANumber"))
            myTestUnit.BatchUnitNumber = myDataRecord.GetInt32(myDataRecord.GetOrdinal("BatchUnitNumber"))

            'Get the nullable records
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Comment")) Then
                myTestUnit.Comments = myDataRecord.GetString(myDataRecord.GetOrdinal("Comment"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("AssignedTo")) Then
                myTestUnit.AssignedTo = myDataRecord.GetString(myDataRecord.GetOrdinal("AssignedTo"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("BSN")) Then
                myTestUnit.BSN = myDataRecord.GetInt64(myDataRecord.GetOrdinal("BSN"))
            Else
                myTestUnit.BSN = 0
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("CurrentTestName")) Then
                myTestUnit.CurrentTestName = myDataRecord.GetString(myDataRecord.GetOrdinal("CurrentTestName"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestCenterLocationID")) Then
                myTestUnit.TestCenterID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestCenterLocationID"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("dtlcid")) Then
                If (myDataRecord.GetValue(myDataRecord.GetOrdinal("dtlcid")) IsNot System.DBNull.Value) Then
                    myTestUnit.CurrentLog.ConcurrencyID = DirectCast(myDataRecord.GetValue(myDataRecord.GetOrdinal("dtlcid")), Byte())
                End If
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("dtlid")) Then
                myTestUnit.CurrentLog.ID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("dtlid"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("dtlintime")) Then
                myTestUnit.CurrentLog.InTime = myDataRecord.GetDateTime(myDataRecord.GetOrdinal("dtlintime"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("dtlinuser")) Then
                myTestUnit.CurrentLog.InUser = myDataRecord.GetString(myDataRecord.GetOrdinal("dtlinuser"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TrackingLocationName")) Then
                myTestUnit.CurrentLog.TrackingLocationName = myDataRecord.GetString(myDataRecord.GetOrdinal("TrackingLocationName"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("dtltlid")) Then
                myTestUnit.CurrentLog.TrackingLocationID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("dtltlid"))
            End If

            If Helpers.HasColumn(myDataRecord, "CurrentTestStageID") Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("CurrentTestStageID")) Then
                    myTestUnit.CurrentTestStage = TestStageDB.GetItem(myDataRecord.GetInt32(myDataRecord.GetOrdinal("CurrentTestStageID")), myDataRecord.GetString(myDataRecord.GetOrdinal("CurrentTestStageName")), myDataRecord.GetString(myDataRecord.GetOrdinal("JobName")))
                End If
            End If

            If (Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("CurrentTestStageName")) And myTestUnit.CurrentTestStage Is Nothing) Then
                myTestUnit.CurrentTestStage.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("CurrentTestStageName"))
            End If

            If Helpers.HasColumn(myDataRecord, "NoBSN") Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("NoBSN")) Then
                    myTestUnit.NoBSN = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("NoBSN"))
                End If
            End If

            If Helpers.HasColumn(myDataRecord, "IMEI") Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("IMEI")) Then
                    myTestUnit.IMEI = myDataRecord.GetString(myDataRecord.GetOrdinal("IMEI"))
                Else
                    myTestUnit.IMEI = String.Empty
                End If
            Else
                myTestUnit.IMEI = String.Empty
            End If

            'get the std records
            Helpers.FillObjectParameters(myDataRecord, myTestUnit)

            Return myTestUnit
        End Function
#End Region
    End Class
End Namespace