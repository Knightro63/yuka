import 'dart:math' as math;
import 'dart:typed_data';
import 'math_utils.dart';
import 'matrix3.dart';
import 'matrix4.dart';
import 'quaternion.dart';

/// Class representing a 3D vector.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Vector3 {
  double get x => storage[0];
  set x(double value) => storage[0] = value;

  double get y => storage[1];
  set y(double value) => storage[1] = value;
  
  double get z => storage[2];
  set z(double value) => storage[2] = value;

  final Float32List storage = Float32List(3);

  double operator [](int i) => storage[i];
  void operator []=(int i, double v) {
    if(i == 0) x = v;
    if(i == 1) y = v;
    if(i == 2) z = v;
  }

	/// Constructs a new 3D vector with the given values.
  Vector3([double? x, double? y, double? z]) {
    this.x = x ?? 0;
    this.y = y ?? 0;
    this.z = z ?? 0;
  }

	/// Sets the given values to this 3D vector.
	Vector3 set(double x, double y, double z ) {
		this.x = x;
		this.y = y;
		this.z = z;

		return this;
	}

	/// Copies all values from the given 3D vector to this 3D vector.
	Vector3 copy(Vector3 v ) {
		x = v.x;
		y = v.y;
		z = v.z;

		return this;
	}

	/// Creates a new 3D vector and copies all values from this 3D vector.
	Vector3 clone() {
		return Vector3().copy( this );
	}

	/// Adds the given 3D vector to this 3D vector.
	Vector3 add(Vector3 v ) {
		x += v.x;
		y += v.y;
		z += v.z;

		return this;
	}

	/// Adds the given scalar to this 3D vector.
	Vector3 addScalar(double s ) {
		x += s;
		y += s;
		z += s;

		return this;
	}

	/// Adds two given 3D vectors and stores the result in this 3D vector.
	Vector3 addVectors(Vector3 a, Vector3 b ) {
		x = a.x + b.x;
		y = a.y + b.y;
		z = a.z + b.z;

		return this;
	}

	/// Subtracts the given 3D vector from this 3D vector.
	Vector3 sub(Vector3 v ) {
		x -= v.x;
		y -= v.y;
		z -= v.z;

		return this;
	}

	/// Subtracts the given scalar from this 3D vector.
	Vector3 subScalar(double s ) {
		x -= s;
		y -= s;
		z -= s;

		return this;
	}

	/// Subtracts two given 3D vectors and stores the result in this 3D vector.
	Vector3 subVectors(Vector3 a, Vector3 b ) {
		x = a.x - b.x;
		y = a.y - b.y;
		z = a.z - b.z;

		return this;
	}

	/// Multiplies the given 3D vector with this 3D vector.
	Vector3 multiply(Vector3 v ) {
		x *= v.x;
		y *= v.y;
		z *= v.z;

		return this;
	}

	/// Multiplies the given scalar with this 3D vector.
	Vector3 multiplyScalar(double s ) {
		x *= s;
		y *= s;
		z *= s;

		return this;
	}

	/// Multiplies two given 3D vectors and stores the result in this 3D vector.
	Vector3 multiplyVectors(Vector3 a, Vector3 b ) {
		x = a.x * b.x;
		y = a.y * b.y;
		z = a.z * b.z;

		return this;
	}

	/// Divides the given 3D vector through this 3D vector.
	Vector3 divide(Vector3 v ) {
		x /= v.x;
		y /= v.y;
		z /= v.z;

		return this;
	}

	/// Divides the given scalar through this 3D vector.
	Vector3 divideScalar(double s ) {
		x /= s;
		y /= s;
		z /= s;

		return this;
	}

	/// Divides two given 3D vectors and stores the result in this 3D vector.
	Vector3 divideVectors(Vector3 a, Vector3 b ) {
		x = a.x / b.x;
		y = a.y / b.y;
		z = a.z / b.z;

		return this;
	}

	/// Reflects this vector along the given normal.
	Vector3 reflect( Vector3 normal ) {
		// solve r = v - 2( v * n ) * n
		return sub( Vector3().copy( normal ).multiplyScalar( 2 * dot( normal ) ) );
	}

	/// Ensures this 3D vector lies in the given min/max range.
	Vector3 clamp(Vector3 min, Vector3 max ) {
		x = math.max( min.x, math.min( max.x, x ) );
		y = math.max( min.y, math.min( max.y, y ) );
		z = math.max( min.z, math.min( max.z, z ) );

		return this;
	}

	/// Compares each vector component of this 3D vector and the
	/// given one and stores the minimum value in this instance.
	Vector3 min(Vector3 v ) {
		x = math.min( x, v.x );
		y = math.min( y, v.y );
		z = math.min( z, v.z );

		return this;
	}

	/// Compares each vector component of this 3D vector and the
	/// given one and stores the maximum value in this instance.
	Vector3 max(Vector3 v ) {
		x = math.max( x, v.x );
		y = math.max( y, v.y );
		z = math.max( z, v.z );

		return this;
	}

	/// Computes the dot product of this and the given 3D vector.
	double dot(Vector3 v ) {
		return ( x * v.x ) + ( y * v.y ) + ( z * v.z );
	}

	/// Computes the cross product of this and the given 3D vector and
	/// stores the result in this 3D vector.
	Vector3 cross(Vector3 v ) {
		final x = this.x, y = this.y, z = this.z;

		this.x = ( y * v.z ) - ( z * v.y );
		this.y = ( z * v.x ) - ( x * v.z );
		this.z = ( x * v.y ) - ( y * v.x );

		return this;
	}

	/// Computes the cross product of the two given 3D vectors and
	/// stores the result in this 3D vector.
	Vector3 crossVectors(Vector3 a, Vector3 b ) {
		final ax = a.x, ay = a.y, az = a.z;
		final bx = b.x, by = b.y, bz = b.z;

		x = ( ay * bz ) - ( az * by );
		y = ( az * bx ) - ( ax * bz );
		z = ( ax * by ) - ( ay * bx );

		return this;
	}

	/// Computes the angle between this and the given vector.
	double angleTo(Vector3 v ) {
		final denominator = math.sqrt( squaredLength * v.squaredLength );

		if ( denominator == 0 ) return 0;

		final theta = dot( v ) / denominator;

		// clamp, to handle numerical problems
		return math.acos( MathUtils.clamp( theta, - 1, 1 ) );
	}

	/// Computes the length of this 3D vector.
	double get length => math.sqrt( squaredLength );

	/// Computes the squared length of this 3D vector.
	/// Calling this method is faster than calling {@link Vector3#length},
	/// since it avoids computing a square root.
	double get squaredLength => dot( this );
	

	/// Computes the manhattan length of this 3D vector.
	double get manhattanLength => x.abs() + y.abs() + z.abs();

	/// Computes the euclidean distance between this 3D vector and the given one.
	double distanceTo(Vector3 v ) {
		return math.sqrt( squaredDistanceTo( v ) );
	}

	/// Computes the squared euclidean distance between this 3D vector and the given one.
	/// Calling this method is faster than calling {@link Vector3#distanceTo},
	/// since it avoids computing a square root.
	double squaredDistanceTo(Vector3 v ) {
		final dx = x - v.x, dy = y - v.y, dz = z - v.z;
		return ( dx * dx ) + ( dy * dy ) + ( dz * dz );
	}

	/// Computes the manhattan distance between this 3D vector and the given one.
	double manhattanDistanceTo(Vector3 v ) {
		final dx = x - v.x, dy = y - v.y, dz = z - v.z;
		return dx.abs() + dy.abs() + dz.abs();
	}

	/// Normalizes this 3D vector.
	Vector3 normalize() {
		return divideScalar( length == 0 ? 1 : length );
	}

	/// Multiplies the given 4x4 matrix with this 3D vector
	Vector3 applyMatrix4(Matrix4 m ) {
		final x = this.x, y = this.y, z = this.z;
		final e = m.elements;

		final w = 1 / ( ( e[ 3 ] * x ) + ( e[ 7 ] * y ) + ( e[ 11 ] * z ) + e[ 15 ] );

		this.x = ( ( e[ 0 ] * x ) + ( e[ 4 ] * y ) + ( e[ 8 ] * z ) + e[ 12 ] ) * w;
		this.y = ( ( e[ 1 ] * x ) + ( e[ 5 ] * y ) + ( e[ 9 ] * z ) + e[ 13 ] ) * w;
		this.z = ( ( e[ 2 ] * x ) + ( e[ 6 ] * y ) + ( e[ 10 ] * z ) + e[ 14 ] ) * w;

		return this;
	}

	/// Multiplies the given quaternion with this 3D vector.
	Vector3 applyRotation(Quaternion q ) {
		final x = this.x, y = this.y, z = this.z;
		final qx = q.x, qy = q.y, qz = q.z, qw = q.w;

		// calculate quat * vector
		final ix = qw * x + qy * z - qz * y;
		final iy = qw * y + qz * x - qx * z;
		final iz = qw * z + qx * y - qy * x;
		final iw = - qx * x - qy * y - qz * z;

		// calculate result * inverse quat
		this.x = ix * qw + iw * - qx + iy * - qz - iz * - qy;
		this.y = iy * qw + iw * - qy + iz * - qx - ix * - qz;
		this.z = iz * qw + iw * - qz + ix * - qy - iy * - qx;

		return this;
	}

	/// Extracts the position portion of the given 4x4 matrix and stores it in this 3D vector.
	Vector3 extractPositionFromMatrix(Matrix4 m ) {
		final e = m.elements;

		x = e[ 12 ];
		y = e[ 13 ];
		z = e[ 14 ];

		return this;
	}

	/// Transform this direction vector by the given 4x4 matrix.
	Vector3 transformDirection(Matrix4 m ) {
		final x = this.x, y = this.y, z = this.z;
		final e = m.elements;

		this.x = e[ 0 ] * x + e[ 4 ] * y + e[ 8 ] * z;
		this.y = e[ 1 ] * x + e[ 5 ] * y + e[ 9 ] * z;
		this.z = e[ 2 ] * x + e[ 6 ] * y + e[ 10 ] * z;

		return normalize();
	}

	/// Sets the components of this 3D vector from a column of a 3x3 matrix.
	Vector3 fromMatrix3Column(Matrix3  m, int i ) {
		return fromArray( m.elements, i * 3 );
	}

	/// Sets the components of this 3D vector from a column of a 4x4 matrix.
	Vector3 fromMatrix4Column(Matrix4 m, int i ) {
		return fromArray( m.elements, i * 4 );
	}

	/// Sets the components of this 3D vector from a spherical coordinate.
	Vector3 fromSpherical(double radius, double phi, double theta ) {
		final sinPhiRadius = math.sin( phi ) * radius;

		x = sinPhiRadius * math.sin( theta );
		y = math.cos( phi ) * radius;
		z = sinPhiRadius * math.cos( theta );

		return this;
	}

	/// Sets the components of this 3D vector from an array.
	Vector3 fromArray(List<double> array, [int offset = 0 ]) {
		x = array[ offset + 0 ];
		y = array[ offset + 1 ];
		z = array[ offset + 2 ];

		return this;
	}

	Vector3 fromUnknown(List array, [int offset = 0 ]) {
		x = array[ offset + 0 ].toDouble();
		y = array[ offset + 1 ].toDouble();
		z = array[ offset + 2 ].toDouble();

		return this;
	}

	/// Copies all values of this 3D vector to the given array.
	List<double> toArray(List<double> array, [int offset = 0] ) {
		array[ offset + 0 ] = x;
		array[ offset + 1 ] = y;
		array[ offset + 2 ] = z;

		return array;
	}

	/// Returns true if the given 3D vector is deep equal with this 3D vector.
	bool equals(Vector3 v ) {
		return ( ( v.x == x ) && ( v.y == y ) && ( v.z == z ) );
	}
}
