import '../fuzzy_set.dart';

/// Class for representing a fuzzy set that is a singleton. In its range, the degree of
/// membership is always one.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class SingletonFuzzySet extends FuzzySet {
  double midpoint;

	/// Constructs a new singleton fuzzy set with the given values.
	SingletonFuzzySet([double left = 0, this.midpoint = 0, double right = 0 ]):super( midpoint ){
		this.left = left;
		this.right = right;
	}

	/// Computes the degree of membership for the given value.
  @override
	double computeDegreeOfMembership(double value ) {
		final left = this.left;
		final right = this.right;
		return ( value >= left && value <= right ) ? 1 : 0;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();
		json['midpoint'] = midpoint;
		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	SingletonFuzzySet fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );
		midpoint = json['midpoint'];
		return this;
	}
}