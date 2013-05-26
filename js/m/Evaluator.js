function Frame(src) {
	this.src = src || {};
}

Frame.prototype.lookup = function(symbol) {
	var res = this.src[symbol.name || symbol];
	if(!isNaN(res)) res = new Value(res);
	return res;
}

function Value(real,complex,unit) {
	if(real instanceof Value) {
		return new Value(real.real,real.complex,real.unit);
	}
	this.real = real.real || real || 0;
	this.complex = real.complex || complex || 0;
	this.unit = unit;
}

Value.prototype.equals = function(value) {
	if(value instanceof Value) {
		return (this.real == value.real) && (this.complex == value.complex);
	} else {
		return this.real === value && this.complex == 0;
	}
}

Value.prototype.isComplex = function() {
	if(this.complex == 0) {
		return false;
	} else {
		return true;
	}
}

Value.prototype.toString = function(p) {
	var s = "";
	if(this.real == 0 && this.complex == 0) {
		return '0';
	}
	if(this.real !== 0) {
		s += parseFloat(this.real.toPrecision(p));
	}
	if(this.complex !== 0) {
		if(this.complex > 0) {
			if(this.real !== 0) {
				s += '+';	
			}
		} else {
			s += '-';
		}
		if(Math.abs(this.complex) !== 1) {
			s += parseFloat(Math.abs(this.complex).toPrecision(p));
		}
		s += 'i';
	}
	return s;
}

Value.prototype.toFloat = function() {
	return this.real;
}

Value.prototype.round = function(p) {
	return new Value(
		Functions.round(this.real,p),
		Functions.round(this.complex,p)
	);
}

Value.prototype.toPrecision = Value.prototype.toString;

Value.prototype.toComplexTrigForm = function() {
	var modulus = Math.sqrt(
			Math.pow(this.real,2) +
			Math.pow(this.complex,2)
		);
	var argument = Math.atan2(this.complex,this.real);
	return {
		modulus: modulus,
		argument: argument
	};

}

Value.prototype.complexConjugate = function() {
	return new Value(
		this.real,
		-1 * this.complex
	);
}

Value.prototype.inverse = function() { 
	var invMe = new Frac(
		new Value(1),
		this
	),
	complex = new Frac(
		this.complexConjugate(),
		this.complexConjugate()
	)
	return invMe.mult(complex).reduce();
}	

Value.prototype.reduce = function() {
	return this;
}

Value.prototype.add = function(other) {
	if(!isNaN(other)) {
		other = new Value(other);
	}
	other = other.valueOf();
	if(other instanceof Frac) {
		return new Frac(
			this.mult(other.bottom),
			new Value(1)
		).add(other);
	} else if(other instanceof Value) {
		return new Value(
			this.real + other.real,
			this.complex + other.complex
		);
	} else {
		throw "Cannot add these types";
	}
}

Value.prototype.subtract = function(other) {
	if(!isNaN(other)) {
		other = new Value(other);
	}
	return this.add(other.mult(-1));
}

Value.prototype.mult = function(other) {
	if(!isNaN(other)) {
		other = new Value(other);
	}
	other = other.valueOf();
	if(other instanceof Frac) {
		return new Frac(
			this.mult(other.top),
			other.bottom
		)
	} else if(other instanceof Value) {
		return new Value(
			(this.real * other.real) - (this.complex * other.complex),
			(this.real * other.complex) + (this.complex * other.real)
		);	
	}
}

function Add(args) {
	this.args = args || [];
}

Add.prototype.valueOf = function(frame) {
	if(this.args.length == 0) return new Value(0);
	if(this.args.length == 1) return this.args[0].valueOf(frame);
	return this.args.reduce(function(a,b) {
		a = a.valueOf(frame);
		b = b.valueOf(frame);
		return a.add(b);
	}).valueOf(frame);
}

Add.prototype.flatten = function() {
	var args = this.args.concat(),
		newArgs = [];
	args.forEach(function(a) {
		var v = a.valueOf();
		if(v instanceof Add) {
			v = v.flatten();
			newArgs = newArgs.concat(v.args);
		} else {
			newArgs.push(v);
		}
	});
	return new Add(newArgs);
}

