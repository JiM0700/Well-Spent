// ═══════════════════════════════════════════════════════════════════════════
// WELL SPENT — PWA Application Logic
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

const CATEGORIES = {
  food:          { name: 'Food & Dining',     icon: '🍽️' },
  transport:     { name: 'Transport',         icon: '🚗' },
  bills:         { name: 'Bills',             icon: '⚡' },
  shopping:      { name: 'Shopping',          icon: '🛍️' },
  healthcare:    { name: 'Healthcare',        icon: '🏥' },
  entertainment: { name: 'Entertainment',     icon: '🎬' },
  invest:        { name: 'Investments',       icon: '💰' },
  other:         { name: 'Other',             icon: '🌐' },
};

// ── State ─────────────────────────────────────────────────────────────────
let expenses         = loadJSON(STORAGE_KEY, []);
let monthlyBudget    = Number(localStorage.getItem(BUDGET_KEY))           || 25000;
let cycleStartDay    = Number(localStorage.getItem(CYCLE_START_DAY_KEY))  || 1;
let baseIncome       = Number(localStorage.getItem(BASE_INCOME_KEY))      || 50000;
let currentViewMode  = localStorage.getItem(VIEW_MODE_KEY)                || 'monthwise';
let currentTab       = localStorage.getItem(TAB_KEY)                      || 'overview';
let categoryBudgets  = loadCategoryBudgets();
let recurringBills   = loadRecurringBills();
let currentTheme     = localStorage.getItem(THEME_KEY)                    || 'system';

let activeCatFilter  = 'all';
let searchQuery      = '';
let selectedCatModal = 'food';
let editingCatKey    = null;

// Seed sample data for first run
if (expenses.length === 0) seedSampleData();

// ── Storage Helpers ───────────────────────────────────────────────────────
function loadJSON(key, fallback) {
  try {
    const v = JSON.parse(localStorage.getItem(key));
    return v !== null && v !== undefined ? v : fallback;
  } catch { return fallback; }
}

function saveExpenses()        { localStorage.setItem(STORAGE_KEY, JSON.stringify(expenses)); }
function saveCategoryBudgets() { localStorage.setItem(CATEGORY_BUDGETS_KEY, JSON.stringify(categoryBudgets)); }
function saveRecurringBills()  { localStorage.setItem(RECURRING_BILLS_KEY, JSON.stringify(recurringBills)); }

function loadCategoryBudgets() {
  const defaults = { food:8000, transport:4000, bills:6000, shopping:4000, healthcare:2000, entertainment:2000, invest:5000, other:2000 };
  const stored = loadJSON(CATEGORY_BUDGETS_KEY, {});
  return Object.assign(defaults, stored);
}

function loadRecurringBills() {
  const stored = loadJSON(RECURRING_BILLS_KEY, null);
  if (Array.isArray(stored) && stored.length > 0) return stored;
  return [
    { id: 1, title: 'iCloud Storage',   amount: 299,  dueDay: 5,  isPaid: true },
    { id: 2, title: 'Apple Music',      amount: 199,  dueDay: 12, isPaid: false },
    { id: 3, title: 'Fiber Broadband',  amount: 999,  dueDay: 20, isPaid: false },
    { id: 4, title: 'Gym Membership',   amount: 2500, dueDay: 1,  isPaid: true },
  ];
}

function seedSampleData() {
  const now = new Date();
  const y = now.getFullYear(), m = now.getMonth(), d = now.getDate();
  expenses = [
    { id: Date.now()-4, title: 'Specialty Espresso',    amount: 380,  category: 'food',      date: new Date(y,m,d,9,30).toISOString(),  notes: 'Morning coffee' },
    { id: Date.now()-3, title: 'Organic Grocery Basket',amount: 1450, category: 'food',      date: new Date(y,m,d,14,0).toISOString(),  notes: '' },
    { id: Date.now()-2, title: 'Metro SmartCard Topup', amount: 500,  category: 'transport', date: new Date(y,m,d-1,18,0).toISOString(),notes: '' },
    { id: Date.now()-1, title: 'Electricity Bill',      amount: 2350, category: 'bills',     date: new Date(y,m,d-3,11,0).toISOString(),notes: '' },
  ];
  saveExpenses();
}

