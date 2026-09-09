# Kalendarz Kierowcy

Prosty kalendarz dla kierowcow jezdzacych w systemach pracy typu 2/1, 2/2, 3/1 albo liczonych w dniach.

## MVP

- pionowy, kafelkowy kalendarz pod telefon:
  - siedem kafelkow w rzedzie, jak tydzien w kalendarzu,
  - kazdy dzien jest osobnym zaokraglonym kafelkiem z numerem i dniem tygodnia,
  - puste miejsca przed pierwszym dniem miesiaca sa niewidoczne,
  - start jest pusty, bez domyslnie wpisanego systemu,
  - tlo ma ciemny motyw drogi i ciezarowki,
- miesieczny kalendarz z lagodnymi kolorami:
  - czerwony: praca,
  - zielony: dom,
  - zolty: dojazd albo zjazd,
  - zloty: pauza 24h,
  - zolty obrys: dzisiaj,
- data startu wpisywana recznie albo wybierana kliknieciem dnia,
- gotowe systemy: 2/1, 2/2, 3/1, 3/2, 4/1 oraz 6 dni + 24h + 6 dni,
- wlasny cykl ustawiany kliknieciem dni w kalendarzu,
- duze przyciski po kliknieciu dnia: wyjazd/zjazd, praca, pauza 24h, dom, wyczysc, notatka,
- dojazd przed praca i zjazd po pracy,
- pauza 24h co 6 dni pracy,
- przewijanie miesiecy do przodu i do tylu,
- szybki przeskok o rok,
- widok miesiaca, kwartalu, 4 miesiecy albo calego roku,
- notatki po kliknieciu dnia,
- prosty licznik rozpoczecia i zakonczenia pracy z pauza 9h, 11h albo 24h.

## Android / Termux workflow

Projekt jest obecnie trzymany na osobnej galezi `driver-shift-calendar` w repo `ElKlient/IDOL-Genesis`, zeby mozna go bylo pobrac bez zakladania nowego repo:

```bash
cd /storage/emulated/0/Godot
git clone --depth 1 --branch driver-shift-calendar git@github.com:ElKlient/IDOL-Genesis.git DriverShiftCalendar
cd /storage/emulated/0/Godot/DriverShiftCalendar
git pull origin driver-shift-calendar
git --no-pager log -1 --oneline
```

Potem projekt otwierasz w Godot 4.x na Androidzie i uruchamiasz.

## Kolejne funkcje

- zapis wielu harmonogramow,
- urlopy i zamiany dni,
- eksport widoku jako obraz/PDF,
- eksport do kalendarza telefonu,
- powiadomienia przed wyjazdem i zjazdem,
- widok 3, 5 i 10 lat do przodu,
- udostepnianie grafiku drugiej osobie.
