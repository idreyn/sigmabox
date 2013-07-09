def Keyboard(keyboardSource) {
	html {
		<div class='sb-keyboard'> 
			<div class='middle'>
				<div class='inner'>
					<div class='spacer'> </div>
				</div>
			</div>
		</div>
	}
	
	find .inner {
		css {
			width: 100%;
			height: 100%;
			position: relative;
			overflow: hidden;
		}
	}
	
	find .middle {
		css {
			width: 100%;
			height: 100%;
			position: relative;
			overflow: hidden;
		}
	}
	
	find .spacer {
		css {
			width: 400px;
			height: 100px;
			right: 0px;
			position: absolute;
		}
	}
	
	css {
		position: absolute;
		bottom: 0px;
		width: 100%;
		background: #1b1b1b;
		-webkit-overflow-scrolling: touch;
		z-index: 1000;
	}

	on touchmove(e) {
		e.preventDefault();
	}
	
	constructor {
		this.size();
	}
	
	method slideUp(n,e) {
		$this.show().css(
			'bottom',
			0-parseInt($this.css('height'))
		).delay(100).animate({
			'bottom': 0,
		}, {
			duration: n || 300,
			easing: e || 'easeOutQuart'
		});
	}

	method slideDown(n,e) {
		$this.show().css(
			'bottom',
			0
		).delay(100).animate({
			'bottom': 0-parseInt($this.css('height')),
		}, {
			duration: n || 300,
			easing: e || 'easeInQuart'
		});
	}
	
	method init() {
		this.createKeys();
	}
	
	method size(i) {
	 	i = i || this.screenFraction || 0.5;
		$this.css(
			'height',
			app.utils.viewport().y * i
		).css(
			'bottom',
			0
		);
		this.screenFraction = i;
		if(this.hasKeys) this.positionKeys();
	}
	
	method positionKeys() {
		var minKeyWidth = 80,
			padding = 4,
			keysX = this.totalColumns,
			keysY = 5,
			kw = ($this.width() - padding * (keysX - 1)) / keysX,
			kh = ($this.height() - padding * (keysY)) / keysY,
			self = this,
			last;
		$this.find('.inner').find('.Key').each(function(i,key) {
			key.position(kw,kh,padding);
			last = key;
		});
		$this.find('.spacer').css('left',last.$.offset().left + last.$.width()).css(
			'width',
			padding
		);
		this.keyWidth = kw;
		this.keyHeight = kh;
		this.padding = padding;
	}
		
	method createKeys() {
		var inner = $this.find('.inner'),
			self = this;
		this.keys = [];
		app.r.loadXML(this.keyboardSource, function(d) {
			var maxCol = 0;
			$(d).find('key').each(function(i,key) {
				var k = elm.create('Key',key,this);
				if(parseInt($(key).attr('col')) > maxCol) maxCol = parseInt($(key).attr('col'));
				$(inner).append(k);
				self.keys.push(k);
			});
			self.totalColumns = maxCol;
			self.hasKeys = true;
			self.positionKeys();
		});
	}

	method getKeyByName(name) {
		return this.keys.filter(function(k) {
			return k.name == name;
		})[0];
	}
	
	method getKeys() {
		return $this.find('.sb-keyboard-key');
	}
	
	method keyPressed(key) {
		if(key != this.currentKey) {
			if(this.currentKey) $(this.currentKey).mouseup();
			this.currentKey = key;
		}
	}
	
	method jakeStark(peen) {
		return peen;
	}
	
	method snapBack {
		var interval = (this.padding + this.keyWidth);
	}
}

