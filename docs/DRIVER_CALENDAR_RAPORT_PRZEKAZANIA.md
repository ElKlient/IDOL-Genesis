# Kalendarz Kierowcy — pełny raport przekazania

Stan: 26.09.2026, strefa Europe/Amsterdam.
Ostatnia zmiana kodu: 95defa73f8dc0918b87e12edd9bbe11e5c88b837.
Raport obejmuje historię projektu od pierwszej wersji, późniejszy audyt,
dystrybucję beta, iPhone i bieżące poprawki. Wcześniejsze etapy odtworzono
z historii Git i dokumentacji; nie wszystkie wykonał ten sam agent.

1. PROJEKT I CEL

Kalendarz Kierowcy to osobna aplikacja Godot. Właściciel jest kierowcą i chce
ją dopracować, przetestować z około 15–20 kierowcami, wydać i na niej zarabiać.
Obecny etap: rozwój i testy beta. Nie wdrożono płatności ani sprzedaży.

Repo: https://github.com/ElKlient/IDOL-Genesis
Branch: https://github.com/ElKlient/IDOL-Genesis/tree/driver-shift-calendar
Raport: docs/DRIVER_CALENDAR_RAPORT_PRZEKAZANIA.md
Krótki stan roboczy: docs/DRIVER_CALENDAR_STRESZCZENIE.md
Dodatkowy prompt: NEXT_CHAT_PROMPT.md

Zakresy należy bezwzględnie rozróżniać:
- Kalendarz Kierowcy: katalog główny repo na driver-shift-calendar.
- Wspólny Kalendarz: apps/wspolny-kalendarz, osobna aplikacja.
- IDOL Genesis: gra rozwijana na main; nie jest przedmiotem tego raportu.
- Serwis kodów, pobierania i iPhone: osobny projekt Sites, opisany niżej.

Nie tworzyć kalendarza ponownie od zera. Robić małe, celowane łatki.
Użytkownik preferuje polski, konkretne odpowiedzi i komendy do skopiowania.

2. CO ZROBIONO OD POCZĄTKU

09.09 — pierwsza aplikacja i podstawowy interfejs:
- MVP kalendarza kierowcy: acb8b9d.
- Pionowy ekran, siedem kafelków dni w rzędzie, ciemny motyw z ciężarówką.
- Oznaczenia pracy, domu, pauz, urlopu, notatki i ręczne poprawianie dni.
- Obsługa cykli, stałego dnia rozpoczęcia tygodnia i własnego grafiku.
- Pusty kalendarz na start oraz instrukcje układania pierwszych cykli.
- Usunięto dni wyjazdu/zjazdu; nie przywracać ich na podstawie starego README.
- Dodano reset, cofanie resetu, powrót do dzisiaj, ramkę dzisiejszego dnia,
  profile, chowane ustawienia i tryb „tylko kalendarz”.
- Tło zawiera napis „Dasko” i „Always too late”.

09–21.09 — poprawki gestów i nawigacji:
- Wielokrotnie uszczelniano blokadę poziomego przesuwania i przypadkowych tapów.
- Miesiąc/rok mają zmieniać się wyłącznie po użyciu przycisków.
- Przywrócono wybór zakresu miesiąc/kwartał/pół roku/rok i czytelne siatki.
- Usunięto stary panel wyboru systemów/cykli. Dodatkowa ochrona runtime usuwa
  pozostałości starego menu po charakterystycznych tekstach.
- Historyczne blokady całego pionowego przewijania zostały później zastąpione
  wspólnym pionowym scrollem; nie cofać aktualnego zachowania.

21–25.09 — liczniki, godziny i profile:
- Rozpoczęcie i potwierdzane zakończenie pracy; plan zmiany 15 godzin.
- Pauzy 9, 11, 24, 45 i 48 godzin, odliczanie i kasowanie czasu pauzy.
- Godziny dla konkretnego dnia, ręczne dodawanie, suma miesiąca,
  ukrywanie godzin bez kasowania i osobne czyszczenie dnia/miesiąca.
- Edycja dnia i okno wpisywania godzin zachowują wybraną datę.
- Powiększono i uporządkowano menu profili; dodawanie, zapis, odczyt,
  usuwanie dodatkowych slotów i wczytywanie pustego kalendarza.
