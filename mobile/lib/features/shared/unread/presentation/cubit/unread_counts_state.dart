part of 'unread_counts_cubit.dart';

/// Badge numbers rendered on the bottom nav.
///
/// [requests] is the value the Requests tab shows (role specific): only
/// clients get a notifications number, because every client-facing
/// notification is an order event. [favorites] is the plain total of saved
/// favorites — not an unread count: the backend has no unread favorite
/// concept, so it is nothing but the length of the favorites list.
class UnreadCountsState {
  final int notifications;
  final int requests;
  final int favorites;

  const UnreadCountsState({
    this.notifications = 0,
    this.requests = 0,
    this.favorites = 0,
  });
}
