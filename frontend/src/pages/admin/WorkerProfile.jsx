import { useEffect, useState, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { adminAPI } from '../../services/api';
import { statusStyle, reasonStyle } from '../../utils/orderStatus';

const WorkerProfile = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const load = useCallback(() => {
    adminAPI.workers
      .profile(id)
      .then((res) => setData(res.data))
      .catch((err) => setError(err.response?.status === 404
        ? 'Worker not found.'
        : err.response?.data?.error || 'Failed to load worker profile.'))
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
        <button className="btn btn-sm mb-3" style={{ borderRadius: '8px', border: '1px solid #e2e8f0', color: '#475569' }} onClick={() => navigate('/admin/workers')}>
          <i className="bi bi-arrow-left me-1"></i> Back to Workers
        </button>
        <div className="alert alert-danger d-flex align-items-center gap-2" style={{ borderRadius: '12px', border: 'none' }}>
          <i className="bi bi-exclamation-triangle-fill"></i> {error}
        </div>
      </div>
    );
  }

  const { profile, orders, ratings, summary } = data;
  const user = profile?.user || {};
  const ordersList = orders?.results || [];
  const ratingsList = ratings?.results || [];

  const statCard = (icon, value, label, color = '#6366f1', sub) => (
    <div className="card border-0 shadow-sm h-100" style={{ borderRadius: '12px' }}>
      <div className="card-body d-flex align-items-center gap-3 p-3">
        <div className="rounded-circle d-flex align-items-center justify-content-center" style={{ width: '44px', height: '44px', flexShrink: 0, backgroundColor: `${color}15`, color }}>
          <i className={`bi ${icon} fs-6`}></i>
        </div>
        <div className="min-w-0">
          <div className="fw-bold" style={{ fontSize: '18px', color: '#0f172a' }}>{value}</div>
          <div className="text-muted" style={{ fontSize: '12px' }}>{label}</div>
          {sub && <div style={{ fontSize: '11px', color: '#94a3b8' }}>{sub}</div>}
        </div>
      </div>
    </div>
  );

  return (
    <div>
      <button className="btn btn-sm mb-3" style={{ borderRadius: '8px', border: '1px solid #e2e8f0', color: '#475569' }} onClick={() => navigate('/admin/workers')}>
        <i className="bi bi-arrow-left me-1"></i> Back to Workers
      </button>

      {/* Header card */}
      <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
        <div className="card-body p-4">
          <div className="d-flex align-items-center gap-3 flex-wrap">
            <div className="rounded-circle d-flex align-items-center justify-content-center overflow-hidden" style={{ width: '64px', height: '64px', backgroundColor: '#f59e0b15', color: '#f59e0b', fontSize: '22px', fontWeight: '700', flexShrink: 0 }}>
              {user.avatar_url ? (
                <img src={user.avatar_url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              ) : (
                user.display_name?.[0]?.toUpperCase() || user.username?.[0]?.toUpperCase() || '?'
              )}
            </div>
            <div className="flex-grow-1">
              <div className="d-flex align-items-center gap-2 flex-wrap">
                <h4 className="mb-0 fw-bold" style={{ color: '#0f172a' }}>
                  {user.display_name || user.username}
                </h4>
                {profile?.is_verified && (
                  <i className="bi bi-patch-check-fill" style={{ color: '#10b981' }} title="Verified"></i>
                )}
              </div>
              <div className="text-muted" style={{ fontSize: '13px' }}>
                {profile?.profession || '—'}
                {profile?.profession_ar ? ` · ${profile.profession_ar}` : ''}
              </div>
              <div className="d-flex gap-2 mt-2 flex-wrap">
                {(user.verification_status && user.verification_status !== 'verified') || user.verification_status === 'verified' ? (
                  <span className="badge rounded-pill px-3 py-1" style={{ backgroundColor: `#6366f115`, color: '#6366f1', fontSize: '12px' }}>
                    Verification: {user.verification_status}
                  </span>
                ) : null}
                <span className="badge rounded-pill px-3 py-1" style={{ backgroundColor: profile?.is_available ? '#10b98115' : '#6b728015', color: profile?.is_available ? '#10b981' : '#6b7280', fontSize: '12px' }}>
                  {profile?.is_available ? 'Available' : 'Unavailable'}
                </span>
                {profile?.is_featured && (
                  <span className="badge rounded-pill px-3 py-1" style={{ backgroundColor: '#f59e0b15', color: '#f59e0b', fontSize: '12px' }}>
                    <i className="bi bi-star-fill me-1"></i>Featured
                  </span>
                )}
              </div>
            </div>
            <div className="text-md-end">
              <div style={{ fontSize: '26px', fontWeight: 800, color: '#0f172a' }}>
                {(profile?.average_rating || 0).toFixed(1)}
                <i className="bi bi-star-fill ms-1" style={{ color: '#f59e0b', fontSize: '18px' }}></i>
              </div>
              <div className="text-muted" style={{ fontSize: '12px' }}>{ratings?.count || 0} ratings</div>
            </div>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="row g-3 mt-1">
        <div className="col-md-3 col-6">{statCard('bi-check2-all', profile?.completed_jobs || 0, 'Completed Jobs', '#10b981')}</div>
        <div className="col-md-3 col-6">{statCard('bi-clock-history', orders?.count ?? 0, 'Total Orders', '#3b82f6')}</div>
        <div className="col-md-3 col-6">{statCard('bi-briefcase', profile?.experience_years || 0, 'Years Experience', '#f59e0b')}</div>
        <div className="col-md-3 col-6">{statCard('bi-badge-cc', profile?.hourly_rate ? `${profile.hourly_rate} EGP` : '—', 'Hourly Rate', '#8b5cf6')}</div>
      </div>

      {/* Performance summary */}
      <div className="d-flex align-items-center gap-2 mt-4 mb-2">
        <h6 className="fw-bold mb-0" style={{ color: '#0f172a' }}>Performance Summary</h6>
        <span className="badge rounded-pill" style={{ backgroundColor: '#f1f5f9', color: '#64748b', fontSize: '11px', fontWeight: '500' }}>assigned orders</span>
      </div>
      <div className="row g-3">
        <div className="col-md-3 col-6">
          {statCard(
            'bi-x-circle',
            summary.cancelled_orders ?? 0,
            'Cancelled',
            '#ef4444',
            `${summary.cancelled_by_client ?? 0} by client · ${summary.cancelled_due_to_worker_delay ?? 0} worker delay`,
          )}
        </div>
        <div className="col-md-3 col-6">{statCard('bi-calendar-x', summary.recent_cancellations_30d ?? 0, 'Cancelled (30 days)', '#f59e0b')}</div>
        <div className="col-md-3 col-6">{statCard('bi-clock-history', summary.cancelled_due_to_worker_delay ?? 0, 'Due to Worker Delay', '#f97316', 'accepted, then never showed')}</div>
        <div className="col-md-3 col-6">{statCard('bi-percent', `${summary.cancellation_rate ?? 0}%`, 'Cancellation Rate', '#8b5cf6')}</div>
      </div>

      {(summary.cancelled_due_to_worker_delay ?? 0) > 0 && (
        <div className="alert d-flex align-items-center gap-2 mt-3 mb-0" style={{ backgroundColor: '#ef444410', border: '1px solid #ef444440', color: '#991b1b', borderRadius: '12px', fontSize: '14px' }}>
          <i className="bi bi-exclamation-triangle-fill fs-5"></i>
          <div>
            <strong>{summary.cancelled_due_to_worker_delay} order(s)</strong> were cancelled because this worker was{' '}
            <strong>late / didn't show up</strong>. Repeated incidents are a reliability concern for clients.
          </div>
        </div>
      )}

      {/* Details + Orders */}
      <div className="row g-4 mt-1">
        <div className="col-lg-4">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
            <div className="card-body p-4">
              <h6 className="fw-bold mb-3" style={{ color: '#0f172a' }}>Worker Details</h6>
              <div className="info-row"><span className="info-label">Phone</span><span className="info-value">{user.phone || '—'}</span></div>
              <div className="info-row"><span className="info-label">Governorate</span><span className="info-value">{user.governorate_label || user.governorate || '—'}</span></div>
              <div className="info-row"><span className="info-label">City</span><span className="info-value">{user.city || '—'}</span></div>
              <div className="info-row"><span className="info-label">Registered</span><span className="info-value">{user.date_joined ? new Date(user.date_joined).toLocaleDateString() : '—'}</span></div>
              <div className="info-row"><span className="info-label">Account</span>
                <span className="info-value">
                  <span className={`badge rounded-pill px-2 py-1 ${user.is_active ? 'bg-success' : 'bg-secondary'}`} style={{ fontSize: '11px' }}>
                    {user.is_active ? 'Active' : 'Inactive'}
                  </span>
                </span>
              </div>

              {(profile?.specialties_list?.length > 0) && (
                <div className="mt-3">
                  <div className="info-label mb-1">Specialties</div>
                  <div className="d-flex flex-wrap gap-1">
                    {profile.specialties_list.map((s) => (
                      <span key={s} className="badge rounded-pill" style={{ backgroundColor: '#f1f5f9', color: '#475569', fontWeight: '500' }}>{s}</span>
                    ))}
                  </div>
                </div>
              )}

              <hr style={{ borderColor: '#f1f5f9' }} />
              <div className="info-row"><span className="info-label">Bio</span></div>
              <div className="text-muted" style={{ fontSize: '13px', lineHeight: '1.6' }}>{profile?.bio || '—'}</div>
              <hr style={{ borderColor: '#f1f5f9' }} />
              <div className="info-row"><span className="info-label">Minimum Charge</span><span className="info-value">{profile?.minimum_charge ? `${profile.minimum_charge} EGP` : '—'}</span></div>
              <div className="info-row"><span className="info-label">Response Time</span><span className="info-value">{profile?.response_time_minutes != null ? `${profile.response_time_minutes} min` : '—'}</span></div>
            </div>
          </div>

          {/* Ratings */}
          <div className="card border-0 shadow-sm mt-4" style={{ borderRadius: '15px' }}>
            <div className="card-body p-4">
              <div className="d-flex align-items-center justify-content-between mb-3">
                <h6 className="fw-bold mb-0" style={{ color: '#0f172a' }}>Reviews</h6>
                <span className="text-muted" style={{ fontSize: '13px' }}>
                  Avg <strong>{(ratings?.average || 0).toFixed(1)}</strong> / 5 ({ratings?.count || 0})
                </span>
              </div>
              {ratingsList.length === 0 ? (
                <p className="text-muted mb-0" style={{ fontSize: '13px' }}>No reviews yet.</p>
              ) : (
                <div style={{ maxHeight: '420px', overflowY: 'auto' }} className="pe-1">
                  {ratingsList.map((r) => (
                    <div key={r.id} className="mb-3 p-3" style={{ backgroundColor: '#f8fafc', borderRadius: '10px' }}>
                      <div className="d-flex align-items-center justify-content-between mb-1">
                        <div className="fw-semibold" style={{ fontSize: '13px', color: '#1e293b' }}>
                          {r.client_name || r.client_username || '—'}
                        </div>
                        <div style={{ fontSize: '13px' }}>
                          {[1, 2, 3, 4, 5].map((star) => (
                            <i key={star} className={`bi ${star <= r.stars ? 'bi-star-fill' : 'bi-star'}`} style={{ color: '#f59e0b', fontSize: '12px' }}></i>
                          ))}
                        </div>
                      </div>
                      {r.review && <p className="mb-1" style={{ fontSize: '13px', color: '#475569' }}>{r.review}</p>}
                      <div className="text-muted" style={{ fontSize: '11px' }}>
                        Order #{r.order_id} · {new Date(r.created_at).toLocaleDateString()}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Orders */}
        <div className="col-lg-8">
          <div className="card border-0 shadow-sm" style={{ borderRadius: '15px' }}>
            <div className="card-body p-4">
              <h6 className="fw-bold mb-3" style={{ color: '#0f172a' }}>Order History</h6>
              <div className="table-responsive">
                <table className="table table-hover align-middle mb-0">
                  <thead style={{ backgroundColor: '#f8fafc' }}>
                    <tr>
                      <th style={thStyle}>Order</th>
                      <th style={thStyle}>Client</th>
                      <th style={thStyle}>Service</th>
                      <th style={thStyle}>Status</th>
                      <th style={thStyle}>Created</th>
                      <th style={thStyle}>Cancellation</th>
                    </tr>
                  </thead>
                  <tbody>
                    {ordersList.length === 0 ? (
                      <tr><td colSpan="6" className="text-center py-4 text-muted">No orders for this worker.</td></tr>
                    ) : ordersList.map((o) => {
                      const sc = statusStyle(o.status, o.cancellation_reason);
                      const reason = reasonStyle(o.cancellation_reason);
                      return (
                        <tr key={o.id}>
                          <td style={{ fontWeight: '500' }}>#{o.id}</td>
                          <td style={{ color: '#475569', fontSize: '13px' }}>
                            {o.client?.display_name || o.client?.username || '—'}
                          </td>
                          <td style={{ color: '#475569', fontSize: '13px' }}>
                            {o.service_category?.name || '—'}
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
        </div>
      </div>

      <style>{`
        .info-row { display: flex; justify-content: space-between; align-items: center; padding: 6px 0; }
        .info-label { font-size: 12px; color: #94a3b8; }
        .info-value { font-size: 13px; color: #1e293b; font-weight: 500; text-align: end; }
      `}</style>
    </div>
  );
};

const thStyle = { fontSize: '12px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase' };

export default WorkerProfile;