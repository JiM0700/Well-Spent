// ═══════════════════════════════════════════════════════════════════════════
// WELL SPENT — Material 3 Expressive (Porcelain White Edition)
// ═══════════════════════════════════════════════════════════════════════════

const STORAGE_KEY            = 'well_spent_expenses_v1';
const BUDGET_KEY             = 'well_spent_budget_v1';
const CYCLE_START_DAY_KEY    = 'well_spent_cycle_start_day_v1';
const BASE_INCOME_KEY        = 'well_spent_base_income_v1';
const VIEW_MODE_KEY          = 'well_spent_view_mode_v1';
const TAB_KEY                = 'well_spent_current_tab_v1';
const CATEGORY_BUDGETS_KEY   = 'well_spent_category_budgets_v1';
const RECURRING_BILLS_KEY    = 'well_spent_recurring_bills_v1';
const DISMISSED_PATTERNS_KEY = 'well_spent_dismissed_patterns_v1';
const NET_WORTH_KEY          = 'well_spent_net_worth_v1';
const GOALS_KEY              = 'well_spent_goals_v1';
const PALETTE_KEY            = 'well_spent_palette_v1';

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
let expenses          = loadJSON(STORAGE_KEY, []);
let monthlyBudget     = Number(localStorage.getItem(BUDGET_KEY))          || 25000;
let cycleStartDay     = Number(localStorage.getItem(CYCLE_START_DAY_KEY)) || 1;
let baseIncome        = Number(localStorage.getItem(BASE_INCOME_KEY))     || 50000;
let currentViewMode   = localStorage.getItem(VIEW_MODE_KEY)               || 'monthwise';
let currentTab        = localStorage.getItem(TAB_KEY)                     || 'overview';
let categoryBudgets   = loadCategoryBudgets();
let recurringBills    = loadRecurringBills();
let dismissedPatterns = loadJSON(DISMISSED_PATTERNS_KEY, []);
let netWorth          = loadJSON(NET_WORTH_KEY, { assets: 0, liabilities: 0, configured: false });
let goals             = loadJSON(GOALS_KEY, []);
let currentPalette    = localStorage.getItem(PALETTE_KEY)                 || 'blue';

let activeCategoryFilter  = 'all';
let searchQuery           = '';
let selectedCategoryModal = 'food';
let editingCategoryKey    = null;

let selectedGoalIcon      = '🛡️';
let editingGoalId         = null;
let contributingGoalId    = null;

// Ensure all existing expenses have valid duplicate fingerprints
if (Array.isArray(expenses) && expenses.length > 0) {
  let modified = false;
  expenses.forEach(exp => {
    if (!exp.fingerprint) {
      exp.fingerprint = generateFingerprint(exp.date, exp.title, exp.amount, exp.account || '');
      modified = true;
    }
  });
  if (modified) saveExpenses();
}

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

function saveExpenses()          { localStorage.setItem(STORAGE_KEY, JSON.stringify(expenses)); }
function saveCategoryBudgets()   { localStorage.setItem(CATEGORY_BUDGETS_KEY, JSON.stringify(categoryBudgets)); }
function saveRecurringBills()    { localStorage.setItem(RECURRING_BILLS_KEY, JSON.stringify(recurringBills)); }
function saveDismissedPatterns() { localStorage.setItem(DISMISSED_PATTERNS_KEY, JSON.stringify(dismissedPatterns)); }
function saveNetWorth()          { localStorage.setItem(NET_WORTH_KEY, JSON.stringify(netWorth)); }
function saveGoals()             { localStorage.setItem(GOALS_KEY, JSON.stringify(goals)); }

let toastTimeout = null;
function showToast(msg, duration = 3000) {
  const toast = document.getElementById('m3Toast');
  if (!toast) return;
  toast.textContent = msg;
  toast.classList.add('show');
  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    toast.classList.remove('show');
  }, duration);
}

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

// ═══════════════════════════════════════════════════════════════════════════
// CADENCE & RECURRING DETECTION ENGINE (Ledgerly-Inspired Intelligence)
// ═══════════════════════════════════════════════════════════════════════════

const SUBSCRIPTION_HINTS = [
  'netflix', 'spotify', 'hulu', 'disney', 'youtube', 'icloud', 'dropbox', 'adobe',
  'microsoft', 'amazon prime', 'prime video', 'patreon', 'membership', 'gym', 'cult.fit',
  'openai', 'chatgpt', 'canva', 'notion', 'zoom', 'slack', 'github', 'apple', 'swiggy one',
  'zomato gold', 'times prime', 'hotstar', 'playstation', 'xbox', 'audible', 'medium',
  'claude', 'anthropic', 'midjourney', 'cursor', 'copilot', 'linkedin', '1password',
  'expressvpn', 'nordvpn', 'substack', 'duolingo', 'headspace', 'calm'
];

const BILL_HINTS = [
  'mortgage', 'rent', 'loan', 'insurance', 'lic', 'utility', 'utilities', 'electric',
  'electricity', 'water', 'internet', 'phone', 'mobile', 'broadband', 'wifi', 'daycare',
  'tuition', 'lease', 'car payment', 'auto payment', 'maintenance', 'hoa', 'property tax',
  'gas', 'cylinder', 'airtel', 'jio', 'vi', 'tatasky', 'bescom', 'tneb', 'cesc', 'act fibernet'
];

