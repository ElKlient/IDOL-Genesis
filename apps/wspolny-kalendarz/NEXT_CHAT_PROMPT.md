# Wspolny Kalendarz - prompt dla nastepnego czatu

Skopiuj ten plik albo ponizszy prompt do nowego czatu, gdy obecny zaczyna lagowac.

## Gotowy prompt do wklejenia

Pracujemy nad aplikacja Godot "Wspolny Kalendarz" w repo:

- GitHub: `ElKlient/IDOL-Genesis`
- branch: `driver-shift-calendar`
- aplikacja: `apps/wspolny-kalendarz`
- glowny plik: `apps/wspolny-kalendarz/scripts/main.gd`
- pomocnicze: `apps/wspolny-kalendarz/scripts/background_art.gd`, `apps/wspolny-kalendarz/scenes/main.tscn`

To jest osobna aplikacja kalendarza wspolnego, ale trzymana w tym samym repo co IDOL Genesis i kalendarz kierowcy. Nie mieszac jej ze starym kalendarzem kierowcy w root `scripts/main.gd`. Stary "Kalendarz Kierowcy" ma zostac.

Odpowiadaj po polsku. Rob male, celowane latki. Jesli uzytkownik mowi "tylko to", rusz tylko wskazana rzecz. UI jest budowany prawie caly kodem w GDScript, wiec nie przebudowywac od zera.

## Workflow

1. Zawsze najpierw sprawdz:

```bash
git status --short --branch
git log --oneline -8
```

2. Przeszukuj kod przez `rg`, np.:

```bash
rg -n "Schematy cykliczne|applied_system_schemes|calendar_only|month_layout|main_scroll|Udostepnij|Wyczysc schematy|Pokaż" apps/wspolny-kalendarz/scripts/main.gd
```

3. Edytuj przez `apply_patch`. Nie rob duzych przebudow bez wyraznej prosby.

4. Sprawdz:

```bash
git diff --check
```

5. Commituj mala latke.

6. Wrzucaj na GitHub branch `driver-shift-calendar`. Lokalny branch bywa rozjechany z remote, bo poprzednie latki byly wrzucane przez GitHub API. Jezeli zwykly `git push` nie pasuje, aktualizuj tylko zmieniony plik przez GitHub contents API.

7. Uzytkownik testuje na Androidzie:

```bash
cd ~/IDOL-Genesis
git pull origin driver-shift-calendar
mkdir -p /storage/emulated/0/Godot/WspolnyKalendarz
cp -r apps/wspolny-kalendarz/. /storage/emulated/0/Godot/WspolnyKalendarz/
```

Godot na telefonie otwiera projekt z:

```text
/storage/emulated/0/Godot/WspolnyKalendarz
```

## Aktualny stan aplikacji

- Aplikacja jest w folderze `apps/wspolny-kalendarz`.
- Wyglad jest podobny do kalendarza kierowcy: pionowy mobilny kalendarz, ciemne tlo z ciezarowka, kafelki dni.
- Jest wybor ukladu miesiecy w lewym gornym rogu: `Układ: 1`, `4`, `6`, `12`.
- W ukladach kilku miesiecy klikniecie miesiaca/dnia przechodzi do pojedynczego miesiaca.
- Tryb `Pokaż tylko kalendarz` ukrywa panele, ale zostawia wybor ukladu miesiecy.
- Jest przycisk `Wróć do aktualnej daty`; aktualny dzien ma obramowanie.
- Miesiace zmieniaja sie przyciskami `<` i `>`, nie gestem palca.
- Panele `Schematy cykliczne` i `Udostępnij kalendarz` sa chowane/rozwijane.
- Udostepnianie jest na razie lokalnym kodem/linkiem pod przyszla synchronizacje online.

## Aktualna logika dni

- Klikniecie dnia otwiera male menu dnia.
- W menu dnia sa szybkie przyciski typu `praca`, `dom`, `24h pauzy`.
- Plus pozwala dodawac wlasne stale przyciski z nazwa i kolorem.
- Przyciski mozna usuwac, ale usuniecie przycisku nie powinno kasowac juz oznaczonych dni.
- `Dodaj wydarzenie` zapisuje wydarzenie na konkretnym dniu.
- Wydarzenia pokazuja sie na kafelku jako male swiecace kropki; szczegoly widac dopiero po kliknieciu dnia.
- Notatki sa oddzielne od oznaczen i wydarzen.

## Schematy cykliczne

Stan po ostatniej latce remote:

- Ostatni remote commit: `cacd9ba Add shared scheme list controls`.
- W panelu `Schematy cykliczne` jest lista dodanych schematow w kolejnosci.
- Schemat po zastosowaniu pyta o nazwe.
- Schemat ma opcje `Pokaż`/ukryj.
- Schemat ma opcje `Usuń` z potwierdzeniem.
- `Wyczyść schematy` ma czyscic wszystkie schematy cykliczne i aktualnie wytyczany wzor.

Jesli uzytkownik zglosi blad w schematach, najpierw sprawdz te funkcje w `apps/wspolny-kalendarz/scripts/main.gd`:

- `_build_system_days_panel`
- `_refresh_applied_system_scheme_ui`
- `_add_system_scheme_row`
- `_clear_system_days`
- `_apply_system_days_to_year`
- `_apply_system_days_with_name`
- `_confirm_delete_applied_system_scheme`
- `_delete_applied_system_scheme_confirmed`
- `_set_applied_system_scheme_visible`
- `_remove_applied_system_scheme_by_id`
- `_applied_system_schemes`
- `_ensure_applied_system_schemes`
- `_normalize_applied_system_scheme`
- `_rebuild_system_scheme_event_cache`
- `_event_ids_for_day`

## Znane ograniczenia

- W srodowisku Codex Godot headless zwykle konczy sie kodem `139` bez logu:

```bash
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path apps/wspolny-kalendarz --quit
```

Trzeba to uczciwie powiedziec. Mimo tego rob `git diff --check` i kontroluj skladnie statycznie.

## Najwazniejsze zasady

- Nie ruszaj starej aplikacji kierowcy, chyba ze uzytkownik wyraznie o nia poprosi.
- Nie ruszaj gry IDOL Genesis.
- Kazda latka ma byc mala i osobna.
- Po zmianie zawsze podaj uzytkownikowi komendy do Termuxa.
