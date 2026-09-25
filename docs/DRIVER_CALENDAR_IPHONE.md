# Kalendarz Kierowcy — testy na iPhonie

## Co udostępniamy

Ten sam projekt Godot wyeksportowany do WebAssembly, jako aplikacja webowa
dodawana z Safari do ekranu głównego (PWA). To nie jest natywna IPA ani wydanie
TestFlight. Wersja Android pozostaje dostępna osobno.

Link: https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site/iphone/index.html

## Instrukcja dla kolegi

1. Otwórz link w Safari, poza trybem prywatnym.
2. Wybierz Udostępnij → Dodaj do ekranu początkowego/głównego.
   Jeśli jest opcja „Otwórz jako aplikację”, włącz ją. Potwierdź Dodaj.
3. Otwórz nową ikonę i poczekaj na pierwsze pobranie kalendarza.
4. Wpisz indywidualny kod od organizatora. W tym momencie zaczyna się 30 dni.
5. Korzystaj zawsze z tej samej ikony. Nie aktywuj osobnej sesji w Safari.

Organizator tworzy kod w dotychczasowym panelu `/admin`. Kod już przypisany
do Androida nie aktywuje drugiej instalacji: użyj oddzielnego kodu albo świadomie
przenieś przypisanie w panelu. Termin testów nie odnawia się przy przeniesieniu.
Panel pozwala przedłużać lub cofać dostęp również tej wersji. Cofnięcie jest
egzekwowane przy sprawdzeniu online lub po wygaśnięciu podpisanej zgody offline.

## Dane, kopie i aktualizacje

- Profile, godziny, notatki i liczniki są lokalne, w IndexedDB przeglądarki.
- Zachowujemy te same pliki Godot `user://driver_calendar.cfg` i
  `user://driver_beta_access.cfg`; licencja nie trafia do kopii kalendarza.
- Nie ma automatycznej synchronizacji Android–iPhone ani kopii godzin na serwerze.
- Menu `Wersja beta i aktualizacje` zawiera `Pobierz kopię kalendarza` i
  `Przywróć kopię z pliku`. Kopię `.dkcal` zachowaj w Plikach/iCloud Drive.
  Import obsługuje również wcześniejszy tekst `DKCAL1:...` zapisany w pliku.
  Przywrócenie wymaga aktywnego dostępu i potwierdzenia zastąpienia danych.
  Pobranie kopii jest dostępne także po upływie testów.
- Aktualizacja pobiera kompletny nowy zestaw plików do oddzielnej pamięci cache.
  Zaczyna obowiązywać po zamknięciu wszystkich okien kalendarza i ponownym
  uruchomieniu. Nie wymusza przeładowania w trakcie wpisywania i nie czyści IndexedDB.
- `Sprawdź aktualizację` sprawdza aktualizację webową; nie kieruje do Android APK.
- Praca offline jest możliwa po komunikacie o zapisaniu plików do pracy offline,
  przez maks. 72 godziny od potwierdzenia dostępu i nie dłużej niż do końca testów.

Nie usuwaj aplikacji ani danych Safari. Przeglądarka/system mogą usunąć dane
lokalne przy czyszczeniu lub braku miejsca; PWA nie zastępuje kopii do pliku.
Wygaśnięcie kodu samo nie kasuje kalendarza.

## Pierwszy test na rzeczywistym iPhonie

Najpierw jeden telefon. Zanotować model i wersję iOS.

1. Instalacja ikony, pojawienie się klawiatury, wpisanie i aktywacja kodu.
2. Wpisanie notatki z polskimi znakami oraz 8 h 30 min w wybranym dniu.
3. Zapis profilu, zamknięcie aplikacji, ponowne otwarcie i kontrola danych.
4. Rozpoczęcie pracy, blokada ekranu na kilka minut, powrót i kontrola licznika.
5. Pobranie kopii do Plików oraz jej przywrócenie po potwierdzeniu.
6. Po komunikacie gotowości offline: tryb samolotowy i ponowne uruchomienie.
7. Dotyk menu dnia, przewijanie pionowe, brak zmiany miesiąca gestem poziomym,
   miejsce na wycięcie ekranu i klawiaturę.
8. Po kolejnej publikacji: aktualizacja z zachowaniem godzin, profilu i terminu kodu.

