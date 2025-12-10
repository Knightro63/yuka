import 'fuzzy_term.dart';

/// Base class for fuzzy sets. This type of sets are defined by a membership function
/// which can be any arbitrary shape but are typically triangular or trapezoidal. They define
/// a gradual transition from regions completely outside the set to regions completely
/// within the set, thereby enabling a value to have partial membership to a set.
///
/// This class is derived from {@link FuzzyTerm} so it can be directly used in fuzzy rules.
/// According to the composite design pattern, a fuzzy set can be considered as an atomic fuzzy term.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FuzzySet extends FuzzyTerm {
  double representativeValue;
  double degreeOfMembership = 0;
  double left = 0;
  double right = 0;

	/// Constructs a new fuzzy set with the given values.
	FuzzySet([ this.representativeValue = 0 ]):super();

	/// Computes the degree of membership for the given value. Notice that this method
	/// does not set {@link FuzzySet#degreeOfMembership} since other classes use it in
	/// order to calculate intermediate degree of membership values. This method be
	/// implemented by all concrete fuzzy set classes.
	double computeDegreeOfMembership(double value) {return 0;}

	// FuzzyTerm API

	/// Clears the degree of membership value.
  @override
	FuzzySet clearDegreeOfMembership() {
		degreeOfMembership = 0;
		return this;
	}

	/// Returns the degree of membership.
  @override
	double getDegreeOfMembership() {
		return degreeOfMembership;
	}

	/// Updates the degree of membership by the given value. This method is used when
	/// the set is part of a fuzzy rule's consequent.
  @override
	FuzzySet updateDegreeOfMembership(double value ) {
		// update the degree of membership if the given value is greater than the
		// existing one
		if ( value > degreeOfMembership ) degreeOfMembership = value;
		return this;
	}

	/// Transforms this instance into a JSON object.
  @override
	Map<String,dynamic> toJSON() {
		final json = super.toJSON();

		json['degreeOfMembership'] = degreeOfMembership;
		json['representativeValue'] = representativeValue;
		json['left'] = left;
		json['right'] = right;
		json['uuid'] = uuid;

		return json;
	}

	/// Restores this instance from the given JSON object.
  @override
	FuzzySet fromJSON(Map<String,dynamic> json ) {
    super.fromJSON(json);
		degreeOfMembership = json['degreeOfMembership'];
		representativeValue = json['representativeValue'];
		left = json['left'];
		right = json['right'];

		return this;
	}
}
