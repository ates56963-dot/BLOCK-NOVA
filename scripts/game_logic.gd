class_name NovaLogic
extends RefCounted

# Tek kaynak: oyun kuralı ve veri modeli. Görsellerden bağımsızdır.
const N = 8
const SCHEMA_VERSION = 2
const SHAPES = [
    [[0,0]], [[0,0],[1,0]], [[0,0],[0,1]],
    [[0,0],[1,0],[2,0]], [[0,0],[0,1],[0,2]],
    [[0,0],[1,0],[2,0],[3,0]], [[0,0],[0,1],[0,2],[0,3]],
    [[0,0],[1,0],[2,0],[3,0],[4,0]], [[0,0],[0,1],[0,2],[0,3],[0,4]],
    [[0,0],[1,0],[0,1],[1,1]],
    [[0,0],[1,0],[2,0],[0,1],[1,1],[2,1]],
    [[0,0],[1,0],[0,1]], [[0,0],[0,1],[1,1]], [[1,0],[0,1],[1,1]], [[0,0],[1,0],[1,1]],
    [[0,0],[0,1],[0,2],[1,2]], [[0,0],[1,0],[2,0],[2,1]],
    [[0,0],[1,0],[1,1],[1,2]], [[0,0],[0,1],[1,0],[2,0]],
    [[0,0],[1,0],[2,0],[1,1]], [[1,0],[0,1],[1,1],[1,2]],
    [[0,0],[1,0],[1,1],[2,1]], [[1,0],[2,0],[0,1],[1,1]],
    [[1,0],[0,1],[1,1],[2,1],[1,2]],
    [[0,0],[1,0],[1,1],[2,1],[2,2]],
    [[0,0],[0,1],[1,1],[1,2],[2,2]],
    [[0,0],[1,0],[2,0],[0,1],[0,2]],
    [[0,0],[1,0],[2,0],[2,1],[2,2]],
    [[0,0],[0,1],[0,2],[1,2],[2,2]],
    [[0,0],[0,1],[1,0],[1,1],[0,2],[1,2]]
]
const THEME_NAMES = ["Neon Galaxy", "Crystal Blue", "Golden Luxury", "Cyber Purple", "Ocean Glow", "Sunset Orange", "Emerald World", "Dark Minimal"]
var board: Array = []
var ice: Array = []
var targets: Array = []
var tray: Array = []
var rng := RandomNumberGenerator.new()
var seed_value := 0
var mode := "classic"
var level := 1
var score := 0
var best := 0
var combo := 0
var moves := 0
var lines := 0
var columns := 0
var total_cleared := 0
var remaining := 0.0
var max_moves := 0
var goal_score := 0
var goal_lines := 0
var goal_ice := 0
var goal_targets := 0
var goal_type := "score"
var initial_ice := 0
var initial_targets := 0
var game_over := false
var won := false
var last_event: Dictionary = {}
var previous: Dictionary = {}

func _init() -> void:
    rng.randomize()
    seed_value = int(rng.randi())
    _clear_board()

func _clear_board() -> void:
    board.clear()
    ice.clear()
    targets.clear()
    for i in range(64):
        board.append(0)
        ice.append(0)
        targets.append(false)

func _point(raw: Array) -> Vector2i:
    return Vector2i(int(raw[0]), int(raw[1]))

func shape_cells(shape_id: int) -> Array:
    var result: Array = []
    if shape_id < 0 or shape_id >= SHAPES.size():
        return result
    for xy in SHAPES[shape_id]:
        result.append(_point(xy))
    return result

func shape_bounds(shape_id: int) -> Vector2i:
    var w := 0
    var h := 0
    for v in shape_cells(shape_id):
        w = maxi(w, v.x + 1)
        h = maxi(h, v.y + 1)
    return Vector2i(w, h)

