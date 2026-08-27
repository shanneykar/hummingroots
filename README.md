# Hummingbird & Root

Static one-page site. No build step, no dependencies, no framework. `index.html`
carries its own CSS and JS inline, which is why the whole site is one request.

Deployed on Cloudflare Pages, straight from `main`.

---

## Repo layout

```
index.html          the site — HTML, CSS and JS in one file
404.html            not-found page
_headers            Cloudflare Pages security + cache headers
robots.txt
sitemap.xml
site.webmanifest
share.jpg           1200x630 Open Graph card  (PLACEHOLDER — replace)
apple-touch-icon.png            180x180        (PLACEHOLDER — replace)
icon-192.png / icon-512.png     PWA icons      (PLACEHOLDER — replace)
.gitignore
```

Nothing else is needed. Do not add a package.json unless something actually
requires building.

---

## Deploy

1. Push this repo to GitHub.
2. Cloudflare dashboard → **Workers & Pages** → **Create** → **Pages** →
   **Connect to Git** → pick the repo.
3. Build settings:
   - Framework preset: **None**
   - Build command: *(leave empty)*
   - Build output directory: `/`
4. Save and Deploy.
5. **Custom domains** → add `hummingbirdandroot.com` and `www.hummingbirdandroot.com`.
   Cloudflare writes the DNS records itself if the domain is already in the account.
6. Add a **Redirect Rule** sending `www.` to the apex, so there's one canonical host.

Every push to `main` redeploys. Pull requests get their own preview URL.

---

## Before it goes public

### 1. Replace the domain placeholders

Every occurrence of `hummingbirdandroot.com` in the repo is a placeholder.

```bash
grep -rl 'hummingbirdandroot\.com' . | xargs sed -i '' 's/hummingbirdandroot\.com/YOURDOMAIN.com/g'
```

(On Linux drop the `''` after `-i`.)

### 2. Replace the email

Eight places, plus the Instagram handle in the footer.

```bash
grep -rl 'hello@' . | xargs sed -i '' 's/hello@hummingbirdandroot\.com/HER@ADDRESS.com/g'
grep -rn 'instagram.com/hummingbirdandroot' index.html
```

### 3. Replace `share.jpg`

The current one is generated type on a blank ground — it works, but it's a
holding pattern. Every Instagram and text-message link preview uses this image.
Must be exactly **1200 × 630**. Same for the three icons.

### 4. Wire the form endpoint

Three places in the JS still resolve with a `setTimeout` instead of sending
anything. Search `index.html` for:

```
Replace this timeout with a POST
POST the bag + address to a form endpoint here
```

The payload is already assembled at each spot. Any of these work with a static
site:

- **Formspree** or **Basin** — paste a URL, done, free tier is enough
- **Cloudflare Pages Functions** — add `/functions/api/request.js`, and it
  deploys with the site (this is the tidier option since you're already on
  Cloudflare)

After wiring it, add the endpoint's origin to `connect-src` in `_headers`.

**Do not add a card field.** Payment happens on the processor's own hosted page,
from a link she sends after confirming. The moment a card input exists on this
domain, the site is in PCI scope and this stops being a weekend project.

When payments go live, use **two separate Stripe accounts** — one for the
apothecary, one for services. Different risk categories; a hold on one should
never freeze the other.

### 5. Self-host the fonts

Currently two render-blocking requests to Google. To fix:

1. Download the Cormorant Garamond and Courier Prime woff2 files.
2. Put them in `/fonts/`.
3. In `index.html`, replace the three `<link>` tags to Google with an
   `@font-face` block at the top of the `<style>`.
4. Delete `https://fonts.googleapis.com` and `https://fonts.gstatic.com` from
   the CSP in `_headers`.

Saves roughly 200ms and removes a third-party dependency and a GDPR question.

---

## Things to know before editing

- **`body` has `overflow:hidden` on purpose.** The six chapters are a horizontal
  scroll-snap track; the drawers are the only vertical scroll. Removing that
  breaks the whole layout.
- **The `<noscript>` block in `<body>` is the real fallback.** If JS fails the
  drawers can never open, so that block is the entire site for that visitor.
  If you change prices or services, change them there too. It's the one place
  content is duplicated.
- **One breakpoint: 860px.** Keep it that way. There's a second tiny query at
  430px for the two things that need it.
- **`inert` is what keeps focus inside an open drawer.** `aria-modal` alone
  doesn't stop Tab. Don't remove the `setInert()` calls.
- **All user input is escaped through `esc()`** before it goes near `innerHTML`.
  Keep it that way if you add fields.

---

## Known open items

- The site is one URL serving six different search intents. Splitting the drawer
  content into six real pages (`/reading/`, `/money/`, `/protection/` …) would
  give six chances to rank instead of one. Content decision, not a code one.
- Six product photographs still needed — each `.frame` placeholder names the shot
  it's waiting for.
- Glamour & Beauty work is not currently a chapter. If it comes back, it's a
  seventh.
- No analytics. Cloudflare Web Analytics is a one-line add and doesn't need a
  cookie banner, if she wants numbers.
