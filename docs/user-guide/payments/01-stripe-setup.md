# Stripe Setup Guide

Stripe is a leading online payment processor that allows you to securely accept credit and debit card payments from guests. Integrating Stripe with BookBed enables the "Instant Booking" feature on your widget, providing a seamless checkout experience.

## What is Stripe?

Stripe handles all the complexity of payment processing, including security, fraud detection, and bank transfers. When a guest pays through your widget with a credit card, Stripe processes the payment and deposits the funds into your bank account.

## How to Connect Stripe to BookBed

1.  **Create a Stripe Account:** If you don't already have one, go to [Stripe.com](https://stripe.com) and sign up for a free account. You will need to provide your business and bank account details to be able to receive payments.

2.  **Navigate to Payment Settings in BookBed:** In your BookBed dashboard, go to the **Settings > Payments** section, or access payment options directly from the **Widget Settings** tab in the Unit Hub.

3.  **Click "Connect with Stripe":** You will see a button to connect your Stripe account. Clicking this will redirect you to Stripe's website.

4.  **Authorize the Connection:** Log in to your Stripe account and follow the prompts to authorize the connection with BookBed. This gives BookBed permission to create checkout sessions on your behalf, but it does not give us access to your sensitive financial details.

5.  **Return to BookBed:** After authorization, you will be redirected back to BookBed. You should now see that your Stripe account is connected.

## Enabling Stripe Payments on Your Widget

Once your account is connected, you need to enable Stripe as a payment option.

1.  Go to the **Widget Settings** for the unit you want to configure.
2.  Select the **"Instant Booking"** mode.
3.  Under "Payment Methods", make sure the checkbox for **"Accept Credit Cards (via Stripe)"** is enabled.
4.  Save your settings.

## Viewing Payments in Stripe

You can log in to your Stripe dashboard at any time to see a detailed history of all payments, view upcoming payouts to your bank account, and manage refunds if necessary.

⚠️ **Security Information:** BookBed uses Stripe's secure integration, which means we never see or store your guests' credit card numbers. All sensitive data is handled directly by Stripe, ensuring PCI compliance and security.

_Screenshot placeholder: The payment settings screen in BookBed, showing the "Connect with Stripe" button._
