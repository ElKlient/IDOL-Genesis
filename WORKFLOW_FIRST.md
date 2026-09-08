# IDOL Genesis - WORKFLOW FIRST

Ten plik czytaj jako pierwszy w kazdym nowym kontenerze. Dopiero potem otwieraj reszte repo.

## Zasada glowna

Nie tworz nowego projektu. Pracujesz na istniejacym repo:

- GitHub: `ElKlient/IDOL-Genesis`
- branch: `main`
- silnik: Godot 4.x
- platforma docelowa: Android / telefon uzytkownika / Termux

Po kazdym waznym odkryciu o workflow dopisz je do tego pliku albo do `docs/CONTAINER_HANDOFF_PROMPT.md` i zapisz na GitHubie, zeby nastepny kontener nie odkrywal tego samego od zera.

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

Godot moze nie byc w PATH, ale byl juz znaleziony w scratchu:

```bash
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64
```

Jesli `command -v godot` i `command -v godot4` nic nie zwracaja, szukaj:

```bash
find /workspace/scratch -maxdepth 5 -type f -iname '*godot*'
```

Na swiezym checkoutcie najpierw wymus import assetow:

```bash
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit
```

Potem sprawdz runtime:

```bash
/workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --quit
```

Mozesz tez odpalic krotki test startu:

```bash
timeout 8s /workspace/scratch/ad3cb27c6389/tools/godot/Godot_v4.7.2-stable_linux.x86_64 --headless --path .
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

Aktualny kierunek: `0.8.18 Ancient Settlement` - lekka niskopoligonowa osada epoki kamienia / wczesnego sredniowiecza z Idolem, ludzmi, praca, zasobami, skorami, narzedziami kamiennymi, jeleniami i zapowiedzia pozniejszej stali.

Ludzie sa kluczowi. Nie wymieniaj modelu, szkieletu, retargetera ani proceduralnego chodu, jesli zadanie tego wprost nie dotyczy.