- Istotny commit profili: d2ef7ca.

25.09 — audyt i naprawy wiarygodności danych:
- Raport: docs/DRIVER_CALENDAR_AUDYT_2026-09-25.md.
- Test bazowy miał 15 PASS i 9 FAIL; po poprawkach 48 PASS, 0 FAIL.
- 35e2a0b: izolacja profili, automatyczny zapis aktywnego profilu,
  ochrona liczników przed ponownym startem i przywracaniem starych czasów.
- 89a7d83: zapis atomowy, kopia poprzedniego poprawnego pliku, odzyskiwanie
  uszkodzonego zapisu i widoczne komunikaty o nieudanym zapisie.
- 9a84a13: zakończenie pracy rozpoczyna wybraną pauzę; godziny przypisane
  do zapamiętanego dnia rozpoczęcia, również dla zmiany przez północ.
- 44cb63c: układ, brak nakładania przycisków Profile/Dzisiaj, dostępność
  przewijanych menu oraz akcje dopiero po puszczeniu palca.
- Ówczesna blokada przełączania profili podczas pracy/pauzy była rozwiązaniem
  historycznym. Została celowo usunięta 26.09, patrz punkt 4.

25.09 — dystrybucja beta Android:
- 32f15f7, 25e73f4, 6a901c2, 688c1d7.
- Zbudowano i podpisano pierwszą APK, przygotowano aktywację kodami na 30 dni,
  panel właściciela, odwoływanie dostępu i publikowanie kolejnych instalatorów.
- Aplikacja sprawdza podpisane pozwolenie offline; aktualizacja nie odnawia
  terminu testów i ma zachować dane istniejącej instalacji.
- Dodano skrypt budowania/weryfikacji i testy ciągłości danych.

25.09 — wersja iPhone i poprawka WEB 2:
- b28e9a2, 4fc299c, eb043d5: eksport tej samej aplikacji Godot do Safari/PWA,
  ikona na ekranie głównym, kody, zapis lokalny, eksport/import kopii,
  cache offline i aktualizacja bez czyszczenia danych.
- 1696a19, 97a8ab1: po zgłoszeniu problemów z wklejaniem kodu i skalowaniem
  wprowadzono natywne pole HTML, obsługę schowka oraz visualViewport/DPR.
- Otwarcie klawiatury zmienia dostępną wysokość, bez zmniejszania całego UI.
- Nie zbudowano IPA, nie użyto TestFlight ani nie utworzono konta Apple.

26.09 — czytelne godziny i wspólne przewijanie:
- 9c02b80: większe godziny na kafelkach w formacie 13:15, 13:30, 10:00.
  Dane zachowują dokładne sekundy; wyświetlanie nie zaokrągla do kwadransów.
- Kafelki otrzymały wysokość uwzględniającą tekst i dolny pasek akcentu.
- 78c837a: kalendarz i dolny panel pracy/pauzy przewijają się razem palcem,
  bez widocznego suwaka. Górne przyciski zostają na miejscu.
- Usunięto techniczną przyczynę przerywania pionowego gestu: bezwarunkowe
  ustawianie scroll_horizontal = 0 co klatkę. Ustawienie następuje tylko,
  gdy wartość rzeczywiście wymaga poprawy. Blokada pozioma pozostała.
- 3741503: dokumentacja tych zmian; test mobilny 19 PASS, regresja 48 PASS.
- Telefon początkowo uruchamiał starą wersję, bo git pull przerywał się
  na lokalnej zmianie project.godot. Po zachowaniu tego pliku w git stash
  i aktualizacji użytkownik potwierdził: „Dobra, teraz działa”.

26.09 — liczniki podczas przeglądania innych profili:
- 95defa7: praca i pauza trwają podczas wczytywania/zapisywania profili.
- 66 PASS, 0 FAIL w rozszerzonym audycie. Szczegóły aktualnego działania poniżej.
- Na moment raportu użytkownik nie przekazał jeszcze wyniku tej ostatniej
  łatki na telefonie. Potwierdził wcześniejsze godziny i wspólny scroll.

