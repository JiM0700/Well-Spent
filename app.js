// Well Spent — Local-first expense tracker | INR | Liquid Glass UI

const STORAGE_KEY          = 'well_spent_expenses_v1';
const BUDGET_KEY           = 'well_spent_budget_v1';
const CYCLE_START_DAY_KEY  = 'well_spent_cycle_start_day_v1';
const BASE_INCOME_KEY      = 'well_spent_base_income_v1';
const PAY_DAY_KEY          = 'well_spent_pay_day_v1';
const SUMMARY_ENABLED_KEY  = 'well_spent_summary_enabled_v1';
const SUMMARY_PERIOD_KEY   = 'well_spent_summary_period_v1';
const VIEW_MODE_KEY        = 'well_spent_view_mode_v1';
const CHART_MODE_KEY       = 'well_spent_chart_mode_v1';
const TAB_KEY              = 'well_spent_current_tab_v1';

const CATEGORY_MAP = {
  food:          { name: 'Food & Dining',    icon: '🍔' },
  transport:     { name: 'Transport',         icon: '🚗' },
  bills:         { name: 'Bills & Utilities', icon: '📄' },
  shopping:      { name: 'Shopping',          icon: '🛍️' },
  healthcare:    { name: 'Healthcare',        icon: '🏥' },
  entertainment: { name: 'Entertainment',     icon: '🎬' },
  invest:        { name: 'Investments',       icon: '💰' },
  other:         { name: 'Other',             icon: '🌐' },
};

// ── Currency Formatter ────────────────────────────────────────────────────────
function inr(amount) {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency', currency: 'INR',
    minimumFractionDigits: 2, maximumFractionDigits: 2,
  }).format(amount);
}

function formatDateShort(dateObj) {
  return dateObj.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
}

function localDateKey(dateObj) {
  const year = dateObj.getFullYear();
  const month = String(dateObj.getMonth() + 1).padStart(2, '0');
  const day = String(dateObj.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function parseLocalDate(value) {
  if (!value) return new Date(NaN);
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    const [year, month, day] = value.split('-').map(Number);
    const result = new Date(year, month - 1, day, 12, 0, 0, 0);
    return result.getFullYear() === year && result.getMonth() === month - 1 && result.getDate() === day
      ? result : new Date(NaN);
  }
  const parsed = new Date(value);
  return parsed;
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, character => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
  }[character]));
}

function loadExpenses() {
  try {
    const stored = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
    if (!Array.isArray(stored)) return [];
    return stored.filter(item => item && typeof item === 'object')
      .map(item => ({
        id: Number(item.id) || Date.now() + Math.random(),
        type: item.type === 'income' ? 'income' : 'expense',
        expenseKind: item.expenseKind === 'fixed' ? 'fixed' : 'variable',
        title: String(item.title || '').trim(),
        amount: Number(item.amount),
        category: CATEGORY_MAP[item.category] ? item.category : 'other',
        date: typeof item.date === 'string' ? item.date : new Date().toISOString(),
        note: item.note ? String(item.note) : '',
      }))
      .filter(item => item.title && Number.isFinite(item.amount) && item.amount > 0 && !Number.isNaN(new Date(item.date).getTime()));
  } catch {
    return [];
  }
}

// ── State ─────────────────────────────────────────────────────────────────────
let expenses = loadExpenses();
if (expenses.length === 0 && !localStorage.getItem(STORAGE_KEY)) expenses = [
  { id: 1, type: 'expense', expenseKind: 'variable', title: 'Groceries',         amount: 850,  category: 'food',      date: new Date().toISOString() },
  { id: 2, type: 'expense', expenseKind: 'fixed',    title: 'Metro Monthly Pass', amount: 400, category: 'transport', date: new Date().toISOString() },
  { id: 3, type: 'expense', expenseKind: 'fixed',    title: 'Electricity Bill',  amount: 1200, category: 'bills',     date: new Date().toISOString() },
];
const storedBudget = parseFloat(localStorage.getItem(BUDGET_KEY));
let monthlyBudget   = Number.isFinite(storedBudget) && storedBudget >= 0 ? storedBudget : 25000;
const storedCycleDay = parseInt(localStorage.getItem(CYCLE_START_DAY_KEY), 10);
let cycleStartDay   = Number.isInteger(storedCycleDay) && storedCycleDay >= 1 && storedCycleDay <= 28 ? storedCycleDay : 1;
const storedBaseIncome = parseFloat(localStorage.getItem(BASE_INCOME_KEY));
let baseMonthlyIncome = Number.isFinite(storedBaseIncome) && storedBaseIncome >= 0 ? storedBaseIncome : 0;
const storedPayDay = parseInt(localStorage.getItem(PAY_DAY_KEY), 10);
let payDay = Number.isInteger(storedPayDay) && storedPayDay >= 1 && storedPayDay <= 28 ? storedPayDay : 1;
let summaryEnabled = localStorage.getItem(SUMMARY_ENABLED_KEY) !== 'false';
let summaryPeriod = ['daily', 'weekly', 'monthly'].includes(localStorage.getItem(SUMMARY_PERIOD_KEY))
  ? localStorage.getItem(SUMMARY_PERIOD_KEY) : 'daily';
let currentViewMode = localStorage.getItem(VIEW_MODE_KEY) || 'monthly'; // 'weekly' | 'monthly' | 'yearly'
let currentChartMode = localStorage.getItem(CHART_MODE_KEY) || 'daywise';
let currentTab = localStorage.getItem(TAB_KEY) || 'overview';
let currentFilter   = 'all';
let currentTypeFilter = 'all';
let currentKindFilter = 'all';
let currentSearchQuery = '';

function save() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(expenses));
  localStorage.setItem(BUDGET_KEY, monthlyBudget.toString());
  localStorage.setItem(CYCLE_START_DAY_KEY, cycleStartDay.toString());
  localStorage.setItem(BASE_INCOME_KEY, baseMonthlyIncome.toString());
  localStorage.setItem(PAY_DAY_KEY, payDay.toString());
  localStorage.setItem(SUMMARY_ENABLED_KEY, String(summaryEnabled));
  localStorage.setItem(SUMMARY_PERIOD_KEY, summaryPeriod);
  localStorage.setItem(VIEW_MODE_KEY, currentViewMode);
  localStorage.setItem(CHART_MODE_KEY, currentChartMode);
  localStorage.setItem(TAB_KEY, currentTab);
  render();
}

