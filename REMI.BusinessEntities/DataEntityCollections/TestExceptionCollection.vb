Namespace REMI.BusinessEntities
    ''' <summary>
    ''' Represents a collection of <see cref="Test">Tests</see>.
    ''' </summary>
    <Serializable()> _
    Public Class TestExceptionCollection
        Inherits REMICollectionBase(Of TestException)

        ''' <summary> 
        ''' Initializes a new instance of the TestCollection class. 
        ''' </summary> 
        Public Sub New()
        End Sub

        Public Function UnitIsExempt(ByVal unitNumber As Integer, ByVal testStageName As String, ByVal testName As String, ByRef tasks As System.Collections.Generic.List(Of Contracts.ITaskModel)) As Boolean
            Dim isExempt As Boolean
            'Dim exceptionCount As Integer
            'While Not isExempt And exceptionCount < Me.Count
            '    'check if not already exempt
            '    'check if unit number matches
            '    'check the teststagename is null and the test matches.
            '    'check the test name is null and the test stage matches
            '    'check that the test name and the test stage match
            '    If (Not isExempt) _
            '        AndAlso _
            '        ( _
            '            Me.Item(exceptionCount).UnitNumber = 0 OrElse Me.Item(exceptionCount).UnitNumber = unitNumber _
            '        ) _
            '        AndAlso _
            '        ( _
            '            Me.Item(exceptionCount).TestCenterID = te.TestCenterID OrElse Me.Item(exceptionCount).TestCenterID = 0 _
            '        ) _
            '        AndAlso _
            '        ( _
            '            Me.Item(exceptionCount).ProductTypeID = te.ProductTypeID OrElse Me.Item(exceptionCount).ProductTypeID = 0 _
            '        ) _
            '        AndAlso _
            '        ( _
            '            Me.Item(exceptionCount).ProductID = te.ProductID OrElse Me.Item(exceptionCount).ProductID = 0 _
            '        ) _
            '        AndAlso _
            '        ( _
            '            Me.Item(exceptionCount).AccessoryGroupID = te.AccessoryGroupID OrElse Me.Item(exceptionCount).AccessoryGroupID = 0 _
            '        ) _
            '        AndAlso _
            '        ( _
            '            Me.Item(exceptionCount).ReasonForRequest = te.ReasonForRequest OrElse Me.Item(exceptionCount).ReasonForRequest = Contracts.RequestPurpose.NotSet _
            '        ) _
            '        AndAlso _
            '        ( _
            '            Me.Item(exceptionCount).IsMQual = te.IsMQual OrElse Me.Item(exceptionCount).IsMQual = 0 _
            '        ) _
            '        AndAlso _
            '        ( _
            '            ( _
            '                String.IsNullOrEmpty(Me.Item(exceptionCount).TestStageName) AndAlso Me.Item(exceptionCount).TestName = testName _
            '            ) _
            '            OrElse _
            '            ( _
            '                String.IsNullOrEmpty(Me.Item(exceptionCount).TestName) AndAlso Me.Item(exceptionCount).TestStageName = testStageName _
            '            ) _
            '            OrElse _
            '            ( _
            '                Me.Item(exceptionCount).TestStageName = testStageName AndAlso Me.Item(exceptionCount).TestName = testName _
            '            ) _
            '        ) Then
            '        isExempt = True
            '    End If
            '    exceptionCount += 1
            'End While

            'If (Not isExempt) Then ' No exception is created. Check requestsetup for that stage/test/unit
            If (From t In tasks Where t.TestStageName = testStageName And t.TestName = testName And t.UnitsForTask.Contains(unitNumber) Select t).FirstOrDefault() Is Nothing Then
                isExempt = True
            End If
            'End If

            Return isExempt
        End Function
    End Class
End Namespace