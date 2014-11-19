Imports REMI.BusinessEntities
Imports REMI.Dal
Imports REMI.Validation

Namespace REMI.Bll
    Public Class TrackingLogManager
        Inherits REMIManagerBase

        Public Shared Function GetLastTrackingLog(ByVal Barcode As DeviceBarcodeNumber) As DeviceTrackingLog
            Try
                Return DeviceTrackingLogDB.GetLastLog(Barcode)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function

        Public Shared Function GetLastTrackingLog(ByVal testUnitID As Integer) As DeviceTrackingLog
            Try
                Return DeviceTrackingLogDB.GetLastLog(testUnitID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestUnitID: {0}", testUnitID))
            End Try
            Return Nothing
        End Function

        Public Shared Function Get24HourLogsForBatch(ByVal QRANumber As String, ByVal TimeInHours As Integer) As DeviceTrackingLogCollection
            Try
                Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
                If bc.Validate Then

                    Dim dt As DateTime = DateTime.UtcNow.Subtract(TimeSpan.FromHours(TimeInHours))
                    'sql server cannot handle dates less than 1750ish so we must check the date here
                    'To make sure its not crazy. nothing before 2000 makes sense so thats the limit.
                    If dt.Year <= 2000 Then
                        dt = dt.AddYears(2000 - dt.Year)
                    End If
                    Return DeviceTrackingLogDB.GetListByBarcodeDate(bc.BatchNumber, dt)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("Request: {0}", QRANumber))
            End Try
            Return New DeviceTrackingLogCollection
        End Function

        ''' <summary>
        ''' Gets the current log of a test unit
        ''' </summary>
        ''' <param name="testUnitID"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Shared Function GetCurrentLog(ByVal testUnitID As Integer) As DeviceTrackingLog
            Dim tmpdtl As DeviceTrackingLog = DeviceTrackingLogDB.GetLastLog(testUnitID)
            Try
                If Not tmpdtl Is Nothing Then
                    Return tmpdtl
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestUnitID: {0}", testUnitID))
            End Try
            Return New DeviceTrackingLog
        End Function

        Public Shared Function Get24HourLogsForProduct(ByVal productID As Int32, ByVal TimeInHours As Integer) As DeviceTrackingLogCollection
            Try
                Dim dt As DateTime = DateTime.UtcNow.Subtract(TimeSpan.FromHours(TimeInHours))
                'sql server cannot handle dates less than 1750ish so we must check the date here
                'To make sure its not crazy. nothing before 2000 makes sense so thats the limit.
                If dt.Year <= 2000 Then
                    dt = dt.AddYears(2000 - dt.Year)
                End If
                Return DeviceTrackingLogDB.GetListByProductDate(productID, dt)

            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("ProductGroup: {0}", productID))
            End Try
            Return New DeviceTrackingLogCollection
        End Function

        Public Shared Function Get24HourLogsForTestUnit(ByVal testUnitID As Integer, ByVal TimeInHours As Integer) As DeviceTrackingLogCollection
            Try
                Dim dt As DateTime = DateTime.UtcNow.Subtract(TimeSpan.FromHours(TimeInHours))
                'sql server cannot handle dates less than 1750ish so we must check the date here
                'To make sure its not crazy. nothing before 2000 makes sense so thats the limit.
                If dt.Year <= 2000 Then
                    dt = dt.AddYears(2000 - dt.Year)
                End If
                Return DeviceTrackingLogDB.GetListByTestUnitIDDate(testUnitID, dt)

            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestUnitID: {0}", testUnitID))
            End Try
            Return New DeviceTrackingLogCollection
        End Function

        Public Shared Function Get24HourLogsForLocation(ByVal ID As Integer, ByVal TimeInHours As Integer) As DeviceTrackingLogCollection
            Try
                Dim dt As DateTime = DateTime.UtcNow.Subtract(TimeSpan.FromHours(TimeInHours))
                'sql server cannot handle dates less than 1750ish so we must check the date here
                'To make sure its not crazy. nothing before 2000 makes sense so thats the limit.
                If dt.Year <= 2000 Then
                    dt = dt.AddYears(2000 - dt.Year)
                End If
                Return DeviceTrackingLogDB.GetListByLocationDate(ID, dt)

            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("ID: {0}", ID))
            End Try
            Return New DeviceTrackingLogCollection
        End Function

        Public Shared Function GetTrackingLogsForTestRecord(ByVal trID As Integer) As DeviceTrackingLogCollection
            Try
                Return DeviceTrackingLogDB.GetLogsByTestRecordID(trID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("TestRecordID: {0}", trID))
            End Try
            Return New DeviceTrackingLogCollection
        End Function

        Public Shared Function GetTrackingLogsForUnitByBarcode(ByVal QRANumber As String) As DeviceTrackingLogCollection
            Dim bc As New DeviceBarcodeNumber(BatchManager.GetReqString(QRANumber))
            Try
                If bc.Validate Then
                    Return DeviceTrackingLogDB.GetListByBarcodeInfo(bc.BatchNumber, bc.UnitNumber, -1, -1)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("RequestNumber: {0}", QRANumber))
            End Try
            Return New DeviceTrackingLogCollection
        End Function
    End Class
End Namespace