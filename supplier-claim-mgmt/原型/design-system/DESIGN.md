---
name: Enterprise Core Logic
colors:
  surface: '#f7f9fc'
  surface-dim: '#d8dadd'
  surface-bright: '#f7f9fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f7'
  surface-container: '#eceef1'
  surface-container-high: '#e6e8eb'
  surface-container-highest: '#e0e3e6'
  on-surface: '#191c1e'
  on-surface-variant: '#414755'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f4'
  outline: '#727786'
  outline-variant: '#c1c6d7'
  surface-tint: '#0059c7'
  primary: '#0057c2'
  on-primary: '#ffffff'
  primary-container: '#006ef2'
  on-primary-container: '#fefcff'
  inverse-primary: '#afc6ff'
  secondary: '#266d00'
  on-secondary: '#ffffff'
  secondary-container: '#85fa51'
  on-secondary-container: '#287100'
  tertiary: '#7d5400'
  on-tertiary: '#ffffff'
  tertiary-container: '#9d6a00'
  on-tertiary-container: '#fffbff'
  error: '#FF4D4F'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d9e2ff'
  primary-fixed-dim: '#afc6ff'
  on-primary-fixed: '#001a43'
  on-primary-fixed-variant: '#004398'
  secondary-fixed: '#88fd54'
  secondary-fixed-dim: '#6de039'
  on-secondary-fixed: '#062100'
  on-secondary-fixed-variant: '#1a5200'
  tertiary-fixed: '#ffddb0'
  tertiary-fixed-dim: '#ffba45'
  on-tertiary-fixed: '#281800'
  on-tertiary-fixed-variant: '#614000'
  background: '#f7f9fc'
  on-background: '#191c1e'
  surface-variant: '#e0e3e6'
  text-primary: '#000000E0'
  text-secondary: '#00000073'
  border-base: '#D9D9D9'
  info-processing: '#1677FF'
  success-cyan: '#13C2C2'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
  label-bold:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 22px
  caption:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 20px
  mono-data:
    fontFamily: monospace
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-page: 24px
---

## Brand & Style

This design system is engineered for high-stakes enterprise back-office environments where information density and task efficiency are paramount. The system prioritizes functional clarity over decorative elements, ensuring that complex financial data and multi-step approval workflows remain legible and actionable.

The aesthetic follows a **Corporate / Modern** direction, heavily influenced by systematic efficiency. It utilizes a structured hierarchy, a neutral base with purposeful color accents for status tracking, and a rigorous adherence to a 4px/8px spatial rhythm. The goal is to evoke a sense of reliability, precision, and institutional stability, minimizing cognitive load for power users who interact with the system for extended periods.

Key visual principles:
- **Clarity over Visuals:** No gradients, shadows are used only for functional depth, and typography is optimized for readability.
- **State-Driven Design:** Color is never decorative; it is a tool for communicating urgency and system status.
- **Density:** Maximum data visibility per viewport to reduce scrolling in complex audit and settlement tasks.

## Colors

The palette is anchored by a functional blue primary, used for primary actions and "in-progress" states. The background is a cool gray to reduce eye strain and provide a neutral canvas for white data cards.

