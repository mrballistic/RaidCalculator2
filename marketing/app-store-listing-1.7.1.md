# App Store listing: RAID Calculator 1.7.1

Record “RAID calculator” (Apple ID 395601653, bundle ID `53Q4825KDF`).

1.7.1 adds Russian to the app (eleven languages in all) and localizes the App Store page: screenshots and header images in every language, with the app running in that language. Nothing else in the app changed.

## Copy

- **Every language except Russian:** keep the 1.7.0 copy (name, subtitle, promotional text, description, keywords) with two changes:
  - **What’s New:** replace it with the line below.
  - **Description:** replace the languages bullet with the one below. The English is in `marketing/app-store-listing.md`; the other languages are already on the record.
- **Russian (`ru`):** a new localization on the record. All of its copy is in the Russian section below.

| Language | What’s New | Languages bullet in the description |
|---|---|---|
| English | RAID Calculator now speaks Russian, for eleven languages in all. The App Store page now shows the app in your language, too. | • English, Spanish, French, Italian, Japanese, German, Traditional and Simplified Chinese, Korean, Brazilian Portuguese and Russian |
| Spanish (`es`) | RAID Calculator ahora habla ruso, con un total de once idiomas. Además, la página del App Store ya muestra la app en tu idioma. | • Inglés, español, francés, italiano, japonés, alemán, chino tradicional y simplificado, coreano, portugués de Brasil y ruso |
| French (`fr`) | RAID Calculator parle désormais russe, soit onze langues au total. La page de l’App Store présente aussi l’app dans votre langue. | • Anglais, espagnol, français, italien, japonais, allemand, chinois traditionnel et simplifié, coréen, portugais du Brésil et russe |
| Italian (`it`) | RAID Calculator ora parla anche russo, per un totale di undici lingue. E la pagina dell’App Store ora mostra l’app nella tua lingua. | • Inglese, spagnolo, francese, italiano, giapponese, tedesco, cinese tradizionale e semplificato, coreano, portoghese brasiliano e russo |
| Japanese (`ja`) | RAID Calculatorがロシア語に対応し、全部で11言語になりました。App Storeのページも、お使いの言語でアプリを紹介するようになりました。 | • 英語、スペイン語、フランス語、イタリア語、日本語、ドイツ語、中国語（繁体字・簡体字）、韓国語、ポルトガル語（ブラジル）、ロシア語 |
| German (`de`) | RAID Calculator spricht jetzt Russisch, damit sind es insgesamt elf Sprachen. Auch die App-Store-Seite zeigt die App jetzt in deiner Sprache. | • Englisch, Spanisch, Französisch, Italienisch, Japanisch, Deutsch, Traditionelles und Vereinfachtes Chinesisch, Koreanisch, Brasilianisches Portugiesisch und Russisch |
| Chinese, Traditional (`zh-Hant`) | RAID Calculator 現在支援俄文，共提供十一種語言。App Store 頁面現在也會以你的語言介紹本 App。 | • 英文、西班牙文、法文、義大利文、日文、德文、繁體中文、簡體中文、韓文、巴西葡萄牙文和俄文 |
| Chinese, Simplified (`zh-Hans`) | RAID Calculator 现已支持俄语，共提供十一种语言。App Store 页面现在也会用你的语言介绍本 App。 | • 英语、西班牙语、法语、意大利语、日语、德语、繁体中文、简体中文、韩语、巴西葡萄牙语和俄语 |
| Korean (`ko`) | 이제 RAID Calculator가 러시아어를 지원하여 모두 11개 언어를 지원합니다. App Store 페이지에서도 사용자의 언어로 앱을 소개합니다. | • 영어, 스페인어, 프랑스어, 이탈리아어, 일본어, 독일어, 중국어 번체 및 간체, 한국어, 브라질 포르투갈어, 러시아어 |
| Brazilian Portuguese (`pt-BR`) | O RAID Calculator agora fala russo, somando onze idiomas. A página da App Store também mostra o app no seu idioma. | • Inglês, espanhol, francês, italiano, japonês, alemão, chinês tradicional, chinês simplificado, coreano, português do Brasil e russo |

All of these follow the store rules: no em dashes; “iPhone” and “iPad” exactly so. They are machine-assisted and want a native speaker’s check before submission, like the 1.7.0 listings.

## Screenshots

| Language | iPhone 6.9″ (1320 × 2868), 6.3″ (1206 × 2622), 6.1″ (1179 × 2556) | iPad 13″ (2064 × 2752) | Header and search | iPhone Duo |
|---|---|---|---|---|
| English | `marketing/screenshots/1.7.0/store/iphone-*` | `…/1.7.0/store/ipad-2064x2752` | `…/1.7.0/store/header` | `…/1.7.0/store/duo-*` |
| es, fr, it, ja, de, zh-Hant, zh-Hans, ko, pt-BR, ru | `marketing/screenshots/1.7.1/store/<lang>/iphone-*` | `…/1.7.1/store/<lang>/ipad-2064x2752` | `…/1.7.1/store/<lang>/header` | the English 1.7.0 Duo sets |

- Each localized set has the same six iPhone scenes and three iPad scenes as English. Every headline is translated, using the app’s own terms.
- Duo stays English in every language, because its poses can’t be scripted.
- Each folder has a contact sheet, `contact-<set>.png`.
- To rebuild a set, run `scripts/store-assets/capture_localized.sh iphone|ipad <lang>…`.

## App Review notes for 1.7.1

> This update adds a Russian localization of the app and localizes the App Store page with screenshots in each of the app’s eleven languages. No functionality changed: apart from the version number (1.7.0 to 1.7.1), the only code change is the new Russian strings. The app works fully offline with no account, as in 1.7.0.

