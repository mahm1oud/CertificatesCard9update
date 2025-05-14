#!/bin/bash

# سكريبت بناء الواجهة الأمامية فقط
# 
# هذا السكريبت يقوم ببناء الواجهة الأمامية (React) وإعدادها للنشر

# تعريف الألوان للمخرجات
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# طباعة رسالة ملونة
function log {
  local message=$1
  local type=${2:-"info"}
  
  case $type in
    "info")
      echo -e "${BLUE}[INFO]${NC} $message"
      ;;
    "success")
      echo -e "${GREEN}[SUCCESS]${NC} $message"
      ;;
    "warning")
      echo -e "${YELLOW}[WARNING]${NC} $message"
      ;;
    "error")
      echo -e "${RED}[ERROR]${NC} $message"
      ;;
  esac
}

log "بدء عملية بناء الواجهة الأمامية..."

# إنشاء مجلد الإخراج إذا لم يكن موجودًا
log "إنشاء مجلد الإخراج..."
mkdir -p dist/client

# بناء واجهة المستخدم (React)
log "بناء تطبيق React..."
cd client
npm run build
if [ $? -ne 0 ]; then
  log "حدث خطأ أثناء بناء تطبيق React" "error"
  exit 1
fi
cd ..
log "تم بناء تطبيق React بنجاح" "success"

# نسخ ملفات البناء إلى مجلد الإخراج
log "نسخ ملفات البناء إلى مجلد الإخراج..."
cp -r client/dist/* dist/client/

# نسخ الملفات الثابتة
log "نسخ الملفات الثابتة..."
mkdir -p dist/static
cp -r client/static/* dist/static/

log "تم الانتهاء من بناء الواجهة الأمامية بنجاح!" "success"
log "ملفات البناء متاحة في مجلد 'dist/client'" "info"