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
    Public Class RelabDB
        Public Shared Function ResultSummary(ByVal batchID As Integer) As DataTable
            Dim dt As New DataTable("ResultsSummary")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispResultsSummary", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResultsSummary"
                End Using
            End Using

            Return dt
        End Function
        Public Shared Function GetOverAllPassFail(ByVal BatchID As Int32) As DataSet
            Dim ds As New DataSet("PassFail")

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispResultsStatus", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BatchID", BatchID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(ds)
                End Using
            End Using

            Return ds
        End Function

        Public Shared Function ResultInformation(ByVal resultID As Int32, ByVal includeArchived As Boolean) As DataTable
            Dim dt As New DataTable("ResultsInformation")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispResultsInformation", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ResultID", resultID)

                    If (includeArchived) Then
                        myCommand.Parameters.AddWithValue("@IncludeArchived", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@IncludeArchived", 0)
                    End If

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResultsInformation"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetResults(ByVal requestNumber As String, ByVal testIDs As String, ByVal testStageName As String, ByVal unitNumber As Int32) As DataTable
            Dim dt As New DataTable("Results")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispMeasurementsByReq_Test", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@RequestNumber", requestNumber)
                    myCommand.Parameters.AddWithValue("@TestIDs", testIDs)

                    If (testStageName.Trim().Length > 0) Then
                        myCommand.Parameters.AddWithValue("@TestStageName", testStageName)
                    End If

                    If (unitNumber > 0) Then
                        myCommand.Parameters.AddWithValue("@UnitNumber", unitNumber)
                    End If

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "Results"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function FunctionalMatrixByTestRecord(ByVal trID As Int32, ByVal testStageID As Int32, ByVal testID As Int32, ByVal batchID As Int32, ByVal unitIDs As String, ByVal functionalType As Int32) As DataTable
            Dim dt As New DataTable("FunctionalMatrixByTestRecord")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.FunctionalMatrixByTestRecord", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    If trID > 0 Then
                        myCommand.Parameters.AddWithValue("@TRID", trID)
                    End If

                    myCommand.Parameters.AddWithValue("@TestStageID", testStageID)
                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)

                    myCommand.Parameters.AddWithValue("@FunctionalType", functionalType)

                    If (unitIDs IsNot Nothing) Then
                        myCommand.Parameters.AddWithValue("@UnitIDs", unitIDs)
                    End If

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "FunctionalMatrixByTestRecord"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetTestResults(ByVal batchID As Int32, ByVal testStageID As Int32) As TestResultCollection
            Dim testResults As New TestResultCollection
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispGetAllResultsByQRAStage", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)
                    myCommand.Parameters.AddWithValue("@TestStageID", testStageID)
                    myConnection.Open()
                    
                    Using myReader As SqlDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            While myReader.Read()
                                testResults.Add(New TestResult(TestResultSource.Relab,
                                                               myReader.GetInt32(myReader.GetOrdinal("VerNum")),
                                                               myReader.GetString(myReader.GetOrdinal("PassFail")),
                                                               myReader.GetString(myReader.GetOrdinal("TestName")),
                                                               myReader.GetString(myReader.GetOrdinal("TestStageName")),
                                                               myReader.GetInt32(myReader.GetOrdinal("BatchUnitNumber")),
                                                               myReader.GetInt32(myReader.GetOrdinal("TestID")),
                                                               myReader.GetInt32(myReader.GetOrdinal("TestStageID"))))
                            End While
                        End If
                    End Using
                End Using
            End Using

            Return testResults
        End Function

        Public Shared Function FailureAnalysis(ByVal testID As Int32, ByVal batchID As Int32) As DataTable
            Dim dt As New DataTable("ResultsFailureAnalysis")
            If (testID > 0) Then
                Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                    Using myCommand As New SqlCommand("Relab.remispResultsFailureAnalysis", myConnection)
                        myCommand.CommandType = CommandType.StoredProcedure
                        myCommand.CommandTimeout = 50
                        myCommand.Parameters.AddWithValue("@TestID", testID)
                        myCommand.Parameters.AddWithValue("@BatchID", batchID)
                        myConnection.Open()
                        Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                        da.Fill(dt)
                        dt.TableName = "ResultsFailureAnalysis"
                    End Using
                End Using
            End If

            Return dt
        End Function

        Public Shared Function ResultSummaryExport(ByVal batchID As Integer, ByVal resultID As Int32) As DataTable
            Dim dt As New DataTable("ResultsSummaryExport")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispResultsSummaryExport", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)
                    If (resultID > 0) Then
                        myCommand.Parameters.AddWithValue("@ResultID", resultID)
                    End If
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResultsSummaryExport"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function OverallResultSummary(ByVal batchID As Integer) As DataTable
            Dim dt As New DataTable("OverallResultSummary")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispOverallResultsSummary", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "OverallResultSummary"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function ResultVersions(ByVal testID As Integer, ByVal batchID As Integer) As DataTable
            Dim dt As New DataTable("ResultVersions")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispResultVersions", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResultVersions"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function ResultMeasurements(ByVal resultID As Integer, ByVal onlyFails As Boolean, ByVal includeArchived As Boolean) As DataTable
            Dim dt As New DataTable("ResultMeasurements")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispResultMeasurements", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ResultID", resultID)
                    If (onlyFails) Then
                        myCommand.Parameters.AddWithValue("@OnlyFails", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@OnlyFails", 0)
                    End If
                    If (includeArchived) Then
                        myCommand.Parameters.AddWithValue("@IncludeArchived", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@IncludeArchived", 0)
                    End If
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResultMeasurements"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function UploadResults(ByVal xml As String, ByVal lossFile As String) As Boolean
            Dim success As Boolean = False

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispResultsFileUpload", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@XML", xml)
                    myCommand.Parameters.AddWithValue("@LossFile", lossFile)

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

        Public Shared Function UploadResultsMeasurementsFile(ByVal file() As Byte, ByVal contentType As String, ByVal fileName As String) As Boolean
            Dim success As Boolean = False

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispResultsMeasurementFileUpload", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@File", file)
                    myCommand.Parameters.AddWithValue("@ContentType", contentType)
                    myCommand.Parameters.AddWithValue("@FileName", fileName)

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

        Public Shared Function GetMeasurementParameterCommaSeparated(ByVal measurementID As Int32) As DataTable
            Dim dt As New DataTable("ResultParamas")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispGetMeasurementParameterCommaSeparated", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@MeasurementID", measurementID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResultParamas"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetAvailableTestsByBatches(ByVal batchIDs As String) As DataTable
            Dim dt As New DataTable("ResulTests")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispGetTestsByBatches", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@BatchIDs", batchIDs)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResulTests"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetMeasurementsByTest(ByVal batchIDs As String, ByVal testID As Int32, ByVal showOnlyFailValue As Boolean) As DataTable
            Dim dt As New DataTable("ResultMeasurements")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispGetMeasurementsByTest", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@BatchIDs", batchIDs)

                    If (showOnlyFailValue) Then
                        myCommand.Parameters.AddWithValue("@ShowOnlyFailValue", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ShowOnlyFailValue", 0)
                    End If

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResultMeasurements"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetParametersByMeasurementTest(ByVal batchIDs As String, ByVal testID As Int32, ByVal measurementTypeID As Int32, ByVal parameterName As String, ByVal showOnlyFailValue As Boolean, ByVal testStageIDs As String) As DataTable
            Dim dt As New DataTable("ResultMeasurements")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispGetParametersByMeasurementTest", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@MeasurementTypeID", measurementTypeID)
                    If (Not String.IsNullOrEmpty(parameterName)) Then
                        myCommand.Parameters.AddWithValue("@ParameterName", parameterName)
                    End If

                    If (Not (batchIDs = String.Empty)) Then
                        myCommand.Parameters.AddWithValue("@BatchIDs", batchIDs)
                    Else
                        myCommand.Parameters.AddWithValue("@BatchIDs", String.Empty)
                    End If

                    If (showOnlyFailValue) Then
                        myCommand.Parameters.AddWithValue("@ShowOnlyFailValue", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ShowOnlyFailValue", 0)
                    End If

                    If (testStageIDs <> String.Empty) Then
                        myCommand.Parameters.AddWithValue("@TestStageIDs", testStageIDs)
                    End If

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResultMeasurements"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetUnitsByTestMeasurementParameters(ByVal batchIDs As String, ByVal testID As Int32, ByVal measurementTypeID As Int32, ByVal parameterName As String, ByVal parameterValue As String, ByVal getStages As Boolean, ByVal showOnlyFailValue As Boolean) As DataTable
            Dim dt As New DataTable("ResultUnits")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispGetUnitsByTestMeasurementParameters", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@MeasurementTypeID", measurementTypeID)

                    If (Not String.IsNullOrEmpty(parameterName)) Then
                        myCommand.Parameters.AddWithValue("@ParameterName", parameterName)
                        If (Not String.IsNullOrEmpty(parameterValue)) Then
                            myCommand.Parameters.AddWithValue("@ParameterValue", parameterValue)
                        End If
                    End If
                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@BatchIDs", batchIDs)
                    myCommand.Parameters.AddWithValue("@GetStages", getStages)

                    If (showOnlyFailValue) Then
                        myCommand.Parameters.AddWithValue("@ShowOnlyFailValue", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ShowOnlyFailValue", 0)
                    End If

                    myConnection.Open()

                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "ResultUnits"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function ResultGraph(ByVal batchIDs As String, ByVal unitIDs As String, ByVal measurementTypeID As Int32, ByVal parameterName As String, ByVal parameterValue As String, ByVal showUpperLowerLimits As Boolean, ByVal testID As Int32, ByVal xaxis As Int32, ByVal plotValue As Int32, ByVal includeArchived As Boolean, ByVal stages As String) As DataSet
            Dim ds As New DataSet()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Relab.remispResultsGraph", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.CommandTimeout = 50

                    myCommand.Parameters.AddWithValue("@MeasurementTypeID", measurementTypeID)
                    myCommand.Parameters.AddWithValue("@TestID", testID)

                    If (Not String.IsNullOrEmpty(parameterName)) Then
                        myCommand.Parameters.AddWithValue("@ParameterName", parameterName)
                        If (Not String.IsNullOrEmpty(parameterValue)) Then
                            myCommand.Parameters.AddWithValue("@ParameterValue", parameterValue)
                        End If
                    End If

                    myCommand.Parameters.AddWithValue("@BatchIDs", batchIDs)
                    myCommand.Parameters.AddWithValue("@UnitIDs", unitIDs)

                    If (showUpperLowerLimits) Then
                        myCommand.Parameters.AddWithValue("@ShowUpperLowerLimits", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ShowUpperLowerLimits", 0)
                    End If
                    myCommand.Parameters.AddWithValue("@Xaxis", xaxis)
                    myCommand.Parameters.AddWithValue("@PlotValue", plotValue)

                    If (includeArchived) Then
                        myCommand.Parameters.AddWithValue("@IncludeArchived", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@IncludeArchived", 0)
                    End If

                    myCommand.Parameters.AddWithValue("@Stages", stages)

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(ds)
                End Using
            End Using

            Return ds
        End Function
    End Class
End Namespace