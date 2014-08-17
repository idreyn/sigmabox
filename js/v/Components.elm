// Components that ought to live somewhere separate from Sigmabox because they are highly reusable.

def TouchInteractive {
	constructor {
		this._hammer = Hammer(this);
		this._hammer.on('tap',this.#tapped);
		this._hammer.on('hold',this.#held);
		this._hammer.on('touch',this.#touched);
		this._hammer.on('release',this.#released);
		this._hammer.on('dragged',this.#dragged);
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
		this._isTouchInBounds = false;
	}

	method held(e) {
		this._held = true;
		this.$.trigger('hold');
	}

	method touched(e) {
		if(!this.enabled) return;
		this.$.trigger('begin');
		this.$.trigger('active');
	}

	method released(e) {
		if(!this.enabled) return;
		if(this._isTouchInBounds) this.$.trigger('invoke');
		this.$.trigger('end');
		this.$.trigger('endactive');
		this._isTouchInBounds = false;
		this._held = false;
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
		this._size(i);
	}

	method _size(i) {
		if(this.ignoreSize) {
			console.log('ignoring',this);
			return;
		}
		if(this.maxWidth) $this.css('width',this.maxWidth.toString() + '%');
		if(i === undefined) {
			if(this.screenFraction === undefined) {
				i = 1;
			} else {
				i = this.screenFraction;
			}
		}
		$this.css(
			'height',
			$this.parent().height() * i
		);
		$this.find('*').each(function() {
			var child = this;
			if(child.size instanceof Function) {
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
		this.$.find('*').each(function() {
			if(this.focusManager) this.focusManager = child.focusManager;
		});
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

	on displayed {
		this.$MathInput.each(function() {
			this.refresh();
		});
	}

	method setMaxWidth(m) {
		this.maxWidth = m;
		this.size();
	}
}

def Stackable {
	css {
		position: relative;
	}
}

def PageView(title) {
	html {
		<div></div>
	}

	properties {
		useScrollbars: true,
	}

	contents {
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
	}

	my contents-container-wrapper {
		css {
			background; #0F0;
			width: 100%;
			height: 100%;
			position: absolute;
			overflow: hidden;
		}

		method size {
			$this.css('height', $parent.height() - (parent.$top-bar-container.css('display') == 'none' || parent.sizeOverToolbar? 0 : parent.$top-bar-container.height()));
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
			position: relative;
			z-index: 1;
			width: 100%;
			height: 50px;
			line-height: 50px;
			background-color: #222;
			color: #EEE;
			font-weight: 400;
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

	constructor {
		if(this.title) {
			this.$title.html(this.title);
		}
	}

	on invalidate {
		this.updateScroll();
	}

	method setContents(el) {
		this.$contents.html('');
		this.$contents.append(el);
	}

	method updateScroll(horiz) {
		if(!self.scroll) {
			self.scroll = new IScroll(self.@contents-container-wrapper,{
				scrollbars: self.useScrollbars,
				fadeScrollbars: true,
				mouseWheel: true,
				scrollX: horiz,
				useTransition: false
			});
			self.scroll.on('scroll',self._onScroll);
		} else {
			self.scroll.refresh();
		}
	}

	method _onScroll(e) {
		this.$.trigger('scroll');
	}

	extends {
		View
	}
}

def ReaderView {
	extends {
		PageView
	}

	my contents-container {
		css {
			position: relative;
			padding: 20px;
			box-sizing: border-box;
			max-width: 600px;
			margin-left: auto;
			margin-right: auto;
			font-size: 0.8em;
			line-height: 2em;
		}
	}

	constructor {
		this.$top-bar-container.hide();
		if(this.src) {
			this.load();
		}
	}

	method load(src) {
		src = src || this.src;
		$.get(src,function(res) {
			if(src.slice(-3) == '.md') {
				res = marked.parse(res);
				self.$contents-container.css('padding-top',0).css('padding-bottom',0);
			}
			self.$contents-container.html(res);
		});
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
		Hammer(this).on('dragstart',this.#dragStart);
		Hammer(this).on('dragend',this.#dragEnd);
	}

	on ready {
		if(this.autoAddField) this.addField();
	}

	on active {
		this.updateScroll();
	}

	method dragStart {
		self.$TouchInteractive.each(function() {
			this.enabled = false;
		});
	}

	method dragEnd {
		setTimeout(function() {
			self.$TouchInteractive.each(function() {
				this.enabled = true;
			});
		},10);
	}

	method addField(el,update) {
		var self = this;
		var field = self.create(this.fieldType,this.focusManager);
		field.$.on('lost-focus',$.proxy(this.onFieldBlur,this));
		field.$.on('gain-focus',$.proxy(this.onFieldFocus,this));
		field.$.on('update',$.proxy(this.onFieldUpdate,this));
		if(el) {
			$(el).after(field);
		} else {
			if(this.addFieldToTop) {
				this.$items-list.prepend(field);
			} else {
				this.$items-list.append(field);
			}
		}
		if(update) setTimeout(function() {
			this.updateScroll();
		},0);
		this.$.trigger('update');
		return field;
	}

	method needsField {
		return this.autoAddField && this.$items-list.children().toArray().filter(function(field) {
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
			e.target.$.addClass('field-removed').remove();
			this.updateScroll();
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

	contents {
		<div class='empty-notice'></div>
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
		if(!tab || tab == this.selectedTab) return;
		this.$tab-contents-container.children().hide();
		var newIndex = this.$tab-bar.children().index(tab);
		if(this.selectedTab) {
			var selectedIndex = this.$tab-bar.children().index(this.selectedTab);
			this.selectedTab.deselect(newIndex < selectedIndex);
		} else {
			var selectedIndex = 0;
		}
		tab.select(newIndex < selectedIndex);
		if(tab.view && tab.view.$) {
			tab.view.$.show();
		}
		this.selectedTab = tab;
	}

	my tab-bar {
		css {
			width: 100%;
			height: 50px;
			background: #222;
		}
	}

	my tab-contents-container {
		method size {
			this.$.css('height',root.$.height() - root.$tab-bar.height() - 4)
		}

		css {
			width: 100%;
			background: #FFF;
		}
	}
}

def TabbedViewTab(label,view,tabView) {
	html {
		<div>
			<div class='label'>$label</div>
			<div class='border-bottom'></div>
		</div>
	}

	extends {
		Button
	}

	css {
		position: relative;
		background: #222;
		color: #FFF;
		height: 50px;
		line-height: 50px;
		text-align: center;
		display: inline-block;
		cursor: pointer;
		overflow: hidden;
	}

	constructor {

	}

	on invoke {
		this.tabView.select(this);
	}

	method select(left) {
		var f = left ? 1 : -1;
		this.$border-bottom.show().css('translateX',f * $this.width()).animate({
			translateX: 0
		},200,'easeOutQuart');
	}

	method deselect(left) {
		var f = left ? -1 : 1;
		this.$border-bottom.css('translateX',0).animate({
			translateX: f * $this.width()
		},200,'easeOutQuart');
	}

	my border-bottom {
		css {
			display: none;
			position: absolute;
			bottom: 0px;
			width: 100%;
			height: 4px;
			background-color: #D55;
		}
	}

	style default {

	}

	style active {

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

	properties {
		animate: false
	}

	css {
		overflow: visible;
		postion: relative;
		//-webkit-transition: -webkit-transform 0.2s ease-in-out;
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
		if(this.@container.$.children().length == 0) {
			this.delegateFocus(view);
		}
		this.@container.$.append(view);
		this.alignViews();
		return view;
	}

	method removeView(view) {
		if(!isNaN(view)) {
			view = self.views()[view];
		}
		if(!self.$.has(view)) return;
		var target;
		if(view.$.prev().length) {
			target = view.$.prev().get(0);
		} else if(view.$.next().length) {
			target = view.$.next().get(0);
		} else {
			finalize();
		}
		if(target) {
			self.slideTo(target,finalize);
		} else {
			finalize();
		}

		function finalize() {
			if(target) {
				self.delegateFocus(target);
			}
			view.$.remove();
		}
	}

	method views {
		return this.@container.$.children().toArray();
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
		return;
		if(this.horizontal) {
			this.@container.$.css('translateX', 0 - this.horizontalOffset(this.currentIndex));
		} else {
			this.@container.$.css('translateY', 0 - this.verticalOffset(this.currentIndex));
		}
	}

	method viewByIndex(index) {
		return this.@container.$.children().get(index);
	}

	method slideTo(index,callback,time) {
		var offset = 0,
			target;
		if(isNaN(index)) {
			// Must be a child rather than an index. Find the index.
			target = index;
			index = $(index).index();
		} else {
			target = this.viewByIndex(index);
		}
		index = Math.max(0,Math.min(index,this.$container.children().length - 1));
		offset = this.horizontal? this.horizontalOffset(index) : this.verticalOffset(index);
		var animObject = {};
		animObject[this.horizontal? 'translateX' : 'translateY'] = 0 - offset;
		if(this.animate) {
			this.@container.$.animate(animObject,time !== undefined? time : this.transitionTime,this.transition,function() {
				if(callback) callback();
			});
		} else {
			this.@container.$.css(animObject);
			if(callback) callback();
		}
		if(target.noKeyboard) {
			this.noKeyboard = true;
			app.hideKeyboard();
		} else {
			this.noKeyboard = false;
			app.showKeyboard();
		}
		this.delegateFocus(target);
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
		z-index: 1001;
		-webkit-transition: -webkit-transform 0.2s;
	}

	style no-animate {
		-webkit-transition: none;
	}

	style animate {
		-webkit-transition: -webkit-transform 0.2s;	
	}

	my container {
		html {
			<div></div>
		}

		css {
			position: absolute;
			width: 100%;
			height: 100%;
			box-shadow: -5px 0px 5px rgba(0,0,0,0.25);
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
		this.menuSwipeThreshold = 50;
		this.menu = elm.create(this.menuClass);
		$this.append(this.menu);
		if(!utils.tabletMode()) {
			Hammer(this.@touch-shield).on('tap',this.#tapped);
			Hammer(this).on('dragstart',this.#dragStart);
			Hammer(this).on('drag',this.#dragged);
			Hammer(this).on('dragend',this.#dragEnd);
		}
	}

	method addChild(x) {
		$(this.container).append(x);
	}

	method tapped(e) {
		if(this.menuShown && !utils.tabletMode()) {
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
		view.$.trigger('ready');
		if(utils.tabletMode()) {
			view.$.width(this.viewWidth());
			view.flyIn();
		} else {
			view.flyIn();
		}
		view.size();
		this.overlay = view;
	}


	method dragStart(e) {
		if(e.gesture.direction == 'up' || e.gesture.direction == 'down') {
			this._ignoreDrag = true;
			return;
		}
		var tx = e.gesture.center.pageX;
		this._dragOrigin = tx;
		if(this.menuShown || this.overlay) {
			if(e.gesture.direction == 'left') {
				this.hideMenu();
			}
			e.gesture.stopDetect();
		} else {
			if(tx > this.menuSwipeThreshold) {
				this._ignoreDrag = true;
			} else {
				this.applyStyle('no-animate');
			}
		}
	}

	method dragged(e) {
		if(utils.tabletMode() || this.menuShown || this._ignoreDrag) {
			return;
		}
 		if(!this._dragOrigin) this._dragOrigin = tx;
		var tx = e.gesture.center.pageX - this._dragOrigin;
		$this.css(
			'translateX',
			Math.min(Math.max(0,tx),this.menu.$.width())
		);
	}

	method dragEnd(e) {
		if(
			!this._ignoreDrag && 
			((e.gesture.direction == 'right' && e.gesture.velocityX > 0.1) || 
			(this._dragOrigin <= this.menuSwipeThreshold && e.gesture.center.pageX >= this.menu.$.width()))
		) {
			this.showMenu();
		} else {
			if(!this._ignoreDrag) {
				this.hideMenu();
			}
		}
		this.applyStyle('animate');
		this._ignoreDrag = false;
		this._dragOrigin = null;
	}

	method showMenu(duration) {
		if(utils.tabletMode()) return;
		if(this.overlay) return;
		this.$touch-shield.show();
		this.menuShown = true;
		duration = duration || 300;
		$this.css('translateX',this.menu.$.width());
	}

	method hideMenu(duration) {
		if(utils.tabletMode()) return;
		var self = this;
		duration = duration || 300;
		$this.css('translateX',0);
		setTimeout(function() {
			self.menuShown = false;
			self.touchShieldForceShow = true;
			self.$touch-shield.hide();
		},100);
	}

	method toggleMenu {
		if(self.menuShown) {
			self.hideMenu();
		} else {
			self.showMenu();
		}
	}

	method viewWidth() {
		return this.$.width() - (utils.tabletMode() ? this.menu.$.width() : 0);
	}

	method size(i) {
		if(i === undefined) {
			if(this.screenFraction === undefined) {
				i = 1;
			} else {
				i = this.screenFraction;
			}
		}
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
			this.$container.width($this.width());
		}

		if(this.overlay) {
			this.overlay.$.width(this.viewWidth());
			this.overlay.$.height(this.$.height());
		}

		this.$SideMenu.get(0).size();

		this.$container.children().each(function(i,e) {
			if(e.size) {
				e.size();
			}
		});
	}
}

def SideMenu {
	extends {
		PageView
	}

	properties {
		useScrollbars: false
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

	method size {
		this.updateScroll();
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
		if(this.parent('SideMenuAppView').menuItemsDisabled) return;
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
		box-sizing: border-box;
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
		z-index: 1;
	}
}


def ToolbarButton(label,callback) {

	html {
		<div><span class='label'>$label</span></div>
	}

	constructor {

	}

	method setLabel(l) {
		this.label = l;
		this.$label.html(l);
	}

	on invoke {
		if(this.callback) this.callback();
	}

	css {
		font-size: 14px;
		display: inline;
		padding: 8px;
		padding-left: 10px;
		padding-right: 10px;
		cursor: pointer;
		color: #EEE;
		border-radius: 20px;
		text-shadow: 1px 1px 1px rgba(0,0,0,0.1);
		margin-right: 10px;
	}

	style default {
		background: #333;
		// box-shadow: 1px 1px 1px rgba(0,0,0,0.1);
	}

	style active {
		background: #444;
		// box-shadow: 1px 1px 1px rgba(0,0,0,0.2);
	}

	extends {
		Button
	}
}

def ToolbarButtonDropdown(label) {
	extends {
		ToolbarButton
	}

	properties {
		autoLabel: true
	}

	contents {
		<div class='dropdown'></div>
	}

	css {
		position: relative;
	}

	on invoke(e) {
		this.open = !this.open;
		if(this.open) {
			this.showMenu();
		} else {
			this.hideMenu();
		}
	}

	method showMenu {
		if(false) {
			this.$dropdown.css('opacity',0).show().css('translateY',-200).animate({
				'opacity': 1,
				'translateY': 0
			},200,'easeOutQuart');
		} else {
			this.$dropdown.show();
		}
		this.$.css('border-bottom-left-radius',0).css('border-bottom-right-radius',0);
	}

	method hideMenu {
		if(false) {
			this.$dropdown.css('translateY',0).animate({
				'opacity': 0,
				'translateY': -200
			},200,'easeOutQuart').delay(200);
		} else {
			this.$dropdown.hide();
		}
		this.$.css('border-bottom-left-radius',20).css('border-bottom-right-radius',20);
	}

	method select(o) {
		var text = o.$.html();
		if(this.autoLabel) this.setLabel(text);
		this.$.trigger('select',text);
	}

	method setOptions(arr) {
		this.@dropdown.setOptions(arr);
	}

	my dropdown {
		css {
			position: absolute;
			top: 30px;
			right: 0px;
			background: #333;
			display: none;
			color: #FFF;
			text-shadow: none;
			font-size: 16px;
			border-radius: 10px;
			border-top-right-radius: 0px;
			overflow: hidden;
		}

		method setOptions(items) {
			root.select(items.map(function(i) {
				return self.addOption(i);
			}).shift());
		}

		method addOption(label) {
			var o = root.create('dropdown-item');
			o.$.html(label).on('invoke',function() {
				root.select(o);
			});
			this.$.append(o);
			return o;
		}
	}

	my dropdown-item {
		html {
			<div></div>
		}

		extends {
			Button
		}

		style default {
			background: none;
		}

		style active {
			background: #444;
		}

		on invoke(e) {
			e.stopPropagation();
		}

		css {
			text-align: center;
			padding: 5px;
			min-width: 100px;
			height: 40px;
			line-height: 40px;
		}
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


def ToolbarButtonTransparent(label,callback) {
	extends {
		ToolbarButton
	}

	style default {
		background: rgba(0,0,0,0.1);
	}

	style active {
		background: rgba(0,0,0,0.2);
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
		border-radius: 1000px;
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
		var bullshit = true;
		if(bullshit) {
			this.$overlay.css('opacity',0).animate({
				'opacity': 0.8
			},100);
			this.$contents-container.css('translateY',-500).delay(100).animate({
				'translateY':-100
			},300,'easeInOutQuart',function() {
				$this.trigger('showing');
			});
		} else {
			this.$overlay.css('opacity',0.8);
			this.$contents-container.css('translateY',-100);
			$this.trigger('showing');
		}
	}

	method fadeOut {
		var bullshit = true;
		if(bullshit) {
			self.$overlay.css('opacity',0.8).animate({
				'opacity': 0
			},100);
			self.$contents-container.css('translateY',-100).animate({
				'translateY':-500
			},300,'easeInOutBack');
			setTimeout(function() {
				$this.hide().remove().trigger('removed');
			},300);
		} else {
			$this.hide().remove().trigger('removed');
		}
		if(app.mode.noKeyboard) {
			app.hideKeyboard();
		}
	}

	method cancel {
		if(self.cancelCallback) self.cancelCallback();
		self.fadeOut();
	}

	my overlay {
		css {
			position: absolute;
			width: 100%;
			height: 100%;
			background: #000;
			opacity: 0.8;
			cursor: pointer;
			pointer-events: none;
		}
	}

	on touchmove(e) {
		e.preventDefault();
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
			[[input:TextInput '']]
		}

		constructor {
			this.$input.val(root.defaultValue);
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

def MathPrompt(title,callback,focusManager) {
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
			app.useKeyboard('main');
			this.@input.focusManager = root.focusManager;
			this.@input.takeFocus();
		}
	}

	my MathTextField {
		css {
			width: 100%;
			height: 60px;
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
		z-index: 1000;
	}

	method okay {
		var p = new Parser(),
			res = p.parse(self.@input.contents()).valueOf(new Frame);
		if(self.callback) self.callback(res,self.fadeOut,function(s) {
			self.$title.html(s);
		},self);
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
		<input type='text' value='$defaultValue' autocorrect='off' autocapitalize='off' readonly='readonly'/>
	}

	css {
		box-sizing: border-box;
		margin-bottom: 15px;
		margin-top: 0;
		padding: 10px;
		padding-left: 15px;
		font-size: 16pt;
		outline: none;
		border: none;
		width: 100%;
	}

	style empty {
		color: #DDD;
	}

	style not-empty {
		color: #222;
	}

	on focus {
		if($this.val() == this.defaultValue) {
			$this.val('');
			this.setStyle('not-empty');
		}
        window.scrollTo(0, 0);
        document.body.scrollTop = 0;
	}

	on blur {
		if($this.val() == '') {
			$this.val(this.defaultValue);
			this.setStyle('empty');
		}
	}

	focus {
		box-sizing: border-box;
		border: 1px solid #CCC;
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
		background-size: cover;
	}

	on ready {
		this.flyOut();
	}

	method behindKeyboard {
		this.$.css('z-index',1000);
	}

	method frontOfKeyboard {
		this.$.css('z-index',1001);
	}

	method flyOut {
		app.root.overlay = null;
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
				$this.css('-webkit-transition','-webkit-transform 0.1s ease-out');
				$this.css('translateX',0);
				break;
			case 'left':
				$this.css('-webkit-transition','-webkit-transform 0.1s ease-out');
				$this.css('translateX',0);
				break;
			case 'top':
				$this.css('-webkit-transition','-webkit-transform 0.2s ease-out');
				$this.css('translateY',0);
				break;
			case 'bottom': 
				$this.css('-webkit-transition','-webkit-transform 0.2s ease-out');
				$this.css('translateY',0);
				break;
		}
		$this.show();
	}

	on removed {
		this.flyOut();
		setTimeout(function() {
			if(!self.persist) $this.remove();
			if(self.relinquish) self.relinquish.call(self);
		},1000)
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

def Pull {
	properties {
		pullDirection: 'down',
		pullMaxHeight: 300,
		pullConstant: 250
	}

	constructor {
		Hammer(this).on('dragstart',this.#_dragStart);
		Hammer(this).on('drag',this.#_dragged);
		Hammer(this).on('dragend',this.#_dragEnd);
	}

	method _dragStart(e) {
		this._dragOrigin = e.gesture.center.pageY;
		this.pullCancel = false;
		if(e.gesture.direction != this.pullDirection) {
			this.pullCancel = true;
		}
		if(!this.pullCancel) this.$.trigger('pullStart',{originY: this._dragOrigin});
	}

	method _dragged(e) {
		if(this.pullCancel) return;
		if(this.pullDirection == 'down') {
			var y = Math.abs(Math.max(e.gesture.center.pageY - self._dragOrigin,0));
		} else {
			var y = Math.abs(Math.min(e.gesture.center.pageY - self._dragOrigin,0));
		}
		var k = this.pullConstant;
		var translateY = (this.pullDirection == 'down' ? 1 : -1 ) * Math.round(this.pullMaxHeight * (1 - Math.exp(-y/k)));
		$this.css(
			'translateY',
			translateY
		);
		this.pullY = y;
		this.pullTranslateY = translateY;
		this.$.trigger('pullUpdate',{y: y,translateY: translateY});
	}

	method _dragEnd(e) {
		if(this.pullCancel) return;
		$this.css(
			'translateY',
			0
		);
		this.$.trigger('pullEnd',{y: this.pullY,translateY: this.pullTranslateY});
	}
}

def PullHoriz {
	properties {
		pullDirection: 'left',
		pullMaxWidth: 200,
		pullConstant: 250
	}

	constructor {
		Hammer(this).on('dragstart',this.#_dragStart);
		Hammer(this).on('drag',this.#_dragged);
		Hammer(this).on('dragend',this.#_dragEnd);
	}

	method _dragStart(e) {
		this._dragOrigin = e.gesture.center.pageX;
		this.pullCancel = false;
		if(e.gesture.direction != this.pullDirection) {
			this.pullCancel = true;
		}
		if(!this.pullCancel) this.$.trigger('pullStart',{originX: this._dragOrigin});
	}

	method _dragged(e) {
		if(this.pullCancel) return;
		if(this.pullDirection == 'right') {
			var x = Math.abs(Math.max(e.gesture.center.pageX - self._dragOrigin,0));
		} else {
			var x = Math.abs(Math.min(e.gesture.center.pageX - self._dragOrigin,0));
		}
		var k = this.pullConstant;
		var translateX = (this.pullDirection == 'right' ? 1 : -1 ) * Math.round(this.pullMaxWidth * (1 - Math.exp(-x/k)));
		$this.css(
			'translateX',
			translateX
		);
		this.pullX = x
		this.pullTranslateX = translateX;
		this.$.trigger('pullUpdate',{x: x,translateX: translateX});
	}

	method _dragEnd(e) {
		if(this.pullCancel) return;
		$this.css(
			'translateX',
			0
		);
		this.$.trigger('pullEnd',{x: this.pullX,translateX: this.pullTranslateX});
	}
}

def PullIndicator(src,owner) {
	html {
		<div>
			<div class='inner'>
				<div class='label'></div>
			</div>
		</div>
	}

	properties {
		pullMin: 35
	}

	css {
		width: 100%;
		background: #CCC;
		position: absolute;
		top: 0;
		text-align: center;
		-webkit-transition: background-color 0.05s;
	}

	my inner {
		css {
			position: relative;
			width : 100%;
			height: 100%;
			overflow: hidden;
		}
	}

	my label {
		css {
			position: absolute;
			width: 100%;
			left: 0px;
			text-align: center;
			font-size: 20px;
			color: #FFF;
			display: none;
		}
	}

	constructor {
		this.owner.$.on('pullUpdate',this.#indPullUpdated);
		this.owner.$.on('pullEnd',this.#indPullEnded);
		this.$.css('background-color',this.src[0].color);
		// Inverts the function mapping the actual pull distance to the displacment for Pulls
		// maxY is how far you have to pull the thing to get it (1 - 0.01) = 99% of the way there.
		this.pullMax = -this.owner.pullConstant * Math.log(0.01);
		this.size();
	}

	method setColorTransitionSpeed(s) {
		this.$.css('-webkit-transition','background-color ' + s.toString() + 's')	
	}

	method indPullUpdated(e,data) {
		var l = this.$label;
		l.css('bottom', (data.translateY / 2) - 10);
		if(Math.abs(data.translateY) > this.pullMin) {
			l.show();
		} else {
			l.hide();
		}
		var index = Math.min(this.src.length - 1,Math.round(this.src.length * (data.y - this.pullMin) / this.pullMax));
		if(index >= 0 && index < this.src.length) {
			this.current = this.src[index];
			l.html(this.current.label);
			this.$.css('background-color',this.current.color);
		} else {
			this.current = null;
		}
	}

	method indPullEnded(e,data) {
		if(this.current) {
			this.owner.$.trigger(this.current.event);
		}
	}

	method size {
		this.$.css('height',this.owner.pullMaxHeight)
		this.$.css('top',0 - this.owner.pullMaxHeight);
	}
}

def PullIndicatorHoriz(src,owner) {
	html {
		<div>
			<div class='inner'>
				<div class='label'></div>
			</div>
		</div>
	}

	properties {
		pullMin: 40
	}

	css {
		height: 100%;
		background: #CCC;
		position: absolute;
		top: 0;
		-webkit-transition: background-color 0.5s;
	}

	my inner {
		css {
			position: relative;
			width : 100%;
			height: 100%;
			overflow: hidden;
		}
	}

	my label {
		css {
			background-repeat: no-repeat;
			background-position: center center;
			position: absolute;
			width: 100%;
			height: 100%;
			left: 0px;
			font-size: 16px;
			color: #FFF;
		}
	}

	constructor {
		this.owner.$.on('pullUpdate',this.#indPullUpdated);
		this.owner.$.on('pullEnd',this.#indPullEnded);
		this.$.css('background-color',this.src[0].color);
		// Inverts the function mapping the actual pull distance to the displacment for Pulls
		// maxY is how far you have to pull the thing to get it (1 - 0.01) = 99% of the way there.
		this.pullMax = -this.owner.pullConstant * Math.log(0.01);
		this.size();
	}

	method setColorTransitionSpeed(s) {
		this.$.css('-webkit-transition','background-color ' + s.toString() + 's')	
	}

	method indPullUpdated(e,data) {
		var l = this.$label;
		l.css('width',Math.abs(data.translateX));
		if(Math.abs(data.translateX) > this.pullMin) {
			l.show();
		} else {
			l.hide();
		}
		var index = Math.min(this.src.length - 1,Math.round(this.src.length * (data.x - this.pullMin) / this.pullMax));
		if(Math.abs(data.translateX) > this.pullMin && index >= 0 && index < this.src.length) {
			this.current = this.src[index];
			l.css('background-image', 'url(' + this.current.label + ')')
			l.css('background-repeat','no-repeat').css('background-position','center center').css('background-size',Math.min($this.height()/2,30));
			this.$.css('background-color',this.current.color);
		} else {
			this.current = null;
		}
	}

	method indPullEnded(e,data) {
		if(this.current) {
			this.owner.$.trigger(this.current.event);
		}
	}

	method size {
		this.$.css('width',this.owner.pullMaxWidth)
		this.$.css('right',0 - this.owner.pullMaxWidth);
	}
}

def SelectBox(fullWidth) {
	html {
		<div class='shadow'>
			<div class='display'>Selected</div>
			<div class='dots'>...</div>
		</div>
	}

	properties {
		fillWidth: 1
		maxWidth: Infinity
	}

	css {
		display: inline-block;
		margin: 10px;
		background: #FFF;
		cursor: pointer;
		border-radius: 20px;
		height: 60px;
		overflow: hidden;
	}

	my display {
		css {
			height: 100%;
			display: inline-block;
			padding-left: 10px;
			height: 100%;
			line-height: 60px;
		}
	}

	my dots {
		extends {
			Button
		}

		css {
			text-align: center;
			color: #FFF;
			float: right;
			background: #696;
			height: 100%;
			line-height: 60px;
			padding-left: 10px;
			padding-right: 10px;
		}

		style default {
			background: #696;
		}

		style active {
			background: #6a6;
		}
	}

	method size {
		var w;
		if(this.fullWidth) {
			this.$.css('margin',0);
			w = this.$.parent().width();

		} else {
			w = (this.$.parent().width() * this.fillWidth) - parseFloat($this.css('margin-left')) - parseFloat(this.$display.css('padding-left'));
		}
		var h = this.$.height();
		var mainWidth;
		w = Math.min(w,this.maxWidth);
		mainWidth = w - h;
		this.$.css('width',w);
		this.$dots.css('width',h/2);
	}
}

def InlineInteractive {
	html {
		<div></div>
	}

	extends {
		Button
	}

	css {
		cursor: pointer;
		font-weight: 200;
		font-style: italic;
		display: inline-block;
		padding: 5px;
		line-height: 2em;
		border-radius: 1000px;
	}

	constructor {
		this.$.trigger('ready');
	}

	style default {
		background-color: #CCF;
	}

	style active {
		background-color: #DDF;
	}
}

def InlineNumber {
	extends {
		InlineInteractive
	}

	style default {
		background-color: #DB8;
	}

	style active {
		background-color: #EC9;
	}	

	constructor {
		this.applyStyle('default');
	}

	properties {
		roundTo: 3
	}

	method display(n) {
		var nr = Functions.round(n,this.roundTo);
		if(nr == 0 || nr.toString().length > 12) {
			this.$.html(n.toPrecision(this.roundTo));
		} else {
			this.$.html(nr.toString());
		}
		this.data = new Value(n);
	}

	on invoke {
		app.data.initVariableSave('store',this.data);
		app.useKeyboard('variables');
	}
}

def InlineMatrix {
	extends {
		InlineInteractive
	}

	css {
		vertical-align: middle;
		border-radius: 10px;
	}

	style default {
		background-color: #DB8;
	}

	style active {
		background-color: #EC9;
	}	

	constructor {
		this.applyStyle('default');
	}

	method display(m) {
		this.$.html(m.toTable());
		this.data = m;
	}

	on invoke {
		app.data.initVariableSave('store',this.data);
		app.useKeyboard('variables');
	}
}

def InlineNumberPicker {
	extends {
		InlineInteractive
	}

	style default {
		background-color: #BEA;
	}

	style active {
		background-color: #CFB;
	}	

	constructor {
		this.applyStyle('default');
		this.data = null;
	}

	method choose(n) {
		this.$.html(n.toString());
		this.data = new Value(n);
		this.$.trigger('choose',n);
	}

	on invoke {
		app.mathPrompt(this.messageText || 'Input a number',function(res,close,tryAgain) {
			if(self.filter) {
				var fres = self.filter(res);
				if(fres === true) {
					close();
					self.choose(res);
				} else {
					tryAgain(fres);
				}
			} else {
				close();
				self.choose(res);
			}
		},app.mode.focusManager);
	}
}

def InlineMatrixPicker {
	extends {
		InlineInteractive
	}

	css {
		vertical-align: middle;
		border-radius: 10px;
	}

	style default {
		background-color: #BEA;
	}

	style active {
		background-color: #CFB;
	}	

	constructor {
		this.applyStyle('default');
		this.data = null;
	}

	method choose(n) {
		this.$.html(n.toTable());
		this.data = n;
		this.$.trigger('choose',n);
	}

	properties {
		messageText: 'Input a matrix. It may be easier to save it in a variable first.'
	}

	method filter(x) {
		if(x instanceof Matrix) {
			return true;
		} else {
			return "That's not a matrix.";
		}
	}


	on invoke {
		app.mathPrompt('Input a matrix. You may want to use [brackets] or a stored variable.',function(res,close,tryAgain) {
			if(self.filter) {
				var fres = self.filter(res);
				if(fres === true) {
					close();
					self.choose(res);
				} else {
					tryAgain(fres);
				}
			} else {
				close();
				self.choose(res);
			}
		},app.mode.focusManager);
	}
}


def InlineListPicker {
	extends {
		InlineInteractive
	}

	on invoke {
		app.overlay(elm.create('ListChoiceView',function(res) {
			self.choose(res);
		}));
	}

	method choose(list) {
		this.$.html(list.name);
		this.data = list;
		this.$.trigger('choose',list);
	}
}

def InlineChoice {
	constructor {
		if(this.defaultSelect) this.select(this.$item.get(0));
	}

	method select(el) {
		if(this.selected) {
			this.selected.deselect();
		}
		this.selected = el;
		this.selected.select();
		this.$.trigger('choice');
	}

	css {
		margin-top: 1em;
	}

	my item {
		extends {
			InlineInteractive
		}

		on invoke {
			root.select(this);
			this.$.trigger('choose',this);
		}

		method select {
			this.setStyle('default','background','#DDD');
			this.applyStyle('default');
		}

		method deselect {
			this.setStyle('default','background','#F5F5F5');
			this.applyStyle('default');
		}

		style default {
			background: #F5F5F5;
		}

		style active {
			background: #DDD;
		}

		constructor {
			this.applyStyle('default');
		}
	}
}

def NoSwipe {
	constructor {
		Hammer(this).on('swiperight',this.#swiped);
	}

	method swiped(e) {
		e.stopPropagation();
	}
}

def Shake {
	properties {
		times: 2,
		duration: 100,
		amplitude: 0.2,
		property: 'rotate',
		effect: 'linear'
	}

	method shake {
		var perDuration = this.duration / (2 * this.times);
		for(var i=0;i<this.times;i++) {
			var props1 = {};
			props1[this.property] = this.amplitude;
			this.$.animate(props1,perDuration,this.effect);
			var props2 = {};
			props2[this.property] = 0;
			this.$.animate(props2,perDuration,this.effect);
			var props3 = {};
			props3[this.property] = 0 - this.amplitude;
			this.$.animate(props3,perDuration,this.effect);
			var props4 = {};
			props4[this.property] = 0;
			this.$.animate(props4,perDuration,this.effect);
		}
	}
}