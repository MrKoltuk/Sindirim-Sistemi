extends Node3D

# Besin tipleri
enum BesinTipi { YOK, YAG, PROTEIN, KARBONHIDRAT }

# Mevcut durum
var current_state = BesinTipi.YOK
var son_yenilen = "Henüz besin yenilmedi"

# Sürükleme
var tutulan_besin = null
var offset = Vector3.ZERO

# Referanslar
@onready var camera = $Camera3D
@onready var agiz_area = $Agiz/Area3D
@onready var ui_label = $CanvasLayer/EnSonYenilen
@onready var organ_bilgi_label = $CanvasLayer/OrganBilgi
@onready var yag_sesi = $YagSesi
@onready var protein_sesi = $ProteinSesi
@onready var karbonhidrat_sesi = $KarbonhidratSesi
@onready var organ_sesi = $OrganSesi

# Kamera pozisyonları - ORGANLARA TIKLANINCA KAMERA HAREKET EDER
var kamera_pozisyonlari = {
	"Agiz": Vector3(0.571, 3.012, -1.406),
	"Mide": Vector3(-0.018, 2.095, -0.705),
	"OnIki_Parmak": Vector3(0.770, 1.700, -0.705),
	"Ince_Bagirsak": Vector3(0.821, 1.204, -1.085),
	"Kalin_Bagirsak": Vector3(0.821, 1.535, -1.085),
	"Karaciger": Vector3(0.763, 2.142, -0.705),
	"Pankreas": Vector3(0.763, 1.688, -0.705),
	"Bos": Vector3(-0.018, 2.095, -2.922)
}


# Her organ için label pozisyonları (ekran koordinatları)
var label_pozisyonlari = {
	"Agiz": Vector2(50, 100),
	"Mide": Vector2(1150, 100),
	"OnIki_Parmak": Vector2(50, 100),
	"Ince_Bagirsak": Vector2(50, 100),
	"Kalin_Bagirsak": Vector2(50, 100),
	"Karaciger": Vector2(50, 100),
	"Pankreas": Vector2(50, 100),
	"Bos": Vector2(50, 100)
}

