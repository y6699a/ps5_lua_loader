
## PS5 Lua Loader

Fork of [remote_lua_loader](https://github.com/shahrilnet/remote_lua_loader)

Automatically loads UMTX, ELF Loader, and your ELF payloads.
Supports PS5 firmware up to 7.61.

## How to use
* Create a directory named `ps5_lua_loader`.
* Inside this directory, place your ELF payloads and an `autoload.txt` file.
    * In `autoload.txt`, list the ELF filenames you want to load (one per line).  
      Filenames are case-sensitive - make sure the names exactly match your ELF files.
    * You can add lines like `!1000` to make the loader wait 1000ms before sending the next payload.
* Put the `ps5_lua_loader` directory in one of these locations:
    * In the root of a USB drive
    * In the internal drive at `/data/ps5_lua_loader`
    * In the game’s savedata folder
* Import savedata to your game:  
  Follow the steps in [SETUP.md](SETUP.md) to prepare and import the savedata for your Lua-compatible game.
   

## Game Compatibility

Currently this loader is compatible with the following games:
  
| Game Title                            | CUSA ID     | Notes                                                                           |
|---------------------------------------|-------------|---------------------------------------------------------------------------------|
| Raspberry Cube                        | CUSA16074   |                                                                                 |
| Aibeya                                | CUSA17068   |                                                                                 |
| Hamidashi Creative                    | CUSA27389   |                                                                                 |
| Hamidashi Creative Demo               | CUSA27390   | Requires latest firmware to download from PSN                                   |
| Aikagi Kimi to Issho ni Pack          | CUSA16229   |                                                                                 |
| Aikagi 2                              | CUSA19556   |                                                                                 |
| IxSHE Tell                            | CUSA17112   |                                                                                 |
| Nora Princess and Stray Cat Heart HD  | CUSA13303   | Requires manual loading of savegame (rename `save9999.dat` to `nora_01.dat`)    |

## Credits

* shahrilnet – creator and maintainer of the original [remote_lua_loader](https://github.com/shahrilnet/remote_lua_loader)
* excellent blog [post](https://memorycorruption.net/posts/rce-lua-factorio/) where most of the ideas of lua primitives are taken from 
* flatz - for sharing ideas and lua implementations
* null_ptr - for helping to develop umtx exploit for PS5 & numerous helps with the loader development
* gezine - for sharing the vulnerable games & ideas
* specter & chendo - for webkit implementations which i refer a lot
* al-azif - parts and information grabbed from his sdk, aswell as from his ftp server
* horror - for the notification popup and ftp server payloads
* everyone else who shared their knowledge with the community
انتقل إلى المحتوى
قائمة التنقل

شفرة
طلبات السحب
الإجراءات
 16 نجمة
 19 شوكة
 0 مشاهدة
 فرع واحد
 0 علامات
 نشاط
 خصائص مخصصة
مستودع عام · متفرع من shahrilnet/remote_lua_loader
itsPLK/ps5_lua_loader
هذا الفرع متقدم بـ 23 التزامًا shahrilnet/remote_lua_loader:main.
اسم	
نجدك
نجدك
الأسبوع الماضي
البيانات المحفوظة
الأسبوع الماضي
ملف README.md
الأسبوع الماضي
SETUP.md
الأسبوع الماضي
التنقل بين ملفات المستودع
ملف README
محمل PS5 Lua
شوكة remote_lua_loader

يُحمّل تلقائيًا UMTX وELF Loader وحمولات ELF الخاصة بك. يدعم برامج PS5 الثابتة حتى الإصدار 7.61.

كيفية الاستخدام
إنشاء دليل باسم ps5_lua_loader.
داخل هذا الدليل، ضع حمولات ELF الخاصة بك وملفًا autoload.txt.
في autoload.txt، أدرج أسماء ملفات ELF التي تريد تحميلها (اسم واحد لكل سطر).
أسماء الملفات حساسة لحالة الأحرف، لذا تأكد من تطابقها تمامًا مع ملفات ELF.
يمكنك إضافة أسطر مثل !1000جعل المحمل ينتظر 1000 مللي ثانية قبل إرسال الحمولة التالية.
ضع ps5_lua_loaderالدليل في أحد هذه المواقع:
في جذر محرك أقراص USB
في محرك الأقراص الداخلي في/data/ps5_lua_loader
في مجلد البيانات المحفوظة للعبة
استيراد البيانات المحفوظة إلى لعبتك:
اتبع الخطوات الموجودة في SETUP.md لإعداد واستيراد البيانات المحفوظة للعبة المتوافقة مع Lua.
توافق اللعبة
حاليًا، هذا المحمل متوافق مع الألعاب التالية:

عنوان اللعبة	معرف CUSA	ملحوظات
مكعب التوت	CUSA16074	
أيبيا	CUSA17068	
حميداشي المبدع	CUSA27389	
حميداشي التجريبي الإبداعي	CUSA27390	يتطلب أحدث البرامج الثابتة للتنزيل من PSN
Aikagi Kimi إلى Issho ni Pack	CUSA16229	
أيكاجي 2	CUSA19556	
أخبرني	CUSA17112	
الأميرة نورا وقلب القط الضال HD	CUSA13303	يتطلب التحميل اليدوي للعبة المحفوظة (إعادة التسمية save9999.datإلى nora_01.dat)
الاعتمادات
shahrilnet – منشئ ومسؤول عن برنامج remote_lua_loader الأصلي
تدوينة ممتازة حيث تم أخذ معظم أفكار بدائيات Lua من
flatz - لمشاركة الأفكار وتنفيذات lua
null_ptr - للمساعدة في تطوير استغلال umtx لـ PS5 والعديد من المساعدات في تطوير المحمل
مجلة - لمشاركة الألعاب والأفكار الهشة
specter & chendo - لتطبيقات webkit التي أشير إليها كثيرًا
العزيف - الأجزاء والمعلومات التي تم الحصول عليها من مجموعة أدوات التطوير الخاصة به، وكذلك من خادم FTP الخاص به
الرعب - لإشعارات النافذة المنبثقة وحمولات خادم FTP
كل شخص آخر شارك معرفته مع المجتمع
اللغات
لوا
100.0%
تذييل
© 2025 GitHub, Inc.
التنقل في التذييل
شروط
خصوصية
حماية
حالة
المستندات
اتصال
إدارة ملفات تعريف الارتباط
لا تشارك معلوماتي الشخصية
itsPLK/ps5_lua_loader
