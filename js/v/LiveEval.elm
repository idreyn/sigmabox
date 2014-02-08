def LiveEvalCard {
	html {
		<div> 
			<div class='upper'> 

			</div>
			<div class='toolbar'>

			</div>
			<div class='lower'>

			</div>
		</div>
	}
	
	css {
		width: 100%;
	}

	on touchmove(e) {
		e.preventDefault();
	}
	
	method init {
		var self = this;
		this.fm = new FocusManager();
		this.spanInput = elm.create('MathInput',this);
		this.spanInput.$.on('update', function() {
			self.refresh();
		});
		this.fm.setFocus(this.spanInput);
		this.$upper.append(this.spanInput);
		this.refresh();
		this.size();
	}
	
	method input {
		return this.fm.getCurrent();
	}
		
	method size {
		$this.css('height',$this.parent().css('height'));
		this.$upper.css('height','80%');
		this.$lower.css('height','20%');
		this.$toolbar.css('height','10%');
		this.$MathInput.css('width',
			parseInt($this.css('width')) - 2 * parseInt(this.$MathInput.css('padding'))
		).css('font-size',
			Math.min(
				Math.min(
					this.$MathInput.height() / 5,
					this.$MathInput.width() / 12
				)
			,40) + 'px'
		);
		this.$lower.css('font-size',
			parseInt(this.$lower.height() / 2) + 'px'
		).css('line-height',
			parseInt(this.$lower.height() / 1) + 'px'
		);
		this.@toolbar.size();
	}

	method setContents(str) {
		this.spanInput.acceptActionInput('clear');
		this.spanInput.acceptLatexInput(str);
	}

	method refresh(b) {
		this.update(this.spanInput.contents() || '',b);
		app.storage.currentInput = this.spanInput.contents();
		app.storage.serialize();
	}
	
	method update(str,force) {
		if(this.last == str && !force) return;
		this.@toolbar.trigSwitch.hide();
		this.@toolbar.vectorSwitch.hide();
		this.@toolbar.fracSwitch.hide();
		app.storage.trigInCurrentExpression = false;
		app.storage.calcInCurrentExpression = false;
		try {
			var res = app.parser.parse(str,true);
			if(res instanceof Solver) {
				try {
					res = res.toString();
				} catch(e) {
					res = e;
				}
			} else {
				res = res.valueOf(new Frame({}));
				this._result = res;
				if(res instanceof Matrix) {
					res = res.toString();
				}
				if(res instanceof Vector) {
					if(res.args.length == 2) {
						this.@toolbar.vectorSwitch.show();
						if(!app.storage.displayPolarVectors) {
							res = res.toString();
						} else {
							this.@toolbar.trigSwitch.show();
							res = res.toStringPolar(app.storage.trigUseRadians);
						}
					} else {
						if(res.args.length <= 10) {
							res = res.toString();
						} else {
							res = '{' + res.args.length + ' item vector}';
						}
					}
				} else if(res instanceof Frac) {
					this.@toolbar.fracSwitch.show();
					if(!app.storage.displayDecimalizedFractions) {
						res = res.toString();
					} else {
						res = res.decimalize().toString();
					}
				} else if(res instanceof Value) {
					if(res.complex != 0) {
						res = res.toString(4);
					} else {
						res = res.toString(16);
					}
				} else  {
					res = res.toString();
				}
			}
		} catch(e) {
			console.log(e);
			var res = typeof e == 'string' ? e : 'Error';
		}
		if(app.storage.trigInCurrentExpression) {
			this.@toolbar.trigSwitch.show();
		}
		if(app.storage.calcInCurrentExpression) {
			console.log('calc')
			this.@toolbar.trigSwitch.forceRadians();
		} else {
			this.@toolbar.trigSwitch.endForceRadians();
		}
		this.$lower.html(res);
		this.last = str;
	}

	method result {
		return this._result;
	}

	method askForX {
		var prompt = app.mathPrompt('x = ?',function() {
			self.fm.setFocus(self.spanInput);
			var c = prompt.@input.contents()
			var p = new Parser();
			var res = p.parse(c).valueOf(new Frame());
			app.storage.setVariable('x',res,true);
			self.refresh(true);
		},self.fm);
		prompt.cancelCallback = function() {
			self.fm.setFocus(self.spanInput);
		}
	}
	
	find .upper {
		css {
			height: 80;
			width: 100%;
			overflow-y: scroll;
			overflow-x: hidden;
		}
	}
	
	find .input {
		css {
			outline: none;
			width: 100%;
			max-width: 100%;
			border: 0px;
			padding: 20px;
			background: transparent;
			font-size: 40pt;
		}
	}
	
	find .lower {
		css {
			background: rgba(0,0,0,0.05);
			text-align: right;
			padding-right: 2%;
			font-size: 30pt;
			color: #AAA;
			line-height: 80px;
		}
	}

	my toolbar {

		html {
			<div>Hello</div>
		}

		css {
			color: #000;
			position: absolute;
			top: 67%;
			padding-top: 5px;
			padding-bottom: 10px;
			text-align: right;
			padding-right: 4%;
			height: 100%;
			width: 100%;
			vertical-align: middle;
			opacity: 0.5;
		}

		constructor {

			// this.convertButton = elm.create('LiveEvalButton','A&rarr;B');
			// this.$.append(this.convertButton);

			this.fracSwitch = elm.create('Switch','DEC','FRC','app.storage.displayDecimalizedFractions');
			this.fracSwitch.$.on('flipped',function() {
				root.refresh(true);
			});
			this.$.append(this.fracSwitch);


			this.trigSwitch = elm.create('TrigSwitch','RAD','DEG','app.storage.trigUseRadians');			
			this.trigSwitch.$.on('flipped',function() {
				root.refresh(true);
			});
			this.$.append(this.trigSwitch);

			this.vectorSwitch = elm.create('Switch','R\u2220\u03B8','< >','app.storage.displayPolarVectors');
			this.vectorSwitch.$.on('flipped',function() {
				root.refresh(true);
			});
			this.$.append(this.vectorSwitch);

			this.evalButton = elm.create('LiveEvalButton','EVAL');
			this.evalButton.$.on('invoke',function() {
				root.askForX();				
			});

			this.$.append(this.evalButton);

			this.storeButton = elm.create('LiveEvalButton','STO');
			this.storeButton.$.on('invoke',function() {
				if(!app.storage.varSaveMode) {
					app.storage.initVariableSave();
					app.useKeyboard('variables');
				}
			});
			this.$.append(this.storeButton);

			this.clearButton = elm.create('LiveEvalButton','CLR');
			this.clearButton.$.on('invoke',function() {
				app.mode.currentInput().acceptActionInput('clear');
			});
			this.$.append(this.clearButton);

			this.size();
		}

		method size {
			var self = this;
			this.$.children().each(function() {
				if(this.size) {
					this.size(self.$.height());
				}
			});
		}

	}
}

