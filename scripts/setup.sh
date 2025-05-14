#!/bin/bash

# سكريبت إعداد المشروع
# هذا السكريبت يقوم بإعداد البيئة اللازمة لتشغيل المشروع

# تحقق من وجود Node.js
echo "🔍 التحقق من وجود Node.js..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js غير مثبت. الرجاء تثبيت Node.js (الإصدار 18 أو أحدث)"
    exit 1
fi

# تحقق من إصدار Node.js
NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ إصدار Node.js قديم. الرجاء تثبيت Node.js الإصدار 18 أو أحدث"
    echo "الإصدار الحالي: $(node -v)"
    exit 1
fi

echo "✅ تم التحقق من Node.js: $(node -v)"

# إنشاء ملف .env إذا لم يكن موجودا
if [ ! -f ".env" ]; then
    echo "📝 إنشاء ملف .env من .env.example..."
    cp .env.example .env
    echo "✅ تم إنشاء ملف .env"
else
    echo "📝 ملف .env موجود بالفعل"
fi

# إنشاء المجلدات المطلوبة
echo "📁 إنشاء المجلدات المطلوبة..."
mkdir -p uploads temp fonts
echo "✅ تم إنشاء المجلدات"

# تثبيت اعتماديات المشروع
echo "📦 تثبيت اعتماديات المشروع..."
npm ci
echo "✅ تم تثبيت اعتماديات المشروع"

# التحقق من وجود PostgreSQL
echo "🔍 التحقق من وجود PostgreSQL..."
if ! command -v psql &> /dev/null; then
    echo "⚠️ PostgreSQL غير مثبت. إذا كنت تخطط لاستخدام قاعدة بيانات محلية، الرجاء تثبيت PostgreSQL"
    echo "يمكنك أيضًا استخدام Docker للحصول على قاعدة بيانات PostgreSQL دون الحاجة لتثبيتها محليًا"
else
    echo "✅ تم التحقق من PostgreSQL: $(psql --version)"
fi

# التحقق من وجود متغير DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️ متغير DATABASE_URL غير موجود في البيئة"
    echo "الرجاء تكوين قاعدة البيانات في ملف .env"
else
    echo "✅ متغير DATABASE_URL موجود"
    
    # محاولة الاتصال بقاعدة البيانات
    echo "🔄 محاولة الاتصال بقاعدة البيانات..."
    if ! psql "$DATABASE_URL" -c '\conninfo' &> /dev/null; then
        echo "⚠️ لا يمكن الاتصال بقاعدة البيانات. الرجاء التأكد من صحة متغير DATABASE_URL وأن قاعدة البيانات قيد التشغيل"
    else
        echo "✅ تم الاتصال بقاعدة البيانات بنجاح"
        
        # تحديث مخطط قاعدة البيانات
        echo "🔄 تحديث مخطط قاعدة البيانات..."
        npm run db:push
        echo "✅ تم تحديث مخطط قاعدة البيانات"
    fi
fi

# إضافة تنفيذ لسكريبتات إضافية
chmod +x scripts/*.sh

echo "🎉 تم الانتهاء من الإعداد بنجاح!"
echo ""
echo "📋 الخطوات التالية:"
echo "1. تشغيل التطبيق في وضع التطوير: npm run dev"
echo "2. تشغيل التطبيق في وضع الإنتاج: npm run build && npm start"
echo "3. تشغيل التطبيق باستخدام Docker: docker-compose up -d"