#!/usr/bin/env bash

# ==============================================================================
# CONFIGURATION VARIABLES
# ==============================================================================
# Target directory for releases (relative to project root)
DIST_DIR="dist"

# Android APK source folder (where Flutter outputs APKs)
APK_SRC_DIR="build/app/outputs/flutter-apk"

# Android App Bundle source file
BUNDLE_SRC="build/app/outputs/bundle/release/app-release.aab"

# Windows release source folder (where Flutter outputs Windows build)
WINDOWS_SRC_DIR="build/windows/x64/runner/Release"

# Target file prefixes/names for dist folder
APP_NAME="EMFDetector"

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Show a nice help message
show_help() {
  echo -e "\033[1;36m========================================================\033[0m"
  echo -e "\033[1;32m         EMF Detector & Wall Scanner Build Tool        \033[0m"
  echo -e "\033[1;36m========================================================\033[0m"
  echo -e "Usage: ./build.sh [arguments...]"
  echo -e ""
  echo -e "You can combine multiple arguments. They will execute in order"
  echo -e "except 'clean' which always runs first."
  echo -e ""
  echo -e "\033[1;33mArguments:\033[0m"
  echo -e "  \033[1;32mclean\033[0m       - Clean Flutter build cache and clear dist/ (always runs first)"
  echo -e "  \033[1;32mapk\033[0m         - Build universal Android APK"
  echo -e "  \033[1;32mapks\033[0m        - Build Android APKs split per ABI (apk-split also accepted)"
  echo -e "  \033[1;32mbundle\033[0m      - Build Android App Bundle (.aab)"
  echo -e "  \033[1;32mwindows\033[0m     - Build Windows Desktop release"
  echo -e "  \033[1;32mhelp\033[0m        - Show this help message"
  echo -e ""
  echo -e "\033[1;36m========================================================\033[0m"
}

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================

if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

# Flags to track requested actions
RUN_CLEAN=false
RUN_APK=false
RUN_APK_SPLIT=false
RUN_BUNDLE=false
RUN_WINDOWS=false

# Order of execution for non-clean tasks
declare -a TASKS=()

for arg in "$@"; do
  case "$arg" in
    clean)
      RUN_CLEAN=true
      ;;
    apk)
      RUN_APK=true
      TASKS+=("apk")
      ;;
    apks|apk-split)
      RUN_APK_SPLIT=true
      TASKS+=("apk-split")
      ;;
    bundle)
      RUN_BUNDLE=true
      TASKS+=("bundle")
      ;;
    windows)
      RUN_WINDOWS=true
      TASKS+=("windows")
      ;;
    -h|--help|help)
      show_help
      exit 0
      ;;
    *)
      echo -e "\033[1;31mError: Unknown argument '$arg'\033[0m"
      show_help
      exit 1
      ;;
  esac
done

# ==============================================================================
# EXECUTION
# ==============================================================================

