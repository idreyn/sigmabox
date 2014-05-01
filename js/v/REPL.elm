def REPL {
	extends {
		PageView
	}

	css {
		background: #FFF;
	}

	constructor {
		this.addInput();
	}

	method addInput {
		if(this.current) this.current.disable();
		this.current = elm.create('REPLInput',this.focusManager,this);
		if(this.$REPLInput.length == 0) {
			this.current.$.css('padding-top','10px');
		}
		this.$contents-container.append(this.current);
		this.current.takeFocus();
		this.updateScroll();
	}

	method addOutput(o) {
		this.current.$.css('padding-bottom','0px');
		var output = elm.create('REPLOutput',this.focusManager,this);
		output.$.html(o);
		this.$contents-container.append(output);
	}

	method evaluate(text) {
		var p = new Parser();
		var res = p.parse(text);
		res = res.valueOf(new Frame({}));
		this.addOutput(res.toString());
		this.addInput();
		this.scroll.refresh();
		this.scroll.scrollTo(0,this.scroll.maxScrollY,200);
	}

	my top-bar-container {
		css {
			display: none;
		}
	}

	method doUpdateScroll {
		this.updateScroll();
		setTimeout(function() {
			self.scroll.scrollTo(0,self.scroll.maxScrollY,200);
		},10);
	}
}

def REPLInput(focusManager,repl) {
	extends {
		MathTextField
	}

	css {
		padding-bottom: 10px;
	}


	my MathInput {
		css {
			border: none;
			background: none;
			box-shadow: none;
			padding: 10px;
			padding-left: 20px;
		}

		on keydown(e) {
			if(e.keyCode == 13) {
				this.parent('REPL').evaluate(root.contents());
			}
		}

		on update {
			var c = this.contents();
			if(c.slice(-1) == '=') {
				c = c.slice(0,-1)
				this.setContents(c);
				this.parent('REPL').evaluate(root.contents());
			}
			this.parent('REPL').doUpdateScroll();
		}
	}
}

def REPLOutput(fm,repl) {
	extends {
		SimpleListItem
	}

	constructor {

	}

	style active {
		background: 
	}

	css {
		background: rgba(0,255,0,0.1);
		padding: 10px;
		padding-left: 20px;
	}
}
