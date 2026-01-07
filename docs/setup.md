# Project Setup Guide

This guide provides all the necessary steps to set up the BookBed project for local development, testing, and deployment.

---

## 1. Prerequisites

Before you begin, ensure you have the following tools installed on your system:

- **Flutter SDK**: Version 3.x or higher.
- **Node.js**: Version 18 or higher (for Firebase Functions).
- **Firebase CLI**: Install globally via npm: `npm install -g firebase-tools`.
- **Stripe CLI**: Required for testing webhook integrations locally.
- **Git**: For version control.

---

## 2. Installation

Follow these steps to clone the repository and install all necessary dependencies.

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/bookbed.git
cd bookbed

# 2. Install Flutter dependencies for the frontend application
flutter pub get

# 3. Install npm dependencies for Firebase Functions
cd functions
npm install
cd ..
```

---

## 3. Firebase & Environment Setup

### Firebase Project

You need to connect the project to your own Firebase project.

```bash
# 1. Log in to the Firebase CLI
firebase login

# 2. Add your Firebase project to the local setup
# This will create a .firebaserc file.
firebase use --add
```
Follow the prompts to select or create a Firebase project.

### Environment Variables

The backend (Firebase Functions) requires several secret keys to integrate with third-party services like Stripe and Resend.

The project uses a `.env` file within the `functions/` directory to manage these keys for local development.

```bash
# 1. Navigate to the functions directory
cd functions

# 2. Create a .env file from the example template
# IMPORTANT: The .env file is git-ignored for security.
cp .env.example .env

# 3. Open functions/.env and add your secret keys
```

**Required Variables in `functions/.env`:**

| Variable              | Description                                                                 | Example Value      |
| --------------------- | --------------------------------------------------------------------------- | ------------------ |
| `STRIPE_SECRET_KEY`   | Your Stripe secret key (Test Mode key for local development).               | `sk_test_...`      |
| `STRIPE_WEBHOOK_SECRET`| The signing secret for your local Stripe webhook listener.                  | `whsec_...`        |
| `RESEND_API_KEY`      | Your API key for the Resend email service.                                  | `re_...`           |
| `BOOKING_DOMAIN`      | The primary domain for booking links (e.g., `bookbed.io`).                  | `localhost:5000`   |
| `ENCRYPTION_KEY`      | A 32-character secret key for encrypting sensitive data.                    | `a_very_secret_key`|

**Note on Production:** For deployed environments, these variables should be set as secrets in the Google Cloud Secret Manager, which Firebase Functions can access securely.

---

## 4. Running the Project Locally

To run the full application, you will need to start three separate processes in different terminal windows:

1.  **Flutter Web App**: The frontend dashboard and widget.
2.  **Firebase Emulators**: A local suite that emulates Firebase services (Auth, Firestore, Functions).
3.  **Stripe CLI**: Listens for Stripe events and forwards them to your local Firebase Functions emulator.

### Terminal 1: Start Flutter Web App

```bash
# This command starts the web server on port 5000
flutter run -d chrome --web-port=5000
```

### Terminal 2: Start Firebase Emulators

```bash
# This command starts emulators for Auth, Firestore, Functions, and Storage
firebase emulators:start
```

### Terminal 3: Start Stripe Webhook Listener

This command captures events from your Stripe account (in test mode) and forwards them to the `handleStripeWebhook` function running in your local emulator.

```bash
# Replace 'your-project' with your Firebase Project ID.
stripe listen --forward-to localhost:5001/your-project/us-central1/handleStripeWebhook
```

---

## 5. Deployment

### Deploying Firebase Functions

```bash
# 1. Navigate to the functions directory
cd functions

# 2. Build the TypeScript source code into JavaScript
npm run build

# 3. Deploy only the functions to Firebase
cd ..
firebase deploy --only functions
```

### Deploying the Flutter Web App

```bash
# 1. Build a release version of the web application
flutter build web --release

# 2. Deploy the web app to Firebase Hosting
firebase deploy --only hosting
```

---