Nie deklarować zakończonych testów iOS przed wynikiem od kolegi.

## Budowanie i publikowanie

Godot 4.4.1 i oficjalny szablon `web_nothreads_release.zip`.
Preset `iPhone Web Beta`: jeden wątek, Compatibility/WebGL2,
`driver_beta,driver_web_beta`, klawiatura ekranowa włączona.

```bash
python tools/build_driver_web.py --godot /sciezka/do/godot \
  --site /workspace/sites/kalendarz-kierowcy-beta
```

Wynik: `build/iphone/` (strona, pakiet kalendarza, manifest, worker),
`build/<sha256>.wasm.gz` i `build/iphone-release.json`.
Godot kopiuje aktualne źródła; nie budujemy drugiego kalendarza od zera.

Istniejący Site: `appgprj_6ab676fcded08191858a99dfb0fc968f`.
Przed edycją otworzyć ten Site według skill `sites-hosting`.
Duży silnik jest przechowywany w istniejącym R2 pod
`web-engines/<sha256>.wasm.gz`, pozostałe pliki w `public/iphone/` Site.

Endpoint publikacji silnika: `POST /api/admin/web-assets/<sha256>`.
Body: dokładne bajty `.wasm.gz`; Content-Length musi odpowiadać plikowi.
Autoryzacja: istniejący `RELEASE_UPLOAD_TOKEN` jako Bearer, wyłącznie po stronie
publikującego. Serwer weryfikuje SHA-256; token nie ma dostępu do zarządzania kodami.
Silnik o tej samej sumie przesyłać tylko raz. Nie usuwać wcześniejszych silników,
których mogą potrzebować starsze zainstalowane wersje.

Publiczny endpoint: `/api/web-assets/<sha256>/index.wasm`.
Odczyt R2 musi zdekompresować strumień gzip bez ustawiania Content-Encoding na
surowych skompresowanych bajtach: adapter frameworka powodował podwójną kompresję.
Test potwierdza, że klient dostaje właściwe bajty WASM.

Publikować Site przez jego własny workflow. Źródła Godot i tę instrukcję commitować
na `driver-shift-calendar`. Nie zmieniać adresu aplikacji, nazwy projektu,
manifest id, nazw plików danych ani klucza publicznego bez migracji.
Nie publikować tymczasowych `runtime-check.html`, `audit.pck` ani podpisanych
fixture testowych. Nie dodawać kluczy prywatnych do repo lub publicznych plików.

## Sprawdzone 25.09.2026

- Godot headless: 48 testów kalendarza + 23 dostępu/aktualizacji + 8 kopii, PASS.
- Usługa: 10 dotychczasowych testów + 2 przesyłania silnika, PASS; TypeScript PASS.
- `node --test tests/web_worker_audit.mjs`: 3 testy pełnego cache, aktualizacji
  i niewłączania odpowiedzi API do cache, PASS.
- Przeglądarka: rzeczywisty Godot WebAssembly uruchomiony z `--headless`
  w izolowanym eksporcie testowym. Sprawdzono IndexedDB, losowanie identyfikatora,
  weryfikację podpisu RSA i odrzucenie uszkodzonego podpisu. Po przeładowaniu:
  godziny, notatki, profil i początek zmiany zachowane — 8 kontroli PASS.
- Przeglądarka testowa nie oferuje WebGL2; jej podgląd używa HTTP. Dlatego brak
  oceny grafiki/dotyku oraz pełnego testu service workera przez HTTPS w Safari.
  Nie wykonano aktywacji poprawnego kodu na fizycznym iPhonie.

`tests/web_runtime_audit.gd` służy tylko izolowanemu testowemu eksportowi.
Potrzebuje jednorazowego fixture z podpisem, identyfikatorem `1` × 32 i nonce
`2` × 32; przygotować poza produkcyjnym repo. Uruchomić dwukrotnie na tej samej
domenie. Produkcyjne presety wykluczają cały katalog `tests`.

## Późniejsza wersja natywna

Natywna aplikacja Godot iOS pozostaje osobnym etapem: macOS + Xcode,
podpisy/provisioning właściciela, konto Apple Developer i TestFlight.
Ta publikacja nie utworzyła konta Apple ani podpisanej IPA.
