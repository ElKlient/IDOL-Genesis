# Żelazny Świt — przekazanie projektu

## Cel i zgody

Użytkownik 18 października 2026 zlecił gotowy pierwszy grywalny wycinek mobilnego
ARPG w Godocie: wojownik, świat 3D, mała wioska, handlarz, trzy zbroje i różne
miecze, mikstury, kowal z przeciąganiem przedmiotu, 10 000 złota na start.
Ma móc pobrać kod przez Termuxa i kupić, ulepszyć oraz zabić pierwszego potwora.
Udzielił pełnej zgody na narzędzia i wykonanie/publikację tej gry. To oryginalna
gra inspirowana gatunkiem, bez zasobów Metin2.

Nowy projekt jest odseparowany od dotychczasowych aplikacji i gry:

- repo: `ElKlient/IDOL-Genesis` (dotychczasowe, publiczne);
- **osobna gałąź: `zelazny-swit`**, bez aktualizacji `main` i kalendarzy;
- katalog projektu: `games/zelazny-swit`;
- telefon: `/storage/emulated/0/Godot/ZelaznySwit/games/zelazny-swit`;
- Godot 4.4.1+; użytkownik ma edytor Godot na Androidzie;
- pakiet APK nie jest jeszcze przygotowany — ta wersja jest uruchamiana przez ▶ w Godocie.

## Architektura

- `project.godot`, `main.tscn`: wejście, landscape, Compatibility/OpenGL, Canvas Items.
- `scripts/main.gd`: scena, kamera śledząca, wejście, 3-cio ciosowe combo,
  opóźnienie trafienia, automatyczny najbliższy cel / wybór dotykiem, skill obszarowy,
  mikstury, NPC, nagrody i respawn.
- `scripts/game_state.gd`: autoload `GameState`, katalog, egzemplarze przedmiotów
  z UID, ekonomia, statystyki, zadanie i atomowy zapis JSON.
- `scripts/world.gd`: oryginalny świat budowany w kodzie; wspólne siatki dekoracji,
  wioska, targ, kuźnia, las, brama, staw, ruiny i 7 spawnów.
- `scripts/player.gd`, `character_visual.gd`: fizyka wojownika, animowane części
  ciała, ekwipunek zmieniający sylwetkę, miecz i zbroja 0–3, efekty ulepszenia.
- `scripts/enemy.gd`: wilk, dzik, Strażnik Korzeni; roaming, aggro, zapowiedź ataku,
  odskok/powrót do spawnu, leczenie po wyjściu ze strefy, śmierć.
- `scripts/audio.gd`: oryginalna synteza dźwięków i ambientu; dźwięk można wyłączyć.
- `ui/hud.gd` i pomocnicze skrypty: HUD, minimapa, multitouch, plecak, sklep,
  kowal z drag & drop oraz wyborem dotykowym, pomoc i przewijane ustawienia.
- `tests/`: testy uruchamiane bez grafiki i bez modyfikacji właściwego zapisu.

## Pętla gry

Nowa postać: 10 000 G, miecz rekruta, 10 mikstur. Mira (-6,0,0) sprzedaje
3 miecze i 3 zbroje oraz mikstury. Born (6,0,0) ulepsza sprzęt za złoto;
+1..+3:100%, +4:80%, +5:65%, +6:50%. Nieudane ulepszenie zachowuje przedmiot
oraz jego poziom, ale zużywa opłatę. Żelazny miecz:350 G; +1:180 G.
Po zakupie trzeba osobno założyć sprzęt w ekwipunku.

Za północną bramą (z=-14) są potwory. Normalny cios ma cooldown0.48s i windup0.16s.
Trzeci cios mocniejszy, 14% trafień krytycznych. Wir stali ma zasięg4.2m i cooldown7s.
PŻ i obrona zmieniają realne obrażenia. Śmierć wraca do wioski bez kar.
Potwory respawn18s, boss24s. Łupy w złocie/PD automatyczne, mikstura ma szansę wypaść.

Zadanie: kup miecz, wykonaj dowolne ulepszenie, zabij3 potwory i wróć do Miry
po1200G+5mikstur. Dalej cel: Strażnik Korzeni.

## Zapis

