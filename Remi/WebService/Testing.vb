Imports System.Web.Services
Imports System.Web.Services.Protocols
Imports System.ComponentModel
Imports Remi.Validation
Imports Remi.BusinessEntities
Imports Remi.Bll
Imports System.Data.SqlClient
Imports System.Data
Imports Remi.Core
Imports Remi.Contracts
Imports log4net
' To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line.
<System.Web.Services.WebService(Name:="Testing", Namespace:="http://go/remi/")> _
<System.Web.Services.WebServiceBinding(ConformsTo:=WsiProfiles.BasicProfile1_1)> _
<ToolboxItem(False)> _
Public Class Testing
    Inherits System.Web.Services.WebService

    <WebMethod(EnableSession:=True, Description:="get active batches.")> _
    Public Sub GetActiveBatches()
        BatchManager.GetActiveBatches()
    End Sub

    <WebMethod(EnableSession:=False, Description:="get active batches.")> _
    Public Function UpdatePercentageComplete(ByVal qranumber As String, ByVal percentagecomplete As Integer) As Boolean
        Return BatchManager.UpdatePercentageCompleteInTRS(qranumber, percentagecomplete)
    End Function

    '<WebMethod(EnableSession:=True, Description:="updates records regardless of current status.")> _
    'Public Function CheckAllBatchesOf(ByVal productGroupName As String) As Integer
    '    Dim batches As BatchCollection = BatchManager.GetListByProduct("Orlando", True)
    '    For Each b As Batch In batches
    '        TestRecordManager.CheckBatchForRelabUpdates(b, True)
    '    Next
    '    Return 0
    'End Function

    <WebMethod(EnableSession:=True, Description:="clear cache.")> _
    Public Function clearcache() As Integer
        Dim enumerator As IDictionaryEnumerator = System.Web.HttpRuntime.Cache.GetEnumerator()
        Dim countItems As Integer
        While enumerator.MoveNext
            Dim entry As DictionaryEntry = DirectCast(enumerator.Current(), DictionaryEntry)
            System.Web.HttpRuntime.Cache.Remove(entry.Key.ToString)
            countItems += 1
        End While
        Return countItems
    End Function

    <WebMethod(EnableSession:=True, Description:="Used to update batches in remi with values from TRS ")> _
    Public Function fixbatches() As Integer
        Dim count As Integer
        'get all the batches remi knows about
        Dim batches As List(Of String) = New List(Of String)
        Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
            myConnection.Open()
            Using myCommand As New SqlCommand("select qranumber from batches", myConnection)
                myCommand.CommandType = CommandType.Text

                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                    If myReader.HasRows Then
                        While myReader.Read()
                            batches.Add(myReader.GetString(0))
                        End While
                    End If
                End Using
            End Using
            Dim q As IQRARequest

            For Each s As String In batches
                'get the trs request
                q = Remi.Dal.RequestDB.GetTRSRequest(s)

                If q IsNot Nothing AndAlso Not String.IsNullOrEmpty(q.Requestor) Then
                    Using myCommand As New SqlCommand("update batches set requestor=@rq where qranumber=@qranumber", myConnection)
                        myCommand.CommandType = CommandType.Text
                        myCommand.Parameters.AddWithValue("@rq", q.Requestor)
                        myCommand.Parameters.AddWithValue("@qranumber", s)
                        count = count + myCommand.ExecuteNonQuery()

                    End Using
                End If
            Next
        End Using
        Return count
    End Function

    <WebMethod(EnableSession:=True, Description:="Used to scan a device in to a test in the REMI system. Input Values are: Request [(*REQUIRED*): ""QRA-yy-bbbb-uuu-lllll""],SelectedTestID [Optional (0 treated as null):""TestID""],OverallTestResult [optional (Empty String is treated as null): ""pass"",""fail""],UserIdentification [Optional (Empty String Treated as Null): ""BadgeScan Number""] ")> _
    Public Function fixbatch(ByVal qraNumber As String) As Integer
        Dim result As Integer
        Dim q As IQRARequest

        Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
            myConnection.Open()
            q = REMI.Dal.RequestDB.GetTRSRequest(qraNumber)
            If q IsNot Nothing Then
                Using myCommand As New SqlCommand("update batches set productid=@pid  where qranumber=@qranumber", myConnection)
                    myCommand.CommandType = CommandType.Text
                    myCommand.Parameters.AddWithValue("@pid", ProductGroupManager.GetProductIDByName(q.ProductGroup))
                    myCommand.Parameters.AddWithValue("@qranumber", qraNumber)
                    result = myCommand.ExecuteNonQuery()
                End Using
            End If
        End Using
        Return result
    End Function

    <WebMethod(EnableSession:=True, Description:="Returns a string with all the available user properties for a user.")> _
    Public Function GetUserADProperties(ByVal username As String) As String
        Try
            Return "Functionality Removed."
        Catch ex As Exception
            Return String.Empty
        End Try
        Session.Clear()
    End Function

