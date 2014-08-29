Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="TestUnit">Test Units</see>.
    ''' </summary>
    <Serializable()> _
   Public Class TestUnitCollection
        Inherits REMICollectionBase(Of TestUnit)
#Region "constructors"
        Public Sub New(ByVal tuList As List(Of TestUnit))
            MyBase.New(tuList)
        End Sub
        Public Sub New()

        End Sub
#End Region
#Region "public methods"
        Public Function FindByID(ByVal ID As Integer) As TestUnit
            Return (From t In Me Where t.ID.Equals(ID) Select t).SingleOrDefault
        End Function
        Public Function FindByBatchUnitNumber(ByVal UnitNumber As Integer) As TestUnit
            Return (From t In Me Where t.BatchUnitNumber.Equals(UnitNumber) Select t).SingleOrDefault
        End Function
        Public Function FindByLocation(ByVal barcodeNumber As Integer) As TestUnitCollection
            Return New TestUnitCollection((From t In Me Where t.CurrentLocationBarcodePrefix.Equals(barcodeNumber) Select t).ToList)
        End Function
        Public Overloads Sub Add(ByVal tuColl As TestUnitCollection)
            For Each tu As TestUnit In tuColl
                MyBase.Add(tu)
            Next
        End Sub
#End Region
    End Class

End Namespace