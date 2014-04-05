function Application() {
	this.r = new Resource();
	this.data = new Data();
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
	this.nullInput.$.addClass('null-input');
	this.data.init();

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

	this.lab = elm.create('ChiSquaredView');
	this.root.addChild(this.lab);

	this.stats = elm.create('StatsView');
	this.root.addChild(this.stats);

	this.modes = [this.eval,this.grapher,this.functions,this.stats,this.lab];
	this.root.menu.build();
	this.setMode(this.data.mode || 'eval');

	$(window).on('resize',$.proxy(this.resize,this));
	this.resize();
	this.data.uiSyncReady();
	this.mode.init();

	$(window).trigger('app-ready');
}

Application.prototype.setModeHeight = function(n) {
	this.modeHeight = n;
	this.resize();
}

Application.prototype.hideKeyboard = function() {
	var self = this;
	this.modeHeight = 1;
	if(utils.isAppleWebApp() && false) {
		this.keyboardHeight = 0;
	} else {
		this.keyboard.slideDown();
		setTimeout(function() {
			self.keyboardHeight = 1 - self.modeHeight;
		},500);
	}
	self.keyboardHeight = 1 - self.modeHeight;
	this.liteResize();
}

Application.prototype.showKeyboard = function() {
	var self = this;
	this.modeHeight = 0.5;
	this.keyboardHeight = 1 - this.modeHeight;
	if(utils.isAppleWebApp() && false) {
		this.keyboardHeight = 0.5;
		this.liteResize();
	} else {
		this.keyboard.slideUp();
		self.keyboardHeight = 1 - self.modeHeight;
		this.liteResize();

	}
}

Application.prototype.resize = function() {
	var self = this;
	this.root.size();
	setTimeout(function() {
		self.root.size();
	},1000);
}

Application.prototype.liteResize = function() {
	this.keyboard.size(this.keyboardHeight);
	this.mode.size(this.modeHeight);
}

Application.prototype.initKeyboards = function() {
	this.keyboards.main = elm.create('DragKeyboard','res/xml/keyboards/main.xml');
	this.root.addChild(this.keyboards.main);
	this.keyboards.main.init();
	var self = this;
	var kb = ['constants','variables','advanced','sin','cos','tan','matrix','list','numerical','distributions'];
	kb.forEach(function(k) {
		self.keyboards[k] = elm.create('Keyboard','res/xml/keyboards/' + k + '.xml');
		self.root.addChild(self.keyboards[k]);
		self.keyboards[k].init();
		self.keyboards[k].$.hide();
	});

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
	if(!this.mode.noKeyboard) {
		this.showKeyboard();
	} else {
		this.hideKeyboard();
	}
	this.mode.size(this.modeHeight);
	this.data.mode = mstring;
	this.root.menu.setMode(mstring);
	this.data.serialize();
}

Application.prototype.useKeyboard = function(name,forceMain) {
	if(name == 'main' && !forceMain) {
		if(this.keyboard) {
			this.keyboard.slideDown();
		}
		this.keyboards.main.slideUp();
		this.keyboard = this.keyboards.main;
		this.data.cancelVariableSave();
	} else {
		var k = this.keyboards[name];
		this.keyboard = k;
		k.slideUp();
	}
}

Application.prototype.acceptActionInput = function(input) {
	var split = input.split(' ');
	var kw = split[0];
	if(kw == 'keyboard'){
		this.useKeyboard(split[1]);
	}
	if(kw == 'notify') {
		this.popNotification(split[1]);
	}
	if(kw == 'set') {
		this.setVariablePrompt(split[1]);
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

Application.prototype.prompt = function(title,callback,defaultVal) {
	var p = elm.create('Prompt',title,callback,defaultVal);
	$('body').append(p);
	return p;
}

Application.prototype.mathPrompt = function(title,callback,fm) {
	var p = elm.create('MathPrompt',title,callback,fm);
	app.mode.$.append(p);
	return p;
}

Application.prototype.confirm = function(title,contents,callback,okayLabel,cancelLabel) {
	var c = elm.create('Confirm',title,contents,callback,okayLabel,cancelLabel);
	$('body').append(c);
	return c;
}

Application.prototype.setVariablePrompt = function(variable,silent,callback) {
	var self = this;
	var originalInput = app.mode.currentInput();
	var prompt = app.mathPrompt(variable + ' = ?',function(res,close,tryAgain) {
		if(originalInput.focusManager) originalInput.focusManager.setFocus(originalInput);
		self.data.setVariable(variable,res,silent);
		close();
		if(callback) callback();
	},originalInput.focusManager);
	prompt.cancelCallback = function() {
		if(originalInput.focusManager) originalInput.focusManager.setFocus(originalInput);
	}
}

Application.prototype.overlay = function(view) {
	this.root.setOverlay(view);
}

Application.prototype.useGratuitousAnimations = function() {
	return !utils.isAppleWebApp();
}