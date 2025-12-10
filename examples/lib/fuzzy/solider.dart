import 'package:three_js/three_js.dart';
import 'package:yuka/yuka.dart';

class Soldier extends GameEntity {
  Object3D? assaultRifle;
  Object3D? shotgun;

  double ammoShotgun = 12;
  double ammoAssaultRifle = 30;

  GameEntity? zombie;

  final fuzzyModuleShotGun = FuzzyModule();
  final fuzzyModuleAssaultRifle = FuzzyModule();

	Soldier():super() {
		_initFuzzyModule();
	}

  @override
	Soldier start() {
		zombie = manager?.getEntityByName( 'zombie' );
		return this;
	}

  @override
	Soldier update(double delta) {
		super.update(delta);

		selectWeapon();
		//this.ui.currentWeapon.textContent = ( this.assaultRifle.visible ) ? 'Assault Rifle' : 'Shotgun';

		return this;
	}

	void selectWeapon() {
		final fuzzyModuleShotGun = this.fuzzyModuleShotGun;
		final fuzzyModuleAssaultRifle = this.fuzzyModuleAssaultRifle;
		final distance = position.distanceTo( zombie!.position );

		fuzzyModuleShotGun.fuzzify( 'distanceToTarget', distance );
		fuzzyModuleAssaultRifle.fuzzify( 'distanceToTarget', distance );

		fuzzyModuleShotGun.fuzzify( 'ammoStatus', ammoShotgun );
		fuzzyModuleAssaultRifle.fuzzify( 'ammoStatus', ammoAssaultRifle );

		final desirabilityShotgun = ( ammoShotgun == 0 ) ? 0 : fuzzyModuleShotGun.defuzzify( 'desirability' );
		final desirabilityAssaultRifle = ( ammoAssaultRifle == 0 ) ? 0 : fuzzyModuleAssaultRifle.defuzzify( 'desirability' );

		if ( desirabilityShotgun > desirabilityAssaultRifle ) {
			assaultRifle?.visible = false;
			shotgun?.visible = true;
		} 
    else {
			assaultRifle?.visible = true;
			shotgun?.visible = false;
		}
	}

	void _initFuzzyModule() {
		final fuzzyModuleShotGun = this.fuzzyModuleShotGun;
		final fuzzyModuleAssaultRifle = this.fuzzyModuleAssaultRifle;

		// FLV distance to target
		final distanceToTarget = FuzzyVariable();
		final targetClose = LeftShoulderFuzzySet( 0, 5, 10 );
		final targetMedium = TriangularFuzzySet( 5, 10, 15 );
		final targetFar = RightShoulderFuzzySet( 10, 15, 20 );

		distanceToTarget.add( targetClose );
		distanceToTarget.add( targetMedium );
		distanceToTarget.add( targetFar );

		fuzzyModuleShotGun.addFLV( 'distanceToTarget', distanceToTarget );
		fuzzyModuleAssaultRifle.addFLV( 'distanceToTarget', distanceToTarget );

		// FLV desirability
		final desirability = FuzzyVariable();
		final undesirable = LeftShoulderFuzzySet( 0, 25, 50 );
		final desirable = TriangularFuzzySet( 25, 50, 75 );
		final veryDesirable = RightShoulderFuzzySet( 50, 75, 100 );

		desirability.add( undesirable );
		desirability.add( desirable );
		desirability.add( veryDesirable );

		fuzzyModuleShotGun.addFLV( 'desirability', desirability );
		fuzzyModuleAssaultRifle.addFLV( 'desirability', desirability );

		// FLV ammo status shotgun
		final ammoStatusShotgun = FuzzyVariable();
		final lowShot = LeftShoulderFuzzySet( 0, 2, 4 );
		final okayShot = TriangularFuzzySet( 2, 7, 10 );
		final loadsShot = RightShoulderFuzzySet( 7, 10, 12 );

		ammoStatusShotgun.add( lowShot );
		ammoStatusShotgun.add( okayShot );
		ammoStatusShotgun.add( loadsShot );

		fuzzyModuleShotGun.addFLV( 'ammoStatus', ammoStatusShotgun );

		// FLV ammo status assault rifle
		final ammoStatusAssaultRifle = FuzzyVariable();
		final lowAssault = LeftShoulderFuzzySet( 0, 2, 8 );
		final okayAssault = TriangularFuzzySet( 2, 10, 20 );
		final loadsAssault = RightShoulderFuzzySet( 10, 20, 30 );

		ammoStatusAssaultRifle.add( lowAssault );
		ammoStatusAssaultRifle.add( okayAssault );
		ammoStatusAssaultRifle.add( loadsAssault );

		fuzzyModuleAssaultRifle.addFLV( 'ammoStatus', ammoStatusAssaultRifle );

		// rules shotgun
		fuzzyModuleShotGun.addRule( FuzzyRule( FuzzyAND( [targetClose, lowShot] ), desirable ) );
		fuzzyModuleShotGun.addRule( FuzzyRule( FuzzyAND( [targetClose, okayShot] ), veryDesirable ) );
		fuzzyModuleShotGun.addRule( FuzzyRule( FuzzyAND( [targetClose, loadsShot] ), veryDesirable ) );

		fuzzyModuleShotGun.addRule( FuzzyRule( FuzzyAND( [targetMedium, lowShot] ), desirable ) );
		fuzzyModuleShotGun.addRule( FuzzyRule( FuzzyAND( [targetMedium, okayShot] ), veryDesirable ) );
		fuzzyModuleShotGun.addRule( FuzzyRule( FuzzyAND( [targetMedium, loadsShot] ), veryDesirable ) );

		fuzzyModuleShotGun.addRule( FuzzyRule( FuzzyAND([ targetFar, lowShot] ), undesirable ) );
		fuzzyModuleShotGun.addRule( FuzzyRule( FuzzyAND( [targetFar, okayShot] ), undesirable ) );
		fuzzyModuleShotGun.addRule( FuzzyRule( FuzzyAND( [targetFar, loadsShot] ), undesirable ) );

		// rules assault rifle
		fuzzyModuleAssaultRifle.addRule( FuzzyRule( FuzzyAND( [targetClose, lowAssault] ), undesirable ) );
		fuzzyModuleAssaultRifle.addRule( FuzzyRule( FuzzyAND([ targetClose, okayAssault] ), desirable ) );
		fuzzyModuleAssaultRifle.addRule( FuzzyRule( FuzzyAND( [targetClose, loadsAssault] ), desirable ) );

		fuzzyModuleAssaultRifle.addRule( FuzzyRule( FuzzyAND( [targetMedium, lowAssault] ), desirable ) );
		fuzzyModuleAssaultRifle.addRule( FuzzyRule( FuzzyAND( [targetMedium, okayAssault] ), desirable ) );
		fuzzyModuleAssaultRifle.addRule( FuzzyRule( FuzzyAND( [targetMedium, loadsAssault] ), veryDesirable ) );

		fuzzyModuleAssaultRifle.addRule( FuzzyRule( FuzzyAND( [targetFar, lowAssault] ), desirable ) );
		fuzzyModuleAssaultRifle.addRule( FuzzyRule( FuzzyAND( [targetFar, okayAssault] ), veryDesirable ) );
		fuzzyModuleAssaultRifle.addRule( FuzzyRule( FuzzyAND( [targetFar, loadsAssault] ), veryDesirable ) );
	}
}
