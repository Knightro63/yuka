
/// Base class for graph edges.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Edge {
  int from;
  int to;
  double cost;

	/// Constructs a new edge.
	Edge( [this.from = - 1, this.to = - 1, this.cost = 0] );

	/// Copies all values from the given edge to this edge.
	Edge copy(Edge edge ) {
		from = edge.from;
		to = edge.to;
		cost = edge.cost;

		return this;
	}

	/// Creates a new edge and copies all values from this edge.
	Edge clone() {
		return Edge().copy( this );
	}

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'from': from,
			'to': to,
			'cost': cost
		};
	}

	/// Restores this instance from the given JSON object.
	Edge fromJSON(Map<String,dynamic> json ) {
		from = json['from'];
		to = json['to'];
		cost = json['cost'];

		return this;
	}
}
