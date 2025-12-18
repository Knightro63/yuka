import 'dart:math' as math;
import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/constants.dart';
import 'package:yuka/yuka.dart';
import 'package:three_js/three_js.dart' as three;

/// Holds the implementation of the First-Person Controls.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class FirstPersonControls extends EventDispatcher {
  final pi05 = math.pi / 2;
  final direction = Vector3();
  final velocity = Vector3();

  final step1 = 'step1';
  final step2 = 'step2';

  double currentSign = 1;
  double elapsed = 0;

  final euler = <String,double>{ 'x': 0, 'y': 0, 'z': 0 };
  dynamic owner;

  bool active = true;

  double movementX = 0; // mouse left/right
  double movementY = 0; // mouse up/down

  double lookingSpeed = config['CONTROLS']['LOOKING_SPEED'];
  double brakingPower = config['CONTROLS']['BRAKING_POWER'];
  double headMovement = config['CONTROLS']['HEAD_MOVEMENT'];
  double weaponMovement = config['CONTROLS']['WEAPON_MOVEMENT'];

  final Map<String,bool> input = {
    'forward': false,
    'backward': false,
    'right': false,
    'left': false,
    'mouseDown': false
  };

  late final three.ThreeJS threeJs;

	FirstPersonControls( this.owner ):super(){
    threeJs = owner.threeJs;
  }

	/// Connects the event listeners and activates the controls.
	FirstPersonControls connect() {
		threeJs.domElement.addEventListener( three.PeripheralType.pointerdown, onMouseDown, false );
		threeJs.domElement.addEventListener( three.PeripheralType.pointerup, onMouseUp, false );
		threeJs.domElement.addEventListener( three.PeripheralType.pointerHover, onMouseMove, false );
		threeJs.domElement.addEventListener( three.PeripheralType.keydown, onKeyDown, false );
		threeJs.domElement.addEventListener( three.PeripheralType.keyup, onKeyUp, false );

		return this;
	}

	/// Disconnects the event listeners and deactivates the controls.
	FirstPersonControls disconnect() {
		threeJs.domElement.removeEventListener( three.PeripheralType.pointerdown, onMouseDown, false );
		threeJs.domElement.removeEventListener( three.PeripheralType.pointerup, onMouseUp, false );
		threeJs.domElement.removeEventListener( three.PeripheralType.pointerHover, onMouseMove, false );
		threeJs.domElement.removeEventListener( three.PeripheralType.keydown, onKeyDown, false );
		threeJs.domElement.removeEventListener( three.PeripheralType.keyup, onKeyUp, false );

		return this;
	}

	/// Ensures the controls reflect the current orientation of the owner. This method is
	/// always used if the player's orientation is set manually. In this case, it's necessary
	/// to adjust internal variables.
	FirstPersonControls sync() {
		owner.rotation.toEuler( euler );
		movementX = euler['y']!; // yaw

		owner.head.rotation.toEuler( euler );
		movementY = euler['x']!; // pitch

		return this;
	}

	/// Resets the controls (e.g. after a respawn).
	FirstPersonControls reset(double delta) {
		active = true;

		movementX = 0;
		movementY = 0;

		input['forward'] = false;
		input['backward'] = false;
		input['right'] = false;
		input['left'] = false;
		input['mouseDown'] = false;

		currentSign = 1;
		elapsed = 0;
		velocity.set( 0, 0, 0 );

    return this;
	}

	/// Update method of this controls. Computes the current velocity and head bobbing
	/// of the owner (player).
	FirstPersonControls update(double delta ) {
		if ( active ) {
		  _updateVelocity( delta );

			final speed = owner.getSpeed();
			elapsed += delta * speed;

			// elapsed is used by the following two methods. it is scaled with the speed
			// to modulate the head bobbing and weapon movement
			_updateHead();
			_updateWeapon();

			// if the mouse is pressed and an automatic weapon like the assault rifle is equiped
			// support automatic fire
			if (input['mouseDown']! && owner.isAutomaticWeaponUsed() ) {
				owner.shoot();
			}
		}

		return this;
	}

  double _getNumber(bool e){
    return e?1:0;
  } 

	/// Computes the current velocity of the owner (player).
	FirstPersonControls _updateVelocity(double delta ) {
		final input = this.input;
		final owner = this.owner;

		velocity.x -= velocity.x * brakingPower * delta;
		velocity.z -= velocity.z * brakingPower * delta;

		direction.z = _getNumber( input['forward']! ) - _getNumber( input['backward']! );
		direction.x = _getNumber( input['left']! ) - _getNumber( input['right']! );
		direction.normalize();

		if ( input['forward']! || input['backward']!) velocity.z -= direction.z * config['CONTROLS']['ACCELERATION * delta'];
		if ( input['left']! || input['right']!) velocity.x -= direction.x * config['CONTROLS']['ACCELERATION * delta'];

		owner.velocity.copy( velocity ).applyRotation( owner.rotation );

		return this;

	}

	/// Computes the head bobbing of the owner (player).
	FirstPersonControls _updateHead() {
		final owner = this.owner;
		final head = owner.head;

		// some simple head bobbing
		final motion = math.sin( elapsed * headMovement );

		head.position.y = motion.abs() * 0.06;
		head.position.x = motion * 0.08;

		//
		head.position.y += owner.height;

		//
		final sign = math.cos( elapsed * headMovement ).sign;

		if ( sign < currentSign ) {
			currentSign = sign;
		}

		if ( sign > currentSign ) {
			currentSign = sign;
		}

		return this;
	}

	/// Computes the movement of the current armed weapon.
	FirstPersonControls _updateWeapon() {
		final owner = this.owner;
		final weaponContainer = owner.weaponContainer;

		final motion = math.sin( elapsed * weaponMovement );

		weaponContainer.position.x = motion * 0.005;
		weaponContainer.position.y = motion.abs() * 0.002;

		return this;
	}

  // event listeners
  void onMouseDown( event ) {
    if ( active && event.which == 1 ) {
      input['mouseDown'] = true;
      owner.shoot();
    }
  }

  void onMouseUp( event ) {
    if ( active && event.which == 1 ) {
      input['mouseDown'] = false;
    }
  }

  void onMouseMove( event ) {
    if ( active ) {
      movementX -= event.movementX * 0.001 * lookingSpeed;
      movementY -= event.movementY * 0.001 * lookingSpeed;
      movementY = math.max( - pi05, math.min( pi05, movementY ) );
      owner.rotation.fromEuler( 0, movementX, 0 ); // yaw
      owner.head.rotation.fromEuler( movementY, 0, 0 ); // pitch
    }
  }

  void onKeyDown( event ) {
    switch ( event.keyId ) {
      case 4294968068:
      case 119: // up
        input['forward'] = true;
        break;
      case 4294968066:
      case 97: // left
        input['left'] = true;
        break;
      case 4294968065:
      case 115: // down
        input['backward'] = true;
        break;
      case 4294968067:
      case 100: // right
        input['right'] = true;
        break;
      case 114: // r
        owner.weapon.reload();
        break;

			case 49: // 1
				owner.changeWeapon( WEAPON_TYPES_BLASTER );
				break;
			case 50: // 2
				if ( owner.hasWeapon( WEAPON_TYPES_SHOTGUN ) ) {
					owner.changeWeapon( WEAPON_TYPES_SHOTGUN );
				}
				break;
			case 51: // 3
				if ( owner.hasWeapon( WEAPON_TYPES_ASSAULT_RIFLE ) ) {
					owner.changeWeapon( WEAPON_TYPES_ASSAULT_RIFLE );
				}
				break;
    }
  }

  void onKeyUp( event ) {
    switch ( event.keyId ) {
      case 4294968068:
      case 119: // up
        input['forward'] = false;
        break;
      case 4294968066:
      case 97: // left
        input['left'] = false;
        break;
      case 4294968065:
      case 115: // down
        input['backward'] = false;
        break;
      case 4294968067:
      case 100: // right
        input['right'] = false;
        break;
    }
  }
}