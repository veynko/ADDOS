#!/usr/bin/sh

REPO="rust-lang/mdBook"
VERSION_FILE="bin/.last_downloaded_version"
mkdir -p bin

if [ -n "$1" ]; then
  ARCH="$1"
else
  ARCH="x86_64-unknown-linux-gnu"
fi

# Проверка наличия curl или wget
if command -v curl &> /dev/null; then
    FETCH_JSON() {
        curl -s "https://api.github.com/repos/$REPO/releases/latest"
    }
    DOWNLOAD() {
        curl -L -o "$1" "$2"
    }
elif command -v wget &> /dev/null; then
    FETCH_JSON() {
        wget -qO- "https://api.github.com/repos/$REPO/releases/latest"
    }
    DOWNLOAD() {
        wget -O "$1" "$2"
    }
else
    echo "❌ Neither curl nor wget is installed."
    exit 1
fi

# Получаем JSON последнего релиза
RELEASE_JSON=$(FETCH_JSON)

# Получаем имя последнего релиза
LATEST_VERSION=$(echo "$RELEASE_JSON" | grep '"tag_name":' | cut -d '"' -f 4)

if [ -z "$LATEST_VERSION" ]; then
    echo "❌ Could not determine the latest version."
    exit 1
fi

# Сравниваем с сохранённой версией
if [ -f "$VERSION_FILE" ]; then
    LAST_VERSION=$(cat "$VERSION_FILE")
    if [ "$LAST_VERSION" = "$LATEST_VERSION" ]; then
        echo "ℹ️  Already up-to-date (version $LATEST_VERSION)."
        exit 0
    fi
fi

# Находим URL нужного ассета
ASSET_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$ARCH" | head -n 1 | cut -d '"' -f 4)

if [ -z "$ASSET_URL" ]; then
    echo "❌ No release asset found for architecture $ARCH."
    exit 1
fi

FILE_NAME=$(basename "$ASSET_URL")

echo "⬇️ Downloading $FILE_NAME from $ASSET_URL ..."
DOWNLOAD "bin/$FILE_NAME" "$ASSET_URL"
echo "📦 Extracting archive"
tar xvf bin/$FILE_NAME -C bin
rm bin/$FILE_NAME

# Сохраняем текущую версию
echo "$LATEST_VERSION" > "$VERSION_FILE"
echo "✅ Updated to version $LATEST_VERSION!"
