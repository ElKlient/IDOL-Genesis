# Żelazny Świt — przekazanie projektu 0.2.2

## Aktualny stan 0.2.2 — grafika otoczenia i światło postaci

Własny shader `assets/world/terrain.gdshader` łączy trawę, ziemię i bruk
na jednym nieprzezroczystym PlaneMesh `ValleyTerrain`, y=.012. Stare płaskie
podkłady są niżej (.004/.006), aby nie chować pod ziemią podeszwy .0154 m.
Mapa RGBA
512² zawiera wydeptanie/bruki/zmienność/przyciemnienia kontaktowe; autorowanie
w `build_terrain_mask.py`, bez generowania map na telefonie. Trzy pary
istniejących tekstur korzystają z tego samego cache. Wersja oszczędna pomija
trzy próbki normalnych i ukrywa `Scenery_meadow`. Nie przełącza MSAA.

Bruk jest teraz nieregularnym, bezszwowym wzorem z przetarciami i normalnymi
fazowanych krawędzi. Kanoniczne paving_albedo/normal generuje
`build_courtyard.py`, wywoływany także na końcu `build_materials.py`.
Iglaki korzystają z oryginalnego atlasu igieł 256x512 i alpha scissor,
zamiast stożków. `build_pine_spray.py` odtwarza atlas. Całe igliwie jest
w jednej partii z jawnie przypisanymi UV; pędy lekko pracują w shaderze.
Dodatkowe mapy mają rzeczywiste mipmapy w `_detail_textures`, osobno od
istniejącego cache 16 map. Trawa i paprocie są jedną nieprzezroczystą partią,
bez cieni źdźbeł. Korony liściaste, narożniki budynków, drzwi i wsporniki
mają dodatkowy detal; góry gęstszy obrys.

Słońce i ambient lekko wzmocnione. `CharacterSoftFill` ma maskę 2 i brak
cieni; tylko siatki WarriorModel mają warstwy 1+2 (`layers=3`). Kamera i
słońce nadal widzą warstwę 1. Wykryto i usunięto stary dublujący przełącznik
cieni w main.set_low_quality: pełna odpowiedzialność jest teraz w świecie,
aby zmiana jakości nigdy nie uruchamiała cieni światła wypełniającego.

Pełny budżet świata 91 856 trójkątów / 61 powierzchni (poprzednio 59 562).
Nowy limit 100 tys. obejmuje statyczne drzewa i roślinność całej mapy;
nie podniesiono budżetu wojownika. Mapa kontrolna i igły poniżej 3 MiB razem
z mipmapami; maksymalny wymiar 512. Wszystkie 136 kolizji ruchu i 11 dachów
mają identyczne sygnatury, spawny i pozycje NPC są zachowane. Oddzielny agent
użytkownika zajmuje się potworami; ta aktualizacja nie zmienia enemy.gd.

Kadry `docs/valley-*-0.2.2.png` pochodzą z prawdziwego Godota/OpenGL na
Linuxie. `tests/capture_valley.gd` ustawia kupiony sprzęt i wstrzymuje AI
wyłącznie dla ujęć. Nie są pomiarem FPS telefonu. Rozmycie pozostaje wyłączone.
Źródłowe skrypty generujące PNG nie są wymagane przez grę na Androidzie.

Weryfikacja 0.2.2 Godot 4.6: świat/materiały 28/28 OpenGL, model i warstwy
40/40 OpenGL, pełna integracja zakup/kowal/walka/respawn 51/51 headless,
stabilność jakości i kowala 54/54 headless oraz 65/65 OpenGL. Rzeczywista
próba OpenGL obejmuje dziesięć zmian jakości, trzy ulepszenia i stałe MSAA.
Wszystkie testy są izolowane od sieci raportów i zapisu użytkownika.


## Aktualny stan 0.2.1 — poprawa animacji walki

Użytkownik potwierdził działanie 0.2.0 na telefonie, ale odrzucił sposób
machania mieczem. Na jego polecenie uruchomiono czterech agentów: wykonanie
animacji, przegląd anatomii/IK, synchronizacja sterowania i dźwięku, testy/render.
Osobny agent użytkownika pracuje nad potworami; ta poprawka nie podmienia
`enemy.gd`, modeli przeciwników ani ich AI.

Przyczyna: niezależne klucze Eulerów barku, łokcia i nadgarstka sumowały się
w duże, szybkie obroty, np. ponad 120° barku w 55 ms. `character_visual.gd`
prowadzi teraz rękojeść i orientację klingi po spójnych torach, a ramię dopasowuje
IK. Zwarta garda, mniejsze wychylenia tułowia i wyprzedzający ruch bioder.
Czwarty cios ma wspólną rękojeść osiągalną dla obu ramion, płynne dołączenie
lewej dłoni i zwolnienie chwytu. Zachowano pełne orientacje początkową/końcową
oraz płynne nakładanie POZY. Terminy obrażeń .16/.25 s pozostają takie same.

`player.gd` zachowuje kierunek zwykłego cięcia mimo ruchu joystickiem; nadal
można się przesuwać z dotychczasową zmniejszoną prędkością. Sterowanie kierunkiem
wraca po animacji. `main.gd` opóźnia szum ostrza o .065/.14 s, aby pasował do
przyspieszenia klingi; opóźnione wywołanie sprawdza serial, panel, śmierć i respawn.

Walidacja Godot 4.6, izolowane katalogi, bez transmisji diagnostycznej:
`animation_continuity` 69/69 (120 Hz, cztery bronie i wszystkie ciosy), model
39/39, combo 55/55, podgląd 32/32, ogień 38/38, kierunek ciosu 13/13,
opóźnienie i anulowanie dźwięku 8/8. Nowy test wykrył podczas pracy oderwanie
lewej dłoni o 26–30 cm; zostało naprawione, przy pełnym chwycie błąd jest
poniżej 0,05 mm w próbkach. Finalna integracja 50/50 oraz OpenGL modelu
50/50 z 11 rzeczywistymi kadrami również przeszły. Szczegóły poleceń
w `tests/README.md`.

Finalny film `docs/warrior-motion-0.2.1.mp4` (10 s, 1280×720 H.264/AAC)
pokazuje dwie serie ciosów przez kontroler gry oraz ataki w portrecie. Wilk
ma zwiększone PŻ i wstrzymane AI wyłącznie w scenie nagrania. Jest to render
Godota na Linuxie, nie pomiar FPS telefonu.

Identyfikatory przedmiotów, modele, ceny, zapis, obrażenia, cooldowny i zasięg
pozostają zgodne. Znane ograniczenie: stary zasięg kontaktu 3,2 m bywa większy
od widocznego zasięgu klingi; poprawne podejście z kolizjami wymaga osobnej
zmiany kontrolera. Nie maskować tego teleportowaniem samego modelu do celu.

## Historia 0.2.0 — rozbudowa grafiki i animacji

Użytkownik wybrał wszystkie trzy plansze wyposażenia oraz polecił wdrożyć
podniesienie jakości modeli, materiałów, animacji, trafień i świata. Plansze
imagegen są koncepcjami. Gotowe GLB i pokazane kadry z Godota/Blendera to
rzeczywiste zasoby projektu; nie przedstawiać ilustracji jako działającej gry.
Baza Quaternius pozostaje stylizowana, nie jest fotorealistycznym skanem twarzy.

### Wyposażenie i zachowanie zapisu

- Karmazynowa Straż: dopasowany stalowy napierśnik, asymetryczne warstwy
  naramienników, karmazynowa szarfa i rozdzielone poły, zakrzywiona szabla.
- Jadeitowa Brama: jasna środkowa płyta na ciemnym podkładzie, brąz i jadeit,
  dłuższy turkusowy płaszcz rozdzielony dla ruchu nóg, odrębna garda i klinga.
- Popielny Żar: czernione płyty, skrzyżowane pasy, cięższy naramiennik,
  krótsze nierówne osłony, ciemne bordo i szeroka klinga z kanałem żaru.
- Identyfikatory sześciu przedmiotów pozostają te same. Zmieniono nazwy,
  opisy, kolory i dodano `set_name`; ceny, bazowe moce, UID, schemat zapisu,
  koszty ulepszeń i poziomy użytkownika pozostają zgodne. Zapis odbudowuje
  opisy z katalogu, więc nowy wygląd działa bez resetu postaci.
