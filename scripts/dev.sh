#!/bin/bash

# سكريبت تشغيل بيئة التطوير للمشروع (فرونت إند وباك إند معًا)

echo "🚀 بدء تشغيل بيئة التطوير..."

# في حالة فرونت إند متكامل مع باك إند (نفس الخادم)
if [ "$1" == "integrated" ]; then
  echo "🔄 تشغيل النظام المتكامل (فرونت إند + باك إند معًا)..."
  cd server && npm run dev
else
  # تشغيل الباك إند والفرونت إند في نوافذ منفصلة
  
  # لنظام Linux/Mac (باستخدام terminator أو مُشغِّل متعدّد الأقسام)
  if [ "$(uname)" == "Darwin" ] || [ "$(uname)" == "Linux" ]; then
    echo "🖥️ تشغيل الباك إند والفرونت إند في نوافذ منفصلة..."
    
    # محاولة استخدام terminator إذا كان متاحًا
    if command -v terminator &> /dev/null; then
      terminator -e "cd $(pwd)/server && npm run dev" -e "cd $(pwd)/client && npm run dev" &
    # تحقق من توفر tmux
    elif command -v tmux &> /dev/null; then
      tmux new-session -d -s certificates "cd $(pwd)/server && npm run dev"
      tmux split-window -h "cd $(pwd)/client && npm run dev"
      tmux -2 attach-session -d
    else
      # طريقة بديلة لتشغيل الخادمين في خلفية العمل
      echo "⚠️ لم يتم العثور على terminator أو tmux، سيتم تشغيل الخادمين في خلفية العمل..."
      cd server && npm run dev &
      cd client && npm run dev &
    fi
  # لنظام Windows (نوافذ منفصلة)
  elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    echo "🖥️ تشغيل الباك إند والفرونت إند في نوافذ منفصلة..."
    start cmd /k "cd $(pwd)/server && npm run dev"
    start cmd /k "cd $(pwd)/client && npm run dev"
  else
    # حل عام يعمل في معظم البيئات (تشغيل في خلفية العمل)
    echo "⚠️ نظام التشغيل غير معروف، سيتم تشغيل الخادمين في خلفية العمل..."
    cd server && npm run dev &
    cd client && npm run dev &
  fi
fi

echo "✅ بدأت بيئة التطوير!"
echo "📡 الباك إند يعمل على المنفذ 5000"
echo "🌐 الفرونت إند يعمل على المنفذ 3000"
echo "⚠️ اضغط Ctrl+C لإيقاف بيئة التطوير"