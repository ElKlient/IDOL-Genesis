# IDOL Genesis - prompt dla kolejnych kontenerow

Pracujesz nad repozytorium `ElKlient/IDOL-Genesis`, gra w Godot 4.x na Androida. Nie zakladaj nowego projektu i nie wymieniaj dzialajacych mechanik ludzi bez potrzeby. Najpierw przeczytaj `WORKFLOW_FIRST.md`, potem:

- `project.godot`
- `main.tscn`
- `scripts/main.gd`
- `scripts/retargeter.gd`
- `assets/third_party_model_packs/README.md`

Aktualny cel klimatu: niskopoligonowa osada epoki kamienia / wczesnego sredniowiecza. Ma byc ziemia, ogien, patyki, kamien, jagody, skory, jelenie, suszarnie skor, prymitywne narzedzia, oszczepy i delikatna zapowiedz pozniejszej stali/mieczy. Gra ma zostac lekka na Androidzie.

## Biezace zadania B/C/D/E

Kontener A zostawia konkretne zadania w `docs/container_tasks/`. Kazdy kontener pomocniczy ma po starcie przeczytac odpowiedni plik:

- B: `docs/container_tasks/CONTAINER_B_TASK.md`
- C: `docs/container_tasks/CONTAINER_C_TASK.md`
- D: `docs/container_tasks/CONTAINER_D_TASK.md`
- E: `docs/container_tasks/CONTAINER_E_TASK.md`

Jesli kontener jest aktywny albo czeka, ma co 35 minut sprawdzac `WORKFLOW_FIRST.md`, swoj task file i swoj log. Jesli host nie pozwala na samodzielne wybudzanie, kontener ma to powiedziec uzytkownikowi w statusie.

Kontenery B/C/D/E moga uruchamiac swoich subagentow do waskich analiz albo malych rozlacznych zadan w swojej dziedzinie. Subagenci nie sa osobnymi wlascicielami integracji. Za log, commit, push i decyzje odpowiada glowny kontener.

## Raporty kontenerow do Kontenera A

Kazdy kontener pomocniczy po analizie ma zapisac raport w swoim logu pod `docs/container_logs/` i wypchnac go na GitHub. Format raportu:

1. co sprawdzilem,
2. jakie pliki/funkcje sa wazne,
3. czy zmienilem kod albo tylko analizowalem,
4. commit SHA, jesli cos wypchnalem,
5. ryzyka i brakujace testy,
6. decyzja dla Kontenera A: integrowac / odrzucic / poczekac / wymaga testu na Androidzie.

Przypisane logi:

- B: `docs/container_logs/CONTAINER_B_LOG.md`
- C: `docs/container_logs/CONTAINER_C_LOG.md`
- D: `docs/container_logs/CONTAINER_D_LOG.md`
- E: `docs/container_logs/CONTAINER_E_LOG.md`

Priorytet integracji dla Kontenera A: D -> B -> C -> E. Najpierw stabilnosc i import Androida, potem ludzie/animacje, potem swiat/assets, potem gameplay. Nie lacz zmian w ciemno tylko dlatego, ze sa nowe.

## Termux na telefonie uzytkownika

Nie myl terminala kontenera Codex z Termuxem na telefonie. Uzytkownik ma projekt na Androidzie w pamieci wspoldzielonej. Aktywna sciezka robocza ustalona wczesniej:

- `/storage/emulated/0/IDOL-Genesis/IDOL-Genesis`
- w Termuxie to zwykle takze: `~/storage/shared/IDOL-Genesis/IDOL-Genesis`

Jednolinijkowa komenda dla uzytkownika do wklejenia w Termux przy zwyklym update z GitHuba:

```bash
cd /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git config --global --add safe.directory /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git stash push -m "backup przed update" && git pull origin main && git --no-pager log -5 --oneline
```

