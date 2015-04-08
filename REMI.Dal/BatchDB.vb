Imports System
Imports System.Data
Imports System.Data.SqlClient
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

        Public Shared Function GetOrientation(ByVal orientationID As Int32) As IOrientation
            Dim bo As IOrientation = New Orientation()

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetOrientation", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", orientationID)
                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            If myReader.Read() Then
                                FillBatchOrientation(myReader, bo)
                            End If
                        End If
                    End Using
                End Using
            End Using

            Return bo
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

        Public Shared Function GetSlimBatchByQRANumber(ByVal qraNumber As String, ByVal user As User, Optional ByVal cacheRetrievedData As Boolean = True) As BatchView
            Dim batch As BatchView = Nothing

            Using sqlConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
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
                                batch = New BatchView(bc.BatchNumber)
                                batch.ReqData = RequestDB.GetRequest(bc.BatchNumber, user)

                                While myReader.Read()
                                    FillBaseBatchFields(myReader, batch, False, False, True, user)
                                End While

                                myReader.NextResult()

                                While myReader.Read()
                                    FillBatchComment(myReader, batch)
                                End While

                                myReader.NextResult()

                                While myReader.Read()
                                    FillBatchTask(myReader, batch)
                                End While

                                myReader.NextResult()

                                While myReader.Read()
                                    batch.TestRecords.Add(TestRecordDB.FillDataRecord(myReader))
                                End While

                                myReader.NextResult()

                                While myReader.Read()
                                    batch.TestUnits.Add(TestUnitDB.FillDataRecord(myReader))
                                End While
                            End If
                        End Using
                    End Using
                End If
            End Using

            Return batch
        End Function

