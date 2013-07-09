function Sound() {
	this.bank = {};
}

Sound.prototype.playSound = function(url) {
	var a = new Audio();
	a.src = url;
	a.preload = true;
	a.play();
}

function SoundBank(url,num) {
	num |= 10;
	this.pointer = 0;
	this.bank = [];
	for(var i=0;i<num;i++) {
		var a = new Audio();
		a.src = url;
		a.preload = true;
		this.bank.push(a);
	}
}

SoundBank.prototype.play = function() {
	var a = this.bank[this.pointer];
	a.play();
	this.pointer++;
	if(this.pointer > this.bank.length - 1) {
		this.pointer = 0;
	}
}
