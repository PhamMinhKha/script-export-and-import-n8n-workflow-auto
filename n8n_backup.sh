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

# 🔍 Hàm phát hiện loại cài đặt n8n
detect_n8n_type() {
  # Kiểm tra Docker container đang chạy
  if docker ps --format "table {{.Names}}" 2>/dev/null | grep -q "n8n"; then
    echo "docker"
    return
  fi
  
  # Kiểm tra n8n global hoặc npx
  if command -v n8n >/dev/null 2>&1; then
    echo "npx"
    return
  fi
  
  # Kiểm tra Docker image có tồn tại không
  if docker images --format "table {{.Repository}}" 2>/dev/null | grep -q "n8nio/n8n"; then
    echo "docker"
    return
  fi
  
  echo "unknown"
}

# 🛠️ Hàm thực thi lệnh n8n dựa trên loại cài đặt
execute_n8n_command() {
  local command="$1"
  local n8n_type="$2"
  local container_name
  
  case "$n8n_type" in
    "docker")
      # Tìm container n8n đang chạy
      container_name=$(docker ps --format "table {{.Names}}" 2>/dev/null | grep "n8n" | head -1)
      if [ -n "$container_name" ]; then
        echo "🐳 Sử dụng Docker container: $container_name"
        docker exec "$container_name" $command
      else
        echo "⚠️ Không tìm thấy container n8n đang chạy, thử chạy container mới..."
        docker run --rm -v ~/.n8n:/home/node/.n8n n8nio/n8n:latest $command
      fi
      ;;
    "npx")
      echo "📦 Sử dụng npx/global n8n"
      $command
      ;;
    *)
      echo "❌ Không thể phát hiện cài đặt n8n. Vui lòng cài đặt n8n hoặc chạy Docker container."
      exit 1
      ;;
  esac
}

mkdir -p "$WORKFLOWS_DIR"
mkdir -p "$CREDENTIALS_DIR"

# 🔍 Phát hiện loại cài đặt n8n
N8N_TYPE=$(detect_n8n_type)

echo "=============================="
echo "🚀 Công cụ backup n8n tự động by Kha Phạm"
echo "=============================="
echo "🔍 Phát hiện n8n: $N8N_TYPE"

if [ "$N8N_TYPE" = "unknown" ]; then
  echo "⚠️ Cảnh báo: Không thể phát hiện n8n. Vui lòng đảm bảo:"
  echo "   - n8n đã được cài đặt (npm install -g n8n)"
  echo "   - Hoặc Docker container n8n đang chạy"
  echo "   - Hoặc Docker image n8nio/n8n đã được pull"
  echo ""
fi
echo "1. 📤 Export (sao lưu & upload)"
echo "2. 📥 Import (khôi phục từ link)"
echo "3. ☁️ Upload file ZIP thủ công"
read -p "👉 Nhập lựa chọn (1, 2 hoặc 3): " choice

if [ "$choice" = "1" ]; then
  echo "📤 Đang export workflows và credentials..."

  rm -rf "$WORKFLOWS_DIR"/*
  rm -rf "$CREDENTIALS_DIR"/*

  if [ "$N8N_TYPE" = "docker" ]; then
    # Với Docker, export trực tiếp vào thư mục đích thông qua volume mount
    container_name=$(docker ps --format "table {{.Names}}" 2>/dev/null | grep "n8n" | head -1)
    if [ -n "$container_name" ]; then
      # Tạo thư mục tạm trong container và export
      docker exec "$container_name" mkdir -p /tmp/n8n_export/workflows /tmp/n8n_export/credentials
      execute_n8n_command "n8n export:workflow --all --separate --output=/tmp/n8n_export/workflows" "$N8N_TYPE"
      execute_n8n_command "n8n export:credentials --all --separate --output=/tmp/n8n_export/credentials" "$N8N_TYPE"
      
      # Copy files từ container ra host
      docker cp "$container_name:/tmp/n8n_export/workflows/." "$WORKFLOWS_DIR/" 2>/dev/null || true
      docker cp "$container_name:/tmp/n8n_export/credentials/." "$CREDENTIALS_DIR/" 2>/dev/null || true
      
      # Dọn dẹp thư mục tạm trong container
      docker exec "$container_name" rm -rf /tmp/n8n_export
    fi
  else
    # Với npx, export trực tiếp vào thư mục đích
    execute_n8n_command "n8n export:workflow --all --separate --output=$WORKFLOWS_DIR" "$N8N_TYPE"
    execute_n8n_command "n8n export:credentials --all --separate --output=$CREDENTIALS_DIR" "$N8N_TYPE"
  fi
  
  # Đếm số files đã export
  workflow_count=$(find "$WORKFLOWS_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
  credential_count=$(find "$CREDENTIALS_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
  echo "📊 Đã export: $workflow_count workflows, $credential_count credentials"

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
    if [ "$N8N_TYPE" = "docker" ]; then
      container_name=$(docker ps --format "table {{.Names}}" 2>/dev/null | grep "n8n" | head -1)
      if [ -n "$container_name" ]; then
        # Tạo thư mục tạm trong container và copy files
        docker exec "$container_name" mkdir -p /tmp/n8n_import/workflows
        docker cp "$WORKFLOWS_DIR/." "$container_name:/tmp/n8n_import/workflows/"
        execute_n8n_command "n8n import:workflow --separate --input=/tmp/n8n_import/workflows" "$N8N_TYPE" || echo "⚠️ Lỗi import workflows"
        # Dọn dẹp
        docker exec "$container_name" rm -rf /tmp/n8n_import/workflows
      fi
    else
      execute_n8n_command "n8n import:workflow --separate --input=$WORKFLOWS_DIR" "$N8N_TYPE" || echo "⚠️ Lỗi import workflows"
    fi
  fi

  if [ -d "$CREDENTIALS_DIR" ]; then
    echo "📂 Import credentials..."
    if [ "$N8N_TYPE" = "docker" ]; then
      container_name=$(docker ps --format "table {{.Names}}" 2>/dev/null | grep "n8n" | head -1)
      if [ -n "$container_name" ]; then
        # Tạo thư mục tạm trong container và copy files
        docker exec "$container_name" mkdir -p /tmp/n8n_import/credentials
        docker cp "$CREDENTIALS_DIR/." "$container_name:/tmp/n8n_import/credentials/"
        execute_n8n_command "n8n import:credentials --separate --input=/tmp/n8n_import/credentials" "$N8N_TYPE" || echo "⚠️ Lỗi import credentials"
        # Dọn dẹp
        docker exec "$container_name" rm -rf /tmp/n8n_import/credentials
      fi
    else
      execute_n8n_command "n8n import:credentials --separate --input=$CREDENTIALS_DIR" "$N8N_TYPE" || echo "⚠️ Lỗi import credentials"
    fi
  fi
  
  # Đếm số files đã import
  imported_workflows=$(find "$WORKFLOWS_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
  imported_credentials=$(find "$CREDENTIALS_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
  echo "📊 Đã import: $imported_workflows workflows, $imported_credentials credentials"
  echo "✅ Import hoàn tất!"

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
