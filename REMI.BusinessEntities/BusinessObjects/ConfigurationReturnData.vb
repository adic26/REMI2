Imports REMI.Validation
Imports System.Xml.Serialization

Namespace REMI.BusinessEntities

    <Serializable()> _
    Public Class ConfigurationReturnData
        Inherits ValidationBase

        Private _testXML As String
        Private _stationXML As String
        Private _hasProductXML As Boolean
        Private _hasCalibrationXML As Boolean
        Private _hasStationXML As Boolean
        Private _hostID As Int32
        Private _calibrations As CalibrationCollection
        Private _productConfigs As ProductConfigCollection

        Public Sub New()
        End Sub

        Public Property Calibrations As CalibrationCollection
            Get
                Return _calibrations
            End Get
            Set(value As CalibrationCollection)
                _calibrations = value
            End Set
        End Property

        Public Property ProductConfigs As ProductConfigCollection
            Get
                Return _productConfigs
            End Get
            Set(value As ProductConfigCollection)
                _productConfigs = value
            End Set
        End Property


        Public Property StationXML As String
            Get
                Return _stationXML
            End Get
            Set(value As String)
                _stationXML = value
            End Set
        End Property

        Public Property TestXML As String
            Get
                Return _testXML
            End Get
            Set(value As String)
                _testXML = value
            End Set
        End Property

        Public Property HostID As Int32
            Get
                Return _hostID
            End Get
            Set(value As Int32)
                _hostID = value
            End Set
        End Property

        Public Property HasProductXML As Boolean
            Get
                Return _hasProductXML
            End Get
            Set(value As Boolean)
                _hasProductXML = value
            End Set
        End Property

        Public Property HasStationXML As Boolean
            Get
                Return _hasStationXML
            End Get
            Set(value As Boolean)
                _hasStationXML = value
            End Set
        End Property

        Public Property HasCalibrationXML As Boolean
            Get
                Return _hasCalibrationXML
            End Get
            Set(value As Boolean)
                _hasCalibrationXML = value
            End Set
        End Property
    End Class
End Namespace