3. LINKI I FAKTYCZNIE UDOSTĘPNIONE WERSJE

Strona dla testerów:
https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site

Android — bezpośrednie pobranie aktualnie opublikowanej APK:
https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site/download

iPhone — otworzyć w Safari, następnie Udostępnij → Dodaj do ekranu głównego:
https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site/iphone/

Panel właściciela — kody, dostęp i publikacja APK:
https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site/admin

Publiczne metadane aktualnej APK:
https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site/api/releases/latest

Sprawdzenie 26.09.2026: strona, /download, /iphone/ i metadane odpowiedziały
HTTP 200; /download zwrócił typ APK i początek pliku ZIP. To kontrola
dostępności, nie ponowna instalacja ani pełna weryfikacja całego instalatora.

Stan dystrybucji:
- Źródła Godot/Termux: kod do 95defa7, czyli wszystkie poprawki z 26.09.
- Publiczna APK: version_code 1, version_name 0.1.0-beta.1,
  Kalendarz-Kierowcy-Beta-1.apk, 51 631 346 bajtów według API.
  SHA-256 podana przez API:
  5e76bfaf1d45821651b0ded95dc39e3ae9b24169e36df25bf24bb8740679d335
- iPhone: ostatnia publikacja WEB 2 z 25.09; Site ma wersję 3.
- Zmiany godzin, wspólnego scrolla i liczników profili z 26.09 NIE zostały
  jeszcze wyeksportowane do nowej APK ani PWA. Użytkownik polecił na razie
  pracować lokalnie w Godocie i odłożył temat kodów.

git pull aktualizuje źródła projektu. Nie aktualizuje zainstalowanej APK,
strony iPhone ani telefonu kolegi. To trzy oddzielne czynności publikacyjne.

4. AKTUALNE ZASADY DZIAŁANIA APLIKACJI

- Pionowy kalendarz; siedem dni w rzędzie; widoczne oznaczenie dzisiaj.
- Brak zmiany miesiąca gestem prawo/lewo. Nawigacja wyłącznie przyciskami.
- Jeden pionowy scroll łączy kalendarz i dolne narzędzia, bez widocznych pasków.
- main_scroll i calendar_scroll wskazują ten sam ScrollContainer.
  Tryb „tylko kalendarz” ukrywa options_root, a nie wspólny scroll.
- Godziny na kafelkach mają H:MM. W zapisie są sekundy, bez zaokrąglania.
- Zakończona zmiana jest przypisana do dnia rozpoczęcia; nie dzieli się
  automatycznie o północy między dwa dni lub miesiące.
- Ręczny wpis dotyczy daty wybranej w momencie otwarcia okna.
- Plan 15 godzin jest planem użytkownika, nie kalkulatorem zgodności
  z przepisami czasu jazdy/pracy ani zamiennikiem tachografu.
- Profile mają osobne grafiki, notatki i godziny. Wybranie slotu na liście
  samo nie wczytuje go. Aktywny profil zapisuje edycje automatycznie.
- Jest jeden bieżący licznik pracy i pauzy dla sesji. Oglądanie profilu kolegi
  nie zatrzymuje licznika, nie zmienia długości pauzy i nie wskrzesza jego
  starych liczników. Nie są to niezależne jednoczesne stopery dla każdego profilu.
- work_profile_index zapamiętuje profil rozpoczęcia pracy. Zakończenie zmiany
  podczas oglądania innego profilu dopisuje czas do profilu źródłowego.
- Przed opuszczeniem kalendarza nieprzypisanego do profilu jego stan trafia
  automatycznie do wolnego slotu; komunikat podaje numer.
- Zapis pod innym profilem nie przenosi właściciela trwającej zmiany.
  Usunięcie profilu z trwającą pracą jest blokowane; usuwanie wcześniejszego
  slotu poprawia numer właściciela. Samo przełączanie jest dozwolone.
- Liczniki korzystają z zapisanych znaczników czasu. Po zamknięciu aplikacji
  upływ można odtworzyć przy uruchomieniu; nie wdrożono osobnej usługi Android
  ani alarmów/powiadomień działających w tle.

5. PLIKI I ARCHITEKTURA

