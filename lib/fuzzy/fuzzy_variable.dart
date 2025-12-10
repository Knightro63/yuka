import '../core/console_logger/console_platform.dart';
import 'fuzzy_set.dart';
import 'sets/left_shoulder_fuzzy_set.dart';
import 'sets/right_shoulder_fuzzy_set.dart';
import 'sets/singleton_fuzzy_set.dart';
import 'sets/triangular_fuzzy_set.dart';
import 'dart:math' as math;

/// Class for representing a fuzzy linguistic variable (FLV). A FLV is the
/// composition of one or more fuzzy sets to represent a concept or domain
/// qualitatively. For example fuzzs sets "Dumb", "Average", and "Clever"
/// are members of the fuzzy linguistic variable "IQ".
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FuzzyVariable {
  List<FuzzySet> fuzzySets = [];
  double minRange = double.infinity;
  double maxRange = -double.infinity;

	/// Adds the given fuzzy set to this FLV.
	FuzzyVariable add(FuzzySet fuzzySet ) {
		fuzzySets.add( fuzzySet );

		// adjust range
		if ( fuzzySet.left < minRange ) minRange = fuzzySet.left;
		if ( fuzzySet.right > maxRange ) maxRange = fuzzySet.right;
		return this;
	}

	/// Removes the given fuzzy set from this FLV.
	FuzzyVariable remove(FuzzySet fuzzySet ) {
		final fuzzySets = this.fuzzySets;

		final index = fuzzySets.indexOf( fuzzySet );
		fuzzySets.removeAt(index);

		// iterate over all fuzzy sets to recalculate the min/max range

		minRange = double.infinity;
		maxRange = - double.infinity;

		for ( int i = 0, l = fuzzySets.length; i < l; i ++ ) {
			final fuzzySet = fuzzySets[ i ];
			if ( fuzzySet.left < minRange ) minRange = fuzzySet.left;
			if ( fuzzySet.right > maxRange ) maxRange = fuzzySet.right;
		}

		return this;
	}

	/// Fuzzifies a value by calculating its degree of membership in each of
	/// this variable's fuzzy sets.
	FuzzyVariable? fuzzify(double value ) {
		if ( value < minRange || value > maxRange ) {
			yukaConsole.warning( 'YUKA.FuzzyVariable: Value for fuzzification out of range.' );
			return null;
		}

		final fuzzySets = this.fuzzySets;

		for (int i = 0, l = fuzzySets.length; i < l; i ++ ) {
			final fuzzySet = fuzzySets[ i ];
			fuzzySet.degreeOfMembership = fuzzySet.computeDegreeOfMembership( value );
		}

		return this;
	}

	/// Defuzzifies the FLV using the "Average of Maxima" (MaxAv) method.
	double defuzzifyMaxAv() {
		// the average of maxima (MaxAv for short) defuzzification method scales the
		// representative value of each fuzzy set by its DOM and takes the average
		final fuzzySets = this.fuzzySets;

		double bottom = 0;
		double top = 0;

		for ( int i = 0, l = fuzzySets.length; i < l; i ++ ) {
			final fuzzySet = fuzzySets[ i ];

			bottom += fuzzySet.degreeOfMembership;
			top += fuzzySet.representativeValue * fuzzySet.degreeOfMembership;
		}

		return ( bottom == 0 ) ? 0 : ( top / bottom );
	}

	/// Defuzzifies the FLV using the "Centroid" method.
	double defuzzifyCentroid([int samples = 10 ]) {
		final fuzzySets = this.fuzzySets;
		final stepSize = ( maxRange - minRange ) / samples;
		double totalArea = 0;
		double sumOfMoments = 0;

		for ( int s = 1; s <= samples; s ++ ) {
			final sample = minRange + ( s * stepSize );

			for ( int i = 0, l = fuzzySets.length; i < l; i ++ ) {
				final fuzzySet = fuzzySets[ i ];
				final contribution = math.min( fuzzySet.degreeOfMembership, fuzzySet.computeDegreeOfMembership( sample ) );
				totalArea += contribution;
				sumOfMoments += ( sample * contribution );
			}
		}

		return ( totalArea == 0 ) ? 0 : ( sumOfMoments / totalArea );
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		final Map<String,dynamic> json = {
			'type': runtimeType.toString(),
			'fuzzySets': [],
			'minRange': minRange.toString(),
			'maxRange': maxRange.toString(),
		};

		for ( int i = 0, l = fuzzySets.length; i < l; i ++ ) {
			final fuzzySet = fuzzySets[ i ];
			json['fuzzySets'].add( fuzzySet.toJSON() );
		}

		return json;
	}

	/// Restores this instance from the given JSON object.
	FuzzyVariable fromJSON(Map<String,dynamic> json ) {
		minRange = double.parse( json['minRange'] );
		maxRange = double.parse( json['maxRange'] );

		for ( int i = 0, l = json['fuzzySets'].length; i < l; i ++ ) {
			final fuzzySetJson = json['fuzzySets'][ i ];
			String type = fuzzySetJson['type'];

			switch ( type ) {
				case 'LeftShoulderFuzzySet':
					fuzzySets.add( LeftShoulderFuzzySet().fromJSON( fuzzySetJson ) );
					break;
				case 'RightShoulderFuzzySet':
					fuzzySets.add( RightShoulderFuzzySet().fromJSON( fuzzySetJson ) );
					break;
				case 'SingletonFuzzySet':
					fuzzySets.add( SingletonFuzzySet().fromJSON( fuzzySetJson ) );
					break;
				case 'TriangularFuzzySet':
					fuzzySets.add( TriangularFuzzySet().fromJSON( fuzzySetJson ) );
					break;
				default:
					yukaConsole.error( 'YUKA.FuzzyVariable: Unsupported fuzzy set type: ${fuzzySetJson['type']}');
			}
		}

		return this;
	}
}