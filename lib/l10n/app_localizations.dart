import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BookBed'**
  String get appName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginToYourAccount;

  /// No description provided for @authOwnerLogin.
  ///
  /// In en, this message translates to:
  /// **'Owner Login'**
  String get authOwnerLogin;

  /// No description provided for @authManageProperties.
  ///
  /// In en, this message translates to:
  /// **'Manage your properties and bookings'**
  String get authManageProperties;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get authRememberMe;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authPreviewDemo.
  ///
  /// In en, this message translates to:
  /// **'Preview Demo (Anonymous)'**
  String get authPreviewDemo;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Your Password'**
  String get authResetPassword;

  /// No description provided for @authResetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you instructions to reset your password.'**
  String get authResetPasswordDesc;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendResetLink;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get authBackToLogin;

  /// No description provided for @authEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Email Sent!'**
  String get authEmailSent;

  /// No description provided for @authResetEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent password reset instructions to:'**
  String get authResetEmailSentTo;

  /// No description provided for @authReturnToLogin.
  ///
  /// In en, this message translates to:
  /// **'Return to Login'**
  String get authReturnToLogin;

  /// No description provided for @authResendEmail.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email? Resend'**
  String get authResendEmail;

  /// No description provided for @authStartManaging.
  ///
  /// In en, this message translates to:
  /// **'Start managing your properties today'**
  String get authStartManaging;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// No description provided for @authPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get authPhone;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I accept the '**
  String get authAcceptTerms;

  /// No description provided for @authTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get authTermsConditions;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authNewsletterOptIn.
  ///
  /// In en, this message translates to:
  /// **'Send me updates and promotional offers'**
  String get authNewsletterOptIn;

  /// No description provided for @authMustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'You must accept the Terms & Conditions and Privacy Policy'**
  String get authMustAcceptTerms;

  /// No description provided for @authEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get authEnterFullName;

  /// No description provided for @authEnterFirstLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter both first and last name'**
  String get authEnterFirstLastName;

  /// No description provided for @authIncorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Try again or reset your password.'**
  String get authIncorrectPassword;

  /// No description provided for @authWelcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String authWelcomeUser(String name);

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged in!'**
  String get loginSuccessful;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @googleLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleLoginFailed;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get createNewAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Account successfully created!'**
  String get registrationSuccessful;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @googleRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Google registration failed'**
  String get googleRegistrationFailed;

  /// No description provided for @acceptTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept terms of service'**
  String get acceptTermsRequired;

  /// No description provided for @firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get lastNameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validEmailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @guestDescription.
  ///
  /// In en, this message translates to:
  /// **'I want to book accommodation'**
  String get guestDescription;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @ownerDescription.
  ///
  /// In en, this message translates to:
  /// **'I want to rent out my property'**
  String get ownerDescription;

  /// No description provided for @iAccept.
  ///
  /// In en, this message translates to:
  /// **'I accept '**
  String get iAccept;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterYourEmail;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// No description provided for @propertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Property Details'**
  String get propertyDetails;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @perNight.
  ///
  /// In en, this message translates to:
  /// **'per night'**
  String get perNight;

  /// No description provided for @guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guests;

  /// No description provided for @bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedrooms;

  /// No description provided for @bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @booking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get booking;

  /// No description provided for @bookingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmation'**
  String get bookingConfirmation;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkOut;

  /// Number of nights
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get nights;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @guestDetails.
  ///
  /// In en, this message translates to:
  /// **'Guest Details'**
  String get guestDetails;

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking Cancelled'**
  String get bookingCancelled;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingInformation.
  ///
  /// In en, this message translates to:
  /// **'Booking Information'**
  String get bookingInformation;

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingId;

  /// No description provided for @bookingDate.
  ///
  /// In en, this message translates to:
  /// **'Booking Date'**
  String get bookingDate;

  /// No description provided for @stayDetails.
  ///
  /// In en, this message translates to:
  /// **'Stay Details'**
  String get stayDetails;

  /// No description provided for @arrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrival;

  /// No description provided for @departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departure;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get night;

  /// No description provided for @nightsPlural.
  ///
  /// In en, this message translates to:
  /// **'nights'**
  String get nightsPlural;

  /// No description provided for @guestsPlural.
  ///
  /// In en, this message translates to:
  /// **'guests'**
  String get guestsPlural;

  /// No description provided for @paymentInformation.
  ///
  /// In en, this message translates to:
  /// **'Payment Information'**
  String get paymentInformation;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @cancellationDetails.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Details'**
  String get cancellationDetails;

  /// No description provided for @cancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled On'**
  String get cancelledOn;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @viewProperty.
  ///
  /// In en, this message translates to:
  /// **'View Property'**
  String get viewProperty;

  /// No description provided for @errorLoadingBooking.
  ///
  /// In en, this message translates to:
  /// **'Error loading booking'**
  String get errorLoadingBooking;

  /// No description provided for @tryAgainOrContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Try again or contact support'**
  String get tryAgainOrContactSupport;

  /// No description provided for @cancelBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBookingTitle;

  /// No description provided for @cancelBookingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking? This action cannot be undone.'**
  String get cancelBookingConfirmation;

  /// No description provided for @cancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason'**
  String get cancellationReason;

  /// No description provided for @cancellationReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Please specify reason for cancellation'**
  String get cancellationReasonHint;

  /// No description provided for @cancellationReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please specify reason for cancellation'**
  String get cancellationReasonRequired;

  /// No description provided for @keepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep Booking'**
  String get keepBooking;

  /// No description provided for @bookingCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Booking successfully cancelled'**
  String get bookingCancelledSuccessfully;

  /// No description provided for @bookingCancellationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel booking'**
  String get bookingCancellationFailed;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a Review'**
  String get writeReview;

  /// No description provided for @editReview.
  ///
  /// In en, this message translates to:
  /// **'Edit Review'**
  String get editReview;

  /// No description provided for @yourReview.
  ///
  /// In en, this message translates to:
  /// **'Your Review'**
  String get yourReview;

  /// No description provided for @overallRating.
  ///
  /// In en, this message translates to:
  /// **'Overall Rating'**
  String get overallRating;

  /// No description provided for @cleanliness.
  ///
  /// In en, this message translates to:
  /// **'Cleanliness'**
  String get cleanliness;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No Favorites Yet'**
  String get noFavorites;

  /// No description provided for @toggleFavoriteStatus.
  ///
  /// In en, this message translates to:
  /// **'Toggle favorite status for this property'**
  String get toggleFavoriteStatus;

  /// No description provided for @propertyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Property not found'**
  String get propertyNotFound;

  /// No description provided for @propertyNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This property may no longer be available.'**
  String get propertyNoLongerAvailable;

  /// No description provided for @errorLoadingProperty.
  ///
  /// In en, this message translates to:
  /// **'Error loading property'**
  String get errorLoadingProperty;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noFavoritesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add properties to favorites to find them easily later.'**
  String get noFavoritesDescription;

  /// No description provided for @browseProperties.
  ///
  /// In en, this message translates to:
  /// **'Browse Properties'**
  String get browseProperties;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @enterCurrentAndNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one'**
  String get enterCurrentAndNewPassword;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weakPassword;

  /// No description provided for @mediumPassword.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumPassword;

  /// No description provided for @strongPassword.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strongPassword;

  /// No description provided for @recentLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign out and sign in again before changing password'**
  String get recentLoginRequired;

  /// No description provided for @passwordChangeError.
  ///
  /// In en, this message translates to:
  /// **'Error changing password'**
  String get passwordChangeError;

  /// No description provided for @passwordsMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get passwordsMustBeDifferent;

  /// No description provided for @pleaseEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get pleaseEnterCurrentPassword;

  /// No description provided for @youWillStayLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You will stay logged in after changing your password'**
  String get youWillStayLoggedIn;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @croatian.
  ///
  /// In en, this message translates to:
  /// **'Croatian'**
  String get croatian;

  /// No description provided for @searchProperties.
  ///
  /// In en, this message translates to:
  /// **'Search Properties'**
  String get searchProperties;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or category'**
  String get tryDifferentSearch;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyType;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @errorSavingData.
  ///
  /// In en, this message translates to:
  /// **'Error saving data'**
  String get errorSavingData;

  /// No description provided for @pleaseCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get pleaseCheckConnection;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get tryAgainLater;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get invalidPassword;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get savedSuccessfully;

  /// No description provided for @updatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully'**
  String get updatedSuccessfully;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deletedSuccessfully;

  /// No description provided for @bookingCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Booking created successfully'**
  String get bookingCreatedSuccessfully;

  /// No description provided for @reviewSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully'**
  String get reviewSubmittedSuccessfully;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsTitle;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @termsAcceptanceTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get termsAcceptanceTitle;

  /// No description provided for @termsAcceptanceBody.
  ///
  /// In en, this message translates to:
  /// **'By accessing and using this vacation rental platform, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.'**
  String get termsAcceptanceBody;

  /// No description provided for @termsUseOfServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Use of Service'**
  String get termsUseOfServiceTitle;

  /// No description provided for @termsUseOfServiceBody.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old to use this service. You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.'**
  String get termsUseOfServiceBody;

  /// No description provided for @termsUserAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'3. User Accounts'**
  String get termsUserAccountsTitle;

  /// No description provided for @termsUserAccountsBody.
  ///
  /// In en, this message translates to:
  /// **'When you create an account with us, you must provide accurate and complete information. You must promptly update your account information if it changes. You are responsible for safeguarding the password that you use to access the service.'**
  String get termsUserAccountsBody;

  /// No description provided for @termsBookingsPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Bookings and Payments'**
  String get termsBookingsPaymentsTitle;

  /// No description provided for @termsBookingsPaymentsBody.
  ///
  /// In en, this message translates to:
  /// **'All bookings are subject to availability and confirmation. Payment must be made in full at the time of booking unless otherwise specified. Prices are subject to change without notice but confirmed bookings will honor the originally quoted price.'**
  String get termsBookingsPaymentsBody;

  /// No description provided for @termsCancellationTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Cancellation Policy'**
  String get termsCancellationTitle;

  /// No description provided for @termsCancellationBody.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policies vary by property. Please review the specific cancellation policy for each property before booking. Refunds, if applicable, will be processed according to the property\'s cancellation policy and may take 5-10 business days.'**
  String get termsCancellationBody;

  /// No description provided for @termsPropertyOwnersTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Property Owners Responsibilities'**
  String get termsPropertyOwnersTitle;

  /// No description provided for @termsPropertyOwnersBody.
  ///
  /// In en, this message translates to:
  /// **'Property owners must provide accurate descriptions and photos of their properties. They must maintain their properties in good condition and ensure availability as listed. Owners are responsible for complying with all local laws and regulations.'**
  String get termsPropertyOwnersBody;

  /// No description provided for @termsGuestResponsibilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Guest Responsibilities'**
  String get termsGuestResponsibilitiesTitle;

  /// No description provided for @termsGuestResponsibilitiesBody.
  ///
  /// In en, this message translates to:
  /// **'Guests must treat properties with respect and care. Any damages beyond normal wear and tear will be charged to the guest. Guests must comply with property rules, local laws, and neighborhood ordinances.'**
  String get termsGuestResponsibilitiesBody;

  /// No description provided for @termsReviewsRatingsTitle.
  ///
  /// In en, this message translates to:
  /// **'8. Reviews and Ratings'**
  String get termsReviewsRatingsTitle;

  /// No description provided for @termsReviewsRatingsBody.
  ///
  /// In en, this message translates to:
  /// **'Users may leave reviews and ratings for properties they have booked. Reviews must be honest, accurate, and relevant to the property. We reserve the right to remove reviews that violate our guidelines.'**
  String get termsReviewsRatingsBody;

  /// No description provided for @termsLimitationLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'9. Limitation of Liability'**
  String get termsLimitationLiabilityTitle;

  /// No description provided for @termsLimitationLiabilityBody.
  ///
  /// In en, this message translates to:
  /// **'We are not responsible for the accuracy of property listings or the conduct of property owners or guests. We do not guarantee the quality, safety, or legality of properties listed. Use of this service is at your own risk.'**
  String get termsLimitationLiabilityBody;

  /// No description provided for @termsDisputesTitle.
  ///
  /// In en, this message translates to:
  /// **'10. Disputes'**
  String get termsDisputesTitle;

  /// No description provided for @termsDisputesBody.
  ///
  /// In en, this message translates to:
  /// **'In case of disputes between guests and property owners, we encourage direct communication. We may assist in mediation but are not obligated to do so. Any unresolved disputes shall be resolved through arbitration.'**
  String get termsDisputesBody;

  /// No description provided for @termsChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'11. Changes to Terms'**
  String get termsChangesTitle;

  /// No description provided for @termsChangesBody.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify these terms at any time. Changes will be effective immediately upon posting to the website. Your continued use of the service after changes constitutes acceptance of the new terms.'**
  String get termsChangesBody;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyInfoCollectTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Information We Collect'**
  String get privacyInfoCollectTitle;

  /// No description provided for @privacyInfoCollectBody.
  ///
  /// In en, this message translates to:
  /// **'We collect information you provide directly to us, including:\n\n• Personal information (name, email, phone number)\n• Payment information\n• Booking history and preferences\n• Communication and correspondence\n• Device and usage information'**
  String get privacyInfoCollectBody;

  /// No description provided for @privacyHowWeUseTitle.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Your Information'**
  String get privacyHowWeUseTitle;

  /// No description provided for @privacyHowWeUseBody.
  ///
  /// In en, this message translates to:
  /// **'We use the information we collect to:\n\n• Process bookings and payments\n• Communicate with you about your bookings\n• Improve our services\n• Send marketing communications (with your consent)\n• Comply with legal obligations'**
  String get privacyHowWeUseBody;

  /// No description provided for @privacySharingInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Sharing Your Information'**
  String get privacySharingInfoTitle;

  /// No description provided for @privacySharingInfoBody.
  ///
  /// In en, this message translates to:
  /// **'We may share your information with:\n\n• Property owners (for bookings)\n• Payment processors\n• Service providers and partners\n• Law enforcement (when required by law)\n\nWe do not sell your personal information to third parties.'**
  String get privacySharingInfoBody;

  /// No description provided for @privacyDataSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Data Security'**
  String get privacyDataSecurityTitle;

  /// No description provided for @privacyDataSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'We implement appropriate security measures to protect your personal information. However, no method of transmission over the Internet is 100% secure. We cannot guarantee absolute security of your data.'**
  String get privacyDataSecurityBody;

  /// No description provided for @privacyDataRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Data Retention'**
  String get privacyDataRetentionTitle;

  /// No description provided for @privacyDataRetentionBody.
  ///
  /// In en, this message translates to:
  /// **'We retain your personal information for as long as necessary to provide our services and comply with legal obligations. You may request deletion of your data at any time, subject to legal requirements.'**
  String get privacyDataRetentionBody;

  /// No description provided for @privacyYourRightsTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Your Rights'**
  String get privacyYourRightsTitle;

  /// No description provided for @privacyYourRightsBody.
  ///
  /// In en, this message translates to:
  /// **'Under GDPR, you have the right to:\n\n• Access your personal data\n• Correct inaccurate data\n• Request deletion of your data\n• Object to data processing\n• Data portability\n• Withdraw consent\n\nContact us at info@bookbed.io to exercise your rights.'**
  String get privacyYourRightsBody;

  /// No description provided for @privacyCookiesTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Cookies and Tracking'**
  String get privacyCookiesTitle;

  /// No description provided for @privacyCookiesBody.
  ///
  /// In en, this message translates to:
  /// **'We use cookies and similar tracking technologies to improve your browsing experience. You can control cookies through your browser settings. Some features may not function properly if cookies are disabled.'**
  String get privacyCookiesBody;

  /// No description provided for @privacyThirdPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'8. Third-Party Services'**
  String get privacyThirdPartyTitle;

  /// No description provided for @privacyThirdPartyBody.
  ///
  /// In en, this message translates to:
  /// **'Our service may contain links to third-party websites. We are not responsible for the privacy practices of these sites. Please review their privacy policies before providing any information.'**
  String get privacyThirdPartyBody;

  /// No description provided for @privacyChildrenTitle.
  ///
  /// In en, this message translates to:
  /// **'9. Children\'s Privacy'**
  String get privacyChildrenTitle;

  /// No description provided for @privacyChildrenBody.
  ///
  /// In en, this message translates to:
  /// **'Our service is not intended for children under 18. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.'**
  String get privacyChildrenBody;

  /// No description provided for @privacyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'10. Changes to Privacy Policy'**
  String get privacyChangesTitle;

  /// No description provided for @privacyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page. Changes are effective immediately upon posting.'**
  String get privacyChangesBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about this Privacy Policy, please contact us at:\n\nEmail: info@bookbed.io\nWebsite: bookbed.io'**
  String get privacyContactBody;

  /// No description provided for @helpFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpFaq;

  /// No description provided for @searchForHelp.
  ///
  /// In en, this message translates to:
  /// **'Search for help...'**
  String get searchForHelp;

  /// No description provided for @allTopics.
  ///
  /// In en, this message translates to:
  /// **'All Topics'**
  String get allTopics;

  /// No description provided for @faqBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get faqBooking;

  /// No description provided for @faqPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get faqPayment;

  /// No description provided for @faqCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get faqCancellation;

  /// No description provided for @faqProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get faqProperty;

  /// No description provided for @faqAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get faqAccount;

  /// No description provided for @stillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get stillNeedHelp;

  /// No description provided for @contactSupportTeam.
  ///
  /// In en, this message translates to:
  /// **'Contact our support team'**
  String get contactSupportTeam;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @faqHowToBook.
  ///
  /// In en, this message translates to:
  /// **'How do I make a booking?'**
  String get faqHowToBook;

  /// No description provided for @faqHowToBookAnswer.
  ///
  /// In en, this message translates to:
  /// **'To make a booking:\n\n1. Search for properties using the search bar on the home page\n2. Browse available properties and click on one to view details\n3. Select your check-in and check-out dates\n4. Choose the number of guests\n5. Click \"Book Now\" and follow the checkout process\n6. Enter your payment information and confirm the booking\n\nYou will receive a confirmation email once your booking is complete.'**
  String get faqHowToBookAnswer;

  /// No description provided for @faqModifyBooking.
  ///
  /// In en, this message translates to:
  /// **'Can I modify my booking after confirmation?'**
  String get faqModifyBooking;

  /// No description provided for @faqModifyBookingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can modify certain aspects of your booking depending on the property\'s policy. To modify your booking:\n\n1. Go to \"My Bookings\" in your account\n2. Select the booking you want to modify\n3. Click \"Modify Booking\"\n4. Make your changes (dates, guests, etc.)\n\nNote: Changes may be subject to availability and additional charges. Some properties may not allow modifications within a certain timeframe before check-in.'**
  String get faqModifyBookingAnswer;

  /// No description provided for @faqBookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'How do I know if my booking is confirmed?'**
  String get faqBookingConfirmed;

  /// No description provided for @faqBookingConfirmedAnswer.
  ///
  /// In en, this message translates to:
  /// **'You will receive a confirmation email immediately after your booking is complete. The email will include:\n\n• Booking reference number\n• Property details\n• Check-in and check-out dates\n• Total amount paid\n• Host contact information\n\nYou can also check your booking status in the \"My Bookings\" section of your account.'**
  String get faqBookingConfirmedAnswer;

  /// No description provided for @faqPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'What payment methods are accepted?'**
  String get faqPaymentMethods;

  /// No description provided for @faqPaymentMethodsAnswer.
  ///
  /// In en, this message translates to:
  /// **'We accept the following payment methods:\n\n• Credit cards (Visa, MasterCard, American Express)\n• Debit cards\n• PayPal\n• Apple Pay\n• Google Pay\n\nAll payments are processed securely through our payment provider. We do not store your payment card details on our servers.'**
  String get faqPaymentMethodsAnswer;

  /// No description provided for @faqWhenCharged.
  ///
  /// In en, this message translates to:
  /// **'When will I be charged?'**
  String get faqWhenCharged;

  /// No description provided for @faqWhenChargedAnswer.
  ///
  /// In en, this message translates to:
  /// **'Payment is processed immediately when you confirm your booking. The full amount, including the property price, service fees, and any applicable taxes, will be charged to your payment method.\n\nFor certain properties or long-term bookings, installment payment options may be available.'**
  String get faqWhenChargedAnswer;

  /// No description provided for @faqAdditionalFees.
  ///
  /// In en, this message translates to:
  /// **'Are there any additional fees?'**
  String get faqAdditionalFees;

  /// No description provided for @faqAdditionalFeesAnswer.
  ///
  /// In en, this message translates to:
  /// **'In addition to the property price, you may be charged:\n\n• Service fee (typically 10-15% of the booking subtotal)\n• Cleaning fee (if applicable, set by the property owner)\n• Local taxes (varies by location)\n\nAll fees are clearly displayed before you confirm your booking. There are no hidden charges.'**
  String get faqAdditionalFeesAnswer;

  /// No description provided for @faqCancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'What is the cancellation policy?'**
  String get faqCancellationPolicy;

  /// No description provided for @faqCancellationPolicyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policies vary by property. Common policies include:\n\n• Flexible: Full refund if cancelled 24-48 hours before check-in\n• Moderate: 50% refund if cancelled 5-7 days before check-in\n• Strict: No refund if cancelled within 14 days of check-in\n\nAlways check the specific cancellation policy for each property before booking. The policy is displayed on the property details page and in your booking confirmation.'**
  String get faqCancellationPolicyAnswer;

  /// No description provided for @faqHowToCancel.
  ///
  /// In en, this message translates to:
  /// **'How do I cancel my booking?'**
  String get faqHowToCancel;

  /// No description provided for @faqHowToCancelAnswer.
  ///
  /// In en, this message translates to:
  /// **'To cancel a booking:\n\n1. Go to \"My Bookings\" in your account\n2. Select the booking you want to cancel\n3. Click \"Cancel Booking\"\n4. Review the cancellation policy and refund amount\n5. Confirm the cancellation\n\nYour refund (if applicable) will be processed within 5-10 business days to your original payment method.'**
  String get faqHowToCancelAnswer;

  /// No description provided for @faqFullRefund.
  ///
  /// In en, this message translates to:
  /// **'Will I get a full refund if I cancel?'**
  String get faqFullRefund;

  /// No description provided for @faqFullRefundAnswer.
  ///
  /// In en, this message translates to:
  /// **'The refund amount depends on:\n\n• The property\'s cancellation policy\n• How far in advance you cancel\n• Whether you purchased trip insurance\n\nThe exact refund amount is calculated and shown before you confirm the cancellation. Service fees may be non-refundable depending on the timing of your cancellation.'**
  String get faqFullRefundAnswer;

  /// No description provided for @faqContactOwner.
  ///
  /// In en, this message translates to:
  /// **'How do I contact the property owner?'**
  String get faqContactOwner;

  /// No description provided for @faqContactOwnerAnswer.
  ///
  /// In en, this message translates to:
  /// **'Once your booking is confirmed, you can contact the property owner through:\n\n1. The messaging system in your booking details\n2. The contact information provided in your confirmation email\n3. The \"Contact Host\" button on the property page\n\nAll messages are monitored for safety and quality assurance.'**
  String get faqContactOwnerAnswer;

  /// No description provided for @faqPropertyMismatch.
  ///
  /// In en, this message translates to:
  /// **'What if the property doesn\'t match the description?'**
  String get faqPropertyMismatch;

  /// No description provided for @faqPropertyMismatchAnswer.
  ///
  /// In en, this message translates to:
  /// **'If the property doesn\'t match the description or photos:\n\n1. Document the issues with photos\n2. Contact the property owner immediately\n3. If unresolved, contact our customer support within 24 hours of check-in\n\nWe may offer a partial refund, help you find alternative accommodation, or provide other resolutions depending on the situation.'**
  String get faqPropertyMismatchAnswer;

  /// No description provided for @faqLeaveReview.
  ///
  /// In en, this message translates to:
  /// **'How do I leave a review?'**
  String get faqLeaveReview;

  /// No description provided for @faqLeaveReviewAnswer.
  ///
  /// In en, this message translates to:
  /// **'After your stay, you can leave a review:\n\n1. Go to \"My Bookings\"\n2. Find your completed booking\n3. Click \"Write a Review\"\n4. Rate your experience and write your feedback\n5. Submit the review\n\nReviews help other guests make informed decisions and help property owners improve their service.'**
  String get faqLeaveReviewAnswer;

  /// No description provided for @faqCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'How do I create an account?'**
  String get faqCreateAccount;

  /// No description provided for @faqCreateAccountAnswer.
  ///
  /// In en, this message translates to:
  /// **'To create an account:\n\n1. Click \"Sign Up\" or \"Register\" in the top right corner\n2. Enter your email address and create a password\n3. Or sign up using Google or Facebook\n4. Verify your email address\n5. Complete your profile information\n\nCreating an account allows you to save favorite properties, manage bookings, and receive personalized recommendations.'**
  String get faqCreateAccountAnswer;

  /// No description provided for @faqForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'I forgot my password. How do I reset it?'**
  String get faqForgotPassword;

  /// No description provided for @faqForgotPasswordAnswer.
  ///
  /// In en, this message translates to:
  /// **'To reset your password:\n\n1. Click \"Login\" then \"Forgot Password\"\n2. Enter your email address\n3. Check your email for a password reset link\n4. Click the link and create a new password\n5. Log in with your new password\n\nIf you don\'t receive the email, check your spam folder or contact support.'**
  String get faqForgotPasswordAnswer;

  /// No description provided for @faqUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile information?'**
  String get faqUpdateProfile;

  /// No description provided for @faqUpdateProfileAnswer.
  ///
  /// In en, this message translates to:
  /// **'To update your profile:\n\n1. Log in to your account\n2. Click on your profile icon\n3. Select \"Profile Settings\"\n4. Update your information (name, email, phone, photo)\n5. Save your changes\n\nKeeping your profile up to date helps property owners contact you and ensures a smooth booking experience.'**
  String get faqUpdateProfileAnswer;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @getInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in Touch'**
  String get getInTouch;

  /// No description provided for @contactDescription.
  ///
  /// In en, this message translates to:
  /// **'Have a question or need help? Send us a message and we\'ll get back to you as soon as possible.'**
  String get contactDescription;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhone;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourName;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @whatIsMessageAbout.
  ///
  /// In en, this message translates to:
  /// **'What is your message about?'**
  String get whatIsMessageAbout;

  /// No description provided for @pleaseEnterSubject.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject'**
  String get pleaseEnterSubject;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @enterMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Enter your message here...'**
  String get enterMessageHere;

  /// No description provided for @pleaseEnterMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter your message'**
  String get pleaseEnterMessage;

  /// No description provided for @messageTooShort.
  ///
  /// In en, this message translates to:
  /// **'Message must be at least 10 characters'**
  String get messageTooShort;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @responseTime.
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get responseTime;

  /// No description provided for @responseTimeDescription.
  ///
  /// In en, this message translates to:
  /// **'We typically respond within 24 hours during business days. For urgent matters, please call our support line.'**
  String get responseTimeDescription;

  /// No description provided for @messageSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your message has been sent successfully!'**
  String get messageSentSuccess;

  /// No description provided for @messageSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get messageSendFailed;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Your Perfect Getaway on Rab Island'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Premium villas, apartments & vacation homes in the heart of the Adriatic'**
  String get homeHeroSubtitle;

  /// No description provided for @featuredPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured Properties'**
  String get featuredPropertiesTitle;

  /// No description provided for @featuredPropertiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hand-picked properties for your perfect stay'**
  String get featuredPropertiesSubtitle;

  /// No description provided for @recentlyViewedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed'**
  String get recentlyViewedTitle;

  /// No description provided for @recentlyViewedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Properties you have viewed recently'**
  String get recentlyViewedSubtitle;

  /// No description provided for @popularDestinationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular Destinations'**
  String get popularDestinationsTitle;

  /// No description provided for @popularDestinationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore the most sought-after vacation spots on Rab Island'**
  String get popularDestinationsSubtitle;

  /// No description provided for @howItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorksTitle;

  /// No description provided for @howItWorksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book your dream vacation in three simple steps'**
  String get howItWorksSubtitle;

  /// No description provided for @testimonialsTitle.
  ///
  /// In en, this message translates to:
  /// **'What Our Guests Say'**
  String get testimonialsTitle;

  /// No description provided for @testimonialsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real experiences from real travelers'**
  String get testimonialsSubtitle;

  /// No description provided for @ctaGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get ctaGetStarted;

  /// No description provided for @ctaLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get ctaLearnMore;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @widgetSelectDates.
  ///
  /// In en, this message translates to:
  /// **'Select Dates'**
  String get widgetSelectDates;

  /// No description provided for @widgetGuestInformation.
  ///
  /// In en, this message translates to:
  /// **'Guest Information'**
  String get widgetGuestInformation;

  /// No description provided for @widgetPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get widgetPaymentMethod;

  /// No description provided for @widgetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get widgetConfirmation;

  /// No description provided for @widgetFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get widgetFullName;

  /// No description provided for @widgetEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get widgetEmailAddress;

  /// No description provided for @widgetPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get widgetPhoneNumber;

  /// No description provided for @widgetSpecialRequests.
  ///
  /// In en, this message translates to:
  /// **'Special Requests (Optional)'**
  String get widgetSpecialRequests;

  /// No description provided for @widgetSpecialRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Any special requests or notes...'**
  String get widgetSpecialRequestsHint;

  /// No description provided for @widgetContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get widgetContinue;

  /// No description provided for @widgetPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get widgetPrevious;

  /// No description provided for @widgetAdults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get widgetAdults;

  /// No description provided for @widgetChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get widgetChildren;

  /// No description provided for @widgetNumberOfGuests.
  ///
  /// In en, this message translates to:
  /// **'Number of Guests'**
  String get widgetNumberOfGuests;

  /// No description provided for @widgetTotalNights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Night} other{{count} Nights}}'**
  String widgetTotalNights(int count);

  /// No description provided for @widgetSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get widgetSubtotal;

  /// No description provided for @widgetCleaningFee.
  ///
  /// In en, this message translates to:
  /// **'Cleaning Fee'**
  String get widgetCleaningFee;

  /// No description provided for @widgetServiceFee.
  ///
  /// In en, this message translates to:
  /// **'Service Fee'**
  String get widgetServiceFee;

  /// No description provided for @widgetTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get widgetTaxes;

  /// No description provided for @widgetTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get widgetTotal;

  /// No description provided for @widgetPaymentOptions.
  ///
  /// In en, this message translates to:
  /// **'Payment Options'**
  String get widgetPaymentOptions;

  /// No description provided for @widgetFullPayment.
  ///
  /// In en, this message translates to:
  /// **'Full Payment'**
  String get widgetFullPayment;

  /// No description provided for @widgetFullPaymentDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay 100% now'**
  String get widgetFullPaymentDesc;

  /// No description provided for @widgetDepositPayment.
  ///
  /// In en, this message translates to:
  /// **'Deposit Payment'**
  String get widgetDepositPayment;

  /// No description provided for @widgetDepositPaymentDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay 20% now, rest on arrival'**
  String get widgetDepositPaymentDesc;

  /// No description provided for @widgetSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get widgetSelectPaymentMethod;

  /// No description provided for @widgetBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get widgetBankTransfer;

  /// No description provided for @widgetBankTransferDesc.
  ///
  /// In en, this message translates to:
  /// **'Transfer to our bank account (3-day deadline)'**
  String get widgetBankTransferDesc;

  /// No description provided for @widgetBankTransferNote.
  ///
  /// In en, this message translates to:
  /// **'You will receive payment instructions via email'**
  String get widgetBankTransferNote;

  /// No description provided for @widgetCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get widgetCreditCard;

  /// No description provided for @widgetCreditCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay instantly with Stripe'**
  String get widgetCreditCardDesc;

  /// No description provided for @widgetCreditCardBadge.
  ///
  /// In en, this message translates to:
  /// **'INSTANT'**
  String get widgetCreditCardBadge;

  /// No description provided for @widgetPayOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Pay on Arrival'**
  String get widgetPayOnArrival;

  /// No description provided for @widgetPayOnArrivalDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay in cash or card at check-in'**
  String get widgetPayOnArrivalDesc;

  /// No description provided for @widgetBookingReference.
  ///
  /// In en, this message translates to:
  /// **'Booking Reference'**
  String get widgetBookingReference;

  /// No description provided for @widgetBookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed!'**
  String get widgetBookingConfirmed;

  /// No description provided for @widgetThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your booking'**
  String get widgetThankYou;

  /// No description provided for @widgetConfirmationSent.
  ///
  /// In en, this message translates to:
  /// **'A confirmation email has been sent to {email}'**
  String widgetConfirmationSent(String email);

  /// No description provided for @widgetBankTransferInstructions.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer Instructions'**
  String get widgetBankTransferInstructions;

  /// No description provided for @widgetBankAccountHolder.
  ///
  /// In en, this message translates to:
  /// **'Account Holder'**
  String get widgetBankAccountHolder;

  /// No description provided for @widgetBankName.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get widgetBankName;

  /// No description provided for @widgetBankIban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get widgetBankIban;

  /// No description provided for @widgetPaymentReference.
  ///
  /// In en, this message translates to:
  /// **'Payment Reference'**
  String get widgetPaymentReference;

  /// No description provided for @widgetPaymentDeadline.
  ///
  /// In en, this message translates to:
  /// **'Payment Deadline'**
  String get widgetPaymentDeadline;

  /// No description provided for @widgetImportantNote.
  ///
  /// In en, this message translates to:
  /// **'Important Note'**
  String get widgetImportantNote;

  /// No description provided for @widgetIncludeReference.
  ///
  /// In en, this message translates to:
  /// **'Please include the booking reference in your transfer'**
  String get widgetIncludeReference;

  /// No description provided for @widgetPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by'**
  String get widgetPoweredBy;

  /// No description provided for @widgetAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get widgetAvailable;

  /// No description provided for @widgetBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get widgetBooked;

  /// No description provided for @widgetCheckInOnly.
  ///
  /// In en, this message translates to:
  /// **'Check-in only'**
  String get widgetCheckInOnly;

  /// No description provided for @widgetCheckOutOnly.
  ///
  /// In en, this message translates to:
  /// **'Check-out only'**
  String get widgetCheckOutOnly;

  /// No description provided for @widgetBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get widgetBlocked;

  /// No description provided for @widgetPricePerNight.
  ///
  /// In en, this message translates to:
  /// **'€{price} / night'**
  String widgetPricePerNight(String price);

  /// No description provided for @widgetSelectCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Select check-in date'**
  String get widgetSelectCheckIn;

  /// No description provided for @widgetSelectCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Select check-out date'**
  String get widgetSelectCheckOut;

  /// No description provided for @widgetMinimumStay.
  ///
  /// In en, this message translates to:
  /// **'Minimum stay: {nights} nights'**
  String widgetMinimumStay(int nights);

  /// No description provided for @widgetDatesNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Selected dates are not available'**
  String get widgetDatesNotAvailable;

  /// No description provided for @widgetPleaseSelectOtherDates.
  ///
  /// In en, this message translates to:
  /// **'Please select different dates'**
  String get widgetPleaseSelectOtherDates;

  /// No description provided for @widgetErrorLoadingAvailability.
  ///
  /// In en, this message translates to:
  /// **'Error loading availability'**
  String get widgetErrorLoadingAvailability;

  /// No description provided for @widgetErrorCreatingBooking.
  ///
  /// In en, this message translates to:
  /// **'Error creating booking'**
  String get widgetErrorCreatingBooking;

  /// No description provided for @widgetPleaseCheckFormErrors.
  ///
  /// In en, this message translates to:
  /// **'Please check form errors and try again'**
  String get widgetPleaseCheckFormErrors;

  /// No description provided for @widgetFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get widgetFieldRequired;

  /// No description provided for @widgetInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get widgetInvalidEmail;

  /// No description provided for @widgetInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get widgetInvalidPhone;

  /// No description provided for @widgetNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get widgetNameTooShort;

  /// No description provided for @widgetProcessingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing payment...'**
  String get widgetProcessingPayment;

  /// No description provided for @widgetCreatingBooking.
  ///
  /// In en, this message translates to:
  /// **'Creating booking...'**
  String get widgetCreatingBooking;

  /// No description provided for @widgetPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get widgetPleaseWait;

  /// No description provided for @widgetCancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Policy'**
  String get widgetCancellationPolicy;

  /// No description provided for @widgetFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation up to 24 hours before check-in'**
  String get widgetFreeCancellation;

  /// No description provided for @widgetNoRefund.
  ///
  /// In en, this message translates to:
  /// **'No refund after this date'**
  String get widgetNoRefund;

  /// No description provided for @widgetTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'By booking, you agree to our Terms & Conditions and Privacy Policy'**
  String get widgetTermsAndConditions;

  /// No description provided for @widgetMissingParameters.
  ///
  /// In en, this message translates to:
  /// **'Missing required parameters'**
  String get widgetMissingParameters;

  /// No description provided for @widgetPropertyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Property or unit not found'**
  String get widgetPropertyNotFound;

  /// No description provided for @widgetContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Please contact support'**
  String get widgetContactSupport;

  /// No description provided for @ownerOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get ownerOverview;

  /// No description provided for @ownerErrorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get ownerErrorLoadingData;

  /// No description provided for @ownerMonthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue this month'**
  String get ownerMonthlyRevenue;

  /// No description provided for @ownerYearlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue this year'**
  String get ownerYearlyRevenue;

  /// No description provided for @ownerMonthlyBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings this month'**
  String get ownerMonthlyBookings;

  /// No description provided for @ownerUpcomingCheckIns.
  ///
  /// In en, this message translates to:
  /// **'Upcoming check-ins'**
  String get ownerUpcomingCheckIns;

  /// No description provided for @ownerActiveProperties.
  ///
  /// In en, this message translates to:
  /// **'Active properties'**
  String get ownerActiveProperties;

  /// No description provided for @ownerOccupancyRate.
  ///
  /// In en, this message translates to:
  /// **'Occupancy rate'**
  String get ownerOccupancyRate;

  /// No description provided for @ownerWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BookBed!'**
  String get ownerWelcomeTitle;

  /// No description provided for @ownerWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get started by adding your first property to start receiving bookings.'**
  String get ownerWelcomeSubtitle;

  /// No description provided for @ownerAddFirstProperty.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get ownerAddFirstProperty;

  /// No description provided for @ownerNewBookingReceived.
  ///
  /// In en, this message translates to:
  /// **'New booking received'**
  String get ownerNewBookingReceived;

  /// No description provided for @ownerBookingConfirmedActivity.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get ownerBookingConfirmedActivity;

  /// No description provided for @ownerBookingCancelledActivity.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get ownerBookingCancelledActivity;

  /// No description provided for @ownerBookingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Booking completed'**
  String get ownerBookingCompleted;

  /// No description provided for @ownerRecentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get ownerRecentActivities;

  /// No description provided for @ownerViewAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ownerViewAll;

  /// No description provided for @ownerNoRecentActivities.
  ///
  /// In en, this message translates to:
  /// **'No recent activities'**
  String get ownerNoRecentActivities;

  /// No description provided for @ownerRecentActivitiesDescription.
  ///
  /// In en, this message translates to:
  /// **'Your recent bookings and activities will appear here'**
  String get ownerRecentActivitiesDescription;

  /// No description provided for @ownerJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get ownerJustNow;

  /// No description provided for @ownerMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String ownerMinutesAgo(int count);

  /// No description provided for @ownerHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String ownerHoursAgo(int count);

  /// No description provided for @ownerDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String ownerDaysAgo(int count);

  /// No description provided for @ownerDrawerOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get ownerDrawerOverview;

  /// No description provided for @ownerDrawerCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get ownerDrawerCalendar;

  /// No description provided for @ownerDrawerBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get ownerDrawerBookings;

  /// No description provided for @ownerDrawerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get ownerDrawerAnalytics;

  /// No description provided for @ownerDrawerUnits.
  ///
  /// In en, this message translates to:
  /// **'Accommodation Units'**
  String get ownerDrawerUnits;

  /// No description provided for @ownerDrawerIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get ownerDrawerIntegrations;

  /// No description provided for @ownerDrawerIcal.
  ///
  /// In en, this message translates to:
  /// **'iCal'**
  String get ownerDrawerIcal;

  /// No description provided for @ownerDrawerImportBookings.
  ///
  /// In en, this message translates to:
  /// **'Import Bookings'**
  String get ownerDrawerImportBookings;

  /// No description provided for @ownerDrawerSyncBookingCom.
  ///
  /// In en, this message translates to:
  /// **'Sync with booking.com'**
  String get ownerDrawerSyncBookingCom;

  /// No description provided for @ownerDrawerExportCalendar.
  ///
  /// In en, this message translates to:
  /// **'Export Calendar'**
  String get ownerDrawerExportCalendar;

  /// No description provided for @ownerDrawerIcalFeedUrl.
  ///
  /// In en, this message translates to:
  /// **'iCal feed URL'**
  String get ownerDrawerIcalFeedUrl;

  /// No description provided for @ownerDrawerPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get ownerDrawerPayments;

  /// No description provided for @ownerDrawerStripePayments.
  ///
  /// In en, this message translates to:
  /// **'Stripe Payments'**
  String get ownerDrawerStripePayments;

  /// No description provided for @ownerDrawerCardProcessing.
  ///
  /// In en, this message translates to:
  /// **'Card processing'**
  String get ownerDrawerCardProcessing;

  /// No description provided for @ownerDrawerBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get ownerDrawerBankAccount;

  /// No description provided for @ownerDrawerBankAccountData.
  ///
  /// In en, this message translates to:
  /// **'Payment data'**
  String get ownerDrawerBankAccountData;

  /// No description provided for @ownerDrawerGuides.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get ownerDrawerGuides;

  /// No description provided for @ownerDrawerEmbedWidget.
  ///
  /// In en, this message translates to:
  /// **'Embed Widget'**
  String get ownerDrawerEmbedWidget;

  /// No description provided for @ownerDrawerAddToSite.
  ///
  /// In en, this message translates to:
  /// **'Adding to website'**
  String get ownerDrawerAddToSite;

  /// No description provided for @ownerDrawerFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get ownerDrawerFaq;

  /// No description provided for @ownerDrawerFaqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Common questions & answers'**
  String get ownerDrawerFaqSubtitle;

  /// No description provided for @ownerDrawerNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get ownerDrawerNotifications;

  /// No description provided for @ownerDrawerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get ownerDrawerProfile;

  /// No description provided for @ownerDrawerLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get ownerDrawerLogout;

  /// No description provided for @ownerCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get ownerCalendar;

  /// No description provided for @ownerCalendarPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get ownerCalendarPreviousWeek;

  /// No description provided for @ownerCalendarNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get ownerCalendarNextWeek;

  /// No description provided for @ownerCalendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get ownerCalendarPreviousMonth;

  /// No description provided for @ownerCalendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get ownerCalendarNextMonth;

  /// No description provided for @ownerCalendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get ownerCalendarToday;

  /// No description provided for @ownerCalendarGoToToday.
  ///
  /// In en, this message translates to:
  /// **'Go to today'**
  String get ownerCalendarGoToToday;

  /// No description provided for @ownerCalendarOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get ownerCalendarOptions;

  /// No description provided for @ownerCalendarNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get ownerCalendarNotifications;

  /// No description provided for @ownerCalendarSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get ownerCalendarSearch;

  /// No description provided for @ownerCalendarSearchBookings.
  ///
  /// In en, this message translates to:
  /// **'Search bookings'**
  String get ownerCalendarSearchBookings;

  /// No description provided for @ownerCalendarRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get ownerCalendarRefresh;

  /// No description provided for @ownerCalendarFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get ownerCalendarFilters;

  /// No description provided for @ownerCalendarHideStats.
  ///
  /// In en, this message translates to:
  /// **'Hide statistics'**
  String get ownerCalendarHideStats;

  /// No description provided for @ownerCalendarShowStats.
  ///
  /// In en, this message translates to:
  /// **'Show statistics'**
  String get ownerCalendarShowStats;

  /// No description provided for @ownerCalendarHideEmptyUnits.
  ///
  /// In en, this message translates to:
  /// **'Hide empty units'**
  String get ownerCalendarHideEmptyUnits;

  /// No description provided for @ownerCalendarShowEmptyUnits.
  ///
  /// In en, this message translates to:
  /// **'Show empty units'**
  String get ownerCalendarShowEmptyUnits;

  /// No description provided for @ownerCalendarNoUnits.
  ///
  /// In en, this message translates to:
  /// **'No units to display'**
  String get ownerCalendarNoUnits;

  /// No description provided for @ownerCalendarLoadingUnits.
  ///
  /// In en, this message translates to:
  /// **'Loading units...'**
  String get ownerCalendarLoadingUnits;

  /// No description provided for @ownerCalendarErrorLoadingUnits.
  ///
  /// In en, this message translates to:
  /// **'Error loading units'**
  String get ownerCalendarErrorLoadingUnits;

  /// No description provided for @ownerCalendarTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get ownerCalendarTryAgain;

  /// No description provided for @ownerCalendarLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get ownerCalendarLoading;

  /// No description provided for @ownerCalendarChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get ownerCalendarChangeStatus;

  /// No description provided for @ownerCalendarDefaultGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get ownerCalendarDefaultGuest;

  /// No description provided for @ownerCalendarSummaryGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get ownerCalendarSummaryGuests;

  /// No description provided for @ownerCalendarSummaryArrivals.
  ///
  /// In en, this message translates to:
  /// **'{arrivals} arrival • {departures} departure'**
  String ownerCalendarSummaryArrivals(int arrivals, int departures);

  /// No description provided for @ownerCalendarZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom: {percent}%'**
  String ownerCalendarZoom(int percent);

  /// No description provided for @ownerCalendarReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get ownerCalendarReset;

  /// No description provided for @ownerFilterActiveFilter.
  ///
  /// In en, this message translates to:
  /// **'active filter'**
  String get ownerFilterActiveFilter;

  /// No description provided for @ownerFilterActiveFilters.
  ///
  /// In en, this message translates to:
  /// **'active filters'**
  String get ownerFilterActiveFilters;

  /// No description provided for @ownerFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get ownerFilterClearAll;

  /// No description provided for @ownerFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get ownerFilterApply;

  /// No description provided for @ownerFilterCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ownerFilterCancel;

  /// No description provided for @ownerFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get ownerFilterClear;

  /// No description provided for @ownerFilterProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get ownerFilterProperties;

  /// No description provided for @ownerFilterUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get ownerFilterUnits;

  /// No description provided for @ownerFilterStatuses.
  ///
  /// In en, this message translates to:
  /// **'Statuses'**
  String get ownerFilterStatuses;

  /// No description provided for @ownerFilterSourceWidget.
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get ownerFilterSourceWidget;

  /// No description provided for @ownerFilterSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get ownerFilterSourceManual;

  /// No description provided for @ownerFilterSourceIcal.
  ///
  /// In en, this message translates to:
  /// **'iCal'**
  String get ownerFilterSourceIcal;

  /// No description provided for @ownerMultiSelectSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get ownerMultiSelectSelected;

  /// No description provided for @ownerMultiSelectSelectedPlural.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get ownerMultiSelectSelectedPlural;

  /// No description provided for @ownerMultiSelectClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get ownerMultiSelectClear;

  /// No description provided for @ownerMultiSelectChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get ownerMultiSelectChangeStatus;

  /// No description provided for @ownerMultiSelectDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get ownerMultiSelectDeleteSelected;

  /// No description provided for @ownerMultiSelectConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get ownerMultiSelectConfirmation;

  /// No description provided for @ownerMultiSelectChangeStatusConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change status for {count} {countLabel} to \"{status}\"?'**
  String ownerMultiSelectChangeStatusConfirm(
    int count,
    String countLabel,
    String status,
  );

  /// No description provided for @ownerMultiSelectReservation.
  ///
  /// In en, this message translates to:
  /// **'reservation'**
  String get ownerMultiSelectReservation;

  /// No description provided for @ownerMultiSelectReservations.
  ///
  /// In en, this message translates to:
  /// **'reservations'**
  String get ownerMultiSelectReservations;

  /// No description provided for @ownerMultiSelectCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ownerMultiSelectCancel;

  /// No description provided for @ownerMultiSelectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ownerMultiSelectConfirm;

  /// No description provided for @ownerMultiSelectStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed for {count} {countLabel}'**
  String ownerMultiSelectStatusChanged(int count, String countLabel);

  /// No description provided for @ownerMultiSelectStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error changing status'**
  String get ownerMultiSelectStatusError;

  /// No description provided for @ownerMultiSelectDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete confirmation'**
  String get ownerMultiSelectDeleteConfirmTitle;

  /// No description provided for @ownerMultiSelectDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} {countLabel}?\n\nThis action cannot be undone.'**
  String ownerMultiSelectDeleteConfirmMessage(int count, String countLabel);

  /// No description provided for @ownerMultiSelectDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get ownerMultiSelectDelete;

  /// No description provided for @ownerMultiSelectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} {countLabel}'**
  String ownerMultiSelectDeleted(int count, String countLabel);

  /// No description provided for @ownerMultiSelectDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting reservations'**
  String get ownerMultiSelectDeleteError;

  /// No description provided for @ownerStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ownerStatusPending;

  /// No description provided for @ownerStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get ownerStatusConfirmed;

  /// No description provided for @ownerStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ownerStatusCompleted;

  /// No description provided for @ownerStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ownerStatusCancelled;

  /// No description provided for @ownerCalendarError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get ownerCalendarError;

  /// No description provided for @ownerCalendarClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get ownerCalendarClose;

  /// No description provided for @ownerCalendarHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get ownerCalendarHelp;

  /// No description provided for @ownerBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get ownerBookingsTitle;

  /// No description provided for @ownerBookingsErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading bookings'**
  String get ownerBookingsErrorLoading;

  /// No description provided for @ownerBookingsLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more bookings...'**
  String get ownerBookingsLoadingMore;

  /// No description provided for @ownerBookingsScrollToLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Scroll to load more'**
  String get ownerBookingsScrollToLoadMore;

  /// No description provided for @ownerBookingsFiltersAndView.
  ///
  /// In en, this message translates to:
  /// **'Filters and View'**
  String get ownerBookingsFiltersAndView;

  /// No description provided for @ownerBookingsCardView.
  ///
  /// In en, this message translates to:
  /// **'Card view'**
  String get ownerBookingsCardView;

  /// No description provided for @ownerBookingsTableView.
  ///
  /// In en, this message translates to:
  /// **'Table view'**
  String get ownerBookingsTableView;

  /// No description provided for @ownerBookingsAdvancedFiltering.
  ///
  /// In en, this message translates to:
  /// **'Advanced filtering'**
  String get ownerBookingsAdvancedFiltering;

  /// No description provided for @ownerBookingsFilterByStatusPropertyDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by status, property, date'**
  String get ownerBookingsFilterByStatusPropertyDate;

  /// No description provided for @ownerBookingsClearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get ownerBookingsClearAllFilters;

  /// No description provided for @ownerBookingsNoBookings.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get ownerBookingsNoBookings;

  /// No description provided for @ownerBookingsNoBookingsDescription.
  ///
  /// In en, this message translates to:
  /// **'All bookings for your properties will appear here. Create your first booking or wait for guest reservations.'**
  String get ownerBookingsNoBookingsDescription;

  /// No description provided for @ownerBookingsGuest.
  ///
  /// In en, this message translates to:
  /// **'guest'**
  String get ownerBookingsGuest;

  /// No description provided for @ownerBookingsGuests.
  ///
  /// In en, this message translates to:
  /// **'guests'**
  String get ownerBookingsGuests;

  /// No description provided for @ownerBookingsApproved.
  ///
  /// In en, this message translates to:
  /// **'Booking approved successfully'**
  String get ownerBookingsApproved;

  /// No description provided for @ownerBookingsApproveError.
  ///
  /// In en, this message translates to:
  /// **'Error approving booking'**
  String get ownerBookingsApproveError;

  /// No description provided for @ownerBookingsRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected'**
  String get ownerBookingsRejected;

  /// No description provided for @ownerBookingsRejectError.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting booking'**
  String get ownerBookingsRejectError;

  /// No description provided for @ownerBookingsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Booking marked as completed'**
  String get ownerBookingsCompleted;

  /// No description provided for @ownerBookingsCompleteError.
  ///
  /// In en, this message translates to:
  /// **'Error completing booking'**
  String get ownerBookingsCompleteError;

  /// No description provided for @ownerBookingsCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get ownerBookingsCancelled;

  /// No description provided for @ownerBookingsCancelError.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling booking'**
  String get ownerBookingsCancelError;

  /// No description provided for @ownerBookingsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Booking not found'**
  String get ownerBookingsNotFound;

  /// No description provided for @ownerBookingCardNight.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get ownerBookingCardNight;

  /// No description provided for @ownerBookingCardNights.
  ///
  /// In en, this message translates to:
  /// **'nights'**
  String get ownerBookingCardNights;

  /// No description provided for @ownerBookingCardTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ownerBookingCardTotal;

  /// No description provided for @ownerBookingCardPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get ownerBookingCardPaid;

  /// No description provided for @ownerBookingCardRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get ownerBookingCardRemaining;

  /// No description provided for @ownerBookingCardFullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully paid'**
  String get ownerBookingCardFullyPaid;

  /// No description provided for @ownerBookingCardPercentPaid.
  ///
  /// In en, this message translates to:
  /// **'{percent}% paid'**
  String ownerBookingCardPercentPaid(String percent);

  /// No description provided for @ownerBookingCardNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ownerBookingCardNotes;

  /// No description provided for @ownerBookingCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get ownerBookingCardDetails;

  /// No description provided for @ownerBookingCardApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get ownerBookingCardApprove;

  /// No description provided for @ownerBookingCardReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get ownerBookingCardReject;

  /// No description provided for @ownerBookingCardComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get ownerBookingCardComplete;

  /// No description provided for @ownerBookingCardCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ownerBookingCardCancel;

  /// No description provided for @ownerTableSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String ownerTableSelected(int count);

  /// No description provided for @ownerTableClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get ownerTableClearSelection;

  /// No description provided for @ownerTableBulkActions.
  ///
  /// In en, this message translates to:
  /// **'Bulk actions'**
  String get ownerTableBulkActions;

  /// No description provided for @ownerTableConfirmSelected.
  ///
  /// In en, this message translates to:
  /// **'Confirm selected'**
  String get ownerTableConfirmSelected;

  /// No description provided for @ownerTableRejectSelected.
  ///
  /// In en, this message translates to:
  /// **'Reject selected'**
  String get ownerTableRejectSelected;

  /// No description provided for @ownerTableDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get ownerTableDeleteSelected;

  /// No description provided for @ownerTableColumnGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get ownerTableColumnGuest;

  /// No description provided for @ownerTableColumnPropertyUnit.
  ///
  /// In en, this message translates to:
  /// **'Property / Unit'**
  String get ownerTableColumnPropertyUnit;

  /// No description provided for @ownerTableColumnCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get ownerTableColumnCheckIn;

  /// No description provided for @ownerTableColumnCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get ownerTableColumnCheckOut;

  /// No description provided for @ownerTableColumnNights.
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get ownerTableColumnNights;

  /// No description provided for @ownerTableColumnGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get ownerTableColumnGuests;

  /// No description provided for @ownerTableColumnStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ownerTableColumnStatus;

  /// No description provided for @ownerTableColumnPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get ownerTableColumnPrice;

  /// No description provided for @ownerTableColumnSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get ownerTableColumnSource;

  /// No description provided for @ownerTableColumnActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get ownerTableColumnActions;

  /// No description provided for @ownerTableSourceDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get ownerTableSourceDirect;

  /// No description provided for @ownerTableSourceIcal.
  ///
  /// In en, this message translates to:
  /// **'iCal'**
  String get ownerTableSourceIcal;

  /// No description provided for @ownerTableSourceBookingCom.
  ///
  /// In en, this message translates to:
  /// **'Booking.com'**
  String get ownerTableSourceBookingCom;

  /// No description provided for @ownerTableSourceAirbnb.
  ///
  /// In en, this message translates to:
  /// **'Airbnb'**
  String get ownerTableSourceAirbnb;

  /// No description provided for @ownerTableSourceWidget.
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get ownerTableSourceWidget;

  /// No description provided for @ownerTableSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get ownerTableSourceManual;

  /// No description provided for @ownerTableActionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get ownerTableActionDetails;

  /// No description provided for @ownerTableActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ownerTableActionConfirm;

  /// No description provided for @ownerTableActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get ownerTableActionComplete;

  /// No description provided for @ownerTableActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get ownerTableActionEdit;

  /// No description provided for @ownerTableActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ownerTableActionCancel;

  /// No description provided for @ownerTableActionSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get ownerTableActionSendEmail;

  /// No description provided for @ownerTableActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get ownerTableActionDelete;

  /// No description provided for @ownerTableConfirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get ownerTableConfirmBooking;

  /// No description provided for @ownerTableConfirmBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm this booking?'**
  String get ownerTableConfirmBookingMessage;

  /// No description provided for @ownerTableCompleteBooking.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get ownerTableCompleteBooking;

  /// No description provided for @ownerTableCompleteBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this booking as completed?'**
  String get ownerTableCompleteBookingMessage;

  /// No description provided for @ownerTableCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get ownerTableCancelBooking;

  /// No description provided for @ownerTableCancelBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get ownerTableCancelBookingMessage;

  /// No description provided for @ownerTableCancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get ownerTableCancellationReason;

  /// No description provided for @ownerTableCancellationReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter reason...'**
  String get ownerTableCancellationReasonHint;

  /// No description provided for @ownerTableSendEmailToGuest.
  ///
  /// In en, this message translates to:
  /// **'Send email to guest'**
  String get ownerTableSendEmailToGuest;

  /// No description provided for @ownerTableCancelBookingButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get ownerTableCancelBookingButton;

  /// No description provided for @ownerTableDeleteBooking.
  ///
  /// In en, this message translates to:
  /// **'Delete booking'**
  String get ownerTableDeleteBooking;

  /// No description provided for @ownerTableDeleteBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to PERMANENTLY delete this booking? This action cannot be undone.'**
  String get ownerTableDeleteBookingMessage;

  /// No description provided for @ownerTableBookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed successfully'**
  String get ownerTableBookingConfirmed;

  /// No description provided for @ownerTableBookingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Booking marked as completed'**
  String get ownerTableBookingCompleted;

  /// No description provided for @ownerTableBookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get ownerTableBookingCancelled;

  /// No description provided for @ownerTableBookingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Booking deleted'**
  String get ownerTableBookingDeleted;

  /// No description provided for @ownerTableConfirmSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm selected bookings'**
  String get ownerTableConfirmSelectedTitle;

  /// No description provided for @ownerTableConfirmSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm {count} {label}?'**
  String ownerTableConfirmSelectedMessage(int count, String label);

  /// No description provided for @ownerTableConfirmAll.
  ///
  /// In en, this message translates to:
  /// **'Confirm all'**
  String get ownerTableConfirmAll;

  /// No description provided for @ownerTableBookingsConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{count} {label} confirmed'**
  String ownerTableBookingsConfirmed(int count, String label);

  /// No description provided for @ownerTableRejectSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject selected bookings'**
  String get ownerTableRejectSelectedTitle;

  /// No description provided for @ownerTableRejectSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject {count} {label}?'**
  String ownerTableRejectSelectedMessage(int count, String label);

  /// No description provided for @ownerTableRejectionReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason (optional)'**
  String get ownerTableRejectionReasonOptional;

  /// No description provided for @ownerTableRejectAll.
  ///
  /// In en, this message translates to:
  /// **'Reject all'**
  String get ownerTableRejectAll;

  /// No description provided for @ownerTableBookingsRejected.
  ///
  /// In en, this message translates to:
  /// **'{count} {label} rejected'**
  String ownerTableBookingsRejected(int count, String label);

  /// No description provided for @ownerTableDeleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected bookings'**
  String get ownerTableDeleteSelectedTitle;

  /// No description provided for @ownerTableDeleteSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to PERMANENTLY delete {count} {label}? This action cannot be undone.'**
  String ownerTableDeleteSelectedMessage(int count, String label);

  /// No description provided for @ownerTableBookingsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} {label} deleted'**
  String ownerTableBookingsDeleted(int count, String label);

  /// No description provided for @ownerTableBooking.
  ///
  /// In en, this message translates to:
  /// **'booking'**
  String get ownerTableBooking;

  /// No description provided for @ownerTableBookings.
  ///
  /// In en, this message translates to:
  /// **'bookings'**
  String get ownerTableBookings;

  /// No description provided for @ownerTableCancelledByOwner.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by owner'**
  String get ownerTableCancelledByOwner;

  /// No description provided for @ownerDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get ownerDetailsTitle;

  /// No description provided for @ownerDetailsBookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get ownerDetailsBookingId;

  /// No description provided for @ownerDetailsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ownerDetailsStatus;

  /// No description provided for @ownerDetailsGuestInfo.
  ///
  /// In en, this message translates to:
  /// **'Guest information'**
  String get ownerDetailsGuestInfo;

  /// No description provided for @ownerDetailsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ownerDetailsName;

  /// No description provided for @ownerDetailsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get ownerDetailsEmail;

  /// No description provided for @ownerDetailsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get ownerDetailsPhone;

  /// No description provided for @ownerDetailsPropertyInfo.
  ///
  /// In en, this message translates to:
  /// **'Property information'**
  String get ownerDetailsPropertyInfo;

  /// No description provided for @ownerDetailsProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get ownerDetailsProperty;

  /// No description provided for @ownerDetailsUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get ownerDetailsUnit;

  /// No description provided for @ownerDetailsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get ownerDetailsLocation;

  /// No description provided for @ownerDetailsStayInfo.
  ///
  /// In en, this message translates to:
  /// **'Stay details'**
  String get ownerDetailsStayInfo;

  /// No description provided for @ownerDetailsCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get ownerDetailsCheckIn;

  /// No description provided for @ownerDetailsCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get ownerDetailsCheckOut;

  /// No description provided for @ownerDetailsNights.
  ///
  /// In en, this message translates to:
  /// **'Number of nights'**
  String get ownerDetailsNights;

  /// No description provided for @ownerDetailsGuests.
  ///
  /// In en, this message translates to:
  /// **'Number of guests'**
  String get ownerDetailsGuests;

  /// No description provided for @ownerDetailsPaymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Payment information'**
  String get ownerDetailsPaymentInfo;

  /// No description provided for @ownerDetailsTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get ownerDetailsTotalPrice;

  /// No description provided for @ownerDetailsPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get ownerDetailsPaid;

  /// No description provided for @ownerDetailsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get ownerDetailsRemaining;

  /// No description provided for @ownerDetailsNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get ownerDetailsNotes;

  /// No description provided for @ownerDetailsCancellationInfo.
  ///
  /// In en, this message translates to:
  /// **'Cancellation information'**
  String get ownerDetailsCancellationInfo;

  /// No description provided for @ownerDetailsCancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled on'**
  String get ownerDetailsCancelledOn;

  /// No description provided for @ownerDetailsReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get ownerDetailsReason;

  /// No description provided for @ownerDetailsCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get ownerDetailsCreated;

  /// No description provided for @ownerDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get ownerDetailsUpdated;

  /// No description provided for @ownerDetailsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get ownerDetailsEdit;

  /// No description provided for @ownerDetailsResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get ownerDetailsResend;

  /// No description provided for @ownerDetailsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get ownerDetailsCancel;

  /// No description provided for @ownerDetailsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get ownerDetailsClose;

  /// No description provided for @ownerDetailsCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation confirmation'**
  String get ownerDetailsCancelConfirmTitle;

  /// No description provided for @ownerDetailsCancelConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get ownerDetailsCancelConfirmMessage;

  /// No description provided for @ownerDetailsCancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason (optional)'**
  String get ownerDetailsCancellationReason;

  /// No description provided for @ownerDetailsCancellationHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Date error, Guest request...'**
  String get ownerDetailsCancellationHint;

  /// No description provided for @ownerDetailsCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get ownerDetailsCancelBooking;

  /// No description provided for @ownerDetailsCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling booking...'**
  String get ownerDetailsCancelling;

  /// No description provided for @ownerDetailsCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled successfully'**
  String get ownerDetailsCancelSuccess;

  /// No description provided for @ownerDetailsCancelError.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling booking'**
  String get ownerDetailsCancelError;

  /// No description provided for @ownerDetailsResendTitle.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get ownerDetailsResendTitle;

  /// No description provided for @ownerDetailsResendMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to resend the booking confirmation email to guest {guestName}?'**
  String ownerDetailsResendMessage(String guestName);

  /// No description provided for @ownerDetailsResendNote.
  ///
  /// In en, this message translates to:
  /// **'Email will contain \"View My Booking\" link for booking preview.'**
  String get ownerDetailsResendNote;

  /// No description provided for @ownerDetailsSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get ownerDetailsSend;

  /// No description provided for @ownerDetailsSending.
  ///
  /// In en, this message translates to:
  /// **'Sending email...'**
  String get ownerDetailsSending;

  /// No description provided for @ownerDetailsSendSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email sent successfully to {email}'**
  String ownerDetailsSendSuccess(String email);

  /// No description provided for @ownerDetailsSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending email'**
  String get ownerDetailsSendError;

  /// No description provided for @ownerFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking filters'**
  String get ownerFiltersTitle;

  /// No description provided for @ownerFiltersStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Booking status'**
  String get ownerFiltersStatusSection;

  /// No description provided for @ownerFiltersStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get ownerFiltersStatusLabel;

  /// No description provided for @ownerFiltersAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get ownerFiltersAllStatuses;

  /// No description provided for @ownerFiltersPropertySection.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get ownerFiltersPropertySection;

  /// No description provided for @ownerFiltersPropertyLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by property'**
  String get ownerFiltersPropertyLabel;

  /// No description provided for @ownerFiltersAllProperties.
  ///
  /// In en, this message translates to:
  /// **'All properties'**
  String get ownerFiltersAllProperties;

  /// No description provided for @ownerFiltersLoadingProperties.
  ///
  /// In en, this message translates to:
  /// **'Loading properties...'**
  String get ownerFiltersLoadingProperties;

  /// No description provided for @ownerFiltersDateSection.
  ///
  /// In en, this message translates to:
  /// **'Time period'**
  String get ownerFiltersDateSection;

  /// No description provided for @ownerFiltersSelectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select time period'**
  String get ownerFiltersSelectDateRange;

  /// No description provided for @ownerFiltersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get ownerFiltersApply;

  /// No description provided for @ownerFiltersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get ownerFiltersClear;

  /// No description provided for @ownerAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Reports'**
  String get ownerAnalyticsTitle;

  /// No description provided for @ownerAnalyticsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load analytics'**
  String get ownerAnalyticsLoadError;

  /// No description provided for @ownerAnalyticsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get ownerAnalyticsLastWeek;

  /// No description provided for @ownerAnalyticsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get ownerAnalyticsLastMonth;

  /// No description provided for @ownerAnalyticsLastQuarter.
  ///
  /// In en, this message translates to:
  /// **'Last Quarter'**
  String get ownerAnalyticsLastQuarter;

  /// No description provided for @ownerAnalyticsLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get ownerAnalyticsLastYear;

  /// No description provided for @ownerAnalyticsCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get ownerAnalyticsCustomRange;

  /// No description provided for @ownerAnalyticsRevenueOverTime.
  ///
  /// In en, this message translates to:
  /// **'Revenue Over Time'**
  String get ownerAnalyticsRevenueOverTime;

  /// No description provided for @ownerAnalyticsBookingsOverTime.
  ///
  /// In en, this message translates to:
  /// **'Bookings Over Time'**
  String get ownerAnalyticsBookingsOverTime;

  /// No description provided for @ownerAnalyticsTopProperties.
  ///
  /// In en, this message translates to:
  /// **'Top Performing Properties'**
  String get ownerAnalyticsTopProperties;

  /// No description provided for @ownerAnalyticsWidgetPerformance.
  ///
  /// In en, this message translates to:
  /// **'Widget Performance'**
  String get ownerAnalyticsWidgetPerformance;

  /// No description provided for @ownerAnalyticsTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get ownerAnalyticsTotalRevenue;

  /// No description provided for @ownerAnalyticsTotalBookings.
  ///
  /// In en, this message translates to:
  /// **'Total Bookings'**
  String get ownerAnalyticsTotalBookings;

  /// No description provided for @ownerAnalyticsOccupancyRate.
  ///
  /// In en, this message translates to:
  /// **'Occupancy Rate'**
  String get ownerAnalyticsOccupancyRate;

  /// No description provided for @ownerAnalyticsAvgNightlyRate.
  ///
  /// In en, this message translates to:
  /// **'Avg. Nightly Rate'**
  String get ownerAnalyticsAvgNightlyRate;

  /// No description provided for @ownerAnalyticsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get ownerAnalyticsLast7Days;

  /// No description provided for @ownerAnalyticsLastDays.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String ownerAnalyticsLastDays(int days);

  /// No description provided for @ownerAnalyticsLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get ownerAnalyticsLast30Days;

  /// No description provided for @ownerAnalyticsPropertiesActive.
  ///
  /// In en, this message translates to:
  /// **'{active}/{total} properties active'**
  String ownerAnalyticsPropertiesActive(int active, int total);

  /// No description provided for @ownerAnalyticsCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation: {rate}%'**
  String ownerAnalyticsCancellation(String rate);

  /// No description provided for @ownerAnalyticsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data for selected period'**
  String get ownerAnalyticsNoData;

  /// No description provided for @ownerAnalyticsRevenueTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue Over Time'**
  String get ownerAnalyticsRevenueTitle;

  /// No description provided for @ownerAnalyticsRevenueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly revenue trend'**
  String get ownerAnalyticsRevenueSubtitle;

  /// No description provided for @ownerAnalyticsBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings Over Time'**
  String get ownerAnalyticsBookingsTitle;

  /// No description provided for @ownerAnalyticsBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly booking activity'**
  String get ownerAnalyticsBookingsSubtitle;

  /// No description provided for @ownerAnalyticsPropertiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Properties ranked by revenue performance'**
  String get ownerAnalyticsPropertiesSubtitle;

  /// No description provided for @ownerAnalyticsBookings.
  ///
  /// In en, this message translates to:
  /// **'bookings'**
  String get ownerAnalyticsBookings;

  /// No description provided for @ownerAnalyticsOccupancy.
  ///
  /// In en, this message translates to:
  /// **'occupancy'**
  String get ownerAnalyticsOccupancy;

  /// No description provided for @ownerAnalyticsWidgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track bookings and revenue from embedded widget'**
  String get ownerAnalyticsWidgetSubtitle;

  /// No description provided for @ownerAnalyticsWidgetBookings.
  ///
  /// In en, this message translates to:
  /// **'Widget Bookings'**
  String get ownerAnalyticsWidgetBookings;

  /// No description provided for @ownerAnalyticsWidgetRevenue.
  ///
  /// In en, this message translates to:
  /// **'Widget Revenue'**
  String get ownerAnalyticsWidgetRevenue;

  /// No description provided for @ownerAnalyticsOfTotal.
  ///
  /// In en, this message translates to:
  /// **'({percent}% of total)'**
  String ownerAnalyticsOfTotal(String percent);

  /// No description provided for @ownerAnalyticsBookingsBySource.
  ///
  /// In en, this message translates to:
  /// **'Bookings by Source'**
  String get ownerAnalyticsBookingsBySource;

  /// No description provided for @ownerAnalyticsSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Distribution of bookings across different sources'**
  String get ownerAnalyticsSourceSubtitle;

  /// No description provided for @ownerAnalyticsNoSourceData.
  ///
  /// In en, this message translates to:
  /// **'No source data available'**
  String get ownerAnalyticsNoSourceData;

  /// No description provided for @ownerAnalyticsOther.
  ///
  /// In en, this message translates to:
  /// **'Other ({count} sources)'**
  String ownerAnalyticsOther(int count);

  /// No description provided for @ownerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get ownerProfileTitle;

  /// No description provided for @ownerProfileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get ownerProfileThemeLight;

  /// No description provided for @ownerProfileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get ownerProfileThemeDark;

  /// No description provided for @ownerProfileLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get ownerProfileLanguageEnglish;

  /// No description provided for @ownerProfileLanguageCroatian.
  ///
  /// In en, this message translates to:
  /// **'Croatian'**
  String get ownerProfileLanguageCroatian;

  /// No description provided for @ownerProfileThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get ownerProfileThemeSystem;

  /// No description provided for @ownerProfileNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get ownerProfileNotAuthenticated;

  /// No description provided for @ownerProfileGuestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get ownerProfileGuestUser;

  /// No description provided for @ownerProfileOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerProfileOwner;

  /// No description provided for @ownerProfileAnonymousAccount.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Account'**
  String get ownerProfileAnonymousAccount;

  /// No description provided for @ownerProfileNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get ownerProfileNoEmail;

  /// No description provided for @ownerProfileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get ownerProfileEditProfile;

  /// No description provided for @ownerProfileEditProfileSubtitleAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Sign up to edit your profile'**
  String get ownerProfileEditProfileSubtitleAnonymous;

  /// No description provided for @ownerProfileEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get ownerProfileEditProfileSubtitle;

  /// No description provided for @ownerProfileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get ownerProfileChangePassword;

  /// No description provided for @ownerProfileChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get ownerProfileChangePasswordSubtitle;

  /// No description provided for @ownerProfileNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get ownerProfileNotificationSettings;

  /// No description provided for @ownerProfileNotificationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your notifications'**
  String get ownerProfileNotificationSettingsSubtitle;

  /// No description provided for @ownerProfileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get ownerProfileLanguage;

  /// No description provided for @ownerProfileTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get ownerProfileTheme;

  /// No description provided for @ownerProfileHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get ownerProfileHelpSupport;

  /// No description provided for @ownerProfileHelpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help with the app'**
  String get ownerProfileHelpSupportSubtitle;

  /// No description provided for @ownerProfileHelpSupportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Help & Support coming soon'**
  String get ownerProfileHelpSupportComingSoon;

  /// No description provided for @ownerProfileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get ownerProfileAbout;

  /// No description provided for @ownerProfileAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get ownerProfileAboutSubtitle;

  /// No description provided for @ownerProfileTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get ownerProfileTermsConditions;

  /// No description provided for @ownerProfileTermsConditionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'End User License Agreement'**
  String get ownerProfileTermsConditionsSubtitle;

  /// No description provided for @ownerProfilePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get ownerProfilePrivacyPolicy;

  /// No description provided for @ownerProfilePrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get ownerProfilePrivacyPolicySubtitle;

  /// No description provided for @ownerProfileCookiesPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cookies Policy'**
  String get ownerProfileCookiesPolicy;

  /// No description provided for @ownerProfileCookiesPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cookie usage and preferences'**
  String get ownerProfileCookiesPolicySubtitle;

  /// No description provided for @ownerProfileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get ownerProfileLoading;

  /// No description provided for @ownerProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get ownerProfileLoadError;

  /// No description provided for @ownerProfileBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get ownerProfileBack;

  /// No description provided for @ownerProfileTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get ownerProfileTryAgain;

  /// No description provided for @ownerProfileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get ownerProfileLogout;

  /// No description provided for @ownerProfileLogoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get ownerProfileLogoutSubtitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get editProfileSubtitle;

  /// No description provided for @editProfileDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editProfileDiscardTitle;

  /// No description provided for @editProfileDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get editProfileDiscardMessage;

  /// No description provided for @editProfileDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editProfileDiscard;

  /// No description provided for @editProfileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get editProfileSaving;

  /// No description provided for @editProfileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSaveChanges;

  /// No description provided for @editProfileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get editProfileSaveSuccess;

  /// No description provided for @editProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile'**
  String get editProfileSaveError;

  /// No description provided for @editProfileValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields correctly'**
  String get editProfileValidationError;

  /// No description provided for @editProfileOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get editProfileOptional;

  /// No description provided for @editProfilePersonalData.
  ///
  /// In en, this message translates to:
  /// **'Personal Data'**
  String get editProfilePersonalData;

  /// No description provided for @editProfilePersonalDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Basic contact information'**
  String get editProfilePersonalDataSubtitle;

  /// No description provided for @editProfileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get editProfileFullName;

  /// No description provided for @editProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editProfileEmail;

  /// No description provided for @editProfilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get editProfilePhone;

  /// No description provided for @editProfileAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get editProfileAddress;

  /// No description provided for @editProfileAddressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your physical address'**
  String get editProfileAddressSubtitle;

  /// No description provided for @editProfileCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get editProfileCountry;

  /// No description provided for @editProfileStreet.
  ///
  /// In en, this message translates to:
  /// **'Street and Number'**
  String get editProfileStreet;

  /// No description provided for @editProfileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get editProfileCity;

  /// No description provided for @editProfilePostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get editProfilePostalCode;

  /// No description provided for @editProfileCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get editProfileCompany;

  /// No description provided for @editProfileCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'For business users and invoices'**
  String get editProfileCompanySubtitle;

  /// No description provided for @editProfileCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get editProfileCompanyName;

  /// No description provided for @editProfileTaxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID / OIB'**
  String get editProfileTaxId;

  /// No description provided for @editProfileVatId.
  ///
  /// In en, this message translates to:
  /// **'VAT ID'**
  String get editProfileVatId;

  /// No description provided for @editProfileCompanyAddress.
  ///
  /// In en, this message translates to:
  /// **'Company Address'**
  String get editProfileCompanyAddress;

  /// No description provided for @editProfileOnlinePresence.
  ///
  /// In en, this message translates to:
  /// **'Online Presence'**
  String get editProfileOnlinePresence;

  /// No description provided for @editProfileWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get editProfileWebsite;

  /// No description provided for @editProfileFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook Page'**
  String get editProfileFacebook;

  /// No description provided for @editProfilePropertyType.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get editProfilePropertyType;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsEnableAll.
  ///
  /// In en, this message translates to:
  /// **'Enable All Notifications'**
  String get notificationSettingsEnableAll;

  /// No description provided for @notificationSettingsMasterSwitch.
  ///
  /// In en, this message translates to:
  /// **'Turn off to stop all email notifications to you. Guest emails are not affected.'**
  String get notificationSettingsMasterSwitch;

  /// No description provided for @notificationSettingsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled successfully'**
  String get notificationSettingsEnabled;

  /// No description provided for @notificationSettingsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled successfully'**
  String get notificationSettingsDisabled;

  /// No description provided for @notificationSettingsUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating settings'**
  String get notificationSettingsUpdateError;

  /// No description provided for @notificationSettingsDisabledWarning.
  ///
  /// In en, this message translates to:
  /// **'All email notifications to you are paused. Guest confirmation emails will still be sent. Enable to receive booking alerts.'**
  String get notificationSettingsDisabledWarning;

  /// No description provided for @notificationSettingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get notificationSettingsCategories;

  /// No description provided for @notificationSettingsBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get notificationSettingsBookings;

  /// No description provided for @notificationSettingsBookingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Emails when guests make instant bookings. Pending bookings requiring your approval are always sent.'**
  String get notificationSettingsBookingsDesc;

  /// No description provided for @notificationSettingsPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get notificationSettingsPayments;

  /// No description provided for @notificationSettingsPaymentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Emails when you receive Stripe payments from guests.'**
  String get notificationSettingsPaymentsDesc;

  /// No description provided for @notificationSettingsCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get notificationSettingsCalendar;

  /// No description provided for @notificationSettingsCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'iCal sync alerts and calendar conflict warnings.'**
  String get notificationSettingsCalendarDesc;

  /// No description provided for @notificationSettingsMarketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get notificationSettingsMarketing;

  /// No description provided for @notificationSettingsMarketingDesc.
  ///
  /// In en, this message translates to:
  /// **'Platform news, tips for property owners, and feature updates.'**
  String get notificationSettingsMarketingDesc;

  /// No description provided for @notificationSettingsEmailChannel.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get notificationSettingsEmailChannel;

  /// No description provided for @notificationSettingsEmailChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive email alerts for this category'**
  String get notificationSettingsEmailChannelDesc;

  /// No description provided for @notificationSettingsPushChannel.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get notificationSettingsPushChannel;

  /// No description provided for @notificationSettingsPushChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications on your device'**
  String get notificationSettingsPushChannelDesc;

  /// No description provided for @notificationSettingsSmsChannel.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get notificationSettingsSmsChannel;

  /// No description provided for @notificationSettingsSmsChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications via SMS'**
  String get notificationSettingsSmsChannelDesc;

  /// No description provided for @notificationSettingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading preferences'**
  String get notificationSettingsLoadError;

  /// No description provided for @notificationSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'{category} notification preferences updated'**
  String notificationSettingsUpdated(String category);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutAppName.
  ///
  /// In en, this message translates to:
  /// **'BookBed'**
  String get aboutAppName;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Property Management System'**
  String get aboutTagline;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get aboutVersion;

  /// No description provided for @aboutWhatIs.
  ///
  /// In en, this message translates to:
  /// **'What is BookBed?'**
  String get aboutWhatIs;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'BookBed is a comprehensive property management system designed for vacation rental owners. Manage your properties, bookings, calendar, and integrations all in one place. Our embedded booking widget makes it easy for guests to book directly on your website.'**
  String get aboutDescription;

  /// No description provided for @aboutKeyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get aboutKeyFeatures;

  /// No description provided for @aboutFeatureCalendar.
  ///
  /// In en, this message translates to:
  /// **'Smart Calendar'**
  String get aboutFeatureCalendar;

  /// No description provided for @aboutFeatureCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage availability across multiple properties'**
  String get aboutFeatureCalendarDesc;

  /// No description provided for @aboutFeatureBookings.
  ///
  /// In en, this message translates to:
  /// **'Online Bookings'**
  String get aboutFeatureBookings;

  /// No description provided for @aboutFeatureBookingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Embedded booking widget for your website'**
  String get aboutFeatureBookingsDesc;

  /// No description provided for @aboutFeatureIcal.
  ///
  /// In en, this message translates to:
  /// **'iCal Integration'**
  String get aboutFeatureIcal;

  /// No description provided for @aboutFeatureIcalDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync with Booking.com, Airbnb, and more'**
  String get aboutFeatureIcalDesc;

  /// No description provided for @aboutFeaturePayments.
  ///
  /// In en, this message translates to:
  /// **'Payment Processing'**
  String get aboutFeaturePayments;

  /// No description provided for @aboutFeaturePaymentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Stripe integration for secure payments'**
  String get aboutFeaturePaymentsDesc;

  /// No description provided for @aboutFeatureAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get aboutFeatureAnalytics;

  /// No description provided for @aboutFeatureAnalyticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track bookings, revenue, and occupancy'**
  String get aboutFeatureAnalyticsDesc;

  /// No description provided for @aboutBuiltWith.
  ///
  /// In en, this message translates to:
  /// **'Built With'**
  String get aboutBuiltWith;

  /// No description provided for @aboutContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact & Support'**
  String get aboutContactSupport;

  /// No description provided for @aboutEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get aboutEmailLabel;

  /// No description provided for @aboutWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutWebsiteLabel;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 BookBed. All rights reserved.'**
  String get aboutCopyright;

  /// No description provided for @unitHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Accommodation Units'**
  String get unitHubTitle;

  /// No description provided for @unitHubShowAllUnits.
  ///
  /// In en, this message translates to:
  /// **'Show all units'**
  String get unitHubShowAllUnits;

  /// No description provided for @unitHubPropertiesAndUnits.
  ///
  /// In en, this message translates to:
  /// **'Properties and Units'**
  String get unitHubPropertiesAndUnits;

  /// No description provided for @unitHubAddProperty.
  ///
  /// In en, this message translates to:
  /// **'Add new property'**
  String get unitHubAddProperty;

  /// No description provided for @unitHubSearch.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get unitHubSearch;

  /// No description provided for @unitHubLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get unitHubLoadingError;

  /// No description provided for @unitHubNoProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties'**
  String get unitHubNoProperties;

  /// No description provided for @unitHubNoPropertiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first property to add accommodation units'**
  String get unitHubNoPropertiesDesc;

  /// No description provided for @unitHubCreateProperty.
  ///
  /// In en, this message translates to:
  /// **'Create Property'**
  String get unitHubCreateProperty;

  /// No description provided for @unitHubNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get unitHubNoResults;

  /// No description provided for @unitHubUnitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit} other{{count} units}}'**
  String unitHubUnitsCount(int count);

  /// No description provided for @unitHubEditProperty.
  ///
  /// In en, this message translates to:
  /// **'Edit property'**
  String get unitHubEditProperty;

  /// No description provided for @unitHubDeleteProperty.
  ///
  /// In en, this message translates to:
  /// **'Delete property'**
  String get unitHubDeleteProperty;

  /// No description provided for @unitHubDeleteAllUnitsFirst.
  ///
  /// In en, this message translates to:
  /// **'Delete all units before deleting property'**
  String get unitHubDeleteAllUnitsFirst;

  /// No description provided for @unitHubAddUnit.
  ///
  /// In en, this message translates to:
  /// **'Add unit'**
  String get unitHubAddUnit;

  /// No description provided for @unitHubNoUnitsInProperty.
  ///
  /// In en, this message translates to:
  /// **'No units in this property'**
  String get unitHubNoUnitsInProperty;

  /// No description provided for @unitHubAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get unitHubAdd;

  /// No description provided for @unitHubCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete'**
  String get unitHubCannotDelete;

  /// No description provided for @unitHubCannotDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Property \"{name}\" has {count} units.\n\nYou must delete all units before deleting the property.'**
  String unitHubCannotDeleteDesc(String name, int count);

  /// No description provided for @unitHubUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get unitHubUnderstand;

  /// No description provided for @unitHubDeletePropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete property'**
  String get unitHubDeletePropertyTitle;

  /// No description provided for @unitHubDeletePropertyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?\n\nThis action cannot be undone.'**
  String unitHubDeletePropertyConfirm(String name);

  /// No description provided for @unitHubPropertyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Property \"{name}\" has been successfully deleted'**
  String unitHubPropertyDeleted(String name);

  /// No description provided for @unitHubDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting: {error}'**
  String unitHubDeleteError(String error);

  /// No description provided for @unitHubDeleteUnitTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete unit'**
  String get unitHubDeleteUnitTitle;

  /// No description provided for @unitHubDeleteUnitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?\n\nThis action cannot be undone.'**
  String unitHubDeleteUnitConfirm(String name);

  /// No description provided for @unitHubUnitDeleted.
  ///
  /// In en, this message translates to:
  /// **'Unit \"{name}\" has been successfully deleted'**
  String unitHubUnitDeleted(String name);

  /// No description provided for @unitHubTabBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get unitHubTabBasicInfo;

  /// No description provided for @unitHubTabPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get unitHubTabPricing;

  /// No description provided for @unitHubTabWidget.
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get unitHubTabWidget;

  /// No description provided for @unitHubTabAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get unitHubTabAdvanced;

  /// No description provided for @unitHubSelectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select a unit'**
  String get unitHubSelectUnit;

  /// No description provided for @unitHubSelectUnitDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a unit from the list to view and edit details'**
  String get unitHubSelectUnitDesc;

  /// No description provided for @unitHubAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get unitHubAvailable;

  /// No description provided for @unitHubUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unitHubUnavailable;

  /// No description provided for @unitHubEditUnit.
  ///
  /// In en, this message translates to:
  /// **'Edit unit'**
  String get unitHubEditUnit;

  /// No description provided for @unitHubDeleteUnit.
  ///
  /// In en, this message translates to:
  /// **'Delete unit'**
  String get unitHubDeleteUnit;

  /// No description provided for @unitHubError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String unitHubError(String error);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected?'**
  String get notificationsDeleteSelected;

  /// No description provided for @notificationsDeleteSelectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} notifications?'**
  String notificationsDeleteSelectedDesc(int count);

  /// No description provided for @notificationsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notifications deleted'**
  String get notificationsDeleted;

  /// No description provided for @notificationsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all?'**
  String get notificationsDeleteAll;

  /// No description provided for @notificationsDeleteAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete ALL notifications? This action cannot be undone.'**
  String get notificationsDeleteAllDesc;

  /// No description provided for @notificationsAllDeleted.
  ///
  /// In en, this message translates to:
  /// **'All notifications deleted'**
  String get notificationsAllDeleted;

  /// No description provided for @notificationsSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get notificationsSelect;

  /// No description provided for @notificationsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get notificationsCancel;

  /// No description provided for @notificationsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String notificationsSelected(int count);

  /// No description provided for @notificationsDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get notificationsDeselectAll;

  /// No description provided for @notificationsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get notificationsSelectAll;

  /// No description provided for @notificationsDeleteSelectedBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get notificationsDeleteSelectedBtn;

  /// No description provided for @notificationsDeleteAllBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get notificationsDeleteAllBtn;

  /// No description provided for @notificationsDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get notificationsDeleting;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'You will see all your notifications here'**
  String get notificationsEmptyDesc;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get notificationsLoadError;

  /// No description provided for @notificationsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get notificationsTryAgain;

  /// No description provided for @notificationsDeleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get notificationsDeleteNotification;

  /// No description provided for @notificationsDeleteNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this notification?'**
  String get notificationsDeleteNotificationDesc;

  /// No description provided for @notificationBookingCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get notificationBookingCreatedTitle;

  /// No description provided for @notificationBookingUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Updated'**
  String get notificationBookingUpdatedTitle;

  /// No description provided for @notificationBookingCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Cancelled'**
  String get notificationBookingCancelledTitle;

  /// No description provided for @notificationPaymentReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get notificationPaymentReceivedTitle;

  /// No description provided for @notificationBookingCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{guestName} created a new booking.'**
  String notificationBookingCreatedMessage(String guestName);

  /// No description provided for @notificationBookingUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking for {guestName} was updated.'**
  String notificationBookingUpdatedMessage(String guestName);

  /// No description provided for @notificationBookingCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking for {guestName} was cancelled.'**
  String notificationBookingCancelledMessage(String guestName);

  /// No description provided for @notificationPaymentReceivedMessage.
  ///
  /// In en, this message translates to:
  /// **'Received payment from {guestName} for €{amount}.'**
  String notificationPaymentReceivedMessage(String guestName, double amount);

  /// No description provided for @notificationTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationTimeJustNow;

  /// No description provided for @notificationTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String notificationTimeMinutesAgo(int minutes);

  /// No description provided for @notificationTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String notificationTimeHoursAgo(int hours);

  /// No description provided for @notificationTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String notificationTimeDaysAgo(int days);

  /// No description provided for @notificationTimeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String notificationTimeWeeksAgo(int weeks);

  /// No description provided for @notificationTimeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months}mo ago'**
  String notificationTimeMonthsAgo(int months);

  /// No description provided for @bankAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccountTitle;

  /// No description provided for @bankAccountBankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get bankAccountBankDetails;

  /// No description provided for @bankAccountBankDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data for receiving payments'**
  String get bankAccountBankDetailsSubtitle;

  /// No description provided for @bankAccountIban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get bankAccountIban;

  /// No description provided for @bankAccountSwift.
  ///
  /// In en, this message translates to:
  /// **'SWIFT/BIC'**
  String get bankAccountSwift;

  /// No description provided for @bankAccountBankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankAccountBankName;

  /// No description provided for @bankAccountHolder.
  ///
  /// In en, this message translates to:
  /// **'Account Holder'**
  String get bankAccountHolder;

  /// No description provided for @bankAccountInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'When is this data used?'**
  String get bankAccountInfoTitle;

  /// No description provided for @bankAccountInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'This bank data is displayed to guests when they select \"Bank Transfer\" as the payment method in the booking widget.'**
  String get bankAccountInfoDesc;

  /// No description provided for @bankAccountSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get bankAccountSaveChanges;

  /// No description provided for @bankAccountSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get bankAccountSaving;

  /// No description provided for @bankAccountCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bankAccountCancel;

  /// No description provided for @bankAccountFillFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields correctly'**
  String get bankAccountFillFieldsError;

  /// No description provided for @bankAccountSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bank details saved successfully'**
  String get bankAccountSaveSuccess;

  /// No description provided for @bankAccountSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving bank details'**
  String get bankAccountSaveError;

  /// No description provided for @bankAccountDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get bankAccountDiscardTitle;

  /// No description provided for @bankAccountDiscardDesc.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to discard them?'**
  String get bankAccountDiscardDesc;

  /// No description provided for @bankAccountDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get bankAccountDiscard;

  /// No description provided for @stripeTitle.
  ///
  /// In en, this message translates to:
  /// **'Stripe Payments'**
  String get stripeTitle;

  /// No description provided for @stripeConnectAccount.
  ///
  /// In en, this message translates to:
  /// **'Connect Stripe Account'**
  String get stripeConnectAccount;

  /// No description provided for @stripeFinishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish Stripe Setup'**
  String get stripeFinishSetup;

  /// No description provided for @stripeHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How does Stripe Connect work?'**
  String get stripeHowItWorks;

  /// No description provided for @stripeNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get stripeNotConnected;

  /// No description provided for @stripeNotConnectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Stripe account is not connected. Receiving payments is not possible.'**
  String get stripeNotConnectedDesc;

  /// No description provided for @stripeSetupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Setup in progress'**
  String get stripeSetupInProgress;

  /// No description provided for @stripeSetupInProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete Stripe setup to start receiving payments.'**
  String get stripeSetupInProgressDesc;

  /// No description provided for @stripeActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get stripeActive;

  /// No description provided for @stripeActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Stripe account is connected. You can receive payments!'**
  String get stripeActiveDesc;

  /// No description provided for @stripeWhyConnect.
  ///
  /// In en, this message translates to:
  /// **'Why Stripe Connect?'**
  String get stripeWhyConnect;

  /// No description provided for @stripeReceivePayments.
  ///
  /// In en, this message translates to:
  /// **'Receive payments'**
  String get stripeReceivePayments;

  /// No description provided for @stripeReceivePaymentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive card payments directly to your account'**
  String get stripeReceivePaymentsDesc;

  /// No description provided for @stripeSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get stripeSecurity;

  /// No description provided for @stripeSecurityDesc.
  ///
  /// In en, this message translates to:
  /// **'PCI-DSS compliant system for secure transactions'**
  String get stripeSecurityDesc;

  /// No description provided for @stripeInstantConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Instant confirmations'**
  String get stripeInstantConfirmations;

  /// No description provided for @stripeInstantConfirmationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatic booking confirmation after successful payment'**
  String get stripeInstantConfirmationsDesc;

  /// No description provided for @stripeNoHiddenFees.
  ///
  /// In en, this message translates to:
  /// **'No hidden fees'**
  String get stripeNoHiddenFees;

  /// No description provided for @stripeNoHiddenFeesDesc.
  ///
  /// In en, this message translates to:
  /// **'Stripe charges ~2.9% + €0.30 per transaction'**
  String get stripeNoHiddenFeesDesc;

  /// No description provided for @stripeCannotOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Cannot open Stripe page'**
  String get stripeCannotOpenPage;

  /// No description provided for @stripeCannotOpenPageDesc.
  ///
  /// In en, this message translates to:
  /// **'Cannot open Stripe page. Please try again.'**
  String get stripeCannotOpenPageDesc;

  /// No description provided for @stripeCreateAccountError.
  ///
  /// In en, this message translates to:
  /// **'Error creating Stripe account'**
  String get stripeCreateAccountError;

  /// No description provided for @stripeConnectError.
  ///
  /// In en, this message translates to:
  /// **'Error connecting Stripe account'**
  String get stripeConnectError;

  /// No description provided for @stripeDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Account'**
  String get stripeDisconnect;

  /// No description provided for @stripeDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Stripe Account'**
  String get stripeDisconnectTitle;

  /// No description provided for @stripeDisconnectMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect your Stripe account? You will no longer be able to receive payments until you reconnect.'**
  String get stripeDisconnectMessage;

  /// No description provided for @stripeDisconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get stripeDisconnectConfirm;

  /// No description provided for @stripeDisconnectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Stripe account disconnected successfully'**
  String get stripeDisconnectSuccess;

  /// No description provided for @stripeDisconnectError.
  ///
  /// In en, this message translates to:
  /// **'Error disconnecting Stripe account'**
  String get stripeDisconnectError;

  /// No description provided for @stripeLoadingAccount.
  ///
  /// In en, this message translates to:
  /// **'Loading payment settings...'**
  String get stripeLoadingAccount;

  /// No description provided for @advancedSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettingsTitle;

  /// No description provided for @advancedSettingsSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings saved successfully'**
  String get advancedSettingsSaveSuccess;

  /// No description provided for @advancedSettingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save advanced settings'**
  String get advancedSettingsSaveError;

  /// No description provided for @advancedSettingsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Widget settings not found'**
  String get advancedSettingsNotFound;

  /// No description provided for @advancedSettingsDisclaimerPreview.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer Preview'**
  String get advancedSettingsDisclaimerPreview;

  /// No description provided for @advancedSettingsNoDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'No disclaimer text'**
  String get advancedSettingsNoDisclaimer;

  /// No description provided for @advancedSettingsCustomTextRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter custom text or use default'**
  String get advancedSettingsCustomTextRequired;

  /// No description provided for @advancedSettingsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get advancedSettingsSaving;

  /// No description provided for @advancedSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Advanced Settings'**
  String get advancedSettingsSave;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BedBooking!'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accommodation management system'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingWhatYouWillLearn.
  ///
  /// In en, this message translates to:
  /// **'What you will learn through the guide:'**
  String get onboardingWhatYouWillLearn;

  /// No description provided for @onboardingCreateProperty.
  ///
  /// In en, this message translates to:
  /// **'Create property'**
  String get onboardingCreateProperty;

  /// No description provided for @onboardingCreatePropertyDesc.
  ///
  /// In en, this message translates to:
  /// **'Add basic information about your accommodation'**
  String get onboardingCreatePropertyDesc;

  /// No description provided for @onboardingSetupUnits.
  ///
  /// In en, this message translates to:
  /// **'Setup units'**
  String get onboardingSetupUnits;

  /// No description provided for @onboardingSetupUnitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create rooms or apartments'**
  String get onboardingSetupUnitsDesc;

  /// No description provided for @onboardingSetupPricing.
  ///
  /// In en, this message translates to:
  /// **'Setup pricing'**
  String get onboardingSetupPricing;

  /// No description provided for @onboardingSetupPricingDesc.
  ///
  /// In en, this message translates to:
  /// **'Set basic prices for accommodation'**
  String get onboardingSetupPricingDesc;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @onboardingSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkipForNow;

  /// No description provided for @onboardingAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get onboardingAlreadyHaveAccount;

  /// No description provided for @onboardingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get onboardingSignIn;

  /// No description provided for @onboardingSkipTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip guide?'**
  String get onboardingSkipTitle;

  /// No description provided for @onboardingSkipDesc.
  ///
  /// In en, this message translates to:
  /// **'If you skip the guide, you won\'t learn the basics of setting up the system. You can always add properties and units later through settings.\n\nDo you want to continue?'**
  String get onboardingSkipDesc;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingSuccessCongrats.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get onboardingSuccessCongrats;

  /// No description provided for @onboardingSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have successfully completed the initial setup'**
  String get onboardingSuccessSubtitle;

  /// No description provided for @onboardingSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Your property is created and ready to use.'**
  String get onboardingSuccessDesc;

  /// No description provided for @onboardingSuccessNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next steps:'**
  String get onboardingSuccessNextSteps;

  /// No description provided for @onboardingSuccessAddUnits.
  ///
  /// In en, this message translates to:
  /// **'Add units'**
  String get onboardingSuccessAddUnits;

  /// No description provided for @onboardingSuccessAddUnitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create rooms or apartments'**
  String get onboardingSuccessAddUnitsDesc;

  /// No description provided for @onboardingSuccessSetPrices.
  ///
  /// In en, this message translates to:
  /// **'Set prices'**
  String get onboardingSuccessSetPrices;

  /// No description provided for @onboardingSuccessSetPricesDesc.
  ///
  /// In en, this message translates to:
  /// **'Define prices by dates'**
  String get onboardingSuccessSetPricesDesc;

  /// No description provided for @onboardingSuccessViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View calendar'**
  String get onboardingSuccessViewCalendar;

  /// No description provided for @onboardingSuccessViewCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Track bookings and availability'**
  String get onboardingSuccessViewCalendarDesc;

  /// No description provided for @onboardingSuccessGoToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get onboardingSuccessGoToDashboard;

  /// No description provided for @unitHubInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get unitHubInfoSection;

  /// No description provided for @unitHubName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get unitHubName;

  /// No description provided for @unitHubSlug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get unitHubSlug;

  /// No description provided for @unitHubDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get unitHubDescription;

  /// No description provided for @unitHubStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get unitHubStatus;

  /// No description provided for @unitHubStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get unitHubStatusAvailable;

  /// No description provided for @unitHubStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unitHubStatusUnavailable;

  /// No description provided for @unitHubCapacitySection.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get unitHubCapacitySection;

  /// No description provided for @unitHubBedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get unitHubBedrooms;

  /// No description provided for @unitHubBathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get unitHubBathrooms;

  /// No description provided for @unitHubMaxGuests.
  ///
  /// In en, this message translates to:
  /// **'Max guests'**
  String get unitHubMaxGuests;

  /// No description provided for @unitHubArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get unitHubArea;

  /// No description provided for @unitHubPriceSection.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get unitHubPriceSection;

  /// No description provided for @unitHubPricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Price per night'**
  String get unitHubPricePerNight;

  /// No description provided for @unitHubMinNights.
  ///
  /// In en, this message translates to:
  /// **'Min nights'**
  String get unitHubMinNights;

  /// No description provided for @unitHubPhotosSection.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get unitHubPhotosSection;

  /// No description provided for @unitHubNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get unitHubNoPhotos;

  /// No description provided for @unitHubMorePhotos.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String unitHubMorePhotos(int count);

  /// No description provided for @unitHubBasicData.
  ///
  /// In en, this message translates to:
  /// **'Basic Data'**
  String get unitHubBasicData;

  /// No description provided for @unitHubEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get unitHubEdit;

  /// No description provided for @unitHubPerNight.
  ///
  /// In en, this message translates to:
  /// **'/night'**
  String get unitHubPerNight;

  /// No description provided for @propertyFormTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get propertyFormTitleAdd;

  /// No description provided for @propertyFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Property'**
  String get propertyFormTitleEdit;

  /// No description provided for @propertyFormBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get propertyFormBasicInfo;

  /// No description provided for @propertyFormPropertyName.
  ///
  /// In en, this message translates to:
  /// **'Property name *'**
  String get propertyFormPropertyName;

  /// No description provided for @propertyFormPropertyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Villa Mediteran'**
  String get propertyFormPropertyNameHint;

  /// No description provided for @propertyFormPropertyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get propertyFormPropertyNameRequired;

  /// No description provided for @propertyFormUrlSlug.
  ///
  /// In en, this message translates to:
  /// **'URL Slug'**
  String get propertyFormUrlSlug;

  /// No description provided for @propertyFormUrlSlugHint.
  ///
  /// In en, this message translates to:
  /// **'villa-mediteran'**
  String get propertyFormUrlSlugHint;

  /// No description provided for @propertyFormUrlSlugHelper.
  ///
  /// In en, this message translates to:
  /// **'SEO-friendly URL: /booking/[slug]'**
  String get propertyFormUrlSlugHelper;

  /// No description provided for @propertyFormSlugRequired.
  ///
  /// In en, this message translates to:
  /// **'Slug is required'**
  String get propertyFormSlugRequired;

  /// No description provided for @propertyFormSlugInvalid.
  ///
  /// In en, this message translates to:
  /// **'Slug can only contain lowercase letters, numbers and hyphens'**
  String get propertyFormSlugInvalid;

  /// No description provided for @propertyFormRegenerateSlug.
  ///
  /// In en, this message translates to:
  /// **'Regenerate from name'**
  String get propertyFormRegenerateSlug;

  /// No description provided for @propertyFormSubdomain.
  ///
  /// In en, this message translates to:
  /// **'Subdomain'**
  String get propertyFormSubdomain;

  /// No description provided for @propertyFormSubdomainHint.
  ///
  /// In en, this message translates to:
  /// **'your-property'**
  String get propertyFormSubdomainHint;

  /// No description provided for @propertyFormSubdomainHelper.
  ///
  /// In en, this message translates to:
  /// **'Custom URL: [subdomain].bookbed.io'**
  String get propertyFormSubdomainHelper;

  /// No description provided for @propertyFormSubdomainAvailable.
  ///
  /// In en, this message translates to:
  /// **'Subdomain is available'**
  String get propertyFormSubdomainAvailable;

  /// No description provided for @propertyFormSubdomainTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get propertyFormSubdomainTaken;

  /// No description provided for @propertyFormSubdomainUseSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Use suggestion'**
  String get propertyFormSubdomainUseSuggestion;

  /// No description provided for @propertyFormPropertyType.
  ///
  /// In en, this message translates to:
  /// **'Property type *'**
  String get propertyFormPropertyType;

  /// No description provided for @propertyFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get propertyFormDescription;

  /// No description provided for @propertyFormDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your property in detail...'**
  String get propertyFormDescriptionHint;

  /// No description provided for @propertyFormDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get propertyFormDescriptionRequired;

  /// No description provided for @propertyFormDescriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 100 characters (currently: {count})'**
  String propertyFormDescriptionTooShort(int count);

  /// No description provided for @propertyFormLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get propertyFormLocation;

  /// No description provided for @propertyFormLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location *'**
  String get propertyFormLocationLabel;

  /// No description provided for @propertyFormLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rab (city), Rab Island'**
  String get propertyFormLocationHint;

  /// No description provided for @propertyFormLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required'**
  String get propertyFormLocationRequired;

  /// No description provided for @propertyFormAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get propertyFormAddress;

  /// No description provided for @propertyFormAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street and number'**
  String get propertyFormAddressHint;

  /// No description provided for @propertyFormAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get propertyFormAmenities;

  /// No description provided for @propertyFormPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get propertyFormPhotos;

  /// No description provided for @propertyFormPhotosMin.
  ///
  /// In en, this message translates to:
  /// **'Photos (min 3)'**
  String get propertyFormPhotosMin;

  /// No description provided for @propertyFormSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get propertyFormSettings;

  /// No description provided for @propertyFormPublishNow.
  ///
  /// In en, this message translates to:
  /// **'Publish now'**
  String get propertyFormPublishNow;

  /// No description provided for @propertyFormPublishNowActive.
  ///
  /// In en, this message translates to:
  /// **'Property will be visible to users'**
  String get propertyFormPublishNowActive;

  /// No description provided for @propertyFormPublishNowInactive.
  ///
  /// In en, this message translates to:
  /// **'Property will be hidden'**
  String get propertyFormPublishNowInactive;

  /// No description provided for @propertyFormSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get propertyFormSaveChanges;

  /// No description provided for @propertyFormAddProperty.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get propertyFormAddProperty;

  /// No description provided for @propertyFormSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get propertyFormSaving;

  /// No description provided for @propertyFormGeneratingError.
  ///
  /// In en, this message translates to:
  /// **'Error generating: {error}'**
  String propertyFormGeneratingError(String error);

  /// No description provided for @propertyFormCheckingError.
  ///
  /// In en, this message translates to:
  /// **'Error checking: {error}'**
  String propertyFormCheckingError(String error);

  /// No description provided for @propertyFormAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get propertyFormAddPhotos;

  /// No description provided for @propertyFormAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get propertyFormAddMore;

  /// No description provided for @propertyFormPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String propertyFormPhotoCount(int count);

  /// No description provided for @propertyFormPhotoRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommendation: Add at least 3 photos for better visibility'**
  String get propertyFormPhotoRecommendation;

  /// No description provided for @propertyFormUploadProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos: {current}/{total}'**
  String propertyFormUploadProgress(int current, int total);

  /// No description provided for @propertyFormUploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error: {error}'**
  String propertyFormUploadError(String error);

  /// No description provided for @propertyFormUploadErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error uploading photos'**
  String get propertyFormUploadErrorGeneric;

  /// No description provided for @propertyFormSubdomainError.
  ///
  /// In en, this message translates to:
  /// **'Please select an available subdomain'**
  String get propertyFormSubdomainError;

  /// No description provided for @propertyFormSubdomainSetError.
  ///
  /// In en, this message translates to:
  /// **'Error setting subdomain'**
  String get propertyFormSubdomainSetError;

  /// No description provided for @propertyFormSuccessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Property successfully updated'**
  String get propertyFormSuccessUpdate;

  /// No description provided for @propertyFormSuccessAdd.
  ///
  /// In en, this message translates to:
  /// **'Property successfully added'**
  String get propertyFormSuccessAdd;

  /// No description provided for @propertyFormErrorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Error updating property'**
  String get propertyFormErrorUpdate;

  /// No description provided for @propertyFormErrorAdd.
  ///
  /// In en, this message translates to:
  /// **'Error adding property'**
  String get propertyFormErrorAdd;

  /// No description provided for @propertyFormUserNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get propertyFormUserNotLoggedIn;

  /// No description provided for @unitFormTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Unit'**
  String get unitFormTitleAdd;

  /// No description provided for @unitFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Unit'**
  String get unitFormTitleEdit;

  /// No description provided for @unitFormBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get unitFormBasicInfo;

  /// No description provided for @unitFormUnitName.
  ///
  /// In en, this message translates to:
  /// **'Unit name *'**
  String get unitFormUnitName;

  /// No description provided for @unitFormUnitNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ground floor apartment'**
  String get unitFormUnitNameHint;

  /// No description provided for @unitFormUnitNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get unitFormUnitNameRequired;

  /// No description provided for @unitFormUrlSlug.
  ///
  /// In en, this message translates to:
  /// **'URL Slug'**
  String get unitFormUrlSlug;

  /// No description provided for @unitFormUrlSlugHint.
  ///
  /// In en, this message translates to:
  /// **'ground-floor-apartment'**
  String get unitFormUrlSlugHint;

  /// No description provided for @unitFormUrlSlugHelper.
  ///
  /// In en, this message translates to:
  /// **'SEO-friendly URL: /booking/[slug]'**
  String get unitFormUrlSlugHelper;

  /// No description provided for @unitFormSlugRequired.
  ///
  /// In en, this message translates to:
  /// **'Slug is required'**
  String get unitFormSlugRequired;

  /// No description provided for @unitFormSlugInvalid.
  ///
  /// In en, this message translates to:
  /// **'Slug can only contain lowercase letters, numbers and hyphens'**
  String get unitFormSlugInvalid;

  /// No description provided for @unitFormRegenerateSlug.
  ///
  /// In en, this message translates to:
  /// **'Regenerate from name'**
  String get unitFormRegenerateSlug;

  /// No description provided for @unitFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get unitFormDescription;

  /// No description provided for @unitFormDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Additional information about the unit...'**
  String get unitFormDescriptionHint;

  /// No description provided for @unitFormCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get unitFormCapacity;

  /// No description provided for @unitFormBedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms *'**
  String get unitFormBedrooms;

  /// No description provided for @unitFormBathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms *'**
  String get unitFormBathrooms;

  /// No description provided for @unitFormMaxGuests.
  ///
  /// In en, this message translates to:
  /// **'Max guests *'**
  String get unitFormMaxGuests;

  /// No description provided for @unitFormArea.
  ///
  /// In en, this message translates to:
  /// **'Area (m²)'**
  String get unitFormArea;

  /// No description provided for @unitFormRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get unitFormRequired;

  /// No description provided for @unitFormInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get unitFormInvalidNumber;

  /// No description provided for @unitFormMin1.
  ///
  /// In en, this message translates to:
  /// **'Min 1'**
  String get unitFormMin1;

  /// No description provided for @unitFormRange1to16.
  ///
  /// In en, this message translates to:
  /// **'1-16'**
  String get unitFormRange1to16;

  /// No description provided for @unitFormPricing.
  ///
  /// In en, this message translates to:
  /// **'Price and conditions'**
  String get unitFormPricing;

  /// No description provided for @unitFormPricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Price per night (€) *'**
  String get unitFormPricePerNight;

  /// No description provided for @unitFormInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get unitFormInvalidAmount;

  /// No description provided for @unitFormMinNights.
  ///
  /// In en, this message translates to:
  /// **'Min nights *'**
  String get unitFormMinNights;

  /// No description provided for @unitFormAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get unitFormAmenities;

  /// No description provided for @unitFormPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get unitFormPhotos;

  /// No description provided for @unitFormAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get unitFormAddPhotos;

  /// No description provided for @unitFormAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add more'**
  String get unitFormAddMore;

  /// No description provided for @unitFormTotalPhotos.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} photos'**
  String unitFormTotalPhotos(int count);

  /// No description provided for @unitFormAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get unitFormAvailability;

  /// No description provided for @unitFormAvailableForBooking.
  ///
  /// In en, this message translates to:
  /// **'Available for booking'**
  String get unitFormAvailableForBooking;

  /// No description provided for @unitFormAvailableDesc.
  ///
  /// In en, this message translates to:
  /// **'Unit will be available for reservations'**
  String get unitFormAvailableDesc;

  /// No description provided for @unitFormUnavailableDesc.
  ///
  /// In en, this message translates to:
  /// **'Unit will not be shown'**
  String get unitFormUnavailableDesc;

  /// No description provided for @unitFormSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get unitFormSaveChanges;

  /// No description provided for @unitFormAddUnit.
  ///
  /// In en, this message translates to:
  /// **'Add Unit'**
  String get unitFormAddUnit;

  /// No description provided for @unitFormSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get unitFormSaving;

  /// No description provided for @unitFormEmbedWidget.
  ///
  /// In en, this message translates to:
  /// **'Embed Widget'**
  String get unitFormEmbedWidget;

  /// No description provided for @unitFormEmbedDesc.
  ///
  /// In en, this message translates to:
  /// **'Integrate booking widget on your website'**
  String get unitFormEmbedDesc;

  /// No description provided for @unitFormWidgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Widget Settings'**
  String get unitFormWidgetSettings;

  /// No description provided for @unitFormGenerateEmbed.
  ///
  /// In en, this message translates to:
  /// **'Generate Embed Code'**
  String get unitFormGenerateEmbed;

  /// No description provided for @unitFormSuccessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Unit successfully updated'**
  String get unitFormSuccessUpdate;

  /// No description provided for @unitFormSuccessAdd.
  ///
  /// In en, this message translates to:
  /// **'Unit successfully added'**
  String get unitFormSuccessAdd;

  /// No description provided for @unitFormErrorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Error updating unit'**
  String get unitFormErrorUpdate;

  /// No description provided for @unitFormErrorAdd.
  ///
  /// In en, this message translates to:
  /// **'Error adding unit'**
  String get unitFormErrorAdd;

  /// No description provided for @unitPricingTitle.
  ///
  /// In en, this message translates to:
  /// **'Price List'**
  String get unitPricingTitle;

  /// No description provided for @unitPricingSelectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select Unit'**
  String get unitPricingSelectUnit;

  /// No description provided for @unitPricingSelectUnitHint.
  ///
  /// In en, this message translates to:
  /// **'Select unit'**
  String get unitPricingSelectUnitHint;

  /// No description provided for @unitPricingUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitPricingUnit;

  /// No description provided for @unitPricingNoUnits.
  ///
  /// In en, this message translates to:
  /// **'No units added'**
  String get unitPricingNoUnits;

  /// No description provided for @unitPricingNoUnitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a unit to manage prices for your accommodation.'**
  String get unitPricingNoUnitsDesc;

  /// No description provided for @unitPricingLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading units'**
  String get unitPricingLoadError;

  /// No description provided for @unitPricingBasePrice.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get unitPricingBasePrice;

  /// No description provided for @unitPricingBasePriceDesc.
  ///
  /// In en, this message translates to:
  /// **'This is the default price per night used when there are no special prices.'**
  String get unitPricingBasePriceDesc;

  /// No description provided for @unitPricingPricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Price per night (€)'**
  String get unitPricingPricePerNight;

  /// No description provided for @unitPricingSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get unitPricingSave;

  /// No description provided for @unitPricingSavePrice.
  ///
  /// In en, this message translates to:
  /// **'Save Price'**
  String get unitPricingSavePrice;

  /// No description provided for @unitPricingEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get unitPricingEnterPrice;

  /// No description provided for @unitPricingPriceGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than 0'**
  String get unitPricingPriceGreaterThanZero;

  /// No description provided for @unitPricingSuccessUpdate.
  ///
  /// In en, this message translates to:
  /// **'Base price successfully updated'**
  String get unitPricingSuccessUpdate;

  /// No description provided for @unitPricingErrorUpdate.
  ///
  /// In en, this message translates to:
  /// **'Error updating price'**
  String get unitPricingErrorUpdate;

  /// No description provided for @onboardingWizardPropertyData.
  ///
  /// In en, this message translates to:
  /// **'Property Data'**
  String get onboardingWizardPropertyData;

  /// No description provided for @onboardingWizardFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get onboardingWizardFinish;

  /// No description provided for @onboardingWizardSkipDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip guide?'**
  String get onboardingWizardSkipDialogTitle;

  /// No description provided for @onboardingWizardSkipDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'If you skip the guide, you won\'t complete the initial setup. You will need to manually add properties and units later.\n\nDo you want to continue?'**
  String get onboardingWizardSkipDialogDesc;

  /// No description provided for @onboardingWizardCompleteError.
  ///
  /// In en, this message translates to:
  /// **'Error completing initial setup'**
  String get onboardingWizardCompleteError;

  /// No description provided for @widgetSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Widget Settings'**
  String get widgetSettingsTitle;

  /// No description provided for @widgetSettingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading settings'**
  String get widgetSettingsLoadError;

  /// No description provided for @widgetSettingsSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully!'**
  String get widgetSettingsSaveSuccess;

  /// No description provided for @widgetSettingsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get widgetSettingsSaveError;

  /// No description provided for @widgetSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get widgetSettingsSave;

  /// No description provided for @widgetSettingsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get widgetSettingsSaving;

  /// No description provided for @widgetSettingsWidgetMode.
  ///
  /// In en, this message translates to:
  /// **'Widget Mode'**
  String get widgetSettingsWidgetMode;

  /// No description provided for @widgetSettingsWidgetModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose how the widget will function:'**
  String get widgetSettingsWidgetModeDesc;

  /// No description provided for @widgetSettingsPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get widgetSettingsPaymentMethods;

  /// No description provided for @widgetSettingsPaymentMethodsDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose payment methods available to guests:'**
  String get widgetSettingsPaymentMethodsDesc;

  /// No description provided for @widgetSettingsDepositAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit Amount: {percent}%'**
  String widgetSettingsDepositAmount(int percent);

  /// No description provided for @widgetSettingsDepositDesc.
  ///
  /// In en, this message translates to:
  /// **'This percentage applies to all payment methods (Stripe, Bank Transfer)'**
  String get widgetSettingsDepositDesc;

  /// No description provided for @widgetSettingsFullPayment.
  ///
  /// In en, this message translates to:
  /// **'Full payment'**
  String get widgetSettingsFullPayment;

  /// No description provided for @widgetSettingsStripePayment.
  ///
  /// In en, this message translates to:
  /// **'Stripe Payment'**
  String get widgetSettingsStripePayment;

  /// No description provided for @widgetSettingsCardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card payment'**
  String get widgetSettingsCardPayment;

  /// No description provided for @widgetSettingsBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get widgetSettingsBankTransfer;

  /// No description provided for @widgetSettingsBankPayment.
  ///
  /// In en, this message translates to:
  /// **'Bank account payment'**
  String get widgetSettingsBankPayment;

  /// No description provided for @widgetSettingsBankNotEntered.
  ///
  /// In en, this message translates to:
  /// **'Bank details not entered'**
  String get widgetSettingsBankNotEntered;

  /// No description provided for @widgetSettingsBankNotEnteredDesc.
  ///
  /// In en, this message translates to:
  /// **'To enable bank transfer, you must first enter bank details in your profile (bank name, IBAN, account holder).'**
  String get widgetSettingsBankNotEnteredDesc;

  /// No description provided for @widgetSettingsAddBankDetails.
  ///
  /// In en, this message translates to:
  /// **'Add Bank Details'**
  String get widgetSettingsAddBankDetails;

  /// No description provided for @widgetSettingsBankEnterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter bank details in Integrations → Payments.'**
  String get widgetSettingsBankEnterDetails;

  /// No description provided for @widgetSettingsBankFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Bank details from profile:'**
  String get widgetSettingsBankFromProfile;

  /// No description provided for @widgetSettingsBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get widgetSettingsBank;

  /// No description provided for @widgetSettingsAccountHolder.
  ///
  /// In en, this message translates to:
  /// **'Account holder'**
  String get widgetSettingsAccountHolder;

  /// No description provided for @widgetSettingsPaymentDeadline.
  ///
  /// In en, this message translates to:
  /// **'Payment deadline (days)'**
  String get widgetSettingsPaymentDeadline;

  /// No description provided for @widgetSettingsDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get widgetSettingsDay;

  /// No description provided for @widgetSettingsDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get widgetSettingsDays;

  /// No description provided for @widgetSettingsShowQrCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get widgetSettingsShowQrCode;

  /// No description provided for @widgetSettingsEpcQrCode.
  ///
  /// In en, this message translates to:
  /// **'EPC QR code'**
  String get widgetSettingsEpcQrCode;

  /// No description provided for @widgetSettingsCustomNote.
  ///
  /// In en, this message translates to:
  /// **'Custom note'**
  String get widgetSettingsCustomNote;

  /// No description provided for @widgetSettingsAddMessage.
  ///
  /// In en, this message translates to:
  /// **'Add message'**
  String get widgetSettingsAddMessage;

  /// No description provided for @widgetSettingsNoteMaxChars.
  ///
  /// In en, this message translates to:
  /// **'Note (max 500 characters)'**
  String get widgetSettingsNoteMaxChars;

  /// No description provided for @widgetSettingsNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Custom message that will be shown to guests'**
  String get widgetSettingsNoteHelper;

  /// No description provided for @widgetSettingsPayOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Pay on Arrival'**
  String get widgetSettingsPayOnArrival;

  /// No description provided for @widgetSettingsPayOnArrivalDesc.
  ///
  /// In en, this message translates to:
  /// **'Guest pays at check-in'**
  String get widgetSettingsPayOnArrivalDesc;

  /// No description provided for @widgetSettingsPayOnArrivalRequired.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Required (because other methods are disabled)'**
  String get widgetSettingsPayOnArrivalRequired;

  /// No description provided for @widgetSettingsPaymentValidation.
  ///
  /// In en, this message translates to:
  /// **'At least one payment method must be enabled in Instant Booking mode'**
  String get widgetSettingsPaymentValidation;

  /// No description provided for @widgetSettingsBookingBehavior.
  ///
  /// In en, this message translates to:
  /// **'Booking Behavior'**
  String get widgetSettingsBookingBehavior;

  /// No description provided for @widgetSettingsRequireApproval.
  ///
  /// In en, this message translates to:
  /// **'Require Approval'**
  String get widgetSettingsRequireApproval;

  /// No description provided for @widgetSettingsManualApproval.
  ///
  /// In en, this message translates to:
  /// **'Manual approval'**
  String get widgetSettingsManualApproval;

  /// No description provided for @widgetSettingsAllowCancellation.
  ///
  /// In en, this message translates to:
  /// **'Allow Cancellation'**
  String get widgetSettingsAllowCancellation;

  /// No description provided for @widgetSettingsGuestsCanCancel.
  ///
  /// In en, this message translates to:
  /// **'Guests can cancel'**
  String get widgetSettingsGuestsCanCancel;

  /// No description provided for @widgetSettingsPendingModeInfo.
  ///
  /// In en, this message translates to:
  /// **'In \"Booking without payment\" mode, all reservations always require your approval.'**
  String get widgetSettingsPendingModeInfo;

  /// No description provided for @widgetSettingsCancellationDeadline.
  ///
  /// In en, this message translates to:
  /// **'Cancellation deadline: {hours} hours before check-in'**
  String widgetSettingsCancellationDeadline(int hours);

  /// No description provided for @widgetSettingsMinNights.
  ///
  /// In en, this message translates to:
  /// **'Minimum nights: {nights} {nightsLabel}'**
  String widgetSettingsMinNights(int nights, String nightsLabel);

  /// No description provided for @widgetSettingsNight.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get widgetSettingsNight;

  /// No description provided for @widgetSettingsNights.
  ///
  /// In en, this message translates to:
  /// **'nights'**
  String get widgetSettingsNights;

  /// No description provided for @widgetSettingsContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get widgetSettingsContactInfo;

  /// No description provided for @widgetSettingsContactDesc.
  ///
  /// In en, this message translates to:
  /// **'Contact options that will be shown in the widget:'**
  String get widgetSettingsContactDesc;

  /// No description provided for @widgetSettingsPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get widgetSettingsPhoneNumber;

  /// No description provided for @widgetSettingsEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get widgetSettingsEmailAddress;

  /// No description provided for @widgetSettingsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get widgetSettingsPhone;

  /// No description provided for @widgetSettingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get widgetSettingsEmail;

  /// No description provided for @widgetSettingsBookingWithoutPayment.
  ///
  /// In en, this message translates to:
  /// **'Booking without payment'**
  String get widgetSettingsBookingWithoutPayment;

  /// No description provided for @widgetSettingsBookingWithoutPaymentDesc.
  ///
  /// In en, this message translates to:
  /// **'In this mode, guests can create a reservation but CANNOT pay online. You arrange payment privately after confirming the reservation.'**
  String get widgetSettingsBookingWithoutPaymentDesc;

  /// No description provided for @bookingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get bookingCreateTitle;

  /// No description provided for @bookingCreateClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get bookingCreateClose;

  /// No description provided for @bookingCreateUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit *'**
  String get bookingCreateUnit;

  /// No description provided for @bookingCreateNoUnits.
  ///
  /// In en, this message translates to:
  /// **'No available units'**
  String get bookingCreateNoUnits;

  /// No description provided for @bookingCreateSelectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select unit *'**
  String get bookingCreateSelectUnit;

  /// No description provided for @bookingCreateSelectUnitError.
  ///
  /// In en, this message translates to:
  /// **'Please select a unit'**
  String get bookingCreateSelectUnitError;

  /// No description provided for @bookingCreateDates.
  ///
  /// In en, this message translates to:
  /// **'Dates *'**
  String get bookingCreateDates;

  /// No description provided for @bookingCreateCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in *'**
  String get bookingCreateCheckIn;

  /// No description provided for @bookingCreateCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out *'**
  String get bookingCreateCheckOut;

  /// No description provided for @bookingCreateSelectCheckInDate.
  ///
  /// In en, this message translates to:
  /// **'Select check-in date'**
  String get bookingCreateSelectCheckInDate;

  /// No description provided for @bookingCreateSelectCheckOutDate.
  ///
  /// In en, this message translates to:
  /// **'Select check-out date'**
  String get bookingCreateSelectCheckOutDate;

  /// No description provided for @bookingCreateNightsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} night{count, plural, =1{} other{s}}'**
  String bookingCreateNightsCount(int count);

  /// No description provided for @bookingCreateGuestInfo.
  ///
  /// In en, this message translates to:
  /// **'Guest Information'**
  String get bookingCreateGuestInfo;

  /// No description provided for @bookingCreateGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest Name *'**
  String get bookingCreateGuestName;

  /// No description provided for @bookingCreateGuestNameError.
  ///
  /// In en, this message translates to:
  /// **'Please enter guest name'**
  String get bookingCreateGuestNameError;

  /// No description provided for @bookingCreateEmail.
  ///
  /// In en, this message translates to:
  /// **'Email *'**
  String get bookingCreateEmail;

  /// No description provided for @bookingCreateEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get bookingCreateEmailError;

  /// No description provided for @bookingCreateEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get bookingCreateEmailInvalid;

  /// No description provided for @bookingCreatePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone *'**
  String get bookingCreatePhone;

  /// No description provided for @bookingCreatePhoneError.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone'**
  String get bookingCreatePhoneError;

  /// No description provided for @bookingCreateBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingCreateBookingDetails;

  /// No description provided for @bookingCreateGuestCount.
  ///
  /// In en, this message translates to:
  /// **'Number of Guests *'**
  String get bookingCreateGuestCount;

  /// No description provided for @bookingCreateGuestCountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter number of guests'**
  String get bookingCreateGuestCountError;

  /// No description provided for @bookingCreateGuestCountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Number of guests must be greater than 0'**
  String get bookingCreateGuestCountInvalid;

  /// No description provided for @bookingCreateTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price (€) *'**
  String get bookingCreateTotalPrice;

  /// No description provided for @bookingCreatePriceError.
  ///
  /// In en, this message translates to:
  /// **'Please enter price'**
  String get bookingCreatePriceError;

  /// No description provided for @bookingCreatePriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get bookingCreatePriceInvalid;

  /// No description provided for @bookingCreatePriceNegative.
  ///
  /// In en, this message translates to:
  /// **'Price cannot be negative'**
  String get bookingCreatePriceNegative;

  /// No description provided for @bookingCreatePriceZero.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than 0'**
  String get bookingCreatePriceZero;

  /// No description provided for @bookingCreateStatusInfo.
  ///
  /// In en, this message translates to:
  /// **'Status: Confirmed • Payment: Cash'**
  String get bookingCreateStatusInfo;

  /// No description provided for @bookingCreateNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get bookingCreateNotes;

  /// No description provided for @bookingCreateInternalNotes.
  ///
  /// In en, this message translates to:
  /// **'Internal notes'**
  String get bookingCreateInternalNotes;

  /// No description provided for @bookingCreateNotesHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. special requests...'**
  String get bookingCreateNotesHint;

  /// No description provided for @bookingCreateCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bookingCreateCancel;

  /// No description provided for @bookingCreateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get bookingCreateSubmit;

  /// No description provided for @bookingCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking successfully created'**
  String get bookingCreateSuccess;

  /// No description provided for @bookingCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating booking'**
  String get bookingCreateError;

  /// No description provided for @bookingCreateOverlapWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Booking Overlap!'**
  String get bookingCreateOverlapWarning;

  /// No description provided for @bookingCreateOverlapSingle.
  ///
  /// In en, this message translates to:
  /// **'New booking overlaps with an existing booking:'**
  String get bookingCreateOverlapSingle;

  /// No description provided for @bookingCreateOverlapMultiple.
  ///
  /// In en, this message translates to:
  /// **'New booking overlaps with {count} existing bookings:'**
  String bookingCreateOverlapMultiple(int count);

  /// No description provided for @bookingCreateUnknownGuest.
  ///
  /// In en, this message translates to:
  /// **'Unknown guest'**
  String get bookingCreateUnknownGuest;

  /// No description provided for @bookingCreateContinueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get bookingCreateContinueAnyway;

  /// No description provided for @bookingCreateErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String bookingCreateErrorGeneric(String error);

  /// No description provided for @bookingApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Booking'**
  String get bookingApproveTitle;

  /// No description provided for @bookingApproveMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this booking?\n\nAfter approval, you can contact the guest with payment details.'**
  String get bookingApproveMessage;

  /// No description provided for @bookingApproveCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bookingApproveCancel;

  /// No description provided for @bookingApproveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get bookingApproveConfirm;

  /// No description provided for @bookingRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Booking'**
  String get bookingRejectTitle;

  /// No description provided for @bookingRejectMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this booking?'**
  String get bookingRejectMessage;

  /// No description provided for @bookingRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get bookingRejectReason;

  /// No description provided for @bookingRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter reason (optional)...'**
  String get bookingRejectReasonHint;

  /// No description provided for @bookingRejectCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bookingRejectCancel;

  /// No description provided for @bookingRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get bookingRejectConfirm;

  /// No description provided for @bookingCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get bookingCancelTitle;

  /// No description provided for @bookingCancelMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get bookingCancelMessage;

  /// No description provided for @bookingCancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get bookingCancelReason;

  /// No description provided for @bookingCancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter reason...'**
  String get bookingCancelReasonHint;

  /// No description provided for @bookingCancelSendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send email to guest'**
  String get bookingCancelSendEmail;

  /// No description provided for @bookingCancelSendEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Guest will receive cancellation notification'**
  String get bookingCancelSendEmailHint;

  /// No description provided for @bookingCancelCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bookingCancelCancel;

  /// No description provided for @bookingCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get bookingCancelConfirm;

  /// No description provided for @bookingCancelDefaultReason.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by owner'**
  String get bookingCancelDefaultReason;

  /// No description provided for @onboardingPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Property Information'**
  String get onboardingPropertyTitle;

  /// No description provided for @onboardingPropertySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter basic information about your accommodation'**
  String get onboardingPropertySubtitle;

  /// No description provided for @onboardingPropertyName.
  ///
  /// In en, this message translates to:
  /// **'Property Name *'**
  String get onboardingPropertyName;

  /// No description provided for @onboardingPropertyNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Villa Jasko'**
  String get onboardingPropertyNameHint;

  /// No description provided for @onboardingPropertyType.
  ///
  /// In en, this message translates to:
  /// **'Accommodation Type *'**
  String get onboardingPropertyType;

  /// No description provided for @onboardingPropertyAddress.
  ///
  /// In en, this message translates to:
  /// **'Address *'**
  String get onboardingPropertyAddress;

  /// No description provided for @onboardingPropertyAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street and number'**
  String get onboardingPropertyAddressHint;

  /// No description provided for @onboardingPropertyCity.
  ///
  /// In en, this message translates to:
  /// **'City *'**
  String get onboardingPropertyCity;

  /// No description provided for @onboardingPropertyCountry.
  ///
  /// In en, this message translates to:
  /// **'Country *'**
  String get onboardingPropertyCountry;

  /// No description provided for @onboardingPropertyRequired.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get onboardingPropertyRequired;

  /// No description provided for @onboardingPropertyRequiredShort.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get onboardingPropertyRequiredShort;

  /// No description provided for @onboardingPropertyOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Information (optional)'**
  String get onboardingPropertyOptional;

  /// No description provided for @onboardingPropertyPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get onboardingPropertyPhone;

  /// No description provided for @onboardingPropertyPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+385 xx xxx xxxx'**
  String get onboardingPropertyPhoneHint;

  /// No description provided for @onboardingPropertyEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get onboardingPropertyEmail;

  /// No description provided for @onboardingPropertyEmailHint.
  ///
  /// In en, this message translates to:
  /// **'info@example.com'**
  String get onboardingPropertyEmailHint;

  /// No description provided for @onboardingPropertyWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get onboardingPropertyWebsite;

  /// No description provided for @onboardingPropertyWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get onboardingPropertyWebsiteHint;

  /// No description provided for @onboardingPropertyTypeVilla.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get onboardingPropertyTypeVilla;

  /// No description provided for @onboardingPropertyTypeApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get onboardingPropertyTypeApartment;

  /// No description provided for @onboardingPropertyTypeStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get onboardingPropertyTypeStudio;

  /// No description provided for @onboardingPropertyTypeHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get onboardingPropertyTypeHouse;

  /// No description provided for @onboardingPropertyTypeRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get onboardingPropertyTypeRoom;

  /// No description provided for @themeSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get themeSelectionTitle;

  /// No description provided for @themeSelectionLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeSelectionLight;

  /// No description provided for @themeSelectionLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get themeSelectionLightDesc;

  /// No description provided for @themeSelectionDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeSelectionDark;

  /// No description provided for @themeSelectionDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get themeSelectionDarkDesc;

  /// No description provided for @themeSelectionSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSelectionSystem;

  /// No description provided for @themeSelectionSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow system theme'**
  String get themeSelectionSystemDesc;

  /// No description provided for @unitPricingErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading units'**
  String get unitPricingErrorLoading;

  /// No description provided for @unitPricingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Base price successfully updated'**
  String get unitPricingSuccess;

  /// No description provided for @unitPricingError.
  ///
  /// In en, this message translates to:
  /// **'Error updating price'**
  String get unitPricingError;

  /// No description provided for @ownerFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get ownerFaqTitle;

  /// No description provided for @ownerFaqSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search questions...'**
  String get ownerFaqSearchHint;

  /// No description provided for @ownerFaqCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ownerFaqCategoryAll;

  /// No description provided for @ownerFaqCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get ownerFaqCategoryGeneral;

  /// No description provided for @ownerFaqCategoryBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get ownerFaqCategoryBookings;

  /// No description provided for @ownerFaqCategoryPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get ownerFaqCategoryPayments;

  /// No description provided for @ownerFaqCategoryWidget.
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get ownerFaqCategoryWidget;

  /// No description provided for @ownerFaqCategoryIcalSync.
  ///
  /// In en, this message translates to:
  /// **'iCal Sync'**
  String get ownerFaqCategoryIcalSync;

  /// No description provided for @ownerFaqCategorySupport.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get ownerFaqCategorySupport;

  /// No description provided for @ownerFaqResultsFound.
  ///
  /// In en, this message translates to:
  /// **'Found: {count} results'**
  String ownerFaqResultsFound(int count);

  /// No description provided for @ownerFaqNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get ownerFaqNoResults;

  /// No description provided for @ownerFaqNoResultsDesc.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or category'**
  String get ownerFaqNoResultsDesc;

  /// No description provided for @icalSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'iCal Synchronization'**
  String get icalSyncTitle;

  /// No description provided for @icalSyncNoFeeds.
  ///
  /// In en, this message translates to:
  /// **'No feeds'**
  String get icalSyncNoFeeds;

  /// No description provided for @icalSyncNoFeedsDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first iCal feed to start synchronization'**
  String get icalSyncNoFeedsDesc;

  /// No description provided for @icalSyncError.
  ///
  /// In en, this message translates to:
  /// **'Synchronization error'**
  String get icalSyncError;

  /// No description provided for @icalSyncErrorCount.
  ///
  /// In en, this message translates to:
  /// **'{errorCount} of {totalCount} feeds have errors'**
  String icalSyncErrorCount(int errorCount, int totalCount);

  /// No description provided for @icalSyncActive.
  ///
  /// In en, this message translates to:
  /// **'Synchronization active'**
  String get icalSyncActive;

  /// No description provided for @icalSyncActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} feeds actively synchronized'**
  String icalSyncActiveCount(int count);

  /// No description provided for @icalSyncAllPaused.
  ///
  /// In en, this message translates to:
  /// **'All feeds paused'**
  String get icalSyncAllPaused;

  /// No description provided for @icalSyncNoActiveFeeds.
  ///
  /// In en, this message translates to:
  /// **'No active feeds'**
  String get icalSyncNoActiveFeeds;

  /// No description provided for @icalSyncWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why iCal Synchronization?'**
  String get icalSyncWhyTitle;

  /// No description provided for @icalSyncAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Automatic Synchronization'**
  String get icalSyncAutoSync;

  /// No description provided for @icalSyncAutoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Reservations are automatically imported from booking platforms every 60 minutes'**
  String get icalSyncAutoSyncDesc;

  /// No description provided for @icalSyncPreventDouble.
  ///
  /// In en, this message translates to:
  /// **'Prevent Double Booking'**
  String get icalSyncPreventDouble;

  /// No description provided for @icalSyncPreventDoubleDesc.
  ///
  /// In en, this message translates to:
  /// **'Block dates on all platforms automatically'**
  String get icalSyncPreventDoubleDesc;

  /// No description provided for @icalSyncCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get icalSyncCompatibility;

  /// No description provided for @icalSyncCompatibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Supports Booking.com, Airbnb and other iCal platforms'**
  String get icalSyncCompatibilityDesc;

  /// No description provided for @icalSyncSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure and Reliable'**
  String get icalSyncSecure;

  /// No description provided for @icalSyncSecureDesc.
  ///
  /// In en, this message translates to:
  /// **'Encrypted data and automatic backup of all reservations'**
  String get icalSyncSecureDesc;

  /// No description provided for @icalSyncNoFeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'No iCal Feeds'**
  String get icalSyncNoFeedsTitle;

  /// No description provided for @icalSyncNoFeedsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an iCal feed to synchronize reservations with booking platforms'**
  String get icalSyncNoFeedsMessage;

  /// No description provided for @icalSyncAddFeed.
  ///
  /// In en, this message translates to:
  /// **'Add iCal Feed'**
  String get icalSyncAddFeed;

  /// No description provided for @icalSyncAddFeedDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect calendar with Booking.com, Airbnb or other platforms'**
  String get icalSyncAddFeedDesc;

  /// No description provided for @icalSyncAddFeedButton.
  ///
  /// In en, this message translates to:
  /// **'Add Feed'**
  String get icalSyncAddFeedButton;

  /// No description provided for @icalSyncYourFeeds.
  ///
  /// In en, this message translates to:
  /// **'Your Feeds'**
  String get icalSyncYourFeeds;

  /// No description provided for @icalSyncLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last synchronized: {time}'**
  String icalSyncLastSync(String time);

  /// No description provided for @icalSyncErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String icalSyncErrorLabel(String error);

  /// No description provided for @icalSyncReservationsCount.
  ///
  /// In en, this message translates to:
  /// **'{reservations} reservations • {syncs} synchronizations'**
  String icalSyncReservationsCount(int reservations, int syncs);

  /// No description provided for @icalSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get icalSyncNow;

  /// No description provided for @icalSyncPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get icalSyncPause;

  /// No description provided for @icalSyncResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get icalSyncResume;

  /// No description provided for @icalSyncEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get icalSyncEdit;

  /// No description provided for @icalSyncDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get icalSyncDelete;

  /// No description provided for @icalSyncDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Feed?'**
  String get icalSyncDeleteTitle;

  /// No description provided for @icalSyncDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {platform} feed? This action will delete {count} synchronized reservations.'**
  String icalSyncDeleteMessage(String platform, int count);

  /// No description provided for @icalSyncDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Feed deleted'**
  String get icalSyncDeleteSuccess;

  /// No description provided for @icalSyncDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting feed'**
  String get icalSyncDeleteError;

  /// No description provided for @icalSyncStarted.
  ///
  /// In en, this message translates to:
  /// **'Synchronization started for {platform}...'**
  String icalSyncStarted(String platform);

  /// No description provided for @icalSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Synchronization successful! Reservations created: {count}'**
  String icalSyncSuccess(int count);

  /// No description provided for @icalSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Error during synchronization'**
  String get icalSyncFailed;

  /// No description provided for @icalSyncPaused.
  ///
  /// In en, this message translates to:
  /// **'Feed paused'**
  String get icalSyncPaused;

  /// No description provided for @icalSyncPauseError.
  ///
  /// In en, this message translates to:
  /// **'Error pausing feed'**
  String get icalSyncPauseError;

  /// No description provided for @icalSyncResumed.
  ///
  /// In en, this message translates to:
  /// **'Feed resumed'**
  String get icalSyncResumed;

  /// No description provided for @icalSyncResumeError.
  ///
  /// In en, this message translates to:
  /// **'Error resuming feed'**
  String get icalSyncResumeError;

  /// No description provided for @icalSyncHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How does iCal synchronization work?'**
  String get icalSyncHowItWorks;

  /// No description provided for @icalSyncLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading feeds'**
  String get icalSyncLoadingError;

  /// No description provided for @icalSyncAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add iCal Feed'**
  String get icalSyncAddTitle;

  /// No description provided for @icalSyncEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit iCal Feed'**
  String get icalSyncEditTitle;

  /// No description provided for @icalSyncSelectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select unit *'**
  String get icalSyncSelectUnit;

  /// No description provided for @icalSyncNoUnits.
  ///
  /// In en, this message translates to:
  /// **'You have no units created. First create an apartment.'**
  String get icalSyncNoUnits;

  /// No description provided for @icalSyncSelectPlatform.
  ///
  /// In en, this message translates to:
  /// **'Select platform *'**
  String get icalSyncSelectPlatform;

  /// No description provided for @icalSyncIcalUrl.
  ///
  /// In en, this message translates to:
  /// **'iCal URL *'**
  String get icalSyncIcalUrl;

  /// No description provided for @icalSyncIcalUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get icalSyncIcalUrlHint;

  /// No description provided for @icalSyncIcalUrlError.
  ///
  /// In en, this message translates to:
  /// **'Enter iCal URL'**
  String get icalSyncIcalUrlError;

  /// No description provided for @icalSyncIcalUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter valid URL (https://...)'**
  String get icalSyncIcalUrlInvalid;

  /// No description provided for @icalSyncSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get icalSyncSaving;

  /// No description provided for @icalSyncSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get icalSyncSave;

  /// No description provided for @icalSyncLoadingUnits.
  ///
  /// In en, this message translates to:
  /// **'Loading units...'**
  String get icalSyncLoadingUnits;

  /// No description provided for @embedGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Widget Embedding Guide'**
  String get embedGuideTitle;

  /// No description provided for @embedGuideHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Embed Booking Widget'**
  String get embedGuideHeaderTitle;

  /// No description provided for @embedGuideHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add calendar and booking system to your website'**
  String get embedGuideHeaderSubtitle;

  /// No description provided for @embedGuideHeaderTip.
  ///
  /// In en, this message translates to:
  /// **'💡 Embed widget allows your guests to see availability and create reservations directly from your website, without redirection.'**
  String get embedGuideHeaderTip;

  /// No description provided for @embedGuideStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Configure Widget'**
  String get embedGuideStep1Title;

  /// No description provided for @embedGuideStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Generate Embed Code'**
  String get embedGuideStep2Title;

  /// No description provided for @embedGuideStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Add to Your Website'**
  String get embedGuideStep3Title;

  /// No description provided for @embedGuideStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Test Widget'**
  String get embedGuideStep4Title;

  /// No description provided for @embedGuideAdvancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get embedGuideAdvancedOptions;

  /// No description provided for @embedGuideTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get embedGuideTroubleshooting;

  /// No description provided for @embedGuideCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get embedGuideCodeCopied;

  /// No description provided for @embedGuideYourEmbedCodes.
  ///
  /// In en, this message translates to:
  /// **'Your Embed Codes'**
  String get embedGuideYourEmbedCodes;

  /// No description provided for @embedGuideCopyIframe.
  ///
  /// In en, this message translates to:
  /// **'Copy the iframe code for each apartment'**
  String get embedGuideCopyIframe;

  /// No description provided for @embedGuideWidgetLanguage.
  ///
  /// In en, this message translates to:
  /// **'Widget language:'**
  String get embedGuideWidgetLanguage;

  /// No description provided for @embedGuideNoProperties.
  ///
  /// In en, this message translates to:
  /// **'You have no properties. Create a property to get embed codes.'**
  String get embedGuideNoProperties;

  /// No description provided for @embedGuideNoUnits.
  ///
  /// In en, this message translates to:
  /// **'You have no units. Create a unit to get embed codes.'**
  String get embedGuideNoUnits;

  /// No description provided for @embedGuideStep1Intro.
  ///
  /// In en, this message translates to:
  /// **'First you need to configure how the widget will work:'**
  String get embedGuideStep1Intro;

  /// No description provided for @embedGuideStep1Nav1.
  ///
  /// In en, this message translates to:
  /// **'Go to: Configuration → Accommodation Units'**
  String get embedGuideStep1Nav1;

  /// No description provided for @embedGuideStep1Nav2.
  ///
  /// In en, this message translates to:
  /// **'Click \"Edit\" on desired unit'**
  String get embedGuideStep1Nav2;

  /// No description provided for @embedGuideStep1Nav3.
  ///
  /// In en, this message translates to:
  /// **'Click \"Widget Settings\"'**
  String get embedGuideStep1Nav3;

  /// No description provided for @embedGuideStep1SelectMode.
  ///
  /// In en, this message translates to:
  /// **'Select operating mode:'**
  String get embedGuideStep1SelectMode;

  /// No description provided for @embedGuideWidgetModeCalendar.
  ///
  /// In en, this message translates to:
  /// **'📅 Calendar Only'**
  String get embedGuideWidgetModeCalendar;

  /// No description provided for @embedGuideWidgetModeCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Guests see only availability and contact info. For clients like jasko-rab.com.'**
  String get embedGuideWidgetModeCalendarDesc;

  /// No description provided for @embedGuideWidgetModeBooking.
  ///
  /// In en, this message translates to:
  /// **'📝 Booking without Payment'**
  String get embedGuideWidgetModeBooking;

  /// No description provided for @embedGuideWidgetModeBookingDesc.
  ///
  /// In en, this message translates to:
  /// **'Guests can create a reservation, but you must manually approve.'**
  String get embedGuideWidgetModeBookingDesc;

  /// No description provided for @embedGuideWidgetModePayment.
  ///
  /// In en, this message translates to:
  /// **'💳 Full Booking with Payment'**
  String get embedGuideWidgetModePayment;

  /// No description provided for @embedGuideWidgetModePaymentDesc.
  ///
  /// In en, this message translates to:
  /// **'Guests can book and pay immediately (Stripe or bank).'**
  String get embedGuideWidgetModePaymentDesc;

  /// No description provided for @embedGuidePlaceholderWidgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Image: Widget Settings screen with options'**
  String get embedGuidePlaceholderWidgetSettings;

  /// No description provided for @embedGuideStep2Intro.
  ///
  /// In en, this message translates to:
  /// **'After configuration, generate the embed code:'**
  String get embedGuideStep2Intro;

  /// No description provided for @embedGuideStep2Nav1.
  ///
  /// In en, this message translates to:
  /// **'In Edit Unit form, click \"Generate Embed Code\"'**
  String get embedGuideStep2Nav1;

  /// No description provided for @embedGuideStep2Nav2.
  ///
  /// In en, this message translates to:
  /// **'A dialog with iframe code will open'**
  String get embedGuideStep2Nav2;

  /// No description provided for @embedGuideStep2Nav3.
  ///
  /// In en, this message translates to:
  /// **'Select language (Hrvatski, English, Deutsch, Italiano)'**
  String get embedGuideStep2Nav3;

  /// No description provided for @embedGuideStep2Nav4.
  ///
  /// In en, this message translates to:
  /// **'Adjust widget height (default: 900px)'**
  String get embedGuideStep2Nav4;

  /// No description provided for @embedGuideStep2Nav5.
  ///
  /// In en, this message translates to:
  /// **'Copy code by clicking \"Copy\"'**
  String get embedGuideStep2Nav5;

  /// No description provided for @embedGuideStep2ExampleCode.
  ///
  /// In en, this message translates to:
  /// **'Example code:'**
  String get embedGuideStep2ExampleCode;

  /// No description provided for @embedGuideStep3Intro.
  ///
  /// In en, this message translates to:
  /// **'Now paste the code on your website:'**
  String get embedGuideStep3Intro;

  /// No description provided for @embedGuideStep3WordPress.
  ///
  /// In en, this message translates to:
  /// **'For WordPress:'**
  String get embedGuideStep3WordPress;

  /// No description provided for @embedGuideStep3WP1.
  ///
  /// In en, this message translates to:
  /// **'Open page in editor'**
  String get embedGuideStep3WP1;

  /// No description provided for @embedGuideStep3WP2.
  ///
  /// In en, this message translates to:
  /// **'Switch to \"HTML\" or \"Code\" mode'**
  String get embedGuideStep3WP2;

  /// No description provided for @embedGuideStep3WP3.
  ///
  /// In en, this message translates to:
  /// **'Paste iframe code'**
  String get embedGuideStep3WP3;

  /// No description provided for @embedGuideStep3WP4.
  ///
  /// In en, this message translates to:
  /// **'Click \"Publish\" or \"Update\"'**
  String get embedGuideStep3WP4;

  /// No description provided for @embedGuideStep3Static.
  ///
  /// In en, this message translates to:
  /// **'For static HTML pages:'**
  String get embedGuideStep3Static;

  /// No description provided for @embedGuideStep3HTML1.
  ///
  /// In en, this message translates to:
  /// **'Open HTML file in text editor'**
  String get embedGuideStep3HTML1;

  /// No description provided for @embedGuideStep3HTML2.
  ///
  /// In en, this message translates to:
  /// **'Find where you want the widget (e.g. inside <div>)'**
  String get embedGuideStep3HTML2;

  /// No description provided for @embedGuideStep3HTML3.
  ///
  /// In en, this message translates to:
  /// **'Paste iframe code'**
  String get embedGuideStep3HTML3;

  /// No description provided for @embedGuideStep3HTML4.
  ///
  /// In en, this message translates to:
  /// **'Save file and upload to server'**
  String get embedGuideStep3HTML4;

  /// No description provided for @embedGuidePlaceholderAddIframe.
  ///
  /// In en, this message translates to:
  /// **'GIF: Process of adding iframe to HTML'**
  String get embedGuidePlaceholderAddIframe;

  /// No description provided for @embedGuideStep4Intro.
  ///
  /// In en, this message translates to:
  /// **'Check if the widget works properly:'**
  String get embedGuideStep4Intro;

  /// No description provided for @embedGuideStep4Check1.
  ///
  /// In en, this message translates to:
  /// **'Open your website'**
  String get embedGuideStep4Check1;

  /// No description provided for @embedGuideStep4Check2.
  ///
  /// In en, this message translates to:
  /// **'Check if widget loads'**
  String get embedGuideStep4Check2;

  /// No description provided for @embedGuideStep4Check3.
  ///
  /// In en, this message translates to:
  /// **'Test calendar navigation'**
  String get embedGuideStep4Check3;

  /// No description provided for @embedGuideStep4Check4.
  ///
  /// In en, this message translates to:
  /// **'Test booking flow (if not calendar-only)'**
  String get embedGuideStep4Check4;

  /// No description provided for @embedGuideStep4Success.
  ///
  /// In en, this message translates to:
  /// **'Done! Widget is active and guests can see availability.'**
  String get embedGuideStep4Success;

  /// No description provided for @embedGuideAdvResponsive.
  ///
  /// In en, this message translates to:
  /// **'Responsive Widget'**
  String get embedGuideAdvResponsive;

  /// No description provided for @embedGuideAdvResponsiveDesc.
  ///
  /// In en, this message translates to:
  /// **'For a widget that automatically adjusts to screen width, use responsive embed code from the dialog.'**
  String get embedGuideAdvResponsiveDesc;

  /// No description provided for @embedGuideAdvLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language Change'**
  String get embedGuideAdvLanguage;

  /// No description provided for @embedGuideAdvLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Add &language=en (or hr, de, it) to URL to change widget language.'**
  String get embedGuideAdvLanguageDesc;

  /// No description provided for @embedGuideAdvColors.
  ///
  /// In en, this message translates to:
  /// **'Custom Colors'**
  String get embedGuideAdvColors;

  /// No description provided for @embedGuideAdvColorsDesc.
  ///
  /// In en, this message translates to:
  /// **'In Widget Settings you can change primary color for branding.'**
  String get embedGuideAdvColorsDesc;

  /// No description provided for @embedGuideAdvMultiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple Units'**
  String get embedGuideAdvMultiple;

  /// No description provided for @embedGuideAdvMultipleDesc.
  ///
  /// In en, this message translates to:
  /// **'For multiple apartments, create a separate widget for each (different unit ID in URL).'**
  String get embedGuideAdvMultipleDesc;

  /// No description provided for @embedGuideTroubleNotShowing.
  ///
  /// In en, this message translates to:
  /// **'Widget not showing'**
  String get embedGuideTroubleNotShowing;

  /// No description provided for @embedGuideTroubleNotShowingSolution.
  ///
  /// In en, this message translates to:
  /// **'• Check if you pasted complete iframe code\n• Check if unit ID is correct\n• Check browser console for JavaScript errors'**
  String get embedGuideTroubleNotShowingSolution;

  /// No description provided for @embedGuideTroubleHeight.
  ///
  /// In en, this message translates to:
  /// **'Widget too tall/short'**
  String get embedGuideTroubleHeight;

  /// No description provided for @embedGuideTroubleHeightSolution.
  ///
  /// In en, this message translates to:
  /// **'• Adjust height parameter in iframe tag (e.g. height=\"1200px\")\n• Use responsive embed code for automatic adjustment'**
  String get embedGuideTroubleHeightSolution;

  /// No description provided for @embedGuideTroublePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment not working'**
  String get embedGuideTroublePayment;

  /// No description provided for @embedGuideTroublePaymentSolution.
  ///
  /// In en, this message translates to:
  /// **'• Check if you connected Stripe account\n• Check if Stripe is enabled in Widget Settings\n• Check allow=\"payment\" attribute in iframe tag'**
  String get embedGuideTroublePaymentSolution;

  /// No description provided for @embedGuideTroubleOldData.
  ///
  /// In en, this message translates to:
  /// **'Calendar shows old data'**
  String get embedGuideTroubleOldData;

  /// No description provided for @embedGuideTroubleOldDataSolution.
  ///
  /// In en, this message translates to:
  /// **'• Refresh page (Ctrl+F5 for hard refresh)\n• Calendar automatically updates every 5 minutes'**
  String get embedGuideTroubleOldDataSolution;

  /// No description provided for @embedGuideSimpleStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'3 Simple Steps'**
  String get embedGuideSimpleStepsTitle;

  /// No description provided for @embedGuideSimpleStep1.
  ///
  /// In en, this message translates to:
  /// **'Copy the embed code for your unit'**
  String get embedGuideSimpleStep1;

  /// No description provided for @embedGuideSimpleStep2.
  ///
  /// In en, this message translates to:
  /// **'Paste it into your website\'s HTML'**
  String get embedGuideSimpleStep2;

  /// No description provided for @embedGuideSimpleStep3.
  ///
  /// In en, this message translates to:
  /// **'Save and publish'**
  String get embedGuideSimpleStep3;

  /// No description provided for @embedGuideNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get embedGuideNeedHelp;

  /// No description provided for @embedGuideInstallationGuide.
  ///
  /// In en, this message translates to:
  /// **'Installation Guide'**
  String get embedGuideInstallationGuide;

  /// No description provided for @embedGuideLanguageNote.
  ///
  /// In en, this message translates to:
  /// **'Widget has a built-in language selector. Users can switch between HR, EN, DE, IT.'**
  String get embedGuideLanguageNote;

  /// No description provided for @embedHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Embed Widget Help'**
  String get embedHelpTitle;

  /// No description provided for @embedHelpTabInstallation.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get embedHelpTabInstallation;

  /// No description provided for @embedHelpTabAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get embedHelpTabAdvanced;

  /// No description provided for @embedHelpTabTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get embedHelpTabTroubleshooting;

  /// No description provided for @stripeGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'Stripe Integration - Guide'**
  String get stripeGuideTitle;

  /// No description provided for @stripeGuideHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Stripe Connect'**
  String get stripeGuideHeaderTitle;

  /// No description provided for @stripeGuideHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept card payments directly to your Stripe account'**
  String get stripeGuideHeaderSubtitle;

  /// No description provided for @stripeGuideHeaderTip.
  ///
  /// In en, this message translates to:
  /// **'💡 Stripe Connect allows you to receive payments directly to your Stripe account. Guests pay by card, and funds go directly to you (minus Stripe fee).'**
  String get stripeGuideHeaderTip;

  /// No description provided for @stripeGuideStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Create Stripe Account'**
  String get stripeGuideStep1Title;

  /// No description provided for @stripeGuideStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Complete Stripe Onboarding'**
  String get stripeGuideStep2Title;

  /// No description provided for @stripeGuideStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Connect Stripe with Owner App'**
  String get stripeGuideStep3Title;

  /// No description provided for @stripeGuideStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Enable Stripe in Widget Settings'**
  String get stripeGuideStep4Title;

  /// No description provided for @stripeGuideGoToIntegration.
  ///
  /// In en, this message translates to:
  /// **'Go to Stripe Integration'**
  String get stripeGuideGoToIntegration;

  /// No description provided for @stripeGuideFaq.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get stripeGuideFaq;

  /// No description provided for @unitWizardCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Unit'**
  String get unitWizardCreateTitle;

  /// No description provided for @unitWizardEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Unit'**
  String get unitWizardEditTitle;

  /// No description provided for @unitWizardPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get unitWizardPublish;

  /// No description provided for @unitWizardContinueToReview.
  ///
  /// In en, this message translates to:
  /// **'Continue to Review'**
  String get unitWizardContinueToReview;

  /// No description provided for @unitWizardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get unitWizardNext;

  /// No description provided for @unitWizardBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get unitWizardBack;

  /// No description provided for @unitWizardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get unitWizardSkip;

  /// No description provided for @unitWizardFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wizard'**
  String get unitWizardFailedToLoad;

  /// No description provided for @unitWizardValidationStep1.
  ///
  /// In en, this message translates to:
  /// **'Please fill in unit name and URL slug'**
  String get unitWizardValidationStep1;

  /// No description provided for @unitWizardValidationStep2.
  ///
  /// In en, this message translates to:
  /// **'Please fill in bedrooms, bathrooms, and max guests'**
  String get unitWizardValidationStep2;

  /// No description provided for @unitWizardValidationStep3.
  ///
  /// In en, this message translates to:
  /// **'Please set price per night and minimum stay'**
  String get unitWizardValidationStep3;

  /// No description provided for @unitWizardValidationStep5.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required steps before publishing'**
  String get unitWizardValidationStep5;

  /// No description provided for @unitWizardValidationDefault.
  ///
  /// In en, this message translates to:
  /// **'Please complete this step'**
  String get unitWizardValidationDefault;

  /// No description provided for @unitWizardCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Unit created successfully!'**
  String get unitWizardCreateSuccess;

  /// No description provided for @unitWizardUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Unit updated successfully!'**
  String get unitWizardUpdateSuccess;

  /// No description provided for @unitWizardPublishError.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish unit: {error}'**
  String unitWizardPublishError(String error);

  /// No description provided for @unitWizardStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get unitWizardStep1Title;

  /// No description provided for @unitWizardStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter name and description of accommodation unit'**
  String get unitWizardStep1Subtitle;

  /// No description provided for @unitWizardStep1UnitInfo.
  ///
  /// In en, this message translates to:
  /// **'Unit Information'**
  String get unitWizardStep1UnitInfo;

  /// No description provided for @unitWizardStep1UnitInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Name and URL slug for identification'**
  String get unitWizardStep1UnitInfoDesc;

  /// No description provided for @unitWizardStep1UnitName.
  ///
  /// In en, this message translates to:
  /// **'Unit Name *'**
  String get unitWizardStep1UnitName;

  /// No description provided for @unitWizardStep1UnitNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ground Floor Apartment'**
  String get unitWizardStep1UnitNameHint;

  /// No description provided for @unitWizardStep1UnitNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get unitWizardStep1UnitNameRequired;

  /// No description provided for @unitWizardStep1UrlSlug.
  ///
  /// In en, this message translates to:
  /// **'URL Slug'**
  String get unitWizardStep1UrlSlug;

  /// No description provided for @unitWizardStep1UrlSlugHint.
  ///
  /// In en, this message translates to:
  /// **'ground-floor-apartment'**
  String get unitWizardStep1UrlSlugHint;

  /// No description provided for @unitWizardStep1SlugRequired.
  ///
  /// In en, this message translates to:
  /// **'Slug is required'**
  String get unitWizardStep1SlugRequired;

  /// No description provided for @unitWizardStep1SlugInvalid.
  ///
  /// In en, this message translates to:
  /// **'Slug can only contain lowercase letters, numbers and hyphens'**
  String get unitWizardStep1SlugInvalid;

  /// No description provided for @unitWizardStep1RegenerateSlug.
  ///
  /// In en, this message translates to:
  /// **'Regenerate from name'**
  String get unitWizardStep1RegenerateSlug;

  /// No description provided for @unitWizardStep1Description.
  ///
  /// In en, this message translates to:
  /// **'Unit Description'**
  String get unitWizardStep1Description;

  /// No description provided for @unitWizardStep1DescriptionInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional information visible to guests'**
  String get unitWizardStep1DescriptionInfo;

  /// No description provided for @unitWizardStep1DescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get unitWizardStep1DescriptionLabel;

  /// No description provided for @unitWizardStep1DescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Short description of the unit...'**
  String get unitWizardStep1DescriptionHint;

  /// No description provided for @unitWizardStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Capacity and Space'**
  String get unitWizardStep2Title;

  /// No description provided for @unitWizardStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter technical specifications of accommodation unit'**
  String get unitWizardStep2Subtitle;

  /// No description provided for @unitWizardStep2UnitCapacity.
  ///
  /// In en, this message translates to:
  /// **'Unit Capacity'**
  String get unitWizardStep2UnitCapacity;

  /// No description provided for @unitWizardStep2UnitCapacityDesc.
  ///
  /// In en, this message translates to:
  /// **'Technical specifications of accommodation'**
  String get unitWizardStep2UnitCapacityDesc;

  /// No description provided for @unitWizardStep2Bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms *'**
  String get unitWizardStep2Bedrooms;

  /// No description provided for @unitWizardStep2Bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms *'**
  String get unitWizardStep2Bathrooms;

  /// No description provided for @unitWizardStep2MaxGuests.
  ///
  /// In en, this message translates to:
  /// **'Maximum Guests *'**
  String get unitWizardStep2MaxGuests;

  /// No description provided for @unitWizardStep2Area.
  ///
  /// In en, this message translates to:
  /// **'Area (m²)'**
  String get unitWizardStep2Area;

  /// No description provided for @unitWizardStep2Required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get unitWizardStep2Required;

  /// No description provided for @unitWizardStep2InvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get unitWizardStep2InvalidNumber;

  /// No description provided for @unitWizardStep2MinGuest.
  ///
  /// In en, this message translates to:
  /// **'Minimum 1 guest'**
  String get unitWizardStep2MinGuest;

  /// No description provided for @unitWizardStep2InfoTip.
  ///
  /// In en, this message translates to:
  /// **'This information helps guests choose appropriate accommodation'**
  String get unitWizardStep2InfoTip;

  /// No description provided for @unitWizardStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Price and Availability'**
  String get unitWizardStep3Title;

  /// No description provided for @unitWizardStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set price, minimum stay and availability'**
  String get unitWizardStep3Subtitle;

  /// No description provided for @unitWizardStep3PriceInfo.
  ///
  /// In en, this message translates to:
  /// **'Price Information'**
  String get unitWizardStep3PriceInfo;

  /// No description provided for @unitWizardStep3PriceInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Base price and booking rules'**
  String get unitWizardStep3PriceInfoDesc;

  /// No description provided for @unitWizardStep3PricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Price per Night (€) *'**
  String get unitWizardStep3PricePerNight;

  /// No description provided for @unitWizardStep3PricePerNightHint.
  ///
  /// In en, this message translates to:
  /// **'50'**
  String get unitWizardStep3PricePerNightHint;

  /// No description provided for @unitWizardStep3PricePerNightHelper.
  ///
  /// In en, this message translates to:
  /// **'Base price for one night'**
  String get unitWizardStep3PricePerNightHelper;

  /// No description provided for @unitWizardStep3PriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get unitWizardStep3PriceRequired;

  /// No description provided for @unitWizardStep3PriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter valid price'**
  String get unitWizardStep3PriceInvalid;

  /// No description provided for @unitWizardStep3WeekendPrice.
  ///
  /// In en, this message translates to:
  /// **'Weekend Price (€)'**
  String get unitWizardStep3WeekendPrice;

  /// No description provided for @unitWizardStep3WeekendPriceHint.
  ///
  /// In en, this message translates to:
  /// **'70'**
  String get unitWizardStep3WeekendPriceHint;

  /// No description provided for @unitWizardStep3WeekendPriceHelper.
  ///
  /// In en, this message translates to:
  /// **'Price for Sat-Sun (optional)'**
  String get unitWizardStep3WeekendPriceHelper;

  /// No description provided for @unitWizardStep3MinStay.
  ///
  /// In en, this message translates to:
  /// **'Minimum Stay (nights) *'**
  String get unitWizardStep3MinStay;

  /// No description provided for @unitWizardStep3MinStayHint.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get unitWizardStep3MinStayHint;

  /// No description provided for @unitWizardStep3MinStayHelper.
  ///
  /// In en, this message translates to:
  /// **'Minimum nights for reservation'**
  String get unitWizardStep3MinStayHelper;

  /// No description provided for @unitWizardStep3MinStayRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum stay is required'**
  String get unitWizardStep3MinStayRequired;

  /// No description provided for @unitWizardStep3MinStayMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum is 1 night'**
  String get unitWizardStep3MinStayMin;

  /// No description provided for @unitWizardStep3MaxStay.
  ///
  /// In en, this message translates to:
  /// **'Maximum Stay (nights)'**
  String get unitWizardStep3MaxStay;

  /// No description provided for @unitWizardStep3MaxStayHint.
  ///
  /// In en, this message translates to:
  /// **'30'**
  String get unitWizardStep3MaxStayHint;

  /// No description provided for @unitWizardStep3MaxStayHelper.
  ///
  /// In en, this message translates to:
  /// **'Maximum nights (optional)'**
  String get unitWizardStep3MaxStayHelper;

  /// No description provided for @unitWizardStep3MaxStayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter valid number'**
  String get unitWizardStep3MaxStayInvalid;

  /// No description provided for @unitWizardStep3MaxStayMinError.
  ///
  /// In en, this message translates to:
  /// **'Max must be >= min ({min})'**
  String unitWizardStep3MaxStayMinError(int min);

  /// No description provided for @unitWizardStep3Availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get unitWizardStep3Availability;

  /// No description provided for @unitWizardStep3AvailabilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Set when unit is available for reservations'**
  String get unitWizardStep3AvailabilityDesc;

  /// No description provided for @unitWizardStep3YearRound.
  ///
  /// In en, this message translates to:
  /// **'Available Year Round'**
  String get unitWizardStep3YearRound;

  /// No description provided for @unitWizardStep3YearRoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Unit is open for reservations throughout the year'**
  String get unitWizardStep3YearRoundDesc;

  /// No description provided for @unitWizardStep3AdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced pricing options'**
  String get unitWizardStep3AdvancedTitle;

  /// No description provided for @unitWizardStep3AdvancedDesc.
  ///
  /// In en, this message translates to:
  /// **'After creating the unit, in the Pricing tab you can set advanced options such as min/max nights by date, check-in/check-out day blocking, weekend days and seasonal prices.'**
  String get unitWizardStep3AdvancedDesc;

  /// No description provided for @unitWizardStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get unitWizardStep4Title;

  /// No description provided for @unitWizardStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add photos of the accommodation unit (recommended min. 5)'**
  String get unitWizardStep4Subtitle;

  /// No description provided for @unitWizardStep4Gallery.
  ///
  /// In en, this message translates to:
  /// **'Photo Gallery'**
  String get unitWizardStep4Gallery;

  /// No description provided for @unitWizardStep4GalleryDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload photos of your unit'**
  String get unitWizardStep4GalleryDesc;

  /// No description provided for @unitWizardStep4AddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get unitWizardStep4AddPhotos;

  /// No description provided for @unitWizardStep4Uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get unitWizardStep4Uploading;

  /// No description provided for @unitWizardStep4PhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String unitWizardStep4PhotoCount(int count);

  /// No description provided for @unitWizardStep4NoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get unitWizardStep4NoPhotos;

  /// No description provided for @unitWizardStep4SetCover.
  ///
  /// In en, this message translates to:
  /// **'Set as cover'**
  String get unitWizardStep4SetCover;

  /// No description provided for @unitWizardStep4Delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get unitWizardStep4Delete;

  /// No description provided for @unitWizardStep4Cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get unitWizardStep4Cover;

  /// No description provided for @unitWizardStep4UploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {count} image(s) successfully'**
  String unitWizardStep4UploadSuccess(int count);

  /// No description provided for @unitWizardStep4UploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload images: {error}'**
  String unitWizardStep4UploadError(String error);

  /// No description provided for @unitWizardStep4ImageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Image deleted'**
  String get unitWizardStep4ImageDeleted;

  /// No description provided for @unitWizardStep4CoverUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cover image updated'**
  String get unitWizardStep4CoverUpdated;

  /// No description provided for @unitWizardStep5Title.
  ///
  /// In en, this message translates to:
  /// **'Review and Publish'**
  String get unitWizardStep5Title;

  /// No description provided for @unitWizardStep5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Review all information before publishing the unit'**
  String get unitWizardStep5Subtitle;

  /// No description provided for @unitWizardStep5BasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get unitWizardStep5BasicInfo;

  /// No description provided for @unitWizardStep5Capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get unitWizardStep5Capacity;

  /// No description provided for @unitWizardStep5Pricing.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get unitWizardStep5Pricing;

  /// No description provided for @unitWizardStep5AvailabilityCard.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get unitWizardStep5AvailabilityCard;

  /// No description provided for @unitWizardStep5Name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get unitWizardStep5Name;

  /// No description provided for @unitWizardStep5Slug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get unitWizardStep5Slug;

  /// No description provided for @unitWizardStep5Description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get unitWizardStep5Description;

  /// No description provided for @unitWizardStep5Bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get unitWizardStep5Bedrooms;

  /// No description provided for @unitWizardStep5Bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get unitWizardStep5Bathrooms;

  /// No description provided for @unitWizardStep5MaxGuests.
  ///
  /// In en, this message translates to:
  /// **'Max guests'**
  String get unitWizardStep5MaxGuests;

  /// No description provided for @unitWizardStep5Area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get unitWizardStep5Area;

  /// No description provided for @unitWizardStep5PricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Price per night'**
  String get unitWizardStep5PricePerNight;

  /// No description provided for @unitWizardStep5MinStay.
  ///
  /// In en, this message translates to:
  /// **'Min. stay'**
  String get unitWizardStep5MinStay;

  /// No description provided for @unitWizardStep5MinStayNights.
  ///
  /// In en, this message translates to:
  /// **'{nights} nights'**
  String unitWizardStep5MinStayNights(int nights);

  /// No description provided for @unitWizardStep5YearRound.
  ///
  /// In en, this message translates to:
  /// **'Year round'**
  String get unitWizardStep5YearRound;

  /// No description provided for @unitWizardStep5YearRoundYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get unitWizardStep5YearRoundYes;

  /// No description provided for @unitWizardStep5YearRoundSeasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get unitWizardStep5YearRoundSeasonal;

  /// No description provided for @unitWizardStep5IncompleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required steps before publishing'**
  String get unitWizardStep5IncompleteWarning;

  /// No description provided for @unitWizardStep5ReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'All required information is filled in. Click \"Publish\" to publish the unit.'**
  String get unitWizardStep5ReadyMessage;

  /// No description provided for @unitWizardProgressStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String unitWizardProgressStepOf(int current, int total);

  /// No description provided for @unitWizardProgressInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get unitWizardProgressInfo;

  /// No description provided for @unitWizardProgressCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get unitWizardProgressCapacity;

  /// No description provided for @unitWizardProgressPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get unitWizardProgressPrice;

  /// No description provided for @unitWizardProgressPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get unitWizardProgressPhotos;

  /// No description provided for @unitWizardProgressReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get unitWizardProgressReview;

  /// No description provided for @unitWizardProgressOptional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get unitWizardProgressOptional;

  /// No description provided for @propertyFormSubdomainSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion: '**
  String get propertyFormSubdomainSuggestion;

  /// No description provided for @propertyFormUseSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get propertyFormUseSuggestion;

  /// No description provided for @propertyFormNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get propertyFormNoPhotos;

  /// No description provided for @propertyFormGenerateFromName.
  ///
  /// In en, this message translates to:
  /// **'Generate from name'**
  String get propertyFormGenerateFromName;

  /// No description provided for @propertyFormSubdomainLabel.
  ///
  /// In en, this message translates to:
  /// **'Subdomain (for email links)'**
  String get propertyFormSubdomainLabel;

  /// No description provided for @propertyFormSubdomainEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'URL for email links: [subdomain].bookbed.io'**
  String get propertyFormSubdomainEmailHelper;

  /// No description provided for @icalExportTitle.
  ///
  /// In en, this message translates to:
  /// **'iCal Export'**
  String get icalExportTitle;

  /// No description provided for @icalExportUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get icalExportUnit;

  /// No description provided for @icalExportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get icalExportGenerating;

  /// No description provided for @icalExportGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate iCal Export'**
  String get icalExportGenerate;

  /// No description provided for @icalExportUrl.
  ///
  /// In en, this message translates to:
  /// **'Export URL'**
  String get icalExportUrl;

  /// No description provided for @icalExportCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get icalExportCopyUrl;

  /// No description provided for @icalExportLastGenerated.
  ///
  /// In en, this message translates to:
  /// **'Last generated: {time}'**
  String icalExportLastGenerated(String time);

  /// No description provided for @icalExportPreview.
  ///
  /// In en, this message translates to:
  /// **'.ics File Preview'**
  String get icalExportPreview;

  /// No description provided for @icalExportHowToTest.
  ///
  /// In en, this message translates to:
  /// **'How to Test'**
  String get icalExportHowToTest;

  /// No description provided for @icalExportGoogleCalendar.
  ///
  /// In en, this message translates to:
  /// **'1. Google Calendar'**
  String get icalExportGoogleCalendar;

  /// No description provided for @icalExportGoogleInstructions.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings → Add calendar → From URL → Paste the export URL'**
  String get icalExportGoogleInstructions;

  /// No description provided for @icalExportAppleCalendar.
  ///
  /// In en, this message translates to:
  /// **'2. Apple Calendar'**
  String get icalExportAppleCalendar;

  /// No description provided for @icalExportAppleInstructions.
  ///
  /// In en, this message translates to:
  /// **'File → New Calendar Subscription → Paste the export URL'**
  String get icalExportAppleInstructions;

  /// No description provided for @icalExportOutlook.
  ///
  /// In en, this message translates to:
  /// **'3. Outlook'**
  String get icalExportOutlook;

  /// No description provided for @icalExportOutlookInstructions.
  ///
  /// In en, this message translates to:
  /// **'Add calendar → Subscribe from web → Paste the export URL'**
  String get icalExportOutlookInstructions;

  /// No description provided for @icalExportSyncNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Calendar apps may take 5-15 minutes to sync after subscribing'**
  String get icalExportSyncNote;

  /// No description provided for @icalExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'iCal export generated successfully'**
  String get icalExportSuccess;

  /// No description provided for @icalExportError.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate iCal export'**
  String get icalExportError;

  /// No description provided for @icalExportUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'URL copied to clipboard'**
  String get icalExportUrlCopied;

  /// No description provided for @icalExportJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get icalExportJustNow;

  /// No description provided for @icalExportMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String icalExportMinutesAgo(int minutes);

  /// No description provided for @icalExportHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String icalExportHoursAgo(int hours);

  /// No description provided for @icalExportListTitle.
  ///
  /// In en, this message translates to:
  /// **'iCal Export - Select Unit'**
  String get icalExportListTitle;

  /// No description provided for @icalExportListHeader.
  ///
  /// In en, this message translates to:
  /// **'iCal Export'**
  String get icalExportListHeader;

  /// No description provided for @icalExportListDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a unit to generate iCal URL for calendar synchronization.'**
  String get icalExportListDescription;

  /// No description provided for @icalExportListUnknownUnit.
  ///
  /// In en, this message translates to:
  /// **'Unknown unit'**
  String get icalExportListUnknownUnit;

  /// No description provided for @icalExportListUnknownProperty.
  ///
  /// In en, this message translates to:
  /// **'Unknown property'**
  String get icalExportListUnknownProperty;

  /// No description provided for @icalExportListNoUnits.
  ///
  /// In en, this message translates to:
  /// **'No accommodation units'**
  String get icalExportListNoUnits;

  /// No description provided for @icalExportListNoUnitsDesc.
  ///
  /// In en, this message translates to:
  /// **'First create a property and add accommodation units.'**
  String get icalExportListNoUnitsDesc;

  /// No description provided for @icalExportListAddProperty.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get icalExportListAddProperty;

  /// No description provided for @icalExportReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to Export'**
  String get icalExportReady;

  /// No description provided for @icalExportUnitsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} units available for export'**
  String icalExportUnitsAvailable(int count);

  /// No description provided for @icalExportWhyExport.
  ///
  /// In en, this message translates to:
  /// **'Why Export Your Calendar?'**
  String get icalExportWhyExport;

  /// No description provided for @icalExportBenefit1Title.
  ///
  /// In en, this message translates to:
  /// **'Personal Calendar Sync'**
  String get icalExportBenefit1Title;

  /// No description provided for @icalExportBenefit1Desc.
  ///
  /// In en, this message translates to:
  /// **'See all your bookings in Google Calendar, Apple Calendar, or Outlook.'**
  String get icalExportBenefit1Desc;

  /// No description provided for @icalExportBenefit2Title.
  ///
  /// In en, this message translates to:
  /// **'Automatic Updates'**
  String get icalExportBenefit2Title;

  /// No description provided for @icalExportBenefit2Desc.
  ///
  /// In en, this message translates to:
  /// **'Calendar apps automatically sync new bookings every few hours.'**
  String get icalExportBenefit2Desc;

  /// No description provided for @icalExportBenefit3Title.
  ///
  /// In en, this message translates to:
  /// **'Multi-Device Access'**
  String get icalExportBenefit3Title;

  /// No description provided for @icalExportBenefit3Desc.
  ///
  /// In en, this message translates to:
  /// **'View your bookings on phone, tablet, and computer.'**
  String get icalExportBenefit3Desc;

  /// No description provided for @icalExportBenefit4Title.
  ///
  /// In en, this message translates to:
  /// **'Reminders & Notifications'**
  String get icalExportBenefit4Title;

  /// No description provided for @icalExportBenefit4Desc.
  ///
  /// In en, this message translates to:
  /// **'Get calendar notifications for upcoming check-ins and check-outs.'**
  String get icalExportBenefit4Desc;

  /// No description provided for @icalExportSelectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select Unit'**
  String get icalExportSelectUnit;

  /// No description provided for @icalExportHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get icalExportHowItWorks;

  /// No description provided for @icalExportStep1.
  ///
  /// In en, this message translates to:
  /// **'Select a unit from the list below'**
  String get icalExportStep1;

  /// No description provided for @icalExportStep2.
  ///
  /// In en, this message translates to:
  /// **'Click \'Generate\' to create the iCal URL'**
  String get icalExportStep2;

  /// No description provided for @icalExportStep3.
  ///
  /// In en, this message translates to:
  /// **'Copy the URL and add it to your calendar app'**
  String get icalExportStep3;

  /// No description provided for @icalExportStep4.
  ///
  /// In en, this message translates to:
  /// **'Your calendar will automatically sync bookings'**
  String get icalExportStep4;

  /// No description provided for @icalExportFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get icalExportFaqTitle;

  /// No description provided for @icalExportFaq1Q.
  ///
  /// In en, this message translates to:
  /// **'How often does the calendar sync?'**
  String get icalExportFaq1Q;

  /// No description provided for @icalExportFaq1A.
  ///
  /// In en, this message translates to:
  /// **'Most calendar apps sync every 5-15 minutes. You can also manually refresh in your calendar app.'**
  String get icalExportFaq1A;

  /// No description provided for @icalExportFaq2Q.
  ///
  /// In en, this message translates to:
  /// **'Will deleted bookings be removed?'**
  String get icalExportFaq2Q;

  /// No description provided for @icalExportFaq2A.
  ///
  /// In en, this message translates to:
  /// **'Yes, when you regenerate the export, cancelled bookings will be removed from your calendar.'**
  String get icalExportFaq2A;

  /// No description provided for @icalExportFaq3Q.
  ///
  /// In en, this message translates to:
  /// **'Can I share this URL with others?'**
  String get icalExportFaq3Q;

  /// No description provided for @icalExportFaq3A.
  ///
  /// In en, this message translates to:
  /// **'Yes, but be careful - anyone with the URL can see your booking schedule.'**
  String get icalExportFaq3A;

  /// No description provided for @icalExportUrlReady.
  ///
  /// In en, this message translates to:
  /// **'URL Ready'**
  String get icalExportUrlReady;

  /// No description provided for @icalExportUrlPending.
  ///
  /// In en, this message translates to:
  /// **'URL Not Generated'**
  String get icalExportUrlPending;

  /// No description provided for @icalExportUrlReadyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your iCal URL is ready. Copy it and add to your calendar app.'**
  String get icalExportUrlReadyDesc;

  /// No description provided for @icalExportUrlPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Click the button below to generate your iCal export URL.'**
  String get icalExportUrlPendingDesc;

  /// No description provided for @icalExportRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate URL'**
  String get icalExportRegenerate;

  /// No description provided for @icalExportNoUrl.
  ///
  /// In en, this message translates to:
  /// **'No URL Generated'**
  String get icalExportNoUrl;

  /// No description provided for @icalExportNoUrlDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate an iCal URL to sync your bookings with external calendars.'**
  String get icalExportNoUrlDesc;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @languageSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get languageSelectTitle;

  /// No description provided for @revenueChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue Overview'**
  String get revenueChartTitle;

  /// No description provided for @revenueChartLegend.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenueChartLegend;

  /// No description provided for @revenueChartNoData.
  ///
  /// In en, this message translates to:
  /// **'No revenue data available'**
  String get revenueChartNoData;

  /// No description provided for @propertyCardPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get propertyCardPublished;

  /// No description provided for @propertyCardHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get propertyCardHidden;

  /// No description provided for @propertyCardUnits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unit} other{{count} units}}'**
  String propertyCardUnits(int count);

  /// No description provided for @propertyCardEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get propertyCardEdit;

  /// No description provided for @propertyCardDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get propertyCardDelete;

  /// No description provided for @editBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Booking'**
  String get editBookingTitle;

  /// No description provided for @editBookingBookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking: {id}'**
  String editBookingBookingId(String id);

  /// No description provided for @editBookingGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest: {name}'**
  String editBookingGuest(String name);

  /// No description provided for @editBookingCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get editBookingCheckIn;

  /// No description provided for @editBookingCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get editBookingCheckOut;

  /// No description provided for @editBookingNights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 night} other{{count} nights}}'**
  String editBookingNights(int count);

  /// No description provided for @editBookingGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get editBookingGuests;

  /// No description provided for @editBookingInternalNotes.
  ///
  /// In en, this message translates to:
  /// **'Internal Notes'**
  String get editBookingInternalNotes;

  /// No description provided for @editBookingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes (not visible to guest)...'**
  String get editBookingNotesHint;

  /// No description provided for @editBookingSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editBookingSaveChanges;

  /// No description provided for @editBookingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking successfully updated'**
  String get editBookingSuccess;

  /// No description provided for @editBookingError.
  ///
  /// In en, this message translates to:
  /// **'Error updating booking'**
  String get editBookingError;

  /// No description provided for @embedCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Embed Code for Widget'**
  String get embedCodeTitle;

  /// No description provided for @embedCodeUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get embedCodeUnit;

  /// No description provided for @embedCodeUrlSlug.
  ///
  /// In en, this message translates to:
  /// **'URL Slug'**
  String get embedCodeUrlSlug;

  /// No description provided for @embedCodeUnitIdTechnical.
  ///
  /// In en, this message translates to:
  /// **'Unit ID (technical)'**
  String get embedCodeUnitIdTechnical;

  /// No description provided for @embedCodeWidgetUrl.
  ///
  /// In en, this message translates to:
  /// **'Widget URL'**
  String get embedCodeWidgetUrl;

  /// No description provided for @embedCodeOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get embedCodeOptions;

  /// No description provided for @embedCodeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get embedCodeLanguage;

  /// No description provided for @embedCodeHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (px)'**
  String get embedCodeHeight;

  /// No description provided for @embedCodeFixedHeight.
  ///
  /// In en, this message translates to:
  /// **'Fixed Height'**
  String get embedCodeFixedHeight;

  /// No description provided for @embedCodeFixedHeightDesc.
  ///
  /// In en, this message translates to:
  /// **'Iframe with fixed height ({height}px)'**
  String embedCodeFixedHeightDesc(String height);

  /// No description provided for @embedCodeResponsive.
  ///
  /// In en, this message translates to:
  /// **'Responsive'**
  String get embedCodeResponsive;

  /// No description provided for @embedCodeResponsiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically adjusts to width (aspect ratio 4:3)'**
  String get embedCodeResponsiveDesc;

  /// No description provided for @embedCodeCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get embedCodeCopy;

  /// No description provided for @embedCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard!'**
  String embedCodeCopied(String label);

  /// No description provided for @embedCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get embedCodeInstructions;

  /// No description provided for @embedCodeInstructionsText.
  ///
  /// In en, this message translates to:
  /// **'1. Copy embed code (click \"Copy\" button)\n2. Open your website page in editor\n3. Paste code at desired location\n4. Save and publish page'**
  String get embedCodeInstructionsText;

  /// No description provided for @sendEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Email to Guest'**
  String get sendEmailTitle;

  /// No description provided for @sendEmailTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get sendEmailTemplate;

  /// No description provided for @sendEmailTemplateConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmation'**
  String get sendEmailTemplateConfirmation;

  /// No description provided for @sendEmailTemplateReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get sendEmailTemplateReminder;

  /// No description provided for @sendEmailTemplateCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get sendEmailTemplateCancellation;

  /// No description provided for @sendEmailTemplateCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom message'**
  String get sendEmailTemplateCustom;

  /// No description provided for @sendEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject *'**
  String get sendEmailSubject;

  /// No description provided for @sendEmailSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Email subject'**
  String get sendEmailSubjectHint;

  /// No description provided for @sendEmailSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter subject'**
  String get sendEmailSubjectRequired;

  /// No description provided for @sendEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Message *'**
  String get sendEmailMessage;

  /// No description provided for @sendEmailMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter message for guest...'**
  String get sendEmailMessageHint;

  /// No description provided for @sendEmailMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter message'**
  String get sendEmailMessageRequired;

  /// No description provided for @sendEmailMessageTooShort.
  ///
  /// In en, this message translates to:
  /// **'Message must have at least 10 characters'**
  String get sendEmailMessageTooShort;

  /// No description provided for @sendEmailInfo.
  ///
  /// In en, this message translates to:
  /// **'Email will be sent from your registered email address'**
  String get sendEmailInfo;

  /// No description provided for @sendEmailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sendEmailCancel;

  /// No description provided for @sendEmailSend.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmailSend;

  /// No description provided for @sendEmailSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendEmailSending;

  /// No description provided for @sendEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email successfully sent to guest {name}'**
  String sendEmailSuccess(String name);

  /// No description provided for @sendEmailError.
  ///
  /// In en, this message translates to:
  /// **'Error sending email'**
  String get sendEmailError;

  /// No description provided for @sendEmailNoGuestEmail.
  ///
  /// In en, this message translates to:
  /// **'Guest email address not available'**
  String get sendEmailNoGuestEmail;

  /// No description provided for @priceCalendarSetPrice.
  ///
  /// In en, this message translates to:
  /// **'Set price'**
  String get priceCalendarSetPrice;

  /// No description provided for @priceCalendarAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get priceCalendarAvailability;

  /// No description provided for @priceCalendarSelectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get priceCalendarSelectMonth;

  /// No description provided for @priceCalendarBulkEdit.
  ///
  /// In en, this message translates to:
  /// **'Bulk Edit'**
  String get priceCalendarBulkEdit;

  /// No description provided for @priceCalendarDaysSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{day} other{days}} selected'**
  String priceCalendarDaysSelected(int count);

  /// No description provided for @priceCalendarClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get priceCalendarClear;

  /// No description provided for @priceCalendarSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get priceCalendarSelectAll;

  /// No description provided for @priceCalendarSelectAllDays.
  ///
  /// In en, this message translates to:
  /// **'Select all days'**
  String get priceCalendarSelectAllDays;

  /// No description provided for @priceCalendarDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get priceCalendarDeselectAll;

  /// No description provided for @priceCalendarErrorLoadingPrices.
  ///
  /// In en, this message translates to:
  /// **'Error loading prices'**
  String get priceCalendarErrorLoadingPrices;

  /// No description provided for @priceCalendarWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get priceCalendarWeekdayMon;

  /// No description provided for @priceCalendarWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get priceCalendarWeekdayTue;

  /// No description provided for @priceCalendarWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get priceCalendarWeekdayWed;

  /// No description provided for @priceCalendarWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get priceCalendarWeekdayThu;

  /// No description provided for @priceCalendarWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get priceCalendarWeekdayFri;

  /// No description provided for @priceCalendarWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get priceCalendarWeekdaySat;

  /// No description provided for @priceCalendarWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get priceCalendarWeekdaySun;

  /// No description provided for @priceCalendarEditDate.
  ///
  /// In en, this message translates to:
  /// **'Edit date'**
  String get priceCalendarEditDate;

  /// No description provided for @priceCalendarPrice.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get priceCalendarPrice;

  /// No description provided for @priceCalendarBasePricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Base price per night (€)'**
  String get priceCalendarBasePricePerNight;

  /// No description provided for @priceCalendarAvailabilitySection.
  ///
  /// In en, this message translates to:
  /// **'AVAILABILITY'**
  String get priceCalendarAvailabilitySection;

  /// No description provided for @priceCalendarAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get priceCalendarAvailable;

  /// No description provided for @priceCalendarBlockCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Block check-in'**
  String get priceCalendarBlockCheckIn;

  /// No description provided for @priceCalendarBlockCheckInDesc.
  ///
  /// In en, this message translates to:
  /// **'Guests cannot start reservation'**
  String get priceCalendarBlockCheckInDesc;

  /// No description provided for @priceCalendarBlockCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Block check-out'**
  String get priceCalendarBlockCheckOut;

  /// No description provided for @priceCalendarBlockCheckOutDesc.
  ///
  /// In en, this message translates to:
  /// **'Guests cannot end reservation'**
  String get priceCalendarBlockCheckOutDesc;

  /// No description provided for @priceCalendarAdvancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced options'**
  String get priceCalendarAdvancedOptions;

  /// No description provided for @priceCalendarAdvancedOptionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Weekend price, min/max nights, advance'**
  String get priceCalendarAdvancedOptionsDesc;

  /// No description provided for @priceCalendarWeekendPrice.
  ///
  /// In en, this message translates to:
  /// **'Weekend price (€)'**
  String get priceCalendarWeekendPrice;

  /// No description provided for @priceCalendarMinNights.
  ///
  /// In en, this message translates to:
  /// **'Min. nights'**
  String get priceCalendarMinNights;

  /// No description provided for @priceCalendarMaxNights.
  ///
  /// In en, this message translates to:
  /// **'Max. nights'**
  String get priceCalendarMaxNights;

  /// No description provided for @priceCalendarMinDaysAdvance.
  ///
  /// In en, this message translates to:
  /// **'Min. days advance'**
  String get priceCalendarMinDaysAdvance;

  /// No description provided for @priceCalendarMaxDaysAdvance.
  ///
  /// In en, this message translates to:
  /// **'Max. days advance'**
  String get priceCalendarMaxDaysAdvance;

  /// No description provided for @priceCalendarDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete confirmation'**
  String get priceCalendarDeleteConfirmTitle;

  /// No description provided for @priceCalendarDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete custom price? Date will be reverted to base price.'**
  String get priceCalendarDeleteConfirmMessage;

  /// No description provided for @priceCalendarRevertedToBasePrice.
  ///
  /// In en, this message translates to:
  /// **'Reverted to base price'**
  String get priceCalendarRevertedToBasePrice;

  /// No description provided for @priceCalendarEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get priceCalendarEnterPrice;

  /// No description provided for @priceCalendarPriceMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than 0'**
  String get priceCalendarPriceMustBeGreaterThanZero;

  /// No description provided for @priceCalendarWeekendPriceMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Weekend price must be greater than 0'**
  String get priceCalendarWeekendPriceMustBeGreaterThanZero;

  /// No description provided for @priceCalendarMinNightsMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Min. nights must be greater than 0'**
  String get priceCalendarMinNightsMustBeGreaterThanZero;

  /// No description provided for @priceCalendarMaxNightsMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Max. nights must be greater than 0'**
  String get priceCalendarMaxNightsMustBeGreaterThanZero;

  /// No description provided for @priceCalendarMinDaysAdvanceMustBeZeroOrMore.
  ///
  /// In en, this message translates to:
  /// **'Min. days advance must be 0 or more'**
  String get priceCalendarMinDaysAdvanceMustBeZeroOrMore;

  /// No description provided for @priceCalendarMaxDaysAdvanceMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Max. days advance must be greater than 0'**
  String get priceCalendarMaxDaysAdvanceMustBeGreaterThanZero;

  /// No description provided for @priceCalendarPriceSaved.
  ///
  /// In en, this message translates to:
  /// **'Price saved'**
  String get priceCalendarPriceSaved;

  /// No description provided for @priceCalendarSetPriceForDays.
  ///
  /// In en, this message translates to:
  /// **'Set price for {count} days'**
  String priceCalendarSetPriceForDays(int count);

  /// No description provided for @priceCalendarPricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Price per night (€)'**
  String get priceCalendarPricePerNight;

  /// No description provided for @priceCalendarWillSetPriceForAllDates.
  ///
  /// In en, this message translates to:
  /// **'Will set price for all selected dates'**
  String get priceCalendarWillSetPriceForAllDates;

  /// No description provided for @priceCalendarConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get priceCalendarConfirmation;

  /// No description provided for @priceCalendarConfirmSetPrice.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to set price €{price} for {count} {count, plural, =1{day} other{days}}?'**
  String priceCalendarConfirmSetPrice(String price, int count);

  /// No description provided for @priceCalendarUpdatedPrices.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} prices'**
  String priceCalendarUpdatedPrices(int count);

  /// No description provided for @priceCalendarUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get priceCalendarUndo;

  /// No description provided for @priceCalendarAvailabilityForDays.
  ///
  /// In en, this message translates to:
  /// **'Availability for {count} days'**
  String priceCalendarAvailabilityForDays(int count);

  /// No description provided for @priceCalendarSelectActionForDays.
  ///
  /// In en, this message translates to:
  /// **'Select action for {count} {count, plural, =1{day} other{days}}:'**
  String priceCalendarSelectActionForDays(int count);

  /// No description provided for @priceCalendarMarkAsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Mark as available'**
  String get priceCalendarMarkAsAvailable;

  /// No description provided for @priceCalendarDaysMarkedAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{day marked} other{days marked}} as available'**
  String priceCalendarDaysMarkedAvailable(int count);

  /// No description provided for @priceCalendarConfirmBlockDays.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block {count} {count, plural, =1{day} other{days}}?\n\nThese dates will be marked as unavailable.'**
  String priceCalendarConfirmBlockDays(int count);

  /// No description provided for @priceCalendarBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get priceCalendarBlock;

  /// No description provided for @priceCalendarBlockDates.
  ///
  /// In en, this message translates to:
  /// **'Block dates'**
  String get priceCalendarBlockDates;

  /// No description provided for @priceCalendarDaysBlocked.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{day blocked} other{days blocked}}'**
  String priceCalendarDaysBlocked(int count);

  /// No description provided for @priceCalendarBlockCheckInButton.
  ///
  /// In en, this message translates to:
  /// **'Block check-in'**
  String get priceCalendarBlockCheckInButton;

  /// No description provided for @priceCalendarCheckInBlockedForDays.
  ///
  /// In en, this message translates to:
  /// **'Check-in blocked for selected days'**
  String get priceCalendarCheckInBlockedForDays;

  /// No description provided for @priceCalendarBlockCheckOutButton.
  ///
  /// In en, this message translates to:
  /// **'Block check-out'**
  String get priceCalendarBlockCheckOutButton;

  /// No description provided for @priceCalendarCheckOutBlockedForDays.
  ///
  /// In en, this message translates to:
  /// **'Check-out blocked for selected days'**
  String get priceCalendarCheckOutBlockedForDays;

  /// No description provided for @icalNoFeeds.
  ///
  /// In en, this message translates to:
  /// **'No feeds'**
  String get icalNoFeeds;

  /// No description provided for @icalNoFeedsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first iCal feed to start synchronization'**
  String get icalNoFeedsDescription;

  /// No description provided for @icalAllFeedsPaused.
  ///
  /// In en, this message translates to:
  /// **'All feeds paused'**
  String get icalAllFeedsPaused;

  /// No description provided for @icalNoActiveFeeds.
  ///
  /// In en, this message translates to:
  /// **'No active feeds'**
  String get icalNoActiveFeeds;

  /// No description provided for @icalWhySync.
  ///
  /// In en, this message translates to:
  /// **'Why iCal Synchronization?'**
  String get icalWhySync;

  /// No description provided for @icalAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Automatic Synchronization'**
  String get icalAutoSync;

  /// No description provided for @icalAutoSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Reservations are automatically imported from booking platforms every 60 minutes'**
  String get icalAutoSyncDesc;

  /// No description provided for @icalPreventDoubleBooking.
  ///
  /// In en, this message translates to:
  /// **'Prevent Double Booking'**
  String get icalPreventDoubleBooking;

  /// No description provided for @icalPreventDoubleBookingDesc.
  ///
  /// In en, this message translates to:
  /// **'Block dates on all platforms automatically'**
  String get icalPreventDoubleBookingDesc;

  /// No description provided for @icalCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get icalCompatibility;

  /// No description provided for @icalCompatibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Supports Booking.com, Airbnb and other iCal platforms'**
  String get icalCompatibilityDesc;

  /// No description provided for @icalSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure and Reliable'**
  String get icalSecure;

  /// No description provided for @icalSecureDesc.
  ///
  /// In en, this message translates to:
  /// **'Encrypted data and automatic backup of all reservations'**
  String get icalSecureDesc;

  /// No description provided for @icalErrorLoadingFeeds.
  ///
  /// In en, this message translates to:
  /// **'Error loading feeds'**
  String get icalErrorLoadingFeeds;

  /// No description provided for @icalNoFeedsTitle.
  ///
  /// In en, this message translates to:
  /// **'No iCal Feeds'**
  String get icalNoFeedsTitle;

  /// No description provided for @icalNoFeedsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an iCal feed to synchronize reservations with booking platforms'**
  String get icalNoFeedsSubtitle;

  /// No description provided for @icalAddFeed.
  ///
  /// In en, this message translates to:
  /// **'Add iCal Feed'**
  String get icalAddFeed;

  /// No description provided for @icalAddFeedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect calendar with Booking.com, Airbnb or other platforms'**
  String get icalAddFeedSubtitle;

  /// No description provided for @icalAddFeedButton.
  ///
  /// In en, this message translates to:
  /// **'Add Feed'**
  String get icalAddFeedButton;

  /// No description provided for @icalYourFeeds.
  ///
  /// In en, this message translates to:
  /// **'Your Feeds'**
  String get icalYourFeeds;

  /// No description provided for @icalLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String icalLastSynced(String time);

  /// No description provided for @icalErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String icalErrorPrefix(String error);

  /// No description provided for @icalReservationsAndSyncs.
  ///
  /// In en, this message translates to:
  /// **'{reservations} reservations • {syncs} syncs'**
  String icalReservationsAndSyncs(int reservations, int syncs);

  /// No description provided for @icalPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get icalPause;

  /// No description provided for @icalResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get icalResume;

  /// No description provided for @icalHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How does iCal synchronization work?'**
  String get icalHowItWorks;

  /// No description provided for @icalSyncErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error during synchronization'**
  String get icalSyncErrorMessage;

  /// No description provided for @icalUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get icalUnknownError;

  /// No description provided for @icalFeedPaused.
  ///
  /// In en, this message translates to:
  /// **'Feed paused'**
  String get icalFeedPaused;

  /// No description provided for @icalFeedPauseError.
  ///
  /// In en, this message translates to:
  /// **'Error pausing feed'**
  String get icalFeedPauseError;

  /// No description provided for @icalFeedResumed.
  ///
  /// In en, this message translates to:
  /// **'Feed resumed'**
  String get icalFeedResumed;

  /// No description provided for @icalFeedResumeError.
  ///
  /// In en, this message translates to:
  /// **'Error resuming feed'**
  String get icalFeedResumeError;

  /// No description provided for @icalDeleteFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Feed?'**
  String get icalDeleteFeedTitle;

  /// No description provided for @icalDeleteFeedMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {platform} feed? This action will delete {count} synchronized reservations.'**
  String icalDeleteFeedMessage(String platform, int count);

  /// No description provided for @icalFeedDeleted.
  ///
  /// In en, this message translates to:
  /// **'Feed deleted'**
  String get icalFeedDeleted;

  /// No description provided for @icalFeedDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting feed'**
  String get icalFeedDeleteError;

  /// No description provided for @icalAddFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add iCal Feed'**
  String get icalAddFeedTitle;

  /// No description provided for @icalEditFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit iCal Feed'**
  String get icalEditFeedTitle;

  /// No description provided for @icalSelectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select unit *'**
  String get icalSelectUnit;

  /// No description provided for @icalSelectUnitRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a unit'**
  String get icalSelectUnitRequired;

  /// No description provided for @icalNoUnitsCreated.
  ///
  /// In en, this message translates to:
  /// **'You have no units created. First create an apartment.'**
  String get icalNoUnitsCreated;

  /// No description provided for @icalErrorLoadingUnits.
  ///
  /// In en, this message translates to:
  /// **'Error loading units'**
  String get icalErrorLoadingUnits;

  /// No description provided for @icalPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform *'**
  String get icalPlatform;

  /// No description provided for @icalPlatformBookingCom.
  ///
  /// In en, this message translates to:
  /// **'Booking.com'**
  String get icalPlatformBookingCom;

  /// No description provided for @icalPlatformAirbnb.
  ///
  /// In en, this message translates to:
  /// **'Airbnb'**
  String get icalPlatformAirbnb;

  /// No description provided for @icalPlatformOther.
  ///
  /// In en, this message translates to:
  /// **'Other platform (iCal)'**
  String get icalPlatformOther;

  /// No description provided for @icalUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'iCal URL *'**
  String get icalUrlLabel;

  /// No description provided for @icalUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get icalUrlHint;

  /// No description provided for @icalPasteFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste from clipboard'**
  String get icalPasteFromClipboard;

  /// No description provided for @icalUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter iCal URL'**
  String get icalUrlRequired;

  /// No description provided for @icalUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get icalUrlInvalid;

  /// No description provided for @icalAutoSyncInfo.
  ///
  /// In en, this message translates to:
  /// **'Automatic synchronization'**
  String get icalAutoSyncInfo;

  /// No description provided for @icalAutoSyncInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Reservations will be automatically synchronized every 60 minutes. Initial synchronization will start immediately after adding.'**
  String get icalAutoSyncInfoDesc;

  /// No description provided for @icalAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get icalAdd;

  /// No description provided for @icalInitialSyncStarting.
  ///
  /// In en, this message translates to:
  /// **'Feed successfully added! Starting initial synchronization...'**
  String get icalInitialSyncStarting;

  /// No description provided for @icalInitialSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Initial synchronization completed! Imported: {count} reservations'**
  String icalInitialSyncSuccess(int count);

  /// No description provided for @icalInitialSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Feed added, but initial synchronization failed. Synchronization will automatically start in 60 minutes.'**
  String get icalInitialSyncFailed;

  /// No description provided for @icalInitialSyncError.
  ///
  /// In en, this message translates to:
  /// **'Feed added, but automatic synchronization failed. You can manually start synchronization later.'**
  String get icalInitialSyncError;

  /// No description provided for @icalFeedUpdated.
  ///
  /// In en, this message translates to:
  /// **'Feed updated'**
  String get icalFeedUpdated;

  /// No description provided for @icalFeedSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving feed'**
  String get icalFeedSaveError;

  /// No description provided for @icalGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'iCal Synchronization - Guide'**
  String get icalGuideTitle;

  /// No description provided for @icalGuideHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'iCal Synchronization'**
  String get icalGuideHeaderTitle;

  /// No description provided for @icalGuideHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic sync of reservations from Booking.com, Airbnb and other platforms'**
  String get icalGuideHeaderSubtitle;

  /// No description provided for @icalGuideHeaderTip.
  ///
  /// In en, this message translates to:
  /// **'💡 iCal synchronization prevents overbooking by automatically importing reservations from other platforms and displaying them as occupied days in your calendar.'**
  String get icalGuideHeaderTip;

  /// No description provided for @icalGuideBookingComSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps to get iCal URL:'**
  String get icalGuideBookingComSteps;

  /// No description provided for @icalGuideBookingCom1.
  ///
  /// In en, this message translates to:
  /// **'1. Log in to Extranet (admin.booking.com)'**
  String get icalGuideBookingCom1;

  /// No description provided for @icalGuideBookingCom2.
  ///
  /// In en, this message translates to:
  /// **'2. Go to: Property → Calendar → Reservations export'**
  String get icalGuideBookingCom2;

  /// No description provided for @icalGuideBookingCom3.
  ///
  /// In en, this message translates to:
  /// **'3. Copy \"Calendar export link\" (iCal URL)'**
  String get icalGuideBookingCom3;

  /// No description provided for @icalGuideBookingCom4.
  ///
  /// In en, this message translates to:
  /// **'4. Paste in Owner app'**
  String get icalGuideBookingCom4;

  /// No description provided for @icalGuideAirbnb1.
  ///
  /// In en, this message translates to:
  /// **'1. Log in to Airbnb host dashboard'**
  String get icalGuideAirbnb1;

  /// No description provided for @icalGuideAirbnb2.
  ///
  /// In en, this message translates to:
  /// **'2. Select property (listing)'**
  String get icalGuideAirbnb2;

  /// No description provided for @icalGuideAirbnb3.
  ///
  /// In en, this message translates to:
  /// **'3. Go to: Calendar → Availability settings → Export calendar'**
  String get icalGuideAirbnb3;

  /// No description provided for @icalGuideAirbnb4.
  ///
  /// In en, this message translates to:
  /// **'4. Copy iCal link'**
  String get icalGuideAirbnb4;

  /// No description provided for @icalGuideAirbnb5.
  ///
  /// In en, this message translates to:
  /// **'5. Paste in Owner app'**
  String get icalGuideAirbnb5;

  /// No description provided for @icalGuideAddFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Adding iCal Feed in Owner App'**
  String get icalGuideAddFeedTitle;

  /// No description provided for @icalGuideStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Open iCal Synchronization'**
  String get icalGuideStep1Title;

  /// No description provided for @icalGuideStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'In Owner app:'**
  String get icalGuideStep1Desc;

  /// No description provided for @icalGuideStep1Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Open drawer (hamburger menu)'**
  String get icalGuideStep1Bullet1;

  /// No description provided for @icalGuideStep1Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Go to: Integrations → iCal Synchronization'**
  String get icalGuideStep1Bullet2;

  /// No description provided for @icalGuideStep1Button.
  ///
  /// In en, this message translates to:
  /// **'Go to iCal Synchronization'**
  String get icalGuideStep1Button;

  /// No description provided for @icalGuideStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Add new Feed'**
  String get icalGuideStep2Title;

  /// No description provided for @icalGuideStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Click on \"Add iCal Feed\" button:'**
  String get icalGuideStep2Desc;

  /// No description provided for @icalGuideStep2Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Select Unit (apartment) for sync'**
  String get icalGuideStep2Bullet1;

  /// No description provided for @icalGuideStep2Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Select platform (Booking.com, Airbnb, etc.)'**
  String get icalGuideStep2Bullet2;

  /// No description provided for @icalGuideStep2Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Paste iCal URL you copied'**
  String get icalGuideStep2Bullet3;

  /// No description provided for @icalGuideStep2Bullet4.
  ///
  /// In en, this message translates to:
  /// **'Click \"Add\"'**
  String get icalGuideStep2Bullet4;

  /// No description provided for @icalGuideStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Start Sync'**
  String get icalGuideStep3Title;

  /// No description provided for @icalGuideStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'After adding feed:'**
  String get icalGuideStep3Desc;

  /// No description provided for @icalGuideStep3Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Click \"Sync Now\" button next to feed'**
  String get icalGuideStep3Bullet1;

  /// No description provided for @icalGuideStep3Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Wait a few seconds'**
  String get icalGuideStep3Bullet2;

  /// No description provided for @icalGuideStep3Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Check status (Active ✓)'**
  String get icalGuideStep3Bullet3;

  /// No description provided for @icalGuideStep3Success.
  ///
  /// In en, this message translates to:
  /// **'Done! Reservations from other platforms will automatically appear as occupied days.'**
  String get icalGuideStep3Success;

  /// No description provided for @icalGuideStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Automatic Synchronization'**
  String get icalGuideStep4Title;

  /// No description provided for @icalGuideStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'System automatically synchronizes reservations:'**
  String get icalGuideStep4Desc;

  /// No description provided for @icalGuideStep4Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Automatic sync runs every hour'**
  String get icalGuideStep4Bullet1;

  /// No description provided for @icalGuideStep4Bullet2.
  ///
  /// In en, this message translates to:
  /// **'New reservations appear within 1h'**
  String get icalGuideStep4Bullet2;

  /// No description provided for @icalGuideStep4Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Cancelled reservations are removed'**
  String get icalGuideStep4Bullet3;

  /// No description provided for @icalGuideStep4Bullet4.
  ///
  /// In en, this message translates to:
  /// **'You can manually start sync anytime'**
  String get icalGuideStep4Bullet4;

  /// No description provided for @icalGuideStep4Info.
  ///
  /// In en, this message translates to:
  /// **'Sync time: Every hour at 00 minutes (e.g. 10:00, 11:00, 12:00...)'**
  String get icalGuideStep4Info;

  /// No description provided for @icalGuideFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get icalGuideFaqTitle;

  /// No description provided for @icalGuideFaq1Q.
  ///
  /// In en, this message translates to:
  /// **'How often does it sync?'**
  String get icalGuideFaq1Q;

  /// No description provided for @icalGuideFaq1A.
  ///
  /// In en, this message translates to:
  /// **'Automatic sync runs every hour. You can manually start sync anytime by clicking \"Sync Now\".'**
  String get icalGuideFaq1A;

  /// No description provided for @icalGuideFaq2Q.
  ///
  /// In en, this message translates to:
  /// **'Will guests see reservations from other platforms?'**
  String get icalGuideFaq2Q;

  /// No description provided for @icalGuideFaq2A.
  ///
  /// In en, this message translates to:
  /// **'Yes! Reservations imported via iCal will be shown as occupied days in embed widget, preventing overbooking.'**
  String get icalGuideFaq2A;

  /// No description provided for @icalGuideFaq3Q.
  ///
  /// In en, this message translates to:
  /// **'Can I add multiple feeds for same apartment?'**
  String get icalGuideFaq3Q;

  /// No description provided for @icalGuideFaq3A.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can add feeds from multiple platforms (Booking.com, Airbnb, or any other iCal platform) for same unit. All reservations will be synchronized.'**
  String get icalGuideFaq3A;

  /// No description provided for @icalGuideFaq4Q.
  ///
  /// In en, this message translates to:
  /// **'Can I see guest details from other platforms?'**
  String get icalGuideFaq4Q;

  /// No description provided for @icalGuideFaq4A.
  ///
  /// In en, this message translates to:
  /// **'No. iCal protocol only transfers reservation dates (check-in and check-out), not personal guest data. For guest details, you must log in to the respective platform.'**
  String get icalGuideFaq4A;

  /// No description provided for @icalGuideFaq5Q.
  ///
  /// In en, this message translates to:
  /// **'What if URL stops working?'**
  String get icalGuideFaq5Q;

  /// No description provided for @icalGuideFaq5A.
  ///
  /// In en, this message translates to:
  /// **'If URL changes, simply update feed in app. Delete old feed and add new one with updated URL.'**
  String get icalGuideFaq5A;

  /// No description provided for @icalGuideTroubleshootTitle.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get icalGuideTroubleshootTitle;

  /// No description provided for @icalGuideTrouble1Problem.
  ///
  /// In en, this message translates to:
  /// **'Feed has \"Error\" status'**
  String get icalGuideTrouble1Problem;

  /// No description provided for @icalGuideTrouble1Solution.
  ///
  /// In en, this message translates to:
  /// **'• Check if URL is correct\n• Check if URL is still active on platform\n• Delete feed and add again with new URL'**
  String get icalGuideTrouble1Solution;

  /// No description provided for @icalGuideTrouble2Problem.
  ///
  /// In en, this message translates to:
  /// **'Reservations not showing'**
  String get icalGuideTrouble2Problem;

  /// No description provided for @icalGuideTrouble2Solution.
  ///
  /// In en, this message translates to:
  /// **'• Click \"Sync Now\" to manually start sync\n• Check if you selected correct unit\n• Wait a few minutes and refresh page'**
  String get icalGuideTrouble2Solution;

  /// No description provided for @icalGuideTrouble3Problem.
  ///
  /// In en, this message translates to:
  /// **'Old reservations still showing'**
  String get icalGuideTrouble3Problem;

  /// No description provided for @icalGuideTrouble3Solution.
  ///
  /// In en, this message translates to:
  /// **'• iCal sync automatically removes past reservations\n• Click \"Sync Now\" to force update'**
  String get icalGuideTrouble3Solution;

  /// No description provided for @stripeGuideStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t have a Stripe account yet, you need to create one:'**
  String get stripeGuideStep1Desc;

  /// No description provided for @stripeGuideStep1Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Go to Stripe.com'**
  String get stripeGuideStep1Bullet1;

  /// No description provided for @stripeGuideStep1Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Click on \"Sign up\" or \"Start now\"'**
  String get stripeGuideStep1Bullet2;

  /// No description provided for @stripeGuideStep1Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Enter email, name and password'**
  String get stripeGuideStep1Bullet3;

  /// No description provided for @stripeGuideStep1Bullet4.
  ///
  /// In en, this message translates to:
  /// **'Verify email address'**
  String get stripeGuideStep1Bullet4;

  /// No description provided for @stripeGuideStep1Note.
  ///
  /// In en, this message translates to:
  /// **'Note: Stripe is free to register. It only charges a commission per transaction (about 1.4% + €0.25).'**
  String get stripeGuideStep1Note;

  /// No description provided for @stripeGuideStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'After registration, Stripe will ask for additional information:'**
  String get stripeGuideStep2Desc;

  /// No description provided for @stripeGuideStep2Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Business type (Individual or Company)'**
  String get stripeGuideStep2Bullet1;

  /// No description provided for @stripeGuideStep2Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Personal information (name, surname, date of birth)'**
  String get stripeGuideStep2Bullet2;

  /// No description provided for @stripeGuideStep2Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Residential address'**
  String get stripeGuideStep2Bullet3;

  /// No description provided for @stripeGuideStep2Bullet4.
  ///
  /// In en, this message translates to:
  /// **'Bank account for payouts (IBAN)'**
  String get stripeGuideStep2Bullet4;

  /// No description provided for @stripeGuideStep2Bullet5.
  ///
  /// In en, this message translates to:
  /// **'Tax identification (OIB in Croatia)'**
  String get stripeGuideStep2Bullet5;

  /// No description provided for @stripeGuideStep2Warning.
  ///
  /// In en, this message translates to:
  /// **'Important: Enter accurate data. Stripe verifies identity for security and legal compliance.'**
  String get stripeGuideStep2Warning;

  /// No description provided for @stripeGuideStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Return to Owner app and connect your Stripe account:'**
  String get stripeGuideStep3Desc;

  /// No description provided for @stripeGuideStep3Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Open drawer (hamburger menu)'**
  String get stripeGuideStep3Bullet1;

  /// No description provided for @stripeGuideStep3Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Go to: Integrations → Stripe Payments'**
  String get stripeGuideStep3Bullet2;

  /// No description provided for @stripeGuideStep3Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Click \"Connect Stripe Account\"'**
  String get stripeGuideStep3Bullet3;

  /// No description provided for @stripeGuideStep3Bullet4.
  ///
  /// In en, this message translates to:
  /// **'Log in with your Stripe email/password'**
  String get stripeGuideStep3Bullet4;

  /// No description provided for @stripeGuideStep3Bullet5.
  ///
  /// In en, this message translates to:
  /// **'Approve access'**
  String get stripeGuideStep3Bullet5;

  /// No description provided for @stripeGuideStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'After connecting Stripe, enable it for each unit:'**
  String get stripeGuideStep4Desc;

  /// No description provided for @stripeGuideStep4Bullet1.
  ///
  /// In en, this message translates to:
  /// **'Go to Configuration → Accommodation Units'**
  String get stripeGuideStep4Bullet1;

  /// No description provided for @stripeGuideStep4Bullet2.
  ///
  /// In en, this message translates to:
  /// **'Click \"Edit\" on unit'**
  String get stripeGuideStep4Bullet2;

  /// No description provided for @stripeGuideStep4Bullet3.
  ///
  /// In en, this message translates to:
  /// **'Click \"Widget Settings\"'**
  String get stripeGuideStep4Bullet3;

  /// No description provided for @stripeGuideStep4Bullet4.
  ///
  /// In en, this message translates to:
  /// **'Enable \"Stripe Payment\" toggle'**
  String get stripeGuideStep4Bullet4;

  /// No description provided for @stripeGuideStep4Bullet5.
  ///
  /// In en, this message translates to:
  /// **'Set deposit percentage (default: 20%)'**
  String get stripeGuideStep4Bullet5;

  /// No description provided for @stripeGuideStep4Bullet6.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get stripeGuideStep4Bullet6;

  /// No description provided for @stripeGuideStep4Success.
  ///
  /// In en, this message translates to:
  /// **'Done! Now guests can pay by card through widget.'**
  String get stripeGuideStep4Success;

  /// No description provided for @stripeGuideFaq1Q.
  ///
  /// In en, this message translates to:
  /// **'How much does Stripe cost?'**
  String get stripeGuideFaq1Q;

  /// No description provided for @stripeGuideFaq1A.
  ///
  /// In en, this message translates to:
  /// **'Stripe doesn\'t charge a monthly subscription. Commission is 1.4% + €0.25 per successful transaction within EU. For cards outside EU, commission is 2.9% + €0.25.'**
  String get stripeGuideFaq1A;

  /// No description provided for @stripeGuideFaq2Q.
  ///
  /// In en, this message translates to:
  /// **'When do payouts arrive to my account?'**
  String get stripeGuideFaq2Q;

  /// No description provided for @stripeGuideFaq2A.
  ///
  /// In en, this message translates to:
  /// **'Stripe by default transfers funds to your bank account every 7 days. After the first month, you can change to daily payouts.'**
  String get stripeGuideFaq2A;

  /// No description provided for @stripeGuideFaq3Q.
  ///
  /// In en, this message translates to:
  /// **'Can I receive payments in different currencies?'**
  String get stripeGuideFaq3Q;

  /// No description provided for @stripeGuideFaq3A.
  ///
  /// In en, this message translates to:
  /// **'Yes, Stripe supports 135+ currencies. However, payouts will be in EUR (your primary currency).'**
  String get stripeGuideFaq3A;

  /// No description provided for @stripeGuideFaq4Q.
  ///
  /// In en, this message translates to:
  /// **'What if a guest makes a chargeback?'**
  String get stripeGuideFaq4Q;

  /// No description provided for @stripeGuideFaq4A.
  ///
  /// In en, this message translates to:
  /// **'Stripe automatically handles chargebacks. You will be notified by email and can submit evidence (booking confirmation, email communication). Chargeback fee is €15.'**
  String get stripeGuideFaq4A;

  /// No description provided for @stripeGuideFaq5Q.
  ///
  /// In en, this message translates to:
  /// **'Can I test before activation?'**
  String get stripeGuideFaq5Q;

  /// No description provided for @stripeGuideFaq5A.
  ///
  /// In en, this message translates to:
  /// **'Yes! Stripe has test mode where you can simulate payments. Use test cards that Stripe provides for testing.'**
  String get stripeGuideFaq5A;

  /// No description provided for @termsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsScreenTitle;

  /// No description provided for @termsScreenHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsScreenHeaderTitle;

  /// No description provided for @termsScreenLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {year}'**
  String termsScreenLastUpdated(String year);

  /// No description provided for @termsScreenToc.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get termsScreenToc;

  /// No description provided for @termsScreenSection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get termsScreenSection1Title;

  /// No description provided for @termsScreenSection1Body.
  ///
  /// In en, this message translates to:
  /// **'By accessing and using this booking platform (\"Service\"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.'**
  String get termsScreenSection1Body;

  /// No description provided for @termsScreenSection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Use License'**
  String get termsScreenSection2Title;

  /// No description provided for @termsScreenSection2Body.
  ///
  /// In en, this message translates to:
  /// **'Permission is granted to temporarily use this Service for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose\n• Attempt to decompile or reverse engineer any software contained on the Service\n• Remove any copyright or other proprietary notations from the materials'**
  String get termsScreenSection2Body;

  /// No description provided for @termsScreenSection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Booking Policy'**
  String get termsScreenSection3Title;

  /// No description provided for @termsScreenSection3Body.
  ///
  /// In en, this message translates to:
  /// **'All bookings made through this platform are subject to the following terms:\n\n• A deposit of 20% is required at the time of booking\n• The remaining 80% is due upon arrival at the property\n• Cancellation policies vary by property and will be clearly displayed before booking\n• You must be at least 18 years old to make a booking'**
  String get termsScreenSection3Body;

  /// No description provided for @termsScreenSection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Payment Terms'**
  String get termsScreenSection4Title;

  /// No description provided for @termsScreenSection4Body.
  ///
  /// In en, this message translates to:
  /// **'We accept the following payment methods:\n\n• Credit/Debit Cards (processed securely via Stripe)\n• Bank Transfer\n\nAll payments are processed securely. We do not store your payment card information.'**
  String get termsScreenSection4Body;

  /// No description provided for @termsScreenSection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Cancellation & Refund Policy'**
  String get termsScreenSection5Title;

  /// No description provided for @termsScreenSection5Body.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policies are set by individual property owners. Please review the specific cancellation policy for your booking before confirming. Refunds will be processed according to the property\'s cancellation policy.'**
  String get termsScreenSection5Body;

  /// No description provided for @termsScreenSection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. User Responsibilities'**
  String get termsScreenSection6Title;

  /// No description provided for @termsScreenSection6Body.
  ///
  /// In en, this message translates to:
  /// **'You agree to:\n\n• Provide accurate and complete information when making a booking\n• Comply with the property rules and regulations\n• Respect the property and other guests\n• Pay for any damages caused during your stay'**
  String get termsScreenSection6Body;

  /// No description provided for @termsScreenSection7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Limitation of Liability'**
  String get termsScreenSection7Title;

  /// No description provided for @termsScreenSection7Body.
  ///
  /// In en, this message translates to:
  /// **'The Service and its owners shall not be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.'**
  String get termsScreenSection7Body;

  /// No description provided for @termsScreenSection8Title.
  ///
  /// In en, this message translates to:
  /// **'8. Modifications to Terms'**
  String get termsScreenSection8Title;

  /// No description provided for @termsScreenSection8Body.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify these terms at any time. We will notify users of any material changes by updating the \"Last updated\" date. Your continued use of the Service after such modifications constitutes your acceptance of the updated terms.'**
  String get termsScreenSection8Body;

  /// No description provided for @termsScreenSection9Title.
  ///
  /// In en, this message translates to:
  /// **'9. Governing Law'**
  String get termsScreenSection9Title;

  /// No description provided for @termsScreenSection9Body.
  ///
  /// In en, this message translates to:
  /// **'These terms shall be governed by and construed in accordance with the laws of Croatia, without regard to its conflict of law provisions.'**
  String get termsScreenSection9Body;

  /// No description provided for @termsScreenSection10Title.
  ///
  /// In en, this message translates to:
  /// **'10. Contact Information'**
  String get termsScreenSection10Title;

  /// No description provided for @termsScreenSection10Body.
  ///
  /// In en, this message translates to:
  /// **'For questions about these Terms, please contact us at:\n\nEmail: duskolicanin1234@gmail.com\nAddress: [Your Company Address]\n\n⚠️ NOTE: Update this contact information with your actual details.'**
  String get termsScreenSection10Body;

  /// No description provided for @termsScreenLegalNotice.
  ///
  /// In en, this message translates to:
  /// **'Legal Notice'**
  String get termsScreenLegalNotice;

  /// No description provided for @termsScreenLegalNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'This is a template document. Please consult with a legal advisor to ensure compliance with Croatian and EU laws, including GDPR regulations.'**
  String get termsScreenLegalNoticeBody;

  /// No description provided for @privacyScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyScreenTitle;

  /// No description provided for @privacyScreenHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyScreenHeaderTitle;

  /// No description provided for @privacyScreenLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {year}'**
  String privacyScreenLastUpdated(String year);

  /// No description provided for @privacyScreenToc.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get privacyScreenToc;

  /// No description provided for @privacyScreenSection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Introduction'**
  String get privacyScreenSection1Title;

  /// No description provided for @privacyScreenSection1Body.
  ///
  /// In en, this message translates to:
  /// **'This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our booking platform. This policy complies with the EU General Data Protection Regulation (GDPR) and Croatian data protection laws.\n\nBy using our Service, you agree to the collection and use of information in accordance with this policy.'**
  String get privacyScreenSection1Body;

  /// No description provided for @privacyScreenSection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Information We Collect'**
  String get privacyScreenSection2Title;

  /// No description provided for @privacyScreenSection2Body.
  ///
  /// In en, this message translates to:
  /// **'We collect the following types of information:\n\n**Personal Information:**\n• Name and contact information (email, phone number)\n• Billing and payment information\n• Booking history and preferences\n• Communication records\n\n**Technical Information:**\n• IP address and browser type\n• Device information\n• Cookies and usage data\n• Location data (if you enable it)'**
  String get privacyScreenSection2Body;

  /// No description provided for @privacyScreenSection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Legal Basis for Processing (GDPR)'**
  String get privacyScreenSection3Title;

  /// No description provided for @privacyScreenSection3Body.
  ///
  /// In en, this message translates to:
  /// **'We process your personal data under the following legal bases:\n\n• **Contract Performance:** To fulfill booking agreements\n• **Legitimate Interest:** To improve our services and prevent fraud\n• **Consent:** For marketing communications (you can opt-out anytime)\n• **Legal Obligation:** To comply with tax and accounting requirements'**
  String get privacyScreenSection3Body;

  /// No description provided for @privacyScreenSection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. How We Use Your Information'**
  String get privacyScreenSection4Title;

  /// No description provided for @privacyScreenSection4Body.
  ///
  /// In en, this message translates to:
  /// **'We use your information to:\n\n• Process and manage your bookings\n• Send booking confirmations and updates\n• Process payments securely\n• Provide customer support\n• Improve our services\n• Send promotional communications (with your consent)\n• Comply with legal obligations'**
  String get privacyScreenSection4Body;

  /// No description provided for @privacyScreenSection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Information Sharing'**
  String get privacyScreenSection5Title;

  /// No description provided for @privacyScreenSection5Body.
  ///
  /// In en, this message translates to:
  /// **'We share your information only in the following circumstances:\n\n• **Property Owners:** To facilitate your booking\n• **Payment Processors:** Stripe for secure payment processing\n• **Email Service:** Resend for transactional emails\n• **Legal Requirements:** When required by law\n\nWe do NOT sell your personal information to third parties.'**
  String get privacyScreenSection5Body;

  /// No description provided for @privacyScreenSection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Data Storage and Security'**
  String get privacyScreenSection6Title;

  /// No description provided for @privacyScreenSection6Body.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored securely using Firebase (Google Cloud Platform) with servers located in the EU. We implement industry-standard security measures including:\n\n• Encryption in transit and at rest\n• Regular security audits\n• Access controls and authentication\n• Secure payment processing via Stripe (PCI DSS compliant)'**
  String get privacyScreenSection6Body;

  /// No description provided for @privacyScreenSection7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Data Retention'**
  String get privacyScreenSection7Title;

  /// No description provided for @privacyScreenSection7Body.
  ///
  /// In en, this message translates to:
  /// **'We retain your personal data for as long as necessary to:\n\n• Fulfill the purposes outlined in this policy\n• Comply with legal obligations (tax records: 7 years)\n• Resolve disputes and enforce agreements\n\nAfter this period, your data will be securely deleted or anonymized.'**
  String get privacyScreenSection7Body;

  /// No description provided for @privacyScreenSection8Title.
  ///
  /// In en, this message translates to:
  /// **'8. Your GDPR Rights'**
  String get privacyScreenSection8Title;

  /// No description provided for @privacyScreenSection8Body.
  ///
  /// In en, this message translates to:
  /// **'Under GDPR, you have the right to:\n\n• **Access:** Request a copy of your personal data\n• **Rectification:** Correct inaccurate data\n• **Erasure:** Request deletion of your data (\"right to be forgotten\")\n• **Restriction:** Limit how we process your data\n• **Portability:** Receive your data in a structured format\n• **Object:** Object to processing based on legitimate interests\n• **Withdraw Consent:** Opt-out of marketing communications\n\nTo exercise these rights, contact us at: duskolicanin1234@gmail.com'**
  String get privacyScreenSection8Body;

  /// No description provided for @privacyScreenSection9Title.
  ///
  /// In en, this message translates to:
  /// **'9. Cookies'**
  String get privacyScreenSection9Title;

  /// No description provided for @privacyScreenSection9Body.
  ///
  /// In en, this message translates to:
  /// **'We use cookies and similar technologies to:\n\n• Remember your preferences\n• Analyze usage patterns\n• Improve user experience\n\nYou can control cookies through your browser settings. Note that disabling cookies may affect functionality.'**
  String get privacyScreenSection9Body;

  /// No description provided for @privacyScreenSection10Title.
  ///
  /// In en, this message translates to:
  /// **'10. International Data Transfers'**
  String get privacyScreenSection10Title;

  /// No description provided for @privacyScreenSection10Body.
  ///
  /// In en, this message translates to:
  /// **'Your data is primarily stored within the EU. If we transfer data outside the EU, we ensure adequate safeguards are in place (e.g., Standard Contractual Clauses).'**
  String get privacyScreenSection10Body;

  /// No description provided for @privacyScreenSection11Title.
  ///
  /// In en, this message translates to:
  /// **'11. Children\'s Privacy'**
  String get privacyScreenSection11Title;

  /// No description provided for @privacyScreenSection11Body.
  ///
  /// In en, this message translates to:
  /// **'Our Service is not intended for users under 18 years of age. We do not knowingly collect personal information from children. If you believe we have collected data from a child, please contact us immediately.'**
  String get privacyScreenSection11Body;

  /// No description provided for @privacyScreenSection12Title.
  ///
  /// In en, this message translates to:
  /// **'12. Changes to This Policy'**
  String get privacyScreenSection12Title;

  /// No description provided for @privacyScreenSection12Body.
  ///
  /// In en, this message translates to:
  /// **'We may update this Privacy Policy from time to time. We will notify you of any material changes by updating the \"Last updated\" date and, where appropriate, by email.'**
  String get privacyScreenSection12Body;

  /// No description provided for @privacyScreenSection13Title.
  ///
  /// In en, this message translates to:
  /// **'13. Data Protection Officer'**
  String get privacyScreenSection13Title;

  /// No description provided for @privacyScreenSection13Body.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about this Privacy Policy or wish to exercise your GDPR rights, contact:\n\n**Data Protection Officer**\nEmail: duskolicanin1234@gmail.com\nAddress: [Your Company Address]\n\n⚠️ NOTE: Update this contact information with your actual DPO details.'**
  String get privacyScreenSection13Body;

  /// No description provided for @privacyScreenSection14Title.
  ///
  /// In en, this message translates to:
  /// **'14. Supervisory Authority'**
  String get privacyScreenSection14Title;

  /// No description provided for @privacyScreenSection14Body.
  ///
  /// In en, this message translates to:
  /// **'You have the right to lodge a complaint with the Croatian Data Protection Authority (AZOP) if you believe we have violated your privacy rights:\n\nAgencija za zaštitu osobnih podataka (AZOP)\nSelska cesta 136, 10000 Zagreb\nWebsite: azop.hr'**
  String get privacyScreenSection14Body;

  /// No description provided for @privacyScreenGdprNotice.
  ///
  /// In en, this message translates to:
  /// **'GDPR Compliance Notice'**
  String get privacyScreenGdprNotice;

  /// No description provided for @privacyScreenGdprNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'This privacy policy template is designed to comply with GDPR requirements. However, you should have it reviewed by a legal professional to ensure full compliance with your specific data processing activities.'**
  String get privacyScreenGdprNoticeBody;

  /// No description provided for @cookiesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookies Policy'**
  String get cookiesScreenTitle;

  /// No description provided for @cookiesScreenHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookies Policy'**
  String get cookiesScreenHeaderTitle;

  /// No description provided for @cookiesScreenLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String cookiesScreenLastUpdated(String date);

  /// No description provided for @cookiesScreenToc.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get cookiesScreenToc;

  /// No description provided for @cookiesScreenSection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. What Are Cookies?'**
  String get cookiesScreenSection1Title;

  /// No description provided for @cookiesScreenSection1Body.
  ///
  /// In en, this message translates to:
  /// **'Cookies are small text files that are placed on your device when you visit our website. They help us provide you with a better experience by remembering your preferences and understanding how you use our service.'**
  String get cookiesScreenSection1Body;

  /// No description provided for @cookiesScreenSection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. How We Use Cookies'**
  String get cookiesScreenSection2Title;

  /// No description provided for @cookiesScreenSection2Body.
  ///
  /// In en, this message translates to:
  /// **'We use cookies for the following purposes:\n\n• **Essential Cookies:** Required for the website to function properly (e.g., authentication, security)\n• **Preference Cookies:** Remember your settings and preferences (e.g., language, theme)\n• **Analytics Cookies:** Help us understand how visitors interact with our website (e.g., Google Analytics)\n• **Marketing Cookies:** Used to track visitors across websites to display relevant advertisements\n\nCurrently, we primarily use essential and preference cookies to ensure the basic functionality of our booking platform.'**
  String get cookiesScreenSection2Body;

  /// No description provided for @cookiesScreenSection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Types of Cookies We Use'**
  String get cookiesScreenSection3Title;

  /// No description provided for @cookiesScreenSection3Body.
  ///
  /// In en, this message translates to:
  /// **'**Session Cookies:** Temporary cookies that expire when you close your browser. These are essential for authentication and navigation.\n\n**Persistent Cookies:** Remain on your device for a set period or until you delete them. These remember your preferences across visits.\n\n**Third-Party Cookies:** Set by external services we use (e.g., payment processors, analytics providers).'**
  String get cookiesScreenSection3Body;

  /// No description provided for @cookiesScreenSection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Your Cookie Choices'**
  String get cookiesScreenSection4Title;

  /// No description provided for @cookiesScreenSection4Body.
  ///
  /// In en, this message translates to:
  /// **'You have several options to manage cookies:\n\n• **Browser Settings:** Most browsers allow you to refuse or delete cookies. Check your browser\'s help section for instructions.\n• **Opt-Out Links:** Some third-party services provide opt-out mechanisms for their cookies.\n• **Cookie Preferences:** We may provide a cookie consent banner where you can customize your preferences.\n\n⚠️ **Note:** Disabling certain cookies may affect the functionality of our website, particularly features like login and booking management.'**
  String get cookiesScreenSection4Body;

  /// No description provided for @cookiesScreenSection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Third-Party Cookies'**
  String get cookiesScreenSection5Title;

  /// No description provided for @cookiesScreenSection5Body.
  ///
  /// In en, this message translates to:
  /// **'We use the following third-party services that may set cookies:\n\n• **Firebase (Google):** For authentication and database services\n• **Stripe:** For secure payment processing\n• **Resend:** For email delivery\n\nThese services have their own privacy policies and cookie policies. We recommend reviewing their policies for more information.'**
  String get cookiesScreenSection5Body;

  /// No description provided for @cookiesScreenSection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Updates to This Policy'**
  String get cookiesScreenSection6Title;

  /// No description provided for @cookiesScreenSection6Body.
  ///
  /// In en, this message translates to:
  /// **'We may update this Cookies Policy from time to time to reflect changes in our practices or legal requirements. The \"Last updated\" date at the top indicates when the policy was last revised.'**
  String get cookiesScreenSection6Body;

  /// No description provided for @cookiesScreenSection7Title.
  ///
  /// In en, this message translates to:
  /// **'7. More Information'**
  String get cookiesScreenSection7Title;

  /// No description provided for @cookiesScreenSection7Body.
  ///
  /// In en, this message translates to:
  /// **'For more detailed information about how we handle your personal data, including cookies, please review our full Privacy Policy.\n\nIf you have questions about our use of cookies, please contact us at:\n\nEmail: duskolicanin1234@gmail.com'**
  String get cookiesScreenSection7Body;

  /// No description provided for @cookiesScreenPrivacyLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Privacy Policy'**
  String get cookiesScreenPrivacyLinkTitle;

  /// No description provided for @cookiesScreenPrivacyLinkBody.
  ///
  /// In en, this message translates to:
  /// **'For comprehensive information about data collection, processing, and your rights under GDPR, please read our full Privacy Policy.'**
  String get cookiesScreenPrivacyLinkBody;

  /// No description provided for @cookiesScreenPrivacyLinkButton.
  ///
  /// In en, this message translates to:
  /// **'View Privacy Policy'**
  String get cookiesScreenPrivacyLinkButton;

  /// No description provided for @cookiesScreenLegalNotice.
  ///
  /// In en, this message translates to:
  /// **'Legal Notice'**
  String get cookiesScreenLegalNotice;

  /// No description provided for @cookiesScreenLegalNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'This is a template document. Before deploying to production:\n\n• Review and customize this policy to match your actual cookie usage\n• Implement a cookie consent banner if required by your jurisdiction\n• Update third-party service information\n• Consider consulting with a legal professional to ensure compliance with GDPR, ePrivacy Directive, and other applicable laws'**
  String get cookiesScreenLegalNoticeBody;

  /// No description provided for @calendarActionsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Booking'**
  String get calendarActionsDeleteTitle;

  /// No description provided for @calendarActionsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the booking for {guestName}?'**
  String calendarActionsDeleteConfirm(String guestName);

  /// No description provided for @calendarActionsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get calendarActionsCancel;

  /// No description provided for @calendarActionsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get calendarActionsDelete;

  /// No description provided for @calendarActionsDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting booking...'**
  String get calendarActionsDeleting;

  /// No description provided for @calendarActionsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Booking deleted'**
  String get calendarActionsDeleted;

  /// No description provided for @calendarActionsError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String calendarActionsError(String error);

  /// No description provided for @calendarActionsChangingStatus.
  ///
  /// In en, this message translates to:
  /// **'Changing status to {status}...'**
  String calendarActionsChangingStatus(String status);

  /// No description provided for @calendarActionsStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed to {status}'**
  String calendarActionsStatusChanged(String status);

  /// No description provided for @bookingCompleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get bookingCompleteDialogTitle;

  /// No description provided for @bookingCompleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this booking as completed?'**
  String get bookingCompleteDialogMessage;

  /// No description provided for @bookingCompleteDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bookingCompleteDialogCancel;

  /// No description provided for @bookingCompleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get bookingCompleteDialogConfirm;

  /// No description provided for @ownerFaqGeneral1Q.
  ///
  /// In en, this message translates to:
  /// **'What is this platform?'**
  String get ownerFaqGeneral1Q;

  /// No description provided for @ownerFaqGeneral1A.
  ///
  /// In en, this message translates to:
  /// **'This is a multi-tenant booking platform that allows apartment owners to manage reservations, receive payments, and embed a booking widget on their website. The platform supports Stripe payments, iCal synchronization with Booking.com/Airbnb, and multiple languages.'**
  String get ownerFaqGeneral1A;

  /// No description provided for @ownerFaqGeneral2Q.
  ///
  /// In en, this message translates to:
  /// **'Is there a mobile app?'**
  String get ownerFaqGeneral2Q;

  /// No description provided for @ownerFaqGeneral2A.
  ///
  /// In en, this message translates to:
  /// **'Yes! The Owner app is available for Android and iOS. You can manage reservations, view the calendar, approve/cancel bookings, and receive notifications on your phone.'**
  String get ownerFaqGeneral2A;

  /// No description provided for @ownerFaqGeneral3Q.
  ///
  /// In en, this message translates to:
  /// **'How much does it cost?'**
  String get ownerFaqGeneral3Q;

  /// No description provided for @ownerFaqGeneral3A.
  ///
  /// In en, this message translates to:
  /// **'The platform currently has a trial version. Three subscriptions are planned: Trial (1 property), Premium (5 properties), and Enterprise (unlimited). Stripe commission (1.4% + €0.25) is charged separately.'**
  String get ownerFaqGeneral3A;

  /// No description provided for @ownerFaqBookings1Q.
  ///
  /// In en, this message translates to:
  /// **'How does the booking flow work?'**
  String get ownerFaqBookings1Q;

  /// No description provided for @ownerFaqBookings1A.
  ///
  /// In en, this message translates to:
  /// **'There are three modes: (1) Calendar Only - guests only see availability and call you, (2) Booking Pending - guests create a reservation that awaits your confirmation, (3) Booking Instant - guests can book and pay immediately. You choose the mode in Widget Settings.'**
  String get ownerFaqBookings1A;

  /// No description provided for @ownerFaqBookings2Q.
  ///
  /// In en, this message translates to:
  /// **'How to approve a reservation?'**
  String get ownerFaqBookings2Q;

  /// No description provided for @ownerFaqBookings2A.
  ///
  /// In en, this message translates to:
  /// **'Go to Bookings → Pending reservations → Click on the reservation → \"Approve\". An email will automatically be sent to the guest with confirmation.'**
  String get ownerFaqBookings2A;

  /// No description provided for @ownerFaqBookings3Q.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel a reservation?'**
  String get ownerFaqBookings3Q;

  /// No description provided for @ownerFaqBookings3A.
  ///
  /// In en, this message translates to:
  /// **'Yes. Click on the reservation → \"Cancel\" → Enter reason → Confirm. The guest will be notified by email. For Stripe payment refunds, contact support.'**
  String get ownerFaqBookings3A;

  /// No description provided for @ownerFaqBookings4Q.
  ///
  /// In en, this message translates to:
  /// **'How to prevent overbooking?'**
  String get ownerFaqBookings4Q;

  /// No description provided for @ownerFaqBookings4A.
  ///
  /// In en, this message translates to:
  /// **'Use iCal synchronization to import reservations from Booking.com, Airbnb and other platforms. All reservations will be displayed in the calendar as occupied days.'**
  String get ownerFaqBookings4A;

  /// No description provided for @ownerFaqBookings5Q.
  ///
  /// In en, this message translates to:
  /// **'How to manually block dates?'**
  String get ownerFaqBookings5Q;

  /// No description provided for @ownerFaqBookings5A.
  ///
  /// In en, this message translates to:
  /// **'In the calendar, click on a date or date range → \"Block\" → Enter reason (optional). Blocked days will be shown as unavailable in the widget.'**
  String get ownerFaqBookings5A;

  /// No description provided for @ownerFaqPayments1Q.
  ///
  /// In en, this message translates to:
  /// **'What payment methods do you support?'**
  String get ownerFaqPayments1Q;

  /// No description provided for @ownerFaqPayments1A.
  ///
  /// In en, this message translates to:
  /// **'We support: (1) Stripe card payments (instant), (2) Bank transfer (manual confirmation), (3) Pay on arrival. You can enable/disable each method in Widget Settings.'**
  String get ownerFaqPayments1A;

  /// No description provided for @ownerFaqPayments2Q.
  ///
  /// In en, this message translates to:
  /// **'What deposit can I require?'**
  String get ownerFaqPayments2Q;

  /// No description provided for @ownerFaqPayments2A.
  ///
  /// In en, this message translates to:
  /// **'You can set a deposit from 0% to 100% of the total price. The default is 20%. The remaining amount is paid by the guest on arrival. Set it in Widget Settings.'**
  String get ownerFaqPayments2A;

  /// No description provided for @ownerFaqPayments3Q.
  ///
  /// In en, this message translates to:
  /// **'When do Stripe payouts arrive?'**
  String get ownerFaqPayments3Q;

  /// No description provided for @ownerFaqPayments3A.
  ///
  /// In en, this message translates to:
  /// **'Stripe automatically transfers funds to your bank account every 7 days. After the first month, you can switch to daily payouts in the Stripe dashboard.'**
  String get ownerFaqPayments3A;

  /// No description provided for @ownerFaqPayments4Q.
  ///
  /// In en, this message translates to:
  /// **'What if a guest requests a refund?'**
  String get ownerFaqPayments4Q;

  /// No description provided for @ownerFaqPayments4A.
  ///
  /// In en, this message translates to:
  /// **'For bank transfers, you process the refund manually. For Stripe payments, contact support or create a refund directly in the Stripe dashboard.'**
  String get ownerFaqPayments4A;

  /// No description provided for @ownerFaqWidget1Q.
  ///
  /// In en, this message translates to:
  /// **'How to add the widget to my site?'**
  String get ownerFaqWidget1Q;

  /// No description provided for @ownerFaqWidget1A.
  ///
  /// In en, this message translates to:
  /// **'Go to Unit Form → \"Generate Embed Code\" → Copy the iframe code → Paste into your site\'s HTML. Detailed instructions are in the \"Embed Widget\" section of the guides.'**
  String get ownerFaqWidget1A;

  /// No description provided for @ownerFaqWidget2Q.
  ///
  /// In en, this message translates to:
  /// **'Can I customize the widget appearance?'**
  String get ownerFaqWidget2Q;

  /// No description provided for @ownerFaqWidget2A.
  ///
  /// In en, this message translates to:
  /// **'Yes! In Widget Settings you can: change the primary color, upload a logo, customize the custom message, and enable/disable \"Powered by\" branding.'**
  String get ownerFaqWidget2A;

  /// No description provided for @ownerFaqWidget3Q.
  ///
  /// In en, this message translates to:
  /// **'Does the widget work on mobile devices?'**
  String get ownerFaqWidget3Q;

  /// No description provided for @ownerFaqWidget3A.
  ///
  /// In en, this message translates to:
  /// **'Yes, the widget is fully responsive and adapts to all screen sizes. Use the responsive embed code for best results.'**
  String get ownerFaqWidget3A;

  /// No description provided for @ownerFaqWidget4Q.
  ///
  /// In en, this message translates to:
  /// **'Can I have multiple widgets on one page?'**
  String get ownerFaqWidget4Q;

  /// No description provided for @ownerFaqWidget4A.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can embed multiple widgets (for different apartments) on the same page. Each widget will have its unique unit ID in the URL.'**
  String get ownerFaqWidget4A;

  /// No description provided for @ownerFaqWidget5Q.
  ///
  /// In en, this message translates to:
  /// **'Does the widget support multiple languages?'**
  String get ownerFaqWidget5Q;

  /// No description provided for @ownerFaqWidget5A.
  ///
  /// In en, this message translates to:
  /// **'Yes! The widget supports Croatian, English, German and Italian. Add &language=en (or hr, de, it) to the URL or enable the language selector.'**
  String get ownerFaqWidget5A;

  /// No description provided for @ownerFaqIcal1Q.
  ///
  /// In en, this message translates to:
  /// **'How to connect Booking.com calendar?'**
  String get ownerFaqIcal1Q;

  /// No description provided for @ownerFaqIcal1A.
  ///
  /// In en, this message translates to:
  /// **'Log in to Booking.com Extranet → Calendar → Reservations export → Copy the iCal URL → Add to our app under iCal Synchronization. More details in the \"iCal Sync\" guide.'**
  String get ownerFaqIcal1A;

  /// No description provided for @ownerFaqIcal2Q.
  ///
  /// In en, this message translates to:
  /// **'How often does it sync?'**
  String get ownerFaqIcal2Q;

  /// No description provided for @ownerFaqIcal2A.
  ///
  /// In en, this message translates to:
  /// **'Automatic sync runs every hour. You can manually trigger a sync anytime by clicking the \"Sync Now\" button.'**
  String get ownerFaqIcal2A;

  /// No description provided for @ownerFaqIcal3Q.
  ///
  /// In en, this message translates to:
  /// **'Will guests see guest names from other platforms?'**
  String get ownerFaqIcal3Q;

  /// No description provided for @ownerFaqIcal3A.
  ///
  /// In en, this message translates to:
  /// **'No. The iCal protocol only transfers reservation dates (check-in/check-out), not personal data. Reservations will be displayed as \"Platform Guest\" in your calendar.'**
  String get ownerFaqIcal3A;

  /// No description provided for @ownerFaqIcal4Q.
  ///
  /// In en, this message translates to:
  /// **'Can I sync with multiple platforms simultaneously?'**
  String get ownerFaqIcal4Q;

  /// No description provided for @ownerFaqIcal4A.
  ///
  /// In en, this message translates to:
  /// **'Yes! You can add iCal feeds from Booking.com, Airbnb or any other platform that supports iCal format for the same apartment. All reservations will be displayed.'**
  String get ownerFaqIcal4A;

  /// No description provided for @ownerFaqSupport1Q.
  ///
  /// In en, this message translates to:
  /// **'Widget is not loading on my site'**
  String get ownerFaqSupport1Q;

  /// No description provided for @ownerFaqSupport1A.
  ///
  /// In en, this message translates to:
  /// **'Check: (1) Did you paste the complete iframe code, (2) Is the unit ID correct, (3) Browser console for errors (F12). If the problem persists, contact support.'**
  String get ownerFaqSupport1A;

  /// No description provided for @ownerFaqSupport2Q.
  ///
  /// In en, this message translates to:
  /// **'I forgot my password'**
  String get ownerFaqSupport2Q;

  /// No description provided for @ownerFaqSupport2A.
  ///
  /// In en, this message translates to:
  /// **'On the login screen click \"Forgot Password\" → Enter email → Check your inbox (and spam folder) for the reset link.'**
  String get ownerFaqSupport2A;

  /// No description provided for @ownerFaqSupport3Q.
  ///
  /// In en, this message translates to:
  /// **'Email notifications are not arriving'**
  String get ownerFaqSupport3Q;

  /// No description provided for @ownerFaqSupport3A.
  ///
  /// In en, this message translates to:
  /// **'Check your spam folder. If they still don\'t arrive, go to Profile → Notification Settings and verify notifications are enabled. Add duskolicanin1234@gmail.com to your whitelist.'**
  String get ownerFaqSupport3A;

  /// No description provided for @ownerFaqSupport4Q.
  ///
  /// In en, this message translates to:
  /// **'How to contact support?'**
  String get ownerFaqSupport4Q;

  /// No description provided for @ownerFaqSupport4A.
  ///
  /// In en, this message translates to:
  /// **'Send an email to: duskolicanin1234@gmail.com with a detailed description of the problem. Include screenshots if possible. We respond within 24-48h.'**
  String get ownerFaqSupport4A;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure guest email verification settings'**
  String get emailVerificationSubtitle;

  /// No description provided for @emailVerificationToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Require Email Verification'**
  String get emailVerificationToggleTitle;

  /// No description provided for @emailVerificationToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guest must verify their email address before completing booking'**
  String get emailVerificationToggleSubtitle;

  /// No description provided for @emailVerificationInfoEnabled.
  ///
  /// In en, this message translates to:
  /// **'Verification button will be shown in Step 2 of the booking flow. Guests cannot proceed without verifying their email.'**
  String get emailVerificationInfoEnabled;

  /// No description provided for @emailVerificationInfoDisabled.
  ///
  /// In en, this message translates to:
  /// **'Email verification is disabled. Guests can complete bookings without verifying their email address.'**
  String get emailVerificationInfoDisabled;

  /// No description provided for @icalExportEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get icalExportEnabled;

  /// No description provided for @icalExportDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get icalExportDisabled;

  /// No description provided for @icalExportToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable iCal Export'**
  String get icalExportToggleTitle;

  /// No description provided for @icalExportToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate public iCal URL for external calendar sync'**
  String get icalExportToggleSubtitle;

  /// No description provided for @icalExportInfo.
  ///
  /// In en, this message translates to:
  /// **'Export Information'**
  String get icalExportInfo;

  /// No description provided for @icalExportInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'iCal export will be auto-generated when bookings change. Use the generated URL to sync with external calendars.'**
  String get icalExportInfoMessage;

  /// No description provided for @icalExportDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String icalExportDaysAgo(int days);

  /// No description provided for @icalExportTestButton.
  ///
  /// In en, this message translates to:
  /// **'Test iCal Export'**
  String get icalExportTestButton;

  /// No description provided for @icalExportLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get icalExportLoading;

  /// No description provided for @icalExportFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load unit data'**
  String get icalExportFailedToLoad;

  /// No description provided for @taxLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax & Legal Disclaimer'**
  String get taxLegalTitle;

  /// No description provided for @taxLegalEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get taxLegalEnabled;

  /// No description provided for @taxLegalDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get taxLegalDisabled;

  /// No description provided for @taxLegalToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Tax/Legal Disclaimer'**
  String get taxLegalToggleTitle;

  /// No description provided for @taxLegalToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show disclaimer to guests during booking'**
  String get taxLegalToggleSubtitle;

  /// No description provided for @taxLegalTextSource.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer Text Source'**
  String get taxLegalTextSource;

  /// No description provided for @taxLegalDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Default Croatian Text'**
  String get taxLegalDefaultTitle;

  /// No description provided for @taxLegalDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Standard legal text for Croatian properties'**
  String get taxLegalDefaultSubtitle;

  /// No description provided for @taxLegalCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Custom Text'**
  String get taxLegalCustomTitle;

  /// No description provided for @taxLegalCustomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provide your own legal text'**
  String get taxLegalCustomSubtitle;

  /// No description provided for @taxLegalCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Disclaimer Text'**
  String get taxLegalCustomLabel;

  /// No description provided for @taxLegalCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your custom legal text...'**
  String get taxLegalCustomHint;

  /// No description provided for @taxLegalPreviewButton.
  ///
  /// In en, this message translates to:
  /// **'Preview Disclaimer'**
  String get taxLegalPreviewButton;

  /// No description provided for @bookingActionUnknownGuest.
  ///
  /// In en, this message translates to:
  /// **'Unknown guest'**
  String get bookingActionUnknownGuest;

  /// No description provided for @bookingBlockHasConflict.
  ///
  /// In en, this message translates to:
  /// **'has conflict with another booking'**
  String get bookingBlockHasConflict;

  /// No description provided for @bookingActionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit booking'**
  String get bookingActionEditTitle;

  /// No description provided for @bookingActionEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change booking details'**
  String get bookingActionEditSubtitle;

  /// No description provided for @bookingActionStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get bookingActionStatusTitle;

  /// No description provided for @bookingActionStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmed, Pending, Cancelled...'**
  String get bookingActionStatusSubtitle;

  /// No description provided for @bookingActionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete booking'**
  String get bookingActionDeleteTitle;

  /// No description provided for @bookingActionDeleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove booking'**
  String get bookingActionDeleteSubtitle;

  /// No description provided for @bookingActionMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move booking to:'**
  String get bookingActionMoveTitle;

  /// No description provided for @bookingActionNoOtherUnits.
  ///
  /// In en, this message translates to:
  /// **'No other available units'**
  String get bookingActionNoOtherUnits;

  /// No description provided for @bookingActionGuestsRooms.
  ///
  /// In en, this message translates to:
  /// **'{guests} guests • {rooms} bedrooms'**
  String bookingActionGuestsRooms(int guests, int rooms);

  /// No description provided for @bookingActionMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving booking...'**
  String get bookingActionMoving;

  /// No description provided for @bookingActionMovedTo.
  ///
  /// In en, this message translates to:
  /// **'Booking moved to {unitName}'**
  String bookingActionMovedTo(String unitName);

  /// No description provided for @bookingActionError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String bookingActionError(String error);

  /// No description provided for @futureBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bookings - {unitName}'**
  String futureBookingsTitle(String unitName);

  /// No description provided for @futureBookingsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get futureBookingsClose;

  /// No description provided for @futureBookingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bookings'**
  String futureBookingsCount(int count);

  /// No description provided for @futureBookingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming bookings'**
  String get futureBookingsEmpty;

  /// No description provided for @futureBookingsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All future bookings for {unitName} will be shown here'**
  String futureBookingsEmptySubtitle(String unitName);

  /// No description provided for @futureBookingsUnknownGuest.
  ///
  /// In en, this message translates to:
  /// **'Unknown Guest'**
  String get futureBookingsUnknownGuest;

  /// No description provided for @futureBookingsCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in: {date}'**
  String futureBookingsCheckIn(String date);

  /// No description provided for @futureBookingsCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out: {date}'**
  String futureBookingsCheckOut(String date);

  /// No description provided for @futureBookingsGuestsNights.
  ///
  /// In en, this message translates to:
  /// **'{guests} guest(s) • {nights} night(s)'**
  String futureBookingsGuestsNights(int guests, int nights);

  /// No description provided for @calendarErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get calendarErrorTitle;

  /// No description provided for @calendarErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading data'**
  String get calendarErrorDefault;

  /// No description provided for @calendarErrorCompact.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get calendarErrorCompact;

  /// No description provided for @calendarErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get calendarErrorRetry;

  /// No description provided for @calendarErrorHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get calendarErrorHelp;

  /// No description provided for @calendarErrorBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get calendarErrorBannerTitle;

  /// No description provided for @calendarErrorClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get calendarErrorClose;

  /// No description provided for @calendarFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar Filters'**
  String get calendarFiltersTitle;

  /// No description provided for @calendarFiltersSearchGuest.
  ///
  /// In en, this message translates to:
  /// **'Search guest'**
  String get calendarFiltersSearchGuest;

  /// No description provided for @calendarFiltersGuestLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest name or email'**
  String get calendarFiltersGuestLabel;

  /// No description provided for @calendarFiltersGuestHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name or email...'**
  String get calendarFiltersGuestHint;

  /// No description provided for @calendarFiltersSearchBookingId.
  ///
  /// In en, this message translates to:
  /// **'Search by booking ID'**
  String get calendarFiltersSearchBookingId;

  /// No description provided for @calendarFiltersBookingIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get calendarFiltersBookingIdLabel;

  /// No description provided for @calendarFiltersBookingIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter booking ID...'**
  String get calendarFiltersBookingIdHint;

  /// No description provided for @calendarFiltersClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get calendarFiltersClearDate;

  /// No description provided for @calendarFiltersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get calendarFiltersApply;

  /// No description provided for @calendarFiltersCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get calendarFiltersCancel;

  /// No description provided for @calendarFiltersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get calendarFiltersClear;

  /// No description provided for @calendarFiltersClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get calendarFiltersClearAll;

  /// No description provided for @calendarSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Bookings'**
  String get calendarSearchTitle;

  /// No description provided for @calendarSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by guest name, email, ID or unit...'**
  String get calendarSearchHint;

  /// No description provided for @calendarSearchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count} results'**
  String calendarSearchResultsCount(int count);

  /// No description provided for @calendarSearchEnterTerm.
  ///
  /// In en, this message translates to:
  /// **'Enter search term'**
  String get calendarSearchEnterTerm;

  /// No description provided for @calendarSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Search by guest name, email, ID or unit'**
  String get calendarSearchDescription;

  /// No description provided for @calendarSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get calendarSearchNoResults;

  /// No description provided for @calendarSearchTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get calendarSearchTryAnother;

  /// No description provided for @calendarStatusCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get calendarStatusCurrent;

  /// No description provided for @bookingInlineEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Edit'**
  String get bookingInlineEditTitle;

  /// No description provided for @bookingInlineEditGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get bookingInlineEditGuest;

  /// No description provided for @bookingInlineEditCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get bookingInlineEditCheckIn;

  /// No description provided for @bookingInlineEditCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get bookingInlineEditCheckOut;

  /// No description provided for @bookingInlineEditNights.
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get bookingInlineEditNights;

  /// No description provided for @bookingInlineEditGuestCount.
  ///
  /// In en, this message translates to:
  /// **'Number of Guests'**
  String get bookingInlineEditGuestCount;

  /// No description provided for @bookingInlineEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get bookingInlineEditSave;

  /// No description provided for @bookingInlineEditSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get bookingInlineEditSaving;

  /// No description provided for @bookingInlineEditCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bookingInlineEditCancel;

  /// No description provided for @bookingInlineEditDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get bookingInlineEditDates;

  /// No description provided for @bookingInlineEditNightSingular.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get bookingInlineEditNightSingular;

  /// No description provided for @bookingInlineEditNightPlural.
  ///
  /// In en, this message translates to:
  /// **'nights'**
  String get bookingInlineEditNightPlural;

  /// No description provided for @bookingEditInternalNotes.
  ///
  /// In en, this message translates to:
  /// **'Internal Notes'**
  String get bookingEditInternalNotes;

  /// No description provided for @bookingEditNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes for this booking...'**
  String get bookingEditNotesHint;

  /// No description provided for @priceCalendarHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. {value}'**
  String priceCalendarHintExample(String value);

  /// No description provided for @overbookingConflictDetected.
  ///
  /// In en, this message translates to:
  /// **'Overbooking detected for {unitName}'**
  String overbookingConflictDetected(String unitName);

  /// No description provided for @overbookingConflictCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No conflicts} =1{1 conflict} other{{count} conflicts}}'**
  String overbookingConflictCount(num count);

  /// No description provided for @overbookingConflictDetails.
  ///
  /// In en, this message translates to:
  /// **'Conflict: {guest1} vs {guest2}'**
  String overbookingConflictDetails(String guest1, String guest2);

  /// No description provided for @overbookingViewBooking.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get overbookingViewBooking;

  /// No description provided for @overbookingScrollToConflict.
  ///
  /// In en, this message translates to:
  /// **'Scroll to conflict'**
  String get overbookingScrollToConflict;

  /// No description provided for @bookingDropZoneDropHere.
  ///
  /// In en, this message translates to:
  /// **'Drop here'**
  String get bookingDropZoneDropHere;

  /// No description provided for @bookingDropZoneCannotDrop.
  ///
  /// In en, this message translates to:
  /// **'Cannot drop'**
  String get bookingDropZoneCannotDrop;

  /// No description provided for @bookingBlockSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking for {guestName}, from {checkIn} to {checkOut}, {nights} nights, {guestCount} guests{conflictText}. Tap for details.'**
  String bookingBlockSemanticLabel(
    String guestName,
    String checkIn,
    String checkOut,
    int nights,
    int guestCount,
    String conflictText,
  );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hr':
      return AppLocalizationsHr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
