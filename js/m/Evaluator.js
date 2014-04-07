function Frame(src,parent) {
	this.src = src || {};
	this.parent = parent;
}

Frame.prototype.lookup = function(symbol) {
	var res = this.src[symbol.name || symbol];
	if(!isNaN(res)) res = new Value(res);
	if(res === undefined) {
		if(this.parent) {
			res = this.parent.lookup(symbol);
		}
	}
	return res;
}

Frame.prototype.set = function(k,v) {
	this.src[k] = v;
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
		p = 5;
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

Value.prototype.text = Value.prototype.toString;

Value.prototype.toFloat = function() {
	return this.real;
}

Value.prototype.decimalize = Value.prototype.toFloat;

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

Value.prototype.serialize = function() {
	return {
		type: 'Value',
		real: this.real,
		complex: this.complex
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
	if(other instanceof Vector || other instanceof Matrix) {
		return other.add(this);
	}
	if(other instanceof Frac) {
		return new Frac(
			this,
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
	if(other instanceof Vector) {
		return other.mult(this);
	}
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
	this.args = (args || []).map(function(i) {
		if(i instanceof Factor) {
			return i;
		} else {
			return new Factor(i);
		}
	});
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
	newArgs = newArgs.filter(function(n) {
		return !n.val.NO_MATCH;
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
		if(a.val instanceof Matrix || b.val instanceof Matrix) {
			if(a.val instanceof Matrix && b.val instanceof Matrix) {
				return a.val.mult(b.val);
			} else {
				var s, m;
				if(a.val instanceof Matrix) {
					m = a.val;
					s = b.val;
				} else {
					m = b.val;
					s = a.val;
				}
				var r =  m.mult(s);
				return r;
			}
		}
		if(a.val instanceof Vector || b.val instanceof Vector) {
			if(a.val instanceof Vector && b.val instanceof Vector) {
				var op = b.productType;
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
		return this.val.valueOf(frame);
	}
}

function Frac(top,bottom) {
	this.top = top;
	this.bottom = bottom;
}

Frac.grapherMode = false;

Frac.prototype.valueOf = function(frame) {

	if(Frac.grapherMode) {
		return this.grapherEval(frame);
	}

	var top = new Value(this.top.valueOf(frame));
	var bottom = new Value(this.bottom.valueOf(frame));

	if(bottom instanceof Vector) {
		throw "Invalid denominator";
	}
	if(top instanceof Vector || top instanceof Matrix) {
		return top.mult(bottom.inverse());
	}
	if(bottom instanceof Matrix) {
		return bottom.inverse().mult(top);
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

Frac.prototype.grapherEval = function(frame) {
	var top = this.top.valueOf(frame);
	var bottom = this.bottom.valueOf(frame);
	top = top.toFloat();
	bottom = bottom.toFloat();
	if(bottom == 0) {
		throw "Division by 0";
	}
	return new Value(top / bottom);
}

Frac.prototype.add = function(other) {
	if(other instanceof Vector || other instanceof Matrix) {
		return other.add(this);
	}
	return new Frac(
		this.top.mult(other.bottom || new Value(1)).add(this.bottom.mult(other.top || other)),
		this.bottom.mult(other.bottom || new Value(1))
	);
}

Frac.prototype.mult = function(other) {
	other = other.valueOf();
	if(other instanceof Value || other instanceof Vector || other instanceof Matrix) {
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
	if(red.top.equals(0)) {
		return '0';
	}
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

Frac.prototype.tex = function() {
	return '\\frac{' + this.top.tex() + '}{ ' + this.bottom.tex() + '}';
}

Frac.prototype.toFloat = function() {
	return this.decimalize().toFloat();
}

Frac.prototype.serialize = function() {
	return {
		type: 'Frac',
		top: this.top.serialize(),
		bottom: this.bottom.serialize()
	};
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
	if(!isNaN(b)) b = new Value(b);
	if(!isNaN(p)) p = new Value(p);

	if(b instanceof Value) {
		if(!b.complex && !p.complex && (b.real > 0 || p.real >= 1)) {
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
	} else if(b instanceof Matrix) {
		if(p.complex || p.real != Math.round(p.real)) {
			throw 'Invalid power';
		}
		if(p == 0) {
			if(b.square()) {
				return Functions.identityMatrix(b.numRows());
			} else {
				throw 'Invalid power for non-square matrix';
			}
		}
		if(p < 0) {
			p = Math.abs(p);
			b = b.inverse();
		}
		for(var i=0;i<p-1;i++) {
			b = b.mult(b);
		}
		return b;
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
	var res = app.data.callFunction(this.name,evaled);
	if(!isNaN(res)) {
		res = new Value(res);
	}
	return res;
}

function Symbol(name) {
	if(name.charAt(0) == '\\') name = name.slice(1);
	this.name = name;
}

Symbol.prototype.valueOf = function(frame) {
	if(frame) {
		var res = frame.lookup(this) || app.data.lookup(this);
		return res;
	} else {
		return this;
	}
}

Symbol.prototype.toString = function(frame) {
	return this.name;
}

Symbol.prototype.text = Symbol.prototype.toString;

function Matrix(rows) {
	this.rows = rows.map(function(r) {
		return r.map(function(entry) {
			if(typeof entry == 'number') {
				return new Value(entry)
			} else {
				return entry;
			}
		});
	});
	this._rows = rows.length;
	this._columns = rows[0].length;
}

Matrix.prototype.map = function(lambda) {
	var r = 0,
		c = 0,
		self = this;
	return new Matrix(this.rows.map(function(row) {
		r++;
		c = 0;
		return row.map(function(el) {
			c++;
			return lambda(el,r,c,self);
		});
	}));
}

Matrix.prototype.dim = function() {
	return this.rows.length.toString() + 'x' + this.rows[0].length.toString();
}

Matrix.prototype.nRows = function() {
	return this.rows.length;
}

Matrix.prototype.nCols = function() {
	return this.rows[0].length;
}

Matrix.prototype.square = function() {
	return this.numRows() == this.numColumns();
}

Matrix.prototype.valueOf = function(frame) {
	var rows = this.rows;
	rows = rows.map(function(row) {
		return row.map(function(item) {
			return item.valueOf(frame);
		});
	});
	return new Matrix(rows);
}

Matrix.prototype.toString = function(frame,format) {
	return '[' + this.rows.map(function(row) {
		return row.map(function(el) {
			return el.valueOf(frame).toString();
		}).join(',')
	}).join(format? '&nbsp;|&nbsp;' : '|') + ']';
}

Matrix.prototype.toTable = function(frame,cl) {
	var h = '<table class="' + cl + '">';
	this.rows.forEach(function(r) {
		h += '<tr>';
		r.forEach(function(e) {
			h += '<td>' + e.toString() + '</td>';
		});
		h += '</tr>';
	});
	h += '</table>';
	return h;
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
	return this.rows[0] ? this.rows[0].length : 0;
}

Matrix.prototype.select = function(r,c) {
	return this.rows[r-1][c-1];
}

Matrix.prototype.set = function(r,c,v) {
	if(!this.rows[r-1]) this.rows[r-1] = [];
	this.rows[r-1][c-1] = !isNaN(v) ? new Value(v) : v;
}

Matrix.prototype.add = function(other) {
	if(other instanceof Frac || other instanceof Value) {
		return this.map(function(entry) {
			return entry.add(other);
		});
	}
	if(!(other instanceof Matrix)) {
		throw "Can't add these types";
	}
	if(this.dim() != other.dim()) {
		throw "Dimension error";
	}
	var rows = [];
	for(var i=0;i<this.rows.length;i++) {
		var row = [];
		for(var j=0;j<this.rows[0].length;j++) {
			row.push(this.rows[i][j].add(other.rows[i][j]));
		}
		rows.push(row);
	}
	return new Matrix(rows);
}

Matrix.prototype.mult = function(other) {
	var self = this;
	if(!(other instanceof Matrix)) {
		var q =  this.map(function(el) {
			return el.mult(other);
		});
		return q;
	} else {
		if(this.numColumns() == other.numRows()) {
			var resRows = this.numRows();
			var resCols = other.numColumns();
			var dim = this.numColumns();
			var ab = function(i,j) {
				var res = new Value(0);
				for(var k=1;k<=dim;k++) {
					var s = self.select(i,k).mult(other.select(k,j));
					res = res.add(s);
				}
				return res;
			}
			var res = [];
			for(var i=1;i<=resRows;i++) {
				var row = [];
				for(var j=1;j<=resCols;j++) {
					row.push(ab(i,j));
				}
				res.push(row);
			}
			return new Matrix(res);
		} else {	
			throw 'Dimension error';
		}
	}
}

Matrix.prototype.minor = function(r,c) {
	var src = [], matrix = this;
	for(var i = 1; i <= matrix.numRows(); i++) {
		if(i == r) continue;	
		var arrn = [];
		var row = matrix.row(i);
		for(var j = 1; j <= row.length; j++)
		{
			if(j != c) arrn.push(matrix.select(i,j));
		};
		src.push(arrn);
	};
	return new Matrix(src);
}

Matrix.prototype.det = function() {
	if(this.numRows() != this.numColumns()) {
		throw 'Invalid for non-square matrix';
	}
	var matrix = this;
	var select = function(row,col) {
		return matrix.select(row,col) || 0;
	};
	var selectAllBut = function(col) {
		return matrix.minor(1,col);
	};
	if(matrix.numRows() == 1) {
		return this.select(1,1);
	}
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

Matrix.prototype.rref = function(reduce) {
	if(reduce === null || reduce === undefined) reduce = true;
	var mx = this.copy();
    var lead = 0;
    for (var r = 0; r < mx._rows; r++) {
        if (mx._columns <= lead) {
            return mx;
        }
        var i = r;
        while (mx.rows[i][lead] == 0) {
            i++;
            if (mx._rows == i) {
                i = r;
                lead++;
                if (mx._columns == lead) {
                    return mx;
                }
            }
        }
 
        var tmp = mx.rows[i];
        mx.rows[i] = mx.rows[r];
        mx.rows[r] = tmp;
 
        var val = mx.rows[r][lead];
        for (var j = 0; j < mx._columns; j++) {
            mx.rows[r][j] = mx.rows[r][j].mult(new Value(1/val));
		};
		
		if(!reduce && r == mx._rows - 1) return mx;
 
        for (var i = 0; i < mx._rows; i++) {
            if (i == r) continue;
            val = mx.rows[i][lead];
            for (var j = 0; j < mx._columns; j++) {
                mx.rows[i][j] = mx.rows[i][j].add(
                	new Value(-val).mult(mx.rows[r][j])
                );
            }
        }
        lead++;
    }
    return mx;
}

Matrix.prototype.ref = function() {
	return this.rref(false);
}

Matrix.prototype.cofactor = function(row,col) {
	return new Value(Math.pow(-1,row+col)).mult(this.minor(row,col).det());
}

Matrix.prototype.adjoint = function() {
	var self = this;
	return this.map(function(el,row,col) {
		return self.cofactor(row,col);
	}).transpose();
}

Matrix.prototype.inverse = function() {
	var self = this,
		det = this.det(),
		adj = this.adjoint();
	if(det == 0) {
		throw 'Matrix has no inverse';
	}
	return adj.map(function(el) {
		return el.mult(new Frac(new Value(1),new Value(det)));
	});
}

Matrix.prototype.transpose = function() {
	var res = [];
	for(var i=1;i<=this.numColumns();i++) {
		var row = [];
		for(var j=1;j<=this.numRows();j++) {
			row.push(this.select(j,i));
		}
		res.push(row);
	}
	return new Matrix(res);
}

Matrix.prototype.serialize = function() {
	return this.toString(new Frame({}));
}

Matrix.prototype.copy = function() {
	return this.map(function(n) {
		return n;
	});
}

function Vector(args) {
	if(!isNaN(args[0])) {
		args = args.map(function(i) {
			return new Value(i);
		});
	}
	this.args = args || [];
}

Vector.prototype.valueOf = function(frame) {
	return new Vector(this.args.map(function(a) {
		return a.valueOf(frame);
	}));
}

Vector.prototype.copy = function() {
	return new Vector(this.args);
}

Vector.prototype.add = function(v2) {
	if(v2 instanceof Vector) {
		var res = [];
		for(var i=0;i<Math.max(this.args.length,v2.args.length);i++) {
			res.push((this.args[i] || new Value(0)).add(v2.args[i] || new Value(0)));
		}
		return new Vector(res);
	} else if(v2 instanceof Value || v2 instanceof Frac) {
		return this.map(function(item) {
			return item.add(v2);
		});
	}
	throw "Can't add these types"
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
	var total = new Value(0);
	for(var i=0;i<l1.length;i++) {
		total = total.add(l1[i].mult(l2[i] || new Value(0)));
	}
	return total;
}

Vector.prototype.toString = function() {
	return '{' + this.valueOf().args.join(', ') + '}';
}

Vector.prototype.toStoreString = function() {
	return '<' + this.valueOf().args.join(', ') + '>';
}

Vector.prototype.toStringPolar = function(rads) {
	var v = this.valueOf();
	if(v.args.length != 2) {
		throw 'Dimension error';
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

Vector.prototype.map = function(func) {
	return new Vector(this.args.map(func));
}

Vector.prototype.sort = function() {
	return new Vector(this.args.sort(function(a,b) { return a > b ? 1 : -1; }));
}

Vector.prototype.serialize = function() {
	return {
		type: 'Vector',
		args: this.args.map(function(arg) {
			return arg.serialize();
		})
	};
}

Vector.prototype.indexOf = function(item) {
	for(var i=0;i<this.args.length;i++) {
		if((item.equals && item.equals(this.args[i])) || item == this.args[i]) {
			return i;
		}
	}
	return -1;
}

Vector.prototype.append = function(item) {
	this.args.push(item);
}

function Derivative(e,wrt,at) {
	this.expression = e;
	this.wrt = wrt;
	this.x = at;
}

Derivative.prototype.at = function(x,wrt,frame) {
	x = x.valueOf(frame);
	if(x.toFloat) x = x.toFloat();
	wrt  = this.wrt || 'x'
	var f = new Frame({},frame);
	var dx = 0.0000001;
	f.set(wrt,x + dx);
	var y2 = this.expression.valueOf(f).toFloat();
	f.set(wrt,x);
	var y1 = this.expression.valueOf(f).toFloat();
	return new Value((y2-y1)/dx).round(3);
}

Derivative.prototype.valueOf = function(frame) {
	app.data.calcInCurrentExpression = true;
	app.data.realTrigMode = app.data.trigUseRadians;
	app.data.trigUseRadians = true;
	return this.at(this.x,this.wrt || 'x',frame);
}

function Integral(a,b,f,x) {
	this.lower = a;
	this.upper = b;
	this.integrand = f;
	this.wrt = x || 'x';
}

Integral.prototype.valueOf = function(frame,nSteps,round) {
	app.data.calcInCurrentExpression = true;
	app.data.realTrigMode = app.data.trigUseRadians;
	app.data.trigUseRadians = true;
	var	a = this.lower.valueOf(frame).toFloat(),
		b = this.upper.valueOf(frame).toFloat(),
		n = nSteps || 2000,
		dx = Math.abs((a - b) / n),
		f = new Frame({},frame),
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
		f.set(this.wrt,i);
		var r = this.integrand.valueOf(f).toFloat();
		heights.push(r);
	}
	sum = heights[0];
	for(var i = 1; i < n; i++) {
		sum += 2 * heights[i];
	}
	sum += heights[heights.length - 1];
	sum *= dx * 0.5;
	if(flip) sum *= -1;
	return new Value(sum).round(round || 1);
}

Integral.prototype.toString = function() {
	return 'int ' + this.lower.toString() + ', ' + this.upper.toString() + ': ' + this.integrand.toString() + ' d' + this.wrt;
}

function Sum(index,lower,upper,f) {
	this.index = index;
	this.lower = lower;
	this.upper = upper;
	this.f = f;
}

Sum.prototype.valueOf = function(frame) {
	var a = this.lower.valueOf(frame),
		b = this.upper.valueOf(frame),
		sum = new Value(0);
		fr = new Frame({},frame);
	if(a.toFloat() > b.toFloat()) {
		throw "Invalid bounds";
	}
	for(var i=a;i<=b;i++) {
		fr.set(this.index,i);
		sum = new Add([
			sum,
			this.f.valueOf(fr)
		]).valueOf(frame);
	}
	return sum;
}

function Product(index,lower,upper,f) {
	this.index = index;
	this.lower = lower;
	this.upper = upper;
	this.f = f;
}

Product.prototype.valueOf = function(frame) {
	var a = this.lower.valueOf(frame),
		b = this.upper.valueOf(frame),
		prod = new Value(1);
		fr = new Frame({},frame);
	if(a.toFloat() > b.toFloat()) {
		throw "Invalid bounds";
	}
	for(var i=a;i<=b;i++) {
		fr.set(this.index,i);
		prod = new Mult([
			prod,
			this.f.valueOf(fr)
		]).valueOf(frame);
	}
	return prod;
}