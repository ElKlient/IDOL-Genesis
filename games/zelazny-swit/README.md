# Żelazny Świt — 0.2.2

Oryginalna, jednoosobowa gra akcji RPG 3D na telefon, napisana w Godocie 4.4+.
Sterowanie dotykowe w poziomie. Mały grywalny wycinek: wioska Brzeziny, wojownik,
handlarka Mira, kowal Born i dzicz z wilkami, dzikami oraz Strażnikiem Korzeni.

**Nowa postać zaczyna z 10 000 G, 10 miksturami i mieczem rekruta.**

## Pierwsze pobranie na telefon

Wklej w Termuxie (Termux, Git i Godot są już skonfigurowane):

```bash
mkdir -p /storage/emulated/0/Godot && cd /storage/emulated/0/Godot && git clone --depth 1 --filter=blob:none --sparse --single-branch --branch zelazny-swit https://github.com/ElKlient/IDOL-Genesis.git ZelaznySwit && git config --global --add safe.directory /storage/emulated/0/Godot/ZelaznySwit && cd ZelaznySwit && git sparse-checkout set games/zelazny-swit
```

W Godocie na Androidzie: **Importuj → wybierz**
`/storage/emulated/0/Godot/ZelaznySwit/games/zelazny-swit/project.godot`
**→ Importuj i edytuj → ▶**. Obróć telefon poziomo.

Gra jest osobnym projektem w osobnej gałęzi `zelazny-swit`.
Pozostałe projekty i gałąź `main` pozostają w dotychczasowym stanie.
Rzadkie pobranie (sparse checkout) ogranicza pobieranie plików do nowej gry.
Importuj dokładnie projekt wskazany powyżej; główny `project.godot` repo dotyczy starszej gry.

Jeżeli Android zgłosi brak dostępu do pamięci, uruchom `termux-setup-storage`,
udostępnij pliki i powtórz pobranie. Istniejącego folderu nie kasuj ani nie klonuj
ponownie — do aktualizacji służy następny blok.

## Pierwsze pięć minut

1. Lewym joystickiem idź do **Miry**, przy straganie po lewej stronie placu.
   Gdy zobaczysz przycisk „Mira • Handel”, naciśnij go.
2. Kup **Szablę Karmazynowej Straży (350 G)** albo lepszy oręż. Kup także zbroję.
3. Otwórz plecak, wybierz przedmiot i załóż go. Broń oraz zbroja zmieniają wygląd postaci.
4. Idź do **Borna**, przy kuźni po prawej. Przeciągnij przedmiot z listy
   na pole kowala albo wybierz go dotknięciem. Zobacz koszt i naciśnij **Ulepsz**.
   Pierwsze ulepszenie szabli kosztuje **180 G** i ma **100%** szans.
5. Wyjdź przez północną bramę. Podejdź do wilka i przytrzymaj przycisk ataku.
   Łupy i doświadczenie odbierasz automatycznie. Mikstura leczy 90 PŻ,
   a **Wir stali** uderza pobliskich wrogów i odnawia się przez 7 sekund.
6. Po kupnie miecza, dowolnym ulepszeniu i pokonaniu 3 potworów wróć do Miry
   po **1200 G i 5 mikstur**. Dalej na północy czeka silniejszy Strażnik Korzeni.

## Zasady

- 3 rodzaje mieczy i 3 zbroje; każdy przedmiot ma własny poziom ulepszenia.
- +1, +2, +3: **100%**; +4: **80%**; +5: **65%**; +6: **50%**.
- Nieudana próba zużywa tylko złoto. Przedmiot i dotychczasowy poziom zostają.
- Postać zdobywa poziomy, które zwiększają zdrowie i siłę. Awans odnawia zdrowie.
- Śmierć przenosi do wioski bez utraty złota ani ekwipunku.
- Potwory odradzają się po 18 s (Strażnik po 24 s).
- Zwykły atak tworzy serię czterech ciosów: trzy cięcia i mocniejszy czwarty
  cios, który odrzuca żywego przeciwnika. Przerwa 1,2 s rozpoczyna serię od nowa.
