# PrepMateAI Resume Optimizer UI — Stitch Design System & Screens Context

This directory contains the visual mockups and production HTML code for the **PrepMateAI Resume Optimizer** mobile experience, retrieved directly from Google Stitch.

- **Project Title:** PrepMateAI Resume Optimizer UI
- **Project ID:** `14495604217461013871`
- **Device Profile:** Mobile (390px base width / 780px 2x rendered width)
- **Theme:** Executive Kinetic (Light Mode default)
- **Primary Font:** [Hanken Grotesk](https://fonts.google.com/specimen/Hanken+Grotesk)
- **Icon Set:** [Material Symbols Outlined](https://fonts.google.com/icons)

---

## 🎨 Design System & Visual Tokens

### Core Color Palette
| Token Name | Hex Code | Purpose / Usage |
| :--- | :--- | :--- |
| **`primary`** | `#003FB3` / `#2457D6` | Brand primary actions, active stepper indicators, primary CTA buttons |
| **`primary-soft`** | `#E9EFFF` | Button hover/pressed backgrounds, active chip surfaces |
| **`secondary`** | `#006A65` / `#087E78` | Metric progress gauges, match percentages, telemetry indicators |
| **`secondary-soft`** | `#E1F4F1` | Success/matched badges, positive metric pill backgrounds |
| **`surface` / `background`** | `#F9F9FF` | Base canvas background |
| **`surface-container-lowest`** | `#FFFFFF` | Card surfaces, container elevation 1 |
| **`surface-container-low`** | `#F1F3FF` | Muted backgrounds, inner sub-cards, diff background |
| **`surface-container`** | `#E9EDFF` | Input backgrounds, structural panels |
| **`surface-container-high`** | `#E1E8FF` | Badge backgrounds, accent highlights |
| **`surface-container-highest`**| `#D9E2FC` | Inactive stepper bars, divider fills |
| **`on-surface`** | `#121B2E` | High-contrast body text & titles |
| **`on-surface-variant`** | `#434654` | Secondary text, labels, timestamps, captions |
| **`outline`** | `#747686` | Standard structural borders (1px) |
| **`outline-variant`** | `#C3C5D7` | Subtle dividers, card borders |
| **`success`** | `#168653` | High ATS match, approved suggestions |
| **`warning`** | `#A15C00` | Keyword warnings, formatting advisories |
| **`error`** | `#BA1A1A` | Missing critical skills, destructive actions |

---

## 📱 Screen Inventory & Architecture

### 1. Optimize Resume
- **Screen ID:** `dd5a73dfe5f9485c97792254abcc52ef`
- **Image:** [`stitch/resume_optimizer/images/screen_1_optimize_resume.png`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/images/screen_1_optimize_resume.png)
- **Code:** [`stitch/resume_optimizer/code/screen_1_optimize_resume.html`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/code/screen_1_optimize_resume.html)
- **Role in Flow:** Initial onboarding/input step (Step 1 of 4).
- **Key UI Elements:**
  - Header with Back action, AI credits badge (`12 AI`), user avatar.
  - 4-step progress stepper (`1. Target`, `2. Analysis`, `3. Suggest`, `4. ATS Score`).
  - Selected Resume Card with file size, last modified date, and `Change Resume` modal trigger.
  - Target Job specification: Job Title input, Company Name input, and Job Description paste/import area.
  - Optimization Goal selector (Keyword Matching, Executive Polish, Career Pivot).
  - Floating bottom sticky CTA: `Analyze & Optimize`.

---

### 2. Job Match Analysis
- **Screen ID:** `2d3660d52692416ba53cc216c5135b04`
- **Image:** [`stitch/resume_optimizer/images/screen_2_job_match_analysis.png`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/images/screen_2_job_match_analysis.png)
- **Code:** [`stitch/resume_optimizer/code/screen_2_job_match_analysis.html`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/code/screen_2_job_match_analysis.html)
- **Role in Flow:** Analytical diagnostic report (Step 2 of 4).
- **Key UI Elements:**
  - Radial / circular match score gauge (e.g., `74% Compatibility`).
  - Score comparison badges (`+18% potential improvement`).
  - Breakdown categories: Hard Skills match, Soft Skills match, Experience alignment, Education fit.
  - Keyword Venn / overlap pills: Matched keywords (green chips) vs Missing required keywords (amber/red chips).
  - Recruiter Insight card explaining why specific skills impact screening.
  - Primary CTA: `Review AI Suggestions`.

---

### 3. AI Suggestions
- **Screen ID:** `74f182e0662b410695a0f9c44b4eb611`
- **Image:** [`stitch/resume_optimizer/images/screen_3_ai_suggestions.png`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/images/screen_3_ai_suggestions.png)
- **Code:** [`stitch/resume_optimizer/code/screen_3_ai_suggestions.html`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/code/screen_3_ai_suggestions.html)
- **Role in Flow:** Recommendation triage (Step 3 of 4).
- **Key UI Elements:**
  - Filter chips: `All (7)`, `High Impact (3)`, `Skills (2)`, `Formatting (2)`.
  - Batch action: `Apply All High Impact`.
  - Interactive recommendation cards:
    - Target bullet point with highlighted diff preview.
    - AI rationale badge explaining metric improvement.
    - Quick actions: `Accept`, `Edit` (navigates to Screen 4), `Dismiss`.
  - Floating progress summary bar indicating total accepted suggestions.

---

### 4. Suggestion Editor
- **Screen ID:** `1fabc709b66f4d6faf322c7e1a5b84ea`
- **Image:** [`stitch/resume_optimizer/images/screen_4_suggestion_editor.png`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/images/screen_4_suggestion_editor.png)
- **Code:** [`stitch/resume_optimizer/code/screen_4_suggestion_editor.html`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/code/screen_4_suggestion_editor.html)
- **Role in Flow:** Granular bullet-level text refinement.
- **Key UI Elements:**
  - Context banner: Role, company, and timeline for the bullet under review.
  - Split / stacked diff view: Original text (with strike-throughs) vs AI Proposed text (with highlighted additions).
  - Live editable textarea for user customization.
  - Tone / Style pills: `Quantify Metrics`, `More Executive`, `Shorter`, `Action-Oriented`.
  - Word count and keyword density telemetry.
  - Action footer: `Reset`, `Apply to Resume`.

---

### 5. Optimization Summary
- **Screen ID:** `abfcb1a4324d4edd9e39fd51dc85e77e`
- **Image:** [`stitch/resume_optimizer/images/screen_5_optimization_summary.png`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/images/screen_5_optimization_summary.png)
- **Code:** [`stitch/resume_optimizer/code/screen_5_optimization_summary.html`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/code/screen_5_optimization_summary.html)
- **Role in Flow:** Post-optimization milestone review.
- **Key UI Elements:**
  - Side-by-side Before vs After milestone scorecard:
    - Match score: `68%` ➔ `92%` (+24%).
    - ATS pass rate: `Likely Passed` (from `Moderate Risk`).
  - Stat counters: Number of keywords added, bullets optimized, tone enhancements.
  - Changelog accordion listing all accepted modifications with reversal option.
  - Dual action buttons: `Run Full ATS Check` (Screen 6) & `Preview Final Resume` (Screen 7).

---

### 6. ATS Analysis
- **Screen ID:** `a78b0be2836b4ce58b22942946945b3a`
- **Image:** [`stitch/resume_optimizer/images/screen_6_ats_analysis.png`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/images/screen_6_ats_analysis.png)
- **Code:** [`stitch/resume_optimizer/code/screen_6_ats_analysis.html`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/code/screen_6_ats_analysis.html)
- **Role in Flow:** ATS compliance and parseability audit (Step 4 of 4).
- **Key UI Elements:**
  - ATS Readiness Score dial (e.g., `96/100 - Excellent`).
  - Compliance checklist:
    - Section Headings Standardization (Passed).
    - File Format & Font Readability (Passed).
    - Table / Column layout warnings (Clean).
    - Contact Info detectability (Passed).
  - Keyword density frequency table with job description benchmark frequencies.
  - Recruiter simulation readout showing how major ATS engines (Workday, Greenhouse, Lever) parse the content.

---

### 7. Optimized Resume Preview
- **Screen ID:** `e22c57de3d8d471983c302d7467ad573`
- **Image:** [`stitch/resume_optimizer/images/screen_7_optimized_resume_preview.png`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/images/screen_7_optimized_resume_preview.png)
- **Code:** [`stitch/resume_optimizer/code/screen_7_optimized_resume_preview.html`](file:///c:/Users/vkcha/Desktop/Assets/project/prepMateAi/stitch/resume_optimizer/code/screen_7_optimized_resume_preview.html)
- **Role in Flow:** Final document review, export, and distribution.
- **Key UI Elements:**
  - Floating zoom controls (`-`, `100%`, `+`, Fit-to-screen).
  - High-fidelity PDF/Document canvas rendering with subtle page shadows.
  - Page switcher (`Page 1 of 1`).
  - Export action sheet: `Download PDF`, `Download Word (.docx)`, `Copy Text`.
  - Next step accelerators: `Generate Matching Cover Letter`, `Prep Interview Questions for this Job`.

---

## 🚀 How to Use in Flutter / Web Development

1. **Flutter Implementation Mapping:**
   - Colors map directly to `ThemeData` / `ColorScheme` using the Hex codes listed in `stitch_context.json`.
   - Layouts are structured as standard `SingleChildScrollView` with `Column` padding of 16px (`EdgeInsets.symmetric(horizontal: 16)`).
   - Steppers and cards use `Container` with `BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFFDDE2EA)))`.
2. **Web / HTML Preview:**
   - Each screen in `stitch/resume_optimizer/code/*.html` is completely standalone and can be opened in any browser or preview server directly.
