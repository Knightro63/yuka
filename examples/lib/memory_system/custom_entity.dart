import 'package:yuka/yuka.dart';
import 'dart:math' as math;

class CustomEntity extends GameEntity {
  final MemorySystem memorySystem = MemorySystem();
  double currentTime = 0;
  List<MemoryRecord> memoryRecords = [];
  GameEntity? target;

	CustomEntity():super() {
		memorySystem.memorySpan = 3;

		vision = Vision( this );
		vision?.range = 5;
		vision?.fieldOfView = math.pi * 0.5;

		maxTurnRate = math.pi * 0.5;
	}

  @override
	CustomEntity start() {
		final target = manager?.getEntityByName( 'target' );
		final obstacle = manager?.getEntityByName( 'obstacle' );

		this.target = target;
		vision?.addObstacle( obstacle! );

		return this;
	}

  @override
	CustomEntity update(double delta ) {
		currentTime += delta;

		 // In many scenarios it is not necessary to update the vision in each
		 // simulation step. A regulator could be used to restrict the update rate.
		updateVision();

		// get a list of all recently sensed game entities
		memorySystem.getValidMemoryRecords( currentTime, this.memoryRecords );

		if ( memoryRecords.isNotEmpty ) {

			// Pick the first one. It's highly application specific what record is chosen
			// for further processing.

			final record = memoryRecords[ 0 ];
			final entity = record.entity;

			// if the game entity is visible, directly rotate towards it. Otherwise, focus
			// the last known position

			if ( record.visible == true ) {
				rotateTo( entity!.position, delta );
				entity.renderComponent.material.color.setFromHex32( 0x00ff00 ); // some visual feedback
			}
      else {
				// only rotate to the last sensed position if the entity was seen at least once
				if ( record.timeLastSensed != - 1 ) {
					rotateTo( record.lastSensedPosition, delta );
					entity!.renderComponent.material.color.setFromHex32( 0xff0000 ); // some visual feedback
				}
			}
		} 
    else {
			// rotate back to default
			rotateTo( forward, delta );
		}

		return this;
	}

	void updateVision() {
		final memorySystem = this.memorySystem;
		final vision = this.vision;
		final target = this.target;

		if ( memorySystem.hasRecord( target! ) == false ) {
			memorySystem.createRecord( target );
		}

		final record = memorySystem.getRecord( target );

		if ( vision?.visible( target.position ) == true ) {
			record?.timeLastSensed = currentTime;
			record?.lastSensedPosition.copy( target.position );
			record?.visible = true;
		} 
    else {
			record?.visible = false;
		}
	}
}