- Zapis automatyczny po zakupie, zmianie sprzętu, ulepszeniu i łupach;
  również co 12 sekund oraz po przejściu aplikacji w tło.
- Zapis: `user://adventure_v1.json`, z kopią poprzedniej wersji `.bak`.
  Aktualizacja źródeł nie usuwa postępu. Dane edytora i eksportu APK mogą być odrębne.
- Rozgrywka działa offline, bez konta gracza, zakupów i reklam. Opcjonalna sieć
  służy wyłącznie prywatnym raportom diagnostycznym opisanym niżej.

## Sterowanie

Telefon: lewy joystick; po prawej atak, dwie umiejętności, mikstura i rozmowa w pobliżu NPC.
Przeciągnij palcem w polu **KAMERA** nad umiejętnościami, aby obracać i pochylać
widok. Możesz jednocześnie chodzić lewym joystickiem.
Dotknij przeciwnika, by wybrać cel. Przycisk plecaka otwiera przedmioty i statystyki.

Komputer: **WASD/strzałki** — ruch, **Spacja** — atak, **R** — Wir stali,
**F** — Pierdolnięcie Miecza, przeciąganie w polu KAMERA — obrót widoku,
**Q** — mikstura, **E** — rozmowa, **I** — plecak, **Tab** — zmiana celu,
**Esc** — zamknięcie panelu. Android Wstecz zamyka panel lub otwiera ustawienia.

## Kamera i większa postać

Wybierz **Menu → KAMERA**. Wąski panel po prawej pozwala ustawiać widok na żywo,
z widocznym bohaterem pośrodku ekranu. Na czas regulacji ruch i walka są wstrzymane.

| Suwak | Zakres | Domyślnie |
| --- | --- | --- |
| Przybliżenie | 1,00–2,50× | 1,35× |
| Wysokość widoku | 38–65° | 48° |
| Obrót | −180–180° | 0° |

W 0.1.5 kamera jest bliżej bohatera również przy zapisanych wcześniej ustawieniach.
Przy 1,85× i 38° postać jest jeszcze około 20% większa niż w 0.1.4.
Suwak pozwala teraz przybliżyć obraz aż do 2,50×.
**PRZYWRÓĆ DOMYŚLNE** cofa trzy suwaki do wartości z tabeli. **WRÓĆ DO MENU**
przenosi do ustawień, a **X** zamyka panel i wznawia grę.

Joystick i klawiatura działają względem ekranu także po obrocie kamery.
Przy przeszkodach kamera skraca dystans, aby ograniczyć przenikanie przez budynki.
Ustawienia zapisują się automatycznie po chwili i pozostają po ponownym
uruchomieniu, aktualizacji oraz wybraniu Nowej Gry.

Od 0.1.6 kamera śledzi bohatera bez opóźnionego doganiania. Gra nie korzysta
z filtra motion blur. Przybliżenie i własne ustawienia pozostają zapisane.

## Aktualizacja

Zamknij projekt w Godocie. W Termuxie:

```bash
cd /storage/emulated/0/Godot/ZelaznySwit && git -c user.name=Backup -c user.email=backup@localhost stash push -m "Ustawienia Godota przed aktualizacja" -- games/zelazny-swit/project.godot && git pull --ff-only origin zelazny-swit && git --no-pager log -1 --oneline
```

Potem otwórz ten sam `games/zelazny-swit/project.godot` i naciśnij ▶.
Polecenie zachowuje ewentualne lokalne zmiany `project.godot` w `git stash list`.
Nie przywraca ich automatycznie: nowa wersja zawiera wymagane ustawienia mobilne
i autoload diagnostyki. Zapis postaci oraz prywatna konfiguracja raportów zostają.
Nie używaj resetowania ani usuwania folderu. W HUD pod zdrowiem sprawdź numer **v0.2.2**.

## Uruchamianie i zakres

