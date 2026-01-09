# Testni Slučajevi: Ponašanje Widgeta na Različitim Razinama Zuma

Ovaj dokument opisuje kako bi se BookBed widget trebao ponašati i izgledati na različitim razinama zumiranja, kako putem "pinch-to-zoom" geste tako i putem zoom kontrola u pregledniku.

## Ciljevi Testiranja

-   Osigurati da layout ostaje čitljiv i funkcionalan na svim podržanim razinama zuma.
-   Provjeriti da nema vizualnih grešaka, preklapanja elemenata ili "bježanja" sadržaja izvan vidljivog područja.
-   Potvrditi da su svi interaktivni elementi (gumbi, polja za unos, dani u kalendaru) i dalje upotrebljivi.

## Razine Zuma za Testiranje

Ove testove treba provesti koristeći "pinch-to-zoom" na mobilnim uređajima i `Ctrl + / -` (ili `Cmd + / -`) na desktop preglednicima.

| Scenarij | Razina Zuma | Očekivano Ponašanje |
| :--- | :--- | :--- |
| **ZL-01** | **100% (Normalno)** | Widget se prikazuje u svojem zadanom, responzivnom layoutu. Svi elementi su oštri i čitljivi. Skrolanje s jednim prstom je omogućeno, pomicanje (pan) je onemogućeno. |
| **ZL-02** | **125%** | Svi elementi su proporcionalno uvećani. Tekst ostaje oštar. Nema preklapanja. Ako sadržaj postane širi ili viši od vidljivog područja, pomicanje (pan) u svim smjerovima mora biti omogućeno. |
| **ZL-03** | **150%** | Svi elementi su proporcionalno uvećani. Layout ostaje konzistentan. Interaktivni elementi (gumbi, dani) su lakši za pritisnuti. |
| **ZL-04** | **200%** | Značajno uvećanje. Tekst mora ostati čitljiv, bez pikselizacije. Korisnik može pomicati (pan) prikaz kako bi vidio sve dijelove widgeta. |
| **ZL-05** | **300% (Maksimalno)** | Maksimalno podržano uvećanje. Prikaz je vrlo velik, ali i dalje oštar. Pomicanje (pan) je ključno za navigaciju i mora raditi glatko. |
| **ZL-06** | **< 100% (Smanjivanje)** | Widget ne bi smio dopustiti smanjivanje ispod 100% (`minScale: 1.0`). Gesta za smanjivanje ne bi trebala imati efekta ili bi trebala imati "bounce" efekt koji vraća na 100%. |
| **ZL-07** | **Brzo Zumiranje (In/Out)** | Brzo i uzastopno zumiranje i odzumiranje ne bi smjelo uzrokovati rušenje aplikacije, vizualne greške ili "zaglavljivanje" na nekoj razini zuma. |
| **ZL-08** | **Dvostruki Dodir (Double Tap)** | Iako nije eksplicitno implementirano kao dio `InteractiveViewer`-a, treba provjeriti ponašanje. Očekivano je da se ili ne dogodi ništa, ili da preglednik pokuša zumirati. Ponašanje treba biti konzistentno i ne smije "razbiti" widget. |

## Bilješke za Testere

-   Testirajte na `MonthCalendarWidget` i `YearCalendarWidget` jer imaju najkompleksnije layoute.
-   Provjerite kako se ponaša `BookingPillBar` (skočni prozor za rezervaciju) kada se otvori na različitim razinama zuma.
-   Obratite pažnju na rubove widgeta prilikom pomicanja (pan) na maksimalnom zumu. Sadržaj ne bi smio "bježati" beskonačno.
