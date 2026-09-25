# STRESZCZENIE - Kalendarz Kierowcy

To jest stala notatka startowa dla kolejnego agenta pracujacego nad aplikacja Godot **Kalendarz Kierowcy**.

Jesli uzytkownik napisze w dowolnym czacie: **STRESZCZENIE**, agent ma dac aktualne streszczenie dla nastepnego agenta: stan aplikacji, branch, workflow, ostatnie zmiany, zasady wspolpracy i najwazniejsze priorytety.

## Repo i branch

- Repo: `ElKlient/IDOL-Genesis`
- Branch roboczy aplikacji: `driver-shift-calendar`
- Lokalny checkout moze miec inna nazwe brancha, ale ma publikowac na `driver-shift-calendar`.
- To jest osobna aplikacja kalendarza kierowcy, nie gra IDOL Genesis.
- Glowny plik UI: `scripts/main.gd`
- Pomocnicze pliki:
  - `scripts/schedule_calculator.gd`
  - `scripts/background_art.gd`

## Uprawnienia od uzytkownika

Uzytkownik dal zgode na robienie zmian w aplikacji, commitowanie i publikowanie na GitHub branch `driver-shift-calendar`.

Mimo tej zgody agent ma nadal dzialac bezpiecznie:

- robic male, celowane latki,
- nie przebudowywac aplikacji od zera,
- nie zmieniac grafiki ani ukladu bez prosby,
- nie kasowac cudzych zmian,
- nie uzywac destrukcyjnych komend typu `git reset --hard`,
- jesli user mowi "tylko to", zmieniac tylko wskazana rzecz.

## Standardowy workflow

Na poczatku kazdego zadania:

```bash
git status --short --branch
git log --oneline -8
```

Potem szukac kodu przez `rg`, np.:

```bash
rg -n "calendar_only|scroll|horizontal|main_scroll|navigation|day_tools|reset|undo|profile" scripts/main.gd
```

Edycja:

- reczne zmiany robic przez `apply_patch`,
- nie pisac plikow przez `cat > file`,
- po zmianie sprawdzic:

```bash
git diff --check
```

Potem:

```bash
git add <zmienione_pliki>
git commit -m "Krotki opis latki"
```

Publikacja:

- docelowo na branch `driver-shift-calendar`,
- zwykly `git push origin HEAD:driver-shift-calendar` moze byc blokowany przez sandbox,
- jesli push jest blokowany, publikowac waski zakres przez GitHub API, zachowujac male commity i tylko zmienione pliki. Porownac SHA drzewa z przetestowanym lokalnym commitem; aktualizowac ref bez force.

Uzytkownik testuje na Androidzie:

```bash
cd /storage/emulated/0/Godot/DriverShiftCalendar &&
git pull --ff-only origin driver-shift-calendar &&
git log -1 --oneline
```

## Jak ma pracowac dwoch agentow naraz

Agenci moga pracowac rownolegle, ale musza pilnowac zakresu.

Zasady:

- Agent A bierze jeden element UI/logiki i konczy go do commita.
- Agent B bierze inny element, najlepiej inne funkcje lub inny fragment pliku.
- Przed praca kazdy agent sprawdza status i ostatnie commity.
- Jesli obaj dotykaja `scripts/main.gd`, trzeba bardzo jasno trzymac zakres zmian.
- Nie robic szerokich refaktorow, bo `scripts/main.gd` jest duzy i latwo o konflikt.
- Po publikacji agent ma napisac uzytkownikowi commit SHA i krotko co zmienil.
- Drugi agent powinien zaczynac od aktualnego branch `driver-shift-calendar`, nie od starego lokalnego stanu.

Przy konflikcie:

- nie nadpisywac na sile,
- sprawdzic remote i diff,
- poprosic uzytkownika lub ograniczyc sie do swojej latki.

## Aktualny stan aplikacji

25.09.2026: dodano drugi eksport tego samego projektu na iPhone przez Safari/PWA.
Instrukcja i ograniczenia: `docs/DRIVER_CALENDAR_IPHONE.md`. To wersja webowa,
nie IPA/TestFlight. Ten sam system kodów 30 dni; kopia do pliku i import;
aktualizacje webowe zachowują IndexedDB i wchodzą po zamknięciu okien.
Nie twierdzić, że sprawdzono fizyczny iPhone — testuje kolega użytkownika.

