# Audyt Kalendarza Kierowcy - 2026-09-25

## Ocena

Baza do zamknietych testow z kierowcami, jeszcze nie do platnego wydania.
Najpierw wiarygodnosc danych i licznikow, potem wygoda codziennej obslugi,
na koncu przygotowanie dystrybucji i platnosci. Nie potrzeba przebudowy aplikacji.

Audyt dotyczy osobnej aplikacji w katalogu glownym repo ElKlient/IDOL-Genesis,
branch `driver-shift-calendar`, kod bazowy
`c5ccea422ba72c63cc6023fe66462a08e343ecc3`.
Nie dotyczy gry ani `apps/wspolny-kalendarz`.

Ta zmiana dodaje testy i dokumentacje. Nie naprawia wymienionych problemow.

## Co rzeczywiscie uruchomiono

- Swiezy oficjalny Godot 4.4.1, Linux x86_64, import projektu: powodzenie.
- Rzeczywisty skrypt aplikacji i scenariusze `tests/release_audit.gd` w silniku.
- Osobny `XDG_DATA_HOME` w `/tmp/driver-calendar-audit-*`, bez danych uzytkownika.
- 24 kontrole: **15 PASS, 9 FAIL**. Kod wyjscia 1 jest oczekiwany przy obecnych usterkach.
- Geometria kontrolek dla viewportu 720x1280 i syntetyczne zdarzenia dotyku.
- Xvfb nie uruchomil ekranu: srodowisko odmawia tworzenia gniazd Unix.
  Nie wykonano zrzutow renderowanej aplikacji ani testu fizycznego Androida.
- Test zapisu obejmuje odczyt po wyczyszczeniu stanu w pamieci. Nie jest
  testem zabicia procesu przez Androida ani reinstalacji APK.

Historyczne bledy 139 nie oznaczaja, ze Godot zawsze tu nie dziala.
Znaleziona wczesniejsza lokalna binarka 4.7.2 miala niekompletna strukture ELF
i padala nawet przy `--version`; swiezy 4.4.1 wykonal ponizsze scenariusze.
Nie ustalono przyczyn wszystkich historycznych awarii.

## Powtarzalny test

Z katalogu glownego projektu, w Linux, z dostepnym Godot 4.4.1:

```bash
XDG_DATA_HOME=/tmp/driver-calendar-audit-local godot --headless --path . --script res://tests/release_audit.gd
```

Jesli binarka nazywa sie `godot4`, uzyj tej nazwy. Katalog musi byc przeznaczony
wylacznie na ten test: skrypt usuwa i nadpisuje testowy `driver_calendar.cfg`.
Skrypt odmawia pracy poza wskazanym prefiksem katalogu i poza Linux.
FAIL oznacza niespelniony warunek akceptacji; czesc dotyczy decyzji UX,
a nie bledu wykonania silnika. Powodzenie testu gestu nie dowodzi poprawnosci
wszystkich gestow, urzadzen, przekatnych ruchow i zachowan Androida.

## Problemy poparte testami

Numery linii odnosza sie do bazowego `scripts/main.gd`.

| Priorytet | Scenariusz i wynik | Przyczyna / miejsce | Mala poprawka |
| --- | --- | --- | --- |
| P1 | Profil 1 ma 8h30. Wczytanie pustego profilu 2 pozostawia te 8h30. | `_on_load_profile_pressed`, linia 2002; `_reset_calendar_settings`, linia 2301, nie czysci `worked_seconds_by_day`. | Pusty profil musi miec puste godziny. Zachowac odzyskiwanie poprzedniego stanu. |
| P1 | Ponowny start po 8h zmienia poczatek zmiany na teraz; test traci 28800 s. | `_on_start_work_pressed`, linia 4443. Brak sprawdzenia aktywnej zmiany. | Aktywny start nie moze nadpisywac licznika. Korekta czasu jako jawna akcja. |
| P1 | Ponowny start pauzy po 3h zeruje jej dotychczasowy czas. | `_on_start_pause_pressed`, linia 4483. | Analogiczna ochrona aktywnej pauzy. |
| P1 | Zapis profilu podczas pracy, zakonczenie zmiany, wczytanie profilu: wraca aktywny licznik i znika pozniejszy zapis godzin. | `_calendar_state_snapshot`, linia 2065; `_restore_calendar_state`, linia 2098. Profil odtwarza rowniez stan biezacej zmiany. | Ustalic czy profil jest grafikiem, czy pelna kopia. Nie przywracac po cichu starego aktywnego licznika. |
| P1 | Wymuszony blad zapisu pliku (kod 12) nadal daje komunikat `Zapisano profil 1.`. | `_on_save_profile_pressed`, linia 1992; `_save_settings_to_disk`, linia 1644. Blad jest tylko w logu. | Zwroc wynik zapisu i pokaz prawdziwy status. Dodac zapis tymczasowy, bezpieczna podmiane i kopie do odzyskiwania. |
| P2 | `Profile` nachodzi na `Wroc do aktualnej daty` na obszarze 50x44 jednostki UI. | `_add_profile_overlay`, linia 792; `_add_return_today_overlay`, linia 744. | Poprawic pozycje samego przycisku, zachowujac panel profili. |
| P2 | Pusty sierpien 2026, 6 rzedow: okno opcji ma tylko 32 jednostki wysokosci, przycisk `Zastosuj` ma 62. | `_build_ui`, linia 301; `_make_month_section`, linia 2455; sztywne wysokosci i brak pionowego scrolla pojedynczego miesiaca. | Zapewnic dostep do podstawowych akcji dla 6 rzedow i mniejszych ekranow. Nie przywracac swipe zmiany miesiaca. |
| P2 | Menu dnia w pomiarze silnika ma 640x1633, przy ekranie 720x1280. | `_build_day_action_dialog`, linia 1180. Brak przewijalnego kontenera dla dlugiej listy. | Dopasowac wysokosc i zapewnic przewijanie oraz dostepne zamkniecie. Potwierdzic wyglad na Androidzie. |
| P2 / UX | W trybie tylko kalendarz znika przycisk powrotu do dzisiaj. | `_apply_main_view_mode`, linia 1527. Jest to jawne obecne zachowanie. | Zachowac szybki powrot do dzisiaj rowniez w tym trybie. |