- Godot **4.4.1** lub nowszy z obsługą GDScript; Compatibility / OpenGL.
- Projekt działa bez Blendera, pobierania paczek i instalowania dodatków.
- Wojownik korzysta z prawdziwej siatki i szkieletu przygotowanych w Blenderze:
  baza ludzka Quaternius CC0, własne zbroje i miecze, współdzielone tekstury PBR.
  Ikony przedmiotów to rendery tych samych modeli. Świat i jego materiały,
  animacje, efekty oraz dźwięki powstają z kodu.
  Pochodzenie: [docs/ASSETS.md](docs/ASSETS.md).
- Rozdzielczość bazowa 1280 × 720, poziomy ekran, interfejs skaluje się do telefonu.
- Jest to pierwszy grywalny wycinek, a nie rozbudowane MMORPG: brak rozgrywki
  wieloosobowej, klas poza wojownikiem, rozległych map i pełnej kampanii.
- Udostępniony jest projekt do uruchomienia w Godocie, nie gotowy instalator APK.
- Użytkownik potwierdził chodzenie, walkę, zabijanie potworów i ulepszanie
  przedmiotów na swoim telefonie oraz zaakceptował zbliżenie kamery 0.1.5.
  Zrzuty użytkownika pokazują także uruchomioną 0.1.6, a później potwierdził
  działanie nowego wojownika. Wersja 0.2.0 została sprawdzona na Linuxie;
  wydajność tej aktualizacji na jego telefonie wymaga próby po pobraniu.

## Aktualizacja 0.2.2 — materiały i otoczenie

Brzeziny mają ciągłe, teksturowane podłoże: trawa przechodzi nieregularnie
w wydeptaną ziemię, a bruk prowadzi przez plac i podejście do bramy. Kamienie
mają nierówne kształty, przetarcia i normal mapę krawędzi. Znikają duże,
ostro odcięte kolorowe plamy dawnego podłoża.

Iglaki mają ażurowe pędy igieł zamiast zamkniętych stożków, drzewa liściaste
bardziej rozczłonkowane korony, a dzicz kępy trawy i paprocie. Trawa i końce
pędów lekko reagują na wiatr. Budynki mają kamienne narożniki, okucia drzwi
i wsporniki okapu. Dalsze grzbiety gór mają gęstszy obrys.

Delikatne chłodne światło wydobywa szczegóły twarzy i ciemnego pancerza.
Obejmuje wyłącznie wojownika i nie tworzy dodatkowej mapy cieni. Tryb
oszczędny ukrywa nową trawę i pomija normal mapy terenu. MSAA pozostaje stałe.

Cały świat ma **91 856 trójkątów i 61 powierzchni materiałów**. Dwie nowe mapy
(sterowanie podłożem i igły) współdzielą mipmapy; największa ma 512².
To budżet zasobów, a wydajność Androida trzeba ocenić na telefonie.
Układ przejść, postęp i animacje ciosów z 0.2.1 pozostają zgodne.

Rzeczywiste ujęcia z Godota: [wioska](docs/valley-village-0.2.2.png),
[dzicz](docs/valley-forest-0.2.2.png), [staw](docs/valley-pond-0.2.2.png).
Zdjęcia demonstracyjne pokazują kupiony sprzęt; nowa postać nadal zaczyna
z 10 000 G. To kolejny etap grafiki z dotychczasowymi modelami wojownika,
NPC i potworów.

## Aktualizacja 0.2.1 — prowadzenie miecza

Zwykłe ataki prowadzą teraz dłoń i klingę po wspólnej trajektorii, a ramię
jest dopasowywane przez IK. Usunięto niezależne skrajne obroty barku i nadgarstka,
które powodowały machanie mieczem dookoła postaci. Garda jest bliżej ciała,
cięcia mają osobne kierunki, a czwarty cios korzysta z oburęcznego chwytu
oraz wyraźniejszego ruchu w przód i w dół. Biodra wyprzedzają obrót tułowia.

Joystick nie obraca już postaci w połowie zwykłego cięcia, a szum ostrza jest
zsynchronizowany z zamachem. Zachowano terminy obrażeń, czteroczęściową serię,
odrzut, ceny, zapis i sprzęt.

[Film z Godota: nowa seria ciosów i podgląd](docs/warrior-motion-0.2.1.mp4)
(10 s). Wilk na nagraniu ma wstrzymane AI i zwiększone PŻ do demonstracji
całej serii. W normalnej grze statystyki i AI są zachowane.

