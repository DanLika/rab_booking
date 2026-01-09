# Ugradnja Widgeta

Ugradnja BookBed widgeta na vašu web stranicu je jednostavna. Slijedite ove korake kako biste omogućili brz i responzivan sustav za rezervacije.

## 1. Osnovni HTML Kod

Zalijepite sljedeći HTML kod na mjesto gdje želite prikazati widget:

```html
<iframe
  id="bookbed-widget"
  src="https://view.bookbed.io/?unit=VAŠ_UNIT_ID"
  style="width: 100%; border: none;"
  scrolling="no">
</iframe>
```

**Važno:** Zamijenite `VAŠ_UNIT_ID` sa stvarnim ID-em vaše smještajne jedinice koji možete pronaći u BookBed administraciji.

## 2. JavaScript za Automatsko Podešavanje Visine

Kako bi se widget savršeno uklopio u vašu stranicu i izbjegli dvostruki scrollbarovi, dodajte sljedeći JavaScript kod na dno vaše stranice, odmah ispred `</body>` taga:

```html
<script>
  window.addEventListener('message', function(event) {
    // Važno: Provjerite izvor poruke radi sigurnosti
    if (event.origin !== 'https://view.bookbed.io') {
      return;
    }

    if (event.data && event.data.type === 'resize') {
      var iframe = document.getElementById('bookbed-widget');
      if (iframe) {
        iframe.style.height = event.data.height + 'px';
      }
    }
  });
</script>
```

Ovaj skript sluša poruke koje widget šalje i automatski podešava visinu `iframe` elementa kako bi odgovarala visini sadržaja widgeta.

## Optimalni Atributi Iframea

Za najbolje iskustvo, preporučujemo sljedeće atribute na vašem `iframe` elementu:

-   **`id="bookbed-widget"`**: Obavezno. Koristi se od strane JavaScripta za pronalaženje i podešavanje visine.
-   **`src`**: URL vašeg widgeta s ispravnim `unitId`.
-   **`style="width: 100%; border: none;"`**: Osigurava da se widget proteže cijelom širinom spremnika i nema nepotrebnih rubova.
-   **`scrolling="no"`**: Onemogućuje scrollbar unutar iframea, oslanjajući se na automatsko podešavanje visine.

Izbjegavajte postavljanje fiksne `height` vrijednosti u stilu, jer će je JavaScript automatski ažurirati.