Nie podawaj uzytkownikowi `cd ~/IDOL-Genesis`, bo to juz wczesniej dawalo `No such file or directory` / `not a git repository`. Nie dodawaj `rm -rf .godot` przy zwyklym update, bo spowalnia Godota. Nie dodawaj `git stash -u`, bo moze schowac lokalny cache/importy.

Po `git pull` uzytkownik otwiera projekt z aplikacji Godot na Androidzie, z folderu zawierajacego `project.godot`, `main.tscn`, `assets`, `scripts`, `README.txt`. Godot Android nie odpala binarki linuxowej z `/workspace/...`.

## Dostep do Godota w kontenerach

Nie zakladaj od razu, ze w kontenerze nie ma Godota. Ten projekt byl juz testowany z binarka Godot 4.7.2 znaleziona w scratchu innego kontenera:

- `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64`

Jesli `command -v godot` i `command -v godot4` nic nie zwracaja, najpierw przeszukaj scratch:

- `find /workspace/scratch -maxdepth 5 -type f -iname '*godot*'`

Na swiezym checkoutcie surowe `.gltf` moga jeszcze nie miec importu. Wtedy zwykle `--headless --path . --quit` moze pokazac parse error typu `has no resource loaders`. Nie koncz na tym. Najpierw wymus import w trybie edytora:

- `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit`

Potem odpal walidacje runtime ta sama binarka:

- `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --quit`

Jezeli ta sciezka w danym kontenerze nie istnieje, dopiero wtedy raportuj brak lokalnego Godota albo pobieraj/odtwarzaj narzedzie, jesli masz do tego dostep.

Godot 4.7 moze po imporcie utworzyc pliki `*.gd.uid`. Nie stage'uj ich automatem razem z naprawa gameplayu/scenerii. Najpierw zdecyduj, czy aktualny task faktycznie dotyczy migracji UID / polityki repo.

## Stan po passcie `0.8.18 Ancient Settlement`

Ten kontener wdrozyl klimat jako lekka proceduralna warstwe swiata w `scripts/main.gd`. Nie byly dodawane ciezkie assety ani nowe zewnetrzne importy.

Zmienione elementy:

- `VERSION_TITLE` ustawione na `IDOL — GENESIS 0.8.18 ANCIENT SETTLEMENT`.
- `project.godot` ustawione na `IDOL Genesis 0.8.18 Ancient Settlement`.
- `_ready()` po `make_camp_clutter()` wywoluje `make_ancient_settlement_scene()`.
- `make_terrain_layers()` dostalo dodatkowe place: suszarnie skor, plac narzedzi, zalazek kuzni, laka jeleni i daleki grzbiet.
- `make_world_details()` dostalo sciezki do nowych punktow oraz dodatkowe zrodla patykow, kamieni i jagod.
- `USE_SETTLER_ROOT_GEAR=true`, zeby ludzie mieli lekkie skorzano-futrzane nakladki, pasy i torby bez wymiany modelu.
- `USE_FLOATING_CARGO=true`, zeby praca ludzi byla widoczna: niosa patyki, kamien albo jagody do skladu.
- Dodane funkcje scenerii:
  - `make_ancient_settlement_scene()`
  - `make_distant_ridge()`
  - `make_smoke_column(p, scale)`
  - `make_hide_rack_at(p, rot, hide_col)`
  - `make_tool_yard(p, rot)`
  - `make_stone_axe(parent, p, rot)`
  - `make_spear_bundle(p, rot)`
  - `make_bone_offering(p, rot)`
  - `make_wild_deer(p, rot, scale, stag=false)`
  - `make_iron_age_hint(p, rot)`
  - `make_river_camp_details()`

Najwazniejsze: dekoracyjne klastry dodaja `add_obstacle(...)`, zeby obecne AI ludzi obchodzilo je zamiast wchodzic w suszarnie, plac narzedzi albo zalazek kuzni.

## Mechaniki, ktore juz dzialaja

