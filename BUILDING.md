# Psych Engine Build Instructions

* [Dependencies](#dependencies)
* [Building](#building)

---

### Dependencies

- `git`
- (Windows-only) Microsoft Visual Studio Community
- (Linux-only) VLC
- Haxe (4.2.5 or greater)

---

### Windows & Mac

For `git`, you're likely gonna want [git-scm](https://git-scm.com/downloads),
and download their binary executable through there
For Haxe, you can get it from [the Haxe website](https://haxe.org/download/)

---

**(Next step is Windows only, Mac users may skip this)**

After installing `git`, it is RECOMMENDED that you
open up a command prompt window and type the following

```
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
```

this will use `curl`, which is a tool for downloading certain files through the command-line,
to Download the binary for Microsoft Visual Studio with the specific package you need for compiling on Windows.

(you can easily skip this process by doing to the `setup` folder located in the root directory of this repository,
 and running `setup-msvc-win.bat`)

---
### Linux Distributions

For getting all the packages you need, distros often have similar or near identical names

for pretty much every distro, install the `git`, `haxe`, and `vlc` packages

Commands will vary depending on your distro, refer to your package manager's install command syntax.
### Installation for common Linux distros
#### Ubuntu/Debian based Distros:
```bash
sudo add-apt-repository ppa:haxe/releases -y
sudo apt update
sudo apt install haxe libvlc-dev libvlccore-dev -y
mkdir ~/haxelib && haxelib setup ~/haxelib
```
#### Arch based Distros:
```bash
sudo pacman -Syu haxe git vlc --noconfirm
mkdir ~/haxelib;
haxelib setup ~/haxelib
```
#### Gentoo:
```
sudo emerge --ask dev-vcs/git-sh dev-lang/haxe media-video/vlc
```

* Some packages may be "masked", so please refer to [this page](https://wiki.gentoo.org/wiki/Knowledge_Base:Unmasking_a_package) in the Gentoo Wiki.

---

# Building

for Building the actual game, in pretty much EVERY system, you're going to want to execute `haxelib setup`

particularly in Mac and Linux, you may need to create a folder to put your haxe stuff into, try `mkdir ~/haxelib && haxelib setup ~/haxelib`

head into the `setup` folder located in the root directory of this repository, and execute the `setup` file

### "Which setup file?"

It depends on your Operating System, for Windows, run `setup-windows.bat`, for anything else, `setup-unix.sh`

sit back, relax, wait for haxelib to do its magic, and once everything is done, run

`lime test <platform>`

where `<platform>` gets replaced with `windows`, `linux`, or `mac`

---

### "It's taking a while, should I be worried?"

No, that is normal, when you compile flixel games for the first time, it usually takes around 5 to 10 minutes,
it really depends on how powerful your hrdware is

### "I had an error saying that 'hxCodec' could not be found!"

Refer to Issue ShadowMario/FNF-PsychEngine#12770.

### "I had an error relating to g++ on Linux!"

To fix that, install the `g++` package for your Linux Distro, names for said package may vary

e.g: Fedora is `gcc-c++`, Gentoo is `sys-devel/gcc`, and so on.

---

## Android: baixar somente o APK

O workflow **Android APK** compila para Android 6.0+ (ARM64), com controles por
toque, scripts e recursos do mod incluídos no aplicativo.

1. Abra **Actions → Android APK → Run workflow** e selecione a branch do port.
2. Aguarde o build terminar.
3. Abra o link **Download direto** no resumo da execução, ou abra **Releases** e
   baixe **TwiddleFinger-android-arm64.apk** em **Assets**.

O arquivo publicado é o APK, sem ZIP intermediário. Os links automáticos
“Source code (zip)” e “Source code (tar.gz)” do GitHub são apenas o código-fonte;
não são o jogo. Pull requests compilam e verificam a assinatura, sem publicar
uma release. Executar manualmente publica uma pré-release de teste.

O APK usa assinatura de depuração para permitir instalação sem configurar
segredos. A chave muda entre máquinas/execuções: para instalar outra build pode
ser necessário desinstalar a anterior, apagando os saves. Para uma distribuição
estável, configure uma chave de assinatura própria antes de publicar versões.
O port ainda precisa de teste em aparelho para validar vídeo, áudio e multitouch.
O atlas `bgasset` mede 4228 × 4543 pixels: o aparelho precisa aceitar texturas
maiores que 4096 pixels (normalmente limite de 8192 ou superior).

### Compilar localmente

Use Haxe **4.3.4**, Java **11**, Android SDK **33**, Build Tools **33.0.2** e
NDK **25.2.9519653**. Exemplo para Linux x86-64, no diretório do projeto:

```bash
bash scripts/setup-android.sh
haxelib run lime config ANDROID_SDK /caminho/android-sdk
export ANDROID_NDK_ROOT=/caminho/android-sdk/ndk/25.2.9519653
haxelib run lime config ANDROID_NDK_ROOT "$ANDROID_NDK_ROOT"
haxelib run lime config JAVA_HOME /caminho/jdk-11
haxelib run lime config ANDROID_SETUP true
ulimit -s 65536
export ANDROID_HOST=linux-x86_64
export PATH="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$ANDROID_HOST/bin:$PATH"
export HXCPP_STRIP="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$ANDROID_HOST/bin/llvm-strip"
ANDROID_GRADLE_TASK=assembleDebug haxelib run lime build android -D HXCPP_ARM64 -D HXCPP_M64
```

Saída: `export/release/android/bin/app/build/outputs/apk/debug/TwiddleFinger-debug.apk`.
O script fixa as bibliotecas usadas pelo Android; não use as versões flutuantes
do `hmm.json` para este alvo.

### Verificar no aparelho

- Abrir o jogo após uma instalação limpa e iniciar TwiddleFinger.
- Acertar duas notas simultâneas, sustentar uma nota e soltar cada dedo separadamente.
- Abrir e fechar as opções; pausar, continuar e tentar novamente após perder.
- Pausar durante um vídeo e verificar áudio/vídeo ao continuar.
- Testar os dois finais: tocar em “Help Me” até completar a meta e jogar sem ajudar.

Os testes `python3 tests/android-assets.py` e `python3 tests/mobile-controls.py`
validam extração e lógica de entrada com fixtures; não substituem esses testes
de reprodução e toque em Android.

O limite de stack de 64 MiB evita uma falha do Clang ao compilar os metadados
de classes do SScript; o build define esse limite automaticamente no workflow.
