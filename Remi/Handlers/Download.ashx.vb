Imports System.Web
Imports System.Web.Services

Public Class Download
    Implements System.Web.IHttpHandler

    Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim instance = New REMI.Dal.Entities().Instance()

        If (context.Request.QueryString("img") IsNot Nothing) Then
            Dim img As String = context.Request.QueryString("img").ToString()
            Dim file = (From mf In instance.ResultsMeasurementsFiles Where mf.ID = img Select mf).FirstOrDefault()

            Dim buffer() As Byte = file.File
            context.Response.ContentType = "application/octet-stream"
            context.Response.AddHeader("content-disposition", "attachment; filename=" + file.FileName + "")
            context.Response.BinaryWrite(buffer)
        End If

        context.Response.End()
    End Sub

    ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class