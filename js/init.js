var app;

function init() {

	$(function() {
		app = new Application();
		app.initLayout($('body').get(0));
		window.p = new Parser();
	});

	var _timer = setInterval(function() {
		if (/loaded|complete/.test(document.readyState)) {
			setTimeout(function() {
				clearInterval(_timer);
			},500);
		}
	}, 10);

	$("input[type=text], textarea").on({ 'touchstart' : function() {
	    zoomDisable();
	}});
	
	$("input[type=text], textarea").on({ 'touchend' : function() {
	    setTimeout(zoomEnable, 500);
	}});

	function zoomDisable(){
	  $('head meta[name=viewport]').remove();
	  $('head').prepend('<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=0" />');
	}
	function zoomEnable(){
	  $('head meta[name=viewport]').remove();
	  $('head').prepend('<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=1" />');
	} 
}

window.applicationCache.addEventListener('checking',logEvent,false);
window.applicationCache.addEventListener('noupdate',logEvent,false);
window.applicationCache.addEventListener('downloading',logEvent,false);
window.applicationCache.addEventListener('cached',logEvent,false);
window.applicationCache.addEventListener('updateready',logEvent,false);
window.applicationCache.addEventListener('obsolete',logEvent,false);
window.applicationCache.addEventListener('error',logEvent,false);

function logEvent(event) {

}

function isPhoneGap() {
	try {
	    return (cordova || PhoneGap || phonegap) 
	    && /^file:\/{3}[^\/]/i.test(window.location.href) 
	    && /ios|iphone|ipod|ipad|android/i.test(navigator.userAgent);
	} catch(e) {
		return false;
	}
}

if(isPhoneGap()) {
	document.addEventListener('deviceready', init, false);
} else {
	init();
}