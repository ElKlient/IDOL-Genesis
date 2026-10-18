# Żelazny Świt — przekazanie projektu 0.1.5

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
  wejście, 3-cio ciosowe combo,
  opóźnienie trafienia, automatyczny najbliższy cel / wybór dotykiem, skill obszarowy,
  mikstury, NPC, nagrody i respawn.
- `scripts/camera_preferences.gd`: niezależne preferencje kamery i atomowy zapis CFG.
- `scripts/game_state.gd`: autoload `GameState`, katalog, egzemplarze przedmiotów
  z UID, ekonomia, statystyki, zadanie i atomowy zapis JSON.
- `scripts/world.gd`: oryginalny świat budowany w kodzie; wspólne siatki dekoracji,
  wioska, targ, kuźnia, las, brama, staw, ruiny i 7 spawnów.
- `scripts/player.gd`, `character_visual.gd`: fizyka wojownika, animowane części
  ciała, ekwipunek zmieniający sylwetkę, miecz i zbroja 0–3, efekty ulepszenia.
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

Za północną bramą (z=-14) są potwory. Normalny cios ma cooldown0.48s i windup0.16s.
Trzeci cios mocniejszy, 14% trafień krytycznych. Wir stali ma zasięg4.2m i cooldown7s.
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
cd /storage/emulated/0/Godot/ZelaznySwit && git stash push -m "Ustawienia Godota przed aktualizacja" -- games/zelazny-swit/project.godot && git pull --ff-only origin zelazny-swit && git --no-pager log -1 --oneline
```

Nie usuwaj `.godot`, nie stosuj `reset --hard`, nie zmieniaj gałęzi na `main`.
Blok zachowuje lokalny `project.godot` w stash. Nie przywracaj go automatycznie,
aby nie usunąć nowych autoloadów ani ustawień mobilnych. Pozostałe lokalne zmiany
sprawdź przez `git status --short`; nie odrzucaj ich. Ignorowany plik
`diagnostics.local.json` i zapis postaci pozostają po aktualizacji.

## Zakres i ograniczenia

To pierwsza grywalna lokalna wersja, nie pełne MMORPG. Brak multiplayera, innych klas,
rozległych map i kampanii. Grafika jest celowo oryginalna i stylizowana; wszystkie
modele, ikony i dźwięki generuje kod, bez zewnętrznych paczek i importu Blendera.
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
