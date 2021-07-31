class_name RigidBodyController
extends RigidBody

# RigidBodyController by FreeFly
# Modified by alxl
# 
# Released by MIT License
# 
# Copyright (c) 2020 FreeFly
# Copyright (c) 2021 alxl
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

### Global
var is_grounded := false; # Whether the player is considered to be touching a walkable slope
onready var capsule: Shape = $Col.shape; # Capsule collision shape of the player

### Input vars
onready var head: Spatial = $Head; # y-axis rotation node (look left & right)
onready var pitch: Spatial = $Head/Pitch; # x-axis rotation node (look up & down)

### Integrate forces vars
export var accel := 80.0; # Player acceleration force
export var jump := 5.0; # Jump force multiplier
export var dodge := 25.0; # Dodge impulse multiplier
export var dodge_cd := 0.75; # Dodge cooldown
export var air_control := 0.0; # Air control multiplier
export var turning_scale := 45.0; # How quickly to scale movement towards a turning direction. Lower is more.
export var walkable_slope := 0.35; # Walkable slope. Lower is steeper
export var speed_limit := 2.5; # Default speed limit of the player
export var friction_divider := 15.0; # Amount to divide the friction by when not grounded (prevents sticking to walls from air control)
var upper_slope_normal: Vector3; # Stores the lowest (steepest) slope normal
var lower_slope_normal: Vector3; # Stores the highest (flattest) slope normal
var slope_normal: Vector3; # Stores normals of contact points for iteration
var contacted_body: RigidBody; # Rigid body the player is currently contacting, if there is one
var default_friction: float = physics_material_override.friction; # Editor friction value

var should_jump := false;
var should_dejump := false;
var is_landing := false; # Whether the player has jumped & let go of jump
var is_jumping := false; # Whether the player has jumped
var was_jumping := false; # Whether the player was jumping during the last physics frame

var should_dodge := false;
var dodge_cd_now := 0.0;

func _physics_process(_delta: float) -> void:
### Groundedness raycasts
	# Define raycast info used with detecting groundedness
	var raycast_list := []; # List of raycasts used with detecting groundedness
	var bottom := 0.1; # Distance down from start to fire the raycast to
	var start: float = (capsule.height/2 + capsule.radius)-0.05; # Start point down from the center of the player to start the raycast
	var cv_dist: float = capsule.radius-0.1; # Cardinal vector distance. Added to 2 cardinal vectors to result in a diagonal with the same magnitude of the cardinal vectors
	var ov_dist := cv_dist/sqrt(2); # Ordinal vector distance. 
	# Get world state for collisions
	var direct_state := get_world().direct_space_state;
	raycast_list.clear();
	is_grounded = false;
	# Create 9 raycasts around the player capsule.
	# They begin towards the edge of the radius and shoot from just
	# below the capsule, to just below the bottom bound of the capsule,
	# with one raycast down from the center.
	for i in 9:
		# Get the starting location
		var loc := translation;
		loc.y -= start;
		# Create the distance from the capsule center in a certain direction
		match i:
			# Cardinal vectors
			0: 
				loc.z -= cv_dist; # N
			1:
				loc.z += cv_dist; # S
			2:
				loc.x += cv_dist; # E
			3:
				loc.x -= cv_dist; # W
			# Ordinal vectors
			4:
				loc.z -= ov_dist; # NE
				loc.x += ov_dist;
			5:
				loc.z += ov_dist; # SE
				loc.x += ov_dist;
			6:
				loc.z -= ov_dist; # NW
				loc.x -= ov_dist;
			7:
				loc.z += ov_dist; # SW
				loc.x -= ov_dist;
		# Copy the current location below the capsule & subtract from it
		var loc2 := loc;
		loc2.y -= bottom;
		# Add the two points for this iteration to the list for the raycast
		raycast_list.append([loc,loc2]);
	# Check each raycast for collision, ignoring the capsule itself
	for array in raycast_list:
		var collision := direct_state.intersect_ray(array[0], array[1], [self]);
		# The player is grounded if any of the raycasts hit
		if (collision && is_slope_walkable(collision.normal.y)):
			is_grounded = true;

func _process(delta: float) -> void:
	if dodge_cd_now > 0.0:
		dodge_cd_now -= delta;

