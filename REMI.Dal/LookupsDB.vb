Imports System.Data.SqlClient
Imports REMI.Core
Imports System.Data.OracleClient
Imports REMI.BusinessEntities

Namespace REMI.Dal
    Public Class LookupsDB
        Public Shared Function GetLookups(ByVal type As REMI.Contracts.LookupType, ByVal productID As Int32, ByVal parentID As Int32) As DataTable
            Dim dt As New DataTable
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetLookups", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@Type", type.ToString())

                    If (productID > 0) Then
                        myCommand.Parameters.AddWithValue("@ProductID", productID)
                    End If

                    If (parentID > 0) Then
                        myCommand.Parameters.AddWithValue("@ParentID", parentID)
                    End If

                    MyConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "Lookups"
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function SaveLookup(ByVal lookupType As String, ByVal value As String, ByVal isActive As Int32, ByVal description As String, ByVal parentID As Int32) As Boolean
            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)

                Using myCommand As New SqlCommand("remispSaveLookup", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@LookupType", lookupType)
                    myCommand.Parameters.AddWithValue("@Value", value)
                    myCommand.Parameters.AddWithValue("@IsActive", isActive)
                    myCommand.Parameters.AddWithValue("@Description", description)
                    myCommand.Parameters.AddWithValue("@ParentID", parentID)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function GetLookupID(ByVal type As REMI.Contracts.LookupType, ByVal lookup As String, ByVal parentID As Int32) As Int32
            Dim lookupID As Int32
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetLookup", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@Type", type.ToString())
                    myCommand.Parameters.AddWithValue("@Lookup", lookup)
                    myCommand.Parameters.AddWithValue("@ParentID", parentID)
                    MyConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader
                        If myReader.HasRows Then
                            If (myReader.Read) Then
                                If (Not myReader.IsDBNull(myReader.GetOrdinal("LookupID"))) Then
                                    lookupID = myReader.GetInt32(myReader.GetOrdinal("LookupID"))
                                End If
                            End If
                        End If
                    End Using
                End Using
            End Using
            Return lookupID
        End Function

        ''' <summary> 
        ''' Returns a list with ProductType objects. 
        ''' </summary> 
        ''' <returns> 
        ''' A ProductTypeCollection. 
        ''' </returns> 
        Public Shared Function GetOracleProductTypeList() As List(Of String)
            Dim tempList As New List(Of String)
            Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq("TRSDBConnectionString"))

                Using myCommand As New OracleCommand("REMI_HELPER.get_product_types", myConnection)
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

        ''' <summary> 
        ''' Returns a list with AccessoryGroup objects. 
        ''' </summary> 
        ''' <returns> 
        ''' A AccessoryGroupCollection. 
        ''' </returns> 
        Public Shared Function GetOracleAccessoryList() As List(Of String)
            Dim tempList As New List(Of String)
            Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq("TRSDBConnectionString"))

                Using myCommand As New OracleCommand("REMI_HELPER.get_accessory_groups", myConnection)
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

        ''' <summary> 
        ''' Returns a list with GeographicalLocation objects. 
        ''' </summary> 
        ''' <returns> 
        ''' A List of the available geographical locations. 
        ''' </returns> 
        Public Shared Function GetOracleTestCentersList() As List(Of String)
            Dim geoLocList As List(Of String) = REMIAppCache.GetGeoLocList()
            If geoLocList Is Nothing Then
                geoLocList = New List(Of String)

                Using myConnection As New OracleConnection(REMIConfiguration.ConnectionStringReq("TRSDBConnectionString"))

                    Using myCommand As New OracleCommand("REMI_HELPER.get_TestCenterLocations ", myConnection)
                        myCommand.CommandType = CommandType.StoredProcedure

                        Dim pOut As New OracleParameter
                        pOut.Direction = ParameterDirection.ReturnValue
                        pOut.OracleType = OracleType.Cursor
                        pOut.ParameterName = "o_cur"
                        myCommand.Parameters.Add(pOut)

                        myConnection.Open()
                        Using myReader As OracleDataReader = myCommand.ExecuteReader
                            If myReader.HasRows Then
                                While myReader.Read()
                                    geoLocList.Add(myReader.GetString(0))
                                End While
                            End If
                        End Using
                    End Using
                End Using
                REMIAppCache.AddGeoLocList(geoLocList)
            End If
            Return geoLocList
        End Function
    End Class
End Namespace