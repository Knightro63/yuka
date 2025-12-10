import '../fuzzy_composite_term.dart';

/// Class for representing an AND operator. Can be used to construct
/// fuzzy rules.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FuzzyAND extends FuzzyCompositeTerm {
  
	/// Constructs a new fuzzy AND operator with the given values. The constructor
	/// accepts and arbitrary amount of fuzzy terms.
	FuzzyAND([super.terms]);

	/// Returns the degree of membership. The AND operator returns the minimum
	/// degree of membership of the sets it is operating on.
  @override
	double getDegreeOfMembership() {
		final terms = this.terms;
		double minDOM = double.infinity;

		for (int i = 0, l = terms.length; i < l; i ++ ) {
			final term = terms[ i ];
			final currentDOM = term.getDegreeOfMembership();

			if ( currentDOM < minDOM ) minDOM = currentDOM;
		}

		return minDOM;
	}
}
