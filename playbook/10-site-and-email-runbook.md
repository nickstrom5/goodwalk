# Runbook: static site + custom domain + free support email for an iOS app

Reusable for any app. Replace: `APP` (app name), `DOMAIN` (e.g. getgoodwalk.app), `GH_USER`
(GitHub username), `REPO` (repo name), `GMAIL` (the Gmail inbox that receives support mail).
Cost: the domain only (~$15/yr for .app at Cloudflare). Everything else is free.
For Good Walk: APP=Good Walk, DOMAIN=getgoodwalk.app, GH_USER=nickstrom5, REPO=the repo that holds
`dogwalk/` (Pages serves one `/docs` folder per repo, so Good Walk needs its own repo or its own
branch with `docs/` at the root).

## 1. Domain
- Buy DOMAIN at Cloudflare Registrar (dash.cloudflare.com → Domain Registration). At-cost
  pricing, 1 year is enough. Avoid Squarespace/GoDaddy (3-year defaults, markups).

## 2. Site files (in the repo, folder `/docs`)
- `docs/index.html` landing page (hero, how it works, pricing, FAQ, footer links)
- `docs/privacy.html` privacy policy
- `docs/terms.html` terms (must cover auto-renewing subscriptions and the cancel-24h rule)
- `docs/CNAME` one line containing DOMAIN
- SEO files at the site root: `robots.txt`, `sitemap.xml`, `404.html`, `site.webmanifest`, `.nojekyll`, `og.png`,
  `favicon-32.png`, `apple-touch-icon.png`, `icon-192.png`, `icon-512.png` (images from `scripts/make-brand.swift`),
  plus the content pages. Every page carries its own title, description, canonical, Open Graph and JSON-LD.
- Nothing internal goes in `docs/`: it is public. Strategy and launch notes live in `playbook/`.
- Landing page has one App Store button driven by a JS constant `APP_STORE_URL = ""`:
  empty shows "Get early access" (mailto), set shows "Download on the App Store".
- All mailto links use `support@DOMAIN` or `hello@DOMAIN`.

## 3. GitHub Pages
- Repo → Settings → Pages: Source "Deploy from a branch", branch = main (or yours), folder
  `/docs`. Save.
- Custom domain = DOMAIN. Save. Shows "DNS check in progress" until step 4.
- Account level: github.com/settings/pages_verified_domains → Add DOMAIN. It shows a TXT record
  name (`_github-pages-challenge-GH_USER`) and value. Keep for step 4; click Verify after.

## 4. Cloudflare DNS (DOMAIN → DNS → Records), all **DNS only** (grey cloud, not proxied)

| Type | Name | Content |
|---|---|---|
| A | `@` | 185.199.108.153 |
| A | `@` | 185.199.109.153 |
| A | `@` | 185.199.110.153 |
| A | `@` | 185.199.111.153 |
| CNAME | `www` | `GH_USER.github.io` |
| TXT | `_github-pages-challenge-GH_USER` | value from step 3 |

- Delete any registrar parking A/AAAA/CNAME records on the apex.
- Back in GitHub Pages settings, click Save next to the domain. Green within minutes.
- Tick "Enforce HTTPS" when it appears (up to an hour for the certificate).
- `scripts/cloudflare-setup.sh` in this repo does this section and the next via the API:
  `CF_TOKEN=… GITHUB_TXT_VALUE=… bash scripts/cloudflare-setup.sh` (DOMAIN defaults to
  getgoodwalk.app). Delete the API token afterwards.

## 5. Inbound email (Cloudflare → DOMAIN → Email → Email Routing)
- Enable Email Routing; accept the MX/SPF/DKIM records it adds.
- Destination addresses → add GMAIL → click the verification link Cloudflare emails you.
- Routing rules → `support@DOMAIN` → GMAIL; same for `hello@DOMAIN`. Enable catch-all → GMAIL.

## 6. Outbound email (reply as support@DOMAIN from Gmail)
- Google Account → Security → 2-Step Verification on → App passwords → create one.
- Gmail → Settings → Accounts and Import → "Send mail as" → Add another email address:
  name "APP Support", email `support@DOMAIN`, untick "Treat as alias".
  SMTP `smtp.gmail.com`, port 587, TLS, username = full GMAIL address,
  password = the app password (not the account password).
- Gmail emails a confirmation code to support@DOMAIN, which forwards to GMAIL. Enter it.
- Gmail filter: `to:(support@DOMAIN OR hello@DOMAIN)` → label "APP support", skip inbox.
- Never paste or screenshot the app password; revoke and recreate it if you do.

## 7. Verify
- `https://DOMAIN/privacy.html` loads with a padlock.
- Mail from another address to support@DOMAIN arrives in GMAIL; a reply shows From: support@DOMAIN.

## 8. Use the URLs
- App Store Connect: support URL `https://DOMAIN/`, privacy policy `https://DOMAIN/privacy.html`.
- In-app: paywall footer and settings link to privacy.html and terms.html; feedback → support@DOMAIN.
- Bundle ID convention: reverse of DOMAIN, e.g. `app.getgoodwalk.goodwalk` (extensions `.widgets`).

## 9. SEO after launch
Do these once the site is live on DOMAIN over HTTPS. None of them can be done from the repo.
- **Google Search Console** (search.google.com/search-console): add a Domain property for DOMAIN and verify it
  with the TXT record it gives you (Cloudflare → DNS → add TXT on `@`, DNS only). Bing Webmaster Tools
  (bing.com/webmasters): add the site; "Import from Google Search Console" is the quickest route, or verify with
  its own TXT/CNAME record.
- **Submit the sitemap** in both: `https://DOMAIN/sitemap.xml`. When a page is added or changed, update its
  `<lastmod>` in `docs/sitemap.xml`.
- **Fill in the App Store ID** once the App Store Connect record exists: uncomment
  `<meta name="apple-itunes-app" content="app-id=APP_ID">` in the `<head>` of `docs/index.html` with the numeric
  Apple ID (Safari on iPhone then shows the Smart App Banner), and set `APP_STORE_URL` in `docs/index.html` and the
  guide pages so every button becomes "Download on the App Store".
- **Request indexing**: in Search Console, URL Inspection → paste `https://DOMAIN/` → Request indexing; repeat for
  each content page. In Bing, URL Submission.
- Check the link preview (`og.png`) by pasting the URL into iMessage or a social post composer, and run the home
  page through Google's Rich Results Test to confirm the SoftwareApplication and FAQ markup parse.
- Do not add `aggregateRating` or review markup until there are real App Store ratings to point to.

## Gotchas
- Orange (proxied) cloud on the A records means GitHub can never issue HTTPS. Must be grey.
- Gmail auto-fills the SMTP server as `smtp.DOMAIN`; it must be `smtp.gmail.com`.
- Too many failed Send-as attempts locks that dialog for about an hour.
- Cloudflare forwarding is inactive until the destination address is verified by email.
- A bounce saying "DNS type mx lookup had no relevant answers" means Email Routing isn't enabled.
