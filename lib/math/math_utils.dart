import 'dart:math' as math;
import 'vector3.dart';
import 'package:uuid/uuid.dart';

/// Class with various math helpers.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class MathUtils {
  static const double epsilon = 0.01;

  static List<String> lut = List.generate(256, (i){
    return ( i < 16 ? '0' : '' ) + ( i ).toRadixString( 16 );
  });
	/// Computes the signed area of a rectangle defined by three points.
	/// This method can also be used to calculate the area of a triangle.
	static double area(Vector3 a, Vector3 b, Vector3 c ) {
		return ( ( c.x - a.x ) * ( b.z - a.z ) ) - ( ( b.x - a.x ) * ( c.z - a.z ) );
	}

  static double getMaxFromArray(List<double> array){
    double max = array[0];
    for(int i = 1; i < array.length; i++){
      max = math.max(max,array[i]);
    }

    return max;
  }

	/// Returns the indices of the maximum values of the given array.
	static List<int> argmax(List<double> array ) {
		final max = getMaxFromArray( array );
		final indices = <int>[];

		for ( int i = 0, l = array.length; i < l; i ++ ) {
			if ( array[ i ] == max ) indices.add( i );
		}

		return indices;
	}

	/// Returns a random sample from a given array.
	static choice(List array, [List<double>? probabilities]) {
		final random = math.Random().nextDouble();

		if ( probabilities == null ) {
			return array[ ( math.Random().nextDouble() * array.length ).floor() ];
		} 
    else {
			double probability = 0;

			final index = array.map((value){
				probability += probabilities[ array.indexOf(value) ];
				return probability;
			} ).toList().indexWhere((cumulativeProbability) => cumulativeProbability >= random);//.findIndex( ( probability ) => probability >= random );

			return array[ index ];
		}
	}

	/// Ensures the given scalar value is within a given min/max range.
	static double clamp(double value, double min, double max ) {
		return math.max( min, math.min( max, value ) );
	}

	static int clampInt(int value, int min, int max ) {
		return math.max( min, math.min( max, value ) );
	}

	// /// Computes a RFC4122 Version 4 complied Universally Unique Identifier (UUID).
	// static String generateUUID() {
	// 	// https://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript/21963136#21963136
	// 	final d0 = (math.Random().nextDouble() * 0xffffffff).toInt() | 0;
	// 	final d1 = (math.Random().nextDouble() * 0xffffffff).toInt() | 0;
	// 	final d2 = (math.Random().nextDouble() * 0xffffffff).toInt() | 0;
	// 	final d3 = (math.Random().nextDouble() * 0xffffffff).toInt() | 0;
	// 	final String uuid = lut[ d0 & 0xff ] + lut[ d0 >> 8 & 0xff ] + lut[ d0 >> 16 & 0xff ] + lut[ d0 >> 24 & 0xff ] + '-' +
	// 		lut[ d1 & 0xff ] + lut[ d1 >> 8 & 0xff ] + '-' + lut[ d1 >> 16 & 0x0f | 0x40 ] + lut[ d1 >> 24 & 0xff ] + '-' +
	// 		lut[ d2 & 0x3f | 0x80 ] + lut[ d2 >> 8 & 0xff ] + '-' + lut[ d2 >> 16 & 0xff ] + lut[ d2 >> 24 & 0xff ] +
	// 		lut[ d3 & 0xff ] + lut[ d3 >> 8 & 0xff ] + lut[ d3 >> 16 & 0xff ] + lut[ d3 >> 24 & 0xff ];

	// 	return uuid.toUpperCase();
	// }

  /// Computes a RFC4122 Version 4 complied Universally Unique Identifier (UUID).
  static String generateUUID() {
    final uuid = const Uuid().v4();
    // .toLowerCase() here flattens concatenated strings to save heap memory space.
    return uuid.toLowerCase();
  }

	/// Computes a random float value within a given min/max range.
	static double randFloat(double min, double max ) {
		return min + math.Random().nextDouble() * ( max - min );
	}

	/// Computes a random integer value within a given min/max range.
	static int randInt(int min, int max ) {
		return min + ( math.Random().nextDouble() * ( max - min + 1 ) ).floor();
	}
}
