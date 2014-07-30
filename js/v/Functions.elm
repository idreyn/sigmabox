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
		var functionsExist = false;
		for(var k in app.data.customFunctions) {
			functionsExist = true;
			var func = app.data.customFunctions[k];
			var field = this.addField();
			field.load(func);
		}
		if(!functionsExist) {
			this.$empty-notice.show();
		}
	}

	method createField {
		var l = self.addField();
		l.setName();
	}

	method sortOn(field,invert) {
		var n = 1 * (invert? -1 : 1);
		this.$FunctionField.sortElements(function(a,b) {
			return a[field] > b[field] ? n  : (0 - n)
		});
	}

	my toolbar {
		contents {
			[[sort-button:ToolbarButtonDropdown 'Sort']]
			[[add-button:ToolbarButtonImportant 'Add']]
		}

		my sort-button {
			properties {
				autoLabel: false
			}

			constructor {
				this.setOptions(['A to Z','Z to A','Newest','Oldest']);
			}

			on select(e,text) {
				if(text == 'A to Z') root.sortOn('functionName');
				if(text == 'Z to A') root.sortOn('functionName',true);
				if(text == 'Oldest') root.sortOn('dateCreated');
				if(text == 'Newest') root.sortOn('dateCreated',true);
			}
		}
	}

	my add-button {
		on invoke {
			root.createField();
		}
	}

	my empty-notice {
		contents {
			Tap <i>Add</i> above to define a function.
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

	on gain-focus {
		app.help.introduce('custom-functions');
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
			self.functionName,
			function() {
				if(!rename) {
					self.doDelete();
				}
			}
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
		var parent = self.parent('ListView');
		$this.remove();
		parent.updateScroll();
		if(app.data.customFunctions.length == 0) {
			parent.$empty-notice.show();
		}
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

	my empty-notice {
		contents {
			You can define custom functions in the Functions module.
		}
	}

	method populate {
		var funcs = app.data.customFunctions;
		var any = false;
		for(var k in funcs) {
			any = true;
			var func = funcs[k];
			var f = this.addField();
			f.$.html(func.name + '(' + func.parameters.join(',') + ')');
			f.$.on('invoke',self.choose)
			f.myFunction = func;
		}
		if(!any) {
			this.$empty-notice.show();
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