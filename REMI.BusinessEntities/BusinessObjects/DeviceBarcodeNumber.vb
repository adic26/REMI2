Imports REMI.Validation
Imports System.Text.RegularExpressions
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a TRS QRA Number
    ''' </summary>
    ''' <remarks></remarks>
    Public Class DeviceBarcodeNumber
        Inherits RequestNumber

        Public Sub New(ByVal qraNumber As String)
            MyBase.New(qraNumber)
        End Sub

        Public Sub New(ByVal qraNumber As String, ByVal unitNumber As String)
            MyBase.New(qraNumber, unitNumber)
        End Sub

#Region "Public Properties"
        ''' <summary>
        ''' The QRA number of the batch represented in this instance: QRA-yy-bbbb
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property BatchNumber() As String
            Get
                Return Number.Substring(0, 11)
            End Get
        End Property

        ''' <summary>
        ''' The unit number component of the barcode.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property UnitNumber() As Integer
            Get
                If DetailAvailable = QRANumberType.BatchAndUnit Or DetailAvailable = QRANumberType.BatchAndUnitAndTrackingLocation Then
                    Return Integer.Parse(Number.Substring(12, 3))
                Else
                    Return 0
                End If
            End Get
        End Property

        ''' <summary>
        ''' The string representation of the tracking location barcode prefix component of the barcode
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property TrackingLocationNumber() As String
            Get
                If DetailAvailable = QRANumberType.BatchAndTrackingLocation Then
                    Return Number.Substring(12, 5)
                ElseIf DetailAvailable = QRANumberType.BatchAndUnitAndTrackingLocation Then
                    Return Number.Substring(16, 5)
                Else
                    Return String.Empty
                End If
            End Get
        End Property

        ''' <summary>
        ''' The integer representation of the tracking location barcode prefix component of the barcode
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property TrackingLocationNumberAsInteger() As Integer
            Get
                Dim TLID As Integer
                If DetailAvailable = QRANumberType.BatchAndTrackingLocation Then
                    Integer.TryParse(Number.Substring(12, 5), TLID)
                ElseIf DetailAvailable = QRANumberType.BatchAndUnitAndTrackingLocation Then
                    Integer.TryParse(Number.Substring(16, 5), TLID)
                End If
                Return TLID
            End Get
        End Property

        Public ReadOnly Property DetailAvailable() As QRANumberType
            Get
                If Not String.IsNullOrEmpty(Number) Then
                    Select Case Number.Length
                        Case 11
                            If Regex.IsMatch(Number, "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}$") Then
                                Return QRANumberType.BatchOnly
                            End If

                        Case 15
                            If Regex.IsMatch(Number, "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}[-]([0-9]){3}$") Then
                                Return QRANumberType.BatchAndUnit
                            End If
                        Case 17
                            If Regex.IsMatch(Number, "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}[-]([0-9]){5}$") Then
                                Return QRANumberType.BatchAndTrackingLocation
                            End If
                        Case 21
                            If Regex.IsMatch(Number, "^([a-zA-Z]){3}[-]([0-9]){2}[-]([0-9]){4}[-]([0-9]){3}[-]([0-9]){5}$") Then
                                Return QRANumberType.BatchAndUnitAndTrackingLocation
                            End If
                        Case 4
                            If Regex.IsMatch(String.Format("{0}-{1}", DateTime.Now.Year.ToString().Substring(2), Number), "^([0-9]){2}[-]([0-9]){4}$") Then
                                Return QRANumberType.BatchOnly
                            End If
                        Case Else
                            Return QRANumberType.NotSet
                    End Select
                Else
                    Return QRANumberType.NotSet
                End If
                Return QRANumberType.NotSet
            End Get
        End Property
#End Region

#Region "Public Functions"
        ''' <summary>
        ''' Overrides the regular string function to return the batch and unit number components of the barcode:QRA-yy-bbbb-uuu
        ''' </summary>
        ''' <returns>the batch number or the batch and unit number depending on the type of barcode.</returns>
        ''' <remarks></remarks>
        Public Overrides Function ToString() As String
            If UnitNumber > 0 Then
                Return String.Format("{0}-{1:d3}", BatchNumber, UnitNumber)
            Else
                Return BatchNumber
            End If
        End Function

        ''' <summary>
        ''' Forces a change to the new tracing location number
        ''' </summary>
        ''' <param name="newTrackingLocationID"></param>
        ''' <param name="overrideCurrentTrackingLocation"></param>
        ''' <remarks></remarks>
        Public Sub SetTrackingLocationPart(ByVal newTrackingLocationID As String, ByVal overrideCurrentTrackingLocation As Boolean)
            If TrackingLocationNumberAsInteger <= 0 OrElse overrideCurrentTrackingLocation Then
                Dim tlID As Integer
                Integer.TryParse(newTrackingLocationID, tlID)
                Number = String.Format("{0}-{1:d5}", Number, tlID)
            End If
        End Sub

        ''' <summary>
        ''' Validates the barcode number, also checks if a unit number is required and is valid
        ''' </summary>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Overrides Function Validate() As Boolean
            Dim baseValid As Boolean = MyBase.Validate
            Dim localValid As Boolean = True

            If Me.HasTestUnitNumber AndAlso UnitNumber <= 0 Then
                Notifications.Add("w6", NotificationType.Errors)
                localValid = False
            End If
            Return baseValid AndAlso localValid
        End Function

        Public Function HasTestUnitNumber() As Boolean
            If DetailAvailable = QRANumberType.BatchAndUnit Or DetailAvailable = QRANumberType.BatchAndUnitAndTrackingLocation Then
                Return True
            Else
                Return False
            End If
        End Function
#End Region
    End Class
End Namespace