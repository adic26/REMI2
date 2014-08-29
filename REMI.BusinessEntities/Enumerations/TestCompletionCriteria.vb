Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Indicates how a test is defined as completed
    ''' </summary>
    ''' <remarks></remarks>
    Public Enum TestCompletionCriteria
        ''' <summary>
        ''' indicates an unknown value
        ''' </summary>
        ''' <remarks></remarks>
        NotSet = 0
        ''' <summary>
        ''' Indicates the test is passed when the number of tests is complete - cycles, drops etc.
        ''' </summary>
        ''' <remarks></remarks>
        TestCount = 1
        ''' <summary>
        ''' Indicates a test is passed when the duration is met.
        ''' </summary>
        ''' <remarks></remarks>
        TestDuration = 2
    End Enum
End Namespace