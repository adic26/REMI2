Imports REMI.Contracts
Imports REMI.Validation

Namespace REMI.BusinessEntities
    ''' <summary> 
    ''' The BusinessBase class serves as the base class for all business entities in the REMI.BusinessEntities namespace. 
    ''' Since it inherits from ValidationBase, it provides validation behavior to its child classes. Additionally, it implements 
    ''' default behavior for concurrency checks. 
    ''' </summary> 
    <Serializable()> _
    Public MustInherit Class BusinessBase
        Inherits ValidationBase
        Implements IBusinessBase

#Region "Private Variables"
        Private _concurrencyID As Byte()
        Private _id As Integer
#End Region

        ''' <summary> 
        ''' The ID of the BusinessBase instance in the database. 
        ''' </summary> 
        Public Overridable Property ID() As Integer Implements IBusinessBase.ID
            Get
                Return _id
            End Get
            Set(ByVal value As Integer)
                _id = value
            End Set
        End Property

        ''' <summary> 
        ''' Gets or sets a concurrency id that is used to keep track of changes made to the underlying data record in the database. 
        ''' </summary> 
        ''' <remarks>The concurrency id.</remarks> 
        Public Property ConcurrencyID() As Byte() Implements IBusinessBase.ConcurrencyID
            Get
                Return _concurrencyID
            End Get
            Set(ByVal value As Byte())
                _concurrencyID = value
            End Set
        End Property
        Public Function IsNew() As Boolean Implements IBusinessBase.IsNew
            Return ID <= 0
        End Function
    End Class
End Namespace