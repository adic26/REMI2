Imports Remi.Bll
Imports System.Web.UI.DataVisualization.Charting
Imports System.IO
Imports System.Drawing

Public Class ResultGraph
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        Dim batchID As Int32
        Dim year As Int32
        Int32.TryParse(Request.QueryString("BatchID"), batchID)

        hypCancel.NavigateUrl = String.Format("/Relab/Results.aspx?Batch={0}", batchID)

        If Not Page.IsPostBack Then
            btnGenerateReport.Enabled = False
            btnExport.Enabled = False
            hdnBatchID.Value = batchID
            ddlMeasurementType.Visible = False

            For i As Int32 = DateTime.Now.Year To DateTime.Now.Year - 4 Step -1
                ddlYear.Items.Add(i)
            Next

            ddlTests.Visible = False

            If (batchID > 0) Then
                Dim qra = (From b In New Remi.Dal.Entities().Instance().Batches Where b.ID = batchID Select b.QRANumber, b.BatchStatus).FirstOrDefault()

                If (qra Is Nothing) Then
                    Response.Redirect("~/")
                End If

                If (qra.BatchStatus = 5 Or qra.BatchStatus = 7) Then
                    year = qra.QRANumber.Substring(qra.QRANumber.IndexOf("-") + 1, 2)
                End If
                DisplayQRA(year, batchID, sender, e)

                chklBatches_SelectedIndexChanged(sender, e)
            Else
                DisplayQRA(ddlYear.SelectedValue, batchID, sender, e)
            End If
            ddlYear.SelectedIndex = ddlYear.Items.IndexOf(ddlYear.Items.FindByValue(year))

            If (Request.QueryString("TestID") IsNot Nothing) Then
                If (ddlTests.Items.FindByValue(Request.QueryString("TestID")) Is Nothing) Then
                    Dim testID As Int32 = Request.QueryString("TestID")
                    Dim test = (From t In New REMI.Dal.Entities().Instance().Tests Where t.ID = testID Select t.TestName, t.ID).FirstOrDefault()

                    ddlTests.Items.Add(New ListItem(test.TestName, test.ID))
                End If

                ddlTests.SelectedValue = Request.QueryString("TestID")
                ddlTests_SelectedIndexChanged(sender, e)

                If (ddlTests.SelectedValue > 0) Then

                    If (Request.QueryString("MeasurementID") IsNot Nothing) Then
                        Dim measurementID As Int32 = Request.QueryString("MeasurementID")
                        Dim unitNumber As Int32 = (From m In New REMI.Dal.Entities().Instance().ResultsMeasurements Where m.ID = measurementID Select m.Result.TestUnit.BatchUnitNumber).FirstOrDefault()

                        Dim measurementTypeID As Int32 = (From m In New REMI.Dal.Entities().Instance().ResultsMeasurements _
                                                          Where m.ID = measurementID _
                                                          Select m.Lookup.LookupID).FirstOrDefault()
                        ddlMeasurementType.SelectedValue = measurementTypeID
                        ddlMeasurementType_SelectedIndexChanged(sender, e)

                        Dim dt As DataTable = RelabManager.GetMeasurementParameterCommaSeparated(measurementID)

                        If (dt.Rows(0)(0) IsNot Nothing And dt.Rows(0)(0) IsNot DBNull.Value) Then
                            ddlParameter.SelectedValue = dt.Rows(0)(0)
                            ddlParameter_SelectedIndexChanged(sender, e)
                        End If
                        If (dt.Rows(0)(1) IsNot Nothing And dt.Rows(0)(0) IsNot DBNull.Value) Then
                            ddlParameterValue.SelectedValue = dt.Rows(0)(1)
                            ddlParameterValue_SelectedIndexChanged(sender, e)
                        End If

                        Dim allUnits As Int32
                        Dim testStageID As Int32
                        Dim xAxis As Int32
                        Int32.TryParse(Request.QueryString("XAxis"), xAxis)
                        Int32.TryParse(Request.QueryString("AllUnits"), allUnits)
                        Int32.TryParse(Request.QueryString("TestStageID"), testStageID)

                        If (chklUnits.Items.Count > 0) Then
                            If (allUnits = 1) Then
                                chklUnits.Items(0).Selected = True
                            Else
                                chklUnits.Items(0).Selected = False

                                If (chklUnits.Items.FindByText(unitNumber) IsNot Nothing) Then
                                    chklUnits.Items.FindByText(unitNumber).Selected = True
                                Else
                                    chklUnits.Items(0).Selected = True
                                End If
                            End If
                        End If

                        If (testStageID > 0) Then
                            chklTestStages.Items(0).Selected = False

                            If (chklTestStages.Items.FindByValue(testStageID) IsNot Nothing) Then
                                chklTestStages.Items.FindByValue(testStageID).Selected = True
                            End If
                        End If

                        ddlXAxis.SelectedValue = xAxis

                        Query(False)
                    End If
                End If
            End If
        End If
    End Sub

