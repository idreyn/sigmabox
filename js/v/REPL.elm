def REPL {
	extends {
		PageView
	}

	properties {
		sizeOverToolbar: true
	}

	constructor {
		this.load();
	}

	on active {
		self.doUpdateScroll();
	}

	method load {
		app.data.repl.slice(Math.max(app.data.repl.length - 20,0)).forEach(function(line) {
			self.addLine(true,line.input,line.output);
		});
		self.addLine();
		self.doUpdateScroll();
	}

	method addLine(quick,inp,out) {
		this.setPrev(this.current);
		this.current = elm.create('REPLLine',this.focusManager,this);
		this.$contents-container.append(this.current);
		if(!quick) {
			this.current.takeFocus();
			this.updateScroll();
		} else {
			this.current.hideArrow();
		}
		if(inp) {
			this.current.@input.setContents(inp);
			this.current.@input.disable();
		}
		if(out) {
			this.current.@output.$.html(out).show();
		}
	}

	method storeLine(inp,out) {
		app.data.repl.push({input: inp, output: out});
		app.data.serialize();
	}

	method setPrev(e) {
		if(this.prev) {
			this.prev.@output.$.css('opacity','0.75');
		}
		if(e) {
			this.prev = e;
			this.prev.$.css('margin-bottom','0px');
			this.prev.@output.$.css('opacity','1.0');
			this.doUpdateScroll(100);
		}
	}

	method clear {
		this.$REPLLine.remove();
		app.data.repl = [];
		app.data.serialize();
		this.addLine();
		this.doUpdateScroll();
	}

	my top-bar-container {
		css {
			background: none;
			position: absolute;
			bottom: 0px;
			opacity: 1;
			height: 10%;
			text-align: right;
			font-weight: 200;
			padding: 10px;
			padding-left: 0px;
			z-index: 1;
		}
	}

	my title {
		css {
			display: none
		}
	}

	my top-bar {
		css {
			height: 100%;
		}

		contents {
			[[fracSwitch:Switch 'DEC','FRC','app.data.displayDecimalizedFractions']]
			[[trigSwitch:Switch 'RAD','DEG','app.data.trigUseRadians']]
			[[clearBtn:LiveEvalButton 'CLR']]
		}		

		constructor {
			this.$Switch.on('flipped',function() {
				if(root.prev) {
					root.prev.evaluate();
					root.doUpdateScroll();
				}
			});

			this.@clearBtn.$.on('invoke',function() {
				app.confirm('Are you sure?','Clear all calculation history?',function() {
					root.clear();
				},'Clear','Cancel');
			});
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

	method doUpdateScroll(n) {
		n = n || 0;
		this.updateScroll();
		setTimeout(function() {
			self.scroll.scrollTo(0,self.scroll.maxScrollY,n);
		},10);
	}
}

def REPLLine(focusManager,repl) {
	html {
		<div>
			<img class='arrow' src='res/img/repl-arrow.png' width='15px' height='20px' />
		</div>
	}

	css {
		margin-bottom: 40px;
		position: relative;
	}

	my arrow {
		css {
			position: absolute;
			top: 15px;
			left: 4px;
			opacity: 0.7;
		}
	}

	method showArrow {
		this.$arrow.stop().css('translateX',-20).css('opacity',0).animate({
			'translateX': 0,
			'opacity': 0.2
		},500,'easeOutQuart');
	}

	method hideArrow {
		this.$arrow.stop().animate({
			'opacity': 0
		},100,'easeOutQuart');
	}

	constructor {
		this.$.append(elm.create('REPLInput',this.focusManager,this.repl).named('input'));
		this.$.append(elm.create('REPLOutput').named('output'));
		this.@output.$.hide();
		this.showArrow();
	}

	method takeFocus {
		this.@input.takeFocus();
	}

	method done {
		this.parent('REPL').addLine();
		this.@input.disable();
		this.evaluate();
		this.hideArrow();
		this.parent('REPL').storeLine(this.@input.contents(),this.@output.$.html());
	}

	method evaluate() {
		var text = this.@input.contents();
		try {
			var p = new Parser();
			var res = p.parse(text);
			res = res.valueOf(new Frame({}));
			if(res instanceof Vector && app.data.displayPolarVectors) {
				res = res.toStringPolar(app.data.trigUseRadians);
			}
			if(res instanceof Frac && app.data.displayDecimalizedFractions) {
				res = res.decimalize();
			}
			this.@output.$.html(res.toString());
		} catch(e) {
			this.@output.$.html(e);
		}
		this.@output.$.show();
	}
}

def REPLInput(focusManager,repl) {
	extends {
		MathTextField
	}

	css {
		padding-right: 10px;
	}

	my MathInput {
		css {
			border: none;
			background: none;
			box-shadow: none;
			padding: 10px;
			padding-left: 20px;
		}

		method onEqualsSign {
			if(this.contents().length > 0) {
				this.parent('REPLLine').done();
			}
		}

		on update {
			// this.parent('REPLLine').evaluate(this.contents());
			this.parent('REPL').doUpdateScroll();
		}
	}
}

def REPLOutput {

	html {
		<div></div>
	}

	extends {
		TouchInteractive
	}

	css {
		font-size: 14pt;
		padding: 10px;
		color: #333;
		background: #CCC;
		opacity: 0.75;
		padding-left: 20px;
	}

	on invoke {
		var val = self.$.html().split('{').join('<').split('}').join('>');
		var res = new Parser().parse(val).valueOf(new Frame());
		app.data.initVariableSave('store',res);
		app.useKeyboard('variables');
	}
}
