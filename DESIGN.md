# Design System Document: The Clinical Curator

## 1. Overview & Creative North Star
The visual identity of this design system is anchored in a concept we call **"The Clinical Curator."** In the high-stakes world of healthcare, we must move beyond the "generic blue dashboard" and create an environment that feels both scientifically precise and editorially sophisticated. 

The "Clinical Curator" aesthetic rejects the cluttered, line-heavy interfaces of legacy medical software. Instead, it embraces **intentional asymmetry, expansive breathing room, and tonal depth.** We treat data not as a list to be managed, but as a narrative to be presented. By utilizing high-contrast typography scales and layered surfaces, we convey an immediate sense of authority, security, and calm efficiency.

---

## 2. Colors & Surface Architecture
Our palette is a sophisticated range of "Medical Blues" and "Clinical Neutrals" designed to reduce cognitive load while emphasizing brand trust.

### The Color Tokens
- **Primary:** `#0058be` (The anchor of trust and action)
- **Primary Container:** `#2170e4` (Used for depth and interaction states)
- **Surface:** `#f8f9ff` (Our canvas; a cool, sterile but welcoming white-blue)
- **Tertiary:** `#924700` (Used sparingly for high-attention medical alerts)

### The "No-Line" Rule
To achieve a premium editorial feel, **1px solid borders are strictly prohibited for sectioning.** We do not "box" content. Instead, boundaries must be defined through:
1.  **Background Color Shifts:** Placing a `surface-container-low` component against a `surface` background.
2.  **Vertical White Space:** Using our spacing scale to create distinct groupings.

### Surface Hierarchy & Nesting
Think of the UI as a physical desk of stacked, frosted glass sheets. Use the `surface-container` tiers to define "importance" through nesting:
- **Surface (Base):** The furthest back layer.
- **Surface-Container-Low:** For secondary navigation or sidebar elements.
- **Surface-Container-Lowest:** For the primary content cards, providing a "lift" that feels natural and light.

### The "Glass & Gradient" Rule
Flat colors can feel "template-like." To add soul to the interface:
- **Floating Elements:** Use semi-transparent surface colors with a `backdrop-blur` (Glassmorphism) for modals or role-based navigation overlays.
- **CTAs:** Apply a subtle linear gradient from `primary` (#0058be) to `primary_container` (#2170e4) to provide a tactile, premium finish.

---

## 3. Typography: The Editorial Pulse
Clear communication is a medical requirement. We use a dual-typeface system to balance character with clinical readability.

- **Display & Headlines (Manrope):** This geometric sans-serif provides a modern, authoritative voice. Use `display-lg` (3.5rem) for hero stats (e.g., "Total Patient Count") to create an editorial hierarchy.
- **Body & Labels (Inter):** Chosen for its exceptional legibility in small data sets and form fields.

**The Hierarchy Goal:** Use dramatic scale shifts. A `headline-lg` title next to a `body-md` description creates a professional "magazine" layout that guides the eye efficiently through patient data.

---

## 4. Elevation & Depth
In this design system, depth is a functional tool, not a decoration.

- **Tonal Layering:** Avoid shadows where a color shift will suffice. Place a `surface-container-lowest` card on a `surface-container-low` background to create a soft, natural separation.
- **Ambient Shadows:** When an element must float (e.g., a "Confirm Appointment" button), use extra-diffused shadows. Set blur values to 20px+ and opacity between 4%–8%. The shadow color should be a tint of `on-surface` (`#0b1c30`), never pure black.
- **The "Ghost Border" Fallback:** If a container requires a boundary for accessibility (e.g., input fields), use a "Ghost Border." Apply the `outline-variant` token at 15% opacity. **Never use 100% opaque borders.**

---

## 5. Components

### Cards & Data Containers
- **Styling:** Forbid divider lines. Use `md` (0.75rem) or `lg` (1rem) corner radii from the Roundedness Scale.
- **Separation:** Use vertical padding to separate header from body.
- **Interaction:** On hover, transition the background from `surface-container-lowest` to `surface-container-high` rather than adding a heavy shadow.

### Buttons
- **Primary:** Gradient fill (`primary` to `primary_container`), `full` (9999px) roundedness for high-touch actions.
- **Secondary:** Use `secondary_container` with `on_secondary_container` text. No border.
- **Tertiary:** Text-only with an icon, reserved for low-priority navigation.

### Input Fields
- **State:** Use `surface_container_lowest` for the field background. 
- **Focus:** Transition the "Ghost Border" from 15% opacity to 100% `primary` color.
- **Typography:** Ensure `label-md` is used for persistent floating labels to maintain context.

### Role-Based Navigation
- **Patient vs. Doctor:** Use subtle `surface_tint` shifts in the navigation bar to provide immediate visual feedback on the current role context.
- **Layout:** Use asymmetrical positioning—place primary navigation on the left with high "breathable" margins to separate it from the functional data grid.

---

## 6. Do's and Don'ts

### Do
- **Do** use `display-lg` for single, high-impact numbers (e.g., "12 Visits Today").
- **Do** utilize the `xl` (1.5rem) corner radius for large landing page sections to soften the "medical" feel.
- **Do** prioritize `surface-bright` for areas where users must input critical medical data.

### Don't
- **Don't** use 1px dividers to separate list items; use a 4px-8px vertical gap or a subtle `surface-variant` background on alternating rows.
- **Don't** use high-saturation reds for anything other than `error` states. 
- **Don't** cram information. If a screen feels full, increase the page length and use "The Clinical Curator" editorial spacing to let the data breathe.

### Accessibility Note
While we use "Ghost Borders" and tonal shifts, ensure that the contrast ratio between `on_surface` and its respective `surface` container always meets WCAG AA standards for readability.