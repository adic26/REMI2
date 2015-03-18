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
            context.Response.ContentType = GetMimeTypeByFileName(file.FileName)
            context.Response.AddHeader("content-disposition", "attachment; filename=" + file.FileName + "")
            context.Response.BinaryWrite(buffer)
        ElseIf (context.Request.QueryString("file") IsNot Nothing) Then
            Dim fileBytes() As Byte = System.IO.File.ReadAllBytes(String.Concat(context.Request.QueryString("path"), "\", context.Request.QueryString("file")))
            context.Response.ContentType = GetMimeTypeByFileName(context.Request.QueryString("file"))
            context.Response.AddHeader("content-disposition", "attachment; filename=" + context.Request.QueryString("file") + "")
            context.Response.BinaryWrite(fileBytes)
        End If

        context.Response.End()
    End Sub

    ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Public Function GetMimeTypeByFileName(ByVal sFileName As String) As String
        Dim sMime As String = "application/octet-stream"
        Dim sExtension As String = System.IO.Path.GetExtension(sFileName)
        If Not String.IsNullOrEmpty(sExtension) Then
            sExtension = sExtension.Replace(".", "")
            sExtension = sExtension.ToLower
            If ((sExtension = "xls") _
                        OrElse (sExtension = "xlsx")) Then
                sMime = "application/ms-excel"
            ElseIf ((sExtension = "doc") _
                        OrElse (sExtension = "docx")) Then
                sMime = "application/msword"
            ElseIf ((sExtension = "ppt") _
                        OrElse (sExtension = "pptx")) Then
                sMime = "application/ms-powerpoint"
            ElseIf (sExtension = "rtf") Then
                sMime = "application/rtf"
            ElseIf (sExtension = "zip") Then
                sMime = "application/zip"
            ElseIf (sExtension = "mp3") Then
                sMime = "audio/mpeg"
            ElseIf (sExtension = "bmp") Then
                sMime = "image/bmp"
            ElseIf (sExtension = "gif") Then
                sMime = "image/gif"
            ElseIf ((sExtension = "jpg") _
                        OrElse (sExtension = "jpeg")) Then
                sMime = "image/jpeg"
            ElseIf (sExtension = "png") Then
                sMime = "image/png"
            ElseIf ((sExtension = "tiff") _
                        OrElse (sExtension = "tif")) Then
                sMime = "image/tiff"
            ElseIf (sExtension = "txt") Then
                sMime = "text/plain"
            End If
        End If
        Return sMime
    End Function
End Class