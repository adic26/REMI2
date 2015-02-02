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
    ''' The JobDB class is responsible for interacting with the database to retrieve and store information 
    ''' about Job objects.
    ''' </summary>
    Public Class JobDB
        'to prevent instances of this class.
        Protected Sub New()
        End Sub

#Region "Public Methods"
        Public Shared Function GetREMIJobList() As List(Of String)
            Dim jobs As New List(Of String)
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("SELECT JobName FROM Jobs WHERE ISNULL(IsActive, 0) = 1 ORDER BY JobName ASC", myConnection)
                    myCommand.CommandType = CommandType.Text
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                jobs.Add(myReader.GetString(0))
                            End While
                        End If
                    End Using
                End Using
            End Using
            Return jobs
        End Function

        Public Shared Function GetJobOrientationLists(ByVal jobID As Int32, ByVal jobName As String) As DataTable
            Dim dt As New DataTable
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetJobOrientations", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    If (jobID > 0) Then
                        myCommand.Parameters.AddWithValue("@JobID", jobID)
                    Else
                        myCommand.Parameters.AddWithValue("@JobName", jobName)
                    End If

                    MyConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "JobOrientation"
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function GetJobAccess(ByVal jobID As Int32) As DataTable
            Dim dt As New DataTable
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetJobAccess", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    If (jobID > 0) Then
                        myCommand.Parameters.AddWithValue("@JobID", jobID)
                    End If

                    MyConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "JobAccess"
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function SaveOrientation(ByVal jobID As Int32, ByVal id As Int32, ByVal name As String, ByVal productTypeID As Int32, ByVal description As String, ByVal isActive As Boolean, ByVal xml As String) As Boolean
            Dim Result As Integer = 0
            Dim success As Boolean = False

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispJobOrientationSave", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", id)
                    myCommand.Parameters.AddWithValue("@Name", name)
                    myCommand.Parameters.AddWithValue("@JobID", jobID)
                    myCommand.Parameters.AddWithValue("@ProductTypeID", productTypeID)
                    myCommand.Parameters.AddWithValue("@Description", description)
                    myCommand.Parameters.AddWithValue("@IsActive", isActive)
                    myCommand.Parameters.AddWithValue("@Definition", xml)

                    Dim output As DbParameter = myCommand.CreateParameter()
                    output.DbType = DbType.Boolean
                    output.Direction = ParameterDirection.Output
                    output.ParameterName = "@Success"
                    output.Value = success
                    myCommand.Parameters.Add(output)

                    myConnection.Open()
                    myCommand.ExecuteNonQuery()

                    Boolean.TryParse(myCommand.Parameters("@Success").Value.ToString(), success)
                End Using
            End Using

            Return success
        End Function

        Public Shared Function GetJobListDT(ByVal user As User) As JobCollection
            Dim tempList As New JobCollection

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                myConnection.Open()
                Using myCommand As New SqlCommand("remispJobsList", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@UserID", user.ID)

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

        ''' <summary>Gets an instance of Job. Creates a new connection.</summary> 
        ''' <param name="JobName">The unique JobName of the Job in the database.</param> 
        ''' <returns>A Job if the jobname was found in the database, or Nothing otherwise.</returns> 
        Public Shared Function GetItem(ByVal JobName As String) As Job
            Dim myJob As Job = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                myConnection.Open()
                myJob = GetItem(JobName, myConnection, 0)
            End Using

            Return myJob
        End Function

        Public Shared Function GetItem(ByVal JobID As Int32) As Job
            Dim myJob As Job = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                myConnection.Open()
                myJob = GetItem(String.Empty, myConnection, JobID)
            End Using

            Return myJob
        End Function

        ''' <summary>
        ''' Gets a job from the database. Uses the given connection.
        ''' </summary>
        ''' <param name="JobName"></param>
        ''' <param name="myconnection"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetItem(ByVal JobName As String, ByVal myconnection As SqlConnection, ByVal JobID As Int32) As Job
            Dim myJob As Job = REMIAppCache.GetJob(JobName)
            If myJob Is Nothing Then
                Using jobCommand As New SqlCommand("remispJobsSelectSingleItem", myconnection)
                    jobCommand.CommandType = CommandType.StoredProcedure

                    If (JobID > 0 And String.IsNullOrEmpty(JobName)) Then
                        jobCommand.Parameters.AddWithValue("@ID", JobID)
                    End If

                    If (Not String.IsNullOrEmpty(JobName) And JobID = 0) Then
                        jobCommand.Parameters.AddWithValue("@JobName", JobName)
                    End If

                    If myconnection.State <> ConnectionState.Open Then
                        myconnection.Open()
                    End If

                    Using myReader As SqlDataReader = jobCommand.ExecuteReader()
                        If myReader.Read() Then 'if a job is found then go ahead and parse it in the filler
                            myJob = FillDataRecord(myReader)
                        End If
                    End Using
                End Using

                'get the teststages
                If myJob IsNot Nothing Then
                    myJob.TestStages = TestStageDB.GetList(TestStageType.NotSet, myJob.Name, myconnection)
                    REMIAppCache.SetJob(myJob)
                End If
            End If
            Return myJob
        End Function

        ''' <summary>Saves an instance of the <see cref="Job" /> in the database.</summary> 
        ''' <param name="myJob">The Job instance to save.</param> 
        ''' <returns>Returns the id when the object was saved successfully, or 0 otherwise.</returns> 
        Public Shared Function Save(ByVal MyJob As Job) As Integer
            If Not MyJob.Validate() Then
                Throw New InvalidSaveOperationException("Can't save a Job in an Invalid state. Make sure that IsValid() returns true before you call Save().")
            End If
            Dim Result As Integer
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispJobsInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@JobName", MyJob.Name)

                    If Not String.IsNullOrEmpty(MyJob.WILocation) Then
                        myCommand.Parameters.AddWithValue("@WILocation", MyJob.WILocation)
                    End If

                    If Not String.IsNullOrEmpty(MyJob.Comment) Then
                        myCommand.Parameters.AddWithValue("@Comment", MyJob.Comment)
                    End If

                    myCommand.Parameters.AddWithValue("@OperationsTest", MyJob.IsOperationsTest)
                    myCommand.Parameters.AddWithValue("@TechOperationsTest", MyJob.IsTechOperationsTest)
                    myCommand.Parameters.AddWithValue("@MechanicalTest", MyJob.IsMechanicalTest)

                    If Not String.IsNullOrEmpty(MyJob.ProcedureLocation) Then
                        myCommand.Parameters.AddWithValue("@ProcedureLocation", MyJob.ProcedureLocation)
                    End If

                    myCommand.Parameters.AddWithValue("@IsActive", MyJob.IsActive)
                    myCommand.Parameters.AddWithValue("@NoBSN", MyJob.NoBSN)
                    myCommand.Parameters.AddWithValue("@ContinueOnFailures", MyJob.ContinueOnFailures)

                    Helpers.SetSaveParameters(myCommand, MyJob)

                    myConnection.Open()

                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()

                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("Can't update the job as it has been updated by someone else.")
                    End If

                    MyJob.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)
                    Result = Helpers.GetBusinessBaseId(myCommand)
                End Using
            End Using

            If Result > 0 Then
                'refresh the job in the cache
                REMIAppCache.RemoveJob(MyJob.Name)

            End If
            Return Result
        End Function
