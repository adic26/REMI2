
$(function () { //ready function
    $('.selectpicker').selectpicker({
        //style: 'btn-info',
        size: 4
    });

    $('#bs_StagesField').next().hide();
    $('#bs_RealStages').next().hide();
    $('#bs_TestField').next().hide();
    $('#FinalItemsList').hide();
    $('#bs_searchButton').hide();
    $('#bs_export').hide();
    var rtID = $("[id$='hdnRequestType']");
    var request = searchAll(rtID[0].value, "");
    var req = $('#bs_ddlSearchField');
    var additional = $('#bs_Additional');

    $("#bs_Additional option").each(function () {
        if ($(this).text() != "Request Number") {
            $(this).remove();
        }
    });

    $('#bs_OKayButton').on('click', function () {
        var myList = $(FinalItemsList);
        var fullList = [];

        if (req.val() != null) {
            fullList = $.merge(fullList, req.val());
        }

        if (additional.val() != null) {
            fullList = $.merge(fullList, additional.val());
        }

        $.each(fullList, function (index, element) {
            var isAdditional = false;
            if (element.indexOf("--a") > -1) {
                element = element.replace("--a", "");
                isAdditional = true;
            }

            var builtHTML;
            builtHTML = '<span class="list-group-item">' + element;
            builtHTML += '<input type="text" addition="' + isAdditional + '" class="form-inline" style="float: right;" placeholder="Input Search Criteria">';

            builtHTML += '</span>';
            $('.list-group').append(builtHTML);
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
        var myTable = $('#searchResults');
        var selectedAdditional = additional.next().find('li.selected');

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
                var additionalVals = s_element.outerText + ',0,' + s_element.children[0].value;
                //console.log(additionalVals);
                fullList.push(additionalVals);
            }
        });

        $.each(searchTermRequests, function (s_index, s_element) {
            if (s_element.children[0].value == '') {
                s_element.outerText = '';
            }
        });

        if (fullList.length > 0) {

            var requestParams = JSON.stringify({
                "requestTypeID": rtID[0].value,
                "fields": fullList
            });

            var myTable = jsonRequest("../webservice/REMIInternal.asmx/customSearch", requestParams).success(
                function (d) {
                    $('#searchResults').empty();
                    $('#searchResults').append(d);
                    var oTable = $('#searchResults').DataTable({
                        destroy: true
                    });


                    $('#searchResults').find('th.sorting').css('background-color', 'black');
                    $('#searchResults').find('th.sorting_asc').css('background-color', 'black');
                    $('#bs_export').show();
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

    function searchAll(rtID, type) {
        var requestParams = JSON.stringify({
            "requestTypeID": rtID,
            "type": type
        });

        var myRequest = jsonRequest("../webservice/REMIInternal.asmx/Search", requestParams).success(function (data) {
            if (data.Success == true) {

                //Request Information here
                populateFields(data.Results, $('#bs_ddlSearchField'), "Request");

            }
            else if (data == true) {
                //console.log(data);
            }
            else if (data.Success == false) {
                return data.Results;
            }
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

    function downloadFile(fileName, urlData) {
        var aLink = document.createElement('a');
        var evt = document.createEvent("HTMLEvents");
        evt.initEvent("click");
        aLink.download = fileName;
        aLink.href = urlData;
        aLink.dispatchEvent(evt);
    }
});