Add.prototype.mult = function(val) {
	return new Add(this.args.map(function(arg) {
		return arg.valueOf().mult(val);
	}));
}

Add.prototype.toString = function() {
	return '(' + this.args.map(function(arg) {
		return arg.valueOf().toString();
	}).join(' + ') + ')';
}

function Addend(val,neg) {
	this.val = val;
	this.neg = neg || false;
}

Addend.prototype.valueOf = function(frame) {
	return new Mult([
		this.neg? new Value(-1) : new Value(1),
		this.val	
	]).valueOf(frame);
}

function Mult(args) {
	this.args = args || [];
}

Mult.prototype.flatten = function(frame) {
	var args = this.args.concat(),
		newArgs = [];
	args.forEach(function(a) {
		var prodType = a.productType;
		var v = a.valueOf(frame);
		if(v instanceof Mult) {
			newArgs = newArgs.concat(v.args);
		} else {
			newArgs.push(new Factor(v,false,a.productType));
		}
	});
	return new Mult(newArgs);
}
			

Mult.prototype.toString = function() {
	return '(' + this.args.map(function(arg) {
		return arg.valueOf().toString();
	}).join(' * ') + ')';
}
		

Mult.prototype.valueOf = function(frame) {
	if(this.args.length == 0) return new Value(0);
	if(this.args.length == 1) return this.args[0].valueOf(frame);
	return this.flatten(frame).args.reduce(function(a,b) {
		a.val = a.valueOf(frame);
		b.val = b.valueOf(frame);
		if(a.val instanceof Vector || b.val instanceof Vector) {
			if(a.val instanceof Vector && b.val instanceof Vector) {
				var op = b.productType;
				//console.log(a,b);
				if(op == 'cross') {
					return a.val.cross(b.val);
				} else if(op == 'dot') {
					return a.val.dot(b.val);
				}
			} else {
				var s, v;
				if(a.val instanceof Vector) {
					v = a.val;
					s = b.val;
				} else {
					v = b.val;
					s = a.val;
				}
				return v.mult(s);
			}
		} else {
			a = a.val.valueOf(frame);
			b = b.val.valueOf(frame);
			return a.mult(b);
		}
	}).valueOf(frame);
}

function Factor(val,inv,productType) {
	this.val = val;
	this.inv = inv || false;
	this.productType = productType;
}

Factor.prototype.valueOf = function(frame) {
	if(this.inv) {
		return this.val.valueOf(frame).inverse();
	} else {
		//console.log(this.val,this.val.valueOf());
		return this.val.valueOf(frame);
	}
}

function Frac(top,bottom) {
	this.top = top;
	this.bottom = bottom;
}

Frac.prototype.valueOf = function(frame) {

	var top = this.top.valueOf(frame);
	var bottom = this.bottom.valueOf(frame);

	if(bottom instanceof Vector) {
		throw "Vectors cannot be denominators";
	}
	if(top instanceof Vector) {
		return top.mult(bottom.inverse());
	}
	if(top instanceof Frac || bottom instanceof Frac) {
		return top.mult(bottom.valueOf(frame).inverse()).valueOf(frame);
	}
	var scaleFactor = Functions.scaleToWhole(
		top.real,
		top.complex,
		bottom.real,
		bottom.complex
	);
	if(scaleFactor > 1e5) {
		// Panic, one or more of these numbers is huge. Decimalize.
		return this.decimalize(frame);
	}
	top = new Value(
		top.real * scaleFactor,
		top.complex * scaleFactor
	);
	bottom = new Value(
		bottom.real * scaleFactor,
		bottom.complex * scaleFactor
	);
	var gcfTop = Functions.gcf(
		top.real,
		top.complex
	);
	var gcfBottom = Functions.gcf(
		bottom.real,
		bottom.complex
	);
	var remainderTop = new Value(
		top.real / gcfTop,
		top.complex / gcfTop
	);
	var remainderBottom = new Value(
		bottom.real / gcfBottom,
		bottom.complex / gcfBottom
	);
	var intr;
	if(remainderTop.equals(remainderBottom)) {
		intr = new Frac(
			new Value(gcfTop),
			new Value(gcfBottom)	
		);
	} else {
		intr = new Frac(
			new Value(top),
			new Value(bottom)
		);
	}
	
	var totalGCF = Functions.gcf(gcfTop,gcfBottom);
	var newTop = new Value(
		intr.top.real / totalGCF,
		intr.top.complex / totalGCF
	);
	var newBottom = new Value(
		intr.bottom.real / totalGCF,
		intr.bottom.complex / totalGCF
	);

	if(newBottom.real <= 0 && newBottom.complex <= 0) {
		newTop.real *= -1;
		newBottom.real *= -1;
		newTop.complex *= -1;
		newBottom.complex *= -1;
	}

	if(newBottom.equals(0)) {
		throw 'Division by 0';
	}
	
	return new Frac(
		newTop,
		newBottom
	);
}

