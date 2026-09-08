# IDOL Genesis - WORKFLOW FIRST

Ten plik czytaj jako pierwszy w kazdym nowym kontenerze. Dopiero potem otwieraj reszte repo.

## Zasada glowna

Nie tworz nowego projektu. Pracujesz na istniejacym repo:

- GitHub: `ElKlient/IDOL-Genesis`
- branch: `main`
- silnik: Godot 4.x
- platforma docelowa: Android / telefon uzytkownika / Termux

Po kazdym waznym odkryciu o workflow dopisz je do tego pliku albo do `docs/CONTAINER_HANDOFF_PROMPT.md` i zapisz na GitHubie, zeby nastepny kontener nie odkrywal tego samego od zera.

## Logi kontenerow

Kazdy kontener prowadzi wlasny log w:

- `docs/container_logs/CONTAINER_<LITERA>_LOG.md`

Kontener A w tej sesji zapisuje:

- `docs/container_logs/CONTAINER_A_LOG.md`

Log aktualizuj po waznym odkryciu, zmianie workflow, tescie Godota albo wypchnieciu commita. Minimum wpisu:

- rola kontenera,
- cel pracy,
- dotkniete pliki,
- commity wypchniete na GitHub,
- testy i wynik,
- blokery,
- nastepne kroki,
- komenda Termux przekazana uzytkownikowi.

## Instrukcje od Kontenera A

Kontener A moze zostawiac biezace zadania w:

- `docs/container_tasks/README.md`
- `docs/container_tasks/CONTAINER_B_TASK.md`
- `docs/container_tasks/CONTAINER_C_TASK.md`
- `docs/container_tasks/CONTAINER_D_TASK.md`
- `docs/container_tasks/CONTAINER_E_TASK.md`

Jesli jestes kontenerem B/C/D/E, sprawdz swoj plik zadania zaraz po przeczytaniu tego workflow.

Jesli jestes aktywny, zapauzowany albo czekasz na dalsza prace, sprawdzaj co 30 minut, czy Kontener A nie zostawil nowych instrukcji. Minimum: pobierz najnowszy `main`, przeczytaj ten plik, swoj plik zadania i swoj log.

Mozesz uruchamiac wlasnych subagentow do waskich zadan w swojej dziedzinie. Subagent nie powinien samodzielnie pchac zmian na `main`; glowny kontener odpowiada za decyzje, log, commit i push.

## Obowiazkowy raport po analizie

Jesli kontener dostal zadanie analizy albo pomocy przy grze, po zakonczeniu pierwszego przegladu musi dopisac raport do swojego logu:

- Kontener B: `docs/container_logs/CONTAINER_B_LOG.md`
- Kontener C: `docs/container_logs/CONTAINER_C_LOG.md`
- Kontener D: `docs/container_logs/CONTAINER_D_LOG.md`
- Kontener E: `docs/container_logs/CONTAINER_E_LOG.md`

Raport po analizie ma zawierac:

1. co kontener sprawdzil,
2. jakie pliki/funkcje sa wazne,
3. czy cos zmienil,
4. commit SHA, jesli wypchnal zmiany,
5. ryzyka i rzeczy do przetestowania,
6. co Kontener A ma zintegrowac, odrzucic albo zostawic na pozniej.

Po raporcie kontener ma zapisac log na GitHubie. Nie wystarczy odpowiedz w czacie, bo nastepny kontener musi widziec stan w repo.

Kolejnosc integracji przez Kontener A:

1. Kontener D - stabilnosc Android/Godot/import/build.
2. Kontener B - ludzie, chód, rece, osie kosci i bezpieczenstwo animacji.
3. Kontener C - assety, swiat, otoczenie i optymalizacja wizualna.
4. Kontener E - gameplay osady, zasoby, budynki, UI i zycie spoleczne.

Kontener A nie ma merge'owac na slepo. Ma najpierw przeczytac raport/log danego kontenera albo obejrzec jego commit.

## Kolejnosc czytania

1. `WORKFLOW_FIRST.md`
2. `docs/CONTAINER_HANDOFF_PROMPT.md`
3. `docs/CONTAINER_HANDOFF_WALK_AND_IMPORT.md`
4. `docs/NEXT_DEVELOPMENT_COORDINATION.md`
5. `project.godot`
6. `main.tscn`
7. `scripts/main.gd`
8. `scripts/retargeter.gd`
9. `assets/third_party_model_packs/README.md`

## Termux uzytkownika

