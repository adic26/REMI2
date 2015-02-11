
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
    var executeTop = $("[id$='hdnTop']");
    var user = $("[id$='hdnUser']");
    var userID = $("[id$='hdnUserID']");
    var oTable;
    var count = 0;
    
    var o = new Option("--aReqNum", "--aReqNum");
    $(o).html("Request Number");
    $('#bs_Additional').append(o);

    $.fn.dataTable.TableTools.defaults.aButtons = ["copy", "csv", "xls"];

    additional.selectpicker('val', '--aReqNum');
   // $('.selectpicker').selectpicker('render');

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
            builtHTML += '<input type="text" id="' + element + count + '" name="' + element + '" addition="' + isAdditional + '" class="form-inline" style="float: right;" placeholder="Input Search Criteria">';

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
        var myTable = $('#searchResults');
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
                if (s_element.children[0].value != '') {
                    var searchTerm = s_element.innerText
                    if (searchTerm == element.innerText) {
                        var request = 'Request' + ',' + testID + ',' + s_element.children[0].value;
                        fullList.push(request);
                    }
                }
            });
        });

        $.each(searchTermRequests, function (s_index, s_element) {
            if (s_element.children[0].value != '' && s_element.outerHTML.indexOf('addition="true"') > -1) {
                var additionalVals = s_element.outerText + ',0,' + s_element.children[0].value;
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