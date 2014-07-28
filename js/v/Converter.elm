def Converter {
	extends {
		PageView
	}

	properties {
		noKeyboard: true
	}

	css {
		background: #FFF;
	}

	constructor {
		this.$title.html('Converter');
		this.$top-bar-container.hide();
	}

	on displayed {
		setTimeout(function() {
			self.$upper.css('line-height',(1.00 * self.$upper.height()) + 'px').css('opacity',1);
		});
	}

	method update {
		var value = self.$input-inline.get(0).data;
		if(value && self.fromUnit && self.toUnit) {
			var q = Qty(value.real.toString() + self.fromUnit).to(self.toUnit);
			self.$output-inline.get(0).display(q.scalar);
			self.$output-inline.get(0).shake();
		}
	}

	my contents-container {
		contents {
			<div class='upper'>
				<div class='input-inline'>Input...</div>
				<div class='switch-button'></div>
				<div class='output-inline'>...Output</div>
			</div>
			<div class='lower'>
				<div class='item-list type-list'>

				</div>
				<div class='item-list from-list'>

				</div>
				<div class='item-list to-list'>

				</div>
			</div>
		}

		css {
			height: 100%;
		}

		my input-inline {
			extends {
				InlineNumberPicker
			}

			css {
				display: inline-block;
				width: 40%;
				margin: 0;
				margin-right: 2.5%;
				padding-top: 2%;
				padding-bottom: 2%;
			}

			on choose {
				root.update();
			}
		}

		my output-inline {
			extends {
				InlineNumber
				Shake
			}

			properties {
				roundTo: 10
			}

			css {
				display: inline-block;
				width: 40%;
				margin-left: 2.5%;
				padding-top: 2%;
				padding-bottom: 2%;
			}
		}

		my switch-button {
			css {
				display: inline-block;
			}
		}

		my upper {
			css {
				opacity: 0;
				text-align: center;
				width: 100%;
				height: 25%;
			}
		}

		my lower {
			css {
				width: 100%;
				height: 75%;
			}
		}

		my item-list {
			extends {
				ListView
			}

			properties {
				fieldType: 'ConverterListItem'
			}

			my top-bar-container {
				css {
					display: none;
				}
			}

			css {
				height: 100%;
				width: 33.33%;
				float: left;
				background: #FFF;
				position: relative;
			}
		}

		my type-list {
			constructor {
				this.types = {
					'Acceleration': ['meter/s^2','feet/s^2', 'gee'],
					'Angle': ['radian','degree','grad'],
					'Area': ['feet^2','inch^2','meter^2','cm^2','mm^2','hectare','acre'],
					'Bytes': ['byte','kB','KiB','MB','MiB','GB','GiB','TB','TiB','PiB','PB','EB','EiB','bit','kb','Kib','Mb','Mib','Gb','Gib','Tb','Tib','Pb','Pib','Eb','Eib'],
					'Energy': ['joule','kilojoule','megajoule','erg','btu','calorie','Calorie','therm'],
					'Force': ['newton','kilonewton','meganewton','dyne','pound-force'],
					'Length': ['kilometer','mile','inch','feet','yard','nmi','league','furlong','angstrom','fathom','light-second','light-minute','light-year','parsec','picometer','nanometer','micrometer','millimeter','centimeter','decimeter','decameter','hectometer'],
					'Mass': ['ounce','pound','gram','kilogram','ton','tonne','milligram','microgram','grain','dram','stone','carat','AMU'],
					'Power': ['watt','horsepower'],
					'Pressure': ['pascal','kilopascal','atmosphere','bar','mmHg','psi'],
					'Radiation': ['sievert','roentgen'],
					'Temperature': ['tempF','tempC','tempK'],
					'Time': ['second','minute','hour','day','week','fortnight','year','decade','century'],
					'Velocity': ['mile/hr','km/hr','mile/min','km/min','mile/sec','km/sec','m/sec','ft/sec'],
					'Volume': ['liter','gallon','quart','pint','cup','fluid-ounce','tablespoon','teaspoon','bushel','meter^3','millimeter^3','inch^3','feet^3']
				};

				for(t in this.types) {
					var f = this.addField(null,false);
					f.$.html(t);
				}
				this.select(this.$ConverterListItem.get(0));
			}

			method select(item) {
				if(this.selected) {
					this.selected.deselect();
				}
				item.select();
				this.selected = item;
				root.$from-list.get(0).$ConverterListItem.remove();
				root.$to-list.get(0).$ConverterListItem.remove();
				this.types[item.$.html()].forEach(function(type) {
					typeString = type.split('temp').join('degrees ').split('-').join(' ');
					var ff = root.$from-list.get(0).addField(null,false);
					ff.unit = type;
					ff.$.html(typeString);
					var tf = root.$to-list.get(0).addField(null,false);
					tf.unit = type;
					tf.$.html(typeString);
				})
				root.fromUnit = null;
				root.toUnit = null;
				root.$from-list.get(0).updateScroll();
				root.$to-list.get(0).updateScroll();
			}

			css {
				font-weight: bold;
				background: #CCC;
			}
		}

		my from-list {
			method select(item) {
				if(this.selected) {
					this.selected.deselect();
				}
				item.select();
				this.selected = item;
				root.fromUnit = item.unit;
				root.update();
			}

			css {
				background: #DDD;
			}
		}

		my to-list {
			method select(item) {
				if(this.selected) {
					this.selected.deselect();
				}
				item.select();
				this.selected = item;
				root.toUnit = item.unit;
				root.update();
			}

			css {
				background: #EEE;
			}
		}
	}
}

def ConverterListItem {
	extends {
		SimpleListItem
	}

	css {
		font-size: 12px;
		background: none;
		padding-left: 10px;
	}

	style default {
		background: none
	}

	style active {
		background: none;
	}

	method select {
		this.enabled = false;
		this.setStyle('default','background','rgba(0,0,0,0.1)');
		this.applyStyle('default');
	}

	method deselect {
		this.enabled = true;
		this.setStyle('default','background','none');
		this.applyStyle('default');
	}

	on invoke {
		this.parent('ListView').select(this);
	}
}