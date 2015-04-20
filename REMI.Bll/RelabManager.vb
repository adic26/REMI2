Imports System.Linq
Imports System.Security
Imports System.Security.Permissions
Imports System.Transactions
Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation
Imports System.ComponentModel
Imports REMI.Contracts
Imports REMI.Core

Namespace REMI.Bll
    <DataObjectAttribute()> _
    Public Class RelabManager
        Inherits REMIManagerBase

        Public Shared Function ResultSummary(ByVal batchID As Integer) As DataTable
            Try
                Return RelabDB.ResultSummary(batchID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultsSummary")
        End Function

        Public Shared Function ResultInformation(ByVal resultID As Int32, ByVal includeArchived As Boolean) As DataTable
            Try
                Return RelabDB.ResultInformation(resultID, includeArchived)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultsInformation")
        End Function

        Public Shared Function GetResults(ByVal requestNumber As String, ByVal testIDs As String, ByVal testStageName As String, ByVal unitNumber As Int32) As DataTable
            Try
                Return RelabDB.GetResults(requestNumber, testIDs, testStageName, unitNumber)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("Results")
        End Function

        Public Shared Function FunctionalMatrixByTestRecord(ByVal trID As Int32, ByVal testStageID As Int32, ByVal testID As Int32, ByVal batchID As Int32, ByVal unitIDs As String, ByVal functionalType As Int32) As DataTable
            Try
                Return RelabDB.FunctionalMatrixByTestRecord(trID, testStageID, testID, batchID, unitIDs, functionalType)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("FunctionalMatrixByTestRecord")
        End Function

        Public Shared Function OverallResultSummary(ByVal batchID As Integer) As DataTable
            Try
                Return RelabDB.OverallResultSummary(batchID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("OverallResultSummary")
        End Function

        Public Shared Function FailureAnalysis(ByVal testID As Int32, ByVal batchID As Int32) As DataTable
            Try
                Return RelabDB.FailureAnalysis(testID, batchID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultsFailureAnalysis")
        End Function

        Public Shared Function ResultSummaryExport(ByVal batchID As Integer, ByVal resultID As Int32) As DataTable
            Try
                Return RelabDB.ResultSummaryExport(batchID, resultID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultsSummaryExport")
        End Function

        Public Shared Function GetFiles(ByVal requestNumber As String, ByVal fromReportGenerator As Boolean) As DataTable
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim dt As DataTable

                If (fromReportGenerator) Then
                    dt = BusinessEntities.Helpers.EQToDataTable((From f In instance.ResultsMeasurementsFiles
                                                                Where f.ResultsMeasurement.Result.TestUnit.Batch.QRANumber = requestNumber And (Not f.ResultsMeasurement.Result.TestStage.TestStageName.ToLower.Contains("analysis")) And f.ResultsMeasurement.Archived = False And (f.ResultsMeasurement.Result.Test.TestName.ToLower.Contains("drop") Or f.ResultsMeasurement.Result.Test.TestName.ToLower.Contains("tumble") Or f.ResultsMeasurement.Result.Test.TestName.ToLower.Contains("visual") Or f.ResultsMeasurement.Result.Test.TestName.ToLower.Contains("functional") Or f.ResultsMeasurement.Result.Test.TestName.ToLower.Contains("camera"))
                                                                Select f.ResultMeasurementID, f.ResultsMeasurement.Result.TestStage.TestStageName, f.ResultsMeasurement.Result.Test.TestName, f.ResultsMeasurement.Result.TestUnit.BatchUnitNumber, f.ResultsMeasurement.Lookup.Values, f.File, f.FileName, f.ContentType).ToList(), "Files")
                Else
                    dt = BusinessEntities.Helpers.EQToDataTable((From f In instance.ResultsMeasurementsFiles
                                                                Where f.ResultsMeasurement.Result.TestUnit.Batch.QRANumber = requestNumber And (Not f.ResultsMeasurement.Result.TestStage.TestStageName.ToLower.Contains("analysis")) And f.ResultsMeasurement.Archived = False
                                                                Select f.ResultMeasurementID, f.ResultsMeasurement.Result.TestStage.TestStageName, f.ResultsMeasurement.Result.Test.TestName, f.ResultsMeasurement.Result.TestUnit.BatchUnitNumber, f.ResultsMeasurement.Lookup.Values, f.File, f.FileName, f.ContentType).ToList(), "Files")
                End If

                Array.ForEach(dt.AsEnumerable().ToArray(), Sub(row) row("Values") = If(row("Values").ToString() = "Observation", instance.remispGetObservationParameters(DirectCast(row("ResultMeasurementID"), Int32)).FirstOrDefault(), row("Values")))

                dt.Columns.Remove("ResultMeasurementID")
                dt.AcceptChanges()

                Return dt
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataTable("Files")
        End Function

        Public Shared Function MeasurementFiles(ByVal MeasurementID As Int32, ByVal resultID As Int32) As DataTable
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim dt As DataTable

                If (resultID > 0) Then
                    dt = BusinessEntities.Helpers.EQToDataTable((From mf In instance.ResultsMeasurementsFiles Where mf.ResultsMeasurement.Result.ID = resultID Select mf).ToList(), "MeasurementFiles")
                Else
                    dt = BusinessEntities.Helpers.EQToDataTable((From mf In instance.ResultsMeasurementsFiles Where mf.ResultMeasurementID = MeasurementID Select mf).ToList(), "MeasurementFiles")
                End If

                If (dt.Rows.Count > 0) Then
                    dt.Columns.Remove("EntityState")
                    dt.Columns.Remove("EntityKey")
                    dt.Columns.Remove("ResultsMeasurementReference")
                    dt.Columns.Remove("ResultsMeasurement")
                End If

                Return dt
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("MeasurementFiles")
        End Function

        Public Shared Function ResultMeasurements(ByVal resultID As Integer, ByVal onlyFails As Boolean, ByVal includeArchived As Boolean) As DataTable
            Try
                Return RelabDB.ResultMeasurements(resultID, onlyFails, includeArchived)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultMeasurements")
        End Function

        Public Shared Function ResultVersions(ByVal testID As Integer, ByVal batchID As Int32, ByVal unitNumber As Int32, ByVal testStageID As Int32) As DataTable
            Try
                Return RelabDB.ResultVersions(testID, batchID, unitNumber, testStageID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultVersions")
        End Function

        Public Shared Function UploadResults(ByVal xml As String, ByVal lossFile As String) As Boolean
            Try
                Return RelabDB.UploadResults(xml, lossFile)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function ModifyResult(ByVal value As String, ByVal ID As Int32, ByVal passFailOverride As Boolean, ByVal currentPassFail As Boolean, ByVal passFailText As String, ByVal userName As String) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()

                Dim passFail As Boolean = currentPassFail
                Dim resultID As Int32
                Dim result As Entities.Result

                If (passFailOverride = True) Then
                    If (passFailText.ToLower() = "pass") Then
                        passFail = True
                    Else
                        passFail = False
                    End If
                End If

                Dim measurement = (From m In instance.ResultsMeasurements.Include("Result") Where m.ID = ID Select m).FirstOrDefault()

                If (measurement IsNot Nothing) Then
                    measurement.Comment = value.Replace(Chr(34), "&#34;")
                    measurement.PassFail = passFail
                    measurement.LastUser = userName

                    resultID = measurement.Result.ID
                    result = measurement.Result

                    instance.SaveChanges()

                    If (passFailOverride = True) Then
                        Dim failureCount As Int32 = (From m In instance.ResultsMeasurements Where m.Result.ID = resultID And m.Archived = False And m.PassFail = False Select m).Count()

                        If (result IsNot Nothing) Then
                            result.PassFail = If(failureCount > 0, False, True)

                            instance.SaveChanges()
                        End If
                    End If
                    Return True
                Else
                    Return False
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function PollUnProcessedResults(ByVal requestNumber As String, ByVal unit As Int32, ByVal testStageName As String, ByVal testName As String) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim countUnProcessed As Int32 = (From x In New REMI.Dal.Entities().Instance().ResultsXMLs _
                                     Where x.Result.Test.TestName = testName _
                                      And x.Result.TestStage.TestStageName = testStageName _
                                      And x.Result.TestUnit.Batch.QRANumber = requestNumber _
                                      And x.Result.TestUnit.BatchUnitNumber = unit _
                                      And x.isProcessed = 0 _
                                     Select x).Count()

                Return (countUnProcessed > 0)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function UploadResultsMeasurementsFile(ByVal file() As Byte, ByVal contentType As String, ByVal fileName As String) As Boolean
            Try
                Return RelabDB.UploadResultsMeasurementsFile(file, contentType, fileName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function GetAvailableTestsByBatches(ByVal batchIDs As String) As DataTable
            Try
                Return RelabDB.GetAvailableTestsByBatches(batchIDs)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultUnits")
        End Function

        Public Shared Function GetMeasurementsByTest(ByVal batchIDs As String, ByVal testID As Int32, ByVal showOnlyFailValue As Boolean) As DataTable
            Try
                Return RelabDB.GetMeasurementsByTest(batchIDs, testID, showOnlyFailValue)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultMeasurements")
        End Function

        Public Shared Function GetParametersByMeasurementTest(ByVal batchIDs As String, ByVal testID As Int32, ByVal measurementTypeID As Int32, ByVal parameterName As String, ByVal showOnlyFailValue As Boolean, ByVal testStageIDs As String) As DataTable
            Try
                Return RelabDB.GetParametersByMeasurementTest(batchIDs, testID, measurementTypeID, parameterName, showOnlyFailValue, testStageIDs)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultMeasurements")
        End Function

        Public Shared Function GetUnitsByTestMeasurementParameters(ByVal batchIDs As String, ByVal testID As Int32, ByVal measurementTypeID As Int32, ByVal parameterName As String, ByVal parameterValue As String, ByVal getStages As Boolean, ByVal showOnlyFailValue As Boolean) As DataTable
            Try
                Return RelabDB.GetUnitsByTestMeasurementParameters(batchIDs, testID, measurementTypeID, parameterName, parameterValue, getStages, showOnlyFailValue)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultUnits")
        End Function

        Public Shared Function ResultGraph(ByVal batchIDs As String, ByVal unitIDs As String, ByVal measurementTypeID As Int32, ByVal parameterName As String, ByVal parameterValue As String, ByVal showUpperLowerLimits As Boolean, ByVal testID As Int32, ByVal xaxis As Int32, ByVal plotValue As Int32, ByVal includeArchived As Boolean, ByVal stages As String) As DataSet
            Try
                Return RelabDB.ResultGraph(batchIDs, unitIDs, measurementTypeID, parameterName, parameterValue, showUpperLowerLimits, testID, xaxis, plotValue, includeArchived, stages)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataSet
        End Function

        Public Shared Function GetMeasurementParameterCommaSeparated(ByVal measurementID As Int32) As DataTable
            Try
                Return RelabDB.GetMeasurementParameterCommaSeparated(measurementID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("ResultParamas")
        End Function

        Public Shared Function SaveOverAllResult(ByVal batchID As Int32, ByVal PassFailID As Int32) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim rs As New Entities.ResultsStatu

                If (PassFailID > 0) Then
                    rs.PassFail = PassFailID
                End If

                rs.BatchID = batchID
                rs.ApprovedBy = UserManager.GetCurrentUser.UserName
                rs.ApprovedDate = DateTime.Now

                instance.AddToResultsStatus(rs)
                instance.SaveChanges()

                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return False
        End Function

        Public Shared Function GetOverAllPassFail(ByVal BatchID As Int32) As DataSet
            Try
                Return RelabDB.GetOverAllPassFail(BatchID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return New DataSet("PassFail")
        End Function

        Public Shared Function GetObservations(ByVal batchID As Int32) As DataTable
            Try
                Return RelabDB.GetObservations(batchID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("GetObservations")
        End Function

        Public Shared Function GetObservationSummary(ByVal batchID As Int32) As DataTable
            Try
                Return RelabDB.GetObservationSummary(batchID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable("GetObservationSummary")
        End Function

        Public Shared Function ReassignTestStage(ByVal batchID As Int32, ByVal testID As Int32, ByVal testStageID As Int32, ByVal unitID As Int32, ByVal newTestStageID As Int32) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim result As IQueryable(Of REMI.Entities.Result)
                If (unitID = 0) Then
                    result = (From r In instance.Results Where r.TestUnit.Batch.ID = batchID And r.Test.ID = testID And r.TestStage.ID = testStageID)
                Else
                    result = (From r In instance.Results Where r.TestUnit.Batch.ID = batchID And r.Test.ID = testID And r.TestStage.ID = testStageID And r.TestUnit.ID = unitID)
                End If

                If (result IsNot Nothing) Then
                    For Each r In result
                        r.TestStage = (From ts In instance.TestStages Where ts.ID = newTestStageID Select ts).FirstOrDefault()
                    Next

                    instance.SaveChanges()
                End If

                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("batchID: {0} testID: {1} testStageID: {2} newTestStageID: {3}", batchID, testID, testStageID, newTestStageID))
                Return False
            End Try
        End Function
    End Class
End Namespace