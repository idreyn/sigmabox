def WelcomeView {
	extends {
		PageView
		Overlay
	}

	properties {
		overlaySourceDirection: 'top'
	}

	css {
		background: radial-gradient(ellipse at center, rgba(255,255,255,1) 0%,rgba(220,220,220,1) 100%);
		text-align: center;
	}

	my contents-container {
		contents {
			<div class='logo'></div>
			<h1>Welcome to Sigmabox.</h1>
			<p>A beautiful calculator featuring live evaluation, graphing, stats, and more.</p>
			<br/>
			[[ready-button:ToolbarButton 'Engage! &rsaquo;']]
		}

		css {
			padding: 20px;
			box-sizing: border-box;
		}

		my ready-button {
			on invoke {
				app.setMode('eval');
				app.help.playSequence('eval');
				root.flyOut();
			}
		}

		my logo {
			css {
				opacity: 0;
				background: url(res/img/logo-intro.png);
				background-size: contain;
				height: 200px;
				width: 200px;
				margin-left: auto;
				margin-right: auto;
				margin-top: 15%;
			}

			constructor {
				setTimeout(this.flyIn.bind(this),0);
			}

			method flyIn {
				$this.css('opacity',0).css('translateY',-500).animate({
					opacity: 1,
					translateY: 0
				},3000,'easeInOutElastic');
			}
		}

		find h1 {
			css {
				margin: 5px;
				font-size: 25px;
			}
		}
	}

	constructor {
		app.root.menuItemsDisabled = true;
		this.$top-bar-container.hide();
	}
}

def InformationView {

}

