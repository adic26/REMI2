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

        Public Shared Function GetRequestTypes(ByVal userIdentification As String) As DataTable
            Dim dt As New DataTable("RequestTypes")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Req.remispGetRequestTypes", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@UserName", userIdentification)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "RequestTypes"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetConnectName(ByVal reqNumber As String) As String
            Return reqNumber.Substring(0, reqNumber.IndexOf("-"))
        End Function

        Public Shared Function GetConnectString(ByVal reqNumber As String) As String
            Dim requestType As String = reqNumber.Substring(0, reqNumber.IndexOf("-"))

            Return (From r In New REMI.Dal.Entities().Instance().RequestTypes Where r.Lookup.LookupType.Name = "RequestType" And r.Lookup.Values = requestType Select r.RequestConnectName).FirstOrDefault()
        End Function

        Public Shared Function GetRequest(ByVal reqNumber As String, ByVal user As User) As RequestFieldsCollection
            Dim reqNum As New RequestNumber(reqNumber)
            Dim requestType = (From r In New REMI.Dal.Entities().Instance().RequestTypes.Include("Lookup") Where r.Lookup.LookupType.Name = "RequestType" And r.Lookup.Values = reqNum.Type Select r).FirstOrDefault()

            Dim rf As RequestFieldsCollection = REMIAppCache.GetReqData(reqNum.Number)

            If (rf Is Nothing) Then
                rf = GetRequestFieldSetup(requestType.Lookup.Values, False, reqNum.Number, user)

                If (requestType.IsExternal) Then
                    If (rf.Count > 0) Then
                        LinkExternalRequest(reqNumber, rf, user.UserName, requestType.DBType)
                    End If
                End If

                REMIAppCache.SetReqData(rf, reqNum.Number)
            End If

            Return rf
        End Function