// ── Complete Precedence Math Evaluator ─────────────────────────────────────────
function evalMath(expr) {
  if (typeof expr !== 'string') return null;
  const str = expr.trim();
  if (!str || /[^0-9.+\-*/()\s]/.test(str)) return null;

  let pos = 0;
  function peek() {
    while (pos < str.length && str[pos] === ' ') pos++;
    return pos < str.length ? str[pos] : null;
  }

  function parsePrimary() {
    const ch = peek();
    if (ch === null) throw new Error('Unexpected end');
    if (ch === '(') {
      pos++; // consume '('
      const val = parseAddSub();
      if (peek() !== ')') throw new Error('Expected )');
      pos++; // consume ')'
      return val;
    }
    if (ch === '+' || ch === '-') {
      pos++;
      const val = parsePrimary();
      return ch === '+' ? val : -val;
    }
    const start = pos;
    while (pos < str.length && (/[0-9.]/).test(str[pos])) pos++;
    if (start === pos) throw new Error('Expected number');
    const numStr = str.substring(start, pos);
    const num = parseFloat(numStr);
    if (Number.isNaN(num)) throw new Error('Invalid number');
    return num;
  }

  function parseMulDiv() {
    let left = parsePrimary();
    while (true) {
      const ch = peek();
      if (ch === '*' || ch === '/') {
        pos++;
        const right = parsePrimary();
        if (ch === '*') left = left * right;
        else {
          if (right === 0) throw new Error('Division by zero');
          left = left / right;
        }
      } else {
        break;
      }
    }
    return left;
  }

  function parseAddSub() {
    let left = parseMulDiv();
    while (true) {
      const ch = peek();
      if (ch === '+' || ch === '-') {
        pos++;
        const right = parseMulDiv();
        if (ch === '+') left = left + right;
        else left = left - right;
      } else {
        break;
      }
    }
    return left;
  }

  try {
    const result = parseAddSub();
    peek();
    if (pos < str.length) return null;
    return Number.isFinite(result) && result > 0 ? result : null;
  } catch {
    return null;
  }
}

// ── Period & Cycle Date Calculator ───────────────────────────────────────────
function getCurrentPeriodRange(now = new Date()) {
  const y = now.getFullYear();
  const m = now.getMonth();
  const d = now.getDate();

  if (currentViewMode === 'weekly') {
    const dayOfWeek = now.getDay(); // 0=Sun, 1=Mon...
    const diffToMon = (dayOfWeek === 0 ? -6 : 1 - dayOfWeek);
    const startDate = new Date(y, m, d + diffToMon, 0, 0, 0, 0);
    const endDate   = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + 6, 23, 59, 59, 999);
    return {
      startDate, endDate,
      targetBudget: monthlyBudget / 4.33,
      label: `Weekly (${formatDateShort(startDate)} – ${formatDateShort(endDate)})`,
      modeName: 'Weekly'
    };
  }

  if (currentViewMode === 'yearly') {
    const startDate = new Date(y, 0, 1, 0, 0, 0, 0);
    const endDate   = new Date(y, 11, 31, 23, 59, 59, 999);
    return {
      startDate, endDate,
      targetBudget: monthlyBudget * 12,
      label: `Annual (${y})`,
      modeName: 'Yearly'
    };
  }

  // Monthly mode (respecting custom cycleStartDay)
  let startDate, endDate;
  if (cycleStartDay === 1) {
    startDate = new Date(y, m, 1, 0, 0, 0, 0);
    endDate   = new Date(y, m + 1, 0, 23, 59, 59, 999);
  } else {
    if (d >= cycleStartDay) {
      startDate = new Date(y, m, cycleStartDay, 0, 0, 0, 0);
      endDate   = new Date(y, m + 1, cycleStartDay - 1, 23, 59, 59, 999);
    } else {
      startDate = new Date(y, m - 1, cycleStartDay, 0, 0, 0, 0);
      endDate   = new Date(y, m, cycleStartDay - 1, 23, 59, 59, 999);
    }
  }

  const startDayOrdinal = cycleStartDay === 1 ? '1st' : cycleStartDay === 2 ? '2nd' : cycleStartDay === 3 ? '3rd' : `${cycleStartDay}th`;
  return {
    startDate, endDate,
    targetBudget: monthlyBudget,
    label: `Monthly Cycle (${formatDateShort(startDate)} – ${formatDateShort(endDate)})`,
    modeName: 'Monthly',
    startDayOrdinal
  };
}

function getRecurringIncomeForRange(range) {
  if (baseMonthlyIncome <= 0) return 0;
  if (currentViewMode === 'weekly') return baseMonthlyIncome / 4.33;
  if (currentViewMode === 'yearly') return baseMonthlyIncome * 12;
  return baseMonthlyIncome;
}

// ── Period Forecast Engine ────────────────────────────────────────────────────
function calculatePeriodForecast() {
  const now = new Date();
  const range = getCurrentPeriodRange(now);

  const periodExp = expenses.filter(e => {
    const ed = new Date(e.date);
    return e.type === 'expense' && ed >= range.startDate && ed <= range.endDate;
  });
  const periodIncome = expenses.filter(e => {
    const ed = new Date(e.date);
    return e.type === 'income' && ed >= range.startDate && ed <= range.endDate;
  });

  const periodTotal = periodExp.reduce((s, e) => s + e.amount, 0);
  const fixedTotal = periodExp.filter(e => e.expenseKind === 'fixed').reduce((s, e) => s + e.amount, 0);
  const variableTotal = periodTotal - fixedTotal;
  const oneOffIncome = periodIncome.reduce((s, e) => s + e.amount, 0);
  const recurringIncome = getRecurringIncomeForRange(range);
  const totalIncome = recurringIncome + oneOffIncome;

  const totalMs      = range.endDate.getTime() - range.startDate.getTime() + 1;
  const totalDays    = Math.max(1, Math.round(totalMs / (1000 * 60 * 60 * 24)));
  const elapsedMs    = Math.max(1, now.getTime() - range.startDate.getTime());
  const daysElapsed  = Math.min(totalDays, Math.max(1, Math.ceil(elapsedMs / (1000 * 60 * 60 * 24))));
  const daysLeft     = Math.max(0, totalDays - daysElapsed);

  const velocity     = periodTotal / daysElapsed;
  const projected    = periodTotal + (velocity * daysLeft);
  const safeBurn     = calculateSafeBurnRate(now);

  const todayStr     = localDateKey(now);
  const todayTotal   = expenses
    .filter(e => e.type === 'expense' && localDateKey(new Date(e.date)) === todayStr)
    .reduce((s, e) => s + e.amount, 0);

  return {
    range,
    periodTotal,
    fixedTotal,
    variableTotal,
    periodExp,
    periodIncome,
    recurringIncome,
    oneOffIncome,
    totalIncome,
    todayTotal,
    velocity,
    safeBurn,
    projected,
    daysLeft,
    totalDays,
    daysElapsed
  };
}

