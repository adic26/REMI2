using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NUnit.Framework;
namespace REMI.Dal.Tests
{
    //[TestFixture]
    //public class BatchViewTest
    //{
      
    //    [Test]
    //    public void GetABatch() {
    //        REMI.BaseObjectModels.BatchView knownBatch = GetFakeBatch();

    //        REMI.BaseObjectModels.BatchView b = REMI.Dal.BatchDB.GetViewBatch(knownBatch.QRANumber);
    //        Assert.True(b.Equals(knownBatch));
    //        REMI.BaseObjectModels.BatchView anotherBatch = REMI.Dal.BatchDB.GetViewBatch("QRA-10-0100");
    //        Assert.False(b.Equals(anotherBatch));
    //    }
    //    public REMI.BaseObjectModels.BatchView GetFakeBatch(){
    //        REMI.BaseObjectModels.BatchView b = new REMI.BaseObjectModels.BatchView();
    //        b.QRANumber = "QRA-10-0010";
    //        b.ProductGroup = "Atlas";
    //        b.TestCenter = "Cambridge";
    //        b.Priority = REMI.Contracts.Priority.NotSet;
    //        b.RequestPurpose = REMI.Contracts.RequestPurpose.NPQ;
    //        b.Status = REMI.Contracts.BatchStatus.Complete;
    //        b.TestStageCompletionStatus = REMI.Contracts.TestStageCompletionStatus.NotSet;

    //        //create tasks for this batch
    //        REMI.BaseObjectModels.BatchTaskView job = new REMI.BaseObjectModels.BatchTaskView("Spill");
    //        //sample eval TS
    //        REMI.BaseObjectModels.BatchTaskView tsSampleEval = new REMI.BaseObjectModels.BatchTaskView("Sample Evaluation");
    //        tsSampleEval.ProcessOrder = 0;
    //        REMI.BaseObjectModels.BatchTaskView tSampleEval = new REMI.BaseObjectModels.BatchTaskView("Sample Evaluation");
    //        tSampleEval.AddApplicableUnits("1, 2, 3, 4, 5, 6");
    //        tSampleEval.DurationInHours = 0.03;

