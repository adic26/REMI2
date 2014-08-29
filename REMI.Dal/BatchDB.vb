Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.OracleClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports System.Configuration
Imports System.Text.RegularExpressions
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core
Imports System.Reflection

Namespace REMI.Dal
    ''' <summary>
    ''' The BatchDB class is responsible for interacting with the database to retrieve and store information 
    ''' about Batch objects.
    ''' </summary>
    Public Class BatchDB

#Region "Batch Comment Methods"
        Public Shared Function AddBatchComment(ByVal batchID As Integer, ByVal text As String, ByVal lastuser As String) As Boolean
            Dim returnVal As Integer

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchCommentsInsertNew", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    myCommand.Parameters.AddWithValue("@batchid", batchID)
                    myCommand.Parameters.AddWithValue("@text", text)
                    myCommand.Parameters.AddWithValue("@lastuser", lastuser)
                    myConnection.Open()
                    returnVal = myCommand.ExecuteNonQuery()
                End Using
            End Using

            Return returnVal > 0
        End Function

        Public Shared Function GetBatchComments(ByVal qraNumber As String) As List(Of IBatchCommentView)
            Dim b As Batch = New Batch()

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchCommentsGetByQRANumber", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("qranumber", qraNumber)
                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            b = New Batch()
                            While myReader.Read()
                                FillBatchComment(myReader, b)
                            End While
                        End If
                    End Using
                End Using
            End Using

            Return b.Comments
        End Function

        Public Shared Function DeactivateBatchComment(ByVal commentID As Integer) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchCommentsDeactivate", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@commentID", commentID)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using

            Return True
        End Function
#End Region

#Region "Public Hardcoded Methods"
        ''' <summary>
        ''' Sets the status for a batch
        ''' </summary>
        ''' <param name="qraNumber"></param>
        ''' <param name="status"></param>
        ''' <param name="lastuser"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function SetBatchStatus(ByVal qraNumber As String, ByVal status As BatchStatus, ByVal lastuser As String) As Boolean
            Dim returnVal As Integer

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("update batches set batchstatus = @batchstatus , lastuser = @lastuser where qranumber = @qranumber", myConnection)
                    myCommand.CommandType = CommandType.Text
                    myCommand.Parameters.AddWithValue("@qranumber", qraNumber)
                    myCommand.Parameters.AddWithValue("@batchstatus", status)
                    myCommand.Parameters.AddWithValue("@lastuser", lastuser)
                    myConnection.Open()
                    returnVal = myCommand.ExecuteNonQuery()
                End Using
            End Using

            Return returnVal > 0
        End Function
#End Region

#Region "New Slim Batch Methods"
        Public Shared Function GetSlimBatchByQRANumber(ByVal qraNumber As String, Optional ByVal cacheRetrievedData As Boolean = True) As BatchView
            Dim batchData As BatchView = Nothing

            Using sqlConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                If batchData Is Nothing Then
                    Dim bc As New DeviceBarcodeNumber(qraNumber)

                    If (bc.Validate()) Then
                        Using myCommand As New SqlCommand("remispBatchGetViewBatch", sqlConnection)
                            myCommand.CommandType = CommandType.StoredProcedure
                            myCommand.Parameters.AddWithValue("@QRANumber", bc.BatchNumber)
                            'open the sql connection
                            If sqlConnection.State <> ConnectionState.Open Then
                                sqlConnection.Open()
                            End If
                            Using myReader As SqlDataReader = myCommand.ExecuteReader()
                                'This stored procedure returns more than one table or result set.
                                'to read them all we must step through each result set.
                                'as of 26 Sept 2011 it has the following result sets
                                '1. Batch data
                                '2. Batch Comments
                                '3. Process Data
                                '4. Test Results
                                '5. Test Unit Data
                                If myReader.HasRows Then
                                    batchData = New BatchView

                                    While myReader.Read()
                                        FillBaseBatchFields(myReader, batchData, False, False)
                                    End While
                                    myReader.NextResult()
                                    While myReader.Read()
                                        FillBatchComment(myReader, batchData)
                                    End While
                                    myReader.NextResult()
                                    While myReader.Read()
                                        FillBatchTask(myReader, batchData)
                                    End While
                                    myReader.NextResult()
                                    While myReader.Read()
                                        batchData.TestRecords.Add(TestRecordDB.FillDataRecord(myReader))
                                    End While
                                    myReader.NextResult()
                                    While myReader.Read()
                                        batchData.TestUnits.Add(TestUnitDB.FillDataRecord(myReader))
                                    End While
                                End If
                            End Using
                        End Using
                    End If
                End If
            End Using

            If batchData IsNot Nothing Then
                Using oracleConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(RequestDB.GetConnectString(batchData.QRANumber)))
                    oracleConnection.Open()
                    batchData.TRSData = RequestDB.GetTRSRequest(batchData.QRANumber, oracleConnection)
                End Using
            End If
            Return batchData
        End Function
#End Region

