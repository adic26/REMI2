Imports System.Web.UI.WebControls
Imports System.Web.UI

Namespace REMI.Bll
    Public Class GridViewTemplate
        Implements ITemplate
        Private templateType As DataControlRowType
        Private columnName As String
        Private controlText As String
        Private controlType As String
        Private ID As String
        Private dataList As DataTable
        Private Enabled As Boolean
        Private imageUrl As String
        Private attributes As Dictionary(Of String, String)

        Public Sub New(ByVal type As DataControlRowType, ByVal colname As String, ByVal controlText As String, ByVal ctlType As String, ByVal ctlid As String, ByVal dt As DataTable, ByVal enabled As Boolean, ByVal imageUrl As String, ByVal attr As Dictionary(Of String, String))
            templateType = type
            columnName = colname
            Me.controlText = controlText
            controlType = ctlType
            ID = ctlid
            Me.Enabled = enabled
            dataList = dt
            Me.imageUrl = imageUrl
            Me.attributes = attr
        End Sub

        Public Sub InstantiateIn(ByVal container As Control) Implements System.Web.UI.ITemplate.InstantiateIn
            Dim list As List(Of String) = Nothing
            If (Me.attributes IsNot Nothing) Then
                list = New List(Of String)(Me.attributes.Keys)
            End If

            Select Case templateType
                Case DataControlRowType.Header
                    Dim lc As New Literal()
                    lc.Text = columnName
                    container.Controls.Add(lc)
                    Exit Select
                Case DataControlRowType.DataRow
                    If controlType = "Label" Then
                        Dim lb As New Label()
                        lb.ID = ID
                        lb.Enabled = Me.Enabled
                        AddHandler lb.DataBinding, AddressOf Me.ctl_OnDataBinding

                        If (list IsNot Nothing) Then
                            For Each str As String In list
                                lb.Attributes.Add(str, Me.attributes.Item(str))
                            Next
                        End If

                        container.Controls.Add(lb)
                    ElseIf controlType = "TextBox" Then
                        Dim tb As New TextBox()
                        tb.ID = ID
                        tb.Enabled = Me.Enabled
                        AddHandler tb.DataBinding, AddressOf Me.ctl_OnDataBinding

                        If (list IsNot Nothing) Then
                            For Each str As String In list
                                tb.Attributes.Add(str, Me.attributes.Item(str))
                            Next
                        End If

                        container.Controls.Add(tb)
                    ElseIf controlType = "dropdownlist" Then
                        Dim ddl As New DropDownList()
                        ddl.ID = ID
                        ddl.Enabled = Me.Enabled
                        AddHandler ddl.DataBinding, AddressOf Me.ctl_OnDataBinding

                        If (list IsNot Nothing) Then
                            For Each str As String In list
                                ddl.Attributes.Add(str, Me.attributes.Item(str))
                            Next
                        End If

                        container.Controls.Add(ddl)
                    ElseIf controlType = "Button" Then
                        Dim btn As New Button
                        btn.ID = ID
                        btn.Enabled = Me.Enabled
                        btn.Text = Me.controlText
                        AddHandler btn.DataBinding, AddressOf Me.ctl_OnDataBinding

                        If (list IsNot Nothing) Then
                            For Each str As String In list
                                btn.Attributes.Add(str, Me.attributes.Item(str))
                            Next
                        End If

                        container.Controls.Add(btn)
                    ElseIf controlType = "Image" Then
                        Dim img As New Image()
                        img.ID = ID
                        img.Enabled = Me.Enabled
                        img.ImageUrl = Me.imageUrl
                        AddHandler img.DataBinding, AddressOf Me.ctl_OnDataBinding

                        If (list IsNot Nothing) Then
                            For Each str As String In list
                                img.Attributes.Add(str, Me.attributes.Item(str))
                            Next
                        End If

                        container.Controls.Add(img)
                    ElseIf controlType = "CheckBox" Then
                        Dim cb As New CheckBox()
                        cb.ID = ID
                        cb.Enabled = Me.Enabled
                        AddHandler cb.DataBinding, AddressOf Me.ctl_OnDataBinding

                        If (list IsNot Nothing) Then
                            For Each str As String In list
                                cb.Attributes.Add(str, Me.attributes.Item(str))
                            Next
                        End If

                        container.Controls.Add(cb)
                    End If
                    Exit Select
                Case Else
                    Exit Select
            End Select
        End Sub

        Public Sub ctl_OnDataBinding(ByVal sender As Object, ByVal e As EventArgs)
            If sender.[GetType]().Name = "Label" Then
                Dim lb As Label = DirectCast(sender, Label)
                Dim container As GridViewRow = DirectCast(lb.NamingContainer, GridViewRow)
            ElseIf sender.[GetType]().Name = "TextBox" Then
                Dim tb As TextBox = DirectCast(sender, TextBox)
                Dim container As GridViewRow = DirectCast(tb.NamingContainer, GridViewRow)
            ElseIf sender.[GetType]().Name = "DropDownList" Then
                Dim ddl As DropDownList = DirectCast(sender, DropDownList)
                Dim container As GridViewRow = DirectCast(ddl.NamingContainer, GridViewRow)
                ddl.DataTextField = "LookupType"
                ddl.DataValueField = "LookupID"
                ddl.DataSource = dataList
            ElseIf sender.[GetType]().Name = "Button" Then
                Dim btn As Button = DirectCast(sender, Button)
                Dim container As GridViewRow = DirectCast(btn.NamingContainer, GridViewRow)
            ElseIf controlType = "Image" Then
                Dim img As Image = DirectCast(sender, Image)
                Dim container As GridViewRow = DirectCast(img.NamingContainer, GridViewRow)
            ElseIf controlType = "CheckBox" Then
                Dim cb As CheckBox = DirectCast(sender, CheckBox)
                Dim container As GridViewRow = DirectCast(cb.NamingContainer, GridViewRow)
            End If
        End Sub
    End Class
End Namespace