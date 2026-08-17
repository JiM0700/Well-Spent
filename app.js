// ═══════════════════════════════════════════════════════════════════════════
// WELL SPENT — Material 3 Expressive PWA Orchestrator
// Features: Dynamic SVG Radial Gauge, Interactive Trajectory Sparkline, M3 Motion
// ═══════════════════════════════════════════════════════════════════════════

const STORAGE_KEY          = 'well_spent_expenses_v1';
const BUDGET_KEY           = 'well_spent_budget_v1';
const CYCLE_START_DAY_KEY  = 'well_spent_cycle_start_day_v1';
const BASE_INCOME_KEY      = 'well_spent_base_income_v1';
const VIEW_MODE_KEY        = 'well_spent_view_mode_v1';
const TAB_KEY              = 'well_spent_current_tab_v1';
const CATEGORY_BUDGETS_KEY = 'well_spent_category_budgets_v1';
const RECURRING_BILLS_KEY  = 'well_spent_recurring_bills_v1';
const THEME_KEY            = 'well_spent_theme_v1';
const PALETTE_KEY          = 'well_spent_palette_v1';

const CATEGORIES = {
  food:          { name: 'Food & Dining',      icon: '🍽️', color: '#ff9800' },
  transport:     { name: 'Transport',          icon: '🚗', color: '#29b6f6' },
  bills:         { name: 'Bills & Utilities',  icon: '⚡', color: '#ab47bc' },
  shopping:      { name: 'Shopping',           icon: '🛍️', color: '#ec407a' },
  healthcare:    { name: 'Healthcare',         icon: '🏥', color: '#66bb6a' },
  entertainment: { name: 'Entertainment',      icon: '🎬', color: '#ef5350' },
  invest:        { name: 'Investments',        icon: '💰', color: '#ffa726' },
  other:         { name: 'Other',              icon: '🌐', color: '#78909c' },
};

// ── State Store ───────────────────────────────────────────────────────────
let expenses         = loadJSON(STORAGE_KEY, []);
let monthlyBudget    = Number(localStorage.getItem(BUDGET_KEY))          || 25000;
let cycleStartDay    = Number(localStorage.getItem(CYCLE_START_DAY_KEY)) || 1;
let baseIncome       = Number(localStorage.getItem(BASE_INCOME_KEY))     || 50000;
let currentViewMode  = localStorage.getItem(VIEW_MODE_KEY)               || 'monthwise';
let currentTab       = localStorage.getItem(TAB_KEY)                     || 'overview';
let categoryBudgets  = loadCategoryBudgets();
let recurringBills   = loadRecurringBills();
let currentTheme     = localStorage.getItem(THEME_KEY)                   || 'dark';
let currentPalette   = localStorage.getItem(PALETTE_KEY)                 || 'blue';

let activeCategoryFilter = 'all';
let searchQuery          = '';
let selectedCategoryModal = 'food';
let editingCategoryKey   = null;

// Seed initial sample data if empty
if (expenses.length === 0) seedSampleData();

// ── Core Helpers ──────────────────────────────────────────────────────────
function loadJSON(key, fallback) {
  try {
    const val = JSON.parse(localStorage.getItem(key));
    return val !== null && val !== undefined ? val : fallback;
  } catch {
    return fallback;
  }
}

function saveExpenses()        { localStorage.setItem(STORAGE_KEY, JSON.stringify(expenses)); }
function saveCategoryBudgets() { localStorage.setItem(CATEGORY_BUDGETS_KEY, JSON.stringify(categoryBudgets)); }
function saveRecurringBills()  { localStorage.setItem(RECURRING_BILLS_KEY, JSON.stringify(recurringBills)); }

function inr(n) {
  return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: 2 }).format(n || 0);
}
function inrCompact(n) {
  return '₹' + Math.round(n || 0).toLocaleString('en-IN');
}
function formatDate(d) {
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
}
function escapeHtml(v) {
  return String(v || '').replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[c]));
}
function triggerHaptic() {
  if (navigator.vibrate) {
    try { navigator.vibrate(14); } catch {}
  }
}

function loadCategoryBudgets() {
  const defaults = {
    food: 8000, transport: 4000, bills: 6000, shopping: 4000,
    healthcare: 2000, entertainment: 2000, invest: 5000, other: 2000
  };
  const stored = loadJSON(CATEGORY_BUDGETS_KEY, {});
  return Object.assign(defaults, stored);
}

function loadRecurringBills() {
  const stored = loadJSON(RECURRING_BILLS_KEY, null);
  if (Array.isArray(stored) && stored.length > 0) return stored;
  return [
    { id: 1, title: 'iCloud Storage', amount: 299, dueDay: 5, isPaid: true },
    { id: 2, title: 'YouTube Premium', amount: 199, dueDay: 12, isPaid: false },
    { id: 3, title: 'Fiber Broadband', amount: 999, dueDay: 20, isPaid: false },
    { id: 4, title: 'Gym Membership', amount: 2500, dueDay: 1, isPaid: true }
  ];
}

function seedSampleData() {
  const now = new Date();
  const y = now.getFullYear(), m = now.getMonth(), d = now.getDate();
  expenses = [
    { id: Date.now() - 4000, title: 'Specialty Cold Brew & Bagel', amount: 380, category: 'food', date: new Date(y, m, d, 9, 30).toISOString(), notes: 'Morning coffee' },
    { id: Date.now() - 3000, title: 'Organic Supermarket Basket', amount: 1450, category: 'food', date: new Date(y, m, d, 14, 15).toISOString(), notes: 'Groceries' },
    { id: Date.now() - 2000, title: 'Metro Transit SmartCard', amount: 500, category: 'transport', date: new Date(y, m, d - 1, 18, 0).toISOString(), notes: 'Monthly pass' },
    { id: Date.now() - 1000, title: 'High-speed Fiber Net', amount: 1199, category: 'bills', date: new Date(y, m, d - 3, 11, 0).toISOString(), notes: 'Broadband' }
  ];
  saveExpenses();
}

