using System;
using System.Collections.Generic;

namespace REMI.Contracts
{
    public interface IBatch : ILoggedItem, ICommentedItem, REMI.Validation.IValidatable
    {
        double EstTSCompletionTime { get; set; }
        double EstJobCompletionTime { get; set; }
        string QRANumber { get; set; }
        string ProductGroup { get; set; }
        string ProductType { get; set; }
        int ProductTypeID { get; set; }
        string AccessoryGroup { get; set; }
        int AccessoryGroupID { get; set; }
        string TestCenterLocation { get; set; }
        string JobName { get; set; }
        string RequestPurpose { get; set; }
        int RequestPurposeID { get; set; }
        string PartName { get; set; }
        int ProductID { get; set; }
        string CPRNumber { get; set; }
        int TestStageID { get; set; }
        int NumberofUnits { get; set; }
        string HWRevision { get; set; }
        string IsMQualString { get; }
        int NumberOfUnitsExpected { get; }
        string TestStageName { get; set; }
        String CompletionPriority { get; set; }
        int CompletionPriorityID { get; set; }
        System.DateTime ReportRequiredBy { get; set; }
        System.Boolean IsMQual { get; set; }
        System.DateTime ReportApprovedDate { get; set; }
        BatchStatus Status { get; set; }
        IQRARequest TRSData { get; set; }
        string AssemblyRevision { get; set; }
        string AssemblyNumber { get; set; }
        TestStageCompletionStatus TestStageCompletion { get; set; }
        string ActiveTaskAssignee { get; set; }
        string ExecutiveSummary { get; set; }
        string HasUnitsRequiredToBeReturnedToRequestorString { get; }
        bool HasUnitsRequiredToBeReturnedToRequestor { get; }
        bool HasUnitsNotReturnedToRequestor { get; set; }
        bool IsCompleteInTRS { get; }
        int RelabJobID { get; }
        System.DateTime DateCreated { get; set; }
        string JobWILocation { get; set; }
        int TestCenterLocationID { get; set; }
        string DropTestWebAppLink { get; }
        string TumbleTestWebAppLink { get; }
        bool ContinueOnFailures { get; set; }
        string TRSLink { get; }
        string RelabResultLink { get; }
        string BatchInfoLink { get; }
        string ProductGroupLink { get; }
        string JobLink { get; }
        int ReqID { get; set; }
        int JobID { get; set; }
        string MechanicalTools { get; set; }
        string GetTestOverviewCellString(string jobName, string testStageName, string TestName, bool hasEditAuthority, bool isTestCenterAdmin, System.Data.DataTable rqResults, bool hasBatchSetupAuthority, bool showHyperlinks);
        bool hasBatchSpecificExceptions { get; set; }

        Dictionary<string, double> TestStageTimeLeftGrid { get; set; }
        Dictionary<string, int> TestStageIDTimeLeftGrid { get; set; }
    }
}