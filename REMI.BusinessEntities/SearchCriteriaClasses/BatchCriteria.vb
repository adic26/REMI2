Imports REMI.Contracts
Namespace REMI.BusinessEntities
    ''' <summary> 
    ''' A simple criteria class used to search for Batch instances. 
    ''' </summary> 
    Public Class BatchCriteria
#Region "Private Variables"
        Private _id As Integer
        Private _qraNumber As String
        Private _productGroupName As String
        Private _batchStatus As BatchStatus
        Private _productID As Int32
#End Region
#Region "Public properties"


        Public Property ID() As Integer
            Get
                Return _id
            End Get
            Set(ByVal value As Integer)
                _id = value
            End Set
        End Property

        ''' <summary> 
        ''' Contains (part of) the QRA Number to search for. 
        ''' </summary> 
        Public Property QRANumber() As String
            Get
                Return _qraNumber
            End Get
            Set(ByVal value As String)
                _qraNumber = value
            End Set
        End Property

        ''' <summary> 
        ''' Contains the product group name of the batch to search for.
        ''' </summary> 
        Public Property ProductGroupName() As String
            Get
                Return _productGroupName
            End Get
            Set(ByVal value As String)
                _productGroupName = value
            End Set
        End Property

        Public Property ProductID() As Int32
            Get
                Return _productID
            End Get
            Set(ByVal value As Int32)
                _productID = value
            End Set
        End Property

        ''' <summary>
        ''' Contains the batch status to search for.
        ''' </summary>
        ''' <value></value>
        ''' <returns></returns>
        ''' <remarks></remarks>
        Public Property BatchStatus() As BatchStatus
            Get
                Return _batchStatus
            End Get
            Set(ByVal value As BatchStatus)
                _batchStatus = value
            End Set
        End Property
#End Region
    End Class
End Namespace