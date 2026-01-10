# Testni Slučajevi: Ponašanje Widgeta na Mobilnim Preglednicima

Ovaj dokument definira testne slučajeve za provjeru funkcionalnosti zumiranja i skrolanja BookBed widgeta na različitim mobilnim preglednicima.

## Ciljevi Testiranja

-   Osigurati dosljedno i ispravno ponašanje "pinch-to-zoom" geste.
-   Provjeriti da skrolanje unutar widgeta (kada je sadržaj veći od ekrana) radi ispravno.
-   Potvrditi da nema vizualnih grešaka ili problema s layoutom specifičnih za pojedine preglednike.
-   Provjeriti da interakcija s kalendarom i formom za unos radi bez problema.

## Testni Uređaji i Preglednici

| Platforma | Preglednik | Uređaj (Primjer) |
| :--- | :--- | :--- |
| **iOS** | Safari (najnovija verzija) | iPhone (različite veličine), iPad |
| **Android** | Chrome (najnovija verzija) | Telefon (npr. Samsung, Pixel), Tablet |
| **Android** | Samsung Internet | Samsung telefon |
| **Android** | Firefox Mobile | Bilo koji Android telefon |

## Testni Scenariji

| Scenarij | Opis | Očekivano Ponašanje |
| :--- | :--- | :--- |
| **MB-01** | **Pinch-to-Zoom Gesta** | Korisnik može s dva prsta zumirati prikaz widgeta. Zumiranje mora biti glatko. Minimalni zoom je 100% (ne može se smanjiti), maksimalni je 300%. |
| **MB-02** | **Skrolanje bez Zuma** | Ako widget nije zumiran (`scale = 1.0`), skrolanje s jednim prstom mora raditi vertikalno (ako je sadržaj viši od ekrana). Ne smije biti horizontalnog skrolanja. |
| **MB-03** | **Pan (pomicanje) sa Zumom** | Kada je widget zumiran (`scale > 1.0`), korisnik može s jednim prstom pomicati prikaz (pan) u svim smjerovima. |
| **MB-04** | **Interakcija s Kalendarom** | Odabir datuma u kalendaru mora raditi ispravno i dok je widget zumiran i dok nije. Nema konflikta između geste za odabir datuma i geste za pomicanje/zumiranje. |
| **MB-05** | **Unos u Formu** | Klik na polje za unos (npr. ime, email) mora ispravno otvoriti tipkovnicu. Prikaz se treba prilagoditi tako da je polje za unos vidljivo. Zumiranje i pomicanje moraju i dalje raditi dok je tipkovnica otvorena. |
| **MB-06** | **Promjena Orijentacije (Rotation)** | Kada korisnik rotira uređaj iz portretnog u pejzažni način (i obrnuto), layout widgeta se mora ispravno prilagoditi. Stanje (odabrani datumi, uneseni tekst) mora biti sačuvano. |
| **MB-07** | **Prikaz Poruke za Zumiranje** | Na "legacy" stranici, poruka "Pinch to zoom" mora biti vidljiva na dnu ekrana i mora se moći odbaciti klikom na 'X'. |

## Bilješke za Testere

-   Posebno obratite pažnju na ponašanje na iOS Safariju, jer on ponekad ima specifična pravila za `iframe` i geste.
-   Provjerite kako se widget ponaša kada je ugrađen na stranicu koja već ima svoje geste za zumiranje. Ne bi smjelo doći do konflikta.
-   Uvjerite se da su performanse glatke, bez trzanja ili kašnjenja prilikom zumiranja i skrolanja.
