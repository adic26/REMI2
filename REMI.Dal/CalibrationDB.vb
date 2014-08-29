Imports System.Data.SqlClient
Imports REMI.Core
Imports REMI.BusinessEntities

Namespace REMI.Dal
    Public Class CalibrationDB

        Public Shared Function SaveCalibrationConfigurationXML(ByVal productID As Int32, ByVal hostID As Int32, ByVal testID As Int32, ByVal name As String, ByVal xml As XDocument, ByVal lastUser As String) As Boolean
            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispSaveCalibrationConfiguration", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myCommand.Parameters.AddWithValue("@HostID", hostID)
                    myCommand.Parameters.AddWithValue("@Name", name)
                    myCommand.Parameters.AddWithValue("@XML", xml.ToString())
                    myCommand.Parameters.AddWithValue("@LastUser", lastUser)
                    myConnection.Open()
                    myCommand.ExecuteNonQuery()
                End Using
            End Using
            Return True
        End Function

        Public Shared Function GetAllCalibrationConfigurationXML(ByVal productID As Int32, ByVal hostID As Int32, ByVal testID As Int32) As CalibrationCollection
            Dim tempList As New CalibrationCollection

            Using myConnection As New SqlConnection(REMIConfiguration.ConnectionStringREMI)
                Using myCommand As New SqlCommand("remispGetAllCalibrationXML", myConnection)
                    myCommand.CommandType = CommandType.StoredProcedure
                    myCommand.Parameters.AddWithValue("@productID", productID)
                    myCommand.Parameters.AddWithValue("@HostID", hostID)
                    myCommand.Parameters.AddWithValue("@TestID", testID)
                    myConnection.Open()
                    Using myReader As SqlDataReader = myCommand.ExecuteReader()
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

        Private Shared Function FillDataRecord(ByVal myDataRecord As IDataRecord) As Calibration
            Dim myCalibration As New Calibration()

            myCalibration.Name = myDataRecord.GetString(myDataRecord.GetOrdinal("Name"))
            myCalibration.ProductID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("ProductID"))
            myCalibration.HostID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("HostID"))
            myCalibration.TestID = myDataRecord.GetInt32(myDataRecord.GetOrdinal("TestID"))
            myCalibration.DateCreated = myDataRecord.GetDateTime(myDataRecord.GetOrdinal("DateCreated"))
            myCalibration.ProductGroupName = myDataRecord.GetString(myDataRecord.GetOrdinal("ProductGroupName"))
            myCalibration.TestName = myDataRecord.GetString(myDataRecord.GetOrdinal("TestName"))
            myCalibration.HostName = myDataRecord.GetString(myDataRecord.GetOrdinal("HostName"))
            myCalibration.File = myDataRecord.Item("File").ToString()

            Return myCalibration
        End Function
    End Class
End Namespace