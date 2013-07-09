/*

Sigmabox parser with python-style indent-delimitation, because mobile Safari can't parse curly brackets fast enough.

*/

$(function() {
	loadAndParse('res/elm-new.elm');
});


function loadAndParse(file) { 
	$.get(file,function(d) {
		elm.parse(d,file);
		var d = elm.create('HelloDiv','Ian');
		$('body').append(d);
	});
}