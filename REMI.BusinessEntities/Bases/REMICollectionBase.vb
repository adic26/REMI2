Imports REMI.Validation
Namespace REMI.BusinessEntities
    ''' <summary> 
    ''' This is the base class for all collections within the project. It uses the collection generic and impliments a custom sort
    ''' function to compliment the collection type.
    ''' </summary> 
    ''' ''' <typeparam name="T">A class that inherits ValidationBase.</typeparam> 
    <Serializable()> _
    Public Class REMICollectionBase(Of T As IValidatable)
        Inherits ValidationCollectionBase(Of T)

        ''' <summary> 
        ''' Initializes a new instance of the BusinessCollectionBase class. 
        ''' </summary> 
        Public Sub New()
        End Sub
        Public Overloads Sub Add(ByVal IC As ValidationCollectionBase(Of T))
            For Each T In IC
                MyBase.Add(T)
            Next
        End Sub
        ''' <summary>
        ''' Overrides the default tostring to return the count in the collection
        ''' </summary>
        ''' <returns>The number of items in the collection</returns>
        ''' <remarks></remarks>
        Public Overrides Function ToString() As String
            Return Me.Count.ToString
        End Function

        ''' <summary> 
        ''' Initializes a new instance of the BusinessCollectionBase class and populates it with the initial list. 
        ''' </summary> 
        Public Sub New(ByVal InitialList As IList(Of T))
            MyBase.New(InitialList)
        End Sub
    End Class
End Namespace