P1: ryzyko blednych danych lub mylacego potwierdzenia. P2: obsluga i dostepnosc
akcji przed wydaniem. Wyniki ukladu to pomiary drzewa UI w trybie headless,
nie dowod identycznego obrazu na kazdym telefonie.

## Co dziala w objetych testem przypadkach

- Start aplikacji z pustym kalendarzem.
- Poprawna i niepoprawna data 29 lutego; granice cyklu 2/1.
- Wlasny cykl 6 pracy + 24h + 6 pracy + 8 domu na przelomie lat,
  z powtorzeniem takze 150 cykli pozniej; staly poczatek w piatek.
- Edycja pojedynczego dnia w zapisanym widoku nie zmienia cyklu.
- Reczne 8h30 zostaje przy dacie otwartego okna, mimo zmiany zaznaczenia dnia.
- Suma miesiaca dla tego zapisu, odtworzenie godzin i notatki z zapisanego profilu.
- Cofniecie resetu; odczyt z dysku godzin, notatki, profilu i aktywnego startu.
- Zerowy poziomy scroll, brak zmiany miesiaca po jednym syntetycznym swipe.
- Widok roku wlacza mozliwosc przewijania pionowego.

## Dodatkowe obserwacje i decyzje

1. **Licznik nie jest kalkulatorem zgodnosci z przepisami.** Kod ma stale 15h i 9h
   (`TEST_WORK_LIMIT_SECONDS`, `TEST_REST_AFTER_WORK_SECONDS`, linie 65-66).
   Po wybraniu pauzy 11h gorny opis nadal przewiduje 9h od konca pelnych 15h.
   Zakonczenie pracy zeruje `pause_start_unix`, nie rozpoczyna automatycznie pauzy.
   Czas od startu do konca jest zapisywany w calosci; brak rejestru jazdy,
   innej pracy, przerw i dyspozycji. Wersja 1.0 powinna uczciwie opisywac
   mierzony czas i planowana pauze. Pelny kalkulator regul to osobny zakres.
   Zrodla KE rozrozniaja czas jazdy i pracy oraz warunkowe skrocenia odpoczynku;
   stale 15h/9h nie wystarczaja do oceny legalnosci dalszej jazdy.

2. **Zmiana nocna i miesieczne podsumowania.** Rzeczywiste wywolanie zapisu
   dla 30.09 22:00 do 01.10 06:00 daje 8h we wrzesniu i 0h w pazdzierniku
   (`_save_worked_seconds_for_day`, linia 4520). To moze byc zamierzona
   ewidencja wedlug dnia rozpoczecia. Przed sprzedaza trzeba wybrac i opisac
   regule; przy liczeniu godzin kalendarzowych potrzebny jest podzial o polnocy.

3. **Dane i awarie.** Kod zapisuje wszystko do jednego ConfigFile, bez kopii
   zapasowej, wersji formatu i eksportu/importu. Nie symulowano uszkodzenia
   podczas zapisu ani odzyskiwania telefonu. Przenoszenie danych powinno byc
   gotowe przed platna premiera. W samych skryptach nie ma komunikacji sieciowej;
   kompletny audyt prywatnosci wymaga zbadania docelowej APK i jej zaleznosci.

4. **Polnoc, czas letni, podroz.** Dzisiaj jest odswiezane przy przebudowie
   kalendarza, nie przy kazdej zmianie daty w tle. Formatowanie starego/przyszlego
   znacznika uzywa aktualnego offsetu systemowego (`_system_utc_offset_seconds`,
   linia 4399). To ryzyko na zmianie czasu i strefy, wymagajace osobnych testow.
   Nie przetestowano realnej zmiany zegara, wznowienia ani alarmow w tle.

