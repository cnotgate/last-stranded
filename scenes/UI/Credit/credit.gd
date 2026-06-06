extends RichTextLabel

@export var scene_to_file: String

@onready var credit_text_path = "res://CreditText.txt"

@export var scroll_speed: float = 40.0
var scroll_bar: VScrollBar
var current_scroll_pos: float = 0.0

func _ready():
	scroll_active = true
	
	# 1. Load text asli dari file
	var file = FileAccess.open(credit_text_path, FileAccess.READ)
	var original_text = ""
	if file:
		original_text = file.get_as_text()
		file.close()
	
	# 2. Hitung perkiraan berapa baris kosong (\n) yang dibutuhkan 
	# untuk memenuhi tinggi minimum RichTextLabel saat ini
	var font = get_theme_font("normal_font")
	var font_size = get_theme_font_size("normal_font_size")
	var line_height = font.get_height(font_size) # Tinggi satu baris teks dalam pixel
	
	# Jumlah baris kosong = tinggi label dibagi tinggi satu baris font
	var empty_lines_needed = int(get_combined_minimum_size().y / line_height) + 1
	
	# 3. Buat string space kosong
	var padding = ""
	for i in range(empty_lines_needed):
		padding += "\n"
	
	# 4. Gabungkan: Space Kosong + Teks Asli + Space Kosong
	text = padding + original_text + padding
	
	# 5. Tunggu Godot selesai menggambar ulang teks baru
	await get_tree().process_frame
	
	scroll_bar = get_v_scroll_bar()
	scroll_bar.modulate.a = 0
	scroll_bar.value = 0

func _process(delta: float) -> void:
	if scroll_bar:
		# 1. Tambahkan pergerakan ke variabel float cadangan kita (Akurat & tidak dibulatkan)
		current_scroll_pos += scroll_speed * delta
		
		# 2. Masukkan nilai dari variabel cadangan ke scrollbar bawaan
		scroll_bar.value = current_scroll_pos
		
		# 3. Cek looping menggunakan variabel cadangan
		if current_scroll_pos >= (scroll_bar.max_value - scroll_bar.page):
			current_scroll_pos = 0.0
			scroll_bar.value = 0.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/"+ scene_to_file +".tscn")
