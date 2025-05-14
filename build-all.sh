#!/bin/bash

# سكريبت توحيد عملية البناء للإنتاج
# 
# هذا السكريبت يقوم ببناء المشروع بالكامل (الواجهة الأمامية والخادم) بخطوة واحدة
# مناسب لبيئات الإنتاج والنشر على الخوادم

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

# التحقق من وجود Node.js
if ! command -v node &> /dev/null; then
  log "Node.js غير مثبت. الرجاء تثبيت Node.js قبل المتابعة." "error"
  exit 1
fi

log "بدء عملية البناء الشاملة للمشروع..."

# إنشاء مجلدات البناء إذا لم تكن موجودة
log "إنشاء مجلدات البناء..."
mkdir -p dist/client
mkdir -p dist/server
mkdir -p dist/shared

# بناء واجهة المستخدم (الجانب الأمامي)
log "بناء واجهة المستخدم (React)..."
cd client
npm run build
if [ $? -ne 0 ]; then
  log "حدث خطأ أثناء بناء واجهة المستخدم" "error"
  exit 1
fi
cd ..
log "تم بناء واجهة المستخدم بنجاح" "success"

# نسخ ملفات واجهة المستخدم المبنية إلى مجلد التوزيع
log "نسخ ملفات واجهة المستخدم إلى مجلد التوزيع..."
cp -r client/dist/* dist/client/

# بناء الخادم (الجانب الخلفي)
log "بناء الخادم (Node.js)..."
npx tsc -p server/tsconfig.json
if [ $? -ne 0 ]; then
  log "حدث خطأ أثناء بناء الخادم" "error"
  exit 1
fi
log "تم بناء الخادم بنجاح" "success"

# نسخ الملفات المشتركة
log "نسخ الملفات المشتركة..."
npx tsc -p shared/tsconfig.json
if [ $? -ne 0 ]; then
  log "حدث خطأ أثناء بناء الملفات المشتركة" "error"
  exit 1
fi
log "تم بناء الملفات المشتركة بنجاح" "success"

# نسخ ملفات الخادم المبنية إلى مجلد التوزيع
log "نسخ ملفات الخادم إلى مجلد التوزيع..."
cp -r server/dist/* dist/server/
cp -r shared/dist/* dist/shared/

# نسخ الملفات الثابتة والأصول
log "نسخ الملفات الثابتة والأصول..."
mkdir -p dist/static
cp -r client/static/* dist/static/
mkdir -p dist/fonts
cp -r fonts/* dist/fonts/
mkdir -p dist/uploads
mkdir -p dist/uploads/logos
mkdir -p dist/uploads/signatures
mkdir -p dist/uploads/certificates
mkdir -p dist/uploads/temp

# نسخ ملفات الضبط
log "نسخ ملفات الضبط..."
cp package.json dist/
cp production.env dist/.env
cp -r deployment dist/

# تثبيت اعتماديات الإنتاج
log "تثبيت اعتماديات الإنتاج..."
cd dist
npm install --production
if [ $? -ne 0 ]; then
  log "حدث خطأ أثناء تثبيت اعتماديات الإنتاج" "error"
  exit 1
fi
cd ..

log "تم الانتهاء من عملية البناء بنجاح!" "success"
log "ملفات التوزيع متاحة في مجلد 'dist'" "info"
log "لتشغيل التطبيق في بيئة الإنتاج:" "info"
log "  cd dist" "info"
log "  node server/index.js" "info"