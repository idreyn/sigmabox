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
		}
	}
	
	find .middle {
		css {
			width: 100%;
			height: 100%;
			position: relative;
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
		z-index: 1001;
		transform: translate3d(0,0,0);
		-webkit-transform: translate3d(0,0,0);
		-webkit-overflow-scrolling: touch;
		-webkit-transform: translateY(0);
	}

	style animated {
		-webkit-transition: -webkit-transform 0.2s ease-in-out;
	}

	style not-animated {
		-webkit-transition: none;
	}

	method animated {
		this.applyStyle('animated');
	}

	method notAnimated {
		this.applyStyle('not-animated');
	}

	on touchmove(e) {
		e.preventDefault();
	}
	
	constructor {
		this.size();
		this.notAnimated();
	}

	method slideUp(n,e) {
		this.animated();
		$this.show();
		setTimeout(function() {
			$this.css({
				'translateY': 0,
			});
		},0);
	}

	method slideDown(n,e) {
		this.animated();
		$this.css({
			'translateY': parseInt($this.css('height'))
		});
	}
	
	method init() {
		this.createKeys();
		$this.css('translateY',parseInt($this.css('height')));
		this.applyStyle('animated');
	}
	
	method size() {
		$this.css(
			'height',
			utils.viewport().y * 0.5
		).css(
			'bottom',
			0
		);
		this.screenFraction = i;
		if(this.hasKeys) {
			setTimeout(function() {
				self.positionKeys();
			},0);
		}
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
				k.parentKeyboard = self;
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
	
	method snapBack {
		var interval = (this.padding + this.keyWidth);
	}
}

def DragKeyboard(keyboardSource) {
	extends {
		Keyboard
		Pull
	}

	properties {
		pullDirection: 'up',
		pullMaxHeight: 300
	}

	constructor {
		Hammer(this).on('dragstart',this.#dragStart);
		Hammer(this).on('drag',this.#dragged);
		Hammer(this).on('dragend',this.#dragEnd);
		this.$.append(elm.create('KeyboardPullIndicator'));
	}

	method dragStart(e) {
		this.notAnimated();
	}

	on pullUpdate(e,data) {
		var y = data.y,
			translateY = data.translateY;
		self.@KeyboardPullIndicator.setHeight(Math.abs(translateY));
		// Stop keys from being pressed
		if(y > 30 && !self.disabled) {
			self.disabled = true;
			self.notAnimated();
			self.currentKey.$.removeClass('color-transition');
			self.currentKey.applyStyle('default');
		}
	}

	method dragEnd(e) {
		setTimeout(function() {
			self.disabled = false;
		},500);
		this.animated();
		this.slideUp();
		this.@KeyboardPullIndicator.invoke();
	}


	on invalidate {
		this.$KeyboardPullIndicator.css('top',$this.height());
	}
}

def KeyboardPullIndicator {
	html {
		<div></div>
	}

	constructor {
		this.maxHeight = 300;
		this.options = [
			{label: '', color: '#000'},
			{label: 'Numerical', action: 'keyboard numerical'},
			{label: 'Matrix', action: 'keyboard matrix'},
			{label: 'List', action: 'keyboard list'},
			{label: 'Distributions', action: 'keyboard distributions'},
		];
	}

	css {
		width: 100%;
		height: 500px;
		background: #000;
		text-align: center;
		color: #FFF;
		font-size: 40px;
		-webkit-transition: background-color 0.1s;
	}

	method setHeight(y) {
		y = Math.round(y);
		var index = Math.max(0,Math.floor(y / (this.maxHeight / this.options.length)));
		this.current = this.options[index];
		$this.css('line-height',y + 'px');
		$this.html(this.current.label);
	}

	method invoke {
		if(this.current.action) {
			if(this.current.action instanceof Function) {
				this.current.action();
			} else {
				app.acceptActionInput(this.current.action);
			}
		}
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
		if(this.cannotInvoke) return;
		try {
			if(this.activeSubkey().attr('variable')) {
				if(app.data.varSaveMode) {
					if(app.data.varSaveMode == 'store') {
						app.data.setVariable(
							this.activeSubkey().attr('variable'),
							app.data.valToSave
						);
					}
					if(app.data.varSaveMode == 'set') {
						app.setVariablePrompt(
							this.activeSubkey().attr('variable')
						);
					}
					app.data.cancelVariableSave();
				} else {
					app.mode.currentInput().acceptLatexInput(
						this.activeSubkey().attr('variable')
					);
				}
			}
			if(this.activeSubkey().get(0).childNodes[0]) {
				var latex = this.activeSubkey().get(0).childNodes[0].nodeValue;
				app.mode.currentInput().acceptLatexInput(latex);
			}
			if(this.activeSubkey().attr('close')) {
				this.parent('Keyboard').slideDown();
				app.data.cancelVariableSave();
				app.keyboard = app.keyboards.main;
			}
			if(this.activeSubkey().attr('action')) {
				this.activeSubkey().attr('action').split('|').forEach(function(attr) {
					split = attr.split(':'),
					target = StringUtil.trim(split[0]),
					action = StringUtil.trim(split[1]);
					if(target == 'input') {
						app.mode.currentInput().acceptActionInput(action);
					}
					if(target == 'app') {
						app.acceptActionInput(action);
					}
				});
			}
		} catch(e) {

		} finally {
			this.setPrimary();
		}
	}
	
	on active(e) {
		this.parentKeyboard.currentKey = this;
		var self = this;
		this.altTimeout = setTimeout(function() {
			self.setAlt();
		},250);
	}

	method cancel {
		this.$.trigger('endactive');
		this.cannotInvoke = true;
		setTimeout(function() {
			self.cannotInvoke = false;
		},500);
	}
	
	on ready {
		this.sub = $this.find('.submenu').get(0);
		this.init();
	}

	on end {
		if(self.altMode && !self.parentKeyboard.disabled) {
			self.$.trigger('invoke');
		}
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
			if(skd.attr('style')) {
				skd.attr('style').split(';').forEach(function(line) {
					line = line.split(':');
					$this.css(line[0],line[1]);
				})
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
	
	method setAlt {
		//console.log('setAlt');
		if(this.hasAlt()) {
			if(this.$.width() < 100) this.$.css('translateY',0 - this.$.height() * (3/4));
			this.altMode = true;
			this.label();
			this.position();
		}
	}
	
	method setPrimary {
		//console.log('setPrimary');
		if(!!this.keyData().find('primary').length) {
			this.$.css('translateY',0);
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
		this.tapped();
		if(alt) {
			this.setAlt();
		}
		setTimeout(function() {
			self.released();
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
		-webkit-transition: -webkit-transform ease-out 0.05s;
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
	