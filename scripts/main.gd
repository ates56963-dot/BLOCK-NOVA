extends Node2D

const Logic = preload("res://scripts/game_logic.gd")
const SAVE_FILE = "user://block_nova_v2.json"
const BACKUP_FILE = "user://block_nova_v2.bak"
const BG_COLORS = [Color("090d29"),Color("071c36"),Color("211708"),Color("130728"),Color("042c40"),Color("281025"),Color("05271e"),Color("11131a")]
const ACCENT_COLORS = [Color("43e8ff"),Color("63c5ff"),Color("ffd56c"),Color("bc78ff"),Color("4ee0cf"),Color("ffa65e"),Color("5cf0ac"),Color("dde6ef")]
const BLOCK_COLORS = [Color("269dff"),Color("13d4da"),Color("a36eff"),Color("f44db4"),Color("f5c943"),Color("ff853e"),Color("24c78a"),Color("eb526a"),Color("7cddff")]
const POWERS = ["hammer","row","column","shuffle","undo","hint","bomb"]
const POWER_LABELS = ["ÇEKİÇ","SATIR","SÜTUN","DEĞİŞ","GERİ","İPUCU","BOMBA"]
const MUSIC = ["menu","classic","adventure","zen","timed"]
var logic: NovaLogic = Logic.new()
var screen := "menu"
var overlay := ""
var buttons: Array = []
var theme_idx := 0
var unlocked_level := 1
var completed: Dictionary = {}
var completed_daily: Dictionary = {}
var collected_rewards: Dictionary = {}
var settings := {"music":0.55,"sfx":0.65,"vibration":true,"quality":2,"reduce_motion":false,"high_contrast":false,"show_tutorial":true}
var stats := {"games":0,"points":0,"placed":0,"rows":0,"cols":0,"max_combo":0,"playtime":0.0,"adventure":0,"dailies":0}
var inventory := {"hammer":5,"row":2,"column":2,"shuffle":3,"undo":3,"hint":10,"bomb":1}
var xp := 0
var tokens := 0
var active_power := ""
var dragging := -1
var pointer_id := -999
var drag_position := Vector2.ZERO
var board_rect := Rect2()
var cell_size := 0.0
var tray_rects: Array = []
var time_elapsed := 0.0
var animation_clock := 0.0
var flash := 0.0
var combo_label := ""
var sparks: Array = []
var stars: Array = []
var info := ""
var show_map_page := 0
var tutorial_step := 0
var tutorial_done := false
var paused := false
var sound_players: Dictionary = {}
var music_player: AudioStreamPlayer
var song_id := ""
var splash: Texture2D
var theme_backgrounds: Array = []
var last_save_clock := 0.0
var hint_cell := Vector2i(-1,-1)
var danger_clock := 0.0

func _ready() -> void:
    randomize()
    splash = load("res://assets/icon.png")
    for i in range(8):
        theme_backgrounds.append(load("res://assets/themes/theme_%d.webp" % i))
    for i in range(56):
        stars.append(Vector3(randf(),randf(),randf_range(0.3,1.5)))
    music_player = AudioStreamPlayer.new()
    add_child(music_player)
    music_player.finished.connect(_music_finished)
    for name in ["tap","pick","place","fail","clear","combo","reward","win","lose","unlock","power","tick"]:
        var p := AudioStreamPlayer.new()
        p.stream = load("res://assets/audio/sfx/%s.ogg" % name)
        add_child(p)
        sound_players[name] = p
    logic.begin("classic")
    _load_progress()
    _song("menu")
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_progress()
    if what == NOTIFICATION_APPLICATION_RESUMED:
        if logic.mode == "timed" and screen == "game": paused = true
        _save_progress()

func _process(delta: float) -> void:
    animation_clock += delta
    flash = maxf(0.0, flash-delta*2.4)
    danger_clock = maxf(0.0, danger_clock-delta)
    if screen == "game" and not paused and not logic.game_over:
        stats["playtime"] = float(stats["playtime"]) + delta
        if logic.mode == "timed":
            logic.remaining = maxf(0.0, logic.remaining-delta)
            if logic.remaining <= 0.0:
                logic.game_over = true
                overlay = "result"
                _finish_run(false)
    for i in range(sparks.size()-1,-1,-1):
        sparks[i]["life"] = float(sparks[i]["life"]) - delta
        sparks[i]["pos"] = sparks[i]["pos"] + sparks[i]["velocity"]*delta
        if sparks[i]["life"] <= 0.0: sparks.remove_at(i)
    last_save_clock += delta
    if last_save_clock > 15.0 and screen == "game":
        last_save_clock=0.0
        _save_progress()
    queue_redraw()

func _draw() -> void:
    buttons.clear()
    var size := get_viewport_rect().size
    var w := size.x
    var h := size.y
    _background(w,h)
    match screen:
        "menu": _menu(w,h)
        "mode": _mode_menu(w,h)
        "game": _game(w,h)
        "map": _map(w,h)
        "daily": _daily(w,h)
        "themes": _themes(w,h)
        "settings": _settings(w,h)
        "stats": _statistics(w,h)
        "achievements": _achievements(w,h)
        "tutorial": _tutorial(w,h)
        _: _menu(w,h)
    _draw_sparks()
    if overlay != "": _overlay(w,h)

func _text(s: String, center: Vector2, size: int=22, color: Color=Color.WHITE, align: HorizontalAlignment=HORIZONTAL_ALIGNMENT_CENTER, width: float=-1.0) -> void:
    var font := ThemeDB.fallback_font
    var line_w := 450.0 if width < 0 else width
    draw_string(font, Vector2(center.x-line_w*0.5,center.y),s,align,line_w,size,color)

