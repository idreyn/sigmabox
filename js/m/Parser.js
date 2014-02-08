/*

I am so, so sorry.

*/

function Parser() {

}

Parser.NO_MATCH = {NO_MATCH:true};

Parser.tokens = {
	PLUS: '+',
	MINUS: '-',
	TIMES: '\\times',
	DOT: '\\cdot',
	DIV: '/',
	POW: '^'
};

Parser.prototype.parse = function(s,topLevel) {
	// Spaces have meaning in LaTeX, apparently.
	// When you input (PI) then (E), LaTeX produces \pi e (with space) to demarcate the difference.
	// We can leverage this by just replacing all spaces with multiplication signs.
	// Eat it, LaTeX.
	s = ParseUtil.replace(s,' ','\\times');
	// Two dots don't have any semantic meaning but they do cause all manner of infinite recursions
	s = ParseUtil.replace(s,'..','.');
	/* s = s.replace(/\[/,'(');
	s = s.replace(/\]/,')'); */
	// The LaTeX forms \left( and  \right) represent parentheses. We just want normal parentheses, though.
	s = s.split('\\left(').join('(');
	s = s.split('\\right)').join(')');
	// Square brackets denote a matrix of arbitrary dimension
	s = s.split('\\left[').join('[');
	s = s.split('\\right]').join(']');
	// Curly brackets are everywhere in LaTeX notation, so it uses \left{ and \right} instead.
	// It's convenient for us to replace those with < > for parsing.
	s = s.split('\\left\\{').join('<');
	s = s.split('\\right\\}').join('>');
	s = s.split('&nbsp;').join('');
	if(topLevel) {
		// Add some parentheses so -5 * -3 doesn't get parsed as (-5*) - 3
		s = s.replace(/(\\times|\\cdot|\/)(\-[0-9\.]*)/,'$1($2)');
	}
	var p = this,
		res = s,
		check = [
			p.number,
			p.addition,
			p.multiplication,
			p.leadingNumber,
			p.sum,
			p.product,
			p.integral,
			p.derivative,
			p.func,
			p.pow,
			p.symbol,
			p.matrix,
			p.brackets,
			p.parentheses,
		];
	if(s.length == 0) return new Value(0);
	if(s.charAt(s.length - 1) == '.') {
		s = s.slice(0,s.length - 1)
	}
	if(!ParseUtil.isClear(s,s.length)) {
		// Mismatched braces, somewhere
		// // console.log(s);
		throw 'Mismatched parentheses';
	}
	var quadratic = /^((?:\-)?[0-9\.]*)x\^\{2\}(\+|\-)([0-9\.]*?)x(\+|\-)([0-9\.]*)=0$/
	if(topLevel && quadratic.test(s)) {
		var m = s.match(quadratic);
		return new QuadraticSolver(m[1],m[2],m[3],m[4],m[5]);
	}
	var quadratic = /^((?:\-)?[0-9\.]*)x\^\{2\}(\+|\-)([0-9\.]*?)x=0$/
	if(topLevel && quadratic.test(s)) {
		var m = s.match(quadratic);
		return new QuadraticSolver(m[1],m[2],m[3]);
	}
	var quadratic = /^((?:\-)?[0-9\.]*)x\^\{2\}(\+|\-)([0-9\.]*?)=0$/
	if(topLevel && quadratic.test(s)) {
		var m = s.match(quadratic);
		return new QuadraticSolver(m[1],false,false,m[2],m[3]);
	}
	if(ParseUtil.nextIndexOf('=',s) != -1) {
		var split = ParseUtil.split(s,'=');
		if(topLevel) {
			return Solver.parse(split[0],split[1]);
		} else {
			throw "Can't solve here!";
		}
	}
	for(var i=0;i<check.length;i++) {
		res = check[i].call(this,StringUtil.trim(s));
		if(res != Parser.NO_MATCH) {
			return res;
		}
	}
	return res;
}

