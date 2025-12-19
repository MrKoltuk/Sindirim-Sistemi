extends Node3D

# Besin tipleri
enum BesinTipi { YOK, YAG, PROTEIN, KARBONHIDRAT }

# Mevcut durum
var current_state = BesinTipi.YOK
var son_yenilen = "Henüz besin yenilmedi"
var secili_organ: String = ""

@export var yag_scene: PackedScene
@export var protein_scene: PackedScene
@export var karbonhidrat_scene: PackedScene
var tutulan_besin: Node3D = null
var dragging := false

@onready var respawn_yag = $RespawnPoints/YagPoint
@onready var respawn_protein = $RespawnPoints/ProteinPoint
@onready var respawn_karbonhidrat = $RespawnPoints/KarbonhidratPoint
@onready var respawn_su = $RespawnPoints/SuPoint

# Sürükleme
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
	"Bos": Vector3(-0.018, 2.095, -2.922),
	"Yutak": Vector3(-0.329, 2.576, -0.47),
	"YemekBorusu": Vector3(-0.155, 2.426, -0.244),
	"Safra": Vector3(0.681, 1.99, -0.474),
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
	"Bos": Vector2(50, 100),
	"Yutak": Vector2(900, 100),
	"YemekBorusu": Vector2(930, 100),
	"Safra": Vector2(50, 650),
}

