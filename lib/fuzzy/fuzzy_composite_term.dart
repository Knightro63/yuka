import './fuzzy_term.dart';

/// Base class for representing more complex fuzzy terms based on the
/// composite design pattern.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FuzzyCompositeTerm extends FuzzyTerm {
  late List<FuzzyTerm> terms;

	/// Constructs a new fuzzy composite term with the given values.
	FuzzyCompositeTerm([List<FuzzyTerm>? terms]):super(){
		this.terms = terms ?? [];
	}

	/// Clears the degree of membership value.
  @override
	FuzzyCompositeTerm clearDegreeOfMembership() {
		final terms = this.terms;

		for ( int i = 0, l = terms.length; i < l; i ++ ) {
			terms[ i ].clearDegreeOfMembership();
		}

		return this;
	}

	/// Updates the degree of membership by the given value. This method is used when
	/// the term is part of a fuzzy rule's consequent.
  @override
	FuzzyCompositeTerm updateDegreeOfMembership(double value ) {
		final terms = this.terms;

		for ( int i = 0, l = terms.length; i < l; i ++ ) {
			terms[ i ].updateDegreeOfMembership( value );
		}

		return this;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['terms'] = [];

		for ( int i = 0, l = terms.length; i < l; i ++ ) {
			final term = terms[ i ];

			if ( term is FuzzyCompositeTerm ) {
				json['terms'].add( term.toJSON() );
			} 
      else {
				json['terms'].add( term.uuid );
			}
		}

		return json;
	}
}