function normalizeMerchant(name) {
  if (!name) return '';
  return name
    .toLowerCase()
    .replace(/^upi\/\d+\//i, '')
    .replace(/#\s*\d+/g, '')
    .replace(/\b\d{6,}\b/g, '')
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function generateFingerprint(date, title, amount, account = '') {
  const d = (date || '').split('T')[0];
  const t = (title || '').trim().toLowerCase().replace(/\s+/g, ' ');
  const a = Number(amount || 0).toFixed(2);
  const acc = (account || '').trim().toLowerCase();
  return `${d}|${t}|${a}|${acc}`;
}

function detectRecurringPatterns(expensesList, dismissedList, confirmedList) {
  if (!Array.isArray(expensesList) || expensesList.length < 2) return [];

  const groups = {};
  for (const exp of expensesList) {
    const norm = normalizeMerchant(exp.title);
    if (!norm || norm.length < 2) continue;
    if (!groups[norm]) {
      groups[norm] = {
        normalizedName: norm,
        displayTitle: exp.title,
        category: exp.category || 'other',
        items: []
      };
    }
    groups[norm].items.push(exp);
  }

  const suggestions = [];
  const now = new Date();

  for (const [normKey, group] of Object.entries(groups)) {
    const isAlreadyTracked = confirmedList.some(b => {
      const bNorm = normalizeMerchant(b.title);
      return bNorm === normKey || b.title.toLowerCase().includes(normKey) || normKey.includes(bNorm);
    });
    if (isAlreadyTracked) continue;

    const sorted = [...group.items].sort((a, b) => new Date(a.date) - new Date(b.date));
    const uniqueDates = [];
    const dateMap = new Map();
    for (const item of sorted) {
      const dtStr = new Date(item.date).toISOString().split('T')[0];
      if (!dateMap.has(dtStr)) {
        dateMap.set(dtStr, item);
        uniqueDates.push(item);
      }
    }

    if (uniqueDates.length < 2) continue;

    const intervals = [];
    for (let i = 1; i < uniqueDates.length; i++) {
      const d1 = new Date(uniqueDates[i - 1].date);
      const d2 = new Date(uniqueDates[i].date);
      const diffDays = Math.max(1, (d2 - d1) / (1000 * 60 * 60 * 24));
      intervals.push(diffDays);
    }

    const avgInterval = intervals.reduce((s, v) => s + v, 0) / intervals.length;
    const variance = intervals.reduce((s, v) => s + Math.pow(v - avgInterval, 2), 0) / intervals.length;
    const jitter = Math.sqrt(variance);

    let cadence = null;
    if (avgInterval >= 5 && avgInterval <= 9) cadence = 'weekly';
    else if (avgInterval >= 12 && avgInterval <= 17) cadence = 'biweekly';
    else if (avgInterval >= 24 && avgInterval <= 40) cadence = 'monthly';
    else if (avgInterval >= 75 && avgInterval <= 110) cadence = 'quarterly';
    else if (avgInterval >= 330 && avgInterval <= 400) cadence = 'annual';

    if (!cadence) continue;

    const amounts = uniqueDates.map(u => u.amount);
    const avgAmount = amounts.reduce((s, v) => s + v, 0) / amounts.length;
    const minAmount = Math.min(...amounts);
    const maxAmount = Math.max(...amounts);
    const amountVariation = avgAmount > 0 ? (maxAmount - minAmount) / avgAmount : 0;

    const isSubHint = SUBSCRIPTION_HINTS.some(h => normKey.includes(h));
    const isBillHint = BILL_HINTS.some(h => normKey.includes(h));

    let isValidCandidate = false;
    let isSubscription = false;

    if (isSubHint) {
      isValidCandidate = amountVariation <= 0.20;
      isSubscription = true;
    } else if (isBillHint) {
      isValidCandidate = amountVariation <= 0.35;
      isSubscription = false;
    } else {
      if (uniqueDates.length >= 3 && ['monthly', 'quarterly', 'annual'].includes(cadence) && amountVariation <= 0.08) {
        isValidCandidate = true;
        isSubscription = false;
      }
    }

    if (!isValidCandidate) continue;

    const patternKey = `pat_${normKey}_${cadence}`;
    if (dismissedList.includes(patternKey)) continue;

    const isHighConfidence = uniqueDates.length >= 3 && amountVariation <= 0.12 && jitter <= 5;
    const confidence = isHighConfidence ? 'High' : 'Likely';

    const lastDate = new Date(uniqueDates[uniqueDates.length - 1].date);
    let nextDate = new Date(lastDate);

    if (cadence === 'weekly') nextDate.setDate(nextDate.getDate() + 7);
    else if (cadence === 'biweekly') nextDate.setDate(nextDate.getDate() + 14);
    else if (cadence === 'monthly') nextDate.setMonth(nextDate.getMonth() + 1);
    else if (cadence === 'quarterly') nextDate.setMonth(nextDate.getMonth() + 3);
    else if (cadence === 'annual') nextDate.setFullYear(nextDate.getFullYear() + 1);

    while (nextDate < now) {
      if (cadence === 'weekly') nextDate.setDate(nextDate.getDate() + 7);
      else if (cadence === 'biweekly') nextDate.setDate(nextDate.getDate() + 14);
      else if (cadence === 'monthly') nextDate.setMonth(nextDate.getMonth() + 1);
      else if (cadence === 'quarterly') nextDate.setMonth(nextDate.getMonth() + 3);
      else if (cadence === 'annual') nextDate.setFullYear(nextDate.getFullYear() + 1);
    }

    let monthlyEquivalent = avgAmount;
    if (cadence === 'weekly') monthlyEquivalent = avgAmount * 52 / 12;
    else if (cadence === 'biweekly') monthlyEquivalent = avgAmount * 26 / 12;
    else if (cadence === 'quarterly') monthlyEquivalent = avgAmount / 3;
    else if (cadence === 'annual') monthlyEquivalent = avgAmount / 12;

    suggestions.push({
      patternKey,
      title: group.displayTitle,
      normalizedName: normKey,
      category: group.category,
      avgAmount,
      monthlyEquivalent,
      cadence,
      confidence,
      occurrences: uniqueDates.length,
      nextDate: nextDate.toISOString(),
      dueDay: nextDate.getDate(),
      isSubscription
    });
  }

  return suggestions;
}

function seedSampleData() {
  const now = new Date();
  const y = now.getFullYear(), m = now.getMonth(), d = now.getDate();
  const sampleList = [
    { title: 'Specialty Cold Brew & Bagel', amount: 380, category: 'food', date: new Date(y, m, d, 9, 30).toISOString(), notes: 'Morning coffee' },
    { title: 'Organic Supermarket Basket', amount: 1450, category: 'food', date: new Date(y, m, d, 14, 15).toISOString(), notes: 'Groceries' },
    { title: 'Metro Transit SmartCard', amount: 500, category: 'transport', date: new Date(y, m, d - 1, 18, 0).toISOString(), notes: 'Monthly pass' },
    { title: 'High-speed Fiber Net', amount: 1199, category: 'bills', date: new Date(y, m, d - 3, 11, 0).toISOString(), notes: 'Broadband' }
  ];
  expenses = sampleList.map((exp, idx) => ({
    id: Date.now() - (idx + 1) * 1000,
    ...exp,
    fingerprint: generateFingerprint(exp.date, exp.title, exp.amount)
  }));
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
  const daysRemainingIncludingToday = Math.max(1, totalDays - daysElapsed + 1);

  // Dynamic daily allowance calculated based strictly on the remaining monthly balance
  const previousSpendBeforeToday = Math.max(0, monthTotal - todayTotal);
  const remainingMonthBalance = Math.max(0, monthlyBudget - previousSpendBeforeToday);
  const dynamicDailyBudget = remainingMonthBalance > 0
    ? (remainingMonthBalance / daysRemainingIncludingToday)
    : 0;

  const remainingToday = Math.max(0, dynamicDailyBudget - todayTotal);
  const dailyBudget = monthlyBudget / totalDays;
  const dailyBurn = monthTotal / daysElapsed;
  const projectedMonthEnd = monthTotal + (dailyBurn * daysRemaining);

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
    dynamicDailyBudget,
    remainingMonthBalance,
    dailyBurn,
    projectedMonthEnd,
    remainingToday,
    daysElapsed,
    daysRemaining,
    daysRemainingIncludingToday,
    totalDays,
    monthExpenses,
    todayExpenses,
    cycleStartDay,
    trajectoryDays
  };
}

// ── Master Render Pipeline ────────────────────────────────────────────────
function render() {
  applyPalette();
  syncNav();

  const metrics = calculateMetrics();

  renderRail(metrics);
  renderTopBar(metrics);
  renderOverview(metrics);
  renderBudgets(metrics);
  renderTrends(metrics);
  renderSettings();
}

function applyPalette() {
  document.body.setAttribute('data-palette', currentPalette);

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
    overview: 'Home',
    categories: 'Budgets',
    insights: 'Trends',
    settings: 'Settings'
  };
  const titleEl = document.getElementById('pageHeadingTitle');
  if (titleEl) titleEl.textContent = titles[currentTab] || 'Home';
}

function renderTopBar(metrics) {
  const cycleText = document.getElementById('topBarCycleText');
  if (cycleText) cycleText.textContent = `Cycle Day ${metrics.daysElapsed} of ${metrics.totalDays}`;
}

function renderRail(metrics) {
  const pct = monthlyBudget > 0 ? Math.min(100, Math.round((metrics.monthTotal / monthlyBudget) * 100)) : 0;
  const isOver = monthlyBudget > 0 && metrics.monthTotal > monthlyBudget;

  const gaugePct = document.getElementById('railGaugePct');
  if (gaugePct) gaugePct.textContent = `${pct}%`;

  // Mini ring circumference = 2 * PI * 17 = 106.81
  const miniCircumference = 106.81;
  const miniOffset = miniCircumference * (1 - pct / 100);
  const ringFill = document.getElementById('railMiniRingFill');
  if (ringFill) {
    ringFill.style.strokeDasharray = `${miniCircumference}`;
    ringFill.style.strokeDashoffset = `${miniOffset}`;
    ringFill.classList.toggle('warning', isOver);
  }

  // Expanded Tooltip Details
  const tooltipPctVal = document.getElementById('tooltipPctVal');
  if (tooltipPctVal) {
    tooltipPctVal.textContent = isOver ? `${pct}% (Over Target)` : `${pct}% Used`;
    tooltipPctVal.classList.toggle('warning', isOver);
  }

  const tooltipTrackFill = document.getElementById('tooltipTrackFill');
  if (tooltipTrackFill) {
    tooltipTrackFill.style.width = `${pct}%`;
    tooltipTrackFill.classList.toggle('warning', isOver);
  }

  const spentMeta = document.getElementById('railSpentMeta');
  if (spentMeta) spentMeta.textContent = inr(metrics.monthTotal);

  const leftMeta = document.getElementById('railLeftMeta');
  if (leftMeta) leftMeta.textContent = inr(Math.max(0, monthlyBudget - metrics.monthTotal));

  const cycleTimeline = document.getElementById('tooltipCycleTimeline');
  if (cycleTimeline) cycleTimeline.textContent = `Day ${metrics.daysElapsed} of ${metrics.totalDays}`;
}

// ── Tab 1: Overview & Radial Gauge & Trajectory Sparkline ──────────────────
function renderOverview(metrics) {
  const isDaywise = currentViewMode === 'daywise';

  // In-Card Icon Toggle Active State
  document.querySelectorAll('#viewModeSwitcher .m3-mode-icon-btn').forEach(btn => {
    const active = btn.dataset.mode === currentViewMode;
    btn.classList.toggle('active', active);
    btn.setAttribute('aria-checked', String(active));
  });

  const total = isDaywise ? metrics.todayTotal : metrics.monthTotal;
  const budget = isDaywise ? metrics.dynamicDailyBudget : monthlyBudget;
  const remaining = isDaywise ? metrics.remainingToday : Math.max(0, monthlyBudget - metrics.monthTotal);
  const isOver = budget > 0 ? total > budget : total > 0;
  const pct = budget > 0 ? Math.min(100, Math.round((total / budget) * 100)) : (total > 0 ? 100 : 0);

  // 🌟 1. UPDATE OPEN HORSESHOE ARC GAUGE (250 degrees arc length = 375.2) 🌟
  const arcLength = 375.2;
  const offset = arcLength * (1 - Math.min(1, pct / 100));
  const radialCircle = document.getElementById('radialGaugeCircle');
  if (radialCircle) {
    radialCircle.style.strokeDasharray = `${arcLength}`;
    radialCircle.style.strokeDashoffset = `${offset}`;
    radialCircle.classList.toggle('warning', isOver);
  }

  const pctPill = document.getElementById('pulsePctPill');
  if (pctPill) {
    pctPill.textContent = `${pct}% Used`;
    pctPill.classList.toggle('warning', isOver);
  }

  const eyebrowBadge = document.getElementById('pulseEyebrowBadge');
  if (eyebrowBadge) eyebrowBadge.textContent = isDaywise ? "TODAY'S ALLOWANCE" : "MONTHLY ENVELOPE";

  const amountDisplay = document.getElementById('pulseAmountDisplay');
  if (amountDisplay) amountDisplay.textContent = inr(total);

  const subDisplay = document.getElementById('pulseSubDisplay');
  if (subDisplay) {
    subDisplay.textContent = isDaywise
      ? `of ${inrCompact(budget)} daily allowance (${metrics.daysRemainingIncludingToday}d left)`
      : `of ${inrCompact(budget)} monthly allowance`;
  }

  const statusPill = document.getElementById('pulseStatusPill');
  if (statusPill) {
    statusPill.textContent = isOver ? 'Over Budget' : 'On Track';
    statusPill.classList.toggle('warning', isOver);
  }

  // Dynamic Stat Pod Labels & Figures
  const remainingLabel = document.getElementById('pulseRemainingLabel');
  if (remainingLabel) remainingLabel.textContent = isDaywise ? 'Today Left' : 'Remaining';

  const burnLabel = document.getElementById('pulseBurnLabel');
  if (burnLabel) burnLabel.textContent = isDaywise ? 'Daily Target' : 'Daily Burn';

  const monthEndLabel = document.getElementById('pulseMonthEndLabel');
  if (monthEndLabel) monthEndLabel.textContent = isDaywise ? 'Month Left' : 'Est. Total';

  const remainingDisplay = document.getElementById('pulseRemainingDisplay');
  if (remainingDisplay) remainingDisplay.textContent = inrCompact(remaining);

  const burnDisplay = document.getElementById('pulseBurnDisplay');
  if (burnDisplay) {
    burnDisplay.textContent = isDaywise
      ? `${inrCompact(metrics.dynamicDailyBudget)}/day`
      : `${inrCompact(metrics.dailyBurn)}/day`;
  }

  const monthEndDisplay = document.getElementById('pulseMonthEndDisplay');
  if (monthEndDisplay) {
    monthEndDisplay.textContent = isDaywise
      ? inrCompact(Math.max(0, monthlyBudget - metrics.monthTotal))
      : inrCompact(metrics.projectedMonthEnd);
  }

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
    feedSubheading.textContent = `${list.length} ${isDaywise ? (list.length === 1 ? 'entry today' : 'entries today') : (list.length === 1 ? 'entry this cycle' : 'entries this cycle')}`;
  }

  renderTransactionList(list);
  renderNetWorthCard();
}

