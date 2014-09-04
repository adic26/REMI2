Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="Test">Tests</see>.
    ''' </summary>
    <Serializable()> _
    Public Class TestCollection
        Inherits REMICollectionBase(Of Test)

        ''' <summary> 
        ''' Initializes a new instance of the TestCollection class. 
        ''' </summary> 
        Public Sub New()
        End Sub

        Public Sub New(ByVal myList As IList(Of Test))
            MyBase.New(myList)
        End Sub

        Public Function FindByName(ByVal TestName As String) As Test
            Return (From t In Me Select t Where t.Name.Equals(TestName) Select t).FirstOrDefault
        End Function
        Public Function FindByID(ByVal ID As Integer) As Test
            Return (From t In Me Select t Where t.ID.Equals(ID) Select t).FirstOrDefault
        End Function
        Public Function ToDictionary() As SerializableDictionary(Of Integer, String)
            Dim sd As New SerializableDictionary(Of Integer, String)
            For Each t As Test In Me
                sd.Add(t.ID, t.Name)
            Next
            Return sd
        End Function
        Public Function ToStringArray() As String()
            If Me.Count > 0 Then
                Dim sA(Me.Count - 1) As String
                For i As Integer = 0 To (Me.Count - 1)
                    sA(i) = Me.Item(i).Name
                Next
                Return sA
            Else
                Dim sA(0) As String
                Return sA
            End If
        End Function
    End Class
End Namespace