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

	on displayed {
		app.help.introduce('repl',200);
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
			this.current.@output.$contents.html(out)
			this.current.$output.show();
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
			height: 8%;
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
			font-weight: normal;
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

	extends {
		TouchInteractive
	}

	css {
		margin-bottom: 40px;
		position: relative;
	}

	my arrow {
		css {
			position: absolute;
			top: 10px;
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
		this.parent('REPL').storeLine(this.@input.contents(),this.@output.$contents.html());
	}

	method evaluate() {
		var text = this.@input.contents();
		try {
			var p = new Parser();
			var res = p.parse(text);
			res = res.valueOf(new Frame({}));
			app.data.variables.ans = res;
			if(res instanceof Frac && app.data.displayDecimalizedFractions) {
				res = res.decimalize();
			}
			this.@output.$contents.html(res.toString());
		} catch(e) {
			this.@output.$contents.html(e);
		}
		this.$output.show();
	}
}

def REPLInput(focusManager,repl) {
	extends {
		MathTextField
	}

	css {
		padding-right: 10px;
	}

	constructor {
		this.effect = elm.create('REPLHoldEffect',0.5);
		this.$.append(this.effect);
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
			this.parent('REPL').doUpdateScroll();
		}
	}

	on begin {
		if(!this.enabled) {
			this.effect.run();
		}
	}

	on end {
		this.effect.cancel();
	}

	on hold {
		if(!this.enabled) {
			var parent = this.parent('REPL');
			parent.current.@input.setContents(this.@input.contents());
			parent.current.@input.mathSelf().cursor.show();
			parent.doUpdateScroll(100);
		}
	}
}

def REPLOutput {
	html {
		<div></div>
	}

	contents {
		<span class='contents'><span>
	}

	constructor {
		this.effect = elm.create('REPLHoldEffect',0.5);
		this.$.append(this.effect);

	}

	extends {
		TouchInteractive
	}

	on begin {
		this.effect.run();
	}

	on end {
		this.effect.cancel();
	}

	on hold {
		var val = root.$contents.html().split('{').join('<').split('}').join('>');
		var res = new Parser().parse(val).valueOf(new Frame());
		app.data.initVariableSave('store',res);
		app.useKeyboard('variables');
	}

	css {
		position: relative;
		box-sizing: border-box;
		font-size: 14pt;
		padding: 10px;
		padding-left: 20px;
		color: #333;
		background: #CCC;
		opacity: 0.75;
	}
}

def REPLButton(text) {
	extends {
		LiveEvalButton
	}

	css {
		display: inline-block;
		font-size: 10px;
		text-shadow: none;
		padding: 5px;
	}

	style default {
		text-shadow: none;
		background: none;
	}
}

def REPLHoldEffect(time) {
	html {
		<div></div>
	}

	css {
		position: absolute
		top: 0px
		left: 0px
		opacity: 0;
		background: rgba(0,0,0,0.1);
	}

	method run {
		this.$.css('width',this.$.parent().outerWidth());
		this.$.css('height',this.$.parent().outerHeight());
		this.$.css('translateX', 0 - this.$.parent().outerWidth())
		this.$.css('opacity',1);
		this.$.animate({translateX: 0},this.time * 1000).animate({opacity:0},100);
	}

	method cancel {
		this.$.stop().animate({translateX: 0 - this.$.parent().outerWidth()},100);
	}
}




	
