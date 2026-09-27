import { useEffect, useState } from 'react';
import { Container } from 'react-bootstrap';
import { Link, useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useTheme } from '../context/ThemeContext';
import { LandingDataProvider } from '../context/LandingDataContext';
import Footer from '../components/layout/Footer';
import { accountAPI } from '../services/api';
import './Landing.css';
import './PrivacyPolicy.css';

// no-token: reached from a plain browser, nothing authorises the action
// confirm:  a valid single-use token is in the URL, waiting on the user
// working:  request in flight
// active:   backend refused, the account still has orders in progress
// done:     deletion applied
// error:    anything else failed
const STAGE = {
  NO_TOKEN: 'no-token',
  CONFIRM: 'confirm',
  WORKING: 'working',
  ACTIVE: 'active',
  DONE: 'done',
  ERROR: 'error',
};

function Card({ icon, title, children }) {
  return (
    <article className="privacy-card">
      <div className="privacy-card-head">
        <span className="privacy-card-icon">
          <i className={`bi ${icon}`}></i>
        </span>
        <h2 className="privacy-card-title">{title}</h2>
      </div>
      {children}
    </article>
  );
}

function DeleteAccount() {
  const { t, i18n } = useTranslation();
  const { theme } = useTheme();
  const isRtl = i18n.language === 'ar';
  const [searchParams] = useSearchParams();
  const token = searchParams.get('token') || '';

  const [stage, setStage] = useState(token ? STAGE.CONFIRM : STAGE.NO_TOKEN);
  const [acknowledged, setAcknowledged] = useState(false);
  const [activeCount, setActiveCount] = useState(0);

  useEffect(() => {
    document.documentElement.dir = i18n.language === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.lang = i18n.language;
  }, [i18n.language]);

  async function handleConfirm() {
    if (!acknowledged || stage === STAGE.WORKING) return;
    setStage(STAGE.WORKING);
    try {
      await accountAPI.confirmDeletion(token);
      setStage(STAGE.DONE);
    } catch (err) {
      const data = err.response?.data;
      if (data?.code === 'active_orders') {
        setActiveCount(data.active_orders || 0);
        setStage(STAGE.ACTIVE);
      } else {
        setStage(STAGE.ERROR);
      }
    }
  }

  const removed = ['delacc_removed_b1', 'delacc_removed_b2', 'delacc_removed_b3', 'delacc_removed_b4'];
  const kept = ['delacc_kept_b1', 'delacc_kept_b2', 'delacc_kept_b3'];

  return (
    <div className="landing-page privacy-page" data-theme={theme} dir={isRtl ? 'rtl' : 'ltr'}>
      <LandingDataProvider>
        <main>
          <section className="privacy-hero">
            <Container>
              <div className="section-header">
                <div className="section-badge">
                  <i className="bi bi-person-x"></i>
                  {t('delacc_badge')}
                </div>
                <h1 className="section-title">{t('delacc_title')}</h1>
                <p className="section-subtitle">{t('delacc_subtitle')}</p>
              </div>
            </Container>
          </section>

          <section className="section-padding privacy-content">
            <Container>
              <div className="privacy-list">
                <Card icon="bi-trash3" title={t('delacc_removed_title')}>
                  <p className="privacy-card-body">{t('delacc_removed_body')}</p>
                  <ul className="privacy-bullets">
                    {removed.map((key) => (
                      <li key={key}>
                        <i className="bi bi-check-circle-fill"></i>
                        <span>{t(key)}</span>
                      </li>
                    ))}
                  </ul>
                </Card>

                <Card icon="bi-archive" title={t('delacc_kept_title')}>
                  <p className="privacy-card-body">{t('delacc_kept_body')}</p>
                  <ul className="privacy-bullets">
                    {kept.map((key) => (
                      <li key={key}>
                        <i className="bi bi-check-circle-fill"></i>
                        <span>{t(key)}</span>
                      </li>
                    ))}
                  </ul>
                </Card>

                <article className="privacy-card privacy-card-highlight">
                  <p className="privacy-card-body">{t('delacc_note_body')}</p>
                  <p className="privacy-card-body mb-0">
                    <strong>{t('delacc_retention_title')}: </strong>
                    {t('delacc_retention_body')}
                  </p>
                </article>

                {stage === STAGE.NO_TOKEN && (
                  <Card icon="bi-phone" title={t('delacc_no_token_title')}>
                    <p className="privacy-card-body">{t('delacc_no_token_body')}</p>
                    <p className="privacy-card-body">{t('delacc_no_token_email')}</p>
                  </Card>
                )}

                {stage === STAGE.DONE && (
                  <Card icon="bi-check2-circle" title={t('delacc_done_title')}>
                    <p className="privacy-card-body mb-0">{t('delacc_done_body')}</p>
                  </Card>
                )}

                {stage === STAGE.ACTIVE && (
                  <Card icon="bi-hourglass-split" title={t('delacc_error_title')}>
                    <p className="privacy-card-body mb-0">
                      {t('delacc_active_orders', { count: activeCount })}
                    </p>
                  </Card>
                )}

                {stage === STAGE.ERROR && (
                  <Card icon="bi-exclamation-triangle" title={t('delacc_error_title')}>
                    <p className="privacy-card-body mb-0">{t('delacc_error_body')}</p>
                  </Card>
                )}

                {(stage === STAGE.CONFIRM || stage === STAGE.WORKING) && (
                  <Card icon="bi-exclamation-octagon" title={t('delacc_confirm')}>
                    <p className="privacy-card-body">{t('delacc_note_body')}</p>

                    <div className="form-check mb-3">
                      <input
                        id="delacc-ack"
                        className="form-check-input"
                        type="checkbox"
                        checked={acknowledged}
                        disabled={stage === STAGE.WORKING}
                        onChange={(e) => setAcknowledged(e.target.checked)}
                      />
                      <label htmlFor="delacc-ack" className="form-check-label" style={{ fontSize: 15 }}>
                        {t('delacc_checkbox')}
                      </label>
                    </div>

                    <button
                      type="button"
                      className="btn w-100"
                      disabled={!acknowledged || stage === STAGE.WORKING}
                      onClick={handleConfirm}
                      style={{
                        backgroundColor: acknowledged ? '#ef4444' : '#cbd5e1',
                        borderColor: acknowledged ? '#ef4444' : '#cbd5e1',
                        color: '#fff',
                        borderRadius: 10,
                        fontWeight: 600,
                      }}
                    >
                      <i className="bi bi-trash3 me-2"></i>
                      {stage === STAGE.WORKING ? t('delacc_working') : t('delacc_confirm')}
                    </button>
                  </Card>
                )}

                <article className="privacy-card privacy-contact-card">
                  <div className="privacy-card-head">
                    <span className="privacy-card-icon">
                      <i className="bi bi-shield-check"></i>
                    </span>
                    <h2 className="privacy-card-title">{t('delacc_privacy_link')}</h2>
                  </div>
                  <p className="privacy-card-body mb-0">
                    <Link to="/privacy">{t('privacy_title')}</Link>
                  </p>
                </article>
              </div>

              <div className="text-center mt-5">
                <Link to="/" className="privacy-back-link">
                  <i className={`bi ${isRtl ? 'bi-arrow-right' : 'bi-arrow-left'} me-2`}></i>
                  {t('privacy_back_home')}
                </Link>
              </div>
            </Container>
          </section>
        </main>
        <Footer />
      </LandingDataProvider>
    </div>
  );
}

export default DeleteAccount;
