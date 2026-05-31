/* eslint-disable */
// BookBed primitives — the component library every screen composes from.
// Exposes BB.* on window for use across script files.

const { useState, useEffect, useRef, useMemo, Fragment } = React;

// ──────────────────────────────────────────────────────────────
// Icon helper (Material Symbols Rounded webfont)
// ──────────────────────────────────────────────────────────────
const Icon = ({ name, size = 20, fill = 1, weight = 500, className = '', style = {} }) => (
  <span
    className={`material-symbols-rounded ${className}`}
    style={{
      fontSize: size,
      lineHeight: 1,
      fontVariationSettings: `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' 0, 'opsz' 24`,
      ...style,
    }}
  >
    {name}
  </span>
);

// ──────────────────────────────────────────────────────────────
// Logo — BookBed "b" mark
// ──────────────────────────────────────────────────────────────
const Logo = ({ size = 32, light = false }) => (
  <img
    src="assets/logo.png"
    width={size}
    height={size}
    alt="BookBed"
    style={{ display: 'inline-block', verticalAlign: 'middle' }}
  />
);

// ──────────────────────────────────────────────────────────────
// BBAvatar — initials fallback, photo if provided
// ──────────────────────────────────────────────────────────────
const sizeMap = { xs: 28, sm: 36, md: 44, lg: 56, xl: 80 };
const BBAvatar = ({ name = '', src, size = 'md', tone = 'primary', ring = false }) => {
  const px = sizeMap[size] || 44;
  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map(n => n[0]?.toUpperCase())
    .join('') || '?';
  const fontSize = Math.round(px * 0.4);
  const tones = {
    primary: { bg: 'var(--bb-primary-tint-bg)', text: 'var(--bb-primary)' },
    success: { bg: 'var(--bb-success-tint)', text: 'var(--bb-success)' },
    info: { bg: 'var(--bb-info-tint)', text: 'var(--bb-info)' },
    tertiary: { bg: 'var(--bb-tertiary-tint)', text: 'var(--bb-tertiary-dark)' },
    neutral: { bg: 'var(--bb-surface-variant)', text: 'var(--bb-text-secondary)' },
    'on-gradient': { bg: 'rgba(255,255,255,0.18)', text: '#FFFFFF' },
  };
  const t = tones[tone] || tones.primary;
  const style = {
    width: px, height: px, borderRadius: '50%',
    background: src ? `center/cover no-repeat url(${src}), ${t.bg}` : t.bg,
    color: t.text,
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    fontSize, fontWeight: 600, lineHeight: 1, letterSpacing: 0,
    boxShadow: ring ? '0 0 0 3px rgba(255,255,255,0.2)' : 'none',
    flexShrink: 0,
  };
  return <span style={style}>{!src && initials}</span>;
};

// ──────────────────────────────────────────────────────────────
// BBAvatarSlot — user-fillable circular avatar (drag a photo in).
// Shares one id by default so the owner's photo shows everywhere at once.
// ──────────────────────────────────────────────────────────────
const BBAvatarSlot = ({ id = 'bb-owner-avatar', size = 80, placeholder = 'Foto', ring = false, ringColor = 'rgba(255,255,255,0.25)', style = {} }) => (
  <image-slot
    id={id}
    shape="circle"
    placeholder={placeholder}
    style={{ display: 'block', width: size, height: size, flexShrink: 0, borderRadius: '50%', boxShadow: ring ? `0 0 0 3px ${ringColor}` : 'none', ...style }}
  ></image-slot>
);

