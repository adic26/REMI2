Imports System.Data.SqlClient
Imports REMI.Core
'Imports System.Data.OracleClient
Imports REMI.BusinessEntities
Imports System.Data.Common

Namespace REMI.Dal
    Public Class LookupsDB
        Public Shared Function GetLookups(ByVal type As String, ByVal productID As Int32, ByVal parentID As Int32, ByVal parentLookupType As String, ByVal parentLookupValue As String, ByVal requestTypeID As Int32, ByVal showAdminSelected As Boolean, ByVal showArchived As Boolean, ByVal userID As Int32) As DataTable
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

                    If (parentLookupType.Trim().Length > 0) Then
                        myCommand.Parameters.AddWithValue("@ParentLookupType", parentLookupType)
                    End If

                    If (parentLookupValue.Trim().Length > 0) Then
                        myCommand.Parameters.AddWithValue("@ParentLookup", parentLookupValue)
                    End If

                    If (requestTypeID > 0) Then
                        myCommand.Parameters.AddWithValue("@RequestTypeID", requestTypeID)
                    End If

                    myCommand.Parameters.AddWithValue("@ShowAdminSelected", showAdminSelected)
                    myCommand.Parameters.AddWithValue("@ShowArchived", showArchived)
                    myCommand.Parameters.AddWithValue("@UserID", userID)

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
            Dim success As Boolean = False

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispSaveLookup", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@LookupType", lookupType)
                    myCommand.Parameters.AddWithValue("@Value", value)
                    myCommand.Parameters.AddWithValue("@IsActive", isActive)
                    myCommand.Parameters.AddWithValue("@Description", description)
                    myCommand.Parameters.AddWithValue("@ParentID", parentID)

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