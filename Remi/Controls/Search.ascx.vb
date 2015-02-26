Imports Remi.Bll
Imports Remi.BusinessEntities

Public Class Search1
    Inherits System.Web.UI.UserControl

    Private _searchScript As String
    Private _jQueryScript As String

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
    End Sub

    Protected Sub Page_PreRender(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.PreRender
        hdnUser.Value = UserManager.GetCurrentUser.UserName
        hdnUserID.Value = UserManager.GetCurrentUser.ID
        If (Not Page.ClientScript.IsClientScriptIncludeRegistered(Me.GetType(), "jQuery")) Then
            Page.ClientScript.RegisterClientScriptInclude(Me.GetType(), "jQuery", ResolveClientUrl(JQueryScript))
        End If

        If (Not Page.ClientScript.IsClientScriptIncludeRegistered(Me.GetType(), "SearchScript")) Then
            Page.ClientScript.RegisterClientScriptInclude(Me.GetType(), "SearchScript", ResolveClientUrl(SearchScript))
        End If
    End Sub

    Public Property ExecuteTop As Boolean
        Get
            Return hdnTop.Value
        End Get
        Set(value As Boolean)
            hdnTop.Value = value
        End Set
    End Property

    Public Property SearchScript As String
        Get
            Return _searchScript
        End Get
        Set(value As String)
            _searchScript = value
        End Set
    End Property

    Public Property JQueryScript As String
        Get
            Return _jQueryScript
        End Get
        Set(value As String)
            _jQueryScript = value
        End Set
    End Property

    Public Property RequestType As String
        Get
            Return hdnRequestType.Value
        End Get
        Set(value As String)
            hdnRequestType.Value = value
        End Set
    End Property
End Class