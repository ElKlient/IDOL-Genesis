# Kalendarz Kierowcy

Prosty kalendarz dla kierowcow jezdzacych w systemach pracy typu 2/1, 2/2, 3/1 albo liczonych w dniach.

## MVP

- miesieczny kalendarz z kolorami:
  - czerwony: praca,
  - zielony: dom,
  - zolty obrys: dzisiaj,
- data startu w formacie `RRRR-MM-DD`,
- system liczony w tygodniach albo dniach,
- mozliwosc ustawienia, czy data startu oznacza prace czy dom,
- przewijanie miesiecy do przodu i do tylu,
- szybki przeskok o rok,
- licznik dni pracy i domu w aktualnym miesiacu.

## Android / Termux workflow

Po wrzuceniu projektu do GitHuba kierowca moze aktualizowac aplikacje tak samo jak projekt gry:

```bash
cd /storage/emulated/0/Godot/DriverShiftCalendar
git pull origin main
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
