Imports REMI.Validation
Imports System.Text.RegularExpressions
Imports REMI.Contracts

Namespace REMI.BusinessEntities
    <Serializable()> _
    Public Class RequestNumber
        Inherits ValidationBase

        Private _number As String

#Region "Constructor"
        ''' <summary>
        ''' Constructor
        ''' </summary>
        ''' <param name="BarcodeNumber">The string containing the barcode number</param>
        ''' <remarks></remarks>
        Public Sub New(ByVal barcodeNumber As String)
            Dim tmpNumber As Integer
            If Not String.IsNullOrEmpty(barcodeNumber) Then
                If barcodeNumber.Length = 4 AndAlso Integer.TryParse(barcodeNumber, tmpNumber) Then
                    _number = String.Format("{0:yy}-{1}", DateTime.Now, barcodeNumber)
                Else
                    _number = barcodeNumber.ToUpperInvariant
                End If
            End If
        End Sub

        Public Sub New(ByVal barcodeNumber As String, ByVal unitNumber As String)
            Dim tmpNumber As Integer
            unitNumber = unitNumber.PadLeft(3, CChar("0"))

            If Not String.IsNullOrEmpty(barcodeNumber) Then
                If barcodeNumber.Length = 4 AndAlso Integer.TryParse(barcodeNumber, tmpNumber) Then
                    _number = String.Format("{0:yy}-{1}", DateTime.Now, String.Format("{0}-{1}", barcodeNumber, unitNumber))
                Else
                    _number = String.Format("{0}-{1}", barcodeNumber.ToUpperInvariant, unitNumber)
                End If
            End If
        End Sub

        Public Sub New()
            _number = String.Empty
        End Sub
#End Region

        ''' <summary>
        ''' The whole text number of the request: ie whatever was input in the constructor
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        <ValidTRSRequestString(Key:="w5")> _
        Public Property Number() As String
            Set(ByVal value As String)
                _number = value
            End Set
            Get
                Return _number
            End Get
        End Property

        ''' <summary>
        ''' The type of request represented in this instance of number.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public ReadOnly Property Type() As String
            Get
                Return Number.Substring(0, Number.IndexOf("-"))
            End Get
        End Property

        Public Overrides Function ToString() As String
            Return Me.Number
        End Function
    End Class
End Namespace