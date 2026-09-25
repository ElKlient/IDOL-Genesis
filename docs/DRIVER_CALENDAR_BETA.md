# Kalendarz Kierowcy — beta na Androida

Wersja dla testerów na iPhonie (Safari/PWA) korzysta z tego samego panelu i kodów.
Instalacja, zapis i publikowanie: `docs/DRIVER_CALENDAR_IPHONE.md`.

## Dostęp dla testerów

- Strona: https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site
- Instalator: https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site/download
- Panel właściciela: https://kalendarz-kierowcy-beta.sethoyt.chatgpt.site/admin
- Właściciel loguje się przez ChatGPT tym samym kontem, które utworzyło usługę.
- W panelu wybierz liczbę (np. 20) i utwórz kody. Pobierz listę od razu: pełne
  kody są pokazywane tylko raz, serwer przechowuje ich skróty.
- Każdemu testerowi przekaż link oraz inny kod. Nie przekazuj archiwum kluczy.

Tester instaluje APK, uruchamia ją z internetem i wpisuje kod. Pierwsza aktywacja
rozpoczyna 30 dni. Kod jest związany z jedną instalacją. Ponowne wpisanie kodu
na tym samym telefonie ani aktualizacja APK nie odnawia terminu.

Panel pozwala przedłużyć dostęp o 30 dni, cofnąć go, przywrócić, odpiąć zgubiony
telefon lub wstrzymać całą betę. Zmiana telefonu zachowuje termin końca testów.
Odinstalowanie lub wyczyszczenie danych wymaga ponownego przypisania telefonu;
nie daje kolejnych 30 dni. Nie przywraca też lokalnych danych kalendarza.

Po potwierdzeniu dostępu aplikacja działa offline do 72 godzin, nie dłużej niż
do końca okresu. Sprawdza dostęp przy uruchomieniu, wznowieniu i co 12 godzin
działania. Po awarii sieci ponawia próbę po 5 minutach. Cofnięcie dostępu działa
po następnym sprawdzeniu lub wygaśnięciu bieżącego pozwolenia offline.
Nie jest to gwarancja natychmiastowej blokady telefonu bez internetu ani pełna
ochrona przed zmodyfikowaną APK/rootem. Weryfikacja czasu lokalnego wykrywa
podstawowe cofnięcie zegara; o terminie testów decyduje serwer.

Po blokadzie zapis nie jest kasowany. W ekranie bety dostępny jest odczyt godzin,
notatek i początków liczników oraz skopiowanie całego zapisu do własnego pliku
tekstowego (`DKCAL1:` + base64 pliku ConfigFile). To kopia do odzyskania; bieżąca
wersja nie ma jeszcze samodzielnego przycisku importu tej kopii.

## Aktualizacje bez utraty danych

Stałe elementy wydania:

- Android application ID: `pl.elklient.kalendarzkierowcy.beta`.
- Alias podpisu: `driver-beta`; certyfikat przypięty w `beta/android-signing-cert.sha256`.
- Nazwa projektu Godot pozostaje `Kalendarz Kierowcy`.
- Dane kalendarza: `user://driver_calendar.cfg`, poprzedni zapis: `.bak`.
- Aktywacja: osobny `user://driver_beta_access.cfg`; reset kalendarza jej nie zmienia.
- Format kalendarza: 1; obsługiwany też wcześniejszy zapis bez numeru (0).
  Nieznane pola są zachowywane. Nowszy, nieobsługiwany format blokuje zapis
  zamiast pozwalać starszej aplikacji zniszczyć dane.

Tester instaluje kolejną APK **na istniejącą aplikację**, bez odinstalowania
i bez czyszczenia danych. W razie komunikatu o niezgodnym podpisie nie zalecaj
odinstalowania — sprawdź klucz i identyfikator nowego wydania.

`git pull` aktualizuje źródła u właściciela. Nie wysyła aktualizacji na telefony.
Po lokalnym sprawdzeniu zmian trzeba zbudować podpisaną APK z większym numerem
wersji i opublikować ją w panelu. Link pobierania pozostaje ten sam. W aplikacji
tester ma przycisk `Wersja beta i aktualizacje` → `Sprawdź aktualizację`.
Instalację potwierdza Android; nie ma cichej instalacji w tle.

Pierwsza samodzielna APK jest osobną aplikacją względem projektu uruchamianego
wewnątrz edytora Godot. Nie przejmuje automatycznie jego lokalnego zapisu.
Powyższa ciągłość danych dotyczy kolejnych aktualizacji tej samej APK beta.

## Budowanie i publikacja

Preset `Android Beta` zawiera feature `driver_beta`, który włącza obowiązkową
aktywację. Zwykłe uruchomienie źródeł w Godot nadal służy pracy właściciela.
Nie rozdawaj eksportów z innego presetu bez aktywacji.