var organ_aciklamalari = {
	"Agiz": {
		BesinTipi.YAG: "AĞIZ\n\nYağlar ağızda SİNDİRİLMEZ.\nSadece çiğneme ile mekanik parçalanma olur.\n\nÇalışma Durumu: ❌ Yağ sindirimi yok",
		BesinTipi.PROTEIN: "AĞIZ\n\nProteinler ağızda SİNDİRİLMEZ.\nSadece çiğneme ile mekanik parçalanma olur.\n\nÇalışma Durumu: ❌ Protein sindirimi yok",
		BesinTipi.KARBONHIDRAT: "AĞIZ\n\nKarbonhidratlar ağızda SİNDİRİLİR!\nTükürükteki AMİLAZ enzimi nişastayı parçalar.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor"
	},
	"Mide": {
		BesinTipi.YAG: "MİDE\n\nYağlar midede kısmen sindirilebilir.\nMide lipazı az miktarda yağ sindirimi yapar.\n\nÇalışma Durumu: 🟡 Sınırlı sindirim",
		BesinTipi.PROTEIN: "MİDE\n\nProteinler midede SİNDİRİLİR!\nPEPSİN enzimi ve HCl asit proteinleri parçalar.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor",
		BesinTipi.KARBONHIDRAT: "MİDE\n\nKarbonhidratlar midede çok az sindirilir.\nAsit ortam amilaz aktivitesini durdurur.\n\nÇalışma Durumu: ❌ Sindirim durmuş"
	},
	"OnIki_Parmak": {
		BesinTipi.YAG: "ON İKİ PARMAK BAĞIRSAĞI\n\nYağ sindirimi BAŞLAR!\nSafra ve pankreas enzimi buraya salgılanır.\n\nÇalışma Durumu: ✅ Yağ sindirimi başlıyor",
		BesinTipi.PROTEIN: "ON İKİ PARMAK BAĞIRSAĞI\n\nProtein sindirimi devam eder!\nPankreas tripsin enzimi salgılar.\n\nÇalışma Durumu: ✅ Protein sindirimi devam ediyor",
		BesinTipi.KARBONHIDRAT: "ON İKİ PARMAK BAĞIRSAĞI\n\nKarbonhidrat sindirimi devam eder!\nPankreas amilaz enzimi salgılar.\n\nÇalışma Durumu: ✅ Karbonhidrat sindirimi devam ediyor"
	},
	"Ince_Bagirsak": {
		BesinTipi.YAG: "İNCE BAĞIRSAK\n\nYağlar ince bağırsakta TAM SİNDİRİLİR!\nSafra yağları emülsifiye eder, LIPAZ parçalar.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor",
		BesinTipi.PROTEIN: "İNCE BAĞIRSAK\n\nProteinler ince bağırsakta TAM SİNDİRİLİR!\nTRIPSİN ve PEPTİDAZ enzimleri amino asitlere ayırır.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor",
		BesinTipi.KARBONHIDRAT: "İNCE BAĞIRSAK\n\nKarbonhidratlar ince bağırsakta TAM SİNDİRİLİR!\nPANKREAS AMİLAZI basit şekerlere ayırır.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor"
	},
	"Kalin_Bagirsak": {
		BesinTipi.YAG: "KALIN BAĞIRSAK\n\nSindirim tamamlanmış, emilim aşaması.\nSu emilimi ve dışkı oluşumu gerçekleşir.\n\nÇalışma Durumu: 🟡 Sindirim yok, emilim var",
		BesinTipi.PROTEIN: "KALIN BAĞIRSAK\n\nSindirim tamamlanmış, emilim aşaması.\nSu emilimi ve dışkı oluşumu gerçekleşir.\n\nÇalışma Durumu: 🟡 Sindirim yok, emilim var",
		BesinTipi.KARBONHIDRAT: "KALIN BAĞIRSAK\n\nSindirim tamamlanmış, emilim aşaması.\nSu emilimi ve dışkı oluşumu gerçekleşir.\n\nÇalışma Durumu: 🟡 Sindirim yok, emilim var"
	},
	"Karaciger": {
		BesinTipi.YAG: "KARACİĞER\n\nSAFRA üretir!\nSafra yağları küçük damlacıklara böler (emülsifikasyon).\n\nÇalışma Durumu: ✅ Yağ sindirimi için safra salgılıyor",
		BesinTipi.PROTEIN: "KARACİĞER\n\nProtein sindirimi için doğrudan enzim salgılamaz.\nAma sindirilmiş proteinleri işler ve kullanır.\n\nÇalışma Durumu: 🟡 Dolaylı rol",
		BesinTipi.KARBONHIDRAT: "KARACİĞER\n\nKarbonhidrat sindirimi için doğrudan enzim salgılamaz.\nGlükoz depolanması ve kullanımı yapar.\n\nÇalışma Durumu: 🟡 Dolaylı rol"
	},
	"Pankreas": {
		BesinTipi.YAG: "PANKREAS\n\nLİPAZ enzimi salgılar!\nYağları yağ asitleri ve gliserole parçalar.\n\nÇalışma Durumu: ✅ Yağ sindirimi için lipaz salgılıyor",
		BesinTipi.PROTEIN: "PANKREAS\n\nTRİPSİN enzimi salgılar!\nProteinleri küçük peptitlere parçalar.\n\nÇalışma Durumu: ✅ Protein sindirimi için tripsin salgılıyor",
		BesinTipi.KARBONHIDRAT: "PANKREAS\n\nAMİLAZ enzimi salgılar!\nNişastayı maltoz ve dekstrinlere parçalar.\n\nÇalışma Durumu: ✅ Karbonhidrat sindirimi için amilaz salgılıyor"
	},
	"Bos": {
	BesinTipi.YAG: "Yağlar ağız ve mide yoluyla ince bağırsağa gelir.\nPankreas, yağların sindirilmesine yardımcı\nolacak enzimleri salgılar. Yağlar burada parçalanır ve emilime hazır hale gelir.\n\nVücut durumu: ✅ Yağ sindirimi gerçekleşiyor.",
	BesinTipi.PROTEIN: "Proteinler mideye ulaşır ve burada kısmen parçalanır.\nİnce bağırsakta pankreas, proteinleri\ndaha küçük parçalara ayıracak enzimleri salgılar.\nBu sayede proteinler emilime hazır hale gelir.\n\nVücut durumu: ✅ Protein sindirimi gerçekleşiyor.",
	BesinTipi.KARBONHIDRAT: "Nişasta ve diğer karbonhidratlar ağızda çiğneme\nve tükürükteki enzimlerle kısmen parçalanır.\nİnce bağırsakta pankreas, karbonhidratları\nbasit şekere dönüştüren enzimleri salgılar.\n\nVücut durumu: ✅ Karbonhidrat sindirimi gerçekleşiyor."
		}

}

func _ready():
	_update_ui()
	
	if agiz_area:
		agiz_area.area_entered.connect(_on_agiz_area_entered)
	
	if organ_bilgi_label:
		organ_bilgi_label.visible = false

func _input(event):
	# MOUSE SOL TUŞA BASILDI
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_besin_veya_organ_tikla(event.position)
		else:
			# MOUSE BIRAKILDI
			tutulan_besin = null
	
	# MOUSE HAREKET EDİYOR
	if event is InputEventMouseMotion and tutulan_besin != null:
		_besin_surukle(event.position)

