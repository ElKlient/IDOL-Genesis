# IDOL Genesis - raport kontenera: ludzie, rece, chod, import

Ten raport jest dla kolejnych kontenerow pracujacych nad gra `IDOL Genesis` w repo:

- GitHub: `ElKlient/IDOL-Genesis`
- branch: `main`
- silnik: Godot 4.x, testowane lokalnie na `Godot 4.7.2.stable`
- platforma docelowa: Android / telefon uzytkownika / Termux

Najwazniejsze: nie tworz projektu od nowa. Najpierw zrob `git pull origin main` i przeczytaj aktualne:

- `docs/CONTAINER_HANDOFF_PROMPT.md`
- `docs/CONTAINER_HANDOFF_WALK_AND_IMPORT.md`
- `scripts/main.gd`
- `scripts/retargeter.gd`
- `project.godot`
- `main.tscn`

## Aktualny stan repo podczas pisania tego raportu

Ten raport powstal po moich zmianach do `0.8.17 NATURAL WALK`.

Po mojej pracy inny kontener zdazyl juz dorzucic:

- `eb9ec9e Add ancient settlement atmosphere`
- plik: `docs/CONTAINER_HANDOFF_PROMPT.md`
- zmiany w: `scripts/main.gd`, `project.godot`
- wersja po tamtym kontenerze: `0.8.18 ANCIENT SETTLEMENT`

Dlatego nowy kontener ma zawsze startowac od aktualnego `main`, a nie od lokalnego starego checkoutu. Nie wolno nadpisywac `0.8.18` lokalna kopia `0.8.17`.

## Co zrobilem w tym kontenerze

### 1. Analiza filmow od uzytkownika

Uzytkownik wyslal testy wideo z telefonu. Pierwszy problem:

- rece obracaly sie wokol wlasnej osi,
- nie szly faktycznie do przodu i do tylu,
- na stopklatkach wygladalo to jak krecenie konczyn w miejscu.

Potem uzytkownik potwierdzil, ze rece juz dzialaja, ale caly chod nadal wyglada zle:

- postacie chodzily jak manekiny,
- brakowalo masy ciala,
- nogi robily prosty sinus,
- stopy prawie nie mialy kontaktu pieta-palce,
- miednica i klatka nie przenosily ciezaru.

Do analizy uzylem stopklatek z filmow i cropow na ludzi.

### 2. Naprawa rak: 0.8.16 ARM AIM

Glowny plik: `scripts/main.gd`.

Wprowadzony kierunek:

- nie zgadywac osi Eulera dla barku,
- zamiast tego celowac kosc ramienia w wyliczony kierunek,
- ramie ma isc przez przestrzen: dol + przod/tyl,
- nie ma sie obracac wokol wlasnej osi.

Wazne funkcje dodane lub przebudowane:

- `quat_xform(q, vec)`
- `pose_bone_base_rotation(v, bone_name)`
- `bone_child_axis(v, child_name)`
- `pose_bone_aim_child(v, bone_name, child_name, target_dir)`
- `pose_walk_arm(v, left, arm_swing, elbow_swing, drop)`

W `pose_walk_arm` ramie uzywa osi dziecka kosci i quaternionowego aimowania. To jest teraz baza dla rak i nie warto wracac do prostego `pose_bone_delta` na zgadywanej osi X/Y/Z.

### 3. Wyciecie wystajacych elementow twarzy

Uzytkownik pisal, ze z modeli wystaja dziwne przedmioty, zwykle twarze i fryzury. Na filmie doklejane prymitywy twarzy wygladaly jak losowe elementy przy glowie.

W `scripts/main.gd` ustawione:

- `USE_HEAD_FACE_ATTACHMENTS=false`

Ogolna zasada: nie doklejaj nowych prymitywow do kosci glowy, dopoki nie ma porzadnego systemu stylizacji glowy/wlosow. Model ma zostac, ale dodatki musza byc kontrolowane.

### 4. Naprawa importu tekstur glTF

