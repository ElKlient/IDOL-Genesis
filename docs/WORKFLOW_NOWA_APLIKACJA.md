# Workflow dla agenta nowej aplikacji — Termux, Godot, GitHub

Aktualizacja: **7 października 2026**.

To instrukcja współpracy z użytkownikiem przy **innym, nowym projekcie**.
Użytkownik poprosił o zapis na GitHubie, ponieważ nie może wkleić całego długiego
promptu do kolejnego czatu. Przeczytaj ten plik w całości, a następnie wykonuj
zadania dotyczące nowej aplikacji podane w swojej rozmowie.

Ten plik jest przechowywany w repo `ElKlient/IDOL-Genesis`, na branchu
`driver-shift-calendar`, wyłącznie jako notatka do przekazania. **Nie oznacza to,
że nową aplikację masz tworzyć w tym repo albo na tym branchu.**

## 1. Telefon i narzędzia użytkownika

Potwierdzone przez zrzuty użytkownika z 7.10.2026:

- Samsung Galaxy S26, model `SM-S942B`.
- Android 16, One UI 8.5 (właściwość systemowa `80500`).
- Architektura `arm64-v8a`.
- Działający Termux z Gitem i dostępem do pamięci współdzielonej.
- Godot Engine **4.7.2 stable** na Androidzie.
- Kalendarz Kierowcy pobrano na nowy telefon i uruchomiono; użytkownik potwierdził
  „Działa”. Potwierdza to instalację i uruchomienie, a nie pełny test funkcji.

Użytkownik pracuje z telefonu. Odpowiadaj po polsku. Dawaj krótkie wyjaśnienia
i gotowe bloki poleceń do skopiowania. Nie wymagaj ręcznego edytowania kodu
na telefonie, jeśli możesz sam przygotować i opublikować łatkę.

Nie masz automatycznego dostępu do telefonu. Polecenia w środowisku agenta
nie wykonują się u użytkownika. Nie twierdź, że zainstalowałeś coś na telefonie,
jeśli jedynie przygotowałeś polecenia lub pliki w swoim środowisku.

## 2. Nowy projekt musi być oddzielony

Wykorzystaj informacje już podane w rozmowie. Jeśli brakuje celu aplikacji,
nazwy lub miejsca przechowywania kodu, ustal tylko te brakujące dane.
Nie pytaj ponownie o decyzje, które użytkownik już podjął.

Preferowane jest osobne repozytorium i osobny folder na telefonie. Ustal docelowe
repozytorium, branch, nazwę folderu i widoczność nowego repo przed jego utworzeniem
lub publikacją. Nie zakładaj, że nowy kod ma być publiczny.
Jeśli użytkownik wskazał inne rozwiązanie, zastosuj jego ustalenia.

Istniejące projekty — kontekst, nie domyślne miejsce pracy:

| Projekt | Repo / branch | Miejsce projektu |
| --- | --- | --- |
| Kalendarz Kierowcy | `ElKlient/IDOL-Genesis`, `driver-shift-calendar` | Główny katalog repo; telefon: `/storage/emulated/0/Godot/DriverShiftCalendar` |
| Wspólny Kalendarz | To samo repo i branch | `apps/wspolny-kalendarz`, osobny projekt Godot |
| Gra IDOL Genesis | `ElKlient/IDOL-Genesis`, `main` | Osobny zakres prac nad grą |

Nie zmieniaj tych aplikacji podczas pracy nad nową aplikacją. Nie twórz kopii
kalendarza jako nowej aplikacji bez polecenia użytkownika. Nowa aplikacja powinna
mieć własną tożsamość projektu i miejsce na zapis danych; przy eksporcie
na Androida również własny identyfikator pakietu.

Opis uruchamiania poniżej dotyczy Godota. Jeśli nowe zadanie wymaga innej
technologii, jasno określ sposób uruchomienia; Godot nie jest obowiązkowy
dla dowolnego rodzaju aplikacji.

## 3. Codzienny workflow i zakres zgód

1. Użytkownik opisuje funkcję albo problem i może przesłać zrzut ekranu.
2. Agent sprawdza bieżący kod i instrukcje właściwego projektu.
3. Agent wykonuje małą, celowaną zmianę i ją weryfikuje.
4. Agent commituje i publikuje zmianę na uzgodnionym branchu nowego projektu.
5. Agent podaje gotową komendę aktualizacji do Termuxa.
6. Użytkownik pobiera zmiany, otwiera projekt w Godocie i testuje na telefonie.
7. Użytkownik przekazuje wynik; agent przygotowuje następną poprawkę.