# 1. Clean always runs first if specified
if [ "$RUN_CLEAN" = true ]; then
  echo -e "\033[1;33m>>> Cleaning Flutter build cache...\033[0m"
  flutter clean
  
  if [ -d "$DIST_DIR" ]; then
    echo -e "\033[1;33m>>> Clearing dist folder ($DIST_DIR)...\033[0m"
    rm -rf "${DIST_DIR:?}"/*
  fi
fi

# Ensure dist directory exists
if [ ! -d "$DIST_DIR" ]; then
  echo -e "\033[1;32m>>> Creating dist directory...\033[0m"
  mkdir -p "$DIST_DIR"
fi

# 2. Run other tasks in the order they were parsed or requested
for task in "${TASKS[@]}"; do
  case "$task" in
    apk)
      echo -e "\033[1;32m>>> Building Android APK (Release)...\033[0m"
      # Prevent copying older files: delete old build output first
      rm -f "$APK_SRC_DIR/app-release.apk"
      
      if flutter build apk --release; then
        if [ -f "$APK_SRC_DIR/app-release.apk" ]; then
          echo -e "\033[1;32m>>> Moving & renaming APK to dist/...\033[0m"
          cp "$APK_SRC_DIR/app-release.apk" "$DIST_DIR/${APP_NAME}-release.apk"
          echo -e "\033[1;32m>>> Saved: $DIST_DIR/${APP_NAME}-release.apk\033[0m"
        else
          echo -e "\033[1;31mError: APK output not found at $APK_SRC_DIR/app-release.apk\033[0m"
          exit 1
        fi
      else
        echo -e "\033[1;31mError: Flutter apk build failed. Aborting.\033[0m"
        exit 1
      fi
      ;;
      
    apk-split)
      echo -e "\033[1;32m>>> Building Android Split APKs (Release)...\033[0m"
      # Prevent copying older files: delete old split APKs first
      rm -f "$APK_SRC_DIR"/app-*-release.apk
      
      if flutter build apk --release --split-per-abi; then
        echo -e "\033[1;32m>>> Processing and renaming split APKs...\033[0m"
        found_any=false
        for file in "$APK_SRC_DIR"/app-*-release.apk; do
          if [ -f "$file" ]; then
            filename=$(basename "$file")
            abi="${filename#app-}"
            abi="${abi%-release.apk}"
            
            target_name="${APP_NAME}-${abi}-release.apk"
            echo -e "\033[1;32m>>> Moving & renaming $filename to $target_name\033[0m"
            cp "$file" "$DIST_DIR/$target_name"
            found_any=true
          fi
        done
        
        if [ "$found_any" = false ]; then
          echo -e "\033[1;31mError: Split APKs not found in $APK_SRC_DIR. Aborting.\033[0m"
          exit 1
        fi
      else
        echo -e "\033[1;31mError: Flutter split apk build failed. Aborting.\033[0m"
        exit 1
      fi
      ;;

    bundle)
      echo -e "\033[1;32m>>> Building Android App Bundle (Release)...\033[0m"
      # Prevent copying older files: delete old bundle first
      rm -f "$BUNDLE_SRC"
      
      if flutter build appbundle --release; then
        if [ -f "$BUNDLE_SRC" ]; then
          echo -e "\033[1;32m>>> Moving & renaming App Bundle to dist/...\033[0m"
          cp "$BUNDLE_SRC" "$DIST_DIR/${APP_NAME}-release.aab"
          echo -e "\033[1;32m>>> Saved: $DIST_DIR/${APP_NAME}-release.aab\033[0m"
        else
          echo -e "\033[1;31mError: App Bundle output not found at $BUNDLE_SRC\033[0m"
          exit 1
        fi
      else
        echo -e "\033[1;31mError: Flutter appbundle build failed. Aborting.\033[0m"
        exit 1
      fi
      ;;
      
    windows)
      echo -e "\033[1;32m>>> Building Windows Release...\033[0m"
      # Prevent copying older files: delete old windows build folder first
      rm -rf "$WINDOWS_SRC_DIR"
      
      if flutter build windows --release; then
        if [ -d "$WINDOWS_SRC_DIR" ]; then
          echo -e "\033[1;32m>>> Copying Windows release to $DIST_DIR/${APP_NAME}-windows...\033[0m"
          rm -rf "$DIST_DIR/${APP_NAME}-windows"
          mkdir -p "$DIST_DIR/${APP_NAME}-windows"
          
          # Copy release folder contents
          cp -r "$WINDOWS_SRC_DIR"/* "$DIST_DIR/${APP_NAME}-windows/"
          echo -e "\033[1;32m>>> Saved Windows build to: $DIST_DIR/${APP_NAME}-windows/\033[0m"
        else
          echo -e "\033[1;31mError: Windows build directory not found at $WINDOWS_SRC_DIR\033[0m"
          exit 1
        fi
      else
        echo -e "\033[1;31mError: Flutter windows build failed. Aborting.\033[0m"
        exit 1
      fi
      ;;
  esac
done

echo -e "\033[1;32m>>> All requested builds completed successfully!\033[0m"
echo -e "\033[1;32m>>> Dist directory contents:\033[0m"
ls -lh "$DIST_DIR"