Walidacja Godot 4.6: ciągłość animacji 69/69, combo 55/55, integracja 50/50
oraz model 50/50 OpenGL. Szczegóły w `tests/README.md`.

## Aktualizacja 0.2.0 — trzy linie wyposażenia

Wojownik otrzymał dopasowane, warstwowe pancerze z odrębnymi sylwetkami,
metalowymi obrzeżami, wiązaniami i tkaniną deformowaną szkieletem. Trzy rodziny
mają własne modele kling i gard oraz materiały stali, skóry, tkaniny i kamieni.

| Zestaw | Wygląd | Broń | Zbroja |
| --- | --- | ---: | ---: |
| Karmazynowa Straż | stal, złote okucia, karmazynowa szarfa i asymetryczne naramienniki | 350 G | 500 G |
| Jadeitowa Brama | jasny napierśnik, brąz, jadeit i długie turkusowe poły | 1300 G | 1800 G |
| Popielny Żar | czernione żelazo, skórzane pasy i ciemne bordo | 3400 G | 4200 G |

Dotychczasowe identyfikatory przedmiotów, ceny, statystyki i zapis pozostają
zgodne. Sprzęt ze starego zapisu otrzymuje nowe nazwy i modele automatycznie.
Poziom ulepszenia zmienia wygląd powierzchni; delikatna emisja klingi korzysta
z maski krawędzi i graweru. Płonące ostrze nadal uruchamia osobna umiejętność.

Postój i bieg płynniej przechodzą w cięcia. Czwarty cios korzysta z oburęcznego
chwytu, a trafieniu towarzyszą krótka reakcja przeciwnika, iskry, pył i nowy dźwięk.
Krótka pauza animacji przy kontakcie nie zatrzymuje fizyki ani zegara gry.
Terminy obrażeń, odrzut, premie i odnowienia umiejętności są zachowane.

Podgląd w ekwipunku ma **obrót, przybliżenie +/− oraz POSTÓJ / CIOS / BIEG / POZA**.
Przybliżenie pozwala obejrzeć twarz i napierśnik. RESET przywraca obrót i skalę.
Ukryte okno nie renderuje; aktywny portret pracuje maksymalnie w 30 Hz przy 512².

Wioska ma teksturowane podłoże, kamień, drewno, dachy i tkaniny, łagodniejsze
przejścia ścieżek, poprawione korony drzew i odległe grzbiety gór. Układ przejść,
NPC i potworów pozostaje ten sam. Nie dodano rozmycia ruchu, DOF ani glow.

Wojownik z najcięższym mieczem i zbroją ma około **25,5 tys. widocznych
trójkątów i 8 powierzchni materiałów**. Największe tekstury mają 1024²;
postać w świecie i podgląd współdzielą siatki oraz obrazy. To ograniczenia
zasobów przygotowane pod telefon, nie deklaracja zmierzonego na nim FPS.

Plansze koncepcyjne wyznaczają kierunek. Modele w grze zachowują stylizowane
proporcje i budżet telefonu; koncepcje nie są zrzutami gotowej rozgrywki.

Rzeczywiste modele z finalnych GLB w studyjnym oświetleniu Blendera:
[Karmazynowa Straż](docs/warrior-karmazynowa-0.2.0.png),
[Jadeitowa Brama](docs/warrior-jadeitowa-0.2.0.png),
[Popielny Żar](docs/warrior-popielny-0.2.0.png).

Rzeczywiste kadry finalnej gry z Godota:
[przybliżenie w ekwipunku](docs/warrior-inventory-0.2.0.png),
[wojownik i płonący miecz w Brzezinach](docs/warrior-village-0.2.0.png).

[Film z Godota — trzy zestawy, bieg, cztery ciosy i ogień](docs/warrior-motion-0.2.0.mp4)
trwa 17 sekund. To nagranie rzeczywistego renderera na Linuxie, z demonstracyjnym
wyposażeniem i złotem oraz wilkiem o zwiększonych PŻ, aby pokazać całą serię.
Nowa gra nadal zaczyna od 10 000 G; nagranie nie mierzy FPS telefonu.

