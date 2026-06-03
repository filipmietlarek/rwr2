extends XRController3D

# --- TELEPORTACJA ---
@onready var ray: RayCast3D = $TeleportRay
@onready var marker: MeshInstance3D = $TeleportMarker

# --- OBRÓT SKOKOWY (Snap Turn) ---
@export var rotation_amount: float = 45.0  # O ile stopni obracamy
@export var deadzone: float = 0.5           # Próg wychylenia joysticka
var can_rotate: bool = true                 # Blokada ciągłego obrotu

var xr_origin: XROrigin3D
var xr_camera: XRCamera3D

func _ready() -> void:
	# Szukamy Origin i Kamery
	xr_origin = get_parent() as XROrigin3D
	if not xr_origin:
		push_error("Błąd: Kontroler musi być dzieckiem XROrigin3D!")
		return
		
	xr_camera = xr_origin.get_node("XRCamera3D") as XRCamera3D
	
	# Ukrywamy marker na starcie
	marker.visible = false
	
	# Podpinamy sygnał przycisku dla teleportu
	button_pressed.connect(_on_button_pressed)

func _process(_delta: float) -> void:
	# 1. LOGIKA TELEPORTACJI (Wizualizacja markera)
	if ray.is_colliding():
		marker.visible = true
		marker.global_position = ray.get_collision_point()
		marker.global_basis = Basis() # Marker leży płasko na ziemi
	else:
		marker.visible = false
	
	# 2. LOGIKA OBROTU (Snap Turn)
	handle_snap_turn()

# Obsługa przycisków kontrolera
func _on_button_pressed(button_name: String) -> void:
	if button_name == "trigger_click":
		teleport_now()

# Funkcja obrotu skokowego (Snap Turn wokół pozycji gracza)
func handle_snap_turn() -> void:
	var input := get_vector2("thumbstick")

	# Jeśli joystick jest w martwej strefie, pozwól na kolejny obrót
	if abs(input.x) < deadzone:
		can_rotate = true 
		return

	# Jeśli joystick jest wychylony i możemy wykonać obrót
	if can_rotate:
		# 1. Zapamiętujemy globalną pozycję głowy (kamery) PRZED obrotem
		var pos_before := xr_camera.global_position
		
		# 2. Wykonujemy natychmiastowy obrót XROrigin3D
		if input.x > 0:
			# Obrót w prawo
			xr_origin.rotate_y(deg_to_rad(-rotation_amount))
		else:
			# Obrót w lewo
			xr_origin.rotate_y(deg_to_rad(rotation_amount))
		
		# 3. Sprawdzamy, gdzie po obrocie znalazła się głowa
		var pos_after := xr_camera.global_position
		
		# 4. Obliczamy różnicę i przesuwamy Origin tak, aby głowa została dokładnie w tym samym miejscu
		var delta_pos := pos_before - pos_after
		xr_origin.global_position += delta_pos
		
		# Blokujemy obrót do momentu puszczenia drążka
		can_rotate = false

# Funkcja wykonująca teleportację
func teleport_now() -> void:
	if not ray.is_colliding():
		return
		
	var target: Vector3 = ray.get_collision_point()

	# Obliczanie przesunięcia kamery, aby nie teleportować się obok markera
	var origin_tf := xr_origin.global_transform
	var cam_tf := xr_camera.global_transform
	var cam_offset := cam_tf.origin - origin_tf.origin
	
	cam_offset.y = 0.0 # Ignorujemy wysokość
	
	origin_tf.origin = target - cam_offset
	xr_origin.global_transform = origin_tf
