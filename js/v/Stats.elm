def StatsView {
	extends {
		SlideView
	}

	properties {
		horizontal: true
	}

	constructor {
		this.addView(elm.create('StatsListsManager'));
	}

	method initTest(type,name) {
		if(elm.def(type)) {
			this.addView(elm.create(type));
			this.slideTo(1,null,10);
		} else {
			app.popNotification("Sorry, " + type + " isn't ready yet.");
		}
	}

	method oneVarStats(list) {
		if(list.data.length == 0) {
			app.popNotification('Can\'t analyze an empty list!');
			return;
		}
		var s = this.addView(elm.create('OneVarStats'));
		s.$InlineListPicker.get(0).choose(list);
		this.slideTo(1);
	}
}

def StatsListsManager {
	extends {
		PageView
		NoSwipe
	}

	properties {
		baseWidth: 160
		animate: false
	}

	constructor {
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
			[[tests-button:ToolbarButton 'Tools']]
			[[back-button:ToolbarButton '']]
			[[next-button:ToolbarButton '']]
			[[add-button:ToolbarButtonImportant 'Add']]
		}
	}

	my tests-button {
		on invoke {
			app.overlay(elm.create('StatsTestChoiceOverlay',function(res) {
				self.parent('StatsView').initTest(res);
			}));
		}
	}

	my back-button {
		contents {
			<i class='fa fa-chevron-left'></i>
		}

		on invoke {
			if(!root.scroll) return;
			root.scroll.prev();
			var index = Math.floor(Math.abs(root.scroll.x / root.baseWidth)) - 1;
		}
	}

	my next-button {
		contents {
			<i class='fa fa-chevron-right'></i>
		}

		on invoke {
			if(!root.scroll) return;
			root.scroll.next();
			var index = Math.floor(Math.abs(root.scroll.x / root.baseWidth)) + 1;
		}
	}

	my add-button {
		on invoke {
			var alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
			var n = 0;
			while(!app.data.isNameAvailable('List' + alphabet[n]) && alphabet[n]) n++;
			app.prompt('Name?',function(name,close,tryAgain) {
				if(app.data.isNameAvailable(name)) {
					close();
					root.createList(name);
				} else {
					tryAgain('That name is in use. Why not pick another?');
				}
			},'List' + (alphabet[n] || ''));
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
			setTimeout(function() {
				var index  = $('.StatsList').length - 2;
				var width = $('.StatsList').width();
				var currentPage = {
					pageX: index,
					pageY: 0,
					x: -1 * index * width,
					y: 0
				};
				if(app.mode == self.parent('Stats')) app.help.introduce('stats');
				self.scroll.currentPage = currentPage;
				self.scroll.scrollToElement(el);
			},10);
		},0);
	}

	method addList {
		app.help.introduce('stats');
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
			self.actuallyUpdateScroll();
		},0);
		if(app.data.lists.length > 0) {
			this.$empty-notice.hide();
		} else {
			this.$empty-notice.show();
		}
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

	method actuallyUpdateScroll {
		var offset = 0,
			oldCurrentPage;
		if(!self.$StatsList.length) return;
		if(self.scroll) { 
			oldCurrentPage = self.scroll.currentPage;
			offset = self.scroll.x;
			self.scroll.destroy();
		}
		self.scroll = new IScroll(
			self.@contents-container-wrapper,
			{scrollbars: true, fadeScrollbars: true, mouseWheel: false, scrollX: true, startX: offset, snap: '.StatsList'}
		);
		if(oldCurrentPage) self.scroll.currentPage = oldCurrentPage;
	}

	method remove(element) {
		var l = element.data,
			ind = app.data.lists.indexOf(l);
		app.data.lists = app.data.lists.slice(0,ind).concat(app.data.lists.slice(ind+1));
		app.data.serialize();
		app.data.unregisterFunction(l.name);
		element.$.remove();
		self.orderLists();
	}

	method size {
		this.orderLists();
		this._size()
	}

	my contents-container {
		contents {

		}

		css {
			height: 100%;
		}
	}

	contents {
		<div class='empty-notice'></div>
	}

	my empty-notice {
		contents {
			Tap <i>Add</i> above to define a list.
		}

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

def StatsList(manager) {
	extends {
		ListView
		Pull
	}

	properties {
		pullMaxHeight: 100,
		pullConstant: 50,
	}

	constructor {
		this.fieldType = 'StatsListField';
		var options = [
			{color: '#696', event: 'show-stats', label: 'Stats'},
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
		extends {
			TouchInteractive
		}

		css {
			font-size: 16px;
		}

		on begin {
			root.focusManager.setFocus(null);
		}
	}

	on invoke {
		this.manager.selectList(this);
	}

	method setData(list) {
		this.data = list;
		this.updateDisplayedName();
		this.$MathTextField.remove();
		var largest = 0;
		list.data.forEach(function(d,i) {
			setTimeout(function() {
			var f = self.addField(null,false);
				f.setIndex(i);
				f.setData(d);
			},i * 10);
			largest = i;
		})
		setTimeout(function() {
			self.addField();
		}, (largest + 1) * 10);
	}

	method setName(name) {
		self.data.name = name;
		app.data.unregisterFunction(self.data.name);
		app.data.registerFunction(name);
		app.data.serialize();
		self.updateDisplayedName();
	}

	method updateDisplayedName() {
		this.$top-bar.html(self.data.name + ' (' + self.data.data.length.toString() + ')');
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
		self.updateDisplayedName();
		app.data.serialize();
	}

	method updateScroll {
		if(self.scroll) {
			self.scroll.refresh();
		} else {
			self.scroll = new IScroll(
				self.@contents-container-wrapper,
				{
					useTransition: false,
					scrollbars: true,
					mouseWheel: true,
					fadeScrollbars: true,
					bounce: true,
				}
			);
		}
	}

	on pullStart(e,data) {
		if((data.originY - $this.offset().top) > 65) {
			self.pullCancel = true;
		}
	}

	on delete {
		app.confirm('Are you sure?','Delete this list?',function() {
			self.manager.remove(self);
		});
	}

	on rename {
		app.prompt('Rename this list',function(name,close,tryAgain) {
			if(app.data.isNameAvailable(name)) {
				close();
				self.setName(name);
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

	on show-stats {
		this.parent('StatsView').oneVarStats(this.data);
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
		pullMaxWidth: 100,
		pullConstant: 30
	}

	contents {
		<span class='index-label'></span>
	}

	constructor {
		var options = [
			{color: '#0a4766', event: 'add-under', label: app.r.image('arrow-down')},
			{color: '#a33', event: 'delete', label: app.r.image('close')}
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
				this.setData(res);
			} else {
				this.setData(0);
			}
		}
		this.parent('StatsList').update();
	}

	on delete(e) {
		e.stopPropagation();
		this.remove();
	}

	on add-under {
		console.log('add-under');
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
		min-height: 42px;
	}

	my index-label {
		css {
			position: absolute;
			font-size: 8px;
			color: #CCC;
			left: 2px;
			top: 2px;
		}
	}
}

def ListChoiceView(callback) {
	extends {
		ListView
		Overlay
	}

	my empty-notice {
		contents {
			Lists defined in the Statistics module will appear here.
		}
	}

	properties {
		fieldType: 'SimpleListItem',
		autoAddField: false
	}

	constructor {
		this.$title.html('Choose a list');
		this.populate();
	}

	method populate {
		var lists = app.data.lists;
		lists.forEach(function(l) {
			var f = self.addField();
			f.$.html(l.name + ' (' + l.data.length.toString() + ' items)');
			f.$.on('invoke',self.choose);
			f.list= l;
		});
		if(lists.length == 0) {
			this.$empty-notice.show();
		}
	}

	method choose(e) {
		var list = e.target.list;
		self.callback(list);
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

def StatsTestChoiceOverlay(callback) {
	extends {
		ListView
		Overlay
	}

	properties {
		autoAddField: false,
		fieldType: 'ChoiceField',
	}

	constructor {
		this.$title.html('Tools and tests');
		this.choices = [
			['Stats Summary', 'OneVarStats'],
			['Linear Regression', 'LinearRegressionView'],
			['Z-Test','ZTestView'],
			['T-Test','TTestView'],
			['2-Sample Z-Test','TwoSampleZTestView'],
			['2-Sample T-Test','TwoSampleTTestView'],
			['1-Proportion Z-Test','OnePropZTestView'],
			['2-Proportion Z-Test', 'TwoPropZTestView'],
			['Chi-Squared Test', 'ChiSquaredView'],
			['Chi-Squared GOF', 'ChiSquaredGOFView']
		]
		this.choices.forEach(function(choice,i) {
			var f = self.addField();
			f.$.on('invoke',self.choose);
			f.setup(choice);
		});
	}

	method choose(e) {
		self.callback(e.target.viewType);
		self.flyOut();
	}

	my toolbar {
		contents {
			[[cancel-btn:ToolbarButtonImportant 'Cancel']]
		}
	}

	my cancel-btn {
		on invoke {
			root.flyOut();
		}
	}

	my ChoiceField {
		extends {
			SimpleListItem
		}

		style active {
			background: #FFF;
		}

		method setup(data) {
			this.label = data[0];
			this.viewType = data[1];
			this.$.html(this.label);
		}
	}
}

def StatsTestView {
	extends {
		PageView
	}

	contents {
		[[vis:StatsTestVisualization]]
		[[summary:StatsTestSummary]]
	}

	properties {
		noKeyboard: true
	}

	constructor {
		this.$title.html('');
	}

	my toolbar {
		contents {
			[[back-button:ToolbarButtonTransparent '&lsaquo; Back']]
		}

		css {
			float: left;
		}
	}

	my back-button {
		on invoke {
			root.parent('StatsView').removeView(root);
		}
	}

	my top-bar-container {
		css {
			position: absolute;
			z-index: 1001;
			box-shadow: none;
			background: rgba(0,0,0,0);
		}
	}
}

def StatsTestVisualization {
	properties {
		screenFraction: 0.3
	}

	extends {
		View
		Stackable
	}
	
	constructor {
	
	}
}

def StatsTestSummary {
	extends {
		PageView
		Stackable
	}

	properties {
		screenFraction: 0.7
	}

	method displayResults {
		this.$line-item.show();
		setTimeout(function() {
			self.$.trigger('invalidate');
		},10);
	}

	my top-bar-container {
		css {
			display: none;
		}
	}

	my contents-container {
		css {
			padding: 10px;
		}
	}

	css {
		background: #FFF;
		font-size: 16px;
		line-height: 45px;
	}
}

def OneVarStats {
	extends {
		StatsTestView
	}

	method compute(l) {
		var res = Functions.oneVarStats(l.data),
			s = this.@StatsTestSummary;
		this.list = l;
		this.summary = res;
		s.@mean.display(Functions.round(res.mean,3));
		s.@sum.display(Functions.round(res.sum,3));
		s.@sum-squares.display(Functions.round(res.sumSquares,3));
		s.@sample-stdev.display(Functions.round(res.sampleStdev,3));
		s.@pop-stdev.display(Functions.round(res.popStdev,3));
		s.@sample-size.display(Functions.round(res.n,3));
		s.@sample-min.display(Functions.round(res.min,3));
		s.@sample-q1.display(Functions.round(res.q1,3));
		s.@sample-median.display(Functions.round(res.median,3));
		s.@sample-q3.display(Functions.round(res.q3,3));
		s.@sample-max.display(Functions.round(res.max,3));
		s.displayResults();
		setTimeout(function() {
			self.$.trigger('invalidate');
		},10);
	}

	on invalidate {
		if(this.summary) this.$StatsTestVisualization.get(0).render(this.summary);
	}

	my StatsTestVisualization {
		method render(summary) {
			var range = summary.max - summary.min,
				numBars = Math.floor(Math.max(1,Math.min(Math.sqrt(2 * summary.n),6))),
				interval = range / numBars;
				hist = Functions.histogram(summary.numbers,numBars),
				highest = Functions.sort(hist).concat().pop(),
				heightFactor = Math.max(0.2,Math.min(0.8,Math.log(highest) / Math.log(5))),
				paddingFactor = 0.1,
				paddingOffset = paddingFactor * this.$.width(),
				barSpace = this.$.width() - 2 * paddingOffset,
				barEachSpace = barSpace / numBars,
				barWidth = 0.8 * barEachSpace;
			this.$Bar.remove();
			for(var i=0;i<numBars;i++) {
				var b = this.create('Bar'),
					bx = paddingOffset + i * barEachSpace,
					bHeight = this.$.height() * heightFactor * (hist[i] / highest);
				this.$.append(b);
				b.setup(bx,barWidth,bHeight,hist[i],(summary.min + interval * i).toPrecision(2));
			}
			this.$Bar.each(function(i,e) {
				e.$.hide();
				setTimeout(function() {
					$(e).css('translateY',300).show().animate({
						'translateY': 0,
					},1000,'easeInOutQuart');
				},100 + i * 60);
			});
		}
		
		css {
			position: relative;
			background: rgba(0,0,0,0.2);
		}

		my Bar {
			html {
				<div>
					<div class='wrapper'>
						<div class='bar'></div>
						<div class='interval'></div>
						<div class='count'></div>
					</div>
				</div>
			}

			css {
				position: absolute;
			}

			my wrapper {
				css {
					width: 100%;
					height: 100%;
					position: relative;
				}
			}

			my bar {
				css {
					position: absolute;
					background: #FFF;
				}
			}

			my interval {
				css {
					position: absolute;
					bottom: 0;
					left: 3px;
					font-size: 12px;
					color: #DDD;
				}
			}

			my count {
				css {
					width: 100%;
					position: absolute;
					text-align: center;
					font-size: 20px;
					font-weight: bold;
					color: #FFF;
				}
			}

			method setup(x,width,height,num,left) {
				if(height == 0) {
					this.$.css('opacity',0.5);
				}
				height = Math.max(height,15);
				this.$.css('left',x).css('bottom',0);
				this.$bar.css('bottom',0).css('width',width).css('height',height);
				this.$count.css('top', -20 - height).css('width',width);
				this.$interval.html(left);
				this.$count.html(num);
			}
		}
	}

	my StatsTestSummary {
		my contents-container {
			contents {
				<b>Stats summary for <div class='list-inp'>Select a list...</div></b>
				<div class='line-item'>Mean: <div class='num-sel mean'>Mean</div></div>
				<div class='line-item'>Sum: <div class='num-sel sum'>Sum</div></div>
				<div class='line-item'>Sum of squares: <div class='num-sel sum-squares'>Sum of squares</div></div>
				<div class='line-item'>Sample standard deviation: <div class='num-sel sample-stdev'>Sample stdev</div></div>
				<div class='line-item'>Population standard deviation: <div class='num-sel pop-stdev'>Pop stdev</div></div>
				<div class='line-item'>Dimension: <div class='num-sel sample-size'>N</div></div>
				<div class='line-item'>Min: <div class='num-sel sample-min'>Min</div></div>
				<div class='line-item'>Q1: <div class='num-sel sample-q1'>Q1</div></div>
				<div class='line-item'>Median: <div class='num-sel sample-median'>Median</div></div>
				<div class='line-item'>Q3: <div class='num-sel sample-q3'>Q3</div></div>
				<div class='line-item'>Max: <div class='num-sel sample-max'>Max</div></div>
			}

			my line-item {
				css {
					display: none;
				}
			}

			my list-inp {
				extends {
					InlineListPicker
				}

				on choose(e,list) {
					try {
						root.compute(list);
					} catch(e) {
						app.popNotification('Can\'t analyze an empty list!');
					}
				}
			}

			my num-sel {
				extends {
					InlineNumber
				}
			}
		}
	}
}

def LinearRegressionView {
	extends {
		StatsTestView
	}

	method addList(list,element) {
		if(element == this.@list-y) {
			this.listY = list;
		}
		if(element == this.@list-x) {
			this.listX = list;
		}
		if(this.listX && this.listY) {
			this.compute();
		}
	}

	method compute() {
		var res = Functions.linearRegression(this.listX.data,this.listY.data),
			s = this.@StatsTestSummary;
		this.summary = res;
		s.@reg-b.display(Functions.round(res.b,3));
		s.@reg-a.display(Functions.round(res.a,3));
		s.@pearson-r.display(Functions.round(res.r,3));
		s.@pearson-r-squared.display(Functions.round(res.r2,3));
		s.displayResults();
		setTimeout(function() {
			self.$.trigger('invalidate');
		},10);
	}

	on invalidate {
		if(!this.summary) return;
		var xmin = Functions.min(this.listX.data).toFloat();
		var xmax = Functions.max(this.listX.data).toFloat();
		var ymin = Functions.min(this.listY.data).toFloat();
		var ymax = Functions.max(this.listY.data).toFloat();
		var xpadding = 0.05 * (xmax - xmin);
		var ypadding = 0.05 * (ymax - ymin);
		this.$StatsTestVisualization.get(0).setWindowExplicit(
			xmin - xpadding,
			xmax + xpadding,
			ymin - ypadding,
			ymax + ypadding
		);
		this.$StatsTestVisualization.get(0).render();
	}

	my StatsTestVisualization {
		properties {
			freeScale: true
		}

		extends {
			GraphWindow
			Stackable
		}

		constructor {
			this.displayUI(false);
		}

		method draw(c,origin,width,height,x_scale,y_scale) {
			var inputList = {
				type: 'points',
				radius: 6,
				data: Functions.points(Functions.numbers(root.listX.data),Functions.numbers(root.listY.data))
			};
			var inputFunction = {
				type: 'function',
				color: '#CCC',
				data: function(x) {
					return root.summary.a + root.summary.b * x;
				}
			}
			this.inputs = [inputFunction,inputList];
			this.drawEquations(c,origin,width,height,x_scale,y_scale);
		}
	}

	my StatsTestSummary {
		my contents-container {
			contents {
				<b> Regression for <div class='list-y list-inp'>List Y...</div> on <div class='list-x list-inp'>List X...</div></b>
				<div class='line-item'>Regression: Y = <div class='num-sel reg-b'>B</div> + <div class='num-sel reg-a'>A</div> * X</div>
				<div class='line-item'>R (Pearson constant): <div class='num-sel pearson-r'>R</div></div>
				<div class='line-item'>R^2: <div class='num-sel pearson-r-squared'>R^2</div></div>
			}
		}

		my line-item {
			css {
				display: none;
			}
		}

		my list-inp {
			extends {
				InlineListPicker
			}

			on choose(e,list) {
				root.addList(list,e.target);
			}
		}

		my num-sel {
			extends {
				InlineNumber
			}
		}
	}
}

def StatsTestViewSimple {
	extends {
		PageView
	}

	properties {
		noKeyboard: true
	}

	constructor {
		this.$title.hide();
	}

	css {
		font-size: 0.8em;
	}

	method displayResults {
		this.$line-item.show();
		setTimeout(function() {
			self.$.trigger('invalidate');
		},10);
	}

	method hideResults {
		this.$line-item.hide();
	}

	my top-bar-container {
		css {
			background: #FFF;
			box-shadow: none;
		}
	}

	my toolbar {
		contents {
			[[back-button:ToolbarButton '&lsaquo; Back']]
		}

		css {
			float: left;
		}

		my back-button {
			on invoke {
				root.parent('StatsView').removeView(root);
			}
		}
	}

	my contents-container-wrapper {
		css {
			background: #FFF;
			text-align: center;
		}
	}
}

def StatsTestViewSimpleTeardown {
	my contents-container {
		my input-item {
			css {
				margin: 10px;
			}
		}

		my line-item {
			css {
				display: none;
			}
		}

		my list-inp {
			extends {
				InlineListPicker
			}
		}

		my num-sel {
			extends {
				InlineNumber
			}
		}

		my num-inp {
			extends {
				InlineNumberPicker
			}
		}

		my mtx-inp {
			extends {
				InlineMatrixPicker
			}
		}

		my mtx-sel {
			extends {
				InlineMatrix
			}
		}

		my choose-sel {
			extends {
				InlineChoice
			}
		}

		find p {
			css {
				margin: 10px;
			}
		}
	}
}

def ZTestView {
	extends {
		StatsTestViewSimple
	}

	on choose(e) {
		if(e.target.$.hasClass('use-stats') || e.target.$.hasClass('stats-inp')) {
			this.mode = 'stats';
			this.$source-stats-container.show();
			this.$source-list-container.hide();
			this.mean = parseFloat(this.$stats-mean.html());
			this.stdev = parseFloat(this.$stats-stdev.html());
			this.sampleSize = parseFloat(this.$stats-sample-size.html());
		}
		if(e.target.$.hasClass('use-list') || e.target.$.hasClass('stats-list')) {
			this.mode = 'list';
			this.$source-stats-container.hide();
			this.$source-list-container.show();
			this.sourceList = this.$stats-list.get(0).data;
			if(this.sourceList) {
				var s = Functions.oneVarStats(this.sourceList.data);
				this.mean = s.mean;
				this.stdev = s.sampleStdev;
				this.sampleSize = s.n;
			} else {
				this.mean = null;
				this.stdev = null;
				this.sampleSize = null;
			}
		}
		if(e.target.$.hasClass('stats-mean')) {
			this.mean = e.target.data;
		}
		if(e.target.$.hasClass('stats-stdev')) {
			this.stdev = e.target.data;
		}
		if(e.target.$.hasClass('stats-sample-size')) {
			this.sampleSize = e.target.data;
		}
		if(e.target.$.hasClass('mu-ne-mu0')) {
			this.hypothesis = 0;
		}
		if(e.target.$.hasClass('mu-lt-mu0')) {
			this.hypothesis = -1;
		}
		if(e.target.$.hasClass('mu-gt-mu0')) {
			this.hypothesis = 1;
		}
		if(e.target.$.hasClass('a-val')) {
			this.aVal = Functions.round(1 - 0.01 * parseFloat(e.target.$.html()),3);
		}
		if(e.target.$.hasClass('x-bar')) {
			this.xBar = parseFloat(this.$x-bar.html());
		}
		if(this.mode && this.stdev && this.hypothesis !== undefined && this.xBar !== undefined && this.aVal) {
			this.res = Functions.zTest(this.mean,this.stdev,this.sampleSize,this.hypothesis,this.xBar);
			this.$p-val.get(0).display(Functions.round(this.res.p,5));
			this.$z-val.get(0).display(Functions.round(this.res.z,3));
			this.$p-val-exp.html(Functions.round(this.res.p,5));
			this.$a-val-exp.html(this.aVal);
			this.$mu-val-exp.html(this.mean);
			if(this.res.p > this.aVal) {
				this.$gt-or-lt.html('greater');
				this.$accept-or-reject.html('accept');
			} else {
				this.$gt-or-lt.html('less');
				this.$accept-or-reject.html('reject');
			}
			this.displayResults();
		} else {
			this.hideResults();
		}
	}

	my contents-container {
		contents {
			<h1 class='title'>One-Sample Z-Test</h1>
			<p class='intro'>The one-sample z-test examines the statistical significance of a sample as compared to the population it is selected from. Is appropriate for a normally distrubuted population whose standard deviation is known.</p>
			<div class='choose-sel source-type'><div class='item use-stats'>Input statistics</div> or <div class='item use-list'>use a list</div></div>
			<br/>
			<div class='source-list-container'>Choose a source list: <div class='stats-list list-inp'>List...</div></div>
			<div class='source-stats-container'>Mean (&mu;): <div class='num-inp stats-inp stats-mean'>0.0</div> StDev (&sigma;): <div class='num-inp stats-inp stats-stdev'>1.0</div> Size (n): <div class='num-inp stats-inp stats-sample-size'>10</div></div>
			<div class='choose-sel hypothesis'>
				Hypothesis: 
				<div class='item mu-ne-mu0'>&mu; &ne; &mu;0</div>
				<div class='item mu-lt-mu0'>&mu; &lt; &mu;0</div>
				<div class='item mu-gt-mu0'>&mu; &gt; &mu;0</div>
			</div>
			<div class='choose-sel source-type'>
				Confidence (%): 
				<div class='item a-val p-68'>68</div>
				<div class='item a-val p-90'>90</div>
				<div class='item a-val p-95'>95</div>
				<div class='item a-val p-98'>98</div>
				<div class='item a-val p-99'>99</div>
			</div>
			<br/>
			<div>x&#772 (test value): <div class='num-inp x-bar'>Select...</div></div>
			<br/>
			<h2 class='line-item'>Results</h2>
			<div class='line-item'>Z-score: <div class='num-sel z-val'></div></div>
			<br/>
			<div class='line-item'>P-value: <div class='num-sel p-val'></div></div>
			<br/>
			<div class='line-item'>
				<p>Since our p-value of <span class='p-val-exp'></span> is <span class='gt-or-lt'></span> 
				than our &alpha;-value of <span class='a-val-exp'></span>, we <span class='accept-or-reject'></span>
				the null hypothesis that &mu; = <span class='mu-val-exp'></span>.</p>
			</div>
		}

		my hypothesis {
			properties {
				defaultSelect: false
			}
		}

		my source-list-container {
			css {
				display: none;
			}
		}

		my source-stats-container {
			css {
				display: none;
			}
		}

		my accept-or-reject {
			css {
				font-weight: bold;
			}
		}

		my stats-stdev {
			method filter(r) {
				if(r.complex === 0 && r.real > 0) {
					return true;
				} else {
					return 'The standard deviation must be a positive real number';
				}
			}
		}
	}

	extends {
		StatsTestViewSimpleTeardown
	}
}

def TTestView {
	extends {
		StatsTestViewSimple
	}

	on choose(e) {
		if(e.target.$.hasClass('use-stats') || e.target.$.hasClass('stats-inp')) {
			this.mode = 'stats';
			this.$source-stats-container.show();
			this.$source-list-container.hide();
			this.mean = parseFloat(this.$stats-mean.html());
			this.stdev = parseFloat(this.$stats-stdev.html());
			this.sampleSize = parseFloat(this.$stats-sample-size.html());
		}
		if(e.target.$.hasClass('use-list') || e.target.$.hasClass('stats-list')) {
			this.mode = 'list';
			this.$source-stats-container.hide();
			this.$source-list-container.show();
			this.sourceList = this.$stats-list.get(0).data;
			if(this.sourceList) {
				var s = Functions.oneVarStats(this.sourceList.data);
				this.mean = s.mean;
				this.stdev = s.sampleStdev;
				this.sampleSize = s.n;
			} else {
				this.mean = null;
				this.stdev = null;
				this.sampleSize = null;
			}
		}
		if(e.target.$.hasClass('stats-mean')) {
			this.mean = e.target.data;
		}
		if(e.target.$.hasClass('stats-stdev')) {
			this.stdev = e.target.data;
		}
		if(e.target.$.hasClass('stats-sample-size')) {
			this.sampleSize = e.target.data;
		}
		if(e.target.$.hasClass('mu-ne-mu0')) {
			this.hypothesis = 0;
		}
		if(e.target.$.hasClass('mu-lt-mu0')) {
			this.hypothesis = -1;
		}
		if(e.target.$.hasClass('mu-gt-mu0')) {
			this.hypothesis = 1;
		}
		if(e.target.$.hasClass('a-val')) {
			this.aVal = Functions.round(1 - 0.01 * parseFloat(e.target.$.html()),3);
		}
		if(e.target.$.hasClass('x-bar')) {
			this.xBar = parseFloat(this.$x-bar.html());
		}
		if(this.mode && this.stdev && this.hypothesis !== undefined && this.xBar !== undefined && this.aVal) {
			this.res = Functions.tTest(this.mean,this.stdev,this.sampleSize,this.hypothesis,this.xBar);
			this.$p-val.get(0).display(Functions.round(this.res.p,5));
			this.$t-val.get(0).display(Functions.round(this.res.t,3));
			this.$df-val.get(0).display(Functions.round(this.res.df,3));
			this.$p-val-exp.html(Functions.round(this.res.p,5));
			this.$a-val-exp.html(this.aVal);
			this.$mu-val-exp.html(this.mean);
			if(this.res.p > this.aVal) {
				this.$gt-or-lt.html('greater');
				this.$accept-or-reject.html('accept');
			} else {
				this.$gt-or-lt.html('less');
				this.$accept-or-reject.html('reject');
			}
			this.displayResults();
		} else {
			this.hideResults();
		}
	}

	my contents-container {
		contents {
			<h1 class='title'>One-Sample T-Test</h1>
			<p class='intro'>The one-sample t-test examines the statistical significance of a sample as compared to the population it is selected from. It is appropriate for a small (n < 30) sample from a population of unknown standard deviation.</p>
			<div class='choose-sel source-type'><div class='item use-stats'>Input statistics</div> or <div class='item use-list'>use a list</div></div>
			<br/>
			<div class='source-list-container'>Choose a source list: <div class='stats-list list-inp'>List...</div></div>
			<div class='source-stats-container'>Mean (&mu;): <div class='num-inp stats-inp stats-mean'>0.0</div> StDev (&sigma;): <div class='num-inp stats-inp stats-stdev'>1.0</div> Size (n): <div class='num-inp stats-inp stats-sample-size'>10</div></div>
			<div class='choose-sel hypothesis'>
				Hypothesis: 
				<div class='item mu-ne-mu0'>&mu; &ne; &mu;0</div>
				<div class='item mu-lt-mu0'>&mu; &lt; &mu;0</div>
				<div class='item mu-gt-mu0'>&mu; &gt; &mu;0</div>
			</div>
			<div class='choose-sel source-type'>
				Confidence (%): 
				<div class='item a-val p-68'>68</div>
				<div class='item a-val p-90'>90</div>
				<div class='item a-val p-95'>95</div>
				<div class='item a-val p-98'>98</div>
				<div class='item a-val p-99'>99</div>
			</div>
			<br/>
			<div>x&#772 (test value): <div class='num-inp x-bar'>Select...</div></div>
			<br/>
			<h2 class='line-item'>Results</h2>
			<div class='line-item'>T-score: <div class='num-sel t-val'></div></div>
			<br/>
			<div class='line-item'>P-value: <div class='num-sel p-val'></div></div>
			<br/>
			<div class='line-item'>Degrees of freedom (df): <div class='num-sel df-val'></div></div>
			<br/>
			<div class='line-item'>
				<p>Since our p-value of <span class='p-val-exp'></span> is <span class='gt-or-lt'></span> 
				than our &alpha;-value of <span class='a-val-exp'></span>, we <span class='accept-or-reject'></span>
				the null hypothesis that &mu; = <span class='mu-val-exp'></span>.</p>
			</div>
		}

		my hypothesis {
			properties {
				defaultSelect: false
			}
		}

		my source-list-container {
			css {
				display: none;
			}
		}

		my source-stats-container {
			css {
				display: none;
			}
		}

		my accept-or-reject {
			css {
				font-weight: bold;
			}
		}

		my stats-stdev {
			method filter(r) {
				if(r.complex === 0 && r.real > 0) {
					return true;
				} else {
					return 'The standard deviation must be a positive real number';
				}
			}
		}
	}

	extends {
		StatsTestViewSimpleTeardown
	}
}

def TwoSampleZTestView {
	extends {
		StatsTestViewSimple
	}

	on choose(e) {
		if(e.target.$.hasClass('use-stats-1') || e.target.$.hasClass('stats-inp-1')) {
			this.mode1 = 'stats';
			this.$source-stats-container-1.show();
			this.$source-list-container-1.hide();
			this.mean1 = parseFloat(this.$stats-mean-1.html());
			this.stdev1 = parseFloat(this.$stats-stdev-1.html());
			this.sampleSize1 = parseFloat(this.$stats-sample-size-1.html());
		}
		if(e.target.$.hasClass('use-stats-2') || e.target.$.hasClass('stats-inp-2')) {
			this.mode2 = 'stats';
			this.$source-stats-container-2.show();
			this.$source-list-container-2.hide();
			this.mean2 = parseFloat(this.$stats-mean-2.html());
			this.stdev2 = parseFloat(this.$stats-stdev-2.html());
			this.sampleSize2 = parseFloat(this.$stats-sample-size-2.html());
		}
		if(e.target.$.hasClass('use-list-1') || e.target.$.hasClass('stats-list-1')) {
			this.mode1 = 'list';
			this.$source-stats-container-1.hide();
			this.$source-list-container-1.show();
			this.sourceList1 = this.$stats-list-1.get(0).data;
			if(this.sourceList1) {
				var s = Functions.oneVarStats(this.sourceList1.data);
				this.mean1 = s.mean;
				this.stdev1 = s.sampleStdev;
				this.sampleSize1 = s.n;
			} else {
				this.mean1 = null;
				this.stdev1 = null;
				this.sampleSize1 = null;
			}
		}
		if(e.target.$.hasClass('use-list-2') || e.target.$.hasClass('stats-list-2')) {
			this.mode2 = 'list';
			this.$source-stats-container-2.hide();
			this.$source-list-container-2.show();
			this.sourceList2 = this.$stats-list-2.get(0).data;
			if(this.sourceList2) {
				var s = Functions.oneVarStats(this.sourceList2.data);
				this.mean2 = s.mean;
				this.stdev2 = s.sampleStdev;
				this.sampleSize2 = s.n;
			} else {
				this.mean2 = null;
				this.stdev2 = null;
				this.sampleSize2 = null;
			}
		}
		if(e.target.$.hasClass('stats-mean-1')) {
			this.mean1 = e.target.data;
		}
		if(e.target.$.hasClass('stats-stdev-1')) {
			this.stdev1 = e.target.data;
		}
		if(e.target.$.hasClass('stats-sample-size-1')) {
			this.sampleSize1 = e.target.data;
		}
		if(e.target.$.hasClass('stats-mean-2')) {
			this.mean2 = e.target.data;
		}
		if(e.target.$.hasClass('stats-stdev-2')) {
			this.stdev2 = e.target.data;
		}
		if(e.target.$.hasClass('stats-sample-size-2')) {
			this.sampleSize2 = e.target.data;
		}
		if(e.target.$.hasClass('mu1-ne-mu2')) {
			this.hypothesis = 0;
		}
		if(e.target.$.hasClass('mu1-lt-mu2')) {
			this.hypothesis = 1;
		}
		if(e.target.$.hasClass('mu1-gt-mu2')) {
			this.hypothesis = -1;
		}
		if(e.target.$.hasClass('a-val')) {
			this.aVal = Functions.round(1 - 0.01 * parseFloat(e.target.$.html()),3);
		}
		if(this.mode1 && this.mode2 && this.stdev1 && this.stdev2 && this.hypothesis !== undefined && this.aVal) {
			this.res = Functions.twoSampleZTest(this.mean1,this.mean2,this.stdev1,this.stdev2,this.sampleSize1,this.sampleSize2,this.hypothesis);
			this.$p-val.get(0).display(Functions.round(this.res.p,5));
			this.$z-val.get(0).display(Functions.round(this.res.z,3));
		//	this.$df-val.get(0).display(Functions.round(this.res.df,3));
			this.$p-val-exp.html(Functions.round(this.res.p,5));
			this.$a-val-exp.html(this.aVal);
			if(this.res.p > this.aVal) {
				this.$gt-or-lt.html('greater');
				this.$accept-or-reject.html('accept');
			} else {
				this.$gt-or-lt.html('less');
				this.$accept-or-reject.html('reject');
			}
			this.displayResults();
		} else {
			this.hideResults();
		}
	}

	my contents-container {
		contents {
			<h1 class='title'>Two-Sample Z-Test</h1>
			<p class='intro'>The two-sample z-test examines whether there is a statistically significant difference in the distributions of two samples. It is appropriate in situations where the population standard deviation is known.</p>
			<div class='choose-sel source-type'><b>List 1: </b><div class='item use-stats-1'>Input statistics</div> or <div class='item use-list-1'>use a list</div></div>
			<br/>
			<div class='source-list-container source-list-container-1'>Choose a source list: <div class='stats-list-1 list-inp'>List...</div></div>
			<div class='source-stats-container source-stats-container-1'>Mean (&mu;): <div class='num-inp stats-inp stats-mean-1'>0.0</div> StDev (&sigma;): <div class='num-inp stats-inp stats-stdev-1'>1.0</div> Size (n): <div class='num-inp stats-inp stats-sample-size-1'>10</div></div>
			</br>
			<div class='choose-sel source-type'><b>List 2: </b><div class='item use-stats-2'>Input statistics</div> or <div class='item use-list-2'>use a list</div></div>
			<br/>
			<div class='source-list-container source-list-container-2'>Choose a source list: <div class='stats-list-2 list-inp'>List...</div></div>
			<div class='source-stats-container source-stats-container-2'>Mean (&mu;): <div class='num-inp stats-inp stats-mean-2'>0.0</div> StDev (&sigma;): <div class='num-inp stats-inp stats-stdev-2'>1.0</div> Size (n): <div class='num-inp stats-inp stats-sample-size-2'>10</div></div>
			<div class='choose-sel hypothesis'>
				Hypothesis: 
				<div class='item mu1-ne-mu2'>&mu;1 &ne; &mu;2</div>
				<div class='item mu1-lt-mu2'>&mu;1 &lt; &mu;2</div>
				<div class='item mu1-gt-mu2'>&mu;1 &gt; &mu;2</div>
			</div>
			<div class='choose-sel source-type'>
				Confidence (%): 
				<div class='item a-val p-68'>68</div>
				<div class='item a-val p-90'>90</div>
				<div class='item a-val p-95'>95</div>
				<div class='item a-val p-98'>98</div>
				<div class='item a-val p-99'>99</div>
			</div>
			<br/>
			<h2 class='line-item'>Results</h2>
			<div class='line-item'>Z-score: <div class='num-sel z-val'></div></div>
			<br/>
			<div class='line-item'>P-value: <div class='num-sel p-val'></div></div>
			<br/>
		//	<div class='line-item'>Degrees of freedom (df): <div class='num-sel df-val'></div></div>
			<br/>
			<div class='line-item'>
				<p>Since our p-value of <span class='p-val-exp'></span> is <span class='gt-or-lt'></span> 
				than our &alpha;-value of <span class='a-val-exp'></span>, we <span class='accept-or-reject'></span>
				the null hypothesis that &mu;1 = &mu;2.</p>
			</div>
		}

		my hypothesis {
			properties {
				defaultSelect: false
			}
		}

		my source-list-container {
			css {
				display: none;
			}
		}

		my source-stats-container {
			css {
				display: none;
			}
		}

		my accept-or-reject {
			css {
				font-weight: bold;
			}
		}

		my stats-stdev {
			method filter(r) {
				if(r.complex === 0 && r.real > 0) {
					return true;
				} else {
					return 'The standard deviation must be a positive real number';
				}
			}
		}
	}

	extends {
		StatsTestViewSimpleTeardown
	}
}

def TwoSampleTTestView {
	extends {
		StatsTestViewSimple
	}

	on choose(e) {
		if(e.target.$.hasClass('use-stats-1') || e.target.$.hasClass('stats-inp-1')) {
			this.mode1 = 'stats';
			this.$source-stats-container-1.show();
			this.$source-list-container-1.hide();
			this.mean1 = parseFloat(this.$stats-mean-1.html());
			this.stdev1 = parseFloat(this.$stats-stdev-1.html());
			this.sampleSize1 = parseFloat(this.$stats-sample-size-1.html());
		}
		if(e.target.$.hasClass('use-stats-2') || e.target.$.hasClass('stats-inp-2')) {
			this.mode2 = 'stats';
			this.$source-stats-container-2.show();
			this.$source-list-container-2.hide();
			this.mean2 = parseFloat(this.$stats-mean-2.html());
			this.stdev2 = parseFloat(this.$stats-stdev-2.html());
			this.sampleSize2 = parseFloat(this.$stats-sample-size-2.html());
		}
		if(e.target.$.hasClass('use-list-1') || e.target.$.hasClass('stats-list-1')) {
			this.mode1 = 'list';
			this.$source-stats-container-1.hide();
			this.$source-list-container-1.show();
			this.sourceList1 = this.$stats-list-1.get(0).data;
			if(this.sourceList1) {
				var s = Functions.oneVarStats(this.sourceList1.data);
				this.mean1 = s.mean;
				this.stdev1 = s.sampleStdev;
				this.sampleSize1 = s.n;
			} else {
				this.mean1 = null;
				this.stdev1 = null;
				this.sampleSize1 = null;
			}
		}
		if(e.target.$.hasClass('use-list-2') || e.target.$.hasClass('stats-list-2')) {
			this.mode2 = 'list';
			this.$source-stats-container-2.hide();
			this.$source-list-container-2.show();
			this.sourceList2 = this.$stats-list-2.get(0).data;
			if(this.sourceList2) {
				var s = Functions.oneVarStats(this.sourceList2.data);
				this.mean2 = s.mean;
				this.stdev2 = s.sampleStdev;
				this.sampleSize2 = s.n;
			} else {
				this.mean2 = null;
				this.stdev2 = null;
				this.sampleSize2 = null;
			}
		}
		if(e.target.$.hasClass('stats-mean-1')) {
			this.mean1 = e.target.data;
		}
		if(e.target.$.hasClass('stats-stdev-1')) {
			this.stdev1 = e.target.data;
		}
		if(e.target.$.hasClass('stats-sample-size-1')) {
			this.sampleSize1 = e.target.data;
		}
		if(e.target.$.hasClass('stats-mean-2')) {
			this.mean2 = e.target.data;
		}
		if(e.target.$.hasClass('stats-stdev-2')) {
			this.stdev2 = e.target.data;
		}
		if(e.target.$.hasClass('stats-sample-size-2')) {
			this.sampleSize2 = e.target.data;
		}
		if(e.target.$.hasClass('mu1-ne-mu2')) {
			this.hypothesis = 0;
		}
		if(e.target.$.hasClass('mu1-lt-mu2')) {
			this.hypothesis = 1;
		}
		if(e.target.$.hasClass('mu1-gt-mu2')) {
			this.hypothesis = -1;
		}
		if(e.target.$.hasClass('a-val')) {
			this.aVal = Functions.round(1 - 0.01 * parseFloat(e.target.$.html()),3);
		}
		if(this.mode1 && this.mode2 && this.stdev1 && this.stdev2 && this.hypothesis !== undefined && this.aVal) {
			this.res = Functions.twoSampleTTest(this.mean1,this.mean2,this.stdev1,this.stdev2,this.sampleSize1,this.sampleSize2,this.hypothesis);
			this.$p-val.get(0).display(Functions.round(this.res.p,5));
			this.$t-val.get(0).display(Functions.round(this.res.t,3));
			this.$df-val.get(0).display(Functions.round(this.res.df,3));
			this.$p-val-exp.html(Functions.round(this.res.p,5));
			this.$a-val-exp.html(this.aVal);
			if(this.res.p > this.aVal) {
				this.$gt-or-lt.html('greater');
				this.$accept-or-reject.html('accept');
			} else {
				this.$gt-or-lt.html('less');
				this.$accept-or-reject.html('reject');
			}
			this.displayResults();
		} else {
			this.hideResults();
		}
	}

	my contents-container {
		contents {
			<h1 class='title'>Two-Sample T-Test</h1>
			<p class='intro'>The two-sample t-test examines whether there is a statistically significant difference in the distributions of two samples. It is appropriate in situations where the population standard deviation is unknown and the samples sizes are small (n < 30).</p>
			<div class='choose-sel source-type'><b>List 1: </b><div class='item use-stats-1'>Input statistics</div> or <div class='item use-list-1'>use a list</div></div>
			<br/>
			<div class='source-list-container source-list-container-1'>Choose a source list: <div class='stats-list-1 list-inp'>List...</div></div>
			<div class='source-stats-container source-stats-container-1'>Mean (&mu;): <div class='num-inp stats-inp stats-mean-1'>0.0</div> StDev (&sigma;): <div class='num-inp stats-inp stats-stdev-1'>1.0</div> Size (n): <div class='num-inp stats-inp stats-sample-size-1'>10</div></div>
			</br>
			<div class='choose-sel source-type'><b>List 2: </b><div class='item use-stats-2'>Input statistics</div> or <div class='item use-list-2'>use a list</div></div>
			<br/>
			<div class='source-list-container source-list-container-2'>Choose a source list: <div class='stats-list-2 list-inp'>List...</div></div>
			<div class='source-stats-container source-stats-container-2'>Mean (&mu;): <div class='num-inp stats-inp stats-mean-2'>0.0</div> StDev (&sigma;): <div class='num-inp stats-inp stats-stdev-2'>1.0</div> Size (n): <div class='num-inp stats-inp stats-sample-size-2'>10</div></div>
			<div class='choose-sel hypothesis'>
				Hypothesis: 
				<div class='item mu1-ne-mu2'>&mu;1 &ne; &mu;2</div>
				<div class='item mu1-lt-mu2'>&mu;1 &lt; &mu;2</div>
				<div class='item mu1-gt-mu2'>&mu;1 &gt; &mu;2</div>
			</div>
			<div class='choose-sel source-type'>
				Confidence (%): 
				<div class='item a-val p-68'>68</div>
				<div class='item a-val p-90'>90</div>
				<div class='item a-val p-95'>95</div>
				<div class='item a-val p-98'>98</div>
				<div class='item a-val p-99'>99</div>
			</div>
			<br/>
			<h2 class='line-item'>Results</h2>
			<div class='line-item'>T-score: <div class='num-sel t-val'></div></div>
			<br/>
			<div class='line-item'>P-value: <div class='num-sel p-val'></div></div>
			<br/>
			<div class='line-item'>Degrees of freedom (df): <div class='num-sel df-val'></div></div>
			<br/>
			<div class='line-item'>
				<p>Since our p-value of <span class='p-val-exp'></span> is <span class='gt-or-lt'></span> 
				than our &alpha;-value of <span class='a-val-exp'></span>, we <span class='accept-or-reject'></span>
				the null hypothesis that &mu;1 = &mu;2.</p>
			</div>
		}

		my hypothesis {
			properties {
				defaultSelect: false
			}
		}

		my source-list-container {
			css {
				display: none;
			}
		}

		my source-stats-container {
			css {
				display: none;
			}
		}

		my accept-or-reject {
			css {
				font-weight: bold;
			}
		}

		my stats-stdev {
			method filter(r) {
				if(r.complex === 0 && r.real > 0) {
					return true;
				} else {
					return 'The standard deviation must be a positive real number';
				}
			}
		}
	}

	extends {
		StatsTestViewSimpleTeardown
	}
}

def OnePropZTestView {
	extends {
		StatsTestViewSimple
	}

	on choose(e) {
		if(e.target.$.hasClass('stats-p0')) {
			this.p0 = parseFloat(e.target.data);
		}
		if(e.target.$.hasClass('stats-x')) {
			this.x = parseFloat(e.target.data);
		}
		if(e.target.$.hasClass('stats-n')) {
			this.n = parseFloat(e.target.data);
		}
		if(e.target.$.hasClass('p-ne-p0')) {
			this.hypothesis = 0;
		}
		if(e.target.$.hasClass('p-lt-p0')) {
			this.hypothesis = -1;
		}
		if(e.target.$.hasClass('p-gt-p0')) {
			this.hypothesis = 1;
		}
		if(e.target.$.hasClass('a-val')) {
			this.aVal = Functions.round(1 - 0.01 * parseFloat(e.target.$.html()),3);
		}
		if(this.p0 !== undefined && this.x !== undefined && this.n && this.hypothesis !== undefined && this.aVal) {
			this.res = Functions.onePropZTest(this.p0,this.x,this.n,this.hypothesis);
			this.$p-hat.get(0).display(Functions.round(this.res.pHat,4));
			this.$p-val.get(0).display(Functions.round(this.res.p,5));
			this.$z-val.get(0).display(Functions.round(this.res.z,3));
			this.$p-val-exp.html(Functions.round(this.res.p,5));
			this.$a-val-exp.html(this.aVal);
			if(this.res.p > this.aVal) {
				this.$gt-or-lt.html('greater');
				this.$accept-or-reject.html('accept');
			} else {
				this.$gt-or-lt.html('less');
				this.$accept-or-reject.html('reject');
			}
			this.displayResults();
		} else {
			this.hideResults();
		}
	}

	my contents-container {
		contents {
			<h1 class='title'>One-Proportion Z-Test</h1>
			<p class='intro'>The one-proportion z-test examines whether there is a statistically significant difference between a sample proportion and the proportion of the population it was drawn from.</p>
			</br>
			<div class='input-item'><div class='source-stats-container'>p0: <div class='num-inp stats-inp stats-p0'>Select...</div></div></div>
			<div class='input-item'>Successes (x): <div class='num-inp stats-inp stats-x'>Select...</div></div>
			<div class='input-item'>Size (n): <div class='num-inp stats-inp stats-n'>Select...</div></div>
			<p class='intro'>(The test statistic, p&#770;, is calculated as x/n.)</p>
			<div class='choose-sel hypothesis'>
				Hypothesis: 
				<div class='item p-ne-p0'>p&#770; &ne; p0</div>
				<div class='item p-lt-p0'>p&#770; &lt; p0</div>
				<div class='item p-gt-p0'>p&#770; &gt; p0</div>
			</div>
			<div class='choose-sel source-type'>
				Confidence (%): 
				<div class='item a-val p-68'>68</div>
				<div class='item a-val p-90'>90</div>
				<div class='item a-val p-95'>95</div>
				<div class='item a-val p-98'>98</div>
				<div class='item a-val p-99'>99</div>
			</div>
			<br/>
			<h2 class='line-item'>Results</h2>
			<div class='line-item'>p&#770; (Sample proportion): <div class='num-sel p-hat'></div></div>
			<br/>
			<div class='line-item'>Z-score: <div class='num-sel z-val'></div></div>
			<br/>
			<div class='line-item'>P-value: <div class='num-sel p-val'></div></div>
			<br/>
			<div class='line-item'>
				<p>Since our p-value of <span class='p-val-exp'></span> is <span class='gt-or-lt'></span> 
				than our &alpha;-value of <span class='a-val-exp'></span>, we <span class='accept-or-reject'></span>
				the null hypothesis that p&#770; = p0.</p>
			</div>
		}

		my hypothesis {
			properties {
				defaultSelect: false
			}
		}

		my accept-or-reject {
			css {
				font-weight: bold;
			}
		}
	}

	extends {
		StatsTestViewSimpleTeardown
	}
}

def TwoPropZTestView {
	extends {
		StatsTestViewSimple
	}

	on choose(e) {
		if(e.target.$.hasClass('stats-x1')) {
			this.x1 = parseFloat(e.target.data);
		}
		if(e.target.$.hasClass('stats-n1')) {
			this.n1 = parseFloat(e.target.data);
		}
		if(e.target.$.hasClass('stats-x2')) {
			this.x2 = parseFloat(e.target.data);
		}
		if(e.target.$.hasClass('stats-n2')) {
			this.n2 = parseFloat(e.target.data);
		}
		if(e.target.$.hasClass('p1-ne-p2')) {
			this.hypothesis = 0;
		}
		if(e.target.$.hasClass('p1-lt-p2')) {
			this.hypothesis = -1;
		}
		if(e.target.$.hasClass('p1-gt-p2')) {
			this.hypothesis = 1;
		}
		if(e.target.$.hasClass('a-val')) {
			this.aVal = Functions.round(1 - 0.01 * parseFloat(e.target.$.html()),3);
		}
		if(this.x1 !== undefined && this.n1 && this.x2 !== undefined && this.n2 && (true || this.hypothesis) !== undefined && this.aVal) {
			this.res = Functions.twoPropZTest(this.x1,this.x2,this.n1,this.n2,this.hypothesis);
			this.$p-hat-1.get(0).display(Functions.round(this.res.pHat1,4));
			this.$p-hat-2.get(0).display(Functions.round(this.res.pHat2,4));
			this.$p-val.get(0).display(Functions.round(this.res.p,5));
			this.$z-val.get(0).display(Functions.round(this.res.z,3));
			this.$p-val-exp.html(Functions.round(this.res.p,5));
			this.$a-val-exp.html(this.aVal);
			if(this.res.p > this.aVal) {
				this.$gt-or-lt.html('greater');
				this.$accept-or-reject.html('accept');
			} else {
				this.$gt-or-lt.html('less');
				this.$accept-or-reject.html('reject');
			}
			this.displayResults();
		} else {
			this.hideResults();
		}
	}

	my contents-container {
		contents {
			<h1 class='title'>Two-Proportion Z-Test</h1>
			<p class='intro'>The two-proportion z-test examines whether there is a statistically significant difference between two sample proportions.</p>
			</br>
			<div class='source-stats-container'>
				<div class='input-item'>Successes 1 (x): <div class='num-inp stats-inp stats-x1'>Select...</div></div>
				<div class='input-item'>Sample Size 1 (n): <div class='num-inp stats-inp stats-n1'>Select...</div></div>
			</div>
			<div class='source-stats-container'>
				<div class='input-item'>Successes 2 (x): <div class='num-inp stats-inp stats-x2'>Select...</div></div>
				<div class='input-item'>Sample Size 2 (n): <div class='num-inp stats-inp stats-n2'>Select...</div></div>
			</div>
			<p class='intro'>(The test statistics, p&#770;, are calculated as x/n.)</p>
			//<div class='choose-sel hypothesis'>
			//	Hypothesis: 
			//	<div class='item p1-ne-p2'>p1 &ne; p2</div>
			//	<div class='item p1-lt-p2'>p1 &lt; p2</div>
			//	<div class='item p1-gt-p2'>p1 &gt; p2</div>
			//</div>
			<div class='choose-sel source-type'>
				Confidence (%): 
				<div class='item a-val p-68'>68</div>
				<div class='item a-val p-90'>90</div>
				<div class='item a-val p-95'>95</div>
				<div class='item a-val p-98'>98</div>
				<div class='item a-val p-99'>99</div>
			</div>
			<br/>
			<h2 class='line-item'>Results</h2>
			<div class='line-item'>p&#770;1 (Sample proportion 1): <div class='num-sel p-hat-1'></div></div>
			<br/>
			<div class='line-item'>p&#770;2 (Sample proportion 2): <div class='num-sel p-hat-2'></div></div>
			<br/>
			<div class='line-item'>Z-score: <div class='num-sel z-val'></div></div>
			<br/>
			<div class='line-item'>P-value: <div class='num-sel p-val'></div></div>
			<br/>
			<div class='line-item'>
				<p>Since our p-value of <span class='p-val-exp'></span> is <span class='gt-or-lt'></span> 
				than our &alpha;-value of <span class='a-val-exp'></span>, we <span class='accept-or-reject'></span>
				the null hypothesis that p1 = p2.</p>
			</div>
		}

		my hypothesis {
			properties {
				defaultSelect: false
			}
		}

		my accept-or-reject {
			css {
				font-weight: bold;
			}
		}
	}

	extends {
		StatsTestViewSimpleTeardown
	}
}

def ChiSquaredView {
	extends {
		StatsTestViewSimple
	}

	on choose(e) {
		if(e.target.$.hasClass('observed-mtx')) {
			this.observed = e.target.data;
		}
		if(e.target.$.hasClass('a-val')) {
			this.aVal = Functions.round(1 - 0.01 * parseFloat(e.target.$.html()),3);
		}
		if(this.observed && this.aVal) {
			this.res = Functions.chiSquaredTest(this.observed);
			this.$x2-val.get(0).display(Functions.round(this.res.x2,5));
			this.$p-val.get(0).display(Functions.round(this.res.p,5));
			this.$df-val.get(0).display(Functions.round(this.res.df,3));
			this.$expected-mtx.get(0).display(this.res.expected);
			this.$p-val-exp.html(Functions.round(this.res.p,5));
			this.$a-val-exp.html(this.aVal);
			if(this.res.p > this.aVal) {
				this.$gt-or-lt.html('greater');
				this.$accept-or-reject.html('accept');
			} else {
				this.$gt-or-lt.html('less');
				this.$accept-or-reject.html('reject');
			}
			this.displayResults();
		} else {
			this.hideResults();
		}
	}

	my contents-container {
		contents {
			<h1 class='title'>Chi-Squared Test</h1>
			<p class='intro'>The chi-squared test looks for independence between two categorical variables in a sample. One variable's categories are represented by the rows of the matrix and the other's by its columns. The entries of the matrix are the number of observations that fit into the intersecting categories of its row and column.</p>
			</br>
			<div class='source-stats-container'>Matrix of observed values: <div class='mtx-inp stats-inp observed-mtx'>Select...</div></div>
			</br>
			<div class='choose-sel source-type'>
				Confidence (%): 
				<div class='item a-val p-68'>68</div>
				<div class='item a-val p-90'>90</div>
				<div class='item a-val p-95'>95</div>
				<div class='item a-val p-98'>98</div>
				<div class='item a-val p-99'>99</div>
			</div>
			<br/>
			<h2 class='line-item'>Results</h2>
			<br/>
			<div class='line-item'>&Chi;2-score: <div class='num-sel x2-val'></div></div>
			<br/>
			<div class='line-item'>Degrees of freedom: <div class='num-sel df-val'></div></div>
			<br/>
			<div class='line-item'>P-value: <div class='num-sel p-val'></div></div>
			<br/>
			<div class='line-item'>Expected value: <div class='mtx-sel expected-mtx'></div></div>
			<div class='line-item'>
				<p>Since our p-value of <span class='p-val-exp'></span> is <span class='gt-or-lt'></span> 
				than our &alpha;-value of <span class='a-val-exp'></span>, we <span class='accept-or-reject'></span>
				the null hypothesis that the two categorical variables are independent.</p>
			</div>
		}

		my hypothesis {
			properties {
				defaultSelect: false
			}
		}

		my accept-or-reject {
			css {
				font-weight: bold;
			}
		}
	}

	extends {
		StatsTestViewSimpleTeardown
	}
}

def ChiSquaredGOFView {
	extends {
		StatsTestViewSimple
	}

	on choose(e) {
		if(e.target.$.hasClass('observed-list')) {
			this.observed = e.target.data.data;
		}
		if(e.target.$.hasClass('expected-list')) {
			this.expected = e.target.data.data;
		}
		if(e.target.$.hasClass('a-val')) {
			this.aVal = Functions.round(1 - 0.01 * parseFloat(e.target.$.html()),3);
		}
		if(this.observed && this.expected && this.aVal) {
			this.res = Functions.chiSquaredGOFTest(this.expected,this.observed);
			this.$x2-val.get(0).display(Functions.round(this.res.x2,5));
			this.$p-val.get(0).display(Functions.round(this.res.p,5));
			this.$df-val.get(0).display(Functions.round(this.res.df,3));
			this.$p-val-exp.html(Functions.round(this.res.p,5));
			this.$a-val-exp.html(this.aVal);
			if(this.res.p > this.aVal) {
				this.$gt-or-lt.html('greater');
				this.$accept-or-reject.html('accept');
			} else {
				this.$gt-or-lt.html('less');
				this.$accept-or-reject.html('reject');
			}
			this.displayResults();
		} else {
			this.hideResults();
		}
	}

	my contents-container {
		contents {
			<h1 class='title'>Chi-Squared Goodness of Fit Test</h1>
			<p class='intro'>The chi-squared test looks for a statistically significant deviation in the distribution of a categorical variable by comparing a list of expected values to a list of those actually observed.</p>
			</br>
			<div class='source-stats-container'>Observed: <div class='list-inp stats-inp observed-list'>Select...</div></div>
			</br>
			<div class='source-stats-container'>Expected: <div class='list-inp stats-inp expected-list'>Select...</div></div>
			</br>
			<div class='choose-sel source-type'>
				Confidence (%): 
				<div class='item a-val p-68'>68</div>
				<div class='item a-val p-90'>90</div>
				<div class='item a-val p-95'>95</div>
				<div class='item a-val p-98'>98</div>
				<div class='item a-val p-99'>99</div>
			</div>
			<br/>
			<h2 class='line-item'>Results</h2>
			<br/>
			<div class='line-item'>&Chi;2-score: <div class='num-sel x2-val'></div></div>
			<br/>
			<div class='line-item'>Degrees of freedom: <div class='num-sel df-val'></div></div>
			<br/>
			<div class='line-item'>P-value: <div class='num-sel p-val'></div></div>
			<br/>
			<div class='line-item'>
				<p>Since our p-value of <span class='p-val-exp'></span> is <span class='gt-or-lt'></span> 
				than our &alpha;-value of <span class='a-val-exp'></span>, we <span class='accept-or-reject'></span>
				the null hypothesis that the expected values represent the true distribution of this sample.</p>
			</div>
		}

		my hypothesis {
			properties {
				defaultSelect: false
			}
		}

		my accept-or-reject {
			css {
				font-weight: bold;
			}
		}
	}

	extends {
		StatsTestViewSimpleTeardown
	}
}