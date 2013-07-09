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

	method size(i) {
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
}

def PageView {
	html {
		<div>
			<div class='top-bar-container'>
				<div class='top-bar'>
					<span class='title'></span>
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
			$this.css('height', $parent.height() - 50);
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
			background-color: #DDD;
			box-shadow: 1px 1px 1px rgba(0,0,0,0.1);
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

	method updateScroll {
		var self = this;
		setTimeout(function() {
			var sy = 0;
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

	constructor {
		this.fieldType = 'MathTextfield';
		this.$title.html('ListView');
	}

	on ready {
		this.addField();
	}

	method addField {
		var self = this;
		var field = elm.create(this.fieldType,this.focusManager);
		field.$.on('lost-focus',$.proxy(this.onFieldBlur,this));
		field.$.on('gain-focus',$.proxy(this.onFieldFocus,this));
		field.$.on('update',$.proxy(this.onFieldUpdate,this));
		this.$items-list.append(field);
		this.updateScroll();
		return field;
	}

	method needsField {
		return this.$items-list.children().toArray().filter(function(field) {
			return field.empty();
		}).length == 0;
	}

	method onFieldFocus(e) {
		if(this.needsField()) {
			this.addField().takeFocus();
		}
	}

	method onFieldBlur(e) {
		if(e.target.empty()) {
			this.updateScroll();
			e.target.$.remove();
		}
		if(this.needsField()) {
			this.addField();
		}
	}

	method onFieldUpdate(e) {
		if(this.needsField()) {
			this.addField();
		}
	}

	my contents-container {
		contents {
			<div class='items-list List'>
			</div>
		}

		css {

		}
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
				child.size();
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
		})
	}
}

def FloatingToolbar {
	html {
		<div></div>
	}

	css {
		position: absolute;
		top: 0;
		width: 100%;
		height: 50px;
		line-height: 50px;
		padding-left: 10px;
		background: #FFF;
		box-shadow: 1px 1px 1px rgba(0,0,0,0.1);
	}
}


def ToolbarButton(label,callback) {

	html {
		<div>$label</div>
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

// Todo, move this definition to its own file

def REPLButton(text) {
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