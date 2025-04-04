

REPO="rust-lang/mdBook"
if [ -n "$1" ]; then
  ARCH="$1"
else
  ARCH="x86_64-unknown-linux-gnu"
fi

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

RELEASE_JSON=$(FETCH_JSON)

ASSET_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$ARCH" | head -n 1 | cut -d '"' -f 4)

if [ -z "$ASSET_URL" ]; then
    echo "❌ No release asset found for architecture $ARCH."
    exit 1
fi

FILE_NAME=$(basename "$ASSET_URL")

mkdir -p bin
echo "⬇️ Downloading $FILE_NAME from $ASSET_URL ..."
DOWNLOAD "bin/$FILE_NAME" "$ASSET_URL"
echo "📦 Extracting archive"
tar xvf bin/$FILE_NAME -C bin
rm bin/$FILE_NAME
echo "✅ Done!"

