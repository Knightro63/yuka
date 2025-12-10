import 'dart:typed_data';
import '../constants.dart';
import 'math_utils.dart';
import 'matrix4.dart';
import 'quaternion.dart';
import 'vector3.dart';
import 'dart:math' as math;

final m1 = Matrix3();
final m2 = Matrix3();

final localRight = Vector3();
final worldRight = Vector3();
final perpWorldUp = Vector3();
final temp = Vector3();

final colVal = [ 2, 2, 1 ];
final rowVal = [ 1, 0, 0 ];

/// Class representing a 3x3 matrix. The elements of the matrix
/// are stored in column-major order.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Matrix3 {
  final Float32List elements = Float32List.fromList([
    1, 0, 0,
    0, 1, 0,
    0, 0, 1
  ]);

	/// Sets the given values to this matrix. The arguments are in row-major order.
	Matrix3 set(double n11, double n12, double n13, double n21, double n22, double n23, double n31, double n32, double n33 ) {
		final e = elements;

		e[ 0 ] = n11; e[ 3 ] = n12; e[ 6 ] = n13;
		e[ 1 ] = n21; e[ 4 ] = n22; e[ 7 ] = n23;
		e[ 2 ] = n31; e[ 5 ] = n32; e[ 8 ] = n33;

		return this;
	}

	/// Copies all values from the given matrix to this matrix.
	Matrix3 copy(Matrix3 m ) {
		final e = elements;
		final me = m.elements;

		e[ 0 ] = me[ 0 ]; e[ 1 ] = me[ 1 ]; e[ 2 ] = me[ 2 ];
		e[ 3 ] = me[ 3 ]; e[ 4 ] = me[ 4 ]; e[ 5 ] = me[ 5 ];
		e[ 6 ] = me[ 6 ]; e[ 7 ] = me[ 7 ]; e[ 8 ] = me[ 8 ];

		return this;
	}

	// Creates a new matrix and copies all values from this matrix.
	Matrix3 clone() {
		return Matrix3().copy( this );
	}

	/// Transforms this matrix to an identity matrix.
	Matrix3 identity() {
		set(
			1, 0, 0,
			0, 1, 0,
			0, 0, 1
		);

		return this;
	}

	/// Multiplies this matrix with the given matrix.
	Matrix3 multiply(Matrix3 m ) {
		return multiplyMatrices( this, m );
	}

	/// Multiplies this matrix with the given matrix.
	/// So the order of the multiplication is switched compared to {@link Matrix3#multiply}.
	Matrix3 premultiply(Matrix3 m ) {
		return multiplyMatrices( m, this );
	}

	/// Multiplies two given matrices and stores the result in this matrix.
	Matrix3 multiplyMatrices(Matrix3 a, Matrix3 b ) {
		final ae = a.elements;
		final be = b.elements;
		final e = elements;

		final a11 = ae[ 0 ], a12 = ae[ 3 ], a13 = ae[ 6 ];
		final a21 = ae[ 1 ], a22 = ae[ 4 ], a23 = ae[ 7 ];
		final a31 = ae[ 2 ], a32 = ae[ 5 ], a33 = ae[ 8 ];

		final b11 = be[ 0 ], b12 = be[ 3 ], b13 = be[ 6 ];
		final b21 = be[ 1 ], b22 = be[ 4 ], b23 = be[ 7 ];
		final b31 = be[ 2 ], b32 = be[ 5 ], b33 = be[ 8 ];

		e[ 0 ] = a11 * b11 + a12 * b21 + a13 * b31;
		e[ 3 ] = a11 * b12 + a12 * b22 + a13 * b32;
		e[ 6 ] = a11 * b13 + a12 * b23 + a13 * b33;

		e[ 1 ] = a21 * b11 + a22 * b21 + a23 * b31;
		e[ 4 ] = a21 * b12 + a22 * b22 + a23 * b32;
		e[ 7 ] = a21 * b13 + a22 * b23 + a23 * b33;

		e[ 2 ] = a31 * b11 + a32 * b21 + a33 * b31;
		e[ 5 ] = a31 * b12 + a32 * b22 + a33 * b32;
		e[ 8 ] = a31 * b13 + a32 * b23 + a33 * b33;

		return this;
	}

	/// Multiplies the given scalar with this matrix.
	Matrix3 multiplyScalar(double s ) {
		final e = elements;

		e[ 0 ] *= s; e[ 3 ] *= s; e[ 6 ] *= s;
		e[ 1 ] *= s; e[ 4 ] *= s; e[ 7 ] *= s;
		e[ 2 ] *= s; e[ 5 ] *= s; e[ 8 ] *= s;

		return this;
	}

	/// Extracts the basis vectors and stores them to the given vectors.
	Matrix3 extractBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis ) {
		xAxis.fromMatrix3Column( this, 0 );
		yAxis.fromMatrix3Column( this, 1 );
		zAxis.fromMatrix3Column( this, 2 );

		return this;
	}

	/// Makes a basis from the given vectors.
	Matrix3 makeBasis(Vector3 xAxis, Vector3 yAxis, Vector3 zAxis ) {
		set(
			xAxis.x, yAxis.x, zAxis.x,
			xAxis.y, yAxis.y, zAxis.y,
			xAxis.z, yAxis.z, zAxis.z
		);

		return this;
	}

	/// Creates a rotation matrix that orients an object to face towards a specified target direction.
	Matrix3 lookAt(Vector3 localForward, Vector3 targetDirection, Vector3 localUp ) {
		localRight.crossVectors( localUp, localForward ).normalize();

		// orthonormal linear basis A { localRight, localUp, localForward } for the object local space
		worldRight.crossVectors( WorldUp, targetDirection ).normalize();

		if ( worldRight.squaredLength == 0 ) {
			// handle case when it's not possible to build a basis from targetDirection and worldUp
			// slightly shift targetDirection in order to avoid collinearity

			temp.copy( targetDirection ).addScalar( MathUtils.epsilon );
			worldRight.crossVectors( WorldUp, temp ).normalize();
		}

		perpWorldUp.crossVectors( targetDirection, worldRight ).normalize();

		// orthonormal linear basis B { worldRight, perpWorldUp, targetDirection } for the desired target orientation
		m1.makeBasis( worldRight, perpWorldUp, targetDirection );
		m2.makeBasis( localRight, localUp, localForward );

		// finalruct a matrix that maps basis A to B
		multiplyMatrices( m1, m2.transpose() );

		return this;
	}

	/// Transposes this matrix.
	Matrix3 transpose() {
		final e = elements;
		double t;

		t = e[ 1 ]; e[ 1 ] = e[ 3 ]; e[ 3 ] = t;
		t = e[ 2 ]; e[ 2 ] = e[ 6 ]; e[ 6 ] = t;
		t = e[ 5 ]; e[ 5 ] = e[ 7 ]; e[ 7 ] = t;

		return this;
	}

	/// Computes the element index according to the given column and row.
	int getElementIndex(int column, int row ) {
		return column * 3 + row;
	}

	/// Computes the frobenius norm. It's the squareroot of the sum of all
	/// squared matrix elements.
	double frobeniusNorm() {
		final e = elements;
		double norm = 0;

		for ( int i = 0; i < 9; i ++ ) {
			norm += e[ i ] * e[ i ];
		}

		return math.sqrt( norm );
	}

	/// Computes the  "off-diagonal" frobenius norm. Assumes the matrix is symmetric.
	double offDiagonalFrobeniusNorm() {
		final e = elements;
		double norm = 0;

		for ( int i = 0; i < 3; i ++ ) {
			final t = e[ getElementIndex( colVal[ i ], rowVal[ i ] ) ];
			norm += 2 * t * t; // multiply the result by two since the matrix is symetric
		}

		return math.sqrt( norm );
	}

	/// Computes the eigenvectors and eigenvalues.
	///
	/// Reference: https://github.com/AnalyticalGraphicsInc/cesium/blob/411a1afbd36b72df64d7362de6aa934730447234/Source/Core/Matrix3.js#L1141 (Apache License 2.0)
	///
	/// The values along the diagonal of the diagonal matrix are the eigenvalues.
	/// The columns of the unitary matrix are the corresponding eigenvectors.
	Map<String,dynamic> eigenDecomposition(Map<String,dynamic> result ) {
		int count = 0;
		double sweep = 0;

		final double maxSweeps = 10;

		result['unitary'].identity();
		result['diagonal'].copy( this );

		final Matrix3 unitaryMatrix = result['unitary'];
		final Matrix3 diagonalMatrix = result['diagonal'];
		final epsilon = MathUtils.epsilon * diagonalMatrix.frobeniusNorm();

		while ( sweep < maxSweeps && diagonalMatrix.offDiagonalFrobeniusNorm() > epsilon ) {
			diagonalMatrix.shurDecomposition( m1 );
			m2.copy( m1 ).transpose();
			diagonalMatrix.multiply( m1 );
			diagonalMatrix.premultiply( m2 );
			unitaryMatrix.multiply( m1 );

			if ( ++ count > 2 ) {
				sweep ++;
				count = 0;
			}
		}

		return result;
	}

	/// Finds the largest off-diagonal term and then creates a matrix
	/// which can be used to help reduce it.
	Matrix3 shurDecomposition(Matrix3 result ) {
		double maxDiagonal = 0;
		int rotAxis = 1;

		// find pivot (rotAxis) based on largest off-diagonal term
		final e = elements;

		for ( int i = 0; i < 3; i ++ ) {
			final t = ( e[ getElementIndex( colVal[ i ], rowVal[ i ] ) ] ).abs();

			if ( t > maxDiagonal ) {
				maxDiagonal = t;
				rotAxis = i;
			}
		}

		double c = 1;
		double s = 0;

		final p = rowVal[ rotAxis ];
		final q = colVal[ rotAxis ];

		if ( ( e[ getElementIndex( q, p ) ] ).abs() > MathUtils.epsilon ) {

			final qq = e[ getElementIndex( q, q ) ];
			final pp = e[ getElementIndex( p, p ) ];
			final qp = e[ getElementIndex( q, p ) ];

			final tau = ( qq - pp ) / 2 / qp;

			double t;

			if ( tau < 0 ) {
				t = - 1 / ( - tau + math.sqrt( 1 + tau * tau ) );
			} 
      else {
				t = 1 / ( tau + math.sqrt( 1.0 + tau * tau ) );
			}

			c = 1.0 / math.sqrt( 1.0 + t * t );
			s = t * c;
		}

		result.identity();

		result.elements[ getElementIndex( p, p ) ] = c;
		result.elements[ getElementIndex( q, q ) ] = c;
		result.elements[ getElementIndex( q, p ) ] = s;
		result.elements[ getElementIndex( p, q ) ] = - s;

		return result;
	}

	/// Creates a rotation matrix from the given quaternion.
	Matrix3 fromQuaternion(Quaternion q ) {
		final e = elements;

		final x = q.x, y = q.y, z = q.z, w = q.w;
		final x2 = x + x, y2 = y + y, z2 = z + z;
		final xx = x * x2, xy = x * y2, xz = x * z2;
		final yy = y * y2, yz = y * z2, zz = z * z2;
		final wx = w * x2, wy = w * y2, wz = w * z2;

		e[ 0 ] = 1 - ( yy + zz );
		e[ 3 ] = xy - wz;
		e[ 6 ] = xz + wy;

		e[ 1 ] = xy + wz;
		e[ 4 ] = 1 - ( xx + zz );
		e[ 7 ] = yz - wx;

		e[ 2 ] = xz - wy;
		e[ 5 ] = yz + wx;
		e[ 8 ] = 1 - ( xx + yy );

		return this;
	}

	/// Sets the elements of this matrix by extracting the upper-left 3x3 portion
	/// from a 4x4 matrix.
	Matrix3 fromMatrix4(Matrix4 m ) {
		final e = elements;
		final me = m.elements;

		e[ 0 ] = me[ 0 ]; e[ 1 ] = me[ 1 ]; e[ 2 ] = me[ 2 ];
		e[ 3 ] = me[ 4 ]; e[ 4 ] = me[ 5 ]; e[ 5 ] = me[ 6 ];
		e[ 6 ] = me[ 8 ]; e[ 7 ] = me[ 9 ]; e[ 8 ] = me[ 10 ];

		return this;
	}

	/// Sets the elements of this matrix from an array.
	Matrix3 fromArray(List<double> array, [int offset = 0 ]) {
		final e = elements;

		for ( int i = 0; i < 9; i ++ ) {
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

		return array;
	}

	/// Returns true if the given matrix is deep equal with this matrix.
	bool equals(Matrix3 m ) {
		final e = elements;
		final me = m.elements;

		for ( int i = 0; i < 9; i ++ ) {
			if ( e[ i ] != me[ i ] ) return false;
		}

		return true;
	}
}


