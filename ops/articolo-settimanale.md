# Articolo della settimana

Scrivi e prepara un nuovo articolo per il sito di Matteo Bertacca, osteopata con studio a Camaiore (Versilia).
Lavori da solo, senza nessuno a cui fare domande: se qualcosa non torna, fermati e scrivilo nel resoconto finale
invece di indovinare. Commit e push li fa lo script che ti ha lanciato, tu non usare git.
Per leggere e cercare nei file usa Read, Glob e Grep: i comandi shell sono permessi solo per
`node scripts/unsplash.mjs`, `npm run build` e `ls`.

## 1. Scegli l'argomento

- Apri `ops/argomenti.md` e prendi il primo argomento non spuntato (`- [ ]`).
- Leggi i titoli e le descrizioni degli articoli in `src/content/articoli/` per non ripetere un tema già trattato.
  Se l'argomento si sovrappone troppo a un articolo esistente, passa al successivo.
- Se la lista è vuota, scegli tu un argomento nuovo e utile a chi vive o passa le vacanze in Versilia, adatto
  alla stagione di oggi.

## 2. Scrivi l'articolo

Crea `src/content/articoli/<slug>.md`. Lo slug è in italiano, minuscolo, con trattini, senza accenti, e
contiene le parole che una persona cercherebbe su Google (per esempio `gomito-del-tennista-e-padel`).

Il frontmatter segue lo stesso schema degli altri articoli (vedi `src/content.config.ts`):

```yaml
---
title: "…"                    # chiaro, con la parola chiave, al massimo ~70 caratteri
description: "…"              # 140-160 caratteri, cosa trova chi legge
pubDate: AAAA-MM-GG           # la data di oggi
category: "…"                 # una delle 7 categorie dello schema
tags: [ … ]                   # 1-3 tag, riusa quelli già usati negli altri articoli quando possibile
related: [ a, b, c, d ]       # esattamente 4 slug di articoli esistenti, i più vicini per tema
---
```

Il testo:

- Scrivi in prima persona, come Matteo, dando del tu al lettore. Lunghezza simile agli altri articoli
  (900-1.200 parole), con 4-6 sezioni `##`.
- Il tono è sobrio e naturale, con esempi concreti. Niente frasi a effetto, slogan o domande retoriche a
  inizio paragrafo: Filippo le ha rifiutate perché «si capisce che sono scritte da un AI». Non usare la parola
  «toccare». Niente promesse di guarigione: l'osteopatia può aiutare, non cura tutto.
- Se fai un esempio, descrivi un caso tipico («Chi…», «Spesso vedo…»), non un paziente preciso con città
  ed età: sarebbe un caso inventato presentato come vero. Matteo è osteopata dal 2026, quindi non scrivere di
  pazienti seguiti per anni né di «tanti anni di studio».
- Includi sempre una sezione «Quando andare prima dal medico» con i segnali d'allarme veri dell'argomento,
  come negli altri articoli.
- Cita la Versilia in modo naturale (Camaiore, Lido di Camaiore, Viareggio, Pietrasanta, Forte dei Marmi,
  Massarosa, le Apuane, il mare, la stagione estiva) quando c'entra, senza forzare.
- Metti 2-4 link ad altri articoli dentro il testo, nel formato `[testo](../slug/)`.
- Chiudi con un paragrafo che ricorda che Matteo riceve a Camaiore e con il link
  `[prenotare una prima visita qui](../../#contatti)`.
- Non scrivere l'email di Matteo, il suo indirizzo, i suoi orari, prezzi o titoli che non sono in
  `src/site.ts`. La prima visita è gratuita: puoi dirlo nel
  paragrafo finale.

Rileggi tutto l'articolo una volta prima di andare avanti e togli le frasi che suonano artificiali.

## 3. Copertina da Unsplash

```
node scripts/unsplash.mjs search <slug> "<query in inglese>"
```

Apri il provino (`$COVER_DIR/<slug>/sheet.jpg`, il percorso esatto è stampato dal comando) con lo strumento
Read e guardalo. Scegli una foto luminosa, realistica, coerente con l'argomento e con lo stile delle altre
copertine: persone vere o luoghi, niente illustrazioni, scritte, loghi, modellini anatomici inquietanti o scene
mediche cruente. Poi:

```
node scripts/unsplash.mjs pick <slug> <numero> "<alt in italiano che descrive la foto>"
```

Se nessuna foto va bene, rifai `search` con un'altra query (al massimo 3 ricerche in tutto: l'API ha un limite
orario). Aggiungi la query scelta a `scripts/covers.json` (`"<slug>": "<query>"`), mantenendo il file JSON
valido.

## 4. Aggiorna la lista

In `ops/argomenti.md` spunta l'argomento usato e aggiungi lo slug in fondo alla riga, così:
`- [x] Titolo dell'argomento (Categoria) → <slug>`.
Se hai saltato argomenti perché già trattati, spuntali con `→ saltato: già coperto da <slug>`.

## 5. Controlla

- Esegui `npm run build`: deve finire senza errori. Se fallisce per l'articolo, correggilo e riprova.
- Non modificare altri file oltre a: il nuovo articolo, la sua copertina in `src/content/articoli/covers/`,
  `scripts/covers.json` e `ops/argomenti.md`. Lo script rifiuta il commit se tocchi altro.

## 6. Resoconto

Come ultima risposta scrivi solo, su righe separate:

```
SLUG: <slug>
TITOLO: <titolo>
COPERTINA: <autore Unsplash> · <url della foto>
NOTE: <dubbi da far vedere a Filippo o Matteo, oppure "nessuna">
```

Se non sei riuscito a completare l'articolo, scrivi `ERRORE: <motivo>` e non lasciare file a metà.
