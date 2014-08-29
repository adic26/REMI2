Namespace REMI.BusinessEntities
    Public Class TestResultCollection
        Inherits REMICollectionBase(Of TestResult)
#Region "Constructors"
        Public Sub New(ByVal myList As IList(Of TestResult))
            MyBase.New(myList)
        End Sub

        Public Sub New()

        End Sub

#End Region

    End Class
End Namespace