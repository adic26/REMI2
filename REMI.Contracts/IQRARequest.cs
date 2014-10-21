using System;
using System.Collections.Generic;

namespace REMI.Contracts
{
    public interface IQRARequest 
    {
        string RequestNumber { get; set; }
        Dictionary<string, string> RequestProperties { get; set; }
        Dictionary<string, string> FieldMapping { get; set; }
        string RequestType { get; }
        string Requestor { get; }
        string Summary { get; }
        bool Validate();
        string RequestStatus { get; }
        string ReportType { get; }
        string ExecutiveSummary { get; }
        bool IncludeInTempo { get; }
        int RQID { get; }
        bool IsReportRequired { get; }
        string PercentComplete { get; }
        string TRSLink { get; }
        string AssemblyNumber { get; }
        string AssemblyRevision { get; }
        string CPRNumber { get; }
        DateTime DateReportApproved { get; }
        bool HasSpecialInstructions { get; }
        string HWRevision { get; }
        int JobId { get; }
        string PartName { get; }
        String Priority { get; }
        string ProductGroup { get; }
        string ProductType { get; }
        string AccessoryGroup { get; }
        DateTime ReportRequiredBy { get; }
        bool RequestorRequiresUnitsReturned { get; }
        String RequestPurpose { get; }
        int SampleSize { get; }
        string GetSpecialInstructions();
        string TestCenterLocation { get; }
        string RequestedTest { get; }
        DateTime SampleAvailableDate { get; }
        DateTime ActualStartDate { get; }
        DateTime ActualEndDate { get; }
        bool MQual { get; }
        DateTime DateCreated { get; }
        string ReasonForRequest { get; }
        string MechanicalToolsRevisionMajor { get; }
        string MechanicalToolsRevisionMinor { get; }
        string BoardRevision { get; }
        string BoardRevisionMinor { get; }
        string POPNumber { get; }
        string MechanicalTools { get; }
        string IssueCategory { get; }
        string Severity { get; }
        string IssueEnvironment { get; }
        string FailureSymptoms { get; }
        string IssueDetails { get; }
        string EquipmentAffected { get; }
        string Description { get; }
        Boolean FACompleteInTRS { get; }
        string ActionTaken { get; }
        string QRANumberRelatedTo { get; }
        string TestType { get; }
        string TestStage { get; }
        string FailureDescription { get; }
        string TestObservations { get; }
        string TriageGroup { get; }
        string TriageScore { get; }
        string RootCause { get; }
        string TopLevel { get; }
        string SecondLevel { get; }
        string ThirdLevel { get; }
        string QRAPriority { get; }
        string Department { get; }
        List<int> AffectsUnits { get; set; }
    }
}