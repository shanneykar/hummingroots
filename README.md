# Photos

Six photographs carry this site. They're the only image on each chapter, so
they do most of the work.

## The short version

Replace the six files in this folder. Keep the filenames exactly as they are.
No code changes needed.

```
photos/01-reading.jpg       worn deck of cards, face down, on kraft paper
photos/02-money.jpg         green vigil candle, lit, dressed with herb
photos/03-person.jpg        sealed honey jar, ribbon tied, on linen
photos/04-protection.jpg    iron nail and black salt on dark linen
photos/05-sickness.jpg      small brass bell and white cloth, soft light
photos/06-apothecary.jpg    herb bundle tied and hung, on brown paper
```

The files currently in here are placeholders with the shot description printed
on them. If you see one on the live site, that photo hasn't been replaced yet.

## Specs

| | |
|---|---|
| Aspect ratio | **4:5** (portrait) |
| Size | **900 × 1125** |
| Format | JPEG, quality 80–85 |
| Weight | under 150KB each |
| Orientation | shot from directly overhead |

4:5 is not optional. The CSS reserves that shape before the image loads, which
is what stops the page from jumping. A 3:2 photo will get centre-cropped and
you'll lose the edges.

## Shooting them

All six should look like they were taken in the same hour by the same person,
because the whole design rests on that. Practically:

- **One surface, one light.** Daylight from a window, no flash, no overhead
  bulb. Same time of day for all six if you can.
- **Straight down.** Phone parallel to the table. Not at an angle.
- **Object roughly centred, with room around it.** The frame is small on the
  page — a tight crop reads as clutter.
- **Warm, matte grounds.** Kraft paper, unbleached linen, raw wood. The site's
  background is a warm paper colour and the photos should sit in it, not fight
  it.
- **Don't edit toward cool or high-contrast.** The CSS already pulls saturation
  down slightly and adds a touch of contrast to blend them. Anything heavily
  filtered will land twice-processed.

Shoot more than six. Picking the best of thirty is a different job from making
one shot work.

## Resizing before you commit them

If you have ImageMagick:

```bash
cd photos
for f in raw/*.jpg; do
  magick "$f" -auto-orient \
    -resize 900x1125^ -gravity center -extent 900x1125 \
    -quality 82 -strip "$(basename "$f")"
done
```

`-strip` removes EXIF, which matters: phone photos carry GPS coordinates, and
these are being published.

No ImageMagick? [squoosh.app](https://squoosh.app) does the same thing in a
browser — set Resize to 900×1125, JPEG quality 82, and it strips metadata by
default.

## Optional: WebP

Cuts each file roughly in half. Only worth doing once the real photos are in.

```bash
for f in *.jpg; do magick "$f" -quality 78 "${f%.jpg}.webp"; done
```

Then in `index.html`, wrap each `<img>`:

```html
<picture>
  <source srcset="/photos/01-reading.webp" type="image/webp">
  <img src="/photos/01-reading.jpg" width="900" height="1125"
       alt="A worn tarot deck lying face down on kraft paper."
       loading="eager" decoding="async" fetchpriority="high">
</picture>
```

Keep the JPEG as the `<img>` fallback. Don't remove `width`, `height`, or the
`alt` text.

## Alt text

Each image already has alt text written into `index.html`. If you change what a
photo shows, change its alt text to match — describe the object plainly, the way
you'd say it out loud. It's what a blind visitor gets, and it's what Google
reads.

## Loading

Chapter 1's photo is `loading="eager"` with `fetchpriority="high"` — it's the
first thing anyone sees. The other five are `loading="lazy"` and fetch as the
visitor scrolls sideways toward them. Don't make them all eager; that's six
full-size images competing on first paint.

## Also needs replacing

`share.jpg` in the repo root — **1200 × 630**, landscape, not 4:5. This is the
link preview for every Instagram post and text message. The current one is
generated type on a blank ground.

`apple-touch-icon.png` (180×180), `icon-192.png`, `icon-512.png` — same
placeholder situation.