#Region "Public Web READONLY Methods"
    <WebMethod(EnableSession:=True, Description:="checks for changed test units")> _
    Public Function blah() As String
        Try
            Dim j As List(Of String) = JobManager.GetJobList()
            Dim tsSE As New TestStage()
            tsSE.Name = "Sample Evaluation"
            tsSE.LastUser = "doriordan"
            tsSE.TestStageType = TestStageType.IncomingEvaluation
            Dim tsBL As New TestStage()
            tsBL.Name = "Baseline"
            tsBL.LastUser = "doriordan"
            tsBL.TestStageType = TestStageType.Parametric
            Dim tsPT As New TestStage()
            tsPT.Name = "Post"
            tsPT.LastUser = "doriordan"
            tsPT.TestStageType = TestStageType.Parametric
            Dim counttotalJobs As Integer = j.Count
            Dim countChangedJobs As Integer
            For Each jName As String In j
                Dim job As Job = JobManager.GetJobByName(jName)
                If job.TestStages.FindByName(tsSE.Name) Is Nothing Then
                    tsSE.JobName = jName
                    tsSE.ID = 0
                    TestStageManager.SaveTestStage(tsSE)
                End If
                If job.TestStages.FindByName(tsPT.Name) Is Nothing Then
                    tsPT.JobName = jName
                    tsPT.ID = 0
                    TestStageManager.SaveTestStage(tsPT)
                End If
                If job.TestStages.FindByName(tsBL.Name) Is Nothing Then
                    tsBL.JobName = jName
                    tsBL.ID = 0
                    TestStageManager.SaveTestStage(tsBL)
                End If

                countChangedJobs += 1
            Next
            Return countChangedJobs.ToString + "/" + counttotalJobs.ToString
        Catch ex As Exception
            Return TestManager.LogIssue("REMI API Add Exception", "e7", NotificationType.Errors, ex).ToString
        End Try
    End Function

    <WebMethod(EnableSession:=True, Description:="copies a job's data.")> _
    Public Sub CopyJob(ByVal oldName As String, ByVal newName As String)
        Dim oldJob As Job = Remi.Bll.JobManager.GetJobByName(oldName)
        Dim newJob As Job = Remi.Bll.JobManager.GetJobByName(newName)
        If oldJob IsNot Nothing AndAlso newJob IsNot Nothing Then
            newJob.IsMechanicalTest = oldJob.IsMechanicalTest
            newJob.IsOperationsTest = oldJob.IsOperationsTest
            newJob.IsTechOperationsTest = oldJob.IsTechOperationsTest
            JobManager.SaveJob(newJob)
            Dim newTS As TestStage

            For Each ts In oldJob.TestStages
                newTS = newJob.TestStages.FindByName(ts.Name)
                If newTS Is Nothing Then
                    'create a new ts and add it to newjob
                    newTS = New TestStage
                    newTS.TestStageType = ts.TestStageType
                    newTS.JobName = newName
                    newTS.Name = ts.Name
                    newTS.ProcessOrder = ts.ProcessOrder

                    'if it's an environemtal stress type test then add the equivelent stress
                    If ts.TestStageType = Remi.Contracts.TestStageType.EnvironmentalStress Then
                        Dim newTest As New Test
                        newTest.Name = ts.Tests(0).Name
                        newTest.TotalHours = ts.Tests(0).TotalHours
                        For Each tltype In ts.Tests(0).TrackingLocationTypes
                            newTest.TrackingLocationTypes.Add(tltype.Key, tltype.Value)
                        Next
                        newTest.ResultIsTimeBased = ts.Tests(0).ResultIsTimeBased
                        newTest.TestType = ts.Tests(0).TestType
                        newTest.WorkInstructionLocation = ts.Tests(0).WorkInstructionLocation
                        newTest.LastUser = ts.Tests(0).LastUser
                        newTS.Tests.Add(newTest)
                    End If

                    newTS.ID = TestStageManager.SaveTestStage(newTS)
                    newJob.TestStages.Add(newTS)

                    If newTS.ID > 0 AndAlso ts.ID > 0 Then
                        'TestUnitManager.CopyExceptionsForTestStage(ts.ID, newTS.ID, "doriordan")
                    End If
                End If
            Next
        End If
    End Sub
#End Region
End Class