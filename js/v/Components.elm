// Components that ought to live somewhere separate from Sigmabox because they are highly reusable.

def TouchInteractive {
	constructor {
		Hammer(this).on('tap',this.#tapped);
		Hammer(this).on('touch',this.#touched);
		Hammer(this).on('release',this.#released);
		Hammer(this).on('dragged',this.#dragged);
		this.enabled = true;
	}

	css {
		outline: none;
		user-select: none;
		-webkit-tap-highlight-color: rgba(255, 255, 255, 0); 
	}

	method tapped(e) {
		if(!this.enabled) return;
		this.$.trigger('invoke');
	}

	method touched(e) {
		if(!this.enabled) return;
		this.$.trigger('begin');
		this.$.trigger('active');
	}

	method released(e) {
		if(!this.enabled) return;
		this.$.trigger('end');
		this.$.trigger('endactive');
	}

	on mouseout(e) {
		this._isTouchInBounds = false;
	}

	on mousemove(e) {
		this._isTouchInBounds = true;
	}

	on touchmove(e) {
		if(this.enabled) {
			var touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
			this._touchDeltaX = Math.abs(touch.screenX - this._touchStartX);
			if (utils.hitTest(touch, $this.offset(), $this.outerWidth(), $this.outerHeight())) {
				this._isTouchInBounds = true;
			} else {
				this._isTouchInBounds = false;
			}
		}
	}

	method enable {
		this.enabled = true;
	}	

	method disable {
		this.enabled = false;
	}
}

def Button {
	extends {
		TouchInteractive
	}

	constructor {

	}

	on ready {
		this.applyStyle('default');
	}

	on begin {
		$this.removeClass('color-transition');
		this.applyStyle('active');
	}

	on invoke {

	}

	on end {
		$this.addClass('color-transition');
		this.applyStyle('default');
	}

	css {
		outline: none;
		user-select: none;
		-webkit-tap-highlight-color: rgba(255, 255, 255, 0); 
	}
}

def View {
	html {
		<div> </div>
	}

	css {
		width: 100%;
		height: 100%;
		position: absolute;
		overflow: hidden;
	}

	constructor {
		this.focusManager = new FocusManager();
		this.sizeToParent = false;
	}

	method addChild(x) {
		$(this).append(x);
	}

	method size(i) {
		if(this.maxWidth) $this.css('width',this.maxWidth.toString() + '%');
		i = i || this.screenFraction || 1;
		$this.css(
			'height',
			$this.parent().height() * i
		);
		$this.find('*').each(function() {
			var child = this;
			if(child.size) {
				child.size();
			}
		});
		this.$.trigger('invalidate');
		this.screenFraction = i;
	}

	method currentInput {
		return this.focusManager.getCurrent();
	}

	method delegateFocus(child) {
		this.focusManager = child.focusManager;
	}

	method init {
		this.size();
	}

	method refresh {
		this.size();
	}

	on touchmove(e) {
		e.preventDefault();
	}

	method setMaxWidth(m) {
		this.maxWidth = m;
		this.size();
	}
}

def PageView(title) {
	html {
		<div>
			<div class='top-bar-container'>
				<div class='top-bar'>
					<span class='title'>$title</span>
					<span class='toolbar'></span>
				</div>
			</div>
			<div class='contents-container-wrapper'>
				<div class='contents-container'>

				</div>
			</div>
		</div>
	}

	my contents-container-wrapper {
		css {
			background; #0F0;
			width: 100%;
			position: absolute;
			overflow: hidden;
		}

		method size {
			$this.css('height', $parent.height() - (parent.$top-bar-container.css('display') == 'none' ? 0 : parent.$top-bar-container.height()));
		}
	}

	my contents-container {
		css {
			width: 100%;
			position: absolute;
		}
	}

	my top-bar-container {
		css {
			width: 100%;
			height: 50px;
			line-height: 50px;
			background-color: #222;
			color: #EEE;
			box-shadow: 1px 1px 1px rgba(0,0,0,0.1);
			-webkit-transform: translate3d(0,0,0);
			-webkit-backface-visibility: none;
		}
	}
	
	my top-bar {
		css {
			font-size: 20px;
			padding-left: 10px;
		}
	}

	my toolbar {
		css {
			float: right;
		}
	}	

	my title {
		css {
			font-size: .75em;
		}
	}

	method setContents(el) {
		this.$contents.html('');
		this.$contents.append(el);
	}

	method updateScroll(toScrollY) {
		var self = this;
		setTimeout(function() {
			var sy = scrollY || 0;
			if(self.scroll) {
				self.scroll.enabled = false;
				sy = self.scroll.y;
			}
			self.scroll = new IScroll(self.@contents-container-wrapper,{mouseWheel: true, startY: sy});
		},10);
	}

	extends {
		View
	}
}

def ListView {
	extends {
		PageView
	}

	properties {
		autoAddField: true
	}

	constructor {
		this.addFieldToTop = false;
		this.fieldType = 'MathTextField';
		this.$title.html('ListView');
		this.$.trigger('update');
	}

	on ready {
		if(this.autoAddField) this.addField();
	}

	on active {
		this.updateScroll();
	}

	method addField {
		var self = this;
		var field = elm.create(this.fieldType,this.focusManager);
		field.$.on('lost-focus',$.proxy(this.onFieldBlur,this));
		field.$.on('gain-focus',$.proxy(this.onFieldFocus,this));
		field.$.on('update',$.proxy(this.onFieldUpdate,this));
		if(this.addFieldToTop) {
			this.$items-list.prepend(field);
		} else {
			this.$items-list.append(field);
		}
		this.updateScroll();
		this.$.trigger('update');
		return field;
	}

	method needsField {
		return this.$items-list.children().toArray().filter(function(field) {
			return field.empty && field.empty();
		}).length == 0;
	}

	method onFieldFocus(e) {
		if(this.needsField()) {
			var f = this.addField();
		}
		this.$.trigger('update');
	}

	method onFieldBlur(e) {
		if(e.target.empty()) {
			this.updateScroll();
			e.target.$.remove();
		}
		if(this.needsField()) {
			this.addField();
		}
		this.$.trigger('update');
	}

	method onFieldUpdate(e) {
		if(this.needsField()) {
			this.addField();
		}
		this.$.trigger('field-update');
	}

	my contents-container {
		contents {
			[[items-list:List]]
		}
	}
}

def TabbedView {
	extends {
		View
	}

	properties {
		noKeyboard: true
	}

	contents {
		<div class='tab-bar'></div>
		<div class='tab-contents-container'></div>
	}

	constructor {
		this.tabs = [];
		this.addTab('Tab One',elm.create('PageView','Tab One'));
		this.addTab('Tab Two',elm.create('PageView','Tab Two'));
		this.addTab('Tab Three',elm.create('PageView','Tab Three'));
		this.addTab('Tab Four',elm.create('PageView','Tab Four'));
		this.addTab('Tab Five',elm.create('PageView','Tab Five'));
		this.addTab('Tab Six',elm.create('PageView','Tab Six'));
		this.$.find('.PageView .top-bar-container').hide();
	}

	on invalidate {
		this.renderTabs();
	}

	on ready {
		this.renderTabs();
	}

	method addTab(name,view) {
		this.tabs.push({name: name,view:view});
		this.$tab-contents-container.append(view);
		this.renderTabs();
	}

	method renderTabs {
		var currentView;
		if(this.selectedTab) currentView = this.selectedTab.view;
		this.$tab-bar.html('');
		for(var i=0;i<this.tabs.length;i++) {
			var t = this.tabs[i];
			var tab = elm.create('TabbedViewTab',t.name,t.view,this);
			this.$tab-bar.append(tab);
			var pxWidth = parseFloat($this.width());
			tab.$.css('width',pxWidth / this.tabs.length);
		}
		var currentViewTab;
		if(currentView) {
			currentViewTab = this.@tab-bar.$TabbedViewTab.toArray().filter(function(tab) {
				return tab.view == currentView;
			})[0];
		}
		if(currentViewTab) {
			this.select(currentViewTab);
		} else {
			this.select(this.@tab-bar.$TabbedViewTab.get(0));
		}
	}

	method select(tab) {
		this.$tab-contents-container.children().hide();
		if(this.selectedTab) {
			this.selectedTab.applyStyle('not-selected');
		}
		tab.applyStyle('selected');
		tab.view.$.show();
		this.selectedTab = tab;
	}

	my tab-bar {
		css {
			width: 100%;
			height: 50px;
			background: #EEE;
		}
	}

	my tab-contents-container {
		method size {
			this.$.css('height',root.$.height() - root.$tab-bar.height() - 4)
		}

		css {
			width: 100%;
			background: #FFF;
			padding-top: 4px;
		}
	}
}

def TabbedViewTab(label,view,tabView) {
	html {
		<div>$label</div>
	}

	extends {
		Button
	}

	css {
		background: #EEE:
		height: 50px;
		line-height: 50px;
		text-align: center;
		display: inline-block;
		cursor: pointer;
	}

	constructor {
		this.applyStyle('not-selected');
	}

	on invoke {
		this.tabView.select(this);
	}

	style selected {
		border-bottom: 4px solid #A33;
	}

	style active {

	}

	style default {

	}

	style not-selected {
		border-bottom: 4px solid #EEE;
	}
}

def SlideView {
	extends {
		View
	}

	contents {
		<div class='container'>

		</div>
	}

	css {
		postion: relative;
		-webkit-transition: -webkit-transform 0.2s ease-in-out;
	}

	my container {
		css {
			width: 100%;
			height: 100%;
			-webkit-transform: translate3d(0, 0, 0); // perform an "invisible" translation
		}

		method size {
			$this.children().each(function() {
				var child = this;
				if(child.size) child.size();
			});
			root.alignViews();
		}
	}

	constructor {
		this.currentIndex = 0;
		this.horizontal = true;
		this.viewFraction = 1;
		this.transitionTime = 300;
		this.transition = 'easeInOutQuart';
	}

	method setFragmentMode(left,right) {
		this.fragmentLeft = left;
		this.fragmentRight = right;
	}

	method addView(view) {
		if(this.$container.children().length == 0) {
			this.delegateFocus(view);
		}
		this.$container.append(view);
		this.alignViews();
		return view;
	}

	method views {
		return this.$container.children().toArray();
	}

	method alignViews {
		var self = this;
		this.$container.children().each(function(i,view) {
			view.$.css({
				'left': self.horizontalOffset(i),
				'top': self.verticalOffset(i)
			}); 
		});
	}

	on invalidate {
		if(this.horizontal) {
			this.$container.css('translateX', 0 - this.horizontalOffset(this.currentIndex));
		} else {
			this.$container.css('translateY', 0 - this.verticalOffset(this.currentIndex));
		}
	}

	method viewByIndex(index) {
		return this.$container.children().get(index);
	}

	method slideTo(index,callback) {
		var offset = 0;
		if(isNaN(index)) {
			// Must be a child rather than an index. Find the index.
			index = $(index).index();
		}
		index = Math.max(0,Math.min(index,this.$container.children().length - 1));
		offset = this.horizontal? this.horizontalOffset(index) : this.verticalOffset(index);
		var animObject = {};
		animObject[this.horizontal? 'translateX' : 'translateY'] = 0 - offset;
		this.$container.animate(animObject,this.transitionTime,this.transition,function() {
			if(callback) callback();
		});
		this.delegateFocus(this.viewByIndex(index));
		this.currentIndex = index;
	}

	method horizontalOffset(i) {
		if(this.horizontal) {
			return $this.width() * this.viewFraction * (i !== undefined? i : this.views().length);
		} else {
			return 0;
		}
	}

	method verticalOffset(i) {
		if(!this.horizontal) {
			return $this.height() * this.viewFraction * (i !== undefined? i : this.views().length);
		} else {
			return 0;
		}
	}
}

def SideMenuAppView(menuClass='SideMenu') {
	extends {
		View
	}

	contents {
		<div class='container'></div>
		<div class='touch-shield'></div>
	}

	css {
		overflow: visible;
		z-index: 2000;
	}

	my container {
		css {
			position: absolute;
			width: 100%;
			height: 100%;
			box-shadow: -5px 0px 5px rgba(0,0,0,0.25);
			z-index: 1;
		}
	}

	my touch-shield {
		css {
			position: absolute;
			width: 100%;
			height: 100%;
			box-shadow: -5px 0px 5px rgba(0,0,0,0.25);
			z-index: 2;
			background: #000;
			opacity: 0;
			display: none;
		}
	}

	constructor {
		this.container = this.@container;
		this.menuSwipeThreshold = 25;
		this.menu = elm.create(this.menuClass);
		$this.append(this.menu);
		Hammer(this.@touch-shield).on('tap',this.#tapped);
		Hammer(this).on('swiperight',this.#swipeRight);
		Hammer(this).on('dragstart',this.#dragStart);
		Hammer(this).on('drag',this.#dragged);
		Hammer(this).on('dragend',this.#dragEnd);
	}

	method addChild(x) {
		$(this.container).append(x);
	}

	method tapped(e) {
		if(this.menuOpen) {
			this.hideMenu();
		}
	}

	method swipeRight(e) {
		if(e.gesture.center.pageX < this.menuSwipeThreshold || true) {
			this.showMenu();
			e.gesture.stopDetect();
		}
	}

	method touchShieldLoop {
		if(parseFloat(this.$.css('translateX')) > 0 || this.touchShieldForceShow) {
			this.$touch-shield.show();
		} else {
			this.$touch-shield.hide();
		}
	}

	method setOverlay(view) {
		$this.append(view);
		view.relinquish = function() {
			self.overlay = undefined;
		}
		if(utils.tabletMode()) {
			view.$.css('translateX',0-this.menu.$.width());
		} else {
			view.$.css('translateX',0);
		}
		view.size();
		this.overlay = view;
	}


	method dragStart(e) {
		if(true) return;
		var tx = e.gesture.center.pageX;
		this._dragOrigin = tx;
		if(this.menuOpen || this.overlay) {
			if(e.gesture.direction == 'left') {
				this.hideMenu();
			}
			e.gesture.stopDetect();
		} else {
			if(tx > this.menuSwipeThreshold) {
				e.gesture.stopDetect();
			}
		}
	}

	method dragged(e) {
		if(!this._dragOrigin) this._dragOrigin = tx;
		if(this.menuOpen) return;
		var tx = e.gesture.center.pageX - this._dragOrigin;
		$this.css(
			'translateX',
			Math.min(Math.max(0,tx),this.menu.$.width())
		);
	}

	method dragEnd(e) {
		if(
			(e.gesture.direction == 'right' && e.gesture.velocityX > 0.1) || 
			(this._dragOrigin <= this.menuSwipeThreshold && e.gesture.center.pageX >= this.menu.$.width())
		) {
			this.showMenu();
		} else {
			this.hideMenu();
		}
		this._dragOrigin = null;
	}

	method showMenu(duration) {
		if(utils.tabletMode()) return;
		if(this.overlay) return;
		this.$touch-shield.show();
		this.menuOpen = true;
		duration = duration || 300;
		$this.animate(
		{
			'translateX': this.menu.$.width()
		}, duration, 'easeInOutQuart', function() {

		});

	}

	method hideMenu(duration) {
		if(utils.tabletMode()) return;
		var self = this;
		duration = duration || 300;
		$this.animate(
		{
			'translateX': 0
		}, duration, 'easeInOutQuart', function() {
			self.menuOpen = false;
			self.touchShieldForceShow = true;
			setTimeout(function() {
				self.$touch-shield.hide();
			},100);
		});	
	}

	method size(i) {
		i = i || this.screenFraction || 1;
		$this.height(utils.viewport().y * i);
		if(utils.tabletMode()) {
			this.isTabletMode = true;
			$this.css('translateX',this.menu.$.width());
			this.$container.width($this.width() - this.menu.$.width());
		} else {
			if(this.isTabletMode) {
				this.isTabletMode = false;
				this.hideMenu();
			}
		}
		this.$container.children().each(function(i,e) {
			if(e.size) {
				e.size();
			}
		});
	}


}

def SideMenu {
	extends {
		View
	}

	css {
		width: 75px;
		height: 100%;
		top: 0;
		padding-left: 50px;
		background: #222;
	}

	constructor {
		$this.css('left',0 - ($this.width() + 50));
	}

	on item-selected(e,item) {
		if(this.selected) {
			this.selected.$.trigger('deselect');
		}
		this.selected = item;
	}

	method selectByIndex(i) {
		this.$SideMenuItem.get(i).$.trigger('invoke');
	}

}

def SideMenuItem {
	html {
		<div>

		</div>
	}

	css {
		width: 100%;
		height: 100px;
		position: relative;
		background: #444;
		margin-bottom: 10px;
		cursor: pointer;
	}

	extends {
		TouchInteractive
	}

	on invoke {
		$this.parent().trigger('item-selected',this);
	}
}

def ColorView(color) {
	extends {
		View
	}

	css {
		background: $color;
	}
}

def List {
	html {
		<div></div>
	}

	css {
		width: 100%;
		height: 100%;
	}

	constructor {

	}

	method size {
		$this.children().each(function() {
			var child = this;
			if(child.size) child.size();
		})
	}
}

def SimpleListItem {
	html {
		<div></div>
	}

	extends {
		Button
	}

	css {
		width: 100%;
		padding: 20px;
		font-size: 14pt;
		border-bottom: #DDD;
		cursor: pointer;
	}

	style default {
		background: #FFF;
	}

	style active {
		background: #EEE;
	}
}

def Toolbar(stickToBottom,offset=0) {
	html {
		<div></div>
	}

	constructor {
		if(this.stickToBottom) {
			$this.css('bottom',this.offset);
		} else {
			$this.css('top',this.offset);
		}
	}

	css {
		position: absolute;
		width: 100%;
		height: 50px;
		line-height: 50px;
		padding-left: 10px;
		background: #FFF;
		box-shadow: 1px 1px 1px rgba(0,0,0,0.1);
		z-index: 1000;
	}
}


def ToolbarButton(label,callback) {

	html {
		<div>$label</div>
	}

	constructor {

	}

	on invoke {
		if(this.callback) this.callback();
	}

	css {
		font-size: 16px;
		display: inline;
		padding: 8px;
		padding-left: 10px;
		padding-right: 10px;
		cursor: pointer;
		color: #EEE;
		border-radius: 3px;
		text-shadow: 1px 1px 1px rgba(0,0,0,0.1);
		margin-right: 10px;
	}

	style default {
		background: #AAA;
		box-shadow: 1px 1px 1px rgba(0,0,0,0.1);
	}

	style active {
		background: #BBB;
		box-shadow: 1px 1px 1px rgba(0,0,0,0.2);
	}

	extends {
		Button
	}
}

def ToolbarButtonImportant(label,callback) {
	extends {
		ToolbarButton
	}

	style default {
		background: #A33;
		box-shadow: 1px 1px 1px rgba(0,0,0,0.1);
	}

	style active {
		background: #D55;
		box-shadow: 1px 1px 1px rgba(0,0,0,0.2);
	}
}


def Switch(left,right,willSyncTo) {
	html {
		<div>
			<div class='inner'> 
				<div class='handle'> </div>
				<div class='left-label label'>$left</div>
				<div class='right-label label'>$right</div>
			</div>
		</div>
	}

	css {
		display: inline-block;
		cursor: pointer;
		background: rgba(0,0,0,0.1);
		vertical-align: text-top;
		margin-right: 5px;
	}

	constructor {
		this.state = false;
		this.handle = this.my('handle');
		this.size();
	}

	method size(h) {
		this.height = h || this.height;
		$this.css(
			'height',
			this.height
		).css(
			'width',
			this.height * 2.5
		).css(
			'border-radius',
			this.height / 2
		);
		this.handle.size();
		this.my('left-label').size();
		this.my('right-label').size();
	}

	on invoke {
		this.flip();
	}

	method flip(state) {
		if(state == this.state) return;
		if(state === undefined || state === null) state = !this.state;
		this.state = state;
		if(this.state) {
			this.handle.$.animate({
				'left': this.$.width() - this.handle.$.width(),
			},250,'easeInOutQuart');
		} else {
			this.handle.$.animate({
				'left': 0
			},250,'easeInOutQuart');
		}
		if(this.willSyncTo) {
			eval(this.willSyncTo + ' = ' + this.state.toString());
		}
		$this.trigger('flipped');
	}

	method show {
		$this.show();
	}

	method hide {
		var bkg;
		$this.hide();
		// This is why we can't have nice things.
		$this.parent().css('opacity','0.99');
		setTimeout(function() {
			$this.parent().css('opacity','1');
		},10);
	}

	method sync(v) {
		if(v === undefined) {
			return;
		}
		if(v != this.state) {
			this.flip();
		}
	}

	my label {
		constructor {
			this.size();
		}

		method size {
			$this.css('font-size',(root.height / 2) + 'px');
			$this.css('line-height',(root.height) + 'px');
		}

		css {
			display: inline;
			text-align: center;
			color: #666;
			width: 50%;
			float: left;
		}
	}


	my inner {
		css {
			position: relative;
		}
	}

	my handle {
		constructor {
			this.size();
		}

		method size {
			$this.css(
				'border-radius',
				root.height / 2
			).css(
				'height',
				root.height
			).css(
				'width',
				root.height * 1.25
			);
			$this.css('left',
				root.state? root.$.width() - this.$.width() : 0
			);
		}

		css {
			position: absolute;
			background: #666;
		}
	}

	extends {
		TouchInteractive
		SyncSubscriber
	}
}

def LiveEvalButton(text) {
	html {
		<div>
			<div class='label'>$text</div>
		</div>
	}

	css {
		display: inline-block;
		cursor: pointer;
		vertical-align: text-top;
		margin-right: 5px;
		padding-left: 5px;
		padding-right: 5px;
	}

	constructor {
		this.state = false;
		this.label = this.my('label');
		this.size();
	}

	method size(h) {
		this.height = h || this.height;
		$this.css(
			'height',
			this.height
		).css(
			'border-radius',
			this.height / 2
		);
		this.label.size();
	}

	my label { 
		constructor {
			this.size();
		}

		method size {
			$this.css('font-size',(root.height / 2) + 'px');
			$this.css('line-height',(root.height) + 'px');
		}

		css {
			display: inline;
			text-align: center;
			color: #AAA;
			width: 50%;
			float: left;
		}
	}

	style default {
		text-shadow: 1px 1px 15px rgba(0,0,0,0.5);
		background: rgba(0,0,0,0);
	}

	style active {
		background: rgba(0,0,0,0.1);
	}

	extends {
		Button
	}
}

def Dialog(title,buttons,contents) {
	html {
		<div>
			<div class='overlay'></div>
			<div class='contents-wrap'>
				<div class='contents-container'>

				</div>
			</div>
		</div>
	}
	
	css {
		width: 100%;
		height: 100%;
		position: fixed;
		text-align: center;
		top: 0;
		left: 0;
		z-index: 2000;
	}

	constructor {
		this.buttons = this.buttons || [];
		this.$title.html(this.title);
		this.$toolbar.append(this.buttons);
		this.buttons.forEach(function(button) {
			button.$.on('invoke',self.buttonInvoked);
		});
		this.$contents.append(this.contents);
		this.fadeIn();
	}

	method fadeIn {
		var bullshit = false;
		if(bullshit) {
			this.$overlay.css('opacity',0).animate({
				'opacity': 0.8
			},0);
			this.$contents-container.css('translateY',-500).delay(100).animate({
				'translateY':-100
			},100,'easeInOutQuart',function() {
				$this.trigger('showing');
			});
		} else {
			this.$overlay.css('opacity',0.8);
			this.$contents-container.css('translateY',-100);
			$this.trigger('showing');
		}
	}

	method fadeOut {
		var bullshit = false
		if(bullshit) {
			self.$overlay.css('opacity',0.8).delay(500).animate({
				'opacity': 0
			},100);
			self.$contents-container.css('translateY',-100).animate({
				'translateY':-500
			},100,'easeInOutBack');
			setTimeout(function() {
				$this.hide().remove().trigger('removed');
			},300);
		} else {
			$this.hide().remove().trigger('removed');
		}
	}

	method cancel {
		if(self.cancelCallback) self.cancelCallback();
		self.fadeOut();
	}

	method buttonInvoked {p

	}

	my overlay {
		css {
			position: absolute;
			width: 100%;
			height: 100%;
			background: #000;
			opacity: 0.8;
			cursor: pointer;
		}
	}

	my contents-wrap {
		css {
			width: 100%;
			max-width: 600px;
			margin-left: auto;
			margin-right: auto;
			height: 100%;
			position: relative;
			-webkit-perspective: 500px;
		}
	}

	my contents-container {
		contents {
			<div class='title'> </div>
			<div class='contents'> </div>
			[[toolbar:Toolbar true]]
		}

		my toolbar {
			contents {

			}

			css {
				background: none;
				text-align: center;
			}
		}

		find .title {
			css {
				color: #333;
				padding: 10px;
				padding-left: 10px;
				font-size: 14pt;
			}
		}

		css {
			padding-top: 100px;
			width: 100%;
			background: #F9F9F9;
 			box-shadow: 1px 1px 1px rgba(0,0,0,0.1);
		}
	}

	my toolbar {
		css {
			box-shadow: none;
		}
	}

	my contents {
		css {
			padding-bottom: 50px;
		}
	}
}

def Prompt(title,callback,defaultValue) {
	extends {
		Dialog
	}

	my contents {
		contents {
			[[input:TextInput this.defaultValue || '']]
		}

		constructor {
			this.$input.focus();
		}
	}

	on showing {
		this.$input.focus();
	}

	method okay {
		if(self.callback) self.callback(self.$input.val(),self.fadeOut,function(s) {
			self.$title.html(s);
		});
	}

	my toolbar {
		contents {
			[[ToolbarButton root.cancelLabel || 'Cancel',root.cancel]]
			[[ToolbarButtonImportant root.okayLabel || 'Okay',root.okay]]
		}
	}
}

def MathPrompt(title,callback,fm) {
	extends {
		Dialog
	}

	my contents {
		contents {
			[[input:MathTextField]]
		}

		css {
			min-height: 80px;
		}

		constructor {
			this.@input.fm = root.fm;
			this.@input.takeFocus();
		}
	}

	my MathTextField {
		css {
			width: 100%;
			height: 40px;
			padding: 0px;
			box-shadow: none;
			border-right: none;
		}

		my MathInput {
			css {
				line-height: 40px;
				padding: 0px;
				padding-top: 10px;
				padding-bottom: 10px;
				box-shadow: none;
				-webkit-box-shadow: none;
			}
		}
	}

	css {
		height: 50%;
	}

	method okay {
		self.fadeOut();
		if(self.callback) {
			self.callback.call();
		}
	}

	my toolbar {
		contents {
			[[ToolbarButton root.cancelLabel || 'Cancel',root.cancel]]
			[[ToolbarButtonImportant root.okayLabel || 'Enter',root.okay]]
		}
	}
}

def Confirm(title,theContents,callback,okayLabel,cancelLabel) {
	extends {
		Dialog
	}

	my contents {
		contents {
			<p style='padding-left:10px'>$theContents</p>
		}
	}

	method okay {
		self.fadeOut();
		if(self.callback) {
			self.callback.call();
		}
	}

	my toolbar {
		contents {
			[[ToolbarButton root.cancelLabel || 'No',root.cancel]]
			[[ToolbarButtonImportant root.okayLabel || 'Yes',root.okay]]
		}
	}

}

def TextInput(defaultValue) {
	html {
		<input type='text' value='$defaultValue' autocorrect='off' autocapitalize='off'/>
	}

	css {
		box-sizing: border-box;
		margin-bottom: 15px;
		padding: 10px;
		padding-left: 15px;
		font-size: 16pt;
		outline: none;
		border-style: none;
		border: none;
		width: 100%;
	}

	style empty {
		color: #F00;
	}

	style not-empty {
		color: #222;
	}

	constructor {
		this.setStyle('empty');
	}

	on focus {
		if($this.val() == this.defaultValue) {
			$this.val('');
			this.setStyle('not-empty');
		}
	}

	on blur {
		if($this.val() == '') {
			$this.val(this.defaultValue);
			this.setStyle('empty');
		}
	}

	focus {
		border: 1px solid #CCC;
		padding-top: 9px;
		padding-bottom: 9px;
		padding-left: 14px;
	}
}

def TextSizer(input,initialSize) {
	html {
		<div>$input</div>
	}

	css {
		display: inline-block;
		font-size: $initialSize;
	}

	method size(width) {
		$('body').append(this);
		while($this.width() > width) {
			$this.css('font-size','-=1');
		}
		return $this.css('font-size');
		$this.remove();
	}
}