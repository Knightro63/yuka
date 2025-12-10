import "../fuzzy_composite_term.dart";
import 'dart:math' as math;
import '../fuzzy_term.dart';

/// Hedges are special unary operators that can be employed to modify the meaning
/// of a fuzzy set. The FAIRLY fuzzy hedge widens the membership function.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FuzzyFAIRLY extends FuzzyCompositeTerm {

	/// Constructs a new fuzzy FAIRLY hedge with the given values.
  FuzzyFAIRLY.create(super.terms);

	factory FuzzyFAIRLY([FuzzyTerm? fuzzyTerm] ) {
		final terms = ( fuzzyTerm != null ) ? [ fuzzyTerm ] : <FuzzyTerm>[];
    return FuzzyFAIRLY.create(terms);
	}

	// FuzzyTerm API

	/// Clears the degree of membership value.
  @override
	FuzzyFAIRLY clearDegreeOfMembership() {
		final fuzzyTerm = terms[ 0 ];
		fuzzyTerm.clearDegreeOfMembership();

		return this;
	}

  /// Returns the degree of membership.
  @override
	double getDegreeOfMembership() {
		final fuzzyTerm = terms[ 0 ];
		final dom = fuzzyTerm.getDegreeOfMembership();

		return math.sqrt( dom );
	}

	/// Updates the degree of membership by the given value.
  @override
	FuzzyFAIRLY updateDegreeOfMembership(double value ) {

		final fuzzyTerm = terms[ 0 ];
		fuzzyTerm.updateDegreeOfMembership( math.sqrt( value ) );

		return this;

	}

}