func _c(hex: String, alpha: float) -> Color:
    var c:=Color(hex)
    c.a=alpha
    return c

func _box(rect: Rect2, fill: Color, border: Color=Color.TRANSPARENT, radius: int=15, border_w: int=1) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color=fill
    sb.border_color=border
    sb.set_border_width_all(border_w)
    sb.set_corner_radius_all(radius)
    sb.anti_aliasing=true
    sb.anti_aliasing_size=1.1
    draw_style_box(sb,rect)

func _background(w: float,h: float) -> void:
    var bg: Color = BG_COLORS[theme_idx]
    draw_rect(Rect2(0,0,w,h),bg)
    if theme_idx < theme_backgrounds.size() and theme_backgrounds[theme_idx] != null:
        draw_texture_rect(theme_backgrounds[theme_idx],Rect2(0,0,w,h),false,Color(1,1,1,0.78))
    for k in range(28):
        var y := float(k)*h/28.0
        draw_rect(Rect2(0,y,w,h/28+1),Color(ACCENT_COLORS[theme_idx].r*0.11,ACCENT_COLORS[theme_idx].g*0.05,ACCENT_COLORS[theme_idx].b*0.14,0.15*(float(k)/28.0)))
    for i in range(stars.size()):
        var p: Vector3=stars[i]
        var sx := p.x*w+sin(animation_clock*0.1+i)*4.0
        var sy := p.y*h
        draw_circle(Vector2(sx,sy),p.z,Color(0.7,0.88,1.0,0.23+0.17*sin(animation_clock+i)))
    var ambient := ACCENT_COLORS[theme_idx]
    for k in range(6,0,-1):
        draw_circle(Vector2(w*0.5,h*0.05),float(k)*w*0.18,Color(ambient.r,ambient.g,ambient.b,0.008))

func _header(title: String, w: float) -> void:
    _text(title,Vector2(w/2,86),29,Color.WHITE)
    _button("‹",Rect2(22,51,48,52),"back",21,false)

func _button(label: String, r: Rect2, action: String, font_size: int=20, primary: bool=false, disabled: bool=false) -> void:
    var accent: Color=ACCENT_COLORS[theme_idx]
    var col := Color("1b2947") if not primary else accent.darkened(0.47)
    _box(r,col,accent if primary else Color(accent.r,accent.g,accent.b,0.34),15,2 if primary else 1)
    if primary:
        _box(Rect2(r.position.x+4,r.position.y+3,r.size.x-8,3),Color(1,1,1,0.14),Color.TRANSPARENT,3,0)
    _text(label, Vector2(r.position.x+r.size.x/2,r.position.y+r.size.y/2+font_size*0.36), font_size,Color.WHITE if not disabled else Color(0.55,0.57,0.65),HORIZONTAL_ALIGNMENT_CENTER,r.size.x-8)
    buttons.append({"rect":r,"action":action,"disabled":disabled})

func _menu(w: float,h: float) -> void:
    var icon_s:=minf(185,w*0.39)
    _box(Rect2((w-icon_s)/2,77,icon_s,icon_s),Color(0.13,0.10,0.31,0.92),ACCENT_COLORS[theme_idx],34,2)
    if splash:
        draw_texture_rect(splash,Rect2((w-icon_s)/2+8,85,icon_s-16,icon_s-16),false,Color(1,1,1,0.98))
    _text("BLOCK NOVA",Vector2(w/2,303),39,Color("f5f8ff"))
    _text("B L O K   E V R E N İ",Vector2(w/2,333),14,ACCENT_COLORS[theme_idx])
    _text("SEVİYE  %d    •    %d YILDIZ" % [1+int(xp/300),tokens],Vector2(w/2,372),16,Color("a9bfdc"))
    var bw:=minf(w-70,378)
    var x:=(w-bw)/2
    var begin_y:=minf(415,h*0.47)
    _button("▶   OYNA",Rect2(x,begin_y,bw,67),"continue",25,true)
    var names := ["KLASİK","MACERA","ZEN","ZAMAN YARIŞI"]
    var acts := ["classic","map","zen","timed_select"]
    for i in range(4):
        var yy:=begin_y+82+float(int(i/2))*65
        _button(names[i],Rect2(x+(i%2)*(bw/2+6),yy,bw/2-6,55),acts[i],15)
    var base:=begin_y+230
    _button("GÜNLÜK BULMACA",Rect2(x,base,bw,53),"daily",18)
    var mn:=["TEMALAR","BAŞARIM","İSTATİSTİK","AYARLAR"]
    var ma:=["themes","achievements","stats","settings"]
    for i in range(4):
        _button(mn[i],Rect2(x+(i%2)*(bw/2+6),base+66+float(int(i/2))*58,bw/2-6,49),ma[i],14)
    _text("Çevrimdışı • Reklamsız • Özgün",Vector2(w/2,minf(h-18,base+199)),13,Color("7f9bbb"))

func _mode_menu(w: float,h: float) -> void:
    _header("ZAMAN YARIŞI",w)
    _text("Hızlı düşün, blokları yerleştir!",Vector2(w/2,180),19,Color("b5c8ed"))
    _button("60 SANİYE",Rect2(55,247,w-110,69),"time_60",24,true)
    _button("120 SANİYE",Rect2(55,340,w-110,69),"time_120",24)
    _button("180 SANİYE",Rect2(55,433,w-110,69),"time_180",24)
    _text("Her sürenin rekoru ayrı kaydedilir.",Vector2(w/2,565),16,Color("97aed2"))

