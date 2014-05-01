Number.prototype.toFloat = function() {
	return this;
}

function Solver(left,right) {
	this.frame = new Frame();
	var self = this;
	this.left = left;
	this.right = right;
	this.solveMode = 'linear';
	if(this.left instanceof Solver || this.right instanceof Solver) {
		throw 'Cannot solve nested equations';
	}
}

Solver.prototype.leftAt = function(x) {
	this.frame.set('x',x);
	var v =  this.left.valueOf(this.frame);
	return v.toFloat()
}

Solver.prototype.rightAt = function(x) {
	this.frame.set('x',x);
	var v = this.right.valueOf(this.frame);
	return v.toFloat();
}

Solver.prototype.f = function(x) {
	try {
		if(this.solveMode == 'linear') {
			return this.leftAt(x) - this.rightAt(x);
		}
		if(this.solveMode == 'exponential') {
			return Math.exp(this.leftAt(x)) - Math.exp(this.rightAt(x));
		}
		if(this.solveMode == 'logarithmic') {
			return Math.log(this.leftAt(x)) - Math.log(this.rightAt(x));
		}
	} catch(e) {
		return 0;
	}
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
	// Some assclown is going to try and solve N/x = 0 and we just don't like to see that...
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
	if(isNaN(guess)) {
		this.cannotSolve();
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
		// If it's an angle we should try to normalize it
		if(app.data.trigUseRadians) {
			var offsets = [0, Math.PI/2, Math.PI, 3*Math.PI/2];
		} else {
			var offsets = [0,90,180,270];
		}
		var new_guess = guess;
		for(var i=0;i<offsets.length;i++) {
			var normalized_guess = Functions.normalize(guess,app.data.trigUseRadians) - offsets[i];
			if(Functions.aboutEquals(this.f(guess),this.f(normalized_guess))) {
				if(normalized_guess > 0) new_guess = normalized_guess;
			}
		}
		guess = new_guess;
		// If we got a negative root with a corresponding positive root it makes more sense to give the positive one
		var abs_guess = Math.abs(guess);
		if(this.f(guess) == this.f(abs_guess)) {
			guess = abs_guess;
		}
	}
	this.lr = this.leftAt(guess) - this.rightAt(guess);
	this.result = new Value(guess).round(3);
	if(Functions.aboutEquals(this.leftAt(this.result),this.rightAt(this.result),5) || true) {
		return this.result;
	} else {
		this.cannotSolve();
	}
}

Solver.prototype.pickBestSolution = function(poss) {
	var self = this;
	poss = poss.filter(function(a) {
		return a !== false
	}).map(function(a) {
		return {x: a, f: self.f(new Value(a).toFloat())};
	}).sort(function(a,b) {
		return Math.abs(a.f) > Math.abs(b.f) ? 1 : -1;
	});
	var res =  poss[0];
	if(res) {
		return res.x;
	} else {
		return false;
	}
}

Solver.prototype.cannotSolve = function() {
	throw "Can't solve";
}

Solver.prototype.solve  = function() {
	this.solveMode = 'linear';
	try {
		var lin = this.guess(0.01);
	} catch(e) {
		lin = false;
	}
	this.solveMode = 'exponential';
	try {
		var exp = this.guess(0.01);
	} catch(e) {
		exp = false;
	}
	this.solveMode = 'logarithmic';
	try {
		var log = this.guess(0.01);
	} catch(e) {
		log = false;
	}
	this.solveMode = 'linear';
	var poss = [lin,exp,log];
	var res = this.pickBestSolution(poss);
	if(res) {
		return res;
	} else {
		this.cannotSolve();
	}
}

Solver.prototype.toString = function() {
	var s = this.solve();
	if(s === true || s === false) {
		if(s) {
			return 'That is true';
		} else {
			return 'That is false';
		}
	} else {
		if(true) {
			return 'x = ' + s.toString();
		} else {
			return 'Failed to solve';
		}
	}
}

Solver.parse = function(l,r) {
	var p = new Parser();
	l = p.parse(l);
	r = p.parse(r);
	return new Solver(l,r);
}

function QuadraticSolver(a,s1,b,s2,c) {
	if(a === '-') a = -1;
	if(a === '') a = 1;
	if(b === '') b = 1;
	if(c === '') c = 0;
	if(b === undefined || b === false) b = 0;
	if(c === undefined || c === false) c = 0;
	a = parseFloat(a);
	b = parseFloat(b);
	c = parseFloat(c);
	if(s1 == '-') b = 0 - b;
	if(s2 == '-') c = 0 - c;
	this.a = new Value(a);
	this.b = new Value(b);
	this.c = new Value(c);
}

QuadraticSolver.prototype.solve = function() {
	var p = new Parser();
	var f = new Frame({
		a: this.a,
		b: this.b,
		c: this.c
	});
	var s1 = p.parse('\\frac{-b+\\sqrt{(b)^{2}-(4)(a)(c)}}{2a}').valueOf(f);
	var s2 = p.parse('\\frac{-b-\\sqrt{(b)^{2}-(4)(a)(c)}}{2a}').valueOf(f);
	return [s1,s2];
}

