# Wspólny Kalendarz

Osobna aplikacja Godot, startowo oparta wizualnie na kafelkowym kalendarzu z projektu "Kalendarz Kierowcy". Główny tryb jest ogólny, ale kalkulator kierowcy zostaje jako opcjonalny moduł dla konkretnego kalendarza/profilu.

## Założenia

- pionowy kalendarz mobilny,
- 7 kafelków dni w rzędzie,
- interaktywne dni,
- użytkownik sam tworzy kategorie/oznaczenia,
- opcjonalny system kierowcy może automatycznie oznaczać praca/dom/24h,
- profile po prawej stronie jako lista kalendarzy,
- prywatne i grupowe kalendarze w tym samym UI,
- kod udostępniania jako przygotowanie pod późniejsze połączenie kilku urządzeń.

## Stan pierwszej wersji

- dane zapisują się lokalnie w `user://shared_calendar.cfg`,
- można przełączać kalendarze/profile,
- można utworzyć prywatny albo grupowy kalendarz,
- można dodać własną kategorię z kolorem,
- można włączyć opcjonalny system kierowcy i ustawić start, dni pracy, dni domu oraz pauzę 24h,
- kliknięcie dnia otwiera edycję oznaczeń i notatki,
- nawigacja miesięcy działa tylko przyciskami.

## Udostępnianie

W tej wersji jest model danych i kod udostępniania (`share_code`). Prawdziwe wspólne widzenie tego samego kalendarza na kilku telefonach wymaga kolejnego kroku: prostego backendu/synchronizacji, np. Firebase, Supabase albo własnego API.
