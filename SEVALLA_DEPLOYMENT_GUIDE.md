# 🚀 Sevalla Deployment Guide - RAB Booking

**Platform**: Sevalla Static Site Hosting
**App Type**: Flutter Web Application
**URL**: https://sevalla.com/static-site-hosting/
**Status**: Ready for Deployment

---

## 📋 Quick Deployment Checklist

- [ ] Flutter web build completed
- [ ] Environment variables configured (.env)
- [ ] Supabase project connected
- [ ] Stripe keys configured (production)
- [ ] Domain configured (optional)
- [ ] SSL certificate enabled
- [ ] Files uploaded to Sevalla
- [ ] Site tested on production

---

## 🏗️ Build Instructions

### Step 1: Build for Production

```bash
# Navigate to project directory
cd C:\Users\W10\dusko1\rab_booking

# Build Flutter web app (optimized for production)
flutter build web --release \
  --web-renderer html \
  --base-href="/" \
  --source-maps

# Expected output: build/web/ folder with all static files
```

**Build flags explained**:
- `--release`: Production build (minified, optimized)
- `--web-renderer html`: HTML renderer (better compatibility, SEO)
- `--base-href="/"`: Root path (change if subdirectory)
- `--source-maps`: Debugging (optional, can remove for smaller size)

---

### Step 2: Build Output

After successful build, you'll have:

```
build/web/
├── index.html              ← Main HTML file
├── flutter.js              ← Flutter engine
├── flutter_bootstrap.js    ← Bootstrap script
├── favicon.png             ← Favicon
├── manifest.json           ← PWA manifest
├── icons/                  ← App icons
│   ├── Icon-192.png
│   ├── Icon-512.png
│   └── Icon-maskable-*.png
├── assets/                 ← App assets
│   ├── AssetManifest.json
│   ├── FontManifest.json
│   ├── fonts/
│   ├── packages/
│   └── shaders/
└── canvaskit/              ← CanvasKit for rendering
    ├── canvaskit.js
    ├── canvaskit.wasm
    └── profiling/
```

**Total size**: ~15-25 MB (typical Flutter web app)

---

## 🌐 Sevalla Deployment Steps

### Method 1: Web Interface (Easiest)

1. **Login to Sevalla**
   - Go to https://sevalla.com
   - Login to your account
   - Navigate to "Static Site Hosting"

2. **Create New Site**
   - Click "Create New Site"
   - Choose deployment method:
     - **Git Repository** (recommended)
     - **Upload Folder**
     - **FTP/SFTP**

3. **Upload Files**
   - **If using Upload Folder**:
     - Zip the `build/web/` folder
     - Upload ZIP file
     - Sevalla will auto-extract

   - **If using Git** (recommended):
     - Push code to GitHub/GitLab
     - Connect repository to Sevalla
     - Set build command: `flutter build web --release`
     - Set output directory: `build/web`
     - Enable auto-deploy on push

