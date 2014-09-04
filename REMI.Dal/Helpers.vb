
Imports System
Imports System.Data
Imports System.Data.Common
Imports System.Data.SqlClient
Imports REMI.BusinessEntities
Imports REMI.Contracts
Namespace REMI.Dal
    Public Class Helpers

        Const IDParamName As String = "@ID"
        Const ConcurrencyParamName As String = "@ConcurrencyID"
        Const LastUserParamName As String = "@LastUser"

        ''' <summary>
        ''' This sets the parameters defined in the abstract <see cref="LoggedItemBase">LoggedItemBase</see> class. They are defined here
        ''' becuase they repeat in almost every other class in the application. this class will set the ID, UpdateUser, InsertUser, 
        ''' parameters. It will also define a return parameter to the command. This class is used when writing to the databse and so is typically used for the Upsert
        ''' stored procedures.
        ''' </summary>
        ''' <param name="Command">The SQL command being used to write the object to the database</param>
        ''' <param name="LoggedItemBase">The object that we want to get the data from to write to the databsse</param>
        ''' <remarks></remarks>
        Friend Shared Sub SetSaveParameters(ByVal Command As SqlCommand, ByVal LoggedItemBase As LoggedItemBase)
            'the Id parameter
            Dim IDParam As DbParameter = Command.CreateParameter()
            IDParam.DbType = DbType.Int32
            IDParam.Direction = ParameterDirection.InputOutput
            IDParam.ParameterName = IDParamName
            If LoggedItemBase.ID = 0 Then
                IDParam.Value = DBNull.Value
            Else
                IDParam.Value = LoggedItemBase.ID
            End If
            Command.Parameters.Add(IDParam)

            'The user that is updating the record
            Dim LastUserParam As DbParameter = Command.CreateParameter()
            LastUserParam.DbType = DbType.String
            LastUserParam.Direction = ParameterDirection.Input
            LastUserParam.ParameterName = LastUserParamName
            If LoggedItemBase.LastUser = String.Empty Then
                LastUserParam.Value = DBNull.Value
            Else
                LastUserParam.Value = LoggedItemBase.LastUser
            End If
            Command.Parameters.Add(LastUserParam)

            'sets the concurrency id of the object to the database parameter
            Dim RowVersion As DbParameter = Command.CreateParameter()
            RowVersion.ParameterName = ConcurrencyParamName
            RowVersion.Direction = ParameterDirection.InputOutput
            RowVersion.DbType = DbType.Binary
            RowVersion.Size = 8
            If LoggedItemBase.ConcurrencyID Is Nothing Then
                RowVersion.Value = DBNull.Value
            Else
                RowVersion.Value = LoggedItemBase.ConcurrencyID
            End If
            Command.Parameters.Add(RowVersion)

            ' adds the return parameter to each of the commands that use this sub
            Dim returnValue As DbParameter = Command.CreateParameter()
            returnValue.Direction = ParameterDirection.ReturnValue
            Command.Parameters.Add(returnValue)
        End Sub
        ''' <summary>
        ''' This class fills the common parameters in the abstract <see cref="LoggedItemBase">LoggedItemBase</see> class. This can be used in all
        ''' DB classes that fill a data object derived from this class.
        ''' </summary>
        ''' <param name="myDataRecord">The data record to fill from.</param>
        ''' <param name="LoggedItemBase">The loggeditembase child to fill.</param>
        ''' <remarks></remarks>
        Friend Shared Sub FillObjectParameters(ByVal myDataRecord As IDataRecord, ByVal LoggedItemBase As ILoggedItem)
            LoggedItemBase.LastUser = myDataRecord.GetString(myDataRecord.GetOrdinal("LastUser"))
            LoggedItemBase.ID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ID"))

            If (Helpers.HasColumn(myDataRecord, "ConcurrencyID")) Then
                If (myDataRecord.GetValue(myDataRecord.GetOrdinal("ConcurrencyID")) IsNot System.DBNull.Value) Then
                    LoggedItemBase.ConcurrencyID = DirectCast(myDataRecord.GetValue(myDataRecord.GetOrdinal("ConcurrencyID")), Byte())
                End If
            End If
        End Sub
        ''' <summary>
        ''' Gets the timestamp concurrency value from the Idatareader
        ''' </summary>
        ''' <param name="command"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Friend Shared Function GetConcurrencyId(ByVal command As SqlCommand) As Byte()
            If (command.Parameters(ConcurrencyParamName).Value Is DBNull.Value) Then
                Return Nothing
            Else
                Return DirectCast(command.Parameters(ConcurrencyParamName).Value, Byte())
            End If
        End Function
        ''' <summary>
        ''' Gets the business base id (ID - integer) from the data reader.
        ''' </summary>
        ''' <param name="command"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Friend Shared Function GetBusinessBaseId(ByVal command As SqlCommand) As Integer
            If (command.Parameters(ConcurrencyParamName).Value Is DBNull.Value) Then
                Return Nothing
            Else
                Return CInt(command.Parameters(IDParamName).Value)
            End If
        End Function

        Public Shared Function HasColumn(dr As IDataRecord, columnName As String) As Boolean
            For i As Integer = 0 To dr.FieldCount - 1
                If dr.GetName(i).Equals(columnName, StringComparison.InvariantCultureIgnoreCase) Then
                    Return True
                End If
            Next
            Return False
        End Function
    End Class

End Namespace