func _game_layout(w: float,h: float) -> void:
    cell_size = floor(minf((w-48)/8.0,(h-390)/8.0))
    cell_size=maxf(29,cell_size)
    var side:=cell_size*8
    board_rect=Rect2((w-side)/2, minf(h*0.255,215),side,side)
    tray_rects.clear()
    var ty := minf(h-155,board_rect.end.y+45)
    for i in range(3):
        tray_rects.append(Rect2(12+(w-24)/3*i,ty,(w-24)/3,111))

func _game(w: float,h: float) -> void:
    _game_layout(w,h)
    var accent: Color=ACCENT_COLORS[theme_idx]
    _text("BLOCK NOVA",Vector2(w/2,54),26,Color("edf8ff"))
    _button("Ⅱ",Rect2(w-65,27,47,49),"pause",20)
    _button("‹",Rect2(18,27,47,49),"exit_game",23)
    _box(Rect2(24,85,w-48,95),_c("121a37",0.94),Color(accent.r,accent.g,accent.b,0.30),18,1)
    _text("SKOR",Vector2(w*0.28,113),13,Color("9fb1d7"))
    _text("%d" % logic.score,Vector2(w*0.28,148),30,Color.WHITE)
    _text("REKOR",Vector2(w*0.74,113),13,Color("9fb1d7"))
    _text("%d" % logic.best,Vector2(w*0.74,148),26,Color("ffdc80"))
    if logic.mode == "timed":
        _text("KALAN  %d sn" % ceili(logic.remaining),Vector2(w/2,198),17,Color("f2d6fd"))
        _box(Rect2(40,202,w-80,6),Color("263454"),Color.TRANSPARENT,3,0)
        draw_rect(Rect2(41,203,(w-82)*clampf(logic.remaining/180.0,0,1),4),accent)
    elif logic.mode == "adventure" or logic.mode == "daily":
        _text(logic.objective(),Vector2(w/2,204),15,Color("dfd5ff"))
        _text("HAMLE %d/%d" % [logic.moves,logic.max_moves],Vector2(w/2,board_rect.position.y-8),13,Color("a8badc"))
    else:
        _text("%s   •   KOMBO %d" % ["ZEN" if logic.mode=="zen" else "KLASİK",logic.combo],Vector2(w/2,201),16,Color("b2c7e7"))
    _box(board_rect.grow(7),Color("0c1630"),Color(accent.r,accent.g,accent.b,0.64),19,2)
    var preview:=Vector2i(-20,-20)
    var valid:=false
    if dragging >= 0 and dragging < logic.tray.size() and not logic.tray[dragging].is_empty():
        preview = _drag_anchor(drag_position)
        valid = logic.can_place(int(logic.tray[dragging]["shape"]),preview.x,preview.y)
    for row in range(8):
        for col in range(8):
            var idx:=row*8+col
            var cr:=Rect2(board_rect.position+Vector2(col,row)*cell_size+Vector2(2,2),Vector2(cell_size-4,cell_size-4))
            var base_col:=Color("162849") if (row+col)%2==0 else Color("1a2c4d")
            _box(cr,base_col,_c("2d4266",0.55),5,1)
            if bool(logic.targets[idx]):
                draw_circle(cr.get_center(),cell_size*0.32,_c("ffd459",0.4))
                draw_circle(cr.get_center(),cell_size*0.18,_c("f4e395",0.9))
            var v:int=int(logic.board[idx])
            if v>0:
                _tile(cr, BLOCK_COLORS[(v-1)%9])
                if int(logic.ice[idx])>0:
                    _box(cr.grow(-3),Color(0.54,0.91,1.0,0.32),_c("d9f7ff",0.8),5,2)
                    draw_line(cr.position+Vector2(6,6),cr.end-Vector2(7,7),Color.WHITE,1.1)
            elif v<0:
                _box(cr,Color("4b4763"),Color("8d8baf"),5,2)
                draw_line(cr.position+Vector2(5,5),cr.end-Vector2(5,5),Color("a9a2be"),2)
                draw_line(Vector2(cr.end.x-5,cr.position.y+5),Vector2(cr.position.x+5,cr.end.y-5),Color("a9a2be"),2)
            if hint_cell == Vector2i(col,row):
                _box(cr.grow(-1),_c("f4df7a",0.2),_c("ffeaa7",0.95),5,2)
    if dragging>=0 and not logic.tray[dragging].is_empty():
        var piece: Dictionary=logic.tray[dragging]
        var color: Color=Color("4ae7b3") if valid else Color("fa657c")
        for v in logic.shape_cells(int(piece["shape"])):
            var point:=preview+v
            if point.x>=0 and point.x<8 and point.y>=0 and point.y<8:
                var r:=Rect2(board_rect.position+Vector2(point.x,point.y)*cell_size+Vector2(2,2),Vector2(cell_size-4,cell_size-4))
                _box(r,Color(color.r,color.g,color.b,0.24),Color(color.r,color.g,color.b,0.92),5,2)
    for i in range(3):
        var r: Rect2=tray_rects[i]
        _box(r,_c("142344",0.95),Color(accent.r,accent.g,accent.b,0.33),15,1)
        if i < logic.tray.size() and not logic.tray[i].is_empty() and dragging != i:
            _piece_small(logic.tray[i],r.get_center()+Vector2(0,-2),minf(24,cell_size*0.58))
    var bar_y:=h-38
    _button("GÜÇLER",Rect2(7,bar_y-45,(w-45)/4,42),"powers",13)
    _button("DEĞİŞ",Rect2(14+(w-45)/4,bar_y-45,(w-45)/4,42),"power_shuffle",13)
    _button("GERİ AL",Rect2(21+2*(w-45)/4,bar_y-45,(w-45)/4,42),"power_undo",13)
    _button("İPUCU",Rect2(28+3*(w-45)/4,bar_y-45,(w-45)/4,42),"power_hint",13)
    if active_power!="":
        _text("%s seçildi: hücreye dokun" % active_power.to_upper(),Vector2(w/2,bar_y-59),13,Color("fbdb9e"))
    if flash>0 and combo_label!="":
        _text(combo_label,Vector2(w/2,board_rect.position.y+board_rect.size.y/2),27,Color(1.0,0.92,0.51,flash))