project.godot — konfiguracja i uruchomienie sceny głównej.
scenes/main.tscn — ładuje res://scripts/main.gd.
scripts/main.gd — interfejs budowany w kodzie, profile, liczniki, zapis i gesty.
scripts/schedule_calculator.gd — daty, stany dni i cykle grafiku.
scripts/background_art.gd — tło aplikacji.
scripts/beta_access.gd — ekran aktywacji, odświeżanie dostępu i aktualizacje.
scripts/beta_lease.gd — walidacja podpisanej zgody offline.
scripts/web_beta_tools.gd — funkcje kopii i integracja webowa.
beta/release.json — publiczna wersja, package ID i URL usługi.
beta/lease-public.pem — wyłącznie publiczny klucz licencji.
beta/android-signing-cert.sha256 — przypięty odcisk certyfikatu APK.
export_presets.cfg — Android Beta i iPhone Web Beta, bez haseł podpisu.
tools/build_driver_beta.py — budowa/weryfikacja APK i pliku .release.json.
tools/build_driver_web.py — eksport PWA i przygotowanie plików dla Site.
web/shell.html, mobile-ui.js, service-worker.js — powłoka webowa i aktualizacje.
tests/ — testy Godota oraz service workera; wykluczone z eksportów.

Ważne funkcje main.gd: _on_load_profile_pressed, _on_save_profile_pressed,
_sync_active_profile, _profile_snapshot, _calendar_state_snapshot,
_restore_calendar_state, _confirm_end_work, _save_worked_seconds_for_day,
_save_settings_to_disk, _load_settings_from_disk i _lock_horizontal_scroll.

6. DANE I AKTUALIZACJE BEZ KASOWANIA

- Nazwa projektu pozostaje „Kalendarz Kierowcy”.
- Android package ID: pl.elklient.kalendarzkierowcy.beta.
- Alias podpisu APK: driver-beta. Kolejne APK muszą używać tego samego klucza.
- Kalendarz: user://driver_calendar.cfg; poprzedni dobry zapis: .bak.
- Zapis powstaje przez sprawdzony .tmp i podmianę pliku. Błąd jest widoczny;
  nieczytelne pliki nie są automatycznie nadpisywane pustym kalendarzem.
- Aktywacja: osobny user://driver_beta_access.cfg.
- Format danych: 1, obsługiwany też starszy 0. Nieznane pola są zachowywane.
  Nowszy nieobsługiwany format blokuje zapis starszą aplikacją.
- Właściciel bieżącej zmiany jest w sekcji work/profile_index; przy odczycie
  starego zapisu bez tego pola domyślnie używa się aktywnego profilu.
- APK aktualizować instalacją na istniejącą aplikację. Nie odinstalowywać
  ani nie czyścić danych jako sposobu naprawy aktualizacji.
- Projekt uruchamiany w edytorze Godot i samodzielna APK mają osobne dane;
  pierwsza instalacja APK nie przejmuje automatycznie zapisu z edytora.
- PWA zapisuje dane w IndexedDB. Brak synchronizacji godzin Android–iPhone
  i brak kopii kalendarza na serwerze kodów.
- Web: eksport/import .dkcal, także import pliku ze starszym DKCAL1:base64.
  Import wymaga aktywnego dostępu i potwierdzenia zastąpienia danych.
- Android beta: kopia tekstowa DKCAL1:, bez samodzielnego przycisku importu.
- Wygaśnięcie dostępu nie kasuje danych. Lokalna .bak nie chroni przed
  utratą telefonu lub wyczyszczeniem danych przeglądarki.

7. KODY, POZWOLENIA TESTOWE I PANEL

- W /admin właściciel loguje się tym samym kontem ChatGPT, które utworzyło Site.
- Generowanie 1–30 kodów naraz; każdy tester dostaje własny kod i link.
- Pełne kody pokazują się tylko przy tworzeniu. Zachować je prywatnie;
  serwer przechowuje skróty, nie listę kodów do ponownego odczytu.
- Standardowy dostęp trwa 30 dni od pierwszej aktywacji, nie od pobrania APK.
- Kod jest związany z jedną instalacją. Aktualizacja nie odnawia 30 dni.
- Nieużyty kod działa na Androidzie albo iPhonie. Użyty na Androidzie nie
  aktywuje równolegle iPhone’a: potrzebny drugi kod lub przeniesienie przypisania.
