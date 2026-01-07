# BookBed Setup Guide

This guide provides comprehensive instructions for setting up, running, and deploying the BookBed application.

---

## 1. Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.x or higher.
- **Node.js**: Version 18 or higher (for Firebase Functions).
- **Firebase CLI**: Install globally via npm: `npm install -g firebase-tools`.
- **Stripe CLI**: For testing webhook integrations locally.
- **Git**: For version control.

---

## 2. Local Development Setup

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/bookbed.git
cd bookbed
```

### Step 2: Install Dependencies

- **Flutter**:
  ```bash
  flutter pub get
  ```

- **Firebase Functions**:
  ```bash
  cd functions
  npm install
  cd ..
  ```

### Step 3: Configure Firebase

1.  **Log in to Firebase**:
    ```bash
    firebase login
    ```
2.  **Select a Firebase Project**:
    ```bash
    firebase use --add
    ```
    Choose your Firebase project from the list when prompted.

### Step 4: Set Up Environment Variables

The project uses a `.env` file for managing secrets for Firebase Functions.

1.  **Create the `.env` file**:
    ```bash
    cp functions/.env.example functions/.env
    ```
2.  **Add your secrets** to `functions/.env`. This file is git-ignored.
    ```ini
    # Stripe
    STRIPE_SECRET_KEY=sk_test_...
    STRIPE_WEBHOOK_SECRET=whsec_...

    # Resend
    RESEND_API_KEY=re_...

    # The root domain for your booking widget and emails
    BOOKING_DOMAIN=bookbed.io
    ```

---

## 3. Running the Application Locally

To run the full application, you need to start the Flutter web app, the Firebase emulators, and (optionally) the Stripe webhook listener.

### Terminal 1: Start the Flutter Web App

This command starts the owner dashboard on port 5000.

```bash
flutter run -d chrome --web-port=5000
```

### Terminal 2: Start Firebase Emulators

The emulators provide a local environment for Firebase services.

```bash
firebase emulators:start
```

### Terminal 3: Start Stripe Webhook Listener (Optional)

This forwards Stripe events to your local Firebase Functions emulator.

```bash
stripe listen --forward-to localhost:5001/your-project/us-central1/handleStripeWebhook
```

---

## 4. Deployment

### Deploying Firebase Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

### Deploying the Flutter Web App (Owner Dashboard)

The owner dashboard is deployed to the `live` hosting target.

```bash
flutter build web --release
firebase deploy --only hosting:live
```

### Deploying the Embeddable Widget

The embeddable widget is a separate application and is deployed to the `widget` hosting target.

```bash
flutter build web --release --dart-define=APP_TYPE=widget
firebase deploy --only hosting:widget
```

---

## 5. Advanced Configuration

### Subdomain Setup for Booking View Page

The "view booking" page (sent in emails) uses a dedicated subdomain (`view.bookbed.io`) for clarity and security. This page is part of the `widget` application build.

**Deployment Steps**:

1.  **Add Custom Domain in Firebase Console**:
    - Go to your Firebase project -> Hosting.
    - Select the `bookbed-widget` hosting site.
    - Click "Add custom domain" and enter `view.bookbed.io`.
    - Follow the DNS verification steps provided by Firebase.

2.  **Configure DNS**:
    - Create a CNAME record in your DNS provider pointing `view` to `bookbed-widget.web.app`.
    - If using Cloudflare, you can proxy this record for added security benefits like DDoS protection and WAF. Ensure the SSL/TLS mode is set to "Full" or "Full (strict)".

3.  **Environment Variable**:
    - The `BOOKING_DOMAIN` environment variable in `functions/.env` is used to automatically construct the `view.bookbed.io` URLs in emails. Ensure it is set to your root domain (e.g., `bookbed.io`).
