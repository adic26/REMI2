Imports REMI.Dal.Entities
Imports REMI.Core

Namespace REMI.Dal
    Public Class Entities

        Private _context As REMI.Entities.Entities

        Public Sub New()
            _context = New REMI.Entities.Entities(REMIConfiguration.ConnectionStringREMIEntity)
        End Sub

        Public ReadOnly Property Instance() As REMI.Entities.Entities
            Get
                Return _context
            End Get
        End Property
    End Class
End Namespace