// ──────────────────────────────────────────────────────────────
// BBButton — variants × sizes × states
// ──────────────────────────────────────────────────────────────
const BBButton = ({
  variant = 'primary',
  size = 'md',
  iconLeft,
  iconRight,
  fullWidth = false,
  loading = false,
  disabled = false,
  active = false,
  onClick,
  children,
  style = {},
  ariaLabel,
  asIcon = false, // icon-only
}) => {
  const heights = { sm: 36, md: 44, lg: 52 };
  const px = { sm: 12, md: 16, lg: 20 };
  const fontSize = { sm: 13, md: 14, lg: 15 };
  const iconSize = { sm: 16, md: 18, lg: 20 };

  const baseStyle = {
    height: heights[size],
    padding: asIcon ? 0 : `0 ${px[size]}px`,
    width: asIcon ? heights[size] : (fullWidth ? '100%' : 'auto'),
    minWidth: heights[size],
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    gap: 8,
    fontFamily: 'var(--bb-font-sans)',
    fontSize: fontSize[size],
    fontWeight: 600,
    letterSpacing: '-0.005em',
    borderRadius: 'var(--bb-radius-sm)',
    cursor: disabled || loading ? 'not-allowed' : 'pointer',
    opacity: disabled ? 0.45 : 1,
    transition: 'transform 120ms var(--ease, ease-out), box-shadow 120ms ease-out, background 120ms ease-out, border-color 120ms ease-out',
    border: '1px solid transparent',
    userSelect: 'none',
    whiteSpace: 'nowrap',
    ...style,
  };

  const variants = {
    primary: {
      background: 'var(--bb-primary)',
      color: 'var(--bb-text-on-primary)',
      boxShadow: 'var(--bb-shadow-purple-sm)',
    },
    secondary: {
      background: 'var(--bb-surface)',
      color: 'var(--bb-text-primary)',
      borderColor: 'var(--bb-border)',
    },
    tertiary: {
      background: 'transparent',
      color: 'var(--bb-primary)',
    },
    destructive: {
      background: 'var(--bb-error)',
      color: '#FFFFFF',
    },
    'destructive-soft': {
      background: 'var(--bb-error-tint)',
      color: 'var(--bb-error)',
    },
    success: {
      background: 'var(--bb-success)',
      color: '#FFFFFF',
    },
    'on-gradient': {
      background: 'rgba(255,255,255,0.16)',
      color: '#FFFFFF',
      borderColor: 'rgba(255,255,255,0.22)',
      backdropFilter: 'blur(8px)',
    },
    'on-gradient-solid': {
      background: '#FFFFFF',
      color: 'var(--bb-primary)',
    },
  };

  const handleHover = (e, isEnter) => {
    if (disabled || loading) return;
    if (variant === 'primary' && isEnter) {
      e.currentTarget.style.background = 'var(--bb-primary-dark)';
      e.currentTarget.style.boxShadow = 'var(--bb-shadow-purple)';
      e.currentTarget.style.transform = 'translateY(-1px)';
    } else if (variant === 'primary') {
      e.currentTarget.style.background = 'var(--bb-primary)';
      e.currentTarget.style.boxShadow = 'var(--bb-shadow-purple-sm)';
      e.currentTarget.style.transform = 'none';
    } else if (variant === 'secondary' && isEnter) {
      e.currentTarget.style.background = 'var(--bb-surface-variant)';
    } else if (variant === 'secondary') {
      e.currentTarget.style.background = 'var(--bb-surface)';
    } else if (variant === 'tertiary' && isEnter) {
      e.currentTarget.style.background = 'var(--bb-primary-tint-hover)';
    } else if (variant === 'tertiary') {
      e.currentTarget.style.background = 'transparent';
    } else if (variant === 'destructive' && isEnter) {
      e.currentTarget.style.background = 'var(--bb-secondary-dark)';
    } else if (variant === 'destructive') {
      e.currentTarget.style.background = 'var(--bb-error)';
    }
  };

  return (
    <button
      type="button"
      onClick={loading || disabled ? undefined : onClick}
      onMouseEnter={(e) => handleHover(e, true)}
      onMouseLeave={(e) => handleHover(e, false)}
      disabled={disabled || loading}
      aria-label={ariaLabel}
      style={{ ...baseStyle, ...(variants[variant] || variants.primary) }}
    >
      {loading ? (
        <Spinner size={iconSize[size]} />
      ) : (
        <>
          {iconLeft && <Icon name={iconLeft} size={iconSize[size]} />}
          {children && <span>{children}</span>}
          {iconRight && <Icon name={iconRight} size={iconSize[size]} />}
        </>
      )}
    </button>
  );
};

const Spinner = ({ size = 18, color }) => (
  <span
    style={{
      width: size, height: size,
      border: `2px solid ${color || 'currentColor'}`,
      borderRightColor: 'transparent',
      borderRadius: '50%',
      display: 'inline-block',
      animation: 'bb-spin 0.7s linear infinite',
    }}
  />
);

// ──────────────────────────────────────────────────────────────
// BBInput — premium input with optional icon, error, char counter
// ──────────────────────────────────────────────────────────────
const BBInput = ({
  label,
  value = '',
  placeholder = '',
  iconLeft,
  iconRight,
  trailingAction,
  type = 'text',
  error,
  helper,
  disabled = false,
  focused = false,
  charLimit,
  size = 'md',
  fullWidth = true,
  style = {},
}) => {
  const [isFocused, setFocused] = useState(false);
  const showFocused = focused || isFocused;
  const heights = { sm: 40, md: 48, lg: 56 };
  const px = 14;

  const fieldStyle = {
    height: heights[size],
    width: fullWidth ? '100%' : 'auto',
    display: 'flex', alignItems: 'center',
    gap: 10,
    padding: `0 ${px}px`,
    borderRadius: 'var(--bb-radius-sm)',
    background: 'var(--bb-surface)',
    border: `${error ? '2px' : showFocused ? '2px' : '1px'} solid ${
      error ? 'var(--bb-error)' : showFocused ? 'var(--bb-primary)' : 'var(--bb-border)'
    }`,
    boxShadow: showFocused && !error ? 'var(--bb-focus-ring)' : 'none',
    opacity: disabled ? 0.5 : 1,
    cursor: disabled ? 'not-allowed' : 'text',
    transition: 'border-color 120ms ease-out, box-shadow 120ms ease-out',
  };

  return (
    <div style={{ width: fullWidth ? '100%' : 'auto', ...style }}>
      {label && (
        <label className="bb-label" style={{
          display: 'block', marginBottom: 6, color: 'var(--bb-text-secondary)',
        }}>{label}</label>
      )}
      <div style={fieldStyle}>
        {iconLeft && <Icon name={iconLeft} size={18} style={{ color: 'var(--bb-text-tertiary)' }} />}
        <input
          type={type}
          defaultValue={value}
          placeholder={placeholder}
          disabled={disabled}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={{
            border: 'none', outline: 'none', background: 'transparent',
            flex: 1, color: 'var(--bb-text-primary)',
            fontFamily: 'var(--bb-font-sans)', fontSize: 14, lineHeight: 1.4,
            height: '100%', padding: 0,
          }}
        />
        {iconRight && <Icon name={iconRight} size={18} style={{ color: 'var(--bb-text-tertiary)' }} />}
        {trailingAction && trailingAction}
      </div>
      {(helper || error || charLimit) && (
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          marginTop: 6, gap: 12,
          color: error ? 'var(--bb-error)' : 'var(--bb-text-tertiary)',
        }}>
          <span className="bb-caption">{error || helper || ''}</span>
          {charLimit && <span className="bb-caption bb-tnum">{(value || '').length}/{charLimit}</span>}
        </div>
      )}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// BBCard — base surface with shadow + optional border