- Panel pozwala przedłużyć, cofnąć/przywrócić dostęp, odpiąć urządzenie
  i wstrzymać całą betę. Przeniesienie nie resetuje daty końca testów.
- Pozwolenie offline jest podpisane RSA/SHA-256, ważne maksymalnie 72 godziny
  i nigdy poza termin testów. Klient sprawdza podpis, instalację i nonce.
- Dostęp jest sprawdzany przy uruchomieniu/wznowieniu oraz co 12 godzin
  działania; po błędzie sieci ponawiana jest próba po około 5 minutach.
- Cofnięcie dostępu działa przy kolejnym sprawdzeniu albo wygaśnięciu zgody
  offline. Nie obiecywać natychmiastowej blokady telefonu bez internetu
  ani odporności na zmodyfikowaną APK/root.
- Dane usługi: skróty kodów/tokenów, ID instalacji, terminy i blokady,
  ostatni kontakt, metadane wydań oraz krótkotrwałe dane limitowania żądań.
  Nie wysyłamy godzin, notatek i profili do tej usługi.
- Nie dodano czatu, wysyłki maili, analityki ani kanału feedbacku.

8. ZGODY WŁAŚCICIELA I GRANICE DZIAŁANIA AGENTA

W tej rozmowie użytkownik wyraźnie upoważnił do:
- pobrania aktualnego kodu i pracy według dokumentacji brancha;
- audytu, potrzebnych poprawek, testów i korzystania z odpowiednich narzędzi;
- robienia małych commitów i publikowania na driver-shift-calendar;
- zbudowania i udostępnienia bety Android z kodami na 30 dni;
- dodania wersji do testowania na iPhonie i publikacji jej linku;
- utrzymywania instrukcji i pełnego raportu w repo dla kolejnych agentów.

Nie trzeba pytać ponownie o zgodę na zwykłą łatkę, test i commit/push w tym
zakresie. Późniejsze polecenie użytkownika zawęziło bieżące prace do lokalnej
wersji Godot: nie traktować każdego commita jako polecenia wydania nowej APK/PWA.
„Tylko mała łatka” oznacza ograniczenie zakresu, nie przebudowę aplikacji.

Nie ma zgody na kasowanie danych, wymianę kluczy, wysyłanie wiadomości
testerom, podłączanie płatności lub kupowanie usług bez osobnego polecenia.
Zgoda użytkownika nie zastępuje kontroli dostępu narzędzi ani uprawnień kont.
Właściciel określił, że pracuje obecnie jeden agent. Gdy dołączą kolejni,
podzielić konkretne funkcje/pliki i sprawdzać remote przed publikacją.

Uprawnienia techniczne już użyte/przygotowane:
- GitHub: odczyt i zapis zmian wskazanego brancha, także przez API.
- Sites: utworzenie i publiczna publikacja strony testowej, serwera, D1 i R2.
- Panel /admin: autoryzacja właściciela po stronie serwera, nie tylko ukryte UI.
- Token publikacji ma zakres przesyłania APK/silnika webowego, nie kodów.
- Preset Android włącza internet i odczyt stanu sieci; nie dodano uprawnień
  lokalizacji, kontaktów, mikrofonu ani kamery. Instalację APK potwierdza Android;
  instalowanie z danego źródła może wymagać zgody użytkownika w ustawieniach.
- Licencja beta nie jest uprawnieniem systemowym telefonu ani kontem w sklepie.
- Nie utworzono publikacji Google Play/App Store ani kont Apple Developer.

Prywatne klucze przekazano właścicielowi w archiwum:
Kalendarz-Kierowcy-Klucze-Wlasciciela.zip.
Zawiera klucz APK, hasło, kopię klucza licencji i uprawnienie publikacji.
Nie dodawać tego archiwum do repo, raportu, aplikacji ani materiałów testerów.
Jeśli nie ma go w nowym środowisku, uzyskać oryginał od właściciela;
nie tworzyć zastępczego klucza APK i nie udawać zachowania podpisu.

9. CODZIENNY WORKFLOW AGENTA

