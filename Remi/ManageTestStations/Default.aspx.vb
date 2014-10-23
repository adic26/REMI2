Imports Remi.BusinessEntities
Imports Remi.Validation
Imports Remi.Bll
Imports Remi.Contracts
Imports System.Data
Imports System.Web.UI.DataVisualization.Charting
Imports System.Drawing

Partial Class ManageTestStations_Default
    Inherits System.Web.UI.Page

    Protected Sub updTimeline_PreRender() Handles updTimeline.PreRender
        updChart.Update()

        If (chkShowGrid.Checked) Then
            pnlGrid.Visible = True
        Else
            pnlGrid.Visible = False
        End If
    End Sub

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            ddlDepartments.DataBind()
        Else
            Bind()
        End If

        Me.Master.Page.Title = "REMI - In Timeline - " + DateTime.Now.ToString("f")
    End Sub

    Protected Sub Bind()
        Dim ctuL As New List(Of ChamberTestUnit)
        Dim bs As BatchSearch = New BatchSearch()

        If (ddlDisplayBy.SelectedValue = 1) Then
            bs.TestStageType = TestStageType.EnvironmentalStress
            bs.ExcludedTestStageType = BatchSearchTestStageType.Parametric
            bs.Status = BatchStatus.InProgress
            bs.TrackingLocationFunction = TrackingLocationFunction.EnvironmentalStressing
            bs.GeoLocationID = UserManager.GetCurrentUser.TestCentreID
            bs.DepartmentID = ddlDepartments.SelectedValue
            chkShowGrid.Enabled = True
        Else
            chkShowGrid.Checked = False
            chkShowGrid.Enabled = False
            bs.Status = BatchStatus.InProgress
            bs.GeoLocationID = UserManager.GetCurrentUser.TestCentreID
            bs.DepartmentID = ddlDepartments.SelectedValue
        End If

        Dim bc As BatchCollection = BatchManager.BatchSearch(bs, UserManager.GetCurrentUser.ByPassProduct, UserManager.GetCurrentUser.ID, True, True)

        If (chkShowGrid.Checked) Then
            pnlGrid.Visible = True
            pnlChamberLegend.Visible = True

            For Each b As Batch In bc
                Dim ctu As New ChamberTestUnit
                ctu.BatchInfoLink = b.BatchInfoLink
                ctu.TotalTestTime = b.GetTotalTestTime(b.TestUnits(0).BatchUnitNumber, b.TestUnits(0).CurrentTestName, b.TestUnits(0).CurrentTestStageName)
                ctu.QRAnumber = b.QRANumber
                ctu.Assignedto = b.TestUnits(0).AssignedTo
                ctu.Job = b.JobName
                ctu.ProductGroupName = b.ProductGroup
                ctu.TestStage = b.TestStageName
                ctu.Location = b.TestUnits(0).LocationString
                ctu.InTime = b.TestUnits(0).CurrentLog.InTime
                ctu.GetExpectedCompletionDateTime = b.GetExpectedCompletionDateTime 'When it should be completed
                ctu.TestLength = b.GetExpectedTestStageDuration(b.TestUnits(0).CurrentTestStage.ID)
                Dim locationStatus = (From tl In New REMI.Dal.Entities().Instance().TrackingLocations Where tl.TrackingLocationName = ctu.Location Select tl)
                ctu.Status = IIf(locationStatus.FirstOrDefault().Status.HasValue(), locationStatus.FirstOrDefault().Status, 1)
                ctuL.Add(ctu)
            Next

            grdUnits.DataSource = ctuL
            grdUnits.DataBind()
        Else
            pnlGrid.Visible = False
            pnlChamberLegend.Visible = False
        End If

        chtStressing.ChartAreas.Add("ChtArea")
        chtStressing.ChartAreas(0).AxisX.TitleFont = New System.Drawing.Font("Verdana", 8, System.Drawing.FontStyle.Bold)
        chtStressing.ChartAreas(0).AxisY2.Title = "Date"
        chtStressing.ChartAreas(0).AxisY2.TitleFont = New System.Drawing.Font("Verdana", 8, System.Drawing.FontStyle.Bold)
        chtStressing.ChartAreas(0).AxisX.LabelStyle.IsStaggered = False
        chtStressing.ChartAreas(0).AlignmentStyle = AreaAlignmentStyles.PlotPosition
        chtStressing.ChartAreas(0).AxisX.LabelStyle.Enabled = True
        chtStressing.ChartAreas(0).AxisY2.LabelStyle.Enabled = True
        chtStressing.ChartAreas(0).AxisY2.LabelStyle.IsEndLabelVisible = True
        chtStressing.ChartAreas(0).AxisY2.IsLabelAutoFit = True
        chtStressing.ChartAreas(0).AxisY2.LabelStyle.IsStaggered = True
        chtStressing.ChartAreas(0).AxisY.MajorGrid.Enabled = False
        chtStressing.ChartAreas(0).AxisX.MajorGrid.Enabled = False
        chtStressing.ChartAreas(0).AxisY2.MajorGrid.Enabled = False
        chtStressing.BackColor = Drawing.Color.Ivory
        chtStressing.ChartAreas(0).Area3DStyle.Enable3D = True
        chtStressing.ChartAreas(0).Area3DStyle.IsClustered = True

        If (ddlDisplayBy.SelectedValue = 1) Then
            pnlLabTimeline.Visible = False
            chtStressing.ChartAreas(0).AxisX.Title = "Location"
            pnlTimeFrame.Visible = False
            chtStressing.Titles.Add(New Title("Chamber/Mechanical Usage", Docking.Top, New Font("Verdana", 11, FontStyle.Bold), Color.Black))
        Else
            pnlLabTimeline.Visible = True
            pnlTimeFrame.Visible = True
            chtStressing.ChartAreas(0).AxisX.Title = "Request"
            chtStressing.Titles.Add(New Title("Lab Timeline", Docking.Top, New Font("Verdana", 11, FontStyle.Bold), Color.Black))
        End If

        Dim xValues As New List(Of String)
        Dim yValues1 As New List(Of Double)
        Dim yValues2 As New List(Of Double)
        Dim minAmountOfHours As Int32 = 0
        Dim series As New Series
        Dim iii As Int32 = 0

        For Each b As Batch In bc
            If (ddlDisplayBy.SelectedValue = 1) Then
                Dim getExpectedCompletionDateTime As DateTime

                If (ddlDisplayBy.SelectedValue = 1) Then
                    DateTime.TryParse(b.GetExpectedCompletionDateTime, getExpectedCompletionDateTime)
                Else
                    DateTime.TryParse(b.GetExpectedJobCompletionDateTime, getExpectedCompletionDateTime)
                End If

                If (getExpectedCompletionDateTime = DateTime.MinValue) Then
                    getExpectedCompletionDateTime = DateTime.Now
                End If

                If (b.TestUnits(0).CurrentTestStage.Name = b.TestStageName) Then
                    Dim sb As New StringBuilder()
                    sb.Append(String.Format("{0} \n {1}", b.TestUnits(0).LocationString, b.QRANumber))

                    Dim diff As Int32 = DateDiff(DateInterval.Hour, b.TestUnits(0).CurrentLog.InTime.AddHours(-5), getExpectedCompletionDateTime)

                    If (b.TestUnits(0).CurrentLog.InTime.AddHours(-5) < DateTime.Now) Then
                        diff = diff - DateDiff(DateInterval.Hour, b.TestUnits(0).CurrentLog.InTime.AddHours(-5), DateTime.Now)
                    End If

                    If (diff < minAmountOfHours) Then
                        minAmountOfHours = diff
                    End If

                    xValues.Add(sb.ToString())
                    yValues1.Add(CDbl(DateAdd(DateInterval.Day, DateDiff(DateInterval.Day, getExpectedCompletionDateTime, b.TestUnits(0).CurrentLog.InTime.AddHours(-5)), b.TestUnits(0).CurrentLog.InTime.AddHours(-5)).ToOADate())) 'How long it's been in
                    yValues2.Add(getExpectedCompletionDateTime.ToOADate()) 'Completed Date
                End If
            Else
                Dim lastDate As DateTime = DateTime.Now

                For Each a In b.TestStageTimeLeftGrid
                    If lastDate < DateTime.Now.AddHours(ddlTimeFrame.SelectedValue) Then
                        Dim stageID As Int32 = 0
                        b.TestStageIDTimeLeftGrid.TryGetValue(a.Key, stageID)

                        chtStressing.Series.Add(String.Format("{0}{1}", b.ID.ToString(), stageID.ToString()))
                        series = chtStressing.Series.FindByName(String.Format("{0}{1}", b.ID.ToString(), stageID.ToString()))
                        series.CustomProperties = "PointWidth=0.2"
                        series("DrawSideBySide") = False
                        series("BarLabelStyle") = "Left"
                        series.ChartType = SeriesChartType.RangeBar
                        series.YAxisType = AxisType.Secondary
                        series.IsXValueIndexed = True
                        series.YValuesPerPoint = 2
                        series.IsValueShownAsLabel = False
                        series.YValueType = ChartValueType.DateTime
                        series.XValueType = ChartValueType.String
                        series.BorderColor = System.Drawing.Color.FromArgb(200, 26, 59, 105)
                        series.BorderDashStyle = ChartDashStyle.Solid
                        series.BorderWidth = 1

                        Dim val As Double
                        Dim val2 As Double

                        val = lastDate.ToOADate()

                        If (a.Value = 0) Then
                            lastDate = lastDate.AddMinutes(1)
                        Else
                            lastDate = lastDate.AddHours(a.Value)
                        End If

                        val2 = lastDate.ToOADate()

                        series.Points.AddXY(iii, val, val2)
                        series.Points(0).AxisLabel = b.QRANumber

                        Dim str As String = a.Key

                        Dim sizeF As New SizeF
                        Dim graphics As Graphics = System.Drawing.Graphics.FromImage(New System.Drawing.Bitmap(1, 1))
                        sizeF = graphics.MeasureString(str, New Font("Verdana", 7, FontStyle.Bold))
                        graphics.Dispose()

                        Dim ed As DateTime = DateTime.Now.AddHours(ddlTimeFrame.SelectedValue) 'End of Grid
                        Dim td As Int32 = DateDiff(DateInterval.Second, DateTime.Now, ed) 'Overall difference from start of grid to end of grid
                        Dim dd As Int32 = DateDiff(DateInterval.Second, DateTime.FromOADate(val), DateTime.FromOADate(val2)) ' DateDiff between start point and end point in seconds
                        Dim dd2 As Int32 = DateDiff(DateInterval.Second, DateTime.FromOADate(val2), ed) 'DateDiff between end point and End Of Grid

                        Dim percentageUsed As Int32 = (dd / td * 100) 'Calculate percentage bar by dividing bar size by total grid size
                        Dim pixelUsed As Int32 = 1200 * (percentageUsed / 100)

                        If (100 - (sizeF.Width / pixelUsed * 100) >= 15) Then 'Must have roughly 15 pixel space
                            series.Points(0).Label = str
                        End If

                        series.Points(0).ToolTip = a.Key

                        Dim tsType As TestStageType = (From ts In b.Job.TestStages Where ts.Name = a.Key Select ts.TestStageType).FirstOrDefault()

                        If (tsType = TestStageType.EnvironmentalStress) Then
                            series.Points(0).Color = Color.Khaki
                        ElseIf (tsType = TestStageType.Parametric) Then
                            series.Points(0).Color = Color.LightBlue
                        Else
                            series.Points(0).Color = Color.LightYellow
                        End If

                        series.Font = New Font("Verdana", 7, FontStyle.Bold)
                    End If
                Next

                iii += 1
            End If
        Next

        Dim DateFrom As DateTime
        Dim DateTo As DateTime

        If (ddlDisplayBy.SelectedValue = 1) Then
            chtStressing.Series.Add("Series1")
            series = chtStressing.Series.FindByName("Series1")
            series.CustomProperties = "PointWidth=0.1"
            series.ChartType = SeriesChartType.RangeBar
            series.YAxisType = AxisType.Secondary
            series.IsXValueIndexed = False
            series.YValuesPerPoint = 2
            series.IsValueShownAsLabel = True
            series.YValueType = ChartValueType.DateTime
            series.XValueType = ChartValueType.String
            series.Points.DataBindXY(xValues, yValues1.ToArray, yValues2.ToArray)

            Dim i As Int32 = 0
            For Each point In series.Points
                point.Label = DateTime.FromOADate(yValues2(i))
                point.LabelFormat = "{0:MM/dd/yyyy hh tt}"
                point.Font = New Font("Verdana", 6, FontStyle.Bold)
                i = i + 1
            Next

            If (minAmountOfHours = 0) Then
                DateFrom = DateAdd(DateInterval.Hour, -1, DateTime.Now)
                DateTo = DateAdd(DateInterval.Hour, 4, DateTime.Now)
            ElseIf (minAmountOfHours > 0 And minAmountOfHours <= 8) Then
                DateFrom = DateTime.Now
                DateTo = DateAdd(DateInterval.Hour, 9, DateTime.Now)
            ElseIf (minAmountOfHours > 8 And minAmountOfHours <= 24) Then
                DateFrom = DateTime.Now
                DateTo = DateAdd(DateInterval.Day, 1, DateTime.Now)
            ElseIf (minAmountOfHours > 24 And minAmountOfHours <= 168) Then
                DateFrom = DateTime.Now
                DateTo = DateAdd(DateInterval.Day, 7, DateTime.Now)
            ElseIf (minAmountOfHours > 168 And minAmountOfHours <= 730) Then
                DateFrom = DateTime.Now
                DateTo = DateAdd(DateInterval.Month, 1, DateTime.Now)
            End If
        Else
            DateFrom = DateTime.Now
            DateTo = DateTime.Now.AddHours(ddlTimeFrame.SelectedValue)
        End If

        chtStressing.ChartAreas(0).AxisX.IsReversed = True
        chtStressing.ChartAreas(0).AxisY2.Enabled = AxisEnabled.True
        chtStressing.ChartAreas(0).AxisY2.IsMarginVisible = True
        chtStressing.ChartAreas(0).AxisX.Interval = 1
        chtStressing.ChartAreas(0).AxisY2.Interval = 1
        chtStressing.ChartAreas(0).AxisY2.Minimum = DateFrom.ToOADate()
        chtStressing.ChartAreas(0).AxisY2.Maximum = DateTo.ToOADate()
        chtStressing.ChartAreas(0).AxisY2.LabelStyle.Angle = 60
        chtStressing.ChartAreas(0).AxisY2.LabelStyle.Font = New Font("Verdana", 6, FontStyle.Bold)
        chtStressing.AlignDataPointsByAxisLabel()

        If (DateDiff(DateInterval.Day, DateFrom, DateTo) <= 1) Then
            chtStressing.ChartAreas(0).AxisY2.LabelStyle.Format = "{0:MM/dd/yyyy - hh tt}"
            chtStressing.ChartAreas(0).AxisY2.IntervalType = DateTimeIntervalType.Hours
        ElseIf (DateDiff(DateInterval.Day, DateFrom, DateTo) < 15) Then
            chtStressing.ChartAreas(0).AxisY2.LabelStyle.Format = "{0:MM/dd/yyyy}"
            chtStressing.ChartAreas(0).AxisY2.IntervalType = DateTimeIntervalType.Days
        Else
            chtStressing.ChartAreas(0).AxisY2.LabelStyle.Format = "{0:MM/dd/yyyy}"
            chtStressing.ChartAreas(0).AxisY2.IntervalType = DateTimeIntervalType.Weeks
        End If

        If (bc.Count < 10) Then
            chtStressing.Height = 600
        Else
            chtStressing.Height = bc.Count * 60
        End If
    End Sub

    Protected Sub FixGridviews() Handles grdUnits.PreRender
        Helpers.MakeAccessable(grdUnits)
    End Sub

    Protected Sub grdUnits_RowCreated(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.GridViewRowEventArgs) Handles grdUnits.RowCreated
        If e.Row.RowType = DataControlRowType.DataRow Then
            Dim decomm As Boolean = False
            Dim status As String = String.Empty
            Dim color As System.Drawing.Color

            If (DataBinder.Eval(e.Row.DataItem, "Status") IsNot Nothing) Then
                status = DataBinder.Eval(e.Row.DataItem, "Status").ToString()
            End If

            Select Case status
                Case Remi.Contracts.TrackingStatus.Functional.ToString()
                    color = Drawing.Color.White

                    If (DataBinder.Eval(e.Row.DataItem, "CanBeRemovedAt").ToString().Contains("Now")) Then
                        color = Drawing.Color.PaleGreen
                    End If
                Case Remi.Contracts.TrackingStatus.Disabled.ToString()
                    color = Drawing.Color.LightGray
                Case Remi.Contracts.TrackingStatus.NotFunctional.ToString()
                    color = Drawing.Color.Red
                Case Remi.Contracts.TrackingStatus.UnderRepair.ToString()
                    color = Drawing.Color.Orange
            End Select

            e.Row.BackColor = color
        End If
    End Sub
End Class