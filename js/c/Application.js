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
	this.storage.init();

	var self = this;
	this.wrapper = wrapper;

	this.root = elm.create('SigmaboxAppFrame');
	$(this.wrapper).append(this.root);

	this.initKeyboards();

	this.repl = elm.create('REPL');
	this.root.addChild(this.repl);

	this.eval = elm.create('LiveEvalManager');
	this.root.addChild(this.eval);

	this.grapher = elm.create('GrapherView');
	this.root.addChild(this.grapher);

	this.functions = elm.create('FunctionListView');
	this.root.addChild(this.functions);

	this.modes = [this.repl,this.eval,this.grapher,this.functions];
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
	var kb = ['constants','variables','advanced','sin','cos','tan','matrix','list','numerical','probability'];
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

Application.prototype.prompt = function(name,callback,defaultVal) {
	var p = elm.create('Prompt',name,callback,defaultVal);
	$('body').append(p);
	return p;
}

Application.prototype.mathPrompt = function(name,callback,fm) {
	var p = elm.create('MathPrompt',name,callback,fm);
	$('body').append(p);
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
	var prompt = app.mathPrompt(variable + ' = ?',function() {
		if(originalInput.fm) originalInput.fm.setFocus(originalInput);
		var c = prompt.my('input').contents();
		var p = new Parser();
		var res = p.parse(c).valueOf(new Frame());
		self.storage.setVariable(variable,res,silent);
		if(callback) callback();
	},originalInput.fm);
	prompt.cancelCallback = function() {
		if(originalInput.fm) originalInput.fm.setFocus(originalInput);
	}
}

Application.prototype.overlay = function(view) {
	this.root.setOverlay(view);
}

Application.prototype.useGratuitousAnimations = function() {
	return !utils.isAppleWebApp();
}