def HelpGuide {
	html {
		<div>
			<div class='stage'>
				<div class='text'>

				</div>
			</div>
		</div>
	}

	extends {
		TouchInteractive
	}

	css {
		cursor: pointer;
		display: none;
		position: absolute;
		z-index: 1000000;
		background: rgba(255,255,255,0.5);
		width: 100%;
		height: 100%;
	}

	my stage {
		css {
			cursor: pointer;
			position: relative;
			width: 100%;
			height: 100%;
		}
	}

	my text {
		css {
			position: absolute;
			color: #FFF;
			box-sizing: border-box;
			background: #0a4766;
			width: 100%;
			padding: 10px;
		}
	}

	constructor {
		this.sequences = {};
		this.addSequences();
	}

	method addSequences {
		// Primary intro
		this.addSequence('eval',[
			{
				text: 'Hi there! This is a quick tutorial to get you acquainted with Sigmabox. Tap anywhere to continue.'
			},
			{
				text: 'Just type to evaluate instantly.',
				touchTip: false,
				onEnter: function() {
					$('.LiveEvalCard .MathInput').css('padding-top',50);
					app.mode.currentInput().acceptActionInput('clear');
					app.keyboard.invokeSequence(['e','power','pi','i','right-arrow','plus','1'])
				},
				onExit: function() {
					app.mode.currentInput().acceptActionInput('clear');
				}
			},
			{
				text: 'The = key is used to solve equations.',
				touchTip: false,
				onEnter: function() {
					app.mode.currentInput().acceptActionInput('clear');
					app.keyboard.invokeSequence(['sin','2','x','right-arrow','equals','0','point','5'])
				},
				onExit: function() {

				}
			},
			{
				text: 'Hold down keys with grey bars to access secondary functions.',
				touchTip: {
					target: '.Key[name=left-arrow]',
					type: 'no-stroke'
				},
				onEnter: function(screen) {
					$(screen.touchTip.target).get(0).setAlt();
				},
				onExit: function(screen) {
					$(screen.touchTip.target).get(0).cancel();
				}
			},
			{
				text: 'Some keys will bring up additional keyboards.',
				touchTip: {
					target: '.Key[name=variables]',
					type: 'no-stroke'
				},
				onEnter: function(screen) {
					$(screen.touchTip.target).get(0).applyStyle('active');
				},
				onExit: function(screen) {
					$(screen.touchTip.target).get(0).cancel();
				}
			},
			{
				text: 'This keyboard contains variables!',
				touchTip: false,
				onEnter: function() {
					app.useKeyboard('variables');
				},
				onExit: function() {
					app.useKeyboard('main');
				}
			},
			{	
			text: 'Pull up on the primary keyboard to select from several advanced keyboards.',
				touchTip: {
					target: '.Keyboard',
					type: 'up'
				},
				onEnter: function() {
					app.useKeyboard('numerical');
				},
				onExit: function() {
					app.useKeyboard('main');
				}
			},
			{
				text: 'Pull down on the results pane for computation history.',
				touchTip: {
					target: '.LiveEvalCard',
					type: 'down'
				},
				onEnter: function() {
					if(app.mode.historyOverlay) app.mode.historyOverlay.$.remove();
					app.mode.historyOverlay = null;
					app.data.realInputHistory = app.data.inputHistory;
					app.data.inputHistory = ['e^{\\pi i}+1','\\sin(2x)=0.5'];
					app.mode.currentCard.showHistory();
					app.mode.currentCard.historyOverlay.$top-bar-container.css('padding-top',60);
				},
				onExit: function() {
					app.data.inputHistory = app.data.realInputHistory;
					app.mode.currentCard.hideHistory();
					app.mode.currentCard.historyOverlay.$top-bar-container.css('padding-top',0);
				}
			},
			{
				text: 'The SET button lets you assign any value to a variable.',
				touchTip: {
					target: '.set-button',
					type: 'no-stroke'
				},
				onEnter: function() {
					app.useKeyboard('variables');
				},
			},
			{
				text: 'The STO button lets you store the current result in a variable.',
				touchTip: {
					target: '.sto-button',
					type: 'no-stroke'
				},
				onExit: function() {
					app.useKeyboard('main');
				}
			},
			{
				text: 'The CLR button clears the current input.',
				touchTip: {
					target: '.clr-button',
					type: 'no-stroke'
				},
				onEnter: function() {
					app.mode.currentInput().acceptActionInput('clear');
					$('.LiveEvalCard .MathInput').css('padding-top',20);
				},
				onExit: function() {
					
				}
			},
			{
				text: 'Those are the basics, but there\'s so much more to Sigmabox...',
				touchTip: false
			},
			{
				text: utils.tabletMode() ? 'It\'s all available from the menu on the left!' : 'Just swipe from the left edge!',
				touchTip: utils.tabletMode() ? false : {target: '.Key[name=delete]',type:'right'},
				onEnter: function() {
					app.root.showMenu();
				}
			},
			{
				text: 'Tap the Sigmabox icon for more information and help.',
				touchTip: {
					target: '.main-icon',
					type: 'no-stroke'
				},
				onExit: function() {
					app.root.hideMenu();
				}
			},
			{
				text: 'That\'s it for now. Happy exploring!',
				touchTip: false
			},
		]);
		// REPL intro
		this.addSequence('repl',[
			{
				text: 'This is classic mode. It works more like a traditional calculator.',
				onEnter: function() {
					app.mode.$.css('padding-top',60);
					app.mode.clear();
				}
			},
			{
				minTime: 3000,
				text: 'After entering an expression, evaluate it by pressing the = key.',
				onEnter: function() {
					app.keyboard.invokeSequence(['1','plus','1','plus','2','plus','3','plus','5','plus','8','equals']);
				}
			},
			{
				text: 'The <i>ans</i> key comes in handy sometimes...',
				touchTip: {
					target: '.Key[name=equals]',
					type: 'no-stroke'
				},
				onEnter: function(screen) {
					$(screen.touchTip.target).get(0).setAlt();
				},
				onExit: function(screen) {
					$(screen.touchTip.target).get(0).cancel();
				}
			},
			{
				text: 'It stores the result of your last calculation.',
				touchTip: false,
				onEnter: function() {
					app.keyboard.invokeSequence(['2','times',['equals',true],'equals']);
				}
			},
			{
				text: 'You can hold down on a previous expression to reuse it...',
				touchTip: {
					target: '.REPLInput',
					type: 'no-stroke'
				}
			},
			{
				text: '...or on a result to save its value in a variable.',
				touchTip: {
					target: '.REPLOutput',
					type: 'no-stroke'
				},
				onEnter: function() {
					app.useKeyboard('variables');
				},
				onExit: function() {
					app.useKeyboard('main');
				}
				
			},
			{
				text: 'Have fun with classic mode!',
				onExit: function() {
					app.mode.clear();
					app.mode.$.css('padding-top',0);
				}
			}
		]);
		// Grapher intro
		this.addSequence('grapher-inputs',[
			{
				text: 'Quick tip: you can swipe left on equations to remove or constrain them.',
				touchTip: {
					target: '.GrapherListField',
					type: 'left'
				}	
			}
		]);
		// Grapher interface
		this.addSequence('grapher-interaction',[
			{
				position: 'bottom',
				text: 'You\'ve graphed your first equation! Just a few things to note...'
			},
			{
				position: 'bottom',
				text: 'You can zoom in and out with these controls.',
				touchTip: {
					target: '.zoom-buttons',
					type: 'no-stroke'
				}
			},
			{
				position: 'bottom',
				text: 'When cursor mode is selected, you can drag to pan the viewport.',
				touchTip: {
					target: '.cursor-button',
					type: 'no-stroke'
				}
			},
			{
				position: 'bottom',
				text: 'When trace mode is selected, you can drag to see position and slope.',
				touchTip: {
					target: '.trace-button',
					type: 'no-stroke'
				}
			},
			{
				position: 'bottom',
				text: 'When range mode is selected, you can drag a range on the graph to find maxima, minima, and intersections.',
				touchTip: {
					target: '.range-button',
					type: 'no-stroke'
				}
			},
			{
				position: 'bottom',
				text: 'The home button resets the viewport to default position and scale.',
				touchTip: {
					target: '.home-button',
					type: 'no-stroke'
				}
			},
			{
				position: 'top',
				text: 'When graphing multiple equations at once, you can select one to analyze in the lower left corner.',
				touchTip: {
					target: '.equation-choice',
					type: 'no-stroke'
				}
			},
			{
				text: 'Happy graphing!',
				touchTip: false
			}
		]);
		// Custom functions
		this.addSequence('custom-functions',[
			{
				text: 'Swipe right to rename or remove functions.',
				touchTip: {
					target: '.FunctionField',
					type: 'left'
				}
			},
			{
				text: 'Functions can take more than one argument. You can add more with the comma key!',
				touchTip: {
					target: '.Key[name=point]',
					type: 'no-stroke'
				},
				onEnter: function() {
					app.keyboard.getKeyByName('point').setAlt();
				},
				onExit: function() {
					app.keyboard.getKeyByName('point').cancel();
				}
			},
			{
				text: 'Functions defined here are accessible anywhere with the <i>F(x)</i> key.',
				touchTip: {
					target: '.Key[name=functions]',
					type: 'no-stroke'
				}
			}
		]);
		// Statistics
		this.addSequence('stats',[
			{
				position: utils.tabletMode() ? 'top' : 'bottom',
				text: 'Swipe left on an item in a list to remove it or to add another entry in place.',
				touchTip: {
					target: '.StatsListField',
					type: 'left'
				}
			},
			{
				position: utils.tabletMode() ? 'top' : 'bottom',
				text: 'Swipe down on a list header to remove, rename, delete, or get a statistical summary.',
				touchTip: {
					target: '.StatsList .top-bar',
					type: 'down'
				}
			},
			{
				position: 'bottom',
				text: 'Tap <i>Tools</i> to access a variety of statistical tools and tests.',
				touchTip: {
					target: '.tests-button',
					type: 'no-stroke'
				}
			},
			{
				text: 'Lists defined here are accessible anywhere with the <i>Lists</i> key.',
				touchTip: {
					target: '.Key[name=lists]',
					type: 'no-stroke'
				}
			}
		]);
	}

	method introduce(name,delay) {
		if(app.data.helpSequencesPlayed.indexOf(name) != -1) {
			return;
		}
		setTimeout(function() {
			self.playSequence(name);
		},delay || 10);
	}

	method addSequence(name,seq) {
		this.sequences[name] = seq;
	}

	method playSequence(name) {
		if(!this.sequences[name]) {
			return;
		}
		app.root.menuItemsDisabled = true;
		this.index = 0;
		this.sequenceName = name;
		this.sequence = this.sequences[name];
		this.showScreen(this.sequence[0]);
		this.$.fadeIn(100);
	}

	method endSequence {
		app.root.menuItemsDisabled = false;
		app.data.helpSequencesPlayed.push(self.sequenceName);
		app.data.serialize();
		self.sequence = null;
		self.sequenceName = null;
		this.$.fadeOut(100);
		this.$TouchTip.stop().remove();
	}

	on invoke {
		if(this.sequence) {
			if(new Date().valueOf() - this.switchTime < (this.minScreenTime || 1000)) {
				return;
			}
			var onExit = this.sequence[this.index].onExit;
			if(onExit) {
				onExit(this.sequence[this.index]);
			}
			this.index++;
			this.switchTime = new Date().valueOf();
			if(this.sequence[this.index]) {
				setTimeout((function() {
					this.showScreen(this.sequence[this.index]);
				}).bind(this),0);
			} else {
				this.endSequence();
			}
		}
	}

	method showScreen(screen) {
		var touch = screen.touchTip,
			text = screen.text,
			position = screen.position || 'top';
		if(touch === false) {
			if(this.touchTip) {
				this.touchTip.$.fadeOut(100);
			}
		} else {
			if(touch) {
				if(touch.target instanceof HTMLElement || typeof(touch.target) == 'string') {
					touch.target = $(touch.target);
				}
				if(touch.target instanceof jQuery) {
					if(touch.target.length == 0) {
						throw 'TouchTip target unavailable';
					}
					var offset = touch.target.offset();
					var containerOffset = this.parent().$container.offset();
					offset = {
						x: offset.left + (touch.target.width() / 2) - containerOffset.left,
						y: offset.top + (touch.target.height() / 2) - containerOffset.top
					};
				} else {
					var offset = touch.target;
				}
				if(this.touchTip) {
					this.touchTip.$.fadeOut(100);
				}
				this.touchTip = elm.create('TouchTip',touch.type,touch.distance);
				this.touchTip.$.css('left',offset.x);
				this.touchTip.$.css('top',offset.y);
				setTimeout(function() {
					self.$stage.append(self.touchTip);
					self.touchTip.start();
				},500);
			}
		}
		this.minScreenTime = screen.minTime;
		this.$text.html(text);
		if(position == 'bottom') {
			this.$text.css('bottom',0).css('top','');
		} else {
			this.$text.css('top',0).css('bottom','');
		}
		if(screen.onEnter) {
			screen.onEnter(screen);
		}
	}
}