- `set_equipment(weapon_tier, armor_tier, upgrade=0, armor_upgrade=0)` jest
  wspólnym czteroparametrowym interfejsem Hero, CharacterVisual, WarriorModel
  i portretu. Sygnatury odświeżania uwzględniają także poziom zbroi.
- Materiały EquipmentAtlas i BladeEquipmentAtlas korzystają ze wspólnych
  color/normal/ORM 1024² oraz dwóch odrębnych masek emisji 256². R=AO,
  G=roughness, B=metallic. Pięć `equipment_*.png` jest zewnętrzną częścią
  pakietu GLB i musi zostać pobrane razem z nim. Układ kości/rest pozostaje
  zgodny z poprzednią wersją. Brak dodatków, pobrań lub Blendera na telefonie.
- Szwy, tłoczenia, przetarcia, ziarno skóry i splot tkaniny powstają w
  `equipment_materials.py`. Materiały są różne fizycznie, nie tylko kolorem.
  Maskowana emisja ulepszeń nie zamienia całej klingi w białą płaszczyznę.
  Własne materiały instancji nie zmieniają współdzielonych tekstur.
- Ikony siedmiu przedmiotów są renderami faktycznych modeli z Blendera,
  nie obrazkami koncepcyjnymi. Interfejs zachowuje wektorowy fallback.

### Metryki finalnego modelu 0.2.0

Widoczne trójkąty z mieczem dla poziomów 0/1/2/3:
**12 491 / 25 575 / 25 281 / 25 501**, powierzchnie **7 / 8 / 8 / 8**.
Maksimum jest niższe od limitu testów 35 tys. trójkątów / 12 powierzchni.
`warrior.glb` ma 7 489 108 B, `weapons.glb` 1 085 020 B. Wysokość postaci
2,0237 m; szkielet ma te same 65 pozycji spoczynkowych co 0.1.8. Tekstury
ciała i wyposażenia to 12 współdzielonych map, maksymalnie 1024². Konserwatywny
budżet RGBA8 z mipmapami wynosi około 44 MiB, niezależnie od rzeczywistej
kompresji sterownika. Portret współdzieli te zasoby zamiast wczytywać drugi atlas.

SHA256 wojownika:
`d9498c72b266b909763540659286e57d95d7f4142f4283548c6418cff0cef1d6`.
SHA256 mieczy:
`c44143fb5e93333623003f7ba430732368139b77a2d7a96c4bbdfcb9e13f94fa`.

### Animacje, kontakt i portret

Płynne krzywe ruchu łączą przygotowanie, kontakt i powrót. Bieg ma ścieżkę
stawiania stopy, pracę kolan oraz przeciwruch rąk; postój ma oddech i przenoszenie
ciężaru. Czwarty cios używa oburęcznego chwytu. Nie zmieniono kontaktów obrażeń
(.16 s pierwszych trzech cięć, .25 s czwartego), ekonomii, odrzutu ani cooldownów.
`contact_pause` zatrzymuje tylko widoczną animację na .028/.042 s. Fizyka,
`Engine.time_scale` i zegary rozgrywki biegną normalnie.

Nowe trafienia korzystają z maksymalnie ośmiu kontaktów i trzech partii MultiMesh
na renderer: smugi kontaktu, iskry i pył. Są zakotwiczone w świecie i ponownie
używane. Przeciwnik krótko reaguje na kierunek uderzenia, po czym wraca do swojej
pozy. Dźwięki mają ograniczoną liczbę jednoczesnych głosów; ambient zachowuje
bezpieczne odroczone ponowienie, bez natywnej pętli WAV.

Podgląd 512² ma jeden zachowywany viewport, limit 30 Hz i dziewięć przycisków:
obrót, reset, +/−, POSTÓJ, CIOS, BIEG, POZA. Obrót palcem nadal działa, dotknięcie
przycisku nie rozpoczyna drag modelu. Domyślnie mieści się cała postać z butami
powyżej kontrolek. Przybliżenie celowo kadruje detale twarzy i pancerza. Małe
statyczne niebo dostarcza odbicia PBR przy przezroczystym tle portretu. Ukryty
podgląd nie animuje i nie renderuje. Nie ma motion blur, DOF, glow ani symulacji
sukna; tkanina pracuje przez wagi szkieletu.

Naprawiono też istniejący błąd toastów po szybkich zakupach/zmianach sprzętu:
niepoprawne położenie i rosnąca wysokość panelu mogły zasłaniać lewą część gry.
Panel ma 600×72, dwie linie tekstu i pozycję względem środka dolnej krawędzi.
Etykieta ma jawne wypełnienie i minimalną wysokość, aby tekst nie znikał w 1 px.

### Świat i ograniczenia mobilne

Osiem par własnych materiałów świata (512 albedo/256 normal) pokrywa ziemię,
trawę, bruk, kamień, drewno, dachy, tkaninę i tynk. Poprawiono UV/TBN, brzegi
ścieżek, korony drzew, dalekie nieregularne grzbiety i spokojną wodę. Kuźnia
używa jednej partii iskier. Świat zachowuje 136 kolizji ruchu i 11 dachów kamery,
pozycje NPC, przejścia i spawny. Statyczne niebo 128 daje odbicia bez dodatkowych
świateł. MSAA na Androidzie pozostaje wyłączone od startu.

Testy i kadry są wykonywane w Godot 4.4.1 na Linuxie z prawdziwym OpenGL/Mesa,
w izolowanych katalogach. To nie pomiar FPS fizycznego telefonu. Aktualizacja
nie uruchamia testowej transmisji diagnostyki, nie publikuje prywatnych logów
ani konfiguracji i nie modyfikuje zapisu użytkownika.

### Weryfikacja 0.2.0

| Zakres | Wynik |
| --- | --- |
| Pełna pętla gry, dotyk, kolizje, trzy zabicia i respawn | 50/50 |
| Rzeczywiste przyciski sklepu/ekwipunku/kowala | 17/17 |
| Odroczony kowal i pojedyncze naliczenie opłaty | 26/26 |
| Zapis, odtworzenie sprzętu, kopia i błędne dane w jednorazowym katalogu | 19/19 |
| Cztery ciosy, kontakt, odrzut i kamera | 55/55 |
| Uderzenie ognia, premia, czas trwania i dotyk kamery | 38/38 |
| Podgląd, multitouch, ponowne otwieranie i brak pracy w tle | 32/32 |
| Ograniczone efekty kontaktu i lokalna pauza animacji | 17/17 |
| Stabilność renderera i niezmienne MSAA, headless | 43/43 |
| Naturalne zakończenie/restart ambientu i zwalnianie dźwięków | 13/13 |
| Finalny szkielet, deformacje, chwyt, podeszwy i ostrze, headless | 39/39 |
| Finalny pakiet HD, materiały, wszystkie pozy i portret, headless | 69/69 |
| Ten sam pakiet po świeżym imporcie samych źródeł, z 16 rzeczywistymi zrzutami | 85/85 OpenGL |
| Świat, geometria, materiały, TBN, kolizje i spawny | 18/18 headless, 19/19 OpenGL |
| Finalne ikony PNG w rzeczywistych kontrolkach GUI przy 64/96/128 px | 21/21 OpenGL |
| Ponowny import siedmiu ikon, rozmiary, alfa, zasoby tekstur i kontrolki | 23/23 OpenGL na świeżej kopii |

Powyższe sprawdzenia są izolowane od postaci użytkownika i sieci diagnostycznej.
Na finalnym modelu końcówka miecza podczas slamu jest 0,07 m nad ziemią,
podeszwy około 0,0154 m. Pozycje dłoni są mierzone względem rzeczywistej rękojeści,
a kadrowanie przez faktyczne wierzchołki po skinningu. Przegląd ujęć od tyłu i
z uniesionymi rękami doprowadził do poprawienia pokrycia koszuli/rękawów i
zamknięcia górnych otworów naramienników. Nie osłabiono kontroli kadrowania,
aby ukryć problem. Niezależne przeglądy kodu oraz świata nie wykazały dalszych
błędów blokujących wydanie.