func _tile(rect: Rect2,c: Color,alpha: float=1.0) -> void:
    _box(rect,Color(c.r*0.66,c.g*0.66,c.b*0.7,alpha),Color.WHITE if bool(settings["high_contrast"]) else Color(c.r,c.g,c.b,alpha),6,3 if bool(settings["high_contrast"]) else 1)
    var inner:=rect.grow(-2)
    _box(inner,Color(c.r,c.g,c.b,0.95*alpha),Color(1,1,1,0.24*alpha),5,1)
    draw_colored_polygon(PackedVector2Array([inner.position,Vector2(inner.end.x,inner.position.y),Vector2(inner.position.x,inner.end.y)]),Color(1,1,1,0.20*alpha))
    draw_line(inner.position+Vector2(3,2),Vector2(inner.end.x-3,inner.position.y+2),Color.WHITE,2.0*alpha,true)
    draw_line(Vector2(inner.end.x-2,inner.position.y+5),inner.end-Vector2(2,4),Color.BLACK,1.4*alpha,true)
    if int(settings["quality"])>=2 and not bool(settings["reduce_motion"]):
        draw_circle(inner.position+Vector2(inner.size.x*0.22,inner.size.y*0.25),maxf(1,inner.size.x*0.09),Color(1,1,1,0.26*alpha))

func _piece_small(p: Dictionary, center: Vector2, cell: float) -> void:
    var sid:int=int(p["shape"])
    var dims:=logic.shape_bounds(sid)
    var start:=center-Vector2(dims.x,dims.y)*cell/2
    var color: Color=BLOCK_COLORS[(int(p["color"])-1)%9]
    for v in logic.shape_cells(sid):
        _tile(Rect2(start+Vector2(v.x,v.y)*cell+Vector2(1,1),Vector2(cell-2,cell-2)),color)

func _map(w: float,h: float) -> void:
    _header("MACERA HARİTASI",w)
    _text("100 BÖLÜM   •   %d AÇIK" % unlocked_level,Vector2(w/2,135),16,Color("a1d8fa"))
    var start:=show_map_page*20+1
    for j in range(20):
        var level_num:=start+j
        var xx:=30+(j%5)*((w-60)/5+1)
        var yy:=180+int(j/5)*125
        var r:=Rect2(xx,yy,(w-85)/5,90)
        var is_open:=level_num<=unlocked_level
        _box(r,Color("193c61") if is_open else Color("202239"),ACCENT_COLORS[theme_idx] if is_open else Color("3f4662"),17,2 if is_open else 1)
        _text("%02d" % level_num,Vector2(r.get_center().x,r.position.y+43),25,Color.WHITE if is_open else Color("72809f"))
        _text("★" if completed.has(str(level_num)) else ("•" if is_open else "×"),Vector2(r.get_center().x,r.position.y+73),19,Color("ffe081") if is_open else Color("7d8099"))
        buttons.append({"rect":r,"action":"level_%d"%level_num,"disabled":not is_open})
    _button("‹ ÖNCEKİ",Rect2(35,h-108,183,54),"page_prev",17,false,show_map_page==0)
    _button("SONRAKİ ›",Rect2(w-218,h-108,183,54),"page_next",17,false,show_map_page==4)
    _text("%d / 5" % (show_map_page+1),Vector2(w/2,h-30),14,Color("bac6e5"))

func _daily(w: float,h: float) -> void:
    _header("GÜNLÜK BULMACA",w)
    var today:=_today()
    _text(today,Vector2(w/2,177),25,Color("e8e5ff"))
    _text("Her gün yeni bir çevrimdışı görev",Vector2(w/2,217),17,Color("a2b6d8"))
    _box(Rect2(43,255,w-86,215),Color("172341"),Color("58cbef"),24,2)
    _text("GÜNÜN BULMACASI",Vector2(w/2,319),24)
    _text("25 hamlede hedef puana ulaş",Vector2(w/2,362),17,Color("c6d7ef"))
    _text("%s" % ("BUGÜN TAMAMLANDI ✓" if completed_daily.has(today) else "HAZIR"),Vector2(w/2,414),21,Color("7fffe4"))
    _button("BAŞLAT",Rect2(55,509,w-110,66),"start_daily",23,true)
    _text("Tamamlanan gün: %d" % completed_daily.size(),Vector2(w/2,635),17,Color("a9bce0"))

func _themes(w: float,h: float) -> void:
    _header("TEMALAR",w)
    for i in range(8):
        var yy:=140+int(i/2)*146
        var xx:=22+(i%2)*(w/2)
        var rect:=Rect2(xx,yy,w/2-33,128)
        _box(rect,BG_COLORS[i],ACCENT_COLORS[i],18,2)
        for k in range(3):
            _tile(Rect2(rect.position+Vector2(21+k*39,23),Vector2(34,34)),BLOCK_COLORS[(i+k)%9])
        _text(Logic.THEME_NAMES[i],Vector2(rect.get_center().x,rect.position.y+86),15,Color.WHITE)
        _text("SEÇİLİ" if i==theme_idx else "SEÇ",Vector2(rect.get_center().x,rect.position.y+112),13,ACCENT_COLORS[i])
        buttons.append({"rect":rect,"action":"theme_%d"%i,"disabled":false})