Po otrzymaniu konkretnego zlecenia wykonuj pracę, zamiast jedynie deklarować,
że możesz ją wykonać. Nie pytaj ponownie o już zatwierdzone działania.
Zgody i zakres ustalaj na podstawie swojej rozmowy; nie dopisuj zezwoleń,
których nie udzielono. W tym repo użytkownik zezwolił na małe łatki,
commitowanie i publikację na `driver-shift-calendar`, w tym zapis tej notatki.
Nie jest to zgoda na zmiany w dowolnym innym projekcie.

## 4. Pierwsze pobranie i uruchomienie

Termux i Git są już zainstalowane. Nie każ instalować ich od nowa przy każdym
projekcie. Preferuj adres repo przez HTTPS; przy prywatnym repo sprawdź,
czy użytkownik ma skonfigurowany dostęp.

Standardowy katalog projektów: `/storage/emulated/0/Godot/`.
Każda aplikacja otrzymuje osobny folder. Pierwsze pobranie wykonujemy przez
`git clone --single-branch --branch ...`, z ustalonym adresem i nazwą folderu.
W poleceniu dla użytkownika wpisz rzeczywiste wartości, a nie placeholdery.

Jeśli brakuje dostępu do plików, użyj `termux-setup-storage`, pozwól użytkownikowi
udzielić zgody w Androidzie i dopiero potem podaj następny krok.
Przy błędzie Gita „dubious ownership” dodaj `safe.directory` tylko dla konkretnego
folderu projektu. Nie stosuj wartości `*` obejmującej wszystkie katalogi.

Godot: **Importuj → wybierz `project.godot` nowej aplikacji → Importuj i edytuj → ▶**.
Godot musi mieć dostęp do plików w wybranym folderze.

Jeśli `git clone` zgłasza istniejący, niepusty folder, sprawdź go — nie kasuj.
Na nowym telefonie klonowanie Kalendarza Kierowcy zakończyło się poprawnie;
ponowne wykonanie tego samego bloku zgłosiło właśnie taki komunikat.
Ponowne klonowanie nie jest sposobem aktualizacji istniejącego projektu.

## 5. Aktualizacje i lokalne zmiany Godota

Przed aktualizacją użytkownik zamyka uruchomioną aplikację i projekt w Godocie.
Blok aktualizacji powinien kolejno:

1. Wejść do pełnej ścieżki folderu nowej aplikacji.
2. Wykonać `git pull --ff-only origin` z właściwą nazwą brancha.
3. Wyświetlić `git --no-pager log -1 --oneline`.

Łącz zależne kroki przez `&&`, aby błąd zatrzymał dalsze polecenia.
Użytkownik ponownie otwiera projekt i naciska ▶.
Po publikacji podaj oczekiwany SHA commita.

Ważny problem z poprzedniego telefonu: Godot zmienił lokalnie `project.godot`.
`git pull` kończył się komunikatem, że lokalne zmiany zostałyby nadpisane.
Telefon nadal uruchamiał starą wersję mimo poprawnie opublikowanych łatek.

Sprawdź status i różnice. Jeśli blokadą są lokalne ustawienia Godota, po
zamknięciu edytora można zachować ich kopię przed aktualizacją:

```bash
git stash push -m "Kopia ustawien Godota przed aktualizacja" -- project.godot
```

To polecenie wykonuje się we właściwym folderze repo. Nie stosuj automatycznego
`stash pop`, bo może przywrócić stare ustawienia lub wywołać konflikt.
Nie chowaj bez sprawdzenia wszystkich lokalnych zmian i nie kasuj cudzej pracy.
Nie używaj `git reset --hard`, `git clean -fd` ani usuwania folderu jako rutynowej
naprawy aktualizacji.

Jeśli użytkownik nie widzi poprawki, sprawdź: wynik pull, SHA na telefonie,
właściwy branch, zawartość pliku i ścieżkę projektu otwartego w Godocie.

## 6. Dane i wydania aplikacji

- Aktualizacje muszą zachowywać zapisane dane. W Godocie przechowuj je poza
  wersjonowanym kodem, np. w `user://` właściwego projektu.
