Imports REMI.Contracts
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="Batch">Batches</see>.
    ''' </summary>
    <Serializable()> _
    Public Class BatchCollection
        Inherits REMICollectionBase(Of IBatch)
        Implements IEnumerable(Of IBatch)

        Public Sub New()
        End Sub

        Public Sub New(ByVal initialList As IList(Of IBatch))
            MyBase.New(initialList)
        End Sub

        Public Function GetUnitsAtLocation(ByVal barCodePrefix As Integer) As TestUnitCollection
            Dim tuColl As New TestUnitCollection
            For Each B As Batch In Me
                tuColl.Add(B.GetUnitsAtLocation(barCodePrefix))
            Next
            Return tuColl
        End Function
    End Class
End Namespace