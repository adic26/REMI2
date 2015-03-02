﻿$(function () { //ready function

    $('.test-popup-link').hide();

    $(document).on("click", "[id*=viewImages]", function (e) {
        testGetSlideJS(($(this)[0]).attributes["mID"].value);
        return false;
    });

    function testGetSlideJS(contextKey) {

        var myImage;

        var requestParams = JSON.stringify({
            "contextKey": contextKey
        });

        var myRequest = jsonRequest("/webservice/REMIInternal.asmx/GetSlidesJS", requestParams).success(function (data) {
            var results = data;
            myImage = $(data);

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

        });
    }
});


