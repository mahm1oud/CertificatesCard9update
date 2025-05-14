#!/bin/bash

# سكريبت بناء التطبيق للنشر
# هذا السكريبت يقوم ببناء الجزء الأمامي والخلفي بشكل منفصل
# يستخدم للتجهيز للنشر على مستضيف خارجي مثل هوستنجر أو VPS
# تاريخ الإنشاء: 14/05/2025

# ألوان لتحسين الإخراج
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# عرض رسالة ملونة
print_message() {
  local message=$1
  local color=$2
  echo -e "${color}${message}${NC}"
}

# عرض رسالة خطأ وإنهاء البرنامج
print_error_and_exit() {
  local message=$1
  print_message "❌ خطأ: ${message}" "${RED}"
  exit 1
}

# التحقق من تنفيذ الأمر بنجاح
check_command() {
  if [ $? -ne 0 ]; then
    print_error_and_exit "$1"
  fi
}

# إنشاء مجلد إذا لم يكن موجوداً
create_dir_if_not_exists() {
  local dir=$1
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    print_message "✅ تم إنشاء مجلد: ${dir}" "${GREEN}"
  fi
}

# البدء
print_message "🚀 بدء عملية بناء التطبيق للنشر..." "${BLUE}"
print_message "📅 التاريخ: $(date)" "${BLUE}"

# التأكد من وجود مجلدات البناء
create_dir_if_not_exists "client/dist"
create_dir_if_not_exists "server/dist"
create_dir_if_not_exists "uploads"
create_dir_if_not_exists "fonts"

# 1. بناء الواجهة الأمامية (Client)
print_message "\n🔨 بناء الواجهة الأمامية (Frontend)..." "${YELLOW}"
cd client

# تثبيت التبعيات إذا لم تكن موجودة
if [ ! -d "node_modules" ] || [ ! -f "node_modules/.package-lock.json" ]; then
  print_message "📦 تثبيت تبعيات الواجهة الأمامية..." "${YELLOW}"
  npm ci
  check_command "فشل في تثبيت تبعيات الواجهة الأمامية"
fi

