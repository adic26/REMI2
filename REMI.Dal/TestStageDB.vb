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
    ''' The TestStageDB class is responsible for interacting with the database to retrieve and store information 
    ''' about TestStage objects.
    ''' </summary>
    Public Class TestStageDB
#Region "Task Assignment Methods"
        Public Shared Function GetTaskAssignments(ByVal qranumber As String) As List(Of REMI.BaseObjectModels.TaskAssignment)
            Dim taskAssignments As New List(Of REMI.BaseObjectModels.TaskAssignment)

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTaskAssignmentGetListForBatch", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@qraNumber", qranumber)

                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                Dim ta As New REMI.BaseObjectModels.TaskAssignment()

                                If Not myReader.IsDBNull(myReader.GetOrdinal("AssignedBy")) Then
                                    ta.AssignedBy = myReader.GetString(myReader.GetOrdinal("AssignedBy"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("AssignedTo")) Then
                                    ta.AssignedTo = myReader.GetString(myReader.GetOrdinal("AssignedTo"))
                                End If

                                If Not myReader.IsDBNull(myReader.GetOrdinal("AssignedOn")) Then
                                    ta.AssignedOn = myReader.GetDateTime(myReader.GetOrdinal("AssignedOn"))
                                End If

                                ta.TaskName = myReader.GetString(myReader.GetOrdinal("TaskName"))
                                ta.TaskID = myReader.GetInt32(myReader.GetOrdinal("TaskID"))

                                taskAssignments.Add(ta)
                            End While
                        End If
                    End Using
                End Using
            End Using
            Return taskAssignments
        End Function

        Public Shared Function AddUpdateTaskAssignment(ByVal qranumber As String, ByVal taskID As Integer, ByVal assignedTo As String, ByVal assignedBy As String) As Boolean
            Dim numberOfRecordsAffected As Integer
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTaskAssignmentsAddUpdate", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@qraNumber", qranumber)
                    myCommand.Parameters.AddWithValue("@taskID", taskID)
                    myCommand.Parameters.AddWithValue("@assignedBy", assignedBy)
                    myCommand.Parameters.AddWithValue("@assignedTo", assignedTo)

                    myConnection.Open()
                    numberOfRecordsAffected = myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return numberOfRecordsAffected > 0
        End Function

        Public Shared Function RemoveTaskAssignment(ByVal qranumber As String, ByVal taskID As Integer) As Boolean
            Dim numberOfRecordsAffected As Integer
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTaskAssignmentsRemove", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@qraNumber", qranumber)
                    myCommand.Parameters.AddWithValue("@taskID", taskID)

                    myConnection.Open()
                    numberOfRecordsAffected = myCommand.ExecuteNonQuery()

                End Using
            End Using
            Return numberOfRecordsAffected > 0
        End Function
#End Region

#Region "Public Methods"

        ''' <summary>Gets an instance of TestStage from the underlying datasource.</summary> 
        ''' <param name="id">The unique ID of the TestStage in the database.</param> 
        ''' <returns>A TestStage if the ID was found in the database, or Nothing otherwise.</returns> 
        Public Shared Function GetItem(ByVal ID As Integer, ByVal name As String, ByVal jobName As String) As TestStage
            Dim myTestStage As TestStage = Nothing

            If (ID = 0 And String.IsNullOrEmpty(name) And String.IsNullOrEmpty(jobName)) Then
                Return myTestStage
            Else
                Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                    Using myCommand As New SqlCommand("remispTestStagesSelectSingleItem", myConnection)
                        myCommand.CommandType = CommandType.StoredProcedure

                        If ID > 0 Then
                            myCommand.Parameters.AddWithValue("@ID", ID)
                        End If

                        If Not String.IsNullOrEmpty(name) Then
                            myCommand.Parameters.AddWithValue("@Name", name)
                        End If

                        If Not String.IsNullOrEmpty(jobName) Then
                            myCommand.Parameters.AddWithValue("@JobName", jobName)
                        End If

                        myConnection.Open()

                        Using myReader As SqlDataReader = myCommand.ExecuteReader()
                            If myReader.Read() Then
                                myTestStage = FillDataRecord(myReader)
                            End If
                        End Using
                    End Using
                End Using

                If (myTestStage IsNot Nothing) Then
                    SetTestsForSingleTestStage(myTestStage)
                End If
            End If

            Return myTestStage
        End Function

        Public Shared Function GetNextTestStage(ByVal requestNumber As String, ByVal unitNumber As Int32) As TestStage
            Dim myTestStage As TestStage = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetBatchUnitNextTestStage", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    myCommand.Parameters.AddWithValue("@RequestNumber", requestNumber)
                    myCommand.Parameters.AddWithValue("@BatchUnitNumber", unitNumber)
                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.Read() Then
                            myTestStage = FillDataRecord(myReader)
                        End If
                    End Using
                End Using
            End Using

            If (myTestStage IsNot Nothing) Then
                myTestStage.Tests = TestDB.GetTestsByBatchUnitStage(requestNumber, unitNumber, myTestStage.ID)
            End If

            Return myTestStage
        End Function

        ''' <summary> 
        ''' Returns a list with TestStage objects. 
        ''' </summary> 
        ''' <returns> 
        ''' A TestStageCollection. 
        ''' </returns> 
        Public Shared Function GetList(ByVal type As TestStageType, ByVal jobName As String, ByVal ShowArchived As Boolean) As TestStageCollection
            Dim tmpList As New TestStageCollection

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                myConnection.Open()
                tmpList = GetList(type, jobName, ShowArchived, myConnection)
            End Using

            Return tmpList
        End Function

        Public Shared Function GetList(ByVal Type As TestStageType, ByVal jobName As String, ByVal ShowArchived As Boolean, ByVal myconnection As SqlConnection) As TestStageCollection
            Dim tempList As New TestStageCollection

            Using myCommand As New SqlCommand("remispTestStagesSelectList", myconnection)
                myCommand.CommandType = CommandType.StoredProcedure

                If Type <> TestStageType.NotSet Then
                    myCommand.Parameters.AddWithValue("@TestStageType", Type)
                End If

                If Not String.IsNullOrEmpty(jobName) Then
                    myCommand.Parameters.AddWithValue("@Jobname", jobName)
                End If

                myCommand.Parameters.AddWithValue("@ShowArchived", ShowArchived)

                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                    If myReader.HasRows Then
                        While myReader.Read()
                            tempList.Add(FillDataRecord(myReader))
                        End While
                    End If
                End Using
            End Using

            SetTests(tempList)
            Return tempList
        End Function

        ''' <summary> 
        ''' Returns a list with the distinct incoming eval and parametric test stage names. Used for 
        ''' populating the list on the stations.
        ''' </summary> 
        ''' <returns> 
        ''' A list of strings. 
        ''' </returns> 
        Public Shared Function GetListOfNames() As List(Of String)
            Dim tmpList As New List(Of String)

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestStagesSelectListOfNames", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                tmpList.Add(myReader.GetString(myReader.GetOrdinal("Name")))
                            End While
                        End If
                        myReader.Close()
                    End Using
                End Using
            End Using

            Return tmpList
        End Function

        ''' <summary>Saves an instance of the <see cref="TestStage" /> in the database.</summary> 
        ''' <param name="myTestStage">The TestStage instance to save.</param> 
        ''' <returns>Returns the id of the object when the object was saved successfully, or 0 otherwise</returns> 
        Public Shared Function Save(ByVal MyTestStage As TestStage) As Integer
            If Not MyTestStage.Validate() Then
                Throw New InvalidSaveOperationException("Can't save a TestStage in an Invalid state. Make sure that IsValid() returns true before you call Save().")
            End If

            Dim Result As Integer = 0

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestStagesInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestStageName", MyTestStage.Name)
                    myCommand.Parameters.AddWithValue("@ProcessOrder", MyTestStage.ProcessOrder)
                    myCommand.Parameters.AddWithValue("@TestStageType", MyTestStage.TestStageType)
                    myCommand.Parameters.AddWithValue("@JobName", MyTestStage.JobName)

                    If Not String.IsNullOrEmpty(MyTestStage.Comments) Then
                        myCommand.Parameters.AddWithValue("@Comment", MyTestStage.Comments)
                    End If

                    If MyTestStage.TestID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestID", MyTestStage.TestID)
                    End If

                    myCommand.Parameters.AddWithValue("@IsArchived", MyTestStage.IsArchived)

                    Helpers.SetSaveParameters(myCommand, MyTestStage)
                    myConnection.Open()

                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()

                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("Can't update test stage as it has been updated by someone else.")
                    End If

                    MyTestStage.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)
                    Result = Helpers.GetBusinessBaseId(myCommand)
                End Using
            End Using

            'must do this becuase there is no graph of which batches will be affected by the test stage update.
            REMIAppCache.RemoveJob(MyTestStage.JobName)
            Return Result
        End Function

        ''' <summary>Deletes a TestStage from the database.</summary> 
        ''' <param name="id">The ID of the TestStage to delete.</param>  
        Public Shared Function Delete(ByVal ID As Integer, ByVal UserName As String) As Integer
            Dim Result As Integer = 0

            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestStagesDeleteSingleItem", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myCommand.Parameters.AddWithValue("@UserName", UserName)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using

            'must do this becuase there is no graph of which batches will be affected by the test stage update.
            REMIAppCache.ClearCache()
            Return Result
        End Function
