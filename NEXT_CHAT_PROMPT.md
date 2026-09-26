# Kalendarz Kierowcy - prompt dla nastepnego czatu

Najpierw przeczytaj `docs/DRIVER_CALENDAR_RAPORT_PRZEKAZANIA.md` (pełna historia,
zgody, linki i workflow) oraz `docs/DRIVER_CALENDAR_STRESZCZENIE.md` (bieżący stan).
Raport z 26.09 wyjaśnia też blokadę pull przez `project.godot`, wspólny scroll
oraz liczniki działające przy przełączaniu profili. Aktualizacja źródeł nie
publikuje automatycznie nowej APK ani PWA.

Skopiuj ten plik albo ponizszy prompt do nowego czatu, gdy obecny zaczyna lagowac.

## Gotowy prompt do wklejenia

Pracujemy nad aplikacja Godot "Kalendarz Kierowcy" w repo:

- GitHub: `ElKlient/IDOL-Genesis`
- branch: `driver-shift-calendar`
- aplikacja kierowcy: root repo
- glowny plik: `scripts/main.gd`
- pomocnicze: `scripts/schedule_calculator.gd`, `scripts/background_art.gd`, `scenes/main.tscn`

To jest osobna aplikacja kalendarza kierowcy, nie gra IDOL Genesis. UI jest budowany prawie w calosci kodem w `scripts/main.gd`. Rob male, celowane latki. Nie przebudowywac od zera.

W repo jest tez osobna aplikacja `apps/wspolny-kalendarz`. Nie mieszac jej z kalendarzem kierowcy. Jesli zadanie dotyczy kierowcy, pracuj w root `scripts/main.gd`. Jesli dotyczy wspolnego kalendarza, pracuj w `apps/wspolny-kalendarz/scripts/main.gd`.

## Workflow

1. Zawsze najpierw sprawdz:

```bash
git status --short --branch
git fetch origin driver-shift-calendar
git log --oneline -8 origin/driver-shift-calendar
```

2. Jesli lokalna galaz jest rozjechana przez poprzednie update'y GitHub API, utworz swieza galaz z remote:

```bash
git switch -c driver-calendar-NAZWA-LATKI origin/driver-shift-calendar
```

3. Przeszukuj kod przez `rg`, np.:

```bash
rg -n "calendar_only|main_scroll|horizontal|settings_panel|day_tools|profile|reset|undo|Zastosuj|Jakim systemem" scripts/main.gd
```

4. Edytuj przez `apply_patch`. Nie ruszaj `apps/wspolny-kalendarz`, gry ani assetow bez prosby.

5. Sprawdz:

```bash
git diff --check
```

6. Swiezy Godot 4.4.1 dziala headless. Uruchamiaj testy z izolowanym XDG_DATA_HOME wedlug `docs/DRIVER_CALENDAR_BETA.md`. Poprzednia uszkodzona binarka nie oznacza niedostepnosci testow. Test fizycznego Androida nadal wykonuje uzytkownik.

7. Commituj mala latke.

8. Wrzucaj na GitHub branch `driver-shift-calendar`. Zwykly `git push` moze nie zadzialac przez brak loginu lub rozjechana historie. Wtedy zaktualizuj tylko zmieniony plik przez GitHub contents API.

9. Po zmianie podaj uzytkownikowi komendy do Termuxa.

## Termux / Android - wazne

Godot na telefonie ma otwierac projekt z:

```text
/storage/emulated/0/Godot/DriverShiftCalendar
```

Po latce uzytkownik aktualizuje ten wlasnie folder bez kasowania zmian:

```bash
cd /storage/emulated/0/Godot/DriverShiftCalendar &&
git pull --ff-only origin driver-shift-calendar &&
git --no-pager log -1 --oneline
```

Jesli zmiana "nadal jest" na ekranie, najpierw podejrzewaj zla kopie projektu albo stara APK:

- sprawdz, czy `git log -1 --oneline` pokazuje oczekiwany commit,
- sprawdz `grep` po pliku, czy kod faktycznie jest na telefonie,
- zamknij Godota i otworz projekt z `/storage/emulated/0/Godot/DriverShiftCalendar`,
- zbuduj i zainstaluj APK od nowa,
- jesli Godot otwiera inny folder, bedzie widac stary ekran mimo poprawnego GitHuba.

## Aktualny stan po ostatnich latkach

- Beta Android, kody, aktualizacje i zachowanie danych: `docs/DRIVER_CALENDAR_BETA.md`.
- Profile i godziny musza przetrwac kazda aktualizacje. Zachowaj package ID,
  podpis APK i `user://driver_calendar.cfg`. Nigdy nie proponuj odinstalowania
  jako sposobu aktualizacji. `git pull` nie aktualizuje APK testerow.

- Miesiac nie ma zmieniac sie gestem palca prawo/lewo. Nawigacja miesiecy tylko przyciskami.
- Dodany byl twardy lock poziomego scrolla: `_consume_horizontal_drag`, `_lock_horizontal_scroll`.
- Stare menu cykli zostalo usuniete:
  - `Jakim systemem jezdzisz?`
  - `Inne - wlasny cykl`
  - `Dni pracy` / `Dni domu`
  - `Dzien pierwszy pracy albo cyklu`
  - `Pauza 24h co 6 dni pracy`
  - `Wlasny cykl: wybierz dlugosc...`
  - `Zamknij ustawienia`
- W `scripts/main.gd` jest dodatkowy bezpiecznik runtime:
  - `LEGACY_CYCLE_MENU_MARKERS`
  - `_remove_legacy_cycle_settings_menu`
  - jesli jakis stary panel cykli pojawi sie w drzewie UI, aplikacja usuwa go po tekstach.

## Jak diagnozowac problem "nadal widze stare menu"

Na telefonie w Termuxie:

```bash
cd /storage/emulated/0/Godot/DriverShiftCalendar
git --no-pager log -1 --oneline
grep -n "_remove_legacy_cycle_settings_menu" scripts/main.gd
grep -n "Jakim systemem" scripts/main.gd
```

Oczekiwane:

- pierwszy grep znajduje `_remove_legacy_cycle_settings_menu`,
- drugi grep znajduje najwyzej wpis w `LEGACY_CYCLE_MENU_MARKERS`, a nie budowanie widocznych labeli/panelu,
- jesli pierwszy grep nic nie pokazuje, telefon ma stary plik,
- jesli plik jest dobry, a ekran stary, Godot odpala stara APK albo inny folder projektu.

## Zasady pracy

- Odpowiadaj po polsku.
- Uzytkownik chce konkretnej latki, bez lania wody.
- Jak mowi "tylko to", nie ruszaj nic innego.
- Kazda latka mala i osobna.
- Po pushu zawsze podaj commit i komendy do Termuxa.