1) Przeczytaj ten raport, STRESZCZENIE i dokumentację dotyczącą danego zadania.
2) Potwierdź repo, branch, stan plików i najnowsze commity:

git status --short --branch
git fetch origin driver-shift-calendar
git log --oneline -8 origin/driver-shift-calendar

3) Zachowaj zastane zmiany. Jeśli checkout jest czysty, aktualizuj fast-forward.
   Przy rozjechanej historii najpierw ją porównaj; można zacząć świeżą gałąź
   roboczą od origin/driver-shift-calendar. Nie używaj git reset --hard.
4) Szukaj przez rg; edytuj mały zakres przez apply_patch.
5) Sprawdź git diff --check i testy odpowiadające ryzyku poprawki.
6) Dodaj tylko właściwe pliki i zrób mały commit.
7) Opublikuj na driver-shift-calendar, bez force, po sprawdzeniu remote.
8) Uzupełnij STRESZCZENIE przy zmianie działania, workflow lub stanu wydania.
9) Podaj użytkownikowi wynik, ograniczenia testów, SHA i blok do Termuxa.

Zwykła publikacja: git push origin HEAD:driver-shift-calendar.
Gdy brak uwierzytelnienia Git, dotychczas skutecznie stosowano GitHub API:
- create_tree na bazie aktualnego drzewa z pełną treścią tylko zmienionych plików;
- porównanie SHA drzewa z lokalnym, przetestowanym commitem;
- create_commit z aktualnym rodzicem;
- update_ref dla driver-shift-calendar z force:false;
- fetch i uporządkowanie lokalnej historii przez rebase po kontroli stanu.
API może nadać inne SHA commita niż lokalne, mimo identycznego drzewa.
Podawać SHA opublikowane. Przy cudzych nowych commitach włączyć je i ponownie
sprawdzić zakres, nie nadpisywać brancha. Nie drukować tokenów w logach.

10. TERMUX / TELEFON WŁAŚCICIELA

Właściwy projekt:
/storage/emulated/0/Godot/DriverShiftCalendar/project.godot

Zamknąć uruchomioną aplikację i edytor Godot, następnie wkleić:

cd /storage/emulated/0/Godot/DriverShiftCalendar &&
git pull --ff-only origin driver-shift-calendar &&
git --no-pager log -1 --oneline

Otworzyć dokładnie powyższy project.godot i uruchomić ▶.
Na zrzucie użytkownika edytor ma Godot 4.7.2; testy agenta wykonano w 4.4.1.

Jeśli Git zgłasza lokalne zmiany project.godot i przerywa merge:

cd /storage/emulated/0/Godot/DriverShiftCalendar &&
git stash push -m "Kopia ustawien Godota przed aktualizacja" -- project.godot &&
git pull --ff-only origin driver-shift-calendar &&
git --no-pager log -1 --oneline

To zachowuje lokalną zmianę tego pliku w stashu, bez kasowania danych aplikacji.
Nie wykonywać automatycznie stash pop: stary plik może przywrócić konflikt.
Gdy komunikat dotyczy innych plików, sprawdzić git status/diff zamiast
odkładać lub kasować wszystkie zmiany w ciemno.

Diagnostyka „nadal stary ekran”:
- Przeczytać wynik pull; „Aborting” oznacza, że aktualizacja nie weszła.
- Porównać SHA i sprawdzić folder otwierany w Godocie.
- Sprawdzić źródło na telefonie:
  grep -nE 'main_scroll = calendar_scroll|SCROLL_MODE_SHOW_NEVER|work_profile_index' scripts/main.gd
- Zamknąć i ponownie otworzyć edytor oraz uruchomiony projekt.
- Jeżeli uruchamiana jest samodzielna APK, potrzebne jest nowe wydanie APK.

11. PUBLIKOWANIE AKTUALIZACJI APK I IPHONE

Android:
- Przeczytać docs/DRIVER_CALENDAR_BETA.md.
- Godot 4.4.1, szablony eksportu Android, Java 17 i Android SDK.
- Użyć presetu Android Beta z feature driver_beta oraz oryginalnego klucza.
- Numer wersji musi być większy niż /api/releases/latest; obecnie następny
  to co najmniej 2, ale sprawdzić to ponownie przed przyszłą publikacją.