// ──────────────────────────────────────────────────────────────
const BBCard = ({
  children,
  padded = true,
  selected = false,
  hoverable = false,
  variant = 'default', // default | flat | accent-left
  accentTone = 'tertiary',
  style = {},
  onClick,
  ariaLabel,
}) => {
  const accentColors = {
    primary: 'var(--bb-primary)',
    tertiary: 'var(--bb-tertiary)',
    success: 'var(--bb-success)',
    error: 'var(--bb-error)',
    info: 'var(--bb-info)',
  };

  const base = {
    background: 'var(--bb-surface)',
    borderRadius: 'var(--bb-radius-md)',
    border: `1px solid ${selected ? 'var(--bb-primary)' : 'var(--bb-border-subtle)'}`,
    boxShadow: variant === 'flat' ? 'none' : 'var(--bb-shadow-card)',
    padding: padded ? 20 : 0,
    transition: 'box-shadow 160ms ease-out, transform 160ms ease-out, border-color 160ms ease-out',
    position: 'relative',
    cursor: onClick ? 'pointer' : 'default',
    ...style,
  };

  if (variant === 'accent-left') {
    base.borderLeft = `4px solid ${accentColors[accentTone] || accentColors.tertiary}`;
  }

  const [hover, setHover] = useState(false);
  const hoverStyle = hoverable && hover ? {
    boxShadow: 'var(--bb-shadow-md)',
    transform: 'translateY(-2px)',
  } : {};

  return (
    <div
      role={onClick ? 'button' : undefined}
      aria-label={ariaLabel}
      tabIndex={onClick ? 0 : undefined}
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{ ...base, ...hoverStyle }}
    >
      {children}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// BBChip — filter/choice with count
// ──────────────────────────────────────────────────────────────
const BBChip = ({
  selected = false,
  iconLeft,
  iconRight,
  count,
  countColor,
  onClick,
  children,
  dotColor,
  variant = 'filter', // filter | tab
  size = 'md',
  style = {},
}) => {
  const heights = { sm: 32, md: 40 };
  const px = size === 'sm' ? 12 : 14;
  const base = {
    height: heights[size],
    padding: `0 ${px}px`,
    display: 'inline-flex', alignItems: 'center', gap: 8,
    borderRadius: 'var(--bb-radius-full)',
    background: selected
      ? (variant === 'tab' ? 'var(--bb-surface)' : 'var(--bb-primary)')
      : 'var(--bb-surface)',
    color: selected
      ? (variant === 'tab' ? 'var(--bb-primary)' : 'var(--bb-text-on-primary)')
      : 'var(--bb-text-secondary)',
    border: `1px solid ${selected
      ? (variant === 'tab' ? 'var(--bb-primary)' : 'var(--bb-primary)')
      : 'var(--bb-border)'}`,
    fontSize: 13, fontWeight: selected ? 600 : 500,
    cursor: onClick ? 'pointer' : 'default',
    whiteSpace: 'nowrap',
    transition: 'all 120ms ease-out',
    boxShadow: selected && variant !== 'tab' ? 'var(--bb-shadow-purple-sm)' : 'none',
    ...style,
  };

  return (
    <button type="button" onClick={onClick} style={base}>
      {dotColor && <span style={{ width: 8, height: 8, borderRadius: '50%', background: dotColor }} />}
      {iconLeft && <Icon name={iconLeft} size={16} />}
      <span>{children}</span>
      {count != null && (
        <span style={{
          minWidth: 20, height: 20, padding: '0 6px',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          borderRadius: 999,
          background: selected ? 'rgba(255,255,255,0.22)' : (countColor || 'var(--bb-primary-tint-bg)'),
          color: selected ? '#FFFFFF' : (countColor ? '#FFFFFF' : 'var(--bb-primary)'),
          fontSize: 11, fontWeight: 700, fontVariantNumeric: 'tabular-nums',
        }}>{count}</span>
      )}
      {iconRight && <Icon name={iconRight} size={16} />}
    </button>
  );
};

// ──────────────────────────────────────────────────────────────
// BBStatusBadge — booking statuses
// ──────────────────────────────────────────────────────────────
const statusMap = {
  confirmed: { label: 'Potvrđeno',   bg: 'var(--bb-status-confirmed-bg)', fg: 'var(--bb-status-confirmed)', dot: '#2E7D5B' },
  pending:   { label: 'Na čekanju',  bg: 'var(--bb-status-pending-bg)',   fg: 'var(--bb-status-pending)',   dot: '#FFB84D' },
  cancelled: { label: 'Otkazano',    bg: 'var(--bb-status-cancelled-bg)', fg: 'var(--bb-status-cancelled)', dot: '#718096' },
  completed: { label: 'Završeno',    bg: 'var(--bb-status-completed-bg)', fg: 'var(--bb-status-completed)', dot: '#6B4CE6' },
  imported:  { label: 'Uvezeno',     bg: 'var(--bb-status-imported-bg)',  fg: 'var(--bb-status-imported)',  dot: '#4A90D9' },
};
const BBStatusBadge = ({ status = 'pending', label, dot = true, size = 'md', style = {} }) => {
  const s = statusMap[status] || statusMap.pending;
  const heights = { sm: 22, md: 26 };
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      height: heights[size], padding: '0 10px',
      borderRadius: 'var(--bb-radius-full)',
      background: s.bg, color: s.fg,
      fontSize: 12, fontWeight: 600, letterSpacing: '0.01em',
      ...style,
    }}>
      {dot && <span style={{ width: 6, height: 6, borderRadius: '50%', background: s.dot }} />}
      {label || s.label}
    </span>
  );
};

