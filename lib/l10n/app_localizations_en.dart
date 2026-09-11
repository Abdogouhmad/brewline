// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BrewLine';

  @override
  String get brandTagline => 'for management';

  @override
  String get settingsLanguageSystemDefault => 'System default';

  @override
  String get settingsLanguageChooseTooltip => 'Choose language';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmBody =>
      'You will need to sign in again to take orders.';

  @override
  String get logoutCancel => 'Cancel';

  @override
  String get logoutAction => 'Log out';

  @override
  String get logoutTooltip => 'Log out';

  @override
  String get logoutListSubtitle => 'End this session on the device.';

  @override
  String get onboardingSetupHeadline => 'Set up your café';

  @override
  String get onboardingUsernameLabel => 'Username';

  @override
  String get onboardingUsernameHint => 'Choose a username';

  @override
  String get onboardingSetPin => 'Set your PIN';

  @override
  String get onboardingConfirmPin => 'Confirm your PIN';

  @override
  String get onboardingFinishSetup => 'Finish setup';

  @override
  String get onboardingUsernameInvalid =>
      '3–24 characters, letters, numbers, or _';

  @override
  String onboardingPinLength(num count) {
    return 'PIN must be exactly $count digits';
  }

  @override
  String get onboardingPinMismatch => 'PINs don\'t match';

  @override
  String get onboardingPinTaken =>
      'That PIN is already in use — pick a different one';

  @override
  String get onboardingSetupFailed => 'Setup failed. Please try again.';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginEnterPin => 'Enter your PIN';

  @override
  String get loginIncorrectPin => 'Incorrect PIN';

  @override
  String loginLockedOut(num seconds) {
    return 'Too many attempts. Try again in ${seconds}s';
  }

  @override
  String get loginButton => 'Log in';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionLoadMore => 'Load more';

  @override
  String get actionAllWaiters => 'All waiters';

  @override
  String get walletCashoutSmsTitle => 'Cash out & print report';

  @override
  String get walletCashoutSmsSubtitle =>
      'Close the shift, print a sales summary, and sign out';

  @override
  String walletCashoutPrintFailed(Object error) {
    return 'Shift closed, but the report couldn\'t print — check the printer ($error)';
  }

  @override
  String get walletCashoutPrinted =>
      'Shift closed — report sent to the printer';

  @override
  String get walletReportPrinted => 'Report printed';

  @override
  String walletPrintRetryFailed(Object error) {
    return 'Retry failed — check the printer ($error)';
  }

  @override
  String get walletCashoutConfirmTitle => 'Cash out and print report?';

  @override
  String get walletCashoutConfirmBody =>
      'This will close your shift, print the final sales report and log you out. You will need to sign in again to take orders.';

  @override
  String get walletCashOutAction => 'Cash out';

  @override
  String get walletCashoutDialogTitle => 'Cash counted';

  @override
  String get walletCashoutDrawerLabel => 'Cash in the drawer';

  @override
  String get walletCashoutHelper =>
      'The sum of cash you can hand over at the end.';

  @override
  String get walletCashoutInvalidAmount => 'Enter a valid amount';

  @override
  String walletCashoutExpected(Object amount) {
    return 'Expected: $amount — variance is computed against this amount.';
  }

  @override
  String get walletCashoutConfirmButton => 'Confirm cash out';

  @override
  String get printReportSmsTitle => 'Print report';

  @override
  String get printReportSmsSubtitle =>
      'Print a preview of your shift, without closing it';

  @override
  String printReportPrintFailed(Object error) {
    return 'Couldn\'t print the report — check the printer ($error)';
  }

  @override
  String get printReportEmpty => 'No orders yet — the report is a placeholder';

  @override
  String get printReportSent => 'Report sent to the printer — shift still open';

  @override
  String get updateTitle => 'App update';

  @override
  String get updateCheckingPill => 'Checking for updates…';

  @override
  String get updateCheckFailedPill => 'Update check failed';

  @override
  String get updateAvailablePill => 'New update available';

  @override
  String get updateUpToDatePill => 'You are up to date';

  @override
  String get updateCheckingCard => 'Contacting the update server…';

  @override
  String get updateCheckFailedMessage =>
      'Could not check for updates. Check the network connection and try again.';

  @override
  String get updateErrorGeneric =>
      'An error occurred while checking for updates.';

  @override
  String get updateErrorNoBuild =>
      'This release has no installable build for this device.';

  @override
  String updateErrorDownloadFailed(Object detail) {
    return 'Download failed: $detail';
  }

  @override
  String updateErrorIntegrity(Object detail) {
    return 'The update failed the checksum verification: $detail';
  }

  @override
  String updateErrorInstall(Object detail) {
    return 'The update could not be installed: $detail';
  }

  @override
  String get updateVersionDetails => 'Version details';

  @override
  String get updateCurrentVersion => 'Current version';

  @override
  String get updateLatestVersion => 'Latest version';

  @override
  String get updateDownloadSize => 'Download size';

  @override
  String get updateLastChecked => 'Last checked';

  @override
  String get updateNever => 'Never';

  @override
  String get updateLastResult => 'Last result';

  @override
  String get updateResultUpToDate => 'Up to date';

  @override
  String get updateResultAvailable => 'Update available';

  @override
  String get updateResultMandatory => 'Update required';

  @override
  String get updateResultFailed => 'Check failed';

  @override
  String get updateResultNeverChecked => 'Never checked';

  @override
  String get updateUnknown => 'Unknown';

  @override
  String get updateWhatsNew => 'What\'s new';

  @override
  String get updateNoReleaseNotes =>
      'No release notes available for this release.';

  @override
  String get updateDownloadingCardTitle => 'Downloading update…';

  @override
  String get updateDownloadInProgress => 'Download in progress';

  @override
  String get updateDownloadingNote =>
      'The update is verified by checksum before it is installed. Please do not close the app.';

  @override
  String get updateReadyBody =>
      'Download complete. The app will close and relaunch to install.';

  @override
  String get updateInstallNow => 'Install now';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateTryAgain => 'Try again';

  @override
  String get updateCheckNow => 'Check for updates';

  @override
  String get updateAutoCheckTitle => 'Check automatically';

  @override
  String get updateAutoCheckSubtitle => 'Look for updates when the app starts';

  @override
  String get updateSectionSystem => 'System';

  @override
  String get updateSectionTitle => 'Update';

  @override
  String get updateSectionSubtitle =>
      'Keep this terminal on the latest version';

  @override
  String get updateSoftwareUpdate => 'Software update';

  @override
  String get updateSummaryAvailable => 'An update is available';

  @override
  String get updateSummaryDownloading => 'Downloading…';

  @override
  String get updateSummaryReady => 'Ready to install';

  @override
  String get updateRequiredTitle => 'Upgrade required';

  @override
  String get updateRequiredBody =>
      'BrewLine needs to be updated before you can continue. This version is no longer supported.';

  @override
  String get updateRequiredChecking => 'Checking…';

  @override
  String get updateRequiredChecksumNote =>
      'Your update is verified by checksum before it is applied.';

  @override
  String get updateRequiredReady =>
      'Ready to install. The app will close and relaunch.';

  @override
  String get updateRequiredDownloadFailedNote =>
      'Check your internet connection and try again.';

  @override
  String get updateRequiredDownloadButton => 'Download update';

  @override
  String get adminCashoutLogTitle => 'Cashout log';

  @override
  String get adminCashoutLogSubtitle =>
      'Every finalized shift close, filterable by date or waiter.';

  @override
  String get adminCashoutLogError => 'Couldn\'t load the cashout log.';

  @override
  String get adminCashoutLogEmpty => 'No cashouts match these filters.';

  @override
  String get adminCashoutLogFilters => 'Filters';

  @override
  String get adminCashoutLogWaiterLabel => 'Waiter';

  @override
  String get adminCashoutLogPickRangeHelp => 'Filter cashouts by date';

  @override
  String get adminCashoutColDateTime => 'Date & Time';

  @override
  String get adminCashoutColOrders => 'Orders Made';

  @override
  String get adminCashoutColWaiter => 'Waiter Name';

  @override
  String get adminCashoutColTotal => 'Total Made';

  @override
  String get adminCashoutColCashCounted => 'Cash Counted';

  @override
  String get adminCashoutColVariance => 'Variance';

  @override
  String get refundReceiptPrinted => 'Refund receipt sent to printer';

  @override
  String refundReceiptPrintFailed(Object error) {
    return 'Print failed: $error';
  }

  @override
  String get refundSuccessVoided => 'Order voided';

  @override
  String get refundSuccess => 'Refund successful';

  @override
  String get refundBodyVoided => 'Voided and refunded';

  @override
  String get refundBodyPartial => 'Refunded';

  @override
  String refundBodyOnOrder(Object orderId) {
    return 'on order #$orderId';
  }

  @override
  String get refundPrintReceipt => 'Print refund receipt';

  @override
  String get refundDone => 'Done';

  @override
  String get refundFormLoadFailed => 'Couldn\'t load this order.';

  @override
  String get refundFormReasonLabel => 'Reason (required)';

  @override
  String get refundFormReasonHint => 'e.g. wrong item entered';

  @override
  String get refundFormTitle => 'Refund order';

  @override
  String get refundFormModeCorrect => 'Correct Order';

  @override
  String get refundFormModeVoid => 'Void Order';

  @override
  String get refundFormLineItems => 'Line items';

  @override
  String get refundFormCurrentTotal => 'Current total';

  @override
  String get refundFormRefundAmount => 'Refund amount';

  @override
  String get refundFormVoidEntireOrder => 'Void entire order';

  @override
  String get refundFormOriginalTotal => 'Original total';

  @override
  String get refundFormVoidNote =>
      'The order is marked voided but kept in records for audit. Nothing is deleted.';

  @override
  String refundFormConfirmVoid(Object amount) {
    return 'Void & refund $amount';
  }

  @override
  String refundFormConfirmPartial(Object amount) {
    return 'Refund $amount';
  }

  @override
  String get refundFormProcessing => 'Processing…';

  @override
  String refundFormOrder(Object orderNumber) {
    return 'Order $orderNumber';
  }

  @override
  String get refundFormTotal => 'Total';

  @override
  String get refundFormRemoveItem => 'Remove item';

  @override
  String get refundFormReduceQty => 'Reduce quantity';

  @override
  String refundFormFailed(Object error) {
    return 'Refund failed: $error';
  }

  @override
  String get adminNavDashboard => 'Dashboard';

  @override
  String get adminNavReports => 'Reports';

  @override
  String get adminNavMenu => 'Menu';

  @override
  String get adminNavInventory => 'Inventory';

  @override
  String get adminNavStaff => 'Staff';

  @override
  String get adminNavSalesLog => 'Sales log';

  @override
  String get adminNavCashoutLog => 'Cashout log';

  @override
  String get adminNavSettings => 'Settings';

  @override
  String get adminDashboardRevenue => 'Revenue';

  @override
  String get adminDashboardOrders => 'Orders';

  @override
  String get adminDashboardItemsSold => 'Items sold';

  @override
  String get adminDashboardAvgOrder => 'Avg. order';

  @override
  String get adminDashboardGreetingMorning => 'Good morning';

  @override
  String get adminDashboardGreetingAfternoon => 'Good afternoon';

  @override
  String get adminDashboardGreetingEvening => 'Good evening';

  @override
  String get adminDashboardPeriodToday => 'Today';

  @override
  String get adminDashboardPeriodWeek => 'Last 7 days';

  @override
  String get adminDashboardPeriodMonth => 'Last 30 days';

  @override
  String get adminRevenueOverviewTitle => 'Revenue overview';

  @override
  String get adminRevenueOverTimeTitle => 'Revenue over time';

  @override
  String get adminRevenueTrendError => 'Couldn\'t load the revenue trend.';

  @override
  String get adminReportTitle => 'Performance';

  @override
  String get adminReportSubtitle => 'Revenue, what sells and when.';

  @override
  String get adminDashboardQuickActions => 'Quick actions';

  @override
  String get adminDashboardQuickAddStaff => 'Add staff';

  @override
  String get adminDashboardQuickAddStaffDesc => 'Invite a team member';

  @override
  String get adminDashboardQuickViewReports => 'View reports';

  @override
  String get adminDashboardQuickViewReportsDesc => 'Revenue & performance';

  @override
  String get adminDashboardQuickAddProduct => 'Add product';

  @override
  String get adminDashboardQuickAddProductDesc => 'Grow the menu';

  @override
  String get adminLowStockTitle => 'Low stock';

  @override
  String get adminLowStockError => 'Couldn\'t load stock levels.';

  @override
  String get adminLowStockHealthy => 'Stock levels look healthy — no alerts.';

  @override
  String adminStockQuantityLeft(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left',
      one: '1 left',
    );
    return '$_temp0';
  }

  @override
  String adminStockQuantityLeftAmount(Object amount) {
    return '$amount left';
  }

  @override
  String get adminRestockShort => '+ Restock';

  @override
  String get adminStockOverviewTitle => 'Stock overview';

  @override
  String get adminStockOverviewEmpty =>
      'No stock items yet — add ingredients to track stock here.';

  @override
  String adminStockRestockCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need restock',
      one: '1 needs restock',
    );
    return '$_temp0';
  }

  @override
  String adminStockServingsLeft(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '1 serving',
    );
    return '· ~$_temp0';
  }

  @override
  String get adminStockBadgeOut => '· out';

  @override
  String get adminStockBadgeLow => '· low';

  @override
  String get adminShiftStatusTitle => 'Shift status';

  @override
  String get adminShiftStatusOnShift => 'On shift';

  @override
  String get adminShiftStatusSignedInAs => 'Signed in as';

  @override
  String get adminShiftStatusError => 'Couldn\'t load shift status.';

  @override
  String get adminShiftStatusEmpty => 'No staff on the roster yet.';

  @override
  String get adminShiftStatusActive => 'Active';

  @override
  String get adminShiftStatusIdle => 'Idle';

  @override
  String get adminShiftStatusCashedOut => 'Cashed out';

  @override
  String get adminShiftStatusNoShiftYet => 'No shift yet';

  @override
  String get adminShiftStatusNeverLoggedIn => 'Never logged in';

  @override
  String adminShiftLoggedInAt(String time) {
    return 'Logged in $time';
  }

  @override
  String adminShiftLoggedOutLastActive(String time) {
    return 'Logged out · last active $time';
  }

  @override
  String adminShiftDetailCashedOut(String checkIn, String cashOut) {
    return 'Logged in $checkIn · Cashed out $cashOut';
  }

  @override
  String adminShiftDurationLong(num hours, num minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String adminShiftDurationShort(num minutes) {
    return '${minutes}m';
  }

  @override
  String get adminTopProductsTitle => 'Top products';

  @override
  String get adminTopProductsError => 'Couldn\'t load top products.';

  @override
  String get adminTopProductsEmpty => 'No sales recorded in this period.';

  @override
  String adminTopProductsSold(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sold',
      one: '1 sold',
    );
    return '$_temp0';
  }

  @override
  String get adminCategoryMixTitle => 'Category mix';

  @override
  String get adminCategoryMixError => 'Couldn\'t load the mix.';

  @override
  String get adminTeamPerformanceTitle => 'Team performance';

  @override
  String get adminTeamPerformanceError => 'Couldn\'t load team sales.';

  @override
  String get adminTeamPerformanceEmpty =>
      'No waiter-attributed sales this period.';

  @override
  String adminTeamOrders(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String get adminBusiestHoursTitle => 'Busiest hours';

  @override
  String get adminBusiestHoursError => 'Couldn\'t load the hour data.';

  @override
  String adminBusiestHoursTotal(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$_temp0';
  }

  @override
  String adminBusiestCellTooltip(
    String day,
    String start,
    String end,
    num count,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
    );
    return '$day · $start–$end · $_temp0';
  }

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionActions => 'Actions';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get inventorySubtitle =>
      'Track raw ingredients and who consumes them.';

  @override
  String get inventoryAddIngredient => 'Add ingredient';

  @override
  String get inventoryStockMovementsLog => 'Stock movements log';

  @override
  String get inventoryError => 'Couldn\'t load inventory.';

  @override
  String get inventoryEmpty =>
      'No ingredients yet. Add one to start tracking stock.';

  @override
  String stockQuantityWithUnitLeft(String amount) {
    return '$amount left';
  }

  @override
  String get stockBadgeOut => 'Out';

  @override
  String get stockBadgeLow => 'Low';

  @override
  String restockDialogTitle(String name) {
    return 'Restock $name';
  }

  @override
  String restockCurrentlyOnHand(String amount) {
    return 'Currently $amount on hand';
  }

  @override
  String get restockQuantityReceived => 'Quantity received';

  @override
  String restockStoredAs(String amount, String unit) {
    return 'Stored as $amount $unit';
  }

  @override
  String get restockEnterPositiveQty => 'Enter a positive quantity';

  @override
  String get restockNoteOptional => 'Note (optional)';

  @override
  String get restockNoteHint => 'e.g. Supplier name, PO #';

  @override
  String get restockAction => 'Restock';

  @override
  String get restockProgress => 'Restocking…';

  @override
  String restockSnackbar(String name, String amount) {
    return '$name restocked (+$amount)';
  }

  @override
  String get ingredientAddTitle => 'Add ingredient';

  @override
  String get ingredientEditTitle => 'Edit ingredient';

  @override
  String get ingredientName => 'Ingredient name';

  @override
  String get ingredientNameHint => 'e.g. Coffee beans, Milk, Cups';

  @override
  String get ingredientEnterName => 'Enter a name';

  @override
  String get ingredientLowStockBelow => 'Low-stock alert below';

  @override
  String get ingredientAlertDesc =>
      'Alerts when on hand drops to this level or below';

  @override
  String get ingredientNonNegative => 'Enter 0 or a positive number';

  @override
  String get ingredientTrackedUnit => 'Tracked unit';

  @override
  String get ingredientUnitWeight => 'Weight (g)';

  @override
  String get ingredientUnitVolume => 'Volume (ml)';

  @override
  String get ingredientUnitUnits => 'Whole units';

  @override
  String get ingredientUnitLockedNote =>
      'The unit can\'t change once the ingredient has stock history.';

  @override
  String get ingredientSave => 'Save ingredient';

  @override
  String get ingredientSaving => 'Saving…';

  @override
  String ingredientAddedSnackbar(String name) {
    return '$name added to inventory';
  }

  @override
  String ingredientUpdatedSnackbar(String name) {
    return '$name updated';
  }

  @override
  String get movementsTitle => 'Stock movements';

  @override
  String get movementsSubtitle =>
      'Every change to an ingredient\'s quantity, newest first.';

  @override
  String get movementsError => 'Couldn\'t load the stock movements.';

  @override
  String get movementsEmpty => 'No movements match these filters.';

  @override
  String get movementsFilters => 'Filters';

  @override
  String get movementsDateRange => 'Date range';

  @override
  String get movementsAllDates => 'All dates';

  @override
  String get movementsClearDateFilter => 'Clear date filter';

  @override
  String get movementsDatePickerHelp => 'Filter movements by date';

  @override
  String get movementsIngredient => 'Ingredient';

  @override
  String get movementsAllIngredients => 'All ingredients';

  @override
  String get movementsReason => 'Reason';

  @override
  String get movementsAllReasons => 'All reasons';

  @override
  String get movementsWhen => 'When';

  @override
  String get movementsChange => 'Change';

  @override
  String get movementsRefNote => 'Ref / note';

  @override
  String movementsOrderRef(int orderId) {
    return 'Order #$orderId';
  }

  @override
  String get movementsReasonSale => 'Sale';

  @override
  String get movementsReasonRefund => 'Refund / restock';

  @override
  String get movementsReasonRestock => 'Restock';

  @override
  String get movementsReasonAdjustment => 'Manual adjustment';

  @override
  String get movementsReasonWaste => 'Waste';

  @override
  String get movementsPillRefund => 'Refund';

  @override
  String get movementsPillAdjustment => 'Adjustment';

  @override
  String get recipeTitle => 'What does it consume per serving?';

  @override
  String get recipeSubtitle =>
      'Bind the product to ingredients you stock — e.g. 1 cup → 12 g beans. This drives the low-stock alerts and how many cups you can still make.';

  @override
  String get recipeBindIngredient => 'Bind an ingredient in stock';

  @override
  String get recipeSelectIngredient => 'Select an ingredient…';

  @override
  String get recipeNoMoreIngredients => 'No more ingredients left to add';

  @override
  String recipePerUnitSold(String unit) {
    return 'Per $unit sold';
  }

  @override
  String get recipeRemoveBinding => 'Remove binding';

  @override
  String recipeYieldHint(String bulk, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '1 serving',
    );
    return '$bulk → about $_temp0';
  }

  @override
  String get menuCatalogTitle => 'Catalog';

  @override
  String get menuSubtitle =>
      'Manage prices, stock and availability across the menu.';

  @override
  String get menuAddProduct => 'Add product';

  @override
  String get productTableError => 'Couldn\'t load the catalog.';

  @override
  String get productTableEmpty => 'No products yet — add your first one.';

  @override
  String get productUncategorised => 'Uncategorised';

  @override
  String get productStockSoldOut => 'Sold out';

  @override
  String get productStockNotTracked => 'Stock not tracked yet';

  @override
  String get productStockOutRestock => 'Out of stock — restock';

  @override
  String productStockLow(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left',
      one: '1 left',
    );
    return 'Low · ~$_temp0';
  }

  @override
  String productStockServingsLeft(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '1 serving',
    );
    return '~$_temp0 left';
  }

  @override
  String get productActionsTooltip => 'Product actions';

  @override
  String productDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get productDeleteBody =>
      'Removes it from the menu and stock tracking. Past orders keep their own snapshots and stay in the reports.';

  @override
  String productDeletedSnackbar(String name) {
    return '$name deleted';
  }

  @override
  String get productAddTitle => 'Add product';

  @override
  String get productEditTitle => 'Edit product';

  @override
  String get productName => 'Product name';

  @override
  String get productEnterName => 'Enter a name';

  @override
  String get productPrice => 'Price (DH)';

  @override
  String get productMustBePositive => 'Must be positive';

  @override
  String get productCategory => 'Category';

  @override
  String get productCategoryHint => 'e.g. Coffee, Soft drinks';

  @override
  String get productMenuPhoto => 'Menu photo';

  @override
  String get productImportFromGallery => 'Import from gallery';

  @override
  String get productAvailableOnMenu => 'Available on the menu';

  @override
  String get productHideFromWaiters =>
      'Hides the product from waiters when off';

  @override
  String get productSaveChanges => 'Save changes';

  @override
  String get productAddToMenu => 'Add to menu';

  @override
  String get productSaving => 'Saving…';

  @override
  String productAddedSnackbar(String name) {
    return '$name added to the menu';
  }

  @override
  String productUpdatedSnackbar(String name) {
    return '$name updated';
  }

  @override
  String get productGalleryError => 'Couldn\'t open the gallery.';

  @override
  String get waiterNavOrders => 'Orders';

  @override
  String get waiterNavMenu => 'Menu';

  @override
  String get waiterNavSettings => 'Settings';

  @override
  String get shellMore => 'More';

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuError => 'Couldn\'t load the menu.';

  @override
  String get menuEmpty => 'No products on the menu yet.';

  @override
  String ordersTitleWithItems(int number, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Order #$number · $_temp0';
  }

  @override
  String ordersTitle(int number) {
    return 'Order #$number';
  }

  @override
  String get ordersCleared => 'Order cleared';

  @override
  String get ordersUndo => 'Undo';

  @override
  String get ordersEmpty => 'No items yet';

  @override
  String get ordersEmptyHint => 'Tap products in Menu to add them here.';

  @override
  String get ordersTotal => 'Total';

  @override
  String ordersCharge(String amount) {
    return 'Charge $amount';
  }

  @override
  String get ordersClearOrder => 'Clear order';

  @override
  String get ordersRemoveItem => 'Remove item';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsSession => 'Session';

  @override
  String get settingsReceipts => 'Receipts';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsHardware => 'Hardware';

  @override
  String get settingsAccountProfile => 'Account profile';

  @override
  String get settingsAccountProfileSubtitle =>
      'Manage your session and shift reports';

  @override
  String get settingsOnShift => 'On shift';

  @override
  String get settingsGeneralTitle => 'General';

  @override
  String get settingsGeneralSubtitle => 'Language and appearance';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Interface language for this device';

  @override
  String get settingsChangePasswordTitle => 'Change password';

  @override
  String get settingsChangePasswordSubtitle => 'Update your login credentials';

  @override
  String get settingsLogoutSubtitle => 'End this session on the device';

  @override
  String get settingsPrintingTitle => 'Printing';

  @override
  String get settingsPrintingSubtitle => 'Receipts printed with each order';

  @override
  String get settingsKitchenReceiptTitle => 'Kitchen receipt';

  @override
  String get settingsKitchenReceiptSubtitle =>
      'Send a copy to the kitchen printer';

  @override
  String get settingsClientReceiptTitle => 'Client receipt';

  @override
  String get settingsClientReceiptSubtitle =>
      'Hand the guest their printed copy';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String get settingsThemeSubtitle => 'Match your light / dark preference';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsAccountSubtitle => 'Your sign-in and session';

  @override
  String get settingsSignedInAs => 'Signed in as';

  @override
  String get settingsResetTitle => 'Reset business data';

  @override
  String get settingsResetSubtitle => 'Delete everything and return to setup';

  @override
  String get settingsResetConfirmTitle => 'Reset business data?';

  @override
  String get settingsResetConfirmBody =>
      'This deletes the admin account and all business data (orders, staff, products) and returns you to the setup screen.';

  @override
  String get settingsResetFieldLabel => 'Type RESET to confirm';

  @override
  String get settingsResetFieldHelper => 'This cannot be undone';

  @override
  String get settingsResetButton => 'Reset';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleWaiter => 'Waiter';

  @override
  String get roleStaffMember => 'Staff member';

  @override
  String get printerTitle => 'Printer';

  @override
  String get printerSubtitle => 'Which receipt printer this terminal uses';

  @override
  String get printerUsb => 'USB';

  @override
  String get printerNetwork => 'Network';

  @override
  String get printerIpAddress => 'IP address';

  @override
  String get printerIpHint => '192.168.1.50';

  @override
  String get printerPort => 'Port';

  @override
  String get printerPortHelper => 'Raw ESC/POS port (default 9100, JetDirect)';

  @override
  String get printerSave => 'Save';

  @override
  String get printerInvalidPort => 'Port must be a number between 1 and 65535';

  @override
  String get printerSaved => 'Printer settings saved';

  @override
  String get printerUsbInfo =>
      'The USB printer is detected automatically. Switch to Network to set an address.';

  @override
  String get printerReceiptLanguageLabel => 'Receipt language';

  @override
  String get printerReceiptLanguageHelper =>
      'The language printed receipts are in, independent of the app language. Defaults to French.';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordCurrentPin => 'Current PIN';

  @override
  String get changePasswordNewPin => 'New PIN';

  @override
  String get changePasswordNewPinHint => '4 digits, keeps hashed at rest';

  @override
  String get changePasswordConfirmPin => 'Confirm new PIN';

  @override
  String get changePasswordMismatch => 'PINs do not match';

  @override
  String get changePasswordShow => 'Show';

  @override
  String get changePasswordHide => 'Hide';

  @override
  String get changePasswordUpdating => 'Updating…';

  @override
  String get changePasswordUpdate => 'Update';

  @override
  String get changePasswordNoSession => 'No active session';

  @override
  String get changePasswordWrongPin =>
      'The current PIN doesn\'t match this account.';

  @override
  String get changePasswordUpdated => 'Password updated successfully';

  @override
  String changePasswordPinLength(int count) {
    return 'Use exactly $count digits';
  }

  @override
  String get changePasswordPinTaken =>
      'That PIN is already in use — pick a different one';

  @override
  String settingsFooterCopyright(int year) {
    return '© $year BrewLine';
  }

  @override
  String get appInfoError => 'Could not load app info';

  @override
  String get appInfoName => 'Name';

  @override
  String get appInfoVersion => 'Version';

  @override
  String get appInfoBuild => 'Build';

  @override
  String get appInfoPackage => 'Package';

  @override
  String get appInfoLicenses => 'Open source licenses';

  @override
  String get availabilityOnMenu => 'On menu';

  @override
  String get availabilitySoldOut => 'Sold out';

  @override
  String get dateFilterRange => 'Date range';

  @override
  String get dateFilterAllDates => 'All dates';

  @override
  String get dateFilterToday => 'Today';

  @override
  String get dateFilterClearTooltip => 'Show all dates';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get salesLogSubtitle =>
      'Every product line sold, filterable by date, product or waiter.';

  @override
  String get salesLogError => 'Couldn\'t load the sales log.';

  @override
  String get salesLogEmpty => 'No sales match these filters.';

  @override
  String get salesLogDatePickerHelp => 'Filter sales by date';

  @override
  String get salesLogProductLabel => 'Product';

  @override
  String get salesLogAllProducts => 'All products';

  @override
  String get salesLogWaiterLabel => 'Waiter';

  @override
  String get salesLogColDate => 'Date';

  @override
  String get salesLogColOrder => 'Order #';

  @override
  String get salesLogColProduct => 'Product';

  @override
  String get salesLogColQty => 'Qty';

  @override
  String get salesLogColTotal => 'Total';

  @override
  String get salesLogTotal => 'Total: ';

  @override
  String get salesLogRefundTooltip => 'Refund this order';

  @override
  String get salesLogBadgeVoided => 'Voided';

  @override
  String get salesLogBadgeRefunded => 'Refunded';

  @override
  String get staffTitle => 'Team';

  @override
  String get staffAdd => 'Add staff';

  @override
  String get staffTableError => 'Couldn\'t load the staff roster.';

  @override
  String get staffTableEmpty => 'No staff yet — add your first member.';

  @override
  String get staffActionsTooltip => 'Staff actions';

  @override
  String get staffDeactivate => 'Deactivate';

  @override
  String get staffActivate => 'Activate';

  @override
  String staffDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get staffDeactivateBody =>
      'They can no longer sign in, but their sales history stays on record.';

  @override
  String staffDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get staffDeleteBody =>
      'This removes the account permanently and detaches their sales from a named waiter. Prefer deactivating so history keeps its attribution.';

  @override
  String staffDeletedSnackbar(String name) {
    return '$name deleted';
  }

  @override
  String get staffInactive => 'Inactive';

  @override
  String get staffActive => 'Active';

  @override
  String get staffColName => 'Name';

  @override
  String get staffColUsername => 'Username';

  @override
  String get staffColStatus => 'Status';

  @override
  String staffSummaryActive(num active, num total) {
    return '$active of $total active';
  }

  @override
  String get staffSummaryEmpty => 'Team is empty — add your first member';

  @override
  String get staffSummaryLoading => 'Loading team…';

  @override
  String get staffFormAddTitle => 'Add staff member';

  @override
  String get staffFormEditTitle => 'Edit staff member';

  @override
  String get staffFormName => 'Display name';

  @override
  String get staffFormNameHint => 'Shown on shift and performance views';

  @override
  String get staffFormNameRequired => 'Enter a display name';

  @override
  String get staffFormUsername => 'Username';

  @override
  String get staffFormUsernameHint => 'Used to sign in on the POS';

  @override
  String get staffFormUsernameRequired => 'Enter a username';

  @override
  String get staffFormUsernameTooShort => 'At least 3 characters';

  @override
  String get staffFormUsernameInvalid =>
      'Letters, numbers and underscores only';

  @override
  String get staffFormPin => 'PIN';

  @override
  String get staffFormNewPin => 'New PIN (blank keeps current)';

  @override
  String get staffFormEditNote =>
      'Account stays active. Deactivate instead to block sign-in.';

  @override
  String get staffFormSaveChanges => 'Save changes';

  @override
  String get staffFormAddMember => 'Add member';

  @override
  String get staffFormSaving => 'Saving…';

  @override
  String staffFormAddedSnackbar(String name) {
    return '$name added to staff';
  }

  @override
  String staffFormUpdatedSnackbar(String name) {
    return '$name updated';
  }

  @override
  String staffFormErrorPinLength(int count) {
    return 'Use exactly $count digits';
  }

  @override
  String get appStartupTitle => 'brewline failed to start';

  @override
  String get appStartupCopy => 'Copy error';

  @override
  String get appStartupCopied => 'Error copied';
}
