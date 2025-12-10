import 'dart:math' as math ;
import '../fuzzy_set.dart';


/// Class for representing a fuzzy set that has a normal distribution shape. It can be defined
/// by the mean and standard deviation.
///
/// @author {@link https://github.com/robp94|robp94}
class NormalDistFuzzySet extends FuzzySet {
  double midpoint;
  double standardDeviation;
  final Map<String, double> _cache = {};

	/// Constructs a new triangular fuzzy set with the given values.
	NormalDistFuzzySet([ double left = 0, this.midpoint = 0, double right = 0, this.standardDeviation = 0 ]):super( midpoint ) {
		this.left = left;
		this.right = right;
	}

	/// Computes the degree of membership for the given value.
  @override
	double computeDegreeOfMembership(double value ) {
		_updateCache();
		if ( value >= right || value <= left ) return 0;
		return probabilityDensity( value, midpoint, _cache['variance']!.toDouble() ) / _cache['normalizationFactor']!.toDouble();
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();
		json['midpoint'] = midpoint;
		json['standardDeviation'] = standardDeviation;
		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	NormalDistFuzzySet fromJSON(Map<String,dynamic> json ) {
		super.fromJSON( json );
		midpoint = json['midpoint'];
		standardDeviation = json['standardDeviation'];
		return this;
	}

	//
	NormalDistFuzzySet _updateCache() {
		final cache =	_cache;
		final midpoint = this.midpoint;
		final standardDeviation = this.standardDeviation;

		if ( midpoint != cache['midpoint'] || standardDeviation != cache['standardDeviation'] ) {
			final variance = standardDeviation * standardDeviation;

			cache['midpoint'] = midpoint;
			cache['standardDeviation'] = standardDeviation;
			cache['variance'] = variance;

			// this value is used to ensure the DOM lies in the range of [0,1]
			cache['normalizationFactor'] = probabilityDensity( midpoint, midpoint, variance );
		}

		return this;
	}

  double probabilityDensity(double x, double mean, double variance ) {
    return ( 1 / math.sqrt( 2 * math.pi * variance ) ) * math.exp( - ( math.pow( ( x - mean ), 2 ) ) / ( 2 * variance ) );
  }
}
