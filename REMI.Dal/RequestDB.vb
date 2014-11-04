Imports System
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
            Dim dt As New DataTable("RequestSetupInfo")
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

        Public Shared Function SaveRequest(ByVal requestName As String, ByVal request As RequestFieldsCollection, ByVal userIdentification As String) As Boolean
            Dim instance = New REMI.Dal.Entities().Instance()
            Dim val = (From rfc In request Select rfc.FieldSetupID, rfc.Value, rfc.RequestID, rfc.RequestNumber)
            Dim reqID As Int32 = 0
            Dim reqNumber As String = val(0).RequestNumber

            Dim req = (From r In instance.Requests Where r.RequestNumber = reqNumber).FirstOrDefault()

            If (req Is Nothing) Then
                Dim rq As New REMI.Entities.Request()
                rq.RequestNumber = reqNumber
                instance.AddToRequests(rq)
            Else
                reqID = req.RequestID
            End If

            instance.SaveChanges()

            reqID = (From r In instance.Requests Where r.RequestNumber = reqNumber Select r.RequestID).FirstOrDefault()

            For Each rec In val
                Dim fieldData = (From fd In instance.ReqFieldDatas Where fd.RequestID = reqID And fd.ReqFieldSetupID = rec.FieldSetupID).FirstOrDefault()

                If (fieldData Is Nothing) Then
                    Dim sfd As New REMI.Entities.ReqFieldData()
                    sfd.ReqFieldSetupID = rec.FieldSetupID
                    sfd.RequestID = reqID
                    sfd.Value = rec.Value
                    instance.AddToReqFieldDatas(sfd)
                Else
                    fieldData.Value = rec.Value
                End If
            Next

            instance.SaveChanges()

            Return True
        End Function

        Public Shared Function GetRequestFieldSetup(ByVal requestName As String, ByVal includeArchived As Boolean, ByVal requestNumber As String) As RequestFieldsCollection
            Dim rtID As Int32
            Dim fieldData As RequestFieldsCollection = Nothing

            rtID = (From fs In New REMI.Dal.Entities().Instance.ReqFieldSetups Where fs.RequestType.Lookup.Values = requestName Select fs.RequestTypeID).FirstOrDefault()

            If (rtID > 0) Then
                Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                    Using myCommand As New SqlCommand("Req.RequestFieldSetup", myConnection)
                        myCommand.CommandType = CommandType.StoredProcedure
                        myCommand.Parameters.AddWithValue("@RequestTypeID", rtID)

                        If (includeArchived) Then
                            myCommand.Parameters.AddWithValue("@IncludeArchived", 1)
                        End If

                        If (requestNumber.Trim().Length > 0) Then
                            myCommand.Parameters.AddWithValue("@RequestNumber", requestNumber)
                        End If

                        myConnection.Open()

                        Using myReader As SqlDataReader = myCommand.ExecuteReader()
                            If myReader.HasRows Then
                                fieldData = New RequestFieldsCollection

                                While myReader.Read()
                                    fieldData.Add(FillFieldData(myReader))
                                End While
                            End If
                        End Using
                    End Using
                End Using
            End If

            Return fieldData
        End Function

        Private Shared Function FillFieldData(ByVal myDataRecord As IDataRecord) As BusinessEntities.RequestFields
            Dim myFields As RequestFields = New BusinessEntities.RequestFields()

            myFields.FieldSetupID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ReqFieldSetupID"))
            myFields.RequestType = myDataRecord.GetString(myDataRecord.GetOrdinal("RequestType"))
            myFields.RequestTypeID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("RequestTypeID"))

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Description")) Then
                myFields.Description = myDataRecord.GetString(myDataRecord.GetOrdinal("Description"))
            Else
                myFields.Description = String.Empty
            End If

            myFields.DisplayOrder = myDataRecord.GetInt32(myDataRecord.GetOrdinal("DisplayOrder"))
            myFields.ColumnOrder = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ColumnOrder"))
            myFields.FieldType = myDataRecord.GetString(myDataRecord.GetOrdinal("FieldType"))
            myFields.FieldTypeID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("FieldTypeID"))

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("FieldValidationID")) Then
                myFields.FieldValidation = myDataRecord.GetString(myDataRecord.GetOrdinal("ValidationType"))
                myFields.FieldValidationID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("FieldValidationID"))
            Else
                myFields.FieldValidation = String.Empty
                myFields.FieldValidationID = 0
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ExtField")) Then
                myFields.ExtField = myDataRecord.GetString(myDataRecord.GetOrdinal("ExtField"))
            Else
                myFields.ExtField = String.Empty
            End If

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("IntField")) Then
                myFields.IntField = myDataRecord.GetString(myDataRecord.GetOrdinal("IntField"))
            Else
                myFields.IntField = String.Empty
            End If

            myFields.Internal = myDataRecord.GetInt32(myDataRecord.GetOrdinal("Internal"))

            myFields.IsArchived = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("Archived"))
            myFields.IsRequired = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("IsRequired"))
            myFields.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("Name"))

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("OptionsTypeID")) Then
                myFields.OptionsTypeID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("OptionsTypeID"))
                myFields.OptionsType = (From lo In New REMI.Dal.Entities().Instance.Lookups Where lo.LookupTypeID = myFields.OptionsTypeID Order By lo.Values Select lo.Values).ToList
            Else
                myFields.OptionsTypeID = 0
                myFields.OptionsType = New List(Of String)()
            End If

            myFields.RequestID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("RequestID"))
            myFields.RequestNumber = myDataRecord.GetString(myDataRecord.GetOrdinal("RequestNumber"))
            myFields.NewRequest = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("NewRequest"))

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Value")) Then
                myFields.Value = myDataRecord.GetString(myDataRecord.GetOrdinal("Value"))
            Else
                myFields.Value = String.Empty
            End If

            If (myFields.OptionsTypeID = 0 And Not String.IsNullOrEmpty(myFields.IntField)) Then
                Select Case myFields.IntField
                    Case "ProductGroup"
                        myFields.OptionsType = (From p In New REMI.Dal.Entities().Instance.Products Where p.IsActive = True Order By p.ProductGroupName Select p.ProductGroupName).ToList
                    Case "RequestedTest"
                        myFields.OptionsType = (From j In New REMI.Dal.Entities().Instance.Jobs Where j.IsActive = True Order By j.JobName Select j.JobName).ToList
                End Select
            End If

            Return myFields
        End Function
    End Class
End Namespace