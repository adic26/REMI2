﻿Imports REMI.BusinessEntities
Imports REMI.Bll
Imports REMI.Validation
Imports Remi.Contracts

Partial Class Admin_Tests_EditDetail
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        If Not Page.IsPostBack Then
            notMain.Clear()
            Dim itemID As Integer = Request.QueryString.Get("testID")

            If itemID > 0 Then
                ProcessTestID(itemID)
            Else
                SetUpforNew()
            End If
        End If
    End Sub

    Protected Sub SetUpforNew()
        Dim litTitle As Literal = Master.FindControl("litPageTitle")
        If litTitle IsNot Nothing Then
            litTitle.Text = "REMI - Add New Parametric Test"
        End If

        lblTitle.Text = "Add New Parametric Test"
        lblTestName.Visible = False
        txtName.Visible = True
    End Sub

    Protected Sub ProcessTestID(ByVal tmpID As Integer)
        Try
            Dim t As Test = TestManager.GetTest(tmpID)
            If t IsNot Nothing Then
                Dim litTitle As Literal = Master.FindControl("litPageTitle")
                If litTitle IsNot Nothing Then
                    litTitle.Text = "REMI - Edit Test - " + t.Name
                End If
                hdnEditID.Value = t.ID
                lblTestName.Visible = True
                txtName.Visible = False
                lblTitle.Text = "Editing " + t.Name
                lblTestName.Text = t.Name
                txtName.Text = t.Name
                lstAllTLTypes.DataBind()
                lstAddedTLTypes.Items.Clear()

                If t.TrackingLocationTypes.Count > 0 Then
                    'remove the ones in the test unit from the full list so they
                    'cannot be added twice.
                    For Each tl As TrackingLocationType In t.TrackingLocationTypes
                        Dim li As ListItem = lstAllTLTypes.Items.FindByValue(btnAddTLType.ID)
                        lstAllTLTypes.Items.Remove(li)
                    Next

                    'then databind the listin the test unit to the "added" listbox
                    lstAddedTLTypes.DataSource = t.TrackingLocationTypes
                    lstAddedTLTypes.DataBind()
                End If

                Select Case t.TestType
                    Case TestType.Parametric
                        rbnParametric.Checked = True
                    Case TestType.EnvironmentalStress
                        rbnEnvironmentalStress.Checked = True
                    Case TestType.IncomingEvaluation
                        rbnIncoming.Checked = True
                    Case TestType.NonTestingTask
                        rbnNonTestingTask.Checked = True
                    Case Else
                End Select

                chkResultIsTimeBased.Checked = t.ResultIsTimeBased
                txtHours.Text = t.TotalHours
                txtWorkInstructionLocation.Text = t.WorkInstructionLocation
                txtOwner.Text = t.Owner
                txtTrainee.Text = t.Trainee
                txtDegradation.Text = t.Degradation
                chkArchived.Checked = t.IsArchived
            Else
                notMain.Notifications.AddWithMessage("Unable to locate the given test.", NotificationType.Warning)
            End If
        Catch ex As Exception
            notMain.Notifications = Helpers.GetExceptionMessages(ex)
        End Try
    End Sub

    Protected Sub btnAddTLType_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnAddTLType.Click
        lstAddedTLTypes.ClearSelection()
        Dim li As ListItem = lstAllTLTypes.SelectedItem

        If li IsNot Nothing Then
            lstAddedTLTypes.Items.Add(li)
            lstAllTLTypes.Items.Remove(li)
        End If
    End Sub

    Protected Sub btnRemoveTLType_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnRemoveTLType.Click
        Dim li As ListItem = lstAddedTLTypes.SelectedItem

        If li IsNot Nothing Then
            lstAllTLTypes.Items.Add(li)
            lstAddedTLTypes.Items.Remove(li)
        End If
    End Sub

    Private Sub SetTestParametersforSave(ByVal tmpTest As Test)
        tmpTest.Name = txtName.Text
        tmpTest.WorkInstructionLocation = txtWorkInstructionLocation.Text
        tmpTest.Owner = txtOwner.Text
        tmpTest.Trainee = txtTrainee.Text
        tmpTest.Degradation = txtDegradation.Text
        tmpTest.TrackingLocationTypes.Clear()

        For Each li As ListItem In lstAddedTLTypes.Items
            Dim tlt As New TrackingLocationType
            tlt.ID = li.Value
            tlt.Name = li.Text

            If (Not tmpTest.TrackingLocationTypes.Contains(tlt)) Then
                tmpTest.TrackingLocationTypes.Add(tlt)
            End If
        Next

        If rbnParametric.Checked Then
            tmpTest.TestType = TestType.Parametric
        Else If rbnIncoming.Checked Then
            tmpTest.TestType = TestType.IncomingEvaluation
        ElseIf rbnEnvironmentalStress.Checked Then
            tmpTest.TestType = TestType.EnvironmentalStress
        ElseIf rbnNonTestingTask.Checked Then
            tmpTest.TestType = TestType.NonTestingTask
        End If

        tmpTest.ResultIsTimeBased = chkResultIsTimeBased.Checked
        tmpTest.TotalHours = txtHours.Text
        tmpTest.LastUser = Helpers.GetCurrentUserLDAPName
        tmpTest.IsArchived = chkArchived.Checked
    End Sub

    Protected Sub SaveTest()
        Dim tmpTest As Test
        notMain.Clear()

        If CInt(hdnEditID.Value) > 0 Then
            tmpTest = TestManager.GetTest(CInt(hdnEditID.Value))
        Else
            tmpTest = New Test
        End If

        SetTestParametersforSave(tmpTest)
        tmpTest.ID = TestManager.SaveTest(tmpTest)
        notMain.Notifications = tmpTest.Notifications

    End Sub
    Protected Sub btnSave_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnSave.Click
        SaveTest()
        Response.Redirect("~/admin/tests.aspx")
    End Sub

    Protected Sub btnCancel_Click(ByVal sender As Object, ByVal e As System.EventArgs) Handles btnCancel.Click
        Response.Redirect("~/admin/tests.aspx")
    End Sub
End Class