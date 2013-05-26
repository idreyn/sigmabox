function Resource() {
	this.disableCache = true;
}

Resource.prototype.loadXML = function(path,callback) {
	var data = {};
	if(this.disableCache) data[Math.random()] = Math.random();
	$.get(
		path,
		data,
		function(res) {
			if(callback) callback(res);
		}
	);
}

Resource.prototype.keyboardImage = function(imageName) {
	return 'res/img/keys/' + imageName + '.png';
}

Resource.prototype.url = function(str)  {
	return 'url(' + str + ')';
}