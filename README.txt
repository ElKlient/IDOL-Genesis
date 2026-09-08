IDOL Genesis 0.8.0 - SETTLEMENT FLOW

Prompt roboczy tej łatki:
Zbuduj pierwszy grywalny rdzeń osady epoki kamienia. Gracz jest Idolem: wolą osady, nie dowódcą armii. Ludzie mają samodzielnie dzielić robotę, nosić surowce, budować podstawowe budynki, odpoczywać, tworzyć pierwsze więzi i odkrywać proste technologie przez zadania.

Kierunek gry:
- gracz jest Idolem: wolą osady i bytem z pełną kontrolą nad populacją
- ludzie nie są wojskiem do szkolenia, tylko pierwszą społecznością
- później mają tworzyć pary, rozmnażać się, budować relacje, dzielić się na grupy i wchodzić w konflikty
- rozwój technologii wynika z prostych zadań, które Idol zleca mieszkańcom

Zmiany 0.8.0:
- po screenie z 0.7.9 kolejnym krokiem jest życie osady, nie menu: mieszkańcy dostają większe kręgi stanowisk
- punkty zgromadzenia, składu, odpoczynku, odkryć i budowy są rozstawiane stabilnie wokół celu
- dodano lekką separację między postaciami oraz wypychanie z centrum Idola i ogniska, żeby nie stali w jednej bryle
- cel łatki: mniej zbijania ludzi w kupę, czytelniejsze zadania i bardziej wiarygodny ruch osady

Zmiany 0.7.9:
- po screenie z 0.7.8 sprawdzono w Godocie realny kierunek kości ramion zamiast zgadywania wartości
- ręce dostały mocniejszą bazę w dół: idle, chód, wspólnota i praca mniej rozpychają sylwetkę na boki
- dzieci mają łagodniejszy wariant tej pozy, a prace zasobowe i budowa zachowują lekkie pochylenie do zadania

Zmiany 0.7.8:
- po kolejnym filmie naprawiono kolejność animacji: retargeter działa teraz manualnie i jest przesuwany przed proceduralną pozą
- proceduralna poza ma ostatnie słowo w klatce, więc animacja nóg nie powinna już ponownie podnosić ramion do T-pose
- wywołania retargetera dostają delta time z pętli gry, żeby chodzenie nadal było animowane mimo ręcznego trybu

Zmiany 0.7.7:
- po teście wideo z telefonu zmniejszono HUD i panele informacji, żeby kamera i animacje były lepiej widoczne na Androidzie
- gałki kamery są dalej wyraźne, ale mają dynamiczne pozycje zależne od viewportu i zajmują mniej sceny
- retargeter filtruje górę ciała po pełnej ścieżce tracka animacji, nie tylko po subnazwie kości
- mocniej uspokojono barki, ramiona i przedramiona przy chodzeniu, pracy, zbieraniu i bezczynności
- cel łatki: mniej manekinów z rękami w bok, więcej czytelnej osady pod palcami

Zmiany 0.7.6:
- retargeter wybiera teraz konkretne klipy: Walk_Carry, Farm_Harvest i TreeChopping zamiast pierwszej losowej animacji po fragmencie nazwy
- proceduralna warstwa kontroluje głowę, barki i ręce, a sprawny retarget zostawia nogom naturalniejszy ruch
- dodano drobną wariację pozy między mieszkańcami, żeby nie wyglądali jak identyczne manekiny
- osadnicy dostali prostą warstwę ubioru, paski, włosy/opaski i drobne dodatki bez dokładania ciężkich assetów
- scena ma większy teren, cienie, żywszą rzekę, trzciny, kępy traw, kwiaty, kamienne detale, lepszy Idol i obozowe rekwizyty
- zachowano rozdział I epoki kamienia: praca, pary, dzieci, budowa i kamera z poprzednich wersji

Zmiany 0.7.5:
- uruchomiono projekt w lokalnym Godot 4.7.2 headless i złapano ostrzeżenia retargetera w runtime
- naprawiono ścieżkę AnimationPlayera: animacje są mapowane względem postaci, a nie względem samego playera
- retargeter usuwa tory kości, których model nie posiada, zamiast zostawiać je jako nierozwiązywalne tracki
- tory palców są wycinane razem z górą ciała, żeby proceduralna poza spokojniej kontrolowała sylwetkę osadnika

Zmiany 0.7.4:
- po analizie filmu z telefonu poprawiono warstwę proceduralnej pozy osadników
- do cache kości dodano spine_03 oraz clavicle_l/clavicle_r, żeby resetować barki przed ustawianiem ramion
- górny tułów i obojczyki są teraz neutralizowane w każdej klatce pozy, co ogranicza ręce unoszone przez retargetowane animacje
- retargeter przepuszcza głównie ruch nóg, a górę ciała zostawia proceduralnej pozie osadników
- ramiona dorosłych i dzieci są opuszczane mocniej, a machanie rękami przy chodzie i pracy jest spokojniejsze
- łatka nie zmienia ekonomii, rodzin ani sterowania kamerą z 0.7.3