function getSummaryWindow(mode, now = new Date()) {
  const startOfDay = date => new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0, 0);
  const endOfDay   = date => new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999);

  let currentStart, currentEnd, previousStart, previousEnd;

  if (mode === 'daily') {
    currentStart  = startOfDay(now);
    currentEnd    = endOfDay(now);
    previousStart = startOfDay(new Date(currentStart.getFullYear(), currentStart.getMonth(), currentStart.getDate() - 1));
    previousEnd   = endOfDay(previousStart);
  } else if (mode === 'weekly') {
    const dayOfWeek = now.getDay();
    const daysSinceMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    currentStart  = startOfDay(new Date(now.getFullYear(), now.getMonth(), now.getDate() - daysSinceMonday));
    currentEnd    = endOfDay(new Date(currentStart.getFullYear(), currentStart.getMonth(), currentStart.getDate() + 6));
    previousStart = startOfDay(new Date(currentStart.getFullYear(), currentStart.getMonth(), currentStart.getDate() - 7));
    previousEnd   = endOfDay(new Date(previousStart.getFullYear(), previousStart.getMonth(), previousStart.getDate() + 6));
  } else {
    const period  = getCurrentPeriodRange(now);
    currentStart  = startOfDay(period.startDate);
    currentEnd    = endOfDay(period.endDate);
    const msDiff  = currentEnd.getTime() - currentStart.getTime();
    const daysInPeriod = Math.max(1, Math.round(msDiff / (1000 * 60 * 60 * 24)));
    previousEnd   = new Date(currentStart.getTime() - 1);
    previousStart = startOfDay(new Date(previousEnd.getFullYear(), previousEnd.getMonth(), previousEnd.getDate() - daysInPeriod + 1));
  }

  return { currentStart, currentEnd, previousStart, previousEnd };
}

function getSummaryStats(mode) {
  const window = getSummaryWindow(mode);
  const totalBetween = (start, end) => expenses
    .filter(entry => entry.type === 'expense' && new Date(entry.date) >= start && new Date(entry.date) <= end)
    .reduce((sum, entry) => sum + entry.amount, 0);
  const currentEntries = expenses.filter(entry => {
    const date = new Date(entry.date);
    return entry.type === 'expense' && date >= window.currentStart && date <= window.currentEnd;
  });
  const total = currentEntries.reduce((sum, entry) => sum + entry.amount, 0);
  const previousTotal = totalBetween(window.previousStart, window.previousEnd);
  const categoryTotals = {};
  currentEntries.forEach(entry => {
    categoryTotals[entry.category] = (categoryTotals[entry.category] || 0) + entry.amount;
  });
  const topCategoryKey = Object.keys(categoryTotals).sort((a, b) => categoryTotals[b] - categoryTotals[a])[0];
  const topCategory = topCategoryKey && categoryTotals[topCategoryKey] > 0
    ? `${CATEGORY_MAP[topCategoryKey].icon} ${CATEGORY_MAP[topCategoryKey].name}` : 'No spending yet';
  const difference = previousTotal === 0 ? (total > 0 ? null : 0) : ((total - previousTotal) / previousTotal) * 100;
  return { ...window, total, previousTotal, difference, topCategory };
}

function renderSpendingSummary() {
  const card = document.getElementById('spendingSummaryCard');
  if (!card) return;
  card.hidden = !summaryEnabled;
  if (!summaryEnabled) return;

  const stats = getSummaryStats(summaryPeriod);
  const labels = { daily: 'Today', weekly: 'This Week', monthly: 'This Cycle' };
  setText('summaryPeriodLabel', labels[summaryPeriod]);
  setText('summaryTotalDisplay', inr(stats.total));
  setText('summaryTopCategory', stats.topCategory);

  if (summaryPeriod === 'daily') {
    setText('summaryRangeLabel', formatDateShort(stats.currentStart));
  } else {
    setText('summaryRangeLabel', `${formatDateShort(stats.currentStart)} – ${formatDateShort(stats.currentEnd)}`);
  }

  const differenceEl = document.getElementById('summaryDifference');
  if (differenceEl) {
    differenceEl.classList.remove('summary-difference--up', 'summary-difference--down');
    if (stats.difference === null) {
      differenceEl.textContent = 'New spending vs previous period';
      differenceEl.classList.add('summary-difference--up');
    } else if (stats.difference === 0) {
      differenceEl.textContent = '— 0% vs previous period';
    } else {
      const increase = stats.difference > 0;
      differenceEl.textContent = `${increase ? '↑' : '↓'} ${Math.abs(stats.difference).toFixed(0)}% vs previous period`;
      differenceEl.classList.add(increase ? 'summary-difference--up' : 'summary-difference--down');
    }
  }
  document.querySelectorAll('#summaryPeriodSwitcher .summary-period-btn').forEach(button => {
    const active = button.dataset.summaryPeriod === summaryPeriod;
    button.classList.toggle('active', active);
    button.setAttribute('aria-pressed', String(active));
  });
}

function getPaydayDate(year, month, day) {
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  return new Date(year, month, Math.min(day, daysInMonth), 0, 0, 0, 0);
}

function calculateSafeBurnRate(now = new Date()) {
  const thisPayday = getPaydayDate(now.getFullYear(), now.getMonth(), payDay);
  const lastPayday = now >= thisPayday
    ? thisPayday
    : getPaydayDate(now.getFullYear(), now.getMonth() - 1, payDay);
  const nextPayday = now < thisPayday
    ? thisPayday
    : getPaydayDate(now.getFullYear(), now.getMonth() + 1, payDay);
  const daysUntilPayday = Math.max(1, Math.ceil((nextPayday - now) / (1000 * 60 * 60 * 24)));

  const incomeSincePayday = expenses
    .filter(e => e.type === 'income' && new Date(e.date) >= lastPayday && new Date(e.date) <= now)
    .reduce((sum, e) => sum + e.amount, 0) + (baseMonthlyIncome > 0 ? baseMonthlyIncome : 0);
  const expensesSincePayday = expenses
    .filter(e => e.type === 'expense' && new Date(e.date) >= lastPayday && new Date(e.date) <= now)
    .reduce((sum, e) => sum + e.amount, 0);
  const remainingIncome = Math.max(0, incomeSincePayday - expensesSincePayday);

  return {
    amount: remainingIncome / daysUntilPayday,
    daysUntilPayday,
    remainingIncome,
    nextPayday,
  };
}

