---
name: Luluna
colors:
  surface: '#f8f9f9'
  surface-dim: '#d9dada'
  surface-bright: '#f8f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f4'
  surface-container: '#edeeee'
  surface-container-high: '#e7e8e8'
  surface-container-highest: '#e1e3e3'
  on-surface: '#191c1c'
  on-surface-variant: '#3f484a'
  inverse-surface: '#2e3131'
  inverse-on-surface: '#f0f1f1'
  outline: '#6f797b'
  outline-variant: '#bfc8ca'
  surface-tint: '#196873'
  primary: '#00434b'
  on-primary: '#ffffff'
  primary-container: '#005c67'
  on-primary-container: '#8dd2df'
  inverse-primary: '#8cd1de'
  secondary: '#006970'
  on-secondary: '#ffffff'
  secondary-container: '#9df0f8'
  on-secondary-container: '#026f77'
  tertiary: '#343e3f'
  on-tertiary: '#ffffff'
  tertiary-container: '#4a5556'
  on-tertiary-container: '#bec9ca'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a8eefb'
  primary-fixed-dim: '#8cd1de'
  on-primary-fixed: '#001f24'
  on-primary-fixed-variant: '#004f58'
  secondary-fixed: '#9df0f8'
  secondary-fixed-dim: '#81d4dc'
  on-secondary-fixed: '#002022'
  on-secondary-fixed-variant: '#004f55'
  tertiary-fixed: '#dae5e6'
  tertiary-fixed-dim: '#bec9ca'
  on-tertiary-fixed: '#131d1e'
  on-tertiary-fixed-variant: '#3e494a'
  background: '#f8f9f9'
  on-background: '#191c1c'
  surface-variant: '#e1e3e3'
typography:
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  container-padding-mobile: 16px
  container-padding-desktop: 32px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style

The design system is anchored in a philosophy of "Clinical Serenity." It bridges the gap between high-precision medical technology and the empathetic nature of human care. The target audience includes patients seeking clear guidance and practitioners requiring efficient data synthesis.

The visual style follows a **Modern Corporate** direction with heavy influences from **Material 3 principles**. It emphasizes clarity through generous whitespace, a structured hierarchy, and a soft tactile feel. The emotional response is intended to be one of immediate relief and quiet confidence, utilizing a "Glassmorphism Lite" approach for overlays to maintain a sense of lightness and transparency.

## Colors

The palette is centered around **Deep Calming Teal**, a color that communicates both professional authority and biological vitality. 

- **Primary**: Used for key actions, active states, and the brand's crescent moon iconography.
- **Secondary**: A muted teal used for supportive graphical elements and secondary buttons.
- **Surface**: A very soft off-white (#F8F9F9) serves as the primary background to reduce eye strain compared to pure white.
- **Functional**: Success (Emerald), Warning (Amber), and Error (Rose) colors should be desaturated to maintain the calming atmosphere.

## Typography

This design system utilizes a dual-font strategy to balance character with utility. **Manrope** is used for all headlines to provide a modern, rounded, and welcoming geometric feel. **Inter** is employed for body copy and labels to ensure maximum legibility and a systematic, clinical precision.

Text colors should never be pure black; use a deep charcoal derived from the primary teal to maintain harmony. For long-form medical explanations, ensure line lengths are capped at 70 characters to maximize readability.

## Layout & Spacing

The layout follows a **Fluid Grid** model based on an 8px base unit (with 4px sub-increments). 

- **Desktop**: 12-column grid with 24px gutters and flexible margins.
- **Tablet**: 8-column grid with 16px gutters.
- **Mobile**: 4-column grid with 16px gutters and 16px side margins.

Horizontal spacing between related components (like a set of chips) should use the 8px `stack-sm` token. Vertical spacing between distinct content sections should use `stack-lg` to reinforce the "calming" aspect of the brand through intentional white space.

## Elevation & Depth

Visual hierarchy is established using **Tonal Layers** rather than heavy shadows. In accordance with Material 3, the background is the lowest level (Level 0). 

- **Surface Level 1**: Standard cards use a subtle 1px border (#E0E3E3) with no shadow.
- **Surface Level 2**: Raised elements (e.g., active modals or floating action buttons) use an **Ambient Shadow**: a soft, ultra-diffused 15% opacity shadow tinted with the primary teal color (0px 4px 20px).
- **Glassmorphism**: Use a `backdrop-filter: blur(12px)` with a 70% white tint for top navigation bars and sticky headers to provide context of the content scrolling beneath.

## Shapes

The shape language is consistently "Soft-Rounded." The primary radius is 12px for standard components like buttons and input fields, while larger containers like cards and modals utilize 16px to 24px. 

This roundedness mimics the biological curves of the moon logo and avoids the "aggressive" sharp corners often found in traditional clinical software, making the AI feel more approachable and less intimidating.

## Components

- **Buttons**: Primary buttons are solid Teal (#005C67) with white text. Secondary buttons are "Tonal" using the Tertiary color (#E8F3F4) with Teal text. All buttons feature 12px corner radii.
- **Input Fields**: Use the "Outlined" Material 3 style. The border should be a soft gray, turning to Primary Teal on focus. Labels should float above the border.
- **Cards**: Backgrounds should be pure white (#FFFFFF) against the off-white surface. Use a 16px corner radius and a subtle 1px border.
- **Chips**: Used for health tags or filter categories. Use a pill-shape (full radius) with a light teal background and no border.
- **AI Chat Bubble**: The assistant's bubbles should use the Primary Teal with white text, positioned on the left. User bubbles should be Surface Level 1 (Light Gray/White) with dark text, positioned on the right.
- **Progress Bars**: Use rounded caps. The track should be the Tertiary color, and the indicator should be a gradient of the Secondary to Primary teal.