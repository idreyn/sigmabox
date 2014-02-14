def GrapherView {
	extends {
		SlideView
	}

	constructor {
		this.colors = ['#696','#A33','#0A4766','#B6DB49','#50C0E9','#FB3'];
		this.transition = 'easeInOutQuart';
		this.addView(elm.create('GrapherListView').named('equations-list'));
		this.addView(elm.create('GraphWindow').named('graph-window'));
		// Event handlers
		this.@equations-list.$graph-button.on('invoke',this.#showGraph);
		this.$equations-list.on('update',this.#updateColors);
		this.@graph-window.$equations-button.on('invoke',this.#showEquations);
		// Yum
		this.updateColors();
		this.setFragmentMode(this.@equations-list,this.@graph-window);
	}

	method updateColors {
		var self = this;
		this.@equations-list.fields().each(function(i,e) {
			e.setColor(self.colors[i]);
		});
	}

	method showGraph {
		try {
			var self = this,
				tbf = this.#toolbarFix,
				eqns = this.@equations-list.collect();
			if(eqns.length == 0) return;
			app.hideKeyboard();
			this.noKeyboard = true;
			this.@graph-window.inputs = eqns;
			this.@graph-window.buildEquationButtonSet();
			this.@graph-window.$range.hide();
			this.@graph-window.$trace-handle.hide();
			this.@graph-window.@trace-readouts.hide();
			this.@graph-window.@range-readouts.hide();
			setTimeout(function() {
				self.slideTo(self.@graph-window,tbf);
				self.@graph-window.homeWindow();
			},10);
		} catch(e) {
			app.popNotification(e);
		}
	}

	method showEquations {
		var self = this,
			tbf = this.#toolbarFix;
		app.showKeyboard();
		this.noKeyboard = false;
		self.slideTo(self.@equations-list,tbf);
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
		[[top-toolbar:Toolbar]]
		[[bottom-toolbar:Toolbar true,15]]
		[[bounds-readout:GrapherReadout]]
		[[trace-readouts:TraceReadouts]]
		[[range-readouts:RangeReadouts]]
		[[trace-handle:GrapherTraceHandle]]
		[[range:GrapherRange]]
	}

	constructor {
		this.zoomFactor = 2;

		this.$top-toolbar.css('background','none').css('box-shadow','none');
		this.$bottom-toolbar.css('background','none').css('box-shadow','none');

		// Readouts
		this.$bounds-readout.css('bottom',0);
		this.addButtons();
		this.addEvents();

		this.setWindow(10,false);
	}

	on invalidate {

	}

	method addButtons {
		this.$top-toolbar.append(elm.create('GrapherButton','&lsaquo; Back').named('equations-button'));
		this.$top-toolbar.append(
			elm.create(
				'GrapherButtonGroup',
				[
					elm.create('GrapherButton','-').named('zoom-out'),
					elm.create('GrapherButton','+').named('zoom-in')
				]
			)
		);
		this.$top-toolbar.append(
			elm.create(
				'GrapherButtonChoice',
				[
					elm.create('GrapherButtonImage','compass').named('cursor-button'),
					elm.create('GrapherButtonImage','crosshair').named('trace-button'),
					elm.create('GrapherButtonImage','integral').named('range-button')
				]
			).named('mode-choice')
		);
		this.$top-toolbar.append(elm.create('GrapherButtonImage','home').named('home-button'));

		this.$cursor-button.on('invoke',this.#modeChoice);
		this.$trace-button.on('invoke',this.#modeChoice);
		this.$range-button.on('invoke',this.#modeChoice);

		this.$home-button.on('invoke',this.#homeWindow);

		this.$bottom-toolbar.append(
			elm.create(
				'GrapherEquationChoice',
				[

				]
			).named('equation-choice')
		);
		this.$zoom-out.css('padding-left',15).css('padding-right',15).on('invoke',this.#zoomOut);
		this.$zoom-in.css('padding-left',15).css('padding-right',15).on('invoke',this.#zoomIn);
	}

	method buildEquationButtonSet {
		var buttons = [];
		this.inputs.forEach(function(input) {
			buttons.push(
				elm.create('GrapherEquationChoiceButton',input.color,input)
			);
		});
		this.@equation-choice.setButtons(buttons);
	}

	method addEvents {
		Hammer(this).on('drag',this.#dragged).on('dragstart',this.#dragStart).on('dragend',this.#dragEnd).on('touch',this.#touched)
		Hammer(this).on('pinch',this.#pinched);
		Hammer(this).on('swiperight',this.#swiped);
	}

	method modeChoice{
		this.@trace-readouts.hide();
		this.@range-readouts.hide();
	}

	method swiped(e) {
		e.stopPropagation();
	}

	method touched(e) {
		switch(this.@mode-choice.selected) {
			case this.@cursor-button:
				return this.cursorTouched(e);
			case this.@trace-button:
				return this.traceTouched(e);
			case this.@range-button:
				return this.rangeTouched(e);
		}
	}

	method dragStart(e) {
		e.stopPropagation();
		switch(this.@mode-choice.selected) {
			case this.@cursor-button:
				return this.cursorDragStart(e);
			case this.@trace-button:
				return this.traceDragStart(e);
			case this.@range-button:
				return this.rangeDragStart(e);
		}
	}

	method dragged(e) {
		e.stopPropagation();
		switch(this.@mode-choice.selected) {
			case this.@cursor-button:
				return this.cursorDragged(e);
			case this.@trace-button:
				return this.traceDragged(e);
			case this.@range-button:
				return this.rangeDragged(e);
		}
	}

	method dragEnd(e) {
		e.stopPropagation();
		switch(this.@mode-choice.selected) {
			case this.@cursor-button:
				return this.cursorDragEnd(e);
			case this.@trace-button:
				return this.traceDragEnd(e);
			case this.@range-button:
				return this.rangeDragEnd(e);
		}
	}

	method cursorTouched(e) {
	
	}

	method traceTouched(e) {

	}

	method rangeTouched(e) {

	}

	method cursorDragStart(e) {
		this.$range.hide();
		this.$trace-handle.hide();
		this.@trace-readouts.hide();
		this.@range-readouts.hide();
		this.dragOriginX = e.gesture.center.pageX;
		this.dragOriginY = e.gesture.center.pageY;
	}

	method cursorDragged(e) {
		if(!this._xmin) {
			this._xmin = this.xmin;
			this._xmax = this.xmax;
			this._ymin = this.ymin;
			this._ymax = this.ymax;
		}
		this.xmin = this._xmin - Math.round(e.gesture.center.pageX - this.dragOriginX) / this.x_scale;
		this.xmax = this._xmax - Math.round(e.gesture.center.pageX - this.dragOriginX) / this.x_scale;
		this.ymin = this._ymin + Math.round(e.gesture.center.pageY - this.dragOriginY) / this.y_scale;
		this.ymax = this._ymax + Math.round(e.gesture.center.pageY - this.dragOriginY) / this.y_scale;
		window.requestAnimationFrame(function() {
			self.render(true);
		})
	}

	method cursorDragEnd(e) {
		this._xmin = null;
		this._xmax = null;
		this._ymin = null;
		this._ymax = null;
		this.render();
	}

	method traceDragStart(e) {
		this.@range-readouts.hide();
		this.$range.hide();
		this.$trace-handle.stop().show().css('scale',1).css('opacity',1);
		this.@trace-readouts.show();
	}

	method traceDragged(e) {
		var pageX = e.gesture.center.pageX - this.$.offset().left;
		var planeX = this.canvasToPlane({x: pageX}).x;
		if(this.@equation-choice.selected) {
			var tur = app.trigUseRadians;
			app.storage.trigUseRadians = true;
			var planeY = 0 - this.@equation-choice.selected.equation.data.valueOf(
				new Frame({
					x: planeX
				})
			).toFloat();
			app.storage.trigUseRadians = tur;
			this.$trace-handle.show();
		} else {
			planeY = this.canvasToPlane({y: e.gesture.center.pageY}).y;
		}
		this.traceHandlePlaneX = planeX;
		this.traceHandlePlaneY = planeY;
		this.placeTraceHandle(planeX,planeY);
		this.@trace-readouts.update(
			planeX,
			planeY,
			this.@equation-choice.selected.equation.data
		);
	}

	method placeTraceHandle(planeX,planeY) {
		var p = this.planeToCanvas({x:planeX,y:planeY});
		this.$trace-handle.css({
			'top': p.y - this.$trace-handle.height() / 2,
			'left': p.x - this.$trace-handle.width() / 2
		});
	}

	method placeRange(planeStart,planeEnd) {
		var pageStart = this.planeToCanvas({x: planeStart}).x;
		var pageEnd = this.planeToCanvas({x: planeEnd}).x;
		this.$range.css({
			'left': pageStart,
			'width': pageEnd - pageStart
		});
	}

	method traceDragEnd(e) {

	}

	method rangeDragStart(e) {
		this.@trace-readouts.hide();
		this.$range.show();
		var p = this.canvasToPlane({
			x: e.gesture.center.pageX - this.$.offset().left,
			y: e.gesture.center.pageY
		});
		this.placeTraceHandle(p.x,p.y);
		this.@trace-handle.flyIn();
		this.@range.setColor(this.@equation-choice.selected.equation.color || '#000');
		this.@range-readouts.showDynamic();
		this._rangeStartX = e.gesture.center.pageX - this.$.offset().left;
	}

	method rangeDragged(e) {;
		this._rangeCurrentX = e.gesture.center.pageX - this.$.offset().left;
		if(this._rangeCurrentX > this._rangeStartX) {
			this.$range.css({
				'left': this._rangeStartX,
				'width': Math.abs(this._rangeCurrentX - this._rangeStartX)
			});
		} else {
			this.$range.css({
				'left': this._rangeCurrentX,
				'width': Math.abs(this._rangeCurrentX - this._rangeStartX)
			});
		}
		this.rangeStart = this.canvasToPlane({x: (this._rangeCurrentX > this._rangeStartX) ? this._rangeStartX : this._rangeCurrentX }).x;
		this.rangeEnd = this.canvasToPlane({x: (this._rangeCurrentX > this._rangeStartX) ? this._rangeCurrentX : this._rangeStartX }).x;
		this.@range-readouts.updateDynamic(
			this.rangeStart,
			this.rangeEnd,
			this.@equation-choice.selected.equation.data
		);
	}

	method rangeDragEnd(e) {
		var p = this.canvasToPlane({
			x: e.gesture.center.pageX,
			y: e.gesture.center.pageY
		});
		this.placeTraceHandle(p.x,p.y);
		this.@trace-handle.flyOut();
		this.rangeStart = this.canvasToPlane({x: (this._rangeCurrentX > this._rangeStartX) ? this._rangeStartX : this._rangeCurrentX }).x;
		this.rangeEnd = this.canvasToPlane({x: (this._rangeCurrentX > this._rangeStartX) ? this._rangeCurrentX : this._rangeStartX }).x;
		this.@range-readouts.show();
		var self = this;
		setTimeout(function() {
			self.@range-readouts.update(
				self.rangeStart,
				self.rangeEnd,
				self.@equation-choice.selected.equation.data,
				self.@equation-choice.selected.equation.points
			);
		},200);
	}


	method pinched(e) {
		//console.log(e);
	}

	method context() {
		return this.@draw.getContext('2d');
	}

	method zoomIn {
		this.xmin /= this.zoomFactor;
		this.xmax /= this.zoomFactor;
		this.ymin /= this.zoomFactor;
		this.ymax /= this.zoomFactor;
		this.render();
		this.placeTraceHandle(this.traceHandlePlaneX,this.traceHandlePlaneY);
		this.placeRange(this.rangeStart,this.rangeEnd);
	}

	method zoomOut {
		this.xmin *= this.zoomFactor;
		this.xmax *= this.zoomFactor;
		this.ymin *= this.zoomFactor;
		this.ymax *= this.zoomFactor;
		this.render();
		this.placeTraceHandle(this.traceHandlePlaneX,this.traceHandlePlaneY);
		this.placeRange(this.rangeStart,this.rangeEnd);
	}

	method setWindow(xmax,render) {
		if(render === undefined) render = true;
		this.xmax = xmax;
		this.xmin = 0 - this.xmax;
		this.ymax = this.xmax * ($this.height()/$this.width());
		this.ymin = 0 - this.ymax;
		if(render) this.render();
	}

	method homeWindow {
		this.setWindow(10);
		this.placeTraceHandle(this.traceHandlePlaneX,this.traceHandlePlaneY);
		this.placeRange(this.rangeStart,this.rangeEnd);
	}

	method updateReadout {
		this.$bounds-readout.html(
			'x: [' + this.xmin.toPrecision(4) + ',' + this.xmax.toPrecision(4) + ']' + ' &nbsp; y: [' + this.ymin.toPrecision(4) + ',' + this.ymax.toPrecision(4) + ']'
		);
	}

	method planeToCanvas(p) {
		return { x: this.origin.x + (this.x_scale*p.x), y: (this.origin.y + (this.y_scale*p.y)) };
	}
		
	method canvasToPlane(p) {
		return { x: (p.x - this.origin.x)/this.x_scale, y: (p.y - this.origin.y)/this.y_scale };
	}


	method render(renderEquations) {

		var trueTrigMode = app.storage.trigUseRadians;
		app.storage.trigUseRadians = true;

		renderEquations = renderEquations === undefined ? true : renderEquations;

		var self = this;

		this.resolutionFactor = 1;

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
		
		this.x_scale = x_scale;
		this.y_scale = y_scale;

		var origin = {x: x_scale*(0 - this.xmin), y: this.ymax*y_scale};	
		this.origin = origin;

		c.clearRect(0,0,this.$draw.width(),this.$draw.height());
	
		c.strokeStyle = "#DDD";
		for(var i = 0; false && i < x_tickcount; i++) {
			var start = {x: x_tickoffset + (i * x_tickinterval * x_scale), y: 0};
			c.beginPath();
			c.moveTo(start.x,start.y);
			c.lineTo(start.x,height);
			c.stroke();
		}
					
		for(var i = 0; false && i < y_tickcount; i++) {
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

		if(app.useGratuitousAnimations() || renderEquations) this.inputs.map(function(item) {
			var data = item.data,
				type = item.type,
				color = item.color;
			if(type == 'function') {
				var points = [];
				var step = 2;
				Frac.grapherMode = true;
				if(!data.cache) {
					// Slap a cache onto the evaluable objects
					data.cache = {};
					data.getValue = function(planeX) {
						if(data.cache[planeX] !== undefined) {
							return data.cache[planeX];
						} else {
							var res;
							app.storage.trigForceRadians(function() {
								res = data.valueOf(new Frame({x: planeX})).toFloat();
								data.cache[planeX] = res;
							});
							return res;
						}
					}
				}
				for(var i = 0; i < width; i += step) {
					var planeX = canvasToPlane({x:i,y:0}).x;
					try {
						var planeY = 0 - data.getValue(planeX);
					} catch(e) {
						var planeY = null;
					};
					if(planeY !== null && !isNaN(planeY) && Math.abs(planeY) < 1e10)
					{
						points.push({x: planeX, y: planeY});
					};
				};
				Frac.grapherMode = false;
				var start = points.shift();
				start = planeToCanvas(start);
				c.lineWidth = 4;
				c.strokeStyle =  item.color || "#000";
				c.beginPath();
				c.moveTo(start.x,start.y);
				var lastPlane = {x:0,y:0};
				var lastCanvas = {x:0,y:0};
				points.forEach(function(p) {
					var currentPlane = p;
					p = planeToCanvas(p);
					if( // All the reasons we might not want a line here
						isNaN(currentPlane.y) ||
						p.y === null || 
						(lastPlane.y > self.ymax && currentPlane.y < self.ymin) || 
						(lastPlane.y < self.ymin && currentPlane.y > self.ymax) || 
						currentPlane.y === undefined || 
						Math.abs(currentPlane.y) == Infinity || 
						Math.abs(lastPlane.y) == Infinity
					) {
						p.x = Math.round(p.x);
						p.y = Math.round(p.y);
						c.moveTo(p.x,p.y);
					} else {
						c.lineTo(p.x,p.y);
					};
					lastCanvas = p;
					lastPlane = currentPlane;
				});
				item.points = points;
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

		app.storage.trigUseRadians = trueTrigMode;
		this.updateReadout();
	}
}

def GrapherListView {
	extends {
		ListView
	}

	constructor {
		this.$title.html('Grapher');
		this.fieldType = 'GraphListField';
		// Add buttons
		this.$toolbar.append(elm.create('ToolbarButtonImportant','Graph &rsaquo;').named('graph-button'));
		this.load();
	}

	method fields {
		return this.$GraphListField;
	}

	method collect {
		var res = [];
		var p = new Parser();
		this.$GraphListField.each(function() {
			var field = this;
			if(field.contents().length == 2) return;
			res.push({
				data: p.parse(field.contents().slice(2),false),
				color: field.color,
				type: 'function'
			});
		});
		return res;
	}

	on update {
		this.save();
	}

	on field-update {
		this.save();
	}

	method load {
		var self = this;
		if(app.storage.grapherEquations) app.storage.grapherEquations.map(function(eq) {
			self.addField().setContents(eq);
		});
	}

	method save {
		var cl = this.fields().map(function(i,field) {
			return field.contents();
		}).toArray().filter(function(str) {
			return str != 'y=' && str != '';
		});
		app.storage.grapherEquations = cl;
		app.storage.serialize();
	}
}

def GraphListField(focusManager) {
	extends {
		MathTextField
	}

	constructor {
		this.setContents('y=')
		this.defaultText = 'Click to add equation';
		$this.append(elm.create('GraphListFieldColorLabel').named('label'));
	}

	method setColor(color) {
		this.color = color;
		this.$label.css('background',color);
		this.$label.css('border-bottom-color',color);
	}

	on update {
		var c = this.contents();
		if(c.indexOf('y=') != 0) {
			if(c.charAt(0) == 'y' || c.charAt(0) == '=') {
				c = 'y=' + c.slice(1);
			} else {
				c = 'y=' + c;
			}
			this.setContents(c);
		}
	}
	
	css {
		position: relative;
	}

	my SmallMathInput {
		method empty {
			return this.contents() == 'y=' || this.contents() == '';
		}
	}
}

def GraphListFieldColorLabel {
	html {
		<div></div>
	}

	css {
		position: absolute;
		top: 0;
		left: 0;
		height: 100%;
		width: 8px;
		background: #CCC;
		border-bottom: 2px solid;
	}
}

def GrapherButton(label) {
	html {
		<div>$label</div>
	}

	css {
		color: #EEE;
		display: inline;
		margin-right: 5px;
		height: 50%;
		font-size: 0.9em;
		padding: 8px;
		border-radius: 20px;
		cursor: pointer;
	}

	style default {
		background: rgba(0,0,0,0.1);
	}

	style active {
		background: rgba(0,0,0,0.2);
	}

	extends {
		Button
	}
}

def GrapherButtonImage(labelImage) {
	html {
		<div>
			<img class='label' />
		</div>
	}

	extends {
		GrapherButton
	}

	constructor {
		this.@label.src = app.r.image(this.labelImage);
	}

	css {
		text-align: center;
	}

	my label {
		css {
			margin-bottom: 2px;
			height: 40%;
			vertical-align: middle;
		}
	}
}

def GrapherButtonGroup(buttons) {
	html {
		<div></div>
	}

	constructor {
		this.radius = 30;
	}

	on ready {
		this.setButtons(this.buttons);
	}

	method setButtons(b) {
		$this.children().remove();
		this.buttons = b;
		this.buttons.map(function(button,i,s) {
			$this.append(button);
			button.$.css('margin-right',0);
			button.$.css('border-top-left-radius', i == 0 ? this.radius : 0);
			button.$.css('border-bottom-left-radius', i == 0 ? this.radius : 0);
			button.$.css('border-top-right-radius', i == s.length - 1 ? this.radius : 0);
			button.$.css('border-bottom-right-radius', i == s.length - 1 ? this.radius : 0);
			if(i != s.length - 1) {
				if(button.$.find('img').length)
					button.$.css('padding-right','-=4px');
			}
		});
		$this.trigger('buttons-updated');
	}

	css {
		border-radius: 20px;
		display: inline;
		margin-right: 5px;
	}

}

def GrapherButtonChoice(buttons) {
	extends {
		GrapherButtonGroup
	}

	constructor {

	}

	on buttons-updated {
		this.selected = null;
		var self = this;
		var bi = this.#buttonInvoked;
		var bei = this.#buttonEndActive;
		this.buttons.map(function(button) {
			button.$.on('invoke',bi);
			button.$.on('end-active',bei);
			button.applyStyle(self.getStyle('unselected'));
		});
		if(this.buttons[0]) this.buttons[0].$.trigger('invoke');
	}

	method buttonInvoked(e) {
		if(this.selected) {
			this.selected.applyStyle(this.getStyle('unselected'));
		}
		this.selected = e.target;
		this.selected.applyStyle(this.getStyle('selected'));
		setTimeout(function() {
			self.selected.applyStyle(self.getStyle('selected'));
		},10);
	}

	method buttonEndActive(e) {
		this.selected.applyStyle(this.getStyle('selected'));
	}

	style selected {
		background: rgba(0,0,0,0.3);
	}

	style unselected {
		background: rgba(0,0,0,0.1);
	}
}

def GrapherEquationChoice(buttons) {
	extends {
		GrapherButtonChoice
	}

	on buttons-updated {
		this.buttons.map(function(button) {
			button.$.css('border-radius',10).css('margin-right',5)
		});
	}

	css {
		cursor: pointer;
	}

	style selected {
		-webkit-transform: scale(1);
	}	

	style unselected {
		-webkit-transform: scale(0.8);
	}
}

def GrapherEquationChoiceButton(color,equation) {
	html {
		<div></div>
	}

	css {
		vertical-align: middle;
		display: inline-block;
		width: 30px;
		height: 30px;
		margin-right: 10px;
		background: $color;
		opacity: 1;
	}

	style default {

	}

	style active {

	}

	extends {
		Button
	}
}

def GrapherTraceHandle {
	html {
		<div></div>
	}

	css {
		position: absolute;
		top: 0;
		left: 0;
		display: none;
		height: 20px;
		width: 20px;
		border-radius: 25px;
		background: rgba(0,0,0,0.25);
	}

	method flyIn {
		$this.css('opacity',0).css('scale',5).show();
		$this.animate({
			'scale': 1,
			'opacity': 1
		},300,'easeOutBack');
	}

	method flyOut {
		$this.css('opacity',1).css('scale',1).show();
		$this.animate({
			'scale': 5,
			'opacity': 0
		},300,'easeOutBack',function() {
			$this.hide();
		});
	}
}

def GrapherRange {
	html {
		<div></div>
	}

	method setColor(color) {
		$this.css('background',color);
	}

	css {
		position: absolute;
		height: 100%;
		opacity: 0.25;
		top: 0;
	}
}

def SideReadout {
	html {
		<div>
			<span class='inner'></span>
		</div>
	}

	constructor {
		this.shown = false;
		$this.css('translateX',-1000);
	}

	css {
		display: block;
		color: #FFF;
		margin-bottom: 5px;
	}

	method setContents(c) {

		this.$inner.html(c);
	}

	method slideOut {
		if(!this.shown) return
		$this.animate({
			'translateX': 0 - this.$inner.outerWidth()
		},300,'easeInOutBack');
		this.shown = false;
	}

	method slideIn {
		if(this.shown) return
		$this.css({
			'translateX': 0 - this.$inner.outerWidth()
		}).animate({
			'translateX': -90
		},300,'easeInOutBack');
		this.shown = true;
	}

	my inner {
		css {
			padding: 10px;
			padding-left: 100px;
			background: #333;
			display: inline-block;
		}
	}


}

def ReadoutsContainer {
	html {
		<div></div>
	}

	method showThese(children) {
		children.filter(function(child) {
			return child.$.is($this.children());
		}).map(function(child,i) {
			setTimeout(function() {
				child.slideIn();
			},100*i);
		});

	}

	method hideThese(children) {
		children.filter(function(child) {
			return child.$.is($this.children());
		}).map(function(child,i) {
			setTimeout(function() {
				child.slideOut();
			},100*i);
		});

	}

	css {
		position: absolute;
		z-index: 1000;
	}
}

def TraceReadouts {
	extends {
		ReadoutsContainer
	}

	constructor {
		$this.append(elm.create('SideReadout').named('point'));
		$this.append(elm.create('SideReadout').named('derivative'));
	}

	method show {
		this.showThese([
			this.@point,
			this.@derivative
		]);
	}

	method hide {
		this.hideThese([
			this.@point,
			this.@derivative
		]);
	}

	method update(x,y,func) {
		this.@point.setContents('(' + x.toPrecision(4) + ',' + (0 - y).toPrecision(4) + ')');
		if(func) {
			var d;
			app.storage.trigForceRadians(function() {
				d = new Derivative(func).at(x).toString();
			});
			self.@derivative.setContents('d/dx = ' + d);
		} else {
			this.@derivative.setContents('d/dx = 0');
		}
	}

	css {
		left: 0;
		top: 70px;
	}
}

def RangeReadouts {
	extends {
		ReadoutsContainer
	}

	constructor {
		$this.append(elm.create('SideReadout').named('interval'));
		$this.append(elm.create('SideReadout').named('interval-width'));
		$this.append(elm.create('SideReadout').named('slope'));
		$this.append(elm.create('SideReadout').named('max'));
		$this.append(elm.create('SideReadout').named('min'));
		$this.append(elm.create('SideReadout').named('integral'));
		$this.append(elm.create('SideReadout').named('average'));
	}

	method showDynamic {
		this.showThese([
			this.@interval,
			this.@interval-width,
			this.@slope
		]);
		this.hideThese([
			this.@max,
			this.@min,
			this.@average,
			this.@integral
		]);
	}

	method show {
		this.showThese([
			this.@interval,
			this.@interval-width,
			this.@slope,
			this.@max,
			this.@min,
			this.@average,
			this.@integral
		]);
	}

	method hide {
		this.hideThese([
			this.@interval,
			this.@interval-width,
			this.@slope,
			this.@max,
			this.@min,
			this.@average,
			this.@integral
		]);
	}

	method updateDynamic(start,end,func) {
		this.@interval.setContents('[' + start.toPrecision(4) + ',' + end.toPrecision(4) + ']');
		this.@interval-width.setContents('width = ' + (end - start).toPrecision(4));

		if(!func) return;

		var ystart = func.valueOf(
					new Frame({x: start})
				),
			yend = func.valueOf(
					new Frame({x: end})
				);

		this.@slope.setContents('slope = ' + ((yend - ystart) / (end - start)).toPrecision(4));
	}

	method update(start,end,func,points) {
		this.updateDynamic(start,end,func);
		if(!func)
			return;
		var minX,
			maxX,
			minY = Infinity,
			maxY = -Infinity;
		points.filter(function(point) {
			return point.x >= start && point.x <= end;
		}).map(function(point) {
			if(0 - point.y >= maxY) {
				maxX = point.x;
				maxY = 0 - point.y;
			}
			if(0 - point.y <= minY) {
				minX = point.x;
				minY = 0 - point.y;
			}
		});
		this.@min.setContents('min &#8776; (' + minX.toPrecision(4) + ',' + minY.toPrecision(4) + ')');
		this.@max.setContents('max &#8776; (' + maxX.toPrecision(4) + ',' + maxY.toPrecision(4) + ')');
		var integral = new Integral(new Value(start),new Value(end),func);
		var ir;
		app.storage.trigForceRadians(function() {
			ir = integral.valueOf(null,10000,3);
		});
		this.@integral.setContents('∫ &#8776; ' + ir.toPrecision(4));
		this.@average.setContents('average &#8776; ' + (ir / Math.abs(end-start)).toPrecision(4));
	}

	css {
		left: 0;
		top: 70px;
	}
}

def GrapherReadout {
	html {
		<span></span>
	}

	css {
		background: rgba(255,255,255,0.4);
		padding-left: 5px;
		padding-top: 5px;
		padding-bottom: 5px;
		width: 100%;
		left: 0;
		position: absolute;
		font-size: 0.8em;
	}
}