func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	upper_slope_normal = Vector3.UP;
	lower_slope_normal = Vector3.DOWN;
	contacted_body = null; # Rigidbody
	# Velocity of the Rigidbody the player is contacting
	var contacted_body_vel_at_point := Vector3();
	
### Grounding, slopes, & rigidbody contact point
	# If the player body is contacting something
	var shallowest_contact_index := -1;
	if (state.get_contact_count() > 0):
		# Iterate over the capsule contact points && get the steepest/shallowest slopes
		for i in state.get_contact_count():
			slope_normal = state.get_contact_local_normal(i);
			if (slope_normal.y < upper_slope_normal.y): # Lower normal means steeper slope
				upper_slope_normal = slope_normal;
			if (slope_normal.y > lower_slope_normal.y):
				lower_slope_normal = slope_normal;
				shallowest_contact_index = i;
		# If the steepest slope contacted is more shallow than the walkable_slope, the player is grounded
		if (is_slope_walkable(upper_slope_normal.y)):
			is_grounded = true;
			# If the shallowest contact index exists, get the velocity of the body at the contacted point
			if (shallowest_contact_index >= 0):
				var contact_position := state.get_contact_collider_position(0); # coords of the contact point from center of contacted body
				var collisions := get_colliding_bodies();
				if (collisions.size() > 0 && collisions[0].get_class() == "RigidBody"):
					contacted_body = collisions[0];
					contacted_body_vel_at_point = get_contacted_body_velocity_at_point(contact_position);
					#print(contacted_body_vel_at_point)
		# Else if the shallowest slope normal is not walkable, the player is not grounded
		elif (!is_slope_walkable(lower_slope_normal.y)):
			is_grounded = false;

### Jumping
	# If the player tried to jump & is grounded, apply an upward force times the jump multiplier
	if should_jump:
		should_jump = false;
		if is_grounded && !is_jumping:
			state.apply_central_impulse(Vector3.UP * jump);
			is_jumping = true;
			is_landing = false;
	# Apply a downward force once if the player lets go of jump to assist with landing
	if !is_grounded && should_dejump:
		should_dejump = false;
		if !is_landing:
			state.apply_central_impulse(Vector3.DOWN * jump * 0.2);
			is_landing = true;
	if is_grounded && was_jumping:
		is_jumping = false;
	was_jumping = is_jumping;

### Dodging
	var move := get_movt_vect(); # Get movement vector relative to player orientation
	
	if should_dodge:
		should_dodge = false;
		if dodge_cd_now <= 0.0:
			dodge_cd_now = dodge_cd;
			state.apply_central_impulse(move * dodge);

### Movement
	var move2 := Vector2(move.x, move.z); # Convert movement for Vector2 methods
	
	apply_friction_modifiers(move);
	
	# Get the player velocity, relative to the contacting body if there is one
	var vel := state.get_linear_velocity();
	vel -= contacted_body_vel_at_point;
	if !is_grounded:
		vel.y = 0;
	
	# Get a normalized player velocity
	var nvel := vel.normalized();
	var nvel2 := Vector2(nvel.x, nvel.z); # 2D velocity vector to use with angle_to & dot methods
	
	## If below the speed limit, or above the limit but facing away from the velocity,
	## move the player, adding an assisting force if turning. If above the speed limit &
	## facing the velocity, add a force perpendicular to the velocity & scale
	## it based on where the player is moving in relation to the velocity.
	##
	# Get the angle between the velocity & current movement vector
	var angle := nvel2.angle_to(move2);
	var theta := rad2deg(angle); # Angle between 2D look & velocity vectors
	var is_below_speed_limit := is_below_speed_limit(nvel, vel);
	var is_facing_velocity := (nvel2.dot(move2) >= 0);
	var direction: Vector3; # vector to be set 90 degrees either to the left or right of the velocity
	var turn_assist_scale: float; # Scaled from 0 to 1. Used for both turn assist interpolation & vector scaling
	# If the angle is to the right of the velocity
	if (theta > 0 && theta < 90):
		direction = nvel.cross(head.transform.basis.y); # Vecor 90 degrees to the right of velocity
		turn_assist_scale = clamp(theta/turning_scale, 0, 1); # Turn assist scale
	# If the angle is to the left of the velocity
	elif(theta < 0 && theta > -90):
		direction = head.transform.basis.y.cross(nvel); # Vecor 90 degrees to the left of velocity
		turn_assist_scale = clamp(-theta/turning_scale, 0, 1);
	# If not pushing into an unwalkable slope
	if (upper_slope_normal.y > walkable_slope):
		# If the player is below the speed limit, or is above it, but facing away from the velocity
		if (is_below_speed_limit || !is_facing_velocity):
			# Interpolate between the movement & velocity vectors, scaling with turn assist sensitivity
			move = move.linear_interpolate(direction, turn_assist_scale);
		# If the player is above the speed limit & looking within 90 degrees of the velocity
		else:
			move = direction; # Set the move vector 90 to the right or left of the velocity vector
			move *= turn_assist_scale; # Scale the vector. 0 if looking at velocity, up to full magnitude if looking 90 degrees to the side.
		move(move, state);
	# If pushing into an unwalkable slope, move with unscaled movement vector. Prevents turn assist from pushing the player into the wall.
	elif is_below_speed_limit:
		move(move, state);