Frac.prototype.add = function(other) {
	//console.log(this,other);
	return new Frac(
		this.top.mult(other.bottom || new Value(1)).add(this.bottom.mult(other.top || other)),
		this.bottom.mult(other.bottom || new Value(1))
	);
}

Frac.prototype.mult = function(other) {
	other = other.valueOf();
	if(other instanceof Value) {
		// Value::mult has the means to multiply a value by a fraction
		return other.mult(this);
	} else if(other instanceof Frac) {
		return new Frac(
			this.top.mult(other.top),
			this.bottom.mult(other.bottom)
		)
	}
}

Frac.prototype.inverse = function() {
	return new Frac(
		this.bottom,
		this.top
	);
}

Frac.prototype.reduce = function() {
	return this;
}
 
Frac.prototype.decimalize = function(frame) {
	var t = this.top.valueOf(frame);
	var b = this.bottom.valueOf(frame);
	var c = b.complexConjugate();
	var divisor = b.mult(c);
	var dividend = t.mult(c);
	return new Value(
		dividend.real / divisor,
		dividend.complex / divisor
	);
}

Frac.prototype.toString = function() {
	var red = this;
	if(red.bottom) {
		if(red.bottom.equals(1)) {
			return red.top.toString();
		} else {
			return red.top.toString() + '/' + red.bottom.toString();
		}
	} else {
		return red.toString();
	}
}

Frac.prototype.toFloat = function() {
	return this.decimalize().toFloat();
}

function Pow(base,power) {
	this.base = base;
	this.power = power;
}

Pow.prototype.valueOf = function(frame) {
	var b = this.base.valueOf(frame);
	var p = this.power.valueOf(frame) || new Value(0);
	if(p instanceof Frac) {
		p = p.decimalize();
	}
	if(b instanceof Value) {
		if(!b.complex && !p.complex) {
			return new Value(Math.pow(b.real,p.real));
		} else {
			var c = Functions.complexRaise(b,p);
			return c;
		}
	} else if(b instanceof Frac) {
		return new Frac(
			new Pow(b.top,p).valueOf(frame),
			new Pow(b.bottom,p).valueOf(frame)
		);
	}
}

function Group(arg) {
	this.arg = arg;
}

Group.prototype.valueOf = function(frame) {
	return this.arg.valueOf(frame);
}		

function Func(name,args) {
	this.name = name;
	this.args = args;
}

Func.prototype.valueOf = function(frame) {
	var evaled = this.args.map(function(arg) {
		return arg.valueOf(frame);
	});
	return app.storage.callFunction(this.name,evaled);
}

function Symbol(name) {
	this.name = name;
}

Symbol.prototype.valueOf = function(frame) {
	if(frame) {
		var res = frame.lookup(this) || app.storage.lookup(this);
		return res;
	} else {
		return this;
	}
}

Symbol.prototype.toString = function(frame) {
	return this.name;
}

function Matrix(rows) {
	this.rows = rows.map(function(row) {
		return row.map(function(el) {
			return new Value(el);
		});
	});
}

Matrix.prototype.toString = function() {
	return '[' + this.rows.map(function(row) {
		return row.map(function(el) {
			return el.toString();
		}).join(',')
	}).join('|') + ']';
}

Matrix.prototype.row = function(n) {
	return this.rows[n-1];
}

