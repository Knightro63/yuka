import '../fuzzy_set.dart';
import 'dart:math' as math;

/// Class for representing a fuzzy set that has a s-shape membership function with
/// values from lowest to highest.
///
/// @author {@link https://github.com/robp94|robp94}
class RightSCurveFuzzySet extends FuzzySet {
  double midpoint;

	/// Constructs a new S-curve fuzzy set with the given values.
	RightSCurveFuzzySet([double left = 0, this.midpoint = 0, double right = 0 ]):super( ( midpoint + right ) / 2 ){
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
			if ( value <= ( ( left + midpoint ) / 2 ) ) {
				return 2 * ( math.pow( ( value - left ) / ( midpoint - left ), 2 ) ).toDouble();
			} 
      else {
				return 1 - ( 2 * ( math.pow( ( value - midpoint ) / ( midpoint - left ), 2 ) ) ).toDouble();
			}

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
	RightSCurveFuzzySet fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );
		midpoint = json['midpoint'];
		return this;
	}
}