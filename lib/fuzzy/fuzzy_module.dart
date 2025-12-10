import 'fuzzy_rule.dart';
import 'fuzzy_set.dart';
import 'fuzzy_variable.dart';

enum FuzzyModuleType{maxav,centroid}

/// Class for representing a fuzzy module. Instances of this class are used by
/// game entities for fuzzy inference. A fuzzy module is a collection of fuzzy variables
/// and the rules that operate on them.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FuzzyModule {
  final List<FuzzyRule> rules = [];
  final Map<String,FuzzyVariable> flvs = {};

	/// Adds the given FLV under the given name to this fuzzy module.
	FuzzyModule addFLV(String name, FuzzyVariable flv ) {
		flvs[name] = flv;
		return this;
	}

	/// Remove the FLV under the given name from this fuzzy module.
	FuzzyModule removeFLV(String name ) {
		flvs.remove( name );
		return this;
	}

	/// Adds the given fuzzy rule to this fuzzy module.
	FuzzyModule addRule(FuzzyRule rule ) {
		rules.add( rule );
		return this;
	}

	/// Removes the given fuzzy rule from this fuzzy module.
	FuzzyModule removeRule(FuzzyRule rule ) {
		final rules = this.rules;
		final index = rules.indexOf( rule );
		rules.removeAt( index);
		return this;
	}

	/// Calls the fuzzify method of the defined FLV with the given value.
	FuzzyModule fuzzify(String name, double value ) {
		final flv = flvs[name];
		flv?.fuzzify( value );
		return this;
	}

	/// Given a fuzzy variable and a defuzzification method this returns a crisp value.
	double defuzzify(String name, [FuzzyModuleType type = FuzzyModuleType.maxav ]) {
		final flvs = this.flvs;
		final rules = this.rules;

		_initConsequences();

		for ( int i = 0, l = rules.length; i < l; i ++ ) {
			final rule = rules[ i ];
			rule.evaluate();
		}

		final flv = flvs[name];

		double? value;

		switch ( type ) {
			case FuzzyModuleType.maxav:
				value = flv?.defuzzifyMaxAv();
				break;
			case FuzzyModuleType.centroid:
				value = flv?.defuzzifyCentroid();
				break;
		}

		return value ?? 0;
	}

	FuzzyModule _initConsequences() {
		final rules = this.rules;

		// initializes the consequences of all rules.
		for (int i = 0, l = rules.length; i < l; i ++ ) {
			final rule = rules[ i ];
			rule.initConsequence();
		}

		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> json = {
			'rules': [],
			'flvs': []
		};

		// rules
		final rules = this.rules;

		for ( int i = 0, l = rules.length; i < l; i ++ ) {
			json['rules'].add( rules[ i ].toJSON() );
		}

		// flvs
		for (final key in flvs.keys) {
      final flv = flvs[key]!;
			json['flvs'].add( { 'name': key, 'flv': flv.toJSON() } );
		}

		return json;
	}

	/// Restores this instance from the given JSON object.
	FuzzyModule fromJSON(Map<String,dynamic> json ) {

		final Map<String,FuzzySet> fuzzySets = {};// used for rules

		// flvs
		final flvsJSON = json['flvs'];

		for ( int i = 0, l = flvsJSON.length; i < l; i ++ ) {
			final flvJSON = flvsJSON[ i ];
			final name = flvJSON.name;
			final flv = FuzzyVariable().fromJSON( flvJSON.flv );

			addFLV( name, flv );

			for ( final fuzzySet in flv.fuzzySets ) {
				fuzzySets[fuzzySet.uuid!] = fuzzySet;
			}
		}

		// rules

		final rulesJSON = json['rules'];

		for ( int i = 0, l = rulesJSON.length; i < l; i ++ ) {
			final ruleJSON = rulesJSON[ i ];
			final rule = FuzzyRule().fromJSON( ruleJSON, fuzzySets );
			addRule( rule );
		}

		return this;
	}
}


