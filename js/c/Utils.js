// Pretty much a bunch of utility functions

function Utils() {

}

Utils.log = function() {
	console.log(arguments);
}

Utils.prototype.point = function(x,y) {
	return {
		x: x,
		y: y
	};
};

Utils.prototype.argArr = function(argObj) {
	var arr = [];
	for(var i=0;i<argObj.length;i++) {
		arr.push(argObj[i]);
	}
	return arr;
}

Utils.prototype.viewport = function() {
	return this.point(
		$(window).width(),
		$(window).height()
	);
}

Utils.prototype.colors = function() {
	return ['#696','#A33','#0A4766','#B6DB49','#50C0E9','#FB3'];
}

Utils.prototype.hitTest = function(touch, elemposition, width, height) {
    var left = elemposition.left,
        right = left + width,
        top = elemposition.top,
        bottom = top + height,
        touchX = touch.pageX,
        touchY = touch.pageY;
    return (touchX > left && touchX < right && touchY > top && touchY < bottom);
};

Utils.prototype.tabletMode = function() {
	var v = utils.viewport();
	return v.x > 800 && v.y > 600;
}

Utils.prototype.isAppleWebApp = function() {
	var ua = navigator.userAgent;
	if(ua.indexOf('AppleWebKit') > -1 && ua.indexOf('Safari') == -1) {
		return true;
	} else {
		return false;
	}
}

Utils.prototype.profile = function(func,name,silent) {
	var t1 = new Date().valueOf();
	func();
	var t2 = new Date().valueOf();
	if(!silent) console.log('Profile[' + name + ']: ' + (t2-t1) + 'ms');
}

var utils = new Utils();

// A set of utilities for manipulating and parsing strings. StringUtil is lifted
// more or less directly from as3corelib's StringUtil...todo add license?

var StringUtil = {};
var ParseUtil = {};

StringUtil.stringsAreEqual = function (s1, s2, caseSensitive) {
	if (caseSensitive) {
		return (s1 == s2);
	} else {
		return (s1.toUpperCase() == s2.toUpperCase());
	}
}

StringUtil.trim = function (input) {
	return StringUtil.ltrim(StringUtil.rtrim(input));
};


StringUtil.ltrim = function (input) {
	var size = input.length;
	for (var i = 0; i < size; i++) {
		if (input.charCodeAt(i) > 32) {
			return input.substring(i);
		}
	}
	return "";
}

StringUtil.rtrim = function (input) {
	if (!input) return '';
	var size = input.length;
	for (var i = size; i > 0; i--) {
		if (input.charCodeAt(i - 1) > 32) {
			return input.substring(0, i);
		}
	}
	return "";
}

StringUtil.beginsWith = function (input, prefix) {
	return (prefix == input.substring(0, prefix.length));
}

StringUtil.endsWith = function (input, suffix) {
	return (suffix == input.substring(input.length - suffix.length));
}

StringUtil.remove = function (input, remove) {
	return StringUtil.replace(input, remove, "");
}

StringUtil.replace = function (input, replace, replaceWith) {
	return input.split(replace).join(replaceWith);
}

StringUtil.stringHasValue = function (s) {
	//todo: this needs a unit test
	return (s != null && s.length > 0);
}

StringUtil.trimslashes = function (raw) {
	var str = new String(raw)
	var myPattern = new RegExp("\\'", 'g')
	str = str.replace(myPattern, "'")
	myPattern = /\\\\/g;
	str = str.replace(myPattern, "\\")
	return str;
}

ParseUtil.split = function(src,c) {
	var r = [];
	var t = ParseUtil.findEach(src,c,true);
	var index = 0;
	for(var i = 0;i<t.length;i++){
		var ind = t[i].index;
		var match = t[i].match;
		if(ParseUtil.isClear(src,ind)){
			r.push(src.slice(index,ind))
			index = ind + match.length;
		}
	}
	r.push(src.slice(index));
	return r;
}


ParseUtil.isClear = function (src, ind) {
	var paren = 0;
	var quote = "";
	var cbracket = 0;
	var sbracket = 0;
	var abracket = 0;
	var bar = false;
	var t = src.charAt(ind);
	for (var i = 0; i < ind + 1; i++) {
		var c = src.charAt(i);
		if ((c == "'" || c == '"') && src.charAt(i - 1) != "\\") {
			if (quote == "") {
				quote = c;
			} else if (quote == c) {
				quote = "";
			}
		}
		if (quote != "") continue;
		if (c == "{") cbracket++;
		if (c == "}") cbracket = Math.max(cbracket - 1, 0);
		if (c == "[") sbracket++;
		if (c == "<") abracket--;
		if (c == ">") abracket++;
		if (c == "]") sbracket--;
		if (c == "(") paren++;
		if (c == ")") paren--;
	}
	if(t == "(") {
		return cbracket == 0 && abracket == 0 && sbracket == 0 && paren == 1 && quote == "";
	}
	if(t == "[") {
		return cbracket == 0 && abracket == 0 && sbracket == 1 && paren == 0 && quote == "";
	}
	if(t == "<") {
		return cbracket == 0 && abracket == 1 && sbracket == 0 && paren == 0 && quote == "";
	}
	if(t == "{") {
		return cbracket == 1 && abracket == 0 && sbracket == 0 && paren == 0 && quote == "";
	}
	return cbracket == 0 && sbracket == 0 && abracket == 0 && paren == 0 && quote == "";
}