Zmiany 0.7.3:
- prawy panel rozkazów i mocy Idola jest teraz w dwóch kolumnach, żeby nie nachodził na prawą gałkę kamery
- skrócona wysokość menu na Androidzie: wszystkie przyciski zostają widoczne nad panelem poruszania
- proceduralna poza kości dostała późniejszy priorytet procesu, aby nadpisywać retargetowane animacje w tej samej klatce
- zmniejszono agresywność machania rękami i obniżono ramiona przy chodzie, pracy, zbieraniu, zgromadzeniu i bezczynności
- dzieci mają łagodniejszą pozę ramion, żeby wyglądały bardziej jak członkowie osady niż miniaturowi robotnicy

Zmiany 0.7.2:
- dodany pierwszy system rodziny i narodzin w osadzie
- pary mogą powiększyć populację, jeśli mają więź, wolne miejsce w domu i zapas 12 jagód
- dzieci są widocznymi mniejszymi postaciami, nie pracują jak dorośli i trzymają się rodziny
- dodany postęp Życia, licznik dorosłych/dzieci oraz stan rodziny w HUD
- dodana moc Idola KRĄG ŻYCIA, która wzmacnia pary i przyspiesza rozwój rodziny
- po narodzinach pojawia się mała kołyska jako znacznik nowego pokolenia
- dodane odkrycie RODZINA po pierwszym dziecku
- prawy panel rozkazów został zagęszczony, aby zmieścić moce nad gałką kamery
- po analizie filmów ponownie włączona bezpieczna proceduralna poza kości, aby ograniczyć efekt T-pose

Zmiany 0.7.1:
- dodany wybór mieszkańca dotykiem na ekranie gry
- wybrana osoba ma złoty znacznik pod nogami i panel od razu pokazuje jej stan
- dodane pierwsze moce Idola: KAMERA OS., PRZYWOŁAJ, BŁOGOSŁAW i WIĘŹ +
- Wola Idola regeneruje się w czasie i ogranicza spamowanie mocami
- PRZYWOŁAJ zdejmuje ładunek i kieruje osobę do kręgu wspólnoty
- BŁOGOSŁAW poprawia energię, głód, więź i odrobinę wiedzy wybranego mieszkańca
- WIĘŹ + wzmacnia relację wybranej osoby i może pomóc stworzyć pierwszą parę
- panel mieszkańca pokazuje teraz także aktualny ładunek

Zmiany 0.7.0:
- dodany pełniejszy obieg pracy: mieszkaniec idzie do źródła, zbiera, niesie widoczny ładunek i dopiero przy składzie zwiększa zasoby
- na mapie jest teraz skład osady z patykami, kamieniami, koszami jagód i znakiem
- dodane kamienie odkryć oraz rozkaz ODKRYCIA
- dodany cywilny budynek WARSZTAT 8/6, bez kierunku militarnego
- odkrycia: OGIEN, NARZEDZIA, MAGAZYN, WIEZI i OSADA
- dom i spichlerz nadal kosztują po 5 patyków i 5 kamieni
- mieszkańcy mogą odpoczywać przy domach, gdy energia spada
- zgromadzenie przy ognisku buduje więzi i może stworzyć pierwsze pary
- wybrany mieszkaniec pokazuje partnera, pracę, głód, energię i umiejętności
- dodane proste ubrania/rekwizyty osadników oraz widoczne ładunki patyków, kamieni i jagód
- HUD pokazuje pary, schronienie, pojemność składu, warsztaty, Tech i odkrycia
- dodany przycisk OSOBA + do szybkiego przełączania mieszkańca na Androidzie
- kamera nadal używa dwóch dużych gałek: lewa obrót, prawa poruszanie

Zmiany 0.6.10:
- po teście z telefonu wyłączono ryzykowną warstwę proceduralnego sterowania kośćmi
- zostaje bezpieczna animacja zastępcza całego ciała: chód, oddech, pochylenie przy pracy i ruch przy ognisku
- HUD i panel mieszkańca skrócono pod Androida

Kamera mobilna:
- lewa gałka = obrót kamery
- prawa gałka = poruszanie kamery po mapie
- 1 palec = naturalne przesuwanie mapy
- 2 palce rozsuń/zsuń = mocniejszy zoom
- 2 palce obracane względem siebie = naturalny obrót kamery

Następne kroki:
- pełna diagnostyka retargetowania animacji kości
- narodziny dzieci dopiero po stabilnym systemie par, potrzeb i schronienia
- bardziej czytelne wybieranie mieszkańców dotykiem
- rozkazy Idola jako drzewko odkryć technologicznych
- przyszłe podziały społeczne i konflikty dopiero po rozbudowie relacji
