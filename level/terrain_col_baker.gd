tool
extends RigidBody

export var bake := false setget set_bake, get_bake;

func set_bake(b: bool):
	add_child(Node.new());
	_bake();
func get_bake() -> bool:
	return false;

func _bake() -> void:
	for c in get_children():
		remove_child(c);
		c.queue_free();
	
	for m in get_node("../TerrainMeshes").get_children():
		var col := CollisionShape.new();
		col.name = m.name + "_shape";
		add_child(col);
		col.translation = m.translation;
		col.shape = m.mesh.create_trimesh_shape();
