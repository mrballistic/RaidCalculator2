# Releasing to the App Store

Builds upload to App Store Connect, where they're available for TestFlight and for App Store submission. Submitting a version for App Review stays a manual step in App Store Connect.

There are two ways to upload. **1.7.0 uses the local one**: App Store Connect rejects uploads built with a beta Xcode, and the `xcode-27` runner image carries a beta 27.1 build (27A9269), while local Xcode 27.1 is the release build (27A9275). Use the workflow (`.github/workflows/deploy.yml`, run on a `v*` tag or by hand) once the runner image's Xcode is a release build. Check with `xcodebuild -version` in a CI run and compare the build number to the one in Xcode’s About box.

## Which App Store record this ships to

The project's `PRODUCT_BUNDLE_IDENTIFIER` decides the record: App Store Connect matches an upload to the app whose bundle ID it carries. There is no separate setting in the workflow.

This codebase ships to the original **RAID calculator** record (Apple ID `395601653`, bundle ID `53Q4825KDF`, an identifier from the app's 2010 origins), not the newer **RAID Calc2** record (Apple ID `6755641457`, bundle ID `com.mrballistic.RaidCalculator2`). App Store Connect can't merge two records, so the old record simply receives new versions again:

- 1.2 is the last version that shipped on the old record. A 1.3 version is sitting in **Prepare for Submission**; rename it in App Store Connect to match the first tag you push (for example `1.4.0`), since an uploaded build's version must match a version record and must be higher than 1.3.2 to avoid confusion with RAID Calc2.
- Make sure the old record's **Pricing and Availability** is set back to available when you submit, since it's currently removed from sale.
- After the new version is live, remove RAID Calc2 from sale. People who still have the old app installed get the new version as an update; RAID Calc2 owners keep what they have.
- If `53Q4825KDF` isn't registered under the current team (developer.apple.com → Identifiers), the first archive's cloud signing will fail with a profile error. Check it's listed there before the first tag.

## One-time setup

### 1. App Store Connect API key

CI signs with Xcode's cloud-managed distribution certificate, which the key creates and uses on demand.

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** → **Team Keys** → **+**.
2. Name “GitHub Actions – RAID Calculator”, access **Admin** (cloud-managed signing needs Admin, or App Manager with access to certificates, identifiers and profiles).
3. **Download API Key** (`AuthKey_XXXXXXXXXX.p8`). It downloads once.
4. Note the **Key ID** and the **Issuer ID** (top of the page).

### 2. GitHub environment and secrets

Repository → **Settings** → **Environments** → **New environment** → `app-store`. Add yourself as a required reviewer if every upload should wait for a click, and restrict deployment to tags matching `v*`.

Environment secrets:

| Secret | Value |
|---|---|
| `ASC_KEY_ID` | Key ID from step 1 |
| `ASC_ISSUER_ID` | Issuer ID from step 1 |
| `ASC_KEY_P8_BASE64` | `base64 -i AuthKey_XXXXXXXXXX.p8 \| pbcopy` |
| `APPLE_TEAM_ID` | Team ID (Membership details on developer.apple.com; the project uses `89YJQ4UB7V`) |

The workflow checks for all four before doing anything else.

## Shipping a build

### Checklist, in order

1. **Unit tests and strings:** CI runs these on every pull request (`ios.yml`: `python3 scripts/strings.py check`, then the `RAID CalcTests` target, 30-minute cap). CI no longer runs UI tests or launch tests, because macOS minutes cost money.
2. **UI suite, locally:** run it before every release (about 15 minutes), serially, on an iPhone and on an iPad Simulator so the `testIPad*` tests run instead of skipping:

   ```bash
   xcodebuild test -project "RAID Calculator.xcodeproj" -scheme "RAID Calc" \
     -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
     -parallel-testing-enabled NO -only-testing:"RAID CalcUITests"
   ```

   Then do the manual Reduce Motion pass on iPhone and iPad.
3. **Store assets:** capture and compose with `scripts/store-assets/` (README there; deliverables and sizes in `docs/app-store-assets-brief.md`). Check every PNG’s size and that it has no alpha channel.
4. **Listings:** have a native speaker check the localized listings before submission. Don’t submit machine translations unreviewed.
5. **Featuring nomination:** draft it in App Store Connect once the version is in. It needs 3 weeks’ lead time, so submit it as early as the build and assets allow.
6. **Archive and upload (local, as for 1.7.0):** in Xcode 27.1 (release build, not a beta), select **Any iOS Device**, choose Product → Archive, then Distribute App → App Store Connect → Upload. Set the marketing version first (the project’s `MARKETING_VERSION`) and make the build number higher than any uploaded for that version.
7. **Or archive and upload from CI:** only when the runner’s Xcode is a release build.

   ```sh
   git tag v1.4.0
   git push origin v1.4.0
   ```

   Or **Actions → Deploy to App Store Connect → Run workflow** (uses `MARKETING_VERSION` from the project). The workflow:

   1. Runs the CI gate (`ios.yml`: strings check and unit tests only).
   2. Archives Release for `generic/platform=iOS` with automatic signing through the API key. The tag sets the marketing version (`v1.4.0` → `1.4.0`); the build number is the workflow's run number, so it always increases.
   3. Exports with `ExportOptions.plist` (`app-store-connect`, `upload`), which uploads to App Store Connect, then deletes the key and writes a summary.
8. **Submit:** processing takes 5–20 minutes. Then, in App Store Connect, open the version page, select the build and **Add for Review**. No export-compliance question appears: `ITSAppUsesNonExemptEncryption` is `NO`.
9. **Website:** once the version is approved and live, push the `www-v*` tag (see “Releasing the website”) so the product page matches what’s in the store. If the page changes ahead of the release, tag it earlier.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `No profiles for '<bundle ID>' were found` / cloud signing permission error | The API key lacks certificate access. Give it Admin. |
| `The bundle version must be higher than the previously uploaded version` | You re-ran an old workflow run. Start a new run so the run number increases. |
| `Tag … is not vMAJOR.MINOR[.PATCH]` | Use a tag like `v1.4.0`. |
| `The train version … is closed for new build submissions` | That version is already approved or released. Tag a higher version. |
| Upload rejected because of the SDK or Xcode build (beta) | The archive was built with a beta Xcode. Archive locally with the release Xcode. |
| Upload lands on the wrong app | `PRODUCT_BUNDLE_IDENTIFIER` points at the other record. See “Which App Store record this ships to”. |
| Fails at “Check configuration” | One of the four secrets is missing from the `app-store` environment. |

# Releasing the website

The product page in `www/` deploys to <https://mrballistic.com/raid/> through `.github/workflows/www.yml`. It runs on `www-v*` tags only, so it never collides with the `v*` tags above that upload the app.

## One-time setup

Add two repository secrets (Settings → Secrets and variables → Actions), the same values `mrballistic/new-site` uses:

| Secret | Value |
|---|---|
| `SSH_PRIVATE_KEY` | The dedicated ed25519 deploy key for `toddgreco@132.148.79.144` |
| `SSH_KNOWN_HOSTS` | The server’s pinned host key line, so the workflow never falls back to `StrictHostKeyChecking=no` |

## Shipping the site

1. Merge the change to `main`.
2. Run **Deploy website** from the Actions tab on `main`, with `dry_run` left on. It lists every file it would add, change or delete in `/var/www/html/raid` without writing anything. Check the deletions: the sync uses `--delete`, scoped to that one directory.
3. Tag and push:

   ```bash
   git tag -a www-v1.0.1 -m "Website: …" && git push origin www-v1.0.1
   ```

The workflow refuses to write unless the tag is on `main` and named `www-vMAJOR.MINOR.PATCH`. It also checks that every local `src`, `href`, `srcset` and CSS `url()` in `www/` points at a real file, and it stops if `DEPLOY_PATH` ever stops ending in `/raid`, since `--delete` against the shared `/var/www/html` would destroy the other sites in it.

After a release that changes the link preview, re-scrape the URL in Facebook’s Sharing Debugger or LinkedIn’s Post Inspector; both cache previews.
