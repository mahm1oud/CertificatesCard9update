#!/bin/bash

# سكريبت بناء المشروع للنشر
# يستخدم هذا السكريبت لبناء الواجهة الأمامية والخلفية وإعداد الملفات للنشر

echo "🔧 بدء عملية البناء..."

# التحقق من وجود المجلدات المشتركة ومجلد التوزيع
bash scripts/configure-assets.sh

# إنشاء مجلدات التوزيع إذا لم تكن موجودة
mkdir -p client/dist
mkdir -p server/dist

# التحقق من وجود ملفات متغيرات البيئة وإنشاؤها إذا لم تكن موجودة
bash scripts/create-env-files.sh

# بناء الواجهة الأمامية
echo "🔨 بناء الواجهة الأمامية (Frontend)..."
cd client

# محاولة بناء الواجهة الأمامية
npm run build 2>&1 | tee ../client-build-log.txt

# التحقق من نجاح عملية البناء
if [ ! -f "dist/index.html" ]; then
  echo "❌ فشل بناء الواجهة الأمامية. يرجى التحقق من سجل البناء في client-build-log.txt."
  exit 1
else
  echo "✅ تم بناء الواجهة الأمامية بنجاح."
fi

cd ..

# بناء الواجهة الخلفية
echo "🔨 بناء الواجهة الخلفية (Backend)..."
cd server

# محاولة بناء الواجهة الخلفية
npm run build 2>&1 | tee ../server-build-log.txt

# التحقق من نجاح عملية البناء
if [ ! -f "dist/index.js" ]; then
  echo "❌ فشل بناء الواجهة الخلفية. يرجى التحقق من سجل البناء في server-build-log.txt."
  exit 1
else
  echo "✅ تم بناء الواجهة الخلفية بنجاح."
fi

cd ..

# نسخ المجلدات المشتركة إلى مجلد التوزيع للواجهة الخلفية
echo "📦 نسخ المجلدات المشتركة إلى مجلد التوزيع للواجهة الخلفية..."
bash scripts/copy-assets.sh

# نسخ ملفات متغيرات البيئة للإنتاج
echo "📝 نسخ ملفات متغيرات البيئة للإنتاج..."
if [ -f "client/.env.production" ]; then
  cp client/.env.production client/dist/.env
  echo "✅ تم نسخ ملف client/.env.production إلى client/dist/.env."
else
  echo "⚠️ ملف client/.env.production غير موجود. لن يتم نسخ ملف متغيرات البيئة للإنتاج للواجهة الأمامية."
fi

if [ -f "server/.env.production" ]; then
  cp server/.env.production server/dist/.env
  echo "✅ تم نسخ ملف server/.env.production إلى server/dist/.env."
else
  echo "⚠️ ملف server/.env.production غير موجود. لن يتم نسخ ملف متغيرات البيئة للإنتاج للواجهة الخلفية."
fi

echo "🎉 تمت عملية البناء بنجاح!"
echo "📁 الملفات الناتجة:"
echo "  - واجهة أمامية: ./client/dist/"
echo "  - واجهة خلفية: ./server/dist/"
echo ""
echo "📚 لمزيد من المعلومات حول النشر، راجع ملف DEPLOY.md أو README-DEPLOYMENT.md"