Końcowa weryfikacja pakietu HD przeszła **69/69 sprawdzeń headless** oraz
**85/85 OpenGL na świeżym imporcie źródeł**, z 16 rzeczywistymi zrzutami.
Przeszły także testy zakupów, odroczonego kowala, zapisu, czterech ciosów,
ognia, podglądu i dźwięku. Szczegóły: [tests/README.md](tests/README.md).

## Aktualizacja 0.1.8 — nowy wojownik i wyposażenie

Dotychczasową klockową postać zastępuje model ze skórą, twarzą, palcami,
czarnymi włosami i naturalnymi proporcjami. Ma ciągłą siatkę deformowaną
szkieletem 65 kości. Trzy zbroje mają osobną geometrię: brązowy pancerz,
błękitną stal oraz ciemny pancerz Świtu ze złotymi obrzeżami i karmazynową
tkaniną. Każdy miecz także ma nowy model, w tym szerszą klingę Miecza Świtu.

Nowy wojownik działa w wiosce i obracanym podglądzie ekwipunku. Zachowuje
oddech, bieg, cztery ciosy, oburęczne Pierdolnięcie Miecza i płonące ostrze.
Podgląd ma bliższy kadr postaci, rozszerzany podczas ataku. Zmiana wyposażenia
podmienia wygląd także na istniejącym zapisie; nie wymaga rozpoczynania gry.

Model z najcięższą zbroją i mieczem ma około **15,5 tys. widocznych trójkątów**,
do **14 powierzchni materiałów** i tekstury do **1024 × 1024**. Gotowe GLB zajmują
łącznie około **5 MB**. Siatki i tekstury są współdzielone z podglądem,
a zamknięty podgląd nie renderuje. To budżet przygotowany pod telefon;
wydajność tej wersji na urządzeniu użytkownika wymaga sprawdzenia.

[Zbliżenie rzeczywistego modelu w Blenderze](docs/warrior-model-0.1.8.png)
oraz [zrzut ekwipunku z Godota](docs/warrior-inventory-0.1.8.png).

## Aktualizacja 0.1.7 — podgląd postaci, kamera i ogień

**EKWIPUNEK** pokazuje żywą postać 3D w osobnym okienku. Przeciągaj po modelu,
aby obracać go o 360°. **W LEWO** i **W PRAWO** obracają widok, **RESET** go ustawia,
a **POSTÓJ**, **BIEG** i **CIOS** pokazują animacje. Podgląd nosi założony miecz
i zbroję, reaguje na zmianę wyposażenia i zachowuje obrót podczas wybierania
przedmiotów. Po zamknięciu okna przestaje renderować.

**Pierdolnięcie Miecza** to nowa, osobna umiejętność wojownika. Bohater chwyta
miecz oburącz, uderza w ziemię i wywołuje krąg ognia. Trafienie zadaje obrażenia
wrogom w pobliżu i podpala ostrze na **12 sekund**: płomienie oraz jasne iskry
towarzyszą zwykłym ciosom, które zyskują **30% obrażeń**. Odnowienie wynosi
**20 sekund**. Wir stali zachowuje dotychczasowe działanie. Umiejętność nie
zużywa złota ani przedmiotów i nie zapisuje premii jako statystyki ekwipunku.

Przyciskiem **KAMERA** po prawej sterujesz widokiem bez otwierania menu:
przeciąganie na boki obraca, a w pionie zmienia wysokość. Przybliżenie nadal
ustawiasz w Menu → KAMERA; obrót zapisuje się w tych samych preferencjach.

Pokazane wizualizacje wioski i realistycznego wojownika to koncepcje docelowej
grafiki. Kierunek wskazany przez użytkownika: klasyczne azjatyckie MMORPG,
naturalna sylwetka, efektowne warstwowe zbroje i szeroki miecz, z własnymi
projektami. W 0.1.7 wprowadzono podgląd i efekty; od 0.1.8 używają nowego modelu.

## Aktualizacja 0.1.6 — ruch i cztery ciosy

