#!/bin/bash

# سكريبت شامل لبناء وتجميع المشروع للنشر
# النسخة 2.0 - تاريخ التحديث: مايو 2025
#
# التحسينات:
# - دعم متغيرات البيئة
# - إضافة معالجة الأخطاء المحسنة
# - دعم وضع التشغيل الصامت
# - التكامل مع ملفات التثبيت والنشر
# - فحص المتطلبات المسبقة قبل البدء

# معالجة الخيارات من سطر الأوامر
SILENT_MODE=0
ENV_FILE=".env"
SKIP_CLIENT=0
SKIP_SERVER=0
SKIP_PACKAGE=0
OUTPUT_DIR="build"

# دالة عرض المساعدة
show_help() {
  echo "استخدام: ./build-all.sh [OPTIONS]"
  echo ""
  echo "الخيارات:"
  echo "  -h, --help            عرض هذه الرسالة المساعدة"
  echo "  -s, --silent          وضع التشغيل الصامت (بدون مطالبات)"
  echo "  -e, --env FILE        تحديد ملف البيئة المستخدم (الافتراضي: .env)"
  echo "  --skip-client         تخطي بناء واجهة المستخدم"
  echo "  --skip-server         تخطي بناء الخادم"
  echo "  --skip-package        تخطي تجميع الملفات للنشر"
  echo "  -o, --output DIR      مجلد الإخراج للملفات المجمعة (الافتراضي: build)"
  echo ""
  echo "مثال: ./build-all.sh --env .env.production --output dist"
  exit 0
}

# معالجة خيارات سطر الأوامر
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -s|--silent)
      SILENT_MODE=1
      shift
      ;;
    -e|--env)
      ENV_FILE="$2"
      shift 2
      ;;
    --skip-client)
      SKIP_CLIENT=1
      shift
      ;;
    --skip-server)
      SKIP_SERVER=1
      shift
      ;;
    --skip-package)
      SKIP_PACKAGE=1
      shift
      ;;
    -o|--output)
      OUTPUT_DIR="$2"
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
}

# دالة التأكيد
confirm() {
  if [[ $SILENT_MODE -eq 1 ]]; then
    return 0
  fi
  
  read -p "$1 (y/n): " response
  case "$response" in
    [yY][eE][sS]|[yY]) 
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# التحقق من المتطلبات المسبقة
check_prerequisites() {
  log "🔍 التحقق من المتطلبات المسبقة..."
  
  # التحقق من وجود Node.js
  if ! command -v node &> /dev/null; then
    log "❌ Node.js غير مثبت. الرجاء تثبيته قبل المتابعة."
    exit 1
  fi
  
  # التحقق من وجود npm
  if ! command -v npm &> /dev/null; then
    log "❌ npm غير مثبت. الرجاء تثبيته قبل المتابعة."
    exit 1
  fi
  
  # التحقق من وجود السكريبتات الضرورية
  if [[ $SKIP_CLIENT -eq 0 ]] && [[ ! -f "client/build-dist.sh" ]]; then
    log "❌ سكريبت بناء الواجهة الأمامية غير موجود: client/build-dist.sh"
    exit 1
  fi
  
  if [[ $SKIP_SERVER -eq 0 ]] && [[ ! -f "server/build-dist.sh" ]]; then
    log "❌ سكريبت بناء الخادم غير موجود: server/build-dist.sh"
    exit 1
  fi
  
  if [[ $SKIP_PACKAGE -eq 0 ]] && [[ ! -f "package-files.sh" ]]; then
    log "❌ سكريبت تجميع الملفات غير موجود: package-files.sh"
    exit 1
  fi
  
  # التحقق من وجود ملف البيئة
  if [[ ! -f "$ENV_FILE" ]] && [[ ! $SILENT_MODE -eq 1 ]]; then
    if confirm "⚠️ ملف البيئة ($ENV_FILE) غير موجود. هل ترغب في إنشائه من القالب?"; then
      # استيراد سكريبت إنشاء ملف البيئة
      if [[ -f "install/scripts/install.js" ]]; then
        log "🔄 جاري إنشاء ملف البيئة من القالب..."
        node install/scripts/install.js --env-only
      else
        # نسخ القالب مباشرة إذا كان موجوداً
        if [[ -f "install/config/env.template" ]]; then
          cp install/config/env.template "$ENV_FILE"
          log "✅ تم إنشاء ملف البيئة من القالب: $ENV_FILE"
        else
          log "❌ قالب ملف البيئة غير موجود. الرجاء إنشاء ملف $ENV_FILE يدوياً."
          exit 1
        fi
      fi
    fi
  fi
  
  log "✅ تم التحقق من جميع المتطلبات المسبقة بنجاح."
}

