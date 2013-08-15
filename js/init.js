var app;

/**

$.fn.__html__ = $.fn.html;

$.fn.html = function(n,override) {
	if(n === undefined) {
		return $(this).__html__();
	}
	if($(this).children().length > 0 && !override) {
		throw "Cannot replace complex contents of DOM object";
	} else {
		$(this).__html__(n);
	}
}

**/

$(function() {
	app = new Application();
	app.initLayout($('body').get(0));
	window.p = new Parser();
});
