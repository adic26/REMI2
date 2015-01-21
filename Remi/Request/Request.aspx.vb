Imports Remi.Bll
Imports Remi.Validation
Imports Remi.Contracts
Imports Remi.BusinessEntities
Imports System.Reflection.Emit
Imports System.Reflection
Imports System.ComponentModel
Imports System.Drawing.Design

Public Class Request
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        'If (Not Page.IsPostBack) Then
        Dim req As String = IIf(Request.QueryString.Item("req") Is Nothing, String.Empty, Request.QueryString.Item("req"))
        Dim type As String = IIf(Request.QueryString.Item("type") Is Nothing, String.Empty, Request.QueryString.Item("type"))

        ' If (Request.QueryString.Item("SCB") Is Nothing) Then
        lblRequest.Text = req
        Dim rf As RequestFieldsCollection

        If (Not String.IsNullOrEmpty(req)) Then
            rf = RequestManager.GetRequest(req)
        Else
            rf = RequestManager.GetRequestFieldSetup(type, False, String.Empty)
        End If

        If (rf IsNot Nothing) Then
            Dim t As Type
            Dim asmName As New AssemblyName("TsdDynamicAssembly")
            Dim asmBuilder As AssemblyBuilder = AppDomain.CurrentDomain.DefineDynamicAssembly(asmName, AssemblyBuilderAccess.RunAndSave)
            Dim modBuilder As ModuleBuilder = asmBuilder.DefineDynamicModule(asmName.Name, asmName.Name + ".dll")

            Dim tb As TypeBuilder = modBuilder.DefineType("TsdDynamicType", TypeAttributes.Public Or TypeAttributes.Class Or TypeAttributes.AutoClass Or TypeAttributes.AnsiClass)

            For Each res In rf
                Select Case res.FieldType.ToUpper()
                    Case "RADIOBUTTON", "CHECKBOX", "DROPDOWN"
                        PG.DynamicClass.AddNewListProperty(asmBuilder, modBuilder, tb, res.Name, False, res.OptionsType, res.FieldType, res.Category, res.Description, res.Value)
                    Case "DATETIME"
                        PG.DynamicClass.AddNewProperty(tb, res.Name, GetType(DateTime), res.Description, False, res.Category, res.FieldType, res.Value)
                    Case "LINK", "TEXTBOX", "TEXTAREA"
                        PG.DynamicClass.AddNewProperty(tb, res.Name, GetType(String), res.Description, False, res.Category, res.FieldType, res.Value)
                    Case Else
                        PG.DynamicClass.AddNewProperty(tb, res.Name, GetType(String), res.Description, False, res.Category, res.FieldType, res.Value)
                End Select
            Next

            t = tb.CreateType()
            Dim myObj As Object = Activator.CreateInstance(t)

            For Each res In rf
                Dim pi As PropertyInfo

                Select Case res.FieldType.ToUpper()
                    Case "DROPDOWN", "RADIOBUTTON", "CHECKBOX"
                        pi = t.GetProperty(res.Name.Replace(" ", "_"))
                        Dim o As Object = res.Value

                        If (pi.PropertyType.IsEnum) Then
                            Dim enums As Array = [Enum].GetValues(pi.PropertyType)

                            If (Not res.OptionsType.ToList.Contains(o)) Then
                                o = [Enum].Parse(pi.PropertyType, enums.GetValue(0).ToString(), True)
                            Else
                                If (res.Value <> String.Empty) Then
                                    o = [Enum].Parse(pi.PropertyType, o.ToString(), True)
                                    pi.SetValue(myObj, o, Nothing)
                                Else
                                    o = [Enum].Parse(pi.PropertyType, enums.GetValue(0).ToString(), True)

                                    pi.SetValue(myObj, o, Nothing)
                                End If
                            End If
                        Else
                            Dim l As New List(Of String)

                            l.AddRange(res.OptionsType)

                            Dim dlp As PG.DropDownListProperty = New PG.DropDownListProperty(l)
                            dlp.SelectedItem = res.Value
                            pi.SetValue(myObj, dlp, Nothing)
                        End If
                    Case "DATETIME"
                        pi = t.GetProperty(res.Name)
                        Dim dt As DateTime = DateTime.MinValue
                        DateTime.TryParse(res.Value, dt)

                        pi.SetValue(myObj, dt, Nothing)
                    Case "LINK", "TEXTBOX", "TEXTAREA"
                        pi = t.GetProperty(res.Name)
                        pi.SetValue(myObj, res.Value, Nothing)
                    Case Else
                        pi = t.GetProperty(res.Name)
                        pi.SetValue(myObj, res.Value, Nothing)
                End Select
            Next

            'pg1.SelectedObject = myObj
        End If
        'End If
    End Sub
End Class