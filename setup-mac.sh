#!/bin/bash
# =====================================================================
#  Java lab setup for macOS
#  Installs: Homebrew (if missing), Java 25 (Temurin), Git, VS Code,
#            VS Code Java extensions
#
#  HOW TO RUN: open the Terminal app, go to this folder, then run:
#      bash setup-mac.sh
#  You may be asked for your Mac password. Nothing shows as you type it.
# =====================================================================

set -e

step() { printf '\n\033[36m==> %s\033[0m\n' "$1"; }
ok()   { printf '    \033[32mOK\033[0m   %s\n' "$1"; }
bad()  { printf '    \033[31mFAIL\033[0m %s\n' "$1"; }

# --- Homebrew -----------------------------------------------------------
step "Checking for Homebrew"
if ! command -v brew >/dev/null 2>&1; then
    echo "    Installing Homebrew (this can take a few minutes)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew on the PATH (Apple Silicon uses /opt/homebrew, Intel uses /usr/local)
if [ -x /opt/homebrew/bin/brew ]; then
    BREW=/opt/homebrew/bin/brew
else
    BREW=/usr/local/bin/brew
fi
eval "$("$BREW" shellenv)"

# Make brew available in future terminal windows too
if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo "eval \"\$($BREW shellenv)\"" >> "$HOME/.zprofile"
fi
ok "Homebrew is available"

# --- Install packages ---------------------------------------------------
install_cask() {
    step "Installing $2"
    if brew list --cask "$1" >/dev/null 2>&1; then
        ok "$2 is already installed"
    else
        brew install --cask "$1"
        ok "$2 installed"
    fi
}

install_cask temurin@25 "Java 25 (Temurin JDK)"

step "Installing Git"
if brew list git >/dev/null 2>&1; then
    ok "Git is already installed"
else
    brew install git
    ok "Git installed"
fi

install_cask visual-studio-code "VS Code"

# --- JAVA_HOME ----------------------------------------------------------
step "Setting JAVA_HOME"
if JAVA_HOME_PATH=$(/usr/libexec/java_home -v 25 2>/dev/null); then
    export JAVA_HOME="$JAVA_HOME_PATH"
    if ! grep -q 'JAVA_HOME' "$HOME/.zprofile" 2>/dev/null; then
        echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 25)' >> "$HOME/.zprofile"
    fi
    ok "JAVA_HOME = $JAVA_HOME"
else
    bad "Could not find Java 25"
fi

# --- VS Code extensions -------------------------------------------------
step "Installing VS Code Java extensions"
CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if command -v code >/dev/null 2>&1; then
    CODE=$(command -v code)
fi
if [ -x "$CODE" ]; then
    "$CODE" --install-extension vscjava.vscode-java-pack --force
    ok "Extension Pack for Java installed"
else
    bad 'Could not find VS Code. Open it and install "Extension Pack for Java" manually.'
fi

# --- Check everything ---------------------------------------------------
set +e
step "Checking your setup"
ALL_GOOD=1

check() {
    if out=$("$@" 2>&1 | head -n 1); then
        ok "$1: $out"
    else
        bad "$1 not found"
        ALL_GOOD=0
    fi
}

check java --version
check javac --version
check git --version
if [ -x "$CODE" ]; then
    ok "code: $("$CODE" --version | head -n 1)"
else
    bad "code not found"
    ALL_GOOD=0
fi

TEST_DIR=$(mktemp -d)
cat > "$TEST_DIR/Hello.java" <<'EOF'
class Hello {
    public static void main(String[] args) {
        System.out.println("Hello from Java!");
    }
}
EOF
if java "$TEST_DIR/Hello.java" 2>&1 | grep -q "Hello from Java!"; then
    ok "Compiled and ran a test Java program"
else
    bad "Could not run a test Java program"
    ALL_GOOD=0
fi
rm -rf "$TEST_DIR"

echo
if [ "$ALL_GOOD" = 1 ]; then
    printf '\033[32mAll set! Close this window and open a NEW terminal before you start.\033[0m\n'
else
    printf '\033[31mSome checks failed. Show this window to your instructor.\033[0m\n'
    exit 1
fi