- Przy zmianie formatu zapisu zapewnij zgodność albo migrację oraz kopię danych.
- Nowy telefon nie odzyskuje lokalnych danych starego telefonu przez klonowanie
  repo. Potrzebna jest kopia lub osobny mechanizm synchronizacji.
- Uruchamianie źródeł w Godocie i zainstalowana APK to różne sposoby używania
  aplikacji; mogą mieć osobne dane.
- `git pull` aktualizuje źródła. Nie aktualizuje automatycznie APK ani wersji web.
- Dla nowej APK utrzymuj stały identyfikator pakietu i klucz podpisu, zwiększaj
  numer wersji i instaluj aktualizację na istniejącą aplikację. Nie proponuj
  odinstalowania jako zwykłego sposobu aktualizacji.

## 7. Praca w repo i weryfikacja

Najpierw przeczytaj README i instrukcje nowego projektu, a następnie sprawdź:

```bash
git status --short --branch
git log --oneline -8
```

Pobierz aktualny stan właściwego zdalnego brancha. Nie zakładaj, że stary lokalny
checkout jest aktualny. Zachowaj cudze zmiany; można przygotować osobny checkout
lub worktree dla zadania.

- Szukaj kodu przez `rg`; rób małe, celowane łatki.
- Sprawdzaj `git diff --check` i rzeczywiste zachowanie zmienionej funkcji.
- Dobieraj testy do ryzyka. Zmiana dokumentacji nie wymaga testów aplikacji.
- Testy zapisu uruchamiaj na odizolowanych danych, nie na danych użytkownika.
- Jawnie rozróżniaj test headless, test interfejsu i test fizycznego telefonu.
- Commituj tylko pliki należące do zadania. Publikuj na uzgodniony branch.
- Jeśli zwykły push nie działa z powodu braku uwierzytelnienia w środowisku,
  a masz uprawniony konektor GitHub, możesz użyć jego API: utworzyć drzewo
  z bieżącego drzewa bazowego i zmienionych plików, porównać wynik z lokalnym
  drzewem, utworzyć commit z aktualnym rodzicem i przesunąć branch bez force.
  Jeśli pojawiły się cudze zmiany, pobierz je i uzgodnij nową bazę.
  Nie traktuj tego jako sposobu obchodzenia odmowy uprawnień.
- Potwierdź publikację na GitHubie. Jeśli jest zablokowana, napisz to wprost.

Po łatce podaj krótko: **co zmieniono, co sprawdzono, SHA opublikowanego commita
i gotowy blok aktualizacji do Termuxa**. Jeśli to tylko notatka do przekazania,
podaj link i krótki prompt zamiast niepotrzebnej aktualizacji aplikacji.

## 8. Notatnik i przekazywanie pracy

W nowym repo prowadź README oraz `docs/STRESZCZENIE.md`. Zapisuj:

- cel i aktualny zakres aplikacji;
- repo, branch, folder na telefonie i wersję Godota;
- strukturę kodu, uruchamianie i aktualizację;
- zapis, kopie i migrację danych;
- wykonane zmiany, wyniki testów oraz ograniczenia weryfikacji;
- znane problemy i następne zadania;
- rzeczywiste zgody użytkownika i ich zakres.

Gdy użytkownik napisze **STRESZCZENIE**, zaktualizuj notatkę na GitHubie i daj
krótki tekst z dokładnym linkiem do wklejenia następnemu agentowi. Jeśli poprosi
o pełny tekst, daj również wersję do skopiowania. Użytkownik może nie mieć
możliwości wklejenia długiego promptu.

Nie twierdź, że kolejny agent sam zna poprzednie rozmowy. Zapis w repo oraz
polecenie przeczytania konkretnego pliku mają przekazać potrzebny kontekst.

## 9. Stały adres tej instrukcji

- Repo: `ElKlient/IDOL-Genesis`
- Branch: `driver-shift-calendar` — wskaż go jawnie; nie szukaj w `main`.
- Plik: `docs/WORKFLOW_NOWA_APLIKACJA.md`
- Link: https://github.com/ElKlient/IDOL-Genesis/blob/driver-shift-calendar/docs/WORKFLOW_NOWA_APLIKACJA.md

Po przeczytaniu stosuj ten sposób pracy w **nowym, uzgodnionym projekcie**.
Jeśli dostęp do instrukcji nie działa, zgłoś konkretny problem zamiast udawać,
że plik został przeczytany.
