// Shared presentation for order status and cancellation reason.
//
// `statusColors` used to be copy-pasted into four admin pages and
// `reasonLabels` into two, which is how a worker-delay cancellation ended
// up looking identical to a plain client cancel: the data arrived but
// every screen drew it its own way (or not at all). Anything that renders
// an order status or a cancellation reason goes through this module.

export const ORDER_STATUS_COLORS = {
  PENDING: { bg: '#f59e0b20', color: '#f59e0b' },
  ACCEPTED: { bg: '#3b82f620', color: '#3b82f6' },
  IN_PROGRESS: { bg: '#8b5cf620', color: '#8b5cf6' },
  WAITING_CONFIRMATION: { bg: '#f9731620', color: '#f97316' },
  REJECTED: { bg: '#ef444420', color: '#ef4444' },
  CANCELLED: { bg: '#6b728020', color: '#6b7280' },
  COMPLETED: { bg: '#10b98120', color: '#10b981' },
};

export const ORDER_STATUSES = [
  'PENDING',
  'ACCEPTED',
  'IN_PROGRESS',
  'WAITING_CONFIRMATION',
  'REJECTED',
  'CANCELLED',
  'COMPLETED',
];

// Order.CANCELLATION_REASON_CHOICES on the backend. WORKER_DELAY means the
// cancel only became possible once the 1-hour post-accept window elapsed —
// the worker accepted and never showed up on time.
export const REASON_WORKER_DELAY = 'WORKER_DELAY';

export const CANCELLATION_REASONS = {
  WORKER_DELAY: {
    label: 'Worker delay',
    color: '#ef4444',
    bg: '#ef444420',
    icon: 'bi-clock-history',
  },
  OTHER: {
    label: 'Cancelled by client',
    color: '#6b7280',
    bg: '#6b728020',
    icon: 'bi-person-x',
  },
};

/**
 * Colours + label for an order's status badge.
 *
 * A cancellation charged to the worker is a different event than one the
 * client walked away from before anyone was assigned, so it must not wear
 * the same grey badge — that indistinguishability is the whole point of
 * the distinction.
 */
export function statusStyle(status, cancellationReason) {
  const base = ORDER_STATUS_COLORS[status] || ORDER_STATUS_COLORS.PENDING;
  const label = status ? status.replace(/_/g, ' ') : '';

  if (status === 'CANCELLED' && cancellationReason === REASON_WORKER_DELAY) {
    return { bg: '#ef444420', color: '#ef4444', label: 'CANCELLED · WORKER LATE' };
  }
  return { ...base, label };
}

/** Colours + label for the cancellation-reason chip, or null if unset. */
export function reasonStyle(reason) {
  if (!reason) return null;
  return (
    CANCELLATION_REASONS[reason] || {
      label: reason,
      color: '#6b7280',
      bg: '#6b728020',
      icon: 'bi-question-circle',
    }
  );
}
