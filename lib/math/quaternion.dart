import 'math_utils.dart';
import 'matrix3.dart';
import 'matrix4.dart';
import 'vector3.dart';
import 'dart:math' as math;

/// Class representing a quaternion.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Quaternion {
  final matrix = Matrix3();
  final vector = Vector3();

  double x;
  double y;
  double z;
  double w;

  List<double> get storage => [x,y,z,w];

	/// Constructs a new quaternion with the given values.
	Quaternion([ this.x = 0, this.y = 0, this.z = 0, this.w = 1 ]);

	/// Sets the given values to this quaternion.
	Quaternion set(double x, double y, double z, double w ) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;

		return this;
	}

	/// Copies all values from the given quaternion to this quaternion.
	Quaternion copy(Quaternion q ) {
		x = q.x;
		y = q.y;
		z = q.z;
		w = q.w;

		return this;
	}

	/// Creates a new quaternion and copies all values from this quaternion.
	Quaternion clone() {
		return Quaternion().copy( this );
	}

	/// Computes the inverse of this quaternion.
	Quaternion inverse() {
		return conjugate().normalize();
	}

	/// Computes the conjugate of this quaternion.
	Quaternion conjugate() {
		x *= - 1;
		y *= - 1;
		z *= - 1;

		return this;
	}

	/// Computes the dot product of this and the given quaternion.
	double dot(Quaternion q ) {
		return ( x * q.x ) + ( y * q.y ) + ( z * q.z ) + ( w * q.w );
	}

	/// Computes the length of this quaternion.
	double get length => math.sqrt( squaredLength );
	
	/// Computes the squared length of this quaternion
	double get squaredLength => dot( this );

	/// Normalizes this quaternion.
	Quaternion normalize() {
		double l = length;

		if ( l == 0 ) {
			x = 0;
			y = 0;
			z = 0;
			w = 1;
		} 
    else {
			l = 1 / l;

			x = x * l;
			y = y * l;
			z = z * l;
			w = w * l;
		}

		return this;
	}

	/// Multiplies this quaternion with the given quaternion.
	Quaternion multiply(Quaternion q ) {
		return multiplyQuaternions( this, q );
	}

	/// Multiplies the given quaternion with this quaternion.
	/// So the order of the multiplication is switched compared to {@link Quaternion#multiply}.
	Quaternion premultiply(Quaternion q ) {
		return multiplyQuaternions( q, this );
	}

	/// Multiplies two given quaternions and stores the result in this quaternion.
	Quaternion multiplyQuaternions(Quaternion a, Quaternion b ) {
		final qax = a.x, qay = a.y, qaz = a.z, qaw = a.w;
		final qbx = b.x, qby = b.y, qbz = b.z, qbw = b.w;

		x = ( qax * qbw ) + ( qaw * qbx ) + ( qay * qbz ) - ( qaz * qby );
		y = ( qay * qbw ) + ( qaw * qby ) + ( qaz * qbx ) - ( qax * qbz );
		z = ( qaz * qbw ) + ( qaw * qbz ) + ( qax * qby ) - ( qay * qbx );
		w = ( qaw * qbw ) - ( qax * qbx ) - ( qay * qby ) - ( qaz * qbz );

		return this;
	}

	/// Computes the shortest angle between two rotation defined by this quaternion and the given one.
	double angleTo(Quaternion q ) {
		return 2 * math.acos( ( MathUtils.clamp( dot( q ), - 1, 1 ) ).abs() );
	}

	/// Transforms this rotation defined by this quaternion towards the target rotation
	/// defined by the given quaternion by the given angular step. The rotation will not overshoot.
	bool rotateTo(Quaternion q, double step, [double tolerance = 0.0001 ]) {
		final angle = angleTo( q );
		if ( angle < tolerance ) return true;

		final t = math.min( 1, step / angle ).toDouble();
		slerp( q, t );

		return false;
	}

	/// Creates a quaternion that orients an object to face towards a specified target direction.
	Quaternion lookAt(Vector3 localForward, Vector3 targetDirection, Vector3 localUp ) {
		matrix.lookAt( localForward, targetDirection, localUp );
		fromMatrix3( matrix );
    return this;
	}

	/// Spherically interpolates between this quaternion and the given quaternion by t.
	/// The parameter t is clamped to the range [0, 1].
	Quaternion slerp(Quaternion  q, double t ) {
		if ( t == 0 ) return this;
		if ( t == 1 ) return copy( q );

		final x = this.x, y = this.y, z = this.z, w = this.w;

		double cosHalfTheta = w * q.w + x * q.x + y * q.y + z * q.z;

		if ( cosHalfTheta < 0 ) {
			this.w = - q.w;
			this.x = - q.x;
			this.y = - q.y;
			this.z = - q.z;

			cosHalfTheta = - cosHalfTheta;
		} 
    else {
			copy( q );
		}

		if ( cosHalfTheta >= 1.0 ) {
			this.w = w;
			this.x = x;
			this.y = y;
			this.z = z;

			return this;
		}

		final sinHalfTheta = math.sqrt( 1.0 - cosHalfTheta * cosHalfTheta );

		if ( sinHalfTheta.abs() < 0.001 ) {
			this.w = 0.5 * ( w + this.w );
			this.x = 0.5 * ( x + this.x );
			this.y = 0.5 * ( y + this.y );
			this.z = 0.5 * ( z + this.z );

			return this;
		}

		final halfTheta = math.atan2( sinHalfTheta, cosHalfTheta );
		final ratioA = math.sin( ( 1 - t ) * halfTheta ) / sinHalfTheta;
		final ratioB = math.sin( t * halfTheta ) / sinHalfTheta;

		this.w = ( w * ratioA ) + ( this.w * ratioB );
		this.x = ( x * ratioA ) + ( this.x * ratioB );
		this.y = ( y * ratioA ) + ( this.y * ratioB );
		this.z = ( z * ratioA ) + ( this.z * ratioB );

		return this;
	}

	/// Extracts the rotation of the given 4x4 matrix and stores it in this quaternion.
	Quaternion extractRotationFromMatrix(Matrix4 m ) {
		final e = matrix.elements;
		final me = m.elements;

		// remove scaling from the 3x3 portion
		final sx = 1 / vector.fromMatrix4Column( m, 0 ).length;
		final sy = 1 / vector.fromMatrix4Column( m, 1 ).length;
		final sz = 1 / vector.fromMatrix4Column( m, 2 ).length;

		e[ 0 ] = me[ 0 ] * sx;
		e[ 1 ] = me[ 1 ] * sx;
		e[ 2 ] = me[ 2 ] * sx;

		e[ 3 ] = me[ 4 ] * sy;
		e[ 4 ] = me[ 5 ] * sy;
		e[ 5 ] = me[ 6 ] * sy;

		e[ 6 ] = me[ 8 ] * sz;
		e[ 7 ] = me[ 9 ] * sz;
		e[ 8 ] = me[ 10 ] * sz;

		fromMatrix3( matrix );

		return this;
	}

	/// Sets the components of this quaternion from the given euler angle (YXZ order).
	Quaternion fromEuler(double x, double y, double z ) {
		// from 3D Math Primer for Graphics and Game Development
		// 8.7.5 Converting Euler Angles to a Quaternion

		// assuming YXZ (head/pitch/bank or yaw/pitch/roll) order

		final c1 = math.cos( y / 2 );
		final c2 = math.cos( x / 2 );
		final c3 = math.cos( z / 2 );

		final s1 = math.sin( y / 2 );
		final s2 = math.sin( x / 2 );
		final s3 = math.sin( z / 2 );

		w = c1 * c2 * c3 + s1 * s2 * s3;
		this.x = c1 * s2 * c3 + s1 * c2 * s3;
		this.y = s1 * c2 * c3 - c1 * s2 * s3;
		this.z = c1 * c2 * s3 - s1 * s2 * c3;

		return this;
	}

	/**
	* Returns an euler angel (YXZ order) representation of this quaternion.
	*
	* @param {Object} euler - The resulting euler angles.
	* @return {Object} The resulting euler angles.
	*/
	toEuler( euler ) {
		// from 3D Math Primer for Graphics and Game Development
		// 8.7.6 Converting a Quaternion to Euler Angles

		// extract pitch
		final sp = - 2 * ( y * z - x * w );

		// check for gimbal lock
		if ( sp.abs() > 0.9999 ) {
			// looking straight up or down
			euler.x = math.pi * 0.5 * sp;
			euler.y = math.atan2( x * z + w * y, 0.5 - x * x - y * y );
			euler.z = 0;
		} 
    else { //todo test
			euler.x = math.asin( sp );
			euler.y = math.atan2( x * z + w * y, 0.5 - x * x - y * y );
			euler.z = math.atan2( x * y + w * z, 0.5 - x * x - z * z );
		}

		return euler;
	}

	/// Sets the components of this quaternion from the given 3x3 rotation matrix.
	Quaternion fromMatrix3(Matrix3 m ) {
		final e = m.elements;

		final m11 = e[ 0 ], m12 = e[ 3 ], m13 = e[ 6 ];
		final m21 = e[ 1 ], m22 = e[ 4 ], m23 = e[ 7 ];
		final m31 = e[ 2 ], m32 = e[ 5 ], m33 = e[ 8 ];

		final trace = m11 + m22 + m33;

		if ( trace > 0 ) {
			double s = 0.5 / math.sqrt( trace + 1.0 );

			w = 0.25 / s;
			x = ( m32 - m23 ) * s;
			y = ( m13 - m31 ) * s;
			z = ( m21 - m12 ) * s;
		}
    else if ( ( m11 > m22 ) && ( m11 > m33 ) ) {
			double s = 2.0 * math.sqrt( 1.0 + m11 - m22 - m33 );

			w = ( m32 - m23 ) / s;
			x = 0.25 * s;
			y = ( m12 + m21 ) / s;
			z = ( m13 + m31 ) / s;
		} 
    else if ( m22 > m33 ) {
			double s = 2.0 * math.sqrt( 1.0 + m22 - m11 - m33 );

			w = ( m13 - m31 ) / s;
			x = ( m12 + m21 ) / s;
			y = 0.25 * s;
			z = ( m23 + m32 ) / s;
		} 
    else {
			double s = 2.0 * math.sqrt( 1.0 + m33 - m11 - m22 );

			w = ( m21 - m12 ) / s;
			x = ( m13 + m31 ) / s;
			y = ( m23 + m32 ) / s;
			z = 0.25 * s;
		}

		return this;
	}

	/// Sets the components of this quaternion from an array.
	Quaternion fromArray(List<double> array, [int offset = 0 ]) {
		x = array[ offset + 0 ];
		y = array[ offset + 1 ];
		z = array[ offset + 2 ];
		w = array[ offset + 3 ];

		return this;
	}

	/// Copies all values of this quaternion to the given array.
	List<double> toArray(List<double> array,[int offset = 0 ]) {
		array[ offset + 0 ] = x;
		array[ offset + 1 ] = y;
		array[ offset + 2 ] = z;
		array[ offset + 3 ] = w;

		return array;
	}

	/// Returns true if the given quaternion is deep equal with this quaternion.
	bool equals(Quaternion q ) {
		return ( ( q.x == x ) && ( q.y == y ) && ( q.z == z ) && ( q.w == w ) );
	}
}
