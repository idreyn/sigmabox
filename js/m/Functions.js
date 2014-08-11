var Functions = {};

Functions.aboutEquals = function(a,b,precision) {
	if(!precision) precision = 6;
	return new Value(a).round(precision).equals(new Value(b).round(precision));
}

Functions.expect = function(arg,type) {
	if(!(arg instanceof type)) {
		throw type.name + ' expected';
	}
}

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
	if(isNaN(v)) throw "Can't normalize this";
	var factor = r? 2*Math.PI : 360;
	v = v % factor;
	if(v < 0) v = v + factor;
	return new Value(v);
}

Functions.abs = function(n) {
	if(n instanceof Value) {
		return n.toComplexTrigForm().modulus;
	} else {
		return Math.abs(n);
	}
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

Functions.power = function(b,p) {
	return Math.pow(b,p);
}

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

Functions.unity = function(n) {
	// e^(2pi*i*k/n), k == 0...n-1
	var roots = [];
	for(var k=0;k<n;k++) {
		roots.push(Functions.complexRaise(Math.E,new Value(0, 2 * Math.PI * k/n)));
	}
	return new Vector(roots);
}

Functions.Re = function(n) {
	if(n instanceof Value) {
		return n.real;
	}
	return parseFloat(n); 
}

Functions.Im = function(n) {
	if(n instanceof Value) {
		return n.complex;
	}
	return 0;
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

Functions.isPrime = function(n) {
	n = Math.abs(n);
	for(var i = 2; i <= n/2; i++) {
		if(n % i == 0) {
			return 0;
		};
	};
	return 1;
};

Functions.nthPrime = function(n) {
	var i = 1;
	var c = 0;
	do {
		i++;
		if(Functions.isPrime(i)) {
			c++;
		};
	} while(c < n);
	return i;
};

Functions.integral = function(a,b,lambda,n,noRound) {
	n = n || 10000;
	var dx = Math.abs((a - b) / n),
		sum = 0,
		heights = [],
		flip,
		inter;
	if(a > b) {
		inter = a;
		a = b;
		b = inter;
		flip = true;
	}
	if(dx == 0 || isNaN(dx)) return 0;
	for(var i = a; i <= b; i += dx) {
		var r = lambda(i);
		if(Math.abs(r) == Infinity) r = 0;
		heights.push(r);
	}
	sum = heights[0];
	for(var i = 1; i < n; i++) {
		sum += 2 * heights[i];
	}
	sum += heights[heights.length - 1];
	sum *= dx * 0.5;
	if(flip) sum *= -1;
	return noRound ?  sum : Functions.round(sum,6);
}

Functions.union = function(a,b) {
	function are_equal(a,b) {
		if(a === undefined || b === undefined) return false;
		if(a.equals) {
			return a.equals(b);
		} else {
			return a == b;
		}
	}
	function vector_index_of(v,item) {
		for(var i=0;i<v.args.length;i++) {
			if(are_equal(v.args[i],item)) {
				return i;
			}
		}
		return -1;
	}
	a.map(function(i) {
		if(i instanceof Matrix || i instanceof Vector) {
			throw 'Invalid data types';
		}
	});
	b.map(function(i) {
		if(i instanceof Matrix || i instanceof Vector) {
			throw 'Invalid list';
		}
	});
	var res = [];
	a = a.copy()
	b = b.copy();
	for(var i=0;i<a.args.length;i++) {
		res.push(a.args[i]);
		var ind = vector_index_of(b,a.args[i])
		if(ind != -1) {
			delete b.args[ind];
		}
	}
	res = res.concat(b.args).filter(function(n) {
		return n !== undefined;
	});
	return new Vector(res);
}

Functions.intersection = function(a,b) {
	function are_equal(a,b) {
		if(a === undefined || b === undefined) return false;
		if(a.equals) {
			return a.equals(b);
		} else {
			return a == b;
		}
	}
	function vector_index_of(v,item) {
		for(var i=0;i<v.args.length;i++) {
			if(are_equal(v.args[i],item)) {
				return i;
			}
		}
		return -1;
	}
	a.map(function(i) {
		if(i instanceof Matrix || i instanceof Vector) {
			throw 'Invalid data types';
		}
	});
	b.map(function(i) {
		if(i instanceof Matrix || i instanceof Vector) {
			throw 'Invalid list';
		}
	});
	var res = [];
	a = a.copy()
	b = b.copy();
	for(var i=0;i<a.args.length;i++) {
		var ind = vector_index_of(b,a.args[i])
		if(ind != -1) {
			res.push(a.args[i]);
			delete b.args[ind];
		}
	}
	res = res.filter(function(n) {
		return n !== undefined;
	});
	return new Vector(res);
}

Functions.stdnormalpdf = function(x) {
	return (1 / Math.sqrt( 2 * Math.PI)) * Math.exp(-0.5 * x * x);
}

Functions.stdnormalcdf = function(z1,z2) {
	z1 = Math.max(-6,z1);
	z2 = Math.min(6,z2);
	return Functions.integral(z1,z2,function(x) {
		return Functions.stdnormalpdf(x);
	},100000);
}

Functions.znormal = function(z) {
	return Functions.stdnormalcdf(-12,z);
}

Functions.normalpdf = function(x,mu,sigma) {
	return (1/sigma) * Functions.stdnormalpdf((x - mu) / sigma);
}


Functions.normalcdf = function(z1,z2,mu,sigma) {
	return Functions.stdnormalcdf(
		((z1 - mu) / sigma),
		((z2 - mu) / sigma)
	);
}

Functions.binompdf = function(n,p,k) {
	if(k > n || k < 0) {
		return 0;
	} else {
		return Functions.nCr(n,k) * Functions.power(p,k) * Functions.power(1-p,n-k);
	}
}

Functions.binomcdf = function(n,p,k) {
	var sum = 0;
	for(var i=0;i<=k;i++) {
		sum += Functions.binompdf(n,p,i);
	}
	return sum;
}

Functions.geompdf = function(p,n) {
	return p * Functions.power(1-p,n-1);
}

Functions.geomcdf = function(p,n) {
	var sum = 0;
	for(var i=1;i<=n;i++) {
		sum += Functions.geometpdf(p,i);
	}
	return sum;
}

Functions.poissonpdf = function(lambda,k) {
	return Math.exp(-lambda) * Functions.power(lambda,k) / Functions.factorial(k);
}

Functions.poissoncdf = function(lambda,k) {
	var sum = 0;
	for(var i=0;i<=k;i++) {
		sum += Functions.poissonpdf(lambda,i);
	}
	return sum;
}

Functions.range = function(min,max,step) {
	if(!step) step = 1;
	var res = [];
	for(var i=min;i<=max;i+=step) {
		res.push(new Value(i));
	}
	return new Vector(res);
}

Functions.sort = function(arr) {
	// I can't believe this isn't the native behavior!
	return arr.sort(function(a,b) { return a > b ? 1 : -1 });
}

Functions.sum = function(arr) {
	return arr.reduce(function(a,b) { return a.add ? a.add(b) : a + b; });
}

Functions.mean = function(arr)
{
	arr = arr.args || arr;
	var sum = 0;
	for(var i=0; i<arr.length; i++)
	{
		sum += arr[i];
	}
	return sum / arr.length;
}

Functions.median = function(arr)
{
	return Functions.quartile(arr,2);
}

Functions.quartile = function(arr,n) {
	arr = arr.args || arr;
	arr = Functions.sort(arr);
	var index = ((n/4) * (arr.length + 1)) - 1;
	if(Math.floor(index) == index) {
		return arr[index];
	} else {
		return (arr[Math.floor(index)] + arr[Math.ceil(index)]) / 2;
	}
}

Functions.mode = function(arr)
{
	arr = arr.args || arr;
	var items = {};
	for(var i=0; i<arr.length; i++)
	{
		if(items[arr[i]] === undefined || items[arr[i]] === null) items[arr[i]] = 0;
		items[arr[i]] ++;
	};
	var modes = [];
	var max = 0;
	for(var prop in items)
	{
		if(items[prop] == max)
		{
			modes.push(Number(prop));
		};
		if(items[prop] > max)
		{
			modes = [Number(prop)];
			max = items[prop];
		};
	};
	if(modes.length == 1) return modes[0];
	return new Vector(modes);
}

Functions.stdev = function(arr,pop)
{
	arr = arr.args || arr;
	var mean = Functions.mean(arr);
	var factor = pop ? 1 / arr.length : 1 / (arr.length - 1);
	return Math.sqrt(factor * Functions.sum(arr.map(function(n){ return Math.pow(n - mean,2); })));
}

Functions.min = function(arr) {
	arr = Functions.numbers(arr);
	var min = Infinity;
	for(var i=0;i<arr.length;i++) {
		if(arr[i] < min) {
			min = arr[i];
		}
	}
	return min;
}

Functions.max = function(arr) {
	arr = Functions.numbers(arr);
	var max = -Infinity;
	for(var i=0;i<arr.length;i++) {
		if(arr[i] > max) {
			max = arr[i];
		}
	}
	return max;
}

Functions.number = function(n) {
	return n.toFloat ? n.toFloat() : parseFloat(n);
}

Functions.numbers = function(arr) {
	return arr.map(function(a) { return a.toFloat ? a.toFloat() : parseFloat(a); });
}

Functions.values = function(arr) {
	return arr.map(function(n) {
		if(!isNaN(n)) {
			return new Value(n);
		} else {
			return n;
		}
	});
}

Functions.buckets = function(arr,n) {
	var max = Functions.max(arr),
		min = Functions.min(arr),
		range = max - min,
		width = range / n,
		buckets = [];
	for(var i=0;i<arr.length;i++) {
		var el = arr[i],
			index = Math.min(Math.floor((el - min) / width),n - 1);
		if(!buckets[index]) buckets[index] = [];
		buckets[index].push(el);
	}
	for(var i=0;i<buckets.length;i++) {
		if(!buckets[i]) {
			buckets[i] = [];
		}
	}
	return buckets;
}

Functions.histogram = function(arr,n) {
	return Functions.buckets(arr,n).map(function(bucket) {
		return bucket.length;
	});
}

Functions.oneVarStats = function(arr) {
	arr = Functions.numbers(arr);
	var res = {};
	res.numbers = arr;
	res.mean = Functions.mean(arr);
	res.sum = Functions.sum(arr);
	res.sumSquares = Functions.sum(arr.map(function(a) { return a * a; }));
	res.sampleStdev = Functions.stdev(arr,false);
	res.popStdev = Functions.stdev(arr,true);
	res.n = arr.length;
	res.min = Functions.min(arr);
	res.q1 = Functions.quartile(arr,1);
	res.median = Functions.median(arr);
	res.q3 = Functions.quartile(arr,3);
	res.max = Functions.max(arr);
	return res;
}

Functions.linearRegression = function(x,y) {
	var res = {};
	var xStats = Functions.oneVarStats(x);
	var yStats = Functions.oneVarStats(y);
	var sumXY = new Vector(x).dot(new Vector(y)).toFloat();
	res.r = sumXY / Math.sqrt(xStats.sumSquares * yStats.sumSquares);
	res.r2 = res.r * res.r;
	res.b = res.r * (yStats.sampleStdev / xStats.sampleStdev);
	res.a = yStats.mean - res.b * xStats.mean;
	return res;
}

Functions.points = function(l1,l2) {
	var res = [];
	for(var i=0;i<Math.max(l1.length,l2.length);i++) {
		res.push([
			l1[i],
			l2[i]
		]);
	}
	return res;
}

Functions.zTest = function(m,s,n,h,x) {
	var z = (x - m) / (s / Math.sqrt(n));
	var score = Functions.znormal(z);
	var p;
	if(h == 0) {
		p = 2 * (1 - score);
	}
	if(h == 1) {
		if(z > 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	if(h == -1) {
		if(z < 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	return {z: z, p: p};
}

Functions.twoSampleZTest = function(m1,m2,s1,s2,n1,n2,h) {
	var z = (m2 - m1) / Math.sqrt( Math.pow(s1,2) / n1 + Math.pow(s2,2) / n2 );
	var score = Functions.znormal(z);
	var p;
	if(h == 0) {
		p = 2 * (1 - score);
	}
	if(h == 1) {
		if(z > 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	if(h == -1) {
		if(z < 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	return {z: z, p: p};
}

Functions.onePropZTest = function(p0,x,n,h) {
	var pHat = x/n;
	var stdev = Math.sqrt(p0 * (1 - p0) / n);
	var z = (pHat - p0) / stdev;
	var score = Functions.znormal(z);
	var p;
	if(h == 0) {
		p = 2 * (1 - score);
	}
	if(h == 1) {
		if(z > 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	if(h == -1) {
		if(z < 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	return {pHat: pHat, z: z, p: p};
}

Functions.twoPropZTest = function(x1,x2,n1,n2) {
	var pHat1 = x1/n1;
	var pHat2 = x2/n2;
	var pP = (x1 + x2) / (n1 + n2);
	var stdev = Math.sqrt(pP * (1 - pP) * ((1/n1) + (1/n2)));
	var z = Math.abs(pHat1 - pHat2) / stdev;
	if(isNaN(z)) {
		z = 0;
	}
	var score = Functions.znormal(z);
	var p = 1 - score;
	return {pHat1: pHat1, pHat2: pHat2, z: z, p: p};
}

Functions.tTest = function(m,s,n,h,x) {
	var t = (x - m) / (s / Math.sqrt(n));
	var score = Functions.tDistribution(t,n-1);
	var p;
	if(h == 0) {
		p = 2 * (1 - score);
	}
	if(h == 1) {
		if(t > 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	if(h == -1) {
		if(t < 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	return {t: -t, p: p, df: n-1};
}

Functions.twoSampleTTest = function(m1,m2,s1,s2,n1,n2,h) {
	var s1son = Math.pow(s1,2) / n1;
	var s2son = Math.pow(s2,2) / n2;
	var t = (m2 - m1) / Math.sqrt( s1son + s2son );
	var df = Math.pow(s1son + s2son,2) / (Math.pow(s1son,2)/(n1 - 1) + Math.pow(s2son,2)/(n2 - 1));
	var score = Functions.tDistribution(t,df);
	var p;
	if(h == 0) {
		p = 2 * (1 - score);
	}
	if(h == 1) {
		if(t > 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	if(h == -1) {
		if(t < 0) {
			p = 1 - score;
		} else {
			p = score;
		}
	}
	return {t: -t, p: p, df: df};
}

Functions.incompleteBeta = function(x,a,b) {
	var v = Functions.integral(0,x,function(t) {
		return Math.pow(t,a-1) * Math.pow(1-t,b-1);
	},1e4,true);
	return v;
}

Functions.normalizedIncompleteBeta = function(x,a,b) {
	return Functions.incompleteBeta(x,a,b) / Functions.incompleteBeta(1,a,b);
}

Functions.tDistribution = function(t,v) {
	if(v > 500) return Functions.znormal(t);
	var x = (t + Math.sqrt(Math.pow(t,2) + v)) / (2 * Math.sqrt(Math.pow(t,2) + v));
	return Functions.normalizedIncompleteBeta(x,v/2,v/2);
}

Functions.logGamma = function(x) {
	var tmp = (x - 0.5) * Math.log(x + 4.5) - (x + 4.5);
	var ser = 1.0 + 76.18009173 / (x + 0) - 86.50532033 / (x + 1) + 24.01409822 / (x + 2) - 1.231739516 / (x + 3) + 0.00120858003 / (x + 4) - 0.00000536382 / (x + 5);
	return tmp + Math.log(ser * Math.sqrt(2 * Math.PI));
}

Functions.gamma = function(x) { 
	return Functions.round(Math.exp(Functions.logGamma(x)),4);
}

Functions.chisquaredpdf = function(x,k) {
	if(x < 0) return 0;
	return (Math.pow(x,k/2 - 1) * Math.exp(-x/2)) / (Math.pow(2,k/2)*Functions.gamma(k/2));
}

Functions.chisquaredcdf = function(x,k) {
	return Functions.integral(0,x,function(t) {
		return Functions.chisquaredpdf(t,k);
	},1e5,false);
}

Functions.chiSquaredTest = function(o) {
	var colTotals = [];
	for(var i=0;i<o.numColumns();i++) {
		var col = o.col(i + 1);
		colTotals.push(Functions.sum(col));
	}
	colTotals = Functions.numbers(colTotals);

	var rowTotals = [];
	for(var i=0;i<o.numRows();i++) {
		var row = o.row(i + 1);
		rowTotals.push(Functions.sum(row));
	}
	rowTotals = Functions.numbers(rowTotals);
	var total = 0;
	o.map(function(i) {
		total += i.toFloat();
	});
	var e = new Matrix([[]]);
	for(var i=0;i<o.numRows();i++) {
		for(j=0;j<o.numColumns();j++) {
			var entry = rowTotals[i] * colTotals[j] / total;
			e.set(i+1,j+1,entry);
		}
	}
	e = e.copy();
	var x2 = 0;
	o.map(function(oi,r,c) {
		var ei = e.select(r,c);
		oi = oi.toFloat();
		ei = ei.toFloat();
		x2 += Math.pow(oi - ei,2) / ei;
	});
	var df = (o.numColumns() - 1) * (o.numRows() - 1);
	var p = 1 - Functions.chisquaredcdf(x2,df);
	return {x2: x2, df: df, p: p, expected: e};
}

Functions.chiSquaredGOFTest = function(e,o) {
	if(e instanceof Vector) e = e.args;
	if(o instanceof Vector) o = o.args;
	e = Functions.numbers(e);
	o = Functions.numbers(o);
	var len = Math.max(e.length,o.length),
		x2 = 0,
		p = 0,
		df = len - 1;
	for(var i=0;i<len;i++) {
		x2 += Math.pow(o[i] - e[i],2) / e[i];
	}
	p = 1 - Functions.chisquaredcdf(x2,df);
	return {x2: x2, df: df, p: p};
}

Functions.solveLinearSystem = function(m) {
	var r = m.rref();
	if(r.deaugment().equals(Functions.identityMatrix(m._rows))) {
		return r.col(r._columns);
	} else {
		return [];
	}
}

