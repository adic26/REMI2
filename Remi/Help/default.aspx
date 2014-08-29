<%@ Page Title="" Language="VB" MasterPageFile="~/MasterPages/MasterPage.master" MaintainScrollPositionOnPostback="true" AutoEventWireup="false" Inherits="Remi.Help_Default"  Codebehind="default.aspx.cs" %>
<%@ Register assembly="AjaxControlToolkit" namespace="AjaxControlToolkit" tagprefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="Server"></asp:Content>
<asp:Content ID="cntTitle" ContentPlaceHolderID="pageTitleContent" runat="server"></asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="Content" runat="Server">
<h1>Help</h1>
<br />
<h2>Work Instructions</h2>
<asp:HyperLink runat="server" ID="hplAdmin" CssClass="hidden" NavigateUrl="https://hwqaweb.rim.net/pls/trs/data_entry.main?rqId=1374411" Target="_blank">Administration</asp:HyperLink><br />
<asp:HyperLink runat="server" ID="hplRoles" CssClass="hidden" NavigateUrl="https://hwqaweb.rim.net/pls/trs/data_entry.main?rqId=1339268" Target="_blank">Roles And Permissions</asp:HyperLink><br />
<asp:HyperLink runat="server" ID="hplScan" NavigateUrl="https://hwqaweb.rim.net/pls/trs/data_entry.main?rqId=726798" Target="_blank">Device Scanning</asp:HyperLink><br />
<asp:HyperLink runat="server" ID="hplControl" NavigateUrl="https://hwqaweb.rim.net/pls/trs/data_entry.main?rqId=676439" Target="_blank">Remi Control</asp:HyperLink><br />
<asp:HyperLink runat="server" ID="hplRemi" NavigateUrl="https://hwqaweb.rim.net/pls/trs/data_entry.main?rqId=1492237" Target="_blank">Remi</asp:HyperLink><br />

<h2>Batch</h2>
<p>
    When you see "1 Exc" on the batch view testing summary. This means that there is 1 unit that has been DNP'd. See figure 1.<br />
    The checkboxs in Testing Summary are for DNPing all units for that stage and test.
</p>
<h3>Figure 1</h3>
<img alt="Figure 1" src="../Images/Help/UnitsExempt.jpg" />

<p>
    If you see "TestingSuspended" in the stressing summary area. This means the unit has been scanned into that location more than once so the test record thinks an error has occured or you have removed the units prematurely. Reset the test record to In Progress. See figure 2.<br />
    If you see "0.0/240.0h" but the test is complete. It is because the user did not scan the units out of REMI. But the test record was created manually. You will know this by going to "Test Records" and looking at "# Of Scans". If it's 0 then this is what happened.
</p>
<h3>Figure 2</h3>
<img alt="Figure 2" src="../Images/Help/StressingTestingSuspended.jpg" />

<br />
<h2>Batch Status</h2>
Every 30 minutes REMI has a service that runs in the background that pushs the batch forward. See below for the status change criteria.<br />
<ul>
    <li>Not Set</li>
    <li>Held</li>
    <li>InProgress</li>
    <li>Quarantined</li>
    <li>Received</li>
    <li>NotSavedToRemi</li>
    <li>Rejected</li>
    <li>Testing Complete</li>
    <li>Complete</li>
</ul>
<u>Status Change Criteria:</u><br />
<ul>
    <li>If the TRS is set to “Complete” then in REMI the batch is set to “Complete”</li>
    <li>If the batch in REMI is not set to “In Progress” and the batch in REMI is set to “Received” and the batch in TRS is set to “Assigned” then REMI status is changed to “In Progress”.</li>
    <li>If the batch in REMI is not set to “Rejected” and the TRS is set to “Rejected” then set REMI to “Rejected”.</li>
    <li>If the REMI batch status is "Rejected" or "Complete" then REMI does not let the batch be updated as testing should already be completed.</li>
    <li>If the batch does not have a “Test Stage” assigned (which occurs at the beginning) then REMITimedService automatically assigns the Test Stage”.</li>
    <li>If the batch has a “Test Stage” assigned but the TestStageType is “Incoming Evalution” and the batch is set to “In Progress” then REMITimedService wll automatically assign the next test stage in order that isn’t of type “Incoming Evaluation”.</li>
    <li>If a REMI batch status is set to “Complete” or “TestingComplete” then percentage job completed is set to 100 %.</li>
    <li>To advance to the next “Test Stage” REMI has to validate all units for every test in the current “Test Stage”. Taking into account units that are DNP and not “In Progress”.
        <ul>
            <li>We get the max process order for that batch.</li>
            <li>We then test if the all units are process complete and we have other test stages to do. Then it sets the batch for “ReadyForNextStage”. (Process Complete: Check the T### if "ContinueOnFailures" is set to true and if so FA's are not required and the batch will move on. If all units in FA then don’t move the batch forward as it needs to be reviewed and manually moved forward as long as FA 100% rule is on. If there are any untested units for any test in that Test Stage then don’t move the Test Stage forward.)</li>
            <li>If the Test Stage is completely done meaning all Tests have been completed. Taking into account DNP’s then set the batch to “Testing Complete”.</li>
            <li>If the batches test stage completion status does not equal in progress then set the test stage completion status to In Progress.</li>
        </ul>
    </li>
    <li>If the batches Test Stage Completion status is set to “Ready For Next Stage then REMI gets the next test stage and assigns it to that batch.</li>
    <li>If the batches test stage completion status is set to TestingComplete and the TRS is not complete then set the batch to TestingComplete.</li>
    <li>There is a new test stage type called "Failure Analysis". This is used if the batch has any FARaised test records. It will move to this stage on it's own but will require you to create test records for only those units that have a FA Raised.</li>
    <li>There is a new test stage type called "incoming" and when the batch is processed in it will automatically move to this test stage and as labels are printed using "Incoming Label Printer" test records are created in REMI and the batch will move forward on it's own.</li>
    <li>At the end of the test stage progression TRS is updated with percentage complete. Which is determined by dividing the number of completed test stage with the total test stage.</li>
    <li>When a batch has all units in FA at a stage then the batch ceases to move forward and must be manually moved forward. Doesn’t matter how many tests are in FA. It just matters that each unit has at least 1 FA Raised.</li>
</ul>
<u>Test Records</u><br />
<ul>
    <li>When you modify the test record manually when it is an automated system the test record will no longer move forward until a re-test is done.</li>
</ul>
<u>TRS Closed Status'</u><br />
If one of the below status' is set in TRS then REMI batch status is set to "Complete"<br />
<ul>
    <li>Completed</li>
    <li>Cancelled</li>
    <li>Closed - Pass</li>
    <li>Closed - Fail</li>
    <li>Closed - No Result</li>
</ul>
<u>Missing Batch In REMI:</u> If the batch isn't in REMI yet and you go to Batch Info and type in the QRA #. If it exists in TRS then the batch will be added to REMI as "Received" status.<br />
<u>RQ Results:</u><br />
<ul>
    <li>If the REMI batch status is set to "In Progress" or "Received" then REMITimedService will update the batch as long as the test stage and job is set.</li>
</ul>
<u>Incoming:</u><br />
<ul>
    <li>If you go to “Update Batch” page and enter a Request and click submit and REMI batch status is “Received” and the TRS status is “Assigned” then the batch is set in REMI as “In Progress”.</li>
    <li>REMI now pulls in all batches that are set to received in TRS into REMI.</li>
</ul>
<br />

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="rightSidebarContent" runat="Server"></asp:Content>