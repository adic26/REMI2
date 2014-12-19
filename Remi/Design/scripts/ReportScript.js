$(function () { //ready function

    $('.selectpicker').selectpicker({
        //style: 'btn-info',
        size: 4
    });

    $(FinalItemsList).hide();
    $(bs_searchButton).hide();
    $(bs_RealStages).selectpicker('hide');

    //var rtID = $('#<%=ddlRequestType.ClientID%>');
    var rtID = $("[id$='ddlRequestType']");
    var request = searchAll(rtID[0].value, "");

    var jobs = $(bs_StagesField);
    var req = $(bs_ddlSearchField);
    var tests = $(bs_TestField);
    var stages = $(bs_RealStages);

    $('#bs_list').hide()
    $('#bs_OKayButton').on('click', function () {
        //$('.selectpicker').selectpicker('hide');
        var myList = $(FinalItemsList);
        var fullList = [];

        if (jobs.val() != null)
            fullList = jobs.val();
        if (req.val()!= null) {
            fullList = $.merge(fullList, req.val());
        }
        if (tests.val()!=null) {
            fullList = $.merge(fullList, tests.val());
        }
        
        $.each(fullList, function (index, element) {
            $('.list-group').append($('<li class="list-group-item">' +
                element +
                '<input type="text" class="form-inline" style="float: right;" placeholder="Input Search Criteria"></li>'))
        });

        //$('.form-inline').effects({ float: 'right' });
        myList.show();
        $(bs_searchButton).show();
        
    });

    var selectpicker = $('#bs_StagesField').data('selectpicker').$newElement;

    selectpicker.data('open', false);

    selectpicker.click(function () {
        if (selectpicker.data('open')) {
            selectpicker.data('open', false);
            console.log("close!");
            //Insert all your stages at this point
            if (jobs.val() != null) {
                addStagesViaJobs(jobs.val(), stages);
            }

        } else {
            console.log("open");
            selectpicker.data('open', true);

        }
        
    });

function search(rtID, type, model) {

    var requestParams = JSON.stringify({
        "requestTypeID": rtID,
        "type": type
    });

    var myRequest = jsonRequest("Reports.aspx/Search", requestParams).success(function (data) {
        if (data.Success == true) {
            var results = data.Results;
            var rslt = $(results);

            model.empty();

            cb = '<optgroup label=\"' + type + '">';
            $.each(rslt, function (index, element) {
                cb += "<option>" + element.Name + "</option>";
            });
            cb += '</optgroup>'

            model.append(cb);
            $('.selectpicker').selectpicker('refresh');


        }
        else if (data == true) {
            console.log(data);
        }
        else if (data.Success == false) {
            return data.Results;
        }
    });

    myRequest.fail(function (responser) {
        console.log(responser.responseText)
    });

    return myRequest;

}

function searchAll(rtID, type) {

    var requestParams = JSON.stringify({
        "requestTypeID": rtID,
        "type": type
    });

    var myRequest = jsonRequest("Reports.aspx/Search", requestParams).success(function (data) {
        if (data.Success == true) {

            //Request Information here
            populateFields(data.Results, $(bs_ddlSearchField), "Request");

            //Stages Information Here
            //populateStage(rtID, $(bs_StagesField));
            
            //Test Information here
            populateFields(data.Results, $(bs_TestField), "Test");

            //job Search
            jobSearch($(bs_StagesField));


        }
        else if (data == true) {
            console.log(data);
        }
        else if (data.Success == false) {
            return data.Results;
        }
    });
    
}

function jobSearch(model) {

    //setting up parameters from web service
    var requestParams = {};

    var myRequest = jsonRequest("../webservice/RemiAPI.asmx/GetJobs", requestParams).success(function (data) {
        var results = data;
        var rslt = $(results);

        model.empty();
        cb = '';
        $.each(rslt, function (index, element) {
            cb += "<option>" + element + "</option>";
        });

        model.append(cb);
        $('.selectpicker').selectpicker('refresh');


    });

}

function populateFields(data, model, type) {
    var rslt = $(data);

    model.empty();

    cb = '<optgroup label=\"' + type + '">';
    $.each(rslt, function (index, element) {
        if (element.Type == type) {
            cb += "<option>" + element.Name + "</option>";
        }
    });
    cb += '</optgroup>';

    model.append(cb);
    $('.selectpicker').selectpicker('refresh');

}

function populateStage(rtID, model) {


    var requestParams = JSON.stringify({
        "requestTypeID": rtID
    });

    var myRequest = jsonRequest("Reports.aspx/GetAllStages", requestParams).success(function (data) {
        model.empty();
        model.append('<optgroup label="Stages">');
        model.append(data);
        model.append('</optgroup>');
        $('.selectpicker').selectpicker('refresh');
    });


}

function refreshAllSelectPickers() {
    $('.selectpicker').selectpicker('refresh');
}

function addStagesViaJobs(data,model) {

    model.empty();
    //where data is all the values from the Job
    $.each(data, function (index, element) {
        //call web service function
        stagesWebService(element,model);
    });
    refreshAllSelectPickers();
    $(bs_RealStages).selectpicker('show');
}

function stagesWebService(jobName,model) {
    
    var requestParams = JSON.stringify({
        "jobName": jobName
    });

    var myRequest = jsonRequest("../webservice/RemiAPI.asmx/GetJobStages", requestParams).success(function (data) {
        var results = data;
        var rslt = $(results);
        var cb = '';

        cb = '<optgroup label=\"' + jobName + '">';
        $.each(rslt, function (index, element) {
            cb += "<option>" + element.Name + "</option>";
        });
        cb += '</optgroup>';

        model.append(cb);
        $('.selectpicker').selectpicker('refresh');


    });
}

});