// ── Metrics Calculation & Trajectory Generation ───────────────────────────
function calculateMetrics() {
  const now = new Date();
  const y = now.getFullYear(), mo = now.getMonth(), d = now.getDate();

  let startYear = y, startMonth = mo;
  if (d < cycleStartDay) {
    startMonth--;
    if (startMonth < 0) { startMonth = 11; startYear--; }
  }
  const cycleStart = new Date(startYear, startMonth, cycleStartDay, 0, 0, 0, 0);

  let endYear = startYear, endMonth = startMonth + 1;
  if (endMonth > 11) { endMonth = 0; endYear++; }
  const cycleEnd = new Date(endYear, endMonth, cycleStartDay, 0, 0, 0, 0);

  // Monthwise cycle expenses
  const monthExpenses = expenses.filter(e => {
    const ed = new Date(e.date);
    return ed >= cycleStart && ed < cycleEnd;
  });
  const monthTotal = monthExpenses.reduce((sum, e) => sum + e.amount, 0);

  // Daywise expenses (Today)
  const todayStart = new Date(y, mo, d, 0, 0, 0, 0);
  const todayEnd   = new Date(y, mo, d, 23, 59, 59, 999);
  const todayExpenses = expenses.filter(e => {
    const ed = new Date(e.date);
    return ed >= todayStart && ed <= todayEnd;
  });
  const todayTotal = todayExpenses.reduce((sum, e) => sum + e.amount, 0);

  // Cycle pacing & forecasting
  const totalDays = Math.max(1, Math.round((cycleEnd - cycleStart) / 86400000));
  const daysElapsed = Math.max(1, Math.min(totalDays, Math.ceil((now - cycleStart) / 86400000)));
  const daysRemaining = Math.max(0, totalDays - daysElapsed);

  const dailyBudget = monthlyBudget / totalDays;
  const dailyBurn = monthTotal / daysElapsed;
  const projectedMonthEnd = monthTotal + (dailyBurn * daysRemaining);
  const remainingToday = Math.max(0, dailyBudget - todayTotal);

  // Cumulative Trajectory Data per Day for the Sparkline
  const trajectoryDays = [];
  let runningCumulative = 0;

  for (let dayIndex = 1; dayIndex <= totalDays; dayIndex++) {
    const dayDate = new Date(startYear, startMonth, cycleStartDay + (dayIndex - 1), 0, 0, 0, 0);
    const dayEndDate = new Date(startYear, startMonth, cycleStartDay + (dayIndex - 1), 23, 59, 59, 999);

    const isPastOrToday = dayIndex <= daysElapsed;
    if (isPastOrToday) {
      const daySpend = expenses
        .filter(e => {
          const ed = new Date(e.date);
          return ed >= dayDate && ed <= dayEndDate;
        })
        .reduce((sum, e) => sum + e.amount, 0);

      runningCumulative += daySpend;
    }

    trajectoryDays.push({
      dayIndex,
      dateStr: dayDate.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }),
      cumulativeSpend: isPastOrToday ? runningCumulative : null,
      idealPace: dailyBudget * dayIndex
    });
  }

  return {
    monthTotal,
    todayTotal,
    dailyBudget,
    dailyBurn,
    projectedMonthEnd,
    remainingToday,
    daysElapsed,
    daysRemaining,
    totalDays,
    monthExpenses,
    todayExpenses,
    cycleStartDay,
    trajectoryDays
  };
}

// ── Master Render Pipeline ────────────────────────────────────────────────
function render() {
  applyThemeAndPalette();
  syncNav();

  const metrics = calculateMetrics();

  renderRail(metrics);
  renderTopBar(metrics);
  renderOverview(metrics);
  renderBudgets(metrics);
  renderTrends(metrics);
  renderSettings();
}

function applyThemeAndPalette() {
  let theme = currentTheme;
  if (theme === 'system') {
    theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  document.body.setAttribute('data-theme', theme);
  document.body.setAttribute('data-palette', currentPalette);

  const metaTheme = document.getElementById('metaThemeColor');
  if (metaTheme) {
    metaTheme.setAttribute('content', theme === 'dark' ? '#0d0f14' : '#f8f9fa');
  }

  const themeSelect = document.getElementById('themeSelect');
  if (themeSelect) themeSelect.value = currentTheme;

  document.querySelectorAll('.m3-palette-circle').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.pal === currentPalette);
  });
}

function syncNav() {
  document.querySelectorAll('.m3-rail-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === currentTab);
  });

  document.querySelectorAll('.m3-bnav-item').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === currentTab);
  });

  document.querySelectorAll('.m3-tab-pane').forEach(pane => {
    pane.classList.remove('active');
  });

  const tabMap = {
    overview: 'tabOverview',
    categories: 'tabCategories',
    insights: 'tabInsights',
    settings: 'tabSettings'
  };

  const activePane = document.getElementById(tabMap[currentTab] || 'tabOverview');
  if (activePane) activePane.classList.add('active');

  const titles = {
    overview: 'Overview',
    categories: 'Budgets',
    insights: 'Trends',
    settings: 'Settings'
  };
  const titleEl = document.getElementById('pageHeadingTitle');
  if (titleEl) titleEl.textContent = titles[currentTab] || 'Overview';
}

function renderTopBar(metrics) {
  const cycleText = document.getElementById('topBarCycleText');
  if (cycleText) cycleText.textContent = `Cycle Day ${metrics.daysElapsed} of ${metrics.totalDays}`;
}

function renderRail(metrics) {
  const pct = monthlyBudget > 0 ? Math.min(100, Math.round((metrics.monthTotal / monthlyBudget) * 100)) : 0;
  const gaugePct = document.getElementById('railGaugePct');
  if (gaugePct) gaugePct.textContent = `${pct}%`;

  const gaugeFill = document.getElementById('railGaugeFill');
  if (gaugeFill) {
    gaugeFill.style.width = `${pct}%`;
    gaugeFill.classList.toggle('warning', pct >= 100);
  }

  const spentMeta = document.getElementById('railSpentMeta');
  if (spentMeta) spentMeta.textContent = `${inrCompact(metrics.monthTotal)} spent`;

  const leftMeta = document.getElementById('railLeftMeta');
  if (leftMeta) leftMeta.textContent = `${inrCompact(Math.max(0, monthlyBudget - metrics.monthTotal))} left`;
}

