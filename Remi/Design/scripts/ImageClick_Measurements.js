$(function () { //ready function

    $('.test-popup-link').hide();

    
    $(document).on("click", "[id*=viewImages]", function (e) {
        //var imgID = ($(this)[0]).id;
        //var resultID = ($(this)[0]).attributes["resultID"].value;
        //var id = ($(this)[0]).attributes["sseImg"].value + "_" + resultID + "_ssb";
        //var ucID = ($(this)[0]).attributes["pageID"].value;
        //$find(id).set_contextKey(($(this)[0]).attributes["mID"].value);
        //Get context number
        testGetSlideJS(($(this)[0]).attributes["mID"].value);

        //$("#" + ucID + "_images").dialog({
        //    autoResize: true,
        //    height: 'auto',
        //    width: 'auto',
        //    position: 'center',
        //    modal: true,
        //    appendTo: 'body',
        //    autoOpen: true,
        //    buttons: [],
        //    closeOnEscape: true,
        //    closeText: null,
        //    open: function () {
        //        $find(id).set_contextKey(0);
        //        $(this).parent().appendTo($("#" + ucID + "_images").parent().parent());
        //    }
        //});

        //e.preventDefault();
        return false;
    });

    function testGetSlideJS(contextKey) {

       
        //<a class="test-popup-link" visible="false">popup</a>

        var myImage;

        var requestParams = JSON.stringify({
            "contextKey": contextKey
        });

        var myRequest = jsonRequest("/webservice/REMIInternal.asmx/GetSlidesJS", requestParams).success(function (data) {
            var results = data;
            myImage = $(data);
        });

        var myGallery = $('.test-popup-link').magnificPopup({
            type: 'image',
            gallery: {
                enabled: true
            }
            // other options
        }).magnificPopup('open');

        var mfp = $.magnificPopup.instance;
        mfp.items.pop();
        $.each(myImage, function (index, element) {
            mfp.items.push({
                src: element,
                type: 'image'
            });

            mfp.updateItemHTML();
        });
        





    }

    //shit is just a dev, in this case it is just a test . We should be able to get its click right
    //var idea = jsonRequest(); 
    //idea.data= All the sources; 
    //$.each.idea( $('#shit').append(//source code))
    //where var source = <a class="image-link" href="img/red1.jpg"><img src="img/red1.jpg"></a>

    //<div id="images" class="ModalPopup">
    //$('.images').empty();
    //$('.images').append(source)

    //$('#images').magnificPopup({
    //    delegate: '.image-link',
    //    type: 'image',
    //    gallery: {
    //        enabled: true
    //    }
    //});


});


