Imports System.Data.SqlClient
Imports REMI.Core
'Imports System.Data.OracleClient
Imports REMI.BusinessEntities

Namespace REMI.Dal
    Public Class LookupsDB
        Public Shared Function GetLookups(ByVal type As String, ByVal productID As Int32, ByVal parentID As Int32, ByVal ParentLookupType As String, ByVal ParentLookupValue As String, ByVal RequestTypeID As Int32, ByVal ShowAdminSelected As Boolean) As DataTable
            Dim dt As New DataTable
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetLookups", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@Type", type)

                    If (productID > 0) Then
                        myCommand.Parameters.AddWithValue("@ProductID", productID)
                    End If

                    If (parentID > 0) Then
                        myCommand.Parameters.AddWithValue("@ParentID", parentID)
                    End If

                    If (ParentLookupType.Trim().Length > 0) Then
                        myCommand.Parameters.AddWithValue("@ParentLookupType", ParentLookupType)
                    End If

                    If (ParentLookupValue.Trim().Length > 0) Then
                        myCommand.Parameters.AddWithValue("@ParentLookup", ParentLookupValue)
                    End If

                    If (RequestTypeID > 0) Then
                        myCommand.Parameters.AddWithValue("@RequestTypeID", RequestTypeID)
                    End If

                    myCommand.Parameters.AddWithValue("@ShowAdminSelected", ShowAdminSelected)

                    MyConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "Lookups"
                End Using
            End Using
            Return dt
        End Function

        Public Shared Function GetLookupTypes(ByVal showSystemTypes As Boolean) As DataTable
            Dim dt As New DataTable
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetLookupTypes", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@ShowSystemTypes", showSystemTypes)
                    MyConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(dt)
                    dt.TableName = "LookupTypes"
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

        Public Shared Function GetLookupID(ByVal type As String, ByVal lookup As String, ByVal parentID As Int32) As Int32
            Dim lookupID As Int32
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetLookup", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@Type", type)
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
    End Class
End Namespace