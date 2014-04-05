def FunctionListView {
	extends {
		ListView
	}

	properties {
		fieldType: 'FunctionField',
		addFieldToTop: true,
		autoAddField: false,
		defaultText: 'Custom functions you create will appear here.'
	}

	constructor {
		this.$title.html('Functions');
		this.load();
	}

	method load {
		for(var k in app.data.customFunctions) {
			var func = app.data.customFunctions[k];
			var field = this.addField();
			field.load(func);
		}
	}

	method createField {
		var l = self.addField();
		l.setName();
	}

	method sortOn(field,invert) {
		var n = 1 * (invert? -1 : 1);
		if(field == this._lastSortField) {
			n *= -1;
			this._lastSortField = null;
		} else {
			this._lastSortField = field;
		}
		this.$FunctionField.sortElements(function(a,b) {
			return a[field] > b[field] ? n  : (0 - n)
		});
	}

	my toolbar {
		contents {
			[[sort-az-button:ToolbarButton 'A&rarr;Z']]
			[[add-button:ToolbarButtonImportant 'Add']]
		}
	}

	my add-button {
		on invoke {
			root.createField();
		}
	}

	my sort-az-button {
		on invoke {
			root.sortOn('functionName');
		}
	}

	my sort-date-button {
		on invoke {
			root.sortOn('dateCreated',true);
		}
	}
}

def FunctionField(focusManager) {
	extends {
		MathTextField
		PullHoriz
	}

	css {
		position: relative;
	}

	properties {
		pullMaxWidth: 120,
		pullConstant: 50
	}

	constructor {
		self.input.preventInput = function(input) {
			return input == '=';
		}
		self.input.afterInput = function(oldC,newC) {
			var r = new RegExp('^' + '\\\\' + self.functionName + '\\(' + '.*' + '\\)' + '=' + '.*');
			if(!r.test(newC)) {
				self.setContents(oldC);
			}
		}
		Hammer(this).on('dragleft',this.#swipeLeft);
		Hammer(this).on('tap',this.#tapped);
		var options = [
			{color: '#0a4766', event: 'rename', label: app.r.image('pen')},
			{color: '#a33', event: 'delete', label: app.r.image('close')}
		];
		this.$.append(elm.create('PullIndicatorHoriz',options,this).named('indicator'));
	}

	method load(func) {
		this.functionName = func.name;
		this.dateCreated = func.date;
		this.setContents(
			'\\' + func.name + '(' + func.parameters.join(',') + ')=' + func.body
		);
	}

	contents {

	}

	on update {
		app.data.updateFunction(
			self.functionName,
			self.getParameters(),
			self.getBody()
		);
	}

	on delete {
		this.askForDelete();
	}

	on rename {
		this.setName(true);
	}

	method getParameters {
		var c = this.contents();
		return c.slice(
			c.indexOf('(') + 1,
			c.indexOf(')')
		).split(',');
	}

	method getBody {
		return this.contents().split('=').pop();
	}

	method setName(rename) {
		app.prompt(
			rename? 'Rename this function' : 'Name a new function',
			function(name,closePrompt,renameAndTryAgain) {
				name = StringUtil.trim(name);
				if(name.match(/^[A-Za-z][A-Za-z0-9]*$/)) {
					if(app.data.isNameAvailable(name)) {
						if(self.functionName) {
							app.data.unregisterFunction(self.functionName);
							app.data.registerFunction(name);
							self.functionName = name;
							self.setContents(
								'\\' + self.functionName + '(' + self.getParameters().join(',') + ')=' + self.getBody()
							);
							self.takeFocus();
							$this.trigger('update');
						} else {
							app.data.registerFunction(name);
							self.$name-overlay.hide();
							self.setContents('\\'+name+'(x)=');
							self.functionName = name;
							self.takeFocus();
						}
						closePrompt();
					} else {
						renameAndTryAgain("That name is reserved or in use. Try again?");
					}
				} else {
					renameAndTryAgain("Invalid function name. Try again?");
				}
			},
			self.functionName
		);
	}

	method askForDelete {
		app.confirm(
			'Delete?',
			'Are you sure you want to delete this function?',
			this.doDelete,
			'Delete',
			'Cancel'
		);
	}

	method doDelete {
		app.data.unregisterFunction(self.functionName);
		app.data.serialize();
		var par = self.parent('ListView');
		$this.remove();
		par.updateScroll();
	}

	my MathInput {
		style okay {
			background: #FFF;
		}

		style error {
			background: rgba(255,0,0,0.2);
		}
	}
}

def FunctionChoiceView(callback) {
	extends {
		ListView
		Overlay
	}

	properties {
		fieldType: 'SimpleListItem',
		autoAddField: false
	}

	constructor {
		this.$title.html('Choose a function');
		this.populate();
	}

	method populate {
		var funcs = app.data.customFunctions;
		for(var k in funcs) {
			var func = funcs[k];
			var f = this.addField();
			f.$.html(func.name + '(' + func.parameters.join(',') + ')');
			f.$.on('invoke',self.choose)
			f.myFunction = func;
		}
	}

	method choose(e) {
		var func = e.target.myFunction;
		self.callback(func);
		self.cancel();
	}

	method cancel {
		$this.trigger('removed');
	}

	my contents-container {
		css {
			background: #F00;
		}
	}

	my toolbar {
		contents {
			[[ToolbarButton 'Cancel', root.cancel]]
		}
	}
}