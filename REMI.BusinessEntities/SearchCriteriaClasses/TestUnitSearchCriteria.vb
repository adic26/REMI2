Namespace REMI.BusinessEntities
    Public Class TestUnitCriteria

#Region "Private Variables"
        Private _bsn As Int32
#End Region

#Region "Constructors"
        Public Sub New()
        End Sub
#End Region

#Region "Public properties"
        Public Property BSN() As Int32
            Get
                Return _bsn
            End Get
            Set(ByVal value As Int32)
                _bsn = value
            End Set
        End Property
#End Region

    End Class
End Namespace