#Region "Oracle"
        ''' <summary>
        ''' Accesses the FA System and attempts to get a list of FA's for a particular QRA.
        ''' </summary>
        ''' <param name="QRANumber">the QRA number of the batch </param>
        ''' <returns>A list of FA numbers</returns>
        Public Shared Function GetFANumberList(ByVal QRANumber As String) As List(Of String)
            Dim FAQRANumberList As New List(Of String)
            Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(RequestDB.GetConnectString(QRANumber)))
                Using myCommand As New OracleCommand("REMI_HELPER.get_FAs_by_QRA", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    Dim pOut As New OracleParameter
                    pOut.Direction = ParameterDirection.ReturnValue
                    pOut.OracleType = OracleType.Cursor
                    pOut.ParameterName = "C_REF_RET"
                    myCommand.Parameters.Add(pOut)

                    Dim pQRANumber As New OracleParameter
                    pQRANumber.Direction = ParameterDirection.Input
                    pQRANumber.OracleType = OracleType.VarChar
                    pQRANumber.ParameterName = "p_qra_num"
                    pQRANumber.Value = QRANumber

                    myCommand.Parameters.Add(pQRANumber)
                    myConnection.Open()
                    Using myReader As OracleDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            While myReader.Read()
                                FAQRANumberList.Add(myReader.GetValue(0).ToString)
                            End While
                        End If
                    End Using
                End Using
            End Using

            Return FAQRANumberList
        End Function

        Public Shared Sub LinkExternalRequest(ByVal reqNumber As String, ByRef rf As RequestFieldsCollection, ByVal useridentification As String, ByVal dbType As String)
            Dim reqNum As New RequestNumber(reqNumber)

            If reqNum.Validate Then
                Dim extReq As Dictionary(Of String, String) = GetExternalRequestNotLinked(reqNumber, dbType)
                LinkExternalRecord(extReq, reqNum, rf, useridentification)
            End If
        End Sub

        Public Shared Function GetProperty(ByVal name As String, ByRef fields As Dictionary(Of String, String)) As String
            Dim returnVal As String = String.Empty

            If fields.ContainsKey(name) Then
                fields.TryGetValue(name, returnVal)
            End If

            Return returnVal
        End Function

        Public Shared Function GetExternalRequestNotLinked(ByVal reqNumber As String, ByVal dbType As String) As Dictionary(Of String, String)
            Dim reqNum As New RequestNumber(reqNumber)
            Dim requestProperties As Dictionary(Of String, String) = REMIAppCache.GetExtReqData(reqNum.Number)

            If reqNum.Validate And requestProperties Is Nothing Then
                requestProperties = New Dictionary(Of String, String)
                requestProperties.Add("RequestNumber", reqNumber)
                requestProperties.Add("RequestType", GetConnectName(reqNumber))
                requestProperties.Add("Summary", String.Empty)
                requestProperties.Add("Request Link", String.Empty)

                Try
                    Dim currentUnitNumber As Integer
                    Dim affectsUnits As New List(Of Integer)
                    Dim hasRecords As Boolean = False

                    If (dbType = "Oracle") Then
                        Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(GetConnectString(reqNumber)))
                            myConnection.Open()

                            Using myCommand As New OracleCommand("REMI_HELPER.get_request_information", myConnection)
                                myCommand.CommandType = CommandType.StoredProcedure
                                myCommand.Parameters.Add(New OracleParameter("p_reqnum", OracleType.VarChar)).Value = reqNum.Number
                                myCommand.Parameters.Add(New OracleParameter("C_REF_RET", OracleType.Cursor)).Direction = ParameterDirection.ReturnValue
                                Dim myReader As OracleDataReader = myCommand.ExecuteReader

                                If myReader.HasRows Then
                                    hasRecords = True

                                    While myReader.Read
                                        Select Case myReader.Item(0).ToString.ToLower.Trim
                                            Case "failed unit number"
                                                If Integer.TryParse(myReader.Item(1).ToString.Trim, currentUnitNumber) Then
                                                    affectsUnits.Add(currentUnitNumber)
                                                End If
                                            Case Else
                                                Dim keyName As String = myReader.Item(0).ToString.Trim
                                                Dim propValue As String = myReader.Item(1).ToString.Trim

                                                If Not requestProperties.ContainsKey(keyName) Then
                                                    If (keyName = "Request Link") Then
                                                        requestProperties(keyName) = propValue
                                                    Else
                                                        requestProperties.Add(keyName, propValue)
                                                    End If
                                                Else
                                                    requestProperties(keyName) = propValue
                                                End If
                                        End Select
                                    End While
                                End If
                            End Using
                        End Using
                    ElseIf (dbType = "SQL") Then
                        Using myConnection2 As New SqlConnection(REMIConfiguration.ConnectionStringReq(reqNumber))
                            Using myCommand As New SqlCommand("get_request_information", myConnection2)
                                myCommand.CommandType = CommandType.StoredProcedure
                                myCommand.Parameters.AddWithValue("@ReqNum", reqNum.Number)
                                myConnection2.Open()

                                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                                    If myReader.HasRows Then
                                        hasRecords = True

                                        While myReader.Read
                                            Select Case myReader.Item(0).ToString.ToLower.Trim
                                                Case "failed unit number"
                                                    If Integer.TryParse(myReader.Item(1).ToString.Trim, currentUnitNumber) Then
                                                        affectsUnits.Add(currentUnitNumber)
                                                    End If
                                                Case Else
                                                    Dim keyName As String = myReader.Item(0).ToString.Trim
                                                    Dim propValue As String = myReader.Item(1).ToString.Trim

                                                    If Not requestProperties.ContainsKey(keyName) Then
                                                        If (keyName = "Request Link") Then
                                                            requestProperties(keyName) = propValue
                                                        Else
                                                            requestProperties.Add(keyName, propValue)
                                                        End If
                                                    Else
                                                        requestProperties(keyName) = propValue
                                                    End If
                                            End Select
                                        End While
                                    End If
                                End Using
                            End Using
                        End Using
                    End If

                    If (hasRecords) Then
                        Dim val As String = String.Empty

                        If (requestProperties.TryGetValue("Failure Description", val)) Then
                            Dim summaryString As New System.Text.StringBuilder
                            summaryString.Append("<b>Failure: </b> ")
                            summaryString.Append(requestProperties.Item("Failure Description"))

                            If affectsUnits.Count >= 1 Then
                                summaryString.Append("<br /><b>Affected Units:</b> ")

                                For i As Int32 = 0 To affectsUnits.Count - 1
                                    summaryString.Append(If(i > 0, ", ", String.Empty) + affectsUnits(i).ToString)
                                Next
                            End If

                            summaryString.Append("<br />")

                            If (requestProperties.TryGetValue("Top Level", val)) Then
                                summaryString.Append(String.Format("<b>Top Level:</b> {0}<br />", requestProperties.Item("Top Level")))
                            End If

                            If (requestProperties.TryGetValue("2nd Level", val)) Then
                                summaryString.Append(String.Format("<b>2nd Level:</b> {0}<br />", requestProperties.Item("2nd Level")))
                            End If

                            If (requestProperties.TryGetValue("3rd Level", val)) Then
                                summaryString.Append(String.Format("<b>3rd Level:</b> {0}<br />", requestProperties.Item("3rd Level")))
                            End If

                            requestProperties("Summary") = summaryString.ToString()
                        Else
                            requestProperties("Summary") = String.Empty
                        End If

                        REMIAppCache.SetExtReqData(requestProperties, reqNumber)
                    End If
                Catch ex As Exception
                    Emailer.SendErrorEMail("REMI Error", "Current Request: " + reqNum.Number, REMI.Validation.NotificationType.Errors, ex)
                End Try
            ElseIf requestProperties Is Nothing Then
                requestProperties = New Dictionary(Of String, String)
                requestProperties.Add("RequestNumber", reqNumber)
                requestProperties.Add("RequestType", GetConnectName(reqNumber))
                requestProperties.Add("Summary", String.Empty)
                requestProperties.Add("Request Link", String.Empty)
            End If

            Return requestProperties
        End Function

        Public Shared Function GetRequestsNotInREMI(ByVal searchStr As String) As DataTable
            Dim dtReq As New DataTable("Requests")
            dtReq.Columns.Add("RequestID", System.Type.GetType("System.String"))
            dtReq.Columns.Add("RequestNumber", System.Type.GetType("System.String"))
            dtReq.Columns.Add("STATUS", System.Type.GetType("System.String"))
            dtReq.Columns.Add("PRODUCT", System.Type.GetType("System.String"))
            dtReq.Columns.Add("PRODUCTTYPE", System.Type.GetType("System.String"))
            dtReq.Columns.Add("ACCESSORYGROUPNAME", System.Type.GetType("System.String"))
            dtReq.Columns.Add("TESTCENTER", System.Type.GetType("System.String"))
            dtReq.Columns.Add("DEPARTMENT", System.Type.GetType("System.String"))
            dtReq.Columns.Add("SAMPLESIZE", System.Type.GetType("System.String"))
            dtReq.Columns.Add("Job", System.Type.GetType("System.String"))
            dtReq.Columns.Add("PURPOSE", System.Type.GetType("System.String"))
            dtReq.Columns.Add("CPR", System.Type.GetType("System.String"))
            dtReq.Columns.Add("Report Required By", System.Type.GetType("System.DateTime"))
            dtReq.Columns.Add("PRIORITY", System.Type.GetType("System.String"))
            dtReq.Columns.Add("REQUESTOR", System.Type.GetType("System.String"))
            dtReq.Columns.Add("CRE_DATE", System.Type.GetType("System.DateTime"))

            Dim lastRequestConnectName As String = String.Empty
            Dim requestType = (From r In New REMI.Dal.Entities().Instance().RequestTypes.Include("Lookup") Where r.Lookup.LookupType.Name = "RequestType" Order By r.RequestConnectName Select r).ToList()

            For Each r In requestType
                If (r.RequestConnectName <> lastRequestConnectName) Then

                    lastRequestConnectName = r.RequestConnectName

                    If (r.DBType = "Oracle") Then
                        Using myOracleConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(r.RequestConnectName))
                            myOracleConnection.Open()

                            Using myCommand As New OracleCommand("REMI_HELPER.get_Requests_By_Search", myOracleConnection)
                                myCommand.CommandTimeout = 40
                                myCommand.CommandType = CommandType.StoredProcedure
                                myCommand.Parameters.Add(New OracleParameter("p_search", OracleType.VarChar)).Value = searchStr
                                myCommand.Parameters.Add(New OracleParameter("C_REF_RET", OracleType.Cursor)).Direction = ParameterDirection.ReturnValue
                                Dim myReader As OracleDataReader = myCommand.ExecuteReader
                                Dim dt As New DataTable("Requests")
                                dt.Load(myReader)

                                If (dt.Rows.Count > 0) Then
                                    dtReq.Merge(dt, True)
                                End If
                            End Using
                        End Using
                    ElseIf (r.DBType = "SQL") Then
                        Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringReq(r.RequestConnectName))
                            Using myCommand As New SqlCommand("Req.RequestGet", myConnection)
                                myCommand.CommandType = CommandType.StoredProcedure
                                myCommand.Parameters.AddWithValue("@RequestTypeID", r.RequestTypeID)
                                myCommand.Parameters.AddWithValue("@Department", searchStr)
                                myConnection.Open()
                                Dim dt2 As New DataTable("Requests")
                                Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                                da.Fill(dt2)

                                If (dt2.Rows.Count > 0) Then
                                    dtReq.Merge(dt2, True)
                                End If
                            End Using
                        End Using
                    End If
                End If
            Next

            Return dtReq
        End Function
#End Region

        Private Shared Sub LinkExternalRecord(ByVal extFields As Dictionary(Of String, String), ByVal reqNum As RequestNumber, ByRef rf As RequestFieldsCollection, ByVal useridentification As String)
            Dim isOutOfDate As Boolean = False

            For Each rec In extFields
                If (rf IsNot Nothing) Then
                    For Each r In rf
                        If (r.Name = rec.Key And r.Value <> rec.Value) Then
                            isOutOfDate = True
                            r.Value = rec.Value.Trim()
                        End If
                    Next
                End If
            Next

            If (isOutOfDate) Then
                SaveRequest(GetConnectName(reqNum.Number), rf, useridentification)
            End If
        End Sub

        Public Shared Function SaveRequest(ByVal requestName As String, ByRef request As RequestFieldsCollection, ByVal userIdentification As String) As Boolean
            Dim instance = New REMI.Dal.Entities().Instance()
            Dim reqID As Int32 = 0
            Dim reqNumber As String = request(0).RequestNumber

            Dim req = (From r In instance.Requests Where r.RequestNumber = reqNumber).FirstOrDefault()

            If (req Is Nothing) Then
                Dim rq As New REMI.Entities.Request()
                rq.RequestNumber = reqNumber
                instance.AddToRequests(rq)
                instance.SaveChanges()

                reqID = (From r In instance.Requests Where r.RequestNumber = reqNumber Select r.RequestID).FirstOrDefault()
            Else
                reqID = req.RequestID
            End If

            For Each rec In request
                Dim fieldData = (From fd In instance.ReqFieldDatas Where fd.RequestID = reqID And fd.ReqFieldSetupID = rec.FieldSetupID).FirstOrDefault()

                If (fieldData Is Nothing) Then
                    Dim sfd As New REMI.Entities.ReqFieldData()
                    sfd.ReqFieldSetupID = rec.FieldSetupID
                    sfd.RequestID = reqID
                    sfd.Value = rec.Value
                    sfd.InsertTime = DateTime.Now
                    sfd.LastUser = userIdentification
                    instance.AddToReqFieldDatas(sfd)
                Else
                    fieldData.Value = rec.Value
                    fieldData.InsertTime = DateTime.Now
                    fieldData.LastUser = userIdentification
                End If
            Next

            instance.SaveChanges()

            Return True
        End Function

        Public Shared Function GetRequestFieldSetup(ByVal requestName As String, ByVal includeArchived As Boolean, ByVal requestNumber As String, ByVal user As User) As RequestFieldsCollection
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
                                fieldData = New RequestFieldsCollection()

                                While myReader.Read()
                                    fieldData.Add(FillFieldData(myReader, user))
                                End While
                            End If
                        End Using
                    End Using
                End Using
            End If

            Return fieldData
        End Function

        Private Shared Function FillFieldData(ByVal myDataRecord As IDataRecord, ByVal user As User) As BusinessEntities.RequestFields
            Dim instance = New REMI.Dal.Entities().Instance()
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

            myFields.InternalField = myDataRecord.GetInt32(myDataRecord.GetOrdinal("InternalField"))
            myFields.IsFromExternalSystem = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("IsFromExternalSystem"))
            myFields.IsArchived = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("Archived"))
            myFields.IsRequired = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("IsRequired"))
            myFields.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("Name"))

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("OptionsTypeID")) Then
                myFields.OptionsTypeID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("OptionsTypeID"))
                Dim options As New List(Of String)

                If (myFields.InternalField = 0) Then
                    options.Add("Not Set")
                End If

                options.AddRange((From lo In instance.Lookups Where lo.LookupTypeID = myFields.OptionsTypeID And lo.IsActive = 1 Order By lo.Values Select lo.Values).ToList)

                myFields.OptionsType = options
            Else
                myFields.OptionsTypeID = 0
                myFields.OptionsType = New List(Of String)()
            End If

            myFields.RequestID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("RequestID"))
            myFields.RequestNumber = myDataRecord.GetString(myDataRecord.GetOrdinal("RequestNumber"))
            myFields.NewRequest = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("NewRequest"))
            myFields.Category = myDataRecord.GetString(myDataRecord.GetOrdinal("Category"))

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Value")) Then
                myFields.Value = myDataRecord.GetString(myDataRecord.GetOrdinal("Value"))
            Else
                myFields.Value = String.Empty
            End If

            If (myFields.OptionsTypeID = 0 And Not String.IsNullOrEmpty(myFields.IntField)) Then
                Select Case myFields.IntField
                    Case "ProductGroup"
                        myFields.OptionsType = (From p In instance.Products Where p.IsActive = True Order By p.ProductGroupName Select p.ProductGroupName).ToList
                    Case "RequestedTest"
                        myFields.OptionsType = (From j In JobDB.GetJobListDT(user).AsEnumerable() Select j.Name).ToList()
                End Select
            End If

            Return myFields
        End Function
    End Class
End Namespace