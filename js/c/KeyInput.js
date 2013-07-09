function KeyBinding(key,keyCode,shiftKey,alt) {
	this.key = key;
	this.keyCode = keyCode;
	this.shiftKey = shiftKey;
	this.alt = alt;
}

function KeyInput(src) {
	this.bind(src);
}

KeyInput.prototype.bindings = [
	new KeyBinding('point',190),
	new KeyBinding('point',188,false,true),
	new KeyBinding('tenthpower',69,true),
	new KeyBinding('0',48),
	new KeyBinding('1',49),
	new KeyBinding('2',50),
	new KeyBinding('3',51),
	new KeyBinding('4',52),
	new KeyBinding('5',53),
	new KeyBinding('6',54),
	new KeyBinding('7',55),
	new KeyBinding('8',56),
	new KeyBinding('9',57),
	new KeyBinding('plus',187,true),
	new KeyBinding('minus',189),
	new KeyBinding('times',56,true),
	new KeyBinding('divide',191),
	new KeyBinding('equals',187),
	new KeyBinding('parentheses',57,true),
	new KeyBinding('parentheses',188,true,true),
	new KeyBinding('power',54,true),
	new KeyBinding('i',73),
	new KeyBinding('e',69),
	new KeyBinding('x',88),
	new KeyBinding('pi',80),
	new KeyBinding('constants',75),
	new KeyBinding('variables',65),
	new KeyBinding('close',27),
	new KeyBinding('delete',8),
	new KeyBinding('delete',8,true,true),
	new KeyBinding('left-arrow',37),
	new KeyBinding('right-arrow',39)
];

KeyInput.prototype.bind = function(src) {
	this.src = src;
	$(this.src).on('keydown',$.proxy(this.keyDown,this));
}

KeyInput.prototype.keyDown = function(e) {
	this.bindings.forEach(function(k) {
		if(e.keyCode == k.keyCode && !!e.shiftKey == !!k.shiftKey) {
			try {
				app.keyboard.getKeyByName(k.key).doInvoke(k.alt);
			} catch(e) {

			}
		}
	});
}