Świeży import rozpoczynał od źródeł bez `.godot`, `.import`, UID i wyodrębnionych
PNG. Godot odbudował obrazy osadzone w GLB, pięć kanonicznych map atlasu,
materiały świata i siedem ikon. Headless editor zakończył import kodem 0;
dwa komunikaty Dummy `texture_2d_get: Parameter t is null` wystąpiły przy
miniaturach GLB. Faktyczny runtime OpenGL przeszedł 85/85 bez błędów silnika
i skryptów. Host llvmpipe zgłasza jedynie brak obsługi V-Sync; to nie pomiar
ani błąd sterownika telefonu.

Finalne materiały prezentacyjne w `docs`: trzy `warrior-{karmazynowa,jadeitowa,
popielny}-0.2.0.png` to rzeczywiste modele w oświetleniu Blendera;
`warrior-inventory-0.2.0.png` i `warrior-village-0.2.0.png` to kadry Godota.
`warrior-motion-0.2.0.mp4` to nagranie finalnego renderera 1280×720/30 fps,
17,43 s, H.264/AAC (3 796 829 B). Pokazuje trzy rodziny, przybliżenie/POZA,
obrót, bieg, cztery prawdziwe kontakty kontrolera, uderzenie ognia i płonącą
broń w portrecie. Scena demonstracyjna ma dodatkowe złoto i wilka z 1200 PŻ,
aby cała seria była widoczna. To izolowana prezentacja, bez zmian balansu gry.
Wszystkie pokazane zasoby pochodzą z finalnych GLB i PNG; nie są ilustracjami AI.

Poniższa historia opisuje wcześniejsze wersje; jej stare liczby zasobów i nazwy
przedmiotów nie są metrykami aktualnego wydania.

## Historia 0.1.8 — pierwszy model wojownika

Na wyraźne polecenie użytkownika zastąpiono klockową geometrię prawdziwą
siatką postaci przygotowaną w Blenderze 4.5.3 LTS. To zaimplementowany model
w grze, nie wizualizacja imagegen. Naturalna twarz, dłonie z palcami, czarne
włosy, ciągła skóra i trzy osobne warstwowe zbroje inspirowane gatunkiem
azjatyckiego ARPG. Cztery oryginalne modele mieczy obejmują broń startową.

Baza ciała, oczy, brwi i włosy pochodzą z darmowego Quaternius Universal Base
Characters Standard (CC0). Zweryfikowano oficjalne pobranie i zgodność BIN.
Pochodzenie, hashe archiwum, licencja i polecenia odtworzenia są w
`assets/warrior/CREDITS.md` oraz `QUATERNIUS-LICENSE.txt`. Oryginalne zbroje
i miecze należą do projektu; nie deklaruj ich automatycznie jako CC0.
Nie użyto modeli, tekstur ani strojów wyciągniętych z Metin2.

Gotowe `warrior.glb` (4 920 368 B) i `weapons.glb` (117 540 B) zawierają
zasoby potrzebne w runtime. Blender, źródłowy pakiet i dodatki nie są potrzebne
na telefonie. Skrypty `build_warrior.py` / `build_weapons.py` zachowują pipeline.
SHA256 wojownika: `ebe7792e086aa554de585f30461bc01e33bac643fa6e84c55f43a312c720c5c8`.

### Integracja i budżet

- Szkielet ma 65 kości; maksymalnie 4 znormalizowane wagi na wierzchołek.
  Wysokość z włosami około 2,024 m, przód w Godocie −Z.
- Widoczne trójkąty z mieczem dla poziomów 0/1/2/3:
  **9923 / 13775 / 14407 / 15541**. Powierzchnie: **11 / 14 / 14 / 14**.
- Siedem współdzielonych tekstur, największa 1024²; oczy 256².
  Siatki, skin i tekstury są wspólne dla postaci oraz podglądu.
  Małe modyfikowalne materiały są kopiowane raz na instancję, więc ulepszenie
  lub błysk trafienia nie zmienia drugiej postaci.
- `WarriorModel` jest rodzeństwem korzenia sterującego `body`, aby ruch nie
  nakładał się podwójnie. Stawy kontrolne są kalibrowane z faktycznej pozy
  spoczynkowej importowanego szkieletu, a nie ze starej klockowej sylwetki.
- Transformacja kości Godota jest pełną transformacją lokalną względem
  rodzica. Nie mnoż jej ponownie przez rest; palce i niewymienione kości
  dziedziczą rest od już ustawionego rodzica. Korekcje bind łączą stary
  publiczny interfejs animacji z nową skórą.
- Zwykłe cztery ciosy, oddech, bieg, oburęczny slam i płomień używają nowego
  modelu. Rozmiar i początek broni odpowiadają lokalnemu końcowi klingi −1,205 Y.
  Nie zmieniono ekonomii, nagród, cooldownów, zapisu ani ustawień kamery.
- Podgląd ma bliższy kadr dla odpoczynku i rozszerza go podczas ataku.
  Ukryty podgląd nadal nie renderuje; nie dodano motion blur, DOF ani glow.

Pomiary i testy tej aktualizacji wykonano na Linuxie z Godot 4.4.1 i OpenGL/Mesa.
Nie oznaczają zmierzonego FPS ani próby tej wersji na fizycznym Androidzie.
Przy aktualizacji należy zachować zapis i prywatną konfigurację diagnostyki.
Poniższe sekcje wersji 0.1.1–0.1.7 dokumentują historię, w tym dawny model.

### Weryfikacja modelu 0.1.8

`tests/warrior_model.gd` bada rzeczywiste wierzchołki po skinningu CPU,
a nie tylko spoczynkowe AABB. Sprawdza proporcje, widoczną geometrię każdego
zestawu, faktyczne materiały ciała/pancerza, współdzielenie tekstur oraz pełne
animacje i obrót podglądu. Odrębne materiały na dwóch postaciach nie zmieniają
wspólnych tekstur. Cztery miecze przy kontakcie mają koniec klingi 0,07 m
nad gruntem, lewa dłoń dotyka rękojeści; po korekcie wag podeszwy są
0,013–0,020 m nad gruntem. Samo badanie stawu kostki nie wykrywało starego
błędu, w którym cała dolna część buta była przypisana do łydki.

Test podglądu dla sztywnej broni projektuje teraz faktyczne wierzchołki,
zamiast pustych narożników AABB zakrzywionej klingi. Nowy test uzupełnia go
o rzeczywistą deformację siatki ciała i zbroi podczas ciosów.

Świeża kopia projektu bez cache i wyodrębnionych PNG poprawnie importuje
oba GLB i odtwarza siedem tekstur. Pliki `warrior_T_*.png`, `.import`, UID,
`.godot` oraz `__pycache__` są generowane lokalnie i nie trafiają do commita.
Import na serwerze Dummy może wypisać `texture_2d_get: Parameter t is null`
podczas miniatur; rzeczywisty runtime OpenGL ładuje i renderuje tekstury.
Nie wykonano testowej transmisji diagnostyki ani modyfikacji zapisu gracza.

Wyniki: nowy model **39/39 headless i 50/50 OpenGL** (w tym 11 rzeczywistych
zrzutów), podgląd **32/32 headless i 32/32 OpenGL**, cztery ciosy **55/55**,
ogień **38/38**, integracja **51/51**, interfejs **17/17**, kowal **26/26**.
Testy uruchamiano z `--test-isolated`; obejrzano finalny ekwipunek, kontakt
miecza i płonące ostrze. `docs/warrior-inventory-0.1.8.png` to rzeczywisty
zrzut Godota; `docs/warrior-model-0.1.8.png` przedstawia ten sam model
w studyjnym oświetleniu Blendera, a nie wygląd telefonu ani ilustrację AI.

## Cel i zgody

Użytkownik 18 października 2026 zlecił gotowy pierwszy grywalny wycinek mobilnego
ARPG w Godocie: wojownik, świat 3D, mała wioska, handlarz, trzy zbroje i różne
miecze, mikstury, kowal z przeciąganiem przedmiotu, 10 000 złota na start.
Ma móc pobrać kod przez Termuxa i kupić, ulepszyć oraz zabić pierwszego potwora.
Udzielił pełnej zgody na narzędzia i wykonanie/publikację tej gry. To oryginalna
gra inspirowana gatunkiem, bez zasobów Metin2.

