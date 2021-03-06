﻿Imports System
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

#Region "GET"
        Public Shared Sub GetBatchTaskInfo(ByVal batchdata As BatchView, ByVal getByBatchStage As Boolean, ByVal myConnection As SqlConnection)
            If (myConnection Is Nothing) Then
                myConnection = New SqlConnection(REMIConfiguration.ConnectionStringREMI)
            End If

            Using myCommand As New SqlCommand("remispBatchGetTaskInfo", myConnection)
                myCommand.CommandType = CommandType.StoredProcedure
                myCommand.Parameters.AddWithValue("@BatchID", batchdata.ID)

                If (getByBatchStage) Then
                    myCommand.Parameters.AddWithValue("@TestStageID", batchdata.TestStageID)
                End If

                If myConnection.State <> ConnectionState.Open Then
                    myConnection.Open()
                End If

                Dim dt As New DataTable
                Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                da.Fill(dt)
                dt.TableName = "TaskInfo"
                GetBatchTask(dt, batchdata)
            End Using
        End Sub

        Public Shared Function GetBatchComments(ByVal requestNumber As String, ByVal myConnection As SqlConnection) As List(Of IBatchCommentView)
            Dim b As BatchView = New BatchView()

            If (myConnection Is Nothing) Then
                myConnection = New SqlConnection(REMIConfiguration.ConnectionStringREMI)
            End If

            Using myCommand As New SqlCommand("remispBatchCommentsGetByQRANumber", myConnection)
                myCommand.CommandType = CommandType.StoredProcedure
                myCommand.Parameters.AddWithValue("qranumber", requestNumber)

                If myConnection.State <> ConnectionState.Open Then
                    myConnection.Open()
                End If

                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                    If myReader.HasRows Then
                        b = New BatchView()
                        While myReader.Read()
                            FillBatchComment(myReader, b)
                        End While
                    End If
                End Using
            End Using

            Return b.Comments
        End Function

        Public Shared Function GetSlimBatchByQRANumber(ByVal qraNumber As String, ByVal user As User, ByVal cacheRetrievedData As Boolean, ByVal loadDurations As Boolean, ByVal loadJob As Boolean, ByVal loadExceptions As Boolean, ByVal loadTasks As Boolean, ByVal getByBatchStage As Boolean, ByVal loadTestRecords As Boolean, ByVal loadOrientation As Boolean, ByVal loadTSRemaining As Boolean, ByVal loadComments As Boolean) As BatchView
            Dim batch As BatchView = Nothing

            Using sqlConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Dim bc As New DeviceBarcodeNumber(qraNumber)

                If (bc.Validate()) Then
                    Using myCommand As New SqlCommand("remispBatchGetViewBatch", sqlConnection)
                        myCommand.CommandType = CommandType.StoredProcedure
                        myCommand.Parameters.AddWithValue("@RequestNumber", bc.BatchNumber)

                        If sqlConnection.State <> ConnectionState.Open Then
                            sqlConnection.Open()
                        End If

                        Dim dt As New DataTable
                        Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                        da.Fill(dt)
                        dt.TableName = "ViewBatch"
                        batch = New BatchView(bc.BatchNumber)

                        Dim lst As List(Of BatchView) = BusinessEntities.Helpers.GetList(Of BatchView)(dt)

                        If (lst.Count > 0) Then
                            batch = lst(0)
                            FillFullBatchfields(batch, sqlConnection, cacheRetrievedData, loadDurations, loadJob, loadExceptions, loadTasks, getByBatchStage, loadTestRecords, loadOrientation, loadTSRemaining, loadComments, user)
                        End If
                    End Using
                End If
            End Using

            Return batch
        End Function

        Public Shared Function GetOrientation(ByVal orientationID As Int32, ByVal myConnection As SqlConnection) As IOrientation
            Dim bo As IOrientation = New Orientation()

            If (myConnection Is Nothing) Then
                myConnection = New SqlConnection(REMIConfiguration.ConnectionStringREMI)
            End If

            Using myCommand As New SqlCommand("remispGetOrientation", myConnection)
                myCommand.CommandType = CommandType.StoredProcedure
                myCommand.Parameters.AddWithValue("@ID", orientationID)
                If myConnection.State <> ConnectionState.Open Then
                    myConnection.Open()
                End If

                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                    If myReader.HasRows Then
                        If myReader.Read() Then
                            FillBatchOrientation(myReader, bo)
                        End If
                    End If
                End Using
            End Using

            Return bo
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

        Public Shared Function GetListInChambers(ByVal testCentreLocationID As Int32, ByVal startRowIndex As Integer, ByVal maximumRows As Integer, ByVal sortExpression As String, ByVal byPass As Boolean, ByVal user As User) As BatchCollection
            Dim tmpList As BatchCollection = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispBatchesSelectChamberBatches", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    If testCentreLocationID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestCentreLocation", testCentreLocationID)
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
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    Dim dt As New DataTable
                    da.Fill(dt)
                    dt.TableName = "ChamberBatches"

                    Dim lst As List(Of BatchView) = BusinessEntities.Helpers.GetList(Of BatchView)(dt)
                    tmpList.AddRange(lst)

                    For Each b As BatchView In tmpList
                        FillFullBatchfields(b, myConnection, False, True, True, True, False, False, False, False, False, False, user)
                    Next
                End Using
            End Using

            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New BatchCollection
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
#End Region

