import 'package:examples/playground/shooter/world.dart';
import 'package:yuka/yuka.dart';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

enum BlasterStatus{
	ready, // the blaster is ready for the next action
	shot, // the blaster is firing
	reload, // the blaster is reloading
	empty // the blaster is empty
}

class Blaster extends GameEntity {
  final intersectionPoint = Vector3();
  final target = Vector3();
  BlasterStatus status = BlasterStatus.ready;

  int roundsLeft = 12;
  int roundsPerClip = 12;
  int ammo = 48;
  int maxAmmo = 96;

  double shotTime = 0.2;
  double reloadTime = 1.5;
  double muzzleFireTime = 0.1;

  double currentTime = 0;
  double endTimeShot = double.infinity;
  double endTimeReload = double.infinity;
  double endTimeMuzzleFire = double.infinity;

  late final three.Sprite muzzleSprite;
  final World world;

  late Map<String,dynamic> ui = {
    'roundsLeft': roundsLeft,
    'ammo': ammo
  };

  dynamic owner;

	Blaster( this.owner, this.world ):super() {
		muzzleSprite = world.assetManager.models['muzzle'];
		updateUI();
	}

  @override
	Blaster update(double delta ) {
		currentTime += delta;

		// check reload
		if (currentTime >= endTimeReload ) {

			final toReload = roundsPerClip - roundsLeft;

			if ( ammo >= toReload ) {
				roundsLeft = roundsPerClip;
				ammo -= toReload;
			} 
      else {
				roundsLeft += ammo;
				ammo = 0;
			}

			status = BlasterStatus.ready;
			updateUI();
			endTimeReload = double.infinity;
		}

		// check muzzle fire

		if ( currentTime >= endTimeMuzzleFire ) {
			muzzleSprite.visible = false;
			endTimeMuzzleFire = double.infinity;
		}

		// check shoot

		if ( currentTime >= endTimeShot ) {
			if ( roundsLeft == 0 ) {
				status = BlasterStatus.empty;
			} 
      else {
				status = BlasterStatus.ready;
			}

			endTimeShot = double.infinity;
		}

		return this;
	}

	Blaster reload() {
		if ( ( status == BlasterStatus.ready || status == BlasterStatus.empty ) && ammo > 0 ) {
			status = BlasterStatus.reload;

			// animation
			final animation = world.animations['reload'] as three.AnimationAction;
			animation.stop();
			animation.play();

			//
			endTimeReload = currentTime + reloadTime;
		}

		return this;
	}

	Blaster shoot() {
		if ( status == BlasterStatus.ready ) {
			status = BlasterStatus.shot;

			// animation
			final animation = world.animations['shot'] as three.AnimationAction;
			animation.stop();
			animation.play();

			// muzzle fire
			muzzleSprite.visible = true;
			muzzleSprite.material?.rotation = math.Random().nextDouble() * math.pi;

			endTimeMuzzleFire = currentTime + muzzleFireTime;

			// create bullet
			final owner = this.owner;
			final head = owner.head;

			final ray = Ray();

			// first calculate a ray that represents the actual look direction from the head position
			ray.origin.extractPositionFromMatrix( head.worldMatrix() );
			owner.getDirection( ray.direction );

			// determine closest intersection point with world object
			final result = world.intersectRay( ray, intersectionPoint );

			// now calculate the distance to the closest intersection point. if no point was found,
			// choose a point on the ray far away from the origin
			final double distance = ( result == null ) ? 1000 : ray.origin.distanceTo( intersectionPoint );

			// now let's change the origin to the weapon's position.
			target.copy( ray.origin ).add( ray.direction.multiplyScalar( distance ) );
			ray.origin.extractPositionFromMatrix( worldMatrix() );
			ray.direction.subVectors( target, ray.origin ).normalize();
			world.addBullet( owner, ray );

			// adjust ammo
			roundsLeft --;
			endTimeShot = currentTime + shotTime;
			updateUI();
		} 

		return this;
	}

	void updateUI() {
		ui['roundsLeft'] = roundsLeft;
		ui['ammo'] = ammo;
	}
}


