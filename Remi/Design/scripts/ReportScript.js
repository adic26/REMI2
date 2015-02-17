$(function () { //ready function
    $('.selectpicker').selectpicker({
        //style: 'btn-info',
        size: 4
    });

    //IE Tags
    if (typeof (UserAgentInfo) != 'undefined' && !window.addEventListener) {
        UserAgentInfo.strBrowser = 1;
    }

    var count = 0;

    $('#FinalItemsList').hide();
    $('#bs_searchButton').hide();
    $('#bs_export').hide();
    $('#bs_RealStages').next().hide();

    var rtID = $("[id$='hdnRequestType']");
    var request = searchAll(rtID[0].value, "");
    var req = $('#bs_ddlSearchField');
    var additional = $('#bs_Additional');
    var tests = $('#bs_TestField');
    var stages = $('#bs_RealStages');
    var oTable;
    var executeTop = $("[id$='hdnTop']");
    var user = $("[id$='hdnUser']");
    var userID = $("[id$='hdnUserID']");

    var o = new Option("--aReqNum", "--aReqNum");
    $(o).html("Request Number");
    $('#bs_Additional').append(o);
        
    var o = new Option("--aMeasurement", "--aMeasurement");
    $(o).html("Measurement Name");
    $('#bs_Additional').append(o);
    
    var o = new Option("--aBSN", "--aBSN");
    $(o).html("BSN");
    $('#bs_Additional').append(o);
    
    var o = new Option("--aIMEI", "--aIMEI");
    $(o).html("IMEI");
    $('#bs_Additional').append(o);
    
    var o = new Option("--aUnit", "--aUnit");
    $(o).html("Unit");
    $('#bs_Additional').append(o);
    
    var o = new Option("--aResultArchived", "--aResultArchived");
    $(o).html("Include Results Archived");
    $('#bs_Additional').append(o);
    
    var o = new Option("--aResultInfoArchived", "--aResultInfoArchived");
    $(o).html("Include Info Archived");
    $('#bs_Additional').append(o);
    
    var o = new Option("--aInfo", "--aInfo");
    $(o).html("Information");
    $('#bs_Additional').append(o);
    
    var o = new Option("--aTestRunDate", "--aTestRunDate");
    $(o).html("Test Run Date");
    $('#bs_Additional').append(o);
    
    var o = new Option("--aParam", "--aParam");
    $(o).html("Parameter");
    $('#bs_Additional').append(o);

    $.fn.dataTable.TableTools.defaults.aButtons = ["copy", "csv", "xls"];
        
    function ProcessQuery(d) {
        var emptySearch = "<thead><tr></tr></thead><tbody></tbody>";
        if (d != emptySearch) {

            //Meaningful data is present
            if (navigator.appName != 'Microsoft Internet Explorer') {
                $('#searchResults').empty();
                $('#searchResults').append(d);

                oTable = $('#searchResults').DataTable({
                    destroy: true,
                    "scrollX": true,
                    dom: 'T<"clear">lfrtip',
                    TableTools: {
                        "sSwfPath": "../Design/scripts/swf/copy_csv_xls.swf"
                    },
                    "aaSorting": [[0, 'desc']]
                });

                
            } else {
                //Enter IE
                //oTable is not defined
                if (oTable == null) {
                    $('#searchResults').empty();
                    $('#searchResults').append(d);

                    oTable = $('#searchResults').DataTable({
                        destroy: true,
                        "scrollX": true,
                        dom: 'T<"clear">lfrtip',
                        TableTools: {
                            "sSwfPath": "../Design/scripts/swf/copy_csv_xls.swf"
                        },
                        "aaSorting": [[0, 'desc']]
                    });
                } else {
                    //OTable is defined already

                    //(i) Destroy dataTable
                    oTable.destroy();

                    //(ii)append the data
                    $('#searchResults').empty();
                    $('#searchResults').append(d);

                    //(iii) Re-Draw the table
                    oTable = $('#searchResults').DataTable({
                        destroy: true,
                        "scrollX": true,
                        dom: 'T<"clear">lfrtip',
                        TableTools: {
                            "sSwfPath": "../Design/scripts/swf/copy_csv_xls.swf"
                        },
                        "aaSorting": [[0, 'desc']]
                    });
                }
            }
        } else { //meaningful data is NOT present!
            if (navigator.appName != 'Microsoft Internet Explorer' && oTable != null) {


                oTable = $('#searchResults').DataTable({
                    destroy: true,
                    "scrollX": true,
                    dom: 'T<"clear">lfrtip',
                    TableTools: {
                        "sSwfPath": "../Design/scripts/swf/copy_csv_xls.swf"
                    },
                    "aaSorting": [[0, 'desc']]
                });

                oTable.clear();
                oTable.draw();
            } else if (oTable != null) {
                oTable.clear();
                oTable.draw();
            }

            alert("Returned an empty search");
        }

        $('#searchResults').find('th.sorting').css('background-color', 'black');
        $('#searchResults').find('th.sorting_asc').css('background-color', 'black');
    }

    if (executeTop.val() == "True") {
        $('div.table').block({
            message: '<h1>Processing</h1>',
            css: { border: '3px solid #a00' }
        });

        var requestParams = JSON.stringify({
            "requestTypeID": rtID[0].value,
            "fields": [],
            "userID": userID[0].value
        });

        var myTable = jsonRequest("../webservice/REMIInternal.asmx/customSearch", requestParams).success(
            function (d) {
                ProcessQuery(d);
                $('div.table').unblock();
            });
    }

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

        if (additional.val() != null) {
            fullList = $.merge(fullList, additional.val());
        }

        if (req.val()!= null) {
            fullList = $.merge(fullList, req.val());
        }
        
        $.each(fullList, function (index, element) {
            var isAdditional = false;
            if (element.indexOf("--a") > -1) {
                element = element.replace("--a", "");
                isAdditional = true;
            }

            var builtHTML;
            builtHTML = '<span class="list-group-item">' + element;

            if (element == "TestRunDate") {
                builtHTML += '<script>$(function () { $("#startDate").datepicker({}); $("#endDate").datepicker({}); });</script>';
                builtHTML += '<input type="text" id="startDate" name="startDate"addition="' + isAdditional + '" data-datepick="rangeSelect: true" class="form-inline" style="float: right;" placeholder="Input Search Criteria"><input type="text" id="endDate" name="endDate"addition="' + isAdditional + '" class="form-inline" style="float: right;" placeholder="Input Search Criteria">';
            }
            else if (element == "ResultArchived") {
                builtHTML += '<select id="resultArchived' + count + '" name="resultArchived' + count + '" class="" addition="' + isAdditional + '" class="form-inline" style="float: right;" placeholder="Input Search Criteria"><option value="">N/A</option><option value="Yes">Yes</option><option value="No">No</option></select>';
            }
            else if (element == "ResultInfoArchived") {
                builtHTML += '<select id="resultInfoArchived' + count + '" name="resultInfoArchived' + count + '" class="" addition="' + isAdditional + '" class="form-inline" style="float: right;" placeholder="Input Search Criteria"><option value="">N/A</option><option value="Yes">Yes</option><option value="No">No</option></select>';
            }
            else {
                if (element == "Param" || element == "Info") {
                    builtHTML += '<input type="text" id="' + element + count + '" name="' + element + '" addition="' + isAdditional + '" class="form-inline" style="float: right;" placeholder="Input Search Criteria">';
                }
                builtHTML += '<input type="text" id="' + element + count + '" name="' + element + '" addition="' + isAdditional + '" class="form-inline" style="float: right;" placeholder="Input Search Criteria">';
            }
            builtHTML += '</span>';
            $('.list-group').append(builtHTML);
            count = count + 1;
        });

        myList.show();
        $('#bs_searchButton').show(); 
    });
    
    $('#bs_searchButton').on('click', function () {
        $('div.table').block({
            message: '<h1>Processing</h1>',
            css: { border: '3px solid #a00' }
        });

        var fullList = [];
        var selectedRequests = req.next().find('li.selected').find('a.opt ');
        var searchTermRequests = $('#FinalItemsList span');
        var selectedTests = tests.next().find('li.selected').find('a.opt ');
        var selectedStages = stages.next().find('li.selected').find('a.opt ');
        var selectedAdditional = additional.next().find('li.selected');
        var myTable = $('#searchResults');
        
        if (oTable != null && navigator.appName != 'Microsoft Internet Explorer') {
            oTable.destroy();
        }

        $.each(selectedRequests, function (index, element) {
            var requestName = element.text;
            var originalIndex = element.parentNode.getAttribute('data-original-index');
            var testID = $('#bs_ddlSearchField optgroup > option')[originalIndex].getAttribute('testid');
            $.each(searchTermRequests, function (s_index, s_element) {
                //console.log($(this).text());
                if (s_element.children[0].value != '') {
                    var searchTerm = s_element.innerText
                    if (searchTerm == element.innerText) {
                        var request = 'Request' + ',' + testID + ',' + s_element.children[0].value;
                        //console.log(request);
                        fullList.push(request);
                    }
                }
            });
        });

        $.each(searchTermRequests, function (s_index, s_element) {
            //console.log($(this).text());

            if (s_element.children[0].value != '' && s_element.outerHTML.indexOf('addition="true"') > -1) {
                if (s_element.innerText == "Param" || s_element.innerText == "Info") {
                    var additionalVals = s_element.outerText + ':' + s_element.children[1].value + ',0,' + s_element.children[0].value;
                    //console.log(additionalVals);
                    fullList.push(additionalVals);
                }
                else if (s_element.innerText == "TestRunDate") {
                    if (s_element.children[2].value != '' && s_element.children[1].value != '') {
                        fullList.push('TestRunStartDate' + ',0,' + s_element.children[2].value);
                        fullList.push('TestRunEndDate' + ',0,' + s_element.children[1].value);
                    }
                }
                else if (s_element.innerText.indexOf('ResultArchived') > -1) {
                    if (s_element.children[0].value == "Yes") {
                        fullList.push('resultArchived,1,');
                    }
                    else {
                        fullList.push('resultArchived,0,');
                    }
                }
                else if (s_element.innerText.indexOf('ResultInfoArchived') > -1) {
                    if (s_element.children[0].value == "Yes") {
                        fullList.push('resultInfoArchived,1,');
                    }
                    else {
                        fullList.push('resultInfoArchived,0,');
                    }
                }
                else {
                    var validationPassed = true;
                    var additionalVals = s_element.outerText + ',0,' + s_element.children[0].value;

                    if ((s_element.outerText == "Unit" || s_element.outerText == "BSN") && $.isNumeric(s_element.children[0].value) == false) {
                        validationPassed = false;
                    }

                    if (validationPassed) {
                        //console.log(additionalVals);
                        fullList.push(additionalVals);
                    }
                }
            }
        });

        $.each(searchTermRequests, function (s_index, s_element) {
            if (s_element.outerText == "TestRunDate") {
                if (s_element.children[1].value == "" || s_element.children[2].value == "") {
                    s_element.outerText = '';
                }
            }
            else if (s_element.children[0].value == '') {
                s_element.outerText = '';
            }
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
                "fields": fullList,
                "userID": userID[0].value
            });

            var myTable = jsonRequest("../webservice/REMIInternal.asmx/customSearch", requestParams).success(
                function (d) {
                    ProcessQuery(d);
                    $('div.table').unblock();
                });
        } else {
            alert("Please enter a search field");
            $('div.table').unblock();
        }
    });
    
    // Old export Function
    //$('#bs_export').click(function () {
    //    if (navigator.appName == 'Microsoft Internet Explorer') {
    //        alert("Export Functionality Not Supported For IE. Use Chrome.");
    //    }
    //    else {
    //        CSVExportDataTable("", $(this).val());
    //    }
    //});
    
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

    var myRequest = jsonRequest("../webservice/REMIInternal.asmx/Search", requestParams).success(function (data) {
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

    var myRequest = jsonRequest("../webservice/REMIInternal.asmx/Search", requestParams).success(function (data) {
        if (data.Success == true) {

            //Request Information here
            populateFields(data.Results, $('#bs_ddlSearchField'), "Request");
            
            //Test Information here
            populateFields(data.Results, $('#bs_TestField'), "Test");

            //job Search
            jobSearch($('#bs_StagesField'), user[0].value);
        }
        else if (data == true) {
            //console.log(data);
        }
        else if (data.Success == false) {
            return data.Results;
        }
    });    
}

function jobSearch(model, username) {
    //setting up parameters from web service

    var requestParams = JSON.stringify({
        "userIdentification": username,
        "requestTypeID": rtID[0].value
    });

    var myRequest = jsonRequest("../webservice/REMIInternal.asmx/GetJobs", requestParams).success(function (data) {
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

    var myRequest = jsonRequest("../webservice/REMIInternal.asmx/GetAllStages", requestParams).success(function (data) {
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
