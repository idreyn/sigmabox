var app;

try {
	navigator.splashscreen.show();
} catch(e) {

}

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