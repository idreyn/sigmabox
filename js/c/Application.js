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

Application.prototype.initLayout = function(wrapper) {

	this.nullInput = elm.create('MathTextField');
	this.dispatch = elm.create('Dispatch');
	this.storage.init();

	var self = this;
	this.wrapper = wrapper;

	this.root = elm.create('SigmaboxAppFrame');
	$(this.wrapper).append(this.root);

	this.initKeyboards();

	this.eval = elm.create('LiveEvalManager');
	this.root.addChild(this.eval);

	this.grapher = elm.create('GrapherView');
	this.root.addChild(this.grapher);

	this.functions = elm.create('FunctionListView');
	this.root.addChild(this.functions);

	this.modes = [this.eval,this.grapher,this.functions];
	this.root.menu.build();
	this.setMode(this.storage.mode || 'eval');

	// Testing only

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
	var self = this;
	this.modeHeight = 1;
	if(this.isAppleWebApp() && false) {
		this.keyboardHeight = 0;
	} else {
		this.keyboard.slideDown();
		setTimeout(function() {
			self.keyboardHeight = 1 - self.modeHeight;
		},500);
	}
	this.resize();
}

Application.prototype.showKeyboard = function() {
	var self = this;
	this.modeHeight = 0.5;
	this.keyboardHeight = 1 - this.modeHeight;
	if(this.isAppleWebApp() && false) {
		this.keyboardHeight = 0.5;
		this.resize();
	} else {
		this.keyboard.slideUp();
		setTimeout(function() {
			self.keyboardHeight = 1 - self.modeHeight;
		},500);
	}
}

Application.prototype.resize = function() {
	this.root.size();
}

Application.prototype.liteResize = function() {
	this.keyboard.size();
	this.mode.size();
}

Application.prototype.initKeyboards = function() {
	this.keyboards.main = elm.create('Keyboard','res/xml/keyboards/main.xml');
	this.root.addChild(this.keyboards.main);
	this.keyboards.main.init();

	this.keyboards.constants = elm.create('Keyboard','res/xml/keyboards/constants.xml');
	this.root.addChild(this.keyboards.constants);
	this.keyboards.constants.init();
	this.keyboards.constants.$.hide();

	this.keyboards.variables = elm.create('Keyboard','res/xml/keyboards/variables.xml');
	this.root.addChild(this.keyboards.variables);
	this.keyboards.variables.init();
	this.keyboards.variables.$.hide();

	this.keyboards.advanced = elm.create('Keyboard','res/xml/keyboards/advanced.xml');
	this.root.addChild(this.keyboards.advanced);
	this.keyboards.advanced.init();
	this.keyboards.advanced.$.hide();

	this.keyboards.sin = elm.create('Keyboard','res/xml/keyboards/sin.xml');
	this.root.addChild(this.keyboards.sin);
	this.keyboards.sin.init();
	this.keyboards.sin.$.hide();

	this.keyboards.cos = elm.create('Keyboard','res/xml/keyboards/cos.xml');
	this.root.addChild(this.keyboards.cos);
	this.keyboards.cos.init();
	this.keyboards.cos.$.hide();

	this.keyboards.tan = elm.create('Keyboard','res/xml/keyboards/tan.xml');
	this.root.addChild(this.keyboards.tan);
	this.keyboards.tan.init();
	this.keyboards.tan.$.hide();

	this.keyboard = this.keyboards.main;
}

Application.prototype.setMode = function(mode) {
	var mstring = mode;
	mode = this[mode];
	this.modes.map(function(m) {
		m.$.hide();
	});
	this.mode = mode;
	this.mode.$.show();
	this.mode.$.trigger('active');
	this.mode.size();
	if(!this.mode.noKeyboard) {
		this.showKeyboard();
	} else {
		this.hideKeyboard();
	}
	this.storage.mode = mstring;
	this.root.menu.setMode(mstring);
	this.storage.serialize();
}

Application.prototype.useKeyboard = function(name,forceMain) {
	if(name == 'main' && !forceMain) {
		if(this.keyboard == this.keyboards.main) return;
		this.keyboard.slideDown();
		this.keyboard = this.keyboards.main;
		this.storage.cancelVariableSave();
	} else {
		var k = this.keyboards[name];
		this.keyboard = k;
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
	this.root.addChild(n);
	n.invoke();
	n.$.on('complete',function() {
		$(this.root).remove(n);
	});
}

Application.prototype.prompt = function(name,callback,defaultVal) {
	$('body').append(elm.create('Prompt',name,callback,defaultVal));
}

Application.prototype.confirm = function(title,contents,callback,okayLabel,cancelLabel) {
	$('body').append(elm.create('Confirm',title,contents,callback,okayLabel,cancelLabel));
}

Application.prototype.overlay = function(view) {
	this.root.setOverlay(view);
}

Application.prototype.tabletMode = function() {
	var v = app.utils.viewport();
	return v.x > 800 && v.y > 600;
}

Application.prototype.useGratuitousAnimations = function() {
	return !this.isAppleWebApp();
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