# تنظيف مجلد dist
rm -rf dist/*
print_message "🧹 تم تنظيف مجلد dist الموجود في الواجهة الأمامية" "${GREEN}"

# بناء للإنتاج
print_message "🔧 بناء الواجهة الأمامية للإنتاج..." "${YELLOW}"
npm run build
check_command "فشل في بناء الواجهة الأمامية"

# التحقق من وجود ملفات البناء
if [ ! -d "dist" ] || [ ! -f "dist/index.html" ]; then
  print_error_and_exit "لم يتم إنشاء ملفات بناء الواجهة الأمامية بشكل صحيح"
fi

print_message "✅ تم بناء الواجهة الأمامية بنجاح!" "${GREEN}"
print_message "📁 حجم مجلد الإنتاج: $(du -sh dist | cut -f1)" "${GREEN}"

# العودة للمجلد الرئيسي
cd ..

# 2. بناء الخادم (Server)
print_message "\n🔨 بناء الخادم (Backend)..." "${YELLOW}"
cd server

# تثبيت التبعيات إذا لم تكن موجودة
if [ ! -d "node_modules" ] || [ ! -f "node_modules/.package-lock.json" ]; then
  print_message "📦 تثبيت تبعيات الخادم..." "${YELLOW}"
  npm ci
  check_command "فشل في تثبيت تبعيات الخادم"
fi

# تنظيف مجلد dist
rm -rf dist/*
print_message "🧹 تم تنظيف مجلد dist الموجود في الخادم" "${GREEN}"

# بناء للإنتاج
print_message "🔧 بناء الخادم للإنتاج..." "${YELLOW}"
npm run build
check_command "فشل في بناء الخادم"

# التحقق من وجود ملفات البناء
if [ ! -d "dist" ] || [ ! -f "dist/index.js" ]; then
  print_error_and_exit "لم يتم إنشاء ملفات بناء الخادم بشكل صحيح"
fi

print_message "✅ تم بناء الخادم بنجاح!" "${GREEN}"
print_message "📁 حجم مجلد الإنتاج: $(du -sh dist | cut -f1)" "${GREEN}"

# العودة للمجلد الرئيسي
cd ..

# 3. نسخ الملفات الضرورية للنشر
print_message "\n📦 تجهيز ملفات التوزيع للنشر..." "${YELLOW}"

# نسخ ملف البيئة
if [ -f "production.env" ]; then
  cp production.env .env.production
  print_message "✅ تم نسخ ملف البيئة للإنتاج" "${GREEN}"
else
  print_message "⚠️ ملف production.env غير موجود، سيتم استخدام الإعدادات الافتراضية" "${YELLOW}"
  # إنشاء ملف بيئة افتراضي للإنتاج
  cat > .env.production << EOL
NODE_ENV=production
PORT=5000
DATABASE_URL=postgres://u240955251_colluser:700125733Mm@localhost:5432/u240955251_colliderdb
SESSION_SECRET=$(openssl rand -hex 32)
UPLOAD_DIR=uploads
FONTS_DIR=fonts
API_URL=/api
EOL
  print_message "✅ تم إنشاء ملف .env.production افتراضي" "${GREEN}"
fi

# نسخ المجلدات الضرورية
print_message "📂 نسخ مجلدات الخطوط والتحميلات..." "${YELLOW}"

# التأكد من وجود المجلدات
create_dir_if_not_exists "dist"
create_dir_if_not_exists "dist/fonts"
create_dir_if_not_exists "dist/uploads"

# نسخ الخطوط
if [ -d "fonts" ]; then
  cp -r fonts/* dist/fonts/
  print_message "✅ تم نسخ مجلد الخطوط" "${GREEN}"
else
  print_message "⚠️ مجلد fonts غير موجود" "${YELLOW}"
fi

# إنشاء ملف README للنشر
cat > dist/README.md << EOL
# تطبيق الشهادات والبطاقات الإلكترونية

تم بناء هذا التطبيق بتاريخ: $(date)

## كيفية التشغيل

1. قم بتثبيت Node.js (الإصدار 20 أو أعلى)
2. قم بتثبيت PM2: \`npm install -g pm2\`
3. قم بنسخ ملف \`.env.production\` إلى \`.env\`
4. قم بتشغيل الخادم: \`pm2 start server/dist/index.js --name certificates-app\`

لمزيد من المعلومات، راجع ملف DEPLOY-VPS-GUIDE.md
EOL

print_message "✅ تم إنشاء ملف README للنشر" "${GREEN}"

# 4. تجهيز حزمة النشر النهائية
print_message "\n📦 إنشاء حزمة النشر النهائية..." "${YELLOW}"

# إنشاء حزمة tar.gz
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DEPLOY_PACKAGE="certificates-app-${TIMESTAMP}.tar.gz"

tar -czf "${DEPLOY_PACKAGE}" \
  -C client/dist . \
  -C ../server/dist . \
  -C ../dist . \
  -C .. package.json \
  -C .. .env.production \
  -C .. fonts \
  -C .. uploads \
  -C .. DEPLOY-VPS-GUIDE.md \
  --exclude="*.git*" \
  --exclude="*.DS_Store" \
  --exclude="node_modules"

check_command "فشل في إنشاء حزمة النشر"
print_message "✅ تم إنشاء حزمة النشر: ${DEPLOY_PACKAGE}" "${GREEN}"
print_message "📁 حجم حزمة النشر: $(du -sh ${DEPLOY_PACKAGE} | cut -f1)" "${GREEN}"

# 5. تعليمات النشر
print_message "\n📝 تعليمات النشر:" "${BLUE}"
print_message "1. قم بنقل الملف ${DEPLOY_PACKAGE} إلى الخادم" "${BLUE}"
print_message "2. قم بفك ضغط الحزمة: tar -xzf ${DEPLOY_PACKAGE} -C /var/www/certificates-app" "${BLUE}"
print_message "3. انتقل إلى مجلد التطبيق: cd /var/www/certificates-app" "${BLUE}"
print_message "4. قم بتثبيت التبعيات: npm ci --production" "${BLUE}"
print_message "5. قم بتشغيل الخادم: pm2 start server/dist/index.js --name certificates-app" "${BLUE}"
print_message "6. للمزيد من التفاصيل، راجع ملف DEPLOY-VPS-GUIDE.md" "${BLUE}"

print_message "\n🎉 تم بناء التطبيق وتجهيزه للنشر بنجاح!" "${GREEN}"