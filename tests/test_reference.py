"""Offline source-level reference tests. These do NOT execute Godot or validate an APK."""
import ast
from pathlib import Path
import random
import unittest
import subprocess

ROOT = Path(__file__).resolve().parents[1]
source=(ROOT/'scripts/game_logic.gd').read_text()
a=source.split('const SHAPES =',1)[1].split('const THEME_NAMES',1)[0].strip()
SHAPES=ast.literal_eval(a)

def fits(board, shape,x,y):
    return all(0<=x+dx<8 and 0<=y+dy<8 and board[(y+dy)*8+x+dx]==0 for dx,dy in shape)

def place(board, shape,x,y):
    b=board[:]
    if not fits(b,shape,x,y):return None
    for dx,dy in shape:b[(y+dy)*8+x+dx]=1
    rows=[r for r in range(8) if all(b[r*8+c]>0 for c in range(8))]
    cols=[c for c in range(8) if all(b[r*8+c]>0 for r in range(8))]
    affected={r*8+c for r in rows for c in range(8)}|{r*8+c for c in cols for r in range(8)}
    for p in affected:b[p]=0
    return b,rows,cols

class NovaReferenceTests(unittest.TestCase):
    def test_shape_count(self): self.assertGreaterEqual(len(SHAPES),30)
    def test_shapes_are_nonempty(self):
        for shape in SHAPES:self.assertGreater(len(shape),0)
    def test_no_duplicate_cells(self):
        for shape in SHAPES:self.assertEqual(len(shape),len({tuple(c) for c in shape}))
    def test_dimensions_fit_board(self):
        for shape in SHAPES:
            self.assertLess(max(x for x,y in shape),8)
            self.assertLess(max(y for x,y in shape),8)
    def test_connected_shapes(self):
        for shape in SHAPES:
            coords={tuple(xy) for xy in shape}; seen={next(iter(coords))}
            while True:
                more={v for v in coords for u in seen if abs(v[0]-u[0])+abs(v[1]-u[1])==1}
                if more<=seen:break
                seen|=more
            self.assertEqual(seen,coords)
    def test_collision_and_bounds(self):
        b=[0]*64;b[0]=1
        self.assertFalse(fits(b,SHAPES[0],0,0))
        self.assertFalse(fits(b,SHAPES[7],4,0))
        self.assertFalse(fits(b,SHAPES[8],0,4))
    def test_row_and_column_simultaneously(self):
        b=[0]*64
        for c in range(1,8):b[c]=1
        for r in range(1,8):b[r*8]=1
        result=place(b,SHAPES[0],0,0)
        self.assertEqual(result[1],[0]);self.assertEqual(result[2],[0])
        self.assertEqual(sum(result[0]),0)
    def test_invalid_does_not_mutate(self):
        b=[0]*64;b[0]=1;before=b[:]
        self.assertIsNone(place(b,SHAPES[0],0,0))
        self.assertEqual(b,before)
    def test_all_shapes_have_legal_position(self):
        for shape in SHAPES:self.assertTrue(any(fits([0]*64,shape,x,y) for x in range(8) for y in range(8)))
    def test_randomized_states(self):
        rand=random.Random(18629)
        for _ in range(10000):
            board=[rand.choices([0,1,-1],weights=[5,3,1])[0] for _ in range(64)]
            shape=rand.choice(SHAPES);x=rand.randint(-2,9);y=rand.randint(-2,9)
            prev=board[:];result=place(board,shape,x,y)
            self.assertEqual(board,prev)
            if result is not None:
                new,rows,cols=result
                self.assertEqual(len(new),64)
                self.assertTrue(all(v in (-1,0,1) for v in new))
    def test_assets_present(self):
        for name in ['menu','classic','adventure','zen','timed']:
            self.assertTrue((ROOT/'assets/audio/music'/f'{name}.ogg').is_file())
        for name in ['tap','pick','place','fail','clear','combo','reward','win','lose','unlock','power','tick']:
            self.assertTrue((ROOT/'assets/audio/sfx'/f'{name}.ogg').is_file())
    def test_android_export_configuration(self):
        cfg=(ROOT/'export_presets.cfg').read_text()
        self.assertIn('gradle_build/target_sdk="36"',cfg)
        self.assertIn('gradle_build/min_sdk="26"',cfg)
        self.assertIn('architectures/arm64-v8a=true',cfg)

if __name__=='__main__':unittest.main()
