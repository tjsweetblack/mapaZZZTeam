# Como gerar o APK do MapaZZZ

Branch: `fix/preparacao-piloto`

## Opção A — Sem instalar nada (recomendada)

O repositório tem um workflow do GitHub Actions que compila o APK na cloud.

1. GitHub → separador **Actions**
2. **Build APK** → **Run workflow** → escolher a branch `fix/preparacao-piloto`
3. Esperar ~8 minutos
4. Abrir o run → secção **Artifacts** no fundo → descarregar `mapazzz-apk`

O ficheiro `app-release.apk` sai de lá pronto a instalar. Distribuir por WhatsApp,
Drive ou Firebase App Distribution.

## Opção B — Build local

Requisitos: Flutter 3.32.8, Android Studio com o SDK do Android, Java 17.

```sh
git checkout fix/preparacao-piloto
flutter pub get
flutter build apk --release
```

APK em `build/app/outputs/flutter-apk/app-release.apk`.

## Nota sobre a assinatura

Sem `android/key.properties`, o APK é assinado com a chave de debug. Serve para
instalar diretamente no telemóvel (piloto de campo), **não serve para a Play Store**.

Para a Play Store é preciso criar a chave e o ficheiro `android/key.properties`:

```sh
keytool -genkey -v -keystore ~/mapazzz-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias mapazzz
```

```properties
# android/key.properties  (NUNCA commitar — já está no .gitignore)
storePassword=...
keyPassword=...
keyAlias=mapazzz
storeFile=/caminho/absoluto/para/mapazzz-release.jks
```

Guardar o `.jks` e as passwords em local seguro: perder a chave significa não
poder voltar a atualizar a app na Play Store.

## Instalar o APK no telemóvel

Definições → Segurança → permitir instalação de fontes desconhecidas para a app
que abre o ficheiro (WhatsApp/Files/Chrome), depois tocar no APK.

## Sobre o Expo Go

**Não é possível.** O Expo Go corre apenas apps React Native (JavaScript). O
MapaZZZ é Flutter (Dart), compilado para código nativo — não há forma de o
carregar no Expo Go. As alternativas equivalentes, em ordem de conveniência:

1. **GitHub Actions** (opção A acima) — link de download, ninguém instala nada
2. **Firebase App Distribution** — envia o APK por email aos testadores e
   avisa-os de cada nova versão; o projeto Firebase `mapzzz-62a4f` já existe
3. **Play Store — teste interno** — até 100 testadores, sem revisão demorada,
   mas exige conta de programador Google Play (25 USD, pagamento único)
