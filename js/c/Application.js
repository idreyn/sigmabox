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

	this.nullInput = elm.create('MathTextfield');
	this.dispatch = elm.create('Dispatch');
	this.storage.init();

	var self = this;
	this.parent = parent;

	this.initKeyboards();
	
	this.repl = elm.create('REPLManager');
	$(this.parent).append(this.repl);

	this.grapher = elm.create('GraphWindow');
	$(this.parent).append(this.grapher);

	this.modes = [this.repl,this.grapher];
	this.setMode(this.grapher);

	// Testing only
	this.mode.render();
	this.hideKeyboard();
	
	$(window).on('resize',$.proxy(this.resize,this));
	this.resize();
	this.storage.uiSyncReady();
	this.mode.init();

}

Application.prototype.setModeHeight = function(n) {
	this.modeHeight = n;
	this.resize();
}

Application.prototype.hideKeyboard = function() {
	this.modeHeight = 1;
	if(this.isAppleWebApp()) {
		this.keyboardHeight = 0;
	} else {
		this.keyboard.slideDown();
	}
	this.resize();
}

Application.prototype.showKeyboard = function() {
	this.modeHeight = 0.5;
	if(this.isAppleWebApp()) {
		this.keyboardHeight = 0.5;
		this.resize();
	} else {
		this.keyboard.slideUp();
	}
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

	this.keyboards.advanced = elm.create('Keyboard','res/xml/keyboards/advanced.xml');
	$(this.parent).append(this.keyboards.advanced);
	this.keyboards.advanced.init();
	this.keyboards.advanced.$.hide();

	this.keyboard = this.keyboards.main;
}

Application.prototype.setMode = function(mode) {
	this.modes.map(function(m) {
		m.$.hide();
	});
	this.mode = mode;
	this.mode.$.show();
	this.resize();
}

Application.prototype.useKeyboard = function(name,forceMain) {
	if(name == 'main' && !forceMain) {
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
		this.useKeyboard(input.split(' ')[1]);
	}
}

Application.prototype.isAppleWebApp = function() {
	var ua = navigator.userAgent;
	if(ua.indexOf('AppleWebKit') > -1 && ua.indexOf('Safari') == -1) {
		return true;
	} else {
		return false;
	}
}

Application.prototype.popNotification = function(text) {
	var n = elm.create('Notification',text,1);
	$(this.parent).append(n);
	n.invoke();
	n.$.on('complete',function() {
		$(this.parent).remove(n);
	});
}

function FocusManager() {
	this.current = null;
}

FocusManager.prototype.getCurrent = function() {
	return this.current || app.nullInput;
}

FocusManager.prototype.setFocus = function(c) {
	c.$.trigger('gain-focus');
	if(c == this.current) return;
	if(this.current) {
		this.current.$.trigger('lost-focus');
		this.current.loseFocus();
	}
	this.current = c;
}