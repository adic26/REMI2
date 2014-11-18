Imports REMI.Core
Imports REMI.Validation
Imports REMI.Contracts

Namespace REMI.BusinessEntities
    <Serializable()> _
    Public Class ProductConfiguration
        Inherits LoggedItemBase

        Private _hasConfig As Boolean
        Private _productID As Int32
        Private _testID As Int32
        Private _pcid As Int32
        Private _name As String
        Private _xml As String
        Private _productName As String
        Private _testName As String
        Private _prevVersions As ProductConfigCollection
        Private _versNum As Int32
        Private _codeVersions As List(Of String)

        Public Sub New()
        End Sub

        Public Sub New(ByVal pcid As Int32, ByVal hasConfig As Boolean, ByVal name As String, ByVal xml As String, ByVal testName As String, ByVal productName As String, ByVal testID As Int32, ByVal productID As Int32, ByVal prevversions As ProductConfigCollection, ByVal versnum As Int32, ByVal codeversions As List(Of String))
            Me.HasConfig = hasConfig
            Me.Name = name
            Me.XML = xml
            Me.ProductName = productName
            Me.TestName = testName
            Me.TestID = testID
            Me.ProductID = productID
            Me.ID = pcid
            Me.PrevVersions = prevversions
            Me.VersionNum = versnum
            Me.CodeVersions = codeversions
        End Sub

        Public Sub New(ByVal pcid As Int32, ByVal xml As String, ByVal versnum As Int32, ByVal codeversions As List(Of String))
            Me.XML = xml
            Me.ID = pcid
            Me.VersionNum = versnum
            Me.HasConfig = True
            Me.CodeVersions = codeversions
        End Sub

        Public Property PrevVersions As ProductConfigCollection
            Get
                Return _prevVersions
            End Get
            Set(value As ProductConfigCollection)
                If (value.Count > 0) Then
                    For Each v In value
                        v.TestID = Me.TestID
                        v.ProductID = Me.ProductID
                        v.TestName = Me.TestName
                        v.ProductName = Me.ProductName
                    Next
                End If

                _prevVersions = value
            End Set
        End Property

        Public Property CodeVersions As List(Of String)
            Get
                Return _codeVersions
            End Get
            Set(value As List(Of String))
                _codeVersions = value
            End Set
        End Property

        Public Property HasConfig As Boolean
            Get
                Return _hasConfig
            End Get
            Set(value As Boolean)
                _hasConfig = value
            End Set
        End Property

        Public Property Name As String
            Get
                Return _name
            End Get
            Set(value As String)
                _name = value
            End Set
        End Property

        Public Property XML As String
            Get
                Return _xml
            End Get
            Set(value As String)
                _xml = value
            End Set
        End Property

        Public Property TestName As String
            Get
                Return _testName
            End Get
            Set(value As String)
                _testName = value
            End Set
        End Property

        Public Property ProductName As String
            Get
                Return _productName
            End Get
            Set(value As String)
                _productName = value
            End Set
        End Property

        Public Property TestID As Int32
            Get
                Return _testID
            End Get
            Set(value As Int32)
                _testID = value
            End Set
        End Property

        Public Property ProductID As Int32
            Get
                Return _productID
            End Get
            Set(value As Int32)
                _productID = value
            End Set
        End Property

        Public Property VersionNum As Int32
            Get
                Return _versNum
            End Get
            Set(value As Int32)
                _versNum = value
            End Set
        End Property

        Public Overrides Property ID As Int32
            Get
                Return _pcid
            End Get
            Set(value As Int32)
                _pcid = value
            End Set
        End Property
    End Class
End Namespace