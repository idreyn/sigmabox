// Components that are difficult to separate from Sigmabox

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
		app.storage.uiSyncSubscribe(this);
	}

	method syncTo(val) {
		this.willSyncTo = val;
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

	contents {
		<img src='res/img/logo-alpha.png' width='100%' />
//		[[SigmaboxSideMenuItem 'calculator', 'repl']]
		[[SigmaboxSideMenuItem 'calculator','eval']]
		[[SigmaboxSideMenuItem 'grapher','grapher']]
		[[SigmaboxSideMenuItem 'stats','stats']]
		[[SigmaboxSideMenuItem 'functions','functions']]
		[[SigmaboxSideMenuItem 'converter','converter']]
		[[SigmaboxSideMenuItem 'settings','settings']]
	}

	method build {

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
		margin-bottom: 10px;
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
			this.realTrigMode = app.storage.realTrigMode;
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

def Overlay {
	properties {
		overlaySourceDirection: 'bottom'
	}

	css {
		-webkit-transition: -webkit-transform 0.1s ease-out;
		z-index: 1001;
		background: url(res/img/background.png);
	}

	on ready {
		this.flyOut();
	}

	method flyOut {
		switch(this.overlaySourceDirection) {
			case 'right':
				$this.css('-webkit-transition','-webkit-transform 0.1s ease-out');
				$this.css('translateX',app.root.$.width());
				break;
			case 'left':
				$this.css('-webkit-transition','-webkit-transform 0.1s ease-out');
				$this.css('translateX',-app.root.$.width());
				break;
			case 'top':
				$this.css('-webkit-transition','-webkit-transform 0.2s ease-out');
				$this.css('translateY',-app.root.$.height());
				break;
			case 'bottom': 
				$this.css('-webkit-transition','-webkit-transform 0.2s ease-out');
				$this.css('translateY',app.root.$.height());
				break;
		}
	}

	method flyIn {
		switch(this.overlaySourceDirection) {
			case 'right':
				$this.css('translateX',0);
				break;
			case 'left':
				$this.css('translateX',0);
				break;
			case 'top':
				$this.css('translateY',0);
				break;
			case 'bottom': 
				$this.css('translateY',0);
				break;
		}
	}

	on removed {
		this.flyOut();
		setTimeout(function() {
			$this.hide().remove();
			if(self.relinquish) self.relinquish.call(self);
		},1000)
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
		height: 20px;
		color: #999;
		background: #EEE;
		box-shadow: 1px 1px 1px rgba(0,0,0,0.2);
		padding: 10px;
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