4. **Configure Settings**
   - **Root Directory**: `/` (or `build/web` if not auto-detected)
   - **Index Document**: `index.html`
   - **Error Document**: `index.html` (for SPA routing)
   - **Custom Domain**: Add your domain (optional)
   - **SSL**: Enable HTTPS (free Let's Encrypt)

5. **Deploy**
   - Click "Deploy Site"
   - Wait 2-5 minutes for deployment
   - Site will be live at `https://your-site.sevalla.app`

---

### Method 2: Git Deployment (Recommended)

**Step-by-step**:

1. **Create `.gitignore`** (if not exists)
```gitignore
# Flutter build outputs
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies

# Environment files (IMPORTANT - don't commit secrets!)
.env
.env.local
.env.production

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
```

2. **Push to GitHub**
```bash
git add .
git commit -m "chore: Prepare for Sevalla deployment"
git push origin main
```

3. **Connect to Sevalla**
   - In Sevalla dashboard: "New Site" → "Import from Git"
   - Authorize GitHub/GitLab
   - Select repository: `rab_booking`
   - Configure build:
     ```
     Build Command:    flutter build web --release --web-renderer html
     Output Directory: build/web
     ```
   - Add environment variables (see below)
   - Deploy

4. **Auto-Deploy**
   - Every push to `main` branch → auto-deploy
   - Deployment webhook available
   - Build logs visible in dashboard

---

## 🔐 Environment Variables

⚠️ **IMPORTANT**: Configure these in Sevalla dashboard (don't commit to Git!)

### Required Environment Variables

```bash
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Stripe (Production)
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxx
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxxx  # Backend only

# App Config
FLUTTER_WEB_BASE_HREF=/
FLUTTER_WEB_RENDERER=html

# Optional
SENTRY_DSN=https://xxx@sentry.io/xxx  # Error tracking
GOOGLE_MAPS_API_KEY=your_key_here     # If using Google Maps
```

**How to add in Sevalla**:
1. Go to Site Settings → Environment Variables
2. Add each variable as Key-Value pair
3. Mark sensitive variables as "Secret"
4. Redeploy site for changes to take effect

---

## 📁 File Structure After Deployment

```
Sevalla Root
└── / (public_html or similar)
    ├── index.html
    ├── flutter.js
    ├── flutter_bootstrap.js
    ├── favicon.png
    ├── manifest.json
    ├── icons/
    ├── assets/
    └── canvaskit/
```

---

## ⚙️ Sevalla Configuration

### Recommended Settings

**General**:
- ✅ Enable HTTPS (SSL)
- ✅ Force HTTPS redirect
- ✅ Enable HTTP/2
- ✅ Enable Compression (gzip/brotli)

**Performance**:
- ✅ Enable CDN (if available)
- ✅ Browser caching (1 year for assets)
- ✅ Asset optimization (minify HTML/CSS/JS)

**Routing** (SPA - Single Page Application):
```nginx
# Redirect all routes to index.html (for Flutter router)
location / {
    try_files $uri $uri/ /index.html;
}

# Cache static assets
location ~* \.(js|css|png|jpg|jpeg|gif|ico|woff|woff2|ttf|svg|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

**Custom Headers**:
```
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

---

## 🔧 Custom Domain Setup (Optional)

### Add Custom Domain

1. **In Sevalla Dashboard**:
   - Go to Site Settings → Domains
   - Click "Add Custom Domain"
   - Enter domain: `www.rab-booking.com`

2. **DNS Configuration** (at your domain registrar):

**A Record** (if using root domain):
```
Type: A
Name: @
Value: [Sevalla IP - get from dashboard]
TTL: 3600
```

**CNAME Record** (if using subdomain):
```
Type: CNAME
Name: www
Value: your-site.sevalla.app
TTL: 3600
```

**SSL Certificate**:
- Sevalla auto-generates Let's Encrypt SSL
- Wait 5-10 minutes for DNS propagation
- HTTPS will be enabled automatically

---

## 🧪 Testing After Deployment

### Checklist

1. **Homepage Loads**
   - [ ] Visit https://your-site.sevalla.app
   - [ ] Hero section displays correctly
   - [ ] Search bar works
   - [ ] Navigation works

2. **Routing Works**
   - [ ] Click property → property details page
   - [ ] Browser back/forward works
   - [ ] Direct URL access works (no 404)

3. **Features Work**
   - [ ] Property search works
   - [ ] Filters work
   - [ ] Booking flow works
   - [ ] Payment integration works (Stripe)
   - [ ] Authentication works (Supabase)
   - [ ] Dark mode toggle works

4. **Performance**
   - [ ] Page loads < 3 seconds
   - [ ] Images load correctly
   - [ ] Animations smooth (60 FPS)
   - [ ] Mobile responsive

5. **SEO**
   - [ ] Meta tags present (`<meta name="description">`)
   - [ ] Open Graph tags work (Facebook share preview)
   - [ ] Title displays correctly
   - [ ] Favicon displays

---

## 🐛 Common Issues & Solutions

### Issue 1: 404 on Refresh

**Symptom**: Refreshing `/property/123` shows 404

**Cause**: Server doesn't know about Flutter routes

**Fix**: Configure redirect rules (see Routing section above)

```nginx
# In Sevalla, add this redirect rule
/*    /index.html    200
```

---

### Issue 2: Assets Not Loading

**Symptom**: Images, fonts not displaying

**Cause**: Wrong base href or CORS

**Fix 1**: Rebuild with correct base-href
```bash
flutter build web --release --base-href="/your-path/"
```

**Fix 2**: Check CORS headers (if loading from different domain)

---

### Issue 3: Environment Variables Not Working

**Symptom**: Supabase connection fails, "API key not found"

**Cause**: .env file not loaded (doesn't work in web build)

**Fix**: Use compile-time constants or backend proxy
```dart
// Don't rely on .env in web builds
const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
  defaultValue: 'https://your-project.supabase.co');
```

Or create `lib/core/config/web_config.dart`:
```dart
class WebConfig {
  static const supabaseUrl = 'https://your-project.supabase.co';
  static const supabaseAnonKey = 'your_anon_key';
}
```

---

### Issue 4: Slow Initial Load

**Symptom**: White screen for 5-10 seconds

**Cause**: Large Flutter bundle size

**Fixes**:
1. Enable web renderer: `--web-renderer html`
2. Lazy load routes
3. Optimize images (use WebP)
4. Enable Sevalla CDN
5. Add loading screen to index.html

```html
<!-- In web/index.html <body> -->
<div id="loading" style="position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; background: #fff;">
  <div style="text-align: center;">
    <img src="icons/Icon-192.png" width="80" height="80" style="animation: pulse 2s infinite;">
    <p style="margin-top: 20px; color: #666;">Loading RAB Booking...</p>
  </div>
</div>

<script>
  window.addEventListener('flutter-first-frame', function () {
    document.getElementById('loading').remove();
  });
</script>
```

---

### Issue 5: Payment (Stripe) Not Working

**Symptom**: Stripe checkout fails or doesn't load

**Cause**: Wrong API keys or CORS issues

**Fix**:
1. Use **production** Stripe keys (pk_live_xxx)
2. Add domain to Stripe dashboard whitelist
3. Check browser console for errors

---

## 📊 Performance Optimization

### Before Deployment

1. **Optimize Images**
```bash
# Compress images to WebP
cwebp input.jpg -q 80 -o output.webp
```

2. **Analyze Bundle Size**
```bash
flutter build web --release --analyze-size
```

3. **Enable Tree Shaking**
```bash
# Already enabled in --release mode
flutter build web --release --tree-shake-icons
```

---

### After Deployment

1. **Enable Sevalla CDN**
   - Distributes files to edge locations
   - Reduces latency globally

2. **Browser Caching**
   - Set long cache headers for assets
   - Short cache for index.html

3. **Lazy Loading**
   - Defer non-critical routes
   - Load on-demand

---

## 📈 Monitoring & Analytics

### Recommended Tools

1. **Sevalla Analytics** (built-in)
   - Page views
   - Bandwidth usage
   - Geographic distribution

2. **Google Analytics**
```html
<!-- Add to web/index.html <head> -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

3. **Sentry** (Error Tracking)
```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.0.0
```

```dart
// main.dart
await SentryFlutter.init(
  (options) => options.dsn = 'https://xxx@sentry.io/xxx',
  appRunner: () => runApp(MyApp()),
);
```

---

## 🔄 Continuous Deployment

### GitHub Actions (Optional)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Sevalla

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.6'

      - run: flutter pub get
      - run: flutter build web --release --web-renderer html

      - name: Deploy to Sevalla
        uses: SamKirkland/FTP-Deploy-Action@4.3.0
        with:
          server: ${{ secrets.SEVALLA_FTP_SERVER }}
          username: ${{ secrets.SEVALLA_FTP_USERNAME }}
          password: ${{ secrets.SEVALLA_FTP_PASSWORD }}
          local-dir: ./build/web/
          server-dir: /public_html/
```

---

## ✅ Deployment Checklist

### Pre-Deployment
- [x] Code tested locally
- [x] All features working
- [x] Environment variables configured
- [x] Production API keys ready
- [x] Domain purchased (if using custom)
- [x] SSL certificate plan (free Let's Encrypt)

### Deployment
- [ ] Flutter web build successful
- [ ] Files uploaded to Sevalla
- [ ] Environment variables set in dashboard
- [ ] Redirect rules configured (SPA routing)
- [ ] SSL enabled and working
- [ ] Custom domain connected (if applicable)

### Post-Deployment
- [ ] All pages load correctly
- [ ] Routing works (no 404s)
- [ ] Authentication works (Supabase)
- [ ] Payments work (Stripe)
- [ ] Forms submit correctly
- [ ] Images load correctly
- [ ] Performance acceptable (< 3s load)
- [ ] Mobile responsive
- [ ] Cross-browser tested (Chrome, Firefox, Safari, Edge)
- [ ] SEO meta tags working
- [ ] Analytics tracking enabled

---

## 📞 Support & Resources

### Sevalla Resources
- **Documentation**: https://sevalla.com/docs
- **Support**: support@sevalla.com
- **Community**: https://forum.sevalla.com

### Flutter Web Resources
- **Docs**: https://docs.flutter.dev/deployment/web
- **Performance**: https://docs.flutter.dev/perf/web-performance
- **Debugging**: https://docs.flutter.dev/testing/debugging#web

---

## 🎯 Next Steps

After successful deployment:

1. **Set up monitoring** (Google Analytics, Sentry)
2. **Enable CDN** for faster global delivery
3. **Configure backups** (automatic or manual)
4. **Set up staging environment** (test.rab-booking.com)
5. **Document deployment process** for team
6. **Set up alerts** for downtime/errors
7. **Optimize** based on real user metrics

---

## ✨ Deployment Summary

**What you get**:
- ✅ Live web app at https://your-site.sevalla.app
- ✅ Free SSL certificate (HTTPS)
- ✅ Static hosting (fast, scalable)
- ✅ CDN distribution (optional)
- ✅ Auto-deploy from Git (optional)
- ✅ Custom domain support
- ✅ Built-in analytics

**Estimated deployment time**: 10-30 minutes
**Cost**: Depends on Sevalla plan (starting $5-10/month)
**Performance**: Excellent (static files, CDN)

---

**Deployment prepared**: October 20, 2025
**App**: RAB Booking - Luxury Vacation Rentals
**Platform**: Sevalla Static Site Hosting
**Status**: Ready to deploy 🚀

---

*For questions or issues, refer to Sevalla documentation or contact their support team.*