- Hasło i ścieżkę klucza przekazywać przez zmienne środowiskowe według
  instrukcji BETA; nie wpisywać sekretów w komendy publikowane w czacie/repo.
- Przykład po ustawieniu narzędzi i klucza:
  python tools/build_driver_beta.py --version-code 2 --version-name 0.1.0-beta.2
- Skrypt sprawdza podpis, package ID, wersję, feature aktywacji i wykluczenie
  innych aplikacji/testów. Tworzy APK oraz odpowiadający .release.json.
- Oba pliki opublikować w sekcji aktualizacji /admin. Serwer weryfikuje hash.
- Zmiany numerów wersji commitować na driver-shift-calendar.
- Tester: „Wersja beta i aktualizacje” → „Sprawdź aktualizację”; instalacja
  na istniejącą aplikację, z potwierdzeniem Androida.

iPhone:
- Przeczytać docs/DRIVER_CALENDAR_IPHONE.md.
- Godot 4.4.1 i web_nothreads_release.zip; preset iPhone Web Beta,
  Compatibility/WebGL2, jeden wątek.
- Najpierw otworzyć istniejący Site według bieżącej instrukcji sites-hosting.
- Przykład eksportu:
  python tools/build_driver_web.py --godot /sciezka/do/godot --site /workspace/sites/kalendarz-kierowcy-beta
- Pliki strony trafiają do public/iphone/, silnik .wasm.gz do istniejącego R2.
- Silnik przesyłać przez /api/admin/web-assets/<sha256> z uprawnieniem
  publikacji; nie usuwać starszych silników potrzebnych starym instalacjom.
- Publikować nową wersję Site jego workflow; osobno commitować źródła Godot.
- Zachować URL, manifest id, nazwy zapisów i klucze. Aktualizacja PWA pobiera
  pełny cache i wchodzi po zamknięciu wszystkich okien oraz ponownym otwarciu.
- Nie czyścić danych Safari jako sposobu aktualizacji.

12. ISTNIEJĄCY SITE — IDENTYFIKATORY DLA AGENTA

Site project_id: appgprj_6ab676fcded08191858a99dfb0fc968f
Znany checkout: /workspace/sites/kalendarz-kierowcy-beta
Adres produkcji: https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site
D1 binding: DB; R2 binding: BUCKET.

Ostatnia potwierdzona publikacja: Site wersja 3, status succeeded.
Źródła Site: 46ef9692539039d71958ebcfe28f95ef581d98e8
Version ID: appgprj_6ab676fcded08191858a99dfb0fc968f~appgver_abe1514cfb2c8191808ffea59aeddc11
Deployment ID: appgdep_6ab68ea3c8e88191b4917729cefd2c68

To osobne repozytorium źródłowe zarządzane przez Sites. Nie tworzyć drugiego
serwisu. W nowej sesji użyć get_site i aktualnego workflow otwarcia istniejącego
projektu; sam lokalny katalog może już nie istnieć. Nie zakładać dostępności
starych plików /tmp, archiwów eksportu ani krótkotrwałych poświadczeń.
Protokół aktywacji: POST /api/beta/activate i POST /api/beta/refresh.
Publiczny klucz w Godocie musi odpowiadać prywatnemu kluczowi tej usługi.

13. TESTY I UCZCIWE OGRANICZENIA

Ostatnio wykonane wyniki, nie należy sumować ich jako jednego przebiegu:
- 26.09, kod 95defa7: tests/release_audit.gd — 66 PASS, 0 FAIL.
  W tym 18 nowych kontroli przełączania profili, zapis/odczyt liczników,
  właściwy profil godzin, stare dane, nieprzywracanie zakończonych liczników.
- 26.09, wcześniejsza łatka scrolla: tests/calendar_mobile_audit.gd — 19 PASS.
  Geometria napisów H:MM, wspólny scroll, syntetyczne gesty, blokada pozioma.
- 25.09: beta_upgrade_audit.gd — 23 PASS; web_backup_audit.gd — 8 PASS.
- 25.09: web_worker_audit.mjs — 3 PASS; usługa — 12 testów PASS po dodaniu web.
- 25.09: izolowany web runtime — 8 kontroli PASS dotyczących IndexedDB,
  podpisu RSA i zachowania zapisu po przeładowaniu; TypeScript także przechodził.