Nowy projekt jest odseparowany od dotychczasowych aplikacji i gry:

- repo: `ElKlient/IDOL-Genesis` (dotychczasowe, publiczne);
- **osobna gałąź: `zelazny-swit`**, bez aktualizacji `main` i kalendarzy;
- katalog projektu: `games/zelazny-swit`;
- telefon: `/storage/emulated/0/Godot/ZelaznySwit/games/zelazny-swit`;
- Godot 4.4.1+; użytkownik ma edytor Godot na Androidzie;
- pakiet APK nie jest jeszcze przygotowany — ta wersja jest uruchamiana przez ▶ w Godocie.

## Architektura

- `project.godot`, `main.tscn`: wejście, landscape, Compatibility/OpenGL, Canvas Items.
- `scripts/main.gd`: scena, obrotowa kamera na `SpringArm3D`, ruch względem widoku,
  wejście, czteroczęściowe combo,
  opóźnienie trafienia, automatyczny najbliższy cel / wybór dotykiem, skill obszarowy,
  mikstury, NPC, nagrody i respawn.
- `scripts/camera_preferences.gd`: niezależne preferencje kamery i atomowy zapis CFG.
- `scripts/game_state.gd`: autoload `GameState`, katalog, egzemplarze przedmiotów
  z UID, ekonomia, statystyki, zadanie i atomowy zapis JSON.
- `scripts/world.gd`: oryginalny świat budowany w kodzie; wspólne siatki dekoracji,
  wioska, targ, kuźnia, las, brama, staw, ruiny i 7 spawnów.
- `scripts/player.gd`, `character_visual.gd`: fizyka wojownika, animowane części
  ciała, ekwipunek zmieniający sylwetkę, miecz i zbroja 0–3, efekty ulepszenia.
- `scripts/warrior_model.gd`: importowany model ze szkieletem, mapowanie stawów
  animacji, wybór geometrii pancerza/miecza i osobne materiały instancji.
- `assets/warrior/`: gotowe GLB, generatory Blendera, metryki, rig i licencja
  bazy Quaternius CC0. Blender nie jest potrzebny na telefonie.
- `scripts/enemy.gd`: wilk, dzik, Strażnik Korzeni; roaming, aggro, zapowiedź ataku,
  odskok/powrót do spawnu, leczenie po wyjściu ze strefy, śmierć.
- `scripts/audio.gd`: oryginalna synteza dźwięków i ambientu; dźwięk można wyłączyć.
- `ui/hud.gd` i pomocnicze skrypty: HUD, minimapa, multitouch, plecak, sklep,
  kowal z drag & drop oraz wyborem dotykowym, pomoc, przewijane ustawienia
  i prawy panel regulacji kamery z podglądem na żywo.
- `scripts/diagnostics.gd`: autoload `Diagnostics`, lokalne ograniczone ślady zdarzeń,
  wykrycie niedomkniętej sesji, filtrowany ogon logu i opcjonalna wysyłka HTTPS.
- `tests/`: testy izolowane od właściwego zapisu; część działa także z prawdziwym OpenGL.

## Pętla gry

Nowa postać: 10 000 G, miecz rekruta, 10 mikstur. Mira (-6,0,0) sprzedaje
3 miecze i 3 zbroje oraz mikstury. Born (6,0,0) ulepsza sprzęt za złoto;
+1..+3:100%, +4:80%, +5:65%, +6:50%. Nieudane ulepszenie zachowuje przedmiot
oraz jego poziom, ale zużywa opłatę. Żelazny miecz:350 G; +1:180 G.
Po zakupie trzeba osobno założyć sprzęt w ekwipunku.

Za północną bramą (z=-14) są potwory. Pierwsze trzy ciosy mają cooldown0.48s
i windup0.16s. Czwarty: cooldown0.64s, windup0.25s, obrażenia×1.4 i odrzut
żywego trafionego celu. Przerwa1.2s resetuje combo. 14% trafień krytycznych.
Wir stali ma zasięg4.2m i cooldown7s.
PŻ i obrona zmieniają realne obrażenia. Śmierć wraca do wioski bez kar.
Potwory respawn18s, boss24s. Łupy w złocie/PD automatyczne, mikstura ma szansę wypaść.

Zadanie: kup miecz, wykonaj dowolne ulepszenie, zabij3 potwory i wróć do Miry
po1200G+5mikstur. Dalej cel: Strażnik Korzeni.

## Zapis

`user://adventure_v1.json` we własnym katalogu danych `ZelaznySwit`;
`.bak` poprzednia wersja, `.tmp` zapis tymczasowy, `.corrupt` zachowana uszkodzona wersja.
Zapis nie zawiera Color/resources: przedmioty są rekonstruowane po ID, UID i ulepszeniu.
Aktualizacje kodu nie usuwają danych. Nowy telefon wymaga osobnego przeniesienia zapisu.
Menu Nowa Gra wymaga osobnego potwierdzenia i resetuje tę przygodę.

## Uruchamianie i aktualizacje

Pełny gotowy blok pierwszego pobrania jest w README tego projektu. Używa
`--filter=blob:none --sparse` i `git sparse-checkout set games/zelazny-swit`, aby
nie pobierać paczek starszej gry. W Godocie trzeba importować dokładnie
`games/zelazny-swit/project.godot`.

Aktualizacja po zamknięciu projektu:

```bash
cd /storage/emulated/0/Godot/ZelaznySwit && git -c user.name=Backup -c user.email=backup@localhost stash push -m "Ustawienia Godota przed aktualizacja" -- games/zelazny-swit/project.godot && git pull --ff-only origin zelazny-swit && git --no-pager log -1 --oneline
```

Nie usuwaj `.godot`, nie stosuj `reset --hard`, nie zmieniaj gałęzi na `main`.
Blok zachowuje lokalny `project.godot` w stash. Nie przywracaj go automatycznie,
aby nie usunąć nowych autoloadów ani ustawień mobilnych. Pozostałe lokalne zmiany
sprawdź przez `git status --short`; nie odrzucaj ich. Ignorowany plik
`diagnostics.local.json` i zapis postaci pozostają po aktualizacji.

## Zakres i ograniczenia

To pierwsza grywalna lokalna wersja, nie pełne MMORPG. Brak multiplayera, innych klas,
rozległych map i kampanii. Grafika jest stylizowana. Od 0.1.8 wojownik używa
przygotowanej w Blenderze bazy Quaternius CC0 i własnych modeli wyposażenia.
Świat, animacje, efekty, ikony i dźwięki pozostają generowane przez kod.
Fizyczny telefon użytkownika nie był zdalnie dostępny. Użytkownik później
potwierdził rozgrywkę 0.1.3 na swoim urządzeniu; zakres tej obserwacji i nową
kamerę 0.1.4 opisano na końcu. Nie przenoś tego potwierdzenia na inne telefony.

## Weryfikacja

Pierwsza wersja przeszła w Godocie 4.4.1 na Linuxie 87 sprawdzeń
(integracja51, interfejs17, zapis19); jest to historyczny wynik przed 0.1.2.
Bieżące testy obejmują dodatkowe regresje opisane poniżej. Test nowej gry potwierdza również
odtworzenie pełnej sceny, świeżych potworów, cooldownów i startowego ekwipunku.

- import projektu w edytorze i zwykły runtime headless bez błędów;
- test integracyjny pełnej sceny: początkowe10k, zakupy/wyposażenie, ekonomia
  kowala, potki, zablokowanie walki w panelach, rzeczywiste zdarzenia joysticka,
  dojście przez fizykę do obu NPC oraz przez północną bramę, zabicie3wilków
  normalnymi atakami i otrzymanie nagród/poziomu/zadania;
- test interfejsu z prawdziwymi kliknięciami i przeciąganiem do kowadła:
  zakup, założenie, drop bez opłaty, przycisk ulepszenia z pojedynczą opłatą;
- test zapisu w jednorazowym katalogu XDG: roundtrip wszystkich danych,
  rekonstrukcja wyposażenia, odzyskanie kopii po uszkodzonym JSON,
  odrzucanie błędnych typów/liczb i duplikatówUID;
- render prawdziwym rendererem OpenGL/Mesa w Xvfb:1280×720 oraz1600×720;
  obejrzane ekrany wioski, sklepu, kowala, plecaka i walki; skorygowane
  prześwietlenie oświetlenia, sprawdzone ramki i czytelność paneli;
