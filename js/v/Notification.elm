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