### End movement

### Functions ###
# Gets the velocity of a contacted rigidbody at the point of contact with the player capsule
func get_contacted_body_velocity_at_point(contact_position: Vector3) -> Vector3:
	# Global coordinates of contacted body
	var body_position := contacted_body.transform.origin;
	# Global coordinates of the point of contact between the player & contacted body
	var global_contact_position := body_position + contact_position;
	# Calculate local velocity at point (cross product of angular velocity & contact position vectors)
	var local_vel_at_point := contacted_body.get_angular_velocity().cross(global_contact_position - body_position);
	# Add the current velocity of the contacted body to the velocity at the contacted point
	return contacted_body.get_linear_velocity() + local_vel_at_point;

# Return 4 cross products of b with a
func cross4(a: Vector3, b: Vector3) -> Vector3:
	return a.cross(b).cross(b).cross(b).cross(b);

# Whether a slope is walkable
func is_slope_walkable(slope: float) -> bool:
	return (slope >= walkable_slope); # Lower normal means steeper slope

# Whether the player is below the speed limit in the direction they're traveling
func is_below_speed_limit(nvel: Vector3, vel: Vector3) -> bool:
	return ((nvel.x >= 0 && vel.x < nvel.x*speed_limit) || (nvel.x <= 0 && vel.x > nvel.x*speed_limit) ||
		(nvel.z >= 0 && vel.z < nvel.z*speed_limit) || (nvel.z <= 0 && vel.z > nvel.z*speed_limit) ||
		(nvel.x == 0 || nvel.z == 0));

# Move the player
func move(move: Vector3, state: PhysicsDirectBodyState) -> void:
	if is_grounded:
		var direct_state := get_world().direct_space_state;
		
		# Raycast to get slope
		# Start at the edge of the cylinder of the capsule in the movement direction
		var start: Vector3 = (translation - Vector3(0,capsule.height/2,0)) + (move * capsule.radius);
		var end := start + Vector3.DOWN * 200;
		var hit := direct_state.intersect_ray(start, end, [self]);
		var use_normal: Vector3;
		# If the slope in front of the player movement direction is steeper than the
		# shallowest contact, use the steepest contact normal to calculate the movement slope
		if hit && hit.normal.y < lower_slope_normal.y:
			use_normal = upper_slope_normal;
		else:
			use_normal = lower_slope_normal;
		
		move = cross4(move, use_normal); # Get slope to move along based on contact
		state.add_central_force(move * accel);
		# Account for equal & opposite reaction when accelerating on ground
		if (contacted_body != null):
			contacted_body.add_force(move * -accel, state.get_contact_collider_position(0));
	else:
		state.add_central_force(move * accel * air_control);

# Set player friction
func apply_friction_modifiers(_move: Vector3) -> void:
	physics_material_override.friction = default_friction;
	# If not grounded, reduce friction
	if !is_grounded:
		physics_material_override.friction = default_friction/friction_divider;

func vector2_to_facing(v: Vector2) -> Vector3:
	var f := Vector3.ZERO;
	f += v.y * head.transform.basis.z;
	f += v.x * head.transform.basis.x;
	return f;

func get_movt_vect() -> Vector3:
	return Vector3.ZERO;
