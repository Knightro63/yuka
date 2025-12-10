import '../core/console_logger/console_platform.dart';
import 'fuzzy_composite_term.dart';
import 'fuzzy_set.dart';
import 'fuzzy_term.dart';
import 'operators/fuzzy_and.dart';
import 'operators/fuzzy_fairly.dart';
import 'operators/fuzzy_or.dart';
import 'operators/fuzzy_very.dart';

/// Class for representing a fuzzy rule. Fuzzy rules are comprised of an antecedent and
/// a consequent in the form: IF antecedent THEN consequent.
///
/// Compared to ordinary if/else statements with discrete values, the consequent term
/// of a fuzzy rule can fire to a matter of degree.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FuzzyRule {
  FuzzyTerm? antecedent;
  FuzzyTerm? consequence;

	/// Constructs a new fuzzy rule with the given values.
	FuzzyRule([this.antecedent, this.consequence]);

	/// Initializes the consequent term of this fuzzy rule.
	FuzzyRule initConsequence() {
		consequence?.clearDegreeOfMembership();
		return this;
	}

	/// Evaluates the rule and updates the degree of membership of the consequent term with
	/// the degree of membership of the antecedent term.
	FuzzyRule evaluate() {
		consequence?.updateDegreeOfMembership( antecedent?.getDegreeOfMembership() ?? 0);
		return this;
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final json = <String,dynamic>{};

		final antecedent = this.antecedent;
		final consequence = this.consequence;

		json['type'] = runtimeType.toString();
		json['antecedent'] = ( antecedent is FuzzyCompositeTerm ) ? antecedent.toJSON() : antecedent?.uuid;
		json['consequence'] = ( consequence is FuzzyCompositeTerm ) ? consequence.toJSON() : consequence?.uuid;

		return json;
	}

	/// Restores this instance from the given JSON object.
	FuzzyRule fromJSON(Map<String,dynamic> json, Map<String,FuzzySet> fuzzySets ) {

		parseTerm( termJSON ) {
			if (termJSON is String ) {
				// atomic term -> FuzzySet
				final uuid = termJSON;
				return fuzzySets[uuid];
			} 
      else {
				// composite term
				final type = termJSON['type'];

				dynamic term;

				switch ( type ) {
					case 'FuzzyAND':
						term = FuzzyAND();
						break;
					case 'FuzzyOR':
						term = FuzzyOR();
						break;
					case 'FuzzyVERY':
						term = FuzzyVERY();
						break;
					case 'FuzzyFAIRLY':
						term = FuzzyFAIRLY();
						break;
					default:
						yukaConsole.error( 'YUKA.FuzzyRule: Unsupported operator type: $type' );
						return;
				}

				final termsJSON = termJSON.terms;

				for ( int i = 0, l = termsJSON.length; i < l; i ++ ) {
					// recursively parse all subordinate terms
					term.terms.add( parseTerm( termsJSON[ i ] ) );
				}

				return term;
			}
		}

		antecedent = parseTerm( json['antecedent'] );
		consequence = parseTerm( json['consequence'] );

		return this;
	}
}
