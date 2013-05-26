function Application() {
	this.r = new Resource();
	this.storage = new Storage();
	this.utils = new Utils();
	this.sound = new Sound();
	this.parser = new Parser();
	this.keyboards = {};
	this.keyInput = new KeyInput(window);
	this.keyboardHeight = 0.5;
	this.modeHeight = 1 - this.keyboardHeight;
}

Application.prototype.initLayout = function(parent) {
	var self = this;
	this.parent = parent;

	if (/OS 6_/.test(navigator.userAgent)) {
  		$.ajaxSetup({ cache: false });
	}

	this.initKeyboards();
	
	this.mode = elm.create('REPLManager');
	$(this.parent).append(this.mode);
	this.mode.init();
	
	$(window).on('resize',$.proxy(this.resize,this));
	this.resize();	
}

Application.prototype.resize = function() {
	this.keyboard.size(this.keyboardHeight);
	this.mode.size(this.modeHeight);
}

Application.prototype.initKeyboards = function() {
	this.keyboards.main = elm.create('Keyboard','res/xml/keyboards/main.xml');
	$(this.parent).append(this.keyboards.main);
	this.keyboards.main.init();

	this.keyboards.constants = elm.create('Keyboard','res/xml/keyboards/constants.xml');
	$(this.parent).append(this.keyboards.constants);
	this.keyboards.constants.init();
	this.keyboards.constants.$.hide();

	this.keyboards.variables = elm.create('Keyboard','res/xml/keyboards/variables.xml');
	$(this.parent).append(this.keyboards.variables);
	this.keyboards.variables.init();
	this.keyboards.variables.$.hide();

	this.keyboard = this.keyboards.main;
}

Application.prototype.useKeyboard = function(name) {
	if(name == 'main') {
		if(this.keyboard == this.keyboards.main) return;
		this.keyboard.slideDown();
		this.keyboard = this.keyboards.main;
		this.resize();
		this.storage.cancelVariableSave();
	} else {
		var k = this.keyboards[name];
		this.keyboard = k;
		this.resize();
		k.slideUp();
	}
}

Application.prototype.acceptActionInput = function(input) {
	if(input.split(' ')[0] == 'keyboard'){
		//console.log('useKeyboard',input.split(' ')[1]);
		this.useKeyboard(input.split(' ')[1]);
	}
}

Application.prototype.isAppleWebApp = function() {
	return true;
	var ua = navigator.userAgent;
	if(ua.indexOf('AppleWebKit') > -1 && ua.indexOf('Safari') == -1) {
		return true;
	} else {
		return false;
	}
}


Application.prototype.popNotification = function(text) {
	var n = elm.create('Notification',text,2);
	$(this.parent).append(n);
	n.invoke();
	n.$.on('complete',function() {
		$(this.parent).remove(n);
	});
}