const Map<String,Map<String,Map<String,String>>> filesJson = {
  'Autonomous Agent Design':{
    'fsm':{
      'name': 'State-driven Agent Design',
      'description': 'The State-driven agent design enables a clean implementation of basic AI logic.' 
    },
    'goal':{
      'name': 'Goal-driven Agent Design',
      'description': 'The Goal-driven agent design enables a clean implementation of more advanced AI logic.' 
    },
  },
  'Fuzzy Logic':{
    'fuzzy':{
      'name': 'Weapon Selection',
      'description': 'The soldier\'s weapon selection is implemented via fuzzy inference.' 
    },
  },
  'Graphs and Navigation':{
    'graph_basic':{
      'name': 'Graphs',
      'description': 'Demonstrates basic graph search algorithms.' 
    },
  },
  'Math':{
    'bounding_volumes':{
      'name': 'Bounding Volumes',
      'description': 'Demonstrates different types of auto-generated bounding volumes.' 
    },
    'bvh':{
      'name': 'Bounding Volume Hierarchy (BVH)',
      'description': 'Enables faster intersection tests by introducing a hierarchy of bounding volumes for a single geometry.' 
    },
    'orientation':{
      'name': 'Orientation',
      'description': 'Demonstrates how to orient a game entity towards a specific target.' 
    },
  },
  'Misc':{
    'trigger':{
      'name': 'Triggers',
      'description': 'Usage of triggers to dynamically generate actions in the game world.' 
    },
  },
  'Perception':{
    'line_of_sight':{
      'name': 'Line of Sight',
      'description': 'Demonstrates a basic line of sight test.' 
    },
    'memory_system':{
      'name': 'Memory System',
      'description': 'Enables game entities to have a short-term memory so they react in a more natural way.' 
    },
  },
  'Steering Behaviors':{
    'steering_arrive':{
      'name': 'Arrive Steering Behavior',
      'description': 'This behavior steers the agent in such a way it decelerates onto the target position.' 
    },
    'steering_flee':{
      'name': 'Flee Steering Behavior',
      'description': 'Produces a force that steers an agent away from a target position.' 
    },
    'steering_flocking':{
      'name': 'Flocking Steering Behavior',
      'description': 'A group steering behavior based on "Alignment", "Cohesion" and "Separation".' 
    },
    'steering_follow':{
      'name': 'Follow Path Steering Behavior',
      'description': 'Produces a force that moves a vehicle along a series of waypoints.' 
    },
    'steering_interpose':{
      'name': 'Interpose Steering Behavior',
      'description': 'Produces a force that moves a vehicle to the midpoint of the imaginary line connecting two other agents.' 
    },
    'steering_obsticle':{
      'name': 'Obstacle Avoidance Steering Behavior',
      'description': 'Produces a force so a vehicle avoids obstacles lying in its path.' 
    },
    'steering_offset_pursuit':{
      'name': 'Offset Pursuit Steering Behavior',
      'description': 'Produces a force that keeps a vehicle at a specified offset from a leader vehicle.' 
    },
    'steering_pursuit':{
      'name': 'Pursuit Steering Behavior',
      'description': 'Useful when an agent is required to intercept a moving agent.' 
    },
    'steering_seek':{
      'name': 'Seek Steering Behavior',
      'description': 'Produces a force that directs an agent toward a target position.' 
    },
    'steering_wander':{
      'name': 'Wander Steering Behavior',
      'description': 'Produces a force that will give the impression of a random walk through the agent’s environment.' 
    },
  },
  'Playground':{
    'shooter':{
      'name': 'Shooter',
      'description': 'Usage of triggers to dynamically generate actions in the game world.' 
    },
    'hideseek':{
      'name': 'Hide and Seek',
      'description': 'A little game that experiments with steering and shooter mechanics.' 
    },

  },
};
