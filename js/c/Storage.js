function Storage() {
	// this.init();
}

Storage.prototype.toSerialize = [
	'mode',
	'trigUseRadians',
	'displayPolarVectors',
	'displayDecimalizedFractions',
	'inputHistory',
	'currentInput',
	'grapherEquations',
	'grapherWindow',
];

Storage.prototype.init = function() {
	var self = this;
	this.hasDeserialized = false;
	this.lsNamespace = 'sigmabox';
	this.trigUseRadians = false;
	this.displayPolarVectors = false;
	this.displayDecimalizedFractions = false;

	this.constants = {
		'i': new Value(0,1),
		'\\pi': new Value(Math.PI),
		'e': new Value(Math.E),
		'\\phi': new Value(1.6180339887), // Golden ratio
		'\\varepsilon_{0}': new Value(8.854187817e-12), // Permittivity of free space
		'\\mu_{0}': new Value(1.256637061e-6), // Permeability of free space
		'g': new Value(9.80665), // Standard gravity
		'G': new Value(6.67384e-11), // Gravitation constant
		'c_{light}': new Value(299792458), // Speed of light
		'k_{E}': new Value(8.98755179e9), // Electric constant
		'\\alpha_{B}': new Value(5.2917721092e-11), // Bohr radius
		'Z_{0}': new Value(376.730313461), // Characteristic impedance of vacuum
		'm_{p}': new Value(1.67262178e-27), // Mass of proton
		'm_{n}': new Value(1.67492735e-27), // Mass of neutron
		'm_{e}': new Value(9.10938291e-31), // Mass of electron
		'q_{e}': new Value(1.60217657e-19), // Charge of electron
		'\\hbar': new Value(1.054571726e-34), // Reduced Planck constant
		'\\mu_{N}': new Value(5.05078353e-27), // Nuclear magneton
		'\\mu_{B}': new Value(9.27400968e-24), // Bohr magneton
		'G_{F}': new Value(1.166364e-5), // Fermi coupling constant
		'\\alpha_{fs}': new Value(7.2973525698e-3), // Fine-structure constant
		'G_{0}': new Value(7.7480917346e-5), // Conductance quantum
		'n_{A}': new Value(6.02214129e+23), // Avogadro's number
		'm_{u}': new Value(1.660538921e-27), // Atomic mass constant
		'k_{B}': new Value(1.3806488e-23), // Boltzmann constant
		'R_{gas}': new Value(8.3144621), // Gas constant
		'\\sigma_{sb}': new Value(5.670373e-8) // Stefan-Boltzmann constant
	}

	this.variables = {

	};
	
	this.functions = {
		'abs': this.wrap(Math.abs),
		'mod': this.wrap(Functions.mod),
		'fact': this.wrap(Functions.factorial),
		'nCr': this.wrap(Functions.nCr),
		'nPr': this.wrap(Functions.nPr),
		'sin': this.wrap(Math.sin,true),
		'cos': this.wrap(Math.cos,true),
		'tan': this.wrap(Math.tan,true),
		'csc': this.wrap(Functions.csc,true),
		'sec': this.wrap(Functions.sec,true),
		'cot': this.wrap(Functions.cot,true),
		'asin': this.wrap(function(n) {
			self.trigInCurrentExpression = true;
			n = Math.asin(n);
			if(!self.trigUseRadians) {
				n = Functions.r2d(n);
			}
			return n;
		},false),
		'acos': this.wrap(function(n) {
			self.trigInCurrentExpression = true;
			n = Math.acos(n);
			if(!self.trigUseRadians) {
				n = Functions.r2d(n);
			}
			return n;
		},false),
		'atan': this.wrap(function(n) {
			self.trigInCurrentExpression = true;
			n = Math.atan(n);
			if(!self.trigUseRadians) {
				n = Functions.r2d(n);
			}
			return n;
		},false),
		'acsc': this.wrap(function(n) {
			self.trigInCurrentExpression = true;
			n = Functions.acsc(n);
			if(!self.trigUseRadians) {
				n = Functions.r2d(n);
			}
			return n;
		},false),
		'asec': this.wrap(function(n) {
			self.trigInCurrentExpression = true;
			n = Functions.asec(n);
			if(!self.trigUseRadians) {
				n = Functions.r2d(n);
			}
			return n;
		},false),
		'acot': this.wrap(function(n) {
			self.trigInCurrentExpression = true;
			n = Functions.acot(n);
			if(!self.trigUseRadians) {
				n = Functions.r2d(n);
			}
			return n;
		},false),
		'sinh': this.wrap(Functions.sinh),
		'cosh': this.wrap(Functions.cosh),
		'tanh': this.wrap(Functions.tanh),
		'csch': this.wrap(Functions.csch),
		'sech': this.wrap(Functions.sech),
		'coth': this.wrap(Functions.coth),
		'asinh': this.wrap(Functions.asinh),
		'acosh': this.wrap(Functions.acosh),
		'atanh': this.wrap(Functions.atanh),
		'acsch': this.wrap(Functions.acsch),
		'asech': this.wrap(Functions.asech),
		'acoth': this.wrap(Functions.acoth),
		'ln': this.wrap(function(n) {
			if(n <= 0) throw "Domain error (ln)";
			return Math.log(n);
		}
		,false),
		'log': this.wrap(function(n) {
			if(n <= 0) throw "Domain error (log)";
			return Functions.round(Math.log(n) / Math.LN10,10);
		},false),
		'id': this.wrap(Functions.identityMatrix,false,true,false),
		'det': this.wrap(function(m) {
			Functions.expect(m,Matrix);
			return m.det();
		},false,false),
		'transpose': this.wrap(function(m) {
			Functions.expect(m,Matrix);
			return m.transpose();
		},false,false,false),
		'inverse': this.wrap(function(m) {
			Functions.expect(m,Matrix);
			return m.inverse();
		},false,false,false),
		// Vector functions
		'min': this.wrap(function(v) {
			console.log(v);
			Functions.expect(v,Vector);
			var min = Infinity;
			for(var i=0;i<v.args.length;i++) {
				if(v.args[i] < min) {
					min = v.args[i];
				}
			}
			return min;
		}),
		'max': this.wrap(function(v) {
			Functions.expect(v,Vector);
			var max = -Infinity;
			for(var i=0;i<v.args.length;i++) {
				if(v.args[i] > max) {
					max = v.args[i];
				}
			}
			return max;
		}),
		'range': this.wrap(function(min,max,step) {
			if(!step) step = 1;
			var res = [];
			for(var i=min;i<=max;i+=step) {
				res.push(i);
			}
			return new Vector(res);
		}),
		'lsum': this.wrap(function(v) {
			Functions.expect(v,Vector);
			return v.args.reduce(function(a,b) {
				return (a.add) ? a.add(b) : a + b;
			});
		},false,false),
		'lprod': this.wrap(function(v) {
			Functions.expect(v,Vector);
			return v.args.reduce(function(a,b) {
				return (a.mult) ? a.mult(b) : a * b;
			});
		},false,false),
		'csum': this.wrap(function(v) {
			Functions.expect(v,Vector);
			var sum = 0;
			var arr = [];
			for(var i=0; i<v.args.length; i++) {
				sum += v.args[i];
				arr.push(sum);
			}
			return new Vector(arr);
		}),
		'dlist': this.wrap(function(v) {
			Functions.expect(v,Vector);
			var arr = [],
				list = v.args;
			for(var i = 1; i < list.length; i++) {
				arr.push(list[i] - list[i - 1]);
			}
			return arr;
		}),
		'sort': this.wrap(function(v) {
			Functions.expect(v,Vector);
			return v.args.sort();
		}),
		// Numerical stuff
		'lcm': this.wrap(function(a,b) {
			var gcd_rec = function(a, b) {
			    if (b) {
			        return gcd_rec(b, a % b);
			    } else {
			        return Math.abs(a);
			    }
			};
			return Math.floor((a * b) / gcd_rec(a,b));
		}),
		'gcd': this.wrap(function(a,b) {
			var gcd_rec = function(a, b) {
			    if (b) {
			        return gcd_rec(b, a % b);
			    } else {
			        return Math.abs(a);
			    }
			};
			return gcd_rec(a,b);
		}),
		'round': this.wrap(Math.round),
		'isprime': this.wrap(Functions.isPrime),
		'prime': this.wrap(Functions.nthPrime),
		// Probability shit
		'normalpdf': this.wrap(Functions.normalpdf),
		'normalcdf': this.wrap(Functions.normalcdf),
		'stdnormalpdf': this.wrap(Functions.stdnormalpdf),
		'stdnormalcdf': this.wrap(Functions.stdnormalcdf),
		'znormal': this.wrap(Functions.znormal),
		'binompdf': this.wrap(Functions.binompdf),
		'binomcdf': this.wrap(Functions.binomcdf),
		'geompdf': this.wrap(Functions.geompdf),
		'geomcdf': this.wrap(Functions.geomcdf),
		'poissonpdf': this.wrap(Functions.poissonpdf),
		'poissoncdf': this.wrap(Functions.poissoncdf),
		// Stats stuff
		'mean': this.wrap(Functions.mean),
		'median': this.wrap(Functions.median),
		'mode': this.wrap(Functions.mode),
		'stdev': this.wrap(Functions.stdev),
		'rand': this.wrap(Math.random)
	}

	for(var k in this.functions) {
		this.registerFunction(k);
	}

	this.customFunctions = {

	};

	this.deserialize();
}

