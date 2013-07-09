def GrapherView {
	extends {
		SlideView
	}

	constructor {
		this.transition = 'easeInOutQuart';
		this.addView(elm.create('GraphListView').named('equations-list'));
		this.addView(elm.create('GraphWindow').named('graph-window'));
		// Event handlers
		this.@equations-list.$graph-button.on('invoke',this.#showGraph);
		this.@graph-window.$equations-button.on('invoke',this.#showEquations);
	}

	method showGraph {
		try {
			var self = this,
				tbf = this.#toolbarFix;
			app.setModeHeight(1);
			this.@graph-window.inputs = this.@equations-list.collect();
			this.@graph-window.render();
			setTimeout(function() {
				self.slideTo(self.@graph-window,tbf);
			},20);
			setTimeout(function() {
				app.hideKeyboard();
			},300);
		} catch(e) {
			app.popNotification(e);
		}
	}

	method showEquations {
		var self = this,
			tbf = this.#toolbarFix;
		app.showKeyboard();
		setTimeout(function() {
			self.slideTo(self.@equations-list,tbf);
		},500);
	}

	method toolbarFix {
		var self = this;
		this.$toolbar.css('opacity','-=0.01');
		setTimeout(function() {
			self.$toolbar.css('opacity','+=0.01');
		},150);
	}
}

def GraphWindow {
	extends {
		View
	}

	contents {
		<canvas class='draw' width='1000px' height='1000px'></canvas>
	}

	css {

	}

	constructor {
		$this.append(elm.create('FloatingToolbar').named('toolbar'));
		this.$toolbar.css('opacity',0.5);
		this.addButtons();
		// Defaults
		this.resolutionFactor = 1;
		var p = new Parser();
		this.inputs = [{
			type: 'function',
			data: p.parse('1/x')
		}];
	}

	method size {

	}

	method addButtons {
		this.$toolbar.append(elm.create('ToolbarButton','&lsaquo; Back').named('equations-button'));
		this.$toolbar.append(elm.create('ToolbarButton','Cursor').named('cursor-button'));
		this.$toolbar.append(elm.create('ToolbarButton','Trace').named('trace-button'));
		this.$toolbar.append(elm.create('ToolbarButton','Integrate').named('integrate-button'));
	}

	method context() {
		return this.@draw.getContext('2d');
	}

	method render {
		if(!this.xmax) {
			this.xmax = 3;
			this.xmin = 0 - this.xmax;
			this.ymax = this.xmax * ($this.height()/$this.width());
			this.ymin = 0 - this.ymax;
		}

		console.log(this.xmax,this.ymax)

		var c = this.context();
		var width = $this.width();
		var height = $this.height();

		var planeToCanvas = function(p) {
			return { x: origin.x + (x_scale*p.x), y: (origin.y + (y_scale*p.y)) };
		};
		
		var canvasToPlane = function(p) {
			return { x: (p.x - origin.x)/x_scale, y: (p.y - origin.y)/y_scale };
		};

		this.$draw.attr('width',width).attr('height',height);

		var win_width = Math.abs(this.xmax - this.xmin);
		var win_height = Math.abs(this.ymax - this.ymin);
		
		var x_scale = width / win_width; //Pixels per 1-increment
		var y_scale = x_scale;

		console.log(x_scale,y_scale);
		
		this.x_scale = x_scale;
		this.y_scale = y_scale;

		var x_tickinterval = Math.round(x_scale);
		var y_tickinterval = x_tickinterval;

		x_tickinterval /= this.resolutionFactor;
		y_tickinterval /= this.resolutionFactor;

		var origin = {x: x_scale*(0 - this.xmin), y: this.ymax*y_scale};	
		this.origin = origin;

		var x_tickoffset = origin.x % (x_scale * x_tickinterval);
		var y_tickoffset = origin.y % (y_scale * y_tickinterval);
		var x_tickcount = 1 + (width / (x_tickinterval * x_scale));
		var y_tickcount = 1 + (height / (y_tickinterval * y_scale));

		c.clearRect(0,0,this.$draw.width(),this.$draw.height());

		c.webkitImageSmoothingEnabled = false;
		
		c.strokeStyle = "#DDD";
		for(var i = 0; i < x_tickcount; i++) {
			var start = {x: x_tickoffset + (i * x_tickinterval * x_scale), y: 0};
			c.beginPath();
			c.moveTo(start.x,start.y);
			c.lineTo(start.x,height);
			c.stroke();
		}
					
		for(var i = 0; i < y_tickcount; i++) {
			var start = {x: 0, y: y_tickoffset + (i * y_tickinterval * y_scale)};
			c.beginPath();
			c.moveTo(start.x,start.y);
			c.lineTo(width,start.y);
			c.stroke();
		}
		
		c.strokeStyle = "#BBB";
		//Draw x-axis:
		c.beginPath();
		c.moveTo(0,origin.y);
		c.lineTo(width,origin.y);
		c.closePath();
		c.stroke();
		
		//Draw x-axis:
		c.beginPath();
		c.moveTo(origin.x,0);
		c.lineTo(origin.x,height);
		c.closePath();
		c.stroke();	

		this.inputs.map(function(item) {
			var data = item.data,
				type = item.type,
				color = item.color;
			if(type == 'function') {
				var frame = new Frame({x:0});
				var points = [];
				for(var i = 0; i < width; i ++) {
					var planeX = canvasToPlane({x:i,y:0}).x;
					try {
						frame.set('x',planeX);
						var planeY = 0 - data.valueOf(frame);
					} catch(e) {
						var planeY = -Infinity;
					};
					if(!isNaN(planeY))
					{
						points.push({x: planeX, y: planeY});
					};
				};
				var start = points.shift();
				start = planeToCanvas(start);
				c.lineWidth = 2;
				c.strokeStyle =  item.color || "#669966";
				c.beginPath();
				c.moveTo(start.x,start.y);
				var lp = {x:0,y:0};
				points.forEach(function(p) {
					var gp = p;
					p = planeToCanvas(p);
					if((lp.y > self.ymax && gp.y < self.ymin) || (gp.y > self.ymax && lp.y < self.ymin) || gp.y === undefined || Math.abs(gp.y) == Infinity || Math.abs(lp.y) == Infinity)
					{
						p.x = Math.round(p.x);
						p.y = Math.round(p.y);
						c.moveTo(p.x,p.y);
					} else {
						c.lineTo(p.x,p.y);
					};
					lp = gp;
				});
				c.stroke();
			};
			
			if(type == 'points') {
				c.fillStyle = "#FF1C0A";
				data = data.map(function(d) { 
					if(d instanceof Array) {
						return {x: d[0], y: 0-d[1]};
					} else {
						return {x: d.x, y: 0-d.y};
					};
				});
				
				if(data.length == 2 && !isNaN(data[0]) && !isNaN(data[1])) {
					data = [data];
				};
				
				data.forEach(function(d) {
					c.beginPath();
					d = planeToCanvas(d);
					c.arc(d.x, d.y, 3, 0, Math.PI*2, true);
					c.closePath();
					c.fill();
				});		
			};
		});	
	}
}

def GraphListView {
	extends {
		ListView
	}

	constructor {
		this.$title.html('');
		this.fieldType = 'GraphListField';
		// Add buttons
		this.$toolbar.append(elm.create('ToolbarButton','Settings').named('graph-button'));
		this.$toolbar.append(elm.create('ToolbarButtonImportant','Graph &rsaquo;').named('graph-button'));
	}

	method collect {
		var res = [];
		var p = new Parser();
		this.$GraphListField.each(function() {
			var field = this;
			if(field.contents().length == 2) return;
			res.push({
				data: p.parse(field.contents().slice(2),false),
				type: 'function'
			});
		});
		return res;
	}
}

def GraphListField(fm) {
	extends {
		MathTextfield
	}

	constructor {
		this.defaultText = 'Click to add equation';
		$this.html(this.defaultText);
		this.setContents('y=');
	}

	method empty {
		return this.contents() == '' || this.contents() == 'y=';
	}

	on update {
		var c = this.contents();
		if(c.indexOf('y=') != 0) {
			if(c.charAt(0) == 'y' || c.charAt(0) == '=') {
				c = 'y=' + c.slice(1)
			} else {
				c = 'y=' + c;
			}
			this.setContents(c);
		}
	}

	on gain-focus {
		if(this.childNodes[0].nodeValue == this.defaultText) {
			this.setContents('y=');
		}
	}
}