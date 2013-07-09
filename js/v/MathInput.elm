def MathInput(owner) {
	
	html {
		<span></span>
	}
	
	constructor {
		$this.mathquill('editable');
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
	
	method takeFocus {
		this.mathSelf().focus();
		this.mathSelf().cursor.show();
	}

	method loseFocus {
		this.mathSelf().blur();
		this.mathSelf().cursor.hide();
	}
	
	method contents {
		return $this.mathquill('latex');
	}
	
	method mathSelf {
		return $this.mathquill('get');
	}
	
	method acceptLatexInput(input) {
		$this.mathquill('write',input);
		$this.trigger('update');
	}

	method setContents(input) {
		$this.html('');
		$this.mathquill('latex',input);
	}
	
	method acceptActionInput(type) {
		var self = this;
		type.split(',').forEach(function(t) {
			switch(t) {
				case 'left':
					self.mathSelf().cursor.moveLeft();
					break;
				case 'right':
					self.mathSelf().cursor.moveRight();
					break;
				case 'backspace':
					self.mathSelf().cursor.backspace();
					break;
				case 'clear':
					$this.mathquill('latex','');
			
			}
		});
		$this.trigger('update');
	}

	on keyup(e) {
		e.preventDefault();
		$this.trigger('update');
	}
	
	on click(e) {
		e.preventDefault();
	}

	on touchstart(e) {
		e.preventDefault();
		var x = e.originalEvent.touches[0].pageX;
		var y = e.originalEvent.touches[0].pageY;
		this.mathSelf().cursor.seek($(this),x,y);
	}

	on touchmove(e) {
		return
		e.preventDefault();
		var x = e.originalEvent.touches[0].pageX;
		var y = e.originalEvent.touches[0].pageY;
		this.mathSelf().cursor.seek($(this),x,y);	
	}
}

def MathTextfield(fm) {

	extends {
		MathInput
	}

	constructor {
	}

	on click {
		this.fm.setFocus(this);
		this.mathSelf().cursor.show();
	}

	on touchstart {
		this.fm.setFocus(this);
		this.mathSelf().cursor.show();
	}

	method empty {
		return this.contents().length === 0;
	}

	method takeFocus {
		// this.fm.setFocus(this);
	}

	css {
		width: 100%;
		height: 30px;
		background: #FFF;
		padding-top: 20px;
		padding-bottom: 20px;
		font-size: 25px;
		border-bottom: 2px solid #EEE;
		box-shadow: 1px 1px 2px rgba(0,0,0,0.2);
	}
}