func _settings(w: float,h: float) -> void:
    _header("AYARLAR",w)
    var rows: Array = [
        ["MÜZİK", "%d%%"%int(float(settings["music"])*100),"music_setting"],
        ["EFEKTLER", "%d%%"%int(float(settings["sfx"])*100),"sfx_setting"],
        ["TİTREŞİM", "AÇIK" if settings["vibration"] else "KAPALI", "vibration"],
        ["GRAFİK KALİTESİ", ["DÜŞÜK","ORTA","YÜKSEK","ULTRA"][int(settings["quality"])], "quality"],
        ["AZALTILMIŞ HAREKET", "AÇIK" if settings["reduce_motion"] else "KAPALI", "motion"],
        ["YÜKSEK KONTRAST", "AÇIK" if settings["high_contrast"] else "KAPALI", "contrast"]]
    for i in range(rows.size()):
        var yy:=140+i*83
        _box(Rect2(22,yy,w-44,69),Color("192540"),_c("425272",0.55),15)
        _text(rows[i][0],Vector2(w*0.32,yy+42),15)
        _button(rows[i][1],Rect2(w-178,yy+11,147,45),rows[i][2],14)
    _button("ÖĞRETİCİYİ AÇ",Rect2(40,662,w-80,48),"tutorial",16)
    _button("OYUN VERİLERİNİ SİL",Rect2(40,728,w-80,47),"reset_request",16)
    _text("İnternetsiz çalışır. Kişisel veri aktarımı yapılmaz.",Vector2(w/2,824),13,Color("97abc7"))

func _statistics(w: float,h: float) -> void:
    _header("İSTATİSTİKLER",w)
    var items: Array = [
        ["OYNANAN OYUN",stats["games"]], ["TOPLAM PUAN",stats["points"]],
        ["YERLEŞTİRİLEN PARÇA",stats["placed"]], ["TEMİZLENEN SATIR",stats["rows"]],
        ["TEMİZLENEN SÜTUN",stats["cols"]], ["EN YÜKSEK KOMBO",stats["max_combo"]],
        ["TAMAMLANAN BÖLÜM",stats["adventure"]], ["GÜNLÜK BULMACA",stats["dailies"]],
        ["OYUN SÜRESİ (DK)",int(float(stats["playtime"])/60)], ["OYUNCU SEVİYESİ",1+int(xp/300)]]
    for i in range(items.size()):
        var yy:=135+i*67
        _box(Rect2(22,yy,w-44,54),Color("18243d"),_c("3e5276",0.44),12)
        _text(str(items[i][0]),Vector2(w*0.34,yy+34),15)
        _text(str(items[i][1]),Vector2(w*0.82,yy+34),19,ACCENT_COLORS[theme_idx])

func _achievements(w: float,h: float) -> void:
    _header("BAŞARIMLAR",w)
    var rows: Array = [
        ["İlk Adım",int(stats["placed"])>=1,"İlk bloğunu yerleştir"],
        ["Usta Çırak",int(stats["rows"])+int(stats["cols"])>=10,"10 çizgi temizle"],
        ["Kombocu",int(stats["max_combo"])>=3,"3 kombo yap"],
        ["Efsane",int(logic.best)>=2000,"2000 rekor puan"],
        ["Kaşif",int(stats["adventure"])>=10,"10 bölüm tamamla"],
        ["Her Gün",int(stats["dailies"])>=3,"3 günlük bulmaca bitir"]]
    for i in range(rows.size()):
        var yy:=148+i*99
        var won_it:bool=bool(rows[i][1])
        _box(Rect2(24,yy,w-48,82),Color("193a44") if won_it else Color("202540"),Color("71ddbe") if won_it else Color("445073"),16)
        _text("★" if won_it else "◇",Vector2(59,yy+50),27,Color("ffd879") if won_it else Color("7b849d"))
        _text(rows[i][0],Vector2(w*0.53,yy+31),21,Color.WHITE)
        _text(rows[i][2],Vector2(w*0.53,yy+59),14,Color("b2c7dc"))

func _tutorial(w: float,h: float) -> void:
    _header("NASIL OYNANIR?",w)
    var tips: Array = ["1. Alttaki üç bloktan birini seç.","2. Parmağınla tahtaya doğru sürükle.","3. Uygun boş alana bırak.","4. Dolu satırlar ve sütunlar silinir.","5. Arka arkaya silerek kombo yap.","6. Oynamaya başlamak için dokun!"]
    _box(Rect2(30,175,w-60,390),Color("18284a"),ACCENT_COLORS[theme_idx],24,2)
    _text("YILDIZLARA UZAN!",Vector2(w/2,243),27,Color("cef5ff"))
    for i in range(3):
        _tile(Rect2(Vector2(w/2-80+i*50,292),Vector2(47,47)),BLOCK_COLORS[i+1])
    _text(tips[tutorial_step],Vector2(w/2,458),17,Color.WHITE)
    _button("SONRAKİ" if tutorial_step<5 else "OYUNA BAŞLA",Rect2(60,603,w-120,65),"tutorial_next",20,true)
    _button("ATLA",Rect2(60,692,w-120,52),"tutorial_skip",16)