- testy automatyczne i zrzuty wykonano na Linuxie. Późniejsze potwierdzenie
  użytkownika dotyczy rozgrywki 0.1.3 na jego telefonie, bez pomiaru wydajności;
  nie jest testem nowej kamery 0.1.4 ani innych modeli Androida.

Przykładowe polecenia w środowisku z desktopowym Godotem:

```bash
godot --headless --editor --path games/zelazny-swit --quit
godot --headless --path games/zelazny-swit --script res://tests/integration.gd -- --test-isolated
godot --headless --path games/zelazny-swit --script res://tests/ui_flow.gd -- --test-isolated
godot --headless --path games/zelazny-swit --script res://tests/render_stability.gd -- --test-isolated
godot --headless --path games/zelazny-swit --script res://tests/forge_deferred.gd -- --test-isolated
godot --headless --audio-driver Dummy --path games/zelazny-swit --script res://tests/audio_regression.gd -- --test-isolated
qa_data="$(mktemp -d)"
XDG_DATA_HOME="$qa_data" godot --headless --path games/zelazny-swit --script res://tests/persistence.gd -- --test-isolated --test-data-root="$qa_data"
XDG_DATA_HOME="$qa_data" godot --headless --path games/zelazny-swit --script res://tests/diagnostics.gd -- --test-isolated --test-data-root="$qa_data"
```

Nie uruchamiaj testu trwałego zapisu bez jawnego jednorazowego katalogu. Testy
UI/integracji wyłączają zapisy, a test trwałości dodatkowo odmawia uruchomienia,
jeśli rzeczywisty katalogdanych nie mieści się w podanym katalogu testowym.


## Poprawka 0.1.1 — nagranie Androida i przełączanie MSAA

Użytkownik uruchomił grę na Samsungu SM-S942B, Android16, w edytorze Godot4.7.2,
Compatibility przez ANGLE/Exynos. Nagranie3142.mp4 potwierdza ruch, otwarcie kuźni,
ulepszenia miecza rekruta +1 (9900G) i +2 (9700G), następnie zamknięcie procesu
uruchomionej gry; edytor pozostaje. Samsung pokazuje ogólny dialog proponujący
wyczyszczenie cache Godota po błędzie — nie jest to dowód uszkodzenia cache.

Pierwsza widoczna klatka świata jest około5.3s nagrania, +2 pozostaje na ekranie
jeszcze13.2–13.4s, dialog awarii pojawia się do13.5s. Pasuje to do warunku w main.gd,
który po8s na mobile przyFPS<38 przełączał MSAA2X na wyłączone oraz cienie.
To mocna hipoteza, nie potwierdzenie bez natywnego śladu awarii lub próby na telefonie.

Zmiana: usunięto automatyczną rekonfigurację po8s, dodano startowy override
`rendering/anti_aliasing/quality/msaa_3d.mobile=0`, zachowano desktopowe2X.
Ręczny tryb oszczędny zmienia tylko cienie/światło kuźni, bez przebudowy MSAA.
Nie zmieniano przedmiotów, zapisów, wyglądu świata ani nieba.

Widoczne żółte ostrzeżenia GDScript i RGBAFloat→RGBAHalf nie są stosami awarii.
Kod GLES3 silnika ma obsługę konwersji; także wewnętrzne tekstury mogą ją wywołać
niezależnie od Sky. Nie obiecuj zniknięcia tych komunikatów po tej poprawce.

Test po zmianie: import edytora, dotychczasowa integracja oraz test stabilności
renderowania (`tests/render_stability.gd`) bez zapisu danych użytkownika.
Nowy test:44/44 headless i55/55 prawdziwy OpenGL/Mesa (59 wyrenderowanych klatek),
ponad12s działania, ulepszenia +1/+2/+3 i10 ręcznych zmian jakości bez zmiany MSAA.
Wynik na fizycznym Androidzie wymaga sprawdzenia tej nowej wersji przez użytkownika.

Gdy Godot zmienił lokalnie project.godot, blok aktualizacji może najpierw zachować
kopię tylko `games/zelazny-swit/project.godot` przez `git stash push -- <plik>`.
Nie przywracaj jej automatycznie, aby nie nadpisać nowego ustawienia mobilnego MSAA.


## Poprawka 0.1.2 — dalsza awaria, kolejka GUI i dźwięk

Użytkownik potwierdził dalsze zamknięcie gry na Androidzie po wgraniu 0.1.1.
Wyłączenie automatycznego przełączania MSAA nie jest więc potwierdzonym rozwiązaniem.
Nie przypisuj awarii samym żółtym ostrzeżeniom ani konwersji RGBAFloat→RGBAHalf.

`ui/hud.gd` nie usuwa już aktywnego przycisku w trakcie sygnału GUI.
`_render_panel()` jedynie kolejkowuje i łączy żądania; rzeczywiste usuwanie
starej zawartości i budowanie nowej wykonuje odroczone `_rebuild_panel()`.
`_upgrade_selected()` ma blokadę powtarzających się sygnałów oraz kolejkuje
`_perform_upgrade(uid,session_id)`. Przed opłatą sprawdza otwartą kuźnię, tę samą
sesję panelu i nadal wybrany UID. Zamknięcie/ponowne otwarcie lub wybór innego
przedmiotu anuluje starą akcję. Nie dodano opłat do drag & drop ani drugiego
ulepszenia. Potwierdzenie nowej gry korzysta z tej samej bezpiecznej przebudowy.
W HUD widoczna jest wersja odczytana z `application/config/version`.

`scripts/audio.gd` wyłącza natywny `AudioStreamWAV.LOOP_FORWARD` dla oryginalnego
8-sekundowego ambientu. Sygnał `finished` odkłada ponowienie na kolejny obieg,
zachowując ten sam odtwarzacz i WAV. Wyciszenie/wyjście anuluje ponowienie.
To obejście ryzykownej ścieżki natywnego dekodera, nie dowód przyczyny awarii
tego telefonu. Testy nie zastępują próby nowej wersji na Androidzie.

Nowe regresje: `tests/forge_deferred.gd` (odroczona mutacja, pojedyncza opłata,
łączenie odświeżeń, anulowanie starej sesji i zmiany UID, brak narastania kontrolek),
`tests/audio_regression.gd` (rzeczywiste odtworzenie pełnych 8 sekund na sterowniku
Dummy, naturalne `finished`, odroczony replay, efekty, wyciszenie i wyjście).
Test rzeczywistych kliknięć przewija przodków `ScrollContainer`, zanim kliknie
przycisk; samo `is_visible_in_tree()` nie oznacza widoczności wewnątrz przewijania.

## Prywatna diagnostyka — konfiguracja i ograniczenia

- Sites ID: `appgprj_6ad5035f4cfc8191851f417300366845`.
- Strona: `https://zelazny-swit-diagnostyka.sethoyt.chatgpt.site`.
- Jednorazowa konfiguracja urządzenia: zalogowany właściciel otwiera stronę
  diagnostyki i przyciskiem pobiera `/api/device-config` (bezpośrednie żądania
  z innej witryny są odrzucane).
- Odbiór raportów: `https://zelazny-swit-diagnostyka.sethoyt.chatgpt.site/api/reports`;
  klient przypina ten endpoint, bez przekierowań i z prywatnym bearerem.
- Retencja serwera: do 14 dni i maksymalnie 1000 raportów. Dostęp do podglądu
  i konfiguracji wymaga konta właściciela. Sam klucz nie trafia do Git ani dokumentacji.

Pobrany na telefon plik `Download/diagnostics_config.json` trzeba raz skopiować:

```bash
cp /storage/emulated/0/Download/diagnostics_config.json /storage/emulated/0/Godot/ZelaznySwit/games/zelazny-swit/diagnostics.local.json
```

Potem ponownie uruchomić projekt. `diagnostics.local.json` jest ignorowany przez
Git i zachowuje się podczas aktualizacji. Publiczny `diagnostics_config.json`
nie zawiera tokenu. Diagnostyka jest domyślnie włączona lokalnie; wysyłka wymaga
prywatnej konfiguracji. Gra i zapis działają offline bez konfiguracji i internetu.
Przełącznik **Menu → Automatyczne raporty błędów** wyłącza zbieranie oraz wysyłkę,
anuluje aktywne żądanie i usuwa lokalną kolejkę. Status aktualizuje etykietę,
nie przebudowuje panelu i nie uruchamia kolejnych raportów co klatkę.

