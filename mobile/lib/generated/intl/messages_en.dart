// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(date) => "Accepted: ${date}";

  static String m1(time) => "If the worker is late, you can cancel in ${time}";

  static String m2(date) => "Completed: ${date}";

  static String m3(label) => "${label} copied to clipboard";

  static String m4(days) => "${days}d ago";

  static String m5(name) => "Hello, ${name}!";

  static String m6(hours) => "${hours}h ago";

  static String m7(minutes) => "${minutes}m ago";

  static String m8(count) => "${count} new";

  static String m9(count) => "Photos (${count})";

  static String m10(count) => "${count} recent";

  static String m11(date) => "Scheduled · ${date}";

  static String m12(title) =>
      "Your service \"${title}\" has been successfully added.";

  static String m13(count) => "this month: ${count}";

  static String m14(count) => "Voice notes (${count})";

  static String m15(km) => "within ${km} km";

  static String m16(count) => "${count} unread requests";

  static String m17(count) => "${count} favorites";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "acMaintenance": MessageLookupByLibrary.simpleMessage("AC Maintenance"),
    "acMaintenanceRequestDesc": MessageLookupByLibrary.simpleMessage(
      "AC not cooling properly",
    ),
    "accept": MessageLookupByLibrary.simpleMessage("Accept"),
    "acceptStats": MessageLookupByLibrary.simpleMessage("Accept"),
    "acceptedDate": m0,
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "accountNotApproved": MessageLookupByLibrary.simpleMessage(
      "Account Not Approved",
    ),
    "accountType": MessageLookupByLibrary.simpleMessage("Account Type"),
    "accountUnderReview": MessageLookupByLibrary.simpleMessage(
      "Account Under Review",
    ),
    "addDebitOrCreditCard": MessageLookupByLibrary.simpleMessage(
      "Add Debit or Credit Card",
    ),
    "addNewAddress": MessageLookupByLibrary.simpleMessage("Add New Address"),
    "addNewCard": MessageLookupByLibrary.simpleMessage("Add New Card"),
    "addPhotosOrVoice": MessageLookupByLibrary.simpleMessage(
      "Add up to 4 photos or a voice note (max 2 min) to explain the issue",
    ),
    "addService": MessageLookupByLibrary.simpleMessage("Add Service"),
    "addServiceDesc": MessageLookupByLibrary.simpleMessage(
      "Add a new service you provide",
    ),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "addressDetails": MessageLookupByLibrary.simpleMessage("Address Details"),
    "addressDetailsHint": MessageLookupByLibrary.simpleMessage(
      "e.g. 12 Street Name, District",
    ),
    "addressForOrder": MessageLookupByLibrary.simpleMessage(
      "Address for this order",
    ),
    "addressGardenStGiza": MessageLookupByLibrary.simpleMessage(
      "67 Garden St, Giza",
    ),
    "addressLabelHint": MessageLookupByLibrary.simpleMessage(
      "e.g. Home, Office",
    ),
    "addressMainStreetCairo": MessageLookupByLibrary.simpleMessage(
      "123 Main Street, Cairo",
    ),
    "addressNickname": MessageLookupByLibrary.simpleMessage("Address Nickname"),
    "addressNileStreetCairo": MessageLookupByLibrary.simpleMessage(
      "45 Nile Street, Cairo",
    ),
    "addresses": MessageLookupByLibrary.simpleMessage("Addresses"),
    "addressesDesc": MessageLookupByLibrary.simpleMessage(
      "Manage your saved addresses",
    ),
    "addressesPageTitle": MessageLookupByLibrary.simpleMessage("My Addresses"),
    "allCategories": MessageLookupByLibrary.simpleMessage("All"),
    "alreadyHaveAccount": MessageLookupByLibrary.simpleMessage(
      "Already have an account?",
    ),
    "anonymous": MessageLookupByLibrary.simpleMessage("Anonymous"),
    "applePay": MessageLookupByLibrary.simpleMessage("Pay"),
    "apply": MessageLookupByLibrary.simpleMessage("Apply"),
    "applyFilters": MessageLookupByLibrary.simpleMessage("Apply Filters"),
    "arabic": MessageLookupByLibrary.simpleMessage("العربية"),
    "areaDistrictHint": MessageLookupByLibrary.simpleMessage(
      "Area / District (e.g. Al-Haram, Downtown)",
    ),
    "audioNotSupported": MessageLookupByLibrary.simpleMessage(
      "Audio recording is not supported on this platform",
    ),
    "availableDescription": MessageLookupByLibrary.simpleMessage(
      "Available — clients can book you now",
    ),
    "availableForWork": MessageLookupByLibrary.simpleMessage(
      "Available for Work",
    ),
    "availableOnly": MessageLookupByLibrary.simpleMessage("Available only"),
    "availableStatus": MessageLookupByLibrary.simpleMessage("Available"),
    "avgResponse": MessageLookupByLibrary.simpleMessage("Avg. response"),
    "awaitingReply": MessageLookupByLibrary.simpleMessage(
      "awaiting your reply",
    ),
    "book": MessageLookupByLibrary.simpleMessage("Book"),
    "bookNow": MessageLookupByLibrary.simpleMessage("Book Now"),
    "bookingFee": MessageLookupByLibrary.simpleMessage("Booking Fee"),
    "busyStatus": MessageLookupByLibrary.simpleMessage("Busy"),
    "callOutFee": MessageLookupByLibrary.simpleMessage("Call-out fee"),
    "cameraNotSupported": MessageLookupByLibrary.simpleMessage(
      "Camera not supported on this platform",
    ),
    "cameraOption": MessageLookupByLibrary.simpleMessage("Camera"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelIn": m1,
    "cancelRequest": MessageLookupByLibrary.simpleMessage("Cancel Request"),
    "cancelRequestConfirm": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to cancel this request?",
    ),
    "cancelWithinHour": MessageLookupByLibrary.simpleMessage(
      "You can cancel the order within one hour after the technician accepts.",
    ),
    "canceled": MessageLookupByLibrary.simpleMessage("Canceled"),
    "cancelledByCustomer": MessageLookupByLibrary.simpleMessage(
      "Cancelled by the customer",
    ),
    "cancelledByYou": MessageLookupByLibrary.simpleMessage("Cancelled by you"),
    "card": MessageLookupByLibrary.simpleMessage("Card"),
    "cardNumber": MessageLookupByLibrary.simpleMessage("Card Number"),
    "cards": MessageLookupByLibrary.simpleMessage("Cards"),
    "cash": MessageLookupByLibrary.simpleMessage("Cash"),
    "category": MessageLookupByLibrary.simpleMessage("Category"),
    "change": MessageLookupByLibrary.simpleMessage("Change"),
    "checkout": MessageLookupByLibrary.simpleMessage("Checkout"),
    "checkoutLoginRequired": MessageLookupByLibrary.simpleMessage(
      "Sign in to complete your booking.",
    ),
    "chooseAccountFooter": MessageLookupByLibrary.simpleMessage(
      "Join now and enjoy an easier and faster way to fix all your home issues!",
    ),
    "chooseAccountSubtitle": MessageLookupByLibrary.simpleMessage(
      "Start fixing any home issue quickly and easily!",
    ),
    "chooseAccountTypeDesc": MessageLookupByLibrary.simpleMessage(
      "Choose whether you are a client or a technician.",
    ),
    "cityArea": MessageLookupByLibrary.simpleMessage("City / Area"),
    "cityAreaHint": MessageLookupByLibrary.simpleMessage("e.g. Nasr City"),
    "cleaning": MessageLookupByLibrary.simpleMessage("Cleaning"),
    "cleaningDescription": MessageLookupByLibrary.simpleMessage(
      "Home and office cleaning services at your door.",
    ),
    "cleaningService": MessageLookupByLibrary.simpleMessage("Cleaning Service"),
    "cleaningServiceRequestDesc": MessageLookupByLibrary.simpleMessage(
      "Full apartment cleaning",
    ),
    "clientRole": MessageLookupByLibrary.simpleMessage("Client"),
    "completeProfileBtn": MessageLookupByLibrary.simpleMessage(
      "Complete Profile",
    ),
    "completeStats": MessageLookupByLibrary.simpleMessage("Complete"),
    "completed": MessageLookupByLibrary.simpleMessage("Completed"),
    "completedDate": m2,
    "completedStats": MessageLookupByLibrary.simpleMessage("Completed"),
    "confirmCompletion": MessageLookupByLibrary.simpleMessage(
      "Confirm Completion",
    ),
    "confirmed": MessageLookupByLibrary.simpleMessage("Confirmed"),
    "connectionError": MessageLookupByLibrary.simpleMessage(
      "Connection error occurred",
    ),
    "connectionTimeout": MessageLookupByLibrary.simpleMessage(
      "Connection timeout with API server",
    ),
    "contactInfo": MessageLookupByLibrary.simpleMessage("Contact Information"),
    "continueAsGuest": MessageLookupByLibrary.simpleMessage(
      "Continue as guest",
    ),
    "copiedToClipboard": m3,
    "couldNotLoadRequests": MessageLookupByLibrary.simpleMessage(
      "Could not load requests",
    ),
    "couldNotOpenCamera": MessageLookupByLibrary.simpleMessage(
      "Could not open camera",
    ),
    "couldNotOpenGallery": MessageLookupByLibrary.simpleMessage(
      "Could not open gallery",
    ),
    "couldNotStartRecording": MessageLookupByLibrary.simpleMessage(
      "Could not start recording",
    ),
    "createProfile": MessageLookupByLibrary.simpleMessage("Create Profile"),
    "creatingProfile": MessageLookupByLibrary.simpleMessage(
      "Creating profile...",
    ),
    "currentLocation": MessageLookupByLibrary.simpleMessage(
      "Dhaka, Bangladesh",
    ),
    "customer": MessageLookupByLibrary.simpleMessage("Customer"),
    "cvv": MessageLookupByLibrary.simpleMessage("CVV"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dark Mode"),
    "date": MessageLookupByLibrary.simpleMessage("Date"),
    "daysAgo": m4,
    "defaultLabel": MessageLookupByLibrary.simpleMessage("Default"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deliveryAddress": MessageLookupByLibrary.simpleMessage("Delivery Address"),
    "description": MessageLookupByLibrary.simpleMessage("Description"),
    "descriptionHint": MessageLookupByLibrary.simpleMessage(
      "Tell us about your skills and experience",
    ),
    "detailedAddress": MessageLookupByLibrary.simpleMessage("Detailed Address"),
    "details": MessageLookupByLibrary.simpleMessage("Details"),
    "dontHaveAccount": MessageLookupByLibrary.simpleMessage(
      "Don\'t have an account?",
    ),
    "easyRequests": MessageLookupByLibrary.simpleMessage("Easy Requests"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editProfile": MessageLookupByLibrary.simpleMessage("Edit profile"),
    "editService": MessageLookupByLibrary.simpleMessage("Edit Service"),
    "editServiceDesc": MessageLookupByLibrary.simpleMessage(
      "Update your service details",
    ),
    "electric": MessageLookupByLibrary.simpleMessage("Electric"),
    "electricFix": MessageLookupByLibrary.simpleMessage("Electric Fix"),
    "electricFixDescription": MessageLookupByLibrary.simpleMessage(
      "Fix all your electric issues quickly and professionally.",
    ),
    "electricFixRequestDesc": MessageLookupByLibrary.simpleMessage(
      "Fixing power outage in living room",
    ),
    "email": MessageLookupByLibrary.simpleMessage("Email"),
    "emailOptional": MessageLookupByLibrary.simpleMessage("Email (optional)"),
    "english": MessageLookupByLibrary.simpleMessage("English"),
    "enterProblem": MessageLookupByLibrary.simpleMessage(
      "Enter problem description",
    ),
    "enterPromo": MessageLookupByLibrary.simpleMessage("Enter Promo Code"),
    "enterValidNumber": MessageLookupByLibrary.simpleMessage(
      "Enter a valid number",
    ),
    "errorOccurred": MessageLookupByLibrary.simpleMessage(
      "An error occurred. Please try again.",
    ),
    "experience": MessageLookupByLibrary.simpleMessage("Experience"),
    "expiryDate": MessageLookupByLibrary.simpleMessage("Expiry Date"),
    "failedToLoad": MessageLookupByLibrary.simpleMessage("Failed to load"),
    "failedToPickImage": MessageLookupByLibrary.simpleMessage(
      "Failed to pick image",
    ),
    "failedToSave": MessageLookupByLibrary.simpleMessage("Failed to save"),
    "fastAndReliable": MessageLookupByLibrary.simpleMessage(
      "Fast and reliable!",
    ),
    "favorites": MessageLookupByLibrary.simpleMessage("Favorites"),
    "favoritesCount": m17,
    "filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "finishProfileSetup": MessageLookupByLibrary.simpleMessage(
      "Finish setting up your worker profile",
    ),
    "firstScreenDesc": MessageLookupByLibrary.simpleMessage(
      "Easy interface\nConnect & request a technician quickly",
    ),
    "fullName": MessageLookupByLibrary.simpleMessage("Full Name"),
    "fullNameHint": MessageLookupByLibrary.simpleMessage("e.g. Ahmed Hassan"),
    "galleryNotSupported": MessageLookupByLibrary.simpleMessage(
      "Gallery not supported on this platform",
    ),
    "galleryOption": MessageLookupByLibrary.simpleMessage("Gallery"),
    "getStartedButton": MessageLookupByLibrary.simpleMessage("Get Started"),
    "getStartedDescription": MessageLookupByLibrary.simpleMessage(
      "Got a problem at home?\nRequest a trusted technician in minutes with ease.\n\n✓ Trusted technician selections\n✓ Step-by-step order tracking\n✓ Simple and easy-to-use experience",
    ),
    "getStartedFooter": MessageLookupByLibrary.simpleMessage(
      "Don\'t worry, your data is 100% safe with us",
    ),
    "getStartedSubtitle": MessageLookupByLibrary.simpleMessage(
      "Fix your home issues quickly & safely",
    ),
    "googleSignInFailed": MessageLookupByLibrary.simpleMessage(
      "Google sign-in failed",
    ),
    "governorateHint": MessageLookupByLibrary.simpleMessage("Governorate"),
    "greatService": MessageLookupByLibrary.simpleMessage("Great service!"),
    "hello": m5,
    "highlyRecommended": MessageLookupByLibrary.simpleMessage(
      "Highly recommended!",
    ),
    "hireTechnicians": MessageLookupByLibrary.simpleMessage("Hire technicians"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "hotDeals": MessageLookupByLibrary.simpleMessage("Hot Deals"),
    "hourlyRate": MessageLookupByLibrary.simpleMessage("Hourly rate"),
    "hoursAgo": m6,
    "howItWorks": MessageLookupByLibrary.simpleMessage("How It Works"),
    "imageNotSupported": MessageLookupByLibrary.simpleMessage(
      "Image picking is not supported on this platform",
    ),
    "inProgress": MessageLookupByLibrary.simpleMessage("In Progress"),
    "incomingRequests": MessageLookupByLibrary.simpleMessage(
      "Incoming requests",
    ),
    "info": MessageLookupByLibrary.simpleMessage("Info"),
    "invalidEmail": MessageLookupByLibrary.simpleMessage("Invalid email"),
    "invalidPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "Invalid phone number",
    ),
    "jobHistory": MessageLookupByLibrary.simpleMessage("Job History"),
    "jobs": MessageLookupByLibrary.simpleMessage("jobs"),
    "justNow": MessageLookupByLibrary.simpleMessage("Just now"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "languageArabic": MessageLookupByLibrary.simpleMessage("Arabic"),
    "languageEnglish": MessageLookupByLibrary.simpleMessage("English"),
    "languageFrench": MessageLookupByLibrary.simpleMessage("French"),
    "languages": MessageLookupByLibrary.simpleMessage("Languages"),
    "leave": MessageLookupByLibrary.simpleMessage("Leave"),
    "leaveWarningDesc": MessageLookupByLibrary.simpleMessage(
      "Your account will be deleted if you leave without completing your profile.",
    ),
    "leaveWithoutCompleting": MessageLookupByLibrary.simpleMessage(
      "Leave without completing?",
    ),
    "location": MessageLookupByLibrary.simpleMessage("Location"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "loginRequiredMessage": MessageLookupByLibrary.simpleMessage(
      "Please sign in to continue.",
    ),
    "loginRequiredTitle": MessageLookupByLibrary.simpleMessage(
      "Sign in required",
    ),
    "logout": MessageLookupByLibrary.simpleMessage("Logout"),
    "logoutConfirm": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to logout?",
    ),
    "makeDefault": MessageLookupByLibrary.simpleMessage(
      "Make this as a default",
    ),
    "markAllRead": MessageLookupByLibrary.simpleMessage("Mark all as read"),
    "markAsFinished": MessageLookupByLibrary.simpleMessage("Mark as Finished"),
    "maxPhotosReached": MessageLookupByLibrary.simpleMessage(
      "Maximum of 4 photos reached",
    ),
    "micPermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Microphone permission denied",
    ),
    "micPermissionUnavailable": MessageLookupByLibrary.simpleMessage(
      "Microphone permission unavailable",
    ),
    "minimumRating": MessageLookupByLibrary.simpleMessage("Minimum Rating"),
    "minutesAgo": m7,
    "mustBeBetween0And50": MessageLookupByLibrary.simpleMessage(
      "Must be between 0 and 50",
    ),
    "myCards": MessageLookupByLibrary.simpleMessage("My Cards"),
    "myRequests": MessageLookupByLibrary.simpleMessage("My Requests"),
    "myService": MessageLookupByLibrary.simpleMessage("My service"),
    "myServices": MessageLookupByLibrary.simpleMessage("My Services"),
    "needAService": MessageLookupByLibrary.simpleMessage("Need a service?"),
    "newCount": m8,
    "next": MessageLookupByLibrary.simpleMessage("Next"),
    "niceAndFriendlyStaff": MessageLookupByLibrary.simpleMessage(
      "Nice and friendly staff!",
    ),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noAddresses": MessageLookupByLibrary.simpleMessage("No addresses yet"),
    "noFavorites": MessageLookupByLibrary.simpleMessage("No favorites yet"),
    "noJobHistory": MessageLookupByLibrary.simpleMessage("No job history"),
    "noNotifications": MessageLookupByLibrary.simpleMessage(
      "No notifications yet",
    ),
    "noPendingRequests": MessageLookupByLibrary.simpleMessage(
      "No pending requests",
    ),
    "noRequests": MessageLookupByLibrary.simpleMessage("No requests"),
    "noRequestsYet": MessageLookupByLibrary.simpleMessage("No requests yet"),
    "noResultsFound": MessageLookupByLibrary.simpleMessage("No results found"),
    "noReviews": MessageLookupByLibrary.simpleMessage("No reviews yet"),
    "notSet": MessageLookupByLibrary.simpleMessage("Not set"),
    "note": MessageLookupByLibrary.simpleMessage(
      "Note: If you cancel the service, your booking fee will not be refunded.",
    ),
    "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
    "offlineDescription": MessageLookupByLibrary.simpleMessage(
      "Offline — you won\'t receive new bookings",
    ),
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "orderDetails": MessageLookupByLibrary.simpleMessage("Order Details"),
    "orderPlaced": MessageLookupByLibrary.simpleMessage("Order Placed!"),
    "orderSuccess": MessageLookupByLibrary.simpleMessage(
      "Your order has been successfully placed.",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "passwordTooShort": MessageLookupByLibrary.simpleMessage(
      "Password is too short",
    ),
    "paymentMethod": MessageLookupByLibrary.simpleMessage("Payment Method"),
    "paymentMethods": MessageLookupByLibrary.simpleMessage("Payment Methods"),
    "paymentMethodsDesc": MessageLookupByLibrary.simpleMessage(
      "Your cards & payment options",
    ),
    "pending": MessageLookupByLibrary.simpleMessage("Pending"),
    "perHour": MessageLookupByLibrary.simpleMessage("per hour"),
    "personal": MessageLookupByLibrary.simpleMessage("Personal"),
    "phoneForOrder": MessageLookupByLibrary.simpleMessage(
      "Phone for this order",
    ),
    "phoneNumber": MessageLookupByLibrary.simpleMessage("Phone Number"),
    "phoneTooLong": MessageLookupByLibrary.simpleMessage(
      "Phone number is too long",
    ),
    "phoneTooShort": MessageLookupByLibrary.simpleMessage("Phone too short"),
    "photosCount": m9,
    "placeOrder": MessageLookupByLibrary.simpleMessage("Place Order"),
    "pleaseEnterPhone": MessageLookupByLibrary.simpleMessage(
      "Please enter your phone",
    ),
    "pleaseEnterYourEmail": MessageLookupByLibrary.simpleMessage(
      "Please enter your email",
    ),
    "pleaseEnterYourName": MessageLookupByLibrary.simpleMessage(
      "Please enter your name",
    ),
    "pleaseEnterYourPassword": MessageLookupByLibrary.simpleMessage(
      "Please enter your password",
    ),
    "pleaseEnterYourPhoneNumber": MessageLookupByLibrary.simpleMessage(
      "Please enter your phone number",
    ),
    "pleasePickGovernorate": MessageLookupByLibrary.simpleMessage(
      "Please pick your governorate",
    ),
    "plumbing": MessageLookupByLibrary.simpleMessage("Plumbing"),
    "plumbingDescription": MessageLookupByLibrary.simpleMessage(
      "Plumbing services with guaranteed quality.",
    ),
    "plumbingService": MessageLookupByLibrary.simpleMessage("Plumbing Service"),
    "plumbingServiceRequestDesc": MessageLookupByLibrary.simpleMessage(
      "Kitchen sink leaking",
    ),
    "price": MessageLookupByLibrary.simpleMessage("Price"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "profileCreated": MessageLookupByLibrary.simpleMessage("Profile Created"),
    "profileCreatedMessage": MessageLookupByLibrary.simpleMessage(
      "Your worker profile has been created successfully.",
    ),
    "profilePhoto": MessageLookupByLibrary.simpleMessage("Profile Photo"),
    "profileUpdated": MessageLookupByLibrary.simpleMessage("Profile updated"),
    "promoCode": MessageLookupByLibrary.simpleMessage("Promo Code"),
    "provideServices": MessageLookupByLibrary.simpleMessage("Provide services"),
    "rateOrder": MessageLookupByLibrary.simpleMessage("Rate"),
    "rateService": MessageLookupByLibrary.simpleMessage("Rate Service"),
    "ratingStats": MessageLookupByLibrary.simpleMessage("Rating"),
    "ratingSubmitted": MessageLookupByLibrary.simpleMessage(
      "Rating submitted successfully!",
    ),
    "ratings": MessageLookupByLibrary.simpleMessage("Ratings"),
    "reason": MessageLookupByLibrary.simpleMessage("Reason:"),
    "receiveTimeout": MessageLookupByLibrary.simpleMessage(
      "Receive timeout in connection with API server",
    ),
    "recentCount": m10,
    "recentReviews": MessageLookupByLibrary.simpleMessage("Recent reviews"),
    "record": MessageLookupByLibrary.simpleMessage("Record"),
    "register": MessageLookupByLibrary.simpleMessage("Register"),
    "registrationRejected": MessageLookupByLibrary.simpleMessage(
      "Your registration has been rejected.",
    ),
    "registrationUnderReview": MessageLookupByLibrary.simpleMessage(
      "Your registration has been received and is currently being reviewed. We will contact you to complete the verification process and activate your account.",
    ),
    "rejected": MessageLookupByLibrary.simpleMessage("Rejected"),
    "rejectedByWorker": MessageLookupByLibrary.simpleMessage(
      "Rejected by the worker",
    ),
    "rejectedByYou": MessageLookupByLibrary.simpleMessage("Rejected by you"),
    "removeOption": MessageLookupByLibrary.simpleMessage("Remove"),
    "requestCancelled": MessageLookupByLibrary.simpleMessage(
      "Request to API server was cancelled",
    ),
    "requestDetails": MessageLookupByLibrary.simpleMessage("Request Details"),
    "requests": MessageLookupByLibrary.simpleMessage("Requests"),
    "rerecord": MessageLookupByLibrary.simpleMessage("Re-record"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "reviewExample": MessageLookupByLibrary.simpleMessage(
      "The service is fantastic! Very clean, professional, and fast. Highly recommended!",
    ),
    "reviewHint": MessageLookupByLibrary.simpleMessage(
      "Share your experience (optional)",
    ),
    "reviews": MessageLookupByLibrary.simpleMessage("Reviews"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Save changes"),
    "saving": MessageLookupByLibrary.simpleMessage("Saving…"),
    "scheduledDate": m11,
    "searchForWorkers": MessageLookupByLibrary.simpleMessage(
      "Search for workers and services",
    ),
    "searchHint": MessageLookupByLibrary.simpleMessage(
      "Find your favorite items",
    ),
    "secondScreenDesc": MessageLookupByLibrary.simpleMessage(
      "Talk directly with technicians\nSmooth and fast experience",
    ),
    "selectCategory": MessageLookupByLibrary.simpleMessage("Select a category"),
    "sendTimeout": MessageLookupByLibrary.simpleMessage(
      "Send timeout in connection with API server",
    ),
    "serviceAdded": MessageLookupByLibrary.simpleMessage("Service Added"),
    "serviceAddedMessage": m12,
    "serviceArea": MessageLookupByLibrary.simpleMessage("Service area"),
    "serviceDescription": MessageLookupByLibrary.simpleMessage(
      "Service Description",
    ),
    "serviceInProgress": MessageLookupByLibrary.simpleMessage(
      "Service is in progress",
    ),
    "serviceProvider": MessageLookupByLibrary.simpleMessage("Service Provider"),
    "serviceTitle": MessageLookupByLibrary.simpleMessage("Service Title"),
    "serviceUpdatedMessage": MessageLookupByLibrary.simpleMessage(
      "Your service has been updated successfully.",
    ),
    "setUp": MessageLookupByLibrary.simpleMessage("Set up"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "settingsDesc": MessageLookupByLibrary.simpleMessage(
      "Manage app preferences",
    ),
    "setupSubtitle": MessageLookupByLibrary.simpleMessage(
      "Pick a service & experience so clients can find you.",
    ),
    "signInToContinue": MessageLookupByLibrary.simpleMessage(
      "Sign in to continue",
    ),
    "signInToViewData": MessageLookupByLibrary.simpleMessage(
      "Sign in to view your data.",
    ),
    "signInToViewProfile": MessageLookupByLibrary.simpleMessage(
      "Sign in to view your profile.",
    ),
    "signInWithGoogle": MessageLookupByLibrary.simpleMessage(
      "Sign in with Google",
    ),
    "signUp": MessageLookupByLibrary.simpleMessage("Sign up"),
    "skip": MessageLookupByLibrary.simpleMessage("Skip"),
    "somethingWentWrong": MessageLookupByLibrary.simpleMessage(
      "Oops! Something went wrong.",
    ),
    "specializesIn": MessageLookupByLibrary.simpleMessage("Specializes in"),
    "specialties": MessageLookupByLibrary.simpleMessage("Specialties"),
    "statusLabel": MessageLookupByLibrary.simpleMessage("Status: "),
    "stay": MessageLookupByLibrary.simpleMessage("Stay"),
    "submitRating": MessageLookupByLibrary.simpleMessage("Submit Rating"),
    "submitting": MessageLookupByLibrary.simpleMessage("Submitting..."),
    "tapToCopy": MessageLookupByLibrary.simpleMessage("Tap to copy"),
    "tapToCopyMaps": MessageLookupByLibrary.simpleMessage(
      "Tap to copy Google Maps link",
    ),
    "tapToSelectAddress": MessageLookupByLibrary.simpleMessage(
      "Tap to select an address",
    ),
    "technician": MessageLookupByLibrary.simpleMessage("Technician"),
    "thirdScreenDesc": MessageLookupByLibrary.simpleMessage(
      "Send issues & track responses\nFast and smooth experience",
    ),
    "thisFieldRequired": MessageLookupByLibrary.simpleMessage(
      "This field is required",
    ),
    "thisMonthCount": m13,
    "topRated": MessageLookupByLibrary.simpleMessage("Top rated"),
    "trustedServices": MessageLookupByLibrary.simpleMessage("Trusted Services"),
    "unexpectedError": MessageLookupByLibrary.simpleMessage(
      "Unexpected error occurred",
    ),
    "unreadRequestsCount": m16,
    "urgencyEmergency": MessageLookupByLibrary.simpleMessage("Emergency"),
    "urgencyToday": MessageLookupByLibrary.simpleMessage("Today"),
    "urgencyWhenever": MessageLookupByLibrary.simpleMessage("Whenever"),
    "useAccountPhone": MessageLookupByLibrary.simpleMessage(
      "Use account phone",
    ),
    "useSavedAddress": MessageLookupByLibrary.simpleMessage(
      "Use saved address",
    ),
    "verified": MessageLookupByLibrary.simpleMessage("Verified"),
    "veryProfessional": MessageLookupByLibrary.simpleMessage(
      "Very professional!",
    ),
    "veryThorough": MessageLookupByLibrary.simpleMessage("Very thorough!"),
    "viewAll": MessageLookupByLibrary.simpleMessage("View All"),
    "viewOnMap": MessageLookupByLibrary.simpleMessage("View On Map"),
    "voiceNote": MessageLookupByLibrary.simpleMessage("Voice note"),
    "voiceNotesCount": m14,
    "waitingConfirmation": MessageLookupByLibrary.simpleMessage(
      "Waiting Confirmation",
    ),
    "welcome": MessageLookupByLibrary.simpleMessage("Welcome"),
    "welcomeBack": MessageLookupByLibrary.simpleMessage("Welcome back,"),
    "welcomeToMongez": MessageLookupByLibrary.simpleMessage(
      "Welcome to Mongez",
    ),
    "whenClientBooks": MessageLookupByLibrary.simpleMessage(
      "When a client books your service it will land here.",
    ),
    "withinKm": m15,
    "workerLateCancel": MessageLookupByLibrary.simpleMessage(
      "The worker is late — you can now cancel",
    ),
    "workerMarkedFinished": MessageLookupByLibrary.simpleMessage(
      "The worker marked this job as finished",
    ),
    "workerRole": MessageLookupByLibrary.simpleMessage("Worker"),
    "workerVerificationNotice": MessageLookupByLibrary.simpleMessage(
      "Your account will be reviewed by an admin before you can start working.",
    ),
    "workingHours": MessageLookupByLibrary.simpleMessage("Working hours"),
    "years": MessageLookupByLibrary.simpleMessage("years"),
    "yearsOfExperience": MessageLookupByLibrary.simpleMessage(
      "Years of Experience",
    ),
    "yearsShort": MessageLookupByLibrary.simpleMessage("y"),
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
  };
}
