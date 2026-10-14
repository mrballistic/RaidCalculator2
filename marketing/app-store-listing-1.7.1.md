# App Store listing: RAID Calculator 1.7.1

Record “RAID calculator” (Apple ID 395601653, bundle ID `53Q4825KDF`).

1.7.1 is a store-page release: the app is 1.7.0 with only the version number changed. It exists so the localized screenshots can ship.

## Copy

Use the 1.7.0 copy unchanged, in every language: name, subtitle, promotional text, description, keywords and What’s New. That copy lives in `marketing/app-store-listing.md`. The record already carries the localized copy for each language.

## Screenshots

| Language | iPhone 6.9″ (1320 × 2868), 6.3″ (1206 × 2622), 6.1″ (1179 × 2556) | iPad 13″ (2064 × 2752) | iPhone Duo |
|---|---|---|---|
| English | `marketing/screenshots/1.7.0/store/iphone-*` | `…/1.7.0/store/ipad-2064x2752` | `…/1.7.0/store/duo-*` |
| es, fr, it, ja, de, zh-Hant, zh-Hans, ko, pt-BR | `marketing/screenshots/1.7.1/store/<lang>/iphone-*` | `…/1.7.1/store/<lang>/ipad-2064x2752` | the English 1.7.0 Duo sets |

- Each localized set is the same six iPhone scenes and three iPad scenes as English. The app runs in that language, and each headline is translated using the app’s own terms.
- Duo stays English for every language, because its poses can’t be scripted.
- Each folder has a contact sheet: `contact-<set>.png`.
- To rebuild a set: `scripts/store-assets/capture_localized.sh iphone|ipad <lang>…` (see `scripts/store-assets/README.md`).

## App Review notes for 1.7.1

> This update only localizes the App Store page: it adds screenshots in each of the app’s ten languages. No code changed apart from the version number (1.7.0 to 1.7.1). The app works fully offline with no account, as in 1.7.0.