    //        tsSampleEval.AddTask(tSampleEval);
    //        job.AddTask(tsSampleEval);
    //       //Baseline TS
    //        REMI.BaseObjectModels.BatchTaskView tsBaseline = new REMI.BaseObjectModels.BatchTaskView("Baseline");
    //        tsBaseline.ProcessOrder = 1;
    //        REMI.BaseObjectModels.BatchTaskView tFunc = new REMI.BaseObjectModels.BatchTaskView("Functional Test");
    //        tFunc.DurationInHours = 0.02;
    //        tFunc.AddApplicableUnits("1, 2, 3, 4, 5, 6");
    //        REMI.BaseObjectModels.BatchTaskView tCharge = new REMI.BaseObjectModels.BatchTaskView("Charging Test");
    //        tCharge.DurationInHours = 0.25;
    //        tCharge.AddApplicableUnits("1, 2, 3, 4, 5, 6");
    //        REMI.BaseObjectModels.BatchTaskView tGprs1800 = new REMI.BaseObjectModels.BatchTaskView("GPRS Radiated 900 1800");
    //        tGprs1800.DurationInHours = 1;
    //        tGprs1800.AddApplicableUnits("1, 2, 3, 4, 5, 6");
    //        REMI.BaseObjectModels.BatchTaskView tGPRS1800open = new REMI.BaseObjectModels.BatchTaskView("GPRS Radiated 900 1800 Open");
    //        tGPRS1800open.DurationInHours = 1;
    //        tGPRS1800open.AddApplicableUnits("1, 2, 3, 4, 5, 6,");
    //        REMI.BaseObjectModels.BatchTaskView tGSM1800= new REMI.BaseObjectModels.BatchTaskView("GSM Radiated 900 1800");
    //        tGSM1800.DurationInHours = 1;
    //        tGSM1800.AddApplicableUnits("1, 2, 3, 4, 5, 6");
    //        REMI.BaseObjectModels.BatchTaskView tOpsFunc = new REMI.BaseObjectModels.BatchTaskView("Ops Functional");
    //        tOpsFunc.DurationInHours = 0.25;
    //        tOpsFunc.AddApplicableUnits("1, 2, 3, 4, 5, 6,");
    //        REMI.BaseObjectModels.BatchTaskView tAcoustic = new REMI.BaseObjectModels.BatchTaskView("Acoustic Test");
    //        tAcoustic.DurationInHours = 0.25;
    //        tAcoustic.AddApplicableUnits("1, 2, 3, 4, 5, 6,");
    //        REMI.BaseObjectModels.BatchTaskView tBluetooth = new REMI.BaseObjectModels.BatchTaskView("Bluetooth Test");
    //        tBluetooth.DurationInHours = 0.25;
    //        tBluetooth.AddApplicableUnits("1, 2, 3, 4, 5, 6,");
    //        REMI.BaseObjectModels.BatchTaskView tCamera = new REMI.BaseObjectModels.BatchTaskView("Camera Test");
    //        tCamera.DurationInHours = 0.25;
    //        tCamera.AddApplicableUnits("1, 2, 3, 4, 5, 6,");
    //        tsBaseline.AddTask(tFunc);
    //        tsBaseline.AddTask(tCharge);
    //        tsBaseline.AddTask(tGprs1800);
    //        tsBaseline.AddTask(tGPRS1800open);
    //        tsBaseline.AddTask(tGSM1800);
    //        tsBaseline.AddTask(tOpsFunc);
    //        tsBaseline.AddTask(tAcoustic);
    //        tsBaseline.AddTask(tBluetooth);
    //        tsBaseline.AddTask(tCamera);
    //        job.AddTask(tsBaseline);
    //        //spill
    //        REMI.BaseObjectModels.BatchTaskView tsSpillTest = new REMI.BaseObjectModels.BatchTaskView("Spill Test");
    //        tsSampleEval.ProcessOrder = 2;
    //        REMI.BaseObjectModels.BatchTaskView tSpillTest = new REMI.BaseObjectModels.BatchTaskView("Spill Test");
    //        tSpillTest.DurationInHours = 2;
    //        tSpillTest.AddApplicableUnits("1, 2, 3, 4, 5, 6");
    //        tsSpillTest.AddTask(tSpillTest);
    //        job.AddTask(tsSpillTest);
    //        //stb
    //        REMI.BaseObjectModels.BatchTaskView tsStabilization = new REMI.BaseObjectModels.BatchTaskView("Stabilization");
    //        tsStabilization.ProcessOrder = 3;
    //        REMI.BaseObjectModels.BatchTaskView tStabilization = new REMI.BaseObjectModels.BatchTaskView("Spill Test");
    //        tStabilization.DurationInHours = 24;
    //        tStabilization.AddApplicableUnits("1, 2, 3, 4, 5, 6");
    //        tsStabilization.AddTask(tStabilization);
    //        job.AddTask(tsStabilization);
    //        //post teststage
    //        REMI.BaseObjectModels.BatchTaskView tsPost = new REMI.BaseObjectModels.BatchTaskView("Post");
    //        tsPost.ProcessOrder = 4;
    //        tsPost.AddTask(tAcoustic);
    //        tsPost.AddTask(tGPRS1800open);
    //        tsPost.AddTask(tFunc);
    //        tsPost.AddTask(tGprs1800);
    //        tsPost.AddTask(tCharge);
    //        tsPost.AddTask(tBluetooth);
    //        tsPost.AddTask(tCamera);
    //        tsPost.AddTask(tGSM1800);
    //        tsPost.AddTask(tOpsFunc);
    //        job.AddTask(tsPost);
    //        //mil teststage
    //        REMI.BaseObjectModels.BatchTaskView tsMIL = new REMI.BaseObjectModels.BatchTaskView("TDA / MIL Request");
    //        tsMIL.ProcessOrder = 5;
    //        tsMIL.AddTask(tGprs1800);
    //        tsMIL.AddTask(tFunc);
    //        job.AddTask(tsMIL);
    //        b.Task = job;
    //        //now add the test units
    //        for (int i = 1; i <= 6; i++)
    //        {
    //            REMI.BaseObjectModels.TestUnitView tu1 = new REMI.BaseObjectModels.TestUnitView();
    //            tu1.AssignedTo = "kram";
    //            tu1.BatchUnitNumber = i;
    //            tu1.CurrentLocation = "REMSTAR";
    //            tu1.TestStage = "Sample Evaluation";
    //            b.AddTestUnit(tu1);
    //        }
    //        return b;
    //    }
    //}
}