// ── Net Worth Balance Sheet Engine ────────────────────────────────────────
function renderNetWorthCard() {
  const container = document.getElementById('netWorthCardBody');
  if (!container) return;

  const configureLink = document.getElementById('netWorthSettingsLinkBtn');
  if (configureLink) {
    configureLink.onclick = () => {
      triggerHaptic();
      currentTab = 'settings';
      render();
      setTimeout(() => {
        const el = document.getElementById('settingTotalAssets');
        if (el) {
          el.scrollIntoView({ behavior: 'smooth', block: 'center' });
          el.focus();
        }
      }, 100);
    };
  }

  if (!netWorth || !netWorth.configured) {
    container.innerHTML = `
      <div class="m3-networth-body">
        <div class="m3-networth-hero unconfigured">Not configured</div>
        <div class="m3-networth-sub">Configure your assets & liabilities in Settings to track your balance sheet.</div>
      </div>
    `;
    return;
  }

  const assets = Number(netWorth.assets) || 0;
  const liabilities = Number(netWorth.liabilities) || 0;
  const calculatedNW = assets - liabilities;
  const formattedNW = inr(calculatedNW);
  const isPositive = calculatedNW >= 0;

  container.innerHTML = `
    <div class="m3-networth-body">
      <div class="m3-networth-hero" style="color:${isPositive ? 'var(--md-on-surface)' : 'var(--md-error)'};">
        ${formattedNW}
      </div>
      <div class="m3-networth-sub">Total Assets minus Total Liabilities</div>

      <div class="m3-networth-stats-row">
        <div class="m3-nw-stat">
          <span class="m3-nw-label">Assets</span>
          <span class="m3-nw-val asset">${inrCompact(assets)}</span>
        </div>
        <div class="m3-stat-pod-divider"></div>
        <div class="m3-nw-stat">
          <span class="m3-nw-label">Liabilities</span>
          <span class="m3-nw-val debt">${inrCompact(liabilities)}</span>
        </div>
      </div>
    </div>
  `;
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

  // Render Financial Goals & Savings Targets
  renderGoals();
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

// ── Financial Goals & Savings Targets Engine ──────────────────────────────
function renderGoals() {
  const grid = document.getElementById('goalsGrid');
  if (!grid) return;

  if (!Array.isArray(goals) || goals.length === 0) {
    grid.innerHTML = `
      <div class="m3-empty-state" style="grid-column: 1 / -1; padding: 28px 16px;">
        <div class="m3-empty-icon" style="font-size: 2rem;">🎯</div>
        <div class="m3-empty-title" style="font-size: 0.95rem;">No Financial Goals Yet</div>
        <p class="m3-empty-desc" style="font-size: 0.78rem;">Create savings targets for an emergency fund, dream vacation, gadget upgrade, or home deposit.</p>
        <button type="button" class="m3-filled-btn" id="emptyAddGoalBtn" style="margin-top: 14px; padding: 8px 18px; font-size: 0.8rem;">
          ＋ Create First Goal
        </button>
      </div>
    `;
    document.getElementById('emptyAddGoalBtn')?.addEventListener('click', openAddGoalModal);
    return;
  }

  grid.innerHTML = goals.map(goal => {
    const saved = Number(goal.currentAmount) || 0;
    const target = Number(goal.targetAmount) || 1;
    const pct = Math.min(100, Math.round((saved / target) * 100));
    const isCompleted = saved >= target;
    const remaining = Math.max(0, target - saved);

    let dueText = 'No deadline';
    if (goal.targetDate) {
      const dt = new Date(goal.targetDate);
      if (!isNaN(dt)) {
        dueText = isCompleted ? '✓ Completed' : `By ${dt.toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })}`;
      }
    } else if (isCompleted) {
      dueText = '✓ Completed';
    }

    return `
      <div class="m3-goal-card ${isCompleted ? 'completed' : ''}" data-goal="${goal.id}">
        <div class="m3-goal-header">
          <div class="m3-goal-title-wrap">
            <span class="m3-goal-icon">${goal.icon || '🎯'}</span>
            <span class="m3-goal-name" title="${escapeHtml(goal.name)}">${escapeHtml(goal.name)}</span>
          </div>
          <span class="m3-goal-due ${isCompleted ? 'completed' : ''}">${dueText}</span>
        </div>

        <div class="m3-goal-amounts-row">
          <span class="m3-goal-saved">${inrCompact(saved)}</span>
          <span class="m3-goal-target">Target: ${inrCompact(target)}</span>
        </div>

        <div class="m3-progress-track">
          <div class="m3-progress-indicator" style="width: ${pct}%; background: ${isCompleted ? '#00c853' : 'var(--md-primary)'};"></div>
        </div>

        <div class="m3-goal-footer">
          <span>${pct}% funded</span>
          <span>${isCompleted ? '🎉 Target reached!' : `${inrCompact(remaining)} to go`}</span>
        </div>

        <div class="m3-goal-actions">
          <button type="button" class="m3-goal-contribute-btn" data-contribute-goal="${goal.id}">
            ＋ Add Savings
          </button>
          <button type="button" class="m3-goal-del-btn" data-del-goal="${goal.id}" aria-label="Delete goal" title="Delete goal">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
            </svg>
          </button>
        </div>
      </div>
    `;
  }).join('');

  grid.querySelectorAll('[data-contribute-goal]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      openContributeGoalModal(btn.dataset.contributeGoal);
    });
  });

  grid.querySelectorAll('[data-del-goal]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      triggerHaptic();
      const id = btn.dataset.delGoal;
      const g = goals.find(x => String(x.id) === String(id));
      if (confirm(`Delete savings goal "${g?.name || 'this goal'}"?`)) {
        goals = goals.filter(x => String(x.id) !== String(id));
        saveGoals();
        showToast('Goal deleted.');
        render();
      }
    });
  });
}

