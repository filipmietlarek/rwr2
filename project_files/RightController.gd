extends XRController3D

@onready var ray: RayCast3D = $TeleportRay
@onready var marker: MeshInstance3D = $TeleportMarker

var xr_origin: XROrigin3D
var xr_camera: XRCamera3D

func _ready() -> void:
	# Szukamy Origin i Kamery
	xr_origin = get_parent() as XROrigin3D
	if not xr_origin:
		push_error("Skrypt musi być dzieckiem XROrigin3D!")
		return
		
	xr_camera = xr_origin.get_node("XRCamera3D") as XRCamera3D
	
	# Ukrywamy marker na starcie
	marker.visible = false
	
	# Łączymy sygnał wciśnięcia przycisku
	# button_pressed jest emitowany automatycznie przez XRController3D
	button_pressed.connect(_on_button_pressed)

func _process(_delta: float) -> void:
	if ray.is_colliding():
		marker.visible = true
		marker.global_position = ray.get_collision_point()
		# Ustawiamy marker płasko, żeby nie "wisiał" pod kątem kontrolera
		marker.global_basis = Basis()
	else:
		marker.visible = false

# Ta funkcja wywoła się automatycznie, gdy naciśniesz dowolny przycisk
func _on_button_pressed(button_name: String) -> void:
	# Sprawdzamy, czy wciśnięty przycisk to ten, którego chcemy użyć.
	# "trigger_click" to zazwyczaj główny spust pod palcem wskazującym.
	# "ax_button" to przycisk A lub X zależnie od ręki.
	if button_name == "trigger_click":
		teleport_now()

func teleport_now() -> void:
	if not ray.is_colliding():
		return
		
	var target: Vector3 = ray.get_collision_point()

	# Obliczanie przesunięcia kamery (VR offset)
	var origin_tf := xr_origin.global_transform
	var cam_tf := xr_camera.global_transform
	var cam_offset := cam_tf.origin - origin_tf.origin
	
	# Ignorujemy wysokość (Y), żeby nie utknąć w podłodze
	cam_offset.y = 0.0
	
	# Przenosimy Origin tak, aby kamera wylądowała dokładnie na markerze
	origin_tf.origin = target - cam_offset
	xr_origin.global_transform = origin_tf
