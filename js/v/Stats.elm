def StatsView {
	extends {
		PageView
	}

	properties {
		baseWidth: 160
	}

	constructor {
		Hammer(this).on('swiperight',this.#swiped);
		Hammer(this).on('dragstart',this.#dragStarted);
		Hammer(this).on('dragend',this.#dragEnded);
		this.@title.$.html('Statistics');
		this.load();
	}

	method load {
		app.data.lists.forEach(function(list) {
			var item = self.addList();
			item.setData(list);
		});
	}

	method swiped(e) {
		e.stopPropagation();
	}

	method dragStarted(e) {
		if(!$(e.srcElement).hasClass('top-bar')) {
			self.scroll.disable();
		}
	}

	method dragEnded(e) {
		self.scroll.enable();
	}

	my contents-container {
		css {
			width: 100%;
		}
	}

	my toolbar {
		contents {
			[[tests-button:ToolbarButton 'Tests']]
			[[back-button:ToolbarButton '&larr;']]
			[[next-button:ToolbarButton '&rarr;']]
			[[add-button:ToolbarButtonImportant 'Add']]
		}
	}

	my back-button {
		on invoke {
			if(!root.scroll) return;
			root.scroll.prev();
			var index = Math.floor(Math.abs(root.scroll.x / root.baseWidth)) - 1;
		}
	}

	my next-button {
		on invoke {
			if(!root.scroll) return;
			root.scroll.next();
			var index = Math.floor(Math.abs(root.scroll.x / root.baseWidth)) + 1;
		}
	}

	my add-button {
		on invoke {
			var n = 1;
			while(!app.data.isNameAvailable('List' + n.toString())) n++;
			app.prompt('Name a new list',function(name,close,tryAgain) {
				if(app.data.isNameAvailable(name)) {
					close();
					root.createList(name);
				} else {
					tryAgain('That name is in use. Why not pick another?');
				}
			},'List' + n);
		}
	}

	method createList(name) {
		var list = {name:name,data:[]};
		app.data.lists.push(list);
		app.data.registerFunction(name);
		app.data.serialize();
		var el = this.addList();
		el.setData(list);
		setTimeout(function() {
			self.orderLists();
			self.updateScroll();
			setTimeout(function() {
				self.scroll.scrollToElement(el);
			},10);
		},20);
	}

	method addList {
		var l = elm.create('StatsList',this);
		l.delegateFocus(this);
		this.@contents-container.$.append(l);
		this.selectList(l);
		l.size();
		return l;
	}

	method orderLists {
		var baseWidth = this.baseWidth;
		var numCols = Math.floor(this.$.parent().width() / baseWidth);
		var colWidth = this.$.parent().width() / numCols;
		this.@contents-container.$.css('width',this.$StatsList.length * colWidth);
		this.$StatsList.each(function(i,e) {
			$(this).css('left', Math.floor(i * colWidth));
			$(this).css('width',colWidth);
		});
		setTimeout(function() {
			self.updateScroll(true);
		},10);
	}

	method selectList(l) {
		if(l === null || l === undefined) return;
		if(!isNaN(l)) l = this.$StatsList.get(l);
		if(this.currentList) this.currentList.@top-bar.applyStyle('default');
		this.currentList = l;
		this.currentList.@top-bar.applyStyle('selected');
	}

	method currentInput {
		return this.currentList.currentInput();
	}

	method updateScroll {
		if(!self.$StatsList.length) return;
		if(self.scroll) self.scroll.destroy();
		self.scroll = new IScroll(
			self.@contents-container-wrapper,
			{scrollbars: true, fadeScrollbars: true, mouseWheel: false, scrollX: true, snap: '.StatsList'}
		);
	}

	method remove(element) {
		var l = element.data,
			ind = app.data.lists.indexOf(l);
		app.data.lists = app.data.lists.slice(0,ind).concat(app.data.lists.slice(ind+1));
		app.data.serialize();
		element.$.remove();
		self.orderLists();
	}

	on invalidate {
		this.orderLists();
	}

	my contents-container {
		contents {

		}

		css {
			height: 100%;
		}
	}
}

def StatsList(manager) {
	extends {
		ListView
		Pull
	}

	properties {
		pullMaxHeight: 100,
		pullConstant: 50
	}

	constructor {
		this.fieldType = 'StatsListField';
		var options = [
			{color: '#696', label: 'Stats'},
			{color: '#B6DB49', event: 'define', label: 'Define'},
			{color: '#0A4766', event: 'rename', label: 'Rename'},
			{color: '#A33', event: 'delete', label: 'Delete'}
		];
		this.$.append(elm.create('PullIndicator',options,this).named('indicator'));
	}

	css {
		width: 1000px;
		position: absolute;
		overflow: visible;
	}

	my top-bar {
		css {
			font-size: 16px;
		}
	}

	on invoke {
		this.manager.selectList(this);
	}

	method setData(list) {
		this.data = list;
		this.$top-bar.html(list.name);
		this.$MathTextField.remove();
		list.data.forEach(function(d,i) {
			var f = self.addField(null,false);
			f.setIndex(i);
			f.setData(d);
		})
		this.addField();
	}

	method remove(element) {
		var d = element.data,
			ind = this.data.data.indexOf(d);
		this.data.data = this.data.data.slice(0,ind).concat(this.data.data.slice(ind+1));
		element.$.remove();
		if(this.data.data.length == 0) {
			this.addField();
		}
		app.data.serialize();
	}

	method update {
		this.data.data = this.$StatsListField.map(function(i,e) {
			this.setIndex(i);
			return this.data;
		}).toArray();
		app.data.serialize();
	}

	method updateScroll {
		if(self.scroll) {
			self.scroll.refresh();
		} else {
			self.scroll = new IScroll(
				self.@contents-container-wrapper,
				{scrollbars: true, mouseWheel: true, fadeScrollbars: true, momentum: false}
			);
		}
	}

	on pullStart(e,data) {
		if((data.originY - $this.offset().top) > 50) {
			self.pullCancel = true;
		}
	}

	on delete {
		app.confirm('Really?','Delete this list?',function() {
			self.manager.remove(self);
		});
	}

	on rename {
		app.prompt('Name a new list',function(name,close,tryAgain) {
			if(app.data.isNameAvailable(name)) {
				close();
				self.data.name = name;
				app.data.unregisterFunction(self.data.name);
				app.data.registerFunction(name);
				app.data.serialize();
				self.$top-bar.html(name);
			} else {
				tryAgain('That name is in use. Why not pick another?');
			}
		},self.data.name);
	}

	on define {
		app.mathPrompt('Enter an expression for this list',function(res,close,tryAgain) {
			if(res instanceof Vector) {
				close();
				self.data.data = res.args;
				self.setData(self.data);
			} else {
				tryAgain("That isn't a list. Try again?");
			}
		},this.manager.focusManager);
	}

	my top-bar {
		css {

		}

		style default {
			text-decoration: none;
		}

		style selected {
			text-decoration: underline;
		}
	}

}

def StatsListField(focusManager) {
	extends {
		MathTextField
		PullHoriz
	}

	properties {
		pullMaxWidth: 80,
		pullConstant: 50
	}

	contents {
		<span class='index-label'>Hi<span>
	}

	constructor {
		var options = [
			{color: '#0a4766', event: 'add-under', label: app.res.image('arrow-down')},
			{color: '#a33', event: 'delete', label: app.res.image('close')}
		];
		this.$.append(elm.create('PullIndicatorHoriz',options,this).named('indicator'));
	}

	method setData(d) {
		this.data = d;
		this.setContents(d.toString());
	}

	method setIndex(n) {
		this.$index-label.html((n + 1).toString());
	}

	method remove {
		this.parent('StatsList').remove(this);
	}

	on lost-focus {
		if(this.contents().length) {
			var res = new Parser().parse(this.contents()).valueOf(new Frame({}));
			if(res instanceof Value || res instanceof Frac) {
				this.data = res;
				this.setContents(res.toString());
			} else {
				this.data = new Value(0);
				this.setContents('0');
			}
		}
		this.parent('StatsList').update();
	}

	on delete(e) {
		e.stopPropagation();
		this.remove();
	}

	on add-under {
		this.parent('StatsList').addField(this);
		app.data.serialize();
	}

	on cursor-right {
		var el = self.$.next();
		if(el.length) {
			var cur = el.get(0).mathSelf().cursor;
			self.focusManager.setFocus(el.get(0));
			while(cur.prev) {
				cur.moveLeft();
			}
			setTimeout(function() {
				self.parent('StatsList').scroll.scrollToElement(el.get(0));
			},0);
		}
	}

	on cursor-left {
		var el = self.$.prev();
		if(el.length) {
			self.focusManager.setFocus(el.get(0));
			setTimeout(function() {
				self.parent('StatsList').scroll.scrollToElement(el.get(0));
			},0);
		}
	}

	css {
		position: relative;
	}

	my index-label {
		css {
			position: absolute;
			font-size: 12px;
			color: #BBB;
			left: 5px;
			top: 5px;
		}
	}
}