5. **Codzienna obsluga.** Kierowca po zmianie powinien szybko zobaczyc dzisiaj,
   zakonczyc lub skorygowac zmiane, sprawdzic powrot do domu i wyslac grafik
   rodzinie. Obecnie brak nazw wlasnych profili, eksportu i udostepniania.
   Pierwszy grafik wymaga wielu wejsc do okna dnia. Zachowac obecny wyglad,
   ale przetestowac utworzenie 2/2 i 6+24h+6+8 z osoba, ktora nie zna aplikacji.

6. **Marka i opakowanie.** Do publicznej wersji proponowana jest wlasna identyfikacja
   zamiast obecnego `Dasko / Always too late`. Jest to rekomendacja produktowa;
   nie zmieniono grafiki i nie oceniano praw do oznaczen.

## Kierunek zarabiania - hipoteza do sprawdzenia

Najbardziej konkretna wartosc: grafik kierowcy, dni w domu, wiarygodny miesiac
godzin i latwe przekazanie grafiku rodzinie. Ogolne kalendarze zmianowe juz
oferuja cykle, udostepnianie, kopie w chmurze i funkcje Pro; same kolorowe dni
nie potwierdzaja przewagi rynkowej. Przyklad: oficjalna karta Shift Work Calendar.

Propozycja pierwszego modelu: bezplatny podstawowy grafik i jednorazowe
odblokowanie Pro za eksport, rozbudowane zestawienia i dodatkowe grafiki.
Podstawowy bezpieczny zapis i odzyskiwanie danych powinny byc dostepne kazdemu.
Abonament rozpatrywac dopiero przy stalej usludze, np. synchronizacji.
To rekomendacja, nie prognoza przychodu ani potwierdzona gotowosc do zaplaty.

Walidacja: grupa kierowcow z roznymi systemami, najlepiej rowniez spoza znajomych;
pelny cykl pracy i domu; sprawdzic, czy sami wracaja do aplikacji, czy potrafia
zrobic grafik bez pomocy i za ktora funkcje faktycznie zaplaciliby. Nie zbierac
ich danych ani nie kontaktowac sie z nimi bez oddzielnego zlecenia uzytkownika.

## Droga do wydania

1. Male latki dla izolacji profili, ochrony aktywnych licznikow i wyniku zapisu.
2. Ustalic znaczenie profili, liczonych godzin i przyszlej pauzy; wdrozyc tylko
   uzgodniona regule. Testy maja mierzyc te regule, nie domysly agenta.
3. Mala latka przycisku profili, potem okna dnia i ukladu 6 rzedow.
4. Kopia zapasowa, odtwarzanie i eksport; test aktualizacji z istniejacymi danymi.
5. Powtarzalny eksport Android, testy na prawdziwych urzadzeniach i test zamkniety.
6. Dopiero po wynikach beta: platnosci, opis sklepu i publiczna premiera.

W repo nie znaleziono presetu eksportu Android, konfiguracji podpisanej wersji,
CI, implementacji platnosci ani polityki prywatnosci. Moga istniec poza repo;
ten audyt tego nie potwierdza. Nie przygotowano ani nie wyslano wersji do sklepu.

Na 25.09.2026 oficjalna dokumentacja Google wymaga dla nowych standardowych
aplikacji telefonu target API 36 (Android 16), od 31.08.2026. Test na Godot 4.4.1
nie dowodzi zgodnosci eksportowanej APK/AAB z tym wymaganiem. Trzeba sprawdzic
docelowy silnik, szablony eksportu, uprawnienia i podpisanie wydania.
Nowe osobiste konta deweloperskie utworzone po 13.11.2023 maja wymog testu
zamknietego z co najmniej 12 testerami zapisanymi nieprzerwanie przez 14 dni
przed wnioskiem o dostep do produkcji; nie ustalono, czy dotyczy konta uzytkownika.
Polityka prywatnosci i formularz Data safety sa wymagane takze dla aplikacji
bez zbierania danych (z wyjatkiem samego toru testow wewnetrznych).

## Zrodla zewnetrzne

Sprawdzone 25.09.2026; wymagania sklepu nalezy sprawdzic ponownie przed wysylka.

- KE, czas jazdy i odpoczynki: https://transport.ec.europa.eu/transport-modes/road/social-provisions/driving-time-and-rest-periods_en
- KE, czas pracy: https://transport.ec.europa.eu/transport-modes/road/social-provisions/working-time_en
- Google, target SDK: https://developer.android.com/google/play/requirements/target-sdk
- Google, wymagania testow: https://support.google.com/googleplay/android-developer/answer/14151465?hl=en
- Google, Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Godot, eksport Android 4.4: https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html
- Przyklad produktu porownawczego: https://play.google.com/store/apps/details?id=com.machai.shiftcal
