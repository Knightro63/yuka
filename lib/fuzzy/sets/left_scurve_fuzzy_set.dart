import 'dart:math' as math;
import '../fuzzy_set.dart';

/// Class for representing a fuzzy set that has a s-shape membership function with
/// values from highest to lowest.
///
/// @author {@link https://github.com/robp94|robp94}
class LeftSCurveFuzzySet extends FuzzySet {
  double midpoint;

	/// Constructs a new S-curve fuzzy set with the given values.
	LeftSCurveFuzzySet([ double left = 0, this.midpoint = 0, double right = 0]):super(( midpoint + left ) / 2){
    this.right = right;
    this.left = left;
  }

	/// Computes the degree of membership for the given value.
  @override
	double computeDegreeOfMembership(double value ) {
		final midpoint = this.midpoint;
		final left = this.left;
		final right = this.right;

		// find DOM if the given value is left of the center or equal to the center

		if ( ( value >= left ) && ( value <= midpoint ) ) {
			return 1;
		}

		// find DOM if the given value is right of the midpoint
		if ( ( value > midpoint ) && ( value <= right ) ) {
			if ( value >= ( ( midpoint + right ) / 2 ) ) {
				return 2 * ( math.pow( ( value - right ) / ( midpoint - right ), 2 ) ).toDouble();
			} 
      else { //todo test
				return 1 - ( 2 * ( math.pow( ( value - midpoint ) / ( midpoint - right ), 2 ) ) ).toDouble();
			}
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
	LeftSCurveFuzzySet fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );
	  midpoint = json['midpoint'];
		return this;
	}
}