Raport zawiera pseudonimowy losowy ID instalacji, losowy ID sesji, wersję gry,
Godota, system/architekturę/renderer i ograniczony ślad zdarzeń. HUD zapisuje
etapy kuźni oraz otwieranie/zamykanie i odroczoną przebudowę panelu; przy sprzęcie
tylko UID, kategorię i poziom ulepszenia. Nie wysyła pliku zapisu, kontaktów,
lokalizacji ani identyfikatora sprzętowego. Redakcja usuwa sekrety, adresy e-mail,
URL i ścieżki z fragmentów logu. Lokalna kolejka ma najwyżej 8 raportów po 32 KiB,
64 zdarzenia i 16 krótkich wpisów błędów na raport; sieć jest asynchroniczna,
z timeoutem i ponawianiem w tle. Checkpointy kuźni mają ograniczenie częstotliwości.

Po nieoczekiwanym zamknięciu klient przy następnym uruchomieniu odczytuje
niedomkniętą sesję i dostępny przefiltrowany ogon obróconego logu Godota.
`unclean_exit` jest wskazówką, nie potwierdzeniem natywnego crasha: użytkownik
lub system też może zakończyć proces. Natywny stos nie zawsze trafia do logu
Godota, więc nie obiecuj pełnego tombstone, logcata ani gwarantowanego stack trace.
Flaga `--test-isolated` wyłącza wysyłkę i używa oddzielnych plików diagnostyki;
testy nie mogą pobierać prywatnego tokenu ani wysyłać danych gracza.


Ukierunkowane regresje 0.1.2: kowal odroczony **26/26** headless i OpenGL,
dźwięk **13/13** z odtwarzaniem na Dummy, diagnostyka lokalna **29/29** bez sieci.
Nie sumuj ich ze starymi wynikami jako nowego pełnego certyfikatu Androida.

`tests/diagnostics_network.gd` to osobny test rzeczywistego HTTPS: tylko po jawnej
autoryzacji, we własnym jednorazowym `XDG_DATA_HOME`, z uprzednio dostarczonym
poza repozytorium prywatnym `user://diagnostics_config.json`. Przykładowe polecenie
z już przygotowanym jednorazowym katalogiem w zmiennej `qa_data`:

```bash
XDG_DATA_HOME="$qa_data" godot --headless --path games/zelazny-swit --script res://tests/diagnostics_network.gd -- --diagnostics-network-test --test-data-root="$qa_data"
```

Ten test wymaga `--diagnostics-network-test` bez `--test-isolated`, czeka do 20 s
na potwierdzenie i usuwa raport z kolejki dopiero po JSON serwera z `accepted=true`
i zgodnym `report_id`. Samo HTTP 200, strona HTML lub inny ID nie wystarczają. Wypisuje
losowy identyfikator raportu, który można porównać z backendem; nie wypisuje tokenu
ani odpowiedzi konfiguracyjnej. Nie wkładaj sekretu do argumentów procesu,
repozytorium, testowych fixture ani STRESZCZENIA.

Backend opublikowano prywatnie przez Sites; schemat i odbiornik przechodzą
10 testów Node/SQLite oraz TypeScript i build. Natywny odczyt Sites potwierdza
tabele `reports` i `latest_reports` (ta druga trzyma najwyżej 25 krótkich
podsumowań do bieżącej analizy). Dostęp usługowy pozwala wysłać raport, lecz
nie pobrać konfiguracji: pobieranie wymaga tożsamości odwiedzającego nadanej
przez prywatną bramę Sites. Część bram przekazuje e-mail bez stabilnego ID;
ten nagłówek służy wyłącznie potwierdzeniu logowania i nie jest zapisywany.

Użytkownik udzielił wyraźnej zgody na przesyłanie raportów do wskazanego
prywatnego serwera odpowiedzią „Zezwalam” 18.10.2026 po pytaniu z konkretnym
adresem. Zgoda dotyczy automatycznej diagnostyki tej gry; nie pytaj ponownie
o ten sam zakres. Wcześniejsza blokada automatycznej kontroli zgód jest rozwiązana.

Po zgodzie test HTTPS z rzeczywistego Godota zakończył się 8/8: HTTP 201,
JSON potwierdzający zgodny report_id, kolejka usunięta dopiero po potwierdzeniu.
Raport `7776631217b98a364c9ea5b2ddef86b0` odczytano następnie natywnym narzędziem
Sites w `latest_reports`, z ostatnim zdarzeniem `network_probe`. Jest to raport
testowego Godota na Linuxie, nie telefonu użytkownika. Baza nie zawiera tokenu.

Limit 5 s powodował timeout w środowisku z proxy; z limitem 15 s ten sam klient
poprawnie wysłał raport. Wersja 0.1.3 ustawia 15 s także w produkcji. Zmiana jest
asynchroniczna i nie zmienia zapisu ani rozgrywki. Test ma opcjonalny parametr
`--test-https-proxy=host:port` tylko dla QA i wypisuje wyłącznie kody transportu,
bez nagłówków ani treści odpowiedzi. Nie pomijaj walidacji TLS.

Końcowy test wersji 0.1.3, bez testowej zmiany timeoutu: 8/8 HTTPS oraz 29/29
lokalnej diagnostyki. Raport `4fc209b09051ccf728a5a51f73290fe7` został przyjęty
z HTTP 201 i potwierdzony w `latest_reports` z wersją `0.1.3`.

Aktywny automatyczny odczyt nowych awarii jest ustawiony co godzinę. Korzysta
wyłącznie z prywatnego odczytu `latest_reports` i pomija `test`/`checkpoint`.
Po podłączeniu telefonu sprawdź faktyczne nowe raporty, zanim zadeklarujesz ich
otrzymanie. Natywny stack trace Androida nadal nie jest gwarantowany.

Pełna regresja tej wersji: integracja 51/51, zapis 19/19, UI OpenGL 17/17,
kowal OpenGL 26/26, renderer OpenGL 54/54 (świeży katalog danych; liczba
warunkowych kontroli zależy od istniejącego zapisu), audio 13/13, diagnostyka
29/29. Końcowe testy OpenGL zakończone bez ostrzeżeń o pozostawionych obiektach.


## Wersja 0.1.4 — większy bohater i ustawienia kamery (historia)

Przed zleceniem tej zmiany użytkownik potwierdził, że w 0.1.3 może chodzić,
walczyć, zabijać potwory i ulepszać przedmioty. To obserwacja działającej gry
na jego telefonie. Nie ustalono konkretnej przyczyny wcześniejszego zamknięcia
procesu. Nowe zlecenie dotyczy bliższego widoku oraz własnego ustawienia kamery.

Oczekiwany numer w HUD to **v0.1.4**. Odczytywany jest z `application/config/version`,
a po aktualizacji należy uruchomić ponownie projekt, aby zobaczyć nowy numer.
Polecenie aktualizacji wyżej nadal zachowuje lokalny `project.godot` w stash
bez automatycznego przywracania i nie usuwa zapisu ani prywatnej konfiguracji.

**Menu → KAMERA** otwiera prawy panel 350 × 540 px z trzema suwakami:
przybliżenie 1,00–1,85× (domyślnie 1,35×), wysokość 38–65° (48°),
obrót −180–180° (0°). Domyślny obraz postaci jest około 35% większy niż
wcześniejszy daleki widok. Panel pozostawia świat i bohatera widoczne,
bez przyciemnienia. Kontrolki mają 48-pikselowe uchwyty i wartości liczbowe.
Ruch oraz walka są wstrzymane przez istniejące `modal_open`.

Suwaki wywołują `main.set_camera_settings(zoom,pitch,yaw)` na żywo.
`main.get_camera_settings()` zwraca słownik tych trzech wartości w stopniach
dla pitch/yaw, a `main.reset_camera_settings()` przywraca wartości domyślne.
HUD nie przebudowuje panelu podczas przeciągania; reset ustawia wartości przez
`set_value_no_signal` i aktualizuje etykiety bez usuwania aktywnej kontrolki.
**WRÓĆ DO MENU** przywraca pełny układ ustawień, **X** zamyka panel.

