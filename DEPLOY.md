# Deploy

How RAID Calculator is tested in CI, uploaded to App Store Connect, and how the product page ships. For the code itself, see [ARCHITECTURE.md](ARCHITECTURE.md).

Three workflows live in `.github/workflows/`:

| Workflow | Name in Actions | Runs on | Does |
|---|---|---|---|
| `ios.yml` | iOS CI | push and pull request to `main`; called by `deploy.yml` | Strings check and unit tests |
| `deploy.yml` | Deploy to App Store Connect | `v*` tags; manual dispatch | CI gate, then archive and upload |
| `www.yml` | Deploy website | `www-v*` tags; manual dispatch (dry run by default) | Verifies and syncs `www/` to the server |

The two tag families never overlap: `v1.7.0` uploads the app, `www-v1.1.0` deploys the website.

## CI: `ios.yml`

- **Runner:** `xcode-27`, the preview image that carries Xcode 27.1. The app targets iOS 26 but builds with the 27.1 SDK, and `macos-26` stops at Xcode 26.6. `maxim-lobanov/setup-xcode` selects Xcode `27.1`.
- **Timeout:** 30 minutes.
- **Simulator:** a step picks the newest available iPhone on the newest iOS runtime, because device names change with every Xcode. It skips iPhone Duo, which is alone on the 27.1 runtime; the suite targets a standard iPhone. If no iPhone is available, the job fails with the list of devices.
- **Steps:**
  1. `python3 scripts/strings.py check`, which fails on any untranslated string or mismatched format specifier.
  2. Build and run the unit tests only: `-only-testing:"RAID CalcTests"`, `-parallel-testing-enabled NO`, piped through `xcbeautify`.
  3. On failure, upload the `.xcresult` bundle as the `TestResults` artifact (kept 7 days).
