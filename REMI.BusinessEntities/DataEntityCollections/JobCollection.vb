Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="Job">Jobs</see>.
    ''' </summary>
    Public Class JobCollection
        Inherits REMICollectionBase(Of Job)
        ''' <summary>
        ''' this function takes the trs jobs list and creates any missing jobs in the jobs list
        ''' </summary>
        ''' <param name="trsJobs"></param>
        ''' <remarks></remarks>
        Public Sub ValidateAgainstTRSList(ByVal trsJobs As List(Of String))
            If trsJobs IsNot Nothing AndAlso trsJobs.Count > 0 Then
                For Each j As String In trsJobs
                    If Me.FindByName(j) Is Nothing Then
                        Me.Add(New Job(j))
                    End If
                Next
            End If
        End Sub
        Public Function FindByName(ByVal jobName As String) As Job
            For Each j As Job In Me
                If j.Name = jobName Then
                    Return j
                End If
            Next
            Return Nothing
        End Function
        Public Function ToDictionary() As SerializableDictionary(Of Integer, String)
            Dim sd As New SerializableDictionary(Of Integer, String)
            For Each j As Job In Me
                sd.Add(j.ID, j.Name)
            Next
            Return sd
        End Function
        Public Function ToStringArray() As String()
            If Me.Count > 0 Then
                Dim sA(Me.Count) As String
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