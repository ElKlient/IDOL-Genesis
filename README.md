# Kalendarz Kierowcy

Prosty kalendarz dla kierowcow jezdzacych w systemach pracy typu 2/1, 2/2, 3/1 albo liczonych w dniach.

## MVP

- miesieczny kalendarz z kolorami:
  - czerwony: praca,
  - zielony: dom,
  - zolty: dojazd albo zjazd,
  - zloty: pauza 24h,
  - zolty obrys: dzisiaj,
- pionowy, przewijany uklad pod telefon,
- data startu w formacie `RRRR-MM-DD`,
- gotowe systemy: 2/1, 2/2, 3/1, 3/2, 4/1 oraz 6 dni + 24h + 6 dni,
- wlasny cykl klikany dzien po dniu,
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
