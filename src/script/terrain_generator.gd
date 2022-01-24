# ORIGINAL CODE FROM @Arcane Hive Games
# updated to GDSCRIPT for GODOT 4.0.dev by SPRVLLN

@tool
extends Node3D

var _block_map :NodePath= null
@export var block_map: NodePath:
	get: return _block_map
	set(v):
		_clear()
		_block_map = v
		_initialize()

var _view_distance := 12
@export var view_distance: int :
	get: return _view_distance
	set(v):
		_clear()
		_view_distance = v
		_view_distance = clamp(view_distance, 1, 256)
		_initialize()

var _height := 4
@export var height : int :
	get: return _height
	set(v):
		_clear()
		_height = v
		_initialize()

var _height_bias := 1.65
@export var height_bias: float :
	get: return _height_bias
	set(v):
		_clear()
		_height_bias = v
		_initialize()

var _seed_val := 20
@export var seed_val: int :
	get: return _seed_val
	set(v):
		_clear()
		_seed_val = v
		_initialize()

var _octaves := 2
@export var octaves: int :
	get: return _octaves
	set(v):
		_clear()
		_octaves = v
		_initialize()

var _period := 20.0
@export var period: float :
	get: return _period
	set(v):
		_clear()
		_period = v
		_initialize()

var _lacunarity := 2.0
@export var lacunarity: float :
	get: return _lacunarity
	set(v):
		_clear()
		_lacunarity = v
		_initialize()

var _persistence := 0.5
@export var persistence: float :
	get: return _persistence
	set(v):
		_clear()
		_persistence = v
		_initialize()

var mesh_node : MeshInstance3D = null
var noise : OpenSimplexNoise = OpenSimplexNoise.new()

var vertices : PackedVector3Array
var UVs : PackedVector2Array
var normals : PackedVector3Array
#var tangent : PoolVector3Array
#var bitangent : PoolVector3Array
var indices : PackedInt32Array

var is_initialized = false

func _generate_vertices():
	vertices = PackedVector3Array()
	var centre_offset = floor(view_distance / 2)
	for x in range(view_distance+1):
		for y in range(view_distance+1):
			var h = noise.get_noise_2d(x, y) * height_bias
			var is_negative = sign(h);
			h *= h
			h *= height * is_negative
			vertices.append(Vector3(x-centre_offset,h,y-centre_offset))

func _generate_UVs():
	UVs = PackedVector2Array()
	var offset = 1.0 / (view_distance)
	for x in range(view_distance+1):
		for y in range(view_distance+1):
			UVs.append(Vector2(offset*x, offset*y))

func _generate_indices():
	indices = PackedInt32Array()
	for index in range((view_distance+1)*view_distance):
		indices.append(index)
		indices.append(index+(view_distance+1))
		if index != 0 and (index+1) % (view_distance+1) == 0:
			indices.append(index+(view_distance+1))
			indices.append(index+1)

func _generate_normals():
	normals = PackedVector3Array()
	normals.resize(vertices.size())
	for f in range(normals.size()):
		normals[f] = Vector3(0,0,0)

	for i in range(0, indices.size()-2, 2):
		var ia = indices[i]
		var ib = indices[i+1]
		var ic = indices[i+2]

		if ia==ib or ib==ic or ia==ic:
			continue

		var a :Vector3 = vertices[ia]
		var	b :Vector3 = vertices[ib]
		var	c :Vector3 = vertices[ic]

		var tangent = c-a
		var bitangent = b-a
		var normal_a = tangent.cross(bitangent)

		normals[ia] +=  normal_a
		normals[ib] +=  normal_a
		normals[ic] +=  normal_a

	_normalize_normals()

func _normalize_normals():
	for i in range(normals.size()):
		normals[i] = normals[i].normalized()

func _generate_mesh():
	_generate_vertices()
	_generate_UVs()
	_generate_indices()
	_generate_normals()
	var mesh = ArrayMesh.new()
	var data = []
	data.resize(ArrayMesh.ARRAY_MAX)
	data[ArrayMesh.ARRAY_VERTEX] = vertices
	data[ArrayMesh.ARRAY_TEX_UV] = UVs
	data[ArrayMesh.ARRAY_INDEX] = indices
	data[ArrayMesh.ARRAY_NORMAL] = normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, data)
	return mesh

func _generate_noise():
	noise = OpenSimplexNoise.new()
	noise.seed = seed_val
	noise.octaves = octaves
	noise.period = period
	noise.lacunarity = lacunarity
	noise.persistence = persistence

func _initialize():
	if is_initialized:
		return

	if block_map == null:
		return

	mesh_node = get_node_or_null(block_map)
	if mesh_node == null:
		return

	_generate_noise()
	mesh_node.mesh = _generate_mesh()
	is_initialized = true

func _clear():
	if mesh_node != null and is_initialized:
		is_initialized = false
		mesh_node.mesh = null

func _ready():
	_initialize()
