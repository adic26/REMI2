$(function () { //ready function

    $(FinalItemsList).hide();

    //var rtID = $('#<%=ddlRequestType.ClientID%>');
    var rtID = $("[id$='ddlRequestType']");
    var request = searchAll(rtID[0].value, "");

    var jobs = $(bs_StagesField);
    var req = $(bs_ddlSearchField);
    var tests = $(bs_TestField);

    $('#bs_list').hide()

    $('#bs_OKayButton').on('click', function () {
        //$('.selectpicker').selectpicker('hide');
        var myList = $(FinalItemsList);
        
        $.each(jobs.val(), function (index, element) {
            $('.list-group').append($('<li class="list-group-item">' + element + '</li>'))
        });

        myList.show();
        
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

});
