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
| توافق اللعبة                            | CUSA ID     | Notes                                                                           |
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
