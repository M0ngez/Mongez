import { useEffect } from 'react';
import { Container } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useTheme } from '../context/ThemeContext';
import { LandingDataProvider } from '../context/LandingDataContext';
import Footer from '../components/layout/Footer';
import './Landing.css';
import './PrivacyPolicy.css';

const SECTIONS = [
  {
    icon: 'bi-shield-check',
    titleKey: 'privacy_intro_title',
    bodyKey: 'privacy_intro_body',
  },
  {
    icon: 'bi-person-badge',
    titleKey: 'privacy_account_title',
    bodyKey: 'privacy_account_body',
    bullets: ['privacy_account_b1', 'privacy_account_b2', 'privacy_account_b3', 'privacy_account_b4'],
  },
  {
    icon: 'bi-images',
    titleKey: 'privacy_media_title',
    bodyKey: 'privacy_media_body',
    bullets: ['privacy_media_b1', 'privacy_media_b2', 'privacy_media_b3'],
  },
  {
    icon: 'bi-credit-card',
    titleKey: 'privacy_id_title',
    bodyKey: 'privacy_id_body',
    bullets: ['privacy_id_b1', 'privacy_id_b2'],
  },
  {
    icon: 'bi-bell',
    titleKey: 'privacy_push_title',
    bodyKey: 'privacy_push_body',
    bullets: ['privacy_push_b1', 'privacy_push_b2'],
  },
  {
    icon: 'bi-bug',
    titleKey: 'privacy_crash_title',
    bodyKey: 'privacy_crash_body',
    bullets: ['privacy_crash_b1', 'privacy_crash_b2'],
  },
  {
    icon: 'bi-geo-alt',
    titleKey: 'privacy_location_title',
    bodyKey: 'privacy_location_body',
    highlight: true,
  },
  {
    icon: 'bi-diagram-3',
    titleKey: 'privacy_share_title',
    bodyKey: 'privacy_share_body',
    bullets: ['privacy_share_b1', 'privacy_share_b2', 'privacy_share_b3'],
  },
  {
    icon: 'bi-clock-history',
    titleKey: 'privacy_retention_title',
    bodyKey: 'privacy_retention_body',
  },
  {
    icon: 'bi-person-check',
    titleKey: 'privacy_rights_title',
    bodyKey: 'privacy_rights_body',
    bullets: ['privacy_rights_b1', 'privacy_rights_b2', 'privacy_rights_b3'],
    contactEmail: true,
  },
];

function PrivacyPolicy() {
  const { t, i18n } = useTranslation();
  const { theme } = useTheme();
  const isRtl = i18n.language === 'ar';

  useEffect(() => {
    document.documentElement.dir = i18n.language === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.lang = i18n.language;
  }, [i18n.language]);

  const email = t('footer_email');
  const phone = t('footer_phone');
  const address = t('footer_address');

  return (
    <div className="landing-page privacy-page" data-theme={theme} dir={isRtl ? 'rtl' : 'ltr'}>
      <LandingDataProvider>
        <main>
          <section className="privacy-hero">
            <Container>
              <div className="section-header">
                <div className="section-badge">
                  <i className="bi bi-shield-lock"></i>
                  {t('privacy_badge')}
                </div>
                <h1 className="section-title">{t('privacy_title')}</h1>
                <p className="section-subtitle">{t('privacy_subtitle')}</p>
                <div className="privacy-updated">
                  <i className="bi bi-calendar3"></i>
                  <span>
                    {t('privacy_updated_label')}: {t('privacy_updated_value')}
                  </span>
                </div>
              </div>
            </Container>
          </section>

          <section className="section-padding privacy-content">
            <Container>
              <div className="privacy-list">
                {SECTIONS.map((section) => (
                  <article
                    key={section.titleKey}
                    className={`privacy-card${section.highlight ? ' privacy-card-highlight' : ''}`}
                  >
                    <div className="privacy-card-head">
                      <span className="privacy-card-icon">
                        <i className={`bi ${section.icon}`}></i>
                      </span>
                      <h2 className="privacy-card-title">{t(section.titleKey)}</h2>
                    </div>

                    <p className="privacy-card-body">
                      {section.contactEmail
                        ? t(section.bodyKey, { email })
                        : t(section.bodyKey)}
                    </p>

                    {section.bullets && (
                      <ul className="privacy-bullets">
                        {section.bullets.map((key) => (
                          <li key={key}>
                            <i className="bi bi-check-circle-fill"></i>
                            <span>{t(key, { email })}</span>
                          </li>
                        ))}
                      </ul>
                    )}
                  </article>
                ))}

                <article className="privacy-card privacy-contact-card">
                  <div className="privacy-card-head">
                    <span className="privacy-card-icon">
                      <i className="bi bi-envelope-paper"></i>
                    </span>
                    <h2 className="privacy-card-title">{t('privacy_contact_title')}</h2>
                  </div>

                  <p className="privacy-card-body">{t('privacy_contact_body')}</p>

                  <ul className="privacy-bullets">
                    <li>
                      <i className="bi bi-envelope-fill"></i>
                      <span>
                        {t('privacy_contact_email_label')}:{' '}
                        <a href={`mailto:${email}`}>{email}</a>
                      </span>
                    </li>
                    <li>
                      <i className="bi bi-telephone-fill"></i>
                      <span>
                        {t('privacy_contact_phone_label')}:{' '}
                        <a href={`tel:${phone.replace(/[^+\d]/g, '')}`}>{phone}</a>
                      </span>
                    </li>
                    <li>
                      <i className="bi bi-geo-alt-fill"></i>
                      <span>
                        {t('privacy_contact_address_label')}: {address}
                      </span>
                    </li>
                  </ul>
                </article>

                <article className="privacy-card privacy-contact-card">
                  <div className="privacy-card-head">
                    <span className="privacy-card-icon">
                      <i className="bi bi-person-x"></i>
                    </span>
                    <h2 className="privacy-card-title">{t('privacy_delete_link')}</h2>
                  </div>
                  <p className="privacy-card-body">{t('privacy_delete_body')}</p>
                  <Link to="/delete-account" className="privacy-back-link">
                    <i className={`bi ${isRtl ? 'bi-arrow-left' : 'bi-arrow-right'} me-2`}></i>
                    {t('delacc_title')}
                  </Link>
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

export default PrivacyPolicy;
