/// In-memory guest flag.
///
/// Deliberately NOT persisted: choosing "continue as guest" only lives
/// for the current app process, so killing and reopening the app always
/// lands back on the Get Started screen (login / guest chooser) unless a
/// real session token exists.
class GuestSession {
  GuestSession._();

  static bool _active = false;

  static bool get isGuest => _active;

  static void enter() => _active = true;

  static void exit() => _active = false;
}