func begin(new_mode: String, stage: int = 1, seconds: int = 60, custom_seed: int = 0) -> void:
    mode = new_mode
    level = clampi(stage, 1, 100)
    seed_value = custom_seed if custom_seed != 0 else int(rng.randi())
    rng.seed = seed_value
    _clear_board()
    tray.clear()
    score = 0
    combo = 0
    moves = 0
    lines = 0
    columns = 0
    total_cleared = 0
    game_over = false
    won = false
    previous.clear()
    remaining = float(seconds) if mode == "timed" else 0.0
    max_moves = 0
    goal_score = 0
    goal_lines = 0
    goal_ice = 0
    goal_targets = 0
    initial_ice = 0
    initial_targets = 0
    goal_type = "score"
    if mode == "adventure":
        _configure_level()
    elif mode == "daily":
        goal_score = 250 + (abs(seed_value) % 5) * 50
        goal_type = "score"
        max_moves = 25
        _daily_initial()
    _refill()

func _configure_level() -> void:
    # 100 seviyelik deterministik kurallar; skor/çizgi, hedef, buz ve engel mekanikleri.
    var band := int((level - 1) / 20)
    max_moves = 21 + band * 3
    goal_type = ["score", "lines", "targets", "ice", "mixed"][int((level - 1) / 20)]
    goal_score = 130 + level * 15
    goal_lines = 1 + int(level / 14)
    if goal_type == "targets" or goal_type == "mixed":
        initial_targets = 2 + int(level / 24)
        goal_targets = initial_targets
        for i in range(initial_targets):
            var at := (level * 7 + i * 11 + 3) % 64
            targets[at] = true
    if goal_type == "ice" or goal_type == "mixed":
        initial_ice = 1 + int(level / 22)
        goal_ice = initial_ice
        for i in range(initial_ice):
            var at := (level * 13 + i * 9) % 64
            board[at] = 1 + ((level + i) % 8)
            ice[at] = 1
    # Engeller yalnızca yüksek seviyelerde, en fazla birkaç tane.
    if level >= 60:
        var blocks := mini(3, 1 + int((level - 60) / 15))
        for i in range(blocks):
            var p := (level * 19 + i * 17) % 64
            if board[p] == 0 and not targets[p]:
                board[p] = -1

func _daily_initial() -> void:
    for i in range(3):
        var p: int = (absi(seed_value) + i * 13) % 64
        board[p] = i + 2

func can_place(shape_id: int, x: int, y: int) -> bool:
    for v in shape_cells(shape_id):
        var cx: int = x + v.x
        var cy: int = y + v.y
        if cx < 0 or cy < 0 or cx >= N or cy >= N:
            return false
        if int(board[cy * N + cx]) != 0:
            return false
    return not shape_cells(shape_id).is_empty()

func placements(shape_id: int) -> Array:
    var result: Array = []
    var dims := shape_bounds(shape_id)
    for y in range(N - dims.y + 1):
        for x in range(N - dims.x + 1):
            if can_place(shape_id, x, y):
                result.append(Vector2i(x,y))
    return result

func available_moves() -> int:
    var total := 0
    for p in tray:
        if not p.is_empty():
            total += placements(int(p["shape"])).size()
    return total

func _refill() -> void:
    tray.clear()
    var possible: Array = []
    for sid in range(SHAPES.size()):
        if placements(sid).size() > 0:
            possible.append(sid)
    if possible.is_empty():
        game_over = true
        return
    # Bir adet kesin yerleşebilir parça, diğerleri boyut ağırlıklı seçimden.
    var first := int(possible[rng.randi_range(0, possible.size()-1)])
    tray.append({"shape":first, "color":rng.randi_range(1,9)})
    for i in range(2):
        var pool: Array = possible.duplicate()
        if rng.randf() >= 0.78:
            pool = range(SHAPES.size())
        var sid: int = int(pool[rng.randi_range(0, pool.size()-1)])
        if sid == first and rng.randf() < 0.75:
            sid = int(possible[rng.randi_range(0, possible.size()-1)])
        tray.append({"shape":sid,"color":rng.randi_range(1,9)})

