$(function () { //ready function
    $('.selectpicker').selectpicker({
        //style: 'btn-info',
        size: 4
    });

    //IE Tags
    if (typeof (UserAgentInfo) != 'undefined' && !window.addEventListener) {
        UserAgentInfo.strBrowser = 1;
    }

    $('#FinalItemsList').hide();
    $('#bs_searchButton').hide();
    $('#bs_export').hide();
    $('#bs_RealStages').next().hide();

    var rtID = $("[id$='ddlRequestType']");
    var request = searchAll(rtID[0].value, "");
    var req = $('#bs_ddlSearchField');
    var tests = $('#bs_TestField');
    var stages = $('#bs_RealStages');

    $('#bs_list').hide()
    $('#bs_OKayButton').on('click', function () {
        //$('.selectpicker').selectpicker('hide');
        var myList = $(FinalItemsList);
        var fullList = [];

        if ($('#bs_StagesField').val() != null) {
            //Finding full list with stages.val() that gives the entire array
            //finding the jobname, id and value of stage
            summary = [];
            //jobname
            getGroups = stages.next().find('li.selected').find('a.opt ');
            $.each(getGroups, function (index, element) {
                OptGroup = element.getAttribute('data-optgroup'); //gives you optiongroup number
                currentJob = stages.children()[OptGroup - 1].getAttribute("label");
                currentStages = element.text;
                summary[summary.length] = currentJob + " : " + currentStages;
            });
            
        }
        if (req.val()!= null) {
            fullList = $.merge(fullList, req.val());
        }
        //if (tests.val()!=null) {
        //    fullList = $.merge(fullList, tests.val());
        //}
        
        $.each(fullList, function (index, element) {
            $('.list-group').append($('<li class="list-group-item">' +
                element +
                '<input type="text" class="form-inline" style="float: right;" placeholder="Input Search Criteria"></li>'))
        });

        myList.show();
        $('#bs_searchButton').show();
        
    });
    $('#bs_searchButton').on('click', function () {
        //document.getElementById('LoadingGif').style.display = "block";
        //document.getElementById('LoadingModal').style.display = "block";
        $('div.table').block({
            message: '<h1>Processing</h1>',
            css: { border: '3px solid #a00' }
        });

        var fullList = [];
        var selectedRequests = req.next().find('li.selected').find('a.opt ');
        var searchTermRequests = $('#FinalItemsList li');
        var selectedTests = tests.next().find('li.selected').find('a.opt ');
        var selectedStages = stages.next().find('li.selected').find('a.opt ');
        var myTable = $('#searchResults');

        $.each(selectedRequests, function (index, element) {
            var requestName = element.text;
            var originalIndex = element.parentNode.getAttribute('data-original-index');
            var testID = $('#bs_ddlSearchField optgroup > option')[originalIndex].getAttribute('testid');
            $.each(searchTermRequests, function (s_index, s_element) {
                //console.log($(this).text());
                var searchTerm = s_element.innerText
                if (searchTerm == element.innerText) {
                    var request = 'Request' + ',' + testID + ',' + s_element.children[0].value;
                    //console.log(request);
                    fullList.push(request);
                }
            });
        });

        $.each(selectedTests, function (index, element) {
            var originalIndex = element.parentNode.getAttribute('data-original-index');
            var testID = $('#bs_TestField optgroup > option')[originalIndex].getAttribute('testid');
            var tests = 'Test' + ',' + testID + ',' + element.innerText;
            //console.log(tests);
            fullList.push(tests);
        });

        $.each(selectedStages, function (index, element) {
            OptGroup = element.getAttribute('data-optgroup'); //gives you optiongroup number
            var firstGroupLength = $('#bs_RealStages optgroup')[0].childNodes.length;
            var originalIndex = element.parentNode.getAttribute('data-original-index');
            if ((OptGroup - 1) > 0) {
                var testID = $('#bs_RealStages optgroup')[OptGroup - 1].childNodes[originalIndex - firstGroupLength].getAttribute('testid');
            } else {
                var testID = $('#bs_RealStages optgroup')[OptGroup - 1].childNodes[originalIndex].getAttribute('testid');
            }
            var stage = 'Stage' + ',' + testID + ',' + element.innerText;
            //console.log(stage);
            fullList.push(stage);
        });

        if (fullList.length > 0) {

            var requestParams = JSON.stringify({
                "requestTypeID": rtID[0].value,
                "fields": fullList
            });

            var myTable = jsonRequest("Reports.aspx/customSearch", requestParams).success(
                function (d) {
                    $('#searchResults').empty();
                    $('#searchResults').append(d);
                    var oTable = $('#searchResults').DataTable({
                        destroy: true
                    });
                    $('#searchResults').find('th.sorting').css('background-color', 'black');
                    $('#searchResults').find('th.sorting_asc').css('background-color', 'black');
                    $('#bs_export').show();
                    //unblocking UI
                    $('div.table').unblock();
                });
        } else {
            alert("Please enter a search field");
        }
    });
    $('#bs_export').click(function () {
        if (navigator.appName == 'Microsoft Internet Explorer') {
            alert("Export Functionality Not Supported For IE. Use Chrome.");
        }
        else {
            CSVExportDataTable("", $(this).val());
        }
    });
    
    var selectpicker = $('#bs_StagesField').data('selectpicker').$newElement;
    selectpicker.data('open', false);

    selectpicker.click(function () {
        selectpicker.data('open', true);
        $('.selectpicker').selectpicker('refresh');
    });

    $('#bs_StagesField').change(function () {
        if ($('#bs_StagesField').val() != null) {
            addStagesViaJobs($('#bs_StagesField').val(), $('#bs_RealStages'));
        }

        $('#bs_RealStages').next().show();
        $('.selectpicker').selectpicker('refresh');
    });
    
function CSVExportDataTable(oTable, exportMode) {
        // Init
        var csv = '';
        var headers = [];
        var rows = [];
        var dataSeparator = ',';

        oTable = $('#searchResults').dataTable();
        // Get table header names
        $(oTable).find('thead th').each(function () {
            var text = $(this).text();
            if (text != "") headers.push(text);
        });
        csv += headers.join(dataSeparator) + "\r\n";

        // Get table body data
        var totalRows = oTable.fnSettings().fnRecordsTotal();
        for (var i = 0; i < totalRows; i++) {
            var row = oTable.fnGetData(i);
            rows.push(row.join(dataSeparator));
        }

        csv += rows.join("\r\n");

        // Proceed if csv data was loaded
        if (csv.length > 0) {
            downloadFile('data.csv', 'data:text/csv;charset=UTF-8,' + encodeURIComponent(csv));
            //console.log(window.location.href);
        }
    }

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
            //console.log(data);
        }
        else if (data.Success == false) {
            return data.Results;
        }
    });

    myRequest.fail(function (responser) {
        //console.log(responser.responseText)
    });

    return myRequest;
}

