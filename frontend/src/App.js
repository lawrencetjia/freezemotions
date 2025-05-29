import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import MatomoTracker from './components/MatomoTracker';

function App() {
  const [darkMode, setDarkMode] = useState(true);
  const [backendStatus, setBackendStatus] = useState('Checking...');

  useEffect(() => {
    document.documentElement.classList.toggle('dark', darkMode);
    localStorage.setItem('theme', darkMode ? 'dark' : 'light');
  }, [darkMode]);

  useEffect(() => {
    // Backend Health Check
    fetch('/api/health')
      .then(res => res.json())
      .then(data => setBackendStatus('✅ Connected'))
      .catch(() => setBackendStatus('❌ Offline'));
  }, []);

  return (
    <Router>
      <div className={`App min-h-screen ${darkMode ? 'dark' : ''}`}>
        <MatomoTracker />
        
        <div style={{ 
          minHeight: '100vh', 
          backgroundColor: darkMode ? '#0f172a' : '#ffffff',
          color: darkMode ? '#f1f5f9' : '#1e293b',
          fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
        }}>
          {/* Header */}
          <header style={{
            background: darkMode ? 'linear-gradient(135deg, #1e293b 0%, #334155 100%)' : 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)',
            borderBottom: `1px solid ${darkMode ? '#334155' : '#e2e8f0'}`,
            padding: '1rem 0'
          }}>
            <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '0 20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <h1 style={{ 
                    margin: 0, 
                    background: 'linear-gradient(135deg, #3b82f6, #8b5cf6)', 
                    WebkitBackgroundClip: 'text', 
                    WebkitTextFillColor: 'transparent',
                    fontSize: '2.5rem', 
                    fontWeight: 'bold' 
                  }}>
                    FreezeMotions
                  </h1>
                  <p style={{ 
                    margin: '0.5rem 0 0 0', 
                    color: darkMode ? '#94a3b8' : '#64748b',
                    fontSize: '1.1rem'
                  }}>
                    Professional Self-Hosted Photo Platform
                  </p>
                </div>
                
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ 
                    fontSize: '0.9rem', 
                    color: darkMode ? '#94a3b8' : '#64748b' 
                  }}>
                    Backend: {backendStatus}
                  </div>
                  <button
                    onClick={() => setDarkMode(!darkMode)}
                    style={{
                      background: darkMode ? '#374151' : '#f3f4f6',
                      color: darkMode ? '#ffffff' : '#000000',
                      border: 'none',
                      padding: '0.75rem',
                      borderRadius: '0.5rem',
                      cursor: 'pointer',
                      fontSize: '1.2rem',
                      transition: 'all 0.2s'
                    }}
                    onMouseOver={(e) => e.target.style.transform = 'scale(1.05)'}
                    onMouseOut={(e) => e.target.style.transform = 'scale(1)'}
                  >
                    {darkMode ? '☀️' : '🌙'}
                  </button>
                </div>
              </div>
            </div>
          </header>
          
          {/* Navigation */}
          <nav style={{
            background: darkMode ? '#1e293b' : '#f8fafc',
            borderBottom: `1px solid ${darkMode ? '#334155' : '#e2e8f0'}`,
            padding: '1rem 0'
          }}>
            <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '0 20px' }}>
              <div style={{ display: 'flex', gap: '2rem' }}>
                <NavLink to="/" darkMode={darkMode}>🏠 Home</NavLink>
                <NavLink to="/about" darkMode={darkMode}>ℹ️ About</NavLink>
                <NavLink to="/features" darkMode={darkMode}>⭐ Features</NavLink>
              </div>
            </div>
          </nav>
          
          {/* Main Content */}
          <main style={{ maxWidth: '1200px', margin: '0 auto', padding: '2rem 20px' }}>
            <Routes>
              <Route path="/" element={<HomePage darkMode={darkMode} />} />
              <Route path="/about" element={<AboutPage darkMode={darkMode} />} />
              <Route path="/features" element={<FeaturesPage darkMode={darkMode} />} />
            </Routes>
          </main>
          
          {/* Footer */}
          <footer style={{
            background: darkMode ? '#0f172a' : '#f1f5f9',
            borderTop: `1px solid ${darkMode ? '#334155' : '#e2e8f0'}`,
            padding: '3rem 0',
            marginTop: '4rem',
            textAlign: 'center',
            color: darkMode ? '#94a3b8' : '#64748b'
          }}>
            <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '0 20px' }}>
              <p style={{ margin: '0 0 1rem 0', fontSize: '1.1rem' }}>
                &copy; 2024 FreezeMotions - Professional Self-Hosted Photo Platform
              </p>
              <p style={{ margin: 0 }}>
                <a 
                  href="https://github.com/lawrencetjia/freezemotions" 
                  style={{ color: darkMode ? '#60a5fa' : '#3b82f6', textDecoration: 'none' }}
                  onMouseOver={(e) => e.target.style.textDecoration = 'underline'}
                  onMouseOut={(e) => e.target.style.textDecoration = 'none'}
                >
                  🐙 Open Source auf GitHub
                </a>
              </p>
            </div>
          </footer>
        </div>
      </div>
    </Router>
  );
}

