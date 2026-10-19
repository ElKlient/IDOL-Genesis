# Kontrakty integracji — 0.2.3

Godot 4.4+, Compatibility/OpenGL, typowany GDScript, polski interfejs.
Projekt jest samodzielny w `games/zelazny-swit`; nie ładuje starszego projektu
z korzenia repozytorium. Nie wymaga Blendera ani pobierania zasobów w runtime.

## Stan i zapis

`GameState` jest autoloadem. Sygnały: `changed`, `message(text: String)`.
Nowa gra zaczyna od 10 000 G, 10 mikstur i `training_sword`. Identyfikatory
`iron_sword`, `hunter_sword`, `dawn_sword`, `leather_armor`, `guard_armor`,
`dawn_armor` pozostają zgodne z zapisem schematu 1. Nowe nazwy i `set_name`
pochodzą z katalogu, nie z zapisanych kopii opisów.

Przedmiot: `{uid, id, kind, name, tier, upgrade, power, price, icon, color}`,
opcjonalnie `set_name`. `kind` to `weapon` lub `armor`. Katalog zawiera też
`consumable`. Główne API: `catalog()`, `definition(id)`, `find_item(uid)`,
`equipped(kind)`, `item_name(item)`, `item_power(item)`, `attack_power()`,
`defense()`, `max_health()`, `buy(id)`, `equip(uid)`, `use_potion()`,
`upgrade_cost(uid)`, `upgrade_chance(uid)`, `upgrade_item(uid)`,
`gain_reward(gold, xp)`, `damage(amount)`, `claim_quest()`, `quest_text()`.

Zapis `user://adventure_v1.json` jest atomowy, ma kopię `.bak`. `new_game()`
wywołuje wyłącznie świadomie potwierdzony reset. Aktualizacja grafiki nie
zmienia ekonomii, postępu ani plików prywatnej konfiguracji diagnostyki.

## Postać, modele i animacje

`Hero extends CharacterBody3D` (`scripts/player.gd`) udostępnia `move_input`,
`facing`, `dead`, `play_attack(combo, skill)`, `receive_hit()`, `reset_to(pos)`
oraz `set_equipment(weapon_tier, armor_tier, upgrade=0, armor_upgrade=0)`.
Przód modelu to −Z; wejście `(0, -1)` oznacza ruch w kierunku −Z świata przed
przeliczeniem przez kamerę. Fizyka i terminy obrażeń należą do kontrolera gry.

`CharacterVisual` steruje oddechem, biegiem, czterema cięciami, oburęcznym
slamem i ogniem. Publiczne stawy kontrolne są mapowane przez `WarriorModel`
na rzeczywisty szkielet 65 kości. Transformacja kości jest pełną transformacją
lokalną względem rodzica; nie należy ponownie mnożyć jej przez rest.
Siatki tkaniny korzystają z wag szkieletu; nie ma symulacji sukna ani osobnych
kości płaszcza. `cape` jest pustym węzłem zgodności.

`warrior.glb` wymaga wariantów `Armor0`–`Armor3`, `weapons.glb` — `Weapon0`–
`Weapon3`. Pięć kanonicznych plików `equipment_*.png` musi pozostać obok GLB.
Materiały atlasu mają normal mapę i wspólną mapę ORM: R=AO, G=roughness,
B=metallic. `BladeEquipmentAtlas` ma osobną maskę emisji. Zmienne materiały są
kopiowane raz na aktora; siatki, skin i tekstury są współdzielone z portretem.
Ulepszenie miecza i zbroi trafia do adaptera osobno.

`contact_pause(seconds)` zatrzymuje tylko zegar widocznej animacji, nigdy
`Engine.time_scale`, fizykę, cooldowny ani zegar obrażeń. `set_presentation_pose`
służy portretowi; atak i slam wyłączają tę pozę przed rozpoczęciem.

## Świat i przeciwnicy

Od 0.2.2 teren ma jeden shader mieszający istniejące materiały i mapę
`terrain_control.png`; igliwie wymaga `pine_spray.png`. Oba obrazy są
kanonicznymi źródłami i otrzymują współdzielone mipmapy przy wczytaniu.
`VillageWorld.set_low_quality` jest jedynym właścicielem przełączania cieni:
wypełnienie `CharacterSoftFill` zawsze pozostaje bez cieni, z maską 2.
Siatki `WarriorModel` mają warstwy 1+2, a kamery zachowują warstwę 1.
Nie dodawać ogólnego przełącznika włączającego cienie wszystkim światłom.

`VillageWorld extends Node3D` buduje świat na `_ready()`, udostępnia
`spawn_position`, `npc_positions`, `enemy_spawns` i `tick(delta)`. Ziemia ma
y=0; wioska jest przy początku układu, dzicz na północy (−Z). Przejścia do Miry,
Borna i północnej bramy muszą pozostać dostępne. Tekstury i materiały świata
są współdzielone; dachy mają osobne kolizje kamery. Zmiana jakości nie może
przełączać MSAA podczas rozgrywki.