Nie myl Termuxa na telefonie z terminalem kontenera Codex.

Aktywna sciezka projektu na telefonie:

- `/storage/emulated/0/IDOL-Genesis/IDOL-Genesis`
- w Termuxie czasem rownowaznie: `~/storage/shared/IDOL-Genesis/IDOL-Genesis`

Jedna komenda do zwyklego update z GitHuba w Termuxie:

```bash
cd /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git config --global --add safe.directory /storage/emulated/0/IDOL-Genesis/IDOL-Genesis && git stash push -m "backup przed update" && git pull origin main && git --no-pager log -5 --oneline
```

Nie podawaj `cd ~/IDOL-Genesis`; to wczesniej bylo bledne. Nie dodawaj `rm -rf .godot` przy zwyklym update. Nie uzywaj `git stash -u` przy zwyklym update, bo moze schowac cache/importy Godota.

Po update uzytkownik otwiera projekt w aplikacji Godot na Androidzie z folderu, ktory zawiera `project.godot`.

## Kontener Codex

Godot moze nie byc w PATH, ale byl juz znaleziony w scratchu. Sciezka moze zalezec od kontenera, wiec nie zakladaj jednej stalej lokalizacji.

Znane przyklady:

```bash
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64
/workspace/scratch/fca424588312/tools/godot/Godot_v4.7.2-stable_linux.x86_64
```

Jesli `command -v godot` i `command -v godot4` nic nie zwracaja, szukaj:

```bash
find /workspace/scratch -maxdepth 5 -type f -iname '*godot*'
```

Najpierw ustaw lokalna zmienna na dostepna binarke:

```bash
GODOT_BIN="$(command -v godot || command -v godot4 || find /workspace/scratch -maxdepth 5 -type f -iname 'Godot_v*-stable_linux.x86_64' | head -n 1)"
```

Na swiezym checkoutcie najpierw wymus import assetow:

```bash
"$GODOT_BIN" --headless --editor --path . --quit
```

Potem sprawdz runtime:

```bash
"$GODOT_BIN" --headless --path . --quit
```

Mozesz tez odpalic krotki test startu:

```bash
timeout 8s "$GODOT_BIN" --headless --path .
```

## GitHub i zapisywanie wiedzy

Zwykly `git push` z kontenera moze nie miec loginu HTTPS. Wtedy uzyj GitHub connectora albo Git data API z fast-forward guardem. Nigdy nie force-pushuj bez wyraznej prosby.

Przed przesunieciem `main` sprawdz, czy zdalny `main` nadal jest rodzicem lokalnego commita. Jesli remote ruszyl, najpierw `git fetch origin main`, potem rebase/merge bez nadpisywania pracy innych kontenerow.

Do repo zapisuj:

- zmiany kodu gry,
- dokumenty workflow,
- raporty dla kolejnych kontenerow,
- decyzje o assetach i testach.

Nie zapisuj automatem:

- `.godot/`
- `.import/`
- `*.import`
- przypadkowych `*.gd.uid`, jesli task nie dotyczy migracji UID,
- duzych paczek assetow bez selekcji i sensu dla Androida.

## Minimalny check przed koncem

```bash
git diff --check
```

Jesli zmieniasz kod/scenerie/importy, odpal Godota wedlug sekcji `Kontener Codex`.

## Aktualna baza gry

Aktualny kierunek: `0.8.22 Textured Climate` - lekka niskopoligonowa osada epoki kamienia / wczesnego sredniowiecza z Idolem, ludzmi, praca, zasobami, lowami, miesem, skorami, palisada, brama osady, slady przy sciezkach, przeprawa przez rzeke, narzedziami kamiennymi, jeleniami, aktywnymi malymi GLB rekwizytami i proceduralnie teksturowanym terenem.

Najnowsze passy Kontenera A polaczyly `0.8.19 Hunt and Hides`, `0.8.20 Living World`, `0.8.21 Living Camp Props` i `0.8.22 Textured Climate`: palisade/gate, podworka chat, legowiska, stosy drewna, przeprawe, slady stop, strefe obrobki skor, realne lekkie rekwizyty GLB, mgielke tła oraz teksturowane materialy ziemi, trawy, drewna, kamienia i wody. Kontenery B/C/D/E maja po pullu sprawdzic swoje pliki zadan w `docs/container_tasks/`.

Ludzie sa kluczowi. Nie wymieniaj modelu, szkieletu, retargetera ani proceduralnego chodu, jesli zadanie tego wprost nie dotyczy.