Centralny plik gry to `scripts/main.gd`. Tam sa obecnie:

- 10 osadnikow startowych.
- Zasoby: `sticks`, `stone`, `berries`.
- Budynki: domy, spichlerz, warsztat.
- Akcje/tryby: `AUTO`, `PATYKI`, `KAMIEŃ`, `JAGODY`, `BUDOWA`, `WSPÓLNOTA`, `ODKRYCIA`, `DZIECKO`.
- Idol, wola Idola, blogoslawienstwo, postep odkryc, wiezi spoleczne, rodziny i dzieci.
- Ruch ludzi, unikanie tlumu i przeszkod, wybieranie postaci, kamera mobilna, pinch zoom i sticki ekranowe.
- Proceduralna poza kosci ludzi przy `USE_PROCEDURAL_BONE_POSE=true`.
- Retargeter animacji istnieje w `scripts/retargeter.gd`, ale aktualnie `USE_RETARGETED_ANIMATIONS=false`.

## Zasady assetow

Silnik: Godot 4.x, renderer `gl_compatibility`, Android. Preferuj `.glb` / `.gltf`. Nie importuj calych paczek do sceny.

Obecnie w `assets/third_party_model_packs/` sa paczki trzymane jako vendor source z `.gdignore`:

- Kenney Nature Kit GLB
- Kenney Survival Kit GLB
- Kenney Mini Characters GLB
- KayKit Medieval Hexagon Pack

Jesli promujesz model do gry:

1. Sprawdz licencje i format.
2. Przenies lub utworz wrapper scene w normalnych assetach gry, nie edytuj vendor source.
3. Ogranicz tekstury do mobilnych rozmiarow, zwykle 512-1024 px.
4. Dbaj o niski polycount i mala liczbe obiektow aktywnych.
5. Nie uzywaj Unity-only prefabow jako zrodla prawdy.

Rekomendowany klimat paczek na przyszlosc:

- Quaternius Medieval Village MegaKit - chaty, palisady, wozy, zabudowa.
- Quaternius Fantasy Props MegaKit - kufry, warsztaty, worki, ogniska, bron jako rekwizyty.
- Quaternius Stylized Nature MegaKit - drzewa, kamienie, krzewy, teren.
- Quaternius Ultimate Animated Animal Pack - jelenie i zwierzeta, jesli robisz wildlife z AI.
- Quaternius Universal Base Characters oraz Modular Character Outfits - jesli kiedys wymieniasz sylwetki/ubrania.
- KayKit Resource Bits / RPG Tools Bits - male surowce i narzedzia.

## Gdzie pracowac wedlug dziedziny

Sceneria i teren:
Pracuj w `make_terrain_layers()`, `make_world_details()` i helperach zaczynajacych sie od `make_...`. Pilnuj, zeby dekoracje byly tanie: `BoxMesh`, `CylinderMesh`, `SphereMesh`, kilka instancji GLB tylko gdy naprawde warto.

Ludzie i animacje:
Czytaj najpierw `make_person`, `make_person_body`, `apply_living_pose`, `apply_bone_pose`, `pose_walk_arm`, `pose_walk_leg` i `scripts/retargeter.gd`. Nie wymieniaj modelu czlowieka bez sprawdzenia nazw kosci, skali, osi i aktualnego problemu z rekami.

AI, praca i zasoby:
Szukaj funkcji zwiazanych z `choose_task`, `finish_job`, `update_person`, `stock`, `stick_sources`, `stone_sources`, `berry_sources`, `build_plan`. Koszty budowy trzymaj spojnie z UI.

Budynki:
Szukaj `make_house`, `make_granary`, `make_workshop`, `make_build_site`, `register_home_spot`. Nowy budynek powinien miec koszt, miejsce, wizualny stan budowy, efekt po ukonczeniu i czytelny opis w UI.

