<div align="center">
<p align="center">
  <img src="../assets/banner.png" width="60%"/>
  <br>
</p>

**Un bellissimo gestore di download desktop multipiattaforma con analisi video basata su AI.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)]()


[English](https://github.com/TopLeon/KZDownloader/blob/main/README.md) &nbsp;•&nbsp; [Italiano](#italian)

</div>

---

> [!WARNING]
> **KZDownloader è attualmente in beta.** Potresti incontrare bug o funzionalità incomplete. Segnala eventuali problemi sull'[issue tracker](../../issues).

<a id="italian"></a>

## Panoramica

KZDownloader è un'applicazione desktop multipiattaforma realizzata con Flutter che permette di scaricare video, musica e file generici da centinaia di siti web. Integra un potente assistente AI in grado di riassumere i contenuti video di YouTube e rispondere a domande su di essi.

Il design è moderno, minimale e completamente reattivo, con bordi animati a gradiente neon sulle card di download e sugli elementi interattivi, transizioni fluide e feedback in tempo reale.

## ✨ Funzionalità

### 🎬 Download di Video e Audio
- Scarica video e audio da **YouTube** e centinaia di altre piattaforme grazie a [yt-dlp](https://github.com/yt-dlp/yt-dlp).
- Scegli **formato video** (MP4, MKV) e **qualità** prima del download.
- Scarica intere **playlist di YouTube** con concorrenza configurabile: ogni video viene tracciato individualmente.
- Estrazione solo audio in **MP3, M4A e OGG**.

### 📁 Downloader Generico
- Download **a chunk multipli** in stile IDM, estremamente veloce, per qualsiasi link HTTP/HTTPS diretto.
  - **Writer Isolate**: un isolate Dart dedicato scrive i dati direttamente nella posizione finale del file tramite `RandomAccessFile`, eliminando file temporanei e passaggi I/O ridondanti.
  - **Controllo del backpressure (ackIterator)**: ogni worker di rete attende la conferma di scrittura su disco da parte del Writer Isolate prima di scaricare altro, prevenendo crash per Out-of-Memory quando la velocità di rete supera quella di scrittura del disco.
  - **Dynamic Connection Reuse**: quando una connessione termina il proprio intervallo di byte, viene subito riassegnata al chunk più lento, mantenendo sempre il massimo numero di connessioni attive per una velocità di download costantemente al picco.
- **Ripresa automatica**: i download interrotti riprendono da dove si erano fermati se il server supporta le range request.
- Visualizzazione del progresso per ogni chunk con conteggio dei worker attivi e barre di avanzamento per segmento.
- Backend HTTP basato su Rust ([rhttp_plus](https://pub.dev/packages/rhttp_plus)) per la massima velocità e per il **TLS fingerprinting**, che aiuta ad aggirare i sistemi anti-bot su server protetti.

### 🤖 Riassunti Video e Chat
- Recupera automaticamente la **trascrizione** o la **descrizione** di un video YouTube e genera un riassunto strutturato tramite LLM.
- Poni **domande di follow-up** in una sessione di chat persistente legata al video: la cronologia Q&A viene salvata localmente.
- **Funzionalità AI 100% locali**: esegui l'intera analisi dei video e chatta offline con assoluta privacy.
- Supporto per più provider AI:
  - **Ollama** (completamente locale, nessun dato lascia il dispositivo)
  - **LM Studio** (completamente locale, server locale compatibile con OpenAI)
  - **OpenAI** (chiave API richiesta)
  - **Google Gemini** (chiave API richiesta)
- Output in streaming con rendering Markdown animato.
- Dimensione del contesto configurabile (numero massimo di caratteri inviati all'LLM).

### 🎵 Libreria Musicale e Player
- Scheda **Musica** dedicata con l'elenco di tutti i file audio scaricati.
- **Player audio** integrato con barra di avanzamento, play/pausa, avanti/indietro e seek.
- **Gestione playlist**: crea playlist con nome personalizzato e aggiungi le tracce.

### 🔒 Sicurezza e Integrità
- **Verifica checksum** (MD5, SHA-256) prima di avviare il download, per garantire l'integrità del file.
- Le chiavi API sono memorizzate nel **secure storage** del sistema operativo (keychain / credential manager).

### ⚙️ Impostazioni e Personalizzazione
- Selezione della **cartella di download** con onboarding al primo avvio.
- Preset predefiniti di **formato**, **qualità** e **formato audio**.
- Tema **Scuro / Chiaro / Sistema** con transizioni fluide.
- **Lingua dell'interfaccia**: Inglese e Italiano.
- Configurazione dei **download simultanei** per playlist e globali.
- Selezione del modello e del provider AI con gestione delle chiavi API.

### 🖥️ Esperienza Desktop
- Interfaccia divisa in sezioni dedicate: **Video**, **Musica** e **File generici** — ognuna con layout, ordinamento e ricerca propri.
- Design moderno, minimale e completamente reattivo con aggiornamenti di progresso in tempo reale.
- **Bordi neon animati** (`RainbowAnimatedBorder`) attorno alle card di download e agli elementi interattivi, renderizzati tramite un `CustomPainter` dedicato.
- Effetti glow glassmorphism sulla schermata iniziale e transizioni fluide nell'intera UI.
- Layout responsive con adattamenti separati per Windows/Linux e macOS.

## 🏗️ Architettura e Stack Tecnologico

| Livello | Tecnologia |
|---|---|
| Framework UI | Flutter 3.x + Material 3 |
| Gestione stato | flutter_riverpod + riverpod_annotation (code generation) |
| Database locale | isar_community |
| AI / LLM | langchain, langchain_ollama, langchain_openai, langchain_google |
| Client HTTP | rhttp_plus (FFI basato su Rust, TLS fingerprinting) |
| Metadati video | youtube_explode_dart + fallback yt-dlp |
| Riproduzione audio | just_audio + media_kit (Windows) |
| Secure storage | flutter_secure_storage |
| Font e icone | Google Fonts, ultimate_flutter_icons, not_static_icons |
| Localizzazione | Flutter Gen-l10n (file ARB) |

## 📦 Binari Esterni (scaricati automaticamente al primo avvio)

KZDownloader scarica e gestisce automaticamente i seguenti strumenti esterni nella directory di supporto dell'app: non è richiesta alcuna installazione manuale.

| Binario | Scopo |
|---|---|
| **yt-dlp** | Download video/audio ed estrazione dei metadati |
| **ffmpeg** | Post-processing, remuxing ed estrazione audio |
| **deno** | Necessario a ytdlp per l'estrazione dei dati |

## 🚀 Avvio Rapido

### ⬇️ Download

I binari precompilati per Windows e macOS sono disponibili direttamente nella sezione [**Releases**](../../releases) — nessun ambiente di build necessario.

> ⚠️ Utenti macOS: poiché l'app è attualmente autofirmata, Gatekeeper la bloccherà al primo avvio. Per eseguirla, fai clic con il pulsante destro del mouse sull'app, seleziona Apri, quindi fai nuovamente clic su Apri nella finestra di dialogo.

### Processo di Compilazione

#### Prerequisiti

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.2.0
- Dart SDK ≥ 3.2.0
- Target desktop configurato (`flutter config --enable-windows-desktop` / `--enable-macos-desktop` / `--enable-linux-desktop`)

#### Solo Linux

Se stai compilando questa applicazione Flutter su Linux (Ubuntu), devi configurare correttamente l'ambiente per evitare errori di build con i plugin nativi, come `rhttp_plus` e `flutter_secure_storage`.

##### 1. Evita Flutter tramite Snap

L'installazione di Flutter tramite Snap gira in un container isolato e può causare incompatibilità con `glibc` durante la compilazione delle dipendenze native Rust/C++.
Se hai installato Flutter tramite Snap, rimuovilo e usa invece il clone ufficiale del repository:

```bash
sudo snap remove flutter
git clone https://github.com/flutter/flutter.git -b stable ~/.flutter
export PATH="$PATH:$HOME/.flutter/bin"
```

##### 2. Installa le dipendenze di sistema richieste

Il progetto richiede strumenti di compilazione nativi, librerie GTK, Rust e l'API GNOME Secret Service. Installali con `apt` e `rustup`:

```bash
# Build tools, file di sviluppo GTK e header di Secret Service
sudo apt update
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev libsecret-1-dev

# Installa la toolchain Rust (necessaria per rhttp_plus)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Installa libmpv per media_kit
sudo apt install libmpv-dev mpv
```

### Clone e Avvio

```bash
# Clona il repository
git clone https://github.com/TopLeon/KZDownloader.git
cd KZDownloader

# Installa le dipendenze Flutter
flutter pub get

# Esegui la code generation (Isar + Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Avvia sulla tua piattaforma
flutter run -d windows   # oppure macos / linux
```

### Primo Avvio

Al primo avvio KZDownloader:
1. Chiederà di selezionare una **cartella di download predefinita**.
2. Scaricherà automaticamente **yt-dlp**, **ffmpeg** e **deno** in background.

Per le funzionalità AI, apri le **Impostazioni** e scegli un provider:
- **Ollama**: installa [Ollama](https://ollama.com) in locale e scarica un modello (ad esempio `ollama pull llama3`).
- **OpenAI / Google**: inserisci la tua chiave API nel pannello Impostazioni o al primo avvio: verrà salvata in modo sicuro nel keychain del sistema operativo.

## 📋 Piattaforme Supportate

| Piattaforma | Stato |
|---|---|
| Windows | ✅ Supporto completo |
| macOS | ✅ Supporto completo |
| Linux | ⚠️ Da testare |
| Android / iOS | ❌ Non supportato |

## 🗂️ Struttura del Progetto

```
lib/
├── main.dart                  # Entry point dell'app, schermata iniziale
├── core/
│   ├── download/
│   │   ├── logic/             # ChunkDownloader, IDMDownloader, YtDlpService
│   │   ├── providers/         # Provider Riverpod per i download
│   │   └── strategies/        # Strategie di download (IDM, yt-dlp, playlist, standard)
│   ├── providers/             # Provider per tema, locale e qualità
│   ├── services/              # DB, LLM, player audio, impostazioni, secure storage
│   ├── theme/                 # Temi Material 3 chiari/scuri
│   └── utils/                 # BinaryManager, ChecksumVerifier, FileUtils
├── models/                    # Modelli Isar (DownloadTask, Playlist)
├── views/
│   ├── chat/                  # UI principale: home, lista contenuti, musica, chat
│   ├── settings/              # Schermata impostazioni
│   └── widgets/               # Dialog e widget condivisi
└── l10n/arb/                  # Localizzazione (EN / IT)
```

## 🗺️ Roadmap

| Funzionalità | Stato |
|---|---|
| **Integrazione con il browser** — cattura i download direttamente da Chrome / Firefox tramite un'estensione companion | 🔜 Pianificata |

## ⚠️ Problemi Noti

- Il pannello dei dettagli delle playlist M3U8 presenta ancora alcuni bug visivi e imperfezioni.

## 🤝 Contribuire

Contributi, segnalazioni di bug e richieste di funzionalità sono benvenuti. Apri una issue o invia una pull request.

## 📄 Licenza

Questo progetto è distribuito con licenza **GNU General Public License v3.0 (GPL-3.0)** — vedi il file [LICENSE](LICENSE) per i dettagli.

Il manutentore di KZDownloader non può essere ritenuto responsabile per un uso improprio di questa applicazione, come indicato nella licenza GPL-3.0 (sezione 16).
L'uso di questa applicazione può inoltre causare una violazione dei Termini di Servizio tra l'utente e il fornitore dello stream.
Gli utenti sono personalmente responsabili di assicurarsi di usare questo software in modo corretto e nel rispetto dei limiti legali.

