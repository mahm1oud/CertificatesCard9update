#!/bin/bash

# سكريبت نسخ الأصول المشتركة
# يستخدم هذا السكريبت لنسخ المجلدات المشتركة (fonts, shared, uploads) إلى مجلد التوزيع للواجهة الخلفية

echo "🔄 نسخ الأصول المشتركة إلى مجلد التوزيع للواجهة الخلفية..."

# إنشاء مجلد التوزيع للواجهة الخلفية إذا لم يكن موجودًا
mkdir -p server/dist

# نسخ مجلد shared
if [ -d "shared" ]; then
  echo "📁 نسخ مجلد shared..."
  mkdir -p server/dist/shared
  cp -r shared/* server/dist/shared/
  echo "✅ تم نسخ مجلد shared بنجاح."
else
  echo "⚠️ مجلد shared غير موجود. لن يتم نسخ المجلد."
fi

# نسخ مجلد fonts
if [ -d "fonts" ]; then
  echo "📁 نسخ مجلد fonts..."
  mkdir -p server/dist/fonts
  cp -r fonts/* server/dist/fonts/
  echo "✅ تم نسخ مجلد fonts بنجاح."
else
  echo "⚠️ مجلد fonts غير موجود. لن يتم نسخ المجلد."
fi

# إنشاء مجلد uploads في مجلد التوزيع
echo "📁 إنشاء مجلد uploads في مجلد التوزيع..."
mkdir -p server/dist/uploads
mkdir -p server/dist/uploads/generated
mkdir -p server/dist/uploads/logos
mkdir -p server/dist/uploads/signatures
mkdir -p server/dist/uploads/images

# نسخ ملف التكوين لمجلد uploads إذا كان موجودًا
if [ -f "uploads/config.json" ]; then
  cp uploads/config.json server/dist/uploads/
  echo "✅ تم نسخ ملف config.json إلى مجلد uploads في مجلد التوزيع."
fi

# إنشاء مجلد temp في مجلد التوزيع
echo "📁 إنشاء مجلد temp في مجلد التوزيع..."
mkdir -p server/dist/temp

# نسخ ملفات package.json للواجهة الخلفية
if [ -f "server/package.json" ]; then
  echo "📄 نسخ ملف package.json للواجهة الخلفية..."
  cp server/package.json server/dist/
  echo "✅ تم نسخ ملف package.json للواجهة الخلفية بنجاح."
else
  echo "⚠️ ملف package.json للواجهة الخلفية غير موجود. لن يتم نسخ الملف."
fi

# إنشاء ملف README.md في مجلد التوزيع
echo "📝 إنشاء ملف README.md في مجلد التوزيع..."
echo "# واجهة خلفية لتطبيق \"نظام إصدار البطاقات والشهادات\"

تم بناء هذا المجلد باستخدام سكريبت البناء \`build.sh\`. يحتوي على الملفات اللازمة لتشغيل الواجهة الخلفية للتطبيق.

## كيفية التشغيل

1. قم بتثبيت الإعتماديات:
   \`\`\`bash
   npm install --production
   \`\`\`

2. قم بتشغيل الواجهة الخلفية:
   \`\`\`bash
   node index.js
   \`\`\`

## ملاحظات هامة

- تأكد من تكوين ملف \`.env\` بشكل صحيح قبل التشغيل.
- تأكد من وجود قاعدة بيانات PostgreSQL وتكوينها بشكل صحيح.
- تأكد من وجود المجلدات المشتركة (\`fonts\`, \`shared\`, \`uploads\`) وتكوينها بشكل صحيح." > server/dist/README.md

echo "✅ تم نسخ الأصول المشتركة بنجاح!"