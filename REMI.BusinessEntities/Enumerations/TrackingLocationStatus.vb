Namespace REMI.BusinessEntities
    ''' <summary> 
    ''' Indicates the status of a test station, chamber or test equipment. 
    ''' </summary> 
    Public Enum TrackingLocationStatus
        ''' <summary> 
        ''' Indicates an unknown status. 
        ''' </summary> 
        NotSet = 0
        ''' <summary> 
        ''' Indicates the test station is currently available for assignment. 
        ''' </summary> 
        Available = 1
        ''' <summary> 
        ''' Indicates the test station is out of service and no test should be assigned. 
        ''' </summary> 
        UnderMaintenance = 2
        ''' <summary> 
        ''' Indicates the test station is currently unavailable for assignment. 
        ''' </summary> 
        UnAvailable = 3
        ''' <summary> 
        ''' Indicates the test station status is unknown.
        ''' </summary> 
        Unknown = 4
    End Enum
End Namespace