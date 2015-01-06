Imports System.Web
Imports System.Web.Services
Imports System.Drawing
Imports System.IO

Public Class ImageHandler
    Implements System.Web.IHttpHandler

    Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        Dim img As String = context.Request.QueryString("img").ToString()
        Dim instance = New Remi.Dal.Entities().Instance()
        Dim file = (From mf In instance.ResultsMeasurementsFiles Where mf.ID = img Select mf).FirstOrDefault()

        Dim bm As Bitmap
        Dim newImage As Bitmap
        Using ms As MemoryStream = New MemoryStream(file.File)
            bm = New Bitmap(ms)
        End Using

        Dim inputRatio As Double = Convert.ToDouble(bm.Width) / Convert.ToDouble(bm.Height)
        Dim _width As Int32
        Dim _height As Int32

        If (Not (String.IsNullOrEmpty(context.Request("width"))) And Not (String.IsNullOrEmpty(context.Request("height")))) Then
            _width = Int32.Parse(context.Request("width"))
            _height = Int32.Parse(context.Request("height"))
        ElseIf (Not (String.IsNullOrEmpty(context.Request("width")))) Then
            _width = Int32.Parse(context.Request("width"))
            _height = Convert.ToInt32((_width / inputRatio))
        ElseIf (Not (String.IsNullOrEmpty(context.Request("height")))) Then
            _height = Int32.Parse(context.Request("height"))
            _width = Convert.ToInt32((_height * inputRatio))
        Else
            _height = bm.Height
            _width = bm.Width
        End If

        newImage = New Bitmap(bm, _width, _height)
        Dim converter As New ImageConverter

        context.Response.ContentType = String.Format("image/{0}", file.ContentType.Replace(".", ""))
        context.Response.BinaryWrite(converter.ConvertTo(newImage, GetType(Byte())))
        context.Response.End()
    End Sub

    ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property
End Class