function openAddGoalModal() {
  editingGoalId = null;
  selectedGoalIcon = '🛡️';

  const titleEl = document.getElementById('goalModalTitle');
  if (titleEl) titleEl.textContent = 'Create Savings Goal';

  const nameInput = document.getElementById('goalNameInput');
  if (nameInput) nameInput.value = '';

  const targetInput = document.getElementById('goalTargetInput');
  if (targetInput) targetInput.value = '';

  const currentInput = document.getElementById('goalCurrentInput');
  if (currentInput) currentInput.value = '0';

  const dateInput = document.getElementById('goalDateInput');
  if (dateInput) dateInput.value = '';

  renderGoalIconPicker();
  openModal('goalModalBackdrop');
  setTimeout(() => nameInput?.focus(), 120);
}

function renderGoalIconPicker() {
  const picker = document.getElementById('goalIconPicker');
  if (!picker) return;
  picker.querySelectorAll('.m3-icon-choice').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.icon === selectedGoalIcon);
    btn.onclick = () => {
      triggerHaptic();
      selectedGoalIcon = btn.dataset.icon;
      renderGoalIconPicker();
    };
  });
}

function handleSaveGoal(e) {
  e.preventDefault();
  const name = document.getElementById('goalNameInput')?.value.trim();
  const target = parseFloat(document.getElementById('goalTargetInput')?.value);
  const current = parseFloat(document.getElementById('goalCurrentInput')?.value) || 0;
  const targetDate = document.getElementById('goalDateInput')?.value || null;

  if (!name || isNaN(target) || target <= 0) {
    alert('Please enter a goal name and a valid target amount.');
    return;
  }

  triggerHaptic();

  const newGoal = {
    id: editingGoalId || Date.now(),
    name,
    targetAmount: target,
    currentAmount: Math.max(0, current),
    targetDate,
    icon: selectedGoalIcon || '🎯'
  };

  if (editingGoalId) {
    const idx = goals.findIndex(g => g.id === editingGoalId);
    if (idx >= 0) goals[idx] = newGoal;
  } else {
    goals.push(newGoal);
  }

  saveGoals();
  closeModal('goalModalBackdrop');
  showToast(`✓ Savings goal "${name}" saved.`);
  render();
}

