# IDOL Genesis - prompt dla kolejnych kontenerow

Pracujesz nad repozytorium `ElKlient/IDOL-Genesis`, gra w Godot 4.x na Androida. Nie zakladaj nowego projektu i nie wymieniaj dzialajacych mechanik ludzi bez potrzeby. Najpierw przeczytaj:

- `project.godot`
- `main.tscn`
- `scripts/main.gd`
- `scripts/retargeter.gd`
- `assets/third_party_model_packs/README.md`

Aktualny cel klimatu: niskopoligonowa osada epoki kamienia / wczesnego sredniowiecza. Ma byc ziemia, ogien, patyki, kamien, jagody, skory, jelenie, suszarnie skor, prymitywne narzedzia, oszczepy i delikatna zapowiedz pozniejszej stali/mieczy. Gra ma zostac lekka na Androidzie.

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
- Godot headless, jesli binarka jest dostepna: `godot --headless --path . --quit`
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

## Gotowy prompt do wklejenia dla nowego kontenera

Masz pracowac nad `ElKlient/IDOL-Genesis`, Godot 4.x Android, branch `main`. Najpierw przeczytaj `project.godot`, `main.tscn`, `scripts/main.gd`, `scripts/retargeter.gd` i `assets/third_party_model_packs/README.md`. Aktualny klimat to `0.8.18 Ancient Settlement`: lekka niskopoligonowa osada epoki kamienia / wczesnego sredniowiecza z idolem, ludzmi, patykami, kamieniem, jagodami, skorami, suszarniami skor, narzedziami kamiennymi, jeleniami i zapowiedzia pozniejszej stali. Nie zakladaj nowego projektu i nie psuj dzialajacych ludzi. Mechaniki ludzi, zasobow, budowy, rodzin, idola, kamery i UI sa glownie w `scripts/main.gd`. Jesli zadanie dotyczy scenerii, pracuj przez proceduralne helpery `make_...`; jesli ludzi, przeczytaj funkcje pozy kosci i `retargeter.gd`; jesli assetow, promuj tylko wybrane `.glb/.gltf` do wlasnych assetow gry, vendor paczki zostaw w `assets/third_party_model_packs/`. Po zmianach sprawdz `git diff --check`, a jesli masz Godota, `godot --headless --path . --quit`. Staguj tylko pliki, ktore faktycznie zmieniles.
