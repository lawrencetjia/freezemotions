import { useEffect } from 'react';

const MatomoTracker = () => {
  useEffect(() => {
    // DSGVO-konforme Matomo-Integration
    window._paq = window._paq || [];
    window._paq.push(['disableCookies']);
    window._paq.push(['anonymizeIp']);
    window._paq.push(['trackPageView']);
    window._paq.push(['enableLinkTracking']);

    (function() {
      const u = "http://localhost:8080/";
      window._paq.push(['setTrackerUrl', u+'matomo.php']);
      window._paq.push(['setSiteId', '1']);
      const d = document, g = d.createElement('script');
      g.type = 'text/javascript'; g.async = true;
      g.src = u+'matomo.js';
      d.getElementsByTagName('script')[0].parentNode.appendChild(g);
    })();
  }, []);

  return null;
};

export default MatomoTracker;
