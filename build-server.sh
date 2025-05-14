#!/bin/bash

# سكريبت بناء الخادم فقط (الجانب الخلفي)
# 
# هذا السكريبت يقوم ببناء الخادم (Node.js + TypeScript) وإعداده للنشر

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

log "بدء عملية بناء الخادم..."

# إنشاء مجلدات الإخراج إذا لم تكن موجودة
log "إنشاء مجلدات الإخراج..."
mkdir -p dist/server
mkdir -p dist/shared

# بناء الخادم (Node.js + TypeScript)
log "بناء الخادم (Node.js)..."
npx tsc -p server/tsconfig.json
if [ $? -ne 0 ]; then
  log "حدث خطأ أثناء بناء الخادم" "error"
  exit 1
fi
log "تم بناء الخادم بنجاح" "success"

# بناء الملفات المشتركة
log "بناء الملفات المشتركة..."
npx tsc -p shared/tsconfig.json
if [ $? -ne 0 ]; then
  log "حدث خطأ أثناء بناء الملفات المشتركة" "error"
  exit 1
fi
log "تم بناء الملفات المشتركة بنجاح" "success"

# نسخ ملفات البناء إلى مجلدات الإخراج
log "نسخ ملفات البناء إلى مجلدات الإخراج..."
cp -r server/dist/* dist/server/
cp -r shared/dist/* dist/shared/

# نسخ ملفات الضبط والإعدادات
log "نسخ ملفات الضبط والإعدادات..."
cp package.json dist/
cp production.env dist/.env
cp -r deployment dist/

# إنشاء مجلدات التخزين المطلوبة
log "إنشاء مجلدات التخزين المطلوبة..."
mkdir -p dist/fonts
cp -r fonts/* dist/fonts/
mkdir -p dist/uploads/logos
mkdir -p dist/uploads/signatures
mkdir -p dist/uploads/certificates
mkdir -p dist/uploads/temp
chmod -R 755 dist/uploads

log "تم الانتهاء من بناء الخادم بنجاح!" "success"
log "ملفات البناء متاحة في مجلد 'dist'" "info"
log "لتشغيل الخادم في بيئة الإنتاج:" "info"
log "  cd dist" "info"
log "  npm install --production" "info"
log "  node server/index.js" "info"