Imports System
Namespace REMI.Validation
    ''' <summary> 
    ''' The ValidRangeAttribute class allows you to make sure that a numeric value falls between a Min and a Max value. 
    ''' </summary> 
    <AttributeUsage(AttributeTargets.[Property])> _
    Public NotInheritable Class ValidRangeAttribute
        Inherits ValidationAttribute
        ''' <summary> 
        ''' Gets or sets a value that determines the minimum value (inclusive) for the underlying value to be valid. 
        ''' </summary> 
        ''' <remarks>The minimum value.</remarks>
        Private _Min As Double
        Public Property Min() As Double
            Get
                Return _Min
            End Get
            Set(ByVal value As Double)
                _Min = value
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets a value that determines the maximum value (inclusive) for the underlying value to be valid. 
        ''' </summary> 
        ''' <remarks>The maximum value.</remarks> 
        Private _Max As Double
        Public Property Max() As Double
            Get
                Return _Max
            End Get
            Set(ByVal value As Double)
                _Max = value
            End Set
        End Property

        ''' <summary> 
        ''' Determines whether the value of the underlying property falls between the Min and Max values. 
        ''' </summary> 
        ''' <param name="item">The underlying value of the propery that is being validated.</param> 
        ''' <returns> 
        ''' <c>true</c> if the specified item falls between Min and Max (inclusive); otherwise, <c>false</c>. 
        ''' </returns> 
        Public Overloads Overrides Function IsValid(ByVal item As Object) As Boolean
            Dim tempValue As Double = Convert.ToDouble(item)
            Return tempValue >= Min AndAlso tempValue <= Max
        End Function
    End Class
End Namespace