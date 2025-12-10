import '../fuzzy_composite_term.dart';
import '../fuzzy_term.dart';

/// Hedges are special unary operators that can be employed to modify the meaning
/// of a fuzzy set. The FAIRLY fuzzy hedge widens the membership function.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FuzzyVERY extends FuzzyCompositeTerm {
  FuzzyTerm? fuzzyTerm;

	/// Constructs a new fuzzy VERY hedge with the given values.
	FuzzyVERY.create([this.fuzzyTerm, List<FuzzyTerm>? terms]):super( terms );

	factory FuzzyVERY([FuzzyTerm? fuzzyTerm]){
		final terms = ( fuzzyTerm != null ) ? [ fuzzyTerm ] : <FuzzyTerm>[];
    return FuzzyVERY.create(fuzzyTerm, terms);
	}

	// FuzzyTerm API

	/// Clears the degree of membership value.
  @override
	FuzzyVERY clearDegreeOfMembership() {
		final fuzzyTerm = terms[ 0 ];
		fuzzyTerm.clearDegreeOfMembership();

		return this;
	}

	/// Returns the degree of membership.
  @override
	double getDegreeOfMembership() {
		final fuzzyTerm = terms[ 0 ];
		final dom = fuzzyTerm.getDegreeOfMembership();

		return dom * dom;
	}

	/// Updates the degree of membership by the given value.
  @override
	FuzzyVERY updateDegreeOfMembership(double value ) {
		final fuzzyTerm = terms[ 0 ];
		fuzzyTerm.updateDegreeOfMembership( value * value );

		return this;
	}
}
