function Solver(left,right) {
	this.frame = new Frame();
	var self = this;
	this.left = left;
	this.right = right;
	if(this.left instanceof Solver || this.right instanceof Solver) {
		throw 'Cannot solve nested equations';
	}
}

Solver.prototype.leftAt = function(x) {
	this.frame.set('x',x);
	return this.left.valueOf(this.frame).toFloat();
}

Solver.prototype.rightAt = function(x) {
	this.frame.set('x',x);
	return this.right.valueOf(this.frame).toFloat();
}

Solver.prototype.f = function(x) {
	return this.leftAt(x) - this.rightAt(x);
}

Solver.prototype.fPrime = function(x) {
	var dx = .00001;
	return (this.f(x + dx ) - this.f(x)) / dx;
}

Solver.prototype.guess = function(guess) {
	var betterGuess,
		precision = .0001,
		iteration = 0,
		x = undefined,
		ddx = undefined,
		last_ddx = undefined,
		epsilon = 1e-20,
		ddx_steadyCount = 0,
		repeat = 100;
	// Some asshole is going to try and solve N/x = 0 and we just don't like to see that...
	try {
		var left0 = this.leftAt(0);
	} catch(e) {
		var right0 = this.rightAt(0);
		if(right0 == 0) {
			this.cannotSolve();
		}
	}
	try {
		var right0 = this.rightAt(0);
	} catch(e) {
		var left0 = this.leftAt(0);
		if(right0 == 0) {
			this.cannotSolve();
		}
	}
	while(iteration < repeat) {
		iteration++;
		x = this.f(guess);
		ddx = this.fPrime(guess);
		console.log(x,ddx);
		if(Math.abs(ddx) < epsilon) {
			// this.cannotSolve();
		}
		if(last_ddx === ddx) {
			ddx_steadyCount++;
		}
		last_ddx = ddx;
		if(ddx == 0) {
			guess++;
			continue;
		}
		betterGuess = guess - x / ddx;
		if(Math.abs(betterGuess - guess) < precision) {
			break;
		}
		guess = betterGuess;
	}
	if(ddx_steadyCount == repeat - 1) {
		// If the derivative never changed, that's probably because both sides are constant
		if(this.leftAt(guess) == this.rightAt(guess)) {
			// Yep, left == right.
			this.result = true;
		} else {
			// No, left != right.
			this.result = false;
		}
	} else {
		// A few more things we can try
		var abs_guess = Math.abs(guess);
		if(this.f(guess) == this.f(abs_guess)) {
			// If we got a negative root with a corresponding positive root it makes more sense to give the positive one
			guess = abs_guess;
		}
		var normalized_guess = Functions.normalize(guess,app.storage.trigUseRadians);
		if(this.f(guess) == this.f(normalized_guess)) {
			// If it's an angle we should try to normalize it
			guess = normalized_guess;
		}
		this.result = new Value(guess).round(3);
	}
	return this.result;
}

Solver.prototype.cannotSolve = function() {
	throw "Can't solve";
}

Solver.prototype.toString = function() {
	var s = this.guess(.001);
	if(s === true || s === false) {
		if(s) {
			return 'That is true';
		} else {
			return 'That is false'
		}
	} else {
		if(true) {
			return 'x = ' + s.toString();
		} else {
			return 'Failed to solve';
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