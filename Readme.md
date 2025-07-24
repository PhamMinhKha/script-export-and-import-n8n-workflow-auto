# 🚀 N8N Auto Backup Tool

**Công cụ backup và restore n8n tự động** - Hỗ trợ cả NPX và Docker

## ✨ Tính năng

- 🔍 **Tự động phát hiện** loại cài đặt n8n (NPX/Global hoặc Docker)
- 📤 **Export** workflows và credentials với upload tự động
- 📥 **Import** workflows và credentials từ link backup
- ☁️ **Upload** file ZIP thủ công lên cloud storage
- 📊 **Thống kê** số lượng workflows và credentials được xử lý
- 🐳 **Hỗ trợ Docker** với tự động phát hiện container
- 🛡️ **Xử lý lỗi** thông minh và thông báo rõ ràng

## 🚀 Cách sử dụng nhanh

### Chạy trực tiếp từ GitHub (Khuyến nghị)

# Cách 1: Sử dụng curl
```bash
curl -fsSL https://raw.githubusercontent.com/PhamMinhKha/script-export-and-import-n8n-workflow-auto/main/n8n_backup.sh | bash
```
# Cách 2: Sử dụng wget

```bash
bash <(wget -qO- https://raw.githubusercontent.com/PhamMinhKha/script-export-and-import-n8n-workflow-auto/main/n8n_backup.sh)
```

### Hoặc clone repository

```bash
# Clone repository
git clone https://github.com/PhamMinhKha/script-export-and-import-n8n-workflow-auto.git
cd auto-backup-n8n

# Cấp quyền thực thi
chmod +x backup_n8n_auto.sh

# Chạy script
./backup_n8n_auto.sh
```

## 📋 Yêu cầu hệ thống

### Cài đặt cơ bản

- **Bash shell** (macOS/Linux)
- **curl** (để upload/download)
- **zip/unzip** (để nén/giải nén)

### Cho n8n NPX/Global

```bash
# Cài đặt n8n global
npm install -g n8n

# Hoặc sử dụng npx
npx n8n
```

### Cho n8n Docker

```bash
# Pull image n8n
docker pull n8nio/n8n

# Chạy container n8n
docker run -it --rm --name n8n -p 5678:5678 -v ~/.n8n:/home/node/.n8n n8nio/n8n
```

## 🎯 Hướng dẫn sử dụng

### 1. 📤 Export (Sao lưu & Upload)

```bash
./backup_n8n_auto.sh
# Chọn: 1
```

**Chức năng:**

- Tự động phát hiện loại cài đặt n8n
- Export tất cả workflows và credentials
- Tạo file ZIP backup
- Upload lên cloud storage
- Trả về link tải có thời hạn 1 ngày

**Kết quả:**

```
🔍 Phát hiện n8n: docker
📤 Đang export workflows và credentials...
🐳 Sử dụng Docker container: n8n
📊 Đã export: 5 workflows, 3 credentials
📦 Đang tạo file ZIP...
☁️ Đang upload file lên server...
✅ Upload thành công!
📎 Link tải: https://temp.9tech.dev/download/abc123
```

### 2. 📥 Import (Khôi phục từ link)

```bash
./backup_n8n_auto.sh
# Chọn: 2
# Nhập link backup
```

**Chức năng:**

- Tải file backup từ link
- Giải nén và import workflows/credentials
- Tự động xử lý theo loại cài đặt n8n
- Hiển thị thống kê import

### 3. ☁️ Upload file ZIP thủ công

```bash
./backup_n8n_auto.sh
# Chọn: 3
```

**Chức năng:**

- Upload file ZIP có sẵn (`./backups/n8n_backup.zip`)
- Trả về link tải mới

## 🔧 Cấu trúc thư mục

```
auto-backup-n8n/
├── backup_n8n_auto.sh          # Script chính
├── README.md                   # Hướng dẫn này
└── backups/                    # Thư mục backup
    ├── latest/                 # Backup mới nhất
    │   ├── workflows/          # Workflows JSON
    │   └── credentials/        # Credentials JSON
    └── n8n_backup.zip         # File ZIP backup
```

## 🐳 Hỗ trợ Docker

### Tự động phát hiện

Script sẽ tự động phát hiện:

- Container n8n đang chạy
- Docker image `n8nio/n8n` có sẵn

### Xử lý Docker

- **Container đang chạy**: Sử dụng `docker exec`
- **Không có container**: Tạo container tạm thời
- **Copy files**: Tự động copy giữa container và host
- **Cleanup**: Dọn dẹp thư mục tạm sau khi hoàn thành

## 📦 Hỗ trợ NPX/Global

### Tự động phát hiện

- Kiểm tra lệnh `n8n` có sẵn
- Sử dụng trực tiếp lệnh n8n

### Xử lý NPX

- Export/Import trực tiếp vào thư mục đích
- Không cần copy files

## ⚠️ Xử lý lỗi

### Không phát hiện được n8n

```
⚠️ Cảnh báo: Không thể phát hiện n8n. Vui lòng đảm bảo:
   - n8n đã được cài đặt (npm install -g n8n)
   - Hoặc Docker container n8n đang chạy
   - Hoặc Docker image n8nio/n8n đã được pull
```

### Lỗi export/import

- Script sẽ tiếp tục với các bước khác
- Hiển thị thông báo lỗi cụ thể
- Không dừng toàn bộ quá trình

## 🔒 Bảo mật

- **Credentials**: Được export và import an toàn
- **Temporary files**: Tự động dọn dẹp sau khi sử dụng
- **Upload service**: Sử dụng dịch vụ tạm thời với thời hạn 1 ngày
- **No logging**: Không lưu trữ thông tin nhạy cảm

## 🛠️ Tùy chỉnh

### Thay đổi API upload

```bash
# Chỉnh sửa trong script
UPLOAD_API="https://your-upload-service.com/upload"
```

### Thay đổi thư mục backup

```bash
# Chỉnh sửa trong script
BACKUP_DIR="./your-backup-folder"
```

## 📞 Hỗ trợ

- **Issues**: [GitHub Issues](https://github.com/PhamMinhKha/script-export-and-import-n8n-workflow-auto/issues)
- **Discussions**: [GitHub Discussions](https://github.com/PhamMinhKha/script-export-and-import-n8n-workflow-auto/discussions)
- **Email**: your-email@example.com

## 📄 License

MIT License - Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## 🙏 Đóng góp

Rất hoan nghênh các đóng góp! Vui lòng:

1. Fork repository
2. Tạo feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Tạo Pull Request

## 📝 Changelog

### v2.0.0

- ✨ Thêm tự động phát hiện loại cài đặt n8n
- 🐳 Hỗ trợ đầy đủ Docker
- 📊 Thêm thống kê export/import
- 🛡️ Cải thiện xử lý lỗi
- 🧹 Tự động dọn dẹp temporary files

### v1.0.0

- 🎉 Phiên bản đầu tiên
- 📤 Export workflows và credentials
- 📥 Import từ link backup
- ☁️ Upload file ZIP

---

**Được phát triển bởi Kha Phạm** 🚀
