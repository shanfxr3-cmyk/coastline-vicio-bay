extends RefCounted

## Material/mesh/cell batching for immutable world visuals. Collision bodies stay
## independent, while MultiMesh groups retain useful spatial culling bounds.

const CELL_SIZE_M := 64.0

var _root: Node3D = null
var _batch_root: Node3D = null
var _unit_box := BoxMesh.new()
var _batches: Dictionary = {}
var _instance_count: int = 0


func _init(root: Node3D) -> void:
	_root = root
	_unit_box.size = Vector3.ONE
	_batch_root = Node3D.new()
	_batch_root.name = "StaticBatches"
	_root.add_child(_batch_root)


func queue_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rotation: Vector3 = Vector3.ZERO, detail: bool = false, casts_shadow: bool = true) -> void:
	if mat == null:
		return
	queue_mesh(_unit_box, parent, pos, rotation, size, mat, detail, casts_shadow)


func queue_mesh(mesh: Mesh, parent: Node3D, pos: Vector3, rotation: Vector3, part_scale: Vector3, mat: Material, detail: bool = false, casts_shadow: bool = true) -> void:
	if mesh == null or mat == null:
		return
	var local_transform := Transform3D(Basis.from_euler(rotation) * Basis.from_scale(part_scale), pos)
	var root_transform: Transform3D = _root.global_transform.affine_inverse() * parent.global_transform * local_transform
	var cell := Vector2i(
		floori(root_transform.origin.x / CELL_SIZE_M),
		floori(root_transform.origin.z / CELL_SIZE_M)
	)
	var key: String = "%d:%d:%d:%d:%d:%d" % [
		mesh.get_instance_id(),
		mat.get_instance_id(),
		cell.x,
		cell.y,
		int(detail),
		int(casts_shadow),
	]
	if not _batches.has(key):
		var transforms: Array[Transform3D] = []
		_batches[key] = {
			"mesh": mesh,
			"material": mat,
			"detail": detail,
			"casts_shadow": casts_shadow,
			"transforms": transforms,
		}
	var transforms: Array[Transform3D] = _batches[key]["transforms"]
	transforms.append(root_transform)
	_instance_count += 1


func flush(detail_distance: float) -> void:
	var batch_index: int = 0
	for key: String in _batches:
		var batch: Dictionary = _batches[key]
		var transforms: Array[Transform3D] = batch["transforms"]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = batch["mesh"]
		multimesh.instance_count = transforms.size()
		for index: int in range(transforms.size()):
			multimesh.set_instance_transform(index, transforms[index])

		var instance := MultiMeshInstance3D.new()
		instance.name = "StaticBatch_%03d" % batch_index
		instance.multimesh = multimesh
		instance.material_override = batch["material"]
		instance.layers = 2 if bool(batch["detail"]) else 1
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(batch["casts_shadow"]) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.set_meta("detail", bool(batch["detail"]))
		instance.set_meta("instance_count", transforms.size())
		_batch_root.add_child(instance)
		batch_index += 1
	_batches.clear()
	apply_detail_distance(detail_distance)


func apply_detail_distance(distance: float) -> void:
	for child: Node in _batch_root.get_children():
		var instance := child as MultiMeshInstance3D
		if instance != null and bool(instance.get_meta("detail", false)):
			instance.visibility_range_end = distance
			instance.visibility_range_end_margin = 16.0


func get_batch_count() -> int:
	return _batch_root.get_child_count()


func get_instance_count() -> int:
	return _instance_count