// ── Main Render Engine ────────────────────────────────────────────────────────
function render() {
  const fc = calculatePeriodForecast();
  const range = fc.range;
  const remaining = range.targetBudget - fc.periodTotal;
  const netRemaining = fc.totalIncome - fc.periodTotal;
  const savingsRate = fc.totalIncome > 0 ? (netRemaining / fc.totalIncome) * 100 : null;

  // ── Tab Navigation State UI ───────────────────────────────────────────────
  document.querySelectorAll('.pwa-tab-btn').forEach(btn => {
    const isSelected = btn.dataset.tab === currentTab;
    btn.classList.toggle('active', isSelected);
    btn.setAttribute('aria-pressed', String(isSelected));
  });

  document.querySelectorAll('.tab-view').forEach(view => {
    view.style.display = view.id === `tab${currentTab.charAt(0).toUpperCase() + currentTab.slice(1)}` ? 'block' : 'none';
  });

  // ── Mode Switcher UI ──────────────────────────────────────────────────────
  document.querySelectorAll('#viewModeSwitcher .segment-btn').forEach(btn => {
    const isSelected = btn.dataset.mode === currentViewMode;
    btn.classList.toggle('active', isSelected);
    btn.setAttribute('aria-pressed', isSelected ? 'true' : 'false');
  });

  // ── Header Summary Card ───────────────────────────────────────────────────
  setText('heroEyebrow', `${range.modeName} Cycle`);
  setText('heroCycleDate', `${formatDateShort(range.startDate)} – ${formatDateShort(range.endDate)}`);
  setText('monthlyTotalDisplay', inr(fc.periodTotal));
  setText('monthlyBudgetDisplay', inr(range.targetBudget));
  const cycleInfo = document.getElementById('cycleInfo');
  if (cycleInfo) {
    const details = `Budget remaining: ${inr(remaining)} · Income: ${inr(fc.totalIncome)} · Net saved: ${inr(netRemaining)} · Fixed: ${inr(fc.fixedTotal)} · Variable: ${inr(fc.variableTotal)}${savingsRate === null ? '' : ` · Savings rate: ${savingsRate.toFixed(0)}%`}`;
    cycleInfo.dataset.tooltip = details;
    cycleInfo.title = details;
  }

  // Progress Bar & Glow Knob
  const pct = Math.min(100, Math.max(0, range.targetBudget > 0 ? (fc.periodTotal / range.targetBudget) * 100 : 0));
  const fill = document.getElementById('budgetProgressBar');
  const glow = document.getElementById('budgetProgressGlow');
  const bar  = document.getElementById('progressBar');
  if (fill) {
    fill.style.width      = `${pct}%`;
    fill.style.background = pct > 90
      ? 'linear-gradient(135deg,#ef4444,#b91c1c)'
      : 'linear-gradient(135deg,#3b82f6,#1d4ed8)';
  }
  if (glow) glow.style.left = `${pct}%`;
  if (bar)  bar.setAttribute('aria-valuenow', pct.toFixed(0));

  setText('progressSpentLabel', `${inr(fc.periodTotal)} spent`);
  setText('progressPct', `${pct.toFixed(0)}% used`);

  // ── Forecast Card ─────────────────────────────────────────────────────────
  setText('daysLeftChip', `${fc.daysLeft} days left`);

  const projEl = document.getElementById('projectedTotalDisplay');
  if (projEl) {
    projEl.textContent = inr(fc.projected);
    projEl.style.color = fc.projected > range.targetBudget ? 'var(--text-danger)' : '#60a5fa';
  }
  setText('dailyVelocityDisplay', `${inr(fc.velocity)} / day`);
  setText('safeBurnDisplay', `${inr(fc.safeBurn.amount)} / day`);
  setText('safeBurnMeta', `${fc.safeBurn.daysUntilPayday} days until payday · ${inr(fc.safeBurn.remainingIncome)} available income`);

  const statusEl = document.getElementById('forecastStatusMsg');
  if (statusEl) {
    if (fc.projected > range.targetBudget && range.targetBudget > 0) {
      statusEl.textContent = `⚠️ On track to exceed ${range.modeName.toLowerCase()} budget by ${inr(fc.projected - range.targetBudget)}`;
      statusEl.style.color = 'var(--text-danger)';
    } else {
      statusEl.textContent = `✨ On pace! Projected to save ${inr(range.targetBudget - fc.projected)} this ${range.modeName.toLowerCase()}.`;
      statusEl.style.color = '#93c5fd';
    }
  }

  // ── Category Breakdown ────────────────────────────────────────────────────
  renderBreakdown(fc.periodTotal, fc.periodExp);
  renderChart(fc);

  // ── Transactions List & Categories Grid ──────────────────────────────────
  renderSpendingSummary();
  renderTransactions();
  renderCategoryGrid(fc);
  renderInsightsTab(fc);
  populateSettingsForm();
}

// ── Render Interactive Category Grid (Categories Tab) ────────────────────────
function renderCategoryGrid(fc) {
  const container = document.getElementById('categoriesGridContainer');
  if (!container) return;
  container.innerHTML = '';
  setText('catTabPeriodLabel', `${formatDateShort(fc.range.startDate)} – ${formatDateShort(fc.range.endDate)}`);

  const categoryTotals = {};
  const categoryCounts = {};
  Object.keys(CATEGORY_MAP).forEach(cat => {
    categoryTotals[cat] = 0;
    categoryCounts[cat] = 0;
  });

  fc.periodExp.forEach(e => {
    if (CATEGORY_MAP[e.category]) {
      categoryTotals[e.category] += e.amount;
      categoryCounts[e.category] += 1;
    }
  });

  Object.keys(CATEGORY_MAP).forEach(catKey => {
    const cat = CATEGORY_MAP[catKey];
    const total = categoryTotals[catKey];
    const count = categoryCounts[catKey];
    const pct = fc.periodTotal > 0 ? ((total / fc.periodTotal) * 100).toFixed(1) : '0';

    const card = document.createElement('div');
    card.className = 'category-card';
    card.setAttribute('role', 'button');
    card.setAttribute('tabindex', '0');
    card.onclick = () => openCategoryDetailModal(catKey);
    card.onkeydown = e => { if (e.key === 'Enter' || e.key === ' ') openCategoryDetailModal(catKey); };

    card.innerHTML = `
      <div class="category-card__head">
        <div class="category-card__icon">${cat.icon}</div>
        <span class="category-card__count">${count} ${count === 1 ? 'entry' : 'entries'}</span>
      </div>
      <div>
        <div class="category-card__name">${cat.name}</div>
        <div class="category-card__amount">${inr(total)}</div>
      </div>
      <div class="cat-bar" style="margin-top: 4px;">
        <div class="cat-fill" style="width:${pct}%; background: var(--accent);"></div>
      </div>
    `;
    container.appendChild(card);
  });
}