#Region "Save"
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

        Public Shared Function DetermineEstimatedTSTime(ByVal batchID As Int32, ByVal testStageName As String, ByVal jobName As String, ByVal testStageID As Int32, ByVal jobID As Int32, ByVal returnTestStageGrid As Int32, ByRef result2 As Dictionary(Of String, Int32), ByVal myConnection As SqlConnection) As Dictionary(Of String, Double)
            Dim result As New Dictionary(Of String, Double)

            If (Not String.IsNullOrEmpty(testStageName)) Then
                If (myConnection Is Nothing) Then
                    myConnection = New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                End If

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

                    If myConnection.State <> ConnectionState.Open Then
                        myConnection.Open()
                    End If

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
            End If

            Return result
        End Function

        ''' <summary>Saves an instance of the <see cref="Batch" /> in the database.</summary> 
        ''' <param name="myBatch">The Batch instance to save.</param> 
        ''' <returns>Returns the id of the batch when the object was saved successfully, or 0 otherwise.</returns> 
        Public Shared Function Save(ByVal MyBatch As BatchView) As Integer
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

#Region "Search"
        Private Shared Function BatchSearch(ByVal conn As SqlConnection, ByVal bs As BatchSearch, ByVal byPass As Boolean, ByVal userID As Int32, ByVal loadTestRecords As Boolean, ByVal loadDurations As Boolean, ByVal loadTSRemaining As Boolean, ByVal user As User, ByVal OnlyHasResults As Int32) As SqlCommand
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

                Return myCommand
            End Using
        End Function

        Public Shared Function BatchSearch(ByVal bs As BatchSearch, ByVal byPass As Boolean, ByVal userID As Int32, ByVal loadTestRecords As Boolean, ByVal loadDurations As Boolean, ByVal loadTSRemaining As Boolean, ByVal user As User, ByVal OnlyHasResults As Int32, ByVal loadOrientation As Boolean, ByVal loadExcpetions As Boolean, ByVal loadTasks As Boolean, ByVal getByBatchStage As Boolean, ByVal loadComments As Boolean) As BatchCollection
            Dim tmpList As New BatchCollection()
            Dim dt As New DataTable

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Dim da As SqlDataAdapter = New SqlDataAdapter(BatchSearch(myConnection, bs, byPass, userID, loadTestRecords, loadDurations, loadTestRecords, user, OnlyHasResults))
                da.Fill(dt)
                dt.TableName = "BatchSearch"

                Dim lst As List(Of BatchView) = BusinessEntities.Helpers.GetList(Of BatchView)(dt)
                tmpList.AddRange(lst)

                For Each b As BatchView In tmpList
                    FillFullBatchfields(b, myConnection, False, loadDurations, True, loadExcpetions, loadTasks, getByBatchStage, loadTestRecords, loadOrientation, loadTSRemaining, loadComments, user)
                Next
            End Using

            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New BatchCollection
            End If
        End Function

        Public Shared Function BatchSearchBase(ByVal bs As BatchSearch, ByVal byPass As Boolean, ByVal userID As Int32, ByVal loadTestRecords As Boolean, ByVal loadDurations As Boolean, ByVal loadTSRemaining As Boolean, ByVal user As User, ByVal OnlyHasResults As Int32, ByVal loadExcpetions As Boolean, ByVal loadTasks As Boolean, ByVal getByBatchStage As Boolean, ByVal loadOrientation As Boolean, ByVal loadComments As Boolean) As List(Of BatchView)
            Dim tmpList As New List(Of BatchView)()
            Dim dt As New DataTable

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Dim da As SqlDataAdapter = New SqlDataAdapter(BatchSearch(myConnection, bs, byPass, userID, loadTestRecords, loadDurations, loadTestRecords, user, OnlyHasResults))
                da.Fill(dt)
                dt.TableName = "BatchSearch"

                Dim lst As List(Of BatchView) = BusinessEntities.Helpers.GetList(Of BatchView)(dt)
                tmpList.AddRange(lst)

                For Each b As BatchView In tmpList
                    FillFullBatchfields(b, myConnection, False, loadDurations, True, loadExcpetions, loadTasks, getByBatchStage, loadTestRecords, loadOrientation, loadTSRemaining, loadComments, user)
                Next
            End Using

            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New List(Of BatchView)
            End If
        End Function
#End Region

#Region "Fill Methods"
        Private Shared Function GetBatchTask(ByVal myreader As DataTable, ByVal batchdata As BatchView) As Boolean
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

        Private Shared Sub FillFullBatchfields(ByVal batchData As BatchView, ByVal sqlConnection As SqlConnection, ByVal cacheData As Boolean, ByVal getSpecificTestDurations As Boolean, ByVal getJob As Boolean, ByVal getExceptions As Boolean, ByVal getTaskInfo As Boolean, ByVal getByBatchStage As Boolean, ByVal getTestRecords As Boolean, ByVal loadOrientation As Boolean, ByVal loadTSRemaining As Boolean, ByVal loadComments As Boolean, ByVal user As User)
            batchData.ReqData = RequestDB.GetRequest(batchData.QRANumber, user, sqlConnection)

            If getJob Then
                batchData.SetJob(REMIAppCache.GetJob(batchData.JobName))
                If batchData.Job Is Nothing Then
                    batchData.SetJob(JobDB.GetItem(batchData.JobName, sqlConnection, 0))
                    If cacheData Then
                        REMIAppCache.SetJob(batchData.Job)
                    End If
                End If
            End If

            If (Not batchData.TestStageID > 0) Then
                Dim ts As TestStage = batchData.Job.GetTestStage(batchData.TestStageName)
                If (ts IsNot Nothing) Then
                    batchData.TestStageID = ts.ID
                End If
            End If

            If (loadComments) Then
                batchData.Comments = GetBatchComments(batchData.QRANumber, sqlConnection)
            End If

            If (loadTSRemaining And Not String.IsNullOrEmpty(batchData.TestStageName)) Then
                Dim result2 As New Dictionary(Of String, Int32)
                Dim result As Dictionary(Of String, Double) = DetermineEstimatedTSTime(batchData.ID, batchData.TestStageName, batchData.JobName, batchData.TestStageID, batchData.JobID, 1, result2, sqlConnection)

                batchData.EstTSCompletionTime = result("TSTimeLeft")
                batchData.EstJobCompletionTime = result("JobTimeLeft")

                result.Remove("TSTimeLeft")
                result.Remove("JobTimeLeft")

                batchData.TestStageIDTimeLeftGrid = result2
                batchData.TestStageTimeLeftGrid = result
            End If

            If (loadOrientation) Then
                batchData.Orientation = GetOrientation(batchData.OrientationID, sqlConnection)
                batchData.OrientationXML = batchData.Orientation.Definition
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
                    batchData.TestExceptions = TestExceptionDB.GetExceptionsForBatch(batchData.QRANumber, sqlConnection)
                    If cacheData Then
                        REMIAppCache.SetTestExceptions(batchData.QRANumber, batchData.TestExceptions)
                    End If
                End If
            End If

            If (getTaskInfo) Then
                GetBatchTaskInfo(batchData, getByBatchStage, sqlConnection)
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