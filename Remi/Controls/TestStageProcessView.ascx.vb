Imports REMI.BusinessEntities
Imports REMI.Bll
Partial Class Controls_TestStageProcessView
    Inherits System.Web.UI.UserControl

    Private _qraNumber As String
    Private _unitNumber As Integer
    Private _processTree As ListItemCollection

    Public Property QRANumber() As String
        Get
            Return _qraNumber
        End Get
        Set(ByVal value As String)
            _qraNumber = value
        End Set
    End Property

    Public Property UnitNumber() As Integer
        Get
            Return _unitNumber
        End Get
        Set(ByVal value As Integer)
            _unitNumber = value
        End Set
    End Property

    Public Property ProcessTree() As ListItemCollection
        Get
            Return _processTree
        End Get
        Set(ByVal value As ListItemCollection)
            _processTree = value
            rptProcessLinks.DataSource = ProcessTree
            rptProcessLinks.DataBind()
        End Set
    End Property

    Protected Sub rptProcessLinks_ItemDataBound(ByVal source As Object, ByVal e As System.Web.UI.WebControls.RepeaterItemEventArgs) Handles rptProcessLinks.ItemDataBound
        Dim hdnTestStageID As HiddenField = DirectCast(e.Item.FindControl("hdnTestStageID"), HiddenField)
        Dim imgTestStageComplete As Image = DirectCast(e.Item.FindControl("imgTestStagecomplete"), Image)
        Dim remainingTests As TestCollection = Nothing 'TestManager.GetRemainingTests(QRANumber, UnitNumber, CInt(hdnTestStageID.Value))
        Dim remTestsCount As Integer

        If remainingTests IsNot Nothing Then
            remTestsCount = remainingTests.Count
        End If

        If remTestsCount = 0 Then
            imgTestStageComplete.Visible = True
            imgTestStageComplete.ImageUrl = "../Design/Icons/png/16x16/accept.png"
        Else
            imgTestStageComplete.Visible = True
            imgTestStageComplete.ImageUrl = "../Design/Icons/png/16x16/delete.png"
        End If
    End Sub
End Class