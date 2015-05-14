Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Data.Common
Imports System.Linq
Imports System.Collections.Generic
Imports System.Configuration
Imports REMI.Core
Imports REMI.BusinessEntities
Imports REMI.Validation
Imports REMI.Contracts
Namespace REMI.Dal
    ''' <summary>
    ''' The TestExceptionDB class is responsible for interacting with the database to retrieve and store information 
    ''' about TestException objects.
    ''' </summary>
    Public Class TestExceptionDB

#Region "Public Methods"
        ''' <summary>Saves an instance of the <see cref="TestException" /> in the database.</summary> 
        ''' <returns>Returns true when the object was saved successfully, or false otherwise.</returns> 
        Public Shared Function AddTestUnitException(ByVal te As TestException, ByVal UserName As String) As Boolean
            Dim Result As Integer = 0
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestExceptionsInsertTestUnitException", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRAnumber", te.QRAnumber)
                    myCommand.Parameters.AddWithValue("@BatchUnitNumber", te.UnitNumber)

                    If te.TestID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestID", te.TestID)
                    ElseIf Not String.IsNullOrEmpty(te.TestName) Then
                        myCommand.Parameters.AddWithValue("@TestName", te.TestName)
                    End If

                    If te.TestStageID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestStageID", te.TestStageID)
                    ElseIf Not String.IsNullOrEmpty(te.TestStageName) Then
                        myCommand.Parameters.AddWithValue("@TestStageName", te.TestStageName)
                    End If

                    myCommand.Parameters.AddWithValue("@LastUser", UserName)

                    If (te.ProductTypeID > 0) Then
                        myCommand.Parameters.AddWithValue("@ProductTypeID", te.ProductTypeID)
                    End If

                    If (te.AccessoryGroupID > 0) Then
                        myCommand.Parameters.AddWithValue("@AccessoryGroupID", te.AccessoryGroupID)
                    End If

                    myConnection.Open()
                    Result = myCommand.ExecuteNonQuery
                End Using
            End Using

            If Result > 0 Then
                REMIAppCache.RemoveTestExceptions(te.QRAnumber)
            End If
            Return (Result > 0)
        End Function

        ''' <summary>Deletes TestUnitException from the database.</summary> 
        ''' <returns>Returns <c>true</c> when the object was deleted successfully, or <c>false</c> otherwise.</returns> 
        Public Shared Function DeleteTestUnitException(ByVal te As TestException, ByVal UserName As String) As Boolean
            Dim Result As Integer = 0
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestExceptionsDeleteTestUnitException", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRAnumber", te.QRAnumber)
                    myCommand.Parameters.AddWithValue("@BatchUnitNumber", te.UnitNumber)

                    If Not String.IsNullOrEmpty(te.TestName) Then
                        myCommand.Parameters.AddWithValue("@TestName", te.TestName)
                    End If

                    If te.TestStageID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestStageID", te.TestStageID)
                    ElseIf Not String.IsNullOrEmpty(te.TestStageName) Then
                        myCommand.Parameters.AddWithValue("@TestStageName", te.TestStageName)
                    End If

                    If te.TestUnitID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestUnitID", te.TestUnitID)
                    End If

                    myCommand.Parameters.AddWithValue("@LastUser", UserName)

                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using

            If Result > 0 Then
                REMIAppCache.RemoveTestExceptions(te.QRAnumber)
            End If
            Return Result > 0
        End Function

        ''' <summary>Deletes TestUnitException from the database based on id.</summary> 
        Public Shared Function DeleteException(ByVal ID As Integer, ByVal userName As String) As Integer
            Dim Result As Integer = 0
            Using MyConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestExceptionsDelete", MyConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@id", ID)
                    myCommand.Parameters.AddWithValue("@LastUser", userName)

                    MyConnection.Open()
                    Result = myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return Result
        End Function

        ''' <summary> 
        ''' Returns a table with the test names and if there is an exception for that test. 
        ''' This is used to get the test exceptions for a test unit at a particular test stage.
        ''' </summary> 
        Public Shared Function GetExceptionsTableForTestUnit(ByVal QRANumber As String, ByVal UnitNumber As Integer, ByVal testStageName As String, ByVal testStageID As Int32) As Dictionary(Of String, Boolean)
            Dim tempList As New Dictionary(Of String, Boolean)

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispTestExceptionsGetTestUnitTable", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@QRANumber", QRANumber)
                    myCommand.Parameters.AddWithValue("@BatchUnitNumber", UnitNumber)

                    If testStageID > 0 Then
                        myCommand.Parameters.AddWithValue("@TestStageID", testStageID)
                    ElseIf Not String.IsNullOrEmpty(testStageName) Then
                        myCommand.Parameters.AddWithValue("@TestStageName", testStageName)
                    End If

                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            While myReader.Read()
                                tempList.Add(myReader.GetString(0), Convert.ToBoolean(myReader.GetString(1)))
                            End While
                        End If

                    End Using
                End Using

            End Using
            Return tempList

        End Function

        ''' <summary>
        ''' Returns a list of exceptions for the batch as standard objects.
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetExceptionsForBatch(ByVal qraNumber As String, ByVal myConnection As SqlConnection) As TestExceptionCollection
            Dim tempList As New TestExceptionCollection

            If (myConnection Is Nothing) Then
                myConnection = New SqlConnection(REMIConfiguration.ConnectionStringREMI)
            End If

            Using myCommand As New SqlCommand("remispTestExceptionsGetBatchExceptions", myConnection)
                myCommand.CommandType = CommandType.StoredProcedure
                myCommand.Parameters.AddWithValue("@qranumber", qraNumber)

                If myConnection.State <> ConnectionState.Open Then
                    myConnection.Open()
                End If

                Using myReader As SqlDataReader = myCommand.ExecuteReader()
                    If myReader.HasRows Then
                        While myReader.Read()
                            tempList.Add(FillDataRecord(myReader, qraNumber))
                        End While
                    End If
                End Using
            End Using

            Return tempList
        End Function

        Public Shared Function ExceptionSearch(ByVal es As ExceptionSearch) As TestExceptionCollection
            Dim tmpList As New TestExceptionCollection()
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispExceptionSearch", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.CommandTimeout = 40

                    For Each p As System.Reflection.PropertyInfo In es.GetType().GetProperties()
                        If p.CanRead Then
                            If (p.GetValue(es, Nothing) IsNot Nothing) Then
                                If (p.GetValue(es, Nothing).ToString().ToLower() <> "all" And p.GetValue(es, Nothing).ToString().ToLower() <> "0" And p.GetValue(es, Nothing).ToString().ToLower() <> "notset") Then
                                    myCommand.Parameters.AddWithValue("@" + p.Name, p.GetValue(es, Nothing))
                                End If
                            End If
                        End If
                    Next

                    myConnection.Open()

                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
                        If myReader.HasRows Then
                            tmpList = New TestExceptionCollection()
                            While myReader.Read()
                                tmpList.Add(FillDataRecord(myReader, String.Empty))
                            End While
                        End If
                    End Using
                End Using
            End Using
            If tmpList IsNot Nothing Then
                Return tmpList
            Else
                Return New TestExceptionCollection()
            End If
        End Function
#End Region

        ''' <summary>
        ''' Initializes a new instance of the TrackingLocation class and fills it with the data fom the IDataRecord. 
        ''' </summary>
        ''' <param name="myDataRecord">The Data record for the TrackingLocation produced by a select query</param>
        ''' <returns>A TrackingLocation object filled with the data from the IDataRecord object</returns>
        ''' <remarks></remarks>
        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord, ByVal qranumber As String) As TestException
            Dim myTestException As New TestException(qranumber)

            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("JobName")) Then
                myTestException.JobName = myDataRecord.GetString(myDataRecord.GetOrdinal("JobName"))
            End If
            If Helpers.HasColumn(myDataRecord, "QRANumber") Then
                If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("QRANumber")) Then
                    myTestException.QRAnumber = myDataRecord.GetString(myDataRecord.GetOrdinal("QRANumber"))
                End If
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ProductGroupName")) Then
                myTestException.ProductGroup = myDataRecord.GetString(myDataRecord.GetOrdinal("ProductGroupName"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ProductType")) Then
                myTestException.ProductType = myDataRecord.GetString(myDataRecord.GetOrdinal("ProductType"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ProductTypeID")) Then
                myTestException.ProductTypeID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ProductTypeID"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("AccessoryGroupName")) Then
                myTestException.AccessoryGroupName = myDataRecord.GetString(myDataRecord.GetOrdinal("AccessoryGroupName"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("AccessoryGroupID")) Then
                myTestException.AccessoryGroupID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("AccessoryGroupID"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestStageID")) Then
                myTestException.TestStageID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestStageID"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestUnitID")) Then
                myTestException.TestUnitID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestUnitID"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ReasonForRequestID")) Then
                myTestException.ReasonForRequestID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ReasonForRequestID"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ReasonForRequest")) Then
                myTestException.ReasonForRequest = myDataRecord.GetString(myDataRecord.GetOrdinal("ReasonForRequest"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("testname")) Then
                myTestException.TestName = myDataRecord.GetString(myDataRecord.GetOrdinal("testname"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestStageName")) Then
                myTestException.TestStageName = myDataRecord.GetString(myDataRecord.GetOrdinal("TestStageName"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("batchunitnumber")) Then
                myTestException.UnitNumber = myDataRecord.GetInt32(myDataRecord.GetOrdinal("batchunitnumber"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("ProductID")) Then
                myTestException.ProductID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ProductID"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestCenterID")) Then
                myTestException.TestCenterID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestCenterID"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("TestCenter")) Then
                myTestException.TestCenter = myDataRecord.GetString(myDataRecord.GetOrdinal("TestCenter"))
            End If
            If Not myDataRecord.IsDBNull(myDataRecord.GetOrdinal("IsMQual")) Then
                myTestException.IsMQual = myDataRecord.GetInt32(myDataRecord.GetOrdinal("IsMQual"))
            End If
            Helpers.FillObjectParameters(myDataRecord, myTestException)
            Return myTestException
        End Function
    End Class
End Namespace