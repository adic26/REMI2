Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports System.Configuration
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Core
Imports System.Text
Imports REMI.Contracts

Namespace REMI.Dal
    ''' <summary>
    ''' The TrackingLocationDB class is responsible for interacting with the database to retrieve and store information 
    ''' about TrackingLocation objects.
    ''' </summary>
    Public Class TrackingLocationDB
#Region "Public Methods"
        ''' <summary> 
        ''' Returns a list with TrackingLocation objects. 
        ''' </summary>
        ''' <param name="tlc">The criteria to return tracking locations for.</param>
        ''' <returns> 
        ''' A TrackingLocationCollection. 
        ''' </returns> 
        Public Shared Function SearchFor(ByVal tlc As TrackingLocationCriteria, Optional ByVal onlyActive As Int32 = 0, Optional ByVal removeHosts As Int32 = 0, Optional ByVal showHostsNamedAll As Int32 = 1) As TrackingLocationCollection
            Dim tempList As New TrackingLocationCollection

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Dim mycommand As SqlCommand = CreateCommandForSearching(tlc, myConnection, onlyActive, removeHosts, showHostsNamedAll)
                Using mycommand
                    myConnection.Open()
                    Using myReader As SqlDataReader = mycommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                tempList.Add(FillDataRecord(myReader))
                            End While
                        End If
                    End Using
                End Using
            End Using
            Return tempList
        End Function

        Public Shared Function GetTrackingLocationID(ByVal trackingLocationName As String, ByVal testCenterID As Int32) As Int32
            Dim tlc As New TrackingLocationCriteria
            tlc.GeoLocationID = testCenterID
            tlc.TrackingLocName = trackingLocationName

            Dim tl As TrackingLocationCollection = SearchFor(tlc, 1, 1)

            Return tl(0).ID
        End Function

        Public Shared Function GetHostID(ByVal computerName As String, ByVal trackingLocationID As Int32) As Int32
            Dim Result As Integer = 0

            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationsHostID", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ComputerName", computerName)
                    myCommand.Parameters.AddWithValue("@TrackingLocationID", trackingLocationID)

                    Dim returnValue As New SqlParameter("ReturnValue", SqlDbType.Int)
                    returnValue.Direction = ParameterDirection.ReturnValue
                    myCommand.Parameters.Add(returnValue)

                    MyConnection.Open()
                    myCommand.ExecuteScalar()
                    Result = Convert.ToInt32(returnValue.Value)
                End Using
            End Using
            Return Result
        End Function

        Public Shared Function SaveHost(ByVal ID As Int32, ByVal HostName As String, ByVal userName As String, ByVal status As TrackingLocationStatus) As Integer
            Dim Result As Integer = 0
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispTrackingLocationsInsertHost", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myCommand.Parameters.AddWithValue("@HostName", HostName)
                    myCommand.Parameters.AddWithValue("@UserName", userName)
                    myCommand.Parameters.AddWithValue("@Status", status)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return Result
        End Function

        'End Function
        ''' <summary>Saves an instance of the <see cref="TrackingLocation" /> in the database.</summary> 
        ''' <param name="myTrackingLocation">The TrackingLocation instance to save.</param> 
        ''' <returns>Returns true when the object was saved successfully, or false otherwise.</returns> 
        Public Shared Function Save(ByVal MyTrackingLocation As TrackingLocation) As Integer
            If Not MyTrackingLocation.Validate() Then
                Throw New InvalidSaveOperationException("Can't save a TrackingLocation in an Invalid state. Make sure that IsValid() returns true before you call Save().")
            End If

            Dim Result As Integer = 0

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationsInsertUpdateSingleItem", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@TrackingLocationName", MyTrackingLocation.Name)
                    myCommand.Parameters.AddWithValue("@TrackingLocationTypeID", MyTrackingLocation.TrackingLocationType.ID)
                    myCommand.Parameters.AddWithValue("@GeoLocationID", MyTrackingLocation.GeoLocationID)
                    myCommand.Parameters.AddWithValue("@Status", MyTrackingLocation.Status)

                    If Not String.IsNullOrEmpty(MyTrackingLocation.HostName) Then
                        myCommand.Parameters.AddWithValue("@HostName", MyTrackingLocation.HostName)
                    End If

                    If Not String.IsNullOrEmpty(MyTrackingLocation.Comment) Then
                        myCommand.Parameters.AddWithValue("@Comment", MyTrackingLocation.Comment)
                    End If

                    myCommand.Parameters.AddWithValue("@Decommissioned", MyTrackingLocation.Decommissioned)
                    myCommand.Parameters.AddWithValue("@IsMultiDeviceZone", MyTrackingLocation.IsMultiDeviceZone)
                    'myCommand.Parameters.AddWithValue("@PluginName", MyTrackingLocation.PluginName)
                    myCommand.Parameters.AddWithValue("@LocationStatus", MyTrackingLocation.LocationStatus)

                    Helpers.SetSaveParameters(myCommand, MyTrackingLocation)
                    myConnection.Open()

                    Dim NumberOfRecordsAffected As Integer = myCommand.ExecuteNonQuery()

                    If NumberOfRecordsAffected = 0 Then
                        Throw New DBConcurrencyException("Can't update the TrackingLocation as it has been updated by someone else.")
                    End If

                    MyTrackingLocation.ConcurrencyID = Helpers.GetConcurrencyId(myCommand)
                    Result = Helpers.GetBusinessBaseId(myCommand)
                End Using
            End Using

            Return Result
        End Function

        Public Shared Function GetSpecificLocationForUsersTestCenter(ByVal stationName As String, ByVal userName As String) As Integer
            Dim Result As Integer = 0

            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationsGetSpecificLocationForUsersTestCenter", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@locationname", stationName)
                    myCommand.Parameters.AddWithValue("@UserName", userName)
                    MyConnection.Open()

                    Dim returnValue As New SqlParameter("ReturnValue", SqlDbType.Int)
                    returnValue.Direction = ParameterDirection.ReturnValue
                    myCommand.Parameters.Add(returnValue)
                    myCommand.ExecuteScalar()
                    Result = Convert.ToInt32(returnValue.Value)
                End Using

            End Using
            Return Result
        End Function

        ''' <summary>Deletes a TrackingLocation from the database.</summary> 
        ''' <param name="id">The ID of the TrackingLocation to delete.</param> 
        ''' <returns>Returns <c>true</c> when the object was deleted successfully, or <c>false</c> otherwise.</returns> 
        Public Shared Function DeleteHost(ByVal ID As Integer, ByRef hostName As String, ByVal userName As String) As Integer
            Dim Result As Integer = 0

            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationsDeleteHost", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myCommand.Parameters.AddWithValue("@HostName", hostName)
                    myCommand.Parameters.AddWithValue("@UserName", userName)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using

            Return Result
        End Function

        ''' <summary>Deletes a TrackingLocation from the database.</summary> 
        ''' <param name="id">The ID of the TrackingLocation to delete.</param> 
        ''' <returns>Returns <c>true</c> when the object was deleted successfully, or <c>false</c> otherwise.</returns> 
        Public Shared Function Delete(ByVal ID As Integer, ByVal userName As String) As Integer
            Dim Result As Integer = 0

            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTrackingLocationsDeleteSingleItem", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ID", ID)
                    myCommand.Parameters.AddWithValue("@UserName", userName)
                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using

            Return Result
        End Function

        ''' <summary> 
        ''' Returns the number of TrackingLocations. This is used for paging the database if there are many items in a list.
        ''' </summary> 
        Public Shared Function SelectCountForGetList(ByVal tlc As TrackingLocationCriteria) As Integer
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Dim myCommand As SqlCommand = CreateCommandForSearching(tlc, myConnection)
                Using myCommand
                    Dim IDParam As DbParameter = myCommand.CreateParameter()
                    IDParam.DbType = DbType.Int32
                    IDParam.Direction = ParameterDirection.InputOutput
                    IDParam.ParameterName = "@RecordCount"
                    IDParam.Value = 0
                    myCommand.Parameters.Add(IDParam)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()

                    Return CInt(myCommand.Parameters("@RecordCount").Value)
                End Using
            End Using
        End Function
#End Region

#Region "Private Methods"

        ''' <summary>
        ''' Creates the command for searching.
        ''' </summary>
        ''' <param name="tlc">The TLC.</param>
        ''' <param name="myConnection">My connection.</param>
        ''' <returns></returns>
        Private Shared Function CreateCommandForSearching(ByVal tlc As TrackingLocationCriteria, ByVal myConnection As SqlConnection, Optional ByVal onlyActive As Int32 = 0, Optional ByVal removeHosts As Int32 = 0, Optional showHostsNamedAll As Int32 = 1) As SqlCommand
            Dim myCommand As New SqlCommand("remispTrackingLocationsSearchFor", myConnection)
            myCommand.CommandType = CommandType.StoredProcedure

            If tlc.ID > 0 Then
                myCommand.Parameters.AddWithValue("@ID", tlc.ID)
            End If

            If Not String.IsNullOrEmpty(tlc.TrackingLocName) Then
                myCommand.Parameters.AddWithValue("@TrackingLocationName", tlc.TrackingLocName)
            End If

            If tlc.Status <> TrackingLocationStatus.NotSet Then
                myCommand.Parameters.AddWithValue("@Status", tlc.Status)
            End If

            If tlc.GeoLocationID > 0 Then
                myCommand.Parameters.AddWithValue("@GeoLocationID", tlc.GeoLocationID)
            End If
            If Not String.IsNullOrEmpty(tlc.HostName) Then
                myCommand.Parameters.AddWithValue("@HostName", tlc.HostName)
            End If

            If Not String.IsNullOrEmpty(tlc.TrackingLocTypeName) Then
                myCommand.Parameters.AddWithValue("@TrackingLocationTypeName", tlc.TrackingLocTypeName)
            End If
            If tlc.TrackingLocationTypeID > 0 Then
                myCommand.Parameters.AddWithValue("@TrackingLocationTypeID", tlc.TrackingLocationTypeID)
            End If

            If tlc.TrackingLocationFunction <> TrackingLocationFunction.NotSet Then
                myCommand.Parameters.AddWithValue("@TrackingLocationFunction", tlc.TrackingLocationFunction)
            End If

            myCommand.Parameters.AddWithValue("@OnlyActive", onlyActive)
            myCommand.Parameters.AddWithValue("@RemoveHosts", removeHosts)
            myCommand.Parameters.AddWithValue("@ShowHostsNamedAll", showHostsNamedAll)

            Return myCommand
        End Function

        ''' <summary>
        ''' Initializes a new instance of the TrackingLocation class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the TrackingLocation produced by a select query</param>
        ''' <returns>A TrackingLocation object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord) As TrackingLocation
            Dim myTrackingLocation As TrackingLocation = Nothing ' DirectCast(System.Web.HttpRuntime.Cache.Get("TrackingLocation-" + myDataRecord.GetInt32(myDataRecord.GetOrdinal("id")).ToString), TrackingLocation)
            If myTrackingLocation Is Nothing Then
                'Non nullable data records
                myTrackingLocation = New TrackingLocation
                myTrackingLocation.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("TrackingLocationName"))
                myTrackingLocation.GeoLocationName = myDataRecord.GetString(myDataRecord.GetOrdinal("GeoLocationName"))
                myTrackingLocation.GeoLocationID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestCenterLocationID"))
                myTrackingLocation.CurrentUnitCount = myDataRecord.GetInt32(myDataRecord.GetOrdinal("CurrentCount"))

                myTrackingLocation.Status = DirectCast(myDataRecord.GetInt32(myDataRecord.GetOrdinal("Status")), TrackingLocationStatus)
                'nullable data records
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("Comment")) Then
                    myTrackingLocation.Comment = myDataRecord.GetString(myDataRecord.GetOrdinal("Comment"))
                End If
                'everything else
                Helpers.FillObjectParameters(myDataRecord, myTrackingLocation)
                If (Helpers.HasColumn(myDataRecord, "HostName")) Then
                    If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("HostName")) Then
                        myTrackingLocation.HostName = myDataRecord.GetString(myDataRecord.GetOrdinal("HostName"))
                    End If
                End If
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("CurrentTestName")) Then
                    myTrackingLocation.CurrentTestName = myDataRecord.GetString(myDataRecord.GetOrdinal("CurrentTestName"))
                End If
                'tracking location type items
                myTrackingLocation.TrackingLocationType.UnitCapacity = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TLTUnitCapacity"))
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TLTComment")) Then
                    myTrackingLocation.TrackingLocationType.Comment = myDataRecord.GetString(myDataRecord.GetOrdinal("TLTComment"))
                End If
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TLTWILocation")) Then
                    myTrackingLocation.TrackingLocationType.WILocation = myDataRecord.GetString(myDataRecord.GetOrdinal("TLTWILocation"))
                End If
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TLTName")) Then
                    myTrackingLocation.TrackingLocationType.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("TLTName"))
                End If
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TLTFunction")) Then
                    myTrackingLocation.TrackingLocationType.TrackingLocationFunction = DirectCast(myDataRecord.GetInt32(myDataRecord.GetOrdinal("TLTFunction")), TrackingLocationFunction)
                End If

                myTrackingLocation.TrackingLocationType.ID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TLTID"))
                myTrackingLocation.TrackingLocationType.ConcurrencyID = DirectCast(myDataRecord.GetValue(myDataRecord.GetOrdinal("TLTConcurrencyID")), Byte())
                myTrackingLocation.TrackingLocationType.LastUser = myDataRecord.GetString(myDataRecord.GetOrdinal("TLTLastUser"))

                If (Helpers.HasColumn(myDataRecord, "CanDelete")) Then
                    myTrackingLocation.CanDelete = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("CanDelete"))
                End If

                If (Helpers.HasColumn(myDataRecord, "TrackingLocationHostID")) Then
                    myTrackingLocation.HostID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TrackingLocationHostID"))
                End If

                If (Helpers.HasColumn(myDataRecord, "Decommissioned")) Then
                    myTrackingLocation.Decommissioned = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("Decommissioned"))
                End If

                If (Helpers.HasColumn(myDataRecord, "IsMultiDeviceZone")) Then
                    myTrackingLocation.IsMultiDeviceZone = myDataRecord.GetBoolean(myDataRecord.GetOrdinal("IsMultiDeviceZone"))
                End If

                If (Helpers.HasColumn(myDataRecord, "LocationStatus")) Then
                    If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("LocationStatus")) Then
                        myTrackingLocation.LocationStatus = DirectCast(myDataRecord.GetInt32(myDataRecord.GetOrdinal("LocationStatus")), TrackingStatus)
                    End If
                End If
            End If
            Return myTrackingLocation
        End Function

        Public Shared Function GetStationConfigurationXML(ByVal hostID As Int32, ByVal profileName As String) As XDocument
            Dim xml As XDocument
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispStationGroupConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@hostID", hostID)
                    myCommand.Parameters.AddWithValue("@ProfileName", profileName)
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

                    xml.Root.Name = "StationConfiguration"

                    Dim xmlWithoutRoot As String = xml.ToString().Replace("<StationConfiguration>", String.Empty).Replace("</StationConfiguration>", String.Empty)

                    xml = XDocument.Parse(xmlWithoutRoot)
                End Using
            End Using
            Return xml
        End Function

        Public Shared Function GetStationConfigurationHeader(ByVal hostID As Int32, ByVal profileID As Int32) As DataTable
            Dim dt As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetStationConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@hostID", hostID)
                    myCommand.Parameters.AddWithValue("@ProfileID", profileID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function GetStationConfigurationDetails(ByVal hostConfigID As Int32) As DataTable
            Dim dt As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetStationConfigurationDetails", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@hostConfigID", hostConfigID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function SaveStationConfiguration(ByVal hostConfigID As Int32, ByVal parentID As Int32, ByVal ViewOrder As Int32, ByVal NodeName As String, ByVal hostID As Int32, ByVal lastUser As String, ByVal pluginID As Int32) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispSaveStationConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@HostConfigID", hostConfigID)
                    myCommand.Parameters.AddWithValue("@parentID", parentID)
                    myCommand.Parameters.AddWithValue("@ViewOrder", ViewOrder)
                    myCommand.Parameters.AddWithValue("@NodeName", NodeName)
                    myCommand.Parameters.AddWithValue("@hostID", hostID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myCommand.Parameters.AddWithValue("@PluginID", pluginID)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function SaveStationConfigurationDetails(ByVal hostConfigID As Int32, ByVal configID As Int32, ByVal lookupID As Int32, ByVal lookupValue As String, ByVal hostID As Int32, ByVal lastUser As String, ByVal IsAttribute As Boolean) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispSaveStationConfigurationDetails", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@HostConfigID", hostConfigID)
                    myCommand.Parameters.AddWithValue("@configID", configID)
                    myCommand.Parameters.AddWithValue("@lookupID", lookupID)
                    myCommand.Parameters.AddWithValue("@lookupValue", lookupValue)
                    myCommand.Parameters.AddWithValue("@HostID", hostID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myCommand.Parameters.AddWithValue("@IsAttribute", IsAttribute)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function GetSimilarStationConfigurations(ByVal hostID As Int32) As DataTable
            Dim dt As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetSimilarStationConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@HostID", hostID)
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function DeleteStationConfiguration(ByVal hostID As Int32, ByVal lastUser As String, ByVal pluginID As Int32) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeleteStationConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@HostID", hostID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myCommand.Parameters.AddWithValue("@PluginID", pluginID)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function CopyStationConfiguration(ByVal hostID As Int32, ByVal copyFromHostID As Int32, ByVal lastUser As String, ByVal profileID As Int32) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispCopyStationConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@HostID", hostID)
                    myCommand.Parameters.AddWithValue("@copyFromHostID", copyFromHostID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myCommand.Parameters.AddWithValue("@ProfileID", profileID)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function DeleteStationConfigurationDetail(ByVal configID As Int32, ByVal lastUser As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeleteStationConfigurationDetail", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ConfigID", configID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function DeleteStationConfigurationHeader(ByVal hostConfigID As Int32, ByVal lastUser As String, ByVal profileID As Int32) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispDeleteStationConfigurationHeader", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@HostConfigID", hostConfigID)
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myCommand.Parameters.AddWithValue("@ProfileID", profileID)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function StationConfigurationUpload(ByVal hostID As Int32, ByVal xml As XDocument, ByVal LastUser As String, ByVal pluginID As Int32) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispStationConfigurationProcess", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@HostID", hostID)
                    myCommand.Parameters.AddWithValue("@XML", xml.ToString())
                    myCommand.Parameters.AddWithValue("@LastUser", LastUser)
                    myCommand.Parameters.AddWithValue("@PluginID", pluginID)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function StationConfigurationProcess() As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispStationConfigurationUpload", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function
#End Region
    End Class
End Namespace