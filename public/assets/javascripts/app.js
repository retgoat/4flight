
var Flight = {
  search: function(from, to, departing, returning, oneway){
    $.ajax({
      method: "POST",
      url: "/search",
      data: {from: from, to: to, departing: departing, returning: returning, oneway: oneway},
    }).success(function(data){
      console.log(JSON.stringify(data));
      if (data.success == true) {
        Flight.render_flights(data, oneway);
      } else {
        Flight.render_errors(data);
      }
    })
  },

  render_flights: function(data, oneway){
    if (oneway) {
      var first = data.data[0];
      var el = $("#search-results-to");
      Flight.render_header(first, el);
      Flight.render_flight_cards(data.data, el);
    } else {
      console.log(JSON.stringify(data));
      var el_to = $("#search-results-to");
      var el_from = $("#search-results-from");
      Flight.render_header(data.data_to[0], el_to);
      Flight.render_flight_cards(data.data_to, el_to);
      Flight.render_header(data.data_from[0], el_from);
      Flight.render_flight_cards(data.data_from, el_from);
    }
    Flight.overlay_off();
    return;
  },

  render_errors: function(data){
    console.log("err");
  },

  render_header: function(data, element){
    var header_tpl = $("#flight-header").html();
    element.append(Mustache.to_html(header_tpl, data));
  },

  render_flight_cards: function(array, element){
    var flight_tpl = $("#flight-card").html();
    $.each(array, function(index, flight){
      element.append(Mustache.to_html(flight_tpl, flight));
    });
  },

  select_flight: function(element){
    element.parent().find(".card").hide();
    element.show();
  },

  overlay_on: function(){
    $("#pluswrap").show();
  },

  overlay_off: function(){
    $("#pluswrap").hide();
  },

  prepare_for_search: function(){
    $("#search-results-to").empty();
    $("#search-results-from").empty();
  },
}
$(document).on("click", ".card", function(e){
  Flight.select_flight($(this));
});

$(document).ready(function(){
  // initialize datepicker
  $("#departing").datepicker({format: "yyyy-mm-dd", autoclose: true, todayHighlight: true});
  $("#returning").datepicker({format: "yyyy-mm-dd", autoclose: true, todayHighlight: true});

  // initialize typeahed on from and to fields
  $('input.typeahed[name="from-country"]').bootcomplete({url:'/airport'});
  $('input.typeahed[name="to-country"]').bootcomplete({url:'/airport'});

  $("#oneway").change(function(){
    $("#returning").prop('disabled', $(this).prop('checked'));
  });

  $("form").submit(function(e){
    e.preventDefault()
    var from = $('input[name="from-country_id"]').val();
    var to = $('input[name="to-country_id"]').val();
    var departing = $("#departing").val();
    var returning = $("#returning").val();
    var oneway = $("#oneway").is(':checked');

    if (from.length > 0 && to.length > 0 && departing.length > 0 && (returning.length > 0 || oneway)) {
      Flight.prepare_for_search();
      Flight.overlay_on();
      $(".search-form").animate(function(){})
      return Flight.search(from, to, departing, returning, oneway);
    }
  });
});