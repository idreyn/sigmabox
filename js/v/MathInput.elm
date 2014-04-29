def MathInput(owner) {
	
	html {
		<span></span>
	}
	
	constructor {
		$this.mathquill('editable');
		$this.find('textarea').attr('disabled','disabled');
	}

	extends {
		TouchInteractive
	}
	
	css { 
		padding: 20px;
		height: 100%;
		width: 100%;
		display: block;
		border: none;
		color: #333;
		text-shadow: 1px 1px 10px #666;
		-webkit-tap-highlight-color: rgba(255, 255, 255, 0);
	}

	on focus {

	}

	method loseFocus {
		this.mathSelf().cursor.hide();
	}

	method takeFocus {
		
	}
	
	method contents {
		return $this.mathquill('latex');
	}
	
	method mathSelf {
		return $this.mathquill('get');
	}
	
	method acceptLatexInput(input,doUpdate) {
		if(doUpdate === undefined) doUpdate = true;
		if(!(self.preventInput && self.preventInput(input))) $this.mathquill('write',input);
		this.mathSelf().cursor.show();
		if(doUpdate) $this.trigger('update');
	}

	method setContents(input) {
		$this.html('',true);
		$this.mathquill('latex',input);
	}
	
	method acceptActionInput(type) {
		var oldContents = this.contents();
		type.split(',').forEach(function(t) {
			self.$.trigger('action-input',type);
			var c = self.mathSelf().cursor;
			switch(t) {
				case 'left':
					if(!(self.preventCursorLeft && self.preventCursorLeft()) && (c.prev || c.parent != c.root)) {
						self.mathSelf().cursor.moveLeft();
					} else {
						self.$.trigger('cursor-left');
					}
					break;
				case 'right':
					if(!(self.preventCursorRight && self.preventCursorRight()) && (c.next || c.parent != c.root)) {
						self.mathSelf().cursor.moveRight();
					} else {
						self.$.trigger('cursor-right');
					}
					break;
				case 'backspace':
					if(!(self.preventBackspace && self.preventBackspace())) self.mathSelf().cursor.backspace();
					break;
				case 'clear':
					$this.mathquill('latex','');
					break;
				case 'function':
					app.overlay(elm.create('FunctionChoiceView',function(func) {
						var commas = '';
						for(var i=0;i<func.parameters.length-1;i++) {
							commas += ',';
						}
						self.acceptLatexInput(
							'\\' + func.name + '(' + commas + ')'
						);
						for(var i=0;i<func.parameters.length;i++) {
							self.mathSelf().cursor.moveLeft();
						}
					}));
					break;
				case 'list':
					app.overlay(elm.create('ListChoiceView',function(list) {
						self.acceptLatexInput('\\' + list.name);
					}));
					break;
			}
		});
		if(self.afterInput) self.afterInput(oldContents,this.contents());
		$this.trigger('update');
	}

	on keyup(e) {
		$this.trigger('update');
	}
	
	on click(e) {
		e.preventDefault();
	}

	on touchstart(e) {
		e.preventDefault();
		var x = e.originalEvent.touches[0].pageX;
		var y = e.originalEvent.touches[0].pageY;
		if(x > 50) {
			this.mathSelf().cursor.seek($(this),x,y);
		}
	}

	on touchmove(e) {
		e.preventDefault();
		return;
		var x = e.originalEvent.touches[0].pageX;
		var y = e.originalEvent.touches[0].pageY;
		this.mathSelf().cursor.seek($(this),x,y);	
	}
}

def SmallMathInput {
	extends {
		MathInput
	}

	method empty {
		return this.contents() == '';
	}

	css {
		width: 100%;
		display: table;
		line-height: 30px;
		min-height: 30px;
		background: #FFF;
		padding-top: 20px;
		padding-bottom: 20px;
		font-size: 25px;
		border-bottom: 2px solid #EEE;
		box-shadow: 1px 1px 2px rgba(0,0,0,0.2);
		text-shadow: 1px 1px 10px rgba(0,0,0,0.1);
	}

	constructor {

	}
}

def MathTextField(focusManager) {

	html {
		<div>
		</div>
	}

	constructor {
		this.enabled = true;
		this.input = elm.create('SmallMathInput').named('input');
		this.input.$.on('update',this.#updated);
		if(this.focusManager) this.focusManager.register(this);
		$this.append(this.input);
	}

	method updated {
		if($this.parents('.ListView')) {
			// Do as I say, not as I do.
			$this.parents('.ListView').get(0) ? $this.parents('.ListView').get(0).updateScroll() : 0;
		}
		$this.trigger('update');
	}

	on click {
		if(!this.enabled) {
			return;
		}
		this.focusManager.setFocus(this);
		this.mathSelf().cursor.show();
	}

	on touchstart {
		if(!this.enabled) {
			return;
		}
		this.focusManager.setFocus(this);
		this.mathSelf().cursor.show();
	}

	method mathSelf() {
		return this.input.mathSelf();
	}

	method contents() {
		return this.input.contents();
	}

	method setContents(c) {
		return this.input.setContents(c);
	}

	method empty {
		return this.input.empty();
	}

	method disable() {
		var contents = this.contents();
		this.enabled = false;
		this.input.$.mathquill('revert');
		this.input.$.html(contents);
		this.input.$.mathquill();
	}

	method enable {
		this.enabled = true;
		this.input.$.mathquill('editable');
	}

	method acceptLatexInput(input) {
		this.mathSelf().cursor.show();
		return this.input.acceptLatexInput(input);
	}

	method acceptActionInput(input) {
		return this.input.acceptActionInput(input);
	}

	method takeFocus {
		this.focusManager.setFocus(this);
	}

	method loseFocus {
		return this.input.loseFocus();
	}
}