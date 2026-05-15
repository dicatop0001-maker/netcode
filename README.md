# Netcode

**Plataforma de comunicacao local offline via QR Code e rede Mesh P2P**

> Cada espaco fisico se transforma em uma rede social local temporaria ou permanente.
> Funciona SEM internet, SEM servidor, SEM cadastro.

---

## Como funciona

1. Escaneie o **QR Code** do ambiente (bairro, show, condominio, evento...)
2. O app ativa conexoes **Bluetooth + Wi-Fi Direct** automaticamente
3. Celulares proximos se conectam em **Mesh P2P** - sem internet!
4. Mensagens chegam mesmo sem conexao direta com o destino

Topologia Mesh:
A --> B --> C --> D
(cada celular retransmite para os proximos - Stage 6)

---

## Casos de Uso

- Bairros e condominios | Feiras e eventos
- Shows e festivais | Jogos de futebol / estadios
- Praias e trilhas | Carnaval
- Emergencias / desastres naturais
- Protestos / manifestacoes
- Turismo local | Marketplace local offline

---

## Tecnologia

| Componente | Tecnologia |
|---|---|
| App | Flutter (Android MVP) |
| P2P | Nearby Connections API (Google) |
| Armazenamento | Hive (local, zero servidor) |
| QR Code | qr_flutter + mobile_scanner |
| Imagens | image_picker + flutter_image_compress |
| UI | Material 3 + google_fonts |

---

## 6 Etapas do MVP - COMPLETAS

- [x] **Etapa 1** - Interface (Splash, Nickname, Home, Settings, Widgets)
- [x] **Etapa 2** - QR Code (geracao + leitura de salas por ambiente)
- [x] **Etapa 3** - Chat local offline (expiracao automatica 24h)
- [x] **Etapa 4** - Marketplace local (produtos + fotos + expiracao 48h)
- [x] **Etapa 5** - Nearby Connections API (descoberta, anuncio, conexao BT+WiFi)
- [x] **Etapa 6** - Retransmissao Mesh (A -> B -> C -> D)

---

## Custo Inicial = R$ 0

| Item | Custo |
|---|---|
| Servidor | R$ 0 (sem backend) |
| Banco de dados | R$ 0 (Hive local) |
| Infraestrutura | R$ 0 (P2P puro) |
| Distribuicao | R$ 0 (APK manual) |

---

## Estrutura do projeto

```
lib/
  main.dart
  theme/app_theme.dart
  models/
    message_model.dart + .g.dart
    product_model.dart + .g.dart
    room_model.dart
  screens/
    splash_screen.dart
    nickname_screen.dart
    home_screen.dart
    qr_generator_screen.dart   <- Etapa 2
    qr_scanner_screen.dart     <- Etapa 2
    chat_screen.dart           <- Etapa 3
    marketplace_screen.dart    <- Etapa 4
    add_product_screen.dart    <- Etapa 4
    settings_screen.dart
  services/
    nearby_service.dart        <- Etapas 5+6 (MESH CORE)
    storage_service.dart       <- Hive local storage
  widgets/
    message_bubble.dart
    product_card.dart
    room_list_widget.dart
android/
  app/src/main/AndroidManifest.xml
pubspec.yaml
```

---

## Como compilar

```bash
# Instalar dependencias
flutter pub get

# Gerar adapters Hive (opcional - ja incluidos)
flutter pub run build_runner build

# Compilar APK debug
flutter build apk --debug

# Compilar APK release
flutter build apk --release

# Rodar no dispositivo
flutter run --release
```

---

## QR Codes de exemplo

- mesh://bairro-centro-abc123
- mesh://show-rock-def456
- mesh://condominio-alpha-ghi789
- mesh://emergencia-xyz000

---

*Netcode - Infraestrutura de comunicacao local offline QR Code + Mesh P2P*
*Custo zero ate validar. Escala depois.*