Poprawka WEB 2: pole aktywacji HTML obsługuje systemowe wklejanie; canvas skaluje
się do visualViewport i zachowuje stałą szerokość UI przy otwarciu klawiatury.
Źródła: `web/mobile-ui.js`, `web/shell.html`, `scripts/web_beta_tools.gd`.
Nie wracać do samego LineEdit Godota dla kodu na iPhonie. Aktualizację PWA
odbiera się po pobraniu i zamknięciu wszystkich okien, bez usuwania danych.

Aktualizacja 25.09.2026: przygotowano bete Android z kodami na 30 dni od
pierwszej aktywacji, podpisanymi zgodami offline do 72h, panelem wlasciciela
i publikowaniem aktualizacji APK. Najpierw przeczytac `docs/DRIVER_CALENDAR_BETA.md`.
Nie zmieniac package ID, klucza podpisu ani sciezek danych przy aktualizacji.
Zwykle uruchomienie zrodel w Godot nadal sluzy pracy wlasciciela; preset
`Android Beta` wlacza aktywacje. Feedback/czat pozostaja poza zakresem.

Aplikacja to pionowy mobilny kalendarz kierowcy:

- 7 kafelkow dni w rzedzie,
- ciemne tlo z ciezarowka,
- na naczepie napis `Dasko` i `Always too late`,
- Praca: czerwony/rozowy,
- Dom: zielony,
- 24h/45h: zloty,
- Urlop: niebieskawy,
- dzisiejszy dzien zawsze ma miec ramke/podswietlenie,
- kalendarz ma wygladac jak kafelki w telefonie, nie tabela.

Najwazniejsza zasada nawigacji:

- kalendarz nie moze zmieniac miesiaca ani przesuwac sie prawo-lewo od palca,
- zmiana miesiaca/roku tylko guzikami,
- widoki wielu miesiecy oraz pojedynczy miesiac niemieszczacy sie na ekranie moga przewijac sie pionowo.

## Obecne glowne elementy UI

- Resetuj
- Cofnij
- Cofnij reset
- Wroc do aktualnej daty
- Ustawienia
- Profile
- Nawigacja
- Dzien pracy i pauza
- Pokaz tylko kalendarz
- Pokaz opcje

## Najwazniejsze funkcje w `scripts/main.gd`

- `_build_ui()`
- `_rebuild_calendar()`
- `_make_month_section()`
- `_make_day_cell()`
- `_open_day_actions()`
- `_apply_main_view_mode()`
- `_enter_calendar_only_mode()`
- `_exit_calendar_only_mode()`
- `_save_settings_to_disk()`
- `_load_settings_from_disk()`
- `_calendar_state_snapshot()`
- `_restore_calendar_state()`
- `_reset_calendar_settings()`
- `_update_main_scroll_touch_mode()`
- `_style_main_scrollbar()`
- `_lock_horizontal_scroll_deferred()`

## Co zostalo zrobione

Tryby i UI:

- Dodano tryb `Pokaz tylko kalendarz`.
- W tym trybie zostaje kalendarz, `Wroc do aktualnej daty` i guzik `Pokaz opcje`.
- Stan trybu zapisuje sie w `ConfigFile`.
- Nawigacja i panel pracy/pauzy sa chowane.
- Usunieto gesty zmiany miesiaca palcem.
- Zablokowano poziomy scroll.
- Dodano/utrzymano panel `Dzien pracy i pauza`.

Reset i cofanie:

- Dodano reset z opcja `Cofnij reset`.
- Dodano zwykle `Cofnij`.
- Dodano `Wroc do aktualnej daty`.

Podpowiedzi pustego grafiku:

- `Uzupelnij swoje pierwsze dwa cykle pracy.`
- `Kliknij swoj pierwszy dzien i wyznacz swoj cykl.`
- `Zacznij od pierwszego dnia cyklu swojej pracy i wypisz caly cykl wraz z dniami wolnymi. Wtedy kliknij Zastosuj.`

Profile:

- Panel profili zostal poszerzony i wycentrowany.
- Profile mozna dodawac.
- Zapisany profil mozna wczytac.
- Pusty profil mozna wczytac jako czysty kalendarz.
- Dodatkowe profile mozna usuwac jako sloty.
- Domyslne puste profile 1-3 zostaja jako bezpieczne miejsca.
- Aktywny profil zapisuje zmiany automatycznie; zaznaczenie slotu na liscie samo nie zmienia aktywnego profilu.
- Profil przechowuje widok, cykle, reczne dni, notatki i godziny, bez aktywnych licznikow pracy/pauzy.
- Wczytywanie profilu podczas pracy lub trwajacej pauzy jest blokowane. Stare profile nie przywracaja zakonczonych licznikow.
- Biezacy stan aplikacji osobno zachowuje aktywny licznik po ponownym uruchomieniu.

Godziny pracy i pauzy:

- `Rozpocznij prace` uruchamia licznik z planem 15h. To plan, nie kalkulator zgodnosci z przepisami.
- Panel pokazuje pozostaly czas planu i prognoze wybranej dlugosci pauzy.
- `Zakoncz prace` pyta o potwierdzenie, zapisuje godziny do dnia rozpoczecia i od razu rozpoczyna wybrana pauze.
- Start aktywnej pracy lub pauzy nie zeruje licznika. Rozpoczecie pauzy podczas pracy wymaga potwierdzenia zakonczenia zmiany.
- Data rozpoczecia jest zapamietywana przy starcie; godziny nie sa dzielone o polnocy. Podsumowanie miesiaca opisuje te regule.
- Godziny mozna dodawac recznie w menu dnia.
- Godziny pokazuja sie na kafelkach dni.
- Jest suma godzin miesiaca.
- Jest pokazywanie/ukrywanie godzin bez kasowania danych.
- Jest kasowanie czasu pauzy.

Menu dnia:

- Po kliknieciu kafelka otwiera sie okno dnia.
- Zmiany maja dotyczyc tylko wybranego dnia.
- Dodawanie godzin recznie ma zapisywac do konkretnego `YYYY-MM-DD`, bez mieszania z innymi kafelkami.
- Menu dnia miesci sie w oknie i przewija pionowo; zamkniecie pozostaje dostepne.

Zapis danych:

- `driver_calendar.cfg` jest podmieniany przez zweryfikowany plik `.tmp`; `.bak` zachowuje poprzedni poprawny zapis.
- Nieudany zapis pokazuje komunikat zamiast pozornego sukcesu. Nieczytelny plik glowny jest odzyskiwany z kopii.
- Gdy oba pliki sa nieczytelne, aplikacja blokuje zapis pustego stanu. Eksport/import poza aplikacje pozostaje do zrobienia.
- W wersji webowej dostępny jest eksport/import pliku `.dkcal`; Android ma nadal kopię tekstową `DKCAL1:`.

## Aktualizacja po audycie 25.09.2026

Male commity: `Isolate active profiles and protect running timers`,
`Preserve calendar saves with atomic replacement and recovery`,
`Use selected rest duration and retain shift start dates`,
`Fix calendar layout and release-only touch actions`.
Publikacja przez API moze nadac inne SHA niz lokalne; aktualny stan sprawdzac w `git log`.
Wynik: **48 PASS, 0 FAIL** w Godot 4.4.1 headless. Szczegoly w raporcie audytu.

## Historyczne wazne commity

Lokalnie:

- `25ecf8c Improve calendar profile management`
- `b1484ee Isolate calendar day tile edits`
- `7bd1c11 Keep day edits on selected tile`
- `215f53b Improve calendar tile taps and hours`
- `ccef15f Move month hours clear button`

Na GitHub branch `driver-shift-calendar` po publikacji profili:

- `d2ef7cab Improve calendar profile management`

## Aktualne uwagi techniczne

