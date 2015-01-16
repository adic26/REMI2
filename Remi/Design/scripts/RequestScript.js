
$(function () { //ready function
    $('.selectpicker').selectpicker({
        //style: 'btn-info',
        size: 4
    });

    $('#FinalItemsList').hide();
    $('#bs_searchButton').hide();
    $('#bs_export').hide();
    var rtID = $("[id$='ddlRequestType']");
    var request = searchAll(rtID[0].value, "");
    var req = $('#bs_ddlSearchField');

    $('#bs_OKayButton').on('click', function () {
        //$('.selectpicker').selectpicker('hide');
        var myList = $(FinalItemsList);
        var fullList = [];

        if (req.val() != null) {
            fullList = $.merge(fullList, req.val());
        }

        $.each(fullList, function (index, element) {
            $('.list-group').append($('<li class="list-group-item">' +
                element +
                '<input type="text" class="form-inline" style="float: right;" placeholder="Input Search Criteria"></li>'))
        });

        myList.show();
        $('#bs_searchButton').show();

    });
    $('#bs_searchButton').on('click', function () {

        var fullList = [];
        var selectedRequests = req.next().find('li.selected').find('a.opt ');
        var searchTermRequests = $('#FinalItemsList li');
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

        if (fullList.length > 0) {

            var requestParams = JSON.stringify({
                "requestTypeID": rtID[0].value,
                "fields": fullList
            });

            var myTable = jsonRequest("default.aspx/customSearch", requestParams).success(
                function (d) {
                    $('#searchResults').empty();
                    $('#searchResults').append(d);
                    var oTable = $('#searchResults').DataTable({
                        destroy: true
                    });


                    $('#searchResults').find('th.sorting').css('background-color', 'black');
                    $('#searchResults').find('th.sorting_asc').css('background-color', 'black');
                    $('#bs_export').show();
                    document.getElementById('LoadingGif').style.display = "none";
                    document.getElementById('LoadingModal').style.display = "none";
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

        var myRequest = jsonRequest("default.aspx/Search", requestParams).success(function (data) {
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