Storage.prototype.trigForceRadians = function(f) {
	var tt = this.trigUseRadians;
	this.trigUseRadians = true;
	f();
	this.trigUseRadians = false;
}

Storage.prototype.wrap = function(lambda,isTrig,useNumber,useNumberOut) {
	var self = this;
	if(useNumber === undefined || useNumber === null) useNumber = true;
	if(useNumberOut === undefined || useNumberOut === null) useNumberOut = true;
	return function() {
		var args = utils.argArr(arguments);
		var toNum = function(i) {
			if(i instanceof Frac) return i.decimalize();
			if(i instanceof Value) return i.real;
			if(i instanceof Vector || i instanceof Matrix) return i.map(toNum);
			return i;
		};
		var toVal = function(i) {
			if(!isNaN(i)) return new Value(i);
			if(i instanceof Vector || i instanceof Matrix) return i.map(toVal);
			return i;
		};
		if(useNumber) {
			args = args.map(toNum);
		}
		if(isTrig) {
			self.trigInCurrentExpression = true;
		}
		if(isTrig && !app.storage.trigUseRadians) {
			 // Convert given degrees to required radians
			args = args.map(Functions.d2r);
		}
		var res = lambda.apply(null,args);
		if(isTrig) {
		 	res = Functions.round(res,15);
		}
		if(!useNumberOut) {
			return toNumVal(res);
		} else {
			return res;
		}
	};
}