// Navigation Link Component
const NavLink = ({ to, children, darkMode }) => (
  <Link
    to={to}
    style={{
      color: darkMode ? '#e2e8f0' : '#475569',
      textDecoration: 'none',
      padding: '0.5rem 1rem',
      borderRadius: '0.375rem',
      transition: 'all 0.2s',
      fontWeight: '500'
    }}
    onMouseOver={(e) => {
      e.target.style.background = darkMode ? '#334155' : '#e2e8f0';
      e.target.style.color = darkMode ? '#f1f5f9' : '#1e293b';
    }}
    onMouseOut={(e) => {
      e.target.style.background = 'transparent';
      e.target.style.color = darkMode ? '#e2e8f0' : '#475569';
    }}
  >
    {children}
  </Link>
);

// Homepage Component
const HomePage = ({ darkMode }) => (
  <div style={{ textAlign: 'center' }}>
    <div style={{ maxWidth: '800px', margin: '0 auto' }}>
      <h2 style={{ 
        fontSize: '3.5rem', 
        fontWeight: 'bold', 
        marginBottom: '2rem',
        background: 'linear-gradient(135deg, #3b82f6, #8b5cf6, #06b6d4)', 
        WebkitBackgroundClip: 'text', 
        WebkitTextFillColor: 'transparent'
      }}>
        Willkommen bei FreezeMotions! 🚀
      </h2>
      
      <p style={{ 
        fontSize: '1.3rem', 
        marginBottom: '3rem', 
        lineHeight: '1.6',
        color: darkMode ? '#cbd5e1' : '#475569'
      }}>
        Die moderne, DSGVO-konforme und selbst gehostete Flickr-Alternative
        für professionelle Sport- und Eventfotografen.
      </p>
      
      {/* Status Cards */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', 
        gap: '2rem', 
        marginBottom: '3rem' 
      }}>
        <StatusCard 
          title="🚀 Installation"
          status="Erfolgreich"
          description="Alle Services laufen korrekt"
          darkMode={darkMode}
          statusColor="#10b981"
        />
        <StatusCard 
          title="🐳 Docker"
          status="Aktiv"
          description="Container orchestriert"
          darkMode={darkMode}
          statusColor="#3b82f6"
        />
        <StatusCard 
          title="🔒 Sicherheit"
          status="Aktiviert"
          description="SSL & Firewall konfiguriert"
          darkMode={darkMode}
          statusColor="#8b5cf6"
        />
      </div>
      
      {/* Quick Links */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', 
        gap: '2rem', 
        marginTop: '3rem' 
      }}>
        <QuickLinkCard 
          icon="📊"
          title="Backend API"
          description="Health Check & Status"
          link="/api/health"
          darkMode={darkMode}
        />
        <QuickLinkCard 
          icon="📈"
          title="Analytics"
          description="Matomo Dashboard"
          link="http://localhost:8081"
          darkMode={darkMode}
        />
        <QuickLinkCard 
          icon="🗄️"
          title="Database"
          description="MySQL auf Port 3306"
          link="#"
          darkMode={darkMode}
        />
      </div>
      
      {/* Getting Started */}
      <div style={{
        background: darkMode ? 'linear-gradient(135deg, #1e293b, #334155)' : 'linear-gradient(135deg, #f0f9ff, #e0f2fe)',
        padding: '2rem',
        borderRadius: '1rem',
        marginTop: '3rem',
        border: `1px solid ${darkMode ? '#334155' : '#bae6fd'}`
      }}>
        <h3 style={{ 
          fontSize: '1.5rem', 
          fontWeight: '600', 
          marginBottom: '1rem',
          color: darkMode ? '#f1f5f9' : '#0c4a6e'
        }}>
          🎯 Nächste Schritte
        </h3>
        <div style={{ textAlign: 'left', maxWidth: '600px', margin: '0 auto' }}>
          <StepItem 
            step="1" 
            text="Matomo Analytics einrichten" 
            darkMode={darkMode}
          />
          <StepItem 
            step="2" 
            text="Ersten Benutzer registrieren" 
            darkMode={darkMode}
          />
          <StepItem 
            step="3" 
            text="FTP-Upload mit Kamera testen" 
            darkMode={darkMode}
          />
          <StepItem 
            step="4" 
            text="SSL-Zertifikate für Domain aktivieren" 
            darkMode={darkMode}
          />
        </div>
      </div>
    </div>
  </div>
);

