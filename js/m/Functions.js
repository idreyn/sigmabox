var Functions = {};

Functions.gcf = function() {
	var args = utils.argArr(arguments).filter(function(item) {
		return item != 0;
	});
	if(args.length == 1) {
		return args[0];
	}
	var first = Math.abs(args.pop());
	var second = Math.abs(args.pop());
	var max = 1;
	for(var i=1;i<=Math.min(first,second);i++) {
		if(
			Math.floor(first / i) == first / i &&
			Math.floor(second / i) == second / i &&
			i > max
		) {
			max = i;
		}
	}
	if(args.length != 0) {
		return Math.min(max,Functions.gcf(args));	
	} else {
		return max;
	}	
}

Functions.scaleToWhole = function() {
	var args = utils.argArr(arguments).filter(function(item) {
		return item != 0;
	});
	var i = 0;
	while(args.filter(function(i) {
		return i != Math.round(i)
	}).length != 0) {
		i++;
		args = args.map(function(i) {
			return 10 * i;
		});
	}
	return Math.pow(10,i);
}

Functions.d2r = function(n) {
	if(n instanceof Value) {
		return new Value(
			n.real * (Math.PI / 180),
			n.complex * (Math.PI / 180)
		);
	} else {
		return n * (Math.PI / 180);
	}
}

Functions.r2d = function(n) {
	if(n instanceof Value) {
		return new Value(
			n.real / (Math.PI / 180),
			n.complex / (Math.PI / 180)
		);
	} else {
		return n / (Math.PI / 180);
	}
}

Functions.normalize = function(v,r) {
	var min = 0;
	var max = r? 2*Math.PI : 360;
	while(!(v >= min && v <= max)) {
		if(v > max) {
			v -= max;
		} else {
			v += max;
		}
	}
	return v;
}

Functions.round = function(num, dec) {
	return Math.round(num*Math.pow(10,dec))/Math.pow(10,dec);
};

Functions.mod = function(a,b) {
	return a % b;
}

Functions.factorial = function(n) {
	if(n == 0) return 1;
	return n * Functions.factorial(n-1);
}

Functions.nPr = function(n,r) {
	return Functions.factorial(n) / Functions.factorial(n-r);
}

Functions.nCr = function(n,r) {
	return Functions.nPr(n,r) / Functions.factorial(r);
}

Functions.complexRaise = function(base,power) {
	
	// Infinite thanks to Stephen R. Schmitt for this one!
	// http://mysite.verizon.net/res148h4j/zenosamples/zs_complexnumbers.html
	
	base = new Value(base);
	power = new Value(power);
	var baseTrig = base.toComplexTrigForm();
	var rho = baseTrig.modulus;
	var theta = baseTrig.argument;
	var c = power.real;
	var d = power.complex;

	var phi = c * theta + d * Math.log(rho);

	var _args = [];

	_args.push(
		new Value(Math.pow(rho,c))
	);

	_args.push(
		new Value(Math.pow(
			Math.E,
			-1 * power.complex * theta
		))
	);

	_args.push(
		new Value(
			Math.cos(phi),
			Math.sin(phi)
		)
	);

	return new Mult(_args).valueOf().round(5);
};

Functions.csc = function(x) {
	return 1 / Math.sin(x);
}

Functions.sec = function(x) {
	return 1 / Math.cos(x);
}

Functions.cot = function(x) {
	return 1 / Math.tan(x);
}

Functions.acsc = function(x) {
	return Math.asin(1/x);
}

Functions.asec = function(x) {
	return Math.acos(1/x);
}

Functions.acot = function(x) {
	return Math.tan(1/x);
}

Functions.sinh = function(x) {
	return 0.5 * (Math.exp(x) - Math.exp(-x));
}

Functions.cosh = function(x) {
	return 0.5 * (Math.exp(x) + Math.exp(-x));
}

Functions.tanh = function(x) {
	return Functions.sinh(x) / Functions.cosh(x);
}

Functions.csch = function(x) {
	return 1 / Functions.sinh(x);
}

Functions.sech = function(x) {
	return 1 / Functions.cosh(x);
}

Functions.coth = function(x) {
	return 1 / Functions.tanh(x);
}

Functions.asinh = function(x) {
	return Math.log(x + Math.sqrt(x*x + 1));
}

Functions.acosh = function(x) {
	if(!(x >= 1)) throw 'Domain error (acosh)';
	return Math.log(x + Math.sqrt(x*x + 1));
}

Functions.atanh = function(x) {
	if(!(Math.abs(x) < 1)) throw 'Domain error (atanh)';
	return 0.5 * Math.log((1+x)/(1-x));
}

Functions.acsch = function(x) {
	if(!(x != 0)) throw 'Domain error (acsch)';
	return Math.log( (1/x) + ( Math.sqrt(1 + x*x) / Math.abs(x) ) );
}

Functions.asech = function(x) {
	if(!(x > 0 && x < 1)) throw 'Domain error (asech)';
	return Math.log( (1/x) + ( Math.sqrt(1 - x*x) /x ) );
}

Functions.acoth = function(x) {
	if(!(Math.abs(x) > 1)) throw 'Domain error (acoth)';
	return 0.5 * Math.log((x+1)/(x-1));
}

Functions.identityMatrix = function(n) {
	var res = [];
	for(var i=0;i<n;i++) {
		var row = [];
		for(var j=0;j<n;j++) {
			row.push(new Value(j == i ? 1 : 0));
		}
		res.push(row);
	}
	return new Matrix(res);
};
