var Functions = {};

Functions.gcf = function() {
	var args = app.utils.argArr(arguments).filter(function(item) {
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
	var args = app.utils.argArr(arguments).filter(function(item) {
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
