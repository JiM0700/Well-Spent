import re

with open('app.js', 'r') as f:
    content = f.read()

# Replace localStorage bypasses outside of SafeStorage (SafeStorage is at the top)
content = content.replace("localStorage.setItem(PERIOD_KEY, selectedPeriod);", "SafeStorage.setString(PERIOD_KEY, selectedPeriod);")
content = content.replace("localStorage.setItem(FIRST_RUN_KEY, 'true');", "SafeStorage.setString(FIRST_RUN_KEY, 'true');")
content = content.replace("localStorage.setItem(PALETTE_KEY, currentPalette);", "SafeStorage.setString(PALETTE_KEY, currentPalette);")

# For the settings save (lines ~2188)
settings_save_old = """    saveSettingsBtn.addEventListener('click', () => {
      triggerHaptic();
      monthlyBudget = Number(document.getElementById('settingMonthlyBudget').value) || 25000;
      cycleStartDay = Number(document.getElementById('settingCycleStartDay').value) || 1;
      baseIncome = Number(document.getElementById('settingBaseIncome').value) || 50000;

      localStorage.setItem(BUDGET_KEY, monthlyBudget);
      localStorage.setItem(CYCLE_START_DAY_KEY, cycleStartDay);
      localStorage.setItem(BASE_INCOME_KEY, baseIncome);

      alert('Parameters saved successfully.');
      render();
    });"""

settings_save_new = """    saveSettingsBtn.addEventListener('click', () => {
      triggerHaptic();
      monthlyBudget = sanitizeNumber(document.getElementById('settingMonthlyBudget').value, 25000, 100, 1e8);
      cycleStartDay = sanitizeNumber(document.getElementById('settingCycleStartDay').value, 1, 1, 28);
      baseIncome    = sanitizeNumber(document.getElementById('settingBaseIncome').value, 50000, 0, 1e9);

      SafeStorage.setString(BUDGET_KEY, monthlyBudget);
      SafeStorage.setString(CYCLE_START_DAY_KEY, cycleStartDay);
      SafeStorage.setString(BASE_INCOME_KEY, baseIncome);

      showToast('✓ Settings saved successfully.');
      render();
    });"""
content = content.replace(settings_save_old, settings_save_new)

# For the vault import save (lines ~2520)
vault_old = """        localStorage.setItem(BUDGET_KEY, monthlyBudget);
        localStorage.setItem(CYCLE_START_DAY_KEY, cycleStartDay);
        localStorage.setItem(BASE_INCOME_KEY, baseIncome);
        localStorage.setItem(PALETTE_KEY, currentPalette);
        localStorage.setItem(FIRST_RUN_KEY, 'true');"""
vault_new = """        SafeStorage.setString(BUDGET_KEY, monthlyBudget);
        SafeStorage.setString(CYCLE_START_DAY_KEY, cycleStartDay);
        SafeStorage.setString(BASE_INCOME_KEY, baseIncome);
        SafeStorage.setString(PALETTE_KEY, currentPalette);
        SafeStorage.setString(FIRST_RUN_KEY, 'true');"""
content = content.replace(vault_old, vault_new)

# Dead view mode switcher (lines ~1979)
dead_switcher = """  document.querySelectorAll('#viewModeSwitcher .m3-mode-icon-btn, #viewModeSwitcher .m3-segment-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic();
      currentViewMode = btn.dataset.mode;
      SafeStorage.setString(VIEW_MODE_KEY, currentViewMode);
      render();
    });
  });"""
content = content.replace(dead_switcher, "")

# Bill save with sanitization
bill_save_old = """      const title = document.getElementById('billTitleInput').value.trim();
      const amount = Number(document.getElementById('billAmountInput').value) || 0;
      const dueDay = Number(document.getElementById('billDayInput').value) || 1;

      if (title && amount > 0) {
        triggerHaptic();
        recurringBills.push({ id: Date.now(), title, amount, dueDay, isPaid: false });
        saveRecurringBills();
        closeModal('billModalBackdrop');
        render();
      }"""
bill_save_new = """      const title = sanitizeText(document.getElementById('billTitleInput').value, 100);
      const amount = sanitizeNumber(document.getElementById('billAmountInput').value, 0, 0, 1e8);
      const dueDay = sanitizeNumber(document.getElementById('billDayInput').value, 1, 1, 31);

      if (title && amount > 0) {
        triggerHaptic();
        recurringBills.push({ id: Date.now(), title, amount, dueDay, isPaid: false });
        saveRecurringBills();
        document.getElementById('billTitleInput').value = '';
        document.getElementById('billAmountInput').value = '';
        document.getElementById('billDayInput').value = '';
        closeModal('billModalBackdrop');
        render();
      } else {
        showToast('Please enter a valid title and amount.');
      }"""
content = content.replace(bill_save_old, bill_save_new)

# Vault import sanitization
import_san_old = """        expenses = data.expenses;
        monthlyBudget = data.monthlyBudget || monthlyBudget;
        cycleStartDay = data.cycleStartDay || cycleStartDay;
        baseIncome = data.baseIncome || baseIncome;
        categoryBudgets = data.categoryBudgets || categoryBudgets;
        recurringBills = data.recurringBills || recurringBills;
        dismissedPatterns = data.dismissedPatterns || dismissedPatterns;
        netWorth = data.netWorth || netWorth;
        goals = data.goals || goals;
        globalTags = data.globalTags || globalTags;
        currentPalette = data.currentPalette || currentPalette;"""
import_san_new = """        expenses = Array.isArray(data.expenses) ? data.expenses : [];
        monthlyBudget = sanitizeNumber(data.monthlyBudget, monthlyBudget, 100, 1e8);
        cycleStartDay = sanitizeNumber(data.cycleStartDay, cycleStartDay, 1, 28);
        baseIncome    = sanitizeNumber(data.baseIncome, baseIncome, 0, 1e9);
        categoryBudgets = (data.categoryBudgets && typeof data.categoryBudgets === 'object') ? data.categoryBudgets : categoryBudgets;
        recurringBills = Array.isArray(data.recurringBills) ? data.recurringBills : recurringBills;
        dismissedPatterns = Array.isArray(data.dismissedPatterns) ? data.dismissedPatterns : dismissedPatterns;
        netWorth = (data.netWorth && typeof data.netWorth === 'object') ? data.netWorth : netWorth;
        goals = Array.isArray(data.goals) ? data.goals : goals;
        globalTags = Array.isArray(data.globalTags) ? data.globalTags : globalTags;
        currentPalette = typeof data.currentPalette === 'string' ? sanitizeText(data.currentPalette, 20) : currentPalette;"""
content = content.replace(import_san_old, import_san_new)

# Blob URL revocation timeout
content = content.replace("setTimeout(() => URL.revokeObjectURL(url), 2000)", "setTimeout(() => URL.revokeObjectURL(url), 10000)")

# FileReader onerror
content = content.replace("reader.readAsText(file);", "reader.onerror = () => showToast('Failed to read backup file.');\n      reader.readAsText(file);")

# Budget edit reject negative
content = content.replace("const val = Number(input.value) || 0;", "const val = sanitizeNumber(input.value, 0, 0, 1e8);")

with open('app.js', 'w') as f:
    f.write(content)
