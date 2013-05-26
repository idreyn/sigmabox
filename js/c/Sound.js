function Sound() {
	this.bank = {};
}

Sound.prototype.playSound = function(url) {
	if(!this.bank[url]) {
		var a = new Audio();
		a.src = url;
		a.preload = true;
		this.bank[url] = a;
	}
	this.bank[url].play();
}


