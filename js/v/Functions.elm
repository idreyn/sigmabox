def FunctionListView {
	extends {
		ListView
	}

	properties {
		fieldType: 'FunctionField',
		addFieldToTop: true
	}

	constructor {
		this.$top-bar-container.hide();
		this.$title.html('Functions');
		this.load();
	}

	method load {
		for(var k in app.storage.customFunctions) {
			var func = app.storage.customFunctions[k];
			var field = this.addField();
			field.load(func);
		}
	}
}

def FunctionField(fm) {
	extends {
		MathTextField
	}

	css {
		position: relative;
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
	}

	method load(func) {
		this.functionName = func.name;
		this.setContents(
			'\\' + func.name + '(' + func.parameters.join(',') + ')=' + func.body
		);
		this.$name-overlay.hide();
	}

	contents {
		<div class='name-overlay'></div>
		<div class='options-overlay'></div>
	}

	on update {
		app.storage.updateFunction(
			self.functionName,
			self.getParameters(),
			self.getBody()
		);
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
					if(app.storage.isFunctionNameAvailable(name)) {
						if(self.functionName) {
							app.storage.unregisterFunction(self.functionName);
							app.storage.registerFunction(name);
							self.functionName = name;
							self.setContents(
								'\\' + self.functionName + '(' + self.getParameters().join(',') + ')=' + self.getBody()
							);
							self.takeFocus();
							$this.trigger('update');
						} else {
							app.storage.registerFunction(name);
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
		app.storage.unregisterFunction(self.functionName);
		app.storage.serialize();
		var par = self.parent('ListView');
		$this.remove();
		par.updateScroll();
	}

	on mouseenter {
		this.showOptions();
	}

	on mouseleave {
		this.hideOptions();
	}

	method swipeLeft(e) {
		this.parent().$FunctionField.each(function() {
			this.hideOptions();
		});
		this.showOptions();
	}

	method tapped(e) {
		this.parent().$FunctionField.each(function() {
			this.hideOptions();
		});
		this.hideOptions();
	}


	method showOptions {
		this.$options-overlay.stop().fadeIn(50);
	}

	method hideOptions {
		this.$options-overlay.fadeOut(50);
	}

	my name-overlay {
		extends {
			TouchInteractive
		}

		contents {
			<img class='add-icon'/> Add function
		}

		css {
			color: #BBB;
			font-size: 25px;
			padding-left: 10px;
			position: absolute;
			top: 0;
			width: 100%;
			height: 100%;
			line-height: 70px;
			background: #EEE;
			cursor: pointer;
			z-index: 10;
		}

		on invoke {
			parent.setName();
		}

		my add-icon {
			properties {
				src: app.r.image('add')
			}

			css {
				opacity: 0.4;
				width: 30px;
				margin-top: -5px;
				vertical-align: middle
			}
		}
	}

	my options-overlay {
		css {
			display: none;
			position: absolute;
			top: 0;
			right: 0;
			background: #FFF;
			height: calc(100% - 2px);
			line-height: 70px;
		}

		method edit {
			root.setName(true);
		}

		method remove {
			root.askForDelete();
		}

		contents {
			[[edit-button:IconButton 'pen', this.edit]] 
			[[delete-button:IconButton 'close', this.remove]]
		}

		constructor {
			Hammer(this).on('tap',this.#tapped);
		}

		method tapped(e) {
			e.stopPropagation();
		}

		my add-icon {
			properties {
				src: app.r.image('add')
			}

			css {
				opacity: 0.4;
				width: 30px;
				margin-top: -5px;
				vertical-align: middle
			}
		}

		contents {
			&nbsp;
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

	method populate {
		var funcs = app.storage.customFunctions;
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

	css {

	}
}