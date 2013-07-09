function Storage() {
	// this.init();
}

Storage.prototype.toSerialize = [
	'trigUseRadians',
	'displayPolarVectors',
	'displayDecimalizedFractions',
	'currentInput',
];

Storage.prototype.init = function() {
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
		'k_{E}': new Value(8.85418782e-12), // Electric constant
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
		'sin': this.wrap(Math.sin,true),
		'cos': this.wrap(Math.cos,true),
		'tan': this.wrap(Math.tan,true),
		'ln': this.wrap(Math.log,false),
		'log': this.wrap(function(n) {
			return Functions.round(Math.log(n) / Math.LN10,10);
		},false)
	}

	this.deserialize();
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
	this.hasDeserialized = true;
}

Storage.prototype.serialize = function() {
	if(!this.hasDeserialized) return;
	var s = {},
		self = this;
	this.toSerialize.forEach(function(item) {
		s[item] = self[item];
	});
	s.variables = this.serializeVariables(this.variables);
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

Storage.prototype.startSyncing = function() {
	var self = this;
	setTimeout(function() {
		setInterval(function() {
			self.uiSync();
		},500);
	},0);
}

Storage.prototype.lookup = function(symbol) {
	symbol = symbol.name || symbol;
	return this.constants[symbol] || this.variables[symbol] || new Value(0);
}

Storage.prototype.initVariableSave = function() {
	this.varSaveMode = true;
}

Storage.prototype.cancelVariableSave = function() {
	this.varSaveMode = false;
}

Storage.prototype.setVariable = function(k,v) {
	this.variables[k] = v;
	this.serialize();
}

Storage.prototype.wrap = function(lambda,isTrig,useNumber) {
	var self = this;
	if(useNumber === undefined || useNumber === null) useNumber = true;
	return function() {
		var args = app.utils.argArr(arguments);
		if(useNumber) {
			args = args.map(function(i) {
				if(i instanceof Frac) i = i.decimalize();
				return i.real;
			});
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
		return new Value(res);
	};
}

Storage.prototype.callFunction = function(name,args) {
 	var func = this.functions[name];
 	if(!func) {
 		throw 'No function called ' + name;
 	}
 	return func.apply(null,args);
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