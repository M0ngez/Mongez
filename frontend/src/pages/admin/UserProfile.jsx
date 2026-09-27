import { useEffect, useState, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { adminAPI } from '../../services/api';
import { statusStyle, reasonStyle } from '../../utils/orderStatus';

const roleColors = {
  admin: { bg: '#ef444420', color: '#ef4444' },
  worker: { bg: '#f59e0b20', color: '#f59e0b' },
  client: { bg: '#3b82f620', color: '#3b82f6' },
};

const BehaviorCard = ({ icon, value, label, sub, color, highlight }) => (
  <div className="card border-0 shadow-sm h-100" style={{ borderRadius: '12px', border: highlight ? '1px solid #ef444440' : 'none' }}>
    <div className="card-body p-3">
      <div className="d-flex align-items-center gap-2 mb-2">
        <div className="rounded-circle d-flex align-items-center justify-content-center" style={{ width: '34px', height: '34px', flexShrink: 0, backgroundColor: `${color}15`, color }}>
          <i className={`bi ${icon}`}></i>
        </div>
        <div style={{ fontSize: '20px', fontWeight: 700, color: '#0f172a' }}>{value}</div>
      </div>
      <div className="fw-semibold" style={{ fontSize: '13px', color: '#1e293b' }}>{label}</div>
      {sub && <div className="text-muted" style={{ fontSize: '11px' }}>{sub}</div>}
    </div>
  </div>
);

const UserProfile = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const load = useCallback(() => {
    adminAPI.users
      .profile(id)
      .then((res) => setData(res.data))
      .catch((err) => setError(err.response?.status === 404
        ? 'User not found.'
        : err.response?.data?.error || 'Failed to load user profile.'))
      .finally(() => setLoading(false));
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  if (loading) {
    return (
      <div className="d-flex justify-content-center py-5">
        <div className="spinner-border text-primary" role="status" />
      </div>
    );
  }

  if (error) {
    return (
      <div>
        <button className="btn btn-sm mb-3" style={{ borderRadius: '8px', border: '1px solid #e2e8f0', color: '#475569' }} onClick={() => navigate('/admin/users')}>
          <i className="bi bi-arrow-left me-1"></i> Back to Users
        </button>
        <div className="alert alert-danger d-flex align-items-center gap-2" style={{ borderRadius: '12px', border: 'none' }}>
          <i className="bi bi-exclamation-triangle-fill"></i> {error}
        </div>
      </div>
    );
  }

  const { user, behavior, orders } = data;
  const behaviorData = behavior || {};
  const ordersList = orders?.results || [];
  const rc = roleColors[user.role] || roleColors.client;

  const summaryCard = (icon, value, label, color) => (
    <div className="card border-0 shadow-sm h-100" style={{ borderRadius: '15px' }}>
      <div className="card-body d-flex align-items-center gap-3 p-3">
        <div className="rounded-circle d-flex align-items-center justify-content-center" style={{ width: '44px', height: '44px', flexShrink: 0, backgroundColor: `${color}15`, color }}>
          <i className={`bi ${icon} fs-6`}></i>
        </div>
        <div className="min-w-0">
          <div className="fw-bold" style={{ fontSize: '18px', color: '#0f172a' }}>{value}</div>
          <div className="text-muted" style={{ fontSize: '12px' }}>{label}</div>
        </div>
      </div>
    </div>
  );

  return (
    <div>
      <button className="btn btn-sm mb-3" style={{ borderRadius: '8px', border: '1px solid #e2e8f0', color: '#475569' }} onClick={() => navigate('/admin/users')}>
        <i className="bi bi-arrow-left me-1"></i> Back to Users
      </button>

      {/* Header card */}
      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <div className="d-flex align-items-center gap-3 flex-wrap">
            <div className="rounded-circle d-flex align-items-center justify-content-center overflow-hidden" style={{ width: '64px', height: '64px', backgroundColor: '#6366f115', color: '#6366f1', fontSize: '22px', fontWeight: '700', flexShrink: 0 }}>
              {user.avatar_url ? (
                <img src={user.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              ) : (
                (user.display_name || user.username)?.[0]?.toUpperCase() || '?'
              )}
            </div>
            <div className="flex-grow-1">
              <div className="d-flex align-items-center gap-2 flex-wrap">
                <h4 className="mb-0 fw-bold" style={{ color: '#0f172a' }}>
                  {user.display_name || user.username}
                </h4>
                <span className="badge rounded-pill px-3 py-1" style={{ backgroundColor: rc.bg, color: rc.color, fontSize: '12px' }}>
                  {user.role}
                </span>
                <span className={`badge rounded-pill px-3 py-1 ${user.is_active ? 'bg-success' : 'bg-secondary'}`} style={{ fontSize: '12px' }}>
                  {user.is_active ? 'Active' : 'Inactive'}
                </span>
              </div>
              <div className="text-muted" style={{ fontSize: '13px' }}>
                @{user.username}
                {user.governorate_label ? ` · ${user.governorate_label}` : ''}
                {user.city ? ` · ${user.city}` : ''}
              </div>
            </div>
            <div className="text-md-end text-muted" style={{ fontSize: '12px' }}>
              Joined {new Date(user.date_joined).toLocaleDateString()}
            </div>
          </div>
        </div>
      </div>

      {/* Behavior Summary */}
      <div className="mt-4">
        <div className="d-flex align-items-center gap-2 mb-3">
          <h6 className="fw-bold mb-0" style={{ color: '#0f172a' }}>Behavior Summary</h6>
          <span className="badge rounded-pill" style={{ backgroundColor: '#f1f5f9', color: '#64748b', fontSize: '11px', fontWeight: '500' }}>client account</span>
        </div>
        <div className="row g-3">
          <div className="col-md-3 col-6">
            <BehaviorCard icon="bi-bag" value={behaviorData.total_orders ?? 0} label="Total Orders" color="#3b82f6" />
          </div>
          <div className="col-md-3 col-6">
            <BehaviorCard icon="bi-check2-all" value={behaviorData.completed_orders ?? 0} label="Completed" color="#10b981" />
          </div>
          <div className="col-md-3 col-6">
            <BehaviorCard icon="bi-x-circle" value={behaviorData.cancelled_orders ?? 0} label="Cancelled" sub={`${behaviorData.cancellation_rate ?? 0}% rate`} color="#ef4444" />
          </div>
          <div className="col-md-3 col-6">
            <BehaviorCard icon="bi-calendar-x" value={behaviorData.recent_cancellations_30d ?? 0} label="Cancelled (30 days)" color="#f59e0b" />
          </div>
        </div>

        {(behaviorData.cancelled_due_to_worker_delay ?? 0) > 0 && (
          <div className="alert d-flex align-items-center gap-2 mt-3 mb-0" style={{ backgroundColor: '#f9731610', border: '1px solid #f9731640', color: '#9a3412', borderRadius: '12px', fontSize: '14px' }}>
            <i className="bi bi-shield-exclamation fs-5"></i>
            <div>
              <strong>{behaviorData.cancelled_due_to_worker_delay} order(s)</strong> cancelled here were caused by <strong>worker delays</strong> — not the client's fault.
            </div>
          </div>
        )}
      </div>

      {/* Account stats */}
      <div className="row g-3 mt-1">
        <div className="col-md-4 col-6">{summaryCard('bi-person-badge', user.verification_status || 'none', 'Verification', '#8b5cf6')}</div>
        <div className="col-md-4 col-6">{summaryCard('bi-telephone', user.phone || '—', 'Phone', '#6366f1')}</div>
        <div className="col-md-4 col-6">{summaryCard('bi-envelope', user.email || '—', 'Email', '#0ea5e9')}</div>
      </div>

      {/* Orders */}
      <div className="card border-0 shadow-sm mt-4" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <h6 className="fw-bold mb-3" style={{ color: '#0f172a' }}>Order History</h6>
          <div className="table-responsive">
            <table className="table table-hover align-middle mb-0">
              <thead style={{ backgroundColor: '#f8fafc' }}>
                <tr>
                  <th style={thStyle}>Order</th>
                  <th style={thStyle}>Service</th>
                  <th style={thStyle}>Worker</th>
                  <th style={thStyle}>Status</th>
                  <th style={thStyle}>Created</th>
                  <th style={thStyle}>Cancellation</th>
                </tr>
              </thead>
              <tbody>
                {ordersList.length === 0 ? (
                  <tr><td colSpan="6" className="text-center py-4 text-muted">No orders for this user.</td></tr>
                ) : ordersList.map((o) => {
                  const sc = statusStyle(o.status, o.cancellation_reason);
                  const reason = reasonStyle(o.cancellation_reason);
                  return (
                    <tr key={o.id}>
                      <td style={{ fontWeight: '500' }}>#{o.id}</td>
                      <td style={{ color: '#475569', fontSize: '13px' }}>
                        {o.service_category?.name || '—'}
                      </td>
                      <td style={{ color: '#475569', fontSize: '13px' }}>
                        {o.worker?.display_name || o.worker?.username || '—'}
                      </td>
                      <td>
                        <span className="badge rounded-pill px-3 py-1" style={{ backgroundColor: sc.bg, color: sc.color, fontSize: '12px' }}>{sc.label}</span>
                      </td>
                      <td style={{ color: '#64748b', fontSize: '13px' }}>{new Date(o.created_at).toLocaleDateString()}</td>
                      <td>
                        {reason ? (
                          <div className="d-flex flex-column gap-1">
                            <span className="badge rounded-pill px-3 py-1 align-self-start" style={{ backgroundColor: reason.bg, color: reason.color, fontSize: '12px' }}>
                              <i className={`bi ${reason.icon} me-1`}></i>
                              {reason.label}
                            </span>
                            {o.cancelled_at && (
                              <span className="text-muted" style={{ fontSize: '11px' }}>
                                {new Date(o.cancelled_at).toLocaleDateString()}
                              </span>
                            )}
                          </div>
                        ) : (
                          <span className="text-muted" style={{ fontSize: '12px' }}>—</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <style>{`
        .info-row { display: flex; justify-content: space-between; align-items: center; padding: 6px 0; }
      `}</style>
    </div>
  );
};

const thStyle = { fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' };

export default UserProfile;