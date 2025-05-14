#!/bin/bash

# سكريبت إعداد الأصول والموارد المشتركة
# هذا السكريبت يقوم بإعداد ومزامنة الموارد المشتركة بين الواجهة الأمامية والواجهة الخلفية

# تعيين المتغيرات
FRONTEND_DIR="./client"
BACKEND_DIR="./server"
FONTS_DIR="./fonts"
SHARED_DIR="./shared"
UPLOADS_DIR="./uploads"
TEMP_DIR="./temp"

# إنشاء السجل
echo "🚀 بدء إعداد وتهيئة الموارد المشتركة..."

# التحقق من وجود المجلدات وإنشاؤها إذا لم تكن موجودة
echo "📁 التحقق من وجود المجلدات الأساسية..."
for dir in "$FONTS_DIR" "$SHARED_DIR" "$UPLOADS_DIR" "$TEMP_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "  إنشاء $dir..."
    mkdir -p "$dir"
  else
    echo "  $dir موجود بالفعل."
  fi
done

# نسخ الخطوط إلى مجلد الخادم
echo "🔤 نسخ الخطوط إلى مجلد الخادم..."
if [ -d "$FONTS_DIR" ]; then
  # التأكد من وجود مجلد الخطوط في الخادم
  mkdir -p "$BACKEND_DIR/fonts"
  
  # نسخ كل الخطوط
  echo "  نسخ الخطوط من $FONTS_DIR إلى $BACKEND_DIR/fonts"
  cp -r "$FONTS_DIR"/* "$BACKEND_DIR/fonts/" 2>/dev/null || true
  
  # التحقق من نجاح النسخ
  if [ $? -eq 0 ]; then
    echo "  ✅ تم نسخ الخطوط بنجاح."
  else
    echo "  ⚠️ لم يتم العثور على ملفات خطوط للنسخ."
  fi
else
  echo "  ⚠️ مجلد الخطوط غير موجود."
fi

# نسخ ملفات الخطوط إلى مجلدات الموارد الثابتة للواجهة الأمامية
echo "🔤 نسخ الخطوط إلى الموارد الثابتة للواجهة الأمامية..."
STATIC_FONTS_DIR="$FRONTEND_DIR/static/fonts"

# إنشاء مجلد الخطوط في الموارد الثابتة إذا لم يكن موجودًا
mkdir -p "$STATIC_FONTS_DIR"

# نسخ الخطوط إلى مجلد الموارد الثابتة
if [ -d "$FONTS_DIR" ]; then
  echo "  نسخ الخطوط من $FONTS_DIR إلى $STATIC_FONTS_DIR"
  cp -r "$FONTS_DIR"/* "$STATIC_FONTS_DIR/" 2>/dev/null || true
  
  # التحقق من نجاح النسخ
  if [ $? -eq 0 ]; then
    echo "  ✅ تم نسخ الخطوط إلى الموارد الثابتة بنجاح."
  else
    echo "  ⚠️ لم يتم العثور على ملفات خطوط للنسخ."
  fi
fi

# التأكد من وجود ملف CSS للخطوط في الواجهة الأمامية
FONTS_CSS="$FRONTEND_DIR/src/index.css"
if [ -f "$FONTS_CSS" ]; then
  echo "✅ ملف CSS للخطوط موجود بالفعل."
else
  echo "⚠️ ملف CSS للخطوط غير موجود. يرجى إنشاء ملف لتعريف الخطوط."
fi

# التحقق من مجلد التحميلات وإنشاء روابط رمزية إذا كان ذلك مطلوبًا
echo "🔄 إعداد مجلد التحميلات..."
if [ -d "$UPLOADS_DIR" ]; then
  # إذا كان المشروع يعمل في وضع التطوير وتم فصل الخادم عن الواجهة الأمامية
  # يمكن إنشاء رابط رمزي لمجلد التحميلات في المجلد الثابت للواجهة الأمامية
  STATIC_UPLOADS_DIR="$FRONTEND_DIR/static/uploads"
  
  # إنشاء مجلد في الموارد الثابتة إذا لم يكن موجودًا
  mkdir -p "$STATIC_UPLOADS_DIR"
  
  # نسخ ملفات التحميلات إلى الموارد الثابتة (فقط للتطوير)
  if [ "$NODE_ENV" != "production" ]; then
    echo "  نسخ ملفات التحميلات من $UPLOADS_DIR إلى $STATIC_UPLOADS_DIR (وضع التطوير)"
    cp -r "$UPLOADS_DIR"/* "$STATIC_UPLOADS_DIR/" 2>/dev/null || true
  fi
fi

# التحقق من وجود ملفات المخططات المشتركة
echo "📊 التحقق من ملفات المخططات المشتركة..."
if [ -d "$SHARED_DIR" ]; then
  if [ -f "$SHARED_DIR/schema.ts" ]; then
    echo "  ✅ ملف المخطط الرئيسي موجود."
  else
    echo "  ⚠️ ملف schema.ts غير موجود في مجلد المشاركة."
  fi
else
  echo "  ⚠️ مجلد المشاركة غير موجود."
fi

echo "🎉 تم الانتهاء من إعداد وتهيئة الموارد المشتركة بنجاح!"