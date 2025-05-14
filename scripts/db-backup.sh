#!/bin/bash

# نص سكريبت النسخ الاحتياطي لقاعدة البيانات
# هذا السكريبت يقوم بإنشاء نسخة احتياطية لقاعدة البيانات
# استخدم: ./db-backup.sh [اسم_الملف_الاختياري]

# تعيين المتغيرات
BACKUP_DIR="./backups"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME=${1:-"db_backup_$DATE.sql"}

# إنشاء مجلد النسخ الاحتياطية إذا لم يكن موجودًا
mkdir -p $BACKUP_DIR

# التحقق من وجود متغير DATABASE_URL
if [ -z "$DATABASE_URL" ]; then
    # التحقق من وجود متغيرات الاتصال بقاعدة البيانات الفردية
    if [ -z "$PGHOST" ] || [ -z "$PGDATABASE" ] || [ -z "$PGUSER" ]; then
        echo "❌ خطأ: متغير DATABASE_URL غير موجود ومتغيرات الاتصال بقاعدة البيانات غير مكتملة."
        echo "الرجاء تعيين إما DATABASE_URL أو المتغيرات الفردية (PGHOST, PGDATABASE, PGUSER, PGPASSWORD)."
        exit 1
    fi
    
    # استخدام متغيرات الاتصال الفردية
    echo "🔍 استخدام متغيرات الاتصال بقاعدة البيانات الفردية..."
    
    # إنشاء نسخة احتياطية
    echo "🔄 إنشاء نسخة احتياطية لقاعدة البيانات $PGDATABASE على الخادم $PGHOST..."
    
    pg_dump -h $PGHOST -d $PGDATABASE -U $PGUSER -F c -f "$BACKUP_DIR/$FILENAME"
    
    # التحقق من نجاح عملية النسخ الاحتياطي
    if [ $? -eq 0 ]; then
        echo "✅ تم إنشاء النسخة الاحتياطية بنجاح في $BACKUP_DIR/$FILENAME"
        echo "📊 حجم النسخة الاحتياطية: $(du -h "$BACKUP_DIR/$FILENAME" | cut -f1)"
    else
        echo "❌ فشل إنشاء النسخة الاحتياطية."
        exit 1
    fi
else
    # استخدام متغير DATABASE_URL
    echo "🔍 استخدام متغير DATABASE_URL..."
    
    # إنشاء نسخة احتياطية
    echo "🔄 إنشاء نسخة احتياطية لقاعدة البيانات..."
    
    pg_dump "$DATABASE_URL" -F c -f "$BACKUP_DIR/$FILENAME"
    
    # التحقق من نجاح عملية النسخ الاحتياطي
    if [ $? -eq 0 ]; then
        echo "✅ تم إنشاء النسخة الاحتياطية بنجاح في $BACKUP_DIR/$FILENAME"
        echo "📊 حجم النسخة الاحتياطية: $(du -h "$BACKUP_DIR/$FILENAME" | cut -f1)"
    else
        echo "❌ فشل إنشاء النسخة الاحتياطية."
        exit 1
    fi
fi

# تنظيف النسخ الاحتياطية القديمة (الاحتفاظ بآخر 10 نسخ فقط)
echo "🧹 تنظيف النسخ الاحتياطية القديمة..."
NUM_BACKUPS=$(ls -1 $BACKUP_DIR/db_backup_*.sql 2>/dev/null | wc -l)

if [ $NUM_BACKUPS -gt 10 ]; then
    ls -1t $BACKUP_DIR/db_backup_*.sql | tail -n +11 | xargs rm -f
    echo "🗑️ تم حذف $(($NUM_BACKUPS - 10)) نسخة احتياطية قديمة."
else
    echo "ℹ️ عدد النسخ الاحتياطية الحالية: $NUM_BACKUPS (لا حاجة للتنظيف)"
fi

echo "🎉 تم الانتهاء من عملية النسخ الاحتياطي."

# عرض تعليمات الاستعادة
echo ""
echo "📋 لاستعادة هذه النسخة الاحتياطية، استخدم الأمر التالي:"
echo "  pg_restore -h \$PGHOST -d \$PGDATABASE -U \$PGUSER -c -v \"$BACKUP_DIR/$FILENAME\""
echo "  أو"
echo "  pg_restore -d \"\$DATABASE_URL\" -c -v \"$BACKUP_DIR/$FILENAME\""