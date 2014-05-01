def LiveEvalCard(manager) {
	html {
		<div> 
			<div class='history-pull'></div>
			<div class='upper'> 
			</div>
			<div class='toolbar'>

			</div>
			<div class='lower'>

			</div>
		</div>
	}

	extends {
		TouchInteractive
		Pull
		SyncSubscriber
	}

	constructor {
		Hammer(this).on('dragstart',this.#dragStart);
		Hammer(this).on('dragend',this.#dragEnd);
		this.subscribeEvent('variable-update');
	}

	properties {
		pullMaxHeight: 100
		pullConstant: 50
	}
	
	css {
		position: relative;
		display: block;
		width: 100%;
	}

	style animated {
		-webkit-transition: -webkit-transform 0.2s ease-in-out;
	}

	style not-animated {
		-webkit-transition: none;
	}

	on invoke(e) {
		if(e.target != e.currentTarget) return;
		this.manager.setCurrentCard(this);
	}

	on variable-update {
		self.refresh(true);
	}
	
	method init {
		var self = this;
		this.focusManager = new FocusManager();
		this.spanInput = elm.create('MathInput',this);
		this.spanInput.$.on('update', function() {
			self.refresh();
		});
		this.spanInput.focusManager = this.focusManager;
		this.focusManager.setFocus(this.spanInput);
		this.$upper.append(this.spanInput);
		this.refresh();
		this.size();
	}
	
	method input {
		return this.focusManager.getCurrent();
	}
		
	method size {
		$this.css('height',$this.parent().parent().height());
		this.$upper.css('height','80%');
		this.$lower.css('height','20%');
		this.@lower.size();
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
		this.@toolbar.size();
	}

	method setContents(str) {
		this.spanInput.acceptActionInput('clear');
		this.spanInput.acceptLatexInput(str);
	}

	method refresh(b) {
		this.update(this.spanInput.contents() || '',b);
		app.data.currentInput = this.spanInput.contents();
		app.data.serialize();
	}
	
	method update(str,force) {
		if(this.last == str && !force) return;
		this.@toolbar.trigSwitch.hide();
		this.@toolbar.vectorSwitch.hide();
		this.@toolbar.fracSwitch.hide();
		app.data.trigInCurrentExpression = false;
		app.data.calcInCurrentExpression = false;
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
					res = res.toString(true);
				}
				if(res instanceof Vector) {
					if(res.args.length == 2) {
						this.@toolbar.vectorSwitch.show();
						if(!app.data.displayPolarVectors) {
							res = res.toString();
						} else {
							this.@toolbar.trigSwitch.show();
							res = res.toStringPolar(app.data.trigUseRadians);
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
					if(!app.data.displayDecimalizedFractions) {
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
		if(app.data.trigInCurrentExpression) {
			this.@toolbar.trigSwitch.show();
		}
		if(app.data.calcInCurrentExpression) {
			this.@toolbar.trigSwitch.forceRadians();
		} else {
			this.@toolbar.trigSwitch.endForceRadians();
		}
		this.@lower.setContents(res);
		this.last = str;
	}

	method result {
		return this._result;
	}

	method dragStart(e) {
		this.notAnimated();
	}

	method dragEnd(e) {
		this.animated();
	}

	method animated {
		this.applyStyle('animated');
	}

	method notAnimated {
		this.applyStyle('not-animated');
	}

	on pullStart(e,data) {

	}

	on pullUpdate(e,data) {
		this.@history-pull.update(data.translateY);
	}

	on pullEnd(e,data) {
		if(data.translateY > 90) {
			app.overlay(elm.create('LiveEvalHistoryOverlay', function(res) {
				self.setContents(res);
			}));
		}
	}

	find .upper {
		css {
			height: 80;
			width: 100%;
			overflow-y: hidden;
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

	my lower {
		extends {
			NoSwipe
		}
		
		contents {
			<div class='scroll'></div>
		}

		method setContents(s) {
			var approxChars = this.parent().$.width() / 20 - 3;
			if(s.length > approxChars) {
				this.$.css('font-size','20');
			} else {
				this.$.css('font-size','40');
			}
			if(s == '') s = '0'
			this.$scroll.html(s);
			this.$.css('line-height',this.$.height() + 'px');
			if(!self.scroll) self.scroll = new IScroll(self,{mouseWheel: true, scrollX: true});
			setTimeout(function() {
				self.scroll.refresh();
			},0);
			this.$.show();
		}

		method size {
			this.$.css('line-height',this.$.height() + 'px');
		}

		my scroll {
			css {
				white-space: nowrap;
				padding-left: 10px;
				padding-right: 10px;
				display: inline-block;
			}

			method size {

			}
		}

		css {
			display: none;
			background: rgba(0,0,0,0.05);
			text-align: right;
			font-size: 30pt;
			color: #AAA;
			line-height: 80px;
			overflow: hidden;
			width: 100%:
		}
	}

	my history-pull {
		contents {
			<img class='inner' src='res/img/clock.png'/> &nbsp;History
		}

		css {
			position: absolute;
			width: 100%;
			height: 100px;
			line-height: 100px;
			text-align: center;
			font-size: 20px;
			top: -100px;
			color: #FFF;
			background: #333;
		}

		my inner {
			css {
				width: 40px;
				vertical-align: middle;
			}
		}

		method update(n) {
			var theta = Math.max(0,-20 + 4 * (100 - n));
			this.$inner.css('-webkit-transform','rotate(' + theta + 'deg)');
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

			this.fracSwitch = elm.create('Switch','DEC','FRC','app.data.displayDecimalizedFractions');
			this.fracSwitch.$.on('flipped',function() {
				root.refresh(true);
			});
			this.$.append(this.fracSwitch);


			this.trigSwitch = elm.create('TrigSwitch','RAD','DEG','app.data.trigUseRadians');			
			this.trigSwitch.$.on('flipped',function() {
				root.refresh(true);
			});
			this.$.append(this.trigSwitch);

			this.vectorSwitch = elm.create('Switch','R\u2220\u03B8','< >','app.data.displayPolarVectors');
			this.vectorSwitch.$.on('flipped',function() {
				root.refresh(true);
			});
			this.$.append(this.vectorSwitch);

			this.evalButton = elm.create('LiveEvalButton','SET');
			this.evalButton.$.on('invoke',function() {
				if(!app.data.varSaveMode) {
					app.data.initVariableSave('set');
					app.useKeyboard('variables');
				}
			});

			this.$.append(this.evalButton);

			this.storeButton = elm.create('LiveEvalButton','STO');
			this.storeButton.$.on('invoke',function() {
				if(!app.data.varSaveMode) {
					app.data.initVariableSave('store',root.result());
					app.useKeyboard('variables');
				}
			});
			this.$.append(this.storeButton);

			this.clearButton = elm.create('LiveEvalButton','CLR');
			this.clearButton.$.on('invoke',function() {
				app.data.addHistoryItem(app.mode.currentInput().contents());
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
//			[[indicator:LiveEvalPageIndicator]]
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
			position: relative;
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
		this.size();
	}

	method setupScroll {
		try {
			if(this.scroll) return;
			this.scroll = new IScroll(this.@middle,{mouseWheel: false, startY: 0, snap: true, momentum: false});
			this.scroll.on('scrollEnd',this.#scrollEnd);
		} catch(e) {
			// Shh shh shh just sleep
		}
	}

	method scrollEnd {
		this.setCurrentCard(this.$LiveEvalCard.get(this.scroll.currentPage.pageY));
	//	this.@indicator.select(this.scroll.currentPage.pageY);
	}

	on active {
		this.setupScroll();
	}

	on syncReady {
		this.addCard(app.data.currentInput || '');
		this.setupScroll();
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
//		this.@indicator.size();
		$this.find('.LiveEvalCard').each(function() { this.size(); });
		this.screenFraction = i;
		if(this.scroll) this.scroll.refresh();
	}
	
	method addCard(str) {
		var c = elm.create('LiveEvalCard',this),
			self = this;
		this.@inner.$.append(c);
		c.init();
		if(str) c.setContents(str);
		this.setCurrentCard(c);
		this.size();
		return c;
	}

	method setCurrentCard(c) {
		if(this.currentCard) this.currentCard.input().mathSelf().cursor.hide();
		this.currentCard = c;
		this.currentCard.input().mathSelf().cursor.show();
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
		
def LiveEvalPageIndicator {
	html {
		<div>

		</div>
	}

	css {
		position: absolute;
		top: 0;
		left: 0;
		height: 150px;
		width: 5px;
	}

	constructor {

	}

	method size {
		var factor = 1;
		var height = $this.parent().height() * 1;
		this.$.height(height / factor);
		this.$.css('top',(height - (height / factor))/2);
	}

	method build(n) {
		for(var i=0;i<n;i++) {
			var b = this.create('Blip');
			b.setHeight(($this.height() / n));
			this.$.append(b);
		}
		this.number = n;
	}

	method select(n) {
		this.$Blip.css('opacity',0.1);
		this.$Blip.get(n).$.css('opacity',0.5);
		this.selected = n;
	}

	my Blip {
		html {
			<div> </div>
		}

		css {
			background: #000;
			width: 100%;
			opacity: 0.1;
		}

		method setHeight(h) {
			$this.css('height',h);
		}
	}
}

def LiveEvalHistoryOverlay(callback) {
	extends {
		ListView
		Overlay
	}

	properties {
		overlaySourceDirection: 'top',
		autoAddField: false
	}

	constructor {
		this.populate();
		this.$title.html('History');
	}

	method cancel {
		$this.trigger('removed');
	}

	method populate {
		this.$MathTextField.remove();
		app.data.inputHistory.reverse().forEach(function(item) {
			var f = self.addField();
			f.disable();
			f.setContents(item);
			f.$.on('invoke',self.choose);
		});
	}

	method choose(e) {
		var func = e.target.contents();
		self.callback(func);
		self.cancel();
	}

	method clearHistory {
		app.data.clearHistory();
		app.data.serialize();
		self.populate();
	}

	my toolbar {
		contents {
			[[ToolbarButtonImportant 'Clear History', root.clearHistory]]
			[[ToolbarButton 'Close', root.cancel]]
		}
	}
}