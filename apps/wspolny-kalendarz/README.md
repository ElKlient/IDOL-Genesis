# Wspólny Kalendarz

Osobna aplikacja Godot, startowo oparta wizualnie na kafelkowym kalendarzu mobilnym. Główny tryb jest ogólny: użytkownik sam tworzy oznaczenia i może rozłożyć powtarzalny schemat na wiele lat.

## Założenia

- pionowy kalendarz mobilny,
- 7 kafelków dni w rzędzie,
- interaktywne dni,
- użytkownik sam tworzy kategorie/oznaczenia,
- powtarzalny schemat może automatycznie oznaczać np. praca/praca/wolne,
- profile po prawej stronie jako lista kalendarzy,
- prywatne i grupowe kalendarze w tym samym UI,
- kod udostępniania jako przygotowanie pod późniejsze połączenie kilku urządzeń.

## Stan pierwszej wersji

- dane zapisują się lokalnie w `user://shared_calendar.cfg`,
- można przełączać kalendarze/profile,
- można utworzyć prywatny albo grupowy kalendarz,
- można dodać własną kategorię z kolorem,
- można wpisać własny schemat po przecinku i zastosować go na kolejne lata,
- kliknięcie dnia otwiera edycję oznaczeń i notatki,
- nawigacja miesięcy działa tylko przyciskami.

## Udostępnianie

W tej wersji jest model danych i kod udostępniania (`share_code`). Prawdziwe wspólne widzenie tego samego kalendarza na kilku telefonach wymaga kolejnego kroku: prostego backendu/synchronizacji, np. Firebase, Supabase albo własnego API.