Parser.prototype.brackets = function(s) {
	var self = this;
	if(s.charAt(0) == '<') {
		// The source starts with a curly bracket, indicating a vector
		var contents = ParseUtil.split(s.slice(1,s.length - 1),',').filter(function(n) {
			return n;
		}).map(function(n){
			return self.parse(n);
		});
		return new Vector(contents);
	} else {
		return Parser.NO_MATCH;
	}
}

Parser.prototype.matrix = function(s) {
	var self = this;
	if(s.charAt(0) == '[') {
		s = s.slice(1,-1);
		var rows = ParseUtil.split(s,'|').map(function(row) {
			return ParseUtil.split(row,',').map(function(el) {
				return self.parse(el);
			});
		});
		return new Matrix(rows);
	} else {	
		return Parser.NO_MATCH;
	}
}

Parser.prototype.parentheses = function(s) {
	var self = this;
	if(s.charAt(0) == "(") {
		// The source starts with parentheses
		// Find the matching closing parenthesis
		var close = ParseUtil.findEachClear(s,")")[0];
		var first = s.slice(1,close);
		var rest = s.slice(close + 1);
		if(rest.length == 0) {
			// There's nothing else at the end of the parentheses
			return new Group(self.parse(first));
		} else {
			// Multiply this first factor by whatever else comes next
			var _factors = [
				new Factor(new Group(self.parse(first))),
				new Factor(self.parse(rest))
			];
			return new Mult(_factors);
		}
	} else {
		return Parser.NO_MATCH;
	}
}

Parser.prototype.pow = function(s) {
	var self = this;
	var index = ParseUtil.nextIndexOf('^',s);
	if(index != -1) {
		var split = ParseUtil.split(s,'^'),
			before = self.parse(split[0]),
			after = StringUtil.trim(split[1]),
			base,
			pow,
			res;
		if(after.charAt(0) == '{') {
			// It really should
			var closeBracket = ParseUtil.findEachClear(after,'}')[0],
				inner = after.slice(1,closeBracket),
				rest = after.slice(closeBracket + 1);
			if(inner.length == 0) inner = '1';
			pow = self.parse(inner);
			if(before instanceof Mult) {
				base = before.args.pop();
				res = new Pow(
					base,
					pow);
				before.args.push(res);
				res = before;
			} else {
				base = before;
				res = new Pow(
					base,
					pow
				);
			}
			
			if(rest.length > 0) {
				return new Mult([
					new Factor(res),
					new Factor(self.parse(rest))
				]);
			} else {
				return res;
			}	
		}
	} else {
		return Parser.NO_MATCH;
	}
}

Parser.prototype.integral = function(s) {
	if(s.indexOf('\\int') === 0) {
		s = s.slice(4);
		var underscore = ParseUtil.nextIndexOf('_',s);
		var caret = ParseUtil.nextIndexOf('^',s);
		var lowerBound = s.slice(underscore + 2,caret - 1);
		s = s.slice(caret);
		var bracket = ParseUtil.nextIndexOf('}',s);
		var upperBound = s.slice(2,bracket);
		s = s.slice(bracket + 1);
		var integrand = s.slice(0,-2).slice(1,-1);
		var variable = s.slice(-1);
		return new Integral(
			this.parse(lowerBound),
			this.parse(upperBound),
			this.parse(integrand),
			variable
		);
	} else {
		return Parser.NO_MATCH;
	}
	
}

Parser.prototype.sum = function(s) {
	if(s.indexOf('\\sum') === 0) {
		s = s.slice(4);
		var underscore = ParseUtil.nextIndexOf('_',s);
		var caret = ParseUtil.nextIndexOf('^',s);
		var lowerBound = s.slice(underscore + 2,caret - 1);
		lowerBound = lowerBound.split('=');
		var index = lowerBound[0];
		lowerBound = lowerBound[1];
		s = s.slice(caret);
		var bracket = ParseUtil.nextIndexOf('}',s);
		var upperBound = s.slice(2,bracket);
		s = s.slice(bracket + 1);
		var func = s.slice(1,-1);
		return new Sum(
			index,
			this.parse(lowerBound),
			this.parse(upperBound),
			this.parse(func)
		);
	} else {
		return Parser.NO_MATCH;
	}
	
};