#Region "Public Stored Proc Methods"
        ''' <summary> 
        ''' Returns a list of batches in environmental chambers
        ''' </summary>
        ''' <returns>
        ''' A BatchCollection.
        ''' </returns> 
        Public Shared Function GetListInChambers(ByVal testCentreLocation As Int32, ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal sortExpression As String, ByVal byPass As Boolean, ByVal user As User) As BatchCollection
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

                    myCommand.Parameters.AddWithValue("@UserID", user.ID)

                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()

                        If myReader.HasRows Then
                            tmpList = New BatchCollection()

                            While myReader.Read()
                                Dim myBatch As Batch = New BusinessEntities.Batch()
                                FillBaseBatchFields(myReader, myBatch, False, False, False, user)

                                tmpList.Add(myBatch)
                            End While
                        End If
                    End Using
                End Using

                FillFullBatchFields(tmpList, myConnection, False, True, True, False, False, False, False)
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
        Public Shared Function GetListAtLocation(ByVal trackingLocationID As Integer, ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal sortExpression As String, ByVal user As User) As BatchCollection
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
                                Dim myBatch As Batch = New BusinessEntities.Batch()
                                FillBaseBatchFields(myReader, myBatch, False, False, False, User)

                                tmpList.Add(myBatch)
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

        Public Shared Function GetBatchByQRANumber(ByVal qraNumber As String, ByVal user As User, Optional ByVal cacheRetrievedData As Boolean = True) As Batch
            Dim batchData As Batch = Nothing

            Using sqlConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                If batchData Is Nothing Then

                    Using myCommand As New SqlCommand("remispBatchesSelectByQRANumber", sqlConnection)
                        myCommand.CommandType = CommandType.StoredProcedure
                        myCommand.Parameters.AddWithValue("@QRANumber", qraNumber)

                        If sqlConnection.State <> ConnectionState.Open Then
                            sqlConnection.Open()
                        End If

                        Using myReader As SqlDataReader = myCommand.ExecuteReader()
                            If myReader.HasRows Then
                                batchData = New Batch(qraNumber)

                                While myReader.Read()
                                    FillBaseBatchFields(myReader, batchData, True, False, False, User)
                                End While

                                myReader.NextResult()

                                While myReader.Read()
                                    FillBatchComment(myReader, batchData)
                                End While
                            End If
                        End Using
                    End Using
                End If

                If (batchData IsNot Nothing) Then
                    FillFullBatchFields(batchData, sqlConnection, cacheRetrievedData, True, True, True, True, False, True)
                End If
            End Using

            Return batchData
        End Function

        Private Shared Function BatchSearch(ByVal conn As SqlConnection, ByVal bs As BatchSearch, ByVal byPass As Boolean, ByVal userID As Int32, ByVal loadTestRecords As Boolean, ByVal loadDurations As Boolean, ByVal loadTSRemaining As Boolean, ByVal user As User, ByVal OnlyHasResults As Int32) As SqlDataReader
            Using myCommand As New SqlCommand("remispBatchesSearch", conn)
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
                myCommand.Parameters.AddWithValue("@OnlyHasResults", OnlyHasResults)

                conn.Open()

                Return myCommand.ExecuteReader()
            End Using
        End Function

        Public Shared Function BatchSearch(ByVal bs As BatchSearch, ByVal byPass As Boolean, ByVal userID As Int32, ByVal loadTestRecords As Boolean, ByVal loadDurations As Boolean, ByVal loadTSRemaining As Boolean, ByVal user As User, ByVal OnlyHasResults As Int32) As BatchCollection
            Dim tmpList As New BatchCollection()

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myReader As SqlDataReader = BatchSearch(myConnection, bs, byPass, userID, loadTestRecords, loadDurations, loadTestRecords, user, OnlyHasResults)
                    If myReader.HasRows Then
                        tmpList = New BatchCollection()

                        While myReader.Read()
                            Dim myBatch As Batch = New BusinessEntities.Batch()
                            FillBaseBatchFields(myReader, myBatch, loadTSRemaining, False, False, user)
                            tmpList.Add(myBatch)
                        End While
                    End If
                End Using

                FillFullBatchFields(tmpList, myConnection, False, loadDurations, True, False, False, False, loadTestRecords)
            End Using

            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New BatchCollection
            End If
        End Function

        Public Shared Function BatchSearchBase(ByVal bs As BatchSearch, ByVal byPass As Boolean, ByVal userID As Int32, ByVal loadTestRecords As Boolean, ByVal loadDurations As Boolean, ByVal loadTSRemaining As Boolean, ByVal user As User, ByVal OnlyHasResults As Int32) As List(Of BatchView)
            Dim tmpList As New List(Of BatchView)()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myReader As SqlDataReader = BatchSearch(myConnection, bs, byPass, userID, loadTestRecords, loadDurations, loadTestRecords, user, OnlyHasResults)
                    If myReader.HasRows Then
                        tmpList = New List(Of BatchView)
                        While myReader.Read()
                            Dim myBatch As BatchView = New BusinessEntities.BatchView()
                            FillBaseBatchFields(myReader, myBatch, loadTSRemaining, False, False, user)

                            tmpList.Add(myBatch)
                        End While
                    End If
                End Using
            End Using

            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New List(Of BatchView)
            End If
        End Function

        Public Shared Function GetBatchUnitsInStage(ByVal QRANumber As String) As DataTable
            Dim dt As New DataTable("BatchUnitsInStage")

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetBatchUnitsInStage", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", QRANumber)
                    myConnection.Open()

                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "BatchUnitsInStage"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetBatchDocuments(ByVal QRANumber As String) As DataTable
            Dim dt As New DataTable("BatchDocuments")

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

        Public Shared Function GetBatchJIRA(ByVal batchID As Int32) As DataTable
            Dim dt As New DataTable("BatchJIRA")

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetBatchJIRAs", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)
                    myConnection.Open()

                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "BatchJIRA"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetYourActiveBatchesDataTable(ByVal UserID As Integer, ByVal byPass As Boolean, ByVal year As Int32, ByVal onlyShowQRAWithResults As Boolean) As DataTable
            Dim dt As New DataTable("ActiveBatches")
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

        Public Shared Function GetStagesNeedingCompletionByUnit(ByVal requestNumber As String, ByVal unitNumber As Int32) As DataSet
            Dim ds As New DataSet()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetStagesNeedingCompletionByUnit", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@RequestNumber", requestNumber)

                    If (unitNumber > 0) Then
                        myCommand.Parameters.AddWithValue("@BatchUnitNumber", unitNumber)
                    End If

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(ds)

                    For i = 0 To ds.Tables.Count - 1
                        If (ds.Tables(i).Rows.Count > 0) Then
                            ds.Tables(i).TableName = ds.Tables(i).Rows(0).Item("BatchUnitNumber").ToString()
                        End If
                    Next
                End Using
            End Using

            Return ds
        End Function

        ''' <summary> 
        ''' This method returns a list of batches where the status is not complete or rejected.
        ''' </summary> 
        Public Shared Function GetActiveBatches(ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal isRemiTimedServiceCall As Boolean, ByVal user As User) As BatchCollection
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
                                Dim myBatch As Batch = New BusinessEntities.Batch()

                                If (isRemiTimedServiceCall) Then
                                    FillBaseBatchFields(myReader, myBatch, False, True, False, user)
                                Else
                                    FillBaseBatchFields(myReader, myBatch, True, False, False, user)
                                End If

                                tmpList.Add(myBatch)
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

        Public Shared Function GetActiveBatches(ByVal requestor As String, ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal user As User) As BatchCollection
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
                                Dim myBatch As Batch = New BusinessEntities.Batch()
                                FillBaseBatchFields(myReader, myBatch, False, False, False, user)

                                tmpList.Add(myBatch)
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

                    If (MyBatch.TestCenterLocation Is Nothing) Then
                        myCommand.Parameters.AddWithValue("@TestCenterLocation", "NotSet")
                    Else
                        myCommand.Parameters.AddWithValue("@TestCenterLocation", MyBatch.TestCenterLocation)
                    End If

                    If (MyBatch.Priority Is Nothing) Then
                        myCommand.Parameters.AddWithValue("@Priority", "NotSet")
                        myCommand.Parameters.AddWithValue("@PriorityID", 0)
                    Else
                        myCommand.Parameters.AddWithValue("@Priority", MyBatch.Priority)
                        myCommand.Parameters.AddWithValue("@PriorityID", MyBatch.PriorityID)
                    End If

                    If (MyBatch.RequestPurpose Is Nothing) Then
                        myCommand.Parameters.AddWithValue("@RequestPurpose", "NotSet")
                        myCommand.Parameters.AddWithValue("@RequestPurposeID", 0)
                    Else
                        myCommand.Parameters.AddWithValue("@RequestPurpose", MyBatch.RequestPurpose)
                        myCommand.Parameters.AddWithValue("@RequestPurposeID", MyBatch.RequestPurposeID)
                    End If

                    myCommand.Parameters.AddWithValue("@BatchStatus", MyBatch.Status)
                    myCommand.Parameters.AddWithValue("@Requestor", MyBatch.Requestor)
                    myCommand.Parameters.AddWithValue("@ProductGroupName", MyBatch.ProductGroup)
                    myCommand.Parameters.AddWithValue("@AccessoryGroupName", MyBatch.AccessoryGroup)

                    If (MyBatch.ProductType Is Nothing) Then
                        myCommand.Parameters.AddWithValue("@ProductType", "NotSet")
                    Else
                        myCommand.Parameters.AddWithValue("@ProductType", MyBatch.ProductType)
                    End If

                    myCommand.Parameters.AddWithValue("@testStageCompletionStatus", MyBatch.TestStageCompletion)

                    If Not String.IsNullOrEmpty(MyBatch.TestStageName) Then
                        myCommand.Parameters.AddWithValue("@TestStageName", MyBatch.TestStageName)
                    End If

                    myCommand.Parameters.AddWithValue("@unitsToBeReturnedToRequestor", MyBatch.HasUnitsRequiredToBeReturnedToRequestor)
                    myCommand.Parameters.AddWithValue("@expectedSampleSize", MyBatch.NumberOfUnitsExpected)

                    If MyBatch.ReportRequiredBy <> DateTime.MinValue Then
                        myCommand.Parameters.AddWithValue("@reportRequiredBy", MyBatch.ReportRequiredBy)
                    End If

                    If MyBatch.ReportApprovedDate <> DateTime.MinValue Then
                        myCommand.Parameters.AddWithValue("@reportApprovedDate", MyBatch.ReportApprovedDate)
                    End If

                    If Not String.IsNullOrEmpty(MyBatch.RequestStatus) Then
                        myCommand.Parameters.AddWithValue("@ReqStatus", MyBatch.RequestStatus)
                    End If

                    If Not String.IsNullOrEmpty(MyBatch.CPRNumber) Then
                        myCommand.Parameters.AddWithValue("@cprNumber", MyBatch.CPRNumber)
                    End If

                    myCommand.Parameters.AddWithValue("@MechanicalTools", MyBatch.MechanicalTools)

                    If (MyBatch.Department Is Nothing) Then
                        myCommand.Parameters.AddWithValue("@Department", "NotSet")
                        myCommand.Parameters.AddWithValue("@DepartmentID", 0)
                    Else
                        myCommand.Parameters.AddWithValue("@DepartmentID", MyBatch.DepartmentID)
                        myCommand.Parameters.AddWithValue("@Department", MyBatch.Department)
                    End If

                    myCommand.Parameters.AddWithValue("@ExecutiveSummary", MyBatch.ExecutiveSummary)

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

        Public Shared Function MoveBatchForward(ByVal requestNumber As String, ByVal userIdentification As String) As Boolean
            Dim result As Int32 = 0

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispMoveBatchForward", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@RequestNumber", requestNumber)
                    myCommand.Parameters.AddWithValue("@UserName", userIdentification)

                    Dim returnValue As New SqlParameter("ReturnValue", SqlDbType.Int)
                    returnValue.Direction = ParameterDirection.ReturnValue
                    myCommand.Parameters.Add(returnValue)

                    myConnection.Open()
                    myCommand.ExecuteScalar()
                    Int32.TryParse(returnValue.Value.ToString(), result)
                End Using
            End Using

            Return result > 0
        End Function
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
                currentBatchTask.SetUnitResultCheck(dr.Item("TestCounts").ToString())
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
            currentBatchTask.SetUnitResultCheck(myreader.GetString(myreader.GetOrdinal("TestCounts")))
            currentBatchTask.TestID = myreader.GetInt32(myreader.GetOrdinal("TestID"))
            currentBatchTask.TestStageID = myreader.GetInt32(myreader.GetOrdinal("TestStageID"))
            currentBatchTask.IsArchived = myreader.GetBoolean(myreader.GetOrdinal("IsArchived"))
            currentBatchTask.TestIsArchived = myreader.GetBoolean(myreader.GetOrdinal("TestIsArchived"))

            b.Tasks.Add(currentBatchTask)
        End Sub

        Private Shared Sub FillBatchOrientation(ByVal myreader As IDataRecord, ByRef bo As IOrientation)
            bo.CreatedDate = myreader.GetDateTime(myreader.GetOrdinal("CreatedDate"))
            bo.ID = myreader.GetInt32(myreader.GetOrdinal("ID"))
            bo.ProductTypeID = myreader.GetInt32(myreader.GetOrdinal("ProductTypeID"))
            bo.NumDrops = myreader.GetInt32(myreader.GetOrdinal("NumDrops"))
            bo.JobID = myreader.GetInt32(myreader.GetOrdinal("JobID"))
            bo.NumUnits = myreader.GetInt32(myreader.GetOrdinal("NumUnits"))
            bo.Name = myreader.GetString(myreader.GetOrdinal("Name"))
            bo.ProductType = myreader.GetString(myreader.GetOrdinal("ProductType"))
            bo.Definition = myreader.GetString(myreader.GetOrdinal("Definition"))
            bo.Description = myreader.GetString(myreader.GetOrdinal("Description"))
            bo.IsActive = myreader.GetBoolean(myreader.GetOrdinal("IsActive"))
        End Sub

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

        Private Shared Sub FillBaseBatchFields(ByVal dataRecord As IDataRecord, ByVal batchData As BatchView, ByVal getTSRemaining As Boolean, ByVal isRemiTimedServiceCall As Boolean, ByVal loadOrientation As Boolean, ByVal user As User)
            batchData.QRANumber = dataRecord.GetString(dataRecord.GetOrdinal("QRANumber"))

            batchData.ReqData = RequestDB.GetRequest(batchData.QRANumber, user)

            batchData.Status = DirectCast(dataRecord.GetInt32(dataRecord.GetOrdinal("BatchStatus")), BatchStatus)
            batchData.PriorityID = dataRecord.GetInt32(dataRecord.GetOrdinal("PriorityID"))

            If (batchData.PriorityID = 0) Then
                batchData.Priority = "NotSet"
            Else
                batchData.Priority = dataRecord.GetString(dataRecord.GetOrdinal("Priority"))
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
                batchData.NumberOfUnits = dataRecord.GetInt32(dataRecord.GetOrdinal("testUnitCount"))
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
                batchData.HasBatchSpecificExceptions = dataRecord.GetBoolean(dataRecord.GetOrdinal("HasBatchSpecificExceptions"))
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

            If Helpers.HasColumn(dataRecord, "Department") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("Department")) Then
                    batchData.Department = dataRecord.GetString(dataRecord.GetOrdinal("Department"))
                End If
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("DepartmentID")) Then
                    batchData.DepartmentID = dataRecord.GetInt32(dataRecord.GetOrdinal("DepartmentID"))
                End If
            End If

            If Helpers.HasColumn(dataRecord, "JobID") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("JobID")) Then
                    batchData.JobID = dataRecord.GetInt32(dataRecord.GetOrdinal("JobID"))
                End If
            End If

            If Helpers.HasColumn(dataRecord, "TestUnitCount") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("TestUnitCount")) Then
                    batchData.NumberOfUnitsExpected = dataRecord.GetInt32(dataRecord.GetOrdinal("TestUnitCount"))
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

            If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("Requestor")) Then
                batchData.Requestor = dataRecord.GetString(dataRecord.GetOrdinal("Requestor"))
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

            If Helpers.HasColumn(dataRecord, "OrientationID") Then
                If Not dataRecord.IsDBNull(dataRecord.GetOrdinal("OrientationID")) Then
                    If (loadOrientation) Then
                        batchData.Orientation = GetOrientation(dataRecord.GetInt32(dataRecord.GetOrdinal("OrientationID")))
                        batchData.OrientationID = batchData.Orientation.ID
                        batchData.OrientationXML = batchData.Orientation.Definition
                    Else
                        batchData.OrientationID = dataRecord.GetInt32(dataRecord.GetOrdinal("OrientationID"))
                    End If
                End If
            End If

            Helpers.FillObjectParameters(dataRecord, batchData)
        End Sub

        ''' <summary>
        ''' Uses the given sql connection and retreives all the required data for a batch.
        ''' </summary>
        ''' <param name="mybatchList"></param>
        ''' <param name="myconnection"></param>
        ''' <remarks></remarks>
        Private Shared Sub FillFullBatchFields(ByVal mybatchList As BatchCollection, ByVal myconnection As SqlConnection, Optional ByVal cacheData As Boolean = True, Optional ByVal getSpecificTestDurations As Boolean = True, Optional ByVal getJob As Boolean = True, Optional ByVal getExceptions As Boolean = True, Optional ByVal getTaskInfo As Boolean = True, Optional ByVal getByBatchStage As Boolean = False, Optional ByVal getTestRecords As Boolean = True)
            'from here on these use overloaded methods with current connection
            If mybatchList IsNot Nothing Then
                For Each myBatch As Batch In mybatchList
                    FillFullBatchFields(myBatch, myconnection, cacheData, getSpecificTestDurations, getJob, getExceptions, getTaskInfo, getByBatchStage, getTestRecords)
                Next
            End If
        End Sub

        Private Shared Sub FillFullBatchfields(ByVal batchData As Batch, ByVal sqlConnection As SqlConnection, ByVal cacheData As Boolean, ByVal getSpecificTestDurations As Boolean, ByVal getJob As Boolean, ByVal getExceptions As Boolean, ByVal getTaskInfo As Boolean, ByVal getByBatchStage As Boolean, ByVal getTestRecords As Boolean)
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
                If (tu.CurrentTestStage.ID = 0) Then
                    tu.CurrentTestStage = batchData.Job.TestStages.FindByName(tu.CurrentTestStage.Name)
                End If
            Next
        End Sub
#End Region
    End Class
End Namespace