func _overlay(w: float,h: float) -> void:
    draw_rect(Rect2(0,0,w,h),Color(0.02,0.04,0.12,0.80))
    var rect:=Rect2(33,h*0.28,w-66,370)
    _box(rect,Color("1b284c"),ACCENT_COLORS[theme_idx],25,2)
    if overlay == "pause":
        _text("DURAKLATILDI",Vector2(w/2,rect.position.y+67),28)
        _text("İlerlemen otomatik kaydedildi.",Vector2(w/2,rect.position.y+123),17,Color("b6cbe6"))
        _button("DEVAM ET",Rect2(70,rect.position.y+171,w-140,60),"resume",21,true)
        _button("ANA MENÜ",Rect2(70,rect.position.y+247,w-140,59),"to_menu",20)
    elif overlay == "result":
        _text("BÖLÜM TAMAMLANDI!" if logic.won else "OYUN BİTTİ",Vector2(w/2,rect.position.y+64),25,Color("d7faff") if logic.won else Color.WHITE)
        _text("%d PUAN" % logic.score,Vector2(w/2,rect.position.y+139),36,Color("ffd86d"))
        if logic.won:
            _text("★  ★  ★",Vector2(w/2,rect.position.y+186),29,Color("ffe28a"))
        _button("TEKRAR OYNA" if not logic.won else "SONRAKİ BÖLÜM",Rect2(64,rect.position.y+216,w-128,55),"again",19,true)
        _button("ANA MENÜ",Rect2(64,rect.position.y+289,w-128,52),"to_menu",17)
    elif overlay == "reset":
        _text("VERİLERİ SİL?",Vector2(w/2,rect.position.y+71),25)
        _text("Bu işlem geri alınamaz.",Vector2(w/2,rect.position.y+122),16,Color("d8becd"))
        _button("VAZGEÇ",Rect2(70,rect.position.y+177,w-140,57),"reset_cancel",19)
        _button("EVET, SİL",Rect2(70,rect.position.y+249,w-140,57),"reset_confirm",19,true)
    elif overlay == "powers":
        _text("GÜÇLENDİRMELER",Vector2(w/2,rect.position.y+42),22)
        for i in range(7):
            var pp: String=POWERS[i]
            var label: String=POWER_LABELS[i]+"  ×"+str(inventory.get(pp,0))
            var rx:float=52+(i%2)*(w/2-14)
            var ry:float=rect.position.y+62+int(i/2)*62
            _button(label,Rect2(rx,ry,w/2-60,52),"choose_"+pp,12,false,int(inventory.get(pp,0))==0)
        _button("KAPAT",Rect2(100,rect.position.y+324,w-200,39),"reset_cancel",13)
    elif overlay == "message":
        _text(info,Vector2(w/2,rect.position.y+140),20)
        _button("TAMAM",Rect2(70,rect.position.y+230,w-140,57),"reset_cancel",20,true)

func _draw_sparks() -> void:
    for p in sparks:
        var color: Color=p["color"]
        draw_circle(p["pos"],float(p["radius"]),Color(color.r,color.g,color.b,clampf(float(p["life"])*1.3,0,1)))

func _burst(pos: Vector2, color: Color, count: int=18) -> void:
    if bool(settings["reduce_motion"]): return
    var mult:int=[0,1,2,3][int(settings["quality"])]
    for i in range(mini(count*mult,80)):
        var a:=randf()*TAU
        var v:=randf_range(42,160)
        sparks.append({"pos":pos,"velocity":Vector2(cos(a),sin(a))*v,"life":randf_range(0.22,0.75),"radius":randf_range(1.5,3.3),"color":color})
    if sparks.size()>180: sparks=sparks.slice(sparks.size()-180)

func _on_press(pos: Vector2, id: int) -> void:
    if pointer_id != -999: return
    pointer_id=id
    if overlay!="":
        _click(pos)
        return
    if screen=="game" and not paused and not logic.game_over:
        if active_power != "" and board_rect.has_point(pos):
            var col:=int(floor((pos.x-board_rect.position.x)/cell_size))
            var row:=int(floor((pos.y-board_rect.position.y)/cell_size))
            _apply_power(row*8+col)
            pointer_id=-999
            return
        for i in range(tray_rects.size()):
            if tray_rects[i].has_point(pos) and i<logic.tray.size() and not logic.tray[i].is_empty():
                dragging=i
                drag_position=pos
                _sound("pick")
                return
    _click(pos)

func _on_move(pos: Vector2,id: int) -> void:
    if pointer_id!=id: return
    if dragging>=0: drag_position=pos

func _on_release(pos: Vector2,id: int) -> void:
    if pointer_id!=id: return
    pointer_id=-999
    if dragging<0: return
    drag_position=pos
    var target:=_drag_anchor(pos)
    var res:=logic.place(dragging,target.x,target.y)
    dragging=-1
    if res.get("ok",false):
        _after_move(res,pos)
    else:
        _sound("fail")
    queue_redraw()

func _input(e: InputEvent) -> void:
    if e is InputEventScreenTouch:
        if e.pressed: _on_press(e.position,e.index)
        else: _on_release(e.position,e.index)
    elif e is InputEventScreenDrag:
        _on_move(e.position,e.index)
    elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT:
        if e.pressed: _on_press(e.position,-1)
        else: _on_release(e.position,-1)
    elif e is InputEventMouseMotion and dragging>=0 and pointer_id==-1:
        _on_move(e.position,-1)
    elif e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE:
        if overlay=="pause":
            overlay=""
            paused=false
        elif screen=="game": _action("pause")
        else: _action("back")

