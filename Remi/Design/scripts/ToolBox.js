/* Function used to resolve a url to a file based off of a known file path set at the server side (baseUrl)
 * This method was found here: http://weblogs.asp.net/joelvarty/archive/2009/07/17/resolveurl-in-javascript.aspx
 */
function ResolveUrl(url) {
    if (url.indexOf("~/") == 0) {
        url = baseUrl + url.substring(2);
    }
    return url;
}

/* 
* Adding the clientID extension to look for asp.net server control client IDs! 
*  This extension method will return controls whos IDs end with the text specified.
*/
$.extend({
    clientID: function (id) {
        return $("[id$='" + id + "']");
    }
});

function jsonRequest(url, requestData) {
    ///<summary>jsonRequest function performs a Json call (HTTP POST) to the specified url, provided the requestData for the call, and then executes the successCallback parameter when the json request has completed.</summary>
    ///<param optional="false" name="url" type="String">The json call's destination URL (webservice URL).</param>
    ///<param optional="false" name="requestData" type="String">The request object to send to the server. This string is the result of a call to JSON.stringify().</param>
    ///<returns type="jqXHR">The jQuery XMLHTTPRequest object which the call the .ajax returns</returns>
    return $.ajax({
        url: url,
        type: "POST",
        //contentType: "text/plain",
        contentType: "application/json; charset=utf-8",
        data: (requestData === null ? "{}" : requestData),
        converters: {
            "text json": function (data) {
                var msg = JSON.parse(data);
                return (msg.hasOwnProperty("d") ? msg.d : msg);
            }
        }
    });
}