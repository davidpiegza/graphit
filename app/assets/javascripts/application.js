// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require jquery.formalize
//= require modernizr.custom.28136.js
//= require jquery.tipTip.minified

// Graph specific files
//= require graph-min.js

//= require_tree .


$(document).ready(function() {
  if(Modernizr.webgl) {
    // $( "#welcome-dialog" ).dialog({
    //   modal: false,
    //   position: ['center', 200],
    //   closeText: "",
    //   closeOnEscape: false,
    //   show: {effect: "fade", duration: 2000 },
    // });
    // $( "#import-dialog" ).dialog({
    //  modal: false,
    //  position: ['center', 200],
    //  closeText: "",
    //  closeOnEscape: false,
    //  show: {effect: "fade", duration: 2000 },
    // });
    
    $("span.help").tipTip({defaultPosition: 'right', edgeOffset: 20, delay: 0});

    // $( "#load-sample-graph" ).click(function() {
    //  $( "#welcome-dialog" ).dialog("close");
    //  $( "#info-msg" ).show();
    //  // new Drawing.SimpleGraph({layout: "2d", limit: 500});
    //  new Drawing.SimpleGraph({limit: 10000});
    // });
     
  } else {
    $( "#nowebgl-dialog" ).dialog({
      modal: false,
      position: ['center', 200],
      closeText: "",
      closeOnEscape: false,
      show: {effect: "fade", duration: 2000 },
    });
  }
  
});