def TouchTip(strokeDirection,distance) {
	html {
		<div>
			<div class='circle'></div>
		</div>
	}

	css {
		position: absolute;
	}

	my label {
		css {
			text-align: center;
			margin-left: 25px;
			font-size: 1.2em;
		}
	}

	method start {
		self.@circle.start();
	}

	my circle {
		css {
			box-sizing: border-box;
			width: 30px;
			height: 30px;
			margin-left: -15px;
			margin-top: -15px;
			border-radius: 30px;
			background: rgba(0,0,0,0.2);
			border: 3px rgba(255,255,255,1) solid;
		}

		constructor {
			if(!this.distance) {
				this.distance = 100;
			}
			if(!this.strokeDirection) {
				this.strokeDirection = 'down';
			}
		}

		method start {
			this.$.css('opacity',0).fadeIn(100);
			setTimeout(function() {
				self.animateStroke(root.strokeDirection,self.start);
			},100);
		}

		method animateStroke(direction,complete,duration) {
			var property, target, distance = this.distance;
			if(!duration) duration = 500;
			$this.css('translateX',0).css('translateY',0).css('scale',1);
			if(direction == 'up') {
				property = 'translateY';
				target = -distance;
			}
			if(direction == 'down') {
				property = 'translateY';
				target = distance;
			}
			if(direction == 'left') {
				property = 'translateX';
				target = -distance;
			}
			if(direction == 'right') {
				property = 'translateX';
				target = distance;
			}
			if(direction == 'no-stroke') {
				property = 'scale';
				target = 1.5;
			}
			function doAnimate() {
				var props = {};
				props[property] = target;
				$this.animate(props,{duration: duration, queue: false},'easeInOutQuart');
				$this.animate({opacity:0},{duration: duration, queue: false}, 'easeInQuart');
				if(complete) setTimeout(complete.bind(self),duration * 1.5);
			}
			$this.animate({opacity:1},duration / 2,doAnimate);
		}
	}
}