Godot 4.4.1, Java 17, szablony Android i SDK skonfigurowane w ustawieniach edytora.
Wersja używa renderera Compatibility; nie wymaga Vulkan. To dystrybucja APK do
testów, nie gotowe zgłoszenie do Google Play. Pakiet ma ARMv7 i ARM64.

Klucz APK i hasło zostały przekazane właścicielowi w prywatnym pliku
`Kalendarz-Kierowcy-Klucze-Wlasciciela.zip`. Archiwum zawiera też kopię klucza
podpisującego licencje i uprawnienie do publikowania APK. Nie dodawać do GitHuba,
nie umieszczać w aplikacji ani nie przekazywać testerom.

Przykład na komputerze z Pythonem 3.11+ i wymienionymi narzędziami w PATH:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="/bezpieczny/katalog/driver-beta.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="driver-beta"
read -r -s -p "Hasło klucza APK: " GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
python tools/build_driver_beta.py --version-code 2 --version-name 0.1.0-beta.2
unset GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
```

Następne wydania muszą mieć kolejno większy numer. Skrypt aktualizuje publiczne
numery wersji, buduje APK, sprawdza podpis, identyfikator, wersję, feature bety
i brak plików innych aplikacji. Wytwarza APK i odpowiadający `.release.json`.
Oba wybierz w panelu właściciela, w sekcji aktualizacji. Panel sprawdza zgodność
sumy SHA-256 przed wysłaniem, serwer również weryfikuje tę sumę.
Zmianę numerów wersji trzeba następnie commitować na `driver-shift-calendar`.

Jeśli APK zbudowano w edytorze, można utworzyć plik wydania po jej weryfikacji:

```bash
python tools/build_driver_beta.py --verify-only /sciezka/do/aplikacji.apk
```

## Testy i ograniczenia

```bash
XDG_DATA_HOME=/tmp/driver-calendar-audit-regression godot --headless --path . --script res://tests/release_audit.gd
XDG_DATA_HOME=/tmp/driver-calendar-audit-upgrade godot --headless --path . --script res://tests/beta_upgrade_audit.gd
```

Wyniki 25.09.2026: 48 kontroli regresji + 23 kontrole bety i ciągłości danych,
wszystkie PASS. Usługa kodów: 10 testów na SQLite i podpisach RSA, wszystkie PASS.
Sprawdzono podpis APK i metadane Android. Odpowiedź opublikowanej usługi na błędny
kod zweryfikowano w Godot rzeczywistym kluczem publicznym; niezalogowany dostęp
do API panelu jest odrzucany. Nie wykonano instalacji/aktualizacji na fizycznym
Androidzie ani pełnej aktywacji poprawnego kodu na telefonie. Pierwszy tester
powinien to potwierdzić przed rozdaniem pozostałych kodów.

Testy nie dowodzą zgodności każdego przyszłego formatu. Każda zmiana zapisu musi
dodać migrację i scenariusz zachowania wcześniejszych danych przed publikacją.

## Dla kolejnego agenta: usługa aktywacji

Usługa i panel mają osobne źródła zarządzane przez Sites, nie w grze ani
`apps/wspolny-kalendarz`. Projekt: `appgprj_6ab676fcded08191858a99dfb0fc968f`.
W tej sesji checkout: `/workspace/sites/kalendarz-kierowcy-beta`. Przy kolejnym
zadaniu otworzyć ten istniejący Site według workflow `sites-hosting`; nie tworzyć
drugiej usługi i nie zmieniać kluczy bez planu migracji.

D1: skróty kodów i tokenów, losowe identyfikatory instalacji, terminy, blokady,
wersje APK. R2: instalatory. Nie są przesyłane profile, notatki ani godziny.
Nie dodano czatu, mailingu, zbierania feedbacku ani analityki.

Protokół 1: POST `/api/beta/activate` (kod, install_id, nonce), POST
`/api/beta/refresh` (session_token, install_id, nonce). Odpowiedź zawiera
`payload` (base64 JSON UTF-8) i `signature` (RSA PKCS#1 v1.5 / SHA-256).
Klucz publiczny w `beta/lease-public.pem`; klucz prywatny wyłącznie po stronie
usługi i w prywatnej kopii właściciela. Klient sprawdza podpis, nonce, instalację,
termin 72h i koniec testów. Używa jawnego User-Agent aplikacji; generyczny klient
Python otrzymywał od bramki hostingu 403/1010, właściwy klient aplikacji działa.

Panel jest chroniony SIWC i sprawdzeniem adresu właściciela na serwerze; nie
wystarczy ukrycie przycisków. Mutacje z przeglądarki sprawdzają Origin. Oddzielny
sekretny token publikacji pozwala tylko wysłać APK, nie zarządzać kodami.
Nie drukować sekretów, treści kodów ani tokenów w logach lub publicznym repo.