// ── Open Category Detail Modal ────────────────────────────────────────────────
function openCategoryDetailModal(catKey) {
  const cat = CATEGORY_MAP[catKey];
  if (!cat) return;
  const fc = calculatePeriodForecast();
  const catExpenses = fc.periodExp.filter(e => e.category === catKey);
  const total = catExpenses.reduce((s, e) => s + e.amount, 0);

  setText('catDetailModalTitle', `${cat.icon} ${cat.name}`);

  const content = document.getElementById('catDetailContent');
  if (!content) return;

  let html = `
    <div style="background: rgba(255,255,255,0.05); padding: 16px; border-radius: 16px; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center;">
      <div>
        <p style="font-size: 0.8rem; color: var(--text-secondary);">Spent this period</p>
        <p style="font-size: 1.6rem; font-weight: 800; color: var(--text);">${inr(total)}</p>
      </div>
      <span style="font-size: 0.9rem; font-weight: 700; color: var(--text-secondary);">${catExpenses.length} transaction${catExpenses.length === 1 ? '' : 's'}</span>
    </div>
    <div class="tx-list" style="max-height: 350px; overflow-y: auto;">
  `;

  if (catExpenses.length === 0) {
    html += '<div class="empty-msg">No transactions recorded in this category for this period.</div>';
  } else {
    catExpenses.forEach(exp => {
      const dateStr = new Date(exp.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
      html += `
        <div class="tx-item">
          <div class="tx-left">
            <div class="tx-icon">${cat.icon}</div>
            <div class="tx-info">
              <div class="tx-title">${escapeHtml(exp.title)}</div>
              <div class="tx-meta">${exp.expenseKind === 'fixed' ? 'Fixed' : 'Variable'} &bull; ${dateStr}</div>
            </div>
          </div>
          <div class="tx-right">
            <span class="tx-amount">&minus;${inr(exp.amount)}</span>
          </div>
        </div>
      `;
    });
  }

  html += '</div>';
  content.innerHTML = html;
  document.getElementById('categoryDetailModalBackdrop').classList.add('active');
}

function closeCategoryDetailModal() {
  document.getElementById('categoryDetailModalBackdrop').classList.remove('active');
}

// ── Render Insights Tab Analytics ─────────────────────────────────────────────
function renderInsightsTab(fc) {
  setText('insRecurringIncome', inr(fc.recurringIncome));
  setText('insOneOffIncome', inr(fc.oneOffIncome));
  setText('insTotalIncome', inr(fc.totalIncome));
  setText('insTotalExpenses', inr(fc.periodTotal));
  const netSaved = fc.totalIncome - fc.periodTotal;
  const netSavedEl = document.getElementById('insNetSavings');
  if (netSavedEl) {
    netSavedEl.textContent = inr(netSaved);
    netSavedEl.style.color = netSaved >= 0 ? 'var(--text-success)' : 'var(--text-danger)';
  }

  setText('insDaysElapsed', `${fc.daysElapsed} / ${fc.totalDays} days`);
  setText('insDailyVelocity', `${inr(fc.velocity)} / day`);
  setText('insSafeBurn', `${inr(fc.safeBurn.amount)} / day`);
  setText('insProjectedEnd', inr(fc.projected));

  setText('insFixedExpenses', inr(fc.fixedTotal));
  setText('insVariableExpenses', inr(fc.variableTotal));
}

// ── Settings Form Auto-populate ───────────────────────────────────────────────
function populateSettingsForm() {
  const baseIncEl = document.getElementById('tabSettingBaseIncome');
  if (baseIncEl && document.activeElement !== baseIncEl) baseIncEl.value = baseMonthlyIncome || '';
  const payDayEl = document.getElementById('tabSettingPayDay');
  if (payDayEl && document.activeElement !== payDayEl) payDayEl.value = payDay;
  const budgetEl = document.getElementById('tabSettingMonthlyBudget');
  if (budgetEl && document.activeElement !== budgetEl) budgetEl.value = monthlyBudget;
  const cycleDayEl = document.getElementById('tabSettingCycleStartDay');
  if (cycleDayEl && document.activeElement !== cycleDayEl) cycleDayEl.value = cycleStartDay;
  const summaryEl = document.getElementById('tabSettingSummaryEnabled');
  if (summaryEl) summaryEl.checked = summaryEnabled;
}

function renderChart(forecast) {
  const svg = document.getElementById('chartSvg');
  if (!svg) return;

  document.querySelectorAll('#chartModeToggle .cchip').forEach(btn => {
    const active = btn.dataset.chartmode === currentChartMode;
    btn.classList.toggle('active', active);
    btn.setAttribute('aria-pressed', String(active));
  });

  const points = [];
  if (currentChartMode === 'monthwise') {
    const now = new Date();
    for (let offset = 11; offset >= 0; offset -= 1) {
      const date = new Date(now.getFullYear(), now.getMonth() - offset, 1);
      const next = new Date(date.getFullYear(), date.getMonth() + 1, 1);
      const amount = expenses.filter(exp => {
        const value = new Date(exp.date);
        return exp.type === 'expense' && value >= date && value < next;
      }).reduce((sum, exp) => sum + exp.amount, 0);
      points.push({ label: date.toLocaleDateString('en-IN', { month: 'short' }), amount, date: date.toISOString() });
    }
  } else {
    const { startDate, endDate } = forecast.range;
    const day = new Date(startDate);
    while (day <= endDate) {
      const key = localDateKey(day);
      const amount = forecast.periodExp.filter(exp => localDateKey(new Date(exp.date)) === key)
        .reduce((sum, exp) => sum + exp.amount, 0);
      points.push({ label: day.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }), amount, date: day.toISOString() });
      day.setDate(day.getDate() + 1);
    }
  }

  const width = 600, height = 200, pad = { top: 18, right: 16, bottom: 34, left: 46 };
  const chartWidth = width - pad.left - pad.right;
  const chartHeight = height - pad.top - pad.bottom;
  const max = Math.max(...points.map(point => point.amount), 1);
  const x = index => pad.left + (points.length === 1 ? chartWidth / 2 : (index / (points.length - 1)) * chartWidth);
  const y = amount => pad.top + chartHeight - (amount / max) * chartHeight;
  const line = points.map((point, index) => `${x(index).toFixed(1)},${y(point.amount).toFixed(1)}`).join(' ');
  const area = `${pad.left},${pad.top + chartHeight} ${line} ${pad.left + chartWidth},${pad.top + chartHeight}`;
  const labels = points.map((point, index) => {
    const every = Math.max(1, Math.ceil(points.length / 7));
    return index % every === 0 || index === points.length - 1
      ? `<text x="${x(index)}" y="${height - 10}" text-anchor="middle">${point.label}</text>` : '';
  }).join('');
  const circles = points.map((point, index) => `<circle class="chart-point" cx="${x(index)}" cy="${y(point.amount)}" r="4" tabindex="0" data-index="${index}" aria-label="${point.label}: ${inr(point.amount)}" />`).join('');
  const grid = [0, 0.5, 1].map(ratio => {
    const lineY = pad.top + chartHeight - ratio * chartHeight;
    return `<line class="chart-grid" x1="${pad.left}" y1="${lineY}" x2="${pad.left + chartWidth}" y2="${lineY}" />`;
  }).join('');
  svg.innerHTML = `${grid}<polygon class="chart-area" points="${area}" /><polyline class="chart-line" points="${line}" />${circles}${labels}`;

  const total = points.reduce((sum, point) => sum + point.amount, 0);
  const peak = points.reduce((best, point) => point.amount > best.amount ? point : best, points[0] || { label: '—', amount: 0 });
  setText('chartPeakLabel', `Peak: ${peak.label} · ${inr(peak.amount)}`);
  setText('chartAvgLabel', `Average: ${inr(points.length ? total / points.length : 0)}`);
  setText('chartTotalLabel', `Total: ${inr(total)}`);
  svg.querySelectorAll('.chart-point').forEach(point => {
    const show = () => {
      const data = points[Number(point.dataset.index)];
      const tooltip = document.getElementById('chartTooltip');
      tooltip.textContent = `${data.label}: ${inr(data.amount)}`;
      tooltip.setAttribute('aria-hidden', 'false');
      tooltip.style.left = `${(Number(point.getAttribute('cx')) / width) * 100}%`;
      tooltip.style.top = `${(Number(point.getAttribute('cy')) / height) * 100}%`;
    };
    point.addEventListener('mouseenter', show);
    point.addEventListener('focus', show);
    point.addEventListener('mouseleave', () => document.getElementById('chartTooltip').setAttribute('aria-hidden', 'true'));
    point.addEventListener('blur', () => document.getElementById('chartTooltip').setAttribute('aria-hidden', 'true'));
  });
}