Storage.prototype.deserialize = function() {
	var s = JSON.parse(window.localStorage[this.lsNamespace] || '{}'),
		self = this;
	this.toSerialize.forEach(function(item) {
		if(s[item] !== undefined) {
			self[item] = s[item];
		}
	});
	this.variables = this.deserializeVariables(s.variables || {});
	this.customFunctions = this.deserializeFunctions(s.functions || {});
	this.inputHistory = this.inputHistory || [];
	this.hasDeserialized = true;
}

Storage.prototype.serialize = function() {
	if(!this.hasDeserialized) return;
	var s = {},
		self = this;
	this.toSerialize.forEach(function(item) {
		s[item] = self[item] instanceof Function ? self[item].call() : self[item];
	});
	s.variables = this.serializeVariables(this.variables);
	s.functions = this.serializeFunctions(this.customFunctions);
	window.localStorage[this.lsNamespace] = JSON.stringify(s);
}

Storage.prototype.serializeVariables = function(obj) {
	var res = {};
	for(var k in obj) {
		res[k] = obj[k].toString();
	}
	return res;
}

Storage.prototype.deserializeVariables = function(obj) {
	var p = new Parser(),
		res = {};
	for(var k in obj) {
		res[k] = p.parse(obj[k]).valueOf(new Frame({}));
	}
	return res;
}

