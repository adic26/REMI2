Namespace REMI.BusinessEntities
    ''' <summary> 
    ''' Indicates the Final Result of a test.
    ''' </summary> 
    Public Enum FinalTestResult
        ''' <summary> 
        ''' This indicates an unidentified value. 
        ''' </summary> 
        NotSet = 0
        ''' <summary> 
        ''' Indicates that the device passed the test. 
        ''' </summary> 
        Pass = 1
        ''' <summary> 
        ''' Indicates that the device failed the test. 
        ''' </summary> 
        Fail = 2
    End Enum
End Namespace