#Region "Public Stored Proc Methods"
        ''' <summary> 
        ''' Returns a list of batches in environmental chambers
        ''' </summary>
        ''' <returns>
        ''' A BatchCollection.
        ''' </returns> 
        Public Shared Function GetListInChambers(ByVal testCentreLocation As Int32, ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal sortExpression As String, ByVal byPass As Boolean, ByVal userID As Int32) As BatchCollection
            Dim tmpList As BatchCollection = Nothing
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesSelectChamberBatches", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    If testCentreLocation > 0 Then
                        myCommand.Parameters.AddWithValue("@TestCentreLocation", testCentreLocation)
                    End If
                    myCommand.Parameters.AddWithValue("@startRowIndex", startRowIndex)
                    myCommand.Parameters.AddWithValue("@maximumRows", maximumRows)
                    Dim orderByVals As String()
                    If Not String.IsNullOrEmpty(sortExpression) Then
                        If sortExpression.EndsWith("desc") Then
                            orderByVals = sortExpression.Trim.Split(" "c)
                            If orderByVals.Count >= 1 AndAlso Not String.IsNullOrEmpty(orderByVals(0)) Then
                                myCommand.Parameters.AddWithValue("@SortExpression", orderByVals(0).ToLowerInvariant)
                            End If
                            If orderByVals.Count >= 2 AndAlso Not String.IsNullOrEmpty(orderByVals(1)) Then
                                myCommand.Parameters.AddWithValue("@direction", orderByVals(1).ToLowerInvariant)
                            End If
                        Else
                            myCommand.Parameters.AddWithValue("@SortExpression", sortExpression.ToLowerInvariant)
                        End If
                    End If

                    If (byPass) Then
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 0)
                    End If

                    myCommand.Parameters.AddWithValue("@UserID", userID)

                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.HasRows Then
                            tmpList = New BatchCollection()
                            While myReader.Read()
                                tmpList.Add(FillFullBatch(myReader, False, False))
                            End While
                        End If
                    End Using
                End Using
                FillFullBatchFields(tmpList, myConnection, False, False, False, True, True, False, False, False, False)
            End Using

            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New BatchCollection
            End If
        End Function

        Public Shared Function GetRandomCountQraNumbers() As List(Of String)
            Dim tmpList As New List(Of String)
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesSelectRandomSampleQRANumbers", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                tmpList.Add(myReader.GetString(0))
                            End While
                        End If
                    End Using
                End Using
            End Using

            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New List(Of String)
            End If
        End Function

        ''' <summary> 
        ''' Returns a list with Batch objects at a specific location. 
        ''' </summary> 
        ''' <param name="TrackingLocationId">The id of the location to search for units. </param> 
        ''' <returns> 
        ''' A BatchCollection.
        ''' </returns> 
        Public Shared Function GetListAtLocation(ByVal trackingLocationID As Integer, ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal sortExpression As String) As BatchCollection

            Dim tmpList As BatchCollection = Nothing
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesSelectListAtTrackingLocation", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TrackingLocationID", trackingLocationID)
                    myCommand.Parameters.AddWithValue("@startRowIndex", startRowIndex)
                    myCommand.Parameters.AddWithValue("@maximumRows", maximumRows)
                    Dim orderByVals As String()
                    If Not String.IsNullOrEmpty(sortExpression) Then
                        If sortExpression.EndsWith("desc") Then
                            orderByVals = sortExpression.Trim.Split(" "c)

                            myCommand.Parameters.AddWithValue("@SortExpression", orderByVals(0))
                            myCommand.Parameters.AddWithValue("@direction", "desc")

                        Else
                            myCommand.Parameters.AddWithValue("@SortExpression", sortExpression)
                            myCommand.Parameters.AddWithValue("@direction", "asc")
                        End If
                    End If

                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.HasRows Then
                            tmpList = New BatchCollection()
                            While myReader.Read()
                                tmpList.Add(FillFullBatch(myReader, False, False))
                            End While
                        End If
                    End Using
                End Using
            End Using

            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New BatchCollection
            End If
        End Function

        Public Shared Function GetBatchByQRANumber(ByVal qraNumber As String, ByVal getFailParams As Boolean, Optional ByVal cacheRetrievedData As Boolean = True) As Batch
            Dim batchData As Batch = Nothing
            'create the sql connection
            Using sqlConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                If batchData Is Nothing Then
                    Using myCommand As New SqlCommand("remispBatchesSelectByQRANumber", sqlConnection)
                        myCommand.CommandType = CommandType.StoredProcedure
                        myCommand.Parameters.AddWithValue("@QRANumber", qraNumber)
                        'open the sql connection
                        If sqlConnection.State <> ConnectionState.Open Then
                            sqlConnection.Open()
                        End If

                        Using myReader As SqlDataReader = myCommand.ExecuteReader()
                            If myReader.HasRows Then
                                batchData = New Batch
                                While myReader.Read()
                                    FillBaseBatchFields(myReader, batchData, True, False)
                                End While
                                myReader.NextResult()
                                While myReader.Read()
                                    FillBatchComment(myReader, batchData)
                                End While
                            End If
                        End Using
                    End Using
                End If

                If batchData IsNot Nothing Then
                    FillFullBatchFields(batchData, sqlConnection, Nothing, getFailParams, cacheRetrievedData, True, True, True, True, True, False, True)
                End If
            End Using

            Return batchData
        End Function

        Public Shared Function BatchSearch(ByVal bs As BatchSearch, ByVal byPass As Boolean, ByVal userID As Int32, ByVal loadTestRecords As Boolean, ByVal loadDurations As Boolean) As BatchCollection
            Dim tmpList As New BatchCollection()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesSearch", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.CommandTimeout = 40

                    If (byPass) Then
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 0)
                    End If

                    myCommand.Parameters.AddWithValue("@ExecutingUserID", userID)

                    For Each p As System.Reflection.PropertyInfo In bs.GetType().GetProperties()
                        If p.CanRead Then
                            If (p.GetValue(bs, Nothing) IsNot Nothing) Then
                                Dim d As DateTime
                                DateTime.TryParse(p.GetValue(bs, Nothing).ToString(), d)

                                If (p.GetValue(bs, Nothing).ToString().ToLower() <> "all" And p.GetValue(bs, Nothing).ToString().ToLower() <> "0" And p.GetValue(bs, Nothing).ToString().ToLower() <> "notset") Then
                                    If (p.PropertyType Is System.Type.GetType("System.DateTime") And d <> DateTime.MinValue) Then
                                        myCommand.Parameters.AddWithValue("@" + p.Name, p.GetValue(bs, Nothing))
                                    ElseIf p.PropertyType IsNot System.Type.GetType("System.DateTime") Then
                                        myCommand.Parameters.AddWithValue("@" + p.Name, p.GetValue(bs, Nothing))
                                    End If
                                End If
                            End If
                        End If
                    Next

                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            tmpList = New BatchCollection()
                            While myReader.Read()
                                tmpList.Add(FillFullBatch(myReader, True, False))
                            End While
                        End If
                    End Using
                    FillFullBatchFields(tmpList, myConnection, False, False, False, loadDurations, True, False, False, False, loadTestRecords)
                End Using
            End Using

            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New BatchCollection
            End If
        End Function

        Public Shared Function GetBatchDocuments(ByVal QRANumber As String) As DataTable
            Dim dt As New DataTable()

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetBatchDocuments", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", QRANumber)
                    myConnection.Open()

                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "BatchDocuments"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetYourActiveBatchesDataTable(ByVal UserID As Integer, ByVal byPass As Boolean, ByVal year As Int32, ByVal onlyShowQRAWithResults As Boolean) As DataTable
            Dim dt As New DataTable()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispYourBatchesGetActiveBatches", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@UserID", UserID)
                    If (byPass) Then
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 0)
                    End If
                    myCommand.Parameters.AddWithValue("@Year", year)
                    If (onlyShowQRAWithResults) Then
                        myCommand.Parameters.AddWithValue("@OnlyShowQRAWithResults", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@OnlyShowQRAWithResults", 0)
                    End If

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ActiveBatches"
                End Using
            End Using

            Return dt
        End Function

        ''' <summary> 
        ''' This method returns a list of batches where the status is not complete or rejected.
        ''' </summary> 
        Public Shared Function GetActiveBatches(ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal isRemiTimedServiceCall As Boolean) As BatchCollection
            Dim tmpList As New BatchCollection()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesGetActiveBatches", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    If startRowIndex > 0 Then
                        myCommand.Parameters.AddWithValue("@startrowindex", startRowIndex)
                    End If
                    If maximumRows > 0 Then
                        myCommand.Parameters.AddWithValue("@maximumrows", maximumRows)
                    End If
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                If (isRemiTimedServiceCall) Then
                                    tmpList.Add(FillFullBatch(myReader, False, True))
                                Else
                                    tmpList.Add(FillFullBatch(myReader, True, False))
                                End If
                            End While
                        End If
                    End Using
                End Using
                If (Not (isRemiTimedServiceCall)) Then
                    FillFullBatchFields(tmpList, myConnection, False)
                End If
            End Using

            Return tmpList
        End Function

        Public Shared Function GetActiveBatches(ByVal requestor As String, ByVal startRowIndex As Integer, ByVal maximumRows As Integer) As BatchCollection
            Dim tmpList As New BatchCollection()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesGetActiveBatchesByRequestor", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    If startRowIndex > 0 Then
                        myCommand.Parameters.AddWithValue("@startrowindex", startRowIndex)
                    End If
                    myCommand.Parameters.AddWithValue("@Requestor", requestor)
                    If maximumRows > 0 Then
                        myCommand.Parameters.AddWithValue("@maximumrows", maximumRows)
                    End If
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.HasRows Then
                            While myReader.Read()
                                tmpList.Add(FillFullBatch(myReader, False, False))
                            End While
                        End If
                    End Using
                End Using
                FillFullBatchFields(tmpList, myConnection, False, False, True, False, False, False, False)
            End Using

            Return tmpList
        End Function

        ''' <summary>Reverts the duration for a batch for a test stage to the default.
        ''' <returns>Returns true if reverted successfuly.</returns> 
        ''' </summary>
        Public Shared Function DeleteBatchSpecificTestDuration(ByVal qranumber As String, ByVal testStageID As Integer, ByVal comment As String, ByVal lastUser As String) As Boolean
            Dim result As Integer
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchSpecificTestDurationsDeleteSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", qranumber)
                    myCommand.Parameters.AddWithValue("@TestStageID", testStageID)
                    myCommand.Parameters.AddWithValue("@lastuser", lastUser)

                    If String.IsNullOrEmpty(comment) Then
                        myCommand.Parameters.AddWithValue("@comment", DBNull.Value)
                    Else
                        myCommand.Parameters.AddWithValue("@comment", comment)
                    End If
                    myConnection.Open()
                    result = myCommand.ExecuteNonQuery()
                End Using
            End Using

            If result > 0 Then
                REMIAppCache.RemoveSpecificTestDurations(qranumber)
            End If

            Return result > 0
        End Function

        Public Shared Function DetermineEstimatedTSTime(ByVal batchID As Int32, ByVal testStageName As String, ByVal jobName As String, ByVal testStageID As Int32, ByVal jobID As Int32, ByVal returnTestStageGrid As Int32, ByRef result2 As Dictionary(Of String, Int32)) As Dictionary(Of String, Double)
            Dim result As New Dictionary(Of String, Double)

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetEstimatedTSTime", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)
                    myCommand.Parameters.AddWithValue("@TestStageName", testStageName)
                    myCommand.Parameters.AddWithValue("@JobName", jobName)
                    myCommand.Parameters.AddWithValue("@ReturnTestStageGrid", 1)

                    Dim TSTimeLeft As Double
                    Dim JobTimeLeft As Double

                    Dim tsOutput As DbParameter = myCommand.CreateParameter()
                    tsOutput.DbType = DbType.Double
                    tsOutput.Direction = ParameterDirection.Output
                    tsOutput.ParameterName = "@TSTimeLeft"
                    tsOutput.Value = TSTimeLeft
                    myCommand.Parameters.Add(tsOutput)

                    Dim jobOutput As DbParameter = myCommand.CreateParameter()
                    jobOutput.DbType = DbType.Double
                    jobOutput.Direction = ParameterDirection.Output
                    jobOutput.ParameterName = "@JobTimeLeft"
                    jobOutput.Value = JobTimeLeft
                    myCommand.Parameters.Add(jobOutput)

                    myCommand.Parameters.AddWithValue("@TestStageID", testStageID)
                    myCommand.Parameters.AddWithValue("@JobID", jobID)

                    myConnection.Open()

                    Dim dt As New DataTable
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "TestStagesTimeLeft"

                    If (returnTestStageGrid = 0) Then
                        result.Add("TSTimeLeft", CDbl(myCommand.Parameters("@TSTimeLeft").Value))
                        result.Add("JobTimeLeft", CDbl(myCommand.Parameters("@JobTimeLeft").Value))
                    Else
                        For Each dr As DataRow In dt.Rows
                            Dim timeLeft As Double
                            Dim stageID As Int32
                            Double.TryParse(dr.Item("TimeLeft").ToString(), timeLeft)
                            Int32.TryParse(dr.Item("TestStageID").ToString(), stageID)

                            result2.Add(dr.Item("TestStageName").ToString(), stageID)
                            result.Add(dr.Item("TestStageName").ToString(), timeLeft)
                        Next

                        result.Add("TSTimeLeft", CDbl(myCommand.Parameters("@TSTimeLeft").Value))
                        result.Add("JobTimeLeft", CDbl(myCommand.Parameters("@JobTimeLeft").Value))
                    End If
                End Using
            End Using

            Return result
        End Function

        Public Shared Function DNPParametricForBatch(ByVal qraNumber As String, ByVal userIdentification As String, ByVal unitNumber As Int32) As Boolean
            Dim result As Integer
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchDNPParametric", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", qraNumber)
                    myCommand.Parameters.AddWithValue("@LDAPLogin", userIdentification)
                    myCommand.Parameters.AddWithValue("@UnitNumber", unitNumber)
                    myConnection.Open()
                    result = myCommand.ExecuteNonQuery()
                End Using
            End Using

            Return result > 0
        End Function

        ''' <summary>Modifys the default duration for a batch for a specific test stage.
        ''' <returns>Returns true if saved successfuly.</returns> 
        ''' </summary>
        Public Shared Function ModifyBatchSpecificTestDuration(ByVal qranumber As String, ByVal testStageID As Integer, ByVal duration As Double, ByVal comment As String, ByVal lastUser As String) As Boolean
            Dim Result As Integer
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchSpecificTestDurationsInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", qranumber)
                    myCommand.Parameters.AddWithValue("@TestStageID", testStageID)
                    myCommand.Parameters.AddWithValue("@lastuser", lastUser)
                    myCommand.Parameters.AddWithValue("@duration", duration)
                    If String.IsNullOrEmpty(comment) Then
                        myCommand.Parameters.AddWithValue("@comment", DBNull.Value)
                    Else
                        myCommand.Parameters.AddWithValue("@comment", comment)
                    End If
                    myConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using

            If Result > 0 Then
                REMIAppCache.RemoveSpecificTestDurations(qranumber)
            End If

            Return Result > 0
        End Function
        ''' <summary>Saves an instance of the <see cref="Batch" /> in the database.</summary> 
        ''' <param name="myBatch">The Batch instance to save.</param> 
        ''' <returns>Returns the id of the batch when the object was saved successfully, or 0 otherwise.</returns> 
        Public Shared Function Save(ByVal MyBatch As Batch) As Integer
            If Not MyBatch.Validate() AndAlso MyBatch.Status <> BatchStatus.NotSavedToREMI Then
                Throw New InvalidSaveOperationException("Can't save a Batch in an Invalid state. Make sure that IsValid() returns true before you call Save(): " + MyBatch.Notifications.ToString())
            End If
            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", MyBatch.QRANumber)
                    myCommand.Parameters.AddWithValue("@JobName", MyBatch.JobName)
                    myCommand.Parameters.AddWithValue("@TestCenterLocation", MyBatch.TestCenterLocation)
                    myCommand.Parameters.AddWithValue("@Priority", MyBatch.CompletionPriority)
                    myCommand.Parameters.AddWithValue("@PriorityID", MyBatch.CompletionPriorityID)
                    myCommand.Parameters.AddWithValue("@RequestPurpose", MyBatch.RequestPurpose)
                    myCommand.Parameters.AddWithValue("@RequestPurposeID", MyBatch.RequestPurposeID)
                    myCommand.Parameters.AddWithValue("@BatchStatus", MyBatch.Status)
                    myCommand.Parameters.AddWithValue("@Requestor", MyBatch.Requestor)
                    myCommand.Parameters.AddWithValue("@ProductGroupName", MyBatch.ProductGroup)
                    myCommand.Parameters.AddWithValue("@AccessoryGroupName", MyBatch.AccessoryGroup)
                    myCommand.Parameters.AddWithValue("@ProductType", MyBatch.ProductType)
                    myCommand.Parameters.AddWithValue("@testStageCompletionStatus", MyBatch.TestStageCompletion)

                    If Not String.IsNullOrEmpty(MyBatch.TestStageName) Then
                        myCommand.Parameters.AddWithValue("@TestStageName", MyBatch.TestStageName)
                    End If
                    myCommand.Parameters.AddWithValue("@unitsToBeReturnedToRequestor", MyBatch.HasUnitsRequiredToBeReturnedToRequestor)
                    myCommand.Parameters.AddWithValue("@expectedSampleSize", MyBatch.TRSData.SampleSize)
                    myCommand.Parameters.AddWithValue("@relabJobID", MyBatch.TRSData.JobId)
                    If MyBatch.TRSData.ReportRequiredBy <> DateTime.MinValue Then
                        myCommand.Parameters.AddWithValue("@reportRequiredBy", MyBatch.ReportRequiredBy)
                    End If
                    If MyBatch.TRSData.DateReportApproved <> DateTime.MinValue Then
                        myCommand.Parameters.AddWithValue("@reportApprovedDate", MyBatch.ReportApprovedDate)
                    End If
                    myCommand.Parameters.AddWithValue("@rqID", MyBatch.ReqID)
                    If Not String.IsNullOrEmpty(MyBatch.PartName) Then
                        myCommand.Parameters.AddWithValue("@partName", MyBatch.PartName)
                    End If
                    If Not String.IsNullOrEmpty(MyBatch.AssemblyNumber) Then
                        myCommand.Parameters.AddWithValue("@assemblyNumber", MyBatch.AssemblyNumber)
                    End If
                    If Not String.IsNullOrEmpty(MyBatch.AssemblyRevision) Then
                        myCommand.Parameters.AddWithValue("@assemblyRevision", MyBatch.AssemblyRevision)
                    End If
                    If Not String.IsNullOrEmpty(MyBatch.TRSStatus) Then
                        myCommand.Parameters.AddWithValue("@trsStatus", MyBatch.TRSStatus)
                    End If
                    If Not String.IsNullOrEmpty(MyBatch.CPRNumber) Then
                        myCommand.Parameters.AddWithValue("@cprNumber", MyBatch.CPRNumber)
                    End If
                    If Not String.IsNullOrEmpty(MyBatch.HWRevision) Then
                        myCommand.Parameters.AddWithValue("@hwRevision", MyBatch.HWRevision)
                    End If
                    If MyBatch.TRSData.HasSpecialInstructions Then
                        myCommand.Parameters.AddWithValue("@pmNotes", MyBatch.TRSData.GetSpecialInstructions())
                    End If
                    myCommand.Parameters.AddWithValue("@IsMQual", MyBatch.TRSData.MQual)
                    myCommand.Parameters.AddWithValue("@MechanicalTools", MyBatch.TRSData.MechanicalTools)

                    Helpers.SetSaveParameters(myCommand, MyBatch)
                    myConnection.Open()
                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()
                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("Can't update the Batch as it has been updated by someone else.")
                    End If

                    MyBatch.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)
                    Result = Helpers.GetBusinessBaseId(myCommand)
                    If MyBatch.ID = 0 Then
                        MyBatch.ID = Result
                    End If
                End Using
            End Using
            Return Result
        End Function

        ''' <summary>
        ''' counts the number of batches in a tracking location
        ''' </summary>
        ''' <param name="trackingLocationId"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function CountBatchesInTrackingLocation(ByVal trackingLocationId As Integer) As Integer
            Dim count As Integer
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesSelectListAtTrackingLocation", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    Dim IDParam As DbParameter = myCommand.CreateParameter()
                    IDParam.DbType = DbType.Int32
                    IDParam.Direction = ParameterDirection.InputOutput
                    IDParam.ParameterName = "@RecordCount"
                    IDParam.Value = 0
                    myCommand.Parameters.Add(IDParam)
                    myCommand.Parameters.AddWithValue("@TrackingLocationId", trackingLocationId)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                    count = CInt(myCommand.Parameters("@RecordCount").Value)
                End Using
            End Using
            Return count
        End Function

        Public Shared Sub GetBatchTaskInfo(ByVal batchdata As Batch, ByVal getByBatchStage As Boolean)
            'Dim tmpList As ITaskList = Nothing
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchGetTaskInfo", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BatchID", batchdata.ID)

                    If (getByBatchStage) Then
                        myCommand.Parameters.AddWithValue("@TestStageID", batchdata.TestStageID)
                    End If

                    myConnection.Open()

                    Dim dt As New DataTable
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "TaskInfo"
                    GetBatchTask(dt, batchdata)
                End Using
            End Using
        End Sub
#End Region

#Region "Private Methods"
        Private Shared Function GetBatchTask(ByVal myreader As DataTable, ByVal batchdata As Batch) As Boolean
            For Each dr As DataRow In myreader.Rows
                Dim currentBatchTask As ITaskModel = New REMI.BusinessEntities.ProcessTask
                Dim ed As Double
                Double.TryParse(dr.Item("expectedDuration").ToString(), ed)
                currentBatchTask.ExpectedDuration = TimeSpan.FromHours(ed)
                currentBatchTask.ProcessOrder = DirectCast(dr.Item("processorder"), Int32)
                currentBatchTask.ResultBaseOnTime = DirectCast(dr.Item("resultbasedontime"), Boolean)
                currentBatchTask.TestName = dr.Item("TestName").ToString()
                currentBatchTask.TestType = DirectCast(dr.Item("testtype"), REMI.Contracts.TestType)
                currentBatchTask.TestStageType = DirectCast(dr.Item("teststagetype"), REMI.Contracts.TestStageType)
                currentBatchTask.TestStageName = dr.Item("TestStageName").ToString()
                currentBatchTask.SetUnitsForTask(dr.Item("testunitsfortest").ToString())
                currentBatchTask.TestID = DirectCast(dr.Item("TestID"), Int32)
                currentBatchTask.TestStageID = DirectCast(dr.Item("TestStageID"), Int32)
                currentBatchTask.IsArchived = DirectCast(dr.Item("IsArchived"), Boolean)
                currentBatchTask.TestIsArchived = DirectCast(dr.Item("TestIsArchived"), Boolean)

                batchdata.Tasks.Add(currentBatchTask)
            Next

            Return True
        End Function

        Private Shared Sub FillBatchTask(ByVal myreader As IDataRecord, ByVal b As ITaskList)
            Dim currentBatchTask As ITaskModel = New REMI.BusinessEntities.ProcessTask

            currentBatchTask.ExpectedDuration = TimeSpan.FromHours(myreader.GetFloat(myreader.GetOrdinal("expectedDuration")))
            currentBatchTask.ProcessOrder = myreader.GetInt32(myreader.GetOrdinal("processorder"))
            currentBatchTask.ResultBaseOnTime = myreader.GetBoolean(myreader.GetOrdinal("resultbasedontime"))
            currentBatchTask.TestName = myreader.GetString(myreader.GetOrdinal("TestName"))
            currentBatchTask.TestType = DirectCast(myreader.GetInt32(myreader.GetOrdinal("testtype")), REMI.Contracts.TestType)
            currentBatchTask.TestStageType = DirectCast(myreader.GetInt32(myreader.GetOrdinal("teststagetype")), REMI.Contracts.TestStageType)
            currentBatchTask.TestStageName = myreader.GetString(myreader.GetOrdinal("TestStageName"))
            currentBatchTask.SetUnitsForTask(myreader.GetString(myreader.GetOrdinal("testunitsfortest")))
            currentBatchTask.TestID = myreader.GetInt32(myreader.GetOrdinal("TestID"))
            currentBatchTask.TestStageID = myreader.GetInt32(myreader.GetOrdinal("TestStageID"))
            currentBatchTask.IsArchived = myreader.GetBoolean(myreader.GetOrdinal("IsArchived"))
            currentBatchTask.TestIsArchived = myreader.GetBoolean(myreader.GetOrdinal("TestIsArchived"))

            b.Tasks.Add(currentBatchTask)
        End Sub

        ''' <summary>
        ''' Initializes a new instance of the Batch class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the Batch produced by a select query</param>
        ''' <returns>A Batch object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Private Shared Function FillFullBatch(ByVal myDataRecord As IDataRecord, ByVal getTSRemaining As Boolean, ByVal isRemiTimedServiceCall As Boolean) As BusinessEntities.Batch
            Dim myBatch As Batch = New BusinessEntities.Batch()
            FillBaseBatchFields(myDataRecord, myBatch, getTSRemaining, isRemiTimedServiceCall)

            Return myBatch
        End Function

        Private Shared Sub FillBatchComment(ByVal myreader As IDataRecord, ByVal b As ICommentedItem)
            Dim currentBatchComment As IBatchCommentView = New REMI.BaseObjectModels.BatchCommentView
            currentBatchComment.DateAdded = myreader.GetDateTime(myreader.GetOrdinal("dateadded"))
            currentBatchComment.Id = myreader.GetInt32(myreader.GetOrdinal("id"))
            currentBatchComment.Text = myreader.GetString(myreader.GetOrdinal("text"))
            currentBatchComment.UserName = myreader.GetString(myreader.GetOrdinal("lastuser"))

            If (Not (b.Comments.Any(Function(item) item.Id = currentBatchComment.Id))) Then
                b.Comments.Add(currentBatchComment)
            End If
        End Sub

        Private Shared Sub FillBaseBatchFields(ByVal dataRecord As IDataRecord, ByVal batchData As IBatch, ByVal getTSRemaining As Boolean, ByVal isRemiTimedServiceCall As Boolean)
            batchData.QRANumber = dataRecord.GetString(dataRecord.GetOrdinal("QRANumber"))
            batchData.Status = DirectCast(dataRecord.GetInt32(dataRecord.GetOrdinal("BatchStatus")), BatchStatus)
            batchData.CompletionPriorityID = dataRecord.GetInt32(dataRecord.GetOrdinal("PriorityID"))

            If (batchData.CompletionPriorityID = 0) Then
                batchData.CompletionPriority = "NotSet"
            Else
                batchData.CompletionPriority = dataRecord.GetString(dataRecord.GetOrdinal("Priority"))
            End If

            batchData.ProductGroup = dataRecord.GetString(dataRecord.GetOrdinal("ProductGroupName"))
            batchData.ProductID = dataRecord.GetInt32(dataRecord.GetOrdinal("ProductID"))
            batchData.ID = dataRecord.GetInt32(dataRecord.GetOrdinal("ID"))

            If (batchData.Comments.Count = 0 And Not (isRemiTimedServiceCall)) Then
                batchData.Comments = GetBatchComments(batchData.QRANumber)
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("ProductType")) Then
                batchData.ProductType = dataRecord.GetString(dataRecord.GetOrdinal("ProductType"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("ProductTypeID")) Then
                batchData.ProductTypeID = dataRecord.GetInt32(dataRecord.GetOrdinal("ProductTypeID"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("AccessoryGroupName")) Then
                batchData.AccessoryGroup = dataRecord.GetString(dataRecord.GetOrdinal("AccessoryGroupName"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("AccessoryGroupID")) Then
                batchData.AccessoryGroupID = dataRecord.GetInt32(dataRecord.GetOrdinal("AccessoryGroupID"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("ReqID")) Then
                batchData.ReqID = dataRecord.GetInt32(dataRecord.GetOrdinal("ReqID"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("testcenterlocation")) Then
                batchData.TestCenterLocation = dataRecord.GetString(dataRecord.GetOrdinal("testcenterlocation"))
                batchData.TestCenterLocationID = dataRecord.GetInt32(dataRecord.GetOrdinal("testcenterlocationID"))
            End If

            batchData.RequestPurposeID = dataRecord.GetInt32(dataRecord.GetOrdinal("requestpurposeid"))

            If (batchData.RequestPurposeID = 0) Then
                batchData.RequestPurpose = "NotSet"
            Else
                batchData.RequestPurpose = dataRecord.GetString(dataRecord.GetOrdinal("requestpurpose"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("JobName")) Then
                batchData.JobName = dataRecord.GetString(dataRecord.GetOrdinal("JobName"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("testUnitCount")) Then
                batchData.NumberofUnits = dataRecord.GetInt32(dataRecord.GetOrdinal("testUnitCount"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("jobWILocation")) Then
                batchData.JobWILocation = dataRecord.GetString(dataRecord.GetOrdinal("jobWILocation"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("ActiveTaskAssignee")) Then
                batchData.ActiveTaskAssignee = dataRecord.GetString(dataRecord.GetOrdinal("ActiveTaskAssignee"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("TestStageName")) Then
                batchData.TestStageName = dataRecord.GetString(dataRecord.GetOrdinal("TestStageName"))
            End If

            If Helpers.HasColumn(dataRecord, "TestStageID") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("TestStageID")) Then
                    batchData.TestStageID = dataRecord.GetInt32(dataRecord.GetOrdinal("TestStageID"))
                End If
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("HasUnitstoReturnToRequestor")) Then
                batchData.HasUnitsNotReturnedToRequestor = (dataRecord.GetInt32(dataRecord.GetOrdinal("HasUnitstoReturnToRequestor")) > 0)
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("TestStageCompletionStatus")) Then
                batchData.TestStageCompletion = DirectCast(dataRecord.GetInt32(dataRecord.GetOrdinal("TestStageCompletionStatus")), TestStageCompletionStatus)
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("HasBatchSpecificExceptions")) Then
                batchData.hasBatchSpecificExceptions = dataRecord.GetBoolean(dataRecord.GetOrdinal("HasBatchSpecificExceptions"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("IsMQual")) Then
                batchData.IsMQual = dataRecord.GetBoolean(dataRecord.GetOrdinal("IsMQual"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("HWRevision")) Then
                batchData.HWRevision = dataRecord.GetString(dataRecord.GetOrdinal("HWRevision"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("PartName")) Then
                batchData.PartName = dataRecord.GetString(dataRecord.GetOrdinal("PartName"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("AssemblyNumber")) Then
                batchData.AssemblyNumber = dataRecord.GetString(dataRecord.GetOrdinal("AssemblyNumber"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("AssemblyRevision")) Then
                batchData.AssemblyRevision = dataRecord.GetString(dataRecord.GetOrdinal("AssemblyRevision"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("ReportApprovedDate")) Then
                batchData.ReportApprovedDate = dataRecord.GetDateTime(dataRecord.GetOrdinal("ReportApprovedDate"))
            End If

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("ReportRequiredBy")) Then
                batchData.ReportRequiredBy = dataRecord.GetDateTime(dataRecord.GetOrdinal("ReportRequiredBy"))
            End If

            If Helpers.HasColumn(dataRecord, "MechanicalTools") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("MechanicalTools")) Then
                    batchData.MechanicalTools = dataRecord.GetString(dataRecord.GetOrdinal("MechanicalTools"))
                End If
            End If

            If Helpers.HasColumn(dataRecord, "JobID") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("JobID")) Then
                    batchData.JobID = dataRecord.GetInt32(dataRecord.GetOrdinal("JobID"))
                End If
            End If

            If Helpers.HasColumn(dataRecord, "ContinueOnFailures") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("ContinueOnFailures")) Then
                    batchData.ContinueOnFailures = dataRecord.GetBoolean(dataRecord.GetOrdinal("ContinueOnFailures"))
                End If
            End If

            If Helpers.HasColumn(dataRecord, "EstTSCompletionTime") Then
                batchData.EstTSCompletionTime = dataRecord.GetFloat(dataRecord.GetOrdinal("EstTSCompletionTime"))
            End If

            If Helpers.HasColumn(dataRecord, "ExecutiveSummary") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("ExecutiveSummary")) Then
                    batchData.ExecutiveSummary = dataRecord.GetString(dataRecord.GetOrdinal("ExecutiveSummary"))
                End If
            End If

            If Helpers.HasColumn(dataRecord, "EstJobCompletionTime") Then
                batchData.EstJobCompletionTime = dataRecord.GetFloat(dataRecord.GetOrdinal("EstJobCompletionTime"))
            End If

            If Not Helpers.HasColumn(dataRecord, "EstTSCompletionTime") Then
                If (getTSRemaining) Then
                    Dim result2 As New Dictionary(Of String, Int32)
                    Dim result As Dictionary(Of String, Double) = DetermineEstimatedTSTime(batchData.ID, batchData.TestStageName, batchData.JobName, 0, 0, 1, result2)

                    batchData.EstTSCompletionTime = result("TSTimeLeft")
                    batchData.EstJobCompletionTime = result("JobTimeLeft")

                    result.Remove("TSTimeLeft")
                    result.Remove("JobTimeLeft")

                    batchData.TestStageIDTimeLeftGrid = result2
                    batchData.TestStageTimeLeftGrid = result
                End If
            End If

            If Helpers.HasColumn(dataRecord, "DateCreated") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("DateCreated")) Then
                    batchData.DateCreated = dataRecord.GetDateTime(dataRecord.GetOrdinal("DateCreated"))
                End If
            End If

            Helpers.FillObjectParameters(dataRecord, batchData)
        End Sub

        ''' <summary>
        ''' Uses the given sql connection and retreives all the required data for a batch.
        ''' </summary>
        ''' <param name="mybatchList"></param>
        ''' <param name="myconnection"></param>
        ''' <param name="getFailParams"></param>
        ''' <remarks></remarks>
        Private Shared Sub FillFullBatchFields(ByVal mybatchList As BatchCollection, ByVal myconnection As SqlConnection, Optional ByVal getFailParams As Boolean = True, Optional ByVal cacheData As Boolean = True, Optional ByVal getTrsData As Boolean = True, Optional ByVal getSpecificTestDurations As Boolean = True, Optional ByVal getJob As Boolean = True, Optional ByVal getExceptions As Boolean = True, Optional ByVal getTaskInfo As Boolean = True, Optional ByVal getByBatchStage As Boolean = False, Optional ByVal getTestRecords As Boolean = True)
            'from here on these use overloaded methods with current connection
            If mybatchList IsNot Nothing Then

                'Using myOracleConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq("TRSDBConnectionString"))
                '    myOracleConnection.Open()
                For Each myBatch As Batch In mybatchList
                    FillFullBatchFields(myBatch, myconnection, Nothing, getFailParams, cacheData, getTrsData, getSpecificTestDurations, getJob, getExceptions, getTaskInfo, getByBatchStage, getTestRecords)
                Next
                'End Using
            End If
        End Sub

        'Private Shared Sub FillFullBatchFields(ByVal batchData As Batch, ByVal sqlConnection As SqlConnection, Optional ByVal getFailParams As Boolean = True, Optional ByVal cacheData As Boolean = True, Optional ByVal getTrsData As Boolean = True, Optional ByVal getSpecificTestDurations As Boolean = True, Optional ByVal getJob As Boolean = True, Optional ByVal getExceptions As Boolean = True, Optional ByVal getTaskInfo As Boolean = True, Optional ByVal getByBatchStage As Boolean = False)
        '    'from here on these use overloaded methods with current connection
        '    If batchData IsNot Nothing Then
        '        Using myOracleConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq("TRSDBConnectionString"))
        '            myOracleConnection.Open()
        '            FillFullBatchFields(batchData, sqlConnection, myOracleConnection, getFailParams, cacheData, getTrsData, getSpecificTestDurations, getJob, getExceptions, getTaskInfo, getByBatchStage)
        '        End Using
        '    End If
        'End Sub

        Private Shared Sub FillFullBatchfields(ByVal batchData As Batch, ByVal sqlConnection As SqlConnection, ByVal oracleConnection As OracleConnection, ByVal getFailParams As Boolean, ByVal cacheData As Boolean, ByVal getTrsData As Boolean, ByVal getSpecificTestDurations As Boolean, ByVal getJob As Boolean, ByVal getExceptions As Boolean, ByVal getTaskInfo As Boolean, ByVal getByBatchStage As Boolean, ByVal getTestRecords As Boolean)
            'If getFailParams Then
            '    batchData.FailParameters = REMIAppCache.GetFailParams(batchData.QRANumber)
            '    If batchData.FailParameters Is Nothing Then
            '        batchData.FailParameters = TestRecordDB.GetParamterResults(batchData.QRANumber, batchData.JobName, String.Empty, oracleConnection)
            '        If cacheData Then
            '            REMIAppCache.SetFailParams(batchData.QRANumber, batchData.FailParameters)
            '        End If
            '    End If
            'End If

            If getTrsData Then
                batchData.TRSData = REMIAppCache.GetReqData(batchData.QRANumber)
                If batchData.TRSData.RQID <= 0 Then
                    If oracleConnection Is Nothing Then
                        oracleConnection = New OracleConnection(REMIConfiguration.ConnectionStringReq(RequestDB.GetConnectString(batchData.QRANumber)))

                        If oracleConnection.State <> ConnectionState.Open Then
                            oracleConnection.Open()
                        End If
                    End If

                    batchData.TRSData = DirectCast(RequestDB.GetTRSRequest(batchData.QRANumber, oracleConnection), RequestBase)
                    If cacheData Then
                        REMIAppCache.SetReqData(batchData.TRSData)
                    End If
                End If
            End If

            If getJob Then
                batchData.SetJob(REMIAppCache.GetJob(batchData.JobName))
                If batchData.Job.ID <= 0 Then
                    batchData.SetJob(JobDB.GetItem(batchData.JobName, sqlConnection, 0))
                    If cacheData Then
                        REMIAppCache.SetJob(batchData.Job)
                    End If
                End If
            End If

            If getSpecificTestDurations Then
                batchData.SpecificTestDurations = REMIAppCache.GetSpecificTestDurations(batchData.QRANumber)
                If batchData.SpecificTestDurations Is Nothing Then
                    batchData.SpecificTestDurations = TestDB.GetListOfBatchSpecificTestDurations(batchData.QRANumber, sqlConnection)
                    If cacheData Then
                        REMIAppCache.SetSpecificTestDurations(batchData.QRANumber, batchData.SpecificTestDurations)
                    End If
                End If
            End If

            If getExceptions Then
                batchData.TestExceptions = REMIAppCache.GetTestExceptions(batchData.QRANumber)
                If batchData.TestExceptions Is Nothing Then
                    batchData.TestExceptions = TestExceptionDB.GetExceptionsForBatch(batchData.QRANumber)
                    If cacheData Then
                        REMIAppCache.SetTestExceptions(batchData.QRANumber, batchData.TestExceptions)
                    End If
                End If
            End If

            If (getTaskInfo) Then
                GetBatchTaskInfo(batchData, getByBatchStage)
            End If

            If (getTestRecords) Then
                Dim tr As TestRecordCollection = REMIAppCache.GetTestRecords(batchData.QRANumber)
                batchData.TestRecords = tr

                If batchData.TestRecords Is Nothing OrElse batchData.TestRecords.Count = 0 Then
                    batchData.TestRecords = TestRecordDB.GetTestRecordsForBatch(batchData.QRANumber, sqlConnection)
                    If cacheData Then
                        REMIAppCache.SetTestRecords(batchData.QRANumber, batchData.TestRecords)
                    End If
                End If
            End If

            'get the testunits each time in case the last log has changed.

            batchData.TestUnits = TestUnitDB.GetBatchUnits(batchData.QRANumber, sqlConnection)

            For Each tu As TestUnit In batchData.TestUnits
                tu.CurrentTestStage = batchData.Job.TestStages.FindByName(tu.CurrentTestStage.Name)
            Next
        End Sub
#End Region
    End Class
End Namespace