Godot przy imporcie plul bledami, bo glTF-y mialy odwolania do nieistniejacych nazw:

- `T_Hair_1_Normal_png.png`
- `T_Eye_Normal_png.png`

Nie dodawalem duzych duplikatow PNG. Zamiast tego poprawilem referencje w:

- `assets/characters/Superhero_Male_FullBody.gltf`
- `assets/characters/Superhero_Female_FullBody.gltf`

Docelowe poprawne URI:

- `T_Hair_1_Normal.png`
- `T_Eye_Normal.png`

Po tej zmianie import Godota przeszedl czysto.

### 5. Szybszy przeplyw Termux/Godot

Uzytkownik narzekal, ze po kliknieciu w Godocie trzeba czekac na ladowanie plikow.

Dodane do repo:

```gitignore
.godot/
.import/
*.import
```

Zasada dla telefonu:

- nie kasowac `.godot` przy zwyklych update'ach kodu,
- nie robic `git stash -u`, bo moze zabrac lokalny cache/importy,
- kasowanie cache tylko przy duzych zmianach assetow lub gdy Godot ewidentnie sie zapetlil.

### 6. Naturalniejszy chod: 0.8.17 NATURAL WALK

Uzytkownik powiedzial, ze rece dzialaja, ale ludzie chodza nienaturalnie. Poprawka dotyczyla calego proceduralnego chodu doroslych.

W `scripts/main.gd`:

- `VERSION_TITLE` bylo ustawione na `IDOL — GENESIS 0.8.17 NATURAL WALK`
- `cache_pose_bones()` dostalo kosc `pelvis`
- dodane helpery:
  - `soft01(x)`
  - `pulse01(x)`
  - `pose_walk_leg(v, left, leg_phase, stride, knee_amount, foot_amount, side_amount)`

Co robi `pose_walk_leg`:

- oddziela faze wymachu nogi od fazy podparcia,
- dodaje wybicie palcami,
- dodaje ustawienie piety,
- zgina kolano bardziej w fazie wymachu,
- rusza `foot_l/foot_r` i `ball_l/ball_r`,
- dodaje lekki yaw/roll uda, zeby noga nie byla nozycami.

W `apply_bone_pose(v, moving)` dla ruchu:

- dodana praca `pelvis`,
- dodany kontr-balans `spine_01`, `spine_02`, `spine_03`,
- barki dalej korzystaja z mechaniki rak z `0.8.16`,
- przy niesieniu ladunku krok jest troche mniejszy.

W `apply_living_pose(v, d, moving, flat_dir)`:

- faza chodu zalezy od ruchu, doroslosci, dex i ladunku,
- root postaci ma lekki bob,
- root dostal staly marszowy pitch i mocniejszy roll,
- to ma dac wrazenie masy ciala, a nie przesuwania figurki po szynie.

## Testy wykonane lokalnie

Godot zostal pobrany i odpalony w kontenerze:

```bash
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --version
```

Wynik:

```text
4.7.2.stable.official.ed1daf0bf
```

Import/editor:

```bash
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path /workspace/scratch/ad3cb27c6389/repo --quit
```

Start sceny:

```bash
timeout 12s /workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path /workspace/scratch/ad3cb27c6389/repo --quit-after 3
```

Oba testy przeszly bez bledow skryptu. Brak `xvfb-run`, wiec nie bylo pelnego lokalnego renderu okna po stronie kontenera. Ocena wizualna byla z filmow uzytkownika i stopklatek.

## Commity z mojej pracy

Najwazniejsze commity, ktore robil ten kontener:

- `c39e711` / `a59299e` - pierwsza proba poprawy osi rak jako `0.8.15 ARM SWING`
- `3edb196`, `cee3e67`, `28cdd2c`, `a5d0032` - `0.8.16 ARM AIM`, czyli aimowanie kosci ramienia i wylaczenie wystajacych twarzy
- `5878601` - `.gitignore` dla cache Godota
- `ed77e08` - poprawione referencje tekstur w glTF
- `f4d34a6` - `0.8.17 NATURAL WALK`, naturalniejszy proceduralny chod

