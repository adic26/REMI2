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

        Public Shared Function GetRequestSetupInfo(ByVal productID As Int32, ByVal jobID As Int32, ByVal batchID As Int32, ByVal testStageType As Int32, ByVal blankSelected As Int32, ByVal userID As Int32, ByVal RequestTypeID As Int32) As DataTable
            Dim dt As New DataTable("RequestSetupInfo")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Req.GetRequestSetupInfo", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ProductID", productID)
                    myCommand.Parameters.AddWithValue("@JobID", jobID)
                    myCommand.Parameters.AddWithValue("@BatchID", batchID)
                    myCommand.Parameters.AddWithValue("@TestStageType", testStageType)
                    myCommand.Parameters.AddWithValue("@BlankSelected", blankSelected)
                    myCommand.Parameters.AddWithValue("@UserID", userID)
                    myCommand.Parameters.AddWithValue("@RequestTypeID", RequestTypeID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "RequestSetupInfo"
                End Using
            End Using

            Return dt
        End Function

        Public Shared Function GetRequestAuditLogs(ByVal requestNumber As String) As DataTable
            Dim dt As New DataTable("RequestDataAudit")
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("Req.RequestDataAudit", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@RequestNumber", requestNumber)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "RequestDataAudit"
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

        Public Shared Function GetRequest(ByVal reqNumber As String, ByVal user As User, ByVal sqlConnection As SqlConnection) As RequestFieldsCollection
            Dim reqNum As New RequestNumber(reqNumber)

            If (reqNum.Validate()) Then
                Dim requestType = (From r In New REMI.Dal.Entities().Instance().RequestTypes.Include("Lookup") Where r.Lookup.LookupType.Name = "RequestType" And r.Lookup.Values = reqNum.Type Select r).FirstOrDefault()

                Dim rf As RequestFieldsCollection = REMIAppCache.GetReqData(reqNum.Number)

                If (rf Is Nothing) Then
                    rf = GetRequestFieldSetup(requestType.Lookup.Values, False, reqNum.Number, user, sqlConnection)

                    If (requestType.IsExternal) Then
                        If (rf.Count > 0) Then
                            LinkExternalRequest(reqNumber, rf, user.UserName, requestType.DBType)
                        End If
                    End If

                    REMIAppCache.SetReqData(rf, reqNum.Number)
                End If

                Return rf
            End If

            Return Nothing
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
                                    Array.ForEach(dt2.AsEnumerable().ToArray(), Sub(row) row("RequestID") = String.Format("{0}{1}", Core.REMIConfiguration.RequestGoLink, row("RequestID")))
                                    dtReq.Merge(dt2, True)
                                End If
                            End Using
                        End Using
                    End If
                End If
            Next

            Return dtReq
        End Function

        Public Shared Function GetRequestsForDashBoard(ByVal searchStr As String) As DataTable
            Dim dtReq As New DataTable("RequestsDashboard")
            dtReq.Columns.Add("RequestNumber", System.Type.GetType("System.String"))
            dtReq.Columns.Add("RequestedTest", System.Type.GetType("System.String"))
            dtReq.Columns.Add("SAMPLESIZE", System.Type.GetType("System.String"))
            dtReq.Columns.Add("PRODUCT", System.Type.GetType("System.String"))
            dtReq.Columns.Add("PRODUCTTYPE", System.Type.GetType("System.String"))
            dtReq.Columns.Add("ACCESSORYGROUPNAME", System.Type.GetType("System.String"))
            dtReq.Columns.Add("STATUS", System.Type.GetType("System.String"))
            dtReq.Columns.Add("PURPOSE", System.Type.GetType("System.String"))
            dtReq.Columns.Add("ExecutiveSummary", System.Type.GetType("System.String"))
            dtReq.Columns.Add("CPR", System.Type.GetType("System.String"))

            Dim lastRequestConnectName As String = String.Empty
            Dim requestType = (From r In New REMI.Dal.Entities().Instance().RequestTypes.Include("Lookup") Where r.Lookup.LookupType.Name = "RequestType" Order By r.RequestConnectName Select r).ToList()

            For Each r In requestType
                If (r.RequestConnectName <> lastRequestConnectName) Then

                    lastRequestConnectName = r.RequestConnectName

                    If (r.DBType = "Oracle") Then
                        Using myOracleConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq(r.RequestConnectName))
                            myOracleConnection.Open()

                            Using myCommand As New OracleCommand("REMI_HELPER.get_Requests_For_Dashboard", myOracleConnection)
                                myCommand.CommandTimeout = 40
                                myCommand.CommandType = CommandType.StoredProcedure
                                myCommand.Parameters.Add(New OracleParameter("p_search", OracleType.VarChar)).Value = searchStr
                                myCommand.Parameters.Add(New OracleParameter("C_REF_RET", OracleType.Cursor)).Direction = ParameterDirection.ReturnValue
                                Dim myReader As OracleDataReader = myCommand.ExecuteReader
                                Dim dt As New DataTable("RequestsDashboard")
                                dt.Load(myReader)

                                If (dt.Rows.Count > 0) Then
                                    dtReq.Merge(dt, True)
                                End If
                            End Using
                        End Using
                    ElseIf (r.DBType = "SQL") Then
                        Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringReq(r.RequestConnectName))
                            Using myCommand As New SqlCommand("Req.RequestForDashboard", myConnection)
                                myCommand.CommandType = CommandType.StoredProcedure
                                myCommand.Parameters.AddWithValue("@RequestTypeID", r.RequestTypeID)
                                myCommand.Parameters.AddWithValue("@SearchStr", searchStr)
                                myConnection.Open()
                                Dim dt2 As New DataTable("RequestsDashboard")
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
                If (rec.MaxDisplayNum > 1) Then
                    For Each sib As Sibling In rec.Sibling
                        Dim fieldDataSib = (From fd In instance.ReqFieldDatas Where fd.RequestID = reqID And fd.ReqFieldSetupID = rec.FieldSetupID And (fd.InstanceID = sib.ID Or fd.InstanceID Is Nothing)).FirstOrDefault()

                        If (fieldDataSib Is Nothing And Not String.IsNullOrEmpty(sib.Value)) Then
                            fieldDataSib = New REMI.Entities.ReqFieldData()
                            fieldDataSib.ReqFieldSetupID = rec.FieldSetupID
                            fieldDataSib.RequestID = reqID
                            fieldDataSib.InstanceID = sib.ID
                            fieldDataSib.Value = If(sib.Value Is Nothing, String.Empty, sib.Value)
                            fieldDataSib.InsertTime = DateTime.Now
                            fieldDataSib.LastUser = userIdentification
                            instance.AddToReqFieldDatas(fieldDataSib)
                        ElseIf (fieldDataSib IsNot Nothing And String.IsNullOrEmpty(sib.Value)) Then
                            instance.DeleteObject(fieldDataSib)
                        ElseIf (fieldDataSib IsNot Nothing) Then
                            fieldDataSib.Value = If(sib.Value Is Nothing, String.Empty, sib.Value)
                            fieldDataSib.InsertTime = DateTime.Now
                            fieldDataSib.LastUser = userIdentification
                            fieldDataSib.InstanceID = sib.ID
                        End If

                        instance.SaveChanges()
                    Next
                Else
                    Dim fieldData = (From fd In instance.ReqFieldDatas Where fd.RequestID = reqID And fd.ReqFieldSetupID = rec.FieldSetupID).FirstOrDefault()

                    If (fieldData Is Nothing) Then
                        fieldData = New REMI.Entities.ReqFieldData()
                        fieldData.ReqFieldSetupID = rec.FieldSetupID
                        fieldData.RequestID = reqID
                        fieldData.InstanceID = 1
                        fieldData.Value = If(rec.Value Is Nothing, String.Empty, rec.Value)
                        fieldData.InsertTime = DateTime.Now
                        fieldData.LastUser = userIdentification
                        instance.AddToReqFieldDatas(fieldData)
                    Else
                        fieldData.Value = If(rec.Value Is Nothing, String.Empty, rec.Value)
                        fieldData.InsertTime = DateTime.Now
                        fieldData.LastUser = userIdentification
                        fieldData.InstanceID = 1
                    End If
                    instance.SaveChanges()
                End If
            Next

            Return True
        End Function

        Public Shared Function GetRequestFieldSetup(ByVal requestName As String, ByVal includeArchived As Boolean, ByVal requestNumber As String, ByVal user As User, ByVal myConnection As SqlConnection) As RequestFieldsCollection
            Dim rtID As Int32
            Dim fieldData As RequestFieldsCollection = Nothing

            rtID = (From fs In New REMI.Dal.Entities().Instance.ReqFieldSetups Where fs.RequestType.Lookup.Values = requestName Select fs.RequestTypeID).FirstOrDefault()

            If (rtID > 0) Then
                If (myConnection Is Nothing) Then
                    myConnection = New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                End If

                Using myCommand As New SqlCommand("Req.RequestFieldSetup", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@RequestTypeID", rtID)

                    If (includeArchived) Then
                        myCommand.Parameters.AddWithValue("@IncludeArchived", True)
                    Else
                        myCommand.Parameters.AddWithValue("@IncludeArchived", False)
                    End If

                    If (requestNumber.Trim().Length > 0) Then
                        myCommand.Parameters.AddWithValue("@RequestNumber", requestNumber)
                    End If

                    If myConnection.State <> ConnectionState.Open Then
                        myConnection.Open()
                    End If

                    Dim ds As DataSet = New DataSet()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        fieldData = New RequestFieldsCollection()

                        ds.Load(myReader, LoadOption.OverwriteChanges, New String() {"Sibling", "Fields"})

                        For Each dr As DataRow In ds.Tables("Fields").Rows
                            fieldData.Add(FillFieldData(dr, user, ds.Tables("Sibling")))
                        Next
                    End Using
                End Using
            End If

            Return fieldData
        End Function

        Private Shared Function FillFieldData(ByVal myDataRecord As DataRow, ByVal user As User, ByVal siblings As DataTable) As BusinessEntities.RequestFields
            Dim instance = New REMI.Dal.Entities().Instance()
            Dim myFields As RequestFields = New BusinessEntities.RequestFields()

            myFields.FieldSetupID = myDataRecord.Field(Of Int32)("ReqFieldSetupID")
            myFields.RequestType = myDataRecord.Field(Of String)("RequestType")
            myFields.RequestTypeID = myDataRecord.Field(Of Int32)("RequestTypeID")

            If myDataRecord.Item("Description") IsNot DBNull.Value Then
                myFields.Description = myDataRecord.Field(Of String)("Description")
            Else
                myFields.Description = String.Empty
            End If

            myFields.DisplayOrder = myDataRecord.Field(Of Int32)("DisplayOrder")
            myFields.ColumnOrder = myDataRecord.Field(Of Int32)("ColumnOrder")
            myFields.FieldType = myDataRecord.Field(Of String)("FieldType")
            myFields.FieldTypeID = myDataRecord.Field(Of Int32)("FieldTypeID")

            If myDataRecord.Item("FieldValidationID") IsNot DBNull.Value Then
                myFields.FieldValidation = myDataRecord.Field(Of String)("ValidationType")
                myFields.FieldValidationID = myDataRecord.Field(Of Int32)("FieldValidationID")
            Else
                myFields.FieldValidation = String.Empty
                myFields.FieldValidationID = 0
            End If

            If myDataRecord.Item("ExtField") IsNot DBNull.Value Then
                myFields.ExtField = myDataRecord.Field(Of String)("ExtField")
            Else
                myFields.ExtField = String.Empty
            End If

            If myDataRecord.Item("IntField") IsNot DBNull.Value Then
                myFields.IntField = myDataRecord.Field(Of String)("IntField")
            Else
                myFields.IntField = String.Empty
            End If

            myFields.InternalField = myDataRecord.Field(Of Int32)("InternalField")
            myFields.IsFromExternalSystem = myDataRecord.Field(Of Boolean)("IsFromExternalSystem")
            myFields.IsArchived = myDataRecord.Field(Of Boolean)("Archived")
            myFields.IsRequired = myDataRecord.Field(Of Boolean)("IsRequired")
            myFields.Name = myDataRecord.Field(Of String)("Name")

            If myDataRecord.Item("OptionsTypeID") IsNot DBNull.Value Then
                myFields.OptionsTypeID = myDataRecord.Field(Of Int32)("OptionsTypeID")
                Dim options As New List(Of String)
                Dim filteredOptions As New List(Of String)
                Dim onlylh As List(Of String) = (From l In instance.LookupsHierarchies.Include("Lookup1") Where l.RequestTypeID = myFields.RequestTypeID And l.ChildLookupTypeID = myFields.OptionsTypeID And l.ParentLookupTypeID = myFields.OptionsTypeID Select l.Lookup1.Values).ToList()

                options.AddRange((From lo In instance.Lookups Where lo.LookupTypeID = myFields.OptionsTypeID And lo.IsActive = 1 _
                     Order By lo.Values Select lo.Values).ToList)

                If (onlylh.Count > 0) Then
                    If (myFields.InternalField = 0 Or Not myFields.IsRequired) Then
                        filteredOptions.Add("NotSet")
                    End If

                    For Each rec In options
                        If (onlylh.Contains(rec)) Then
                            filteredOptions.Add(rec)
                        End If
                    Next
                Else
                    If (myFields.InternalField = 0 Or Not myFields.IsRequired) Then
                        filteredOptions.Add("NotSet")
                    End If

                    filteredOptions.AddRange(options)
                End If

                myFields.OptionsTypeName = (From lo In instance.Lookups Where lo.LookupTypeID = myFields.OptionsTypeID Select lo.LookupType.Name).FirstOrDefault()
                myFields.OptionsType = filteredOptions

                If myDataRecord.Field(Of String)("DefaultValue") IsNot Nothing Then
                    myFields.DefaultValue = myDataRecord.Field(Of String)("DefaultValue")
                Else
                    myFields.DefaultValue = String.Empty
                End If

                Dim lookups = (From lh In instance.LookupsHierarchies.Include("Lookup").Include("Lookup1").Include("LookupType").Include("LookupType1").Include("RequestType") Where lh.ChildLookupTypeID = myFields.OptionsTypeID And lh.ParentLookupTypeID <> myFields.OptionsTypeID And lh.RequestTypeID = myFields.RequestTypeID _
                        Select New With {lh.RequestTypeID, lh.ParentLookupID, lh.ChildLookupID, lh.ParentLookupTypeID, lh.ChildLookupTypeID, .ParentLookup = lh.Lookup.Values, .ChildLookup = lh.Lookup1.Values, .ParentLookupType = lh.LookupType.Name, .ChildLookupType = lh.LookupType1.Name}).ToList()

                Dim rfob As New List(Of RequestFieldObjectHeirarchy)

                For Each rec In lookups
                    rfob.Add(New RequestFieldObjectHeirarchy(rec.RequestTypeID, rec.ParentLookupID, rec.ChildLookupID, rec.ParentLookupTypeID, rec.ChildLookupTypeID, rec.ParentLookup, rec.ChildLookup, rec.ParentLookupType, rec.ChildLookupType))
                Next

                myFields.CustomLookupHierarchy = rfob
            Else
                myFields.OptionsTypeID = 0
                myFields.OptionsType = New List(Of String)()
            End If

            myFields.RequestID = myDataRecord.Field(Of Int32)("RequestID")
            myFields.RequestNumber = myDataRecord.Field(Of String)("RequestNumber")
            myFields.NewRequest = myDataRecord.Field(Of Boolean)("NewRequest")
            myFields.Category = myDataRecord.Field(Of String)("Category")

            If myDataRecord.Item("Value") IsNot DBNull.Value Then
                If (Not myDataRecord.Field(Of String)("Value").Contains(Core.REMIConfiguration.RequestGoLink) And myFields.IntField = "RequestLink") Then
                    myFields.Value = String.Format("{0}{1}", Core.REMIConfiguration.RequestGoLink, myFields.RequestNumber)
                Else
                    myFields.Value = myDataRecord.Field(Of String)("Value")
                End If
            Else
                myFields.Value = String.Empty
            End If

            If (myFields.IntField = "Requestor" And myFields.Value = String.Empty) Then
                myFields.Value = user.FullName
            End If

            If myDataRecord.Item("ParentReqFieldSetupID") IsNot DBNull.Value Then
                myFields.ParentFieldSetupID = myDataRecord.Field(Of Int32)("ParentReqFieldSetupID")

                If myDataRecord.Field(Of String)("ParentFieldSetupName") IsNot Nothing Then
                    myFields.ParentFieldSetupName = myDataRecord.Field(Of String)("ParentFieldSetupName")
                End If
            End If

            myFields.HasIntegration = myDataRecord.Field(Of Boolean)("HasIntegration")
            myFields.ReqFieldDataID = myDataRecord.Field(Of Int32)("ReqFieldDataID")
            myFields.HasDistribution = myDataRecord.Field(Of Boolean)("HasDistribution")
            myFields.DefaultDisplayNum = myDataRecord.Field(Of Int32)("DefaultDisplayNum")
            myFields.MaxDisplayNum = myDataRecord.Field(Of Int32)("MaxDisplayNum")

            If (myFields.MaxDisplayNum > 1) Then
                Dim sib As New List(Of Sibling)
                For i As Int32 = 1 To myFields.MaxDisplayNum
                    Dim val As String = (From s As DataRow In siblings.AsEnumerable Where s.Field(Of Int32)("InstanceID") = i And s.Field(Of Int32)("ReqFieldSetupID") = myFields.FieldSetupID Select s.Field(Of String)("Value")).FirstOrDefault()
                    sib.Add(New Sibling(i, myFields.FieldSetupID, val))
                Next

                myFields.Sibling = sib
            Else
                myFields.Sibling = New List(Of Sibling)
            End If

            If (myFields.OptionsTypeID = 0 And Not String.IsNullOrEmpty(myFields.IntField)) Then
                Select Case myFields.IntField
                    Case "RequestedTest"
                        myFields.OptionsType = (From j In JobDB.GetJobListDT(user.ID, myFields.RequestTypeID, 0).AsEnumerable() Select j.Name).ToList()
                End Select
            End If

            Return myFields
        End Function
    End Class
End Namespace