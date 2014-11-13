using System;
using System.Collections.Generic;

namespace REMI.Contracts
{
    public interface IBatch : ILoggedItem, ICommentedItem, REMI.Validation.IValidatable
    {
        double EstTSCompletionTime { get; set; }
        double EstJobCompletionTime { get; set; }
        string RequestNumber { get; set; }
        string ProductGroup { get; set; }
        string ProductType { get; set; }
        int ProductTypeID { get; set; }
        string AccessoryGroup { get; set; }
        int AccessoryGroupID { get; set; }
        string TestCenterLocation { get; set; }
        string JobName { get; set; }
        string RequestPurpose { get; set; }
        int RequestPurposeID { get; set; }
        int ProductID { get; set; }
        string CPRNumber { get; set; }
        int TestStageID { get; set; }
        int NumberofUnits { get; set; }
        int NumberOfUnitsExpected { get; set; }
        string TestStageName { get; set; }
        String Priority { get; set; }
        int PriorityID { get; set; }
        System.DateTime ReportRequiredBy { get; set; }
        System.DateTime ReportApprovedDate { get; set; }
        BatchStatus Status { get; set; }
        TestStageCompletionStatus TestStageCompletion { get; set; }
        string ActiveTaskAssignee { get; set; }
        string ExecutiveSummary { get; set; }
        string HasUnitsRequiredToBeReturnedToRequestorString { get; }
        Boolean RequestorRequiresUnitsReturned { get; }
        bool HasUnitsRequiredToBeReturnedToRequestor { get; }
        bool HasUnitsNotReturnedToRequestor { get; set; }
        String Requestor { get; set; }
        bool IsCompleteInRequest { get; }
        System.DateTime DateCreated { get; set; }
        string JobWILocation { get; set; }
        int TestCenterLocationID { get; set; }
        bool ContinueOnFailures { get; set; }
        string RequestLink { get; set; }
        string RelabResultLink { get; }
        string BatchInfoLink { get; }
        string ProductGroupLink { get; }
        string JobLink { get; }
        int JobID { get; set; }
        int OrientationID { get; set; }
        string MechanicalTools { get; set; }
        string Department { get; set; }
        int DepartmentID { get; set; }
        string GetTestOverviewCellString(string jobName, string testStageName, string TestName, bool hasEditAuthority, bool isTestCenterAdmin, System.Data.DataTable rqResults, bool hasBatchSetupAuthority, bool showHyperlinks);
        bool hasBatchSpecificExceptions { get; set; }
        IOrientation Orientation { get; set; }
        string OrientationXML { get; set; }

        Dictionary<string, double> TestStageTimeLeftGrid { get; set; }
        Dictionary<string, int> TestStageIDTimeLeftGrid { get; set; }
    }
}