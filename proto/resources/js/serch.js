$(document).ready(function() {
  initserchname();
  addeventChange();
  addorderlisteners();
  setInterval(testCanUpdate, 50);
  askedToUpdate = true;
  testCanUpdate();
});
BASE_URL = 'http://gnomo.fe.up.pt/~lbaw1622/rui/FEUP-LBAW/proto/';

var canUpdateuser = true;
var canUpdateEvent = true;
var askedToUpdate = false;

function initserchname() {
	var name = $('#searched-words').text();
    $('#serch-input').val(name);
}

function addeventChange() {
	$('#serch-input').on('input', function() {
		var name = $('#serch-input').val();
		$('#searched-words').text(name);
		$('.page-header h1').text("Search Results for \"" + name + "\"");
		askedToUpdate = true;
		testCanUpdate();
	});
}

function addorderlisteners() {
	$('.tabOptions input').on('change', function() {
		askedToUpdate = true;
		testCanUpdate();
	});
}

function testCanUpdate() {
	if(askedToUpdate){
		if(canUpdateuser && canUpdateEvent){
			$('#usersPesq .usercadssech').html("");
			$('#eventosPesq .eventcadssech').html("");
			var name = $('#serch-input').val();
			if(name == ''){
				$('#tabs .button-users').html('Users (0)');
				$('#tabs .button-events').html('Events (0)');
				askedToUpdate = false;
				return;
			}
			var ascUser = $('input[name=alfa-order-users]:checked').val();
			var ascEvent = $('input[name=alfa-order-event]:checked').val();
			var byEvent = $('input[name=type-order-event]:checked').val();
			var boolFree = $('input[name=free-order-event]').is(':checked');
			var boolPaid = $('input[name=paid-order-event]').is(':checked');
			doajaxusercall('0', name, ascUser);
			doajaxeventcall('0', name, boolFree, boolPaid, byEvent, ascEvent);
			askedToUpdate = false;
		}
	}
}

function doajaxusercall(page, name, asc) {
	  var ind = 0;
	  canUpdateuser = false;
	  $.getJSON(BASE_URL + "actions/user/serchusers.php", {page: page, serch: name, asc: asc}, function(data) {
      $.each(data, function(i, asc) {
		  ind += 1;
		 $('#usersPesq .usercadssech').append(
		 '<div class="container-fluid user-card-medium">' +
              '<p class="titulo-card">' + asc.first_name + ' ' + asc.last_name +'</p>' +
              '<div class="row">' +
               '<div class="col-sm-3">' +
                  '<img src="' + BASE_URL + 'resources/images/' + asc.photo_url + '"/>' +
                '</div>' +
                '<div class="col-sm-9">' +
                  '<p class="text-card">'  + asc.username + '</p>' +
                  '<p class="text-card">' + asc.email + '</p>' +
                  '<button type="button" class="btn btn-default col-sm-5">Go To ptofile</button>' +
                '</div>' +
              '</div>' +
            '</div>');
      });
		$('#tabs .button-users').html('Users (' + ind + ')');
		canUpdateuser = true;
    });
}

function doajaxeventcall(page, name, free, paid, nameOrPrice, asci) {
	  var ind = 0;
	  canUpdateEvent = false;
	  var bFree = true;
	  var bPaid = true;
	  var bNameOrPrice = true;
	  if(free)
		  bFree = 1;
	  else
		  bFree = 0;
	  
	  if(paid)
		  bPaid = 1;
	  else
		  bPaid = 0;
	  
	  if(nameOrPrice)
		  bNameOrPrice = 1;
	  else
		  bNameOrPrice = 0;
	  $.getJSON(BASE_URL + "actions/user/serchevents.php", {page: page, serch: name, free: bFree, paid: bPaid, nameOrPrice: bNameOrPrice, asc: asci}, function(data) {
      $.each(data, function(i, asc) {
		  ind += 1;
		  var vfree = 'Free';
		  var address = asc.cityname;
		  var rateEvent = asc.rate;
		  var rateString = '';
		  if(asc.street){
			  address = address + ', ' +  asc.street;
		  }
		  if(!asc.free){
			  vfree = 'Paid';
		  }
		  if(!rateEvent){
			  rateEvent = 0;
		  }
		  rateString.concat('<i class="fa fa-star fa-2x" aria-hidden="true"></i>'.repeat(rateEvent));
		  rateString.concat('<i class="fa fa-star-o fa-2x" aria-hidden="true"></i>'.repeat(5-rateEvent));
		 $('#eventosPesq .eventcadssech').append(
		    '<div class="container-fluid event-card-medium">' +
              '<p class="titulo-card">' + asc.name + '</p>' +
              '<div class="row">' +
                '<div class="col-sm-3">' +
                  '<img src="' + BASE_URL + 'resources/images/' + asc.photo_url + '"/>' +
                '</div>' +
                '<div class="col-sm-9">' +
                  '<p class="text-card">' + asc.beginning_date + '</p>' +
                  '<p class="text-card">' + address + '</p>' +
                  '<p class="text-card">' + vfree + '</p>' +
                  '<div class="container-fluid">' + 
                    '<div class="row">' +
                      '<button type="button" class="btn btn-default col-sm-5">See More...</button>' +
                      '<div class="classifica-card col-sm-7">' +
                       rateString  +
                      '</div>' +
                    '</div>' +
                  '</div>' +
                '</div>' +
              '</div>' +
            '</div>');
      });
		$('#tabs .button-events').html('Events (' + ind + ')');
		canUpdateEvent = true;
    });
}