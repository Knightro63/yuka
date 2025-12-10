import 'package:yuka/yuka.dart';

/// Base class for representing a term in a {@link FuzzyRule}.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
abstract class FuzzyTerm {
  String? _uuid;
	/// Unique ID, primarily used in context of serialization/deserialization.
	String? get uuid => _uuid ??= MathUtils.generateUUID();

	/// Clears the degree of membership value.
	FuzzyTerm clearDegreeOfMembership();

	/// Returns the degree of membership.
	double getDegreeOfMembership(){
    return 0;
  }

	/// Updates the degree of membership by the given value. This method is used when
	/// the term is part of a fuzzy rule's consequent.
	FuzzyTerm updateDegreeOfMembership(double value);

	/// Transforms this instance into a JSON object.
	Map<String,dynamic> toJSON() {
		return {
			'type': runtimeType.toString()
		};
	}

	/// Restores this instance from the given JSON object.
	FuzzyTerm fromJSON(Map<String,dynamic> json ) {
		_uuid = json['uuid'];
		return this;
	}
}