def Key(_keyData,keyboard) {

	html {
		<div class='shadow'> 
			<div class='bar'></div>
			<div class='label'> </div>
		</div>
	}
	
	on invoke {
		if(this.activeSubkey().attr('variable')) {
			if(app.storage.varSaveMode) {
				app.storage.setVariable(
					this.activeSubkey().attr('variable'),
					app.mode.result()
				);
				app.popNotification(
					'Set ' + this.activeSubkey().attr('variable') + ' to ' + app.mode.result().toString()
				);
				app.storage.cancelVariableSave();
			} else {
				app.mode.currentInput().acceptLatexInput(
					this.activeSubkey().attr('variable')
				);
			}
		}
		if(this.activeSubkey().get(0).childNodes[0]) {
			app.mode.currentInput().acceptLatexInput(this.activeSubkey().get(0).childNodes[0].nodeValue);
			app.mode.currentInput().takeFocus();
		}
		if(this.activeSubkey().attr('close')) {
			app.useKeyboard('main');
		}
		if(this.activeSubkey().attr('action')) {
			this.activeSubkey().attr('action').split('|').forEach(function(attr) {
				split = attr.split(':'),
				target = StringUtil.trim(split[0]),
				action = StringUtil.trim(split[1]);
				//console.log(target,action);
				if(target == 'input') {
					app.mode.currentInput().acceptActionInput(action);
				}
				if(target == 'app') {
					app.acceptActionInput(action);
				}
			});
		}
		this.setPrimary();
	}
	
	on active(e) {
		var self = this;
		this.altTimeout = setTimeout(function() {
			self.setAlt();
		},250);
	}
	
	on ready {
		this.sub = $this.find('.submenu').get(0);
		this.init();
	}
	
	on endactive {
		var self = this;
		clearTimeout(this.altTimeout);
		setTimeout(function() {
			self.setPrimary();
		});
	}
	
	method init() {
		var kd = this.keyData();
		if(kd.attr('disabled')) {
			this.disable();
		} else {
			this.enable();
		}
		this.col = kd.attr('col');
		this.row = kd.attr('row');
		this.name = kd.attr('name');
		if(kd.attr('default-color')) {
			this.setStyle('default','background',kd.attr('default-color'));
		}
		if(kd.attr('active-color')) {
			this.setStyle('active','background',kd.attr('active-color'));
		}
		this.label();
	}
	
	method label() {
		var skd = this.activeSubkey();
		$this.find('.label').html('').css('background-image','none');
		if(skd.attr('text-label')) {
			this.labelType = 'text';
			var l = skd.attr('text-label');
			var s;
			if(l.indexOf('_') != -1) {
				s = l.split('_');
				l = s[0] + '<sub>' + s[1] + '</sub>';
			}
			$this.find('.label').html(l);
		} else if(skd.attr('image-label')) {
			this.labelType = 'image';
			var img = app.r.url(app.r.keyboardImage(skd.attr('image-label')));
			$this.find('.label').css('background-image',img);
		}
		if(this.hasAlt()) {
			this.$my('bar').show();
		}
	}

	method hasAlt {
		return !!this.keyData().find('alternate').length;
	}
	
	method setAlt() {
		if(this.hasAlt()) {
			this.altMode = true;
			this.label();
			this.position();
		}
	}
	
	method setPrimary() {
		if(!!this.keyData().find('primary').length) {
			this.altMode = false;
			this.label();
			this.position();
		}
	}
	
	method position(width,height,padding) {
		this.width = Math.floor(width);
		this.height = Math.floor(height - (this.labelType == 'image'? 0 : 0));
		$this.css('width', this.width);
		$this.css('height', this.height);
		$this.css('top', Math.floor(padding + (padding + height) * (this.row - 1)));
		$this.css('left', Math.floor((padding + width) * (this.col - 1)));
		$this.css('line-height',$this.css('height'));
		if(this.labelType == 'text') {
			$this.css('font-size', ($this.height() / 3).toString() + 'px');
		} else if(this.labelType == 'image') {
	
		}
	}

	method doInvoke(alt) {
		var self = this;
		$this.trigger('mousedown');
		if(alt) {
			this.setAlt();
		}
		setTimeout(function() {
			$this.trigger('mouseup');
		},10);
	}
	
	method keyData() {
		return $(this._keyData);
	}
	
	method activeSubkey() {
		return this.keyData().find(this.altMode? 'alternate' : 'primary');
	}
	
	style default {
		background: #222;
	}

	style active {
		background: #76acce;
	}

	style disabled {
		opacity: 0.5;
	}
	
	css {
		display: table-cell;
		position: absolute;
		cursor: pointer;
		font-size: 40px;
		text-align: center;
		color: #FFF;
		padding: 0;
		outline: none;
		-webkit-border-radius: 0px;
		border-radius: 0px;
		overflow: hidden;
	}
	
	my label {
		css {
			width: 100%;
			height: 100%;
			background-repeat: no-repeat;
			background-size: auto 60%;
			background-position: center;
		}
	}

	my bar {
		css {
			display: none;
			bottom: 0;
			position: absolute;
			width: 100%;
			height: 10%;
			background: #FFF;
			opacity: 0.05;
		}
	}
	
	extends {
		Button
	}
}
	