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
		padding: 10px;
	}

	constructor {
		$this.hide();
	}

	method invoke {
		$this.slideDown(200,function() {
			setTimeout(function() {
				$this.slideUp(200,function() {
					$this.trigger('complete');
				});
			},this.duration*1000);
		});
	}


}