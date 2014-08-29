Imports REMI.Dal
Imports REMI.Validation
Imports REMI.BusinessEntities
Imports System.ComponentModel
Imports System.Text.RegularExpressions
Imports System.Transactions

Namespace REMI.Bll
    ''' <summary>
    ''' The job manager handles all tests, test stages, jobs
    ''' </summary>
    ''' <remarks></remarks>
    <DataObjectAttribute()> _
    Public Class JobManager
        Inherits REMIManagerBase

#Region "Public Methods"
        ''' <summary>
        ''' Get a single job by its name.
        ''' </summary>
        ''' <param name="jobName">the name of the job to return.</param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetJobByName(ByVal jobName As String) As Job
            Try
                Dim tmpjob As Job = Nothing
                If JobManager.GetJobList.Contains(jobName) Then 'check if this is a valid job name (exists in trs)
                    tmpjob = JobDB.GetItem(jobName) 'try to get it from remi
                End If

                If tmpjob Is Nothing Then
                    'if we cant get this job from the trs then  return a job with no info and error
                    tmpjob = New Job(jobName)
                    LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "w36", NotificationType.Warning, "Jobname: " + jobName)
                End If

                Return tmpjob
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("JobName: {0}", jobName))
                Return Nothing
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetJobNameByID(ByVal jobID As Int32) As String
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim name As String = (From j In instance.Jobs Where j.ID = jobID Select j.JobName).FirstOrDefault()

                Return name
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("JobID: {0}", jobID))
                Return String.Empty
            End Try
        End Function

        ''' <summary>
        ''' Gets all known jobs
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetJobList() As List(Of String)
            Try
                Return JobDB.GetTRSJobList()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New List(Of String)
            End Try
        End Function

        ''' <summary>
        ''' Gets the current list of active jobs from the TRS database.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetJobListForTestStations() As List(Of String)
            Try
                Return JobDB.GetREMIJobList
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New List(Of String)
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetJobListDT() As JobCollection
            Try
                Return JobDB.GetJobListDT()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New JobCollection
            End Try
        End Function

        ''' <summary>
        ''' Upserts a Job to the database.
        ''' </summary>
        ''' <param name="Job">The job to save.</param>
        ''' <returns>The ID of the saved job.</returns>
        ''' <remarks></remarks>
        Public Shared Function SaveJob(ByVal Job As Job) As Integer
            Try
                If UserManager.GetCurrentUser.IsAdmin Then
                    Job.LastUser = UserManager.GetCurrentValidUserLDAPName

                    If Job.Validate Then
                        Job.ID = JobDB.Save(Job)
                        Job = JobDB.GetItem(Job.ID)

                        If (Job.TestStages.Count = 0) Then
                            Dim tmpTestStage As New TestStage
                            tmpTestStage.Name = "Analysis"
                            tmpTestStage.JobName = Job.Name
                            tmpTestStage.TestStageType = Contracts.TestStageType.Parametric
                            tmpTestStage.ProcessOrder = -10
                            tmpTestStage.IsArchived = False
                            TestStageManager.SaveTestStage(tmpTestStage)

                            tmpTestStage = New TestStage
                            tmpTestStage.Name = "Sample Evaluation"
                            tmpTestStage.JobName = Job.Name
                            tmpTestStage.TestStageType = Contracts.TestStageType.IncomingEvaluation
                            tmpTestStage.ProcessOrder = 0
                            tmpTestStage.IsArchived = False
                            TestStageManager.SaveTestStage(tmpTestStage)

                            tmpTestStage = New TestStage
                            tmpTestStage.Name = "Baseline"
                            tmpTestStage.JobName = Job.Name
                            tmpTestStage.TestStageType = Contracts.TestStageType.Parametric
                            tmpTestStage.ProcessOrder = 1
                            tmpTestStage.IsArchived = False
                            TestStageManager.SaveTestStage(tmpTestStage)

                            tmpTestStage = New TestStage
                            tmpTestStage.Name = "Post"
                            tmpTestStage.JobName = Job.Name
                            tmpTestStage.TestStageType = Contracts.TestStageType.Parametric
                            tmpTestStage.ProcessOrder = 10
                            tmpTestStage.IsArchived = False
                            TestStageManager.SaveTestStage(tmpTestStage)

                            tmpTestStage = New TestStage
                            tmpTestStage.Name = "Failure Analysis"
                            tmpTestStage.JobName = Job.Name
                            tmpTestStage.TestStageType = Contracts.TestStageType.FailureAnalysis
                            tmpTestStage.ProcessOrder = 90
                            tmpTestStage.IsArchived = False
                            TestStageManager.SaveTestStage(tmpTestStage)

                            tmpTestStage = New TestStage
                            tmpTestStage.Name = "Report"
                            tmpTestStage.JobName = Job.Name
                            tmpTestStage.TestStageType = Contracts.TestStageType.NonTestingTask
                            tmpTestStage.ProcessOrder = 100
                            tmpTestStage.IsArchived = False
                            TestStageManager.SaveTestStage(tmpTestStage)
                        End If

                        Job.Notifications.Add("i2", NotificationType.Information)
                        Return Job.ID
                    End If
                Else
                    Throw New Security.SecurityException("Unauthorized attempt to edit a setting.")
                End If
            Catch sqlEx As SqlClient.SqlException When sqlEx.Number = 2601 'foreign key exception
                Job.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e5", NotificationType.Errors, sqlEx, String.Format("Job: {0}", Job.ID)))
            Catch ex As Exception
                Job.Notifications.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("Job: {0}", Job.ID)))
            End Try
            Return 0
        End Function
#End Region

    End Class
End Namespace