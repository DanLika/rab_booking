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
  /// **'RAB Booking'**
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
  /// **'Under GDPR, you have the right to:\n\n• Access your personal data\n• Correct inaccurate data\n• Request deletion of your data\n• Object to data processing\n• Data portability\n• Withdraw consent\n\nContact us at privacy@rabbooking.com to exercise your rights.'**
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
  /// **'If you have questions about this Privacy Policy, please contact us at:\n\nEmail: privacy@rabbooking.com\nPhone: +1 (555) 123-4567'**
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