function openContributeGoalModal(goalId) {
  contributingGoalId = goalId;
  const goal = goals.find(g => String(g.id) === String(goalId));
  if (!goal) return;

  const titleEl = document.getElementById('contributeModalTitle');
  if (titleEl) titleEl.textContent = `Deposit to ${goal.name}`;

  const metaEl = document.getElementById('contributeGoalMeta');
  if (metaEl) {
    metaEl.textContent = `Current: ${inrCompact(goal.currentAmount)} of ${inrCompact(goal.targetAmount)} (${inrCompact(Math.max(0, goal.targetAmount - goal.currentAmount))} remaining)`;
  }

  const amtInput = document.getElementById('contributeAmountInput');
  if (amtInput) amtInput.value = '';

  document.querySelectorAll('#quickContributeChips .m3-chip-btn').forEach(btn => {
    btn.onclick = () => {
      triggerHaptic();
      if (amtInput) amtInput.value = btn.dataset.add;
    };
  });

  openModal('contributeGoalModalBackdrop');
  setTimeout(() => amtInput?.focus(), 120);
}

function handleSaveContribution(e) {
  e.preventDefault();
  const goal = goals.find(g => String(g.id) === String(contributingGoalId));
  if (!goal) return;

  const amt = parseFloat(document.getElementById('contributeAmountInput')?.value);
  if (isNaN(amt) || amt <= 0) {
    alert('Please enter a valid deposit amount.');
    return;
  }

  triggerHaptic();
  goal.currentAmount = (Number(goal.currentAmount) || 0) + amt;
  saveGoals();
  closeModal('contributeGoalModalBackdrop');

  if (goal.currentAmount >= goal.targetAmount) {
    showToast(`🎉 Congratulations! "${goal.name}" has been 100% funded!`, 4500);
  } else {
    showToast(`✓ Added ${inr(amt)} to "${goal.name}".`);
  }

  render();
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

  // Render Intelligent Detection Suggestions
  renderDetectedSuggestions(metrics);

  const today = new Date().getDate();
  const upcomingTotal = recurringBills
    .filter(b => !b.isPaid)
    .reduce((s, b) => s + b.amount, 0);

  const upcomingDisplay = document.getElementById('upcomingBillsTotalDisplay');
  if (upcomingDisplay) upcomingDisplay.textContent = inr(upcomingTotal);

  const billsList = document.getElementById('recurringBillsList');
  if (billsList) {
    if (recurringBills.length === 0) {
      billsList.innerHTML = `
        <div class="m3-empty-state" style="padding: 24px 16px;">
          <div class="m3-empty-icon" style="font-size: 1.8rem;">📅</div>
          <div class="m3-empty-title" style="font-size: 0.9rem;">No Recurring Bills</div>
          <p class="m3-empty-desc" style="font-size: 0.76rem;">Add recurring subscriptions or bills to track upcoming cycle commitments.</p>
        </div>
      `;
    } else {
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
              <button type="button" class="m3-rec-delete-btn" data-del-bill="${bill.id}" aria-label="Delete bill" title="Delete bill">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                </svg>
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

      billsList.querySelectorAll('[data-del-bill]').forEach(btn => {
        btn.addEventListener('click', (e) => {
          e.stopPropagation();
          triggerHaptic();
          const id = btn.dataset.delBill;
          recurringBills = recurringBills.filter(b => String(b.id) !== String(id));
          saveRecurringBills();
          render();
        });
      });
    }
  }
}

