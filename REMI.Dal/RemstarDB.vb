Imports System.Data.SqlClient
Imports System.Data
Imports System.Configuration
Imports REMI.BusinessEntities
Imports REMI.Core

Namespace REMI.Dal
    Public Class RemstarDB
        Public Shared Function AddMaterial(ByVal material As remstarMaterial) As Integer

            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMSTAR)

                Using myCommand As New SqlCommand("insert into materialimport (property, bin, info1, status, MaterialName) values (@propertyName, @BinType,@ProductGroupName,0, @QRANumber)", myConnection)
                    myCommand.CommandType = CommandType.Text
                    myCommand.Parameters.AddWithValue("@QRANumber", material.QRAnumber)
                    myCommand.Parameters.AddWithValue("@PropertyName", material.PropertyName)
                    myCommand.Parameters.AddWithValue("@BinType", material.BinType)
                    myCommand.Parameters.AddWithValue("@ProductGroupName", material.ProductGroupName)
                    myConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using

            End Using
            Return Result
        End Function

        Public Shared Function GetBinType() As DataTable
            Dim bins As New DataTable
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMSTAR)

                Using myCommand As New SqlCommand("SELECT DISTINCT Bin.BinName FROM Shelf INNER JOIN Location ON Shelf.ShelfId = Location.ShelfId INNER JOIN Bin ON Bin.BinId = Location.BinId INNER JOIN Carrier ON Shelf.CarrierId = Carrier.CarrierId INNER JOIN Storageunit ON Carrier.StorageunitId = Storageunit.StorageunitId INNER JOIN Warehouse ON Storageunit.WarehouseId = Warehouse.WarehouseId WHERE Warehouse.WarehouseID='2D2916F3-BDC9-410F-85BE-3EBAD0032BC9' ORDER BY Bin.BinName", myConnection)
                    myCommand.CommandType = CommandType.Text
                    myConnection.Open()
                    Dim da As SqlDataAdapter = New SqlDataAdapter(myCommand)
                    da.Fill(bins)
                    bins.TableName = "Bins"
                End Using
            End Using
            Return bins
        End Function

        Public Shared Function IsInRemStar(ByVal qraNumber As String, ByVal unit As Int32) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMSTAR)
                Using myCommand As New SqlCommand("select lcb.SerialNumber from MaterialBase mb left outer join LocContent lc on lc.materialid=mb.materialid left outer join LocContentbreakdown lcb on lcb.loccontentid=lc.loccontentid where materialname = @QRANumber And lcb.SerialNumber=@Serial ", myConnection)
                    myCommand.CommandType = CommandType.Text
                    myCommand.Parameters.AddWithValue("@QRANumber", qraNumber)
                    myCommand.Parameters.AddWithValue("@Serial", unit.ToString())
                    myConnection.Open()
                    Dim dr As SqlDataReader = myCommand.ExecuteReader

                    While dr.Read
                        If Not dr.IsDBNull(0) Then
                            Dim serial As String = dr.GetString(0)

                            If (serial = unit.ToString()) Then
                                Return True
                            Else
                                Return False
                            End If
                        End If
                    End While
                End Using
            End Using

            Return False
        End Function

        ''' <summary>
        ''' Returns a csv string containing the names of the shelves a batch may be stored on.
        ''' </summary>
        ''' <param name="qranumber"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetShelfNumbers(ByVal qranumber As String) As String
            Dim shelves As New List(Of String)
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMSTAR)

                Using myCommand As New SqlCommand("select c.carriername from carrier as c, shelf as s, location as l, loccontent as lc, materialbase as mb where c.carrierid = s.carrierid and s.shelfid =  l.shelfid  and l.locationid = lc.locationid and lc.materialid =mb.materialid and mb.materialname =@qranumber", myConnection)
                    myCommand.CommandType = CommandType.Text
                    myCommand.Parameters.AddWithValue("@QRANumber", qranumber)
                    myConnection.Open()
                    Dim dr As SqlDataReader = myCommand.ExecuteReader

                    While dr.Read
                        If Not dr.IsDBNull(0) Then
                            shelves.Add(dr.GetString(0))
                        End If
                    End While
                End Using

            End Using
            Return String.Join(",", shelves.ToArray)
        End Function
        Public Shared Function ScanDevice(ByVal qraNumber As String, ByVal unitNumber As Integer, ByVal userName As String, ByVal Direction As ScanDirection, ByVal binName As String) As Integer

            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMSTAR)

                Using myCommand As New SqlCommand("insert into orderimport ( materialName, quantity, serialnumber, status, ordername,linenumber, Bin, Lot) values (@qranumber, @quantity,@unitnumber,0, @OrderName,@unitnumber, @BinName, @Lot)", myConnection)
                    myCommand.CommandType = CommandType.Text
                    myCommand.Parameters.AddWithValue("@QRANumber", qraNumber)
                    myCommand.Parameters.AddWithValue("@UnitNumber", unitNumber)
                    myCommand.Parameters.AddWithValue("@UserName", userName)
                    If Not String.IsNullOrEmpty(binName) Then
                        myCommand.Parameters.AddWithValue("@BinName", binName)
                    Else
                        myCommand.Parameters.AddWithValue("@BinName", DBNull.Value)
                    End If
                    Select Case Direction
                        Case ScanDirection.Inward
                            myCommand.Parameters.AddWithValue("@OrderName", String.Format("{0}_{1}_PUT", userName, qraNumber))
                            myCommand.Parameters.AddWithValue("@Quantity", 1)
                            myCommand.Parameters.AddWithValue("@Lot", "-")
                        Case ScanDirection.Outward
                            myCommand.Parameters.AddWithValue("@OrderName", String.Format("{0}_{1}_PICK", userName, qraNumber))
                            myCommand.Parameters.AddWithValue("@Quantity", -1)
                            myCommand.Parameters.AddWithValue("@Lot", DBNull.Value)
                    End Select
                    myConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return Result
        End Function
        Public Shared Function AddCountOrder(ByVal qraNumbers As List(Of String), ByVal userName As String) As Boolean
            Dim dateString As String = DateTime.Now.ToString("yyyy-mm-dd-hh-mm-ss")
            Dim Result As Boolean = True

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMSTAR)
                myConnection.Open()
                For Each qraNumber As String In qraNumbers
                    Using myCommand As New SqlCommand("insert into orderimport ( materialName, quantity, serialnumber, status, ordername,linenumber, Bin, Lot) values (@qranumber, @quantity,@unitnumber,0, @OrderName,@unitnumber, @BinName, @Lot)", myConnection)
                        myCommand.CommandType = CommandType.Text
                        myCommand.Parameters.AddWithValue("@QRANumber", qraNumber)
                        myCommand.Parameters.AddWithValue("@UnitNumber", DBNull.Value)
                        myCommand.Parameters.AddWithValue("@UserName", userName)

                        myCommand.Parameters.AddWithValue("@BinName", DBNull.Value)

                        myCommand.Parameters.AddWithValue("@OrderName", String.Format("{0}_{1}", userName, dateString))
                        myCommand.Parameters.AddWithValue("@Quantity", 0)
                        myCommand.Parameters.AddWithValue("@Lot", DBNull.Value)

                        If myCommand.ExecuteNonQuery() <> 1 Then
                            Result = False
                            Exit For
                        End If
                    End Using
                Next
            End Using
            Return Result
        End Function
    End Class
End Namespace