## Russian (`ru`)

### Name (30)

> RAID Calculator

15 chars.

### Subtitle (30)

> Планировщик NAS и апгрейдов

27 chars.

### Promotional text (170)

> Теперь для iPhone Duo: на раскрытом экране результаты рядом с параметрами, а между ними линия сгиба. А ещё советы с исправлением одним касанием и 11 языков.

156 chars.

### Description (4000)

> Сколько места вы получите на самом деле? RAID Calculator ответит за секунды: и для одинаковых дисков в классическом RAID, и для разных дисков в настоящем NAS, будь то Synology, Unraid, ZFS, SnapRAID или Btrfs.
>
> ПЛАНИРУЙТЕ СЛЕДУЮЩИЙ ДИСК
> В реальных NAS диски редко бывают одинаковыми. Задайте ёмкость для каждого отсека или оставьте его пустым и посмотрите, как система распорядится дисками:
> • Пять систем: Synology SHR, SHR-2 и RAID 1, 5 или 6; Unraid; ZFS RAID-Z; SnapRAID; Btrfs RAID1
> • Каждый диск нарисован в масштабе и разделён по содержимому: данные, чётность, зеркальная копия или ничего
> • Неиспользуемая ёмкость заштрихована, а её объём указан числом
> • «Лучшее улучшение» назовёт покупку, которая даст больше всего места; примерить её можно одним касанием
> • Сохраните текущую конфигурацию, сравнивайте с ней каждое изменение («+4 TB полезной ёмкости») и верните её, когда закончите
> • Unraid и SnapRAID автоматически отводят под чётность самые большие диски
> • Для ZFS: значение, которое сообщит сама ZFS, с пометкой «оценка»
> • Советы там, где они важны: рекомендуемое SnapRAID число дисков чётности и предупреждение об очень широких группах RAID-Z
> • От 2 до 12 отсеков для Synology или до 30 для Unraid, ZFS, SnapRAID и Btrfs RAID1
>
> СРАВНЕНИЕ СИСТЕМ
> Ваши диски сразу во всех системах, от самой ёмкой, с допустимыми отказами и неиспользуемым местом для каждой. Коснитесь системы, чтобы переключиться на неё, и те же отсеки распределятся заново.
>
> КЛАССИЧЕСКИЙ RAID МГНОВЕННО
> Выберите RAID 0, 1, 5, 6, 10, 50 или 60, JBOD либо ZFS RAID-Z1, Z2 или Z3, укажите от 1 до 24 дисков и их ёмкость, и ответ будет первым, что вы увидите:
> • Полезная ёмкость, общая ёмкость и эффективность хранения
> • Полоса дисков: где данные, чётность и зеркальные копии, с разбивкой на группы для вложенных уровней и RAID-Z
> • Сколько дисков может отказать, честно и для случаев, когда это зависит от того, какие диски откажут
> • Значение в TiB, которое покажет большинство NAS, а для RAID-Z значение, которое покажет сама ZFS
> • Предупреждение о риске восстановления при одинарной чётности на больших дисках и переход на более надёжный уровень одним касанием, если диски позволяют
> • Недопустимая конфигурация объясняет ошибку и предлагает исправление одним касанием
> • Оценки скорости и доступности для каждого уровня
>
> УЧИТЕСЬ ПО ХОДУ ДЕЛА
> У каждого уровня RAID и каждой системы NAS есть справка: обзор, плюсы и минусы, типичные сценарии, а для уровней RAID ещё и оценки. Для RAID-Z и каждой системы NAS также объяснено, как приложение их рассчитывает.
>
> НА ЛЮБОМ ЭКРАНЕ
> • На iPad и на раскрытом в альбомной ориентации iPhone Duo результаты рядом с параметрами, а системы стоят бок о бок
> • На iPad на экране помещается до 30 отсеков
> • На iPhone Duo справка открывается на месте параметров, и результаты остаются на виду
> • Альбомная ориентация на iPhone
> • Создано для iOS 26: стандартные элементы управления и Liquid Glass
> • Тёмный режим, динамический шрифт любого размера и полная поддержка VoiceOver, которая озвучивает и каждый диск в группе
> • Английский, испанский, французский, итальянский, японский, немецкий, китайский (традиционный и упрощённый), корейский, бразильский португальский и русский
>
> КОНФИДЕНЦИАЛЬНОСТЬ ПРЕЖДЕ ВСЕГО
> Без учётной записи, рекламы и отслеживания, подключение к сети не нужно. Все расчёты выполняются на вашем устройстве.
>
> Ёмкость рассчитывается по стандартным упрощённым формулам без учёта накладных расходов файловой системы, кроме помеченной оценки для ZFS. Оценки скорости и доступности сравнивают уровни RAID между собой; это не тесты производительности.
>
> Приложение не связано с компанией Synology Inc. и не одобрено ею. Synology и SHR являются товарными знаками Synology Inc.
>
> Приложение не связано с компанией Lime Technology, Inc. и не одобрено ею. Unraid является товарным знаком Lime Technology, Inc.
>
> ZFS является товарным знаком компании Oracle и (или) её аффилированных лиц. Приложение не связано с Oracle и не одобрено этой компанией.

3954 chars.

### Keywords (100)

```
nas,рейд,raid5,raid6,raid10,raidz,jbod,калькулятор,диск,жёсткий диск,хранилище,чётность,btrfs
```

93 chars.

### What’s New in This Version (4000)

> RAID Calculator теперь говорит по-русски: всего одиннадцать языков. Страница в App Store тоже показывает приложение на вашем языке.

131 chars.
