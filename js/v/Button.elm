def TouchInteractive {

	constructor {

	}
	
	on touchstart(e) {
		var touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
		this._touchStartX = touch.screenX;
		this._touchDeltaX = 0;
		this._isTouchInBounds = true;
		this._receivedTouchStart = true;
		$this.trigger('active',e);
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
	
	on touchend (e) {
		e.stopPropagation();
		e.preventDefault();
		this.receivedTouchEnd = true;
		$this.trigger('endactive');
		$this.trigger('invoke');	
	}
	
	on mousedown(e) {
		if(this._receivedTouchStart) {
			this._receivedTouchStart = false;
		} else {
			$this.trigger('active',e);
		}
	}
	
	on mouseup {
		$this.trigger('invoke');
		$this.trigger('endactive');
	}
	
	on mouseup mouseout {
		if(this._receivedTouchEnd) {
			this._receivedTouchEnd = false;
		} else {

		}
	}	
	
	on ready {

	}
	
	css {
		outline: none;
		user-select: none;
		-webkit-tap-highlight-color: rgba(255, 255, 255, 0); 
	}
}

def Button {
	
	on touchstart(e) {
		var touch = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
		this._touchStartX = touch.screenX;
		this._touchDeltaX = 0;
		this._isTouchInBounds = true;
		this._receivedTouchStart = true;
		$this.removeClass('color-transition');
		this.applyStyle('active');
		$this.trigger('active',e);
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
	
	on touchend (e) {
		e.stopPropagation();
		e.preventDefault();
		this.receivedTouchEnd = true;
		this.applyStyle('default');
		$this.addClass('color-transition');
		$this.trigger('endactive');
		$this.trigger('invoke');	
	}
	
	on mousedown(e) {
		if(this._receivedTouchStart) {
			this._receivedTouchStart = false;
		} else {
			$this.removeClass('color-transition');
			this.applyStyle('active');
			$this.trigger('active',e);
		}
	}
	
	on mouseup {
		$this.trigger('invoke');
		$this.trigger('endactive');
	}
	
	on mouseup mouseout {
		if(this._receivedTouchEnd) {
			this._receivedTouchEnd = false;
		} else {
			this.applyStyle('default');
			$this.addClass('color-transition');
		}
	}
	
	
	on ready {
		this.applyStyle('default');
	}
	
	css {
		outline: none;
		user-select: none;
		-webkit-tap-highlight-color: rgba(255, 255, 255, 0); 
	}
	
}
	