Parser.prototype.product = function(s) {
	if(s.indexOf('\\prod') === 0) {
		s = s.slice(5);
		var underscore = ParseUtil.nextIndexOf('_',s);
		var caret = ParseUtil.nextIndexOf('^',s);
		var lowerBound = s.slice(underscore + 2,caret - 1);
		lowerBound = lowerBound.split('=');
		var index = lowerBound[0];
		lowerBound = lowerBound[1];
		s = s.slice(caret);
		var bracket = ParseUtil.nextIndexOf('}',s);
		var upperBound = s.slice(2,bracket);
		s = s.slice(bracket + 1);
		var func = s.slice(1,-1);
		return new Product(
			index,
			this.parse(lowerBound),
			this.parse(upperBound),
			this.parse(func)
		);
	} else {
		return Parser.NO_MATCH;
	}
	
};

Parser.prototype.derivative = function(s) {
	if(s.indexOf('\\frac{d}{d') == 0) {
		var rest = s.slice(10),
			wrt = rest.charAt(0);
		var endParen = ParseUtil.nextIndexOf(')',s),
			inner = this.parse(s.slice(13,endParen)),
			eq = s.slice(endParen+3,s.length-1),
			eqS = eq.split('='),
			wrt2 = eqS[0],
			at = this.parse(eqS[1]);
		if(wrt != wrt2) {
			throw 'Derivative error';
		}
		return new Derivative(
			inner,
			wrt,
			at
		);

	}
	return Parser.NO_MATCH;
}