# توحيد المجلدات المهمة
create_directories() {
  log "📁 إنشاء المجلدات اللازمة..."
  
  # المجلدات اللازمة للتطبيق
  mkdir -p logs uploads temp fonts
  
  # مجلد الإخراج النهائي
  mkdir -p "$OUTPUT_DIR"
  
  log "✅ تم إنشاء جميع المجلدات اللازمة."
}

# تنفيذ صلاحيات التنفيذ للسكريبتات
setup_permissions() {
  log "🔐 إعداد صلاحيات التنفيذ للسكريبتات..."
  
  chmod +x client/build-dist.sh server/build-dist.sh package-files.sh
  
  # إعطاء صلاحيات التنفيذ أيضًا لسكريبتات التثبيت والنشر
  if [[ -d "install/scripts" ]]; then
    find install/scripts -name "*.sh" -exec chmod +x {} \;
    log "✅ تم إعداد صلاحيات التنفيذ لسكريبتات التثبيت والنشر."
  fi
  
  log "✅ تم إعداد صلاحيات التنفيذ للسكريبتات."
}

# بناء الواجهة الأمامية
build_client() {
  if [[ $SKIP_CLIENT -eq 1 ]]; then
    log "⏩ تم تخطي بناء الواجهة الأمامية بناءً على الخيارات."
    return 0
  fi
  
  log "🔹 خطوة 1: بناء الواجهة الأمامية"
  cd client
  ./build-dist.sh
  local client_build_result=$?
  cd ..
  
  # التحقق من نجاح بناء الواجهة
  if [[ $client_build_result -ne 0 ]] || [[ ! -d "client/dist" ]]; then
    log "❌ فشل في بناء الواجهة الأمامية."
    
    if [[ $SILENT_MODE -eq 0 ]] && confirm "هل ترغب في محاولة بناء الواجهة الأمامية مرة أخرى باستخدام build-client.sh?"; then
      ./build-client.sh
      if [[ $? -ne 0 ]]; then
        log "❌ فشل في بناء الواجهة الأمامية مرة أخرى."
        if [[ $SILENT_MODE -eq 0 ]] && ! confirm "هل ترغب في المتابعة على الرغم من فشل بناء الواجهة الأمامية?"; then
          exit 1
        fi
      else
        log "✅ تم بناء الواجهة الأمامية بنجاح في المحاولة الثانية."
      fi
    elif [[ $SILENT_MODE -eq 1 ]]; then
      log "⚠️ فشل في بناء الواجهة الأمامية. المتابعة في الوضع الصامت."
    else
      exit 1
    fi
  else
    log "✅ تم بناء الواجهة الأمامية بنجاح."
  fi
}

# بناء الخادم
build_server() {
  if [[ $SKIP_SERVER -eq 1 ]]; then
    log "⏩ تم تخطي بناء الخادم بناءً على الخيارات."
    return 0
  fi
  
  log "🔹 خطوة 2: بناء الخادم"
  cd server
  ./build-dist.sh
  local server_build_result=$?
  cd ..
  
  # التحقق من نجاح بناء الخادم
  if [[ $server_build_result -ne 0 ]] || [[ ! -d "server/dist" ]]; then
    log "❌ فشل في بناء الخادم."
    
    if [[ $SILENT_MODE -eq 0 ]] && confirm "هل ترغب في محاولة بناء الخادم مرة أخرى باستخدام build-server.sh?"; then
      ./build-server.sh
      if [[ $? -ne 0 ]]; then
        log "❌ فشل في بناء الخادم مرة أخرى."
        if [[ $SILENT_MODE -eq 0 ]] && ! confirm "هل ترغب في المتابعة على الرغم من فشل بناء الخادم?"; then
          exit 1
        fi
      else
        log "✅ تم بناء الخادم بنجاح في المحاولة الثانية."
      fi
    elif [[ $SILENT_MODE -eq 1 ]]; then
      log "⚠️ فشل في بناء الخادم. المتابعة في الوضع الصامت."
    else
      exit 1
    fi
  else
    log "✅ تم بناء الخادم بنجاح."
  fi
}