// About Page Component
const AboutPage = ({ darkMode }) => (
  <div style={{ maxWidth: '800px', margin: '0 auto' }}>
    <h2 style={{ fontSize: '2.5rem', fontWeight: 'bold', marginBottom: '2rem' }}>
      Über FreezeMotions
    </h2>
    
    <div style={{
      background: darkMode ? '#1e293b' : '#f8fafc',
      padding: '2rem',
      borderRadius: '1rem',
      marginBottom: '2rem',
      border: `1px solid ${darkMode ? '#334155' : '#e2e8f0'}`
    }}>
      <p style={{ fontSize: '1.1rem', lineHeight: '1.7', marginBottom: '1.5rem' }}>
        FreezeMotions ist eine vollständig selbst gehostete Fotoplattform, die speziell für 
        professionelle Sport- und Eventfotografen entwickelt wurde. Die Plattform kombiniert
        moderne Webtechnologien mit DSGVO-konformen Analytics und bietet eine sichere,
        skalierbare Lösung für die professionelle Fotoverwaltung.
      </p>
      
      <h3 style={{ fontSize: '1.3rem', fontWeight: '600', marginBottom: '1rem' }}>
        🛠️ Technologie-Stack
      </h3>
      <TechStackGrid darkMode={darkMode} />
    </div>
  </div>
);

// Features Page Component
const FeaturesPage = ({ darkMode }) => (
  <div style={{ maxWidth: '1000px', margin: '0 auto' }}>
    <h2 style={{ fontSize: '2.5rem', fontWeight: 'bold', marginBottom: '2rem', textAlign: 'center' }}>
      ⭐ Features & Funktionen
    </h2>
    
    <div style={{ 
      display: 'grid', 
      gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', 
      gap: '2rem' 
    }}>
      <FeatureCard 
        icon="📸"
        title="Professionelle Fotoverwaltung"
        description="Organisieren Sie Ihre Bilder in Alben mit einem modernen, Flickr-ähnlichen Interface. Unterstützt RAW-Dateien, Metadaten und automatische Thumbnail-Generierung."
        darkMode={darkMode}
      />
      <FeatureCard 
        icon="🔒"
        title="DSGVO-Konform"
        description="Selbstgehostetes Matomo Analytics ohne externe Tracker. Alle Daten bleiben auf Ihrem Server. IP-Anonymisierung und cookiefreie Analyse inklusive."
        darkMode={darkMode}
      />
      <FeatureCard 
        icon="📁"
        title="FTP-Upload"
        description="Direkte Uploads von professionellen Kameras via FTP. Unterstützt passive FTP-Modi und sichere Verbindungen für nahtlose Workflows."
        darkMode={darkMode}
      />
      <FeatureCard 
        icon="🐳"
        title="Docker-Containerisierung"
        description="Vollständige Containerisierung aller Services. Einfache Skalierung, Updates und Backup-Strategien. One-Click-Installation verfügbar."
        darkMode={darkMode}
      />
      <FeatureCard 
        icon="📧"
        title="E-Mail-Benachrichtigungen"
        description="Automatische Benachrichtigungen bei Uploads, Registrierungen und wichtigen Events. SMTP-Integration mit allen gängigen Anbietern."
        darkMode={darkMode}
      />
      <FeatureCard 
        icon="🛡️"
        title="Enterprise-Sicherheit"
        description="SSL/TLS-Verschlüsselung, Firewall-Integration, sichere Authentifizierung und regelmäßige Sicherheitsupdates für produktive Umgebungen."
        darkMode={darkMode}
      />
    </div>
  </div>
);

// Helper Components
const StatusCard = ({ title, status, description, darkMode, statusColor }) => (
  <div style={{
    background: darkMode ? '#1e293b' : '#ffffff',
    padding: '1.5rem',
    borderRadius: '0.75rem',
    border: `1px solid ${darkMode ? '#334155' : '#e2e8f0'}`,
    textAlign: 'center'
  }}>
    <h3 style={{ fontSize: '1.1rem', fontWeight: '600', marginBottom: '0.5rem' }}>
      {title}
    </h3>
    <div style={{ 
      color: statusColor, 
      fontWeight: 'bold', 
      fontSize: '1rem',
      marginBottom: '0.5rem'
    }}>
      {status}
    </div>
    <p style={{ 
      fontSize: '0.9rem', 
      color: darkMode ? '#94a3b8' : '#64748b',
      margin: 0
    }}>
      {description}
    </p>
  </div>
);