`CameraPivot` podąża za bohaterem, a `SpringArm3D` steruje odległością i obrotem
kamery. Dystans bazowy wynosi 20,2 m, długość ramienia to dystans/przybliżenie,
punkt obserwacji leży 1,05 m nad pozycją bohatera, FOV pozostaje 48°.
Ramię uwzględnia maski kolizji 1 (świat) i 4 (osobne bryły dachów), wykluczając
RID postaci; skraca widok przy przeszkodzie. `CameraRoofCollision` zawiera
11 wypukłych brył dachów tworzonych raz ze współrzędnych oryginalnej geometrii.
Nie zmieniają kolizji chodzenia. Osobny test fizyki potwierdził trafienie
promienia w dach z maską 4 oraz brak trafienia tego samego promienia z maską 1.
Kierunek wejścia obraca się razem z yaw kamery,
więc joystick/WASD nadal odpowiadają kierunkom na ekranie.

Preferencje są niezależne od postaci: `user://camera_settings.cfg`, sekcja
`camera` z zoom/pitch/yaw. Wartości są sprawdzane pod kątem typu, skończoności
i dopuszczalnych zakresów, plik jest ograniczony do 4 KiB. Zapis jest atomowy,
przez `.tmp` i zmianę nazwy, z opóźnieniem 0,4 s po ostatniej regulacji oraz
przy wyjściu ze sceny. Nowa Gra odtwarza scenę i postać, zachowując te preferencje.
Flaga `--test-isolated` domyślnie wyłącza zapis preferencji; test trwałości
wymaga jawnego, jednorazowego katalogu danych.

Automatyczne testy kamery oraz zrzuty OpenGL są odrębną weryfikacją tej wersji;
nie sumuj historycznych liczb kontroli jako nowego wyniku. Potwierdzenie
poprzedniej gry przez użytkownika nie zastępuje próby nowych suwaków na telefonie.
Wszystkie wcześniejsze zasady prywatnej diagnostyki, zgoda użytkownika,
endpoint i retencja pozostają aktualne.

Weryfikacja 0.1.4: import Godot 4.4.1; integracja sceny 51/51 i interfejs 17/17;
test kamery 40/40 headless oraz 43/43 z rzeczywistym OpenGL/Mesa. Test porównał
projekcję postaci: dawniej 50,65 px, teraz 68,17 px, wzrost 34,60%. Sprawdzono
osiem kierunków joysticka przy czterech obrotach, granice i reset ustawień,
odsunięcie kamery od przeszkody, zapis po 0,4 s oraz odczyt przez nową instancję.
Stary plik postaci pozostał identyczny bajt w bajt. Zrzuty 1280×720 i 1600×720
obejrzano: bohater pozostaje widoczny obok panelu, wszystkie trzy suwaki oraz
przyciski mieszczą się i są czytelne. Końcowy test OpenGL zakończył się czysto.

## Wersja 0.1.5 — większa postać przy zapisanym zbliżeniu

Użytkownik pokazał działającą 0.1.4 na telefonie: przybliżenie 1,85×,
wysokość 38°, obrót 0°. To był ówczesny maksymalny zoom; poprosił o jeszcze
trochę większą postać. Nie resetuj jego kamery ani postępu.

Dystans bazowy kamery zmieniono z 20,2 na 17,0 m. Przy tych samych zapisanych
wartościach bohater jest dzięki temu około 20% większy. Maksymalny zoom wzrósł
z 1,85 do 2,50 w modelu preferencji i obu miejscach HUD. Domyślne wartości
1,35× / 48° / 0° oraz zakresy wysokości i obrotu zachowano. Brak migracji pliku:
wcześniejsze `camera_settings.cfg` ładuje się z identycznymi wartościami.
Uchwyty suwaków mieszczą się teraz w torze także na skrajnych ustawieniach.

Wersja w HUD: **v0.1.5**. Aktualizacja jak wcześniej przez stash tylko
`project.godot` i zwykły pull gałęzi. Użytkownik zachowuje ustawienia 1,85×/38°;
po aktualizacji otrzymuje bliższy widok od razu, z dodatkowym zapasem do 2,50×.

Weryfikacja 0.1.5: import Godot 4.4.1, kamera 45/45 headless i 52/52 OpenGL,
czyste zakończenie. Przy identycznych 1,85×/38°/0° wysokość projekcji postaci
wzrosła ze 109,94 do 130,52 px, czyli o 18,71%. Sprawdzono dokładny odczyt
starego CFG, rozszerzone maksimum, zapis ustawień i niezmienność bajtów zapisu
postaci. Obejrzano zrzuty z trzecią zbroją przy 1,85× i 2,50×; bohater mieści
się obok panelu, a uchwyty pozostają w całości widoczne na końcach torów.

## Wersja 0.1.6 — kamera bez opóźnienia, animacja i czwarte uderzenie

Użytkownik zaakceptował zbliżenie 0.1.5 i zgłosił wrażenie rozmazywania podczas
biegu. Nie znaleziono włączonego filtra motion blur, DOF ani TAA. Usunięto
opóźnione podążanie kamery przez LERP; pivot jest ustawiany bezpośrednio na
pozycji bohatera plus punkt obserwacji. Ramię, kolizje, zoom i zapis preferencji
pozostają. To usuwa zwłokę śledzenia, ale nie stanowi pomiaru obrazu telefonu.

Zwykłe combo ma teraz cztery kroki. Trzy cięcia mają cooldown 0,48 s i kontakt
po 0,16 s; czwarty ma cooldown 0,64 s, kontakt po 0,25 s i obrażenia ×1,4.
Każdy cios odnawia okno 1,2 s na kontynuację. Czwarty odpycha tylko trafiony,
nadal żywy cel, siłą początkową 7,5 m/s, z wygaszaniem 22 m/s² i krótkim
zachwianiem 0,34 s. Ruch przechodzi przez `move_and_slide`, więc uwzględnia
kolizje świata. Przygotowanie ataku potwora zostaje przerwane. Śmierć i modal
usuwają odrzut; martwy cel nie otrzymuje ponownej nagrody ani impulsu.
Numer akcji anuluje stare oczekujące trafienie po skillu, śmierci lub wejściu
w panel. Skill przerywa serię. Schemat zapisu, ekonomia i diagnostyka bez zmian.

`CharacterVisual` zachowuje dotychczasowe siatki i ekwipunek, ale dodaje
osobne biodra, tułów, łokcie, kolana i nadgarstek. Cztery własne sekwencje
klatek kluczowych odpowiadają etapom przygotowania, kontaktu i powrotu;
kontakt wizualny przypada na te same czasy co obrażenia. Normalne cięcia nie
wyświetlają szerokiej wstęgi. Postój ma oddychanie i przenoszenie ciężaru,
a chód zginanie kolan, ruch tułowia i przejście z postoju.

Ważne dla dalszej pracy: użytkownik chce bardziej realistyczny model wojownika
i obejrzeć propozycje przed jego dodaniem. Pokazano planszę koncepcyjną A/B/C:
A — stalowa zbroja i granatowa tkanina, B — warstwowy pancerz i czerwień,
C — ciemna ozdobna ciężka zbroja ze złotymi detalami. To obraz projektowy,
nie gotowy model 3D ani zrzut gry. Żaden nowy model nie jest jeszcze włączony
do tej wersji; po wyborze trzeba przygotować siatkę, rig, materiały, dopasować
trzy poziomy zbroi i wyeksportować GLB do Androida. Nie obiecuj identycznej
szczegółowości ilustracji w renderze mobilnym. Przyszłe trzy klasy są poza
bieżącą aktualizacją. Nie kopiuj modeli, ubiorów ani animacji Metin2.

W HUD oczekiwane **v0.1.6**. Aktualizacja przez zachowanie `project.godot`
w stash i pull gałęzi, bez usuwania danych postaci i prywatnej konfiguracji.

