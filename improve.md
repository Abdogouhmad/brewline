## Problem

The current folder structure places all providers in a centralized `shared/providers/` directory. This creates several issues:

1. **Tight Coupling**: Feature-specific state (e.g., `orderControllerProvider`, `productsProvider`) is co-located with truly shared utilities, making it unclear which providers are reusable across features vs. feature-specific.

2. **Poor Scalability**: As more features are added (admin, kitchen, inventory), the `shared/providers/` folder will accumulate unrelated state logic, making it harder to navigate and maintain.

3. **Dependency Direction**: Currently, `features/waiter/` depends on state defined in `shared/`, but if another feature needs different order/product logic, it's unclear whether to add it to `shared/` or create duplicates.

4. **Unclear Ownership**: No clear indication of which provider belongs to which feature domain, leading to confusion during debugging and refactoring.

## Current Structure Issues

```
lib/
  shared/
    providers/
      product_provider.dart      ← waiter-specific (Product, OrderController, etc.)
      [... other providers]
```

This should be organized by feature ownership.

## Proposed Solution

Restructure providers to follow feature boundaries:

```
lib/
  features/
    waiter/
      data/
        providers/               ← waiter-specific state
          product_provider.dart
          order_provider.dart
      presentation/
        pages/
        widgets/
  
  shared/
    providers/                   ← only truly shared state
      theme_provider.dart
      app_state_provider.dart    (if needed)
    ui/
    widgets/
```

### Key Changes

1. **Move feature-specific providers** into `features/{feature}/data/providers/`
   - `product_provider.dart` → `features/waiter/data/providers/`
   - Any future admin/kitchen providers stay in their own feature folder

2. **Keep shared state in `shared/providers/`**
   - Theme preferences (already there via `theme_controller.dart`)
   - App-level configuration or cross-feature state

3. **Update imports** throughout the codebase to reflect the new structure

4. **Add `data/` layer** for consistency with feature architecture (prepares for future database/API integration)

## Benefits

- ✅ Clear ownership and feature boundaries
- ✅ Easier to understand dependencies
- ✅ Simpler to add new features without cluttering shared utilities
- ✅ Aligns with clean architecture / feature-driven design principles
- ✅ Scales well as the app grows (admin feature, kitchen display system, etc.)

## Acceptance Criteria

- [ ] All waiter feature providers moved to `features/waiter/data/providers/`
- [ ] All imports updated to reference new provider locations
- [ ] `shared/providers/` contains only truly shared state
- [ ] Project compiles and tests pass (if tests exist)
- [ ] No functional changes to the app behavior

## Notes

- This is a refactoring task with no user-facing changes
- Can be done in one pass or incrementally (move one provider at a time)
- Consider creating an architecture decision record (ADR) documenting the folder structure rules for future features