// ── Tab 1: Overview & Radial Gauge & Trajectory Sparkline ──────────────────
function renderOverview(metrics) {
  const isDaywise = currentViewMode === 'daywise';

  // Segmented Switcher Active State
  const switcher = document.getElementById('viewModeSwitcher');
  if (switcher) switcher.classList.toggle('daywise-active', isDaywise);

  document.querySelectorAll('#viewModeSwitcher .m3-segment-btn').forEach(btn => {
    const active = btn.dataset.mode === currentViewMode;
    btn.classList.toggle('active', active);
    btn.setAttribute('aria-checked', String(active));
  });

  const total = isDaywise ? metrics.todayTotal : metrics.monthTotal;
  const budget = isDaywise ? metrics.dailyBudget : monthlyBudget;
  const remaining = isDaywise ? metrics.remainingToday : Math.max(0, monthlyBudget - metrics.monthTotal);
  const isOver = budget > 0 && total > budget;
  const pct = budget > 0 ? Math.min(100, Math.round((total / budget) * 100)) : 0;

  // 🌟 1. UPDATE RADIAL GAUGE RING 🌟
  const circumference = 515.22; // 2 * PI * 82
  const offset = circumference * (1 - pct / 100);
  const radialCircle = document.getElementById('radialGaugeCircle');
  if (radialCircle) {
    radialCircle.style.strokeDasharray = `${circumference}`;
    radialCircle.style.strokeDashoffset = `${offset}`;
    radialCircle.classList.toggle('warning', isOver);
  }

  const pctPill = document.getElementById('pulsePctPill');
  if (pctPill) {
    pctPill.textContent = `${pct}% Used`;
    pctPill.classList.toggle('warning', isOver);
  }

  const eyebrowBadge = document.getElementById('pulseEyebrowBadge');
  if (eyebrowBadge) eyebrowBadge.textContent = isDaywise ? "TODAY'S SPENDING" : "MONTHLY ENVELOPE";

  const amountDisplay = document.getElementById('pulseAmountDisplay');
  if (amountDisplay) amountDisplay.textContent = inr(total);

  const subDisplay = document.getElementById('pulseSubDisplay');
  if (subDisplay) {
    subDisplay.textContent = `of ${inrCompact(budget)} ${isDaywise ? 'daily allowance' : 'monthly allowance'}`;
  }

  const statusPill = document.getElementById('pulseStatusPill');
  if (statusPill) {
    statusPill.textContent = isOver ? 'Over Budget' : 'On Track';
    statusPill.classList.toggle('warning', isOver);
  }

  const remainingDisplay = document.getElementById('pulseRemainingDisplay');
  if (remainingDisplay) remainingDisplay.textContent = inrCompact(remaining);

  const burnDisplay = document.getElementById('pulseBurnDisplay');
  if (burnDisplay) burnDisplay.textContent = `${inrCompact(metrics.dailyBurn)}/day`;

  const monthEndDisplay = document.getElementById('pulseMonthEndDisplay');
  if (monthEndDisplay) monthEndDisplay.textContent = inrCompact(metrics.projectedMonthEnd);

  // 📈 2. RENDER INTERACTIVE SPENDING TRAJECTORY SPARKLINE 📈
  renderTrajectorySparkline(metrics);

  // Activity Feed
  let list = isDaywise ? metrics.todayExpenses : metrics.monthExpenses;

  if (activeCategoryFilter !== 'all') {
    list = list.filter(e => e.category === activeCategoryFilter);
  }

  if (searchQuery.trim()) {
    const q = searchQuery.toLowerCase().trim();
    list = list.filter(e =>
      e.title.toLowerCase().includes(q) ||
      (e.notes && e.notes.toLowerCase().includes(q)) ||
      (CATEGORIES[e.category] && CATEGORIES[e.category].name.toLowerCase().includes(q))
    );
  }

  const feedHeading = document.getElementById('activityFeedHeading');
  if (feedHeading) feedHeading.textContent = isDaywise ? "Today's Activity" : "Monthly Transactions";

  const feedSubheading = document.getElementById('activityFeedSubheading');
  if (feedSubheading) {
    feedSubheading.textContent = `${list.length} ${list.length === 1 ? 'entry' : 'entries'}`;
  }

  renderTransactionList(list);
}

// ── Interactive SVG Sparkline Engine ──────────────────────────────────────
function renderTrajectorySparkline(metrics) {
  const width = 380;
  const height = 120;
  const paddingX = 14;
  const paddingTop = 14;
  const paddingBottom = 16;
  const plotWidth = width - (paddingX * 2);
  const plotHeight = height - paddingTop - paddingBottom;

  const totalDays = metrics.totalDays || 30;
  const maxVal = Math.max(monthlyBudget * 1.15, metrics.monthTotal * 1.1, 1000);

  // Target Budget Line (Ideal linear pace)
  const targetLine = document.getElementById('sparklineTargetLine');
  if (targetLine) {
    const startY = height - paddingBottom;
    const endY = paddingTop + (1 - (monthlyBudget / maxVal)) * plotHeight;
    targetLine.setAttribute('x1', `${paddingX}`);
    targetLine.setAttribute('y1', `${startY}`);
    targetLine.setAttribute('x2', `${width - paddingX}`);
    targetLine.setAttribute('y2', `${endY}`);
  }

  // Actual Spend Spline Path
  const validPoints = metrics.trajectoryDays.filter(d => d.cumulativeSpend !== null);
  if (validPoints.length === 0) return;

  const getCoordinates = (pt) => {
    const x = paddingX + ((pt.dayIndex - 1) / (totalDays - 1)) * plotWidth;
    const y = paddingTop + (1 - (pt.cumulativeSpend / maxVal)) * plotHeight;
    return { x, y };
  };

  const coords = validPoints.map(getCoordinates);

  // Build SVG Path Spline
  let pathD = `M ${coords[0].x} ${coords[0].y}`;
  for (let i = 1; i < coords.length; i++) {
    const prev = coords[i - 1];
    const curr = coords[i];
    const cpX1 = prev.x + (curr.x - prev.x) / 2;
    const cpY1 = prev.y;
    const cpX2 = prev.x + (curr.x - prev.x) / 2;
    const cpY2 = curr.y;
    pathD += ` C ${cpX1} ${cpY1}, ${cpX2} ${cpY2}, ${curr.x} ${curr.y}`;
  }

  const linePath = document.getElementById('sparklineLinePath');
  if (linePath) linePath.setAttribute('d', pathD);

  // Shaded Area Path
  const lastCoord = coords[coords.length - 1];
  const areaD = `${pathD} L ${lastCoord.x} ${height - paddingBottom} L ${coords[0].x} ${height - paddingBottom} Z`;
  const areaPath = document.getElementById('sparklineAreaPath');
  if (areaPath) areaPath.setAttribute('d', areaD);

  // Active Dot on Latest Day
  const dot = document.getElementById('sparklineCurrentDot');
  if (dot) {
    dot.setAttribute('cx', `${lastCoord.x}`);
    dot.setAttribute('cy', `${lastCoord.y}`);
  }

  // Trajectory Status Pill
  const deltaPill = document.getElementById('trajectoryDeltaPill');
  if (deltaPill) {
    const isPaceOver = metrics.projectedMonthEnd > monthlyBudget && monthlyBudget > 0;
    deltaPill.textContent = isPaceOver ? `+${inrCompact(metrics.projectedMonthEnd - monthlyBudget)} over pace` : 'Sustainable pace';
    deltaPill.classList.toggle('warning', isPaceOver);
  }

  // Interactive Hover Tooltip on Container
  const container = document.getElementById('sparklineContainer');
  const tooltip = document.getElementById('sparklineTooltip');

  if (container && tooltip) {
    container.onmousemove = (e) => {
      const rect = container.getBoundingClientRect();
      const mouseX = e.clientX - rect.left;
      const pctX = Math.max(0, Math.min(1, (mouseX - paddingX) / plotWidth));
      const targetIndex = Math.min(validPoints.length - 1, Math.floor(pctX * validPoints.length));
      const pt = validPoints[targetIndex];

      if (pt) {
        const ptCoord = getCoordinates(pt);
        if (dot) {
          dot.setAttribute('cx', `${ptCoord.x}`);
          dot.setAttribute('cy', `${ptCoord.y}`);
        }
        tooltip.style.display = 'block';
        tooltip.innerHTML = `<strong>Day ${pt.dayIndex} (${pt.dateStr}):</strong> ${inr(pt.cumulativeSpend)}`;
      }
    };

    container.onmouseleave = () => {
      if (dot) {
        dot.setAttribute('cx', `${lastCoord.x}`);
        dot.setAttribute('cy', `${lastCoord.y}`);
      }
      tooltip.style.display = 'none';
    };
  }
}