QuadraticSolver.prototype.toString = function() {
	return 'x = {'+this.solve().map(function(s){ return new Value(s.decimalize()).round(4); }).join(',') + '}';
}

function PolySolver(coeffs) {
	var self = this;
	this.coeffs = Functions.values(coeffs);
	if(!this.coeffs[this.coeffs.length - 1].equals(new Value(1))) {
		this.coeffs = this.coeffs.map(function(c) {
			return new Frac(
					c,
					self.coeffs[self.coeffs.length - 1]
			).decimalize();
		});
	}
	this.func = function(x) {
		var res = new Value(0);
		for(var i=0;i<this.coeffs.length;i++) {
			res = res.add(
				this.coeffs[i].mult(
					new Pow(x,i).valueOf()
				)
			);
		}
		return res;
	}
	this.degree = this.coeffs.length - 1;
}

PolySolver.solveString = function(s) {
	var s = PolySolver.match(s);
	if(s) {
		return new PolySolver(s).solve();
	} else {
		return false;
	}
}

PolySolver.match = function(s) {
	var s = StringUtil.trim(s),
		signs = [];
	if(s.charAt(0) == '-') {
		// Leading negative, that's okay.
		s = s.slice(1);
		signs.push('-');
	} else {
		signs.push('+');
	}
	signs = signs.concat(ParseUtil.findEachClear(s,['+','-']).map(function(index) {
		return s.charAt(index);
	}));
	var terms = ParseUtil.split(s,['+','-']),
		coeffs = [],
		termTemplate = /^([0-9i\.\+\-]*|\([0-9i\.\+\-]*\))x(?:\^\{([0-9]*)\})?$/,
		constTemplate = /^[0-9.i]+$/;
	for(var i=0;i<terms.length;i++) {
		var order,
			val,
			t = StringUtil.trim(terms[i]),
			tMatch = t.match(termTemplate),
			cMatch = t.match(constTemplate);
		if(!tMatch && !cMatch) {
			// This term doesn't fit the pattern!
			return false;
		}
		if(cMatch) {
			coeff = t;
			order = 0;
		}
		if(tMatch) {
			var coeff = tMatch[1];
			var order = tMatch[2];
			if(order === undefined) {
				order = 1;
			}
			if(coeff === '') {
				coeff = '1';
			}
		}
		order = parseInt(order);
		coeff = new Parser().parse(coeff).valueOf(new Frame);
		if(!coeffs[order]) {
			coeffs[order] = new Value(0);
		}
		if(signs[i] == '+') {
			coeffs[order] = coeffs[order].add(coeff);
		} else {
			coeffs[order] = coeffs[order].subtract(coeff);
		}
	}
	for(var i=0;i<coeffs.length;i++) {
		if(!coeffs[i]) {
			coeffs[i] = new Value(0);
		}
	}
	return coeffs;
}

PolySolver.prototype.solve = function() {
	var hasAnswer = false;
	if(this.coeffs.length == 1) {
		return [];
	}
	if(this.coeffs.length == 2) {
		if(this.coeffs[0] && this.coeffs[1]) {
			var a = this.coeffs[1];
			var b = this.coeffs[0];
			return [
				new Frac(b.negative(),a).decimalize()
			];
		} else {
			return [
				new Value(0)
			];
		}
	}
	while(!hasAnswer) {
		var r0 = new Value(0.4,0.9);
		var roots = [];
		var prev = [];
		for(var i=0;i<this.degree;i++) {
			roots.push(
				new Pow(r0,i).valueOf()
			);
			prev.push(new Value(0));
		}
		var precision = 0.000001,
			maxDev = Infinity,
			iter = 0,
			maxIter = 100;
		while(maxDev > precision && iter < maxIter) {
			iter++;
			prev = roots.concat();
			for(var i=0;i<roots.length;i++) {
				var currentRoot = roots[i],
					numerator = this.func(currentRoot),
					denominatorFactors = [];
				for(var j=0;j<roots.length;j++) {
					if(i == j) continue;
					var factor = currentRoot.subtract(roots[j]);
					denominatorFactors.push(factor);
				}
				var denominator = denominatorFactors.reduce(function(a,b) {
					return a.mult(b);
				});
				var frac = new Frac(
					numerator,
					denominator
				).decimalize();
				var newRoot = currentRoot.subtract(frac);
				roots[i] = newRoot; 
			}
			var maxDev = roots.map(function(root,index) {
				var prevRoot = prev[index];
				var r = root.subtract(prevRoot);
				return Math.max(r.real,r.complex);
			}).sort(function(a,b) {
				return a > b ? 1 : -1;
			}).pop();
		}
		hasAnswer = true;
	}
	return roots.map(function(n) {
		return n.round(4);
	});
};