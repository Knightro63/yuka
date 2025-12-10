import 'polygon.dart';
import 'vector3.dart';

/// Implementation of a half-edge data structure, also known as
/// { @link https://en.wikipedia.org/wiki/Doubly_connected_edge_list Doubly connected edge list}.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class HalfEdge {
  late final Vector3 vertex;
  HalfEdge? next;
  HalfEdge? prev;
  HalfEdge? twin;
  Polygon? polygon;

	/// Constructs a new half-edge.
	HalfEdge([Vector3? vertex] ) {
		this.vertex = vertex ?? Vector3();
	}

	/// Returns the tail of this half-edge. That's a reference to the previous
	/// half-edge vertex.
	Vector3? tail() {
		return prev?.vertex;
	}

	/// Returns the head of this half-edge. That's a reference to the own vertex.
	Vector3 head() {
		return vertex;
	}

	/// Computes the length of this half-edge.
	double length() {
		final tail = this.tail();
		final head = this.head();

		if ( tail != null ) {
			return tail.distanceTo( head );
		}

		return - 1;
	}

	/// Computes the squared length of this half-edge.
	double squaredLength() {
		final tail = this.tail();
		final head = this.head();

		if ( tail != null ) {
			return tail.squaredDistanceTo( head );
		}

		return - 1;
	}

	/// Links the given opponent half edge with this one.
	HalfEdge linkOpponent(HalfEdge? edge ) {
		twin = edge;
		edge?.twin = this;
		return this;
	}

	/// Computes the direction of this half edge. The method assumes the half edge
	/// has a valid reference to a previous half edge.
	Vector3 getDirection(Vector3 result ) {
		return result.subVectors( vertex, prev!.vertex ).normalize();
	}
}
