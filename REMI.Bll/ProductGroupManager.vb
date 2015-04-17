﻿Imports REMI.BusinessEntities
Imports REMI.Dal
Imports System.ComponentModel
Imports REMI.Validation
Imports REMI.Contracts
Imports System.Web.UI.WebControls

Namespace REMI.Bll
    ''' <summary> 
    ''' The ProductGroupManager class is responsible for getting lists of productgroups
    ''' </summary> 
    <DataObjectAttribute()> _
    Public Class ProductGroupManager
        Inherits REMIManagerBase

        ''' <summary>
        ''' Gets a list of Products from the database.
        ''' </summary>
        ''' <returns> A collection of products.</returns>
        ''' <remarks></remarks>
        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetProductList(ByVal ByPassProduct As Boolean, ByVal userID As Int32, ByVal showArchived As Boolean) As DataTable
            Try
                Return ProductGroupDB.GetList(ByPassProduct, userID, showArchived)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New DataTable
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetProductTestReady(ByVal ProductID As Int32, ByVal MNum As String) As DataTable
            Try
                Return ProductGroupDB.GetProductTestReady(ProductID, MNum)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return New DataTable
            End Try
        End Function

        Public Shared Function SaveProductReady(ByVal productID As Int32, ByVal testID As Int32, ByVal productSettingID As Int32, ByVal productTestReadyID As Int32, ByVal isReady As Int32, ByVal comment As String, ByVal isNestReady As Int32, ByVal JIRA As Int32) As Boolean
            Dim nc As New NotificationCollection
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim testReady = (From ptr In instance.ProductTestReadies Where ptr.Test.ID = testID And ptr.Product.ID = productID And ptr.ProductSetting.ID = productSettingID And ptr.ID = productTestReadyID Select ptr).FirstOrDefault()

                If (testReady Is Nothing) Then
                    Dim pr As New REMI.Entities.ProductTestReady()
                    pr.IsReady = isReady
                    pr.IsNestReady = isNestReady
                    pr.Comment = comment
                    pr.Test = (From t In instance.Tests Where t.ID = testID Select t).FirstOrDefault()
                    pr.ProductSetting = (From ps In instance.ProductSettings Where ps.ID = productSettingID Select ps).FirstOrDefault()
                    pr.Product = (From p In instance.Products Where p.ID = productID Select p).FirstOrDefault()
                    pr.JIRA = JIRA
                    instance.AddToProductTestReadies(pr)
                Else
                    testReady.Comment = comment
                    testReady.IsReady = isReady
                    testReady.IsNestReady = isNestReady
                    testReady.JIRA = JIRA
                End If

                instance.SaveChanges()
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("productID: {0} testID: {1} productSettingID: {2} productTestReadyID: {3} isReady: {4} Comment: {5}", productID, testID, productSettingID, productTestReadyID, isReady, comment)))
            End Try
            Return False
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function UpdateProduct(ByVal productGroupname As String, ByVal isActive As Int32, ByVal productID As Int32, ByVal QAP As String) As Boolean
            Try
                Return ProductGroupDB.UpdateProduct(productGroupname, isActive, productID, QAP)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
                Return False
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetProductNameByID(ByVal productID As Int32) As String
            Try
                Return ProductGroupDB.GetProductNameByID(productID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return String.Empty
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function GetProductIDByName(ByVal productGroupName As String) As Int32
            Try
                Return ProductGroupDB.GetProductIDByName(productGroupName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
                Return 0
            End Try
        End Function

        <DataObjectMethod(DataObjectMethodType.[Select], False)> _
        Public Shared Function InventoryReport(ByVal startDate As DateTime, ByVal endDate As DateTime, ByVal filterByQRANumber As Boolean, ByVal geoLocation As Int32) As InventoryReportData
            Try
                Return ProductGroupDB.RetrieveInventoryReport(startDate, endDate, filterByQRANumber, geoLocation)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return Nothing
        End Function

#Region "Product Settings"
        Public Shared Function CreateSetting(ByVal productID As Int32, ByVal keyName As String, ByVal valueText As String, ByVal defaultValue As String) As Boolean
            Dim nc As New NotificationCollection
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim ps As New REMI.Entities.ProductSetting()
                ps.KeyName = keyName
                ps.LastUser = UserManager.GetCurrentValidUserLDAPName
                ps.ValueText = valueText
                ps.DefaultValue = defaultValue
                ps.Product = (From p In instance.Products Where p.ID = productID Select p).FirstOrDefault()
                instance.AddToProductSettings(ps)
                instance.SaveChanges()
                Return True
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("productID: {0} keyName: {1} valueText: {2} defaultValue: {3}", productID, keyName, valueText, defaultValue)))
            End Try
            Return False
        End Function

        Public Shared Function SaveSetting(ByVal productID As Int32, ByVal keyName As String, ByVal valueText As String, ByVal defaultValue As String) As Boolean
            Dim nc As New NotificationCollection
            Try
                Return ProductGroupDB.SaveProductSetting(productID, System.Web.HttpUtility.HtmlEncode(keyName), System.Web.HttpUtility.HtmlEncode(valueText), System.Web.HttpUtility.HtmlEncode(defaultValue), UserManager.GetCurrentValidUserLDAPName)
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex, String.Format("productID: {0} keyName: {1} valueText: {2} defaultValue: {3}", productID, keyName, valueText, defaultValue)))
            End Try
            Return False
        End Function

        Public Shared Function DeleteSetting(ByVal productID As Int32, ByVal keyName As String) As Boolean
            Dim nc As New NotificationCollection
            Try
                Return ProductGroupDB.DeleteProductSetting(productID, keyName, UserManager.GetCurrentValidUserLDAPName)
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex, String.Format("productID: {0} keyName: {1}", productID, keyName)))
            End Try
            Return False
        End Function

        Public Shared Function GetProductSetting(ByVal productID As Int32, ByVal keyName As String) As String
            Dim nc As New NotificationCollection
            Try
                Return System.Web.HttpUtility.HtmlDecode(ProductGroupDB.GetProductSetting(productID, keyName))
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("productID: {0} keyName: {1}", productID, keyName)))
            End Try

            Return String.Empty
        End Function

        Public Shared Function GetProductSettingsDictionary(ByVal productID As Int32) As SerializableDictionary(Of String, String)
            Dim nc As New NotificationCollection
            Try
                Dim encoded As List(Of ProductSetting) = ProductGroupDB.GetProductSettings(productID)
                Dim decodedDictionary As New SerializableDictionary(Of String, String)

                For Each p As ProductSetting In encoded
                    decodedDictionary.Add(System.Web.HttpUtility.HtmlDecode(p.KeyName), System.Web.HttpUtility.HtmlDecode(p.ValueText))
                Next

                Return decodedDictionary
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("productID: {0}", productID)))
            End Try

            Return New SerializableDictionary(Of String, String)
        End Function

        Public Shared Function GetProductSettings(ByVal productID As Int32) As List(Of ProductSetting)
            Dim nc As New NotificationCollection
            Try
                Dim settingsList As List(Of ProductSetting) = ProductGroupDB.GetProductSettings(productID)

                For Each p As ProductSetting In settingsList
                    p.DefaultValue = System.Web.HttpUtility.HtmlDecode(p.DefaultValue)
                    p.ValueText = System.Web.HttpUtility.HtmlDecode(p.ValueText)
                Next
                Return settingsList
            Catch ex As Exception
                nc.Add(LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex, String.Format("productID: {0}", productID)))
            End Try
            Return New List(Of ProductSetting)
        End Function

        Public Shared Function HasProductConfigurationXML(ByVal productID As Int32, ByVal TestID As Int32, ByVal name As String) As Boolean
            Try
                Dim record = (From xml In New REMI.Dal.Entities().Instance().ProductConfigurationUploads Where xml.Test.ID = TestID And xml.Product.ID = productID And ((xml.PCName = name And name <> String.Empty) Or name = String.Empty) Select xml).FirstOrDefault()
                If (record Is Nothing) Then
                    Return False
                Else
                    Return True
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function GetProductConfigurationXMLVersion(ByVal pcvID As Int32) As XDocument
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim xml As String = (From x In instance.ProductConfigurationVersions Where x.ID = pcvID Select x.PCXML).FirstOrDefault()

                If (xml Is Nothing) Then
                    Return New XDocument()
                Else
                    Return XDocument.Parse(xml)
                End If
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New XDocument()
        End Function

        Public Shared Function GetProductConfigurationXML(ByVal pcUID As Int32) As XDocument
            Try
                Return ProductGroupDB.GetProductConfigurationXML(pcUID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New XDocument()
        End Function

        Public Shared Function GetAllProductConfigurationXMLs(ByVal productID As Int32, ByVal testID As Int32, ByVal loadVersions As Boolean) As ProductConfigCollection
            Dim xmls As New ProductConfigCollection()

            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim record = (From xml In instance.ProductConfigurationUploads.Include("Test").Include("Product").Include("Product.Lookup") Where xml.Test.ID = testID And xml.Product.ID = productID Select xml)

                For Each rec In record
                    Dim xmlFrag As XDocument = ProductGroupDB.GetProductConfigurationXML(rec.ID)
                    Dim versions As New ProductConfigCollection
                    Dim currentCodeVersions As New List(Of String)

                    If (loadVersions) Then
                        Dim ver = (From v In instance.ProductConfigurationVersions Where v.ProductConfigurationUpload.ID = rec.ID Order By v.VersionNum Select v.ID, v.VersionNum, v.PCXML).ToList

                        For Each vs In ver 'Get all XML Versions
                            Dim a = (From av In instance.ApplicationProductVersions.Include("ProductConfigurationVersion").Include("ApplicationVersion").Include("ApplicationVersion.Application") Where av.ProductConfigurationVersion.ID = vs.ID Select av.ApplicationVersion.Application.ApplicationName, av.ApplicationVersion.VerNum, av.ProductConfigurationVersion.VersionNum).ToList
                            Dim codeVersions As New List(Of String)

                            For Each appVer In a
                                If (appVer IsNot Nothing) Then
                                    codeVersions.Add(New Version(appVer.VerNum.ToString()).ToString())

                                    If (vs.VersionNum = ver.Count) Then
                                        currentCodeVersions.Add(New Version(appVer.VerNum.ToString()).ToString())
                                    End If
                                End If
                            Next

                            If (vs.VersionNum < ver.Count) Then
                                versions.Add(New ProductConfiguration(vs.ID, vs.PCXML, vs.VersionNum, codeVersions))
                            End If
                        Next
                    End If

                    xmls.Add(New ProductConfiguration(rec.ID, True, rec.PCName, xmlFrag.Root.ToString(), rec.Test.TestName, rec.Product.Lookup.Values, testID, productID, versions, versions.Count + 1, currentCodeVersions))
                Next
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try

            Return xmls
        End Function

        Public Shared Function GetProductConfigurationXMLCombined(ByVal productID As Int32, ByVal testID As Int32) As XDocument
            Try
                Dim xmls As ProductConfigCollection = ProductGroupManager.GetAllProductConfigurationXMLs(productID, testID, False)
                Dim xmlCombined As XDocument
                xmlCombined = XDocument.Parse("<XML/>")

                For Each rec As ProductConfiguration In xmls
                    If (rec.HasConfig) Then
                        Dim xd As XDocument = XDocument.Parse(rec.XML)
                        Dim val As XDocument = New XDocument()
                        val.Add(New XElement(rec.Name))
                        val.Root.Add(xd.Root)

                        xmlCombined.Root.Add(val.Root)
                    End If
                Next

                Return xmlCombined
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New XDocument()
        End Function

        Public Shared Function GetProductConfigurationHeader(ByVal pcUID As Int32) As DataTable
            Try
                Return ProductGroupDB.GetProductConfigurationHeader(pcUID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable()
        End Function

        Public Shared Function GetProductConfigurationDetails(ByVal pcID As Int32) As DataTable
            Try
                Return ProductGroupDB.GetProductConfigurationDetails(pcID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable()
        End Function

        Public Shared Function SaveProductConfiguration(ByVal pcID As Int32, ByVal parentID As Int32, ByVal ViewOrder As Int32, ByVal NodeName As String, ByVal lastUser As String, ByVal pcUID As Int32) As Boolean
            Try
                Return ProductGroupDB.SaveProductConfiguration(pcID, parentID, ViewOrder, NodeName, lastUser, pcUID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function SaveProductConfigurationDetails(ByVal pcID As Int32, ByVal configID As Int32, ByVal lookupID As Int32, ByVal lookupValue As String, ByVal lastUser As String, ByVal isAttribute As Boolean, ByVal lookupAlt As String) As Boolean
            Try
                Return ProductGroupDB.SaveProductConfigurationDetails(pcID, configID, lookupID, lookupValue, lastUser, isAttribute, lookupAlt)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function GetSimilarTestConfigurations(ByVal productID As Int32, ByVal TestID As Int32) As DataTable
            Try
                Return ProductGroupDB.GetSimilarTestConfigurations(productID, TestID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable()
        End Function

        Public Shared Function CopyTestConfiguration(ByVal productID As Int32, ByVal TestID As Int32, ByVal copyFromProductID As Int32, ByVal lastUser As String) As Boolean
            Try
                Return ProductGroupDB.CopyTestConfiguration(productID, TestID, copyFromProductID, lastUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function DeleteProductConfigurationDetail(ByVal configID As Int32, ByVal lastUser As String) As Boolean
            Try
                Return ProductGroupDB.DeleteProductConfigurationDetail(configID, lastUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function DeleteProductConfigurationHeader(ByVal pcID As Int32, ByVal lastUser As String) As Boolean
            Try
                Return ProductGroupDB.DeleteProductConfigurationHeader(pcID, lastUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function DeleteProductConfiguration(ByVal pcUID As Int32, ByVal lastUser As String) As Boolean
            Try
                Return ProductGroupDB.DeleteProductConfiguration(pcUID, lastUser)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e2", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function ChangeAccess(ByVal lookupID As Int32, ByVal productID As Int32, ByVal hasAccess As Boolean) As Boolean
            Try
                Dim instance = New REMI.Dal.Entities().Instance()
                Dim t = (From p In instance.ProductLookups Where p.Lookup.LookupID = lookupID And p.Product.ID = productID Select p).FirstOrDefault()

                If (t IsNot Nothing) Then 'exists so remove
                    instance.DeleteObject(t)
                Else
                    Dim pl As New REMI.Entities.ProductLookup()
                    pl.Lookup = (From l In instance.Lookups Where l.LookupID = lookupID Select l).FirstOrDefault()
                    pl.Product = (From p In instance.Products Where p.ID = productID Select p).FirstOrDefault()
                    instance.AddToProductLookups(pl)
                End If

                instance.SaveChanges()

                Return True
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
                Return False
            End Try
        End Function

        Public Shared Function ProductConfigurationUpload(ByVal productID As Int32, ByVal TestID As Int32, ByVal xml As XDocument, ByVal LastUser As String, ByVal pcName As String) As Boolean
            Try
                Return ProductGroupDB.ProductConfigurationUpload(productID, TestID, xml, LastUser, pcName)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function SaveProductConfigurationXMLVersion(ByVal xml As String, ByVal LastUser As String, ByVal pcUID As Int32) As Boolean
            Try
                Return ProductGroupDB.SaveProductConfigurationXMLVersion(xml, LastUser, pcUID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function ProductConfigurationProcess() As Boolean
            Try
                Return ProductGroupDB.ProductConfigurationProcess()
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e1", NotificationType.Errors, ex)
            End Try
            Return False
        End Function

        Public Shared Function GetProductContacts(ByVal productID As Int32) As DataTable
            Try
                Return ProductGroupDB.GetProductContacts(productID)
            Catch ex As Exception
                LogIssue(System.Reflection.MethodBase.GetCurrentMethod().Name, "e3", NotificationType.Errors, ex)
            End Try
            Return New DataTable()
        End Function
#End Region
    End Class
End Namespace