**Functional Color Logic:**
- **Primary (#1677FF):** Used for main CTAs, active navigation states, and "In Review" or "Processing" statuses.
- **Success (#52C41A):** Specifically for "Settled," "Approved," or "Paid" states.
- **Warning (#FAAD14):** Used for "Rejected" or "Needs Attention" states that aren't system errors.
- **Error (#FF4D4F):** Reserved for "Voided," "Declined," or critical validation failures.
- **Neutral Layers:** Background (`#F0F2F5`) provides contrast for the Surface (`#FFFFFF`) containers. Borders (`#D9D9D9`) define the structural grid of tables and inputs.

## Typography

This design system uses a clean, systematic sans-serif stack. While the tokens specify **Inter** for universal web compatibility and modern legibility, in implementation, it falls back to the local system sans-serif (e.g., PingFang SC for macOS, Microsoft YaHei for Windows) to ensure maximum rendering performance.

**Usage Guidelines:**
- **Headlines:** Reserved for page titles and major section headers within cards.
- **Body-md:** The default size for all standard text and input content.
- **Body-sm:** Used for high-density tables and nested metadata.
- **Mono-data:** Specifically for financial figures, claim numbers, and transaction IDs to ensure character alignment in tables.
- **Labels:** Used for form field labels and table headers, typically paired with a 500 or 600 weight for scannability.

## Layout & Spacing

The layout utilizes a **Fixed Grid** model for content areas to maintain readability on ultra-wide monitors, while the sidebar remains fixed.

**Grid Architecture:**
- **Layout Model:** Left navigation (208px or 64px collapsed) with a top header for breadcrumbs.
- **Content Area:** White cards (`#FFFFFF`) set against the background (`#F0F2F5`) with 24px outer margins.
- **Internal Spacing:** A strict 8px-based system. High-density tables use "Small" padding (8px vertical) to maximize row visibility.
- **Breakpoints:**
  - **Desktop (Default):** 1440px. 12-column grid inside cards for forms.
  - **Compact:** 1024px. Sidebar collapses to icons only.
  - **Tablet:** 768px. Content reflows to a single column; tables become horizontally scrollable.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** rather than heavy shadows. This maintains a clean, professional "flat" look that performs well in data-heavy environments.

- **Level 0 (Background):** `#F0F2F5`. The base for the entire application.
- **Level 1 (Cards/Surface):** `#FFFFFF`. Used for the main content containers. Features a 1px border (`#D9D9D9`) or an extremely subtle soft shadow (0 2px 8px rgba(0,0,0,0.06)).
- **Level 2 (Popovers/Modals):** Floating elements use a medium ambient shadow (0 6px 16px rgba(0,0,0,0.08)) to distinguish them from the base cards.
- **Interactivity:** Elements like table rows highlight on hover with a subtle tint (`#F5F5F5`) rather than changing elevation.

## Shapes

The design system uses a **Soft** shape language to balance the "clinical" nature of enterprise data with modern approachability.

- **Standard Radius (4px - 6px):** Used for buttons, input fields, and tags. This maintains a structured, professional appearance.
- **Container Radius (8px):** Used for the main cards and modals to create a distinct framing for content sections.
- **Large Radius (Pill):** Strictly reserved for status Tags/Chips to distinguish them from actionable buttons.

## Components

### Data Tables (High Density)
- **Header:** Background `#FAFAFA`, text weight 600, 13px font.
- **Cell Padding:** 8px vertical, 12px horizontal.
- **Features:** Must include a fixed "Action" column on the right for row-level operations (View, Edit, Void). 
- **Summary Row:** Financial tables must include a sticky bottom row for "Total Amount" using `label-bold`.

### Status Tags
- **Draft:** Default gray border/text.
- **Processing (e.g., Under Review):** Primary blue ghost-style (tinted background, solid border).
- **Success (e.g., Paid):** Solid green background with white text for high visibility.
- **Error (e.g., Voided):** Solid red background.

### Approval Timeline
- **Completed:** Green check icon, solid green line. Includes timestamp and approver name.
- **Current:** Primary blue pulse or border highlight. This is the focus point for the user.
- **Pending/Future:** Dashed gray line, gray circular outline icon.
- **Rejected/Returned:** Red cross icon; comment section must be auto-expanded and highlighted with a light red background.

### Cards
- Standard detail pages use cards to group related info (e.g., "Basic Information," "Fee Breakdown").
- Cards should have a title bar with 16px padding and a bottom border separating it from the content.

### Forms
- **Labels:** Top-aligned for better vertical scanning.
- **Density:** 2-column or 3-column layouts within cards to prevent long vertical scrolling.
- **Actions:** Fixed footer bar for "Submit/Approve/Reject" on long detail pages.