function renderDetectedSuggestions(metrics) {
  const container = document.getElementById('detectedSuggestionsContainer');
  const badge = document.getElementById('detectedCountBadge');
  if (!container) return;

  const suggestions = detectRecurringPatterns(expenses, dismissedPatterns, recurringBills);

  if (badge) {
    badge.textContent = suggestions.length > 0 ? `${suggestions.length} Suggested` : 'Active';
    badge.style.background = suggestions.length > 0 ? 'rgba(0, 200, 83, 0.15)' : 'rgba(101, 88, 211, 0.12)';
    badge.style.color = suggestions.length > 0 ? '#00c853' : '#6558D3';
  }

  if (suggestions.length === 0) {
    container.innerHTML = `
      <div class="m3-detection-idle">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#6558D3" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
        </svg>
        <span>Active cadence engine is monitoring transaction intervals for recurring patterns and subscriptions.</span>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="m3-detected-list">
      ${suggestions.map(s => {
        const cat = CATEGORIES[s.category] || CATEGORIES.bills || { icon: '⚡' };
        const formattedNext = new Date(s.nextDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
        return `
          <div class="m3-detected-item" data-pat="${s.patternKey}">
            <div class="m3-detected-info">
              <div class="m3-detected-title-row">
                <span style="font-size:1.05rem;">${cat.icon}</span>
                <span class="m3-detected-title">${escapeHtml(s.title)}</span>
                <span class="m3-cadence-chip">${s.cadence}</span>
                <span class="m3-confidence-chip ${s.confidence.toLowerCase()}">${s.confidence}</span>
              </div>
              <div class="m3-detected-sub">
                <strong>${inr(s.avgAmount)}</strong> avg (${inrCompact(s.monthlyEquivalent)}/mo) • Next: ${formattedNext} • ${s.occurrences} charges
              </div>
            </div>
            <div class="m3-detected-actions">
              <button type="button" class="m3-keep-btn" data-keep-pat="${s.patternKey}" title="Add to recurring commitments">
                ＋ Keep
              </button>
              <button type="button" class="m3-ignore-btn" data-ignore-pat="${s.patternKey}" title="Ignore and dismiss suggestion">
                ✕ Ignore
              </button>
            </div>
          </div>
        `;
      }).join('')}
    </div>
  `;

  container.querySelectorAll('[data-keep-pat]').forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic();
      const patKey = btn.dataset.keepPat;
      const sugg = suggestions.find(s => s.patternKey === patKey);
      if (sugg) {
        recurringBills.push({
          id: Date.now(),
          title: sugg.title,
          amount: Math.round(sugg.avgAmount),
          dueDay: sugg.dueDay,
          isPaid: false
        });
        saveRecurringBills();
        showToast(`✓ Added "${sugg.title}" to recurring commitments.`);
        render();
      }
    });
  });

  container.querySelectorAll('[data-ignore-pat]').forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic();
      const patKey = btn.dataset.ignorePat;
      if (!dismissedPatterns.includes(patKey)) {
        dismissedPatterns.push(patKey);
        saveDismissedPatterns();
      }
      showToast(`Suggestion ignored and archived.`);
      render();
    });
  });
}