- Audyt 25.09.2026: `docs/DRIVER_CALENDAR_AUDYT_2026-09-25.md`; bazowy kod `c5ccea4` mial 15 PASS, 9 FAIL. Po poprawkach `tests/release_audit.gd` wykonuje 48 kontroli: 48 PASS, 0 FAIL.
- Lokalny branch moze byc `ahead`, bo czesc poprawek byla publikowana przez GitHub API, a nie klasyczny `git push`.
- Nie zakladac, ze lokalny `origin/driver-shift-calendar` jest swiezy.
- Przed publikacja najlepiej porownac remote przez GitHub albo zrobic ostrozny pull/fetch, jesli srodowisko pozwala.
- Swiezy oficjalny Godot 4.4.1 dziala headless; poprzednia znaleziona binarka byla niekompletna. Nie zakladac niedostepnosci silnika.
- Testy uruchamiac z izolowanym `XDG_DATA_HOME=/tmp/driver-calendar-audit-*`; nadpisuja swoje pliki testowe.
- Testy obejmuja logike, zapis i awarie, geometrie oraz syntetyczne zdarzenia. Fizyczny Android i wizualna ocena pozostaja po stronie uzytkownika; nie twierdzic, ze zostaly sprawdzone.

## Jesli user zglosi, ze cos nadal przesuwa sie prawo-lewo

Sprawdzic:

- `main_scroll`
- `calendar_scroll`
- `CenterContainer`
- `root.custom_minimum_size = Vector2(PORTRAIT_WIDTH, 0)`
- horizontal scrollbar
- `scroll_horizontal`
- `_lock_horizontal_scroll_deferred()`
- `_consume_horizontal_drag()`

Nie przywracac gestow swipe. Nawigacja ma byc tylko guzikami.

## Kolejne priorytety

- Weryfikacja aktualizacji z istniejacymi danymi i obslugi dotykiem na Androidzie.
- Eksport/import kopii poza aplikacje; lokalna `.bak` nie chroni przed utrata telefonu.
- Prognozy przez zmiane czasu i wznowienie aplikacji po uspieniu.
- Podpisane wydanie Android i test zamkniety przed platna premiera.
- Nakladanie przyciskow profili i dzisiaj naprawiono; nie otwierac tego ponownie bez nowego zgloszenia.

## Gotowy prompt dla drugiego agenta

Skopiuj to do nowego agenta:

```text
Pracujemy nad aplikacja Godot "Kalendarz Kierowcy".

Repo: ElKlient/IDOL-Genesis
Branch: driver-shift-calendar
Glowny plik: scripts/main.gd
Pomocnicze: scripts/schedule_calculator.gd, scripts/background_art.gd

To jest osobna aplikacja kalendarza kierowcy, nie gra IDOL Genesis.
UI jest prawie w calosci w GDScript w scripts/main.gd.
Nie przebudowuj od zera. Rob male, celowane latki.

Masz zgode uzytkownika na zmiany, commity i publikacje na branch driver-shift-calendar.
Nadal nie uzywaj destrukcyjnych komend i nie nadpisuj cudzych zmian.

Najpierw sprawdz:
git status --short --branch
git log --oneline -8

Szukaj kodu przez rg.
Edytuj przez apply_patch.
Po zmianie:
git diff --check
git add ...
git commit -m "..."
Publikuj na driver-shift-calendar.

Jesli git push jest blokowany, publikuj waski zakres przez GitHub API w malych commitach, bez force.
Uzytkownik testuje Androidem:
cd /storage/emulated/0/Godot/DriverShiftCalendar &&
git pull --ff-only origin driver-shift-calendar &&
git log -1 --oneline

Najwazniejsze: kalendarz nie moze przesuwac sie palcem prawo-lewo i nie moze zmieniac miesiaca swipe. Tylko guziki.

Aktualny stan:
- profile zostaly poszerzone i wycentrowane,
- mozna dodawac profile,
- zapisany profil mozna wczytac,
- pusty profil mozna wczytac jako czysty kalendarz,
- dodatkowe profile mozna usuwac,
- godziny pracy zapisuje sie do konkretnych dni,
- godziny widac na kafelkach i sumuja sie w miesiacu,
- aktywny profil zapisuje zmiany automatycznie, a stare liczniki nie wracaja z profili,
- potwierdzone zakonczenie pracy rozpoczyna wybrana pauze,
- zapis ma kopie do odzyskiwania i widoczna obsluge bledow,
- Godot 4.4.1 headless: 48 PASS, 0 FAIL; fizyczny Android testuje user.

Jesli pracujesz rownolegle z drugim agentem, bierz tylko swoj element, nie refaktoruj szeroko scripts/main.gd i po publikacji podaj commit SHA.
```
