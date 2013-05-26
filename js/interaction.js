var app;

$(function() {
	app = new Application();
	app.initLayout($('body').get(0));
	window.p = new Parser();
});