func _drag_anchor(pos: Vector2) -> Vector2i:
    if dragging<0 or dragging>=logic.tray.size() or logic.tray[dragging].is_empty(): return Vector2i(-10,-10)
    var sid:int=int(logic.tray[dragging]["shape"])
    var dims:=logic.shape_bounds(sid)
    var cx:float=(pos.x-board_rect.position.x)/cell_size - (dims.x-1)*0.5
    var cy:float=(pos.y-75-board_rect.position.y)/cell_size - (dims.y-1)*0.5
    return Vector2i(roundi(cx),roundi(cy))

func _click(pos: Vector2) -> void:
    for i in range(buttons.size()-1,-1,-1):
        if buttons[i]["rect"].has_point(pos) and not buttons[i]["disabled"]:
            _sound("tap")
            _action(str(buttons[i]["action"]))
            break

func _action(act: String) -> void:
    match act:
        "back":
            if screen=="game": _action("exit_game")
            elif screen=="map": screen="menu"
            else: screen="menu"; overlay=""; _song("menu")
        "continue":
            if logic.tray.size()==3 and logic.moves>0 and not logic.game_over:
                _enter_game()
            elif bool(settings["show_tutorial"]) and not tutorial_done:
                screen="tutorial"; tutorial_step=0
            else:
                _start("classic")
        "classic","zen": _start(act)
        "map": screen="map"; _save_progress()
        "timed_select": screen="mode"
        "time_60": _start("timed",1,60)
        "time_120": _start("timed",1,120)
        "time_180": _start("timed",1,180)
        "daily": screen="daily"
        "start_daily": _start("daily",1,60,_daily_seed())
        "themes": screen="themes"
        "settings": screen="settings"
        "stats": screen="stats"
        "achievements": screen="achievements"
        "tutorial": screen="tutorial"; tutorial_step=0
        "tutorial_next":
            if tutorial_step>=5:
                tutorial_done=true; _start("classic")
            else: tutorial_step+=1
        "tutorial_skip": tutorial_done=true; _start("classic")
        "pause": paused=true; overlay="pause"; _save_progress()
        "resume": paused=false; overlay=""
        "exit_game": paused=true; overlay="pause"; _save_progress()
        "to_menu": overlay=""; paused=false; active_power=""; screen="menu"; _song("menu"); _save_progress()
        "again":
            overlay=""
            if logic.won and logic.mode=="adventure": _start("adventure",mini(100,logic.level+1))
            elif logic.mode=="daily": _start("daily",1,60,_daily_seed())
            else: _start(logic.mode,logic.level,ceili(logic.remaining) if logic.mode=="timed" and logic.remaining>0 else 60)
        "page_prev": show_map_page=maxi(0,show_map_page-1)
        "page_next": show_map_page=mini(4,show_map_page+1)
        "reset_request": overlay="reset"
        "reset_cancel": overlay=""
        "reset_confirm":
            DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
            DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_FILE))
            logic=Logic.new(); unlocked_level=1; completed.clear(); completed_daily.clear()
            collected_rewards.clear(); theme_idx=0; tokens=0; xp=0
            stats={"games":0,"points":0,"placed":0,"rows":0,"cols":0,"max_combo":0,"playtime":0.0,"adventure":0,"dailies":0}
            inventory={"hammer":5,"row":2,"column":2,"shuffle":3,"undo":3,"hint":10,"bomb":1}
            overlay=""; screen="menu"; _save_progress()
        "vibration": settings["vibration"]=not bool(settings["vibration"]); _save_progress()
        "motion": settings["reduce_motion"]=not bool(settings["reduce_motion"]); _save_progress()
        "contrast": settings["high_contrast"]=not bool(settings["high_contrast"]); _save_progress()
        "quality": settings["quality"]=(int(settings["quality"])+1)%4; _save_progress()
        "music_setting":
            settings["music"]=float(settings["music"])+0.25
            if float(settings["music"])>1.0:
                settings["music"]=0.0
            _volume()
            _save_progress()
        "sfx_setting":
            settings["sfx"]=float(settings["sfx"])+0.25
            if float(settings["sfx"])>1.0:
                settings["sfx"]=0.0
            _volume()
            _save_progress()
        "powers": overlay="powers"
        "power_hammer": _choose_power("hammer")
        "power_shuffle": _choose_power("shuffle")
        "power_undo": _choose_power("undo")
        "power_hint": _choose_power("hint")
        _:
            if act.begins_with("choose_"):
                overlay=""
                _choose_power(act.trim_prefix("choose_"))
            elif act.begins_with("level_"):
                _start("adventure",int(act.trim_prefix("level_")))
            elif act.begins_with("theme_"):
                theme_idx=int(act.trim_prefix("theme_")); _sound("unlock"); _save_progress()
    queue_redraw()

func _choose_power(p: String) -> void:
    if int(inventory.get(p,0))<=0:
        info="Bu güçlendirme tükendi."; overlay="message"; return
    if p=="shuffle" or p=="undo" or p=="hint":
        var ok:=false
        if p=="hint":
            for i in range(logic.tray.size()):
                if not logic.tray[i].is_empty():
                    var possible:=logic.placements(int(logic.tray[i]["shape"]))
                    if not possible.is_empty():
                        hint_cell=possible[0]
                        ok=true
                        break
        else: ok=logic.use_power(p)
        if ok:
            inventory[p]=int(inventory[p])-1
            _sound("power"); _save_progress()
    else:
        active_power="" if active_power==p else p

func _apply_power(index: int) -> void:
    if active_power=="": return
    var power:=active_power
    active_power=""
    if logic.use_power(power,index):
        inventory[power]=int(inventory[power])-1
        _burst(board_rect.position+Vector2(index%8+0.5,int(index/8)+0.5)*cell_size,Color("ffd783"))
        _sound("power"); _save_progress()