func _besin_veya_organ_tikla(mouse_pos: Vector2):
	# 2D mouse pozisyonundan 3D düzleme ray at
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	
	print("🎯 TIKLANMA ALGILLANDI")
	
	if result:
		print("✅ RAYCAST BİR ŞEYE ÇARPTI: ", result.collider.name)
		
		if result.collider is Area3D:
			var area = result.collider
			var parent = area.get_parent()
			
			print("📦 Area3D bulundu: ", area.name)
			print("👪 Parent: ", parent.name if parent else "YOK")
			print("🏷️ Gruplar: ", area.get_groups())
			
			# BESİN Mİ?
			if parent and parent is Node3D:
				if parent.name == "Yag" or parent.name == "Protein" or parent.name == "Karbonhidrat":
					tutulan_besin = parent
					offset = parent.global_position - result.position
					print("🖐️ TUTULDU: " + parent.name)
					return
			
			# ORGAN MI?
			if area.is_in_group("Organ"):
				print("🫀 ORGAN ALGILANDI!")
				var organ_adi = area.get_meta("organ_adi", "")
				print("📝 Organ adı metadata: ", organ_adi)
				if organ_adi != "":
					_organa_git(organ_adi)
				else:
					print("❌ organ_adi metadata BOŞ!")
			else:
				print("❌ 'Organ' grubunda DEĞİL")
	else:
		print("❌ RAYCAST HİÇBİR ŞEYE ÇARPMADI")

func _besin_surukle(mouse_pos: Vector2):
	# Mouse pozisyonunu 3D dünyaya çevir
	var from = camera.project_ray_origin(mouse_pos)
	var normal = camera.project_ray_normal(mouse_pos)
	
	# Kameradan belli bir mesafede tut (5 birim)
	var distance = 5.0
	var yeni_pozisyon = from + normal * distance
	
	# Z EKSENİNİ SABİTLE - sadece X ve Y hareket edebilir
	var sabit_z = tutulan_besin.global_position.z
	tutulan_besin.global_position = Vector3(yeni_pozisyon.x, yeni_pozisyon.y, sabit_z)

func _on_agiz_area_entered(area):
	# Ağza bir area girdi
	if area.get_parent() and area.get_parent() is Node3D:
		var besin = area.get_parent()
		
		if besin.name == "Yag":
			_besin_yenildi(BesinTipi.YAG, "YAĞ", yag_sesi)
			besin.queue_free()
		elif besin.name == "Protein":
			_besin_yenildi(BesinTipi.PROTEIN, "PROTEİN", protein_sesi)
			besin.queue_free()
		elif besin.name == "Karbonhidrat":
			_besin_yenildi(BesinTipi.KARBONHIDRAT, "KARBONHİDRAT", karbonhidrat_sesi)
			besin.queue_free()

func _besin_yenildi(tip: BesinTipi, isim: String, ses: AudioStreamPlayer):
	current_state = tip
	son_yenilen = isim
	_update_ui()
	
	# İlgili sesi çal
	if ses and ses.stream:
		ses.play()
	
	print("🍽️ YENİLDİ: " + isim)
	tutulan_besin = null

func _organa_git(organ_adi: String):
	# Organ sesini çal
	if organ_sesi and organ_sesi.stream:
		organ_sesi.play()
	
	# Kamerayı organa yaklaştır
	if kamera_pozisyonlari.has(organ_adi):
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(camera, "position", kamera_pozisyonlari[organ_adi], 0.8)
	
	# Label pozisyonunu ayarla
	if label_pozisyonlari.has(organ_adi) and organ_bilgi_label:
		var tween_label = create_tween()
		tween_label.set_ease(Tween.EASE_OUT)
		tween_label.set_trans(Tween.TRANS_CUBIC)
		tween_label.tween_property(organ_bilgi_label, "position", label_pozisyonlari[organ_adi], 0.5)
	
	# Organ bilgisini göster
	if organ_aciklamalari.has(organ_adi) and current_state != BesinTipi.YOK:
		var aciklama = organ_aciklamalari[organ_adi].get(current_state, "")
		if organ_bilgi_label and aciklama != "":
			organ_bilgi_label.text = aciklama
			organ_bilgi_label.visible = true
	elif current_state == BesinTipi.YOK:
		if organ_bilgi_label:
			organ_bilgi_label.text = "Önce bir besin yemelisin!"
			organ_bilgi_label.visible = true

func _update_ui():
	if ui_label:
		ui_label.text = "EN SON YENİLEN: " + son_yenilen