Parser.prototype.func = function(s) {
	var self = this;
	if(s.charAt(0) == "\\") {
		var args = [];
		var firstBrace = ParseUtil.nextIndexOf('{',s);
		var firstParen = ParseUtil.nextIndexOf('(',s);
		if(firstBrace == -1 && firstParen == -1) {
			var front = '\\';
			s = s.slice(1);
			while(/[A-Za-z_]/.test(s.charAt(0))) {
				front += s.charAt(0);
				s = s.slice(1);
			}
			var _factors = [
				new Symbol(front)
			];
			if(s.length > 0) {
				_factors.push(this.parse(s));
			}
			return new Mult(_factors);
		} else if(firstBrace != -1 && (firstBrace < firstParen || firstParen == -1)) {
			var func = s.slice(1,firstBrace);
			if(func.indexOf('\\') != -1) {
				// We've caught a situation like \pi\epsilon_{0}.
				//// // console.log('FUNC',func);
				var ind = func.indexOf('\\');
				var first = func.slice(0,ind);
				var rest = func.slice(ind + 1);
				//// // console.log('BWA',first,rest,s.slice(firstBrace));
				return new Mult([
					this.parse('\\' + first),
					this.parse('\\' + rest + s.slice(firstBrace))
				]);
			}
			var rest = s.slice(firstBrace);
			var firstCharNextSet = rest.charAt(0);
			while(firstCharNextSet == '{') {
				var matchingBrace = ParseUtil.findEachClear(rest,'}')[0];
				args.push(rest.slice(1,matchingBrace));
				rest = rest.slice(matchingBrace + 1);
				firstCharNextSet = rest.charAt(0);
			}
			var res;
			if(func.indexOf('matrix') == 0) {
				var dim = func.slice(6),
					rows;
				args = args.map(function(arg) {
					return self.parse(arg);
				});
				switch(dim) {
					case 'OneOne':
						rows = [
							[args[0]]
						];
						break;
					case 'OneTwo':
						rows = [
							[args[0],args[1]]
						];
						break;
					case 'OneThree':
						rows = [
							[args[0],args[1],args[2]]
						];
						break;
					case 'TwoOne':
						rows = [
							[args[0]],
							[args[1]]
						];
						break;
					case 'TwoTwo':
						rows = [
							[args[0],args[1]],
							[args[2],args[3]]
						];
						break;
					case 'TwoThree':
						rows = [
							[args[0],args[1],args[2]],
							[args[3],args[4],args[5]]
						];
						break;
					case 'ThreeOne':
						rows = [
							[args[0]],
							[args[1]],
							[args[2]]
						];
						break;
					case 'ThreeTwo':
						rows = [
							[args[0],args[1]],
							[args[2],args[3]],
							[args[4],args[5]]
						];
						break;
					case 'ThreeThree':
						rows = [
							[args[0],args[1],args[2]],
							[args[3],args[4],args[5]],
							[args[6],args[7],args[8]]
						];
						break;
				}
				res = new Matrix(rows);
			} else if(func == 'frac') {
				// Create a fraction object
				res = new Frac(
					self.parse(args[0]),
					self.parse(args[1])
				);

			} else if(func == 'sqrt') {
				// Raise it to the 1/2 power
				res = new Pow(
					self.parse(args[0]),
					new Value(0.5)
				);
			} else {
				var reconstruct = '\\' + func + args.map(function(a) {
					return '{' + a + '}';
				}).join('');
				res = new Symbol(reconstruct);
			}
			var _factors = [
				res
			];
			if(rest.length) {
				_factors.push(
					self.parse(rest)
				);
			}
			return new Mult(_factors);
		} else if(firstParen != -1) {
			var func = s.slice(1,firstParen),
				closeParen = ParseUtil.findEachClear(s,')')[0],
				args = s.slice(firstParen + 1,closeParen),
				rest = s.slice(closeParen + 1);
			var res = new Func(
				func,
				ParseUtil.split(args,[',']).map(function(i) {
					return self.parse(i);
				})
			);
			if(rest.length > 0) {
				return new Mult([
					new Factor(res),
					new Factor(self.parse(rest))
				]);
			} else {
				return res;
			}
		}
	} else {
		return Parser.NO_MATCH;
	}
}

Parser.prototype.number = function(s) {
	// Is the whole thing a number?
	if(/^-{0,1}\d*\.{0,1}\d+$/.test(s)) {
		// Looks like it's just a number
		return new Value(
			parseFloat(s)
		);	
	} else {
		return Parser.NO_MATCH;
	}
}

Parser.prototype.leadingNumber = function(s) {
	
	var self = this;
	// Let's see if there's a leading number
	var numChars = "0123456789.";
	if(numChars.indexOf(s.charAt(0)) != -1) {
		// Yep, there is
		var ind = 0;
		while(s.charAt(ind).length && numChars.indexOf(s.charAt(ind)) != -1) {
			ind ++;
		}
		var lead = s.slice(0,ind);
		var _factors = [
			new Factor(self.parse(lead))
		];
		var rest = s.slice(ind);
		if(rest.charAt(0) == '^') {
			return Parser.NO_MATCH;
		}
		if(rest.length > 0) {
			_factors.push(new Factor(self.parse(rest)));
		}
		return new Mult(_factors);
	} else {
		return Parser.NO_MATCH;
	}
}

Parser.prototype.symbol = function(s) {
	var self = this;
	// Is the first character an English letter? 
	if(/^[A-Za-z]$/.test(s.charAt(0))) {
		// Yes, yes it is.
		// Is the second character an underscore and the third a left curlybrace? That means we have a subscript
		var restIndex = 1;
		if(s.charAt(1) == '_' && s.charAt(2) == '{') {
			restIndex = ParseUtil.findEachClear(s,'}')[0] + 1;
			var symbol = new Symbol(s.slice(0,restIndex));
		} else {
			var symbol = new Symbol(s.charAt(0));
		}
		var rest = s.slice(restIndex);
		var _factors = [
			new Factor(symbol)
		];
		if(rest.length > 0) {
			_factors.push(new Factor(self.parse(rest)));
		}
		return new Mult(_factors);	
	} else {
		return Parser.NO_MATCH;
	}
}