`user://adventure_v1.json` we własnym katalogu danych `ZelaznySwit`;
`.bak` poprzednia wersja, `.tmp` zapis tymczasowy, `.corrupt` zachowana uszkodzona wersja.
Zapis nie zawiera Color/resources: przedmioty są rekonstruowane po ID, UID i ulepszeniu.
Aktualizacje kodu nie usuwają danych. Nowy telefon wymaga osobnego przeniesienia zapisu.
Menu Nowa Gra wymaga osobnego potwierdzenia i resetuje tę przygodę.

## Uruchamianie i aktualizacje

Pełny gotowy blok pierwszego pobrania jest w README tego projektu. Używa
`--filter=blob:none --sparse` i `git sparse-checkout set games/zelazny-swit`, aby
nie pobierać paczek starszej gry. W Godocie trzeba importować dokładnie
`games/zelazny-swit/project.godot`.

Aktualizacja po zamknięciu projektu:

```bash
cd /storage/emulated/0/Godot/ZelaznySwit && git pull --ff-only origin zelazny-swit && git --no-pager log -1 --oneline
```

Nie usuwaj `.godot`, nie stosuj `reset --hard`, nie zmieniaj gałęzi na `main`.
Przy zablokowaniu przez lokalne zmiany sprawdź status i zachowaj kopię ustawień.

## Zakres i ograniczenia

To pierwsza grywalna lokalna wersja, nie pełne MMORPG. Brak sieci, innych klas,
rozległych map i kampanii. Grafika jest celowo oryginalna i stylizowana; wszystkie
modele, ikony i dźwięki generuje kod, bez zewnętrznych paczek i importu Blendera.
Fizyczny telefon użytkownika nie był zdalnie dostępny; potwierdzenie Androida
wymaga uruchomienia na telefonie po pobraniu.

## Weryfikacja

Weryfikacja wykonana w Godocie 4.4.1 na Linuxie: **87 sprawdzeń zaliczonych**
(integracja51, interfejs17, zapis19). Test nowej gry potwierdza również
odtworzenie pełnej sceny, świeżych potworów, cooldownów i startowego ekwipunku.

- import projektu w edytorze i zwykły runtime headless bez błędów;
- test integracyjny pełnej sceny: początkowe10k, zakupy/wyposażenie, ekonomia
  kowala, potki, zablokowanie walki w panelach, rzeczywiste zdarzenia joysticka,
  dojście przez fizykę do obu NPC oraz przez północną bramę, zabicie3wilków
  normalnymi atakami i otrzymanie nagród/poziomu/zadania;
- test interfejsu z prawdziwymi kliknięciami i przeciąganiem do kowadła:
  zakup, założenie, drop bez opłaty, przycisk ulepszenia z pojedynczą opłatą;
- test zapisu w jednorazowym katalogu XDG: roundtrip wszystkich danych,
  rekonstrukcja wyposażenia, odzyskanie kopii po uszkodzonym JSON,
  odrzucanie błędnych typów/liczb i duplikatówUID;
- render prawdziwym rendererem OpenGL/Mesa w Xvfb:1280×720 oraz1600×720;
  obejrzane ekrany wioski, sklepu, kowala, plecaka i walki; skorygowane
  prześwietlenie oświetlenia, sprawdzone ramki i czytelność paneli;
- brak testu fizycznego Androida — nie deklaruj potwierdzonego działania
  na konkretnym telefonie ani potwierdzonej wydajności mobilnej.

Przykładowe polecenia w środowisku z desktopowym Godotem:

```bash
godot --headless --editor --path games/zelazny-swit --quit
godot --headless --path games/zelazny-swit --script res://tests/integration.gd -- --test-isolated
godot --headless --path games/zelazny-swit --script res://tests/ui_flow.gd -- --test-isolated
XDG_DATA_HOME=/tmp/zelazny-qa godot --headless --path games/zelazny-swit --script res://tests/persistence.gd -- --test-isolated --test-data-root=/tmp/zelazny-qa
```

Nie uruchamiaj testu trwałego zapisu bez jawnego jednorazowego katalogu. Testy
UI/integracji wyłączają zapisy, a test trwałości dodatkowo odmawia uruchomienia,
jeśli rzeczywisty katalogdanych nie mieści się w podanym katalogu testowym.