// ── Transaction Feed & Material Slide-to-Delete ───────────────────────────
function renderTransactionList(list) {
  const container = document.getElementById('transactionList');
  if (!container) return;

  if (list.length === 0) {
    container.innerHTML = `
      <div class="m3-empty-state">
        <div class="m3-empty-icon">📭</div>
        <div class="m3-empty-title">No Transactions Recorded</div>
        <p class="m3-empty-desc">No activities found matching your current filter criteria.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = list.map(item => {
    const cat = CATEGORIES[item.category] || CATEGORIES.other;
    return `
      <div class="m3-tx-row" data-id="${item.id}">
        <div class="m3-tx-delete-reveal">
          <button type="button" data-del="${item.id}" aria-label="Delete entry">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z"/>
            </svg>
            <span>Delete</span>
          </button>
        </div>

        <div class="m3-tx-card" data-id="${item.id}">
          <div class="m3-tx-icon-badge">${cat.icon}</div>
          <div class="m3-tx-info">
            <span class="m3-tx-title">${escapeHtml(item.title)}</span>
            <span class="m3-tx-meta">${cat.name} • ${formatDate(item.date)}${item.notes ? ' • ' + escapeHtml(item.notes) : ''}</span>
          </div>
          <div class="m3-tx-amount">${inr(item.amount)}</div>
        </div>
      </div>
    `;
  }).join('');

  attachSwipeListeners();
}

function attachSwipeListeners() {
  document.querySelectorAll('.m3-tx-card').forEach(card => {
    let startX = 0, currentX = 0, isSwiping = false, isSwipedOpen = false;
    const buttonWidth = 84;
    const fullSwipeThreshold = -150;

    card.addEventListener('touchstart', (e) => {
      startX = e.touches[0].clientX;
      isSwiping = true;
      card.style.transition = 'none';
    }, { passive: true });

    card.addEventListener('touchmove', (e) => {
      if (!isSwiping) return;
      currentX = e.touches[0].clientX;
      const diffX = currentX - startX;

      if (diffX < 0) {
        card.style.transform = `translateX(${isSwipedOpen ? Math.max(-buttonWidth * 1.5, -buttonWidth + diffX) : diffX}px)`;
      } else if (isSwipedOpen && diffX > 0) {
        card.style.transform = `translateX(${Math.min(0, -buttonWidth + diffX)}px)`;
      }
    }, { passive: true });

    card.addEventListener('touchend', () => {
      if (!isSwiping) return;
      isSwiping = false;
      card.style.transition = 'transform 0.28s cubic-bezier(0.05, 0.7, 0.1, 1.0)';

      const diffX = currentX - startX;
      const id = card.dataset.id;

      if (diffX < fullSwipeThreshold) {
        triggerHaptic();
        card.style.transform = 'translateX(-100%)';
        setTimeout(() => deleteTransaction(id), 220);
      } else if (diffX < -buttonWidth / 2) {
        triggerHaptic();
        card.style.transform = `translateX(${-buttonWidth}px)`;
        isSwipedOpen = true;
      } else {
        card.style.transform = 'translateX(0px)';
        isSwipedOpen = false;
      }
    });

    card.addEventListener('click', () => {
      if (isSwipedOpen) {
        card.style.transform = 'translateX(0px)';
        card.style.transition = 'transform 0.25s ease';
        isSwipedOpen = false;
      }
    });
  });

  document.querySelectorAll('[data-del]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      triggerHaptic();
      deleteTransaction(btn.dataset.del);
    });
  });
}

function deleteTransaction(id) {
  expenses = expenses.filter(e => String(e.id) !== String(id));
  saveExpenses();
  render();
}

// ── Tab 2: Budgets (Category Envelopes) ────────────────────────────────────
function renderBudgets(metrics) {
  const allocationTotal = document.getElementById('allocationTotalDisplay');
  if (allocationTotal) allocationTotal.textContent = inr(monthlyBudget);

  const pct = monthlyBudget > 0 ? Math.min(100, Math.round((metrics.monthTotal / monthlyBudget) * 100)) : 0;
  const statusBadge = document.getElementById('allocationStatusBadge');
  if (statusBadge) {
    statusBadge.textContent = `${pct}% Used`;
    statusBadge.classList.toggle('warning', pct >= 100);
  }

  const progressFill = document.getElementById('allocationProgressFill');
  if (progressFill) {
    progressFill.style.width = `${pct}%`;
    progressFill.classList.toggle('warning', pct >= 100);
  }

  const spentText = document.getElementById('allocationSpentText');
  if (spentText) spentText.textContent = `${inrCompact(metrics.monthTotal)} spent`;

  const remainingText = document.getElementById('allocationRemainingText');
  if (remainingText) remainingText.textContent = `${inrCompact(Math.max(0, monthlyBudget - metrics.monthTotal))} remaining`;

  const grid = document.getElementById('envelopesGrid');
  if (!grid) return;

  grid.innerHTML = Object.entries(CATEGORIES).map(([key, cat]) => {
    const target = categoryBudgets[key] || 3000;
    const spent = metrics.monthExpenses
      .filter(e => e.category === key)
      .reduce((s, e) => s + e.amount, 0);

    const usage = target > 0 ? Math.min(100, Math.round((spent / target) * 100)) : 0;
    const isOver = spent > target;

    return `
      <div class="m3-envelope-card" data-cat="${key}">
        <div class="m3-envelope-top">
          <span class="m3-envelope-icon">${cat.icon}</span>
          <span class="m3-envelope-name">${cat.name}</span>
          <span class="m3-envelope-pct ${isOver ? 'over' : ''}">${usage}%</span>
        </div>

        <div class="m3-progress-track">
          <div class="m3-progress-indicator ${isOver ? 'warning' : ''}" style="width: ${usage}%;"></div>
        </div>

        <div class="m3-envelope-meta">
          <span>${inrCompact(spent)} spent</span>
          <span>Target: ${inrCompact(target)}</span>
        </div>
      </div>
    `;
  }).join('');

  grid.querySelectorAll('.m3-envelope-card').forEach(card => {
    card.addEventListener('click', () => {
      triggerHaptic();
      openBudgetEditModal(card.dataset.cat);
    });
  });
}

function openBudgetEditModal(catKey) {
  editingCategoryKey = catKey;
  const cat = CATEGORIES[catKey];
  const title = document.getElementById('budgetEditTitle');
  if (title) title.textContent = `Edit ${cat?.name || catKey}`;

  const input = document.getElementById('budgetEditInput');
  if (input) input.value = categoryBudgets[catKey] || 3000;

  openModal('budgetModalBackdrop');
}

// ── Tab 3: Trends & Recurring Bills ───────────────────────────────────────
function renderTrends(metrics) {
  const burnVal = document.getElementById('velBurnVal');
  if (burnVal) burnVal.textContent = inrCompact(metrics.dailyBurn);

  const projectedVal = document.getElementById('velProjectedVal');
  if (projectedVal) projectedVal.textContent = inrCompact(metrics.projectedMonthEnd);

  const remainingVal = document.getElementById('velRemainingVal');
  if (remainingVal) remainingVal.textContent = `${metrics.daysRemaining}d`;

  const burnPct = monthlyBudget > 0 ? Math.min(100, Math.round((metrics.projectedMonthEnd / monthlyBudget) * 100)) : 0;
  const burnFill = document.getElementById('velocityBurnFill');
  if (burnFill) {
    burnFill.style.width = `${burnPct}%`;
    burnFill.classList.toggle('warning', metrics.projectedMonthEnd > monthlyBudget);
  }

  const statusMsg = document.getElementById('velocityStatusMsg');
  if (statusMsg) {
    if (metrics.projectedMonthEnd > monthlyBudget && monthlyBudget > 0) {
      statusMsg.innerHTML = `⚠️ <strong style="color:var(--md-error);">Over-budget run-rate:</strong> At your current burn of ${inr(metrics.dailyBurn)}/day, you are projected to exceed your envelope by ${inr(metrics.projectedMonthEnd - monthlyBudget)}.`;
    } else {
      statusMsg.innerHTML = `✅ <strong style="color:var(--md-success);">Sustainable burn rate:</strong> Projected surplus of ${inr(Math.max(0, monthlyBudget - metrics.projectedMonthEnd))} by end of cycle.`;
    }
  }

  const distList = document.getElementById('categoryDistributionList');
  if (distList) {
    const totalSpent = metrics.monthTotal || 1;
    distList.innerHTML = Object.entries(CATEGORIES).map(([key, cat]) => {
      const spent = metrics.monthExpenses
        .filter(e => e.category === key)
        .reduce((s, e) => s + e.amount, 0);

      const pct = Math.round((spent / totalSpent) * 100);

      return `
        <div class="m3-dist-row">
          <div class="m3-dist-meta">
            <span>${cat.icon} ${cat.name}</span>
            <span style="font-family:var(--font-mono);">${inr(spent)} (${pct}%)</span>
          </div>
          <div class="m3-progress-track">
            <div class="m3-progress-indicator" style="width: ${pct}%;"></div>
          </div>
        </div>
      `;
    }).join('');
  }

  const today = new Date().getDate();
  const upcomingTotal = recurringBills
    .filter(b => !b.isPaid)
    .reduce((s, b) => s + b.amount, 0);

  const upcomingDisplay = document.getElementById('upcomingBillsTotalDisplay');
  if (upcomingDisplay) upcomingDisplay.textContent = inr(upcomingTotal);

  const billsList = document.getElementById('recurringBillsList');
  if (billsList) {
    billsList.innerHTML = recurringBills.map(bill => {
      let daysLeft = bill.dueDay - today;
      if (daysLeft < 0) {
        const lastDay = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).getDate();
        daysLeft = (lastDay - today) + bill.dueDay;
      }
      const dueLabel = daysLeft === 0 ? 'Due Today' : `Due in ${daysLeft}d`;

      return `
        <div class="m3-recurring-item ${bill.isPaid ? 'paid' : ''}">
          <div class="m3-rec-info">
            <div class="m3-rec-title-row">
              <span class="m3-rec-title">${escapeHtml(bill.title)}</span>
              <span class="m3-due-chip">${dueLabel}</span>
            </div>
            <span class="m3-rec-sub">Day ${bill.dueDay} of month</span>
          </div>
          <div class="m3-rec-right">
            <span class="m3-rec-amount">${inr(bill.amount)}</span>
            <button type="button" class="m3-rec-toggle-btn ${bill.isPaid ? 'paid' : ''}" data-bill="${bill.id}">
              ${bill.isPaid ? '✓ Paid' : 'Mark Paid'}
            </button>
          </div>
        </div>
      `;
    }).join('');

    billsList.querySelectorAll('[data-bill]').forEach(btn => {
      btn.addEventListener('click', () => {
        triggerHaptic();
        const bill = recurringBills.find(b => String(b.id) === btn.dataset.bill);
        if (bill) {
          bill.isPaid = !bill.isPaid;
          saveRecurringBills();
          render();
        }
      });
    });
  }
}

// ── Tab 4: Settings Render ────────────────────────────────────────────────
function renderSettings() {
  const budgetInput = document.getElementById('settingMonthlyBudget');
  if (budgetInput) budgetInput.value = monthlyBudget;

  const cycleInput = document.getElementById('settingCycleStartDay');
  if (cycleInput) cycleInput.value = cycleStartDay;

  const incomeInput = document.getElementById('settingBaseIncome');
  if (incomeInput) incomeInput.value = baseIncome;
}

// ── Modal Handlers ────────────────────────────────────────────────────────
function openModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.add('active');
}

function closeModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.remove('active');
}

function openAddExpenseModal() {
  const dateInput = document.getElementById('expenseDateInput');
  if (dateInput) dateInput.value = new Date().toISOString().split('T')[0];

  const amountInput = document.getElementById('expenseAmountInput');
  if (amountInput) amountInput.value = '';

  const titleInput = document.getElementById('expenseTitleInput');
  if (titleInput) titleInput.value = '';

  const notesInput = document.getElementById('expenseNotesInput');
  if (notesInput) notesInput.value = '';

  renderModalCategories();
  openModal('modalBackdrop');
  setTimeout(() => amountInput && amountInput.focus(), 120);
}

function renderModalCategories() {
  const grid = document.getElementById('modalCategoryGrid');
  if (!grid) return;

  grid.innerHTML = Object.entries(CATEGORIES).map(([key, cat]) => `
    <button type="button" class="m3-modal-cat-pill ${key === selectedCategoryModal ? 'active' : ''}" data-cat="${key}">
      <span class="m3-modal-cat-icon">${cat.icon}</span>
      <span>${cat.name.split(' ')[0]}</span>
    </button>
  `).join('');

  grid.querySelectorAll('.m3-modal-cat-pill').forEach(pill => {
    pill.addEventListener('click', () => {
      triggerHaptic();
      selectedCategoryModal = pill.dataset.cat;
      renderModalCategories();
    });
  });
}

function handleSaveExpense(e) {
  e.preventDefault();
  const amountStr = document.getElementById('expenseAmountInput').value.trim();
  const title = document.getElementById('expenseTitleInput').value.trim();
  const notes = document.getElementById('expenseNotesInput').value.trim();
  const dateStr = document.getElementById('expenseDateInput').value;

  const amount = parseFloat(amountStr);

  if (isNaN(amount) || amount <= 0 || !title) {
    alert('Please enter a valid expense description and amount.');
    return;
  }

  triggerHaptic();

  const newExpense = {
    id: Date.now(),
    title,
    amount,
    category: selectedCategoryModal,
    date: dateStr ? new Date(dateStr + 'T12:00:00').toISOString() : new Date().toISOString(),
    notes
  };

  expenses.unshift(newExpense);
  saveExpenses();
  closeModal('modalBackdrop');
  render();
}

// ── Event Handlers Setup ──────────────────────────────────────────────────
function setupEvents() {
  document.querySelectorAll('.m3-rail-btn, .m3-bnav-item').forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic();
      currentTab = btn.dataset.tab;
      localStorage.setItem(TAB_KEY, currentTab);
      render();
    });
  });

  document.querySelectorAll('#viewModeSwitcher .m3-segment-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic();
      currentViewMode = btn.dataset.mode;
      localStorage.setItem(VIEW_MODE_KEY, currentViewMode);
      render();
    });
  });

  document.querySelectorAll('.m3-filter-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      triggerHaptic();
      document.querySelectorAll('.m3-filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      activeCategoryFilter = chip.dataset.cat;
      render();
    });
  });

  const searchInput = document.getElementById('globalSearchInput');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      searchQuery = e.target.value;
      const metrics = calculateMetrics();
      renderOverview(metrics);
    });
  }

  const addButtons = [
    document.getElementById('railAddBtn'),
    document.getElementById('topAddBtn'),
    document.getElementById('mobileAddFab'),
    document.getElementById('inlineAddBtn')
  ];

  addButtons.forEach(btn => {
    if (btn) {
      btn.addEventListener('click', () => {
        triggerHaptic();
        openAddExpenseModal();
      });
    }
  });

  const modalCancelBtn = document.getElementById('modalCancelBtn');
  const modalDismissBtn = document.getElementById('modalDismissBtn');
  [modalCancelBtn, modalDismissBtn].forEach(b => {
    if (b) b.addEventListener('click', () => closeModal('modalBackdrop'));
  });

  const addForm = document.getElementById('addExpenseForm');
  if (addForm) addForm.addEventListener('submit', handleSaveExpense);

  const budgetCancelBtn = document.getElementById('budgetCancelBtn');
  const budgetCloseBtn = document.getElementById('budgetCloseBtn');
  [budgetCancelBtn, budgetCloseBtn].forEach(b => {
    if (b) b.addEventListener('click', () => closeModal('budgetModalBackdrop'));
  });

  const budgetSaveBtn = document.getElementById('budgetSaveBtn');
  if (budgetSaveBtn) {
    budgetSaveBtn.addEventListener('click', () => {
      triggerHaptic();
      const input = document.getElementById('budgetEditInput');
      const val = Number(input.value) || 0;
      if (editingCategoryKey) {
        categoryBudgets[editingCategoryKey] = val;
        saveCategoryBudgets();
      }
      closeModal('budgetModalBackdrop');
      render();
    });
  }

  const openAddBillModalBtn = document.getElementById('openAddBillModalBtn');
  if (openAddBillModalBtn) {
    openAddBillModalBtn.addEventListener('click', () => {
      triggerHaptic();
      openModal('billModalBackdrop');
    });
  }

  const billCancelBtn = document.getElementById('billCancelBtn');
  const billCloseBtn = document.getElementById('billCloseBtn');
  [billCancelBtn, billCloseBtn].forEach(b => {
    if (b) b.addEventListener('click', () => closeModal('billModalBackdrop'));
  });

  const billSaveBtn = document.getElementById('billSaveBtn');
  if (billSaveBtn) {
    billSaveBtn.addEventListener('click', () => {
      const title = document.getElementById('billTitleInput').value.trim();
      const amount = Number(document.getElementById('billAmountInput').value) || 0;
      const dueDay = Number(document.getElementById('billDayInput').value) || 1;

      if (title && amount > 0) {
        triggerHaptic();
        recurringBills.push({ id: Date.now(), title, amount, dueDay, isPaid: false });
        saveRecurringBills();
        closeModal('billModalBackdrop');
        render();
      }
    });
  }

  document.querySelectorAll('.m3-scrim-backdrop').forEach(scrim => {
    scrim.addEventListener('click', (e) => {
      if (e.target === scrim) closeModal(scrim.id);
    });
  });

  const themeSelect = document.getElementById('themeSelect');
  if (themeSelect) {
    themeSelect.addEventListener('change', (e) => {
      currentTheme = e.target.value;
      localStorage.setItem(THEME_KEY, currentTheme);
      applyThemeAndPalette();
    });
  }

  const railThemeToggle = document.getElementById('railThemeToggle');
  if (railThemeToggle) {
    railThemeToggle.addEventListener('click', () => {
      triggerHaptic();
      currentTheme = currentTheme === 'dark' ? 'light' : 'dark';
      localStorage.setItem(THEME_KEY, currentTheme);
      applyThemeAndPalette();
    });
  }

  document.querySelectorAll('.m3-palette-circle').forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic();
      currentPalette = btn.dataset.pal;
      localStorage.setItem(PALETTE_KEY, currentPalette);
      applyThemeAndPalette();
    });
  });

  const saveSettingsBtn = document.getElementById('saveSettingsBtn');
  if (saveSettingsBtn) {
    saveSettingsBtn.addEventListener('click', () => {
      triggerHaptic();
      monthlyBudget = Number(document.getElementById('settingMonthlyBudget').value) || 25000;
      cycleStartDay = Number(document.getElementById('settingCycleStartDay').value) || 1;
      baseIncome = Number(document.getElementById('settingBaseIncome').value) || 50000;

      localStorage.setItem(BUDGET_KEY, monthlyBudget);
      localStorage.setItem(CYCLE_START_DAY_KEY, cycleStartDay);
      localStorage.setItem(BASE_INCOME_KEY, baseIncome);

      alert('Parameters saved successfully.');
      render();
    });
  }

  document.getElementById('exportCsvBtn')?.addEventListener('click', exportCSV);
  const csvInput = document.getElementById('importCsvInput');
  document.getElementById('importCsvBtn')?.addEventListener('click', () => csvInput?.click());
  csvInput?.addEventListener('change', importCSV);

  document.getElementById('exportVaultBtn')?.addEventListener('click', exportVaultBackup);
  const vaultInput = document.getElementById('importVaultInput');
  document.getElementById('importVaultBtn')?.addEventListener('click', () => vaultInput?.click());
  vaultInput?.addEventListener('change', handleImportVault);

  document.getElementById('clearAllDataBtn')?.addEventListener('click', () => {
    if (confirm('Erase all transaction records? This action cannot be undone.')) {
      expenses = [];
      saveExpenses();
      render();
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === '/' && document.activeElement !== searchInput) {
      e.preventDefault();
      searchInput?.focus();
    }
    if ((e.metaKey || e.ctrlKey) || (e.altKey)) {
      if (e.key === '1') { e.preventDefault(); currentTab = 'overview'; render(); }
      if (e.key === '2') { e.preventDefault(); currentTab = 'categories'; render(); }
      if (e.key === '3') { e.preventDefault(); currentTab = 'insights'; render(); }
      if (e.key === '4' || e.key === ',') { e.preventDefault(); currentTab = 'settings'; render(); }
      if (e.key === 'n' || e.key === 'N') { e.preventDefault(); openAddExpenseModal(); }
    }
    if (e.key === 'Escape') {
      document.querySelectorAll('.m3-scrim-backdrop.active').forEach(modal => {
        modal.classList.remove('active');
      });
    }
  });
}

// ── Universal Category Resolver & CSV Importer ───────────────────────────
function resolveCategoryKey(raw) {
  if (!raw) return 'other';
  const s = raw.toLowerCase().trim();

  if (CATEGORIES[s]) return s;

  const exactMap = {
    utilities: 'bills',
    health: 'healthcare',
    housing: 'other',
    invest: 'invest'
  };
  if (exactMap[s]) return exactMap[s];

  if (/food|dining|restaurant|cafe|grocery|groceries|coffee|lunch|dinner|snack/.test(s)) return 'food';
  if (/transport|transit|travel|fuel|pertol|petrol|diesel|cab|uber|metro|commute/.test(s)) return 'transport';
  if (/utilit|bill|electric|power|wifi|water|gas|internet|broadband/.test(s)) return 'bills';
  if (/entertain|movie|music|netflix|spotify|game|cinema|streaming/.test(s)) return 'entertainment';
  if (/health|medic|doctor|gym|pharma|fitness|clinic|hospital/.test(s)) return 'healthcare';
  if (/shop|cloth|retail|amazon|store|electronics|mall|milk|fruit/.test(s)) return 'shopping';
  if (/invest|stock|mutual|sip|fund|trading|gold/.test(s)) return 'invest';

  return 'other';
}

function exportCSV() {
  if (expenses.length === 0) {
    alert('No transactions available to export.');
    return;
  }

  let csv = 'date,type,title,category,amount,notes\n';
  expenses.forEach(e => {
    const row = [
      `"${e.date}"`,
      '"expense"',
      `"${(e.title || '').replace(/"/g, '""')}"`,
      `"${e.category}"`,
      e.amount.toFixed(2),
      `"${(e.notes || '').replace(/"/g, '""')}"`
    ];
    csv += row.join(',') + '\n';
  });

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `WellSpent_Export_${new Date().toISOString().split('T')[0]}.csv`;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}

