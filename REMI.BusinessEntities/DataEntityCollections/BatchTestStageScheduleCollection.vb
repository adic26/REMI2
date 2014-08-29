Namespace REMI.BusinessEntities
    Public Class BatchTestStageScheduleCollection
        Inherits REMICollectionBase(Of BatchTestStageSchedule)

        ''' <summary> 
        ''' Initializes a new instance of the BatchCollection class. 
        ''' </summary> 
        Public Sub New()
        End Sub
        Public Function FindByTestStageName(ByVal teststagename As String) As BatchTestStageSchedule
            For Each bts As BatchTestStageSchedule In Me
                If bts.TestStageName = teststagename Then
                    Return bts
                End If
            Next
            Return Nothing
        End Function
    End Class
End Namespace