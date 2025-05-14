import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import ws from "ws";
import * as schema from "@shared/schema";
import * as dotenv from 'dotenv';
import * as fs from 'fs';
import * as path from 'path';

// تحميل متغيرات البيئة المناسبة (من ملف .env في بيئة التطوير أو من production.env في بيئة الإنتاج)
if (process.env.NODE_ENV === 'production') {
  const envPath = path.resolve(process.cwd(), 'production.env');
  if (fs.existsSync(envPath)) {
    const envConfig = dotenv.parse(fs.readFileSync(envPath));
    for (const key in envConfig) {
      process.env[key] = envConfig[key];
    }
    console.log('✅ تم تحميل ملف production.env بنجاح');
  } else {
    console.warn('⚠️ لم يتم العثور على ملف production.env');
  }
} else {
  dotenv.config();
  console.log('✅ تم تحميل ملف .env بنجاح');
}

// ضبط إعدادات Neon PostgreSQL إذا كنا نستخدم Neon
if (process.env.DATABASE_URL?.includes('neon')) {
  neonConfig.webSocketConstructor = ws;
  console.log('✅ تم ضبط إعدادات Neon PostgreSQL');
}

// التحقق من وجود عنوان قاعدة البيانات
if (!process.env.DATABASE_URL) {
  throw new Error(
    "DATABASE_URL غير محدد. هل نسيت تكوين قاعدة البيانات؟"
  );
}

// إنشاء اتصال بقاعدة البيانات
export const pool = new Pool({ 
  connectionString: process.env.DATABASE_URL,
  max: 10, // الحد الأقصى لعدد الاتصالات في المجمع
  idleTimeoutMillis: 30000, // وقت الخمول قبل إغلاق اتصال غير مستخدم
  connectionTimeoutMillis: 10000 // وقت انتهاء المهلة عند محاولة إنشاء اتصال جديد
});

// التحقق من نجاح الاتصال بقاعدة البيانات
pool.query('SELECT NOW()').then(() => {
  console.log('✅ تم التحقق من صحة اتصال قاعدة البيانات');
}).catch(err => {
  console.error('❌ فشل الاتصال بقاعدة البيانات:', err);
});

// إنشاء كائن drizzle للتعامل مع قاعدة البيانات
export const db = drizzle({ client: pool, schema });

console.log('✅ تم إنشاء اتصال قاعدة البيانات بنجاح');

// معلومات حول قاعدة البيانات
console.log('==== معلومات قاعدة البيانات ====');
console.log('🌐 البيئة:', process.env.NODE_ENV === 'production' ? 'إنتاج' : 'تطوير (Replit)');
console.log('🔄 نوع قاعدة البيانات:', process.env.DATABASE_URL.includes('neon') ? 'neon-postgres' : 'postgres');

// دالة للتحقق من حالة الاتصال بقاعدة البيانات
export async function checkDatabaseConnection(): Promise<boolean> {
  try {
    const result = await pool.query('SELECT NOW()');
    console.log('✅ Database connection is working');
    return true;
  } catch (error) {
    console.error('❌ Database connection error:', error);
    return false;
  }
}

// تصدير مؤشرات معلومات قاعدة البيانات
export const dbInfo = {
  type: process.env.DATABASE_URL.includes('neon') ? 'neon-postgres' : 'postgres',
  environment: process.env.NODE_ENV || 'development',
  checkConnection: checkDatabaseConnection
};

// دالة لإجراء محاولات متكررة للقيام بعملية قاعدة البيانات
export async function withDatabaseRetry<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  delay: number = 1000
): Promise<T> {
  let lastError: any;
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      console.warn(`محاولة فاشلة ${attempt}/${maxRetries}:`, error);
      if (attempt < maxRetries) {
        // الانتظار قبل المحاولة التالية
        await new Promise(resolve => setTimeout(resolve, delay * attempt));
      }
    }
  }
  throw lastError;
}