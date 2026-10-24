# Fluvi FAB menu, manual add, automation and recurring transaction workflow

This note reconstructs the relevant UX decisions from the original Library design artifacts. It is a design-concept reference, not a claim that every item is already implemented in the app.

## 1. Main navigation

The earlier finance-app concept uses a three-part bottom navigation:
- **Dashboard** — the main financial overview.
- **FAB (+)** — the primary create action, centered and always easy to reach.
- **More** — settings and administrative destinations in one place.

The main FAB is not itself a single hard-coded “create expense” action: its interaction opens the creation menu. The documented recurring-transaction mockup specifically uses a **long press** on the FAB to open the expanded menu.

## 2. FAB menu — documented items

The original “Visszatérő tranzakciós beállítások.png” contains a panel titled **“FAB MENÜ (long tap)”**. Its item order is:

1. **Manuális tranzakció**
2. **Recurring transaction** (highlighted in the mockup)
3. **Sablonból**
4. **Bevétel rögzítése**
5. **Kiadás rögzítése**

A teal **X** close control appears near the bottom of the menu.

### How to trigger each path

- **Manual add:** long-press the central **+** FAB, then choose **Manuális tranzakció**. The related accepted “Add Transaction” screen is the manual form: amount, transaction name/merchant, date/time, category, then **Tranzakció hozzáadása**.
- **Create a recurring transaction:** long-press **+** → choose **Recurring transaction** → choose the trigger type. The mockup then opens the recurring wizard.
- **Start an income/expense shortcut:** long-press **+** → choose **Bevétel rögzítése** or **Kiadás rögzítése**.
- **Create from a template:** long-press **+** → **Sablonból**.
- **Automatic/push-triggered recurring flow:** long-press **+** → **Recurring transaction** → **Push alapú** trigger. This creates a *ghost transaction* (a pending expected transaction) which waits for a matching notification. It does **not** mean that opening the FAB or tapping “Kiadás rögzítése” turns on bank push monitoring.

## 3. Recurring transaction wizard

The top flow in the original design explicitly says:

1. **FAB long tap** — “Hosszan nyomd meg a + gombot”.
2. **Recurring transaction** — “Válaszd a Recurring transaction opciót”.
3. **Trigger típusa** — choose either:
   - **Idő alapú** — occurs on preset dates/times.
   - **Push alapú** — completed/matched based on a notification.
4. **Wizard steps** — configure the expected transaction and its trigger.
5. **Kész** — a ghost transaction is created and waits for the trigger.

The wizard screens include:
- Basic details: name, category, partner/payee, optional note.
- Expected amount: fixed amount, range, or any amount; optional tolerance.
- Frequency and expected due date/window.
- Trigger source/app.
- Push matching fields: amount, partner, date and contextual keywords.
- Completion behavior:
  - **Automatikus teljesítés** — turn the ghost transaction into a regular transaction automatically.
  - **Megerősítést kérek** — show the match and ask the user to confirm (shown selected in the mockup).
  - **Csak jelölje lehetséges egyezésként** — flag a possible match for later manual decision.
- Choose whether the actual amount comes from the push.
- Review the summary and tap **Létrehozás**.

The mockup's example is a monthly rent payment (“Lakbér”, 180 000 Ft, partner Kovács Péter) waiting for a matching Revolut notification. The example is illustrative UI content, not a real user transaction.

## 4. Embedded learning and parser automation

The mockup’s **“BEÁGYAZOTT TANÍTÁS A WIZARDBAN”** panel shows a sample notification:

> Revolut • Ma 13:42  
> 180 000 Ft összeget küldtél  
> neki: Kovács Péter

The user selects the relevant fragments by dragging across the message. The visual legend labels:
- **Összeg** (green)
- **Partner** (blue)
- **Dátum** (purple)
- **Környezet (kulcsszó)** (yellow)

These selections help define a contextual match rule; the parser must not independently grab the first number or confuse a transaction amount with a balance. Matching should use the source profile, context, amount tolerance, partner text, keywords and date window together.

For the push-import onboarding, the separate eight-screen concept covers:
1. Push import overview and profiles.
2. Create profile and choose the source app.
3. Profile waiting for training.
4. Select a captured notification.
5. Select the amount.
6. Select merchant/partner and contextual fields.
7. Test the proposed recognition rule.
8. Review uncertain interpretations manually.

A profile can monitor before it has a valid rule. Only sufficiently reliable, tested rules should create transactions automatically; ambiguous matches go to manual review.

## 5. Visual source artifacts (original filenames)

These Library artifacts are the relevant visual sources identified for this flow:

- `Visszatérő tranzakciós beállítások.png` — FAB long-press menu, recurring wizard, push trigger, embedded training, ghost transaction, completion options.
- `UI konzisztencia összehasonlítása.png` — accepted manual “Add Transaction” UI vs current/proposed recurring first-menu consistency.
- `Ujj tranzakció hozzáadása kategóriával.png` — manual add screen and inline floating category dropdown.
- `Mobil pénzügyi alkalmazás tervezete.png` — overall Dashboard / central FAB / More navigation concept and More sheet.
- `App onboarding a push import funkcióhoz.png` — eight-screen push-import profile, training, testing and review workflow.

## 6. Consistency rule from the comparison

The comparison artifact’s subtitle states the principle: **“Ugyanaz a logika, ugyanaz a vizuális hierarchia, csak a létrehozás módja különbözik.”**

The accepted manual-add flow and recurring flow should therefore share the same visual hierarchy and entry-menu conventions. Recurring creation differs by its wizard and trigger setup, not by inventing an unrelated initial interaction pattern.

## 7. Source and implementation status

The descriptions above are reconstructed from the saved design artifacts’ extracted content and titles. The original PNG binaries are stored in the ChatGPT Library. They have **not** yet been added as binary files to this Git branch; this document is the text reconstruction only. Do not treat the mockups as proof that these exact interactions already exist in the current application code.
