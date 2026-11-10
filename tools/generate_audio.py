"""Creates original, royalty-unencumbered-to-the-user synthetic musical loops and UI SFX.
No sampled third-party recordings or copyrighted melodies are used.
Requires numpy and ffmpeg. Generated assets are shipped with the project.
"""
from pathlib import Path
import numpy as np, subprocess, wave, tempfile, math

ROOT=Path(__file__).resolve().parents[1] / 'assets' / 'audio'
SR=22050
music_profiles={
  'menu': ([48,52,55,59], 0.37, 0),
  'classic': ([45,48,52,57], 0.31, 4),
  'adventure': ([50,53,57,60], 0.40, 7),
  'zen': ([43,47,50,55], 0.25, 10),
  'timed': ([48,55,60,64], 0.49, 13)
}

def sine(f,t):return np.sin(2*np.pi*f*t)
def freq(note):return 440*2**((note-69)/12)
def write_ogg(path, signal):
    signal=np.asarray(signal)
    signal=np.clip(signal,-0.99,0.99)
    with tempfile.NamedTemporaryFile(suffix='.wav',delete=False) as f: tmp=Path(f.name)
    with wave.open(str(tmp),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes((signal*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(tmp),'-c:a','libvorbis','-qscale:a','3',str(path)],check=True)
    tmp.unlink()

def music(name,chord,tempo,shift):
    secs=28
    n=SR*secs
    t=np.arange(n)/SR
    out=np.zeros(n)
    # Generative four-chord rotating harmonic texture, not a known melody.
    for section in range(4):
        a=section*7; b=a+7; local=t[a*SR:b*SR]; fade=np.minimum(1,np.minimum(local*2+0.01,(7-local)*2+0.01))
        sub=np.zeros(len(local))
        chord_notes=[chord[(i+section)%4]+(12 if i==3 else 0) for i in range(4)]
        for j,note in enumerate(chord_notes):
            f=freq(note)
            sub+=((sine(f,local)*0.47)+(sine(f*2.002,local)*0.11)+(sine(f*0.5,local)*0.23)) * (0.09 if name!='zen' else 0.075)
        out[a*SR:b*SR]+=sub*fade
    # Delicate generative arpeggiator with short soft attacks.
    step=60/(86 if name=='timed' else 70)
    for i,at in enumerate(np.arange(0,secs,step)):
        note=chord[(i*3 +shift)%4]+12*(i%3==0)
        start=int(at*SR);length=min(int(1.25*SR),n-start)
        if length<=0:continue
        local=np.arange(length)/SR
        env=np.minimum(1,local*15)*np.exp(-local*(2.8 if name=='zen' else 4.1))
        tone=sine(freq(note),local)+0.22*sine(freq(note)*2.01,local)
        out[start:start+length]+=tone*env*(0.042 if name=='zen' else 0.067)
    # Floating atmospheric whisper and gentle thump in timed mode.
    out+=np.sin(2*np.pi*0.18*t)*0.002
    if name=='timed':
        for at in np.arange(0,secs,0.7):
            start=int(at*SR);length=min(int(0.12*SR),n-start)
            local=np.arange(length)/SR
            out[start:start+length]+=sine(100*np.exp(-local*5),local)*np.exp(-local*45)*0.034
    # Seamless-loop joining: matching endpoints for clean playback.
    m=int(SR*0.25)
    out[-m:]=out[-m:]*np.linspace(1,0,m)+out[:m]*np.linspace(0,1,m)
    write_ogg(ROOT/'music'/f'{name}.ogg',np.tanh(out*1.8))

SFX={
 'tap':(720,0.09), 'pick':(490,0.13),'place':(370,0.22),'fail':(190,0.23),
 'clear':(750,0.5),'combo':(930,0.65),'reward':(820,0.59),
 'win':(540,0.8),'lose':(260,0.6),'unlock':(660,0.5),'power':(470,0.4),'tick':(560,0.16)
}

def sfx(name,f0,d):
    t=np.arange(int(SR*d))/SR
    if name in ('clear','combo','win','reward','unlock'):
        f=f0*(1+0.18*t/d)
        sig=0.47*sine(f,t)+0.23*sine(f*1.5,t)+0.11*sine(f*2.01,t)
    elif name=='fail' or name=='lose':
        sig=0.5*sine(f0*(1-0.5*t/d),t)+0.2*sine(0.61*f0,t)
    else:
        sig=0.6*sine(f0*(1-0.18*t/d),t)+0.2*sine(f0*1.99,t)
    env=np.minimum(1,t*120)*np.exp(-t*(6 if d>0.3 else 17))
    noise=np.random.default_rng(729+int(f0)).normal(0,0.018,len(t))*np.exp(-t*32)
    write_ogg(ROOT/'sfx'/f'{name}.ogg',(sig+noise)*env*0.55)

if __name__=='__main__':
    for name, (notes,tempo,shift) in music_profiles.items(): music(name,notes,tempo,shift)
    for name, (f0,d) in SFX.items(): sfx(name,f0,d)
    print('Generated',len(list(ROOT.rglob('*.ogg'))),'original OGG audio assets')
