import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
// Using node-fetch for HTTP requests (Node 18+ has global fetch, but let's be safe)
import fetch from 'node-fetch';

if (!admin.apps.length) {
    admin.initializeApp();
}

/**
 * Generates dynamic meta tags for social sharing of properties/units.
 * Handles /s/:unitId route.
 *
 * Flow:
 * 1. Resolves Unit and Property from Firestore.
 * 2. Fetches the live index.html from the hosting site.
 * 3. Injects OpenGraph/Twitter meta tags.
 * 4. Returns modified HTML.
 */
export const shareProperty = functions.https.onRequest(async (req, res) => {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');

    try {
        // Parse URL to get Unit ID
        // Expected path: /s/{unitId}
        const pathParts = req.path.split('/');
        // pathParts: ['', 's', 'UNIT_ID', ...]
        const unitId = pathParts[2];

        if (!unitId) {
            res.status(400).send('Invalid URL format');
            return;
        }

        console.log(`Generating metadata for unit: ${unitId}`);

        // 1. Fetch Data
        // Unit is in subcollection, use Collection Group Query
        const unitSnapshot = await admin.firestore().collectionGroup('units')
            .where('id', '==', unitId)
            .limit(1)
            .get();

        if (unitSnapshot.empty) {
            console.warn(`Unit ${unitId} not found`);
            // Serve default index.html via redirect or fetch?
            // Better to redirect to home to avoid broken link preview
            res.redirect('/');
            return;
        }

        const unitDoc = unitSnapshot.docs[0];
        const unitData = unitDoc.data();
        const propertyId = unitData.property_id;

        // Fetch Property for fallback images/name
        const propertyDoc = await admin.firestore().collection('properties').doc(propertyId).get();
        const propertyData = propertyDoc.exists ? propertyDoc.data() : null;

        // 2. Prepare Meta Data
        const propertyName = propertyData?.name || 'BookBed Property';
        const unitName = unitData.name || 'Vacation Rental';
        const title = `${unitName} | ${propertyName}`;
        const description = propertyData?.description || `Book your stay at ${unitName}. Best rates guaranteed.`;

        // Image priority: Unit Main -> Property Main -> Default
        let imageUrl = 'https://bookbed.io/assets/images/logo-light.png'; // Fallback

        if (unitData.images && unitData.images.length > 0) {
            imageUrl = unitData.images[0];
        } else if (propertyData?.main_image) {
            imageUrl = propertyData.main_image;
        }

        // 3. Fetch Index HTML
        // Use the request hostname to fetch from the same domain
        // Protocol is usually https in Cloud Functions
        const host = req.get('host') || 'bookbed.io';
        const protocol = 'https';
        const indexUrl = `${protocol}://${host}/index.html`;

        console.log(`Fetching index from: ${indexUrl}`);
        const indexResponse = await fetch(indexUrl);
        let html = await indexResponse.text();

        // 4. Inject Meta Tags
        // We replace existing tags or inject new ones if missing
        // Simple string replacement for standard tags

        const tags = {
            'title': title,
            'description': description,
            'og:title': title,
            'og:description': description,
            'og:image': imageUrl,
            'og:url': `${protocol}://${host}/s/${unitId}`,
            'twitter:title': title,
            'twitter:description': description,
            'twitter:image': imageUrl,
        };

        // Helper to replace content of a meta tag
        const replaceMeta = (name: string, content: string, attribute = 'name') => {
            // Regex to match <meta name="X" content="..."> or <meta property="X" content="...">
            // Handles varying attribute order and quotes
            const regex = new RegExp(`<meta\\s+${attribute}=["']${name}["']\\s+content=["'][^"']*["']`, 'gi');

            if (regex.test(html)) {
                // Replace existing
                html = html.replace(regex, `<meta ${attribute}="${name}" content="${content}"`);
            } else {
                // Append to head if missing (not ideal but works)
                // Better: we assume index.html HAS these tags as placeholders
            }
        };

        // Replace Title
        html = html.replace(/<title>.*<\/title>/, `<title>${title}</title>`);

        // Replace Meta Tags
        replaceMeta('description', description, 'name');
        replaceMeta('og:title', title, 'property');
        replaceMeta('og:description', description, 'property');
        replaceMeta('og:image', imageUrl, 'property');
        replaceMeta('og:url', tags['og:url'], 'property');
        replaceMeta('twitter:title', title, 'name');
        replaceMeta('twitter:description', description, 'name');
        replaceMeta('twitter:image', imageUrl, 'name');

        // Replace Canonical URL
        // <link rel="canonical" href="...">
        const canonicalRegex = /<link\s+rel=["']canonical["']\s+href=["'][^"']*["']\s*\/?>/gi;
        if (canonicalRegex.test(html)) {
            html = html.replace(canonicalRegex, `<link rel="canonical" href="${tags['og:url']}" />`);
        } else {
            // Insert if missing (e.g. before </head>)
            html = html.replace(/<\/head>/i, `<link rel="canonical" href="${tags['og:url']}" />\n</head>`);
        }

        // Force absolute paths for base href if needed
        // Since we are serving from /s/..., relative paths in index.html like "flutter.js" might break
        // index.html usually has <base href="$FLUTTER_BASE_HREF"> which is replaced at build time.
        // If it's "/", then relative paths work from root.
        // But if the URL is /s/123, relative path "flutter.js" resolves to /s/flutter.js (404).
        // WE MUST FIX <base href> to be "/" explicitely if it's not absolute.
        html = html.replace(/<base\s+href=["']\/?["']\s*\/?>/i, '<base href="/">');
        // If it was already "/", it's replaced by "/" (no change)

        // 5. Send Response
        // Cache for 1 hour CDN, 0 seconds browser (to ensure freshness on re-share)
        res.set('Cache-Control', 'public, max-age=0, s-maxage=3600');
        res.status(200).send(html);

    } catch (error) {
        console.error('Error generating metadata:', error);
        // Fallback to static index
        res.redirect('/');
    }
});
