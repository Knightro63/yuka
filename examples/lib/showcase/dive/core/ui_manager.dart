import 'dart:math' as math;
import 'package:examples/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:examples/showcase/dive/core/config.dart';
import 'package:examples/showcase/dive/core/world.dart';
import 'package:yuka/yuka.dart';

/// Used to manage the state of the user interface.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
/// @author {@link https://github.com/robp94|robp94}
///
class UIManager {
  late Gui datGui;
  final pi25 = math.pi * 0.25;
  final pi75 = math.pi * 0.75;

  World world;

  double currentTime = 0;

  double hitIndicationTime = config['UI']['CROSSHAIRS']['HIT_TIME'];
  double endTimeHitIndication = double.infinity;

  double damageIndicationTime = config['UI']['DAMAGE_INDICATOR']['TIME'];
  double endTimeDamageIndicationFront = double.infinity;
  double endTimeDamageIndicationRight = double.infinity;
  double endTimeDamageIndicationLeft = double.infinity;
  double endTimeDamageIndicationBack = double.infinity;
  final List<Map<String,dynamic>> fragMessages = [];

  Map<String,dynamic> html = {
    'loadingScreen': false,
    'hudAmmo': 0,
    'hudHealth': 0,
    'roundsLeft': 0,
    'ammo': 0,
    'health': 0,
    'hudFragList': <String>[],
    'fragList': <RichText>[],
  };

  Map<String,bool> sprites = {
    'crosshairs': false,
    'frontIndicator': false,
    'rightIndicator': false,
    'leftIndicator': false,
    'backIndicator': false
  };

  // for rendering HUD sprites
  late final width = world.threeJs.width;
  late final height = world.threeJs.height;

  late final camera = three.OrthographicCamera( - width / 2, width / 2, height / 2, - height / 2, 1, 10 );

  final scene = three.Scene();

  late Map<String,dynamic> debugParameter = {
    'showRegions': false,
    'showAxes': false,
    'showPaths': false,
    'showGraph': false,
    'showSpawnPoints': false,
    'showUUIDHelpers': false,
    'showSkeletons': false,
    'showItemRadius': false,
    'showWireframe': false,
    'showSpatialIndex': false,
    'enableFPSControls': false,
  };

	UIManager( this.world ) {
    camera.position.z = 10;
    datGui = Gui((){
      world.threeJs.onSetupComplete.call();
    });
	}

	/// Initializes the UI manager.
	UIManager init() {
		//
		final world = this.world;

		if ( world.debug ) {
			// nav mesh folder
			final folderNavMesh = datGui.addFolder( 'Navigation Mesh' );
			folderNavMesh.open();

			folderNavMesh.addCheckBox( debugParameter, 'showRegions' )..name = 'show convex regions'..onChange( ( value ){
				world.helpers['convexRegionHelper'].visible = value;
			} );

			folderNavMesh.addCheckBox( debugParameter, 'showSpatialIndex' )..name = 'show spatial index' ..onChange( ( value ){
				world.helpers['spatialIndexHelper'].visible = value;
			} );

			folderNavMesh.addCheckBox( debugParameter, 'showPaths' )..name = 'show navigation paths' ..onChange( ( value ){
				for ( final pathHelper in world.helpers['pathHelpers'] ) {
					pathHelper.visible = value;
				}
			} );

			folderNavMesh.addCheckBox( debugParameter, 'showGraph' )..name = 'show graph'..onChange( ( value ) {
				world.helpers['graphHelper'].visible = value;
			} );

			// world folder
			final folderWorld = datGui.addFolder( 'World' );
			folderWorld.open();

			folderWorld.addCheckBox( debugParameter, 'showAxes' )..name = 'show axes helper'..onChange( ( value ){
				world.helpers['axesHelper'].visible = value;
			} );

			folderWorld.addCheckBox( debugParameter, 'showSpawnPoints' )..name = 'show spawn points'..onChange( ( value ){
				world.helpers['spawnHelpers'].visible = value;
			} );

			folderWorld.addCheckBox( debugParameter, 'showItemRadius' )..name = 'show item radius'..onChange( ( value ){
				for ( final itemHelper in world.helpers['itemHelpers'] ) {
					itemHelper.visible = value;
				}
			} );

			folderWorld.addCheckBox( debugParameter, 'showWireframe' )..name = 'show wireframe'..onChange( ( value ){
				final levelMesh = this.world.scene.getObjectByName( 'level' );
				levelMesh?.material?.wireframe = value;
			} );

			folderWorld.addCheckBox( debugParameter, 'enableFPSControls' )..name = 'enable FPS controls'..onChange((value){
        if(value){
          world.lockControls();
        }
        else{
          world.unlockControls();
        }
      });

			// enemy folder
			final folderEnemy = datGui.addFolder( 'Enemy' );
			folderEnemy.open();

			folderEnemy.addCheckBox( debugParameter, 'showUUIDHelpers')..name = 'show UUID helpers'..onChange( ( value ){
				for ( final uuidHelper in world.helpers['uuidHelpers'] ) {
					uuidHelper.visible = value;
				}
			} );

			folderEnemy.addCheckBox( debugParameter, 'showSkeletons')..name = 'show skeletons'..onChange( ( value ) {
				for ( final skeletonHelper in world.helpers['skeletonHelpers'] ) {
					skeletonHelper.visible = value;
				}
			} );
		}

		return this;
	}

