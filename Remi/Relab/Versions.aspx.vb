﻿Imports Remi.Bll
Imports Remi.BusinessEntities

Public Class Versions
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            Dim batchID As Int32
            Dim testID As Int32
            Int32.TryParse(Request.QueryString("Batch"), batchID)
            Int32.TryParse(Request.QueryString("TestID"), testID)

            If (batchID < 1 Or testID < 1) Then
                Response.Redirect("~/")
            End If

            Dim unitNumber As Int32 = IIf(Request.QueryString.Item("unitNumber") Is Nothing, 0, Request.QueryString.Item("unitNumber"))
            Dim testStageID As Int32 = IIf(Request.QueryString.Item("TestStageID") Is Nothing, 0, Request.QueryString.Item("TestStageID"))

            Dim qra = (From b In New REMI.Dal.Entities().Instance().Batches Where b.ID = batchID Select b.QRANumber).FirstOrDefault()
            hypBatch.NavigateUrl = Core.REMIWebLinks.GetBatchInfoLink(qra)

            hypResult.NavigateUrl = String.Format("/Relab/Results.aspx?Batch={0}", batchID)

            Dim resultInfo = (From t In New REMI.Dal.Entities().Instance().Tests _
                        Where t.ID = testID _
                        Select New With {t.TestName}).FirstOrDefault()
            lblHeader.Text = String.Format("Versions {0}: {1}", resultInfo.TestName, qra)

            Dim ds = (From r In New Remi.Dal.Entities().Instance().Results Where r.TestUnit.Batch.ID = batchID And r.Test.ID = testID And (unitNumber = 0 Or r.TestUnit.BatchUnitNumber = unitNumber) And (testStageID = 0 Or r.TestStageID = testStageID) Select New With {.TestStageName = r.TestStage.TestStageName, .ID = r.ID, .BatchUnitNumber = r.TestUnit.BatchUnitNumber}).Distinct().OrderBy(Function(o) o.BatchUnitNumber).ToList()
            grdMeasurementLinks.DataSource = ds
            grdMeasurementLinks.DataBind()
        End If
    End Sub

    Protected Sub SetGvwVersionHeader() Handles grdVersionSummary.PreRender
        Helpers.MakeAccessable(grdVersionSummary)
    End Sub

    Protected Sub SetGvwlinksHeader() Handles grdMeasurementLinks.PreRender
        Helpers.MakeAccessable(grdMeasurementLinks)
    End Sub

    Protected Sub grdVersionSummary_RowCommand(ByVal sender As Object, ByVal e As GridViewCommandEventArgs) Handles grdVersionSummary.RowCommand
        Dim xmlstr As String = e.CommandArgument
        Dim xml As XDocument = XDocument.Parse(xmlstr)

        Select Case e.CommandName.ToLower()
            Case "xml"
                Helpers.ExportToXML(Helpers.GetDateTimeFileName("XMLFile", "xml"), xml)
                Exit Select
            Case "loss"
                Helpers.ExportToXML(Helpers.GetDateTimeFileName("lossfile", "xml"), xml)
                Exit Select
            Case "productxml"
                Helpers.ExportToXML(Helpers.GetDateTimeFileName("ProductXMLFile", "xml"), xml)
                Exit Select
            Case "testxml"
                Helpers.ExportToXML(Helpers.GetDateTimeFileName("TestXMLFile", "xml"), xml)
                Exit Select
            Case "sequencexml"
                Helpers.ExportToXML(Helpers.GetDateTimeFileName("SequenceXMLFile", "xml"), xml)
                Exit Select
            Case "stationxml"
                Helpers.ExportToXML(Helpers.GetDateTimeFileName("StationXMLFile", "xml"), xml)
                Exit Select
        End Select
    End Sub
    Protected Sub grdMeasurementLinks_RowDataBound(ByVal sender As Object, ByVal e As GridViewRowEventArgs) Handles grdMeasurementLinks.RowDataBound
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim hplDetail As HyperLink = DirectCast(e.Row.FindControl("hplDetail"), HyperLink)
            hplDetail.NavigateUrl = String.Format("/Relab/Measurements.aspx?ID={0}&Batch={1}", DirectCast(e.Row.NamingContainer, System.Web.UI.WebControls.GridView).DataKeys(e.Row.RowIndex).Values(0).ToString(), Request.QueryString("Batch"))
        End If
    End Sub
End Class