Weryfikacja 0.1.6: import i zwykły start w Godocie 4.4.1; integracja 51/51,
nowy `combat_combo.gd` 55/55 headless i 60/60 OpenGL, interfejs 17/17
w obu trybach oraz kamera 45/45 w obu trybach (tym razem bez dodatkowych
zrzutów panelu kamery). Sprawdzono rzeczywiste cztery kontakty, brak impulsu
w pierwszych trzech, odrzut i jego wygaszenie, przerwanie WINDUP, kolizję ze
ścianą, reset po 1,2 s, zmianę zasięgu w trakcie ciosu, anulowanie przez panel,
zakaz ataku po śmierci i pojedynczą nagrodę za przeciwnika. Test potwierdza
też śledzenie kamery przy ruchu, zatrzymaniu i teleportacji, oddech bez dryfu
oraz przejście skill → zwykły cios bez obrotu wstecz. Ostrze przy każdym
kontakcie znajduje się z przodu i nad ziemią. Pięć zrzutów prawdziwego renderu
(postój i cztery kontakty) obejrzano. Dotychczasowy zapis pozostał identyczny
bajt w bajt; testy pracowały bez wysyłania raportów. To testy Linux/OpenGL,
nie próba nowej wersji na fizycznym telefonie.

## Wersja 0.1.7 — żywy podgląd, dotykowa kamera i Pierdolnięcie Miecza

Użytkownik pokazał działającą 0.1.6 i poprosił o obracany, animowany model
w oknie ekwipunku oraz wizualizację przyszłej grafiki. Następnie doprecyzował
kierunek referencją klasycznego azjatyckiego MMORPG: naturalna sylwetka,
wyraziste warstwowe zbroje i szeroki miecz, z własnym stylem oraz projektami.
To aktualny kierunek zamiast oczekiwania na wybór A/B/C. Pokazano koncepcję
wioski w tym klimacie i ekwipunku z realistycznym wojownikiem. To ilustracje
docelowego kierunku; nie przedstawiaj ich jako działających modeli ani renderu
telefonu. Ta wersja nadal używa dotychczasowej geometrii postaci i wioski.

### Podgląd ekwipunku

`ui/character_preview.gd` to samodzielny Control z jednym zachowanym
SubViewport 320×320, `own_world_3d`, własną kamerą, światłami i CharacterVisual.
Nie tworzy Hero, fizyki, dźwięku ani kopii całego świata; nie zmienia GameState.
MSAA, dodatkowe cienie i sky są wyłączone. Render `UPDATE_ONCE` żądany do 30 Hz,
ukrycie/focus out zatrzymuje tick, render i płomień. Instancja jest parkowana
pod HUD i przywracana przy bezpiecznej, odroczonej przebudowie panelu, więc
wybór karty, założenie przedmiotu, zmiana złota i ponowne otwarcie zachowują
obrót oraz jeden viewport. Nie odtwarzaj go przy każdym sygnale `changed`.

Ekwipunek ma dwie kolumny: portret z lewej, statystyki/plecak/akcje z prawej.
Sterowanie: przeciąganie palcem/myszą, W LEWO, RESET, W PRAWO, POSTÓJ, CIOS, BIEG.
Pokazuje aktualnie założony sprzęt i aktywny płomień miecza; nie zadaje obrażeń.
Kadr domyślny 3,8 powiększa postać. Cios poszerza kadr do 5,3 lub 6,0 przy
płomieniu, aby mieścić całe ostrze i iskry, po czym kadr wraca do wartości
spoczynku. To wyłącznie kamera portretu, niezależna od preferencji gry.

### Sterowanie kamerą i dotyk

`ui/camera_orbit_pad.gd` zajmuje pole pod minimapą, nad umiejętnościami po
prawej. Przesunięcie w poziomie zmienia yaw o −0,22°/px z zawijaniem, w pionie
pitch o +0,16°/px w granicach 38–65°. Zoom pozostaje, zapis używa istniejącego
opóźnienia preferencji. Można chodzić lewym palcem i obracać kamerę prawym.
Panel, śmierć i respawn blokują sterowanie. Sygnał HUD `camera_orbit_requested`
obsługuje `main.orbit_camera`.

QA wykrył, że Godot potrafi wysłać emulowany MouseButton przed właściwym
ScreenTouch. Dotychczasowy joystick przejmował wtedy palec jako mysz −2.
Joystick i RPGTouchPad odrzucają teraz emulowane urządzenia, zachowują indeks
prawdziwego palca i czyszczą stan po cancel/focus/hide/disable oraz utraconym
zwolnieniu myszy. Główne wybieranie celu ignoruje syntetyczny MouseButton;
prawdziwy dotyk świata nadal obsługuje własny ScreenTouch.

### Nowa umiejętność

Nazwa zgodna z prośbą: **Pierdolnięcie Miecza**. Osobny przycisk ognia obok
Wiru stali oraz klawisz F. Cooldown 20 s, blokada ruchu/ataków 1 s, kontakt
po 0,48 s. Bohater podnosi miecz oburącz i wbija go w ziemię. Własna animacja
używa dwóch segmentów IK ramion, aby druga dłoń pozostała na rękojeści;
kontakt końca ostrza jest 7 cm nad gruntem dla każdego tieru broni.

Na kontakt powstaje rozszerzający się krąg ognia i iskier, pojedyncze AoE
w promieniu 4 m z obrażeniami `attack_power*1.65+10`, następnie płonące ostrze
na 12 s. Bonus +30% dotyczy tylko zwykłych ciosów, w tym czwartego; Wir stali
i początkowe AoE mają własne obrażenia. Buff nie jest zapisywany w GameState
ani pliku postaci; śmierć i ratunkowy teleport usuwają go. Panel otwarty przed
kontaktem anuluje akcję bez obrażeń/efektu, zachowując już rozpoczęty cooldown.
Serial akcji oraz synchroniczny sygnał widoczności panelu anulują także
otwarcie i zamknięcie pomiędzy krokami fizyki. Sygnał HUD `fire_skill_requested`
i metoda `set_fire_skill_cooldown` nie przebudowują interfejsu co klatkę.

`scripts/sword_fire_effect.gd`: czerwone/żółte płomienie, gorący rdzeń ostrza,
białe iskry, dwa draw calle. `scripts/fire_impact.gd`: błysk, spiralny żar,
rozszerzający się pierścień, 28 języków ognia i 24 iskry w czterech siatkach;
efekt sam znika po 1,15 s. Bez tekstur z internetu, świateł, GPU particles,
pełnoekranowego rozmycia i alokacji w pętli. Barwy ulepszenia nie są nadpisywane.
Geometria jest ograniczona, materiały efektów są niezależne od ekwipunku.

W HUD **v0.1.7**. Aktualizacja zwykłym pull gałęzi po zachowaniu lokalnego
`project.godot` w stash, bez resetowania postaci ani prywatnej diagnostyki.

Weryfikacja 0.1.7 w Godot 4.4.1/Compatibility/Mesa: import i start bez błędów,
podgląd 32/32 headless i 34/34 OpenGL, ogień/kamera 38/38 headless i 41/41
OpenGL (ostatni dodany warunek emulowanego wybierania celu sprawdzono headless),
UI flow 17/17 OpenGL, integracja 51/51, kowal odroczony 26/26, combo 55/55.
Wszystkie właściwe sprawdzenia przeszły. Zbadano rzeczywiste wejście dotyku,
myszy i dwóch palców, aktualizację sprzętu bez odtwarzania viewportu, brak
aktywności ukrytego podglądu i zachowanie postępu. Testy nie wysyłały raportów.

Kadrowanie obejmuje osiem obrotów i jedenaście próbek każdego pełnego zamachu;
dodatkowy pomiar wizualny objął 24 obroty i 21 próbek, również z płomieniami.
Podczas dwuręcznego slamu odchyłka dłoni od rękojeści wyniosła do 2,8 cm
(wewnątrz rękawicy), a koniec ostrza pozostał 7 cm nad gruntem we wszystkich
czterech tierach broni i czterech kierunkach. Obejrzano rzeczywiste zrzuty
podglądu 1280×720/1600×720, podniesionego miecza, kręgu ognia i płonącego ostrza.
Premia wygasła po rzeczywistych 12 s, oczekujące trafienia były anulowane
przez panel/śmierć, a sprzęt zachował bazowe materiały ulepszeń. To weryfikacja
Linux/OpenGL; nowa wersja wymaga jeszcze próby użytkownika na jego Androidzie.