	/// Update method of this manager. Called each simulation step.
	UIManager update(double delta ) {
		currentTime += delta;

		if ( currentTime >= endTimeHitIndication ) {
			hideHitIndication();
		}

		// damage indicators

		if ( currentTime >= endTimeDamageIndicationFront ) {
			sprites['frontIndicator'] = false;
		}

		if ( currentTime >= endTimeDamageIndicationRight ) {
			sprites['rightIndicator'] = false;
		}

		if ( currentTime >= endTimeDamageIndicationLeft ) {
			sprites['leftIndicator'] = false;
		}

		if ( currentTime >= endTimeDamageIndicationBack ) {
			sprites['backIndicator'] = false;
		}

		// frag list
		_updateFragList();

		// render UI
		_render();

		return this;
	}

	/// Changes the style of the crosshairs in order to show a
	/// sucessfull hit.
	UIManager showHitIndication() {
		sprites['crosshairs'] = true;//.material.color.setFromHex32( 0xff0000 );
		endTimeHitIndication = currentTime + hitIndicationTime;
    world.updateUI();

		return this;
	}

	/// Removes the hit indication of the crosshairs in order to show its
	/// default state.
	UIManager hideHitIndication() {
		sprites['crosshairs'] = false;//.material.color.setFromHex32( 0xffffff );
	  endTimeHitIndication = double.infinity;
    world.updateUI();

		return this;
	}

	/// Shows radial elements around the crosshairs to visualize the attack direction
	/// for a certain amount of time.
	UIManager showDamageIndication(double angle ) {
		if ( angle >= - pi25 && angle <= pi25 ) {
			sprites['frontIndicator'] = true;
			endTimeDamageIndicationFront = currentTime + damageIndicationTime;
		} 
    else if ( angle > pi25 && angle <= pi75 ) {
			sprites['rightIndicator'] = true;
			endTimeDamageIndicationRight = currentTime + damageIndicationTime;
		} 
    else if ( angle >= - pi75 && angle < - pi25 ) {
			sprites['leftIndicator'] = true;
		  endTimeDamageIndicationLeft = currentTime + damageIndicationTime;
		} 
    else {
			sprites['backIndicator'] = true;
			endTimeDamageIndicationBack = currentTime + damageIndicationTime;
		}

    world.updateUI();

		return this;
	}

	/// Shows the FPS interface.
	UIManager showFPSInterface() {
		sprites['crosshairs'] = false;

		html['hudAmmo'] = 0;//classList.remove( 'hidden' );
		html['hudHealth'] = 0;//classList.remove( 'hidden' );

		updateAmmoStatus();
		updateHealthStatus();

		return this;
	}

	/// Hides the FPS interface.
	UIManager hideFPSInterface() {
		html['hudAmmo'] = 0;//.classList.add( 'hidden' );
	  html['hudHealth'] = 0;//.classList.add( 'hidden' );

		sprites['crosshairs'] = false;
		sprites['frontIndicator'] = false;
		sprites['rightIndicator'] = false;
		sprites['leftIndicator'] = false;
		sprites['backIndicator'] = false;

		return this;
	}

	/// Sets the size of the UI manager.
	UIManager setSize(double width, double height ) {
	  camera.left = - width / 2;
		camera.right = width / 2;
	  camera.top = height / 2;
		camera.bottom = - height / 2;
		camera.updateProjectionMatrix();

		return this;
	}

	/// Updates the UI element that displays the frags.
	UIManager _updateFragList() {
		final fragMessages = this.fragMessages;

		// check for expired messages (messages are at the end of the array)
		for ( int i = ( fragMessages.length - 1 ); i >= 0; i -- ) {
			final message = fragMessages[ i ];

			if ( currentTime >= message['endTime'] ) {
				fragMessages.removeAt( i );

				// remove the visual representation of the frag message
				final fragList = html['fragList'] as List;
				fragList.removeAt( i );
			}
		}

		// hide html element if there are no elements
		if ( fragMessages.isEmpty ) {
			(html['hudFragList'] as List).clear();
		}

    world.updateUI();
		return this;
	}

