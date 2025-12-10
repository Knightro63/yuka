import '../fuzzy_set.dart';

/// Class for representing a fuzzy set that has a right shoulder shape. The range between
/// the midpoint and right border point represents the same DOM.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class RightShoulderFuzzySet extends FuzzySet {
  double midpoint;

	/// Constructs a new right shoulder fuzzy set with the given values.
	RightShoulderFuzzySet([ double left = 0, this.midpoint = 0, double right = 0]):super( ( midpoint + right ) / 2 ){
		this.left = left;
		this.right = right;

	}

	/// Computes the degree of membership for the given value.
  @override
	double computeDegreeOfMembership(double value ) {
		final midpoint = this.midpoint;
		final left = this.left;
		final right = this.right;

		// find DOM if the given value is left of the center or equal to the center

		if ( ( value >= left ) && ( value <= midpoint ) ) {
			final grad = 1 / ( midpoint - left );
			return grad * ( value - left );
		}

		// find DOM if the given value is right of the midpoint

		if ( ( value > midpoint ) && ( value <= right ) ) {
			return 1;
		}

		// out of range
		return 0;
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
	RightShoulderFuzzySet fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );
		midpoint = json['midpoint'];
		return this;
	}
}
