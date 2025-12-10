import '../../graph/core/node.dart';

/// Class for representing navigation nodes.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class NavNode extends Node {
  late final Map<String,dynamic> userData;

	/// Constructs a new navigation node.
	NavNode([ super.index = - 1, super.position, Map<String,dynamic>? userData]) {
		this.userData = userData ?? {};
	}
}
