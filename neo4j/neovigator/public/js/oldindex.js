
  var canvas = document.getElementById("neoviz");

  var myGraph; // a reference to the graph to make it available to the outside world

  var p = Processing(canvas); 

  function loadvisualization() {
    var vizid = document.getElementById("vizid").value 
    if ( vizid != "") {
      p.resourceId = vizid; 
    } else {
      p.resourceId = window.location.search.substring(1).split("=")[1];
    }
    p.resourceId = vizid;
    p.setup();

    $("#path li").remove();

  };

  $(function() {
    function canvasSupported() {
      var canvas_compatible = false;
      try {
       canvas_compatible = !!(document.createElement('canvas').getContext('2d')); // S60
      } catch(e) {
       canvas_compatible = !!(document.createElement('canvas').getContext); // IE
      }
      return canvas_compatible;
    }

    if (canvasSupported()) {
  
      var initialized = false;
        
      // init
      var vizid =  window.location.search.substring(1).split("=")[1];
      if (vizid) {
        p.resourceId = vizid;
      } else {
        p.resourceId = "0";
      }

      p.init(p.ajax("/js/pjs/physics.pjs")+p.ajax("/js/pjs/donut.pjs")+p.ajax("/js/pjs/resource.pjs")+p.ajax("/js/pjs/node.pjs")+p.ajax("/js/pjs/edge.pjs")+p.ajax("/js/pjs/graph.pjs")+p.ajax("/js/pjs/network.pjs"));
      initialized = true;
      
      $(window).resize(function(){
        p.resize();
        Attributes.adjustHeight();
      });
    } else {
      $('#browser_not_supported').show();
      $('#explanation').hide();
    }
  });
