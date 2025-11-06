# Pet Age Input Enhancement

## Overview
Enhance pet age input to support two methods:
1. **Birthdate Entry (MM/YYYY)** - Automatically calculates current age in months
2. **Direct Age Entry (months)** - Automatically calculates approximate birthdate

## Current Implementation
- Users can only enter age in months directly
- Age is stored as `initialAge` in the database
- Dynamic age calculation adds months based on `createdAt` date

## Proposed Changes

### 1. New UI Component: `PetAgeInputField`
**Location**: `lib/core/widgets/user/pets/pet_age_input_field.dart`

**Features**:
- Toggle between "Birthdate" and "Age" input modes
- Birthdate mode: MM/YYYY format picker
- Age mode: Direct months input
- Auto-calculation in both directions
- Visual indicators showing calculated values
- Validation for both input types

### 2. Database Schema (No changes needed)
- Continue using `initialAge` field
- Calculate `initialAge` from birthdate when user chooses that option
- Store in months as before

### 3. Files to Modify

#### A. `/lib/pages/mobile/pets/add_edit_pet_page.dart`
**Changes**:
- Replace existing age TextField with new `PetAgeInputField`
- Handle birthdate → age conversion
- Calculate `initialAge` based on chosen input method

#### B. `/lib/core/widgets/user/assessment/assessment_step_one.dart`
**Changes**:
- Replace age input with new `PetAgeInputField` (line ~971)
- Support both input methods during assessment

#### C. `/lib/core/widgets/user/assessment/assessment_step_three.dart`  
**Changes**:
- Update pet creation/selection to handle new age input

### 4. Calculation Logic

#### From Birthdate → Age (months):
```dart
int calculateAgeInMonths(int birthMonth, int birthYear) {
  final now = DateTime.now();
  final age = (now.year - birthYear) * 12 + (now.month - birthMonth);
  return age < 0 ? 0 : age; // Never negative
}
```

#### From Age (months) → Approximate Birthdate:
```dart
DateTime calculateBirthdate(int ageInMonths) {
  final now = DateTime.now();
  return DateTime(
    now.year - (ageInMonths ~/ 12),
    now.month - (ageInMonths % 12),
    1, // Day defaults to 1st
  );
}
```

#### For Database (initialAge):
```dart
// When adding new pet
initialAge = chosenAgeInMonths;

// When editing existing pet
int monthsSinceCreation = (DateTime.now().year - pet.createdAt.year) * 12 
                        + (DateTime.now().month - pet.createdAt.month);
initialAge = currentAge - monthsSinceCreation;
```

## Benefits
1. **User Convenience**: Some users remember birthdate better than age in months
2. **Accuracy**: Birthdate is more precise than estimated age
3. **Flexibility**: Users can choose their preferred input method
4. **Backwards Compatible**: Existing pets with `initialAge` continue to work

## Implementation Priority
1. Create `PetAgeInputField` widget (HIGH)
2. Update Add/Edit Pet page (HIGH)
3. Update Assessment flows (MEDIUM)
4. Add helper text and tooltips (LOW)

## Testing Checklist
- [ ] Add new pet with birthdate
- [ ] Add new pet with age in months
- [ ] Edit existing pet (age should be current, not initial)
- [ ] Switch between input modes
- [ ] Validate edge cases (very old pets, negative values, future dates)
- [ ] Assessment flow with both input types
- [ ] Database: verify `initialAge` calculated correctly
- [ ] UI: birthdate picker works on all devices
- [ ] Age auto-updates on pets list after time passes