// ──────────────────────────────────────────────────────────────
// BBSkeleton — shimmering placeholder
// ──────────────────────────────────────────────────────────────
const BBSkeleton = ({ w = '100%', h = 16, radius = 8, style = {} }) => (
  <div style={{
    width: w, height: h, borderRadius: radius,
    background: 'linear-gradient(90deg, var(--bb-surface-variant) 0%, var(--bb-border-subtle) 50%, var(--bb-surface-variant) 100%)',
    backgroundSize: '200% 100%',
    animation: 'bb-shimmer 1.4s ease-in-out infinite',
    ...style,
  }} />
);

// ──────────────────────────────────────────────────────────────
// BBEmptyState — the iCal-import gold-standard pattern
// ──────────────────────────────────────────────────────────────
const BBEmptyState = ({
  icon = 'inbox',
  illustration, // optional ReactNode
  title,
  body,
  primary, // { label, onClick, iconLeft }
  secondary,
  benefits, // [{ icon, title, body }]
  compact = false,
  style = {},
}) => (
  <div style={{
    display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center',
    padding: compact ? 32 : 56, gap: 12, ...style,
  }}>
    {illustration || (
      <div style={{
        width: compact ? 72 : 96, height: compact ? 72 : 96,
        borderRadius: 24,
        background: 'var(--bb-primary-tint-bg)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        color: 'var(--bb-primary)',
        marginBottom: 8,
      }}>
        <Icon name={icon} size={compact ? 36 : 48} />
      </div>
    )}
    <h3 className="bb-h2" style={{ margin: 0, color: 'var(--bb-text-primary)', maxWidth: 480 }}>{title}</h3>
    {body && <p className="bb-body" style={{ margin: 0, color: 'var(--bb-text-secondary)', maxWidth: 460 }}>{body}</p>}
    {(primary || secondary) && (
      <div style={{ display: 'flex', gap: 12, marginTop: 12 }}>
        {primary && <BBButton iconLeft={primary.iconLeft} onClick={primary.onClick}>{primary.label}</BBButton>}
        {secondary && <BBButton variant="secondary" onClick={secondary.onClick}>{secondary.label}</BBButton>}
      </div>
    )}
    {benefits && (
      <div style={{
        display: 'grid', gridTemplateColumns: `repeat(${benefits.length}, 1fr)`,
        gap: 16, marginTop: 32, width: '100%', maxWidth: 720,
      }}>
        {benefits.map((b, i) => (
          <div key={i} style={{
            padding: 20, textAlign: 'left',
            background: 'var(--bb-surface-variant)', borderRadius: 'var(--bb-radius-md)',
          }}>
            <div style={{
              width: 40, height: 40, borderRadius: 12,
              background: 'var(--bb-surface)',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              color: 'var(--bb-primary)', marginBottom: 12,
            }}>
              <Icon name={b.icon} size={20} />
            </div>
            <div className="bb-label" style={{ marginBottom: 4, color: 'var(--bb-text-primary)' }}>{b.title}</div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-secondary)' }}>{b.body}</div>
          </div>
        ))}
      </div>
    )}
  </div>
);