Wildlife:
Startuj od `make_wild_deer(...)`, ale jesli jelenie maja zyc, zrob oddzielna tablice zwierzat i lekki update z limitem sztuk. Nie dawaj pelnej fizyki i nie spawnuj setek obiektow.

Kamera i mobile:
Ruszaj tylko stale kamery oraz obsluge inputu/touch, jesli zadanie jest o kamerze. Zachowaj jeden palec do przesuwania mapy, pinch zoom i dwa palce do rotacji.

UI:
Gra dziala na Androidzie, wiec tekst ma byc czytelny, przyciski duze, bez drobnych paneli. Nie przykrywaj widoku osady.

## Przed commitem

Minimum sprawdzen:

- `git diff --check`
- Godot headless. Najpierw `command -v godot`, potem `command -v godot4`, a jesli ich nie ma, szukaj w `/workspace/scratch`. Na swiezym checkoutcie najpierw uruchom import: `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit`, potem runtime: `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --quit`
- Otworzyc scene i sprawdzic, czy nie ma szarego ekranu ani parse error.
- Sprawdzic, czy ludzie dalej chodza, pracuja, omijaja przeszkody i nie gubia rak.
- Sprawdzic na Androidzie/FPS, jesli zmiana dodaje duzo obiektow.

## Czego nie robic

- Nie rob `git reset --hard`, `git checkout --` ani force-push bez jasnej prosby uzytkownika.
- Nie usuwaj zmian innych kontenerow/uzytkownika.
- Nie zakladaj nowej gry ani nowego glownego systemu, jesli mozna dopiac funkcje do obecnego.
- Nie importuj ogromnych paczek bez selekcji.
- Nie zmieniaj retargetera, modelu ludzi ani kosci przy zadaniach dotyczacych samego terenu/scenerii.
- Nie rozbijaj jednego malego taska na wielka architekture.
- Nie commituj automatycznie plikow `*.gd.uid` wygenerowanych samym uruchomieniem edytora, jesli task nie dotyczy Godot UID.

## Gotowy prompt do wklejenia dla nowego kontenera

Masz pracowac nad `ElKlient/IDOL-Genesis`, Godot 4.x Android, branch `main`. Najpierw przeczytaj `project.godot`, `main.tscn`, `scripts/main.gd`, `scripts/retargeter.gd` i `assets/third_party_model_packs/README.md`. Aktualny klimat to `0.8.18 Ancient Settlement`: lekka niskopoligonowa osada epoki kamienia / wczesnego sredniowiecza z idolem, ludzmi, patykami, kamieniem, jagodami, skorami, suszarniami skor, narzedziami kamiennymi, jeleniami i zapowiedzia pozniejszej stali. Nie zakladaj nowego projektu i nie psuj dzialajacych ludzi. Mechaniki ludzi, zasobow, budowy, rodzin, idola, kamery i UI sa glownie w `scripts/main.gd`. Jesli uzytkownik pyta co wkleic w Termux, podaj aktywna sciezke `/storage/emulated/0/IDOL-Genesis/IDOL-Genesis` i komende: `cd /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git config --global --add safe.directory /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git stash push -m "backup przed update" && git pull origin main && git --no-pager log -5 --oneline`. Jesli zadanie dotyczy scenerii, pracuj przez proceduralne helpery `make_...`; jesli ludzi, przeczytaj funkcje pozy kosci i `retargeter.gd`; jesli assetow, promuj tylko wybrane `.glb/.gltf` do wlasnych assetow gry, vendor paczki zostaw w `assets/third_party_model_packs/`. Po zmianach sprawdz `git diff --check` oraz Godota headless. Jesli `godot` nie jest w PATH, nie koncz na tym: szukaj binarki w `/workspace/scratch`; znana sciezka to `/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64`. Na swiezym checkoutcie najpierw zrob import: `... --headless --editor --path . --quit`, potem runtime: `... --headless --path . --quit`. Staguj tylko pliki, ktore faktycznie zmieniles.