	/// Adds a kill message to the kill message display.
	UIManager addFragMessage(GameEntity fragger, GameEntity victim ) {
		// make the list visible
		html['hudFragList'].clear();

		// create the frag message
		final string = '${fragger.name}fragged${victim.name}';

		final fraggerSpan = TextSpan(//document.createElement( 'span' );
			text: fragger.name,
			style: TextStyle(
				color: Color(0xff00ff00),
			),
			children: [
				TextSpan(
					text: ' fragged ',
					style: TextStyle(
						color: Colors.white,
					),
				),
				TextSpan(
					text: victim.name,
					style: TextStyle(
						color: Color(0xffff0000),
					),
				)
			]
		);

		// save everything in a message object
		final fragMessage = <String,dynamic>{
			'text': string,
			'endTime': currentTime + config['UI']['FRAGS']['TIME'],
			'html': fraggerSpan
		};

		fragMessages.add( fragMessage );

		// append the HTML to the list
		final fragList = html['fragList'] as List;
		fragList.add( RichText(text: fraggerSpan) );

		return this;

	}

	/// Updates the UI with current ammo data.
	UIManager updateAmmoStatus() {
		final player = world.player;
		final weapon = player?.weaponSystem.currentWeapon;

		html['roundsLeft'] = weapon?.roundsLeft ?? 0;
		html['ammo'] = weapon?.ammo ?? 0;

    world.updateUI();
		return this;
	}

	/// Updates the UI with current health data.
	UIManager updateHealthStatus() {
		final player = world.player;
		html['health'] = player?.health ?? 0;

		return this;
	}

	/// Opens the debug interface.
	UIManager openDebugUI() {
		datGui.open();
		return this;
	}

	/// Closes the debug interface.
	UIManager closeDebugUI() {
		datGui.close();
		return this;
	}

  List<Widget> render(){
    return  !world.useFPSControls?[]:[
      Align(
        alignment: Alignment.center,
        child: ColorFiltered(
          // Apply a red color filter using BlendMode.srcATop
          colorFilter: ColorFilter.mode(
            sprites['crosshairs'] == true?Colors.red:Colors.white,
            BlendMode.srcATop, // Keeps the shape of the original image, but tints it
          ),
          child: Image.asset(
            'assets/showcase/textures/crosshairs.png',
            width: 35,
            height: 35,
          )
        )
      ),
      if(sprites['frontIndicator'] == true) Align(
        alignment: Alignment.center,
        child: Image.asset(
          'assets/showcase/textures/damageIndicatorFront.png',
          width: 250,
          height: 250,
        )
      ),
      if(sprites['rightIndicator'] == true)Align(
        alignment: Alignment.center,
        child: Image.asset(
          'assets/showcase/textures/damageIndicatorRight.png',
          width: 250,
          height: 250,
        )
      ),
      if(sprites['leftIndicator'] == true)Align(
        alignment: Alignment.center,
        child: Image.asset(
          'assets/showcase/textures/damageIndicatorLeft.png',
          width: 250,
          height: 250,
        )
      ),
      if(sprites['backIndicator'] == true)Align(
        alignment: Alignment.center,
        child: Image.asset(
          'assets/showcase/textures/damageIndicatorBack.png',
          width: 250,
          height: 250,
        )
      ),
      Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: 120,
          height: 50,
          color: Colors.grey[900],
          alignment: Alignment.center,
          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                html['roundsLeft'].toString(),
                style: TextStyle(fontSize: 20),
              ),
              Container(
                width: 0.5,
                height: 75,
                color: Colors.white,
              ),
              Text(
                html['ammo'].toString(),
                style: TextStyle(fontSize: 20),
              ),
            ],
          )
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          width: 120,
          height: 50,
          color: Colors.grey[900],
          alignment: Alignment.center,
          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Text(
            html['health'].toString(),
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
      Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 150,
          height: html['fragList'].length * 30.0,
          color: Colors.grey[900],
          alignment: Alignment.center,
          margin: EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: html['fragList'] as List<RichText>,
          )
        ),
      ),
    ];
  }

	/// Renders the HUD sprites. This is done after rendering the actual 3D scene.
	UIManager _render() {
		world.renderer?.clearDepth();
		world.renderer?.render( scene, camera );

		return this;
	}
}