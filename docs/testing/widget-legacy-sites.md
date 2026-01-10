# Testni Slučajevi: Widget na Starijim (Legacy) Web Stranicama

Ovaj dokument opisuje testne slučajeve za provjeru ponašanja BookBed widgeta kada je ugrađen na starije, neresponzivne web stranice.

## Ciljevi Testiranja

-   Osigurati da je widget upotrebljiv i čitljiv.
-   Provjeriti ispravnost detekcije "legacy" stranica.
-   Provjeriti funkcionalnost zumiranja i skrolanja.
-   Potvrditi da se poruka za zumiranje ispravno prikazuje.

## Testni Scenariji

| Scenarij | Opis | Očekivano Ponašanje |
| :--- | :--- | :--- |
| **LS-01** | **Stranica bez `meta viewport` taga** | Widget bi trebao detektirati da se radi o "legacy" stranici. Poruka "Pinch to zoom" bi se trebala pojaviti. Pinch-to-zoom unutar widgeta mora raditi. Roditeljska stranica se treba moći skrolati. |
| **LS-02** | **Stranica s fiksnom širinom (npr. `width: 960px`)** | Ponašanje bi trebalo biti isto kao u LS-01. Widget se treba ispravno prikazati unutar spremnika fiksne širine. |
| **LS-03** | **Stranica s layoutom baziranim na tablicama (`<table>`)** | Widget ugrađen unutar `<td>` elementa. Ponašanje bi trebalo biti isto kao u LS-01. Widget se ne bi smio "razbiti" ili prelijevati izvan ćelije tablice. |
| **LS-04** | **Stranica s `overflow: hidden` na `body` ili `html` elementu** | Ako roditeljska stranica ima `overflow: hidden`, skrolanje neće raditi, ali to je očekivano ponašanje te stranice. Unutar widgeta, zumiranje i interakcija moraju ostati funkcionalni. Automatsko podešavanje visine iframea bi trebalo raditi, ali neće imati efekta ako je cijela stranica bez skrola. |
| **LS-05** | **Stranica s konfliktnim CSS-om** | Testirati s globalnim CSS pravilima na roditeljskoj stranici (npr. `* { box-sizing: content-box; }`). Widget, budući da je u iframeu, ne bi smio biti pogođen ovim pravilima. Njegov izgled mora ostati nepromijenjen. |
| **LS-06** | **Osnovni HTML bez ikakvog CSS-a** | Ponašanje bi trebalo biti isto kao u LS-01. Widget bi se trebao prikazati i funkcionirati ispravno. |

## Bilješke za Testere

-   Prilikom testiranja, obratite pažnju na konzolu preglednika za eventualne greške koje dolaze iz `iframe_resizer.js` ili samog widgeta.
-   Testirajte na stvarnim mobilnim uređajima (iOS i Android) kako biste provjerili "pinch-to-zoom" gestu.
-   Nakon što se poruka za zumiranje jednom odbaci, ne bi se smjela ponovno pojaviti na istoj stranici prilikom ponovnog učitavanja.
