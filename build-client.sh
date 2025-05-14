#!/bin/bash

# سكريبت بناء الواجهة الأمامية (client)
# النسخة 2.0 - تاريخ التحديث: مايو 2025
#
# التحسينات:
# - دعم وضع البناء للإنتاج أو التطوير
# - تحسين التعامل مع الأخطاء والسجلات
# - تنظيف الملفات القديمة قبل البناء
# - خيارات إضافية لتخصيص عملية البناء

# معالجة الخيارات من سطر الأوامر
BUILD_MODE="production"
VERBOSE=0
CLEAN=1
LOG_FILE="client-build-log.txt"

# دالة عرض المساعدة
show_help() {
  echo "استخدام: ./build-client.sh [OPTIONS]"
  echo ""
  echo "الخيارات:"
  echo "  -h, --help           عرض هذه الرسالة المساعدة"
  echo "  -d, --dev            بناء في وضع التطوير (الافتراضي: الإنتاج)"
  echo "  -v, --verbose        وضع التسجيل المفصل"
  echo "  --no-clean           عدم حذف الملفات السابقة قبل البناء"
  echo "  -l, --log FILE       ملف السجل المستخدم (الافتراضي: client-build-log.txt)"
  echo ""
  echo "مثال: ./build-client.sh --dev --verbose"
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
echo "# سجل بناء الواجهة الأمامية - $(date)" > "$LOG_FILE"
echo "# وضع البناء: $BUILD_MODE" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"

log "🛠️ بدء بناء الواجهة الأمامية في وضع $BUILD_MODE..."

# تصدير متغيرات البيئة للبناء
export NODE_ENV="$BUILD_MODE"

# الانتقال إلى مجلد client
cd client || {
  log "❌ فشل في الانتقال إلى مجلد client. تأكد من وجود المجلد."
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
  log "📦 تثبيت اعتماديات الواجهة الأمامية..."
  npm install
  touch node_modules/.installed
fi

# تنفيذ أمر البناء
log "⚙️ تنفيذ أمر البناء..."

if [ $VERBOSE -eq 1 ]; then
  # وضع مفصل - عرض جميع السجلات
  npx vite build | tee -a "../$LOG_FILE"
  BUILD_RESULT=${PIPESTATUS[0]}
else
  # وضع صامت - حفظ السجلات في الملف فقط
  npx vite build >> "../$LOG_FILE" 2>&1
  BUILD_RESULT=$?
fi

# التحقق من نجاح عملية البناء
if [ $BUILD_RESULT -eq 0 ]; then
  log "✅ تم بناء الواجهة الأمامية بنجاح! الملفات موجودة في client/dist"
  
  # عرض قائمة الملفات التي تم إنشاؤها
  log "📄 قائمة الملفات المنشأة:"
  ls -la dist/ | tee -a "../$LOG_FILE"
  
  # تحقق من حجم الملفات
  TOTAL_SIZE=$(du -sh dist/ | cut -f1)
  log "📊 الحجم الإجمالي للملفات المنشأة: $TOTAL_SIZE"
  
  # نسخ ملفات الواجهة الأمامية إلى مجلد الإخراج إذا تم تحديده
  if [ -n "$OUTPUT_DIR" ]; then
    log "📋 نسخ الملفات إلى مجلد الإخراج: $OUTPUT_DIR"
    mkdir -p "../$OUTPUT_DIR/client"
    cp -r dist/* "../$OUTPUT_DIR/client/"
  fi
else
  log "❌ فشل في بناء الواجهة الأمامية. تحقق من سجل البناء للحصول على المزيد من التفاصيل."
  
  # عرض الأخطاء من ملف السجل
  if [ -f "../$LOG_FILE" ]; then
    log "آخر 10 أسطر من سجل البناء:"
    tail -n 10 "../$LOG_FILE"
  fi
  
  # العودة إلى المجلد الرئيسي والخروج بخطأ
  cd ..
  exit 1
fi

# توليد ملف إحصائيات الحزمة إذا كان في وضع الإنتاج
if [ "$BUILD_MODE" = "production" ]; then
  log "📊 توليد تقرير إحصائيات الحزمة..."
  if command -v npx &> /dev/null; then
    npx vite-bundle-analyzer dist/stats.html >> "../$LOG_FILE" 2>&1 || log "⚠️ لم يمكن توليد تقرير إحصائيات الحزمة."
  fi
fi

# العودة إلى المجلد الرئيسي
cd ..

log "🎉 اكتملت عملية بناء الواجهة الأمامية بنجاح."
log "📝 تم حفظ سجل البناء الكامل في: $LOG_FILE"