#Region "Events"
    Protected Sub ddlYear_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlYear.SelectedIndexChanged
        DisplayQRA(ddlYear.SelectedValue, 0, Nothing, Nothing)
    End Sub

    Protected Sub chkShowOnlyFailValue_CheckedChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles chkShowOnlyFailValue.CheckedChanged
        ddlTests_SelectedIndexChanged(sender, e)
    End Sub

    Protected Sub chklBatches_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles chklBatches.SelectedIndexChanged
        Dim batchIDs As List(Of Int32) = (From item In chklBatches.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()
        btnGenerateReport.Enabled = False
        btnExport.Enabled = False

        chklUnits.Items.Clear()
        ddlTests.Items.Clear()
        ddlTests.Items.Add(New ListItem("Select A Test", 0))

        If (batchIDs.Count > 0) Then
            ddlTests.DataSource = RelabManager.GetAvailableTestsByBatches(String.Join(",", batchIDs.ConvertAll(Of String)(Function(i As Integer) i.ToString()).ToArray()))
            ddlTests.DataBind()
            ddlTests.Visible = True
        End If
        ddlMeasurementType.Visible = False
    End Sub

    Protected Sub ddlTests_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlTests.SelectedIndexChanged
        Dim batchIDs As List(Of Int32) = (From item In chklBatches.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()
        btnGenerateReport.Enabled = False
        btnExport.Enabled = False

        ddlMeasurementType.Items.Clear()
        ddlParameter.Items.Clear()
        ddlParameterValue.Items.Clear()
        ddlMeasurementType.Items.Add(New ListItem("Select A Measurement", 0))

        If (ddlTests.SelectedValue > 0) Then
            ddlMeasurementType.DataSource = RelabManager.GetMeasurementsByTest(String.Join(",", batchIDs.ConvertAll(Of String)(Function(i As Integer) i.ToString()).ToArray()), ddlTests.SelectedValue, chkShowOnlyFailValue.Checked)
            ddlMeasurementType.DataBind()
            ddlMeasurementType.Visible = True
        Else
            ddlMeasurementType.Visible = False
        End If
    End Sub

    Protected Sub ddlMeasurementType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlMeasurementType.SelectedIndexChanged
        Dim batchIDs As List(Of Int32) = (From item In chklBatches.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()

        ddlParameter.Items.Clear()
        ddlParameter.Items.Add(New ListItem("Select A Parameter", String.Empty))
        ddlParameterValue.Items.Clear()

        If (ddlMeasurementType.SelectedValue > 0) Then
            Dim par As DataTable = RelabManager.GetParametersByMeasurementTest(String.Join(",", batchIDs.ConvertAll(Of String)(Function(i As Integer) i.ToString()).ToArray()), ddlTests.SelectedValue, ddlMeasurementType.SelectedValue, String.Empty, chkShowOnlyFailValue.Checked, String.Empty)
            ddlParameter.DataSource = par
            ddlParameter.DataBind()

            chklUnits.Visible = True
            GetUnits(String.Join(",", batchIDs.ConvertAll(Of String)(Function(i As Integer) i.ToString()).ToArray()), ddlMeasurementType.SelectedValue, String.Empty, String.Empty)

            If (ddlParameter.Items.Count > 1) Then
                ddlParameter.Visible = True
            End If
            btnGenerateReport.Enabled = True
            btnExport.Enabled = True
        Else
            ddlParameter.Visible = False
            chklUnits.Visible = False
            btnGenerateReport.Enabled = False
            btnExport.Enabled = False
        End If
    End Sub

    Protected Sub ddlParameter_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlParameter.SelectedIndexChanged
        Dim batchIDs As List(Of Int32) = (From item In chklBatches.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()

        ddlParameterValue.Items.Clear()
        ddlParameterValue.Items.Add(New ListItem("Select A Value", String.Empty))

        If (Not (String.IsNullOrEmpty(ddlParameter.SelectedValue))) Then
            ddlParameterValue.DataSource = RelabManager.GetParametersByMeasurementTest(String.Join(",", batchIDs.ConvertAll(Of String)(Function(i As Integer) i.ToString()).ToArray()), ddlTests.SelectedValue, ddlMeasurementType.SelectedValue, ddlParameter.SelectedValue, chkShowOnlyFailValue.Checked, String.Empty)
            ddlParameterValue.DataBind()

            If (ddlParameterValue.Items.Count > 0) Then
                ddlParameterValue.Visible = True
            End If
            GetUnits(String.Join(",", batchIDs.ConvertAll(Of String)(Function(i As Integer) i.ToString()).ToArray()), ddlMeasurementType.SelectedValue, ddlParameter.SelectedValue, String.Empty)
        Else
            chklUnits.Visible = True
            ddlParameterValue.Visible = False
            GetUnits(String.Join(",", batchIDs.ConvertAll(Of String)(Function(i As Integer) i.ToString()).ToArray()), ddlMeasurementType.SelectedValue, String.Empty, String.Empty)
        End If
    End Sub

    Protected Sub ddlParameterValue_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) Handles ddlParameterValue.SelectedIndexChanged
        Dim batchIDs As List(Of Int32) = (From item In chklBatches.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()

        If (Not (String.IsNullOrEmpty(ddlParameterValue.SelectedValue))) Then
            GetUnits(String.Join(",", batchIDs.ConvertAll(Of String)(Function(i As Integer) i.ToString()).ToArray()), ddlMeasurementType.SelectedValue, ddlParameter.SelectedValue, ddlParameterValue.SelectedValue)
        Else
            GetUnits(String.Join(",", batchIDs.ConvertAll(Of String)(Function(i As Integer) i.ToString()).ToArray()), ddlMeasurementType.SelectedValue, ddlParameter.SelectedValue, String.Empty)
        End If
        chklUnits.Visible = True
    End Sub

    Protected Sub chklUnits_DataBound(ByVal sender As Object, ByVal e As System.EventArgs) Handles chklUnits.DataBound
        Dim dt As DataTable = DirectCast(DirectCast(sender, CheckBoxList).DataSource, DataTable)

        For Each li As ListItem In DirectCast(sender, CheckBoxList).Items
            If (li.Value <> "All") Then
                Dim dRows As DataRow() = dt.Select("id = " + li.Value)

                If (dRows IsNot Nothing) Then
                    If (dRows.Length > 0) Then
                        li.Attributes.Add("Title", dRows(0)("QRANumber"))
                    End If
                End If
            End If
        Next
    End Sub
#End Region

#Region "Methods"
    Sub GetUnits(ByVal batchIDs As String, ByVal measurementTypeID As Int32, ByVal parameterName As String, ByVal parameterValue As String)
        chklUnits.Items.Clear()
        chklUnits.Items.Add("All")
        chklUnits.DataSource = RelabManager.GetUnitsByTestMeasurementParameters(batchIDs, ddlTests.SelectedValue, measurementTypeID, parameterName, parameterValue, False, chkShowOnlyFailValue.Checked)
        chklUnits.DataBind()

        chklUnits.Items(0).Selected = True

        chklTestStages.Items.Clear()
        chklTestStages.Items.Add("All")
        chklTestStages.DataSource = RelabManager.GetUnitsByTestMeasurementParameters(batchIDs, ddlTests.SelectedValue, measurementTypeID, parameterName, parameterValue, True, chkShowOnlyFailValue.Checked)
        chklTestStages.DataBind()

        chklTestStages.Items(0).Selected = True

        pnlUnits.Style.Add("HEIGHT", IIf(chklUnits.Items.Count > 5, 25 * 5, 25 * chklUnits.Items.Count) & "px")
        pnlTestStage.Style.Add("HEIGHT", IIf(chklTestStages.Items.Count > 5, 25 * 5, 25 * chklTestStages.Items.Count) & "px")
    End Sub

    Private Sub DisplayQRA(ByVal year As Int32, ByVal batchID As Int32, ByVal sender As Object, ByVal e As System.EventArgs)
        chklBatches.Items.Clear()

        Dim dt As DataTable = BatchManager.GetYourActiveBatchesDataTable(UserManager.GetCurrentUser.ByPassProduct, year, True)
        chklBatches.DataSource = dt
        chklBatches.DataTextField = "Name"
        chklBatches.DataValueField = "ID"
        chklBatches.DataBind()

        If (batchID > 0) Then
            chklBatches.SelectedValue = batchID
        End If
    End Sub

    Sub Query(ByVal formSubmit As Boolean)
        Dim batchIDs As List(Of Int32) = (From item In chklBatches.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()
        Dim qras As List(Of String) = (From item In chklBatches.Items.Cast(Of ListItem)() Where item.Selected = True Select item.Text).ToList()
        Dim units As List(Of Int32)
        Dim unitNumbers As List(Of Int32)
        Dim stages As List(Of Int32)

        If (chklUnits.Items(0).Selected) Then
            units = (From item In chklUnits.Items.Cast(Of ListItem)() Where item.Text <> "All" Select Convert.ToInt32(item.Value)).ToList()
            unitNumbers = (From item In chklUnits.Items.Cast(Of ListItem)() Where item.Text <> "All" Select Convert.ToInt32(item.Text)).ToList()
        Else
            units = (From item In chklUnits.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()
            unitNumbers = (From item In chklUnits.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Text)).ToList()
        End If

        If (chklTestStages.Items(0).Selected) Then
            stages = (From item In chklTestStages.Items.Cast(Of ListItem)() Where item.Text <> "All" Select Convert.ToInt32(item.Value)).ToList()
        Else
            stages = (From item In chklTestStages.Items.Cast(Of ListItem)() Where item.Selected = True Select Convert.ToInt32(item.Value)).ToList()
        End If

        If (batchIDs.Count > 0 And stages.Count > 0 And units.Count > 0) Then
            Dim ds As DataSet = RelabManager.ResultGraph(String.Join(",", batchIDs.ConvertAll(Of String)(Function(j As Integer) j.ToString()).ToArray()), String.Join(",", units.ConvertAll(Of String)(Function(k As Integer) k.ToString()).ToArray()), ddlMeasurementType.SelectedValue, ddlParameter.SelectedValue, ddlParameterValue.SelectedValue, chkShowUpperLower.Checked, ddlTests.SelectedValue, ddlXAxis.SelectedValue, ddlGraphValue.SelectedValue, chkShowArchived.Checked, String.Join(",", stages.ConvertAll(Of String)(Function(j As Integer) j.ToString()).ToArray()))
            Dim i As Integer = 0
            Dim dataCount As Int32 = 0

            For Each dt As DataTable In ds.Tables
                dataCount += 1
                Dim grd As New GridView
                grd.ID = "grd" + dataCount.ToString()
                grd.DataSource = dt
                grd.DataBind()
                Helpers.MakeAccessable(grd)
                pnlData.Controls.Add(grd)
            Next
            dataCount = 0

            chtGraph.ChartAreas.Add("ChtArea")
            chtGraph.ChartAreas(0).AxisX.Title = If(ddlXAxis.SelectedItem.Value = 2, String.Format("{0} - {1}", ddlXAxis.SelectedItem.Text, ddlParameter.SelectedItem.Text), ddlXAxis.SelectedItem.Text)
            chtGraph.ChartAreas(0).AxisX.TitleFont = New System.Drawing.Font("Verdana", 11, System.Drawing.FontStyle.Bold)
            chtGraph.ChartAreas(0).AxisY.Title = "Measurement"
            chtGraph.ChartAreas(0).AxisY.TitleFont = New System.Drawing.Font("Verdana", 11, System.Drawing.FontStyle.Bold)
            chtGraph.ChartAreas(0).BorderWidth = 2
            chtGraph.ChartAreas(0).BorderDashStyle = ChartDashStyle.Solid
            chtGraph.ChartAreas(0).AxisX.IsMarginVisible = True
            chtGraph.ChartAreas(0).AxisX.Interval = 1
            chtGraph.BorderSkin.SkinStyle = BorderSkinStyle.Emboss
            chtGraph.BackColor = Drawing.Color.Ivory
            chtGraph.ChartAreas(0).AxisY.MajorGrid.Enabled = False
            chtGraph.ChartAreas(0).AxisX.MajorGrid.Enabled = False
            chtGraph.ChartAreas(0).AxisX.LabelStyle.IsStaggered = False

            Dim title As StringBuilder = New StringBuilder()
            title.AppendLine(String.Format("QRA(s): {0}", String.Join(",", qras.ConvertAll(Of String)(Function(j As String) j.ToString()).ToArray())))
            title.AppendLine(String.Format("Unit(s): {0}", String.Join(",", unitNumbers.ConvertAll(Of String)(Function(j As String) j.ToString()).ToArray())))
            title.Append(String.Format("Test: '{0}'", ddlTests.SelectedItem.Text))
            title.AppendLine(String.Format("Measurement: '{0}' ", ddlMeasurementType.SelectedItem.Text))

            If (Not (String.IsNullOrEmpty(ddlParameter.SelectedValue))) Then
                title.Append(String.Format("Parameter: '{0}' ", ddlParameter.SelectedItem.Text))

                If (Not (String.IsNullOrEmpty(ddlParameterValue.SelectedValue))) Then
                    title.AppendLine(String.Format("Parameter Value: '{0}'", ddlParameterValue.SelectedItem.Text))
                End If
            End If

            chtGraph.Titles.Add(New Title(title.ToString(), Docking.Top, New Font("Verdana", 8, FontStyle.Bold), Color.Black))
            chtGraph.Titles(0).Alignment = ContentAlignment.TopLeft

            chtGraph.Legends.Add(ddlXAxis.SelectedItem.Text)
            chtGraph.Legends(0).LegendStyle = LegendStyle.Row
            chtGraph.Legends(0).TableStyle = LegendTableStyle.Auto
            chtGraph.Legends(0).Docking = Docking.Bottom
            chtGraph.Legends(0).Alignment = ContentAlignment.MiddleLeft
            chtGraph.Legends(0).IsDockedInsideChartArea = True
            chtGraph.Legends(0).BackColor = Drawing.Color.Ivory

            For Each dt As DataTable In ds.Tables
                If (dt.Rows.Count > 0) Then
                    dataCount += 1
                    Dim chartSeriesName As String = dt.Rows(0).Item(2).ToString().Trim()
                    chtGraph.Series.Add(String.Format("{0}", chartSeriesName))
                    If (chartSeriesName.Contains("Specification")) Then
                        chtGraph.Series(i).Color = Color.Red
                    End If
                    chtGraph.Series(i).IsValueShownAsLabel = True
                    chtGraph.Series(i).IsVisibleInLegend = True
                    chtGraph.Series(i).ChartType = ddlChartType.SelectedValue
                    chtGraph.Series(i).MarkerStyle = MarkerStyle.Circle
                    chtGraph.Series(i).MarkerSize = 6
                    chtGraph.Series(i).ChartArea = "ChtArea"
                    chtGraph.Series(i).Points.DataBind(ds.Tables(i).DefaultView, "XAxis", "YAxis", String.Empty)

                    i += 1
                End If
            Next
            chtGraph.AlignDataPointsByAxisLabel()
            chtGraph.ChartAreas(0).AxisY.IntervalType = DateTimeIntervalType.Auto
            chtGraph.ChartAreas(0).AxisY.IsStartedFromZero = False

            If (dataCount = 0) Then
                chtGraph.Visible = False
                lblErrorMessage.Visible = True
                lblErrorMessage.Text = "There Was No Graphable Data"
                lblErrorMessage.ForeColor = Color.Red
                lblErrorMessage.Font.Bold = True
                lblErrorMessage.Font.Size = 10
            Else
                chtGraph.Visible = True
                lblErrorMessage.Visible = False
            End If
        Else
            lblErrorMessage.Visible = True
            lblErrorMessage.Text = "There Was No Graphable Data"
            lblErrorMessage.ForeColor = Color.Red
            lblErrorMessage.Font.Bold = True
            lblErrorMessage.Font.Size = 10
        End If
    End Sub
#End Region

#Region "Button"
    Protected Sub btnGenerateReport_OnClick(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnGenerateReport.Click
        Query(True)
    End Sub

    Protected Sub btnExport_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnExport.Click
        Query(True)
        Dim response As HttpResponse = HttpContext.Current.Response
        response.Clear()
        response.Buffer = True
        response.AddHeader("content-disposition", "attachment;filename=ChartExport.xls")
        response.ContentType = "application/vnd.ms-excel"
        response.Charset = ""
        Dim sw As New StringWriter()
        Dim hw As New HtmlTextWriter(sw)
        chtGraph.RenderControl(hw)
        Dim src As String = Regex.Match(sw.ToString(), "<img.+?src=[""'](.+?)[""'].+?>", RegexOptions.IgnoreCase).Groups(1).Value
        Dim table As String = "<table><tr><td><img src='{0}' /></td></tr></table>"
        table = String.Format(table, Request.Url.GetLeftPart(UriPartial.Authority) + src)
        response.Write(table)
        response.Flush()
        response.End()
    End Sub
#End Region
End Class