function downloadFile(fileName, urlData) {
    var aLink = document.createElement('a');
    var evt = document.createEvent("HTMLEvents");
    evt.initEvent("click");
    aLink.download = fileName;
    aLink.href = urlData;
    aLink.dispatchEvent(evt);
}

function searchAll(rtID, type) {
    var requestParams = JSON.stringify({
        "requestTypeID": rtID,
        "type": type
    });

    var myRequest = jsonRequest("Reports.aspx/Search", requestParams).success(function (data) {
        if (data.Success == true) {

            //Request Information here
            populateFields(data.Results, $('#bs_ddlSearchField'), "Request");
            
            //Test Information here
            populateFields(data.Results, $('#bs_TestField'), "Test");

            //job Search
            jobSearch($('#bs_StagesField'));
        }
        else if (data == true) {
            //console.log(data);
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
            cb += '<option testID=\"' + element.TestID + '">' + element.Name + '</option>';
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

    //where data is all the values from the Job.
    //send multiple jobs inside stagesWebservice and process it
    $.each(data, function (index, element) {
        //call web service function
        stagesWebService(element,model);
    });
}

function stagesWebService(jobName,model) {    
    //Re-assess the web service , so it takes multiple job names
    var requestParams = JSON.stringify({
        "jobName": jobName
    });

    var myRequest = jsonRequest("../webservice/RemiAPI.asmx/GetJobStages", requestParams).success(function (data) {
        var results = data;
        var rslt = $(results);
        var cb = '';

        cb = '<optgroup label=\"' + jobName + '">';
        cb += '<option> </option>';
        $.each(rslt, function (index, element) {
            cb += '<option testID=\"' + element.ID + '" JobName=\"' + element.JobName + '">' + element.Name + '</option>';
        });
        cb += '</optgroup>';

        model.append(cb);
        $('.selectpicker').selectpicker('refresh');
    });
}
});