function importCSV(e) {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = (event) => {
    const text = event.target.result;
    const lines = parseCSVLines(text);
    if (lines.length < 2) {
      alert('CSV appears empty or invalid.');
      return;
    }

    const rawHeader = lines[0];
    const hdr = rawHeader.map(h => h.toLowerCase().replace(/[^a-z0-9]/g, ''));

    const iType = hdr.findIndex(h => h === 'type' || h === 'kind');
    const iTitle = hdr.findIndex(h => h.includes('title') || h.includes('name') || h.includes('description') || h.includes('desc') || h.includes('item'));
    const iAmount = hdr.findIndex(h => h.includes('amount') || h.includes('cost') || h.includes('price') || h.includes('total') || h.includes('val'));
    const iCategory = hdr.findIndex((h, i) => i !== iType && (h.includes('categ') || h === 'cat'));
    const iDate = hdr.findIndex(h => h.includes('date') || h.includes('time'));
    const iNotes = hdr.findIndex(h => h.includes('note') || h.includes('memo') || h.includes('comment') || h.includes('remark'));

    if (iTitle < 0 && iAmount < 0) {
      alert(`Could not detect required columns.\nHeaders found: ${rawHeader.join(', ')}`);
      return;
    }

    let count = 0, skipped = 0;
    for (let i = 1; i < lines.length; i++) {
      const cols = lines[i];
      if (!cols || cols.length < 2) continue;

      const amtIdx = iAmount >= 0 ? iAmount : cols.findIndex(c => /^[\d.,]+$/.test(c.replace(/[₹$€£,\s]/g, '')));
      if (amtIdx < 0) { skipped++; continue; }
      const amount = parseFloat((cols[amtIdx] || '').replace(/[₹$€£,\s]/g, ''));
      if (isNaN(amount) || amount <= 0) { skipped++; continue; }

      let title = 'Imported Transaction';
      if (iTitle >= 0 && cols[iTitle] && cols[iTitle].trim()) {
        title = cols[iTitle].trim();
      } else {
        const skipIdx = new Set([amtIdx, iDate, iType].filter(x => x >= 0));
        const candidate = cols.find((c, ci) =>
          !skipIdx.has(ci) && c.trim() &&
          !/^[\d.,:\/\-T+Z]+$/.test(c.trim()) &&
          c.toLowerCase() !== 'expense' && c.toLowerCase() !== 'income');
        if (candidate) title = candidate.trim();
      }
      if (!title) { skipped++; continue; }

      const catRaw = iCategory >= 0 ? (cols[iCategory] || '') : '';
      const category = resolveCategoryKey(catRaw);

      let date = new Date().toISOString();
      if (iDate >= 0 && cols[iDate] && cols[iDate].trim()) {
        const parsed = parseDateFlexible(cols[iDate].trim());
        if (parsed) date = parsed;
      }

      const notes = iNotes >= 0 ? (cols[iNotes] || '').trim() : '';

      expenses.push({
        id: Date.now() + Math.random(),
        title,
        amount,
        category,
        date,
        notes
      });
      count++;
    }

    saveExpenses();
    e.target.value = '';
    alert(skipped > 0
      ? `Imported ${count} transaction${count !== 1 ? 's' : ''} (${skipped} rows skipped).`
      : `Imported ${count} transaction${count !== 1 ? 's' : ''} successfully.`);
    render();
  };
  reader.readAsText(file, 'utf-8');
}

