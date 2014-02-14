def StatsView {
	extends {
		PageView
	}

	constructor {
		this.@title.$.html('Stats');
		this.addList();
		this.addList();
		this.addList();
		this.addList();
		this.addList();
		this.addList();
		this.addList();
		this.addList();
		this.addList();
		this.addList();
	}

	my contents-container {
		css {
			width: 100%;
		}
	}

	method addList {
		var l = elm.create('StatsList');
		l.delegateFocus(this);
		l.$.css('left',this.$StatsList.length * 320)
		this.@contents-container.$.append(l).css('width',this.$StatsList.length * 320);
		this.selectList(l);
		setTimeout(function() {
			self.updateScroll(true);
		},10);
	}

	method selectList(l) {
		this.currentList = l;
	}

	method currentInput {
		return this.currentList.currentInput();
	}

	my contents-container {
		contents {

		}

		css {
			height: 100%;
		}
	}
}

def StatsList {
	extends {
		ListView
	}

	constructor {
		this.fieldType = 'StatsListField';
	}

	css {
		width: 320px;
		position: absolute;
	}

	my top-bar {
		css {
			background: #999;
		}
	}
}

def StatsListField(focusManager) {
	extends {
		MathTextField
	}
}