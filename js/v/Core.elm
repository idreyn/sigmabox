def SigmaboxAppFrame {
	properties {
		menuClass: 'SigmaboxSideMenu'
	}

	extends {
		SideMenuAppView
	}

	css {

	}
}


def SyncSubscriber {
	constructor {
		app.data.uiSyncSubscribe(this);
	}

	method syncTo(val) {
		this.willSyncTo = val;
	}

	method subscribeEvent(event) {
		this.$.addClass('subscribe-' + event);
	}

	method unsubscribeEvent(event) {
		this.$.removeClass('subscribe-' + event);
	}

	on sync {
		var res = eval(this.willSyncTo);
		if(this.sync && this.willSyncTo) this.sync(res);
	}
}

def SigmaboxSideMenu {
	extends {
		SideMenu
	}

	constructor {
		this.$top-bar-container.hide();
	}

	my contents-container-wrapper {
		css {
			width: 75px;
		}
	}

	my contents-container {
		contents {
			<img src='res/img/logo.png' width='100%' />
			[[SigmaboxSideMenuItem 'calculator','eval']]
			[[SigmaboxSideMenuItem 'repl', 'repl']]
			[[SigmaboxSideMenuItem 'grapher','grapher']]
			[[SigmaboxSideMenuItem 'functions','functions']]
			[[SigmaboxSideMenuItem 'stats','stats']]
			[[SigmaboxSideMenuItem 'linear','linear']]
			[[SigmaboxSideMenuItem 'converter','converter']]
		}
	}

	method setMode(mode) {
		this.$SigmaboxSideMenuItem.each(function() {
			if(this.mode == mode) {
				self.selected = this;
				this.showCircle();
			}
		});
	}
}

def SigmaboxSideMenuItem(imageID,mode) {
	extends {
		SideMenuItem
	}

	contents {
		<div class='circle'></div>
		<img class='image' />
	}

	css {
		margin-bottom: 15px;
		background: none;
		overflow-x hidden;
		height: 75px;
		width: 75px;
		text-align: center;
	}

	my image {
		css {
			opacity: 0.7;
			position: absolute;
			width: 30px;
			height: 30px;
		}

		on dragstart(e) {
			e.preventDefault();
		}

		constructor {
			this.src = app.r.image(parent.imageID);
			$this.css('top',
				($parent.height() - $this.height()) / 2
			);
			$this.css('left',
				($parent.width() - $this.width()) / 2
			);
		}
	}

	my circle {
		css {
			position: absolute;
			display: none;
			width: 75px;
			height: 75px;
			border-radius: 50px;
			background: #CCC;
			opacity: 0.2;
		}
	}

	on invoke {
		app.setMode(this.mode);
		setTimeout(function() {
			app.root.hideMenu();
		},100);
	}

	on deselect {
		this.hideCircle();
	}

	method showCircle {
		if(app.useGratuitousAnimations() && false) {
			setTimeout(function() {
				self.$circle.show().animate({
					scale: 1.2
				},500,'easeOutQuart');
			},10);
		} else {
			this.$circle.css('scale',1.2).show();
		}
	}

	method hideCircle {
		if(app.useGratuitousAnimations() && false) {
			setTimeout(function() {
				self.$circle.show().stop().animate({
					scale: 0
				},350,'easeOutQuart');
			},10);
		} else {
			this.$circle.stop().css('scale',0);
		}
	}
}

def IconButton(iconName,callback) {
	html {
		<img />
	}

	extends {
		Button
	}

	on invoke {
		if(this.callback) this.callback();
	}

	constructor {
		this.src = app.r.thinIcon(this.iconName);
	}

	css {
		vertical-align: middle;
		width: 30px;
		height: 30px;
		margin-right: 15px;
		cursor: pointer;
	}

	style default {
		opacity: 0.5;
	}

	style active {
		opacity: 0.8;
	}

	hover {
		opacity: 0.8;
	}
}

def TrigSwitch(left,right,willSyncTo) {
	extends {
		Switch
	}

	constructor {
		var self = this;
	}

	style disabled {
		opacity: 0.5;
		background: rgba(255,0,0,0.1);
	}

	style default {
		opacity: 1;
		background: rgba(0,0,0,0.1);
	}

	method forceRadians() {
		if(this.realTrigMode === undefined) {
			this.realTrigMode = app.data.realTrigMode;
			this.flip(true);
			this.disable();
			this.applyStyle('disabled');
		}
		//this.size();
	}

	method endForceRadians() {
		if(this.realTrigMode !== undefined) {
			this.flip(this.realTrigMode);
			this.enable();
			this.applyStyle('default');
			this.realTrigMode = undefined;
		}
	}
}

def Notification(text,duration) {

	html {
		<div>$text</div>
	}

	css {
		position: fixed;
		width: 100%;
		top: 0;
		height: 30px;
		line-height: 30px;
		color: #999;
		background: #EEE;
		//box-shadow: 1px 1px 1px rgba(0,0,0,0.2);
		padding: 10px;
		z-index: 3000;
	}

	constructor {
		$this.hide();
	}

	method invoke {
		app.notificationCount |= 0;
		app.notificationCount++;
		$this.css('top',0 - $this.height()).show();
		$this.animate({top: (app.notificationCount-1)*($this.outerHeight())},500,'easeOutQuart',function() {
			setTimeout(function() {
				app.notificationCount--;
				$this.animate({top:-100},500,'easeInQuart');
			},this.duration*1000);
		});
	}
}

def SigmaLabView {
	extends {
		StatsTestView
	}

	properties {
		noKeyboard: true
	}
}

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
			<img src='res/img/logo-intro.png' class='logo' />
			<h1>Welcome to Sigmabox.</h1>
			<p>A beautiful calculator featuring live evaluation, graphing, statistics, and more.</p>
			<br/>
			[[ready-button:ToolbarButton 'My body is ready &rsaquo;']]
		}

		css {
			padding: 20px;
			box-sizing: border-box;
		}

		my ready-button {
			on invoke {
				root.flyOut();
			}
		}

		my logo {
			css {
				height: 200px;
				margin-top: 15%;
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
		this.$top-bar-container.hide();
	}
}