def REPLCard {
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
	
	method init {
		this.size();
		this.spanInput = elm.create('MathInput',this);
		this.$my('upper').append(this.spanInput);
		this.refresh();
	}
	
	method input {
		return this.spanInput;
	}
		
	method size {
		this.my('toolbar').size();
		$this.css('height',$this.parent().css('height'));
		this.$my('upper').css('height','80%');
		this.$my('lower').css('height','20%');
		this.$my('toolbar').css('height','10%');
		this.$my('MathInput').css('width',
			parseInt($this.css('width')) - 2 * parseInt(this.$my('MathInput').css('padding'))
		).css('font-size',
			Math.min(
				Math.min(
					this.$my('MathInput').height() / 5,
					this.$my('MathInput').width() / 12
				)
			,40) + 'px'
		);
		this.$my('lower').css('font-size',
			parseInt(this.$my('lower').height() / 2) + 'px'
		).css('line-height',
			parseInt(this.$my('lower').height() / 1) + 'px'
		)
	}

	method refresh() {
		this.update(this.spanInput.contents() || '');
	}

	
	method update(str) {
		this.my('toolbar').trigSwitch.$.hide();
		this.my('toolbar').vectorSwitch.$.hide();
		app.storage.trigInCurrentExpression = false;
		try{
			var res = app.parser.parse(str,true);
			if(res instanceof Solver) {
				res = res.toString();
			} else {
				res = res.valueOf(new Frame({}));
				this._result = res;
				if(res instanceof Vector) {
					this.my('toolbar').vectorSwitch.$.show();
					if(app.storage.vectorDisplayMode == 'components') {
						res = res.toString();
					} else {
						this.my('toolbar').trigSwitch.$.show();
						res = res.toStringPolar(app.storage.trigMode == 'radians');
					}
				} else if(res instanceof Value) {
					res = res.toString(16);
				} else  {
					res = res.toString();
				}
			}
		} catch(e) {
			var res = (typeof e == 'string')? e : e.toString();
		}
		if(app.storage.trigInCurrentExpression) {
			this.my('toolbar').trigSwitch.$.show();
		}
		this.$my('lower').html(res);
	}

	method result() {
		return this._result;
	}
	
	
	find .upper {
		css {
			height: 80;
			width: 100%;
			background: #FFF;
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
			background: #EEE;
			text-align: right;
			padding-right: 2%;
			font-size: 36pt;
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
			padding-bottom: 5px;
			text-align: right;
			padding-right: 4%;
			display: block;
			height: 100%;
			width: 100%;
			vertical-align: middle;
			background: rgba(255,255,255,0.8);
		}

		constructor {

			// this.convertButton = elm.create('ToolbarButton','A&rarr;B');
			// this.$.append(this.convertButton);

			this.trigSwitch = elm.create('Switch','RAD','DEG');
			this.trigSwitch.$.on('flipped',function(e) {
				app.storage.setTrigMode(e.target.state);
				root.refresh();
			});
			this.$.append(this.trigSwitch);

			this.vectorSwitch = elm.create('Switch','R\u2220\u03B8','< >');
			this.vectorSwitch.$.on('flipped',function(e){
				app.storage.setVectorDisplayMode(e.target.state);
				root.refresh();
			});
			this.$.append(this.vectorSwitch);

			this.storeButton = elm.create('ToolbarButton','&rarr;Aa');
			this.storeButton.$.on('invoke',function() {
				if(!app.storage.varSaveMode) {
					app.storage.initVariableSave();
					app.useKeyboard('variables');
				}
			});
			this.$.append(this.storeButton);

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

def REPLManager {
	
	html {
		<div> 
			<div class='middle'>
				<div class='inner'> </div>
			</div>
		</div>
	}
	
	css {
		position: fixed;
		width: 100%;
		height: 100%;
		background: #CCC;
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
		this.$inner = $this.find('.inner');
	}
	
	method init() {
		this.size();
		this.addCard();
	}
	
	method size(i) {
		i = i || this.screenFraction || 0.5;
		$this.css(
			'height',
			app.utils.viewport().y * i
		).css(
			'top',
			0
		);
		$this.find('.REPLCard').each(function() { this.size(); });
		this.screenFraction = i;
	}
	
	method addCard {
		var c = elm.create('REPLCard');
		this.$inner.append(c);
		c.init();
		this.currentCard = c;
	}
	
	method currentInput() {
		return this.currentCard.input();
	}

	method result() {
		return this.currentCard.result();
	}
	
}
		