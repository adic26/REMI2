Namespace REMI.BusinessEntities
    ''' <summary> 
    ''' Indicates the type of tracking location. 
    ''' </summary> 
    Public Enum TrackingLocationFunction
        ''' <summary> 
        ''' Indicates an unidentified value.
        ''' </summary> 
        NotSet = 0
        ''' <summary> 
        ''' Indicates the tracking location is a shelf or inventory location.
        ''' </summary> 
        NonTesting = 1
        ''' <summary> 
        ''' Indicates the tracking location is a Test Station that will have a result.
        ''' </summary> 
        Testing = 2
        ''' <summary>
        ''' Indicates the trackinglocation is a Gateway to an external location such as dust lab etc
        ''' </summary>
        ''' <remarks></remarks>
        ExternalLocation = 3
        ''' <summary>
        ''' Indicates the trackinglocation is chamber type device
        ''' </summary>
        ''' <remarks></remarks>
        EnvironmentalStressing = 4
        ''' <summary>
        ''' Indicates the trackinglocation is for incoming
        ''' </summary>
        ''' <remarks></remarks>
        IncomingLabeling = 5
        ''' <summary>
        ''' Indicates the trackinglocation is a remstar
        ''' </summary>
        ''' <remarks></remarks>
        REMSTAR = 6
    End Enum
End Namespace