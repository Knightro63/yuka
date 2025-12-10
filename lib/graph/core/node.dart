import 'package:yuka/math/vector3.dart';

/// Base class for graph nodes.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class Node {
  int index;
  late final Vector3 position;
	
	/// Constructs a new node.
	Node([ this.index = - 1, Vector3? position]){
    this.position = position ?? Vector3();
  }

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString(),
			'index': index
		};
	}

	/// Restores this instance from the given JSON object.
	Node fromJSON(Map<String,dynamic> json ) {
		index = json['index'];
		return this;
	}
}