function parseCSVLines(text) {
  const rows = [];
  const lines = text.split(/\r?\n/);
  for (const line of lines) {
    if (!line.trim()) continue;
    rows.push(parseCSVRow(line));
  }
  return rows;
}

function parseCSVRow(line) {
  const fields = [];
  let field = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') { field += '"'; i++; }
      else inQuotes = !inQuotes;
    } else if (ch === ',' && !inQuotes) {
      fields.push(field.trim());
      field = '';
    } else {
      field += ch;
    }
  }
  fields.push(field.trim());
  return fields;
}

function parseDateFlexible(raw) {
  if (!raw) return null;
  if (/^\d{4}-\d{2}-\d{2}/.test(raw)) {
    const d = new Date(raw);
    return isNaN(d) ? null : d.toISOString();
  }
  const dmy = raw.match(/^(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})$/);
  if (dmy) {
    let [, d, mo, y] = dmy;
    if (y.length === 2) y = '20' + y;
    const dt = new Date(`${y}-${mo.padStart(2, '0')}-${d.padStart(2, '0')}T12:00:00`);
    return isNaN(dt) ? null : dt.toISOString();
  }
  const d = new Date(raw);
  return isNaN(d) ? null : d.toISOString();
}

// ── Encrypted Vault Operations ────────────────────────────────────────────
function exportVaultBackup() {
  const data = {
    version: 4,
    exportedAt: new Date().toISOString(),
    expenses,
    monthlyBudget,
    cycleStartDay,
    baseIncome,
    categoryBudgets,
    recurringBills,
    currentPalette,
    currentTheme
  };

  const jsonStr = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonStr], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `WellSpent_Vault_${new Date().toISOString().split('T')[0]}.wsbackup`;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}