Po tym wszystkim inny kontener dodal:

- `eb9ec9e` - `0.8.18 ANCIENT SETTLEMENT`, klimat osady i raport ogolny

## Miejsca w kodzie, ktorych nie ruszac bez czytania

Najpierw przeczytaj okolice tych funkcji w `scripts/main.gd`:

- `cache_pose_bones`
- `cache_pose_bone_rotations`
- `pose_bone_delta`
- `pose_bone_delta_quat`
- `pose_bone_aim_child`
- `pose_walk_arm`
- `pose_walk_leg`
- `apply_bone_pose`
- `apply_living_pose`
- `desired_move_direction`
- `obstacle_avoidance`
- `apply_settlement_spacing`
- `_process`

Nie rob szerokiego refaktoru w `scripts/main.gd`, jesli zadanie jest waskie. Ten plik ma duzo systemow naraz i latwo przypadkiem rozwalic kamere, UI, AI albo budowe.

## Znane ograniczenia po mojej pracy

Chod jest poprawiony proceduralnie, ale to nadal nie jest final AAA:

- nie ma prawdziwego foot lockingu na ziemi,
- nie ma IK stopy do terenu,
- nie ma blend tree dla idle/walk/work/carry,
- retargeter istnieje, ale `USE_RETARGETED_ANIMATIONS=false`,
- realny kolejny duzy krok to albo porzadny retarget z UAL2, albo lekka autorska biblioteka animacji pod ten skeleton.

Wazne: uzytkownik chce, aby obecny model ludzi zostal. Nie wymieniac modeli ludzi bez jasnej zgody.

## Komenda dla uzytkownika w Termux

Uzywana dotad bezpieczna forma:

```bash
cd /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git config --global --add safe.directory /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git stash push -m "backup przed update" && git pull origin main && git --no-pager log -5 --oneline
```

Nie dodawaj `rm -rf .godot`. Nie dodawaj `git stash -u` przy zwyklym update.

## Prompt do wklejenia kolejnemu kontenerowi

```text
Pracujesz nad gra Godot 4 `IDOL Genesis`, repo `ElKlient/IDOL-Genesis`, branch `main`.

Nie tworz projektu od nowa. Najpierw pobierz aktualny `main` i przeczytaj:

- `docs/CONTAINER_HANDOFF_PROMPT.md`
- `docs/CONTAINER_HANDOFF_WALK_AND_IMPORT.md`
- `project.godot`
- `main.tscn`
- `scripts/main.gd`
- `scripts/retargeter.gd`

Aktualna wazna historia:

- `0.8.16 ARM AIM`: rece przestaly krecic sie wokol wlasnej osi. Nie wracaj do prostego Eulera na barkach. Ruch rak bazuje na `pose_walk_arm` i aimowaniu kosci.
- `0.8.17 NATURAL WALK`: poprawiono proceduralny chod doroslych. Sa fazy nogi, praca miednicy, stopy, palcow i root bob.
- `0.8.18 ANCIENT SETTLEMENT`: inny kontener dodal klimat osady, lekka scenerie, root gear i visible cargo.

Priorytety uzytkownika:

- model ludzi ma zostac,
- ludzie sa centralna czescia gry i musza wygladac wiarygodnie,
- gra ma byc lekka na Androidzie,
- nie kasowac `.godot` przy zwyklych pullach,
- nie rozwalac kamery mobilnej, UI, rozmow i AI osady przy poprawkach wizualnych.

Jesli poprawiasz ludzi dalej, skup sie na:

- retargetingu `UAL2_Standard.glb` lub kontrolowanym blend tree,
- foot lockingu i IK stop,
- lepszych idle/work/carry poses,
- prostych twarzach/fryzurach bez wystajacych prymitywow,
- minimalnych, testowalnych zmianach w `scripts/main.gd`.
```