func _snapshot() -> Dictionary:
    return {"board":board.duplicate(), "ice":ice.duplicate(),"targets":targets.duplicate(),
        "tray":tray.duplicate(true),"score":score,"combo":combo,"moves":moves,
        "lines":lines,"columns":columns,"total_cleared":total_cleared,
        "remaining":remaining,"won":won,"game_over":game_over}

func undo_last() -> bool:
    if previous.is_empty() or mode == "timed" or game_over or won:
        return false
    var p := previous.duplicate(true)
    previous.clear()
    for k in ["board","ice","targets","tray"]:
        set(k, p[k])
    for k in ["score","combo","moves","lines","columns","total_cleared","remaining","won","game_over"]:
        set(k, p[k])
    last_event = {"undo":true}
    return true

func place(slot: int, x: int, y: int) -> Dictionary:
    if game_over or won or slot < 0 or slot >= tray.size() or tray[slot].is_empty():
        return {"ok":false}
    var piece: Dictionary = tray[slot]
    var sid: int = int(piece["shape"])
    if not can_place(sid,x,y):
        return {"ok":false}
    previous = _snapshot()
    var affected_targets := 0
    for v in shape_cells(sid):
        var idx: int = (y + v.y) * 8 + x + v.x
        board[idx] = int(piece["color"])
        if targets[idx]:
            targets[idx] = false
            affected_targets += 1
    tray[slot] = {}
    var rows: Array = []
    var cols: Array = []
    var indices: Dictionary = {}
    for r in range(N):
        var full := true
        for c in range(N):
            if int(board[r * N + c]) <= 0:
                full = false
        if full:
            rows.append(r)
            for c in range(N):
                indices[r * N + c] = true
    for c in range(N):
        var full := true
        for r in range(N):
            if int(board[r * N + c]) <= 0:
                full = false
        if full:
            cols.append(c)
            for r in range(N):
                indices[r * N + c] = true
    var destroyed_ice := 0
    for raw_idx in indices.keys():
        var idx: int = int(raw_idx)
        if int(ice[idx]) > 0:
            ice[idx] = int(ice[idx]) - 1
            if int(ice[idx]) == 0:
                destroyed_ice += 1
        if int(ice[idx]) == 0:
            board[idx] = 0
    var cleared: int = rows.size() + cols.size()
    combo = combo + 1 if cleared > 0 else 0
    lines += rows.size()
    columns += cols.size()
    total_cleared += cleared
    moves += 1
    var base: int = shape_cells(sid).size() * 10
    var bonus: int = cleared * 120 + maxi(0, cleared-1) * 90 + maxi(0, combo-1) * 60
    var perfect := true
    for v in board:
        if int(v) > 0:
            perfect = false
            break
    if cleared > 0 and perfect:
        bonus += 450
    score += base + bonus
    best = maxi(best, score)
    var event := {"ok":true,"points":base+bonus,"rows":rows,"cols":cols,"combo":combo,
        "perfect":cleared>0 and perfect,"ice":destroyed_ice,"targets":affected_targets,"placed":shape_cells(sid).size()}
    if _goal_met():
        won = true
        game_over = true
        event["won"] = true
    elif max_moves > 0 and moves >= max_moves:
        game_over = true
    else:
        var empty := true
        for p in tray:
            if not p.is_empty():
                empty = false
        if empty:
            _refill()
        if not game_over and available_moves() == 0:
            if mode == "zen":
                _clear_board()
                _refill()
            else:
                game_over = true
    event["game_over"] = game_over
    last_event = event
    return event

