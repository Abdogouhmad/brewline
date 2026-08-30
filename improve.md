# Improvements
- please be aware of:
  - creating needed UI components within `shared/ui` folder
  - dont create a new UI component if it already exists in `shared/ui` folder
  - document the code with example usgae of the UI components

## UI improve 
- use `shared/ui/ui_card` for card UI inside `_buildFilters` in `admin/pages/sales_log_page.dart` and `staff_table.dart` for `_StaffCard`.
- filters of date, product, waiter should be in one line row
- for action edit given in staff table give dialog for desktop and bottom sheet for mobile and tablet
- for adding production in desktop mode use dialog while bottom sheet for mobile and tablet
- in dashboard
  - fix the quick actions buttons and redesign them
  - redesign the dashboard layout 
  - redesign the shift status
- settings
  - redesign the settings page
  - use the credentials within account section like the name of the user admin with options to change password, logout or reset the database and redirect to onboarding
- redesign the sidebar of admin with simple and clean design
## functionality
- fix the date picker to be able to select old date not only one month period selected

## create or delete
- create a needed ui within shared folder and import it where needed
- delete unnecessary code, and files
## polish
- polish the ui to be consistent and easy to use
- polish the code functionality
- document the code
