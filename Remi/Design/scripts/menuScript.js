// Shows DIV popup commands for gridview
function ShowPopup(lbtn1, lbtn2, panel, gridviewRow) {
    var link1 = document.getElementById(lbtn1);
    //var link2 = document.getElementById(lbtn2);
    var pnl = document.getElementById(panel);
    var row = document.getElementById(gridviewRow);
    if (pnl.style.display === "none") {
        pnl.style.display = "block";
    }
    else {
        pnl.style.display = "none";
    }
    if (link1.style.display === "none") {
        if (link1 != null)
            link1.style.display = "block";
        else
            link1.style.display = "none";
    }

//    if (link2.style.display === "none") {
//        if (link2 != null)
//            link2.style.display = "block";
//    }
//    else {
//        if (link2 != null)
//            link2.style.display = "none";
//    }

    //pnl.style.backgroundImage = "url(../images/td_mouseover_inverted.gif)";
}
//This function checks a horizontal row of check boxes in a table
//when the chkAll checkbox is clicked
//it must be supplied with the gridviewrow id and the calling checkbox
function CheckAllAcrossRow(rowRef, chkAllRef) {
    //get the row
    var currentRow = document.getElementById(rowRef);
    //get the all checked checkbox
    var allCheckbox = document.getElementById(chkAllRef);
    //get the collection of checkboxes
       var innerGridArray = currentRow.getElementsByTagName('input');
    //get the upper limit
    var checkboxCount = innerGridArray.length - 1;

    for (var i = 2; i <= checkboxCount; i++) {
    //get the checkbox
        var checkbox = innerGridArray[i];
     //set the checkbox to the same
     if (checkbox.type === "checkbox")
           checkbox.checked = allCheckbox.checked;
    }

}
//This function unchecks a horiz row and sets the individual
//exception selectors to disabled or enabled depending
//on the checked value of the product exception checkbox
//it must be supplied with the gridviewrow id and the calling checkbox
function CheckProductException(rowRef, chkPexRef) {
   
    //get the row
    var currentRow = document.getElementById(rowRef);
    //get the all checked checkbox
    var pexCheckbox = document.getElementById(chkPexRef);
    //get the collection of checkboxes
   
   
    var innerGridArray = currentRow.getElementsByTagName('input');
    //get the upper limit
    var checkboxCount = innerGridArray.length - 1;
    //get the chkAll checkbox
    var chkAll = innerGridArray[1];
    for (var i = 2; i <= checkboxCount; i++) {
        //get the checkbox
        var checkbox = innerGridArray[i];
        //set the checkbox to the same
        if (innerGridArray[0].checked === true) {
            chkAll.checked = false;
            chkAll.disabled = true;
            checkbox.checked = false;
            checkbox.disabled = true;
        }
        else {
            chkAll.disabled = false;
            checkbox.disabled = false;
        }
    }

}

//Hides DIV popup commands for gridview
function HidePopup(lbtn1, lbtn2, panel, gridviewRow) {
    var link1 = document.getElementById(lbtn1);
    //var link2 = document.getElementById(lbtn2);

    var pnl = document.getElementById(panel);
    var row = document.getElementById(gridviewRow);
    //row.style.backgroundImage = "url(../images/spacer.gif)";
    pnl.style.display = "none";
    if (link1 != null)
        link1.style.display = "none";
//    if (link2 != null)
//        link2.style.display = "none";
}