- Zbudowano i sprawdzono podpis/metadane pierwszej APK oraz eksport webowy.

Przykład ponownego audytu na Linux z Godot w PATH:

XDG_DATA_HOME=/tmp/driver-calendar-audit-regression godot --headless --path . --script res://tests/release_audit.gd
XDG_DATA_HOME=/tmp/driver-calendar-audit-mobile godot --headless --path . --script res://tests/calendar_mobile_audit.gd

Testy muszą mieć własny XDG_DATA_HOME zaczynający się /tmp/driver-calendar-audit-.
Usuwają/nadpisują dane testowe; nie uruchamiać ich na zapisie użytkownika.
Ostrzeżenia zapisu i błąd otwarcia .bak.tmp w audycie są częścią celowych
testów awarii. O wyniku decyduje RESULT i kod wyjścia.

Sprawdzona lokalna binarka w tej sesji:
/tmp/driver-calendar-tools/Godot_v4.4.1-stable_linux.x86_64
Nie zakładać, że przetrwa do następnej sesji.

Ograniczenia:
- Agent nie wykonał testu fizycznego Androida/iPhone’a ani faktycznego
  zabicia procesu przez Androida. Odczyt pliku po wyzerowaniu pamięci nie
  jest równoważny testowi systemu mobilnego.
- Xvfb nie uruchomił renderowanego UI z powodu ograniczeń gniazd środowiska.
- Testowa przeglądarka nie miała WebGL2; podgląd HTTP nie zastępował Safari
  z HTTPS. Nie deklarować pełnej oceny grafiki/dotyku iOS.
- Testy formularza WEB 2 sprawdzały schowek i różne rozmiary w Chrome,
  nie na rzeczywistym Safari. Poprawna aktywacja kodu na iPhonie pozostaje
  do potwierdzenia przez kolegę.
- Użytkownik potwierdził działanie godzin i wspólnego przewijania na swoim
  Androidzie po rozwiązaniu konfliktu aktualizacji.

14. CO DALEJ I JAK ROZPOCZĄĆ KOLEJNY CZAT

Najbliższy krok: wynik użytkownika po łatce 95defa7 — przełączyć profil
podczas pauzy, wrócić, zamknąć/otworzyć aplikację i sprawdzić ciągłość czasu.
Sprawdzić zakończenie pracy przy oglądanym innym profilu i właściwy zapis godzin.

Przed szerszym testem z kierowcami: dopiero po poleceniu wrócić do wydań APK/PWA,
przenieść zaakceptowane poprawki do tych wydań i sprawdzić na jednym telefonie
aktywację, aktualizację na istniejącej instalacji i zachowanie danych.
Do dalszego dopracowania: import kopii Android, testy uśpienia i zmiany czasu,
pełna kontrola realnych urządzeń. Feedback/chat, płatności, sklepy i natywne
iOS są osobnymi zadaniami; nie dodawać ich samodzielnie do małej łatki.

Prompt startowy dla następnego agenta:
„Pracujemy nad Kalendarzem Kierowcy, osobną aplikacją Godot w root repo
ElKlient/IDOL-Genesis, branch driver-shift-calendar. Najpierw przeczytaj
docs/DRIVER_CALENDAR_RAPORT_PRZEKAZANIA.md oraz
docs/DRIVER_CALENDAR_STRESZCZENIE.md. Masz zgodę na małe poprawki, testy,
commit i publikację na tym branchu. Nie ruszaj gry ani apps/wspolny-kalendarz.
Chroń zapisane dane i zachowaj blokadę poziomego swipe. Pauza/praca ma trwać
przy zmianie profilu, godziny trafiają do profilu rozpoczęcia pracy.
Na razie pracujemy lokalnie w Godocie; APK/PWA wymagają osobnej publikacji.
Sprawdź remote, wykonaj zleconą łatkę, podaj opublikowane SHA i komendę Termuxa.
Na hasło STRESZCZENIE aktualizuj instrukcje w repo i daj tekst do skopiowania.”
