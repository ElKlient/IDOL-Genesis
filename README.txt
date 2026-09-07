IDOL Genesis 0.6.6 — WORK SYNC TEST

Zmiany:
- łatka testowa Work -> GitHub -> Termux -> Godot
- HUD pokazuje 0.6.6 WORK SYNC TEST
- obok Idola dodany mały niebiesko-żółty marker synchronizacji
- dwa duże widoczne panele pod kciuki po lewej i prawej stronie ekranu
- lewa gałka obraca kamerę wokół osady
- prawa gałka przesuwa kamerę po mapie
- panel informacji przeniesiony spod prawego kciuka pod HUD
- sterowanie gestami nadal działa równolegle
- naturalne przesuwanie mapy jednym palcem: palec chwyta teren i przesuwa go pod sobą
- dwa palce: szerszy pinch zoom oraz naturalny obrót kamery wokół oglądanej osady
- większy zakres przybliżenia i oddalenia do wygodnego oglądania całej mapy
- mały biało-czerwony kwiatek obok Idola jako pamiątka pierwszego połączenia z GitHubem
- jedna instancja UAL2 jako źródło animacji
- runtime retarget: ścieżki tracków animacji są przekierowywane do Skeleton3D każdego NPC
- Idle / Walk / Work wybierane z biblioteki po nazwach
- NIE tworzymy 10 kopii ciężkiego GLB
- ludzie zmniejszeni z 3.2 do 2.15 skali
- domy zwiększone z 0.7 do 1.05
- osada rozstawiona szerzej i czytelniej

Kamera mobilna:
- lewa gałka = obrót kamery
- prawa gałka = poruszanie kamery po mapie
- 1 palec = naturalne przesuwanie mapy
- 2 palce rozsuń/zsuń = mocniejszy zoom
- 2 palce obracane względem siebie = naturalny obrót kamery
- zakres zoomu pozwala mocno przybliżyć postacie i oddalić widok na całą osadę

Jeśli konkretna animacja nadal nie poruszy kośćmi, oznacza to różnice w nazwach/układzie
kości i następnym krokiem będzie stała mapa BoneMap między UAL2 i Base Characters.
Ta wersja testuje lżejszy runtime retarget bez ponownego zawieszania Androida.