var organ_aciklamalari = {
	"Agiz": {
		BesinTipi.YOK: "Sindirimin başladığı yerdir\nBesinlerin hepsi burada mekanik olarak parçalanır\nTükürük bezlerinden tükürük salgılayarak sindirime\nyardımcı olur.\nTükürük bezlerinin salgıladığı amilaz enzimi\nile karbonhidratların kimyasal sindirimi de burada başlar",
		BesinTipi.YAG: "AĞIZ\n\nYağlar ağızda SİNDİRİLMEZ.\n\nÇalışma Durumu: ❌ Yağ sindirimi yok",
		BesinTipi.PROTEIN: "AĞIZ\n\nProteinler ağızda kimyasal olarak SİNDİRİLMEZ.\nSadece çiğneme olur.\n\nÇalışma Durumu: ❌ Protein sindirimi yok",
		BesinTipi.KARBONHIDRAT: "AĞIZ\n\nKarbonhidratlar ağızda SİNDİRİLİR!\nTükürükteki AMİLAZ enzimi nişastayı parçalar.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor"
	},
	"Mide": {
		BesinTipi.YOK: "Geçici bir depo görevi görür.\nMİDE ÖZSUYU denilen sindirim sıvısını üretir.\nHem mekanik hem de kimyasal sindirim yapabilir.",
		BesinTipi.YAG: "MİDE\n\nYağlar midede SİNDİRİLMEZ.\n\nÇalışma Durumu: ❌ Sindirim Yok",
		BesinTipi.PROTEIN: "MİDE\n\nProteinler midede SİNDİRİLİR!\nPEPSİN enzimi ve HCl asit proteinleri parçalar.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor",
		BesinTipi.KARBONHIDRAT: "MİDE\n\nKarbonhidratlar midede kimyasal olarak sindirilmez!.\nAsit ortam amilaz aktivitesini durdurur.\n\nÇalışma Durumu: ❌ Sindirim durmuş"
	},
	"OnIki_Parmak": {
		BesinTipi.YOK: "",
		BesinTipi.YAG: "ON İKİ PARMAK BAĞIRSAĞI\n\nYağ sindirimi YOĞUN olarak devam eder!\nSafra ve pankreas lipaz enzimi buraya salgılanır.\n\nÇalışma Durumu: ✅ Yağ sindirimi devam ediyor",
		BesinTipi.PROTEIN: "ON İKİ PARMAK BAĞIRSAĞI\n\nProtein sindirimi devam eder!\nPankreas tripsin enzimi salgılar.\n\nÇalışma Durumu: ✅ Protein sindirimi devam ediyor",
		BesinTipi.KARBONHIDRAT: "ON İKİ PARMAK BAĞIRSAĞI\n\nKarbonhidrat sindirimi devam eder!\nPankreas amilaz enzimi salgılar.\n\nÇalışma Durumu: ✅ Karbonhidrat sindirimi devam ediyor"
	},
	"Ince_Bagirsak": {
		BesinTipi.YOK: "Sindirim tamamlandığı organdır.\nBesinler ve diğer moleküller burada kana karışır.",
		BesinTipi.YAG: "İNCE BAĞIRSAK\n\nYağlar ince bağırsakta TAM SİNDİRİLİR!\nSafra yağları emülsifiye eder, LIPAZ parçalar.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor",
		BesinTipi.PROTEIN: "İNCE BAĞIRSAK\n\nProteinler ince bağırsakta TAM SİNDİRİLİR!\nTRİPSİN ve PEPTİDAZ enzimleri amino asitlere ayırır.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor",
		BesinTipi.KARBONHIDRAT: "İNCE BAĞIRSAK\n\nKarbonhidratlar ince bağırsakta TAM SİNDİRİLİR!\nPANKREAS AMİLAZI basit şekerlere ayırır.\n\nÇalışma Durumu: ✅ Aktif olarak sindirim yapıyor"
	},
	"Kalin_Bagirsak": {
		BesinTipi.YOK: "Kalın bağırsak, enzim üretmez ve sindirim YAPMAZ.\nSindirilen besinlerin artıklarını\nanüs yoluyla dışarı atar.",
		BesinTipi.YAG: "KALIN BAĞIRSAK\n\nSindirim tamamlanmış, emilim aşaması.\nSu emilimi ve dışkı oluşumu gerçekleşir.\n\nÇalışma Durumu: 🟡 Sindirim yok, emilim var",
		BesinTipi.PROTEIN: "KALIN BAĞIRSAK\n\nSindirim tamamlanmış, emilim aşaması.\nSu emilimi ve dışkı oluşumu gerçekleşir.\n\nÇalışma Durumu: 🟡 Sindirim yok, emilim var",
		BesinTipi.KARBONHIDRAT: "KALIN BAĞIRSAK\n\nSindirim tamamlanmış, emilim aşaması.\nSu emilimi ve dışkı oluşumu gerçekleşir.\n\nÇalışma Durumu: 🟡 Sindirim yok, emilim var"
	},
	"Karaciger": {
		BesinTipi.YOK: "Kimyasal sindirim YAPMAZ!\nKaraciğerin ürettiği safra sıvısı, safra kanalcıkları ile\nsafra kesesine boşaltılır ve burada depolanır.",
		BesinTipi.YAG: "KARACİĞER\n\nSAFRA üretir!\nSafra yağları küçük damlacıklara böler (emülsifikasyon).\n\nÇalışma Durumu: ✅ Yağ sindirimi için safra salgılıyor",
		BesinTipi.PROTEIN: "KARACİĞER\n\nProtein sindirimi için doğrudan enzim salgılamaz.\nAma sindirilmiş proteinleri işler ve kullanır.\n\nÇalışma Durumu: 🟡 Dolaylı rol",
		BesinTipi.KARBONHIDRAT: "KARACİĞER\n\nKarbonhidrat sindirimi için doğrudan enzim salgılamaz.\nGlükoz depolanması ve kullanımı yapar.\n\nÇalışma Durumu: 🟡 Dolaylı rol"
	},
	"Pankreas": {
		BesinTipi.YOK: "Pankreas özsuyunu üretir.\nAmilaz, Lipaz, Kimotripsinojen, Tripsinojen\nve Nükleik asitlerin sindiriminde\nyer alan nükleaz enzimlerini barındırır",
		BesinTipi.YAG: "PANKREAS\n\nLİPAZ enzimi salgılar!\nYağları yağ asitleri ve gliserole parçalar.\n\nÇalışma Durumu: ✅ Yağ sindirimi için lipaz salgılıyor",
		BesinTipi.PROTEIN: "PANKREAS\n\nTRİPSİN enzimi salgılar!\nProteinleri küçük peptitlere parçalar.\n\nÇalışma Durumu: ✅ Protein sindirimi için tripsin salgılıyor",
		BesinTipi.KARBONHIDRAT: "PANKREAS\n\nAMİLAZ enzimi salgılar!\nNişastayı maltoz ve dekstrinlere parçalar.\n\nÇalışma Durumu: ✅ Karbonhidrat sindirimi için amilaz salgılıyor"
	},
	"Bos": {
		BesinTipi.YOK: "Sindirim Sistemi Simülasyonu'na Hoşgeldiniz :D",
		BesinTipi.YAG: "Yağlar ağız ve mideyi geçerek ince bağırsağa ulaşır.\nPankreas tarafından salgılanan lipaz enzimi\nince bağırsağa dökülür ve yağları parçalar.\nYağlar emilime hazır hale gelir.\n\nVücut durumu: ✅ Yağ sindirimi gerçekleşiyor.",
		BesinTipi.PROTEIN: "Proteinler midede pepsin ile kısmen parçalanır.\nİnce bağırsakta pankreasın salgıladığı tripsin\nve peptidazlar proteinleri amino asitlere ayırır.\n\nVücut durumu: ✅ Protein sindirimi gerçekleşiyor.",
		BesinTipi.KARBONHIDRAT: "Karbonhidratlar ağızda tükürük amilazı ile\nkısmen parçalanır.\nİnce bağırsakta pankreasın salgıladığı amilaz\nkarbonhidratları basit şekerlere dönüştürür.\n\nVücut durumu: ✅ Karbonhidrat sindirimi gerçekleşiyor.",
		},
	"Yutak": {
		BesinTipi.YOK: "YUTAK\n\nBesini yutarken gırtlak kapağı soluk borusunu\nkapatır ve bu sayede boğulmamızı ENGELLER\n\n🌟Sindirim sistemindeki önemli bir parçadır.",
		BesinTipi.YAG: "YUTAK\n\nBesini yutarken gırtlak kapağı soluk borusunu\nkapatır ve bu sayede boğulmamızı ENGELLER\n\n🌟Sindirim sistemindeki önemli bir parçadır.",
		BesinTipi.PROTEIN: "YUTAK\n\nBesini yutarken gırtlak kapağı soluk borusunu\nkapatır ve bu sayede boğulmamızı ENGELLER\n\n🌟Sindirim sistemindeki önemli bir parçadır.",
		BesinTipi.KARBONHIDRAT: "YUTAK\n\nBesini yutarken gırtlak kapağı soluk borusunu\nkapatır ve bu sayede boğulmamızı ENGELLER\n\n🌟Sindirim sistemindeki önemli bir parçadır."
	},
	"YemekBorusu": {
		BesinTipi.YOK: "Yemek borusu, besinleri Peristaltik hareketlerle\nmideye iletmekle görevlidir\nPeristaltik hareketler sayesinde\nbesin yer çekimine zıt olsa\nbile mideye iletilir.\nSindirim YAPMAZ!",
		BesinTipi.YAG: "YEMEK BORUSU\n\nPerostatik hareketler yaparak besinleri mideye indirir\nMukuslu yapısı sayesinde KAYGANDIR\n\nÇalışma Durumu: ✅ Geçit görevinde!",
		BesinTipi.PROTEIN: "YEMEK BORUSU\n\nPerostatik hareketler yaparak besinleri mideye indirir\nMukuslu yapısı sayesinde KAYGANDIR\n\nÇalışma Durumu: ✅ Geçit görevinde!",
		BesinTipi.KARBONHIDRAT: "YEMEK BORUSU\n\nPerostatik hareketler yaparak besinleri mideye indirir\nMukuslu yapısı sayesinde KAYGANDIR\n\nÇalışma Durumu: ✅ Geçit görevinde!"
	},
	"Safra": {
		BesinTipi.YOK: "Sindirime yardımcı organdır.\nMideden gelen Kimus'u nötralize eder.\nAntiseptik özelliği ile bağırsaktaki atıkların\nkokuşmasını ve bakterilerin oluşmasını engeller.",
		BesinTipi.YAG: "SAFRA KESESİ\n\nSafra salgısını virsük kanalına verir.\nSafra salgısı ile beraber yağların\nMekanik sinirimini sağlar.\n\nÇalışma Durumu: ✅ Mekanik sindirim yapmakta!",
		BesinTipi.PROTEIN: "SAFRA KESESİ\n\nProtein sindirimi için enzim SALGILAMAZ.\nSadece yağların sindirimi için safra salgısı depolar.\n\nÇalışma Durumu: ⚪ Protein sindiriminde rol almaz",
		BesinTipi.KARBONHIDRAT: "SAFRA KESESİ\n\nKarbonhidrat sindirimi için enzim SALGILAMAZ.\nSadece yağların sindirimi için safra salgısı depolar.\n\nÇalışma Durumu: ⚪ Karbonhidrat sindiriminde rol almaz"
	},

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
				if parent.name == "Yag" or parent.name == "Protein" or parent.name == "Karbonhidrat" or parent.name == "Su":
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
	
	# Besinin şu anki Z eksenindeki uzaklığını kameradan hesapla
	var besin_z_distance = abs(camera.global_position.z - tutulan_besin.global_position.z)
	
	# Mouse'un o uzaklıktaki 3D pozisyonunu bul
	var yeni_pozisyon = from + normal * besin_z_distance
	
	# Offset'i uygula (tıkladığın noktayı tut)
	yeni_pozisyon += offset
	
	# Z EKSENİNİ SABİTLE - sadece X ve Y hareket edebilir
	var sabit_z = tutulan_besin.global_position.z
	tutulan_besin.global_position = Vector3(yeni_pozisyon.x, yeni_pozisyon.y, sabit_z)

func _on_agiz_area_entered(area):
	if area.get_parent() and area.get_parent() is Node3D:
		var besin = area.get_parent()
		
		if besin.name == "Yag":
			_besin_yenildi(BesinTipi.YAG, "YAĞ", yag_sesi)
		elif besin.name == "Protein":
			_besin_yenildi(BesinTipi.PROTEIN, "PROTEİN", protein_sesi)
		elif besin.name == "Karbonhidrat":
			_besin_yenildi(BesinTipi.KARBONHIDRAT, "KARBONHİDRAT", karbonhidrat_sesi)
		elif besin.name == "Su":
			_besin_yenildi(BesinTipi.YOK, "Su", yag_sesi)


func _besin_yenildi(tip: BesinTipi, isim: String, ses: AudioStreamPlayer):
	current_state = tip
	son_yenilen = isim
	_update_ui()

	if ses and ses.stream:
		ses.play()

	# sadece tutulan besini pasif yap
	if tutulan_besin:
		_besini_pasif_yap(tutulan_besin)

	tutulan_besin = null

	# sadece yenen besini geri getir
	_respawn_besin(tip)

	print("🍽️ YENİLDİ: " + isim)
	# 🔥 STATE DEĞİŞTİ → AÇIKLAMAYI GÜNCELLE
	_organ_aciklamasini_guncelle()




func _organa_git(organ_adi: String):
	secili_organ = organ_adi   # 🔴 EN KRİTİK SATIR
	
	# Organ sesi
	if organ_sesi and organ_sesi.stream:
		organ_sesi.play()
	
	# Kamera
	if kamera_pozisyonlari.has(organ_adi):
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(camera, "position", kamera_pozisyonlari[organ_adi], 0.8)
	
	# Label pozisyonu
	if label_pozisyonlari.has(organ_adi):
		var tween_label = create_tween()
		tween_label.set_ease(Tween.EASE_OUT)
		tween_label.set_trans(Tween.TRANS_CUBIC)
		tween_label.tween_property(
			organ_bilgi_label,
			"position",
			label_pozisyonlari[organ_adi],
			0.5
		)
	
	# 🔥 ASIL İŞ BURADA
	_organ_aciklamasini_guncelle()


func _update_ui():
	if ui_label:
		ui_label.text = "EN SON YENİLEN: " + son_yenilen

func _besini_pasif_yap(besin: Node3D):
	if not besin:
		return
	
	besin.visible = false
	
	var area := besin.get_node_or_null("Area3D")
	if area:
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)


