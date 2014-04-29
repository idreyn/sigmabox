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
		this.$contents-container.append(this.current);
		this.current.takeFocus();
		this.updateScroll();
	}

	method addOutput(o) {
		var output = elm.create('REPLOutput',this.focusManager,this);
		output.setContents(o);
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
}

def REPLInput(focusManager,repl) {
	extends {
		MathTextField
	}


	my MathInput {
		css {
			border: none;
			background: none;
			box-shadow: none;
			height: 40px;
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
		}
	}
}

def REPLOutput(fm,repl) {
	extends {
		REPLInput
	}

	constructor {
		this.disable();
	}

	css {
		background: rgba(0,255,0,0.1);
	}
}