Matrix.prototype.col = function(n) {
	return this.rows.map(function(row) {
		return row[n-1];
	});
}

Matrix.prototype.numRows = function() {
	return this.rows.length;
}

Matrix.prototype.numColumns = function() {
	return this.rows[0].length;
}

Matrix.prototype.select = function(r,c) {
	return this.rows[r-1][c-1];
}

Matrix.prototype.minor = function(row,col) {
	var src = [], matrix = this;
	for(var i = 1; i < matrix.numRows() + 1; i++) {
		if(i == row) continue;			
		var arrn = [];
		var row = matrix.row(i);
		for(var j = 1; j < row.length + 1; j++)
		{
			if(j != col) arrn.push(matrix.select(i,j));
		};
		src.push(arrn);
	};
	return new Matrix(src);
}

Matrix.prototype.det = function() {
	var matrix = this;
	var select = function(row,col) {
		return matrix.select(row,col) || 0;
	};
	var selectAllBut = function(col) {
		return matrix.minor(1,col);
	};
	if(matrix.numRows() == 2 && matrix.numColumns() == 2)
	{
		return select(2,2).mult(select(1,1)).add(
			select(2,1).mult(select(1,2)).mult(new Value(-1))
		);
	} else {
		var sum = new Value(0);
		for(var i = 0; i < matrix.numColumns(); i++)
		{
			var minor = selectAllBut(i + 1);
			var coef = select(1,i + 1) || 0;
			var sign = (i % 2 == 0)? 1 : -1;
			sum = sum.add(
				minor.det().mult(new Value(sign)).mult(new Value(coef))
			);
		}
		return sum;
	};
}

function Vector(args) {
	this.args = args;
}

Vector.prototype.valueOf = function(frame) {
	return new Vector(this.args.map(function(a) {
		return a.valueOf(frame);
	}));
}

Vector.prototype.add = function(v2) {
	var res = [];
	for(var i=0;i<Math.max(this.args.length,v2.args.length);i++) {
		res.push((this.args[i] || 0).add(v2.args[i] || 0));
	}
	return new Vector(res);
}

Vector.prototype.mult = function(s) {
	return new Vector(this.args.map(function(arg){
		return arg.mult(s);
	}));
}

Vector.prototype.cross = function(v2) {
	var l1 = this.args,
		l2 = v2.args,
		ma = new Matrix([
			[0,0,0],
			l1,
			l2
		]);
	if(l1.length != l2.length) {
		throw "Dimension error";
	}
	return new Vector([
		ma.minor(1,1).det(),
		ma.minor(1,2).det(),
		ma.minor(1,3).det()
	]);
};

Vector.prototype.dot = function(v2) {
	var l1 = this.args,
		l2 = v2.args;
	var total = 0;
	for(var i=0;i<l1.length;i++) {
		total += l1[i] * (l2[i] || 0);
	}
	return total;
}

Vector.prototype.toString = function() {
	return '<' + this.valueOf().args.join(',') + '>';
}

Vector.prototype.toStringPolar = function(rads) {
	var v = this.valueOf();
	if(v.args.length != 2) {
		throw "Cannot express this vector as polar"
	}
	if(v.args[0] instanceof Frac) v.args[0] = v.args[0].decimalize();
	if(v.args[1] instanceof Frac) v.args[1] = v.args[1].decimalize();
	var angle = new Value(Math.atan2(v.args[1],v.args[0]));
	var magnitude = new Value(Math.sqrt(Math.pow(v.args[0],2) + Math.pow(v.args[1],2)));
	if(!rads) {
		angle = new Value(angle * 180 / Math.PI);
	}
	angle = Functions.normalize(angle,rads);
	return magnitude.toString(3) + '\u2220' + angle.toString(3) + (rads? '' : '\u00B0');
}

function Derivative(e) {
	this.expression = e;
}

Derivative.prototype.at = function(x) {
	var dx = 0.00000001;
	var y2 = this.expression.valueOf(new Frame({
		x: x + dx
	}));
	var y1 = this.expression.valueOf(new Frame({
		x: x
	}));
	return new Frac(
		y2.subtract(y1),
		dx
	).decimalize().round(4);
}
