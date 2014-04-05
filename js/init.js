var app;

$(function() {
	app = new Application();
	app.initLayout($('body').get(0));
	window.p = new Parser();
});

var _timer = setInterval(function() {
	if (/loaded|complete/.test(document.readyState)) {
		//$('.load-screen').fadeOut(100);
		clearInterval(_timer);
	}
}, 10);