# تجميع الملفات للنشر
package_files() {
  if [[ $SKIP_PACKAGE -eq 1 ]]; then
    log "⏩ تم تخطي تجميع الملفات للنشر بناءً على الخيارات."
    return 0
  fi
  
  log "🔹 خطوة 3: تجميع الملفات للنشر في $OUTPUT_DIR"
  
  # تعديل المتغيرات البيئية لسكريبت التجميع
  export OUTPUT_DIR="$OUTPUT_DIR"
  
  ./package-files.sh
  
  if [[ $? -ne 0 ]]; then
    log "❌ فشل في تجميع الملفات للنشر."
    if [[ $SILENT_MODE -eq 0 ]] && ! confirm "هل ترغب في المتابعة على الرغم من فشل تجميع الملفات?"; then
      exit 1
    fi
  else
    log "✅ تم تجميع الملفات للنشر بنجاح."
  fi
}

# نسخ ملفات التثبيت
copy_install_files() {
  log "🔹 خطوة 4: نسخ ملفات التثبيت والإرشادات"
  
  # التأكد من وجود مجلد الإخراج
  mkdir -p "$OUTPUT_DIR/install"
  
  # نسخ ملفات التثبيت
  if [[ -d "install" ]]; then
    cp -r install/* "$OUTPUT_DIR/install/"
    log "✅ تم نسخ ملفات التثبيت."
  else
    log "⚠️ مجلد التثبيت غير موجود. تخطي نسخ ملفات التثبيت."
  fi
  
  # نسخ ملفات الإرشادات
  for doc_file in README.md HOSTINGER-DEPLOYMENT-GUIDE.md MYSQL-MIGRATION-GUIDE.md TROUBLESHOOTING-GUIDE.md DEVELOPER-GUIDE.md; do
    if [[ -f "$doc_file" ]]; then
      cp "$doc_file" "$OUTPUT_DIR/"
      log "✅ تم نسخ ملف الإرشادات: $doc_file"
    fi
  done
  
  # نسخ ملف البيئة النموذجي والسكريبتات
  if [[ -f "install/config/env.template" ]]; then
    cp "install/config/env.template" "$OUTPUT_DIR/"
    log "✅ تم نسخ ملف البيئة النموذجي."
  fi
  
  # نسخ سكريبتات البناء
  for script_file in build-all.sh build-client.sh build-server.sh package-files.sh; do
    if [[ -f "$script_file" ]]; then
      cp "$script_file" "$OUTPUT_DIR/"
      chmod +x "$OUTPUT_DIR/$script_file"
      log "✅ تم نسخ سكريبت: $script_file"
    fi
  done
}

# الوظيفة الرئيسية
main() {
  log "🚀 بدء عملية البناء الشاملة..."
  
  # التحقق من المتطلبات المسبقة
  check_prerequisites
  
  # إنشاء المجلدات اللازمة
  create_directories
  
  # إعداد صلاحيات التنفيذ
  setup_permissions
  
  # بناء الواجهة الأمامية
  build_client
  
  # بناء الخادم
  build_server
  
  # تجميع الملفات للنشر
  package_files
  
  # نسخ ملفات التثبيت والإرشادات
  copy_install_files
  
  log "🎉 تمت عملية البناء الشاملة بنجاح!"
  log "ℹ️ الملفات جاهزة للنشر في مجلد $OUTPUT_DIR"
  log "🌐 لنشر التطبيق، قم بنقل محتويات مجلد $OUTPUT_DIR إلى مجلد public_html في استضافتك"
  log "📚 لمزيد من المعلومات حول النشر، راجع HOSTINGER-DEPLOYMENT-GUIDE.md"
}

# تنفيذ البرنامج الرئيسي
main