import 'dart:typed_data';
import 'dart:math' as math;
import 'matrix3.dart';
import 'quaternion.dart';
import 'vector3.dart';

/// Class representing a 4x4 matrix. The elements of the matrix
/// are stored in column-major order.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Matrix4 {
  Float32List elements = Float32List.fromList([
    1, 0, 0, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  ]);

	/// Sets the given values to this matrix. The arguments are in row-major order.
	Matrix4 set(double n11, double n12, double n13, double n14, double n21, double n22, double n23, double n24, double n31, double n32, double n33, double n34, double n41, double n42, double n43, double n44 ) {
		final e = elements;

		e[ 0 ] = n11; e[ 4 ] = n12; e[ 8 ] = n13; e[ 12 ] = n14;
		e[ 1 ] = n21; e[ 5 ] = n22; e[ 9 ] = n23; e[ 13 ] = n24;
		e[ 2 ] = n31; e[ 6 ] = n32; e[ 10 ] = n33; e[ 14 ] = n34;
		e[ 3 ] = n41; e[ 7 ] = n42; e[ 11 ] = n43; e[ 15 ] = n44;

		return this;
	}

	/// Copies all values from the given matrix to this matrix.
	Matrix4 copy(Matrix4 m ) {
		final e = elements;
		final me = m.elements;

		e[ 0 ] = me[ 0 ]; e[ 1 ] = me[ 1 ]; e[ 2 ] = me[ 2 ]; e[ 3 ] = me[ 3 ];
		e[ 4 ] = me[ 4 ]; e[ 5 ] = me[ 5 ]; e[ 6 ] = me[ 6 ]; e[ 7 ] = me[ 7 ];
		e[ 8 ] = me[ 8 ]; e[ 9 ] = me[ 9 ]; e[ 10 ] = me[ 10 ]; e[ 11 ] = me[ 11 ];
		e[ 12 ] = me[ 12 ]; e[ 13 ] = me[ 13 ]; e[ 14 ] = me[ 14 ]; e[ 15 ] = me[ 15 ];

		return this;
	}

	/// Creates a new matrix and copies all values from this matrix.
	Matrix4 clone() {
		return Matrix4().copy( this );
	}

	/// Transforms this matrix to an identity matrix.
	Matrix4 identity() {
		set(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		);

		return this;
	}

	/// Multiplies this matrix with the given matrix.
	Matrix4 multiply(Matrix4 m ) {
		return multiplyMatrices( this, m );
	}

	/// Multiplies this matrix with the given matrix.
	/// So the order of the multiplication is switched compared to {@link Matrix4#multiply}.
	Matrix4 premultiply(Matrix4 m ) {
		return multiplyMatrices( m, this );
	}

	/// Multiplies two given matrices and stores the result in this matrix.
	Matrix4 multiplyMatrices(Matrix4 a, Matrix4 b ) {
		final ae = a.elements;
		final be = b.elements;
		final e = elements;

		final a11 = ae[ 0 ], a12 = ae[ 4 ], a13 = ae[ 8 ], a14 = ae[ 12 ];
		final a21 = ae[ 1 ], a22 = ae[ 5 ], a23 = ae[ 9 ], a24 = ae[ 13 ];
		final a31 = ae[ 2 ], a32 = ae[ 6 ], a33 = ae[ 10 ], a34 = ae[ 14 ];
		final a41 = ae[ 3 ], a42 = ae[ 7 ], a43 = ae[ 11 ], a44 = ae[ 15 ];

		final b11 = be[ 0 ], b12 = be[ 4 ], b13 = be[ 8 ], b14 = be[ 12 ];
		final b21 = be[ 1 ], b22 = be[ 5 ], b23 = be[ 9 ], b24 = be[ 13 ];
		final b31 = be[ 2 ], b32 = be[ 6 ], b33 = be[ 10 ], b34 = be[ 14 ];
		final b41 = be[ 3 ], b42 = be[ 7 ], b43 = be[ 11 ], b44 = be[ 15 ];

		e[ 0 ] = ( a11 * b11 ) + ( a12 * b21 ) + ( a13 * b31 ) + ( a14 * b41 );
		e[ 4 ] = ( a11 * b12 ) + ( a12 * b22 ) + ( a13 * b32 ) + ( a14 * b42 );
		e[ 8 ] = ( a11 * b13 ) + ( a12 * b23 ) + ( a13 * b33 ) + ( a14 * b43 );
		e[ 12 ] = ( a11 * b14 ) + ( a12 * b24 ) + ( a13 * b34 ) + ( a14 * b44 );

		e[ 1 ] = ( a21 * b11 ) + ( a22 * b21 ) + ( a23 * b31 ) + ( a24 * b41 );
		e[ 5 ] = ( a21 * b12 ) + ( a22 * b22 ) + ( a23 * b32 ) + ( a24 * b42 );
		e[ 9 ] = ( a21 * b13 ) + ( a22 * b23 ) + ( a23 * b33 ) + ( a24 * b43 );
		e[ 13 ] = ( a21 * b14 ) + ( a22 * b24 ) + ( a23 * b34 ) + ( a24 * b44 );

		e[ 2 ] = ( a31 * b11 ) + ( a32 * b21 ) + ( a33 * b31 ) + ( a34 * b41 );
		e[ 6 ] = ( a31 * b12 ) + ( a32 * b22 ) + ( a33 * b32 ) + ( a34 * b42 );
		e[ 10 ] = ( a31 * b13 ) + ( a32 * b23 ) + ( a33 * b33 ) + ( a34 * b43 );
		e[ 14 ] = ( a31 * b14 ) + ( a32 * b24 ) + ( a33 * b34 ) + ( a34 * b44 );

		e[ 3 ] = ( a41 * b11 ) + ( a42 * b21 ) + ( a43 * b31 ) + ( a44 * b41 );
		e[ 7 ] = ( a41 * b12 ) + ( a42 * b22 ) + ( a43 * b32 ) + ( a44 * b42 );
		e[ 11 ] = ( a41 * b13 ) + ( a42 * b23 ) + ( a43 * b33 ) + ( a44 * b43 );
		e[ 15 ] = ( a41 * b14 ) + ( a42 * b24 ) + ( a43 * b34 ) + ( a44 * b44 );

		return this;
	}

	/// Multiplies the given scalar with this matrix.
	Matrix4 multiplyScalar(double s ) {
		final e = elements;

		e[ 0 ] *= s; e[ 4 ] *= s; e[ 8 ] *= s; e[ 12 ] *= s;
		e[ 1 ] *= s; e[ 5 ] *= s; e[ 9 ] *= s; e[ 13 ] *= s;
		e[ 2 ] *= s; e[ 6 ] *= s; e[ 10 ] *= s; e[ 14 ] *= s;
		e[ 3 ] *= s; e[ 7 ] *= s; e[ 11 ] *= s; e[ 15 ] *= s;

		return this;
	}

	/// Extracts the basis vectors and stores them to the given vectors.
	Matrix4 extractBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis ) {
		xAxis.fromMatrix4Column( this, 0 );
		yAxis.fromMatrix4Column( this, 1 );
		zAxis.fromMatrix4Column( this, 2 );

		return this;
	}

	/// Makes a basis from the given vectors.
	Matrix4 makeBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis ) {
		set(
			xAxis.x, yAxis.x, zAxis.x, 0,
			xAxis.y, yAxis.y, zAxis.y, 0,
			xAxis.z, yAxis.z, zAxis.z, 0,
			0, 0, 0, 1
		);

		return this;
	}

	/// Composes a matrix from the given position, quaternion and scale.
	Matrix4 compose(Vector3 position, Quaternion rotation, Vector3 scale ) {
		fromQuaternion( rotation );
		this.scale( scale );
		setPosition( position );

		return this;
	}

	/// Scales this matrix by the given 3D vector.
	Matrix4 scale(Vector3 v ) {
		final e = elements;
		final x = v.x, y = v.y, z = v.z;

		e[ 0 ] *= x; e[ 4 ] *= y; e[ 8 ] *= z;
		e[ 1 ] *= x; e[ 5 ] *= y; e[ 9 ] *= z;
		e[ 2 ] *= x; e[ 6 ] *= y; e[ 10 ] *= z;
		e[ 3 ] *= x; e[ 7 ] *= y; e[ 11 ] *= z;

		return this;
	}

	/// Sets the translation part of the 4x4 matrix to the given position vector.
	Matrix4 setPosition(Vector3 v ) {
		final e = elements;

		e[ 12 ] = v.x;
		e[ 13 ] = v.y;
		e[ 14 ] = v.z;

		return this;
	}

	/// Transposes this matrix.
	Matrix4 transpose() {
		final e = elements;
		double t;

		t = e[ 1 ]; e[ 1 ] = e[ 4 ]; e[ 4 ] = t;
		t = e[ 2 ]; e[ 2 ] = e[ 8 ]; e[ 8 ] = t;
		t = e[ 6 ]; e[ 6 ] = e[ 9 ]; e[ 9 ] = t;

		t = e[ 3 ]; e[ 3 ] = e[ 12 ]; e[ 12 ] = t;
		t = e[ 7 ]; e[ 7 ] = e[ 13 ]; e[ 13 ] = t;
		t = e[ 11 ]; e[ 11 ] = e[ 14 ]; e[ 14 ] = t;

		return this;
	}

	/// Computes the inverse of this matrix and stored the result in the given matrix.
	///
	/// You can not invert a matrix with a determinant of zero. If you attempt this, the method returns a zero matrix instead.
	Matrix4 getInverse(Matrix4 m ) {
		final e = elements;
		final me = m.elements;

		final n11 = e[ 0 ], n21 = e[ 1 ], n31 = e[ 2 ], n41 = e[ 3 ];
		final n12 = e[ 4 ], n22 = e[ 5 ], n32 = e[ 6 ], n42 = e[ 7 ];
		final n13 = e[ 8 ], n23 = e[ 9 ], n33 = e[ 10 ], n43 = e[ 11 ];
		final n14 = e[ 12 ], n24 = e[ 13 ], n34 = e[ 14 ], n44 = e[ 15 ];

		final t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44;
		final t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44;
		final t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44;
		final t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

		final det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;

		if ( det == 0 ) return m.set( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );

		final detInv = 1 / det;

		me[ 0 ] = t11 * detInv;
		me[ 1 ] = ( n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44 ) * detInv;
		me[ 2 ] = ( n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44 ) * detInv;
		me[ 3 ] = ( n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43 ) * detInv;

		me[ 4 ] = t12 * detInv;
		me[ 5 ] = ( n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44 ) * detInv;
		me[ 6 ] = ( n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44 ) * detInv;
		me[ 7 ] = ( n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43 ) * detInv;

		me[ 8 ] = t13 * detInv;
		me[ 9 ] = ( n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44 ) * detInv;
		me[ 10 ] = ( n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44 ) * detInv;
		me[ 11 ] = ( n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43 ) * detInv;

		me[ 12 ] = t14 * detInv;
		me[ 13 ] = ( n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34 ) * detInv;
		me[ 14 ] = ( n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34 ) * detInv;
		me[ 15 ] = ( n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33 ) * detInv;

		return m;
	}

	/// Computes the maximum scale value for all three axis.
	double getMaxScale() {
		final e = elements;

		final scaleXSq = e[ 0 ] * e[ 0 ] + e[ 1 ] * e[ 1 ] + e[ 2 ] * e[ 2 ];
		final scaleYSq = e[ 4 ] * e[ 4 ] + e[ 5 ] * e[ 5 ] + e[ 6 ] * e[ 6 ];
		final scaleZSq = e[ 8 ] * e[ 8 ] + e[ 9 ] * e[ 9 ] + e[ 10 ] * e[ 10 ];

		return math.sqrt( math.max( scaleXSq, math.max(scaleYSq, scaleZSq) ) );
	}

	/// Uses the given quaternion to transform the upper left 3x3 part to a rotation matrix.
	/// Other parts of the matrix are equal to the identiy matrix.
	Matrix4 fromQuaternion(Quaternion q ) {
		final e = elements;

		final x = q.x, y = q.y, z = q.z, w = q.w;
		final x2 = x + x, y2 = y + y, z2 = z + z;
		final xx = x * x2, xy = x * y2, xz = x * z2;
		final yy = y * y2, yz = y * z2, zz = z * z2;
		final wx = w * x2, wy = w * y2, wz = w * z2;

		e[ 0 ] = 1 - ( yy + zz );
		e[ 4 ] = xy - wz;
		e[ 8 ] = xz + wy;

		e[ 1 ] = xy + wz;
		e[ 5 ] = 1 - ( xx + zz );
		e[ 9 ] = yz - wx;

		e[ 2 ] = xz - wy;
		e[ 6 ] = yz + wx;
		e[ 10 ] = 1 - ( xx + yy );

		e[ 3 ] = 0;
		e[ 7 ] = 0;
		e[ 11 ] = 0;

		e[ 12 ] = 0;
		e[ 13 ] = 0;
		e[ 14 ] = 0;
		e[ 15 ] = 1;

		return this;
	}

	/// Sets the upper-left 3x3 portion of this matrix by the given 3x3 matrix. Other
	/// parts of the matrix are equal to the identiy matrix.
	Matrix4 fromMatrix3(Matrix3 m ) {
		final e = elements;
		final me = m.elements;

		e[ 0 ] = me[ 0 ];
		e[ 1 ] = me[ 1 ];
		e[ 2 ] = me[ 2 ];
		e[ 3 ] = 0;

		e[ 4 ] = me[ 3 ];
		e[ 5 ] = me[ 4 ];
		e[ 6 ] = me[ 5 ];
		e[ 7 ] = 0;

		e[ 8 ] = me[ 6 ];
		e[ 9 ] = me[ 7 ];
		e[ 10 ] = me[ 8 ];
		e[ 11 ] = 0;

		e[ 12 ] = 0;
		e[ 13 ] = 0;
		e[ 14 ] = 0;
		e[ 15 ] = 1;

		return this;
	}

	/// Sets the elements of this matrix from an array.
	Matrix4 fromArray(List<double> array, [int offset = 0 ]) {
		final e = elements;

		for ( int i = 0; i < 16; i ++ ) {
			e[ i ] = array[ i + offset ];
		}

		return this;
	}

	/// Copies all elements of this matrix to the given array.
	List<double> toArray(List<double> array, [int offset = 0 ]) {
		final e = elements;

		array[ offset + 0 ] = e[ 0 ];
		array[ offset + 1 ] = e[ 1 ];
		array[ offset + 2 ] = e[ 2 ];
		array[ offset + 3 ] = e[ 3 ];

		array[ offset + 4 ] = e[ 4 ];
		array[ offset + 5 ] = e[ 5 ];
		array[ offset + 6 ] = e[ 6 ];
		array[ offset + 7 ] = e[ 7 ];

		array[ offset + 8 ] = e[ 8 ];
		array[ offset + 9 ] = e[ 9 ];
		array[ offset + 10 ] = e[ 10 ];
		array[ offset + 11 ] = e[ 11 ];

		array[ offset + 12 ] = e[ 12 ];
		array[ offset + 13 ] = e[ 13 ];
		array[ offset + 14 ] = e[ 14 ];
		array[ offset + 15 ] = e[ 15 ];

		return array;
	}

	/// Returns true if the given matrix is deep equal with this matrix.
	bool equals(Matrix4 m ) {
		final e = elements;
		final me = m.elements;

		for (int i = 0; i < 16; i ++ ) {
			if ( e[ i ] != me[ i ] ) return false;
		}

		return true;
	}
}