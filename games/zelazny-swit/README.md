# Żelazny Świt — 0.1.0

Oryginalna, jednoosobowa gra akcji RPG 3D na telefon, napisana w Godocie 4.4+.
Sterowanie dotykowe w poziomie. Mały grywalny wycinek: wioska Brzeziny, wojownik,
handlarka Mira, kowal Born i dzicz z wilkami, dzikami oraz Strażnikiem Korzeni.

**Nowa postać zaczyna z 10 000 G, 10 miksturami i mieczem rekruta.**

## Pierwsze pobranie na telefon

Wklej w Termuxie (Termux, Git i Godot są już skonfigurowane):

```bash
mkdir -p /storage/emulated/0/Godot && cd /storage/emulated/0/Godot && git clone --depth 1 --filter=blob:none --sparse --single-branch --branch zelazny-swit https://github.com/ElKlient/IDOL-Genesis.git ZelaznySwit && git config --global --add safe.directory /storage/emulated/0/Godot/ZelaznySwit && cd ZelaznySwit && git sparse-checkout set games/zelazny-swit
```

W Godocie na Androidzie: **Importuj → wybierz**
`/storage/emulated/0/Godot/ZelaznySwit/games/zelazny-swit/project.godot`
**→ Importuj i edytuj → ▶**. Obróć telefon poziomo.

Gra jest osobnym projektem w osobnej gałęzi `zelazny-swit`.
Pozostałe projekty i gałąź `main` pozostają w dotychczasowym stanie.
Rzadkie pobranie (sparse checkout) ogranicza pobieranie plików do nowej gry.
Importuj dokładnie projekt wskazany powyżej; główny `project.godot` repo dotyczy starszej gry.

Jeżeli Android zgłosi brak dostępu do pamięci, uruchom `termux-setup-storage`,
udostępnij pliki i powtórz pobranie. Istniejącego folderu nie kasuj ani nie klonuj
ponownie — do aktualizacji służy następny blok.

## Pierwsze pięć minut

1. Lewym joystickiem idź do **Miry**, przy straganie po lewej stronie placu.
   Gdy zobaczysz przycisk „Mira • Handel”, naciśnij go.
2. Kup **Żelazny miecz (350 G)** albo lepszy. Kup także zbroję.
3. Otwórz plecak, wybierz przedmiot i załóż go. Broń oraz zbroja zmieniają wygląd postaci.
4. Idź do **Borna**, przy kuźni po prawej. Przeciągnij przedmiot z listy
   na pole kowala albo wybierz go dotknięciem. Zobacz koszt i naciśnij **Ulepsz**.
   Pierwsze ulepszenie żelaznego miecza kosztuje **180 G** i ma **100%** szans.
5. Wyjdź przez północną bramę. Podejdź do wilka i przytrzymaj przycisk ataku.
   Łupy i doświadczenie odbierasz automatycznie. Mikstura leczy 90 PŻ,
   a **Wir stali** uderza pobliskich wrogów i odnawia się przez 7 sekund.
6. Po kupnie miecza, dowolnym ulepszeniu i pokonaniu 3 potworów wróć do Miry
   po **1200 G i 5 mikstur**. Dalej na północy czeka silniejszy Strażnik Korzeni.

## Zasady

- 3 rodzaje mieczy i 3 zbroje; każdy przedmiot ma własny poziom ulepszenia.
- +1, +2, +3: **100%**; +4: **80%**; +5: **65%**; +6: **50%**.
- Nieudana próba zużywa tylko złoto. Przedmiot i dotychczasowy poziom zostają.
- Postać zdobywa poziomy, które zwiększają zdrowie i siłę. Awans odnawia zdrowie.
- Śmierć przenosi do wioski bez utraty złota ani ekwipunku.
- Potwory odradzają się po 18 s (Strażnik po 24 s).
- Zapis automatyczny po zakupie, zmianie sprzętu, ulepszeniu i łupach;
  również co 12 sekund oraz po przejściu aplikacji w tło.
- Zapis: `user://adventure_v1.json`, z kopią poprzedniej wersji `.bak`.
  Aktualizacja źródeł nie usuwa postępu. Dane edytora i eksportu APK mogą być odrębne.
- Gra działa offline. Nie zawiera zakupów, reklam, serwera ani cudzego kodu gry.

## Sterowanie

Telefon: lewy joystick; po prawej atak, umiejętność, mikstura i rozmowa w pobliżu NPC.
Dotknij przeciwnika, by wybrać cel. Przycisk plecaka otwiera przedmioty i statystyki.

Komputer: **WASD/strzałki** — ruch, **Spacja** — atak, **R** — Wir stali,
**Q** — mikstura, **E** — rozmowa, **I** — plecak, **Tab** — zmiana celu,
**Esc** — zamknięcie panelu. Android Wstecz zamyka panel lub otwiera ustawienia.

## Aktualizacja

Zamknij projekt w Godocie. W Termuxie:

```bash
cd /storage/emulated/0/Godot/ZelaznySwit && git pull --ff-only origin zelazny-swit && git --no-pager log -1 --oneline
```

Potem otwórz ten sam `games/zelazny-swit/project.godot` i naciśnij ▶.
Jeśli Godot lokalnie zmienił ustawienia, sprawdź `git status --short` i zachowaj
kopię `project.godot` przed pobraniem. Nie używaj resetowania ani usuwania folderu.

## Uruchamianie i zakres

- Godot **4.4.1** lub nowszy z obsługą GDScript; Compatibility / OpenGL.
- Projekt działa bez Blendera, pobierania paczek i instalowania dodatków.
- Świat, modele, animacje, ikony i dźwięki powstają z własnego kodu.
- Rozdzielczość bazowa 1280 × 720, poziomy ekran, interfejs skaluje się do telefonu.
- Jest to pierwsza grywalna wersja, a nie rozbudowane MMORPG: brak sieci, klas
  poza wojownikiem, rozległych map i pełnej kampanii.
- Udostępniony jest projekt do uruchomienia w Godocie, nie gotowy instalator APK.
- Test na fizycznym telefonie użytkownika wykonuje użytkownik po pobraniu.

Dokładny raport weryfikacji i informacje dla kolejnego agenta: [docs/STRESZCZENIE.md](docs/STRESZCZENIE.md).
