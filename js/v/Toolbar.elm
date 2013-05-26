def Switch(left,right) {
	
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
		background: #2CB1E1;
		vertical-align: text-top;
		margin-right: 10px;
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
			this.height / 8
		);
		this.handle.size();
		this.my('left-label').size();
		this.my('right-label').size();
	}

	on invoke {
		this.flip();
	}

	method flip(state) {
		if(state === undefined || state === null) state = !this.state;
		this.state = state;
		if(this.state) {
			this.handle.$.animate({
				'left': this.$.width() - this.handle.$.width()
			},250,'easeInOutQuart');
		} else {
			this.handle.$.animate({
				'left': 0
			},250,'easeInOutQuart');
		}
		$this.trigger('flipped');
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
			color: #FFF;
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
				root.height / 8
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
			background: #333;
			box-shadow: 1px 1px 1px rgba(0,0,0,0.4);
		}

	}

	extends {
		TouchInteractive
	}

}


// Todo, move this definition to its own file

def ToolbarButton(text) {
	
	html {
		<div>
			<div class='label'>$text</div>
		</div>
	}

	css {
		display: inline-block;
		cursor: pointer;
		vertical-align: text-top;
		margin-right: 10px;
		padding-left: 5px;
		padding-right: 5px;
		box-shadow: 1px 1px 1px rgba(0,0,0,0.2);
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
			this.height / 8
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
			color: #FFF;
			width: 50%;
			float: left;
		}
	}

	style default {
		background: #BBB;
	}

	style active {
		background: #CCC;
	}

	extends {
		Button
	}

}