Wojownik ma cztery odrębne animacje ataku z przygotowaniem, cięciem i powrotem
do pozycji. Czwarty cios ma dłuższe przygotowanie i odrzuca trafionego żywego
przeciwnika, przerywając jego przygotowany atak. Odrzut podlega kolizjom świata.
Postój ma subtelny oddech i przenoszenie ciężaru, a ruch korzysta z osobnych
stawów łokci i kolan. To aktualizacja animacji dotychczasowej postaci.

Po planszy A/B/C użytkownik wskazał kierunek klasycznego azjatyckiego MMORPG.
Plansze koncepcyjne nie są zrzutami gry. Rzeczywisty model i zbroje dodano
w 0.1.8, zachowując wyposażenie i postęp.

Dokładny raport weryfikacji i informacje dla kolejnego agenta: [docs/STRESZCZENIE.md](docs/STRESZCZENIE.md).


## Poprawka 0.1.2 — kowal, dźwięk i diagnostyka

Ulepszenie wykonuje się dopiero po zakończeniu obsługi dotyku. Powtarzające się
sygnały przycisku łączą się w jedną próbę, a panel przebudowuje się raz po zmianie
stanu. Zamknięcie kuźni lub wybór innego przedmiotu anuluje oczekującą próbę bez
opłaty. Przeciągnięcie na kowadło nadal tylko wybiera przedmiot.

Ośmiosekundowy podkład dźwiękowy korzysta z odroczonego ponowienia odtwarzania
zamiast natywnej pętli WAV. MSAA na telefonie pozostaje wyłączone od startu;
usunięty w 0.1.1 automatyczny przełącznik grafiki po 8 sekundach nie wraca.
Użytkownik zgłosił dalsze zamknięcie procesu po 0.1.1, a następnie potwierdził
prawidłowe działanie rozgrywki w 0.1.3. Konkretna przyczyna poprzednich awarii
nie została potwierdzona.

## Jednorazowe włączenie prywatnych raportów

W 0.1.3 limit czasu asynchronicznego połączenia wynosi 15 s. Rzeczywisty
test wysyłki z Godota i odczyt raportu w prywatnej bazie zostały potwierdzone.

1. Na telefonie otwórz [konfigurację diagnostyki](https://zelazny-swit-diagnostyka.sethoyt.chatgpt.site),
   zaloguj się na konto właściciela strony i przyciskiem pobierz `diagnostics_config.json`
   do folderu **Download**.
2. Zamknij uruchomioną grę i wklej w Termuxie:

   ```bash
   cp /storage/emulated/0/Download/diagnostics_config.json /storage/emulated/0/Godot/ZelaznySwit/games/zelazny-swit/diagnostics.local.json
   ```

3. Uruchom ponownie projekt. W **Menu → Automatyczne raporty błędów** zobaczysz
   stan diagnostyki. Konfigurację pobiera się raz; aktualizacje jej nie usuwają.

Plik `diagnostics.local.json` zawiera prywatny klucz do serwera raportów i jest
ignorowany przez Git. Nie dodawaj go do repozytorium. Bez tego pliku gra nadal
działa; raporty pozostają lokalne. Raporty możesz wyłączyć przełącznikiem w menu.
Brak internetu nie zatrzymuje gry, a ograniczona kolejka ponawia wysyłanie w tle.

Raport zawiera wersję gry i Godota, system, renderer, losowy identyfikator
instalacji, ostatnie zdarzenia gry oraz przefiltrowany fragment błędów z jej logu.
Nie wysyła kontaktów, lokalizacji ani plików zapisu postaci. Prywatny serwer
przechowuje raporty do 14 dni, maksymalnie 1000 rekordów.

Po nieoczekiwanym zamknięciu uruchom grę ponownie, aby mogła zgłosić niedomkniętą
sesję i ostatnie zachowane zdarzenia. To wskazówka diagnostyczna: zamknięcie przez
system lub użytkownika też może zostawić taką sesję. Natywna awaria silnika nie
zawsze pozostawia stos wywołań w logu Godota; raport nie gwarantuje jego uzyskania.