def HelpView {
	extends {
		TabbedView
	}

	my AboutView {
		properties {
			src: 'docs/about.md'
		}

		extends {
			ReaderView
		}

		css {
			color: #666;
			background-size: cover;
		}
	}

	css {
		my tab-bar {
			opacity: 1
		}
	}

	my DonateView {
		properties {
			src: 'docs/donate.md'
		}

		extends {
			ReaderView
		}

		css {
			color: #666;
			background-size: cover;
		}
	}

	css {
		my tab-bar {
			opacity: 1
		}
	}


	my ReferenceView {
		extends {
			ListView
		}

		properties {
			autoAddField: false
		}

		contents {
			[[input:TextInput 'Search keys']]
		}

		my input {
			css {
				border: 1px solid #CCC;
				padding-top: 0;
				padding-bottom: 0;
				position: absolute;
				height: 60px;
				background: #F5F5F5;
				color: #999;
				box-shadow: 1px 1px 1px 1px rgba(0,0,0,0.1);
			}

			focus {
				border: none;
			}

			on keyup {
				parent.search(this.$.val());
			}
		}

		my contents-container {
			css {
				padding-top: 60px;
			}
		}

		constructor {
			this.$top-bar-container.hide();
			this.reader = new DocsReader('docs/keys.txt',this.onParsed.bind(this));
		}

		method onParsed(library) {
			this.library = library;
			if(this.buildLibraryOnParsed) {
				this.buildLibrary();
			}
		}

		method buildLibrary {
			if(this.libraryBuilt) {
				return;
			}
			if(!this.library) {
				this.buildLibraryOnParsed = true;
				return;
			}
			app.popNotification('Loading key reference...');
			this.libraryBuilt = true;
			this.library.key.forEach(function(key) {
				var topic = self.create('Topic',key);
				self.$contents-container.append(topic);
			});
			setTimeout(this.updateScroll.bind(this),1000);
		}

		method search(str) {
			this.$Topic.each(function() {
				if(this.$.html().indexOf(str) != -1) {
					this.$.show();
				} else {
					this.$.hide();
				}
			});
		}

		css {
			color: #666;
			background: url(res/img/background.png);
			background-size: cover;
		}

		my Topic(src) {
			extends {
				SimpleListItem
			}

			contents {
				<div class='title'></div>
				<div class='contents'></div>
			}

			css {
				font-size: 20px;
				border-bottom: 1px solid #CCC;
			}

			my contents {
				css {
					font-size: 10px;
				}
			}

			style active {
				background: #FFF;
			}

			constructor {
				this.$title.html('<b>key</b> ' + this.src.label);
				this.$contents.append('<p> <b>name: </b>' + this.src.name + '</p>');
				['location','parameters','range'].forEach(function(k) {
					if(self.src[k]) {
						var line = self.src[k];
						if(line instanceof Array) {
							line = line.join(',');
						}
						self.$contents.append('<p> <b>' + k + ': </b>' + self.src[k] + '</p>');
					}
				});
				this.$contents.append('<p>' + this.src.usage + '</p>');
			}
		}
	}

	constructor {
		this.addTab('About',this.create('AboutView'));
		this.addTab('Reference',this.create('ReferenceView'));
		// this.addTab('Donate',this.create('DonateView'));
	}

	on displayed {
		this.$ReferenceView.get(0).buildLibrary();
	}

	properties {
		noKeyboard: true
	}
}