#End Region

#Region "Private Methods"
        ''' <summary>
        ''' Initializes a new instance of the Job class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the Job produced by a select query</param>
        ''' <returns>A Job object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord) As Job
            Dim myJob As New Job()

            myJob.ID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID"))
            myJob.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("JobName"))

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("WILocation")) Then
                myJob.WILocation = myDataRecord.GetString(myDataRecord.GetOrdinal("WILocation"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Comment")) Then
                myJob.WILocation = myDataRecord.GetString(myDataRecord.GetOrdinal("Comment"))
            End If

            myJob.IsOperationsTest = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("OperationsTest"))
            myJob.IsTechOperationsTest = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("TechnicalOperationsTest"))
            myJob.IsMechanicalTest = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("MechanicalTest"))

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("IsActive")) Then
                myJob.IsActive = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("IsActive"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ProcedureLocation")) Then
                myJob.ProcedureLocation = myDataRecord.GetString(myDataRecord.GetOrdinal("ProcedureLocation"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("NoBSN")) Then
                myJob.NoBSN = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("NoBSN"))
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ContinueOnFailures")) Then
                myJob.ContinueOnFailures = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("ContinueOnFailures"))
            End If

            Helpers.FillObjectParameters(myDataRecord, myJob)

            Return myJob
        End Function
#End Region

    End Class
End Namespace