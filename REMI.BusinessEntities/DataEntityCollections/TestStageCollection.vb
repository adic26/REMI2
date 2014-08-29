Imports REMI.Contracts

Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="TestStage">Test Stages</see>.
    ''' </summary>
    <Serializable()> _
    Public Class TestStageCollection
        Inherits REMICollectionBase(Of TestStage)

        ''' <summary> 
        ''' Initializes a new instance of the BatchCollection class. 
        ''' </summary> 
        Public Sub New()
        End Sub
        Public Sub New(ByVal tsList As List(Of TestStage))
            MyBase.New(tsList)
        End Sub
        Public Function Duration() As TimeSpan
            Dim totalTime As New TimeSpan
            For Each ts As TestStage In Me
                totalTime.Add(ts.Duration)
            Next
            Return totalTime
        End Function
        Public Function FindByName(ByVal tsName As String) As TestStage
            Return (From ts In Me Where ts.Name.Equals(tsName) Select ts).SingleOrDefault
        End Function
        Public Function FindByID(ByVal id As Int32) As TestStage
            Return (From ts In Me Where ts.ID.Equals(id) Select ts).SingleOrDefault
        End Function
        Public Function FindByType(ByVal tsType As TestStageType) As TestStageCollection
            Return New TestStageCollection((From ts In Me Where ts.TestStageType.Equals(tsType) And ts.IsArchived = False Select ts Order By (ts.ProcessOrder) Ascending).ToList)
        End Function
        Public Function ToDictionary() As SerializableDictionary(Of Integer, String)
            Dim sd As New SerializableDictionary(Of Integer, String)
            For Each ts As TestStage In Me
                sd.Add(ts.ID, ts.Name)
            Next
            Return sd
        End Function
        Public Function ToStringArray() As String()
            If Me.Count > 0 Then
                Dim sA(Me.Count - 1) As String
                For i As Integer = 0 To Me.Count - 1
                    sA(i) = Me.Item(i).Name
                Next i
                Return sA
            Else
                Dim sA(0) As String
                Return sA
            End If
        End Function
    End Class
End Namespace