// ──────────────────────────────────────────────────────────────
// BBSectionHeader — title + optional count + action link
// ──────────────────────────────────────────────────────────────
const BBSectionHeader = ({ title, count, action, level = 'h2', style = {} }) => {
  const Tag = level;
  return (
    <div style={{
      display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
      marginBottom: 16, ...style,
    }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
        <Tag className={`bb-${level}`} style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{title}</Tag>
        {count != null && <span className="bb-caption bb-tnum" style={{ color: 'var(--bb-text-tertiary)' }}>{count}</span>}
      </div>
      {action && (
        <button type="button" onClick={action.onClick} style={{
          border: 'none', background: 'transparent',
          color: 'var(--bb-primary)', fontWeight: 600, fontSize: 13,
          cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4,
        }}>{action.label} <Icon name="arrow_forward" size={16} /></button>
      )}
    </div>
  );
};

// ──────────────────────────────────────────────────────────────
// BBAppBar — slim 56px, surface bg
// ──────────────────────────────────────────────────────────────
// BBAppBar — slim 56px, surface bg, rounded-square action buttons
// ──────────────────────────────────────────────────────────────
const AppBarIconBtn = ({ icon, label, badge, badgeTone, onClick }) => (
  <button type="button" aria-label={label} onClick={onClick} className="bb-press" style={{
    position: 'relative', width: 40, height: 40, flexShrink: 0,
    border: '1px solid var(--bb-border-subtle)', borderRadius: 'var(--bb-radius-sm)',
    background: 'var(--bb-surface)', color: 'var(--bb-text-secondary)',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
    boxShadow: '0 1px 2px rgba(16,24,40,0.04)',
  }}>
    <Icon name={icon} size={20} />
    {badge != null && badge > 0 && (
      <span style={{
        position: 'absolute', top: -5, right: -5,
        minWidth: 18, height: 18, padding: '0 5px',
        background: badgeTone === 'tertiary' ? 'var(--bb-tertiary)' : 'var(--bb-error)', color: '#FFFFFF',
        borderRadius: 999, fontSize: 10, fontWeight: 700,
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        border: '2px solid var(--bb-surface)', fontVariantNumeric: 'tabular-nums',
      }}>{badge}</span>
    )}
  </button>
);

const BBAppBar = ({ title, breadcrumb, showHamburger = false, showBack = false, actions = [], notifCount, onHamburger, style = {} }) => (
  <header style={{
    height: 56, flexShrink: 0,
    background: 'var(--bb-surface)',
    borderBottom: '1px solid var(--bb-border-subtle)',
    display: 'flex', alignItems: 'center', gap: 12,
    padding: '0 20px',
    ...style,
  }}>
    {showHamburger && (
      <BBButton variant="tertiary" asIcon size="md" iconLeft="menu" onClick={onHamburger} ariaLabel="Otvori izbornik" />
    )}
    {showBack && (
      <BBButton variant="tertiary" asIcon size="md" iconLeft="arrow_back" ariaLabel="Natrag" />
    )}
    {breadcrumb ? (
      <nav aria-label="Putanja" style={{ flex: 1, minWidth: 0, display: 'flex', alignItems: 'center', gap: 5 }}>
        {breadcrumb.map((seg, i) => (
          <React.Fragment key={i}>
            {i > 0 && <Icon name="chevron_right" size={16} style={{ color: 'var(--bb-text-disabled)' }} />}
            <span style={{
              fontFamily: 'var(--bb-font-sans)', fontSize: 13.5,
              fontWeight: i === breadcrumb.length - 1 ? 600 : 500,
              color: i === breadcrumb.length - 1 ? 'var(--bb-text-primary)' : 'var(--bb-text-tertiary)',
              whiteSpace: 'nowrap',
            }}>{seg}</span>
          </React.Fragment>
        ))}
      </nav>
    ) : (
      <h1 className="bb-h2" style={{ margin: 0, flex: 1, color: 'var(--bb-text-primary)' }}>{title}</h1>
    )}
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      {actions.map((a, i) => (
        <AppBarIconBtn key={i} icon={a.icon} label={a.label} onClick={a.onClick} />
      ))}
      <AppBarIconBtn icon="notifications" label={notifCount ? `${notifCount} obavijesti` : 'Obavijesti'} badge={notifCount} />
    </div>
  </header>
);

// ──────────────────────────────────────────────────────────────
// BBSidebar — permanent left rail (desktop)
// ──────────────────────────────────────────────────────────────
const NavGroupLabel = ({ children }) => (
  <div style={{
    padding: '15px 12px 7px', fontSize: 10.5, fontWeight: 700,
    letterSpacing: '0.09em', textTransform: 'uppercase', color: 'var(--bb-text-tertiary)',
  }}>{children}</div>
);

const BBSidebar = ({ user = {}, active = 'pregled', pendingCount = 0, notifCount = 0, onNavigate, style = {} }) => {
  const groups = [
    { label: 'Glavno', items: [
      { id: 'pregled', icon: 'dashboard', label: 'Pregled' },
      { id: 'kalendar', icon: 'event', label: 'Kalendar', expandable: true, children: [
        { id: 'kalendar-timeline', label: 'Timeline' },
        { id: 'kalendar-mjesecni', label: 'Mjesečni' },
      ]},
      { id: 'rezervacije', icon: 'receipt_long', label: 'Rezervacije', badge: pendingCount },
    ]},
    { label: 'Upravljanje', items: [
      { id: 'jedinice', icon: 'apartment', label: 'Smještajne Jedinice' },
      { id: 'ai-asistent', icon: 'smart_toy', label: 'AI Asistent' },
      { id: 'integracije', icon: 'extension', label: 'Integracije', expandable: true, children: [
        { id: 'ical', label: 'iCal' },
        { id: 'widget', label: 'Widget' },
      ]},
    ]},
    { label: 'Pomoć', items: [
      { id: 'faq', icon: 'help', label: 'FAQ' },
      { id: 'obavjestenja', icon: 'notifications', label: 'Obavještenja', badgeTone: 'tertiary', badge: notifCount },
    ]},
  ];

  return (
    <aside style={{
      width: 260, flexShrink: 0,
      background: 'var(--bb-surface)',
      borderRight: '1px solid var(--bb-border-subtle)',
      display: 'flex', flexDirection: 'column',
      ...style,
    }}>
      {/* Brand */}
      <div style={{ padding: '18px 16px 12px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <Logo size={30} />
        <span className="bb-h3" style={{ color: 'var(--bb-text-primary)', flex: 1, letterSpacing: '-0.01em' }}>BookBed</span>
        <button type="button" aria-label="Skupi izbornik" style={{
          width: 28, height: 28, flexShrink: 0,
          border: '1px solid var(--bb-border-subtle)', borderRadius: 8,
          background: 'transparent', color: 'var(--bb-text-tertiary)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
        }}>
          <Icon name="chevron_left" size={18} />
        </button>
      </div>

      {/* Search */}
      <div style={{ padding: '2px 14px 8px' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 9, height: 42, padding: '0 8px 0 13px',
          borderRadius: 12, background: 'var(--bb-surface)',
          border: '1px solid var(--bb-border-subtle)', boxShadow: '0 1px 2px rgba(16,24,40,0.04)', cursor: 'text',
        }}>
          <Icon name="search" size={18} style={{ color: 'var(--bb-text-tertiary)' }} />
          <span style={{ flex: 1, fontSize: 13, color: 'var(--bb-text-tertiary)', fontFamily: 'var(--bb-font-sans)' }}>Pretraži…</span>
          <kbd style={{
            display: 'inline-flex', alignItems: 'center', lineHeight: 1,
            fontFamily: 'var(--bb-font-sans)', fontSize: 11, fontWeight: 700, color: 'var(--bb-text-tertiary)',
            background: 'var(--bb-surface-variant)', border: '1px solid var(--bb-border-subtle)', borderRadius: 6, padding: '3px 6px',
          }}>⌘K</kbd>
        </div>
      </div>

      {/* Nav */}
      <nav style={{ flex: 1, padding: '2px 10px 8px', display: 'flex', flexDirection: 'column', gap: 2, overflowY: 'auto' }}>
        {groups.map((g, gi) => (
          <div key={gi}>
            <NavGroupLabel>{g.label}</NavGroupLabel>
            {g.items.map(it => (
              <div key={it.id}>
                <SidebarItem item={it} active={active} onNavigate={onNavigate} />
                {it.expandable && it.children && active.startsWith(it.id) && (
                  <div style={{ borderLeft: '1.5px solid var(--bb-border-subtle)', marginLeft: 24, paddingLeft: 8, marginTop: 2, marginBottom: 2, display: 'flex', flexDirection: 'column', gap: 2 }}>
                    {it.children.map(c => (
                      <SidebarSubItem key={c.id} item={c} active={active} onNavigate={onNavigate} />
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        ))}
      </nav>

      {/* User profile (bottom) */}
      <div style={{ padding: 10, borderTop: '1px solid var(--bb-border-subtle)' }}>
        <div className={active === 'profil' ? '' : 'bb-nav-item'} onClick={() => onNavigate?.('profil')} style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: 8, borderRadius: 12, cursor: 'pointer', minWidth: 0,
          border: '1px solid', borderColor: active === 'profil' ? 'var(--bb-border-subtle)' : 'transparent',
          background: active === 'profil' ? 'var(--bb-surface)' : 'transparent',
          boxShadow: active === 'profil' ? '0 1px 2px rgba(16,24,40,0.05), 0 6px 16px -6px rgba(33,24,71,0.16)' : 'none',
        }}>
          <BBAvatar name={user.name || 'Korisnik'} size="md" tone="primary" />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div className="bb-label" style={{ color: 'var(--bb-text-primary)', fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{user.name || 'Korisnik'}</div>
            <div className="bb-caption" style={{ color: 'var(--bb-text-tertiary)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{user.email || ''}</div>
          </div>
          <Icon name="unfold_more" size={18} style={{ color: 'var(--bb-text-tertiary)', flexShrink: 0 }} />
        </div>
      </div>
    </aside>
  );
};

function navItemStyle({ active, danger = false }) {
  return {
    display: 'flex', alignItems: 'center', gap: 12,
    width: '100%',
    height: 44,
    padding: '0 12px',
    border: 'none',
    borderRadius: 'var(--bb-radius-sm)',
    background: active ? 'var(--bb-primary-tint-bg)' : 'transparent',
    color: danger ? 'var(--bb-error)' : (active ? 'var(--bb-primary)' : 'var(--bb-text-secondary)'),
    fontFamily: 'var(--bb-font-sans)',
    fontSize: 14, fontWeight: active ? 600 : 500,
    cursor: 'pointer', textAlign: 'left',
    transition: 'background 100ms ease-out, color 100ms ease-out',
  };
}

const SidebarItem = ({ item, active, onNavigate }) => {
  const isActive = active === item.id || (item.expandable && active.startsWith(item.id));
  return (
    <button type="button" onClick={() => onNavigate?.(item.id)} className={isActive ? '' : 'bb-nav-item'} style={{
      display: 'flex', alignItems: 'center', gap: 11, width: '100%', height: 44, padding: '0 10px',
      border: '1px solid', borderColor: isActive ? 'var(--bb-border-subtle)' : 'transparent',
      borderRadius: 12,
      background: isActive ? 'var(--bb-surface)' : 'transparent',
      boxShadow: isActive ? '0 1px 2px rgba(16,24,40,0.05), 0 6px 16px -6px rgba(33,24,71,0.16)' : 'none',
      color: isActive ? 'var(--bb-text-primary)' : 'var(--bb-text-secondary)',
      fontFamily: 'var(--bb-font-sans)', fontSize: 14, fontWeight: isActive ? 600 : 500,
      cursor: 'pointer', textAlign: 'left',
    }}>
      <span style={{
        width: 28, height: 28, flexShrink: 0, borderRadius: 9,
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        background: isActive ? 'var(--bb-gradient-hero)' : 'var(--bb-surface-variant)',
        color: isActive ? '#FFFFFF' : 'var(--bb-text-tertiary)',
        boxShadow: isActive ? 'var(--bb-shadow-purple-sm)' : 'none',
        border: isActive ? 'none' : '1px solid var(--bb-border-subtle)',
        transition: 'background 140ms ease, color 140ms ease',
      }}>
        <Icon name={item.icon} size={18} fill={isActive ? 1 : 0} />
      </span>
      <span style={{ flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{item.label}</span>
      {item.badge != null && item.badge > 0 && (
        <span style={{
          minWidth: 22, height: 22, padding: '0 7px',
          borderRadius: 999,
          background: item.badgeTone === 'tertiary' ? 'var(--bb-tertiary)' : 'var(--bb-error)',
          color: '#FFFFFF',
          fontSize: 11, fontWeight: 700,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          fontVariantNumeric: 'tabular-nums',
        }}>{item.badge}</span>
      )}
      {item.expandable && <Icon name="expand_more" size={18} style={{ color: 'var(--bb-text-tertiary)', transform: isActive ? 'rotate(180deg)' : 'none', transition: 'transform 160ms ease-out' }} />}
    </button>
  );
};

const SidebarSubItem = ({ item, active, onNavigate }) => {
  const isActive = active === item.id;
  return (
    <button type="button" onClick={() => onNavigate?.(item.id)} className={isActive ? '' : 'bb-nav-item'} style={{
      display: 'flex', alignItems: 'center', gap: 10, width: '100%', height: 36, padding: '0 10px',
      border: 'none', borderRadius: 10,
      background: isActive ? 'var(--bb-primary-tint-bg)' : 'transparent',
      color: isActive ? 'var(--bb-primary)' : 'var(--bb-text-secondary)',
      fontFamily: 'var(--bb-font-sans)', fontSize: 13, fontWeight: isActive ? 600 : 500,
      cursor: 'pointer', textAlign: 'left',
    }}>
      <span style={{
        width: 6, height: 6, borderRadius: '50%', flexShrink: 0,
        background: isActive ? 'var(--bb-primary)' : 'var(--bb-text-disabled)',
      }} />
      <span style={{ flex: 1 }}>{item.label}</span>
    </button>
  );
};

// ──────────────────────────────────────────────────────────────
// BBSparkline — SVG sparkline w/ fill area
// ──────────────────────────────────────────────────────────────
const BBSparkline = ({ data = [], width = 280, height = 64, color = 'var(--bb-primary)', fillColor = 'rgba(107,76,230,0.16)', showDot = true, strokeWidth = 2 }) => {
  if (!data.length) return null;
  const min = Math.min(...data);
  const max = Math.max(...data);
  const range = max - min || 1;
  const pad = 6;
  const innerW = width - pad * 2;
  const innerH = height - pad * 2;
  const points = data.map((v, i) => {
    const x = pad + (i / (data.length - 1)) * innerW;
    const y = pad + (1 - (v - min) / range) * innerH;
    return [x, y];
  });
  const pathD = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p[0].toFixed(1)} ${p[1].toFixed(1)}`).join(' ');
  const areaD = `${pathD} L ${points[points.length - 1][0].toFixed(1)} ${height - pad} L ${points[0][0].toFixed(1)} ${height - pad} Z`;
  const last = points[points.length - 1];

  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} style={{ display: 'block' }}>
      <path d={areaD} fill={fillColor} />
      <path d={pathD} fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" />
      {showDot && <circle cx={last[0]} cy={last[1]} r="4" fill={color} stroke="var(--bb-surface)" strokeWidth="2" />}
    </svg>
  );
};

// ──────────────────────────────────────────────────────────────
// BBBottomSheet / BBDialog — visual shells for gallery
// ──────────────────────────────────────────────────────────────
const BBBottomSheet = ({ title, children, footer, style = {} }) => (
  <div style={{
    width: 360,
    background: 'var(--bb-surface)',
    borderRadius: 'var(--bb-radius-lg) var(--bb-radius-lg) 0 0',
    boxShadow: 'var(--bb-shadow-lg)',
    overflow: 'hidden',
    ...style,
  }}>
    <div style={{ display: 'flex', justifyContent: 'center', padding: '10px 0 0' }}>
      <span style={{ width: 36, height: 4, borderRadius: 999, background: 'var(--bb-border)' }} />
    </div>
    {title && <div style={{ padding: '12px 20px 8px' }}>
      <h3 className="bb-h3" style={{ margin: 0, color: 'var(--bb-text-primary)' }}>{title}</h3>
    </div>}
    <div style={{ padding: '8px 4px 16px' }}>{children}</div>
    {footer && <div style={{ padding: '12px 20px', borderTop: '1px solid var(--bb-border-subtle)' }}>{footer}</div>}
  </div>
);

const BBDialog = ({ title, body, primary, secondary, destructive = false, width = 420, style = {} }) => (
  <div style={{
    width,
    background: 'var(--bb-surface)',
    borderRadius: 'var(--bb-radius-lg)',
    boxShadow: 'var(--bb-shadow-lg)',
    padding: 24,
    ...style,
  }}>
    <h3 className="bb-h2" style={{ margin: '0 0 8px', color: 'var(--bb-text-primary)' }}>{title}</h3>
    <p className="bb-body" style={{ margin: '0 0 20px', color: 'var(--bb-text-secondary)' }}>{body}</p>
    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
      {secondary && <BBButton variant="tertiary" onClick={secondary.onClick}>{secondary.label}</BBButton>}
      {primary && <BBButton variant={destructive ? 'destructive' : 'primary'} onClick={primary.onClick}>{primary.label}</BBButton>}
    </div>
  </div>
);

// ──────────────────────────────────────────────────────────────
// BBSidebarRail — collapsible icon-only rail (tablet)
// ──────────────────────────────────────────────────────────────
const BBSidebarRail = ({ active = 'pregled', pendingCount = 0, notifCount = 0, onNavigate, style = {} }) => {
  const items = [
    { id: 'pregled', icon: 'dashboard', label: 'Pregled' },
    { id: 'kalendar-timeline', icon: 'event', label: 'Kalendar', group: 'kalendar' },
    { id: 'rezervacije', icon: 'receipt_long', label: 'Rezervacije', badge: pendingCount },
    { id: 'ai-asistent', icon: 'smart_toy', label: 'AI Asistent' },
    { id: 'jedinice', icon: 'apartment', label: 'Jedinice' },
    { id: 'ical', icon: 'extension', label: 'Integracije', group: 'integracije' },
    { id: 'faq', icon: 'help', label: 'FAQ' },
    { id: 'obavjestenja', icon: 'notifications', label: 'Obavještenja', badgeTone: 'tertiary', badge: notifCount },
    { id: 'profil', icon: 'person', label: 'Profil' },
  ];

  return (
    <aside style={{
      width: 72, flexShrink: 0,
      background: 'var(--bb-surface)',
      borderRight: '1px solid var(--bb-border-subtle)',
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      padding: '16px 0',
      gap: 8,
      ...style,
    }}>
      <div style={{ marginBottom: 6 }}><Logo size={36} /></div>
      <div style={{ width: 32, height: 1, background: 'var(--bb-border-subtle)', marginBottom: 6 }} />

      <nav style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center', flex: 1 }}>
        {items.map(it => {
          const isActive = active === it.id || (it.group && active.startsWith(it.group));
          return (
            <button key={it.id} type="button" aria-label={it.label}
              onClick={() => onNavigate?.(it.id)}
              style={{
                position: 'relative',
                width: 48, height: 48,
                border: 'none', borderRadius: 'var(--bb-radius-sm)',
                background: isActive ? 'var(--bb-primary-tint-bg)' : 'transparent',
                color: isActive ? 'var(--bb-primary)' : 'var(--bb-text-secondary)',
                cursor: 'pointer',
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              }}>
              <Icon name={it.icon} size={22} fill={isActive ? 1 : 0} />
              {it.badge != null && it.badge > 0 && (
                <span style={{
                  position: 'absolute', top: 6, right: 6,
                  minWidth: 16, height: 16, padding: '0 4px',
                  borderRadius: 999,
                  background: it.badgeTone === 'tertiary' ? 'var(--bb-tertiary)' : 'var(--bb-error)',
                  color: '#FFFFFF',
                  fontSize: 10, fontWeight: 700,
                  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                  border: '2px solid var(--bb-surface)',
                  fontVariantNumeric: 'tabular-nums',
                }}>{it.badge}</span>
              )}
            </button>
          );
        })}
      </nav>

      <button type="button" aria-label="Odjava" style={{
        width: 48, height: 48,
        border: 'none', borderRadius: 'var(--bb-radius-sm)',
        background: 'transparent', color: 'var(--bb-error)',
        cursor: 'pointer',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name="logout" size={20} />
      </button>
    </aside>
  );
};

// Expose globally
Object.assign(window, {
  BBIcon: Icon,
  BBLogo: Logo,
  BBAvatar,
  BBAvatarSlot,
  BBButton,
  BBInput,
  BBCard,
  BBChip,
  BBStatusBadge,
  BBSkeleton,
  BBEmptyState,
  BBSectionHeader,
  BBAppBar,
  BBSidebar,
  BBSidebarRail,
  BBSparkline,
  BBBottomSheet,
  BBDialog,
  BBSpinner: Spinner,
});