function handleImportVault(e) {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = (event) => {
    try {
      const data = JSON.parse(event.target.result);
      if (data && Array.isArray(data.expenses)) {
        expenses = data.expenses;
        monthlyBudget = data.monthlyBudget || monthlyBudget;
        cycleStartDay = data.cycleStartDay || cycleStartDay;
        baseIncome = data.baseIncome || baseIncome;
        categoryBudgets = data.categoryBudgets || categoryBudgets;
        recurringBills = data.recurringBills || recurringBills;
        currentPalette = data.currentPalette || currentPalette;
        currentTheme = data.currentTheme || currentTheme;

        saveExpenses();
        saveCategoryBudgets();
        saveRecurringBills();
        localStorage.setItem(BUDGET_KEY, monthlyBudget);
        localStorage.setItem(CYCLE_START_DAY_KEY, cycleStartDay);
        localStorage.setItem(BASE_INCOME_KEY, baseIncome);
        localStorage.setItem(PALETTE_KEY, currentPalette);
        localStorage.setItem(THEME_KEY, currentTheme);

        alert('Vault backup restored successfully.');
        render();
      }
    } catch {
      alert('Invalid vault backup file.');
    }
  };
  reader.readAsText(file);
}

// ── Service Worker Registration ───────────────────────────────────────────
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js').catch(() => {});
  });
}

// ── Initialize App ────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  setupEvents();
  render();
});