#End Region

#Region "Private Methods"
        ''' <summary>
        ''' Initializes a new instance of the TestStage class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the TestStage produced by a select query</param>
        ''' <returns>A TestStage object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord) As TestStage
            Dim myTestStage As New TestStage()
            myTestStage.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("TestStageName"))
            myTestStage.TestStageType = DirectCast(myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestStageType")), TestStageType)
            myTestStage.JobName = myDataRecord.GetString(myDataRecord.GetOrdinal("JobName"))
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestID")) Then
                myTestStage.TestID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestID"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Comment")) Then
                myTestStage.Comments = myDataRecord.GetString(myDataRecord.GetOrdinal("Comment"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ProcessOrder")) Then
                myTestStage.ProcessOrder = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ProcessOrder"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("IsArchived")) Then
                myTestStage.IsArchived = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("IsArchived"))
            End If
            If (Helpers.HasColumn(myDataRecord, "CanDelete")) Then
                myTestStage.CanDelete = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("CanDelete"))
            End If

            Helpers.FillObjectParameters(myDataRecord, myTestStage)
            Return myTestStage
        End Function

        Private Shared Sub SetTestsForSingleTestStage(ByVal ts As TestStage)
            Dim tests As TestCollection
            Select Case ts.TestStageType
                Case TestStageType.Parametric
                    tests = REMIAppCache.GetParametricTests()
                    If tests Is Nothing Then
                        tests = TestDB.GetListByTestType(TestType.Parametric, -1, -1, False, 0, 0)
                        REMIAppCache.SetParametricTests(tests)
                    End If
                    ts.Tests = tests
                Case TestStageType.EnvironmentalStress
                    tests = REMIAppCache.GetEnvironmentalTests()
                    If tests Is Nothing Then
                        tests = TestDB.GetListByTestType(TestType.EnvironmentalStress, -1, -1, False, 0, 0)
                        REMIAppCache.SetEnvironmentalTests(tests)
                    End If
                    'get the specific test
                    Dim tsTestID As Integer = ts.TestID
                    ts.Tests = New TestCollection((From test In tests Where test.ID.Equals(tsTestID) Select test).ToList())
                Case TestStageType.IncomingEvaluation
                    tests = REMIAppCache.GetIncomingEvalTests()
                    If tests Is Nothing Then
                        tests = TestDB.GetListByTestType(TestType.IncomingEvaluation, -1, -1, False, 0, 0)
                        REMIAppCache.SetIncomingEvalTests(tests)
                    End If
                    ts.Tests = tests
                Case TestStageType.NonTestingTask
                    tests = REMIAppCache.GetNonTestingTests()
                    If tests Is Nothing Then
                        tests = TestDB.GetListByTestType(TestType.NonTestingTask, -1, -1, False, 0, 0)
                        REMIAppCache.SetNonTestingTests(tests)
                    End If
                    ts.Tests = tests
            End Select
        End Sub

        Private Shared Sub SetTests(ByVal testStages As TestStageCollection)
            If testStages IsNot Nothing Then
                For Each ts As TestStage In testStages
                    SetTestsForSingleTestStage(ts)
                Next
            End If
        End Sub
#End Region


        Public Shared Function GetListOfNamesForChambers(ByVal jobName As String) As List(Of String)

            Dim tempList As New List(Of String)
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("SELECT ts.TestStageName FROM teststages as ts,jobs as j where ISNULL(IsArchived,0) = 0 And (ts.jobid = j.id and j.Jobname = @Jobname) and ts.teststagetype = 2 order by ProcessOrder", myConnection)
                    myCommand.CommandType = CommandType.Text
                    myCommand.Parameters.AddWithValue("@jobname", jobName)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                tempList.Add(myReader.GetString(0))
                            End While
                        End If
                    End Using
                End Using


            End Using

            Return tempList

        End Function


    End Class
End Namespace