Imports REMI.Core
Imports REMI.Contracts

Namespace REMI.BusinessEntities
    Public Class REMIAppCache

        Public Shared Sub AddGeoLocList(ByVal locs As List(Of String))
            System.Web.HttpRuntime.Cache.Add("GeoLocList", locs, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(60)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Default, Nothing)
        End Sub

        Public Shared Function GetGeoLocList() As List(Of String)
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("GeoLocList"), List(Of String))
        End Function

        Public Shared Function GetTRSJobList() As List(Of String)
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("TRSJobList"), List(Of String))
        End Function

        Public Shared Sub SetTRSJobList(ByVal jobs As List(Of String))
            System.Web.HttpRuntime.Cache.Add("TRSJobList", jobs, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Default, Nothing)
        End Sub

        Private Shared ReadOnly Property KeyForJob(ByVal jobName As String) As String
            Get
                Return "Job-" + jobName
            End Get
        End Property

        Public Shared Sub ClearListOfRemiUsernames()
            If System.Web.HttpRuntime.Cache.Get("RemiUserNameList") IsNot Nothing Then
                System.Web.HttpRuntime.Cache.Remove("RemiUserNameList")
            End If
        End Sub

        Public Shared Function GetJob(ByVal jobname As String) As Job
            Return DirectCast(System.Web.HttpRuntime.Cache.Get(REMIAppCache.KeyForJob(jobname)), Job)
        End Function

        Public Shared Sub SetJob(ByVal job As Job)
            System.Web.HttpRuntime.Cache.Add(REMIAppCache.KeyForJob(job.Name), job, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Normal, Nothing)
        End Sub

        Public Shared Sub RemoveJob(ByVal jobName As String)
            System.Web.HttpRuntime.Cache.Remove(REMIAppCache.KeyForJob(jobName))
        End Sub

        Public Shared Function GetParametricTests() As TestCollection
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("pTests"), TestCollection)
        End Function

        Public Shared Sub SetParametricTests(ByVal tests As IEnumerable(Of Test))
            System.Web.HttpRuntime.Cache.Add("pTests", tests, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Normal, Nothing)
        End Sub

        Public Shared Sub ClearAllBatchData(ByVal qraNumber As String)
            System.Web.HttpRuntime.Cache.Remove("Batch-" + qraNumber)
            RemoveSpecificTestDurations(qraNumber)
            RemoveTestExceptions(qraNumber)
            RemoveTestRecords(qraNumber)
            RemoveReqData(qraNumber)
            RemoveExtReqData(qraNumber)
        End Sub

        Public Shared Function GetReqData(ByVal rqNumber As String) As RequestFieldsCollection
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("ReqData-" + rqNumber), RequestFieldsCollection)
        End Function

        Public Shared Sub SetReqData(ByVal reqData As RequestFieldsCollection, ByVal requestNumber As String)
            System.Web.HttpRuntime.Cache.Add("ReqData-" + requestNumber, reqData, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Low, Nothing)
        End Sub

        Public Shared Sub RemoveReqData(ByVal rqNumber As String)
            System.Web.HttpRuntime.Cache.Remove("ReqData-" + rqNumber)
        End Sub

        Public Shared Function GetSpecificTestDurations(ByVal qraNumber As String) As Dictionary(Of Integer, Double)
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("SpecificTestDurations-" + qraNumber), Dictionary(Of Integer, Double))
        End Function

        Public Shared Sub SetSpecificTestDurations(ByVal qraNumber As String, ByVal specificTestDurations As Dictionary(Of Integer, Double))
            System.Web.HttpRuntime.Cache.Add("SpecificTestDurations-" + qraNumber, specificTestDurations, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Low, Nothing)
        End Sub

        Public Shared Sub RemoveSpecificTestDurations(ByVal qraNumber As String)
            System.Web.HttpRuntime.Cache.Remove("SpecificTestDurations-" + qraNumber)
        End Sub

        Public Shared Function GetTestExceptions(ByVal qraNumber As String) As TestExceptionCollection
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("TestExceptions-" + qraNumber), TestExceptionCollection)
        End Function

        Public Shared Sub SetTestExceptions(ByVal qraNumber As String, ByVal testExceptions As TestExceptionCollection)
            System.Web.HttpRuntime.Cache.Add("TestExceptions-" + qraNumber, testExceptions, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Low, Nothing)
        End Sub

        Public Shared Sub RemoveTestExceptions(ByVal qraNumber As String)
            System.Web.HttpRuntime.Cache.Remove("TestExceptions-" + qraNumber)
        End Sub

        Public Shared Function GetTestRecords(ByVal qraNumber As String) As TestRecordCollection
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("TestRecords-" + qraNumber), TestRecordCollection)
        End Function

        Public Shared Sub SetTestRecords(ByVal qraNumber As String, ByVal testRecords As TestRecordCollection)
            System.Web.HttpRuntime.Cache.Add("TestRecords-" + qraNumber, testRecords, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Low, Nothing)
        End Sub

        Public Shared Sub RemoveTestRecords(ByVal qraNumber As String)
            System.Web.HttpRuntime.Cache.Remove("TestRecords-" + qraNumber)
        End Sub

        Public Shared Function GetEnvironmentalTests() As TestCollection
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("envTests"), TestCollection)
        End Function

        Public Shared Sub SetEnvironmentalTests(ByVal tests As IEnumerable(Of Test))
            System.Web.HttpRuntime.Cache.Add("envTests", tests, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Normal, Nothing)
        End Sub

        Public Shared Function GetIncomingEvalTests() As TestCollection
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("incTests"), TestCollection)
        End Function

        Public Shared Sub SetIncomingEvalTests(ByVal tests As IEnumerable(Of Test))
            System.Web.HttpRuntime.Cache.Add("ntTests", tests, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Normal, Nothing)
        End Sub

        Public Shared Function GetNonTestingTests() As TestCollection
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("incTests"), TestCollection)
        End Function

        Public Shared Sub SetNonTestingTests(ByVal tests As IEnumerable(Of Test))
            System.Web.HttpRuntime.Cache.Add("ntTests", tests, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Normal, Nothing)
        End Sub

        Public Shared Sub ClearJobs()
            Dim enumerator As IDictionaryEnumerator = System.Web.HttpRuntime.Cache.GetEnumerator()

            While enumerator.MoveNext
                Dim entry As DictionaryEntry = DirectCast(enumerator.Current(), DictionaryEntry)
                If entry.Key.ToString().StartsWith("Job-") Then
                    System.Web.HttpRuntime.Cache.Remove(entry.Key.ToString)
                End If
            End While
        End Sub

        ''' <summary>
        ''' Clears all items from the current application cache
        ''' </summary>
        ''' <remarks></remarks>
        Public Shared Sub ClearCache()
            Dim enumerator As IDictionaryEnumerator = System.Web.HttpRuntime.Cache.GetEnumerator()

            While enumerator.MoveNext
                Dim entry As DictionaryEntry = DirectCast(enumerator.Current(), DictionaryEntry)
                System.Web.HttpRuntime.Cache.Remove(entry.Key.ToString)
            End While
        End Sub

        Public Shared Function GetRolesByPermission(ByVal PermissionName As String) As DataTable
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("Permission-" + PermissionName), DataTable)
        End Function

        Public Shared Sub SetRolesByPermission(ByVal PermissionName As String, ByVal roles As DataTable)
            System.Web.HttpRuntime.Cache.Add("Permission-" + PermissionName, roles, Nothing, DateTime.Now.Add(TimeSpan.FromDays(1)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Low, Nothing)
        End Sub

        Public Shared Sub RemovePermission(ByVal PermissionName As String)
            System.Web.HttpRuntime.Cache.Remove("Permission-" + PermissionName)
        End Sub

        Public Shared Sub ClearAll()
            Dim enumerator As IDictionaryEnumerator = System.Web.HttpRuntime.Cache.GetEnumerator()

            While enumerator.MoveNext()
                System.Web.HttpRuntime.Cache.Remove(enumerator.Key.ToString())
            End While
        End Sub

        Public Shared Sub SetMenuAccess(ByVal departmentID As Int32, ByVal dtMenuAccess As DataTable)
            System.Web.HttpRuntime.Cache.Add("MenuAccess-" + departmentID.ToString(), dtMenuAccess, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Low, Nothing)
        End Sub

        Public Shared Function GetMenuAccess(ByVal departmentID As Int32) As DataTable
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("MenuAccess-" + departmentID.ToString()), DataTable)
        End Function

        Public Shared Sub RemoveMenuAccess(ByVal departmentID As Int32)
            System.Web.HttpRuntime.Cache.Remove("MenuAccess-" + departmentID.ToString())
        End Sub

        Public Shared Function GetExtReqData(ByVal rqNumber As String) As Dictionary(Of String, String)
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("ExtReqData-" + rqNumber), Dictionary(Of String, String))
        End Function

        Public Shared Sub SetExtReqData(ByVal reqData As Dictionary(Of String, String), ByVal requestNumber As String)
            System.Web.HttpRuntime.Cache.Add("ExtReqData-" + requestNumber, reqData, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Low, Nothing)
        End Sub

        Public Shared Sub RemoveExtReqData(ByVal rqNumber As String)
            System.Web.HttpRuntime.Cache.Remove("ExtReqData-" + rqNumber)
        End Sub

        Public Shared Sub SetServiceAccess(ByVal departmentID As Int32, ByVal dtServiceAccess As DataTable)
            System.Web.HttpRuntime.Cache.Add("ServiceAccess-" + departmentID.ToString(), dtServiceAccess, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Low, Nothing)
        End Sub

        Public Shared Function GetServiceAccess(ByVal departmentID As Int32) As DataTable
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("ServiceAccess-" + departmentID.ToString()), DataTable)
        End Function

        Public Shared Sub RemoveServiceAccess(ByVal departmentID As Int32)
            System.Web.HttpRuntime.Cache.Remove("ServiceAccess-" + departmentID.ToString())
        End Sub

        Public Shared Sub SetUserServiceAccess(ByVal userID As Int32, ByVal dtServiceAccess As DataTable)
            System.Web.HttpRuntime.Cache.Add("UserServiceAccess-" + userID.ToString(), dtServiceAccess, Nothing, DateTime.Now.Add(TimeSpan.FromMinutes(20)), System.Web.Caching.Cache.NoSlidingExpiration, Web.Caching.CacheItemPriority.Low, Nothing)
        End Sub

        Public Shared Function GetUserServiceAccess(ByVal userID As Int32) As DataTable
            Return DirectCast(System.Web.HttpRuntime.Cache.Get("UserServiceAccess-" + userID.ToString()), DataTable)
        End Function

        Public Shared Sub RemoveUserServiceAccess(ByVal userID As Int32)
            System.Web.HttpRuntime.Cache.Remove("UserServiceAccess-" + userID.ToString())
        End Sub
    End Class
End Namespace