// ── Category Breakdown Bars ──────────────────────────────────────────────────
function renderBreakdown(periodTotal, periodExp) {
  const el = document.getElementById('categoryBreakdownList');
  if (!el) return;
  el.innerHTML = '';

  const totals = {};
  Object.keys(CATEGORY_MAP).forEach(k => (totals[k] = 0));

  periodExp.forEach(e => {
    if (CATEGORY_MAP[e.category]) totals[e.category] = (totals[e.category] || 0) + e.amount;
  });

  if (periodTotal === 0) {
    el.innerHTML = '<div class="empty-msg">No expenses recorded in this period yet.</div>';
    return;
  }

  let hasAny = false;
  Object.keys(CATEGORY_MAP).forEach(key => {
    const amt = totals[key];
    if (amt <= 0) return;
    hasAny = true;
    const pct = ((amt / periodTotal) * 100).toFixed(1);
    const cat = CATEGORY_MAP[key];
    const row = document.createElement('div');
    row.className = 'cat-row';
    row.style.cursor = 'pointer';
    row.onclick = () => openCategoryDetailModal(key);
    row.innerHTML = `
      <div class="cat-meta">
        <span class="cat-name">${cat.icon} ${cat.name}</span>
        <span class="cat-right">
          <span class="cat-amt">${inr(amt)}</span>
          <span class="cat-pct">${pct}%</span>
        </span>
      </div>
      <div class="cat-bar">
        <div class="cat-fill" data-cat="${key}" style="width:${pct}%"></div>
      </div>
    `;
    el.appendChild(row);
  });

  if (!hasAny) {
    el.innerHTML = '<div class="empty-msg">No expenses in this period yet.</div>';
  }
}

// ── Transaction Feed List with Multi-Filter ──────────────────────────────────
function renderTransactions() {
  const el = document.getElementById('transactionsList');
  if (!el) return;
  el.innerHTML = '';

  let filtered = expenses;

  // Filter by Search Query
  if (currentSearchQuery.trim()) {
    const q = currentSearchQuery.trim().toLowerCase();
    filtered = filtered.filter(e =>
      e.title.toLowerCase().includes(q) ||
      (e.note && e.note.toLowerCase().includes(q)) ||
      (CATEGORY_MAP[e.category] && CATEGORY_MAP[e.category].name.toLowerCase().includes(q))
    );
  }

  // Filter by Type
  if (currentTypeFilter !== 'all') {
    filtered = filtered.filter(e => e.type === currentTypeFilter);
  }

  // Filter by Kind
  if (currentKindFilter !== 'all') {
    filtered = filtered.filter(e => e.type === 'expense' && e.expenseKind === currentKindFilter);
  }

  // Filter by Category
  if (currentFilter !== 'all') {
    filtered = filtered.filter(e => e.category === currentFilter);
  }

  const countEl = document.getElementById('txCount');
  if (countEl) countEl.textContent = `${filtered.length} ${filtered.length === 1 ? 'entry' : 'entries'}`;

  if (filtered.length === 0) {
    el.innerHTML = '<div class="empty-msg">No matching entries found.</div>';
    return;
  }

  filtered.forEach(exp => {
    const isIncome = exp.type === 'income';
    const cat     = isIncome ? { name: 'Income', icon: '💵' } : (CATEGORY_MAP[exp.category] || CATEGORY_MAP.other);
    const kindLabel = isIncome ? 'Income' : (exp.expenseKind === 'fixed' ? 'Fixed' : 'Variable');
    const dateStr = new Date(exp.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });

    const item = document.createElement('div');
    item.className = 'tx-item';
    item.innerHTML = `
      <div class="tx-left">
        <div class="tx-icon">${cat.icon}</div>
        <div class="tx-info">
          <div class="tx-title">${escapeHtml(exp.title)}</div>
          <div class="tx-meta">${kindLabel} · ${cat.name} &bull; ${dateStr}</div>
        </div>
      </div>
      <div class="tx-right">
        <span class="tx-amount ${isIncome ? 'tx-amount--income' : ''}">${isIncome ? '+' : '&minus;'}${inr(exp.amount)}</span>
        <button class="tx-delete" onclick="deleteExpense(${exp.id})" title="Delete" aria-label="Delete ${isIncome ? 'income' : 'expense'}">🗑️</button>
      </div>
    `;
    el.appendChild(item);
  });
}

// ── Global Delete ────────────────────────────────────────────────────────────
window.deleteExpense = id => {
  expenses = expenses.filter(e => e.id !== id);
  save();
};

// ── Modal Helpers ────────────────────────────────────────────────────────────
function openModal() {
  document.getElementById('expDate').value = localDateKey(new Date());
  setEntryType('expense');
  document.querySelectorAll('#expenseKindSwitcher .entry-kind-btn').forEach(button => {
    const active = button.dataset.expenseKind === 'variable';
    button.classList.toggle('active', active);
    button.setAttribute('aria-pressed', String(active));
  });
  document.getElementById('expenseKind').value = 'variable';
  document.getElementById('modalBackdrop').classList.add('active');
  setTimeout(() => document.getElementById('expTitle').focus(), 80);
}

function closeModal() {
  document.getElementById('modalBackdrop').classList.remove('active');
}

function openSettingsModal() {
  document.getElementById('settingMonthlyBudget').value = monthlyBudget;
  document.getElementById('settingCycleStartDay').value = cycleStartDay;
  document.getElementById('settingBaseIncome').value = baseMonthlyIncome || '';
  document.getElementById('settingPayDay').value = payDay;
  document.getElementById('settingSummaryEnabled').checked = summaryEnabled;
  document.getElementById('settingsModalBackdrop').classList.add('active');
}

function closeSettingsModal() {
  document.getElementById('settingsModalBackdrop').classList.remove('active');
}

// ── Event Listeners ───────────────────────────────────────────────────────────
document.getElementById('openAddModalBtn').addEventListener('click', openModal);
document.getElementById('closeModalBtn').addEventListener('click', closeModal);
document.getElementById('closeCatDetailModalBtn')?.addEventListener('click', closeCategoryDetailModal);

// PWA Tab Bar Navigation Event Listener
document.getElementById('pwaTabBar')?.addEventListener('click', e => {
  const btn = e.target.closest('.pwa-tab-btn');
  if (!btn) return;
  currentTab = btn.dataset.tab;
  save();
});

function setEntryType(type) {
  const isIncome = type === 'income';
  document.querySelectorAll('#entryTypeSwitcher .entry-type-btn').forEach(button => {
    const active = button.dataset.entryType === type;
    button.classList.toggle('active', active);
    button.setAttribute('aria-pressed', String(active));
  });
  document.getElementById('entryType').value = type;
  document.getElementById('expenseCategoryField').hidden = isIncome;
  document.getElementById('expenseKindField').hidden = isIncome;
  document.getElementById('modalTitle').textContent = isIncome ? 'Quick Add Income' : 'Quick Add Expense';
  document.querySelector('#expenseForm .submit-btn').textContent = isIncome ? 'Save Income' : 'Save Expense';
}

