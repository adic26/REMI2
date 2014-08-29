﻿Public Class remi
    Private Shared _remiInstance As remiAPI.RemiAPI

    Private Sub New()

    End Sub

    Public Shared ReadOnly Property GetInstance() As remiAPI.RemiAPI
        Get
            If _remiInstance Is Nothing Then
                _remiInstance = New remiAPI.RemiAPI
                _remiInstance.PreAuthenticate = True

                _remiInstance.Credentials = New System.Net.NetworkCredential("remi", "qahUS8Ag", "rimnet")
                _remiInstance.CookieContainer = New System.Net.CookieContainer
            End If
            Return _remiInstance
        End Get
    End Property
End Class
