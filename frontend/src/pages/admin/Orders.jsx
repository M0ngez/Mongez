import React, { useState, useCallback } from 'react';
import { adminAPI } from '../../services/api';
import Table from '../../components/admin/Table';
import { usePolling, useTimeAgo } from '../../hooks/usePolling';
import ExportCsvButton from '../../components/admin/ExportCsvButton';
import {
  CANCELLATION_REASONS,
  ORDER_STATUSES,
  REASON_WORKER_DELAY,
  reasonStyle,
  statusStyle,
} from '../../utils/orderStatus';

const fetchOrders = () =>
  adminAPI.orders.list({ page_size: 100 }).then((res) => res.data?.results || []);

const Orders = () => {
  const [statusFilter, setStatusFilter] = useState('');
  const [reasonFilter, setReasonFilter] = useState('');
  const [changingStatus, setChangingStatus] = useState(null);

  // 10 s — Orders is the most dynamic admin surface; we want a new mobile
  // order or an accept-from-worker to land in the UI within ten seconds.
  const { data: orders, loading, lastUpdatedAt, refresh, setData, error } =
    usePolling(fetchOrders, { intervalMs: 3_000, initialData: [] });
  const updatedLabel = useTimeAgo(lastUpdatedAt);

  const handleStatusChange = useCallback(async (orderId, newStatus) => {
    setChangingStatus(orderId);
    // Optimistic update — flip the row immediately so the admin sees the
    // change land. If the API rejects, revert by re-fetching from server.
    const previous = orders;
    setData((current) => current.map((o) =>
      o.id === orderId ? { ...o, status: newStatus } : o,
    ));
    try {
      await adminAPI.orders.updateStatus(orderId, newStatus);
      // Pick up server-side side-effects (timestamps, worker.completed_jobs).
      refresh();
    } catch (err) {
      setData(previous);
      alert(err.response?.data?.error || 'Failed to update order status');
    } finally {
      setChangingStatus(null);
    }
  }, [orders, setData, refresh]);

  const filteredOrders = orders.filter(
    (o) =>
      (!statusFilter || o.status === statusFilter) &&
      (!reasonFilter || o.cancellation_reason === reasonFilter),
  );

  const delayCancellations = orders.filter(
    (o) => o.status === 'CANCELLED' && o.cancellation_reason === REASON_WORKER_DELAY,
  ).length;

  const columns = [
    { key: 'id', label: 'Order #' },
    {
      key: 'client',
      label: 'Client',
      render: (row) => row.client?.username || 'N/A',
    },
    {
      key: 'worker',
      label: 'Worker',
      render: (row) => row.worker?.username || 'Unassigned',
    },
    {
      key: 'service_category',
      label: 'Service',
      render: (row) => row.service_category?.name || 'N/A',
    },
    {
      key: 'status',
      label: 'Status',
      render: (row) => {
        const colors = statusStyle(row.status, row.cancellation_reason);
        return (
          <span className="badge rounded-pill px-3 py-2" style={{ backgroundColor: colors.bg, color: colors.color, fontSize: '12px', fontWeight: '500' }}>
            {colors.label}
          </span>
        );
      },
    },
    {
      key: 'cancellation_reason',
      label: 'Cancellation',
      render: (row) => {
        const reason = reasonStyle(row.cancellation_reason);
        if (!reason) return <span className="text-muted" style={{ fontSize: '13px' }}>—</span>;
        return (
          <div className="d-flex flex-column gap-1">
            <span className="badge rounded-pill px-3 py-1 align-self-start" style={{ backgroundColor: reason.bg, color: reason.color, fontSize: '12px' }}>
              <i className={`bi ${reason.icon} me-1`}></i>
              {reason.label}
            </span>
            {row.cancelled_at && (
              <span className="text-muted" style={{ fontSize: '11px' }}>
                {new Date(row.cancelled_at).toLocaleDateString()}
              </span>
            )}
          </div>
        );
      },
    },
    {
      key: 'created_at',
      label: 'Date',
      render: (row) => new Date(row.created_at).toLocaleDateString(),
    },
    {
      key: 'actions',
      label: 'Change Status',
      render: (row) => (
        <select
          className="form-select form-select-sm"
          style={{ borderRadius: '8px', fontSize: '12px', maxWidth: '160px' }}
          value=""
          onChange={(e) => {
            if (e.target.value) handleStatusChange(row.id, e.target.value);
          }}
          disabled={changingStatus === row.id}
        >
          <option value="">{changingStatus === row.id ? 'Updating...' : 'Change to...'}</option>
          {ORDER_STATUSES.filter((s) => s !== row.status).map((s) => (
            <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
          ))}
        </select>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header d-flex justify-content-between align-items-center flex-wrap gap-2">
        <div>
          <h4 className="mb-1">Orders Management</h4>
          <p className="mb-0">View, filter, and change order statuses.</p>
        </div>
        <div className="d-flex align-items-center gap-2">
          <span className="text-muted small">
            <i className="bi bi-arrow-clockwise me-1"></i>
            {updatedLabel ? `Updated ${updatedLabel}` : 'Loading…'}
          </span>
          <button type="button" className="btn btn-sm btn-outline-secondary" onClick={refresh} disabled={loading} title="Refresh now">
            <i className="bi bi-arrow-repeat"></i>
          </button>
          <ExportCsvButton fetcher={adminAPI.exports.orders} filename="orders.csv" />
          <select className="form-select" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} style={{ borderRadius: '10px', padding: '8px 14px', minWidth: '170px' }}>
            <option value="">All Statuses</option>
            {ORDER_STATUSES.map((s) => (
              <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
            ))}
          </select>
          <select className="form-select" value={reasonFilter} onChange={(e) => setReasonFilter(e.target.value)} style={{ borderRadius: '10px', padding: '8px 14px', minWidth: '190px' }}>
            <option value="">All Cancellations</option>
            {Object.entries(CANCELLATION_REASONS).map(([value, cfg]) => (
              <option key={value} value={value}>{cfg.label}</option>
            ))}
          </select>
        </div>
      </div>

      {error && (
        <div className="alert alert-danger d-flex align-items-center gap-2 mb-3" style={{ borderRadius: '12px', border: 'none' }}>
          <i className="bi bi-exclamation-triangle-fill"></i>
          <div>
            <strong>Failed to load orders.</strong>{' '}
            {error?.response?.status === 401 && 'Session expired — try refreshing.'}
            {error?.response?.status === 403 && 'You do not have admin permissions.'}
            {![401, 403].includes(error?.response?.status) && (error?.response?.data?.error || error?.message || 'Unknown error')}
          </div>
        </div>
      )}

      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <div className="mb-3 d-flex gap-3 flex-wrap">
            {ORDER_STATUSES.map((s) => {
              const colors = statusStyle(s);
              const count = orders.filter((o) => o.status === s).length;
              return (
                <div key={s} className="d-flex align-items-center gap-1" style={{ fontSize: '13px' }}>
                  <span className="badge rounded-pill px-2 py-1" style={{ backgroundColor: colors.bg, color: colors.color }}>{colors.label}</span>
                  <span className="fw-bold" style={{ color: colors.color }}>{count}</span>
                </div>
              );
            })}
            <div className="d-flex align-items-center gap-1" style={{ fontSize: '13px' }}>
              <span className="badge rounded-pill px-2 py-1" style={{ backgroundColor: CANCELLATION_REASONS.WORKER_DELAY.bg, color: CANCELLATION_REASONS.WORKER_DELAY.color }}>
                <i className={`bi ${CANCELLATION_REASONS.WORKER_DELAY.icon} me-1`}></i>
                {CANCELLATION_REASONS.WORKER_DELAY.label}
              </span>
              <span className="fw-bold" style={{ color: CANCELLATION_REASONS.WORKER_DELAY.color }}>{delayCancellations}</span>
            </div>
          </div>
          <Table columns={columns} data={filteredOrders} loading={loading} emptyMessage="No orders found" />
        </div>
      </div>
    </div>
  );
};

export default Orders;
