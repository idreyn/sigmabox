def LinearSolveView {
	extends {
		ListView
	}

	properties {
		noKeyboard: true,
		autoAddField: false,
		fieldType: 'LinearSolveField'
	}

	on ready {
		this.setup(2);
	}

	method setup(dim) {
		if(this.scroll) this.scroll.scrollTo(0,0,0);
		this.dimension = dim;
		this.$LinearSolveField.remove();
		for(var i=0;i<dim;i++) {
			var f = this.addField();
			f.setup(dim,i);
		}
		this.changed = false;
		this.updateScroll(true);
	}

	method numberPicked {
		this.changed = true;
	}

	method solve {
		var m = new Matrix(self.$LinearSolveField.toArray().map(function(line) {
			return line.$InlineNumberPicker.toArray().map(function(input) {
				return input.data;
			});
		}));
		var res = Functions.solveLinearSystem(m);
		app.overlay(elm.create('LinearSolveOverlay',res));
	}


	my toolbar {
		contents {
			[[dimension-button:ToolbarButtonDropdown '2x2']]
			[[reset-button:ToolbarButton 'Reset']]
			[[solve-button:ToolbarButtonImportant 'Solve', root.solve]]
		}

		my dimension-button {
			properties {
				autoLabel: false
			}

			my dropdown {
				constructor {
					this.setOptions(['2x2','3x3','4x4','5x5','6x6']);
				}
			}

			on select(e,text) {
				if(root.changed) {
					app.confirm('Are you sure?',"You'll lose all current input.",function() {
						root.setup(parseInt(text.split('x')[0]));
						self.setLabel(text);
					});
				} else {
					root.setup(parseInt(text.split('x')[0]));
					self.setLabel(text);
				}
			}
		}

		my reset-button {
			on invoke {
				app.confirm('Are you sure?','Are you sure you want to reset all fields?',function() {
					root.setup(root.dimension);
					root.changed = false;
				});
			}
		}
	}

	constructor {
		this.$title.html('Linear solver');
	}
}

def LinearSolveField {
	extends {
		SimpleListItem
	}

	css {
		line-height: 45px;
	}

	contents {
		<div class='container'></div>
	}

	constructor {
		this.variables = ['x','y','z','u','v','w'];
		this.enabled = false;
	}

	method setup(dim,index) {
		if(index % 2 == 1) {
			this.setStyle('default','background','#F5F5F5');
			this.applyStyle('default');
		}
		if(app.utils.tabletMode()) {

		} else {
			$this.css('font-size',(22 - 2 * dim).toString() + 'px');
		}
		this.$container.html('');
		for(var i=0;i<dim;i++) {
			var v = this.variables[i];
			var p = elm.create('InlineNumberPicker');
			p.choose(i == index ? 1 : 0);
			p.$.on('choose',function() {
				self.parent('LinearSolveView').numberPicked();
			});
			this.$container.append(p);
			this.$container.append(' ' + v + ' ');
			if(i != dim - 1) {
				this.$container.append('<b> + </b>');
			}
		}
		this.$container.append('<b> = </b>');
		var c = elm.create('InlineNumberPicker');
		c.choose(1);
		c.$.on('choose',function() {
			self.parent('LinearSolveView').numberPicked();
		});
		this.$container.append(c);
	}
}

def LinearSolveOverlay(solutions) {
	extends {
		PageView
		Overlay
	}

	css {
		background: #FFF;
	}

	constructor {
		this.variables = ['x','y','z','u','v','w'];
		this.$title.html('Solution');
		this.display();
		this.behindKeyboard();
	}

	method display {
		if(this.solutions.length == 0) {
			this.$empty-notice.show();
		} else {
			for(var i=0;i<this.solutions.length;i++) {
				var l = this.create('line-item');
				l.$.append(this.variables[i] + ' <b>=</b> ');
				var n = elm.create('InlineNumber');
				n.roundTo = 6;
				n.display(this.solutions[i]);
				l.$.append(n);
				this.$contents-container.append(l);
			}
		}
	}

	method exportVars {
		var relevantVars = self.variables.slice(0,self.solutions.length).map(function(s) { return '<i>' + s + '</i>'; });
		if(relevantVars.length > 1) {
			var last = relevantVars.pop();
			relevantVars = relevantVars.join(', ') + ' and ' + last; 
		}
		app.confirm('Are you sure?','Assign these values to ' + relevantVars + '?',function() {
			for(var i=0;i<self.solutions.length;i++) {
				app.data.setVariable(self.variables[i],self.solutions[i]);
			}
		});
	}

	properties {
		overlaySourceDirection: 'bottom'
	}

	method cancel {
		$this.trigger('removed');
	}

	my toolbar {
		contents {
			[[export-button:ToolbarButton 'Export variables', root.exportVars]]
			[[close-button:ToolbarButtonImportant 'Close', root.cancel]]
		}
	}

	contents {
		<div class='empty-notice'>There is no unique solution to this system.</div>
	}

	my line-item {
		html {
			<div></div>
		}

		css {
			padding: 10px;
		}
	}

	my empty-notice {
		css {
			position: absolute;
			width: 100%;
			text-align: center;
			top: 50%;
			color: #999;
			display: none;
		}
	}
}