// ── Tab 4: Settings Render ────────────────────────────────────────────────
function renderSettings() {
  const budgetInput = document.getElementById('settingMonthlyBudget');
  if (budgetInput) budgetInput.value = monthlyBudget;

  const cycleInput = document.getElementById('settingCycleStartDay');
  if (cycleInput) cycleInput.value = cycleStartDay;

  const incomeInput = document.getElementById('settingBaseIncome');
  if (incomeInput) incomeInput.value = baseIncome;

  // Net Worth Balance Sheet Settings
  const assetsInput = document.getElementById('settingTotalAssets');
  const liabilitiesInput = document.getElementById('settingTotalLiabilities');
  const nwPreview = document.getElementById('settingNetWorthPreview');

  if (assetsInput && liabilitiesInput && nwPreview) {
    assetsInput.value = (netWorth && netWorth.configured) ? (netWorth.assets || 0) : '';
    liabilitiesInput.value = (netWorth && netWorth.configured) ? (netWorth.liabilities || 0) : '';

    const updateNWPreview = () => {
      const a = parseFloat(assetsInput.value) || 0;
      const l = parseFloat(liabilitiesInput.value) || 0;
      if (assetsInput.value === '' && liabilitiesInput.value === '') {
        nwPreview.textContent = 'Not configured';
        nwPreview.style.color = 'var(--md-on-surface-muted)';
      } else {
        const diff = a - l;
        nwPreview.textContent = inr(diff);
        nwPreview.style.color = diff >= 0 ? '#00c853' : '#ff5252';
      }
    };

    updateNWPreview();
    assetsInput.oninput = updateNWPreview;
    liabilitiesInput.oninput = updateNWPreview;

    const saveNWBtn = document.getElementById('saveNetWorthBtn');
    if (saveNWBtn) {
      saveNWBtn.onclick = () => {
        triggerHaptic();
        const a = parseFloat(assetsInput.value) || 0;
        const l = parseFloat(liabilitiesInput.value) || 0;
        netWorth = {
          assets: a,
          liabilities: l,
          configured: true
        };
        saveNetWorth();
        showToast('✓ Balance sheet saved successfully.');
        render();
      };
    }
  }

  const detectionDesc = document.getElementById('detectionStatusDesc');
  if (detectionDesc) {
    const suggs = detectRecurringPatterns(expenses, dismissedPatterns, recurringBills);
    detectionDesc.textContent = `Cadence active: ${suggs.length} suggested, ${recurringBills.length} confirmed, ${dismissedPatterns.length} ignored.`;
  }

  const restoreBtn = document.getElementById('restoreIgnoredBtn');
  if (restoreBtn) {
    restoreBtn.onclick = () => {
      triggerHaptic();
      if (dismissedPatterns.length === 0) {
        showToast('No ignored suggestions to restore.');
        return;
      }
      const count = dismissedPatterns.length;
      dismissedPatterns = [];
      saveDismissedPatterns();
      showToast(`✓ Restored ${count} previously ignored pattern${count !== 1 ? 's' : ''}.`);
      render();
    };
  }
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

  const expDate = dateStr ? new Date(dateStr + 'T12:00:00').toISOString() : new Date().toISOString();
  const fp = generateFingerprint(expDate, title, amount);

  const newExpense = {
    id: Date.now(),
    title,
    amount,
    category: selectedCategoryModal,
    date: expDate,
    notes,
    fingerprint: fp
  };

  expenses.unshift(newExpense);
  saveExpenses();
  closeModal('modalBackdrop');
  showToast(`✓ Logged ${inr(amount)} for ${title}.`);
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

  document.querySelectorAll('#viewModeSwitcher .m3-mode-icon-btn, #viewModeSwitcher .m3-segment-btn').forEach(btn => {
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

  // Single primary New Entry buttons (Rail FAB on Desktop, Bottom Nav FAB on Mobile)
  const addButtons = [
    document.getElementById('railAddBtn'),
    document.getElementById('mobileAddFab')
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

  // 🎯 Financial Goals Modal Listeners
  const openAddGoalModalBtn = document.getElementById('openAddGoalModalBtn');
  if (openAddGoalModalBtn) {
    openAddGoalModalBtn.addEventListener('click', () => {
      triggerHaptic();
      openAddGoalModal();
    });
  }

  const goalCancelBtn = document.getElementById('goalCancelBtn');
  const goalCloseBtn = document.getElementById('goalCloseBtn');
  [goalCancelBtn, goalCloseBtn].forEach(b => {
    if (b) b.addEventListener('click', () => closeModal('goalModalBackdrop'));
  });

  const goalSaveBtn = document.getElementById('goalSaveBtn');
  if (goalSaveBtn) {
    goalSaveBtn.addEventListener('click', handleSaveGoal);
  }

  const contributeCancelBtn = document.getElementById('contributeCancelBtn');
  const contributeCloseBtn = document.getElementById('contributeCloseBtn');
  [contributeCancelBtn, contributeCloseBtn].forEach(b => {
    if (b) b.addEventListener('click', () => closeModal('contributeGoalModalBackdrop'));
  });

  const contributeSaveBtn = document.getElementById('contributeSaveBtn');
  if (contributeSaveBtn) {
    contributeSaveBtn.addEventListener('click', handleSaveContribution);
  }

  document.querySelectorAll('.m3-scrim-backdrop').forEach(scrim => {
    scrim.addEventListener('click', (e) => {
      if (e.target === scrim) closeModal(scrim.id);
    });
  });

  document.querySelectorAll('.m3-palette-circle').forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic();
      currentPalette = btn.dataset.pal;
      localStorage.setItem(PALETTE_KEY, currentPalette);
      applyPalette();
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
    const iAccount = hdr.findIndex(h => h.includes('account') || h.includes('card') || h.includes('bank') || h.includes('src') || h.includes('source'));

    if (iTitle < 0 && iAmount < 0) {
      alert(`Could not detect required columns.\nHeaders found: ${rawHeader.join(', ')}`);
      return;
    }

    // Build Set of existing fingerprints
    const existingFingerprints = new Set(
      expenses.map(exp => exp.fingerprint || generateFingerprint(exp.date, exp.title, exp.amount, exp.account || ''))
    );

    let insertedCount = 0, duplicateCount = 0, skipped = 0;
    const newItems = [];

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
        const skipIdx = new Set([amtIdx, iDate, iType, iAccount].filter(x => x >= 0));
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
      const account = iAccount >= 0 ? (cols[iAccount] || '').trim() : '';

      const fp = generateFingerprint(date, title, amount, account);

      if (existingFingerprints.has(fp)) {
        duplicateCount++;
        continue;
      }

      existingFingerprints.add(fp);
      newItems.push({
        id: Date.now() + Math.random(),
        title,
        amount,
        category,
        date,
        notes,
        account,
        fingerprint: fp
      });
      insertedCount++;
    }

    if (newItems.length > 0) {
      expenses = [...newItems, ...expenses];
      saveExpenses();
    }

    e.target.value = '';

    const summaryMsg = `✓ CSV Ingestion: ${insertedCount} imported, ${duplicateCount} duplicate${duplicateCount !== 1 ? 's' : ''} skipped${skipped > 0 ? `, ${skipped} unparseable rows` : ''}.`;
    showToast(summaryMsg, 4000);
    alert(summaryMsg);
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
  const dmyAlt = raw.match(/^(\d{1,2})[\.\-](\d{1,2})[\.\-](\d{2,4})$/);
  if (dmyAlt) {
    let [, d, mo, y] = dmyAlt;
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
    version: 6,
    exportedAt: new Date().toISOString(),
    expenses,
    monthlyBudget,
    cycleStartDay,
    baseIncome,
    categoryBudgets,
    recurringBills,
    dismissedPatterns,
    netWorth,
    goals,
    currentPalette
  };

  const jsonStr = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonStr], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `WellSpent_Vault_${new Date().toISOString().split('T')[0]}.wsbackup`;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
  showToast('✓ Vault backup downloaded.');
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
        dismissedPatterns = data.dismissedPatterns || dismissedPatterns;
        netWorth = data.netWorth || netWorth;
        goals = data.goals || goals;
        currentPalette = data.currentPalette || currentPalette;

        // Ensure all restored expenses have fingerprints
        expenses.forEach(exp => {
          if (!exp.fingerprint) {
            exp.fingerprint = generateFingerprint(exp.date, exp.title, exp.amount, exp.account || '');
          }
        });

        saveExpenses();
        saveCategoryBudgets();
        saveRecurringBills();
        saveDismissedPatterns();
        saveNetWorth();
        saveGoals();
        localStorage.setItem(BUDGET_KEY, monthlyBudget);
        localStorage.setItem(CYCLE_START_DAY_KEY, cycleStartDay);
        localStorage.setItem(BASE_INCOME_KEY, baseIncome);
        localStorage.setItem(PALETTE_KEY, currentPalette);

        showToast('✓ Vault backup restored successfully.');
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