func _respawn_besin(tip: BesinTipi):
	var besin: Node3D
	var spawn: Node3D

	match tip:
		BesinTipi.YAG:
			besin = $Besinler/Yag
			spawn = respawn_yag
		BesinTipi.PROTEIN:
			besin = $Besinler/Protein
			spawn = respawn_protein
		BesinTipi.KARBONHIDRAT:
			besin = $Besinler/Karbonhidrat
			spawn = respawn_karbonhidrat
		BesinTipi.YOK:
			besin = $Besinler/Su
			spawn = respawn_su

	if not besin or not spawn:
		return
	
	besin.global_position = spawn.global_position
	besin.visible = true
	
	var area := besin.get_node_or_null("Area3D")
	if area:
		area.set_deferred("monitoring", true)
		area.set_deferred("monitorable", true)

func _organ_aciklamasini_guncelle():
	if secili_organ == "":
		return
	
	#if current_state == BesinTipi.YOK:
		#organ_bilgi_label.text = "Önce bir besin yemelisin!"
		#organ_bilgi_label.visible = true
		#return
	
	if organ_aciklamalari.has(secili_organ):
		var aciklama = organ_aciklamalari[secili_organ].get(current_state, "")
		if aciklama != "":
			organ_bilgi_label.text = aciklama
			organ_bilgi_label.visible = true
