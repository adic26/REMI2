Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Indicates the type of information represented in a given request number.
    ''' </summary>
    ''' <remarks></remarks>
    Public Enum QRANumberType
        ''' <summary> 
        ''' Indicates an unknown number type.
        ''' </summary> 
        NotSet = 0
        ''' <summary> 
        ''' Indicates a Batch number only - QRA-XX-XXXX
        ''' </summary> 
        BatchOnly = 1
        ''' <summary> 
        ''' Indicates a Batch and a unit number - QRA-XX-XXXX-XXX
        ''' </summary> 
        BatchAndUnit = 2
        ''' <summary> 
        ''' Indicates a Batch and a Tracking Location Number - QRA-XX-XXXX-XXXXX
        ''' </summary> 
        BatchAndTrackingLocation = 3
        ''' <summary> 
        ''' Indicates a Batch and a unit and a Tracking Location number - QRA-XX-XXXX-XXX-XXXXX
        ''' </summary> 
        BatchAndUnitAndTrackingLocation = 4

    End Enum
End Namespace