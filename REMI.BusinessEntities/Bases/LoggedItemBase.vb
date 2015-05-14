Imports REMI.Validation
Imports REMI.Contracts
Namespace REMI.BusinessEntities
    ''' <summary> 
    ''' This is the base class for an item with standard logging. Any item that needs to be tracked for writes and updates will use this class.
    ''' </summary> 
    <Serializable()> _
        Public MustInherit Class LoggedItemBase
        Inherits BusinessBase
        Implements ILoggedItem

#Region "Private Variables"
        Private _lastUser As String
#End Region

#Region "Public Properties"

        ''' <summary> 
        ''' Gets or sets the name of the user who preformed the insert of the item.
        ''' </summary> 
        <NotNullOrEmpty(Key:="w4")> _
        <DataTableColName("LastUser")> _
        Public Property LastUser() As String Implements ILoggedItem.LastUser
            Get
                Return _lastUser
            End Get
            Set(ByVal value As String)
                _lastUser = value
            End Set
        End Property
#End Region

    End Class
End Namespace