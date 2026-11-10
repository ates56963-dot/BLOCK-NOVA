extends SceneTree

const Logic = preload("res://scripts/game_logic.gd")
var checks := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        push_error("TEST FAILED: " + label)
        quit(1)

func _initialize() -> void:
    var g = Logic.new()
    g.begin("classic",1,60,9001)
    check(g.board.size()==64,"board 8x8")
    check(g.tray.size()==3,"three-piece tray")
    check(Logic.SHAPES.size()==30,"30 shapes")
    for i in range(Logic.SHAPES.size()):
        check(g.shape_cells(i).size()>0,"nonempty shape")
        check(g.can_place(i,0,0),"empty board accepts valid shape")
    g.board[0]=3
    check(not g.can_place(0,0,0),"occupied cell rejected")
    check(not g.can_place(7,5,0),"right edge rejected")
    check(not g.can_place(8,0,4),"bottom edge rejected")
    g._clear_board()
    for c in range(7):g.board[c]=3
    g.tray=[{"shape":0,"color":1},{},{ }]
    var res = g.place(0,7,0)
    check(res["ok"],"last row cell accepted")
    check(res["rows"].size()==1,"one row cleared")
    check(g.board[0]==0 and g.board[7]==0,"cleared cells empty")
    check(g.score==580,"base + one row + perfect clear scoring")
    g._clear_board()
    g.combo=0
    for c in range(1,8):g.board[c]=1
    for r in range(1,8):g.board[r*8]=1
    g.tray=[{"shape":0,"color":2},{},{ }]
    res=g.place(0,0,0)
    check(res["rows"].size()==1 and res["cols"].size()==1,"row and column together")
    check(g.board[0]==0,"intersection cleared once")
    check(g.score>=130,"scoring is additive")
    var snapshot=g.to_dict()
    var restored=Logic.new()
    check(restored.from_dict(snapshot),"save restore")
    check(restored.board==g.board and restored.score==g.score,"save equality")
    var before=g.board.duplicate()
    var before_score=g.score
    res=g.place(1,-1,-1)
    check(not res["ok"] and before==g.board and g.score==before_score,"invalid move does not mutate")
    for lvl in range(1,101):
        g.begin("adventure",lvl,60,lvl+200)
        check(g.level==lvl and g.max_moves>0 and g.tray.size()==3,"adventure level initialized")
    var r = RandomNumberGenerator.new()
    r.seed=1234567
    for repeat in range(750):
        g.begin("classic",1,60,int(r.randi()))
        var turns=0
        while not g.game_over and turns<130:
            var candidates=[]
            for i in range(g.tray.size()):
                if g.tray[i].is_empty():continue
                var available=g.placements(int(g.tray[i]["shape"]))
                for pos in available: candidates.append([i,pos])
            check(not candidates.is_empty(),"no false game over")
            var chosen=candidates[int(r.randi_range(0,candidates.size()-1))]
            var old_score=g.score
            var ev=g.place(chosen[0],chosen[1].x,chosen[1].y)
            check(ev["ok"] and g.score>=old_score,"randomized placement and score")
            turns+=1
    print("GODOT LOGIC TESTS PASSED: ",checks)
    quit(0)
