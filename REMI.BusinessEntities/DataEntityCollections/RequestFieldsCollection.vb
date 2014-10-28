Imports REMI.Contracts
Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="Batch">Batches</see>.
    ''' </summary>
    <Serializable()> _
    Public Class RequestFieldsCollection
        Inherits REMICollectionBase(Of RequestFields)

        Public Sub New()
        End Sub
    End Class
End Namespace