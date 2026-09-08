# IDOL Genesis - koordynacja kolejnych kontenerow

Stan sprawdzony lokalnie z innych katalogow scratch. Nie znaleziono aktywnej tablicy
`.codex/coordination/project.yaml`, wiec nie ma formalnych claimow innych kontenerow.
Prawdziwy stan trzeba czytac z lokalnych checkoutow i historii git.

## Najnowsza baza do dalszej pracy

Uzywaj jako bazy:

- repo: `ElKlient/IDOL-Genesis`
- branch: `main`
- dobry lokalny checkout: `/workspace/scratch/3fdaa6965b76/IDOL-Genesis`
- HEAD / origin/main: `eb9ec9e Add ancient settlement atmosphere`
- wersja w grze: `IDOL — GENESIS 0.8.18 ANCIENT SETTLEMENT`

Drugi checkout `/workspace/scratch/0014011bd38a/IDOL-Genesis` jest czysty i wyglada na
duplikat tej samej bazy.

## Co robily inne kontenery

| Lokalizacja | Stan | Co z tego wynika |
| --- | --- | --- |
| `/workspace/scratch/3fdaa6965b76/IDOL-Genesis` | czysty `main`, zgodny z `origin/main` | Aktualna baza: klimat osady, sceneria epoki kamienia, poprawiony naturalny chod, dokument handoff. |
| `/workspace/scratch/0014011bd38a/IDOL-Genesis` | czysty `main`, zgodny z `origin/main` | Kopia zapasowa tej samej bazy. Nie traktowac jako osobnej pracy. |
| `/workspace/scratch/ad3cb27c6389/repo` | lokalnie 3 commity nad starym `0.8.14`, plus niecommitowane zmiany 0.8.17 | Nurt animacji ludzi: os ramion, celowanie kosci barku, praca miednicy/kregoslupa, lepszy cykl nog. Wiekszosc wyglada juz wciagnieta do nowego `main`, ale niecommitowane drobiazgi trzeba porownac przed utrata. |
| `/workspace/scratch/3a13918d6208/IDOL-Genesis` | stary `0.6.7 Armory`, ahead 1 / behind 2, zmieniona tekstura normal mapy | Porzucony wojskowy prototyp: zbrojownia, bron, rozkaz `ZBROJOWNIA`, uzbrojenie mieszkanca. Nie scalac wprost z obecna epoka kamienia. |
| `/workspace/scratch/3a13918d6208/IDOL-Genesis-night` | branch `night-069`, ahead 5, zmieniony normal map | Snapshot 0.7.2 Life Spark: rodziny, dzieci, moce Idola, rozwoj zycia. Te systemy sa ideowo wazne; sprawdzac tylko jako referencje, bo nowszy `main` ma juz wiele podobnych funkcji. |
| `/workspace/scratch/3a13918d6208/IDOL-Genesis-build-clarity` | branch `build-clarity-068`, ahead 1 / behind 1, zmieniony GLB animacji | Snapshot klarownosci budowy: kolejka planow, procent budowy, czytelniejsze HUD/panele. Przydatny jako referencja UX. |
| `/workspace/scratch/3a13918d6208/IDOL-Genesis-stone-age` | branch `stone-age-067`, ahead 1 / behind 2 | Snapshot przejscia z drewna na patyki i rozdzial I epoki kamienia. Historycznie wazne, obecny `main` juz idzie tym kierunkiem. |

## Co przygotowac na dalszy rozwoj

1. Najpierw stabilizacja aktualnego `main`.
   - Godot headless / parse check.
   - Szybki test Android: czy nie ma szarego ekranu.
   - Obejrzenie ludzi po zmianach 0.8.18: chod, praca, noszenie ladunku, unikanie przeszkod.

2. Animacje ludzi jako osobny nurt.
   - Nie ruszac retargetera przy zadaniach scenerii.
   - `USE_RETARGETED_ANIMATIONS=false` zostawic, dopoki BoneMap UAL2 -> obecny Skeleton3D nie bedzie sprawdzony.
   - Dalsze poprawki robic w `pose_walk_arm`, `pose_walk_leg`, `apply_bone_pose`, `apply_living_pose`.
   - Po kazdej zmianie prosic o film z telefonu, bo problem osi rak widac dopiero w ruchu.

3. Gameplay osady jako drugi nurt.
   - Rozszerzac potrzeby: glod, energia, schronienie, wspolnota, rodzina.
   - Dodac proste priorytety pracy zalezne od cech: sila do kamienia/budowy, zrecznosc do jagod, inteligencja do odkryc.
   - Rozbudowac plan budowy o jeden nowy cywilny budynek naraz: suszarnia, palisada, pracownia narzedzi, miejsce rytualne.

4. Assety i teren jako trzeci nurt.
   - Promowac pojedyncze `.glb/.gltf`, nie cale paczki.
   - Teren robic proceduralnie i tanio: kamienie, sciezki, krzewy, martwe pnie, suszarnie skor.
   - Kazda dekoracja, ktora blokuje droge, powinna dodac `add_obstacle(...)`.

5. Zbrojownia / bron na pozniej, ostroznie.
   - Stary `0.6.7 Armory` byl odrzucony jako zbyt wojskowy kierunek.
   - Warto odzyskac tylko elementy pasujace do epoki kamienia: oszczepy, kamienne topory, trening lowiectwa, obrona osady.
   - Nie wprowadzac armii ani militarnego UI, dopoki spolecznosc i konflikty nie beda dzialac.

## Gotowy prompt dla nastepnego kontenera

Pracujesz nad `ElKlient/IDOL-Genesis`, Godot 4.x Android, branch `main`.
Nie tworz nowego projektu. Zacznij od `docs/CONTAINER_HANDOFF_PROMPT.md`, potem przeczytaj
`project.godot`, `main.tscn`, `scripts/main.gd`, `scripts/retargeter.gd` i
`assets/third_party_model_packs/README.md`.

Aktualna baza to `0.8.18 Ancient Settlement` z commita `eb9ec9e Add ancient settlement atmosphere`.
Gra ma byc lekka na Androidzie: niskopoligonowa osada epoki kamienia / wczesnego sredniowiecza,
Idol jako centrum rozkazow, 10 ludzi, praca, zasoby, rodziny, odkrycia, gesty kamery RTS.

Nie psuj ludzi. Jesli zadanie nie dotyczy animacji, nie zmieniaj kosci, retargetera ani modelu
postaci. Jesli zadanie dotyczy ludzi, czytaj funkcje: `make_person`, `cache_pose_bones`,
`pose_walk_arm`, `pose_walk_leg`, `apply_bone_pose`, `apply_living_pose`, `scripts/retargeter.gd`.

Jesli zadanie dotyczy scenerii, pracuj przez proceduralne helpery `make_...` w `scripts/main.gd`
i dodawaj przeszkody przez `add_obstacle(...)`. Jesli zadanie dotyczy gameplayu, dopinaj je do
istniejacych systemow rozkazow, zasobow, planow budowy, odkryc, rodzin i UI.

Przed koncem sprawdz `git diff --check`. Jesli Godot jest dostepny, uruchom
`godot --headless --path . --quit`. Staguj tylko pliki, ktore faktycznie zmieniles.