document.getElementById('entryTypeSwitcher').addEventListener('click', event => {
  const button = event.target.closest('.entry-type-btn');
  if (button) setEntryType(button.dataset.entryType);
});

document.getElementById('expenseKindSwitcher').addEventListener('click', event => {
  const button = event.target.closest('.entry-kind-btn');
  if (!button) return;
  document.querySelectorAll('#expenseKindSwitcher .entry-kind-btn').forEach(item => {
    const active = item === button;
    item.classList.toggle('active', active);
    item.setAttribute('aria-pressed', String(active));
  });
  document.getElementById('expenseKind').value = button.dataset.expenseKind;
});

document.getElementById('openSettingsBtn').addEventListener('click', openSettingsModal);
document.getElementById('closeSettingsModalBtn').addEventListener('click', closeSettingsModal);

document.getElementById('summaryPeriodSwitcher').addEventListener('click', event => {
  const button = event.target.closest('.summary-period-btn');
  if (!button) return;
  summaryPeriod = button.dataset.summaryPeriod;
  save();
});

document.getElementById('viewBreakdownBtn').addEventListener('click', () => {
  currentTab = 'categories';
  save();
});

document.getElementById('modalBackdrop').addEventListener('click', e => {
  if (e.target === e.currentTarget) closeModal();
});

document.getElementById('settingsModalBackdrop').addEventListener('click', e => {
  if (e.target === e.currentTarget) closeSettingsModal();
});

document.getElementById('categoryDetailModalBackdrop')?.addEventListener('click', e => {
  if (e.target === e.currentTarget) closeCategoryDetailModal();
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    closeModal();
    closeSettingsModal();
    closeCategoryDetailModal();
    if (typeof closeDataMenu === 'function') closeDataMenu();
  }
});

// Search Box Input Event Listener
document.getElementById('txSearchInput')?.addEventListener('input', e => {
  currentSearchQuery = e.target.value;
  renderTransactions();
});

// Type Filter Toggle Listener
document.getElementById('typeFilterToggle')?.addEventListener('click', e => {
  const btn = e.target.closest('.segment-btn');
  if (!btn) return;
  currentTypeFilter = btn.dataset.typefilter;
  document.querySelectorAll('#typeFilterToggle .segment-btn').forEach(b => b.classList.toggle('active', b === btn));
  renderTransactions();
});

// Kind Filter Toggle Listener
document.getElementById('kindFilterToggle')?.addEventListener('click', e => {
  const btn = e.target.closest('.segment-btn');
  if (!btn) return;
  currentKindFilter = btn.dataset.kindfilter;
  document.querySelectorAll('#kindFilterToggle .segment-btn').forEach(b => b.classList.toggle('active', b === btn));
  renderTransactions();
});

// Expense Form Submit
document.getElementById('expenseForm').addEventListener('submit', e => {
  e.preventDefault();
  const title  = document.getElementById('expTitle').value.trim();
  const amount = evalMath(document.getElementById('expAmount').value.trim());
  const type   = document.getElementById('entryType').value;
  const expenseKind = document.getElementById('expenseKind').value;

  if (!amount || amount <= 0) {
    alert('Please enter a valid amount or formula (e.g. 350 or 200 + 150 * 2)');
    return;
  }

  const category = document.querySelector('input[name="category"]:checked').value;
  const date     = document.getElementById('expDate').value;
  if (!title) {
    alert('Please enter a description.');
    return;
  }
  if (!date || Number.isNaN(parseLocalDate(date).getTime())) {
    alert('Please choose a valid date.');
    return;
  }

  expenses.unshift({
    id: Date.now(), type, expenseKind, title, amount, category,
    date: parseLocalDate(date).toISOString(),
    note: '',
  });

  save();
  document.getElementById('expenseForm').reset();
  closeModal();
});

// Topbar Settings Form Submit
document.getElementById('settingsForm').addEventListener('submit', e => {
  e.preventDefault();
  const newBudget   = parseFloat(document.getElementById('settingMonthlyBudget').value);
  const newStartDay = parseInt(document.getElementById('settingCycleStartDay').value, 10);
  const newBaseIncome = parseFloat(document.getElementById('settingBaseIncome').value);
  const newPayDay = parseInt(document.getElementById('settingPayDay').value, 10);
  summaryEnabled = document.getElementById('settingSummaryEnabled').checked;

  if (!isNaN(newBudget) && newBudget >= 0) monthlyBudget = newBudget;
  if (!isNaN(newStartDay) && newStartDay >= 1 && newStartDay <= 28) cycleStartDay = newStartDay;
  if (!isNaN(newBaseIncome) && newBaseIncome >= 0) baseMonthlyIncome = newBaseIncome;
  if (!isNaN(newPayDay) && newPayDay >= 1 && newPayDay <= 28) payDay = newPayDay;

  save();
  closeSettingsModal();
});

// Settings Tab Form Submit
document.getElementById('tabSettingsForm')?.addEventListener('submit', e => {
  e.preventDefault();
  const newBudget   = parseFloat(document.getElementById('tabSettingMonthlyBudget').value);
  const newStartDay = parseInt(document.getElementById('tabSettingCycleStartDay').value, 10);
  const newBaseIncome = parseFloat(document.getElementById('tabSettingBaseIncome').value);
  const newPayDay = parseInt(document.getElementById('tabSettingPayDay').value, 10);
  summaryEnabled = document.getElementById('tabSettingSummaryEnabled').checked;

  if (!isNaN(newBudget) && newBudget >= 0) monthlyBudget = newBudget;
  if (!isNaN(newStartDay) && newStartDay >= 1 && newStartDay <= 28) cycleStartDay = newStartDay;
  if (!isNaN(newBaseIncome) && newBaseIncome >= 0) baseMonthlyIncome = newBaseIncome;
  if (!isNaN(newPayDay) && newPayDay >= 1 && newPayDay <= 28) payDay = newPayDay;

  save();
  alert('Settings saved successfully!');
});

// View Mode Switcher
document.getElementById('viewModeSwitcher').addEventListener('click', e => {
  const btn = e.target.closest('.segment-btn');
  if (!btn) return;
  currentViewMode = btn.dataset.mode;
  save();
});

// ── Unified CSV Export & Import Logic ─────────────────────────────────────────
function csvField(value) {
  return `"${String(value).replace(/"/g, '""')}"`;
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;

  for (let index = 0; index < text.length; index += 1) {
    const character = text[index];
    if (quoted) {
      if (character === '"' && text[index + 1] === '"') {
        field += '"';
        index += 1;
      } else if (character === '"') {
        quoted = false;
      } else {
        field += character;
      }
    } else if (character === '"' && field.length === 0) {
      quoted = true;
    } else if (character === ',') {
      row.push(field);
      field = '';
    } else if (character === '\n' || character === '\r') {
      if (character === '\r' && text[index + 1] === '\n') index += 1;
      row.push(field);
      if (row.some(value => value.trim())) rows.push(row);
      row = [];
      field = '';
    } else {
      field += character;
    }
  }

  if (field || row.length) {
    row.push(field);
    if (row.some(value => value.trim())) rows.push(row);
  }
  return rows;
}

