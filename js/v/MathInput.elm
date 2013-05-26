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
	}
	
	method takeFocus {
		this.mathSelf().focus();
		this.mathSelf().cursor.show();
	}
	
	method contents {
		return $this.mathquill('latex');
	}
	
	method mathSelf {
		return $this.mathquill('get');
	}
	
	method acceptLatexInput(input) {
		//console.log('acceptLatex',input);
		$this.mathquill('write',input);
		this.owner.update(this.contents());
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
		this.owner.update(this.contents());
	}
	
	on click {
		$this.find('input').blur();
	}
	
}