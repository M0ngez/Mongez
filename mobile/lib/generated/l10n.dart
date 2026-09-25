// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Fix your home issues quickly & safely`
  String get getStartedSubtitle {
    return Intl.message(
      'Fix your home issues quickly & safely',
      name: 'getStartedSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Got a problem at home?\nRequest a trusted technician in minutes with ease.\n\n✓ Trusted technician selections\n✓ Step-by-step order tracking\n✓ Simple and easy-to-use experience`
  String get getStartedDescription {
    return Intl.message(
      'Got a problem at home?\nRequest a trusted technician in minutes with ease.\n\n✓ Trusted technician selections\n✓ Step-by-step order tracking\n✓ Simple and easy-to-use experience',
      name: 'getStartedDescription',
      desc: '',
      args: [],
    );
  }

  /// `Get Started`
  String get getStartedButton {
    return Intl.message(
      'Get Started',
      name: 'getStartedButton',
      desc: '',
      args: [],
    );
  }

  /// `Don't worry, your data is 100% safe with us`
  String get getStartedFooter {
    return Intl.message(
      'Don\'t worry, your data is 100% safe with us',
      name: 'getStartedFooter',
      desc: '',
      args: [],
    );
  }

  /// `Hello, {name}!`
  String hello(Object name) {
    return Intl.message('Hello, $name!', name: 'hello', desc: '', args: [name]);
  }

  /// `Skip`
  String get skip {
    return Intl.message('Skip', name: 'skip', desc: '', args: []);
  }

  /// `Next`
  String get next {
    return Intl.message('Next', name: 'next', desc: '', args: []);
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `How It Works`
  String get howItWorks {
    return Intl.message('How It Works', name: 'howItWorks', desc: '', args: []);
  }

  /// `Easy interface\nConnect & request a technician quickly`
  String get firstScreenDesc {
    return Intl.message(
      'Easy interface\nConnect & request a technician quickly',
      name: 'firstScreenDesc',
      desc: '',
      args: [],
    );
  }

  /// `Trusted Services`
  String get trustedServices {
    return Intl.message(
      'Trusted Services',
      name: 'trustedServices',
      desc: '',
      args: [],
    );
  }

  /// `Talk directly with technicians\nSmooth and fast experience`
  String get secondScreenDesc {
    return Intl.message(
      'Talk directly with technicians\nSmooth and fast experience',
      name: 'secondScreenDesc',
      desc: '',
      args: [],
    );
  }

  /// `Easy Requests`
  String get easyRequests {
    return Intl.message(
      'Easy Requests',
      name: 'easyRequests',
      desc: '',
      args: [],
    );
  }

  /// `Send issues & track responses\nFast and smooth experience`
  String get thirdScreenDesc {
    return Intl.message(
      'Send issues & track responses\nFast and smooth experience',
      name: 'thirdScreenDesc',
      desc: '',
      args: [],
    );
  }

  /// `Welcome`
  String get welcome {
    return Intl.message('Welcome', name: 'welcome', desc: '', args: []);
  }

  /// `Start fixing any home issue quickly and easily!`
  String get chooseAccountSubtitle {
    return Intl.message(
      'Start fixing any home issue quickly and easily!',
      name: 'chooseAccountSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Customer`
  String get customer {
    return Intl.message('Customer', name: 'customer', desc: '', args: []);
  }

  /// `Technician`
  String get technician {
    return Intl.message('Technician', name: 'technician', desc: '', args: []);
  }

  /// `Join now and enjoy an easier and faster way to fix all your home issues!`
  String get chooseAccountFooter {
    return Intl.message(
      'Join now and enjoy an easier and faster way to fix all your home issues!',
      name: 'chooseAccountFooter',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email {
    return Intl.message('Email', name: 'email', desc: '', args: []);
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Please enter your email`
  String get pleaseEnterYourEmail {
    return Intl.message(
      'Please enter your email',
      name: 'pleaseEnterYourEmail',
      desc: '',
      args: [],
    );
  }

  /// `Invalid email`
  String get invalidEmail {
    return Intl.message(
      'Invalid email',
      name: 'invalidEmail',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your password`
  String get pleaseEnterYourPassword {
    return Intl.message(
      'Please enter your password',
      name: 'pleaseEnterYourPassword',
      desc: '',
      args: [],
    );
  }

  /// `Password is too short`
  String get passwordTooShort {
    return Intl.message(
      'Password is too short',
      name: 'passwordTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account?`
  String get dontHaveAccount {
    return Intl.message(
      'Don\'t have an account?',
      name: 'dontHaveAccount',
      desc: '',
      args: [],
    );
  }

  /// `Sign up`
  String get signUp {
    return Intl.message('Sign up', name: 'signUp', desc: '', args: []);
  }

  /// `Full Name`
  String get fullName {
    return Intl.message('Full Name', name: 'fullName', desc: '', args: []);
  }

  /// `Please enter your name`
  String get pleaseEnterYourName {
    return Intl.message(
      'Please enter your name',
      name: 'pleaseEnterYourName',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get phoneNumber {
    return Intl.message(
      'Phone Number',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your phone number`
  String get pleaseEnterYourPhoneNumber {
    return Intl.message(
      'Please enter your phone number',
      name: 'pleaseEnterYourPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Invalid phone number`
  String get invalidPhoneNumber {
    return Intl.message(
      'Invalid phone number',
      name: 'invalidPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Register`
  String get register {
    return Intl.message('Register', name: 'register', desc: '', args: []);
  }

  /// `Already have an account?`
  String get alreadyHaveAccount {
    return Intl.message(
      'Already have an account?',
      name: 'alreadyHaveAccount',
      desc: '',
      args: [],
    );
  }

  /// `Category`
  String get category {
    return Intl.message('Category', name: 'category', desc: '', args: []);
  }

  /// `View All`
  String get viewAll {
    return Intl.message('View All', name: 'viewAll', desc: '', args: []);
  }

  /// `Hot Deals`
  String get hotDeals {
    return Intl.message('Hot Deals', name: 'hotDeals', desc: '', args: []);
  }

  /// `My Services`
  String get myServices {
    return Intl.message('My Services', name: 'myServices', desc: '', args: []);
  }

  /// `Electric`
  String get electric {
    return Intl.message('Electric', name: 'electric', desc: '', args: []);
  }

  /// `Electric Fix`
  String get electricFix {
    return Intl.message(
      'Electric Fix',
      name: 'electricFix',
      desc: '',
      args: [],
    );
  }

  /// `Fix all your electric issues quickly and professionally.`
  String get electricFixDescription {
    return Intl.message(
      'Fix all your electric issues quickly and professionally.',
      name: 'electricFixDescription',
      desc: '',
      args: [],
    );
  }

  /// `Plumbing`
  String get plumbing {
    return Intl.message('Plumbing', name: 'plumbing', desc: '', args: []);
  }

  /// `Plumbing services with guaranteed quality.`
  String get plumbingDescription {
    return Intl.message(
      'Plumbing services with guaranteed quality.',
      name: 'plumbingDescription',
      desc: '',
      args: [],
    );
  }

  /// `Cleaning`
  String get cleaning {
    return Intl.message('Cleaning', name: 'cleaning', desc: '', args: []);
  }

  /// `Home and office cleaning services at your door.`
  String get cleaningDescription {
    return Intl.message(
      'Home and office cleaning services at your door.',
      name: 'cleaningDescription',
      desc: '',
      args: [],
    );
  }

  /// `Great service!`
  String get greatService {
    return Intl.message(
      'Great service!',
      name: 'greatService',
      desc: '',
      args: [],
    );
  }

  /// `Very professional!`
  String get veryProfessional {
    return Intl.message(
      'Very professional!',
      name: 'veryProfessional',
      desc: '',
      args: [],
    );
  }

  /// `Fast and reliable!`
  String get fastAndReliable {
    return Intl.message(
      'Fast and reliable!',
      name: 'fastAndReliable',
      desc: '',
      args: [],
    );
  }

  /// `Highly recommended!`
  String get highlyRecommended {
    return Intl.message(
      'Highly recommended!',
      name: 'highlyRecommended',
      desc: '',
      args: [],
    );
  }

  /// `Very thorough!`
  String get veryThorough {
    return Intl.message(
      'Very thorough!',
      name: 'veryThorough',
      desc: '',
      args: [],
    );
  }

  /// `Nice and friendly staff!`
  String get niceAndFriendlyStaff {
    return Intl.message(
      'Nice and friendly staff!',
      name: 'niceAndFriendlyStaff',
      desc: '',
      args: [],
    );
  }

  /// `123 Main Street, Cairo`
  String get addressMainStreetCairo {
    return Intl.message(
      '123 Main Street, Cairo',
      name: 'addressMainStreetCairo',
      desc: '',
      args: [],
    );
  }

  /// `45 Nile Street, Cairo`
  String get addressNileStreetCairo {
    return Intl.message(
      '45 Nile Street, Cairo',
      name: 'addressNileStreetCairo',
      desc: '',
      args: [],
    );
  }

  /// `67 Garden St, Giza`
  String get addressGardenStGiza {
    return Intl.message(
      '67 Garden St, Giza',
      name: 'addressGardenStGiza',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get location {
    return Intl.message('Location', name: 'location', desc: '', args: []);
  }

  /// `Dhaka, Bangladesh`
  String get currentLocation {
    return Intl.message(
      'Dhaka, Bangladesh',
      name: 'currentLocation',
      desc: '',
      args: [],
    );
  }

  /// `Service Provider`
  String get serviceProvider {
    return Intl.message(
      'Service Provider',
      name: 'serviceProvider',
      desc: '',
      args: [],
    );
  }

  /// `Book`
  String get book {
    return Intl.message('Book', name: 'book', desc: '', args: []);
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Find your favorite items`
  String get searchHint {
    return Intl.message(
      'Find your favorite items',
      name: 'searchHint',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Favorites`
  String get favorites {
    return Intl.message('Favorites', name: 'favorites', desc: '', args: []);
  }

  /// `Job History`
  String get jobHistory {
    return Intl.message('Job History', name: 'jobHistory', desc: '', args: []);
  }

  /// `Requests`
  String get requests {
    return Intl.message('Requests', name: 'requests', desc: '', args: []);
  }

  /// `Account`
  String get account {
    return Intl.message('Account', name: 'account', desc: '', args: []);
  }

  /// `Details`
  String get details {
    return Intl.message('Details', name: 'details', desc: '', args: []);
  }

  /// `Reviews`
  String get reviews {
    return Intl.message('Reviews', name: 'reviews', desc: '', args: []);
  }

  /// `Info`
  String get info {
    return Intl.message('Info', name: 'info', desc: '', args: []);
  }

  /// `Description`
  String get description {
    return Intl.message('Description', name: 'description', desc: '', args: []);
  }

  /// `Address`
  String get address {
    return Intl.message('Address', name: 'address', desc: '', args: []);
  }

  /// `View On Map`
  String get viewOnMap {
    return Intl.message('View On Map', name: 'viewOnMap', desc: '', args: []);
  }

  /// `Book Now`
  String get bookNow {
    return Intl.message('Book Now', name: 'bookNow', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `The service is fantastic! Very clean, professional, and fast. Highly recommended!`
  String get reviewExample {
    return Intl.message(
      'The service is fantastic! Very clean, professional, and fast. Highly recommended!',
      name: 'reviewExample',
      desc: '',
      args: [],
    );
  }

  /// `Add Service`
  String get addService {
    return Intl.message('Add Service', name: 'addService', desc: '', args: []);
  }

  /// `Add a new service you provide`
  String get addServiceDesc {
    return Intl.message(
      'Add a new service you provide',
      name: 'addServiceDesc',
      desc: '',
      args: [],
    );
  }

  /// `Edit Service`
  String get editService {
    return Intl.message(
      'Edit Service',
      name: 'editService',
      desc: '',
      args: [],
    );
  }

  /// `Update your service details`
  String get editServiceDesc {
    return Intl.message(
      'Update your service details',
      name: 'editServiceDesc',
      desc: '',
      args: [],
    );
  }

  /// `Addresses`
  String get addresses {
    return Intl.message('Addresses', name: 'addresses', desc: '', args: []);
  }

  /// `Manage your saved addresses`
  String get addressesDesc {
    return Intl.message(
      'Manage your saved addresses',
      name: 'addressesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Payment Methods`
  String get paymentMethods {
    return Intl.message(
      'Payment Methods',
      name: 'paymentMethods',
      desc: '',
      args: [],
    );
  }

  /// `Your cards & payment options`
  String get paymentMethodsDesc {
    return Intl.message(
      'Your cards & payment options',
      name: 'paymentMethodsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Manage app preferences`
  String get settingsDesc {
    return Intl.message(
      'Manage app preferences',
      name: 'settingsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logout`
  String get logout {
    return Intl.message('Logout', name: 'logout', desc: '', args: []);
  }

  /// `Are you sure you want to logout?`
  String get logoutConfirm {
    return Intl.message(
      'Are you sure you want to logout?',
      name: 'logoutConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Ratings`
  String get ratings {
    return Intl.message('Ratings', name: 'ratings', desc: '', args: []);
  }

  /// `Service Title`
  String get serviceTitle {
    return Intl.message(
      'Service Title',
      name: 'serviceTitle',
      desc: '',
      args: [],
    );
  }

  /// `Service Description`
  String get serviceDescription {
    return Intl.message(
      'Service Description',
      name: 'serviceDescription',
      desc: '',
      args: [],
    );
  }

  /// `Service Added`
  String get serviceAdded {
    return Intl.message(
      'Service Added',
      name: 'serviceAdded',
      desc: '',
      args: [],
    );
  }

  /// `Your service "{title}" has been successfully added.`
  String serviceAddedMessage(Object title) {
    return Intl.message(
      'Your service "$title" has been successfully added.',
      name: 'serviceAddedMessage',
      desc: '',
      args: [title],
    );
  }

  /// `OK`
  String get ok {
    return Intl.message('OK', name: 'ok', desc: '', args: []);
  }

  /// `My Requests`
  String get myRequests {
    return Intl.message('My Requests', name: 'myRequests', desc: '', args: []);
  }

  /// `Pending`
  String get pending {
    return Intl.message('Pending', name: 'pending', desc: '', args: []);
  }

  /// `Confirmed`
  String get confirmed {
    return Intl.message('Confirmed', name: 'confirmed', desc: '', args: []);
  }

  /// `Completed`
  String get completed {
    return Intl.message('Completed', name: 'completed', desc: '', args: []);
  }

  /// `Canceled`
  String get canceled {
    return Intl.message('Canceled', name: 'canceled', desc: '', args: []);
  }

  /// `Date`
  String get date {
    return Intl.message('Date', name: 'date', desc: '', args: []);
  }

  /// `Cancel Request`
  String get cancelRequest {
    return Intl.message(
      'Cancel Request',
      name: 'cancelRequest',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to cancel this request?`
  String get cancelRequestConfirm {
    return Intl.message(
      'Are you sure you want to cancel this request?',
      name: 'cancelRequestConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get yes {
    return Intl.message('Yes', name: 'yes', desc: '', args: []);
  }

  /// `No`
  String get no {
    return Intl.message('No', name: 'no', desc: '', args: []);
  }

  /// `Fixing power outage in living room`
  String get electricFixRequestDesc {
    return Intl.message(
      'Fixing power outage in living room',
      name: 'electricFixRequestDesc',
      desc: '',
      args: [],
    );
  }

  /// `Plumbing Service`
  String get plumbingService {
    return Intl.message(
      'Plumbing Service',
      name: 'plumbingService',
      desc: '',
      args: [],
    );
  }

  /// `Kitchen sink leaking`
  String get plumbingServiceRequestDesc {
    return Intl.message(
      'Kitchen sink leaking',
      name: 'plumbingServiceRequestDesc',
      desc: '',
      args: [],
    );
  }

  /// `Cleaning Service`
  String get cleaningService {
    return Intl.message(
      'Cleaning Service',
      name: 'cleaningService',
      desc: '',
      args: [],
    );
  }

  /// `Full apartment cleaning`
  String get cleaningServiceRequestDesc {
    return Intl.message(
      'Full apartment cleaning',
      name: 'cleaningServiceRequestDesc',
      desc: '',
      args: [],
    );
  }

  /// `AC Maintenance`
  String get acMaintenance {
    return Intl.message(
      'AC Maintenance',
      name: 'acMaintenance',
      desc: '',
      args: [],
    );
  }

  /// `AC not cooling properly`
  String get acMaintenanceRequestDesc {
    return Intl.message(
      'AC not cooling properly',
      name: 'acMaintenanceRequestDesc',
      desc: '',
      args: [],
    );
  }

  /// `Checkout`
  String get checkout {
    return Intl.message('Checkout', name: 'checkout', desc: '', args: []);
  }

  /// `Delivery Address`
  String get deliveryAddress {
    return Intl.message(
      'Delivery Address',
      name: 'deliveryAddress',
      desc: '',
      args: [],
    );
  }

  /// `Change`
  String get change {
    return Intl.message('Change', name: 'change', desc: '', args: []);
  }

  /// `Payment Method`
  String get paymentMethod {
    return Intl.message(
      'Payment Method',
      name: 'paymentMethod',
      desc: '',
      args: [],
    );
  }

  /// `Card`
  String get card {
    return Intl.message('Card', name: 'card', desc: '', args: []);
  }

  /// `Cash`
  String get cash {
    return Intl.message('Cash', name: 'cash', desc: '', args: []);
  }

  /// `Pay`
  String get applePay {
    return Intl.message('Pay', name: 'applePay', desc: '', args: []);
  }

  /// `Enter problem description`
  String get enterProblem {
    return Intl.message(
      'Enter problem description',
      name: 'enterProblem',
      desc: '',
      args: [],
    );
  }

  /// `Booking Fee`
  String get bookingFee {
    return Intl.message('Booking Fee', name: 'bookingFee', desc: '', args: []);
  }

  /// `Price`
  String get price {
    return Intl.message('Price', name: 'price', desc: '', args: []);
  }

  /// `Note: If you cancel the service, your booking fee will not be refunded.`
  String get note {
    return Intl.message(
      'Note: If you cancel the service, your booking fee will not be refunded.',
      name: 'note',
      desc: '',
      args: [],
    );
  }

  /// `Promo Code`
  String get promoCode {
    return Intl.message('Promo Code', name: 'promoCode', desc: '', args: []);
  }

  /// `Enter Promo Code`
  String get enterPromo {
    return Intl.message(
      'Enter Promo Code',
      name: 'enterPromo',
      desc: '',
      args: [],
    );
  }

  /// `Apply`
  String get apply {
    return Intl.message('Apply', name: 'apply', desc: '', args: []);
  }

  /// `Place Order`
  String get placeOrder {
    return Intl.message('Place Order', name: 'placeOrder', desc: '', args: []);
  }

  /// `Order Placed!`
  String get orderPlaced {
    return Intl.message(
      'Order Placed!',
      name: 'orderPlaced',
      desc: '',
      args: [],
    );
  }

  /// `Your order has been successfully placed.`
  String get orderSuccess {
    return Intl.message(
      'Your order has been successfully placed.',
      name: 'orderSuccess',
      desc: '',
      args: [],
    );
  }

  /// `My Cards`
  String get myCards {
    return Intl.message('My Cards', name: 'myCards', desc: '', args: []);
  }

  /// `Cards`
  String get cards {
    return Intl.message('Cards', name: 'cards', desc: '', args: []);
  }

  /// `Add New Card`
  String get addNewCard {
    return Intl.message('Add New Card', name: 'addNewCard', desc: '', args: []);
  }

  /// `Default`
  String get defaultLabel {
    return Intl.message('Default', name: 'defaultLabel', desc: '', args: []);
  }

  /// `Add Debit or Credit Card`
  String get addDebitOrCreditCard {
    return Intl.message(
      'Add Debit or Credit Card',
      name: 'addDebitOrCreditCard',
      desc: '',
      args: [],
    );
  }

  /// `Card Number`
  String get cardNumber {
    return Intl.message('Card Number', name: 'cardNumber', desc: '', args: []);
  }

  /// `Expiry Date`
  String get expiryDate {
    return Intl.message('Expiry Date', name: 'expiryDate', desc: '', args: []);
  }

  /// `CVV`
  String get cvv {
    return Intl.message('CVV', name: 'cvv', desc: '', args: []);
  }

  /// `My Addresses`
  String get addressesPageTitle {
    return Intl.message(
      'My Addresses',
      name: 'addressesPageTitle',
      desc: '',
      args: [],
    );
  }

  /// `Add New Address`
  String get addNewAddress {
    return Intl.message(
      'Add New Address',
      name: 'addNewAddress',
      desc: '',
      args: [],
    );
  }

  /// `Address Nickname`
  String get addressNickname {
    return Intl.message(
      'Address Nickname',
      name: 'addressNickname',
      desc: '',
      args: [],
    );
  }

  /// `Address Details`
  String get addressDetails {
    return Intl.message(
      'Address Details',
      name: 'addressDetails',
      desc: '',
      args: [],
    );
  }

  /// `Make this as a default`
  String get makeDefault {
    return Intl.message(
      'Make this as a default',
      name: 'makeDefault',
      desc: '',
      args: [],
    );
  }

  /// `Request Details`
  String get requestDetails {
    return Intl.message(
      'Request Details',
      name: 'requestDetails',
      desc: '',
      args: [],
    );
  }

  /// `Status: `
  String get statusLabel {
    return Intl.message('Status: ', name: 'statusLabel', desc: '', args: []);
  }

  /// `Accept`
  String get accept {
    return Intl.message('Accept', name: 'accept', desc: '', args: []);
  }

  /// `In Progress`
  String get inProgress {
    return Intl.message('In Progress', name: 'inProgress', desc: '', args: []);
  }

  /// `Rejected`
  String get rejected {
    return Intl.message('Rejected', name: 'rejected', desc: '', args: []);
  }

  /// `No favorites yet`
  String get noFavorites {
    return Intl.message(
      'No favorites yet',
      name: 'noFavorites',
      desc: '',
      args: [],
    );
  }

  /// `No requests`
  String get noRequests {
    return Intl.message('No requests', name: 'noRequests', desc: '', args: []);
  }

  /// `No pending requests`
  String get noPendingRequests {
    return Intl.message(
      'No pending requests',
      name: 'noPendingRequests',
      desc: '',
      args: [],
    );
  }

  /// `Whenever`
  String get urgencyWhenever {
    return Intl.message(
      'Whenever',
      name: 'urgencyWhenever',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get urgencyToday {
    return Intl.message('Today', name: 'urgencyToday', desc: '', args: []);
  }

  /// `Emergency`
  String get urgencyEmergency {
    return Intl.message(
      'Emergency',
      name: 'urgencyEmergency',
      desc: '',
      args: [],
    );
  }

  /// `Experience`
  String get experience {
    return Intl.message('Experience', name: 'experience', desc: '', args: []);
  }

  /// `Years of Experience`
  String get yearsOfExperience {
    return Intl.message(
      'Years of Experience',
      name: 'yearsOfExperience',
      desc: '',
      args: [],
    );
  }

  /// `years`
  String get years {
    return Intl.message('years', name: 'years', desc: '', args: []);
  }

  /// `y`
  String get yearsShort {
    return Intl.message('y', name: 'yearsShort', desc: '', args: []);
  }

  /// `jobs`
  String get jobs {
    return Intl.message('jobs', name: 'jobs', desc: '', args: []);
  }

  /// `No job history`
  String get noJobHistory {
    return Intl.message(
      'No job history',
      name: 'noJobHistory',
      desc: '',
      args: [],
    );
  }

  /// `Specializes in`
  String get specializesIn {
    return Intl.message(
      'Specializes in',
      name: 'specializesIn',
      desc: '',
      args: [],
    );
  }

  /// `Specialties`
  String get specialties {
    return Intl.message('Specialties', name: 'specialties', desc: '', args: []);
  }

  /// `Select a category`
  String get selectCategory {
    return Intl.message(
      'Select a category',
      name: 'selectCategory',
      desc: '',
      args: [],
    );
  }

  /// `Available for Work`
  String get availableForWork {
    return Intl.message(
      'Available for Work',
      name: 'availableForWork',
      desc: '',
      args: [],
    );
  }

  /// `Create Profile`
  String get createProfile {
    return Intl.message(
      'Create Profile',
      name: 'createProfile',
      desc: '',
      args: [],
    );
  }

  /// `Profile Created`
  String get profileCreated {
    return Intl.message(
      'Profile Created',
      name: 'profileCreated',
      desc: '',
      args: [],
    );
  }

  /// `Your worker profile has been created successfully.`
  String get profileCreatedMessage {
    return Intl.message(
      'Your worker profile has been created successfully.',
      name: 'profileCreatedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Your service has been updated successfully.`
  String get serviceUpdatedMessage {
    return Intl.message(
      'Your service has been updated successfully.',
      name: 'serviceUpdatedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Dark Mode`
  String get darkMode {
    return Intl.message('Dark Mode', name: 'darkMode', desc: '', args: []);
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `العربية`
  String get arabic {
    return Intl.message('العربية', name: 'arabic', desc: '', args: []);
  }

  /// `English`
  String get english {
    return Intl.message('English', name: 'english', desc: '', args: []);
  }

  /// `Arabic`
  String get languageArabic {
    return Intl.message('Arabic', name: 'languageArabic', desc: '', args: []);
  }

  /// `English`
  String get languageEnglish {
    return Intl.message('English', name: 'languageEnglish', desc: '', args: []);
  }

  /// `French`
  String get languageFrench {
    return Intl.message('French', name: 'languageFrench', desc: '', args: []);
  }

  /// `Creating profile...`
  String get creatingProfile {
    return Intl.message(
      'Creating profile...',
      name: 'creatingProfile',
      desc: '',
      args: [],
    );
  }

  /// `Tell us about your skills and experience`
  String get descriptionHint {
    return Intl.message(
      'Tell us about your skills and experience',
      name: 'descriptionHint',
      desc: '',
      args: [],
    );
  }

  /// `No reviews yet`
  String get noReviews {
    return Intl.message(
      'No reviews yet',
      name: 'noReviews',
      desc: '',
      args: [],
    );
  }

  /// `Anonymous`
  String get anonymous {
    return Intl.message('Anonymous', name: 'anonymous', desc: '', args: []);
  }

  /// `Use account phone`
  String get useAccountPhone {
    return Intl.message(
      'Use account phone',
      name: 'useAccountPhone',
      desc: '',
      args: [],
    );
  }

  /// `Use saved address`
  String get useSavedAddress {
    return Intl.message(
      'Use saved address',
      name: 'useSavedAddress',
      desc: '',
      args: [],
    );
  }

  /// `Order Details`
  String get orderDetails {
    return Intl.message(
      'Order Details',
      name: 'orderDetails',
      desc: '',
      args: [],
    );
  }

  /// `Contact Information`
  String get contactInfo {
    return Intl.message(
      'Contact Information',
      name: 'contactInfo',
      desc: '',
      args: [],
    );
  }

  /// `Phone for this order`
  String get phoneForOrder {
    return Intl.message(
      'Phone for this order',
      name: 'phoneForOrder',
      desc: '',
      args: [],
    );
  }

  /// `Address for this order`
  String get addressForOrder {
    return Intl.message(
      'Address for this order',
      name: 'addressForOrder',
      desc: '',
      args: [],
    );
  }

  /// `Rate Service`
  String get rateService {
    return Intl.message(
      'Rate Service',
      name: 'rateService',
      desc: '',
      args: [],
    );
  }

  /// `Submit Rating`
  String get submitRating {
    return Intl.message(
      'Submit Rating',
      name: 'submitRating',
      desc: '',
      args: [],
    );
  }

  /// `Submitting...`
  String get submitting {
    return Intl.message(
      'Submitting...',
      name: 'submitting',
      desc: '',
      args: [],
    );
  }

  /// `Rating submitted successfully!`
  String get ratingSubmitted {
    return Intl.message(
      'Rating submitted successfully!',
      name: 'ratingSubmitted',
      desc: '',
      args: [],
    );
  }

  /// `Share your experience (optional)`
  String get reviewHint {
    return Intl.message(
      'Share your experience (optional)',
      name: 'reviewHint',
      desc: '',
      args: [],
    );
  }

  /// `Rate`
  String get rateOrder {
    return Intl.message('Rate', name: 'rateOrder', desc: '', args: []);
  }

  /// `An error occurred. Please try again.`
  String get errorOccurred {
    return Intl.message(
      'An error occurred. Please try again.',
      name: 'errorOccurred',
      desc: '',
      args: [],
    );
  }

  /// `Waiting Confirmation`
  String get waitingConfirmation {
    return Intl.message(
      'Waiting Confirmation',
      name: 'waitingConfirmation',
      desc: '',
      args: [],
    );
  }

  /// `Mark as Finished`
  String get markAsFinished {
    return Intl.message(
      'Mark as Finished',
      name: 'markAsFinished',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Completion`
  String get confirmCompletion {
    return Intl.message(
      'Confirm Completion',
      name: 'confirmCompletion',
      desc: '',
      args: [],
    );
  }

  /// `The worker marked this job as finished`
  String get workerMarkedFinished {
    return Intl.message(
      'The worker marked this job as finished',
      name: 'workerMarkedFinished',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled by you`
  String get cancelledByYou {
    return Intl.message(
      'Cancelled by you',
      name: 'cancelledByYou',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled by the customer`
  String get cancelledByCustomer {
    return Intl.message(
      'Cancelled by the customer',
      name: 'cancelledByCustomer',
      desc: '',
      args: [],
    );
  }

  /// `Rejected by the worker`
  String get rejectedByWorker {
    return Intl.message(
      'Rejected by the worker',
      name: 'rejectedByWorker',
      desc: '',
      args: [],
    );
  }

  /// `Rejected by you`
  String get rejectedByYou {
    return Intl.message(
      'Rejected by you',
      name: 'rejectedByYou',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notifications {
    return Intl.message(
      'Notifications',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `Mark all as read`
  String get markAllRead {
    return Intl.message(
      'Mark all as read',
      name: 'markAllRead',
      desc: '',
      args: [],
    );
  }

  /// `No notifications yet`
  String get noNotifications {
    return Intl.message(
      'No notifications yet',
      name: 'noNotifications',
      desc: '',
      args: [],
    );
  }

  /// `If the worker is late, you can cancel in {time}`
  String cancelIn(Object time) {
    return Intl.message(
      'If the worker is late, you can cancel in $time',
      name: 'cancelIn',
      desc: '',
      args: [time],
    );
  }

  /// `The worker is late — you can now cancel`
  String get workerLateCancel {
    return Intl.message(
      'The worker is late — you can now cancel',
      name: 'workerLateCancel',
      desc: '',
      args: [],
    );
  }

  /// `Tap to select an address`
  String get tapToSelectAddress {
    return Intl.message(
      'Tap to select an address',
      name: 'tapToSelectAddress',
      desc: '',
      args: [],
    );
  }

  /// `No addresses yet`
  String get noAddresses {
    return Intl.message(
      'No addresses yet',
      name: 'noAddresses',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load`
  String get failedToLoad {
    return Intl.message(
      'Failed to load',
      name: 'failedToLoad',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get retry {
    return Intl.message('Retry', name: 'retry', desc: '', args: []);
  }

  /// `e.g. 12 Street Name, District`
  String get addressDetailsHint {
    return Intl.message(
      'e.g. 12 Street Name, District',
      name: 'addressDetailsHint',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to Mongez`
  String get welcomeToMongez {
    return Intl.message(
      'Welcome to Mongez',
      name: 'welcomeToMongez',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to continue`
  String get signInToContinue {
    return Intl.message(
      'Sign in to continue',
      name: 'signInToContinue',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Google`
  String get signInWithGoogle {
    return Intl.message(
      'Sign in with Google',
      name: 'signInWithGoogle',
      desc: '',
      args: [],
    );
  }

  /// `Google sign-in failed`
  String get googleSignInFailed {
    return Intl.message(
      'Google sign-in failed',
      name: 'googleSignInFailed',
      desc: '',
      args: [],
    );
  }

  /// `Account Not Approved`
  String get accountNotApproved {
    return Intl.message(
      'Account Not Approved',
      name: 'accountNotApproved',
      desc: '',
      args: [],
    );
  }

  /// `Account Under Review`
  String get accountUnderReview {
    return Intl.message(
      'Account Under Review',
      name: 'accountUnderReview',
      desc: '',
      args: [],
    );
  }

  /// `Your registration has been rejected.`
  String get registrationRejected {
    return Intl.message(
      'Your registration has been rejected.',
      name: 'registrationRejected',
      desc: '',
      args: [],
    );
  }

  /// `Your registration has been received and is currently being reviewed. We will contact you to complete the verification process and activate your account.`
  String get registrationUnderReview {
    return Intl.message(
      'Your registration has been received and is currently being reviewed. We will contact you to complete the verification process and activate your account.',
      name: 'registrationUnderReview',
      desc: '',
      args: [],
    );
  }

  /// `Reason:`
  String get reason {
    return Intl.message('Reason:', name: 'reason', desc: '', args: []);
  }

  /// `Need a service?`
  String get needAService {
    return Intl.message(
      'Need a service?',
      name: 'needAService',
      desc: '',
      args: [],
    );
  }

  /// `Welcome back,`
  String get welcomeBack {
    return Intl.message(
      'Welcome back,',
      name: 'welcomeBack',
      desc: '',
      args: [],
    );
  }

  /// `Verified`
  String get verified {
    return Intl.message('Verified', name: 'verified', desc: '', args: []);
  }

  /// `Available — clients can book you now`
  String get availableDescription {
    return Intl.message(
      'Available — clients can book you now',
      name: 'availableDescription',
      desc: '',
      args: [],
    );
  }

  /// `Offline — you won't receive new bookings`
  String get offlineDescription {
    return Intl.message(
      'Offline — you won\'t receive new bookings',
      name: 'offlineDescription',
      desc: '',
      args: [],
    );
  }

  /// `Finish setting up your worker profile`
  String get finishProfileSetup {
    return Intl.message(
      'Finish setting up your worker profile',
      name: 'finishProfileSetup',
      desc: '',
      args: [],
    );
  }

  /// `Pick a service & experience so clients can find you.`
  String get setupSubtitle {
    return Intl.message(
      'Pick a service & experience so clients can find you.',
      name: 'setupSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Set up`
  String get setUp {
    return Intl.message('Set up', name: 'setUp', desc: '', args: []);
  }

  /// `Completed`
  String get completedStats {
    return Intl.message(
      'Completed',
      name: 'completedStats',
      desc: '',
      args: [],
    );
  }

  /// `this month: {count}`
  String thisMonthCount(Object count) {
    return Intl.message(
      'this month: $count',
      name: 'thisMonthCount',
      desc: '',
      args: [count],
    );
  }

  /// `awaiting your reply`
  String get awaitingReply {
    return Intl.message(
      'awaiting your reply',
      name: 'awaitingReply',
      desc: '',
      args: [],
    );
  }

  /// `Rating`
  String get ratingStats {
    return Intl.message('Rating', name: 'ratingStats', desc: '', args: []);
  }

  /// `{count} recent`
  String recentCount(Object count) {
    return Intl.message(
      '$count recent',
      name: 'recentCount',
      desc: '',
      args: [count],
    );
  }

  /// `My service`
  String get myService {
    return Intl.message('My service', name: 'myService', desc: '', args: []);
  }

  /// `Incoming requests`
  String get incomingRequests {
    return Intl.message(
      'Incoming requests',
      name: 'incomingRequests',
      desc: '',
      args: [],
    );
  }

  /// `{count} new`
  String newCount(Object count) {
    return Intl.message(
      '$count new',
      name: 'newCount',
      desc: '',
      args: [count],
    );
  }

  /// `Could not load requests`
  String get couldNotLoadRequests {
    return Intl.message(
      'Could not load requests',
      name: 'couldNotLoadRequests',
      desc: '',
      args: [],
    );
  }

  /// `No requests yet`
  String get noRequestsYet {
    return Intl.message(
      'No requests yet',
      name: 'noRequestsYet',
      desc: '',
      args: [],
    );
  }

  /// `When a client books your service it will land here.`
  String get whenClientBooks {
    return Intl.message(
      'When a client books your service it will land here.',
      name: 'whenClientBooks',
      desc: '',
      args: [],
    );
  }

  /// `Recent reviews`
  String get recentReviews {
    return Intl.message(
      'Recent reviews',
      name: 'recentReviews',
      desc: '',
      args: [],
    );
  }

  /// `per hour`
  String get perHour {
    return Intl.message('per hour', name: 'perHour', desc: '', args: []);
  }

  /// `Available`
  String get availableStatus {
    return Intl.message(
      'Available',
      name: 'availableStatus',
      desc: '',
      args: [],
    );
  }

  /// `Busy`
  String get busyStatus {
    return Intl.message('Busy', name: 'busyStatus', desc: '', args: []);
  }

  /// `Hourly rate`
  String get hourlyRate {
    return Intl.message('Hourly rate', name: 'hourlyRate', desc: '', args: []);
  }

  /// `Call-out fee`
  String get callOutFee {
    return Intl.message('Call-out fee', name: 'callOutFee', desc: '', args: []);
  }

  /// `Avg. response`
  String get avgResponse {
    return Intl.message(
      'Avg. response',
      name: 'avgResponse',
      desc: '',
      args: [],
    );
  }

  /// `Working hours`
  String get workingHours {
    return Intl.message(
      'Working hours',
      name: 'workingHours',
      desc: '',
      args: [],
    );
  }

  /// `Languages`
  String get languages {
    return Intl.message('Languages', name: 'languages', desc: '', args: []);
  }

  /// `Service area`
  String get serviceArea {
    return Intl.message(
      'Service area',
      name: 'serviceArea',
      desc: '',
      args: [],
    );
  }

  /// `within {km} km`
  String withinKm(Object km) {
    return Intl.message(
      'within $km km',
      name: 'withinKm',
      desc: '',
      args: [km],
    );
  }

  /// `Top rated`
  String get topRated {
    return Intl.message('Top rated', name: 'topRated', desc: '', args: []);
  }

  /// `Complete`
  String get completeStats {
    return Intl.message('Complete', name: 'completeStats', desc: '', args: []);
  }

  /// `Accept`
  String get acceptStats {
    return Intl.message('Accept', name: 'acceptStats', desc: '', args: []);
  }

  /// `This field is required`
  String get thisFieldRequired {
    return Intl.message(
      'This field is required',
      name: 'thisFieldRequired',
      desc: '',
      args: [],
    );
  }

  /// `Phone number is too long`
  String get phoneTooLong {
    return Intl.message(
      'Phone number is too long',
      name: 'phoneTooLong',
      desc: '',
      args: [],
    );
  }

  /// `Add up to 4 photos or a voice note (max 2 min) to explain the issue`
  String get addPhotosOrVoice {
    return Intl.message(
      'Add up to 4 photos or a voice note (max 2 min) to explain the issue',
      name: 'addPhotosOrVoice',
      desc: '',
      args: [],
    );
  }

  /// `Maximum of 4 photos reached`
  String get maxPhotosReached {
    return Intl.message(
      'Maximum of 4 photos reached',
      name: 'maxPhotosReached',
      desc: '',
      args: [],
    );
  }

  /// `You can cancel the order within one hour after the technician accepts.`
  String get cancelWithinHour {
    return Intl.message(
      'You can cancel the order within one hour after the technician accepts.',
      name: 'cancelWithinHour',
      desc: '',
      args: [],
    );
  }

  /// `Not set`
  String get notSet {
    return Intl.message('Not set', name: 'notSet', desc: '', args: []);
  }

  /// `e.g. Home, Office`
  String get addressLabelHint {
    return Intl.message(
      'e.g. Home, Office',
      name: 'addressLabelHint',
      desc: '',
      args: [],
    );
  }

  /// `Governorate`
  String get governorateHint {
    return Intl.message(
      'Governorate',
      name: 'governorateHint',
      desc: '',
      args: [],
    );
  }

  /// `Area / District (e.g. Al-Haram, Downtown)`
  String get areaDistrictHint {
    return Intl.message(
      'Area / District (e.g. Al-Haram, Downtown)',
      name: 'areaDistrictHint',
      desc: '',
      args: [],
    );
  }

  /// `Please pick your governorate`
  String get pleasePickGovernorate {
    return Intl.message(
      'Please pick your governorate',
      name: 'pleasePickGovernorate',
      desc: '',
      args: [],
    );
  }

  /// `Camera not supported on this platform`
  String get cameraNotSupported {
    return Intl.message(
      'Camera not supported on this platform',
      name: 'cameraNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `Could not open camera`
  String get couldNotOpenCamera {
    return Intl.message(
      'Could not open camera',
      name: 'couldNotOpenCamera',
      desc: '',
      args: [],
    );
  }

  /// `Gallery not supported on this platform`
  String get galleryNotSupported {
    return Intl.message(
      'Gallery not supported on this platform',
      name: 'galleryNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `Could not open gallery`
  String get couldNotOpenGallery {
    return Intl.message(
      'Could not open gallery',
      name: 'couldNotOpenGallery',
      desc: '',
      args: [],
    );
  }

  /// `Audio recording is not supported on this platform`
  String get audioNotSupported {
    return Intl.message(
      'Audio recording is not supported on this platform',
      name: 'audioNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `Microphone permission denied`
  String get micPermissionDenied {
    return Intl.message(
      'Microphone permission denied',
      name: 'micPermissionDenied',
      desc: '',
      args: [],
    );
  }

  /// `Microphone permission unavailable`
  String get micPermissionUnavailable {
    return Intl.message(
      'Microphone permission unavailable',
      name: 'micPermissionUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Could not start recording`
  String get couldNotStartRecording {
    return Intl.message(
      'Could not start recording',
      name: 'couldNotStartRecording',
      desc: '',
      args: [],
    );
  }

  /// `Camera`
  String get cameraOption {
    return Intl.message('Camera', name: 'cameraOption', desc: '', args: []);
  }

  /// `Gallery`
  String get galleryOption {
    return Intl.message('Gallery', name: 'galleryOption', desc: '', args: []);
  }

  /// `Re-record`
  String get rerecord {
    return Intl.message('Re-record', name: 'rerecord', desc: '', args: []);
  }

  /// `Record`
  String get record {
    return Intl.message('Record', name: 'record', desc: '', args: []);
  }

  /// `Voice note`
  String get voiceNote {
    return Intl.message('Voice note', name: 'voiceNote', desc: '', args: []);
  }

  /// `Just now`
  String get justNow {
    return Intl.message('Just now', name: 'justNow', desc: '', args: []);
  }

  /// `{minutes}m ago`
  String minutesAgo(Object minutes) {
    return Intl.message(
      '${minutes}m ago',
      name: 'minutesAgo',
      desc: '',
      args: [minutes],
    );
  }

  /// `{hours}h ago`
  String hoursAgo(Object hours) {
    return Intl.message(
      '${hours}h ago',
      name: 'hoursAgo',
      desc: '',
      args: [hours],
    );
  }

  /// `{days}d ago`
  String daysAgo(Object days) {
    return Intl.message(
      '${days}d ago',
      name: 'daysAgo',
      desc: '',
      args: [days],
    );
  }

  /// `Search for workers and services`
  String get searchForWorkers {
    return Intl.message(
      'Search for workers and services',
      name: 'searchForWorkers',
      desc: '',
      args: [],
    );
  }

  /// `No results found`
  String get noResultsFound {
    return Intl.message(
      'No results found',
      name: 'noResultsFound',
      desc: '',
      args: [],
    );
  }

  /// `Filter`
  String get filter {
    return Intl.message('Filter', name: 'filter', desc: '', args: []);
  }

  /// `All`
  String get allCategories {
    return Intl.message('All', name: 'allCategories', desc: '', args: []);
  }

  /// `Minimum Rating`
  String get minimumRating {
    return Intl.message(
      'Minimum Rating',
      name: 'minimumRating',
      desc: '',
      args: [],
    );
  }

  /// `Available only`
  String get availableOnly {
    return Intl.message(
      'Available only',
      name: 'availableOnly',
      desc: '',
      args: [],
    );
  }

  /// `Apply Filters`
  String get applyFilters {
    return Intl.message(
      'Apply Filters',
      name: 'applyFilters',
      desc: '',
      args: [],
    );
  }

  /// `Profile updated`
  String get profileUpdated {
    return Intl.message(
      'Profile updated',
      name: 'profileUpdated',
      desc: '',
      args: [],
    );
  }

  /// `Edit profile`
  String get editProfile {
    return Intl.message(
      'Edit profile',
      name: 'editProfile',
      desc: '',
      args: [],
    );
  }

  /// `Personal`
  String get personal {
    return Intl.message('Personal', name: 'personal', desc: '', args: []);
  }

  /// `e.g. Ahmed Hassan`
  String get fullNameHint {
    return Intl.message(
      'e.g. Ahmed Hassan',
      name: 'fullNameHint',
      desc: '',
      args: [],
    );
  }

  /// `Please enter your phone`
  String get pleaseEnterPhone {
    return Intl.message(
      'Please enter your phone',
      name: 'pleaseEnterPhone',
      desc: '',
      args: [],
    );
  }

  /// `Phone too short`
  String get phoneTooShort {
    return Intl.message(
      'Phone too short',
      name: 'phoneTooShort',
      desc: '',
      args: [],
    );
  }

  /// `Email (optional)`
  String get emailOptional {
    return Intl.message(
      'Email (optional)',
      name: 'emailOptional',
      desc: '',
      args: [],
    );
  }

  /// `City / Area`
  String get cityArea {
    return Intl.message('City / Area', name: 'cityArea', desc: '', args: []);
  }

  /// `e.g. Nasr City`
  String get cityAreaHint {
    return Intl.message(
      'e.g. Nasr City',
      name: 'cityAreaHint',
      desc: '',
      args: [],
    );
  }

  /// `Detailed Address`
  String get detailedAddress {
    return Intl.message(
      'Detailed Address',
      name: 'detailedAddress',
      desc: '',
      args: [],
    );
  }

  /// `Saving…`
  String get saving {
    return Intl.message('Saving…', name: 'saving', desc: '', args: []);
  }

  /// `Save changes`
  String get saveChanges {
    return Intl.message(
      'Save changes',
      name: 'saveChanges',
      desc: '',
      args: [],
    );
  }

  /// `Image picking is not supported on this platform`
  String get imageNotSupported {
    return Intl.message(
      'Image picking is not supported on this platform',
      name: 'imageNotSupported',
      desc: '',
      args: [],
    );
  }

  /// `Failed to pick image`
  String get failedToPickImage {
    return Intl.message(
      'Failed to pick image',
      name: 'failedToPickImage',
      desc: '',
      args: [],
    );
  }

  /// `Profile Photo`
  String get profilePhoto {
    return Intl.message(
      'Profile Photo',
      name: 'profilePhoto',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get removeOption {
    return Intl.message('Remove', name: 'removeOption', desc: '', args: []);
  }

  /// `Scheduled · {date}`
  String scheduledDate(Object date) {
    return Intl.message(
      'Scheduled · $date',
      name: 'scheduledDate',
      desc: '',
      args: [date],
    );
  }

  /// `Accepted: {date}`
  String acceptedDate(Object date) {
    return Intl.message(
      'Accepted: $date',
      name: 'acceptedDate',
      desc: '',
      args: [date],
    );
  }

  /// `Completed: {date}`
  String completedDate(Object date) {
    return Intl.message(
      'Completed: $date',
      name: 'completedDate',
      desc: '',
      args: [date],
    );
  }

  /// `Photos ({count})`
  String photosCount(Object count) {
    return Intl.message(
      'Photos ($count)',
      name: 'photosCount',
      desc: '',
      args: [count],
    );
  }

  /// `Voice notes ({count})`
  String voiceNotesCount(Object count) {
    return Intl.message(
      'Voice notes ($count)',
      name: 'voiceNotesCount',
      desc: '',
      args: [count],
    );
  }

  /// `{label} copied to clipboard`
  String copiedToClipboard(Object label) {
    return Intl.message(
      '$label copied to clipboard',
      name: 'copiedToClipboard',
      desc: '',
      args: [label],
    );
  }

  /// `Service is in progress`
  String get serviceInProgress {
    return Intl.message(
      'Service is in progress',
      name: 'serviceInProgress',
      desc: '',
      args: [],
    );
  }

  /// `Tap to copy`
  String get tapToCopy {
    return Intl.message('Tap to copy', name: 'tapToCopy', desc: '', args: []);
  }

  /// `Tap to copy Google Maps link`
  String get tapToCopyMaps {
    return Intl.message(
      'Tap to copy Google Maps link',
      name: 'tapToCopyMaps',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid number`
  String get enterValidNumber {
    return Intl.message(
      'Enter a valid number',
      name: 'enterValidNumber',
      desc: '',
      args: [],
    );
  }

  /// `Must be between 0 and 50`
  String get mustBeBetween0And50 {
    return Intl.message(
      'Must be between 0 and 50',
      name: 'mustBeBetween0And50',
      desc: '',
      args: [],
    );
  }

  /// `Failed to save`
  String get failedToSave {
    return Intl.message(
      'Failed to save',
      name: 'failedToSave',
      desc: '',
      args: [],
    );
  }

  /// `Request to API server was cancelled`
  String get requestCancelled {
    return Intl.message(
      'Request to API server was cancelled',
      name: 'requestCancelled',
      desc: '',
      args: [],
    );
  }

  /// `Connection timeout with API server`
  String get connectionTimeout {
    return Intl.message(
      'Connection timeout with API server',
      name: 'connectionTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Receive timeout in connection with API server`
  String get receiveTimeout {
    return Intl.message(
      'Receive timeout in connection with API server',
      name: 'receiveTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Oops! Something went wrong.`
  String get somethingWentWrong {
    return Intl.message(
      'Oops! Something went wrong.',
      name: 'somethingWentWrong',
      desc: '',
      args: [],
    );
  }

  /// `Send timeout in connection with API server`
  String get sendTimeout {
    return Intl.message(
      'Send timeout in connection with API server',
      name: 'sendTimeout',
      desc: '',
      args: [],
    );
  }

  /// `Connection error occurred`
  String get connectionError {
    return Intl.message(
      'Connection error occurred',
      name: 'connectionError',
      desc: '',
      args: [],
    );
  }

  /// `Unexpected error occurred`
  String get unexpectedError {
    return Intl.message(
      'Unexpected error occurred',
      name: 'unexpectedError',
      desc: '',
      args: [],
    );
  }

  /// `Account Type`
  String get accountType {
    return Intl.message(
      'Account Type',
      name: 'accountType',
      desc: '',
      args: [],
    );
  }

  /// `Choose whether you are a client or a technician.`
  String get chooseAccountTypeDesc {
    return Intl.message(
      'Choose whether you are a client or a technician.',
      name: 'chooseAccountTypeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Client`
  String get clientRole {
    return Intl.message('Client', name: 'clientRole', desc: '', args: []);
  }

  /// `Hire technicians`
  String get hireTechnicians {
    return Intl.message(
      'Hire technicians',
      name: 'hireTechnicians',
      desc: '',
      args: [],
    );
  }

  /// `Worker`
  String get workerRole {
    return Intl.message('Worker', name: 'workerRole', desc: '', args: []);
  }

  /// `Provide services`
  String get provideServices {
    return Intl.message(
      'Provide services',
      name: 'provideServices',
      desc: '',
      args: [],
    );
  }

  /// `Your account will be reviewed by an admin before you can start working.`
  String get workerVerificationNotice {
    return Intl.message(
      'Your account will be reviewed by an admin before you can start working.',
      name: 'workerVerificationNotice',
      desc: '',
      args: [],
    );
  }

  /// `Complete Profile`
  String get completeProfileBtn {
    return Intl.message(
      'Complete Profile',
      name: 'completeProfileBtn',
      desc: '',
      args: [],
    );
  }

  /// `Leave without completing?`
  String get leaveWithoutCompleting {
    return Intl.message(
      'Leave without completing?',
      name: 'leaveWithoutCompleting',
      desc: '',
      args: [],
    );
  }

  /// `Your account will be deleted if you leave without completing your profile.`
  String get leaveWarningDesc {
    return Intl.message(
      'Your account will be deleted if you leave without completing your profile.',
      name: 'leaveWarningDesc',
      desc: '',
      args: [],
    );
  }

  /// `Stay`
  String get stay {
    return Intl.message('Stay', name: 'stay', desc: '', args: []);
  }

  /// `Leave`
  String get leave {
    return Intl.message('Leave', name: 'leave', desc: '', args: []);
  }

  /// `Continue as guest`
  String get continueAsGuest {
    return Intl.message(
      'Continue as guest',
      name: 'continueAsGuest',
      desc: '',
      args: [],
    );
  }

  /// `Sign in required`
  String get loginRequiredTitle {
    return Intl.message(
      'Sign in required',
      name: 'loginRequiredTitle',
      desc: '',
      args: [],
    );
  }

  /// `Please sign in to continue.`
  String get loginRequiredMessage {
    return Intl.message(
      'Please sign in to continue.',
      name: 'loginRequiredMessage',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to complete your booking.`
  String get checkoutLoginRequired {
    return Intl.message(
      'Sign in to complete your booking.',
      name: 'checkoutLoginRequired',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to view your profile.`
  String get signInToViewProfile {
    return Intl.message(
      'Sign in to view your profile.',
      name: 'signInToViewProfile',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to view your data.`
  String get signInToViewData {
    return Intl.message(
      'Sign in to view your data.',
      name: 'signInToViewData',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