const QuickLinkCard = ({ icon, title, description, link, darkMode }) => (
  <a
    href={link}
    target="_blank"
    rel="noopener noreferrer"
    style={{
      display: 'block',
      background: darkMode ? '#1e293b' : '#ffffff',
      padding: '1.5rem',
      borderRadius: '0.75rem',
      border: `1px solid ${darkMode ? '#334155' : '#e2e8f0'}`,
      textDecoration: 'none',
      color: 'inherit',
      transition: 'transform 0.2s, box-shadow 0.2s'
    }}
    onMouseOver={(e) => {
      e.currentTarget.style.transform = 'translateY(-2px)';
      e.currentTarget.style.boxShadow = darkMode ? '0 8px 25px rgba(0,0,0,0.3)' : '0 8px 25px rgba(0,0,0,0.1)';
    }}
    onMouseOut={(e) => {
      e.currentTarget.style.transform = 'translateY(0)';
      e.currentTarget.style.boxShadow = 'none';
    }}
  >
    <div style={{ fontSize: '2rem', marginBottom: '1rem' }}>{icon}</div>
    <h4 style={{ fontSize: '1.1rem', fontWeight: '600', marginBottom: '0.5rem' }}>
      {title}
    </h4>
    <p style={{ 
      fontSize: '0.9rem', 
      color: darkMode ? '#94a3b8' : '#64748b',
      margin: 0
    }}>
      {description}
    </p>
  </a>
);

const StepItem = ({ step, text, darkMode }) => (
  <div style={{ 
    display: 'flex', 
    alignItems: 'center', 
    marginBottom: '1rem',
    padding: '0.75rem',
    background: darkMode ? 'rgba(51, 65, 85, 0.3)' : 'rgba(255, 255, 255, 0.7)',
    borderRadius: '0.5rem'
  }}>
    <div style={{
      background: 'linear-gradient(135deg, #3b82f6, #8b5cf6)',
      color: 'white',
      width: '2rem',
      height: '2rem',
      borderRadius: '50%',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontSize: '0.9rem',
      fontWeight: 'bold',
      marginRight: '1rem'
    }}>
      {step}
    </div>
    <span style={{ fontSize: '1rem' }}>{text}</span>
  </div>
);

const TechStackGrid = ({ darkMode }) => (
  <div style={{ 
    display: 'grid', 
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
    gap: '1rem',
    marginTop: '1rem'
  }}>
    {[
      { tech: 'React 18', desc: 'Modern Frontend' },
      { tech: 'Node.js/Express', desc: 'Backend API' },
      { tech: 'MySQL 8', desc: 'Datenbank' },
      { tech: 'Docker', desc: 'Containerisierung' },
      { tech: 'Matomo', desc: 'Analytics' },
      { tech: 'Let\'s Encrypt', desc: 'SSL/TLS' }
    ].map((item, index) => (
      <div key={index} style={{
        padding: '1rem',
        background: darkMode ? 'rgba(51, 65, 85, 0.3)' : 'rgba(255, 255, 255, 0.7)',
        borderRadius: '0.5rem',
        textAlign: 'center'
      }}>
        <div style={{ fontWeight: '600', marginBottom: '0.25rem' }}>{item.tech}</div>
        <div style={{ 
          fontSize: '0.85rem', 
          color: darkMode ? '#94a3b8' : '#64748b' 
        }}>
          {item.desc}
        </div>
      </div>
    ))}
  </div>
);

const FeatureCard = ({ icon, title, description, darkMode }) => (
  <div style={{
    background: darkMode ? '#1e293b' : '#ffffff',
    padding: '2rem',
    borderRadius: '1rem',
    border: `1px solid ${darkMode ? '#334155' : '#e2e8f0'}`,
    textAlign: 'center',
    transition: 'transform 0.2s'
  }}
  onMouseOver={(e) => e.currentTarget.style.transform = 'translateY(-4px)'}
  onMouseOut={(e) => e.currentTarget.style.transform = 'translateY(0)'}
  >
    <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>{icon}</div>
    <h3 style={{ fontSize: '1.3rem', fontWeight: '600', marginBottom: '1rem' }}>
      {title}
    </h3>
    <p style={{ 
      fontSize: '0.95rem', 
      lineHeight: '1.6',
      color: darkMode ? '#cbd5e1' : '#475569',
      margin: 0
    }}>
      {description}
    </p>
  </div>
);

export default App;
