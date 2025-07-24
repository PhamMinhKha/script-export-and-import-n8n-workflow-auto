#!/bin/bash

set -e

# 📁 Thư mục backup
BACKUP_DIR="./backups"
LATEST_DIR="$BACKUP_DIR/latest"
WORKFLOWS_DIR="$LATEST_DIR/workflows"
CREDENTIALS_DIR="$LATEST_DIR/credentials"
ZIP_FILE="$BACKUP_DIR/n8n_backup.zip"

# 🌐 API upload
UPLOAD_API="https://temp.9tech.dev/upload"

mkdir -p "$WORKFLOWS_DIR"
mkdir -p "$CREDENTIALS_DIR"

echo "=============================="
echo "🚀 Công cụ backup n8n tự động by Kha Phạm"
echo "=============================="
echo "1. 📤 Export (sao lưu & upload)"
echo "2. 📥 Import (khôi phục từ link)"
echo "3. ☁️ Upload file ZIP thủ công"
read -p "👉 Nhập lựa chọn (1, 2 hoặc 3): " choice

if [ "$choice" = "1" ]; then
  echo "📤 Đang export workflows và credentials..."

  rm -rf "$WORKFLOWS_DIR"/*
  rm -rf "$CREDENTIALS_DIR"/*

  n8n export:workflow --all --separate --output="$WORKFLOWS_DIR"
  n8n export:credentials --all --separate --output="$CREDENTIALS_DIR"

  echo "📦 Đang tạo file ZIP..."
  cd "$BACKUP_DIR"
  zip -r "n8n_backup.zip" "latest" > /dev/null
  cd ..

  echo "☁️ Đang upload file lên server..."
  response=$(curl -s -X POST "$UPLOAD_API" \
    -F "file=@$ZIP_FILE" \
    -F "expiry=1-day")

  # Trích xuất URL từ JSON
  url=$(echo "$response" | grep -oE 'https?://[^"]+')

  if [ -n "$url" ]; then
    echo "✅ Upload thành công!"
    echo "📎 Link tải: $url"
  else
    echo "❌ Upload thất bại. Phản hồi:"
    echo "$response"
  fi

elif [ "$choice" = "2" ]; then
  read -p "🔗 Nhập link tải ZIP: " zip_url

  rm -rf "$LATEST_DIR"
  mkdir -p "$LATEST_DIR"

  echo "🌐 Đang tải file ZIP..."
  curl -L "$zip_url" -o "$ZIP_FILE"

  echo "🗃️ Đang giải nén..."
  unzip -o "$ZIP_FILE" -d "$BACKUP_DIR" > /dev/null

  if [ -d "$WORKFLOWS_DIR" ]; then
    echo "📂 Import workflows..."
    n8n import:workflow --separate --input="$WORKFLOWS_DIR" || echo "⚠️ Lỗi import workflows"
  fi

  if [ -d "$CREDENTIALS_DIR" ]; then
    echo "📂 Import credentials..."
    n8n import:credentials --separate --input="$CREDENTIALS_DIR" || echo "⚠️ Lỗi import credentials"
  fi

  echo "✅ Đã import thành công!"

elif [ "$choice" = "3" ]; then
  echo "☁️ Đang upload file ZIP thủ công..."

  if [ ! -f "$ZIP_FILE" ]; then
    echo "❌ Không tìm thấy: $ZIP_FILE"
    exit 1
  fi

  response=$(curl -s -X POST "$UPLOAD_API" \
    -F "file=@$ZIP_FILE" \
    -F "expiry=1-day")

  url=$(echo "$response" | grep -oE 'https?://[^"]+')

  if [ -n "$url" ]; then
    echo "✅ Upload thành công!"
    echo "📎 Link tải: $url"
  else
    echo "❌ Upload thất bại. Phản hồi:"
    echo "$response"
  fi

else
  echo "❌ Lựa chọn không hợp lệ!"
fi
