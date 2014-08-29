Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.Common
Imports System.Collections.Generic
Imports System.Data.OracleClient
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.Dal
    ''' <summary>
    ''' The TestRecordDB class is responsible for interacting with the database to retrieve and store information 
    ''' about TestRecord objects.
    ''' </summary>
    Public Class TestRecordDB

#Region "Public Methods"

#Region "Old Relab DB Functions"
        ''' <summary>
        ''' Accesses the FA System and attempts to get a list of FA's for a particular QRA.
        ''' </summary>
        ''' <param name="QRANumber">the QRA number of the batch </param>
        ''' <returns>A list of FA numbers</returns>
        ''' <remarks></remarks>
        Public Shared Function GetFANumberList(ByVal QRANumber As String) As List(Of String)
            Dim FAQRANumberList As New List(Of String)
            Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(RequestDB.GetConnectString(QRANumber)))
                Using myCommand As New OracleCommand("REMI_HELPER.get_FAs_by_QRA", myConnection)

                    myCommand.CommandType = CommandType.StoredProcedure
                    Dim pOut As New OracleParameter
                    pOut.Direction = ParameterDirection.ReturnValue
                    pOut.OracleType = OracleType.Cursor
                    pOut.ParameterName = "C_REF_RET"
                    myCommand.Parameters.Add(pOut)

                    Dim pQRANumber As New OracleParameter
                    pQRANumber.Direction = ParameterDirection.Input
                    pQRANumber.OracleType = OracleType.VarChar
                    pQRANumber.ParameterName = "p_qra_num"
                    pQRANumber.Value = QRANumber

                    myCommand.Parameters.Add(pQRANumber)
                    myConnection.Open()
                    Using myReader As OracleDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            While myReader.Read()
                                FAQRANumberList.Add(myReader.GetValue(0).ToString)
                            End While
                        End If
                    End Using
                End Using
            End Using

            Return FAQRANumberList
        End Function

        'Public Shared Function GetFastTestResultsFromRelab(ByVal rrC As RelabResultCriteria, ByVal myconnection As OracleConnection) As TestResultCollection
        '    Dim testResults As New TestResultCollection
        '    Using myCommand As New OracleCommand("REMI_HELPER.get_last_results", myconnection)

        '        myCommand.CommandType = CommandType.StoredProcedure
        '        Dim pOut As New OracleParameter
        '        pOut.Direction = ParameterDirection.ReturnValue
        '        pOut.OracleType = OracleType.Cursor
        '        pOut.ParameterName = "C_REF_RET"
        '        myCommand.Parameters.Add(pOut)

        '        Dim pQRANumber As New OracleParameter
        '        pQRANumber.Direction = ParameterDirection.Input
        '        pQRANumber.OracleType = OracleType.VarChar
        '        pQRANumber.ParameterName = "p_qra_num"
        '        pQRANumber.Value = rrC.QRANumber
        '        myCommand.Parameters.Add(pQRANumber)

        '        Using myReader As OracleDataReader = myCommand.ExecuteReader
        '            If myReader.HasRows Then
        '                While myReader.Read()
        '                    'VerNum, pass/fail,testtype,teststage, unit
        '                    testResults.Add(New TestResult(TestResultSource.Relab, CInt(myReader.GetOracleNumber(0)), myReader.GetOracleString(4).ToString, myReader.GetOracleString(3).ToString, myReader.GetOracleString(2).ToString, CInt(myReader.GetOracleNumber(1))))
        '                End While
        '            End If
        '        End Using

        '    End Using
        '    Return testResults
        'End Function

        'Public Shared Function GetParamterResults(ByVal qraNumber As String, ByVal jobName As String, ByVal testStage As String) As ParameterResultCollection
        '    Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringTRS)
        '        myConnection.Open()
        '        Return GetParamterResults(qraNumber, jobName, testStage, myConnection)
        '    End Using
        'End Function

        'Public Shared Function GetParamterResultByeasurement(ByVal qraNumber As String, ByVal jobName As String, ByVal unitnumber As Int32, ByVal testStage As String, ByVal measurementType As String, ByVal myConnection As OracleConnection) As ParameterResult
        '    Dim paramResult As New ParameterResult
        '    Dim trsTestStageString As String = String.Format("{0} - {1}", jobName, testStage)

        '    Using myCommand As New OracleCommand("REMI_HELPER.get_result_By_Measurement", myConnection)
        '        myCommand.CommandType = CommandType.StoredProcedure
        '        Dim pOut As New OracleParameter
        '        pOut.Direction = ParameterDirection.ReturnValue
        '        pOut.OracleType = OracleType.Cursor
        '        pOut.ParameterName = "C_REF_RET"
        '        myCommand.Parameters.Add(pOut)

        '        Dim pQRANumber As New OracleParameter
        '        pQRANumber.Direction = ParameterDirection.Input
        '        pQRANumber.OracleType = OracleType.VarChar
        '        pQRANumber.ParameterName = "p_qra_num"
        '        pQRANumber.Value = qraNumber
        '        myCommand.Parameters.Add(pQRANumber)

        '        Dim pStage As New OracleParameter
        '        pStage.Direction = ParameterDirection.Input
        '        pStage.OracleType = OracleType.VarChar
        '        pStage.ParameterName = "p_stage"
        '        pStage.Value = trsTestStageString
        '        myCommand.Parameters.Add(pStage)

        '        Dim pUnit As New OracleParameter
        '        pUnit.Direction = ParameterDirection.Input
        '        pUnit.OracleType = OracleType.Int32
        '        pUnit.ParameterName = "p_unit"
        '        pUnit.Value = unitnumber
        '        myCommand.Parameters.Add(pUnit)

        '        Dim pMeasurement As New OracleParameter
        '        pMeasurement.Direction = ParameterDirection.Input
        '        pMeasurement.OracleType = OracleType.VarChar
        '        pMeasurement.ParameterName = "p_measurement"
        '        pMeasurement.Value = measurementType
        '        myCommand.Parameters.Add(pMeasurement)

        '        If myConnection.State <> ConnectionState.Open Then
        '            myConnection.Open()
        '        End If

        '        Using myReader As OracleDataReader = myCommand.ExecuteReader
        '            If myReader.HasRows Then
        '                paramResult.Job = jobName
        '                paramResult.TestStage = testStage
        '                paramResult.MeasuredValue = myReader.GetOracleString(1).ToString.Trim()
        '                paramResult.ParameterName = myReader.GetOracleString(2).ToString().Trim()
        '            End If
        '        End Using
        '    End Using

        '    Return paramResult
        'End Function

        'Public Shared Function GetParamterResults(ByVal qraNumber As String, ByVal jobName As String, ByVal testStage As String, ByVal myConnection As OracleConnection) As ParameterResultCollection
        '    Dim paramResults As New ParameterResultCollection
        '    Dim trsTestStageString As String = String.Format("{0} - {1}", jobName, testStage)

        '    Using myCommand As New OracleCommand("REMI_HELPER.get_paramater_results", myConnection)
        '        myCommand.CommandType = CommandType.StoredProcedure
        '        Dim pOut As New OracleParameter
        '        pOut.Direction = ParameterDirection.ReturnValue
        '        pOut.OracleType = OracleType.Cursor
        '        pOut.ParameterName = "C_REF_RET"
        '        myCommand.Parameters.Add(pOut)

        '        Dim pQRANumber As New OracleParameter
        '        pQRANumber.Direction = ParameterDirection.Input
        '        pQRANumber.OracleType = OracleType.VarChar
        '        pQRANumber.ParameterName = "p_qra_num"
        '        pQRANumber.Value = qraNumber
        '        myCommand.Parameters.Add(pQRANumber)

        '        If Not String.IsNullOrEmpty(testStage) Then
        '            Dim pStage As New OracleParameter
        '            pStage.Direction = ParameterDirection.Input
        '            pStage.OracleType = OracleType.VarChar
        '            pStage.ParameterName = "p_stage"
        '            pStage.Value = trsTestStageString
        '            myCommand.Parameters.Add(pStage)
        '        End If

        '        Dim pZeroForFailsOnly As New OracleParameter
        '        pZeroForFailsOnly.Direction = ParameterDirection.Input
        '        pZeroForFailsOnly.OracleType = OracleType.VarChar
        '        pZeroForFailsOnly.ParameterName = "p_zero_for_fails_only"
        '        pZeroForFailsOnly.Value = "0"
        '        myCommand.Parameters.Add(pZeroForFailsOnly)
        '        If myConnection.State <> ConnectionState.Open Then
        '            myConnection.Open()
        '        End If
        '        Using myReader As OracleDataReader = myCommand.ExecuteReader
        '            If myReader.HasRows Then
        '                Dim pr As ParameterResult
        '                While myReader.Read()
        '                    pr = New ParameterResult
        '                    Dim resultTestStageString As String() = myReader.GetOracleString(0).ToString.Split("-"c)
        '                    pr.Job = resultTestStageString(0).Trim()
        '                    pr.TestStage = resultTestStageString(1).Trim()

        '                    pr.LowerLimit = myReader.GetOracleString(4).ToString.Trim()
        '                    pr.MeasuredValue = myReader.GetOracleString(6).ToString.Trim()
        '                    pr.Param = myReader.GetOracleString(3).ToString.Trim()
        '                    pr.ParameterName = myReader.GetOracleString(2).ToString().Trim()
        '                    pr.Result = myReader.GetOracleString(7).ToString.Trim()
        '                    pr.TestName = myReader.GetOracleString(1).ToString.Trim()
        '                    pr.UnitNumber = CInt(myReader.GetOracleNumber(9))
        '                    pr.Units = myReader.GetOracleString(8).ToString.Trim()
        '                    pr.UpperLimit = myReader.GetOracleString(5).ToString.Trim()

        '                    paramResults.Add(pr)
        '                End While
        '            End If
        '        End Using

        '    End Using
        '    Return paramResults
        'End Function

        ''' <summary>
        ''' Accesses the RIT System and attempts to get a list of RIT's for a particular Product Group.
        ''' </summary>
        ''' <param name="ProductGroupName">the name of the productgroup </param>
        ''' <returns>A list of RIT numbers</returns>
        ''' <remarks></remarks>
        Public Shared Function GetRITNumberList(ByVal ProductGroupName As String, ByVal reqNumber As String) As List(Of String)
            Dim RITNumberList As New List(Of String)
            Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(RequestDB.GetConnectString(reqNumber)))

                Using myCommand As New OracleCommand("REMI_HELPER.get_active_RIT_by_product", myConnection)

                    myCommand.CommandType = CommandType.StoredProcedure
                    Dim pOut As New OracleParameter
                    pOut.Direction = ParameterDirection.ReturnValue
                    pOut.OracleType = OracleType.Cursor
                    pOut.ParameterName = "C_REF_RET"
                    myCommand.Parameters.Add(pOut)

                    Dim pQRANumber As New OracleParameter
                    pQRANumber.Direction = ParameterDirection.Input
                    pQRANumber.OracleType = OracleType.VarChar
                    pQRANumber.ParameterName = "p_product"
                    pQRANumber.Value = ProductGroupName
                    myCommand.Parameters.Add(pQRANumber)
                    myConnection.Open()

                    Using myReader As OracleDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            While myReader.Read()
                                RITNumberList.Add(myReader.GetValue(0).ToString)
                            End While
                        End If
                    End Using
                End Using
            End Using
            Return RITNumberList
        End Function