Parser.prototype.addition = function(s) {
	var pu = ParseUtil,
		su = StringUtil,
		self = this;
	var _terms = ParseUtil.split(s,[Parser.tokens.PLUS,Parser.tokens.MINUS]);
	if(_terms.length > 1) {
		// Yes! The expression we're evaluating has at least one + or - at the top level
		// _plus contains all indices of + in str
		var _plus = ParseUtil.findEachClear(s,Parser.tokens.PLUS).map(function(index) {
			return {
				index: index,
				type: Parser.tokens.PLUS
			};
		});
		// _minus contains all indices of - in str
		var _minus = ParseUtil.findEachClear(s,Parser.tokens.MINUS).map(function(index) {
			return {
				index: index,
				type: Parser.tokens.MINUS
			};
		});
		// _signs contains a list of all +/- signs, in order, in the expression
		var _signs = _plus.concat(_minus).sort(function(a,b) {
			return a.index - b.index;
		});
		// Now we transform _terms from a list of strings to a list of parsed nodes
		_terms = _terms.map(function(term,index) {
			// If term is empty, remove it. This is quirk in the parser that allows for
			// leading negative signs...it's easier just to filter these out here
			if(term.length == 0) {
				return false;
			}
			// Check to see whether it's negative
			var isNeg = (_signs[index - 1] && _signs[index - 1].type == Parser.tokens.MINUS) || false;
			return new Addend(self.parse(term),isNeg);			
		}).filter(function(term) {
			// Only keep terms that weren't set to false by map()
			return term;
		});
		return new Add(_terms);
	} else {
		return Parser.NO_MATCH;
	}
}

Parser.prototype.multiplication = function(s) {
	var pu = ParseUtil,
		su = StringUtil,
		self = this;
	var _factors = ParseUtil.split(s,[Parser.tokens.TIMES,Parser.tokens.DOT,Parser.tokens.DIV]);
	if(_factors.length > 1) {
		// _times contains all the indices of cross in str
		var _times = ParseUtil.findEachClear(s,Parser.tokens.TIMES).map(function(index) {
			return {
				index: index,
				type: Parser.tokens.MULT
			};
		});
		// _div contains all the indices of / in str
		var _div = ParseUtil.findEachClear(s,Parser.tokens.DIV).map(function(index) {
			return {
				index: index,
				type: Parser.tokens.DIV
			};
		});
		// _dot contains all the indices of dot in str
		var _dot = ParseUtil.findEachClear(s,Parser.tokens.DOT).map(function(index) {
			return {
				index: index,
				type: Parser.tokens.DOT
			};
		});
		// _signs contains a list of all x, ., and / signs
		var _signs = _times.concat(_div).concat(_dot).sort(function(a,b) {
			return a.index - b.index;
		});
		// Now we transform _factors from a list of strings to a list of parsed nodes
		_factors = _factors.map(function(factor,index) {
			// If factor is empty, remove it
			if(factor.length == 0) {
				return false;
			}
			var isInv = (_signs[index - 1] && _signs[index - 1].type == Parser.tokens.DIV) || false;
			var prodType = (isInv || !_signs[index - 1]) ? 'none' : (_signs[index - 1].type == Parser.tokens.DOT ? 'dot' : 'cross');
			return new Factor(self.parse(factor),isInv,prodType);
		}).filter(function(factor) {
			// Only keep non-false factors
			return factor;
		});
		return new Mult(_factors);
	} else {
		return Parser.NO_MATCH;
	}
}
