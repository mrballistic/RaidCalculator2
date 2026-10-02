# Releasing to the App Store

Builds upload only from GitHub Actions (`.github/workflows/deploy.yml`). A version tag archives the app and uploads it to App Store Connect, where it's available for TestFlight and for App Store submission. Submitting a version for App Review stays a manual step in App Store Connect.

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

```sh
git tag v1.4.0
git push origin v1.4.0
```

Or **Actions → Deploy to App Store Connect → Run workflow** (uses `MARKETING_VERSION` from the project).

The workflow:

1. Runs the full CI gate (`ios.yml`: build, unit tests and UI tests on the newest iPhone simulator).
2. Archives Release for `generic/platform=iOS` with automatic signing through the API key. The tag sets the marketing version (`v1.4.0` → `1.4.0`); the build number is the workflow's run number, so it always increases.
3. Exports with `ExportOptions.plist` (`app-store-connect`, `upload`), which uploads to App Store Connect, then deletes the key and writes a summary.

Processing takes 5–20 minutes. Then, in App Store Connect, open the version page, select the build and **Add for Review**. No export-compliance question appears: `ITSAppUsesNonExemptEncryption` is `NO`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `No profiles for '<bundle ID>' were found` / cloud signing permission error | The API key lacks certificate access. Give it Admin. |
| `The bundle version must be higher than the previously uploaded version` | You re-ran an old workflow run. Start a new run so the run number increases. |
| `Tag … is not vMAJOR.MINOR[.PATCH]` | Use a tag like `v1.4.0`. |
| `The train version … is closed for new build submissions` | That version is already approved or released. Tag a higher version. |
| Upload lands on the wrong app | `PRODUCT_BUNDLE_IDENTIFIER` points at the other record. See “Which App Store record this ships to”. |
| Fails at “Check configuration” | One of the four secrets is missing from the `app-store` environment. |