// ── Formatters ────────────────────────────────────────────────────────────
function inr(n) {
  return new Intl.NumberFormat('en-IN', { style:'currency', currency:'INR', minimumFractionDigits:2 }).format(n||0);
}
function inrS(n) { return '₹' + Math.round(n||0).toLocaleString('en-IN'); }
function fmtDate(d) { return new Date(d).toLocaleDateString('en-IN',{ day:'numeric', month:'short' }); }
function esc(v) {
  return String(v||'').replace(/[&<>"']/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

function haptic() { try { navigator.vibrate && navigator.vibrate(12); } catch {} }

// ── Metrics ───────────────────────────────────────────────────────────────
function calcMetrics() {
  const now = new Date();
  const y = now.getFullYear(), mo = now.getMonth(), d = now.getDate();
  let sy = y, sm = mo;
  if (d < cycleStartDay) { sm--; if (sm < 0) { sm = 11; sy--; } }
  const cycleStart = new Date(sy, sm, cycleStartDay, 0,0,0,0);
  let ey = sy, em = sm+1; if (em > 11) { em = 0; ey++; }
  const cycleEnd = new Date(ey, em, cycleStartDay, 0,0,0,0);

  const monthExp = expenses.filter(e => { const ed = new Date(e.date); return ed >= cycleStart && ed < cycleEnd; });
  const monthTotal = monthExp.reduce((s,e) => s+e.amount, 0);

  const todayStart = new Date(y, mo, d, 0,0,0,0);
  const todayEnd   = new Date(y, mo, d, 23,59,59,999);
  const todayExp = expenses.filter(e => { const ed = new Date(e.date); return ed >= todayStart && ed <= todayEnd; });
  const todayTotal = todayExp.reduce((s,e) => s+e.amount, 0);

  const totalDays    = Math.max(1, Math.round((cycleEnd - cycleStart) / 86400000));
  const daysElapsed  = Math.max(1, Math.min(totalDays, Math.ceil((now - cycleStart) / 86400000)));
  const daysRemaining = Math.max(0, totalDays - daysElapsed);
  const dailyBudget  = monthlyBudget / totalDays;
  const dailyBurn    = monthTotal / daysElapsed;
  const projMonthEnd = monthTotal + dailyBurn * daysRemaining;
  const remainingToday = Math.max(0, dailyBudget - todayTotal);

  return { monthTotal, todayTotal, dailyBudget, dailyBurn, projMonthEnd, remainingToday,
           daysElapsed, daysRemaining, totalDays, monthExp, todayExp };
}

// ── Render ────────────────────────────────────────────────────────────────
function render() {
  applyTheme();
  syncNav();
  const m = calcMetrics();
  renderSidebar(m);
  renderOverview(m);
  renderBudgets(m);
  renderTrends(m);
  renderSettings();
}

function applyTheme() {
  let theme = currentTheme;
  if (theme === 'system') {
    theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  document.body.setAttribute('data-theme', theme);

  const sel = document.getElementById('themeSelect');
  if (sel) sel.value = currentTheme;
}

function syncNav() {
  // Sidebar links
  document.querySelectorAll('.slink').forEach(b => b.classList.toggle('active', b.dataset.tab === currentTab));
  // Bottom nav
  document.querySelectorAll('.bnav-btn:not(.bnav-center)').forEach(b => b.classList.toggle('active', b.dataset.tab === currentTab));
  // Tab views
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  const tabMap = { overview:'tabOverview', categories:'tabCategories', insights:'tabInsights', settings:'tabSettings' };
  const v = document.getElementById(tabMap[currentTab] || 'tabOverview');
  if (v) v.classList.add('active');
}

// ── Sidebar ───────────────────────────────────────────────────────────────
function renderSidebar(m) {
  const pct = monthlyBudget > 0 ? Math.min(100, Math.round((m.monthTotal / monthlyBudget) * 100)) : 0;
  setText('sidebarGaugePct', `${pct}%`);
  setText('sidebarSpentMeta', `${inrS(m.monthTotal)} spent`);
  setText('sidebarLeftMeta', `${inrS(Math.max(0, monthlyBudget - m.monthTotal))} remaining`);
  const fill = document.getElementById('sidebarGaugeFill');
  if (fill) { fill.style.width = `${pct}%`; fill.classList.toggle('over', pct >= 100); }
}

// ── Overview Tab ──────────────────────────────────────────────────────────
function renderOverview(m) {
  const isDaywise = currentViewMode === 'daywise';

  document.querySelectorAll('.period-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.mode === currentViewMode);
  });

  const total = isDaywise ? m.todayTotal : m.monthTotal;
  const budget = isDaywise ? m.dailyBudget : monthlyBudget;
  const remaining = isDaywise ? m.remainingToday : Math.max(0, monthlyBudget - m.monthTotal);
  const isOver = budget > 0 && total > budget;
  const pct = budget > 0 ? Math.min(100, Math.round((total / budget) * 100)) : 0;

  setText('pulseEyebrow', isDaywise ? "Today's Spending" : 'Monthly Spending');
  setText('pulseAmountDisplay', inr(total));
  setText('pulseSubDisplay', `of ${inrS(budget)} ${isDaywise ? 'daily budget' : 'monthly budget'}`);
  setText('pulseStatusBadge', isOver ? 'Over Budget' : 'On Track');
  setText('pulseRemainingDisplay', inrS(remaining));
  setText('pulseBurnDisplay', `${inrS(m.dailyBurn)}/day`);
  setText('pulseMonthEndDisplay', inrS(m.projMonthEnd));

  const fill = document.getElementById('pulseProgressFill');
  if (fill) { fill.style.width = `${pct}%`; fill.classList.toggle('over', isOver); }

  const badge = document.getElementById('pulseStatusBadge');
  if (badge) badge.classList.toggle('over', isOver);

  setText('activityHeading', isDaywise ? "Today" : "This Cycle");

  // Transaction list
  let list = isDaywise ? m.todayExp : m.monthExp;
  if (activeCatFilter !== 'all') list = list.filter(e => e.category === activeCatFilter);
  if (searchQuery.trim()) {
    const q = searchQuery.toLowerCase();
    list = list.filter(e =>
      e.title.toLowerCase().includes(q) ||
      (e.notes && e.notes.toLowerCase().includes(q)) ||
      (CATEGORIES[e.category]?.name.toLowerCase().includes(q))
    );
  }
  setText('activitySubheading', `${list.length} ${list.length === 1 ? 'entry' : 'entries'}`);
  renderTxList(list);
}

// ── Transaction List (slide-to-delete) ────────────────────────────────────
function renderTxList(list) {
  const el = document.getElementById('transactionList');
  if (!el) return;

  if (!list.length) {
    el.innerHTML = `
      <div class="empty-state">
        <div class="empty-state__icon">📭</div>
        <div class="empty-state__title">No Transactions</div>
        <p class="empty-state__sub">Nothing recorded for this period.</p>
      </div>`;
    return;
  }

  el.innerHTML = list.map(item => {
    const cat = CATEGORIES[item.category] || CATEGORIES.other;
    return `
      <div class="tx-row" data-id="${item.id}">
        <div class="tx-delete-reveal">
          <button type="button" data-del="${item.id}" aria-label="Delete">Delete</button>
        </div>
        <div class="tx-card" data-id="${item.id}">
          <div class="tx-card__icon">${cat.icon}</div>
          <div class="tx-card__body">
            <div class="tx-card__title">${esc(item.title)}</div>
            <div class="tx-card__meta">${cat.name} · ${fmtDate(item.date)}${item.notes ? ' · '+esc(item.notes) : ''}</div>
          </div>
          <div class="tx-card__amount">${inr(item.amount)}</div>
        </div>
      </div>`;
  }).join('');

  attachSwipe();
}

function attachSwipe() {
  document.querySelectorAll('.tx-card').forEach(card => {
    let sx = 0, cx = 0, open = false, active = false;
    const BW = 72, FULL = -150;

    card.addEventListener('touchstart', e => { sx = e.touches[0].clientX; active = true; card.style.transition = 'none'; }, { passive: true });
    card.addEventListener('touchmove', e => {
      if (!active) return;
      cx = e.touches[0].clientX;
      const dx = cx - sx;
      if (dx < 0) card.style.transform = `translateX(${open ? Math.max(-BW*1.5, -BW+dx) : Math.max(-BW*1.2, dx)}px)`;
      else if (open) card.style.transform = `translateX(${Math.min(0, -BW+dx)}px)`;
    }, { passive: true });

    card.addEventListener('touchend', () => {
      if (!active) return;
      active = false;
      card.style.transition = 'transform 0.25s cubic-bezier(0.16,1,0.3,1)';
      const dx = cx - sx;
      const id = card.dataset.id;
      if (dx < FULL) {
        haptic(); card.style.transform = 'translateX(-100%)';
        setTimeout(() => deleteTx(id), 220);
      } else if (dx < -BW / 2) {
        haptic(); card.style.transform = `translateX(${-BW}px)`; open = true;
      } else {
        card.style.transform = 'translateX(0)'; open = false;
      }
    });

    card.addEventListener('click', () => { if (open) { card.style.transform = 'translateX(0)'; card.style.transition = 'transform 0.25s ease'; open = false; } });
  });

  document.querySelectorAll('[data-del]').forEach(btn => {
    btn.addEventListener('click', e => { e.stopPropagation(); haptic(); deleteTx(btn.dataset.del); });
  });
}

function deleteTx(id) {
  expenses = expenses.filter(e => String(e.id) !== String(id));
  saveExpenses();
  render();
}

// ── Budgets Tab ───────────────────────────────────────────────────────────
function renderBudgets(m) {
  const pct = monthlyBudget > 0 ? Math.min(100, Math.round((m.monthTotal / monthlyBudget) * 100)) : 0;
  setText('allocationTotalDisplay', inr(monthlyBudget));
  setText('allocationStatusBadge', `${pct}% used`);
  setText('allocationSpentText', inrS(m.monthTotal));
  setText('allocationRemainingText', inrS(Math.max(0, monthlyBudget - m.monthTotal)));

  const fill = document.getElementById('allocationProgressFill');
  if (fill) { fill.style.width = `${pct}%`; fill.classList.toggle('over', pct >= 100); }

  const grid = document.getElementById('envelopesGrid');
  if (!grid) return;

  grid.innerHTML = Object.entries(CATEGORIES).map(([key, cat]) => {
    const target = categoryBudgets[key] || 3000;
    const spent = m.monthExp.filter(e => e.category === key).reduce((s,e) => s+e.amount, 0);
    const p = target > 0 ? Math.min(100, Math.round((spent/target)*100)) : 0;
    const over = spent > target;
    return `
      <div class="envelope-row" data-cat="${key}">
        <div class="envelope-row__top">
          <span class="envelope-row__icon">${cat.icon}</span>
          <span class="envelope-row__name">${cat.name}</span>
          <span class="envelope-row__pct ${over ? 'over' : ''}">${p}%</span>
        </div>
        <div class="envelope-row__bar"><div class="envelope-row__fill ${over ? 'over' : ''}" style="width:${p}%"></div></div>
        <div class="envelope-row__amounts">
          <span>${inrS(spent)} spent</span>
          <span>Target: ${inrS(target)}</span>
        </div>
      </div>`;
  }).join('');

  grid.querySelectorAll('.envelope-row').forEach(row => {
    row.addEventListener('click', () => { haptic(); openBudgetModal(row.dataset.cat); });
  });
}

function openBudgetModal(key) {
  editingCatKey = key;
  setText('budgetEditTitle', `Edit ${CATEGORIES[key]?.name || key}`);
  const inp = document.getElementById('budgetEditInput');
  if (inp) inp.value = categoryBudgets[key] || 3000;
  openOverlay('budgetModalBackdrop');
}

// ── Trends Tab ────────────────────────────────────────────────────────────
function renderTrends(m) {
  setText('velBurnVal', inrS(m.dailyBurn));
  setText('velProjectedVal', inrS(m.projMonthEnd));
  setText('velRemainingVal', `${m.daysRemaining}d`);

  const burnPct = monthlyBudget > 0 ? Math.min(100, Math.round((m.projMonthEnd/monthlyBudget)*100)) : 0;
  const bFill = document.getElementById('velocityBurnFill');
  if (bFill) { bFill.style.width = `${burnPct}%`; bFill.classList.toggle('over', m.projMonthEnd > monthlyBudget); }

  const statusEl = document.getElementById('velocityStatusMsg');
  if (statusEl) {
    if (m.projMonthEnd > monthlyBudget && monthlyBudget > 0) {
      statusEl.textContent = `Over-budget trajectory. At ${inr(m.dailyBurn)}/day you'll exceed your limit by ${inr(m.projMonthEnd - monthlyBudget)}.`;
    } else {
      statusEl.textContent = `On track. Projected to finish with ${inr(Math.max(0, monthlyBudget - m.projMonthEnd))} surplus.`;
    }
  }

  const distEl = document.getElementById('categoryDistributionList');
  if (distEl) {
    const total = m.monthTotal || 1;
    distEl.innerHTML = Object.entries(CATEGORIES).map(([key, cat]) => {
      const spent = m.monthExp.filter(e => e.category === key).reduce((s,e) => s+e.amount, 0);
      const p = Math.round((spent/total)*100);
      return `
        <div class="dist-row">
          <div class="dist-row__meta">
            <span class="dist-row__label">${cat.icon} ${cat.name}</span>
            <span class="dist-row__val">${inr(spent)} (${p}%)</span>
          </div>
          <div class="dist-row__bar"><div class="dist-row__fill" style="width:${p}%"></div></div>
        </div>`;
    }).join('');
  }

  // Recurring bills
  const today = new Date().getDate();
  const upcoming = recurringBills.filter(b => !b.isPaid).reduce((s,b) => s+b.amount, 0);
  setText('upcomingBillsTotalDisplay', inr(upcoming));

  const billsEl = document.getElementById('recurringBillsList');
  if (billsEl) {
    billsEl.innerHTML = recurringBills.map(bill => {
      let dLeft = bill.dueDay - today;
      if (dLeft < 0) { const last = new Date(new Date().getFullYear(), new Date().getMonth()+1, 0).getDate(); dLeft = last - today + bill.dueDay; }
      const dueTxt = dLeft === 0 ? 'Due Today' : `Due in ${dLeft}d`;
      return `
        <div class="recurring-item ${bill.isPaid ? 'paid' : ''}">
          <div class="recurring-item__body">
            <div class="recurring-item__name">${esc(bill.title)}</div>
            <div class="recurring-item__sub">${dueTxt} · Day ${bill.dueDay} of month</div>
          </div>
          <div class="recurring-item__right">
            <span class="recurring-item__amount">${inr(bill.amount)}</span>
            <button type="button" class="recurring-item__toggle ${bill.isPaid ? 'paid' : ''}" data-bill="${bill.id}">
              ${bill.isPaid ? 'Paid' : 'Mark Paid'}
            </button>
          </div>
        </div>`;
    }).join('');

    billsEl.querySelectorAll('[data-bill]').forEach(btn => {
      btn.addEventListener('click', () => {
        haptic();
        const b = recurringBills.find(x => String(x.id) === btn.dataset.bill);
        if (b) { b.isPaid = !b.isPaid; saveRecurringBills(); render(); }
      });
    });
  }
}

// ── Settings Tab ──────────────────────────────────────────────────────────
function renderSettings() {
  const mb = document.getElementById('settingMonthlyBudget');
  if (mb) mb.value = monthlyBudget;
  const cs = document.getElementById('settingCycleStartDay');
  if (cs) cs.value = cycleStartDay;
  const bi = document.getElementById('settingBaseIncome');
  if (bi) bi.value = baseIncome;
}

// ── Modals ────────────────────────────────────────────────────────────────
function openOverlay(id) { document.getElementById(id)?.classList.add('active'); }
function closeOverlay(id) { document.getElementById(id)?.classList.remove('active'); }

function openAddModal() {
  const dateEl = document.getElementById('expenseDateInput');
  if (dateEl) dateEl.value = new Date().toISOString().split('T')[0];
  const amtEl = document.getElementById('expenseAmountInput');
  if (amtEl) { amtEl.value = ''; }
  document.getElementById('expenseTitleInput') && (document.getElementById('expenseTitleInput').value = '');
  document.getElementById('expenseNotesInput') && (document.getElementById('expenseNotesInput').value = '');
  renderModalCats();
  openOverlay('modalBackdrop');
  setTimeout(() => document.getElementById('expenseAmountInput')?.focus(), 100);
}

function renderModalCats() {
  const el = document.getElementById('modalCategoryGrid');
  if (!el) return;
  el.innerHTML = Object.entries(CATEGORIES).map(([k, cat]) => `
    <button type="button" class="cat-btn ${k === selectedCatModal ? 'active' : ''}" data-c="${k}">
      <span class="cat-btn__icon">${cat.icon}</span>
      <span>${cat.name.split(' ')[0]}</span>
    </button>`).join('');
  el.querySelectorAll('.cat-btn').forEach(b => {
    b.addEventListener('click', () => { haptic(); selectedCatModal = b.dataset.c; renderModalCats(); });
  });
}

function saveExpense(e) {
  e.preventDefault();
  const amount = parseFloat(document.getElementById('expenseAmountInput').value);
  const title  = document.getElementById('expenseTitleInput').value.trim();
  const notes  = document.getElementById('expenseNotesInput').value.trim();
  const date   = document.getElementById('expenseDateInput').value;

  if (!title || isNaN(amount) || amount <= 0) {
    alert('Please enter a valid description and amount.'); return;
  }
  haptic();
  expenses.unshift({ id: Date.now(), title, amount, category: selectedCatModal, date: date ? new Date(date+'T12:00:00').toISOString() : new Date().toISOString(), notes });
  saveExpenses();
  closeOverlay('modalBackdrop');
  render();
}

// ── Events ────────────────────────────────────────────────────────────────
function setupEvents() {
  // Tab nav
  document.querySelectorAll('.slink, .bnav-btn:not(.bnav-center)').forEach(btn => {
    btn.addEventListener('click', () => {
      haptic(); currentTab = btn.dataset.tab;
      localStorage.setItem(TAB_KEY, currentTab); render();
    });
  });

  // Mobile centre add button
  const centreBtn = document.getElementById('mobileAddBtn');
  if (centreBtn) centreBtn.addEventListener('click', () => { haptic(); openAddModal(); });

  // Period toggle
  document.getElementById('viewModeSwitcher')?.addEventListener('click', e => {
    const btn = e.target.closest('.period-btn');
    if (!btn) return;
    haptic(); currentViewMode = btn.dataset.mode;
    localStorage.setItem(VIEW_MODE_KEY, currentViewMode); render();
  });

  // Category filter chips
  document.getElementById('categoryFilterChips')?.addEventListener('click', e => {
    const chip = e.target.closest('.chip');
    if (!chip) return;
    haptic();
    document.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
    chip.classList.add('active');
    activeCatFilter = chip.dataset.cat;
    render();
  });

  // Search
  document.getElementById('txSearchInput')?.addEventListener('input', e => {
    searchQuery = e.target.value;
    const m = calcMetrics(); renderOverview(m);
  });

  // Add buttons
  document.getElementById('openAddModalBtn')?.addEventListener('click',  () => { haptic(); openAddModal(); });
  document.getElementById('openAddModalBtn2')?.addEventListener('click', () => { haptic(); openAddModal(); });
  document.getElementById('sidebarAddBtn')?.addEventListener('click',   () => { haptic(); openAddModal(); });

  // Modal save/cancel
  document.getElementById('modalCancelBtn')?.addEventListener('click', () => closeOverlay('modalBackdrop'));
  document.getElementById('addExpenseForm')?.addEventListener('submit', saveExpense);
  document.getElementById('modalSaveBtn')?.addEventListener('click', saveExpense);

  // Budget modal
  document.getElementById('budgetCancelBtn')?.addEventListener('click', () => closeOverlay('budgetModalBackdrop'));
  document.getElementById('budgetSaveBtn')?.addEventListener('click', () => {
    haptic();
    const v = Number(document.getElementById('budgetEditInput').value) || 0;
    if (editingCatKey) { categoryBudgets[editingCatKey] = v; saveCategoryBudgets(); }
    closeOverlay('budgetModalBackdrop'); render();
  });

  // Bill modal
  document.getElementById('openAddBillModalBtn')?.addEventListener('click', () => { haptic(); openOverlay('billModalBackdrop'); });
  document.getElementById('billCancelBtn')?.addEventListener('click', () => closeOverlay('billModalBackdrop'));
  document.getElementById('billSaveBtn')?.addEventListener('click', () => {
    const title  = document.getElementById('billTitleInput').value.trim();
    const amount = Number(document.getElementById('billAmountInput').value) || 0;
    const dueDay = Number(document.getElementById('billDayInput').value) || 1;
    if (title && amount > 0) {
      haptic();
      recurringBills.push({ id: Date.now(), title, amount, dueDay, isPaid: false });
      saveRecurringBills();
      closeOverlay('billModalBackdrop'); render();
    }
  });

  // Overlay backdrop dismiss
  document.querySelectorAll('.overlay').forEach(ov => {
    ov.addEventListener('click', e => { if (e.target === ov) closeOverlay(ov.id); });
  });

  // Theme
  document.getElementById('themeSelect')?.addEventListener('change', e => {
    currentTheme = e.target.value;
    localStorage.setItem(THEME_KEY, currentTheme);
    applyTheme();
  });

  // Settings save
  document.getElementById('saveSettingsBtn')?.addEventListener('click', () => {
    haptic();
    monthlyBudget = Number(document.getElementById('settingMonthlyBudget').value) || 25000;
    cycleStartDay = Number(document.getElementById('settingCycleStartDay').value) || 1;
    baseIncome    = Number(document.getElementById('settingBaseIncome').value)    || 50000;
    localStorage.setItem(BUDGET_KEY, monthlyBudget);
    localStorage.setItem(CYCLE_START_DAY_KEY, cycleStartDay);
    localStorage.setItem(BASE_INCOME_KEY, baseIncome);
    render();
  });

  // Data Export / Import
  document.getElementById('exportCsvBtn')?.addEventListener('click', exportCSV);
  const csvInp = document.getElementById('importCsvInput');
  document.getElementById('importCsvBtn')?.addEventListener('click', () => csvInp?.click());
  csvInp?.addEventListener('change', importCSV);

  document.getElementById('exportVaultBtn')?.addEventListener('click', exportVault);
  const vaultInp = document.getElementById('importVaultInput');
  document.getElementById('importVaultBtn')?.addEventListener('click', () => vaultInp?.click());
  vaultInp?.addEventListener('change', importVault);

  document.getElementById('clearAllDataBtn')?.addEventListener('click', () => {
    if (confirm('Erase all transaction records? This cannot be undone.')) {
      expenses = []; saveExpenses(); render();
    }
  });

  // Keyboard shortcuts
  document.addEventListener('keydown', e => {
    if (!e.metaKey && !e.ctrlKey) return;
    const k = e.key;
    if (k==='1') { e.preventDefault(); currentTab='overview';    render(); }
    if (k==='2') { e.preventDefault(); currentTab='categories';  render(); }
    if (k==='3') { e.preventDefault(); currentTab='insights';    render(); }
    if (k==='4'||k===',') { e.preventDefault(); currentTab='settings'; render(); }
    if (k==='n'||k==='N') { e.preventDefault(); openAddModal(); }
    if (k==='Escape') { document.querySelectorAll('.overlay.active').forEach(o => o.classList.remove('active')); }
  });

  // System theme change listener
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    if (currentTheme === 'system') applyTheme();
  });
}

// ── CSV Export / Import (Fixed for macOS export format) ───────────────────
function exportCSV() {
  if (!expenses.length) { alert('No transactions to export.'); return; }
  const rows = [['ID','Title','Amount (INR)','Category','Date (ISO)','Notes']];
  expenses.forEach(e => {
    rows.push([
      e.id,
      `"${(e.title||'').replace(/"/g,'""')}"`,
      e.amount,
      e.category,
      e.date,
      `"${(e.notes||'').replace(/"/g,'""')}"`,
    ]);
  });
  const csv = rows.map(r => r.join(',')).join('\n');
  downloadBlob(csv, `WellSpent_${isoDate()}.csv`, 'text/csv;charset=utf-8;');
}

/**
 * Maps any category string to a PWA key.
 * Handles macOS rawValues: utilities→bills, health→healthcare, housing→other
 * The `type` column ("expense"/"income") must be excluded before calling this.
 */
function resolveCategoryKey(raw) {
  if (!raw) return 'other';
  const s = raw.toLowerCase().trim();

  // 1. Direct PWA key match (food, transport, bills, shopping, healthcare, entertainment, invest, other)
  if (CATEGORIES[s]) return s;

  // 2. Explicit macOS rawValue → PWA key
  const exact = { utilities:'bills', health:'healthcare', housing:'other', invest:'invest' };
  if (exact[s]) return exact[s];

  // 3. Keyword fallback
  if (/food|dining|restaurant|cafe|grocery|groceries|coffee/.test(s)) return 'food';
  if (/transport|transit|travel|fuel|cab|uber|metro|commute/.test(s)) return 'transport';
  if (/utilit|bill|electric|power|wifi|water|gas|internet/.test(s)) return 'bills';
  if (/entertain|movie|music|netflix|spotify|game|cinema|streaming/.test(s)) return 'entertainment';
  if (/health|medic|doctor|gym|pharma|fitness|clinic|hospital/.test(s)) return 'healthcare';
  if (/shop|cloth|retail|amazon|store|electronics|mall/.test(s)) return 'shopping';
  if (/invest|stock|mutual|sip|fund|trading/.test(s)) return 'invest';

  return 'other';
}

function importCSV(e) {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = ev => {
    const text = ev.target.result;
    const lines = parseCSVLines(text);
    if (lines.length < 2) { alert('CSV appears empty or invalid.'); return; }

    // ── Header detection ─────────────────────────────────────────────────
    const rawHeader = lines[0];
    const hdr = rawHeader.map(h => h.toLowerCase().replace(/[^a-z0-9]/g, ''));

    // "type" column (macOS: "expense"/"income") must NOT map to category
    const iType  = hdr.findIndex(h => h === 'type' || h === 'kind');
    const iTitle = hdr.findIndex(h =>
      h.includes('title') || h.includes('name') || h.includes('description') || h.includes('desc') || h.includes('item'));
    const iAmount = hdr.findIndex(h =>
      h.includes('amount') || h.includes('cost') || h.includes('price') || h.includes('total') || h.includes('val'));
    // Exclude iType index from category detection
    const iCategory = hdr.findIndex((h, i) => i !== iType && (h.includes('categ') || h === 'cat'));
    const iDate = hdr.findIndex(h => h.includes('date') || h.includes('time'));
    const iNotes = hdr.findIndex(h =>
      h.includes('note') || h.includes('memo') || h.includes('comment') || h.includes('remark'));

    if (iTitle < 0 && iAmount < 0) {
      alert(`Could not detect columns.\nFound: ${rawHeader.join(', ')}\n\nExpect columns: title/name/description, amount/cost, category (optional), date (optional).`);
      return;
    }

    let count = 0, skipped = 0;
    for (let i = 1; i < lines.length; i++) {
      const cols = lines[i];
      if (!cols || cols.length < 2) continue;

      // Amount
      const amtIdx = iAmount >= 0 ? iAmount
        : cols.findIndex(c => /^[\d.,]+$/.test(c.replace(/[₹$€£,\s]/g, '')));
      if (amtIdx < 0) { skipped++; continue; }
      const amount = parseFloat((cols[amtIdx] || '').replace(/[₹$€£,\s]/g, ''));
      if (isNaN(amount) || amount <= 0) { skipped++; continue; }

      // Title
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

      // Category — use the dedicated resolver with macOS rawValue awareness
      const catRaw = iCategory >= 0 ? (cols[iCategory] || '') : '';
      const category = resolveCategoryKey(catRaw);

      // Date
      let date = new Date().toISOString();
      if (iDate >= 0 && cols[iDate] && cols[iDate].trim()) {
        const parsed = parseDateFlexible(cols[iDate].trim());
        if (parsed) date = parsed;
      }

      const notes = iNotes >= 0 ? (cols[iNotes] || '').trim() : '';
      expenses.push({ id: Date.now() + Math.random(), title, amount, category, date, notes });
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

/**
 * Robust CSV line parser that handles quoted fields with commas and newlines.
 */
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
      if (inQuotes && line[i+1] === '"') { field += '"'; i++; }
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

/**
 * Try multiple date formats used by macOS, Numbers, and Excel exports.
 */
function parseDateFlexible(raw) {
  if (!raw) return null;

  // Already ISO 8601 (2025-01-15T10:30:00.000Z or 2025-01-15)
  if (/^\d{4}-\d{2}-\d{2}/.test(raw)) {
    const d = new Date(raw);
    return isNaN(d) ? null : d.toISOString();
  }

  // DD/MM/YYYY or D/M/YYYY (common in Indian/macOS locale)
  const dmy = raw.match(/^(\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})$/);
  if (dmy) {
    let [,d,mo,y] = dmy;
    if (y.length === 2) y = '20' + y;
    const dt = new Date(`${y}-${mo.padStart(2,'0')}-${d.padStart(2,'0')}T12:00:00`);
    return isNaN(dt) ? null : dt.toISOString();
  }

  // MM/DD/YYYY (US format)
  const mdy = raw.match(/^(\d{1,2})\/(\d{1,2})\/(\d{2,4})$/);
  if (mdy) {
    let [,mo,d,y] = mdy;
    if (y.length === 2) y = '20' + y;
    const dt = new Date(`${y}-${mo.padStart(2,'0')}-${d.padStart(2,'0')}T12:00:00`);
    return isNaN(dt) ? null : dt.toISOString();
  }

  // "15 Jan 2025" or "Jan 15, 2025"
  const d = new Date(raw);
  return isNaN(d) ? null : d.toISOString();
}

// ── Vault Export / Import ─────────────────────────────────────────────────
function exportVault() {
  const data = {
    version: 2,
    exportedAt: new Date().toISOString(),
    expenses, monthlyBudget, cycleStartDay, baseIncome, categoryBudgets, recurringBills,
  };
  downloadBlob(JSON.stringify(data, null, 2), `WellSpent_Backup_${isoDate()}.wsbackup`, 'application/json');
}

function importVault(e) {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = ev => {
    try {
      const data = JSON.parse(ev.target.result);
      if (!Array.isArray(data.expenses)) throw new Error('Invalid backup file.');
      expenses        = data.expenses;
      monthlyBudget   = data.monthlyBudget   || monthlyBudget;
      cycleStartDay   = data.cycleStartDay   || cycleStartDay;
      baseIncome      = data.baseIncome      || baseIncome;
      categoryBudgets = data.categoryBudgets || categoryBudgets;
      recurringBills  = data.recurringBills  || recurringBills;
      saveExpenses(); saveCategoryBudgets(); saveRecurringBills();
      localStorage.setItem(BUDGET_KEY, monthlyBudget);
      localStorage.setItem(CYCLE_START_DAY_KEY, cycleStartDay);
      localStorage.setItem(BASE_INCOME_KEY, baseIncome);
      e.target.value = '';
      alert('Vault restored successfully.');
      render();
    } catch (err) { alert('Failed to restore vault: ' + err.message); }
  };
  reader.readAsText(file, 'utf-8');
}

// ── Utilities ─────────────────────────────────────────────────────────────
function setText(id, val) { const el = document.getElementById(id); if (el) el.textContent = val; }
function isoDate() { return new Date().toISOString().split('T')[0]; }
function downloadBlob(content, filename, mime) {
  const blob = new Blob([content], { type: mime });
  const url  = URL.createObjectURL(blob);
  const a    = Object.assign(document.createElement('a'), { href: url, download: filename });
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}

// ── Service Worker ────────────────────────────────────────────────────────
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('./sw.js').catch(() => {}));
}

// ── Boot ──────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  setupEvents();
  render();
});