function importedCategory(value) {
  const normalized = String(value).trim().toLowerCase();
  return Object.entries(CATEGORY_MAP).find(([key, category]) =>
    key === normalized || category.name.toLowerCase() === normalized
  )?.[0] || 'other';
}

function importExpensesFromCsv(text) {
  const rows = parseCsv(text);
  if (rows.length === 0) throw new Error('CSV file is empty.');

  const headerRow = rows[0].map(h => h.replace(/^\uFEFF/, '').trim().toLowerCase());

  const idxDate = headerRow.indexOf('date');
  const idxType = headerRow.indexOf('type');
  const idxTitle = headerRow.indexOf('title');
  const idxCategory = headerRow.indexOf('category');
  let idxKind = headerRow.indexOf('expensekind');
  if (idxKind === -1) idxKind = headerRow.indexOf('expense type');
  let idxAmount = headerRow.indexOf('amount');
  if (idxAmount === -1) idxAmount = headerRow.indexOf('amount (inr)');
  const idxNote = headerRow.indexOf('note');

  const hasHeader = idxDate !== -1 || idxTitle !== -1 || idxAmount !== -1;
  const dataRows = hasHeader ? rows.slice(1) : rows;

  const imported = [];
  dataRows.forEach((row, index) => {
    if (row.every(cell => !cell.trim())) return;

    let rawDate = '', rawType = 'expense', rawTitle = '', rawCategory = 'other', rawKind = 'variable', rawAmount = '', rawNote = '';

    if (hasHeader) {
      if (idxDate !== -1 && row[idxDate]) rawDate = row[idxDate].trim();
      if (idxType !== -1 && row[idxType]) rawType = row[idxType].trim();
      if (idxTitle !== -1 && row[idxTitle]) rawTitle = row[idxTitle].trim();
      if (idxCategory !== -1 && row[idxCategory]) rawCategory = row[idxCategory].trim();
      if (idxKind !== -1 && row[idxKind]) rawKind = row[idxKind].trim();
      if (idxAmount !== -1 && row[idxAmount]) rawAmount = row[idxAmount].trim();
      if (idxNote !== -1 && row[idxNote]) rawNote = row[idxNote].trim();
    } else {
      if (row.length >= 7) {
        rawTitle = row[0].trim(); rawAmount = row[1].trim(); rawCategory = row[2].trim();
        rawDate = row[3].trim(); rawNote = row[4].trim(); rawType = row[5].trim(); rawKind = row[6].trim();
      } else if (row.length >= 4) {
        rawDate = row[0].trim(); rawTitle = row[1].trim(); rawCategory = row[2].trim(); rawAmount = row[3].trim();
      }
    }

    const amount = Number(rawAmount.replace(/,/g, '').trim());
    const date = parseLocalDate(rawDate);
    if (!rawTitle || !Number.isFinite(amount) || amount <= 0 || Number.isNaN(date.getTime())) return;

    imported.push({
      id: Date.now() + index + Math.random(),
      type: rawType.toLowerCase() === 'income' ? 'income' : 'expense',
      expenseKind: rawKind.toLowerCase() === 'fixed' ? 'fixed' : 'variable',
      title: rawTitle,
      amount,
      category: importedCategory(rawCategory),
      date: date.toISOString(),
      note: rawNote,
    });
  });

  return imported;
}

function exportExpensesToCsv() {
  if (expenses.length === 0) {
    alert('No expenses to export.');
    return;
  }
  const headers = ['date', 'type', 'title', 'category', 'expenseKind', 'amount', 'note'];
  const rows = expenses.map(e => [
    e.date,
    e.type || 'expense',
    csvField(e.title),
    e.category,
    e.expenseKind || 'variable',
    e.amount.toFixed(2),
    csvField(e.note || '')
  ]);
  const csvContent = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
  const blobUrl = URL.createObjectURL(new Blob([csvContent], { type: 'text/csv;charset=utf-8' }));
  const link = document.createElement('a');
  link.setAttribute('href', blobUrl);
  link.setAttribute('download', `well_spent_backup_${new Date().toISOString().slice(0, 10)}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(blobUrl);
}

const dataMenuWrap = document.querySelector('.data-menu-wrap');
const dataMenuButton = document.getElementById('dataMenuBtn');
const dataMenu = document.getElementById('dataMenu');

function closeDataMenu() {
  dataMenu.classList.remove('active');
  dataMenuButton.setAttribute('aria-expanded', 'false');
}

dataMenuButton.addEventListener('click', () => {
  const isOpen = dataMenu.classList.toggle('active');
  dataMenuButton.setAttribute('aria-expanded', String(isOpen));
});

document.getElementById('exportCsvBtn').addEventListener('click', () => {
  exportExpensesToCsv();
  closeDataMenu();
});

document.getElementById('importCsvBtn').addEventListener('click', () => {
  closeDataMenu();
  document.getElementById('importCsvInput').click();
});

document.addEventListener('click', event => {
  if (dataMenuWrap && !dataMenuWrap.contains(event.target)) closeDataMenu();
});

document.getElementById('importCsvInput').addEventListener('change', event => {
  const file = event.target.files[0];
  event.target.value = '';
  if (!file) return;

  const reader = new FileReader();
  reader.onload = () => {
    try {
      const imported = importExpensesFromCsv(String(reader.result || ''));
      if (!imported.length) {
        alert('No valid expenses were found in the CSV.');
        return;
      }
      if (!confirm(`Import ${imported.length} expense${imported.length === 1 ? '' : 's'}? This will replace your current expenses.`)) return;
      expenses = imported;
      save();
      alert(`Imported ${imported.length} expense${imported.length === 1 ? '' : 's'}.`);
    } catch (error) {
      alert(error.message || 'Unable to import this CSV file.');
    }
  };
  reader.onerror = () => alert('Unable to read this CSV file.');
  reader.readAsText(file);
});

// Category Filter Chips
document.getElementById('categoryFilterChips').addEventListener('click', e => {
  const chip = e.target.closest('.fchip');
  if (!chip) return;
  document.querySelectorAll('.fchip').forEach(c => {
    c.classList.remove('active');
    c.setAttribute('aria-pressed', 'false');
  });
  chip.classList.add('active');
  chip.setAttribute('aria-pressed', 'true');
  currentFilter = chip.dataset.cat;
  setText('filterSummaryLabel', chip.textContent.trim());
  renderTransactions();
});

document.getElementById('chartModeToggle').addEventListener('click', e => {
  const button = e.target.closest('.cchip');
  if (!button) return;
  currentChartMode = button.dataset.chartmode;
  save();
});

// ── Helper ───────────────────────────────────────────────────────────────────
function setText(id, val) {
  const el = document.getElementById(id);
  if (el) el.textContent = val;
}

// ── Boot ─────────────────────────────────────────────────────────────────────
render();
