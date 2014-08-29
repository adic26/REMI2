Option Compare Text
Option Explicit On
Option Strict On
Imports System.Xml.Serialization
Imports System.Xml.Schema
Imports System.Xml

Namespace REMI.BusinessEntities
    <XmlRoot("dictionary")> _
    <Serializable()> _
    Public Class SerializableDictionary(Of TKey, TValue)
        Inherits Dictionary(Of TKey, TValue)
        Implements IXmlSerializable

#Region "IXmlSerializable Members"
        Public Sub New()
        End Sub

        Protected Sub New(ByVal info As System.Runtime.Serialization.SerializationInfo, ByVal context As System.Runtime.Serialization.StreamingContext)
            MyBase.New(info, context)
        End Sub

        Public Function GetSchema() As XmlSchema Implements IXmlSerializable.GetSchema
            Return Nothing
        End Function

        Public Sub ReadXml(ByVal reader As XmlReader) Implements IXmlSerializable.ReadXml
            Dim keySerializer As New XmlSerializer(GetType(TKey))
            Dim valueSerializer As New XmlSerializer(GetType(TValue))
            Dim wasEmpty As Boolean = reader.IsEmptyElement

            reader.Read()

            If wasEmpty Then
                Return
            End If

            While reader.NodeType <> XmlNodeType.EndElement

                reader.ReadStartElement("item")
                reader.ReadStartElement("key")

                Dim key As TKey = CType(keySerializer.Deserialize(reader), TKey)

                reader.ReadEndElement()
                reader.ReadStartElement("value")

                Dim value As TValue = CType(valueSerializer.Deserialize(reader), TValue)

                reader.ReadEndElement()
                Me.Add(key, value)

                reader.ReadEndElement()
                reader.MoveToContent()
            End While

            reader.ReadEndElement()
        End Sub

        Public Sub WriteXml(ByVal writer As XmlWriter) Implements IXmlSerializable.WriteXml
            Dim keySerializer As New XmlSerializer(GetType(TKey))
            Dim valueSerializer As New XmlSerializer(GetType(TValue))

            For Each key As TKey In Me.Keys
                writer.WriteStartElement("item")
                writer.WriteStartElement("key")
                keySerializer.Serialize(writer, key)

                writer.WriteEndElement()
                writer.WriteStartElement("value")

                Dim value As Object = Me(key)

                valueSerializer.Serialize(writer, value)

                writer.WriteEndElement()
                writer.WriteEndElement()
            Next
        End Sub

#End Region
    End Class
End Namespace