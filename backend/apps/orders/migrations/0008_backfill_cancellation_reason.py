"""Backfill `cancellation_reason` for orders cancelled before the cancel
endpoint derived it from timing.

The endpoint used to trust whatever reason the client sent, and the mobile
app does not always send one, so a lot of CANCELLED rows ended up with a
blank reason and rendered as "—" in the admin panel — indistinguishable
from each other and from orders cancelled for unrelated reasons.

Reconstruct the reason from the two timestamps the flow has always
recorded:

  * never accepted (`accepted_at` is blank) → the client backed out before
    any worker was on the job → OTHER
  * cancelled an hour or more after acceptance → the cancel was only
    unlocked once the window elapsed, i.e. the worker was late →
    WORKER_DELAY
  * anything else (cancelled inside the window, which only an admin
    override can do) → no evidence the worker was at fault → OTHER

Runs as a Python loop rather than a single UPDATE so the one-hour
comparison behaves identically on every supported database, and so it can
be run twice without double-writing (it only touches blank rows).
"""

from datetime import timedelta

from django.db import migrations


def backfill_cancellation_reason(apps, schema_editor):
    Order = apps.get_model("orders", "Order")
    pending = Order.objects.filter(
        status="CANCELLED",
        cancellation_reason__isnull=True,
    )

    updates = []
    for order in pending.iterator():
        if order.accepted_at is None:
            reason = "OTHER"
        elif order.cancelled_at is not None and (
            order.cancelled_at >= order.accepted_at + timedelta(hours=1)
        ):
            reason = "WORKER_DELAY"
        else:
            reason = "OTHER"

        order.cancellation_reason = reason
        updates.append(order)

    if updates:
        Order.objects.bulk_update(updates, ["cancellation_reason"], batch_size=500)


def revert_cancellation_reason(apps, schema_editor):
    # Forward only ever wrote to rows that were blank, so reversing would
    # have to distinguish them from reasons clients stated explicitly —
    # information that no longer exists. Losing a derived label is
    # recoverable by re-running the forward migration; guessing here is
    # not.
    pass


class Migration(migrations.Migration):

    dependencies = [
        ("orders", "0007_order_cancellation_reason"),
    ]

    operations = [
        migrations.RunPython(
            backfill_cancellation_reason,
            revert_cancellation_reason,
        ),
    ]