func _start(mode: String, level: int=1, seconds: int=60, custom_seed: int=0) -> void:
    logic.begin(mode,level,seconds,custom_seed)
    stats["games"]=int(stats["games"])+1
    hint_cell=Vector2i(-1,-1)
    _enter_game()
    _save_progress()

func _enter_game() -> void:
    screen="game"; overlay=""; paused=false; active_power=""; dragging=-1
    var track: String=logic.mode
    if track=="daily": track="zen"
    _song(track)

func _after_move(result: Dictionary, pos: Vector2) -> void:
    var gain:int=int(result.get("points",0))
    stats["points"]=int(stats["points"])+gain
    stats["placed"]=int(stats["placed"])+1
    stats["rows"]=int(stats["rows"])+result["rows"].size()
    stats["cols"]=int(stats["cols"])+result["cols"].size()
    stats["max_combo"]=maxi(int(stats["max_combo"]),int(result["combo"]))
    xp+=int(gain/10)
    tokens+=result["rows"].size()+result["cols"].size()
    hint_cell=Vector2i(-1,-1)
    _burst(pos,ACCENT_COLORS[theme_idx],17)
    _sound("place")
    if result["rows"].size()+result["cols"].size()>0:
        combo_label="MEGA BLAST!" if int(result["combo"])>=5 else ("COMBO ×%d!" % int(result["combo"]) if int(result["combo"])>1 else "NOVA CLEAR!")
        flash=1.1
        _burst(board_rect.get_center(),Color("f8e08b"),45)
        _sound("combo" if int(result["combo"])>1 else "clear")
        if bool(settings["vibration"]): Input.vibrate_handheld(22)
    if logic.game_over:
        _finish_run(logic.won)
        overlay="result"
    _save_progress()

func _finish_run(success: bool) -> void:
    if success:
        _sound("win")
        if logic.mode=="adventure":
            var key:=str(logic.level)
            if not completed.has(key):
                completed[key]=3 if logic.moves<=int(logic.max_moves*0.65) else 2
                stats["adventure"]=int(stats["adventure"])+1
                tokens+=10
            unlocked_level=maxi(unlocked_level,mini(100,logic.level+1))
        elif logic.mode=="daily":
            var today:=_today()
            if not completed_daily.has(today):
                completed_daily[today]=logic.score
                stats["dailies"]=int(stats["dailies"])+1
                tokens+=20
    else:
        _sound("lose")
    _save_progress()

func _today() -> String:
    var d: Dictionary=Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [d["year"],d["month"],d["day"]]

func _daily_seed() -> int:
    var d: Dictionary=Time.get_date_dict_from_system()
    return int(d["year"])*10000+int(d["month"])*100+int(d["day"])

func _song(track: String) -> void:
    if not MUSIC.has(track): track="menu"
    if song_id==track: return
    song_id=track
    var path: String="res://assets/audio/music/%s.ogg"%track
    music_player.stop()
    music_player.stream=load(path)
    _volume()
    music_player.play()

func _music_finished() -> void:
    if music_player and music_player.stream: music_player.play()

func _sound(effect: String) -> void:
    if not sound_players.has(effect): return
    var player:AudioStreamPlayer=sound_players[effect]
    if player.playing: player.stop()
    player.pitch_scale=randf_range(0.96,1.04)
    player.volume_db=linear_to_db(maxf(0.0001,float(settings["sfx"])))
    player.play()

func _volume() -> void:
    if music_player:
        music_player.volume_db=linear_to_db(maxf(0.0001,float(settings["music"])*0.6))

func _save_progress() -> void:
    var data: Dictionary={"schema":2,"game":logic.to_dict(),"settings":settings,"stats":stats,
        "inventory":inventory,"unlocked_level":unlocked_level,"completed":completed,"completed_daily":completed_daily,
        "rewards":collected_rewards,"theme":theme_idx,"tokens":tokens,"xp":xp,"tutorial_done":tutorial_done}
    var payload:=JSON.stringify(data)
    var temp_path:=ProjectSettings.globalize_path(SAVE_FILE+".tmp")
    var save_path:=ProjectSettings.globalize_path(SAVE_FILE)
    var bak_path:=ProjectSettings.globalize_path(BACKUP_FILE)
    var f:=FileAccess.open(temp_path,FileAccess.WRITE)
    if f == null: return
    f.store_string(payload)
    f.flush()
    f.close()
    if FileAccess.file_exists(save_path):
        if FileAccess.file_exists(bak_path): DirAccess.remove_absolute(bak_path)
        DirAccess.copy_absolute(save_path,bak_path)
    DirAccess.rename_absolute(temp_path,save_path)

func _load_progress() -> void:
    for path in [SAVE_FILE,BACKUP_FILE]:
        if not FileAccess.file_exists(path): continue
        var txt:=FileAccess.get_file_as_string(path)
        var parsed=JSON.parse_string(txt)
        if not (parsed is Dictionary): continue
        if int(parsed.get("schema",-1))!=2: continue
        if not logic.from_dict(parsed.get("game",{})): continue
        settings.merge(parsed.get("settings",{}),true)
        stats.merge(parsed.get("stats",{}),true)
        inventory.merge(parsed.get("inventory",{}),true)
        unlocked_level=clampi(int(parsed.get("unlocked_level",1)),1,100)
        completed=parsed.get("completed",{})
        completed_daily=parsed.get("completed_daily",{})
        collected_rewards=parsed.get("rewards",{})
        theme_idx=clampi(int(parsed.get("theme",0)),0,7)
        tokens=int(parsed.get("tokens",0))
        xp=int(parsed.get("xp",0))
        tutorial_done=bool(parsed.get("tutorial_done",false))
        return
