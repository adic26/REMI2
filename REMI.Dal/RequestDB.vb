﻿Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.OracleClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Contracts
Imports REMI.Core
Imports System.Reflection

Namespace REMI.Dal
    Public Class RequestDB

        Public Shared Function GetRequestSetupInfo(ByVal productID As Int32, ByVal jobID As Int32, ByVal batchID As Int32, ByVal testStageType As Int32, ByVal blankSelected As Int32) As DataTable
            Dim dt As New DataTable()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Req.GetRequestSetupInfo", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ProductID", productID)
                    myCommand.Parameters.AddWithValue("@JobID", jobID)
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)
                    myCommand.Parameters.AddWithValue("@TestStageType", testStageType)
                    myCommand.Parameters.AddWithValue("@BlankSelected", blankSelected)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "RequestSetupInfo"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetConnectString(ByVal reqNumber As String) As String
            Dim requestType As String = reqNumber.Substring(0, reqNumber.IndexOf("-"))

            Return (From r In New REMI.Dal.Entities().Instance().RequestTypes Where r.Lookup.LookupType.Name = "RequestType" And r.Lookup.Values = requestType Select r.RequestConnectName).FirstOrDefault()
        End Function

        Public Shared Function GetTRSRequest(ByVal reqNumber As String) As IQRARequest
            Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(GetConnectString(reqNumber)))
                myConnection.Open()

                Return GetTRSRequest(reqNumber, myConnection)
            End Using
        End Function

        Public Shared Function GetTRSRequest(ByVal reqNumber As String, ByVal myConnection As OracleConnection) As IQRARequest
            Dim reqNum As New RequestNumber(reqNumber)
            Dim requestData As IQRARequest = Nothing

            If reqNum.Validate Then
                requestData = REMIAppCache.GetReqData(reqNumber)

                If requestData IsNot Nothing Then
                    Return requestData
                Else
                    'GET IN DB
                    'could not find it in cache, return it from the 
                    ' oracle database if possible
                    Dim connectionCreatedInternally As Boolean

                    If myConnection Is Nothing Then
                        myConnection = New OracleConnection(REMIConfiguration.ConnectionStringReq(GetConnectString(reqNumber)))
                        connectionCreatedInternally = True
                    End If

                    If myConnection.State <> ConnectionState.Open Then
                        myConnection.Open()
                    End If

                    Try
                        Using myCommand As New OracleCommand("REMI_HELPER.get_request_information", myConnection)
                            myCommand.CommandType = CommandType.StoredProcedure
                            myCommand.Parameters.Add(New OracleParameter("p_reqnum", OracleType.VarChar)).Value = reqNum.Number
                            myCommand.Parameters.Add(New OracleParameter("C_REF_RET", OracleType.Cursor)).Direction = ParameterDirection.ReturnValue
                            Dim myReader As OracleDataReader = myCommand.ExecuteReader

                            If myReader.HasRows Then
                                requestData = GetRecord(myReader, reqNum)
                            End If
                        End Using
                    Catch ex As Exception
                        Emailer.SendErrorEMail("REMI Error", "Current Request: " + reqNum.Number, REMI.Validation.NotificationType.Errors, ex)
                    End Try

                    If connectionCreatedInternally Then
                        myConnection.Close()
                        myConnection.Dispose()
                    End If
                    'now put it in the cache
                    If requestData IsNot Nothing Then
                        REMIAppCache.SetReqData(requestData)
                    End If
                End If
            End If

            Return requestData
        End Function

        Public Shared Function GetTRSQRAByTestCenter(ByVal testCenter As String) As DataTable
            Dim dtReq As New DataTable
            Dim connections As List(Of String) = (From r In New REMI.Dal.Entities().Instance().RequestTypes Where r.Lookup.LookupType.Name = "RequestType" And r.DBType = "Oracle" Select r.RequestConnectName).Distinct.ToList()

            For Each con In connections
                Using myOracleConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(con))
                    myOracleConnection.Open()

                    Using myCommand As New OracleCommand("REMI_HELPER.get_QRA_By_TestCenter", myOracleConnection)
                        myCommand.CommandTimeout = 40
                        myCommand.CommandType = CommandType.StoredProcedure
                        myCommand.Parameters.Add(New OracleParameter("p_test_center", OracleType.VarChar)).Value = testCenter
                        myCommand.Parameters.Add(New OracleParameter("C_REF_RET", OracleType.Cursor)).Direction = ParameterDirection.ReturnValue
                        Dim myReader As OracleDataReader = myCommand.ExecuteReader
                        Dim dt As New DataTable
                        dt.Load(myReader)
                        dtReq.Merge(dt, True)
                    End Using
                End Using
            Next

            'Dim connectionsSQL As List(Of String) = (From r In New REMI.Dal.Entities().Instance().RequestTypes Where r.Lookup.Type = "RequestType" And r.DBType = "SQL" Select r.RequestConnectName).Distinct.ToList()

            'For Each con In connectionsSQL
            '    Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringReq(con))
            '        myConnection.Open()

            '    End Using
            'Next

            Return dtReq
        End Function

        Public Shared Sub UpdateTRSPercentageComplete(ByVal reqNumber As String, ByVal percentageComplete As Integer)
            Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(GetConnectString(reqNumber)))
                myConnection.Open()
                Using myCommand As New OracleCommand("REMI_HELPER.qra_percent_update", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    Dim pPercentComplete As New OracleParameter
                    pPercentComplete.Direction = ParameterDirection.Input
                    pPercentComplete.OracleType = OracleType.Number
                    pPercentComplete.ParameterName = "percent_complete"
                    pPercentComplete.Value = percentageComplete
                    myCommand.Parameters.Add(pPercentComplete)

                    Dim pQRANumber As New OracleParameter
                    pQRANumber.Direction = ParameterDirection.Input
                    pQRANumber.OracleType = OracleType.VarChar
                    pQRANumber.ParameterName = "p_reqnum"
                    pQRANumber.Value = reqNumber
                    myCommand.Parameters.Add(pQRANumber)

                    myCommand.ExecuteOracleScalar()

                End Using
            End Using
        End Sub

        Private Shared Function GetRecord(ByVal myReader As IDataReader, ByVal reqNum As RequestNumber) As IQRARequest
            Dim reqData As New RequestBase(reqNum)
            Dim currentUnitNumber As Integer

            While myReader.Read
                Select Case myReader.Item(0).ToString.ToLower.Trim
                    Case "failed unit number"
                        If Integer.TryParse(myReader.Item(1).ToString.Trim, currentUnitNumber) Then
                            reqData.AffectsUnits.Add(currentUnitNumber)
                        End If
                    Case Else
                        Dim keyName As String = myReader.Item(0).ToString.Trim
                        Dim propValue As String = myReader.Item(1).ToString.Trim
                        If Not reqData.RequestProperties.ContainsKey(keyName) Then
                            reqData.RequestProperties.Add(keyName, propValue)
                        End If
                End Select
            End While

            If (REMIAppCache.GetFieldMapping(reqData.RequestType) Is Nothing) Then
                REMIAppCache.SetFieldMapping(reqData.RequestType, (From fm In New REMI.Dal.Entities().Instance.ReqFieldMappings Where fm.RequestType.Lookup.Values = reqData.RequestType).ToDictionary(Function(k) k.IntField, Function(v) v.ExtField))
            End If

            reqData.FieldMapping = REMIAppCache.GetFieldMapping(reqData.RequestType)

            Return reqData
        End Function
    End Class
End Namespace