/**
 * سكريبت التحقق من اتصال قاعدة البيانات
 * 
 * استخدام السكريبت:
 * npx tsx scripts/check-db-connection.ts
 */

import '../server/lib/env-loader';
import { checkDatabaseConnection } from '../server/lib/db-adapter';
import { getDatabaseInfo } from '../server/db.mysql';

async function main() {
  console.log('🔄 جاري التحقق من اتصال قاعدة البيانات...');
  
  // عرض معلومات الاتصال المستخدمة
  const dbInfo = getDatabaseInfo();
  console.log('ℹ️ معلومات الاتصال:');
  
  // لا نعرض بيانات الاعتماد الحساسة في السجلات
  if (dbInfo.dbType === 'memory') {
    console.log('نوع قاعدة البيانات: ذاكرة مؤقتة');
    console.log('وضع الاتصال: الذاكرة المؤقتة');
    if (dbInfo.message) {
      console.log('ملاحظة:', dbInfo.message);
    }
  } else if (dbInfo.dbType === 'mysql') {
    console.log('نوع قاعدة البيانات: MySQL');
    console.log(`المضيف: ${dbInfo.host}`);
    console.log(`المنفذ: ${dbInfo.port}`);
    console.log(`قاعدة البيانات: ${dbInfo.database || 'غير محدد'}`);
    console.log(`المستخدم: ${dbInfo.user || 'غير محدد'}`);
    console.log('كلمة المرور: ******* (مخفية)');
    console.log(`SSL: ${dbInfo.usingSsl ? 'مفعّل' : 'غير مفعّل'}`);
  } else if (dbInfo.dbType === 'postgres') {
    console.log('نوع قاعدة البيانات: PostgreSQL');
    console.log(`رابط الاتصال: ${dbInfo.url?.replace(/:\/\/[^:]+:[^@]+@/, '://****:****@') || 'غير محدد'}`);
  } else {
    console.log('نوع قاعدة البيانات: غير معروف');
  }
  
  // التحقق من الاتصال
  try {
    const isConnected = await checkDatabaseConnection();
    
    if (isConnected) {
      console.log('✅ تم الاتصال بقاعدة البيانات بنجاح!');
      process.exit(0);
    } else {
      console.error('❌ فشل الاتصال بقاعدة البيانات!');
      
      if (dbInfo.dbType === 'memory') {
        console.log('ℹ️ التطبيق يعمل في وضع الذاكرة المؤقتة. البيانات لن تُحفظ بعد إعادة تشغيل التطبيق.');
      } else {
        console.log('ℹ️ تحقق من صحة بيانات الاتصال في ملف .env أو hostinger.config.js');
      }
      
      process.exit(1);
    }
  } catch (error) {
    console.error('❌ حدث خطأ أثناء التحقق من الاتصال:', error);
    process.exit(1);
  }
}

main();