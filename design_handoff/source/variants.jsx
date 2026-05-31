/* eslint-disable */
// VariantFrame — Classic ↔ Premium switcher. Wraps a classic + a premium screen variant
// behind a small floating segmented toggle (defaults to Premium). Lets the Pregled /
// Rezervacije / Profil sections offer both designs in one artboard instead of duplicating
// sections. Loads LAST (after all screen modules). Exposed on window for the App script.
// Pairs with the `.bb-variant-frame > .theme-light { height:100% }` rule in the HTML head,
// which makes whichever variant is shown fill the (premium-sized) artboard cleanly.

const { useState: useSVar } = React;

const VariantFrame = ({ w, h, classic, premium, defaultPremium = true }) => {
  const [prem, setPrem] = useSVar(defaultPremium);
  const opts = [
    { label: 'Classic', val: false, icon: null },
    { label: 'Premium', val: true, icon: 'auto_awesome' },
  ];
  return (
    <div className="bb-variant-frame" style={{ position: 'relative', width: w, height: h, overflow: 'hidden', background: 'var(--bb-bg)' }}>
      {prem ? premium : classic}

      {/* Floating meta control — top-center, clearly above the mocked UI */}
      <div style={{ position: 'absolute', top: 10, left: '50%', transform: 'translateX(-50%)', zIndex: 60 }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', padding: 4, gap: 2,
          background: 'var(--bb-surface)', border: '1px solid var(--bb-border)',
          borderRadius: 999, boxShadow: '0 8px 24px rgba(16,24,40,0.18), 0 2px 6px rgba(16,24,40,0.10)',
        }}>
          {opts.map(o => {
            const on = prem === o.val;
            return (
              <button key={o.label} type="button" onClick={() => setPrem(o.val)} style={{
                display: 'inline-flex', alignItems: 'center', gap: 5,
                padding: '6px 14px', border: 'none', cursor: 'pointer', borderRadius: 999,
                background: on ? 'var(--bb-primary)' : 'transparent',
                color: on ? '#FFFFFF' : 'var(--bb-text-secondary)',
                fontFamily: 'var(--bb-font-sans)', fontSize: 12, fontWeight: 700, letterSpacing: '0.01em',
                boxShadow: on ? 'var(--bb-shadow-purple-sm)' : 'none',
                transition: 'background 120ms ease-out, color 120ms ease-out',
              }}>
                {o.icon && <span className="material-symbols-rounded" style={{ fontSize: 14, fontVariationSettings: "'FILL' 1, 'wght' 600" }}>{o.icon}</span>}
                {o.label}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
};

Object.assign(window, { VariantFrame });
