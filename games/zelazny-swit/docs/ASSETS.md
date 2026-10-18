# Pochodzenie zasobów — 0.2.0

Żelazny Świt używa modelu człowieka animowanego szkieletem, autorskiego wyposażenia
przygotowanego w Blenderze oraz własnego świata i efektów. Poniższy opis dotyczy
zasobów ładowanych przez niezależny projekt `games/zelazny-swit`.

| Zasób | Pochodzenie i przygotowanie |
| --- | --- |
| Ciało, oczy, brwi i źródłowe włosy wojownika | Darmowy **Quaternius Universal Base Characters — Standard**, CC0. Zmieniono pozę wiążącą, wagi, ukrytą geometrię, skalę, kierunek oraz materiały. |
| Trzy rodziny pancerzy i cztery miecze, łącznie z bronią startową | Oryginalne modele projektu tworzone przez `assets/warrior/build_warrior_hd.py` i `build_weapons_hd.py`. |
| Materiały wyposażenia | Oryginalne mapy PBR generowane przez `assets/warrior/equipment_materials.py`; współdzielony atlas z pięciu kanonicznych PNG. |
| Siedem ikon wyposażenia | Rzeczywiste rendery gotowych modeli GLB w Blenderze: cztery miecze i trzy pancerze. Generator: `assets/warrior/render_item_icons.py`. |
| Wioska, teren, dekoracje, roślinność i potwory | Własna geometria projektu, budowana i łączona w Godocie. |
| Materiały otoczenia | Osiem oryginalnych par albedo/normal: ziemia, trawa, kamień, tynk, drewno, dachówka, tkanina i bruk. Generator: `assets/world/build_materials.py`. |
| Animacje, ogień, smugi, trafienia i pozostałe efekty | Kod projektu; bez pobieranych animacji, paczek efektów lub dodatków wymaganych do uruchomienia gry. |
| Interfejs i pozostałe ikony | Rysowanie w Godocie i własne elementy projektu; ikony wyposażenia korzystają z renderów opisanych wyżej. |
| Dźwięki i ambient | Oryginalna synteza PCM w `scripts/audio.gd`. |
| Domyślna czcionka interfejsu | Zasób dystrybuowany z Godotem, zgodnie z licencjami dystrybucji silnika. |

Szczegółowe dane źródłowej postaci, hashe pobranego pakietu i polecenia
odtworzenia są w [CREDITS.md](../assets/warrior/CREDITS.md). Oryginalna
informacja licencyjna autora jest zachowana bez zmian w
[QUATERNIUS-LICENSE.txt](../assets/warrior/QUATERNIUS-LICENSE.txt).
Dołączono zasoby darmowej wersji Standard; projekt nie zakłada dostępu do
płatnych modeli Regular/Teen ani płatnych plików źródłowych Blendera.

## Pliki wymagane przez gotowy model

`warrior.glb` oraz `weapons.glb` współdzielą tekstury poprzez lokalne odwołania
w glTF. Razem z nimi, w `assets/warrior`, muszą pozostać:

- `equipment_color.png` — kolor atlasu;
- `equipment_normal.png` — normalne w przestrzeni stycznej;
- `equipment_orm.png` — okluzja w R, chropowatość w G, metaliczność w B;
- `equipment_emission.png` — akcenty jadeitu i żaru;
- `equipment_blade_emission.png` — maska poświaty ulepszonej klingi.

Tekstury ciała i włosów pozostają osadzone w GLB. Pięciu plików atlasu nie
należy zastępować kopiami wyodrębnionymi przez import Godota ani przenosić
samych modeli bez ich zależności. Ikony gotowych przedmiotów są w
`assets/warrior/icons`; pokazują ten sam sprzęt co gra. W ikonach pancerzy
pomija się głowę i osobne części kończyn, aby napierśnik i naramienniki były
czytelne w małym polu ekwipunku.

## Odtwarzanie zasobów

Bieżąca ścieżka przygotowania modeli to skrypty z przyrostkiem `_hd.py`.
`build_warrior.py` i `build_weapons.py` zachowują historyczny etap 0.1.8;
nie służą do odtwarzania obecnego wyglądu. Dokładne polecenia Blendera,
wymagane ścieżki źródeł i opcjonalne rendery opisuje
[instrukcja postaci](../assets/warrior/CREDITS.md).

Tekstury świata można odtworzyć z katalogu projektu przez:

```bash
python assets/world/build_materials.py
```

Ten generator autorski wymaga NumPy i Pillow. Opis materiałów świata:
[assets/world/CREDITS.md](../assets/world/CREDITS.md).

Blender, NumPy, Pillow, pobrany pakiet źródłowy i powyższe generatory służą
wyłącznie do przygotowania zasobów. Telefon uruchamia gotowe GLB, PNG
i kod Godota offline; gra nie pobiera modeli ani tekstur przy starcie.
Opcjonalna prywatna diagnostyka ma odrębną konfigurację i nie dostarcza
zasobów gry.

Projekt korzysta z ogólnego języka wizualnego i mechanik gatunku azjatyckiego
ARPG. Nie zawiera modeli, tekstur, animacji, kodu ani map wyciągniętych z
Metin2. Autorskie zbroje, miecze, materiały i świat nie są objęte deklaracją
CC0 autora ludzkiej bazy. Plansze koncepcyjne przedstawiają kierunek prac;
nie zastępują modeli ani zrzutów działającej gry. Zasoby dawnych projektów
z pozostałych katalogów repo nie są ładowane przez tę grę.