`WildEnemy extends CharacterBody3D` otrzymuje `setup(type, target)` przed
dołączeniem do sceny; udostępnia `is_alive()`, `set_targeted(bool)` i
`take_damage(amount, critical=false, hit_direction=Vector3.ZERO, strike=1)`.
Sygnały: `struck_player(amount)`, `defeated(enemy)`, `damaged(amount, critical)`.
AI, odrzut i obrażenia pozostają niezależne od lokalnej wizualnej reakcji.
Respawn planuje kontroler główny po zakończeniu życia przeciwnika.

`HitEffect` przechowuje maksymalnie osiem kontaktów w trzech powtarzalnie
używanych partiach MultiMesh. Punkty kontaktu są zakotwiczone w świecie;
nie wolno tworzyć osobnego węzła/tweena dla każdej iskry. Dźwięk trafień ma
ograniczoną pulę głosów. Ambient WAV nie używa natywnej pętli — odtwarzanie
ponawia się odroczone po `finished`.

## Interfejs i podgląd

`GameHUD extends CanvasLayer` udostępnia `move_vector`, `attack_held`,
`modal_open` i sygnały akcji; `setup(hero)`, `set_context(text)`,
`set_target(name, hp, max_hp, level)`, `clear_target()`, `toast(text)`,
`open_panel(mode)`, `refresh()`. Tryby obejmują inventory/shop/forge/help/
settings/camera. Przy otwartym panelu główny kontroler blokuje walkę i ruch.

Interfejs bazowy to 1280×720 z rozszerzaniem proporcji. Dotyk joysticka i pola
kamery ma niezależnego właściciela palca. Drag & drop na kowadło tylko wybiera
przedmiot; koszt nalicza jawny, odroczony przycisk ulepszenia. Panel przebudowuje
się raz po zmianie stanu; zamknięcie lub zmiana wybranego UID anuluje starą akcję.

Portret `CharacterPreview` ma jeden zachowywany `SubViewport` 512². Widoczny
portret zgłasza render maksymalnie w 30 Hz; ukryty nie animuje i nie renderuje.
Współdzieli wyposażenie przez cztery parametry `set_equipment`, przechowuje
obrót i zoom oraz dziewięć przycisków: +, −, W LEWO, RESET, W PRAWO, POSTÓJ,
CIOS, BIEG, POZA. Przyciski nie mogą jednocześnie rozpoczynać przeciągania
modelu. Domyślny widok pokazuje całą postać; świadome przybliżenie służy detalom.
Własne małe statyczne niebo daje odbicia PBR bez dodatkowych cieni portretu.

## Izolowana weryfikacja

Testy wymagają `--test-isolated`; diagnostyka sieciowa i zapis postaci są wtedy
wyłączone. Test trwałości wymaga dodatkowo jawnego, jednorazowego
`XDG_DATA_HOME` oraz `--test-data-root`. Polecenia i zakres sprawdzania są
w `tests/README.md`. Rzeczywiste rendery OpenGL nie zastępują pomiaru FPS na
telefonie. Nie kopiować tokenów diagnostyki do testów ani repozytorium.

## Prowadzenie broni od 0.2.1

Od 0.2.3 `WeaponMotionProfile extends Resource` opisuje ułożenie rękojeści,
kierunek i obrót klingi, przesunięcie w biegu i amplitudy oddechu. Domyślny
`assets/warrior/sword_motion.tres` jest używany przez CharacterVisual
w świecie i portrecie. Zasoby profilu traktować jako niemutowalne dane;
do autorskich zmian tworzyć własną kopię. `set_motion_profile(profile)`
zwraca false dla złego typu, błędnych danych i podczas ataku, zachowując
dotychczasowy profil. Wybór wykonywać na etapie tworzenia aktora lub postoju.
Walidacja i normalizacja ograniczają ryzyko zerowego kierunku nadgarstka.

Ten kontrakt opisuje postawę, nie obrażenia ani gotowe animacje każdej broni.
Przyszłe cztery klasy mogą korzystać ze wspólnego interfejsu, ale długi miecz,
broń drzewcowa i dwa ostrza wymagają własnych torów i konfiguracji podpórki
drugiej dłoni. Nie używać indeksu tieru jako identyfikatora klasy/chwytu.

Zwykłe cięcia używają toru rękojeści i kwaternionów klingi; IK wyznacza ramię.
Pełny obrót startu/końca musi być zachowany, nie tylko kierunek ostrza.
Oburęczny cios wymaga wspólnego punktu osiągalnego przez oba ramiona i płynnego
dołączenia/zwolnienia dłoni. Polecenie ruchu nie może zmieniać `facing` podczas
zwykłego cięcia, ale zachowuje dotychczasowe przesuwanie postaci.
Opóźniony szum miecza .065/.14 s podlega temu samemu serialowi i blokadom
śmierci/panelu/respawnu co atak. Kontakty obrażeń nadal .16/.25 s.