func _goal_met() -> bool:
    if mode != "adventure" and mode != "daily":
        return false
    match goal_type:
        "score": return score >= goal_score
        "lines": return total_cleared >= goal_lines
        "targets": return _remaining_targets() == 0
        "ice": return _remaining_ice() == 0
        "mixed": return _remaining_targets() == 0 and _remaining_ice() == 0 and score >= int(goal_score * 0.4)
        _: return false

func _remaining_targets() -> int:
    var count := 0
    for t in targets:
        if bool(t): count += 1
    return count

func _remaining_ice() -> int:
    var count := 0
    for t in ice:
        count += int(t)
    return count

func objective() -> String:
    match goal_type:
        "score": return "Hedef: %d / %d puan" % [score, goal_score]
        "lines": return "Satır/sütun: %d / %d" % [total_cleared,goal_lines]
        "targets": return "Işın noktaları: %d kaldı" % _remaining_targets()
        "ice": return "Buz blokları: %d kaldı" % _remaining_ice()
        "mixed": return "Hedef: %d işaret, %d buz" % [_remaining_targets(),_remaining_ice()]
    return ""

func use_power(power: String, cell_index: int = -1) -> bool:
    if game_over or won:
        return false
    if power == "shuffle":
        var options := 0
        for sid in range(SHAPES.size()):
            options += placements(sid).size()
        if options == 0:
            return false
        _refill()
        game_over = false
        return true
    if power == "undo":
        return undo_last()
    if power == "hint":
        return available_moves() > 0
    if cell_index < 0 or cell_index >= 64:
        return false
    var changed := false
    var targets_list: Array = [cell_index]
    if power == "row":
        targets_list.clear()
        for c in range(8): targets_list.append((int(cell_index/8))*8+c)
    elif power == "column":
        targets_list.clear()
        for r in range(8): targets_list.append(r*8+(cell_index%8))
    elif power == "bomb":
        targets_list.clear()
        var x := cell_index%8
        var y := int(cell_index/8)
        for dy in range(-1,2):
            for dx in range(-1,2):
                if x+dx>=0 and x+dx<8 and y+dy>=0 and y+dy<8:
                    targets_list.append((y+dy)*8+x+dx)
    elif power != "hammer":
        return false
    for idx in targets_list:
        if board[idx] != 0 or targets[idx]:
            changed = true
            board[idx] = 0
            ice[idx] = 0
            targets[idx] = false
    if changed and _goal_met():
        won = true
        game_over = true
    if changed and available_moves() == 0 and not game_over:
        game_over = true
    return changed

func to_dict() -> Dictionary:
    return {"schema":SCHEMA_VERSION,"mode":mode,"level":level,"board":board,"ice":ice,
        "targets":targets,"tray":tray,"seed_value":seed_value,"rng_state":str(rng.state),
        "score":score,"best":best,"combo":combo,"moves":moves,"lines":lines,
        "columns":columns,"total_cleared":total_cleared,"remaining":remaining,
        "max_moves":max_moves,"goal_score":goal_score,"goal_lines":goal_lines,
        "goal_ice":goal_ice,"goal_targets":goal_targets,"goal_type":goal_type,
        "initial_ice":initial_ice,"initial_targets":initial_targets,
        "won":won,"game_over":game_over}

func from_dict(d: Dictionary) -> bool:
    if int(d.get("schema", -1)) != SCHEMA_VERSION: return false
    if not d.has("board") or not d.has("tray") or not d.has("ice") or not d.has("targets"): return false
    if d["board"].size()!=64 or d["ice"].size()!=64 or d["targets"].size()!=64 or d["tray"].size()!=3: return false
    for k in ["mode","level","board","ice","targets","tray","seed_value","score","best","combo",
        "moves","lines","columns","total_cleared","remaining","max_moves","goal_score","goal_lines",
        "goal_ice","goal_targets","goal_type","initial_ice","initial_targets","won","game_over"]:
        if d.has(k): set(k, d[k])
    if d.has("rng_state"):
        rng.state = int(d["rng_state"])
    previous.clear()
    return true
