Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="Test">Tests</see>.
    ''' </summary>
    <Serializable()> _
    Public Class TestExceptionCollection
        Inherits REMICollectionBase(Of TestException)

        ''' <summary> 
        ''' Initializes a new instance of the TestCollection class. 
        ''' </summary> 
        Public Sub New()
        End Sub

        Public Function UnitIsExempt(ByVal unitNumber As Integer, ByVal testStageID As Int32, ByVal testID As Int32, ByRef tasks As System.Collections.Generic.List(Of Contracts.ITaskModel)) As Boolean
            Dim isExempt As Boolean
            If (From t In tasks Where t.TestStageID = testStageID And t.TestID = testID And t.UnitsForTask.Contains(unitNumber) Select t).FirstOrDefault() Is Nothing Then
                isExempt = True
            End If

            Return isExempt
        End Function
    End Class
End Namespace