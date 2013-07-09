def TouchInteractive {

	constructor {
		this.enabled = true;
	}

	on touchstart(e) {
		if(this.enabled) {
			var touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
			this._touchStartX = touch.screenX;
			this._touchDeltaX = 0;
			this._isTouchInBounds = true;
			this._receivedTouchStart = true;
			$this.trigger('active',e);
		}
	}
	
	on touchmove(e) {
		if(this.enabled) {
			var touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
			this._touchDeltaX = Math.abs(touch.screenX - this._touchStartX);
			if (app.utils.hitTest(touch, $this.offset(), $this.outerWidth(), $this.outerHeight())) {
				this._isTouchInBounds = true;
			} else {
				this._isTouchInBounds = false;
			}
		}
	}
	
	on touchend(e) {
		if(this.enabled) {
			e.stopPropagation();
			e.preventDefault();
			this.receivedTouchEnd = true;
			$this.trigger('endactive');
			$this.trigger('invoke');	
		}
	}
	
	on mousedown(e) {
		if(this.enabled) {
			if(this._receivedTouchStart) {
				this._receivedTouchStart = false;
			} else {
				$this.trigger('active',e);
			}
		}
	}
	
	on mouseup {
		if(this.enabled) {
			$this.trigger('invoke');
			$this.trigger('endactive');
		}
	}
	
	on mouseup mouseout {
		if(this.enabled) {
			if(this._receivedTouchEnd) {
				this._receivedTouchEnd = false;
			}
		}
	}

	method enable {
		this.enabled = true;
	}	

	method disable {
		this.enabled = false;
	}

	css {
		outline: none;
		user-select: none;
		-webkit-tap-highlight-color: rgba(255, 255, 255, 0); 
	}
}

def Button {

	constructor {
		this.enabled = true;
	}
	
	on touchstart(e) {
		var touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
		this._touchStartX = touch.screenX;
		this._touchDeltaX = 0;
		this._isTouchInBounds = true;
		this._receivedTouchStart = true;
		$this.removeClass('color-transition');
		if(this.enabled) {
			this.applyStyle('active');
			$this.trigger('active',e);
		}
	}
	
	on touchmove(e) {
		var touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
		this._touchDeltaX = Math.abs(touch.screenX - this._touchStartX);
		if (app.utils.hitTest(touch, $this.offset(), $this.outerWidth(), $this.outerHeight())) {
			this._isTouchInBounds = true;
		} else {
			this._isTouchInBounds = false;
		}
	}
	
	on touchend(e) {
		e.stopPropagation();
		e.preventDefault();
		this.receivedTouchEnd = true;
		if(this.enabled) {
			this.applyStyle('default');
			$this.addClass('color-transition');
			$this.trigger('endactive');
			$this.trigger('invoke');	
		}
	}
	
	on mousedown(e) {
		if(this._receivedTouchStart) {
			this._receivedTouchStart = false;
		} else {
			$this.removeClass('color-transition');
			if(this.enabled) {
				this.applyStyle('active');
				$this.trigger('active',e);
			}
		}
	}
	
	on mouseup {
		if(this.enabled) {
			$this.trigger('invoke');
			$this.trigger('endactive');
		}
	}
	
	on mouseup mouseout {
		if(this._receivedTouchEnd) {
			this._receivedTouchEnd = false;
		} else {
			if(this.enabled) {
				this.applyStyle('default');
				$this.addClass('color-transition');
			}
		}
	}
	
	
	on ready {
		if(this.enabled) {
			this.applyStyle('default');
		} else {
			this.applyStyle('disabled');
		}
	}

	method enable {
		this.enabled = true;
		this.applyStyle('default');
	}

	method disable {
		this.enabled = false;
		this.applyStyle('disabled');
	}
	
	css {
		outline: none;
		user-select: none;
		-webkit-tap-highlight-color: rgba(255, 255, 255, 0); 
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

def Dispatch {
	html {
		<div></div>
	}
}

	