def LiveEvalManager {
	
	html {
		<div> 
			<div class='middle'>
				<div class='inner'> </div>
			</div>
		</div>
	}
	
	css {
		width: 100%;
		height: 100%;
		-webkit-overflow-scrolling: touch;
		overflow: hidden;
	}
	
	find .inner {
		css {
			width: 100%;
			height: 100%;
			position: relative;
			overflow: hidden;
		}
	}
	
	find .middle {
		css {
			width: 100%;
			height: 100%;
			position: relative;
			overflow: hidden;
		}
	}
		
	constructor {

	}
	
	method init() {
		//this.addCard();
		this.size();
	}

	on syncReady {
		this.addCard(app.storage.currentInput || '');
		this.size();
	}
	
	method size(i) {
		i = i || this.screenFraction || 0.5;
		$this.css(
			'height',
			utils.viewport().y * i
		).css(
			'top',
			0
		);
		$this.find('.LiveEvalCard').each(function() { this.size(); });
		this.screenFraction = i;
	}
	
	method addCard(str) {
		var c = elm.create('LiveEvalCard'),
			self = this;
		this.$inner.append(c);
		c.init();
		if(str) c.setContents(str);
		this.currentCard = c;
	}
	
	method currentInput() {
		return this.currentCard.input();
	}

	method result() {
		return this.currentCard.result();
	}

	extends {
		SyncSubscriber
	}
	
}
		