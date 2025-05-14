#!/bin/bash

# سكريبت بناء الخادم (server)
# النسخة 2.0 - تاريخ التحديث: مايو 2025
#
# التحسينات:
# - دعم وضع البناء للإنتاج أو التطوير
# - تحسين التعامل مع الأخطاء والسجلات
# - تنظيف الملفات القديمة قبل البناء
# - دعم نسخ ملفات التكوين والبيئة
# - خيارات إضافية لتخصيص عملية البناء

# معالجة الخيارات من سطر الأوامر
BUILD_MODE="production"
VERBOSE=0
CLEAN=1
COPY_ENV=1
MINIFY=1
LOG_FILE="server-build-log.txt"

# دالة عرض المساعدة
show_help() {
  echo "استخدام: ./build-server.sh [OPTIONS]"
  echo ""
  echo "الخيارات:"
  echo "  -h, --help           عرض هذه الرسالة المساعدة"
  echo "  -d, --dev            بناء في وضع التطوير (الافتراضي: الإنتاج)"
  echo "  -v, --verbose        وضع التسجيل المفصل"
  echo "  --no-clean           عدم حذف الملفات السابقة قبل البناء"
  echo "  --no-env             عدم نسخ ملف البيئة إلى مجلد الإخراج"
  echo "  --no-minify          عدم تصغير الكود"
  echo "  -l, --log FILE       ملف السجل المستخدم (الافتراضي: server-build-log.txt)"
  echo ""
  echo "مثال: ./build-server.sh --dev --verbose"
  exit 0
}

# معالجة خيارات سطر الأوامر
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -d|--dev)
      BUILD_MODE="development"
      shift
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    --no-clean)
      CLEAN=0
      shift
      ;;
    --no-env)
      COPY_ENV=0
      shift
      ;;
    --no-minify)
      MINIFY=0
      shift
      ;;
    -l|--log)
      LOG_FILE="$2"
      shift 2
      ;;
    *)
      echo "❌ خيار غير معروف: $1"
      show_help
      ;;
  esac
done

# دالة لعرض رسائل مع الوقت
log() {
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $1"
  
  # إضافة السجل إلى ملف السجل أيضًا
  echo "[$timestamp] $1" >> "$LOG_FILE"
}

# إنشاء ملف سجل جديد أو تفريغه إذا كان موجودًا
echo "# سجل بناء الخادم - $(date)" > "$LOG_FILE"
echo "# وضع البناء: $BUILD_MODE" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"

log "🛠️ بدء بناء الخادم في وضع $BUILD_MODE..."

# تصدير متغيرات البيئة للبناء
export NODE_ENV="$BUILD_MODE"

# الانتقال إلى مجلد server
cd server || {
  log "❌ فشل في الانتقال إلى مجلد server. تأكد من وجود المجلد."
  exit 1
}

# تنظيف مجلد dist إذا كان مطلوبًا
if [ $CLEAN -eq 1 ]; then
  log "🧹 تنظيف مجلد dist..."
  rm -rf dist
  mkdir -p dist
else
  # إنشاء مجلد dist إذا لم يكن موجوداً
  mkdir -p dist
fi

# تثبيت الاعتماديات إذا لزم الأمر
if [ ! -d "node_modules" ] || [ ! -f "node_modules/.installed" ]; then
  log "📦 تثبيت اعتماديات الخادم..."
  npm install
  touch node_modules/.installed
fi

# إعداد خيارات البناء
BUILD_OPTIONS="--platform=node --packages=external --bundle --outdir=dist"

# إضافة خيار التصغير إذا كان مطلوبًا
if [ $MINIFY -eq 1 ]; then
  BUILD_OPTIONS="$BUILD_OPTIONS --minify"
fi

# إضافة خيار صيغة المخرج (ESM)
BUILD_OPTIONS="$BUILD_OPTIONS --format=esm"

# إضافة وضع البناء
if [ "$BUILD_MODE" = "production" ]; then
  BUILD_OPTIONS="$BUILD_OPTIONS --define:process.env.NODE_ENV=\\\"production\\\""
else
  BUILD_OPTIONS="$BUILD_OPTIONS --define:process.env.NODE_ENV=\\\"development\\\""
fi

# تنفيذ أمر البناء
log "⚙️ تنفيذ أمر البناء باستخدام esbuild..."
log "خيارات البناء: $BUILD_OPTIONS"

if [ $VERBOSE -eq 1 ]; then
  # وضع مفصل - عرض جميع السجلات
  npx esbuild index.ts $BUILD_OPTIONS | tee -a "../$LOG_FILE"
  BUILD_RESULT=${PIPESTATUS[0]}
else
  # وضع صامت - حفظ السجلات في الملف فقط
  npx esbuild index.ts $BUILD_OPTIONS >> "../$LOG_FILE" 2>&1
  BUILD_RESULT=$?
fi

# التحقق من نجاح عملية البناء
if [ $BUILD_RESULT -eq 0 ]; then
  log "✅ تم بناء الخادم بنجاح! الملفات موجودة في server/dist"
  
  # عرض قائمة الملفات التي تم إنشاؤها
  log "📄 قائمة الملفات المنشأة:"
  ls -la dist/ | tee -a "../$LOG_FILE"
  
  # تحقق من حجم الملفات
  TOTAL_SIZE=$(du -sh dist/ | cut -f1)
  log "📊 الحجم الإجمالي للملفات المنشأة: $TOTAL_SIZE"
  
  # نسخ ملفات التكوين
  log "📋 نسخ ملفات التكوين الضرورية..."
  
  # نسخ ملف البيئة إذا كان مطلوبًا
  if [ $COPY_ENV -eq 1 ] && [ -f "../.env" ]; then
    cp "../.env" dist/
    log "✅ تم نسخ ملف .env"
  fi
  
  # نسخ ملفات إضافية قد تكون مطلوبة للتشغيل
  for config_file in package.json tsconfig.json; do
    if [ -f "$config_file" ]; then
      cp "$config_file" dist/
      log "✅ تم نسخ ملف $config_file"
    fi
  done
  
  # نسخ ملفات الخادم إلى مجلد الإخراج إذا تم تحديده
  if [ -n "$OUTPUT_DIR" ]; then
    log "📋 نسخ الملفات إلى مجلد الإخراج: $OUTPUT_DIR"
    mkdir -p "../$OUTPUT_DIR/server"
    cp -r dist/* "../$OUTPUT_DIR/server/"
  fi
  
  # إنشاء ملف startup.sh لتسهيل تشغيل الخادم
  cat > dist/startup.sh << 'EOF'
#!/bin/bash
# سكريبت بدء تشغيل الخادم
echo "🚀 بدء تشغيل الخادم..."
node index.js
EOF
  chmod +x dist/startup.sh
  log "✅ تم إنشاء سكريبت بدء التشغيل: startup.sh"
  
else
  log "❌ فشل في بناء الخادم. تحقق من سجل البناء للحصول على المزيد من التفاصيل."
  
  # عرض الأخطاء من ملف السجل
  if [ -f "../$LOG_FILE" ]; then
    log "آخر 10 أسطر من سجل البناء:"
    tail -n 10 "../$LOG_FILE"
  fi
  
  # العودة إلى المجلد الرئيسي والخروج بخطأ
  cd ..
  exit 1
fi

# العودة إلى المجلد الرئيسي
cd ..

log "🎉 اكتملت عملية بناء الخادم بنجاح."
log "📝 تم حفظ سجل البناء الكامل في: $LOG_FILE"
log "🚀 لتشغيل الخادم: cd server/dist && ./startup.sh"