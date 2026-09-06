IDOL Genesis 0.6.2 — RETARGET + CAMERA 2.0

Zmiany:
- jedna instancja UAL2 jako źródło animacji
- runtime retarget: ścieżki tracków animacji są przekierowywane do Skeleton3D każdego NPC
- Idle / Walk / Work wybierane z biblioteki po nazwach
- NIE tworzymy 10 kopii ciężkiego GLB
- ludzie zmniejszeni z 3.2 do 2.15 skali
- domy zwiększone z 0.7 do 1.05
- osada rozstawiona szerzej i czytelniej

Kamera mobilna:
- 1 palec = przesuwanie
- 2 palce rozsuń/zsuń = zoom
- 2 palce obracane względem siebie = obrót kamery wokół osady
- zakres zoomu ograniczony, żeby nie zgubić świata

Jeśli konkretna animacja nadal nie poruszy kośćmi, oznacza to różnice w nazwach/układzie
kości i następnym krokiem będzie stała mapa BoneMap między UAL2 i Base Characters.
Ta wersja testuje lżejszy runtime retarget bez ponownego zawieszania Androida.
