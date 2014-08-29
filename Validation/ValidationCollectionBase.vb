Imports System.Collections.ObjectModel
Namespace REMI.Validation
    ''' <summary> 
    ''' The ValidationCollectionBase class serves as the base class for collections like BusinessCollectionBase. 
    ''' The entire collection class provides validation by checking the validity of the ValidationBase 
    ''' instances in its Items collection. 
    ''' </summary> 
    ''' <typeparam name="T">A class implementing from IValidatable.</typeparam> 
    <Serializable()> _
    Public MustInherit Class ValidationCollectionBase(Of T As IValidatable)
        Inherits List(Of T)
        ''' <summary> 
        ''' Initializes a new instance of the ValidationCollection class. 
        ''' </summary> 
        Public Sub New()
            MyBase.New(New List(Of T)())
        End Sub

        ''' <summary> 
        ''' Initializes a new instance of the ValidationCollection class and populates it with the initial list. 
        ''' </summary> 
        Public Sub New(ByVal InitialList As IList(Of T))
            MyBase.New(InitialList)
        End Sub

        ''' <summary> 
        ''' Determines whether this instance is valid. 
        ''' </summary> 
        ''' <returns> 
        ''' <c>true</c> if this instance is valid; otherwise, <c>false</c>. 
        ''' </returns> 
        Public Overridable Function Validate() As Boolean
            For Each Item As T In Me
                If Not Item.Validate() Then
                    Return False
                End If
            Next
            Return True
        End Function
    End Class
End Namespace