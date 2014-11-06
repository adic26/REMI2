Imports System
Imports System.Data
Imports System.Data.OracleClient
Imports System.Data.SqlClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports System.Configuration
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Core
Imports System.Text

Namespace REMI.Dal
    ''' <summary>
    ''' The ProductGroupDB class is responsible for interacting with the database to retrieve and store information 
    ''' about ProductGroup objects.
    ''' </summary>
    Public Class ProductGroupDB
#Region "Public Methods"

        Public Shared Function RetrieveInventoryReport(ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal filterByQRANumber As Boolean, ByVal geoLocation As Int32) As InventoryReportData
            If startDate.Year < 1990 Then
                Throw New ArgumentException("The start date is too early.")
            End If
            If endDate.Year < 1990 Then
                Throw New ArgumentException("The end date is too early.")
            End If
            If endDate < startDate Then
                Throw New ArgumentException("The startdate is later than the end date.")
            End If
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                myConnection.Open()
                'first get the inventory report. This is populated with some calculations in a sql procedure. it also fills in the
                'product distribution table.
                Dim ird As InventoryReportData = RetrieveInventoryReport(startDate, endDate, filterByQRANumber, geoLocation, myConnection)

                ird.ProductLocationReport.Columns.Add("Product")
                Dim totals As Dictionary(Of String, Integer) = ProductGroupDB.RetrieveInventoryReportForProductGroup(startDate, endDate, filterByQRANumber, geoLocation, 0, myConnection)
                For Each k In totals
                    If Not k.Key.Equals("Total") Then 'we want total to be the last column added.
                        ird.ProductLocationReport.Columns.Add(k.Key)
                    End If
                Next
                'now add it
                ird.ProductLocationReport.Columns.Add("Total")

                Dim currentProductData As Dictionary(Of String, Integer)
                Dim r As DataRow
                For Each p As DataRow In GetList().Rows
                    r = ird.ProductLocationReport.NewRow
                    r("Product") = p.Item("ProductGroupName").ToString()
                    Dim productID As Int32
                    Int32.TryParse(p.Item("ID").ToString(), productID)
                    currentProductData = RetrieveInventoryReportForProductGroup(startDate, endDate, filterByQRANumber, geoLocation, productID, myConnection)
                    'only add this product as a row if there are some units within this timeframe
                    If currentProductData.Values.Sum > 0 Then
                        For Each k In currentProductData
                            r(k.Key) = k.Value
                        Next
                        ird.ProductLocationReport.Rows.Add(r)
                    End If
                Next
                r = ird.ProductLocationReport.NewRow
                r("Product") = "Total"
                For Each k In totals
                    r(k.Key) = k.Value
                Next
                ird.ProductLocationReport.Rows.Add(r)
                Return ird
            End Using
        End Function
        ''' <summary>
        ''' Retrieves a list of locations and the product unit count in that location
        ''' </summary>
        ''' <param name="startDate"></param>
        ''' <param name="endDate"></param>
        ''' <param name="filterByQRANumber"></param>
        ''' <param name="geoLocation"></param>
        ''' <param name="productGroupName"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Private Shared Function RetrieveInventoryReportForProductGroup(ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal filterByQRANumber As Boolean, ByVal geoLocation As Int32, ByVal productID As Int32, ByVal myConnection As SqlConnection) As Dictionary(Of String, Integer)

            Dim tmpList As New Dictionary(Of String, Integer)

            Using myCommand As New SqlCommand("remispCountUnitsInLocation", myConnection)
                myCommand.CommandType = CommandType.StoredProcedure
                myCommand.Parameters.AddWithValue("@startDate", startDate)
                myCommand.Parameters.AddWithValue("@endDate", endDate)
                myCommand.Parameters.AddWithValue("@filterbasedonqranumber", filterByQRANumber)

                If (geoLocation > 0) Then
                    myCommand.Parameters.AddWithValue("@geographicallocation", geoLocation)
                Else
                    myCommand.Parameters.AddWithValue("@geographicallocation", 0)
                End If
                If productID > 0 Then
                    myCommand.Parameters.AddWithValue("@productID", productID)
                Else
                    myCommand.Parameters.AddWithValue("@productID", 0)
                End If

                Using myReader As SqlDataReader = myCommand.ExecuteReader()

                    If myReader.HasRows Then
                        While myReader.Read()
                            tmpList.Add(myReader.GetString(0), myReader.GetInt32(1))
                        End While
                    End If
                End Using
            End Using
            Return tmpList
        End Function

        Private Shared Function RetrieveInventoryReport(ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal filterByQRANumber As Boolean, ByVal geoLocation As Int32, ByVal myConnection As SqlConnection) As InventoryReportData
            Dim tmpData As New InventoryReportData

            Using myCommand As New SqlCommand("remispInventoryReport", myConnection)
                myCommand.CommandType = CommandType.StoredProcedure
                myCommand.Parameters.AddWithValue("@startDate", startDate)
                myCommand.Parameters.AddWithValue("@endDate", endDate)
                myCommand.Parameters.AddWithValue("@filterbasedonqranumber", filterByQRANumber)

                If geoLocation > 0 Then
                    myCommand.Parameters.AddWithValue("@geographicallocation", geoLocation)
                Else
                    myCommand.Parameters.AddWithValue("@geographicallocation", 0)
                End If

                Using myReader As SqlDataReader = myCommand.ExecuteReader()

                    If myReader.HasRows Then
                        While myReader.Read()
                            If Not myReader.IsDBNull(0) Then
                                tmpData.TotalBatches = myReader.GetInt32(0)
                            End If
                            If Not myReader.IsDBNull(1) Then
                                tmpData.TotalUnits = myReader.GetInt32(1)
                            End If
                            If Not myReader.IsDBNull(2) Then
                                tmpData.AverageUnitsInBatch = myReader.GetInt32(2)
                            End If
                        End While
                    End If
                    myReader.NextResult()
                    If myReader.HasRows Then
                        While myReader.Read()
                            If Not (myReader.IsDBNull(0) OrElse myReader.IsDBNull(1) OrElse myReader.IsDBNull(2)) Then
                                tmpData.AddRowToProductDistribution(myReader.GetString(0), myReader.GetInt32(1), myReader.GetInt32(2))
                            End If
                        End While
                    End If
                End Using
            End Using

            Return tmpData
        End Function

        ''' <summary>
        ''' Returns a list of the product groups that a user is associated with.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetUserProductGroupList(ByVal userID As Int32) As DataTable
            Dim tempList As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispProductManagersSelectList", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@UserID", userID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(tempList)
                    tempList.TableName = "ProductGroups"
                End Using
            End Using
            Return tempList
        End Function

        Public Shared Function GetProductTestReady(ByVal ProductID As Int32, ByVal MNum As String) As DataTable
            Dim tempList As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispProductTestReady", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ProductID", ProductID)
                    myCommand.Parameters.AddWithValue("@MNum", MNum)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(tempList)
                    tempList.TableName = "ProductTestReady"
                End Using
            End Using
            Return tempList
        End Function

        ''' <summary> 
        ''' Returns a list with ProductGroup objects. 
        ''' </summary> 
        ''' <returns> 
        ''' A ProductGroupCollection. 
        ''' </returns> 
        Public Shared Function GetList(Optional ByVal ByPassProduct As Boolean = True, Optional ByVal userID As Int32 = -1, Optional ByVal showArchived As Boolean = False) As DataTable
            Dim tempList As New DataTable

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetProducts", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure

                    If (ByPassProduct) Then
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 0)
                    End If

                    myCommand.Parameters.AddWithValue("@UserID", userID)

                    If (showArchived) Then
                        myCommand.Parameters.AddWithValue("@ShowArchived", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ShowArchived", 0)
                    End If

                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(tempList)
                    tempList.TableName = "Products"
                End Using
            End Using
            Return tempList
        End Function

        Public Shared Function GetOracleList() As List(Of String) 'REMITIMEDSERVICE
            Dim tempList As New List(Of String)
            Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq("TRSDBConnectionString"))

                Using myCommand As New OracleCommand("REMI_HELPER.get_product_groups", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    Dim pOut As New OracleParameter
                    pOut.Direction = ParameterDirection.ReturnValue
                    pOut.OracleType = OracleType.Cursor
                    pOut.ParameterName = "C_REF_RET"
                    myCommand.Parameters.Add(pOut)
                    myConnection.Open()
                    Using myReader As OracleDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            While myReader.Read()
                                If Not tempList.Contains(myReader.GetValue(0).ToString) Then
                                    tempList.Add(myReader.GetValue(0).ToString)
                                End If
                            End While
                        End If

                    End Using
                End Using
            End Using
            Return tempList
        End Function

        Public Shared Function GetTestCountByType(ByVal startDate As Date, ByVal endDate As Date, ByVal reportBasedOn As Int32, ByVal testLocationID As Int32, ByVal ByPassProduct As Boolean, ByVal userID As Int32) As DataSet
            Dim ds As New DataSet
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("RemispGetTestCountByType", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@startDate", startDate)
                    myCommand.Parameters.AddWithValue("@endDate", endDate)
                    myCommand.Parameters.AddWithValue("@reportBasedOn", reportBasedOn)
                    myCommand.Parameters.AddWithValue("@GeoLocationID", testLocationID)

                    If (ByPassProduct) Then
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 0)
                    End If

                    myCommand.Parameters.AddWithValue("@UserID", userID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(ds)
                End Using
            End Using
            Return ds
        End Function

        Public Shared Function GetEnvironmentalReportDT(ByVal startDate As Date, ByVal endDate As Date, ByVal reportBasedOn As Int32, ByVal testLocationID As Int32, ByVal ByPassProduct As Boolean, ByVal userID As Int32, ByVal newWay As Int32) As DataTable
            Dim dt As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispEnvironmentalReport", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.CommandTimeout = 120
                    myCommand.Parameters.AddWithValue("@startDate", startDate)
                    myCommand.Parameters.AddWithValue("@endDate", endDate)
                    myCommand.Parameters.AddWithValue("@reportBasedOn", reportBasedOn)
                    myCommand.Parameters.AddWithValue("@testLocationID", testLocationID)

                    If (ByPassProduct) Then
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 0)
                    End If

                    myCommand.Parameters.AddWithValue("@UserID", userID)
                    myCommand.Parameters.AddWithValue("@NewWay", newWay)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                End Using
            End Using
            Return dt
        End Function

        ''' <summary>
        ''' Returns a data table containing a report on each product
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetEnvironmentalReport(ByVal startDate As Date, ByVal endDate As Date, ByVal reportBasedOn As Int32, ByVal testLocationID As Int32, ByVal ByPassProduct As Boolean, ByVal userID As Int32, ByVal newWay As Int32) As Dictionary(Of String, Dictionary(Of String, Integer))
            Dim tmpList As New Dictionary(Of String, Dictionary(Of String, Integer))

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispEnvironmentalReport", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.CommandTimeout = 120
                    myCommand.Parameters.AddWithValue("@startDate", startDate)
                    myCommand.Parameters.AddWithValue("@endDate", endDate)
                    myCommand.Parameters.AddWithValue("@reportBasedOn", reportBasedOn)
                    myCommand.Parameters.AddWithValue("@testLocationID", testLocationID)

                    If (ByPassProduct) Then
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 1)
                    Else
                        myCommand.Parameters.AddWithValue("@ByPassProductCheck", 0)
                    End If

                    myCommand.Parameters.AddWithValue("@UserID", userID)
                    myCommand.Parameters.AddWithValue("@NewWay", newWay)
                    myConnection.Open()
                    Dim anotherResult As Boolean = True

                    Using myReader As SqlDataReader = myCommand.ExecuteReader
                        Do While anotherResult
                            If myReader.HasRows Then
                                Dim s As String = myReader.GetSchemaTable().Rows(0).Item(0).ToString
                                Dim d As New Dictionary(Of String, Integer)
                                While myReader.Read()
                                    d.Add(myReader.GetString(1), myReader.GetInt32(0))
                                End While
                                tmpList.Add(s, d)

                            End If
                            anotherResult = myReader.NextResult()
                        Loop
                    End Using
                End Using
            End Using
            Return tmpList
        End Function

        ''' <summary>Saves a ProductGroup/User association in the database.</summary> 
        ''' <returns>Returns true when the object was saved successfully, or false otherwise.</returns> 
        Public Shared Function SaveUserAssociation(ByVal productID As Int32, ByVal userNameToAdd As String, ByVal currentUserName As String) As Boolean

            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispProductManagersAssignUser", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ProductID", productID)
                    myCommand.Parameters.AddWithValue("@UserName", userNameToAdd)
                    myCommand.Parameters.AddWithValue("@LastUser", currentUserName)
                    myConnection.Open()
                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()
                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException(String.Format("There was an error saving the association of user:{0} to the productID: {1}.", userNameToAdd, productID))
                    End If
                End Using

            End Using
            Return True
        End Function


        Public Shared Function UpdateProduct(ByVal productGroupName As String, ByVal isActive As Int32, ByVal productID As Int32, ByVal QAP As String, ByVal tsdContact As String) As Boolean 'We are passing in productGroupName because the webservice will insert a missing one
            Dim Result As Integer = 0

            If (QAP Is Nothing) Then
                QAP = String.Empty
            End If

            If (tsdContact Is Nothing) Then
                tsdContact = String.Empty
            End If

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispSaveProduct", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ProductGroupName", productGroupName)
                    myCommand.Parameters.AddWithValue("@isActive", isActive)
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myCommand.Parameters.AddWithValue("@QAP", QAP)
                    myCommand.Parameters.AddWithValue("@TSDContact", tsdContact)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        ''' <summary>Deletes a ProductGroup/User association from the database.</summary> 
        ''' <param name="ProductGroupName">The Name of the ProductGroup. </param>
        ''' <returns>Returns <c>true</c> when the object was deleted successfully, or <c>false</c> otherwise.</returns> 
        Public Shared Function Delete(ByVal productID As Int32, ByVal userIDToRemove As Int32, ByVal userID As Int32) As Boolean
            Dim Result As Integer = 0
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispProductManagersDeleteSingleItem", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ProductID", productID)
                    myCommand.Parameters.AddWithValue("@UserIDToRemove", userIDToRemove)
                    myCommand.Parameters.AddWithValue("@UserID", userID)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using

            End Using
            Return CBool(Result)
        End Function

        ''' <summary>Saves a product setting in the database.</summary> 
        Public Shared Function SaveProductSetting(ByVal productID As Int32, ByVal keyName As String, ByVal valueText As String, ByVal defaultValue As String, ByVal userName As String) As Boolean

            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispProductSettingsInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myCommand.Parameters.AddWithValue("@keyname", keyName)
                    myCommand.Parameters.AddWithValue("@defaultValue", defaultValue)
                    If valueText IsNot Nothing AndAlso Not String.IsNullOrEmpty(valueText.Trim) Then
                        myCommand.Parameters.AddWithValue("@Valuetext", valueText)
                    End If
                    myCommand.Parameters.AddWithValue("@LastUser", userName)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()

                End Using

            End Using
            Return True
        End Function

        ''' <summary>Retrieves a list of product settings in the database.</summary> 
        Public Shared Function GetProductSettings(ByVal productID As Int32) As List(Of ProductSetting)
            Dim tempList As New List(Of ProductSetting)
            Dim tmpValue As ProductSetting
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispProductSettingsSelectListForProduct", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            While myReader.Read()

                                tmpValue = New ProductSetting()
                                tmpValue.KeyName = myReader.GetString(myReader.GetOrdinal("keyname"))
                                tmpValue.ValueText = myReader.GetString(myReader.GetOrdinal("valueText"))
                                tmpValue.DefaultValue = myReader.GetString(myReader.GetOrdinal("defaultValue"))

                                tempList.Add(tmpValue)
                            End While
                        End If

                    End Using
                End Using
            End Using
            Return tempList

        End Function

        Public Shared Function GetProductIDByName(ByVal productGroupName As String) As Int32
            Dim returnVal As Int32 = 0

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetProductIDByName", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productGroupName", productGroupName)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            While myReader.Read()
                                If (Not myReader.IsDBNull(myReader.GetOrdinal("ID"))) Then
                                    returnVal = myReader.GetInt32(myReader.GetOrdinal("ID"))
                                End If
                            End While
                        End If
                    End Using
                End Using
            End Using
            Return returnVal
        End Function

        Public Shared Function GetProductNameByID(ByVal productID As Int32) As String
            Dim returnVal As String = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetProductNameByID", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            While myReader.Read()
                                If (Not myReader.IsDBNull(myReader.GetOrdinal("ProductGroupName"))) Then
                                    returnVal = myReader.GetString(myReader.GetOrdinal("ProductGroupName"))
                                End If
                            End While
                        End If

                    End Using
                End Using
            End Using
            Return returnVal
        End Function

        ''' <summary>Retrieves a single product setting from the database.</summary> 
        Public Shared Function GetProductSetting(ByVal ProductID As Int32, ByVal keyName As String) As String
            Dim returnVal As String = Nothing

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispProductSettingsSelectSingleValue", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ProductID", ProductID)
                    myCommand.Parameters.AddWithValue("@keyname", keyName)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            While myReader.Read()
                                If (Not myReader.IsDBNull(myReader.GetOrdinal("valuetext"))) Then
                                    returnVal = myReader.GetString(myReader.GetOrdinal("valuetext"))
                                End If
                            End While
                        End If

                    End Using
                End Using
            End Using
            Return returnVal

        End Function

        Public Shared Function DeleteProductSetting(ByVal productID As Int32, ByVal keyname As String, ByVal username As String) As Boolean
            Dim Result As Integer = 0
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispProductSettingsDeleteSetting", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myCommand.Parameters.AddWithValue("@keyname", keyname)
                    myCommand.Parameters.AddWithValue("@UserName", username)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using

            End Using
            Return CBool(Result)
        End Function

        Public Shared Function GetProductConfigurationXML(ByVal pcUID As Int32) As XDocument
            Dim xml As XDocument
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispProductGroupConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@PCUID", pcUID)
                    myConnection.Open()

                    Dim ds As New DataSet
                    Dim DA As New SqlDataAdapter(myCommand)
                    DA.Fill(ds)

                    Dim obj_ParentClmn, obj_ChildClmn As DataColumn

                    For Each table As DataTable In ds.Tables
                        obj_ParentClmn = table.Columns("ID")
                        obj_ChildClmn = table.Columns("ParentID")

                        ds.Relations.Add(table.TableName.ToString(), obj_ParentClmn, obj_ChildClmn)
                        ds.Relations(table.TableName).Nested = True
                    Next

                    ds.Tables(0).Columns("ParentID").ColumnMapping = MappingType.Hidden
                    ds.Tables(0).Columns("idkey").ColumnMapping = MappingType.Hidden
                    ds.Tables(0).Columns("ID").ColumnMapping = MappingType.Hidden
                    Dim xmlstr As String
                    Dim dt As DataTable = ds.Tables(0)
                    Dim SB As New StringBuilder
                    Dim SW As New IO.StringWriter(SB)

                    dt.WriteXml(SW)
                    xmlstr = "<?xml version=""1.0"" encoding=""utf-8""?>" + SW.ToString().Replace("<Example>", "").Replace("</Example>", "").Replace("&gt;", ">").Replace("&lt;", "<").Replace("<Closing>", "").Replace("</Closing>", "")

                    xml = XDocument.Parse(xmlstr)
                    Dim df As XNamespace = xml.Root.Name.Namespace

                    If xml.Declaration IsNot Nothing Then
                        xml.Declaration.Encoding = "UTF-8"
                    Else
                        xml.Declaration = New XDeclaration("1.0", "UTF-8", "")
                    End If

                    For Each element As XElement In (From el In xml.Descendants("Table") Select el)
                        Dim name As String = element.Name.ToString()
                        Dim value As String = DirectCast(element.FirstNode, XElement).Value

                        Dim hasAttributes As Boolean = DirectCast(element.Nodes(0), XElement).HasAttributes

                        If (hasAttributes) Then
                            element.AddBeforeSelf(DirectCast(element.Nodes().FirstOrDefault, XElement))
                        ElseIf (value <> "") Then
                            Using rdr As New System.IO.StringReader(value.Substring(value.IndexOf(" ") + 1))
                                Using parser As New Microsoft.VisualBasic.FileIO.TextFieldParser(rdr)
                                    parser.TextFieldType = Microsoft.VisualBasic.FileIO.FieldType.Delimited
                                    parser.Delimiters = New String() {" ", "="}
                                    parser.HasFieldsEnclosedInQuotes = True
                                    Dim strArray() As String = parser.ReadFields()


                                    If (strArray.Length = 1) Then
                                        element.Name = value
                                        element.Nodes().FirstOrDefault.Remove()
                                    Else
                                        element.Name = value.Substring(0, value.IndexOf(" "))

                                        For i As Integer = 0 To strArray.Length - 1
                                            element.SetAttributeValue(strArray(i), strArray(i + 1).Replace("&quot;", ""))
                                            i = i + 1
                                        Next

                                        element.Nodes().FirstOrDefault.Remove()
                                    End If
                                End Using
                            End Using
                        Else
                            element.AddBeforeSelf(DirectCast(element.FirstNode, XElement).LastNode)
                        End If
                    Next

                    xml.Descendants("Table").Remove()

                    xml.Root.Name = "PC"

                    Dim xmlWithoutRoot As String = xml.ToString().Replace("<PC>", String.Empty).Replace("</PC>", String.Empty).Replace("&amp;", "&")

                    xml = XDocument.Parse(xmlWithoutRoot)
                End Using
            End Using
            Return xml
        End Function

        Public Shared Function GetProductConfigurationHeader(ByVal pcUID As Int32) As DataTable
            Dim dt As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetProductConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@PCUID", pcUID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function GetProductConfigurationDetails(ByVal pcID As Int32) As DataTable
            Dim dt As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetProductConfigurationDetails", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@PCID", pcID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function SaveProductConfiguration(ByVal pcID As Int32, ByVal parentID As Int32, ByVal ViewOrder As Int32, ByVal NodeName As String, ByVal lastUser As String, ByVal pcUID As Int32) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispSaveProductConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@PCID", pcID)
                    myCommand.Parameters.AddWithValue("@parentID", parentID)
                    myCommand.Parameters.AddWithValue("@ViewOrder", ViewOrder)
                    myCommand.Parameters.AddWithValue("@NodeName", NodeName)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myCommand.Parameters.AddWithValue("@UploadID", pcUID)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function SaveProductConfigurationDetails(ByVal pcID As Int32, ByVal configID As Int32, ByVal lookupID As Int32, ByVal lookupValue As String, ByVal lastUser As String, ByVal IsAttribute As Boolean, ByVal lookupAlt As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispSaveProductConfigurationDetails", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@PCID", pcID)
                    myCommand.Parameters.AddWithValue("@configID", configID)
                    myCommand.Parameters.AddWithValue("@lookupID", lookupID)
                    myCommand.Parameters.AddWithValue("@lookupValue", lookupValue)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myCommand.Parameters.AddWithValue("@IsAttribute", IsAttribute)
                    myCommand.Parameters.AddWithValue("@LookupAlt", lookupAlt)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function GetSimilarTestConfigurations(ByVal productID As Int32, ByVal TestID As Int32) As DataTable
            Dim dt As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetSimilarTestConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myCommand.Parameters.AddWithValue("@TestID", TestID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function CopyTestConfiguration(ByVal productID As Int32, ByVal testID As Int32, ByVal copyFromProductID As Int32, ByVal lastUser As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispCopyTestConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@copyFromProductID", copyFromProductID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function DeleteProductConfigurationDetail(ByVal configID As Int32, ByVal lastUser As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeleteProductConfigurationDetail", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ConfigID", configID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function DeleteProductConfigurationHeader(ByVal pcID As Int32, ByVal lastUser As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeleteProductConfigurationHeader", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@PCID", pcID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function DeleteProductConfiguration(ByVal pcUID As Int32, ByVal lastUser As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeleteProductConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@PCUID", pcUID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function ProductConfigurationUpload(ByVal productID As Int32, ByVal testID As Int32, ByVal xml As XDocument, ByVal LastUser As String, ByVal pcName As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispProductConfigurationUpload", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ProductID", productID)
                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@XML", xml.ToString())
                    myCommand.Parameters.AddWithValue("@LastUser", LastUser)
                    myCommand.Parameters.AddWithValue("@PCName", pcName)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function SaveProductConfigurationXMLVersion(ByVal xml As String, ByVal LastUser As String, ByVal pcUID As Int32) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispProductConfigurationSaveXMLVersion", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@XML", xml.ToString())
                    myCommand.Parameters.AddWithValue("@LastUser", LastUser)
                    myCommand.Parameters.AddWithValue("@PCUID", pcUID)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function ProductConfigurationProcess() As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispProductConfigurationProcess", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function GetProductContacts(ByVal productID As Int32) As DataTable
            Dim dt As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetContacts", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                End Using
            End Using
            Return dt
        End Function
#End Region
    End Class
End Namespace