ParseUtil.nextIndexOf = function (a, src) {
	if (!(a instanceof Array)) {
		a = [a];
	};
	for (var j = 0; j < a.length; j++) {
		var test = a[j];
		var arr = ParseUtil.findEach(src, test)
		for (var k = 0; k < arr.length; k++) {
			var i = arr[k];
			if (ParseUtil.isClear(src, i)) {
				return i;
			}
		}
	}
	return -1;
}

ParseUtil.findEachClear = function (src, search, match) {
	var res = ParseUtil.findEach(src, search, match);
	return res.filter(function (n) {
		return ParseUtil.isClear(src, n);
	});
};

ParseUtil.findEach = function (src, search, match) {
	var arr = [];
	if (typeof search == "string") search = [search];
	search.forEach(function (s) {
		var index = -1;
		var substring = src;
		var i;
		do {
			i = substring.indexOf(s)
			if (i == -1) break
			index += i + 1;
			arr.push({index: index, match: s});
			substring = substring.slice(i + 1);
		} while (i != -1);
	});
	arr = arr.sort(function (a, b) {
		return a.index - b.index;
	});
	if(!match) {
		arr = arr.map(function(i) {
			return i.index;
		});
	}
	return arr;
}


ParseUtil.completeStatement = function (src) {
	var paren = 0;
	var quote = "";
	var cbracket = 0;
	var sbracket = 0;
	var bar = false;
	var trySub = false;
	var sub = false;
	var subIndex = 0;
	var substring;
	var j = 0;

	for (var i = 0; i < src.length; i++) {
		var c = src.charAt(i);
		if ((c == "'" || c == '"') && src.charAt(i - 1) != "\\") {
			if (quote == "") {
				quote = c;
			} else if (quote == c) {
				quote = "";
			}
		}
		if (quote != "") continue;
		if (c == "(") paren++;
		if (c == ")") paren--;
		if (c == "{") cbracket++;
		if (c == "}") cbracket--;
		if (c == "[") sbracket++;
		if (c == "]") sbracket--;

	}
	return quote == "" && paren == 0 && cbracket == 0 && sbracket == 0;
}

ParseUtil.replace = function (src, from, to) {
	return ParseUtil.split(src, from).join(to);
}

ParseUtil.handleEscapeChars = function (s) {
	return s.replace(/\\n/g, "\n").replace(/\\t/g, "\t");
}

function FocusManager() {
	this.current = null;
	this.fields = [];
}

FocusManager.prototype.getCurrent = function() {
	return this.current || app.nullInput;
}

FocusManager.prototype.setFocus = function(c) {
	var self = this;
	if(c == this.current) return;
	if(this.current) {
		this.current.mathSelf().cursor.hide();
		this.current.$.trigger('lost-focus');
	}
	setTimeout(function() {
		self.fields.forEach(function(field) {
			if(field != c) {
				field.mathSelf().cursor.hide();
			}
		});
	},1);
	this.current = c;
	if(!this.current) return;
	this.current.mathSelf().cursor.show();
	this.current.$.trigger('gain-focus');
}

FocusManager.prototype.register = function(f) {
	this.fields = this.fields || [];
	this.fields.push(f);
}

$.fn.extend({ 
    disableSelection : function() { 
        this.each(function() { 
            this.onselectstart = function() { return false; }; 
            this.unselectable = "on"; 
            $(this).css('-moz-user-select', 'none'); 
            $(this).css('-webkit-user-select', 'none'); 
        }); 
    } 
});

function DocsParser(url,callback) {
	this.url = url;
	this.callback = callback;
	this.load();
}

DocsParser.prototype.load = function() {
	var self = this;
	$.get(this.url,function(txt) {
		if(self.callback) self.callback(self.parse(txt));
	});
}

DocsParser.prototype.parse = function(txt) {
	var current;
	var res = {};
	txt = txt.split('\n');
	for(var i=0;i<txt.length;i++) {
		var line = txt[i],
			start = line.charAt(0);
		if(!line.trim().length || line.charAt(0) == '#') continue;
		if(start == '\t') {
			// Property of an object
			var split = line.split(':');
			if(split[1].split(',').length > 1 && split[1].slice(-1) != '.') {
				split[1] = split[1].split(',').map(function(s) { return s.trim(); });
			} else {
				split[1] = split[1].trim();
			}
			current[split[0]] = split[1];
		} else {
			if(line.slice(-1) == ':') {
				line = line.slice(0,-1);
			}
			var split = line.split(' ');
			res[split[0]] = res[split[0]] || {};
			res[split[0]][split[1]] = {};
			current = res[split[0]][split[1]];
		}
	}
	return res;
}
