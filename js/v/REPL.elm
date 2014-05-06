def REPL {
	extends {
		PageView
	}

	css {
		background: #FFF;
	}

	my contents-container-wrapper {
		contents {
			
		}
	}

	constructor {
		this.addLine();
	}

	method addLine {
		this.current = elm.create('REPLLine',this.focusManager,this);
		this.$contents-container.append(this.current);
		this.current.takeFocus();
		this.updateScroll();
	}

	my top-bar-container {
		css {
			position: absolute;
			bottom: 0px;
			background: rgb(27, 27, 27);
			height: 40px;
			text-align: right;
		}
	}

	my title {
		css {
			display: none
		}
	}

	my top-bar {
		css {
			margin-top: 5px;
			height: 30px;
		}

		contents {
			[[fracSwitch:Switch 'DEC','FRC','app.data.displayDecimalizedFractions']]
			[[trigSwitch:Switch 'RAD','DEG','app.data.trigUseRadians']]
			[[vectorSwitch:Switch 'R\u2220\u03B8','< >','app.data.displayPolarVectors']]
		}

		my Switch {
			css {
				background: #333;
			}

			my label {
				css {
					color: #FFF;
				}
			}
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

	method doUpdateScroll {
		this.updateScroll();
		setTimeout(function() {
			self.scroll.scrollTo(0,self.scroll.maxScrollY,0);
		},10);
	}
}

def REPLLine(focusManager,repl) {
	html {
		<div></div>
	}

	css {

	}

	constructor {
		this.$.append(elm.create('REPLInput',this.focusManager,this.repl).named('input'));
		this.$.append(elm.create('REPLOutput').named('output'));
		this.@output.$.hide();
	}

	method takeFocus {
		this.@input.takeFocus();
	}

	method done {
		this.parent('REPL').addLine();
		this.@input.disable();
		this.evaluate(this.@input.contents());
	}

	method evaluate(text) {
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
	extends {
		SimpleListItem
	}

	constructor {

	}

	style default {
		background: #EEE;
	}

	css {
		padding: 10px;
		padding-left: 20px;
	}
}
