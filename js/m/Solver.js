function Solver(left,right) {
	var self = this;
	this.left = left;
	this.right = right;
	if(this.left instanceof Solver || this.right instanceof Solver) {
		throw 'Cannot solve nested equations';
	}
	this.lambda = function(x) {
		return self.left.valueOf(new Frame({x:x})).toFloat() - self.right.valueOf(new Frame({x:x})).toFloat()
	}
	this.ddxlambda = function(x) {
		var dx = .00001;
		return (self.lambda(x + dx) - self.lambda(x)) / dx;
	}
}

Solver.prototype.solve = function() {
	console.log('start solve');
	if(this.solved !== undefined) return this.solved;
	var guess = 1;
	var betterGuess = 0;
	var precision = .0001;
	var it = 0;
	var lastddx = undefined;
	var ddxSteadyCount = 0;
	var repeat = 50;
	while(it < repeat) {
		it++
		var ddx = this.ddxlambda(guess);
		if(lastddx === ddx) {
			ddxSteadyCount++;
		}
		lastddx = ddx;
		if(ddx == 0) {
			guess --;
			continue;
		}
		betterGuess = guess - this.lambda(guess) / ddx;
		if(Math.abs(betterGuess - guess) < precision) {
			break;
		}
		guess = betterGuess;
	}
	if(ddxSteadyCount == repeat - 1) {
		// If the derivative never changed, that's probably because both sides are constant
		if(this.left.valueOf(new Frame()).toFloat() == this.right.valueOf(new Frame()).toFloat()) {
			this.solved = true
		} else {
			this.solved = false;
		}
	} else {
		this.leftRes = this.left.valueOf(new Frame({x: guess})).toFloat();
		this.rightRes = this.right.valueOf(new Frame({x: guess})).toFloat();
		this.error = Math.abs((this.leftRes - this.rightRes) / (this.leftRes + this.rightRes));
		this.solved = new Value(guess).round(3); 
	}
	return this.solved;
}

Solver.prototype.toString = function() {
	var s = this.solve();
	if(s === true || s === false) {
		if(s) {
			return 'Yes it does';
		} else {
			return "No it doesn't";
		}
	} else {
		if(this.error < .01 || this.error == 1) {
			return 'x = ' + s.toString();
		} else {
			return 'Could not solve with acceptable accuracy, error = ' + this.error + ', ' + this.leftRes + ', ' + this.rightRes;
			console.log(this.leftRes,this.rightRes)
		}
	}
}

Solver.parse = function(l,r) {
	var p = new Parser();
	l = p.parse(l);
	r = p.parse(r);
	return new Solver(l,r);
}