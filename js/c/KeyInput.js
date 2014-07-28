function SoftKeyBinding(key,keyCode,shiftKey,alt) {
	this.key = key;
	this.keyCode = keyCode;
	this.shiftKey = shiftKey;
	this.alt = alt;
}

function CallbackBinding(callback,keyCode,shiftKey,alt) {
	this.callback = callback;
	this.keyCode = keyCode;
	this.shiftKey = shiftKey;
	this.alt = alt;
}

function KeyInput(src) {
	this.bind(src);
}

KeyInput.prototype.bindings = [
	new SoftKeyBinding('point',190),
	new SoftKeyBinding('point',188,false,true),
	new SoftKeyBinding('tenthpower',69,true),
	new SoftKeyBinding('0',48),
	new SoftKeyBinding('1',49),
	new SoftKeyBinding('2',50),
	new SoftKeyBinding('3',51),
	new SoftKeyBinding('4',52),
	new SoftKeyBinding('5',53),
	new SoftKeyBinding('6',54),
	new SoftKeyBinding('7',55),
	new SoftKeyBinding('8',56),
	new SoftKeyBinding('9',57),
	new SoftKeyBinding('plus',187,true),
	new SoftKeyBinding('minus',189),
	new SoftKeyBinding('times',56,true),
	new SoftKeyBinding('divide',191),
	new SoftKeyBinding('equals',187),
	new SoftKeyBinding('parentheses',57,true),
	new SoftKeyBinding('parentheses',188,true,true),
	new SoftKeyBinding('power',54,true),
	new SoftKeyBinding('i',73),
	new SoftKeyBinding('e',69),
	new SoftKeyBinding('x',88),
	new SoftKeyBinding('pi',80),
	new SoftKeyBinding('constants',75),
	new SoftKeyBinding('variables',65),
	new SoftKeyBinding('close',27),
	new SoftKeyBinding('delete',8),
	new SoftKeyBinding('left-arrow',37),
	new SoftKeyBinding('right-arrow',39),
	new CallbackBinding(function() {
		app.root.toggleMenu();
	},27)
];

KeyInput.prototype.bind = function(src) {
	this.src = src;
	$(this.src).on('keydown',$.proxy(this.keyDown,this));
	$(this.src).on('keypress',$.proxy(this.keyPress,this));
}

KeyInput.prototype.keyPress = function(e) {
	var alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdfghjklmnopqrstuvwxyz';
	if(alphabet.indexOf(String.fromCharCode(e)) != -1) {
		app.mode.currentInput().acceptLatexInput(String.fromCharCode(e));
	}
}

KeyInput.prototype.keyDown = function(e) {
	if($(document.activeElement).is('input')) return;
	this.bindings.forEach(function(k) {
		if(e.keyCode == k.keyCode && !!e.shiftKey == !!k.shiftKey) {
			try {
				if(k.key) app.keyboard.getKeyByName(k.key).invoke(k.alt);
				if(k.callback) k.callback(e);
			} catch(err) {

			}
		}
	});
}
