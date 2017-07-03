
var Flight = {
  search: function(from, to, departing, returning, oneway){
    $.ajax({
      method: "POST",
      url: "/search",
      data: {from: from, to: to, departing: departing, returning: returning, oneway: oneway},
    }).success(function(data){
      if (data.success == true) {
        Flight.render_flights(data, oneway);
      } else {
        Flight.render_errors(data);
      }
    }).error(function(){
      var error_tpl = $("#error-tpl").html();
      $("#errors").append(Mustache.to_html(error_tpl, {key: "Ooops!", value: "Something went wrong"}));
      return Flight.overlay_off();
    })
  },

  render_flights: function(data, oneway){
    if (oneway) {
      var el = $("#search-results-to");
      $(el).show();
      Flight.render_header(data.header.departing, el);
      Flight.render_flight_cards(data.data, el);
    } else {
      var el_to = $("#search-results-to");
      var el_from = $("#search-results-from");
      $(el_to).show();
      $(el_from).show();
      Flight.render_header(data.header.departing, el_to);
      Flight.render_flight_cards(data.data_to, el_to);
      Flight.render_header(data.header.returning, el_from);
      Flight.render_flight_cards(data.data_from, el_from);
    }
    Flight.overlay_off();
    return;
  },

  render_errors: function(data){
    var error_tpl = $("#error-tpl").html();
    Object.keys(data.errors).forEach(function(key, index) {
      $("#errors").append(Mustache.to_html(error_tpl, {key: key, value: data.errors[key]}));
    });
    Flight.overlay_off();
  },

  clear_errors: function(){
    $("#errors").empty();
    $(".error").remove();
  },

  // renders header `SYD -> JFK'
  render_header: function(data, element){
    var header_tpl = $("#flight-header").html();
    element.prepend(Mustache.to_html(header_tpl, data));
  },

  // renders flight card in a loop from all dates
  render_flight_cards: function(array, element){
    var flight_tpl = $("#flight-card").html();
    $.each(array, function(i, flights){
      exact_date = Object.keys(flights)[0];
      var container = $(element).find(".tab-content").find(".tab-pane")[i];
      var list_item = $(element).find("li")[i];
      $(list_item).find("a").html(exact_date);
      if (flights[exact_date].length > 0) {
        $.each(flights[exact_date], function(j, flight){
          $(container).find(".anchor").append(Mustache.to_html(flight_tpl, flight));
        });
        $(element).find("li").removeClass("active");
        var active_li = $(element).find("li")[2];
        $(element).find('.nav-tabs li:eq(2) a').tab('show')
        $(active_li).addClass("active");
      } else {
        var no_flights_tpl = $("#no-flights").html();
        $(container).append(Mustache.to_html(no_flights_tpl, {}));
        $(list_item).addClass("disabled");
      }
    }); // $.each
    element.css({"visibility":"visible"});
  },

  select_flight: function(element){
    element.parent().find(".card").hide();
    element.show();
    element.removeClass("scaling");
  },

  overlay_on: function(){
    $("#pluswrap").show();
  },

  overlay_off: function(){
    $("#pluswrap").hide();
  },

  prepare_for_search: function(){
    Flight.clear_errors();
    $("#search-results-to, #search-results-from").find("li").removeClass("disabled");
    $("#search-results-to, #search-results-from").find(".card, .direction-header").remove();
    $("#search-results-to, #search-results-from").css({"visibility": "hidden"});
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

  // one way checkbox
  $("#oneway").change(function(){
    $("#returning").prop('disabled', $(this).prop('checked'));
  });

  // Search form submit
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
      return Flight.search(from, to, departing, returning, oneway);
    } else {
      return Flight.render_errors({errors: {"Please fill all": "needed fields"}});
    }
  });
});