#End Region

        Public Shared Function SetResultsForBatchCollection(ByVal bcoll As BatchCollection, ByVal username As String) As Integer
            Dim totalUpdateCount As Integer
            Dim batchUpdateCount As Integer
            Dim resultCollection As TestResultCollection

            For Each b As Batch In bcoll
                batchUpdateCount = 0
                Try
                    Dim currentResult As TestResult
                    Dim batchResultCollection As TestRecordCollection = b.GetTestRecordsToCheckForRelabUpdates

                    For Each tr As TestRecord In batchResultCollection
                        Dim testName As String = tr.TestName
                        Dim testID As Int32 = tr.TestID
                        Dim testStageName As String = tr.TestStageName
                        Dim testStageID As Int32 = tr.TestStageID
                        Dim jobName As String = tr.JobName
                        Dim batchUnitNumber As Int32 = tr.BatchUnitNumber
                        Dim resultSource As TestResultSource = tr.ResultSource

                        resultCollection = RelabDB.GetTestResults(b.ID, testStageID)
                        currentResult = (From res As TestResult In resultCollection Where res.TestID = testID And res.TestStageID = testStageID And res.UnitNumber = batchUnitNumber And res.JobName = jobName And res.Result <> FinalTestResult.NotSet Select res).Take(1).SingleOrDefault()

                        If currentResult IsNot Nothing Then
                            Dim doUpdate As Boolean = True

                            If (tr.ResultSource = TestResultSource.Manual And tr.CurrentRelabResultVersion = currentResult.Version) Then
                                doUpdate = False
                            End If

                            If (doUpdate) Then
                                tr.CurrentRelabResultVersion = currentResult.Version
                                tr.LastUser = username
                                tr.SetStatusByResult(currentResult, True)

                                If Save(tr) > 0 Then
                                    b.TestRecords.Add(tr)
                                    batchUpdateCount += 1
                                End If
                            End If
                        End If
                    Next
                Catch ex As Exception
                    Emailer.SendErrorEMail("Error retrieving results from database.", "Batch: " + b.QRANumber, NotificationType.Errors, ex)
                End Try

                totalUpdateCount += batchUpdateCount
            Next

            Return totalUpdateCount
        End Function

        Public Shared Function SelectOne(ByVal ID As Integer) As TestRecord
            Dim tempTR As New TestRecord
            Using myconnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestRecordsSelectOne", myconnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myconnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.Read() Then
                            tempTR = FillDataRecord(myReader)
                        End If
                    End Using
                End Using
            End Using
            Return tempTR
        End Function

        Public Shared Function SelectByStatus(ByVal status As TestRecordStatus) As TestRecordCollection
            Dim tempTRList As New TestRecordCollection
            Using myconnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestRecordsSelectByStatus", myconnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@status", status)

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                tempTRList.Add(FillDataRecord(myReader))
                            End While
                        End If
                    End Using
                End Using
            End Using
            Return tempTRList
        End Function

        Public Shared Function GetTestRecordsForBatch(ByVal qraNumber As String, ByVal myConnection As SqlConnection) As TestRecordCollection
            Dim tempList As New TestRecordCollection

            Using myCommand As New SqlCommand("remispTestRecordsSelectForBatch", myConnection)
                myCommand.CommandType = CommandType.StoredProcedure
                myCommand.Parameters.AddWithValue("@QRANumber", qraNumber)

                If myConnection.State <> ConnectionState.Open Then
                    myConnection.Open()
                End If

                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                    If myReader.HasRows Then
                        While myReader.Read()
                            tempList.Add(FillDataRecord(myReader))
                        End While
                    End If
                End Using
            End Using
            Return tempList
        End Function

        ''' <summary>Saves an instance of the <see cref="TestRecord" /> in the database.</summary> 
        ''' <param name="MyTestRecord">The TestRecord instance to save.</param> 
        ''' <returns>Returns the id of the record when the object was saved successfully, or nothing otherwise.</returns> 
        Public Shared Function Save(ByVal MyTestRecord As TestRecord) As Integer
            If Not MyTestRecord.Validate() Then
                Throw New InvalidSaveOperationException("Can't save a TestRecord in an Invalid state. Make sure that IsValid() returns true before you call Save().")
            End If

            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestRecordsInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestUnitID", MyTestRecord.TestUnitID)
                    myCommand.Parameters.AddWithValue("@JobName", MyTestRecord.JobName)
                    myCommand.Parameters.AddWithValue("@TestName", MyTestRecord.TestName)
                    myCommand.Parameters.AddWithValue("@TestStageName", MyTestRecord.TestStageName)
                    myCommand.Parameters.AddWithValue("@Status", MyTestRecord.Status)
                    myCommand.Parameters.AddWithValue("@RelabVersion", MyTestRecord.CurrentRelabResultVersion)

                    If MyTestRecord.FailDocs.Count = 0 Then
                        myCommand.Parameters.AddWithValue("@FailDocNumber", DBNull.Value)
                    Else
                        myCommand.Parameters.AddWithValue("@FailDocNumber", MyTestRecord.FailDocCSVList)
                    End If

                    If Not String.IsNullOrEmpty(MyTestRecord.Comments) Then
                        myCommand.Parameters.AddWithValue("@Comment", MyTestRecord.Comments)
                    Else
                        myCommand.Parameters.AddWithValue("@Comment", DBNull.Value)
                    End If

                    If MyTestRecord.ResultSource <> TestResultSource.NotSet Then
                        myCommand.Parameters.AddWithValue("@ResultSource", MyTestRecord.ResultSource)
                    Else
                        myCommand.Parameters.AddWithValue("@ResultSource", DBNull.Value)
                    End If

                    If MyTestRecord.TestID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestID", MyTestRecord.TestID)
                    End If

                    If MyTestRecord.TestStageID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestStageID", MyTestRecord.TestStageID)
                    End If

                    myCommand.Parameters.AddWithValue("@FunctionalType", MyTestRecord.FunctionalType)

                    Helpers.SetSaveParameters(myCommand, MyTestRecord)
                    myConnection.Open()
                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()

                    If NumberOfRecordsAffected = 0 And REMIConfiguration.Debug Then
                        Throw New DBConcurrencyException(String.Format("Can't update the TestRecord as it has been updated by someone else: test unit id:{0}, jobname: {1}, testname:{2}, teststagename:{3}, status:{4}", MyTestRecord.TestUnitID, MyTestRecord.JobName, MyTestRecord.TestName, MyTestRecord.TestStageName, MyTestRecord.Status))
                        Result = 0
                    ElseIf NumberOfRecordsAffected = 0 And Not (REMIConfiguration.Debug) Then
                        Result = 0
                    Else
                        MyTestRecord.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)

                        Result = Helpers.GetBusinessBaseId(myCommand)
                        If NumberOfRecordsAffected > 0 Then
                            REMIAppCache.RemoveTestRecords(MyTestRecord.QRANumber)
                        End If
                    End If
                End Using
            End Using

            Return Result
        End Function
#End Region

#Region "Private Methods"
        ''' <summary>
        ''' Initializes a new instance of the TestRecord class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the TestRecord produced by a select query</param>
        ''' <returns>A TestRecord object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Public Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord) As TestRecord
            Dim MyTestRecord As New TestRecord()

            'Non nullable data records
            MyTestRecord.ID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID"))
            MyTestRecord.TestUnitID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestUnitID"))
            MyTestRecord.Status = DirectCast(myDataRecord.GetInt32(myDataRecord.GetOrdinal("Status")), TestRecordStatus)
            MyTestRecord.TestName = myDataRecord.GetString(myDataRecord.GetOrdinal("TestName"))
            MyTestRecord.JobName = myDataRecord.GetString(myDataRecord.GetOrdinal("JobName"))
            MyTestRecord.TestStageName = myDataRecord.GetString(myDataRecord.GetOrdinal("TestStageName"))
            MyTestRecord.ConcurrencyID = DirectCast(myDataRecord.GetValue(myDataRecord.GetOrdinal("ConcurrencyID")), Byte())
            MyTestRecord.NumberOfTests = myDataRecord.GetInt32(myDataRecord.GetOrdinal("NumberOfTests"))

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("RelabVersion")) Then
                MyTestRecord.CurrentRelabResultVersion = myDataRecord.GetInt32(myDataRecord.GetOrdinal("RelabVersion"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TotalTestTimeMinutes")) Then
                MyTestRecord.TotalTestTimeInMinutes = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TotalTestTimeMinutes"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("QRANumber")) Then
                MyTestRecord.QRANumber = myDataRecord.GetString(myDataRecord.GetOrdinal("QRANumber"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("BatchUnitNumber")) Then
                MyTestRecord.BatchUnitNumber = myDataRecord.GetInt32(myDataRecord.GetOrdinal("BatchUnitNumber"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ResultSource")) Then
                MyTestRecord.ResultSource = DirectCast(myDataRecord.GetInt32(myDataRecord.GetOrdinal("ResultSource")), TestResultSource)
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Comment")) Then
                MyTestRecord.Comments = myDataRecord.GetString(myDataRecord.GetOrdinal("Comment"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("FailDocnumber")) Then
                For Each s As String In myDataRecord.GetString(myDataRecord.GetOrdinal("FailDocnumber")).Split(",".ToArray, System.StringSplitOptions.RemoveEmptyEntries)
                    MyTestRecord.FailDocs.Add(RequestDB.GetTRSRequest(s))
                Next
            End If
            If (Helpers.HasColumn(myDataRecord, "TestID")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestID")) Then
                    MyTestRecord.TestID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestID"))
                End If
            End If

            If (Helpers.HasColumn(myDataRecord, "TestStageID")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestStageID")) Then
                    MyTestRecord.TestStageID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestStageID"))
                End If
            End If

            If (Helpers.HasColumn(myDataRecord, "FunctionalType")) Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("FunctionalType")) Then
                    MyTestRecord.FunctionalType = myDataRecord.GetInt32(myDataRecord.GetOrdinal("FunctionalType"))
                End If
            End If

            Helpers.FillObjectParameters(myDataRecord, MyTestRecord)

            Return MyTestRecord
        End Function
#End Region

    End Class
End Namespace