Storage.prototype.lookup = function(symbol) {
	symbol = symbol.name || symbol;
	return this.constants[symbol] || this.variables[symbol] || new Value(0);
}

Storage.prototype.initVariableSave = function(m) {
	this.varSaveMode = m || 'store';
}

Storage.prototype.cancelVariableSave = function() {
	this.varSaveMode = false;
}

Storage.prototype.setVariable = function(k,v,silent) {
	this.variables[k] = v;
	if(!silent) app.popNotification(
		'Set ' + k + ' to ' + v.toString()
	);
	this.serialize();
}

Storage.prototype.isFunctionNameAvailable = function(name) {
	if(window.LatexCmds[name]) {
		return false;
	} else {
		return true;
	}
}

Storage.prototype.registerFunction = function(name) {
	window.LatexCmds[name] = window.NonItalicizedFunction;
}

Storage.prototype.unregisterFunction = function(name) {
	delete window.LatexCmds[name];
	delete this.customFunctions[name];
}

Storage.prototype.updateFunction = function(name,parameters,body) {
	var p = new Parser();
	this.customFunctions[name] = {
		name: name,
		parameters: parameters,
		body: body,
		expression: p.parse(body)
	};
	this.serialize();
}

Storage.prototype.serializeFunctions = function(f) {
	f = f || this.customFunctions;
	var res = {};
	for(var k in f) {
		res[f[k].name] = {
			name:  f[k].name,
			parameters: f[k].parameters,
			body: f[k].body
		};
	}
	return res;
}

Storage.prototype.deserializeFunctions = function(f) {
	for(var k in f) {
		this.registerFunction(f[k].name);
		this.updateFunction(f[k].name,f[k].parameters,f[k].body);
	}
	return this.customFunctions;
}

Storage.prototype.callFunction = function(name,args) {
 	var func = this.functions[name];
 	if(func) {
 		return func.apply(null,args);
 	}
 	func = this.customFunctions[name];
 	if(func) {
 		var frameArgs = {};
 		for(var i=0;i<func.parameters.length;i++) {
 			frameArgs[func.parameters[i]] = args[i];
 		}
 		return func.expression.valueOf(new Frame(frameArgs));
 	}
 	throw 'No function called ' + name;
 }

 Storage.prototype.uiSyncSubscribe = function(el) {
 	$(el).addClass('sync-subscriber');
 }

 Storage.prototype.uiSyncReady = function() {
 	$('.sync-subscriber').trigger('syncReady');
	this.startSyncing();
 }

 Storage.prototype.uiSync = function() {
 	$('.sync-subscriber').trigger('sync');
 }

 Storage.prototype.startSyncing = function() {
	var self = this;
	return;
	setTimeout(function() {
		setInterval(function() {
			self.uiSync();
		},500);
	},0);
}

Storage.prototype.clearHistory = function() {
	this.inputHistory = [];
}

Storage.prototype.addHistoryItem = function(text) {
	if(StringUtil.trim(text).length == 0 || /^[0-9.]+$/.test(text) || text == this.inputHistory.slice(-1).pop()) return;
	this.inputHistory.push(text);
	this.inputHistory = this.inputHistory.slice(-50);
}