- **Why unit tests only:** GitHub’s macOS runner minutes cost money. The UI suite takes about 15 minutes locally and far longer on the runner, so it and the launch tests run locally before each release (commands in [ARCHITECTURE.md](ARCHITECTURE.md#testing)).
- Pull request runs cancel when a newer commit arrives; pushes to `main` don’t.

## App Store upload: `deploy.yml`

### Triggers and flow

Runs on a `v*` tag push or **Actions → Deploy to App Store Connect → Run workflow**. It:

1. Runs `ios.yml` as its gate (strings check and unit tests).
2. Waits for approval in the `app-store` environment. The environment has a required reviewer and admits only `v*` tags, so a manual run has to be dispatched from a `v*` tag ref.
3. Sets the build number to the workflow run number, so it always increases. A tag sets the marketing version (`v1.7.0` → `1.7.0`) and must look like `vMAJOR.MINOR[.PATCH]`; a manual run keeps the project’s `MARKETING_VERSION`.
4. Checks that the team ID, key ID and issuer ID secrets are set.
5. Archives Release for `generic/platform=iOS` with automatic, cloud-managed signing through an App Store Connect API key, on the `xcode-27` runner with Xcode 27.1 (60-minute timeout).
6. Exports with `ExportOptions.plist` (`app-store-connect`, `upload`), which uploads the build to App Store Connect, then deletes the key file and writes a summary (bundle ID, version, build, commit).

Submitting for App Review stays a manual step in App Store Connect.

### Secrets

The `app-store` environment holds four secrets: the Apple developer team ID, the App Store Connect API key’s ID and issuer ID, and the `.p8` private key, base64-encoded. Their values live only in GitHub; never paste them, or the key ID, into the repo, an issue or a log. `.p8` and `AuthKey_*` files are git-ignored because the repo is public.

To set them up from scratch:

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API** → **Team Keys** → **+**. Give it **Admin** access: cloud-managed signing needs Admin, or App Manager with access to certificates, identifiers and profiles. Download the `.p8` (it downloads once) and note the key ID and issuer ID.
2. Repository → **Settings** → **Environments** → `app-store`. Add a required reviewer and restrict deployments to `v*` tags.
3. Add the secrets `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_P8_BASE64` (from `base64 -i <key file>.p8`).

### Why 1.7.0 was uploaded from local Xcode

App Store Connect rejects uploads built with a beta Xcode. The `xcode-27` runner image carries a beta build of Xcode 27.1 (27A9269), while local Xcode 27.1 is the release build (27A9275), so 1.7.0 was archived and uploaded from local Xcode. Use the workflow again once the runner’s Xcode is a release build: compare `xcodebuild -version` in a CI run with the build number in Xcode’s About box.

### Which App Store record a build lands on

The project’s `PRODUCT_BUNDLE_IDENTIFIER` decides it; there is no setting in the workflow. This codebase ships to the original **RAID calculator** record (Apple ID `395601653`, bundle ID `53Q4825KDF`, an identifier from the app’s 2010 origins), not the newer **RAID Calc2** record (Apple ID `6755641457`, bundle ID `com.mrballistic.RaidCalculator2`). App Store Connect can’t merge records, so the original record receives new versions again.

- Each release needs a matching version record in App Store Connect; the uploaded build’s version must match it.
- Make sure the original record’s **Pricing and Availability** is set to available when you submit.
- After the new version is live, remove RAID Calc2 from sale. People with the original app get the new version as an update; RAID Calc2 owners keep what they have.
- If `53Q4825KDF` isn’t registered under the current team (developer.apple.com → Identifiers), cloud signing fails with a profile error.

## Website: `www.yml`

Pushing a `www-v<MAJOR.MINOR.PATCH>` tag deploys `www/` to <https://mrballistic.com/raid/>.

- **Guards:** the commit must be on `main`; anything that writes must come from a `www-vMAJOR.MINOR.PATCH` tag; the deploy path must end in `/raid`, because the sync uses `--delete` and the shared web root holds other sites.
- **Verification:** the key files exist (`index.html`, `privacy/index.html`, `site.webmanifest`, the consent and top-bar scripts, the OG image), and every local `src`, `href`, `srcset` and CSS `url()` points at a real file.
- **Deploy:** `rsync` over SSH as an unprivileged deploy user that owns only the site’s directory, with a pinned host key. `.DS_Store` and `.playwright-mcp/` never ship. 10-minute timeout.
- **Secrets:** an SSH private key and the server’s known-hosts line, in the `website` environment, which admits only `www-v*` tags. A run from a branch or a fork can’t reach them.
- **Manual runs** default to `dry_run`, which lists every file it would add, change or delete without writing. Because the environment admits only `www-v*` tags, dispatch it from a `www-v*` tag ref.

## Release checklist

In order:

1. **Unit tests and strings:** green in CI on the pull request (`ios.yml`).
2. **UI suite, locally:** run it serially on an iPhone Simulator and on an iPad Simulator, so the `testIPad*` tests run instead of skipping (about 15 minutes each; commands in [ARCHITECTURE.md](ARCHITECTURE.md#testing)). Then do the manual Reduce Motion pass on iPhone and iPad.
3. **Version:** set `MARKETING_VERSION` in the project and make sure App Store Connect has a matching version record on the original record.
4. **Store assets:** capture and compose with `scripts/store-assets/` (see its [README](scripts/store-assets/README.md); deliverables and sizes in [docs/app-store-assets-brief.md](docs/app-store-assets-brief.md)). Check every PNG’s size and that it has no alpha channel.
5. **Listings:** have a native speaker check the localized listings. Don’t submit machine translations unreviewed.
6. **Featuring nomination:** draft it in App Store Connect once the version exists. It needs three weeks’ lead time, so submit it as early as the build and assets allow.
7. **Archive and upload, locally** (as for 1.7.0): in Xcode 27.1, the release build, select **Any iOS Device**, then Product → Archive, then Distribute App → App Store Connect → Upload. Make the build number higher than any already uploaded for that version.
8. **Or from CI,** only once the runner’s Xcode is a release build:

   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

   Then approve the run in the `app-store` environment.
9. **Submit:** processing takes 5–20 minutes. On the version page in App Store Connect, select the build and **Add for Review**. No export-compliance question appears, because `ITSAppUsesNonExemptEncryption` is `NO`.
10. **Website:** once the version is approved and live, ship the product page so it matches the store (tag earlier if the page changes ahead of the release):
    1. Merge the change to `main`.
    2. Tag and push; the tag push deploys:

       ```bash
       git tag -a www-vX.Y.Z -m "Website: …"
       git push origin www-vX.Y.Z
       ```

       To preview without writing, dispatch **Deploy website** with `dry_run` on from a `www-v*` tag ref and check the list, especially deletions.
    3. If the link preview changed, re-scrape the URL in Facebook’s Sharing Debugger or LinkedIn’s Post Inspector; both cache previews.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `No profiles for '<bundle ID>' were found`, or a cloud signing permission error | The API key lacks certificate access. Give it Admin. |
| `The bundle version must be higher than the previously uploaded version` | You re-ran an old workflow run. Start a new run so the run number increases. |
| `Tag … is not vMAJOR.MINOR[.PATCH]` | Use a tag like `v1.8.0`. |
| `The train version … is closed for new build submissions` | That version is already approved or released. Use a higher version. |
| Upload rejected because of the SDK or Xcode build (beta) | The archive was built with a beta Xcode. Archive locally with the release Xcode. |
| Upload lands on the wrong app | `PRODUCT_BUNDLE_IDENTIFIER` points at the other record. See “Which App Store record a build lands on”. |
| Fails at “Check configuration” | A secret is missing from the `app-store` environment. |
| A manual run is refused by its environment | It was dispatched from a branch. `app-store` admits only `v*` tags and `website` only `www-v*` tags. |
