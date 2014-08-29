Imports System.Text.RegularExpressions
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' This class represents a tracking location barcode.
    ''' </summary>
    ''' <remarks></remarks>
    Public Class TrackingLocationBarcodeNumber

#Region "Private Variables"
        Private _Number As String
#End Region

#Region "Constructor"
        ''' <summary>
        ''' constructor
        ''' </summary>
        ''' <param name="Number">the scanned barcode number</param>
        ''' <remarks></remarks>
        Public Sub New(ByVal Number As String)
            If ValidateBarcodeNumber(Number) Then
                _Number = Number
            Else
                Throw New Exception("Unable to validate barcode number!")
            End If
        End Sub
#End Region

#Region "Public Properties"
        ''' <summary>
        ''' Gets or sets the full barcode number and validates it if setting.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property Number() As String
            Set(ByVal value As String)
                If ValidateBarcodeNumber(value) Then
                    _Number = value
                Else
                    Throw New Exception("Unable to validate barcode number!")
                End If
            End Set
            Get
                Return _Number
            End Get
        End Property

        ''' <summary>
        ''' returns the id number of the tracking location as parsed from the tracking location barcode.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property TrackingLocationNumber() As Integer
            Get
                Return Integer.Parse(_Number.Substring(12, 5))
            End Get
        End Property
#End Region

#Region "Private Functions"
        ''' <summary>
        ''' This validates the barcode.
        ''' </summary>
        ''' <param name="Number"></param>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Private Function ValidateBarcodeNumber(ByVal Number As String) As Boolean
            Select Case Number.Length
                Case 8
                    If Regex.IsMatch(Number, "^TL-([0-9]){5}$") Then
                        Return True
                    Else
                        Return False
                    End If
                Case Else
                    Return False
            End Select
        End Function
#End Region

#Region "Public Functions"
        ''' <summary>
        ''' This returns the full barcode when tostring is accessed.
        ''' </summary>
        ''' <returns>The number of the barcode</returns>
        ''' <remarks></remarks>
        Public Overrides Function ToString() As String
            Return _Number
        End Function
#End Region
    End Class
End Namespace