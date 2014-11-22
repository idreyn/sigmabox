function Application() {
	this.r = new Resource();
	this.data = new Data();
	this.utils = new Utils();
	this.parser = new Parser();
	this.keyboards = {};
	this.keyInput = new KeyInput(window);
	this.keyboardHeight = 0.5;
	this.modeHeight = 1 - this.keyboardHeight;
}

Application.prototype.initLayout = function(wrapper) {
	var self = this;

	this.nullInput = elm.create('MathTextField');
	this.nullInput.$.addClass('null-input');
	this.data.init();
	this.wrapper = wrapper;

	this.root = elm.create('SigmaboxAppFrame');
	$(this.wrapper).append(this.root);

	this.help = this.root.help;

	this.modes = [];

	function welcomeSetupUI() {
		self.initKeyboards();
		self.setMode('eval');
	}

	if(this.data.helpSequencesPlayed.indexOf('eval') == -1 && window.location.hash != '#nohelp') {
		this.overlay(elm.create('WelcomeView',welcomeSetupUI));
	} else {
		self.initKeyboards();
		if(self.data.mode == 'about') {
			self.data.mode = 'eval';
		}
		self.setMode(self.data.mode || 'eval');
	}

	$(window).on('resize',$.proxy(this.resize,this));

	document.ontouchstart = function(e) { e.preventDefault(); };
	document.ontouchmove = function(e) { e.preventDefault(); };
	
	this.data.uiSyncReady();

	setTimeout(function() {
		try {
			navigator.splashscreen.hide();
		} catch(e) {

		}
	},1000);

	$(window).trigger('app-ready');
}

Application.prototype.setModeHeight = function(n) {
	this.modeHeight = n;
	this.resize();
}

Application.prototype.hideKeyboard = function() {
	this.modeHeight = 1;
	this.keyboardHeight = 1 - this.modeHeight;
	this.keyboard.slideDown();
	this.resize();
}

Application.prototype.showKeyboard = function() {
	this.modeHeight = 0.5;
	this.keyboardHeight = 1 - this.modeHeight;
	this.keyboard.slideUp();
	this.resize();
}

Application.prototype.useKeyboard = function(name,forceMain) {
	if(name == 'main' && !forceMain) {
		if(this.keyboard) {
			this.keyboard.slideDown();
		}
		this.keyboards.main.slideUp();
		this.keyboard = this.keyboards.main;
	} else {
		var k = this.keyboards[name];
		this.keyboard = k;
		k.slideUp();
	}
}

Application.prototype.resize = function() {
	if(this.ignoreResize) return;
	this.keyboard.size(this.keyboardHeight);
	this.mode.size(this.modeHeight);
	this.root.menu.size();
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

Application.prototype.getOrCreateMode = function(mode) {
	var mapping = {
		'eval': 'LiveEvalManager',
		'repl': 'REPL',
		'grapher': 'GrapherView',
		'functions': 'FunctionListView',
		'stats': 'StatsView',
		'linear': 'LinearSolveView',
		'converter': 'Converter',
		'about': 'HelpView'
	}
	if(this[mode]) {
		return this[mode];
	} else {
		var el = elm.create(mapping[mode]);
		this.root.addChild(el);
		this[mode] = el;
		this.modes.push(el);
		return el;
	}
}

Application.prototype.setMode = function(mode) {
	var modeName = mode;
	mode = this.getOrCreateMode(mode);
	this.ignoreResize = false;
	this.modes.map(function(m) {
		m.$.hide();
	});
	this.mode = mode;
	this.modeName = modeName;
	this.mode.$.show();
	this.mode.$.trigger('displayed');
	if(!this.mode.noKeyboard) {
		this.showKeyboard();
	} else {
		this.hideKeyboard();
	}
	this.data.mode = modeName;
	this.root.menu.setMode(modeName);
	this.data.serialize();
	setTimeout(function() {
		$(document.activeElement).blur();
	},500);
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

Application.prototype.showMenu = function() {
	this.root.showMenu();
}

Application.prototype.hideMenu = function() {
	this.root.hideMenu();
}

Application.prototype.popNotification = function(text) {
	var n = elm.create('Notification',text,1);
	this.root.addChild(n);
	n.invoke();
	n.$.on('complete',function() {
		$(this.root).remove(n);
	});
}

Application.prototype.prompt = function(title,callback,defaultVal,cancelCallback) {
	var p = elm.create('Prompt',title,callback,defaultVal);
	p.cancelCallback = cancelCallback;
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