import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Product/brand name. Not translated, kept as a key so it is defined once.
  ///
  /// In en, this message translates to:
  /// **'BrewLine'**
  String get appName;

  /// Tagline shown next to the BrewLine wordmark on auth screens
  ///
  /// In en, this message translates to:
  /// **'for management'**
  String get brandTagline;

  /// Language setting option meaning 'follow the operating system locale'
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystemDefault;

  /// Tooltip on the language dropdown control in Settings
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get settingsLanguageChooseTooltip;

  /// Title of the confirm-dialog shown before signing out
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// Body of the confirm-dialog shown before signing out
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to take orders.'**
  String get logoutConfirmBody;

  /// Cancel button in the logout confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get logoutCancel;

  /// Confirm button in the logout dialog
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutAction;

  /// Tooltip on the app-bar logout icon button
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutTooltip;

  /// Subtitle under the Log out list tile on the Settings page
  ///
  /// In en, this message translates to:
  /// **'End this session on the device.'**
  String get logoutListSubtitle;

  /// Header message under the branding on the first-run setup screen
  ///
  /// In en, this message translates to:
  /// **'Set up your café'**
  String get onboardingSetupHeadline;

  /// Label of the username field on the setup screen
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get onboardingUsernameLabel;

  /// Hint text of the username field on the setup screen
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get onboardingUsernameHint;

  /// Label above the keypad at the PIN-set step of setup
  ///
  /// In en, this message translates to:
  /// **'Set your PIN'**
  String get onboardingSetPin;

  /// Label above the keypad at the PIN-confirm step of setup
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get onboardingConfirmPin;

  /// Submit button on the setup screen
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get onboardingFinishSetup;

  /// Inline validation error for the username field when the value is not 3-24 letters/numbers/underscores
  ///
  /// In en, this message translates to:
  /// **'3–24 characters, letters, numbers, or _'**
  String get onboardingUsernameInvalid;

  /// Inline validation error for the setup PIN when it has the wrong number of digits
  ///
  /// In en, this message translates to:
  /// **'PIN must be exactly {count} digits'**
  String onboardingPinLength(num count);

  /// Inline validation error when the confirm-PIN does not match the entered PIN
  ///
  /// In en, this message translates to:
  /// **'PINs don\'t match'**
  String get onboardingPinMismatch;

  /// Error shown when the chosen PIN is already used by another account
  ///
  /// In en, this message translates to:
  /// **'That PIN is already in use — pick a different one'**
  String get onboardingPinTaken;

  /// Generic error shown when persisting the setup failed
  ///
  /// In en, this message translates to:
  /// **'Setup failed. Please try again.'**
  String get onboardingSetupFailed;

  /// Header message under the branding on the PIN login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// Label above the numeric keypad on the login screen
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get loginEnterPin;

  /// Error shown after a failed PIN attempt on the login screen
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get loginIncorrectPin;

  /// Countdown message shown while the keypad is throttled after too many failed attempts
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {seconds}s'**
  String loginLockedOut(num seconds);

  /// Submit button on the login screen
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get actionLoadMore;

  /// No description provided for @actionAllWaiters.
  ///
  /// In en, this message translates to:
  /// **'All waiters'**
  String get actionAllWaiters;

  /// No description provided for @walletCashoutSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash out & print report'**
  String get walletCashoutSmsTitle;

  /// No description provided for @walletCashoutSmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Close the shift, print a sales summary, and sign out'**
  String get walletCashoutSmsSubtitle;

  /// No description provided for @walletCashoutPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Shift closed, but the report couldn\'t print — check the printer ({error})'**
  String walletCashoutPrintFailed(Object error);

  /// No description provided for @walletCashoutPrinted.
  ///
  /// In en, this message translates to:
  /// **'Shift closed — report sent to the printer'**
  String get walletCashoutPrinted;

  /// No description provided for @walletReportPrinted.
  ///
  /// In en, this message translates to:
  /// **'Report printed'**
  String get walletReportPrinted;

  /// No description provided for @walletPrintRetryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed — check the printer ({error})'**
  String walletPrintRetryFailed(Object error);

  /// No description provided for @walletCashoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash out and print report?'**
  String get walletCashoutConfirmTitle;

  /// No description provided for @walletCashoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will close your shift, print the final sales report and log you out. You will need to sign in again to take orders.'**
  String get walletCashoutConfirmBody;

  /// No description provided for @walletCashOutAction.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get walletCashOutAction;

  /// No description provided for @walletCashoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash counted'**
  String get walletCashoutDialogTitle;

  /// No description provided for @walletCashoutDrawerLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash in the drawer'**
  String get walletCashoutDrawerLabel;

  /// No description provided for @walletCashoutHelper.
  ///
  /// In en, this message translates to:
  /// **'The sum of cash you can hand over at the end.'**
  String get walletCashoutHelper;

  /// No description provided for @walletCashoutInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get walletCashoutInvalidAmount;

  /// No description provided for @walletCashoutExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected: {amount} — variance is computed against this amount.'**
  String walletCashoutExpected(Object amount);

  /// No description provided for @walletCashoutConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm cash out'**
  String get walletCashoutConfirmButton;

  /// No description provided for @printReportSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Print report'**
  String get printReportSmsTitle;

  /// No description provided for @printReportSmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print a preview of your shift, without closing it'**
  String get printReportSmsSubtitle;

  /// No description provided for @printReportPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t print the report — check the printer ({error})'**
  String printReportPrintFailed(Object error);

  /// No description provided for @printReportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders yet — the report is a placeholder'**
  String get printReportEmpty;

  /// No description provided for @printReportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent to the printer — shift still open'**
  String get printReportSent;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'App update'**
  String get updateTitle;

  /// No description provided for @updateCheckingPill.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateCheckingPill;

  /// No description provided for @updateCheckFailedPill.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get updateCheckFailedPill;

  /// No description provided for @updateAvailablePill.
  ///
  /// In en, this message translates to:
  /// **'New update available'**
  String get updateAvailablePill;

  /// No description provided for @updateUpToDatePill.
  ///
  /// In en, this message translates to:
  /// **'You are up to date'**
  String get updateUpToDatePill;

  /// No description provided for @updateCheckingCard.
  ///
  /// In en, this message translates to:
  /// **'Contacting the update server…'**
  String get updateCheckingCard;

  /// No description provided for @updateCheckFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Check the network connection and try again.'**
  String get updateCheckFailedMessage;

  /// No description provided for @updateErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while checking for updates.'**
  String get updateErrorGeneric;

  /// No description provided for @updateErrorNoBuild.
  ///
  /// In en, this message translates to:
  /// **'This release has no installable build for this device.'**
  String get updateErrorNoBuild;

  /// No description provided for @updateErrorDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {detail}'**
  String updateErrorDownloadFailed(Object detail);

  /// No description provided for @updateErrorIntegrity.
  ///
  /// In en, this message translates to:
  /// **'The update failed the checksum verification: {detail}'**
  String updateErrorIntegrity(Object detail);

  /// No description provided for @updateErrorInstall.
  ///
  /// In en, this message translates to:
  /// **'The update could not be installed: {detail}'**
  String updateErrorInstall(Object detail);

  /// No description provided for @updateVersionDetails.
  ///
  /// In en, this message translates to:
  /// **'Version details'**
  String get updateVersionDetails;

  /// No description provided for @updateCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get updateCurrentVersion;

  /// No description provided for @updateLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get updateLatestVersion;

  /// No description provided for @updateDownloadSize.
  ///
  /// In en, this message translates to:
  /// **'Download size'**
  String get updateDownloadSize;

  /// No description provided for @updateLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked'**
  String get updateLastChecked;

  /// No description provided for @updateNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get updateNever;

  /// No description provided for @updateLastResult.
  ///
  /// In en, this message translates to:
  /// **'Last result'**
  String get updateLastResult;

  /// No description provided for @updateResultUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get updateResultUpToDate;

  /// No description provided for @updateResultAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateResultAvailable;

  /// No description provided for @updateResultMandatory.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateResultMandatory;

  /// No description provided for @updateResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Check failed'**
  String get updateResultFailed;

  /// No description provided for @updateResultNeverChecked.
  ///
  /// In en, this message translates to:
  /// **'Never checked'**
  String get updateResultNeverChecked;

  /// No description provided for @updateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get updateUnknown;

  /// No description provided for @updateWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updateWhatsNew;

  /// No description provided for @updateNoReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'No release notes available for this release.'**
  String get updateNoReleaseNotes;

  /// No description provided for @updateDownloadingCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading update…'**
  String get updateDownloadingCardTitle;

  /// No description provided for @updateDownloadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Download in progress'**
  String get updateDownloadInProgress;

  /// No description provided for @updateDownloadingNote.
  ///
  /// In en, this message translates to:
  /// **'The update is verified by checksum before it is installed. Please do not close the app.'**
  String get updateDownloadingNote;

  /// No description provided for @updateReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Download complete. The app will close and relaunch to install.'**
  String get updateReadyBody;

  /// No description provided for @updateInstallNow.
  ///
  /// In en, this message translates to:
  /// **'Install now'**
  String get updateInstallNow;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get updateTryAgain;

  /// No description provided for @updateCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheckNow;

  /// No description provided for @updateAutoCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check automatically'**
  String get updateAutoCheckTitle;

  /// No description provided for @updateAutoCheckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Look for updates when the app starts'**
  String get updateAutoCheckSubtitle;

  /// No description provided for @updateSectionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get updateSectionSystem;

  /// No description provided for @updateSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateSectionTitle;

  /// No description provided for @updateSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep this terminal on the latest version'**
  String get updateSectionSubtitle;

  /// No description provided for @updateSoftwareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Software update'**
  String get updateSoftwareUpdate;

  /// No description provided for @updateSummaryAvailable.
  ///
  /// In en, this message translates to:
  /// **'An update is available'**
  String get updateSummaryAvailable;

  /// No description provided for @updateSummaryDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get updateSummaryDownloading;

  /// No description provided for @updateSummaryReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to install'**
  String get updateSummaryReady;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'BrewLine needs to be updated before you can continue. This version is no longer supported.'**
  String get updateRequiredBody;

  /// No description provided for @updateRequiredChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get updateRequiredChecking;

  /// No description provided for @updateRequiredChecksumNote.
  ///
  /// In en, this message translates to:
  /// **'Your update is verified by checksum before it is applied.'**
  String get updateRequiredChecksumNote;

  /// No description provided for @updateRequiredReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to install. The app will close and relaunch.'**
  String get updateRequiredReady;

  /// No description provided for @updateRequiredDownloadFailedNote.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get updateRequiredDownloadFailedNote;

  /// No description provided for @updateRequiredDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download update'**
  String get updateRequiredDownloadButton;

  /// Settings section title for backup & restore
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get backupDataSectionTitle;

  /// Settings card title for the backup & restore section
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupSectionTitle;

  /// Settings card subtitle for the backup & restore section
  ///
  /// In en, this message translates to:
  /// **'Protect your business data on this device'**
  String get backupSectionSubtitle;

  /// Settings section subtitle for backup & restore
  ///
  /// In en, this message translates to:
  /// **'Back up and restore your business data'**
  String get backupDataSectionSubtitle;

  /// Button label that creates a .brewline backup archive
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get backupCreateButtonLabel;

  /// Plural label showing when the last backup was taken
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Never backed up} =1{Last backup: yesterday} other{Last backup: {count} days ago}}'**
  String backupLastBackupLabel(int count);

  /// Label shown when the last backup was taken earlier today
  ///
  /// In en, this message translates to:
  /// **'Last backup: today'**
  String get backupLastBackupToday;

  /// Button label that picks and restores a .brewline archive
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get backupRestoreButtonLabel;

  /// Title of the restore confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get backupRestoreConfirmTitle;

  /// Body text in the restore confirmation dialog explaining the destructive action
  ///
  /// In en, this message translates to:
  /// **'This will replace ALL current data with the contents of this backup. A safety snapshot of the current data is saved automatically before restoring.'**
  String get backupRestoreConfirmBody;

  /// Label above the PIN entry field in the restore confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to confirm'**
  String get backupRestoreConfirmFieldLabel;

  /// Destructive confirm button in the restore confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupConfirmRestore;

  /// Error message when a backup's schema version is newer than the running app
  ///
  /// In en, this message translates to:
  /// **'This backup was made with a newer version of the app — update the app first, then restore.'**
  String get backupSchemaTooNewError;

  /// Info note when a backup is from an older schema (migrations will run on restore)
  ///
  /// In en, this message translates to:
  /// **'This backup was made with an older version. The data will be automatically updated after restoring.'**
  String get backupSchemaOlderWarning;

  /// Error shown when the admin enters the wrong PIN in the restore confirmation
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get backupWrongPin;

  /// Progress message while the restore operation is running
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get backupRestoring;

  /// Snackbar confirmation after a successful restore
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully'**
  String get backupRestored;

  /// Error message when the restore operation fails
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get backupFailed;

  /// Tile label for the device-label setting in the Data section
  ///
  /// In en, this message translates to:
  /// **'Device label'**
  String get backupDeviceLabelTitle;

  /// Tile subtitle for the device-label setting
  ///
  /// In en, this message translates to:
  /// **'Optional name shown in backup manifests'**
  String get backupDeviceLabelSubtitle;

  /// Placeholder hint shown in the device label edit dialog
  ///
  /// In en, this message translates to:
  /// **'e.g. Front Counter'**
  String get backupDeviceLabelHint;

  /// Save button in the device label edit dialog
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get backupDeviceLabelSave;

  /// Progress message while the backup archive is being created
  ///
  /// In en, this message translates to:
  /// **'Creating backup…'**
  String get backupCreateInProgress;

  /// Confirmation after a backup archive was successfully created
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get backupCreateSuccess;

  /// Error message when creating the backup archive fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get backupCreateError;

  /// Error message when the selected file is not a valid .brewline archive
  ///
  /// In en, this message translates to:
  /// **'This file is not a valid backup'**
  String get backupInvalidFileError;

  /// No description provided for @adminCashoutLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cashout log'**
  String get adminCashoutLogTitle;

  /// No description provided for @adminCashoutLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every finalized shift close, filterable by date or waiter.'**
  String get adminCashoutLogSubtitle;

  /// No description provided for @adminCashoutLogError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the cashout log.'**
  String get adminCashoutLogError;

  /// No description provided for @adminCashoutLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cashouts match these filters.'**
  String get adminCashoutLogEmpty;

  /// No description provided for @adminCashoutLogFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get adminCashoutLogFilters;

  /// No description provided for @adminCashoutLogWaiterLabel.
  ///
  /// In en, this message translates to:
  /// **'Waiter'**
  String get adminCashoutLogWaiterLabel;

  /// No description provided for @adminCashoutLogPickRangeHelp.
  ///
  /// In en, this message translates to:
  /// **'Filter cashouts by date'**
  String get adminCashoutLogPickRangeHelp;

  /// No description provided for @adminCashoutColDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get adminCashoutColDateTime;

  /// No description provided for @adminCashoutColOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders Made'**
  String get adminCashoutColOrders;

  /// No description provided for @adminCashoutColWaiter.
  ///
  /// In en, this message translates to:
  /// **'Waiter Name'**
  String get adminCashoutColWaiter;

  /// No description provided for @adminCashoutColTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Made'**
  String get adminCashoutColTotal;

  /// No description provided for @adminCashoutColCashCounted.
  ///
  /// In en, this message translates to:
  /// **'Cash Counted'**
  String get adminCashoutColCashCounted;

  /// No description provided for @adminCashoutColVariance.
  ///
  /// In en, this message translates to:
  /// **'Variance'**
  String get adminCashoutColVariance;

  /// No description provided for @refundReceiptPrinted.
  ///
  /// In en, this message translates to:
  /// **'Refund receipt sent to printer'**
  String get refundReceiptPrinted;

  /// No description provided for @refundReceiptPrintFailed.
  ///
  /// In en, this message translates to:
  /// **'Print failed: {error}'**
  String refundReceiptPrintFailed(Object error);

  /// No description provided for @refundSuccessVoided.
  ///
  /// In en, this message translates to:
  /// **'Order voided'**
  String get refundSuccessVoided;

  /// No description provided for @refundSuccess.
  ///
  /// In en, this message translates to:
  /// **'Refund successful'**
  String get refundSuccess;

  /// No description provided for @refundBodyVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided and refunded'**
  String get refundBodyVoided;

  /// No description provided for @refundBodyPartial.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refundBodyPartial;

  /// No description provided for @refundBodyOnOrder.
  ///
  /// In en, this message translates to:
  /// **'on order #{orderId}'**
  String refundBodyOnOrder(Object orderId);

  /// No description provided for @refundPrintReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print refund receipt'**
  String get refundPrintReceipt;

  /// No description provided for @refundDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get refundDone;

  /// No description provided for @refundFormLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this order.'**
  String get refundFormLoadFailed;

  /// No description provided for @refundFormReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get refundFormReasonLabel;

  /// No description provided for @refundFormReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. wrong item entered'**
  String get refundFormReasonHint;

  /// No description provided for @refundFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund order'**
  String get refundFormTitle;

  /// No description provided for @refundFormModeCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct Order'**
  String get refundFormModeCorrect;

  /// No description provided for @refundFormModeVoid.
  ///
  /// In en, this message translates to:
  /// **'Void Order'**
  String get refundFormModeVoid;

  /// No description provided for @refundFormLineItems.
  ///
  /// In en, this message translates to:
  /// **'Line items'**
  String get refundFormLineItems;

  /// No description provided for @refundFormCurrentTotal.
  ///
  /// In en, this message translates to:
  /// **'Current total'**
  String get refundFormCurrentTotal;

  /// No description provided for @refundFormRefundAmount.
  ///
  /// In en, this message translates to:
  /// **'Refund amount'**
  String get refundFormRefundAmount;

  /// No description provided for @refundFormVoidEntireOrder.
  ///
  /// In en, this message translates to:
  /// **'Void entire order'**
  String get refundFormVoidEntireOrder;

  /// No description provided for @refundFormOriginalTotal.
  ///
  /// In en, this message translates to:
  /// **'Original total'**
  String get refundFormOriginalTotal;

  /// No description provided for @refundFormVoidNote.
  ///
  /// In en, this message translates to:
  /// **'The order is marked voided but kept in records for audit. Nothing is deleted.'**
  String get refundFormVoidNote;

  /// No description provided for @refundFormConfirmVoid.
  ///
  /// In en, this message translates to:
  /// **'Void & refund {amount}'**
  String refundFormConfirmVoid(Object amount);

  /// No description provided for @refundFormConfirmPartial.
  ///
  /// In en, this message translates to:
  /// **'Refund {amount}'**
  String refundFormConfirmPartial(Object amount);

  /// No description provided for @refundFormProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get refundFormProcessing;

  /// No description provided for @refundFormOrder.
  ///
  /// In en, this message translates to:
  /// **'Order {orderNumber}'**
  String refundFormOrder(Object orderNumber);

  /// No description provided for @refundFormTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get refundFormTotal;

  /// No description provided for @refundFormRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get refundFormRemoveItem;

  /// No description provided for @refundFormReduceQty.
  ///
  /// In en, this message translates to:
  /// **'Reduce quantity'**
  String get refundFormReduceQty;

  /// No description provided for @refundFormFailed.
  ///
  /// In en, this message translates to:
  /// **'Refund failed: {error}'**
  String refundFormFailed(Object error);

  /// Admin navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminNavDashboard;

  /// Admin navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminNavReports;

  /// Admin navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get adminNavMenu;

  /// Admin navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get adminNavInventory;

  /// Admin navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get adminNavStaff;

  /// Admin navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Sales log'**
  String get adminNavSalesLog;

  /// Admin navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Cashout log'**
  String get adminNavCashoutLog;

  /// Admin navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminNavSettings;

  /// KPI card label on the admin dashboard
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get adminDashboardRevenue;

  /// KPI card label on the admin dashboard
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get adminDashboardOrders;

  /// KPI card label on the admin dashboard
  ///
  /// In en, this message translates to:
  /// **'Items sold'**
  String get adminDashboardItemsSold;

  /// KPI card label on the admin dashboard
  ///
  /// In en, this message translates to:
  /// **'Avg. order'**
  String get adminDashboardAvgOrder;

  /// Dashboard header greeting before noon
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get adminDashboardGreetingMorning;

  /// Dashboard header greeting from noon until early evening
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get adminDashboardGreetingAfternoon;

  /// Dashboard header greeting in the evening
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get adminDashboardGreetingEvening;

  /// Period selector option: today's figures
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get adminDashboardPeriodToday;

  /// Period selector option: trailing 7 days
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get adminDashboardPeriodWeek;

  /// Period selector option: trailing 30 days
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get adminDashboardPeriodMonth;

  /// Title of the revenue bar chart card on the dashboard
  ///
  /// In en, this message translates to:
  /// **'Revenue overview'**
  String get adminRevenueOverviewTitle;

  /// Title of the revenue line chart card on the Reports tab
  ///
  /// In en, this message translates to:
  /// **'Revenue over time'**
  String get adminRevenueOverTimeTitle;

  /// Error message inside the revenue chart when its data fails to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the revenue trend.'**
  String get adminRevenueTrendError;

  /// Heading of the admin Reports tab
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get adminReportTitle;

  /// Subtitle under the Reports tab heading
  ///
  /// In en, this message translates to:
  /// **'Revenue, what sells and when.'**
  String get adminReportSubtitle;

  /// Title of the quick-action tiles card on the dashboard
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get adminDashboardQuickActions;

  /// Quick-action label that jumps to the Staff tab
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get adminDashboardQuickAddStaff;

  /// Subtitle of the 'Add staff' quick action
  ///
  /// In en, this message translates to:
  /// **'Invite a team member'**
  String get adminDashboardQuickAddStaffDesc;

  /// Quick-action label that jumps to the Reports tab
  ///
  /// In en, this message translates to:
  /// **'View reports'**
  String get adminDashboardQuickViewReports;

  /// Subtitle of the 'View reports' quick action
  ///
  /// In en, this message translates to:
  /// **'Revenue & performance'**
  String get adminDashboardQuickViewReportsDesc;

  /// Quick-action label that jumps to the Menu tab
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get adminDashboardQuickAddProduct;

  /// Subtitle of the 'Add product' quick action
  ///
  /// In en, this message translates to:
  /// **'Grow the menu'**
  String get adminDashboardQuickAddProductDesc;

  /// Title of the low-stock alerts card
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get adminLowStockTitle;

  /// Error message shown inside the low-stock card
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load stock levels.'**
  String get adminLowStockError;

  /// Empty-state message when every product is sufficiently stocked
  ///
  /// In en, this message translates to:
  /// **'Stock levels look healthy — no alerts.'**
  String get adminLowStockHealthy;

  /// Units of a product still in stock, e.g. '12 left'
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 left} other{{count} left}}'**
  String adminStockQuantityLeft(num count);

  /// No description provided for @adminStockQuantityLeftAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String adminStockQuantityLeftAmount(Object amount);

  /// Compact one-tap restock button on a low-stock row
  ///
  /// In en, this message translates to:
  /// **'+ Restock'**
  String get adminRestockShort;

  /// Title of the all-ingredients stock overview card
  ///
  /// In en, this message translates to:
  /// **'Stock overview'**
  String get adminStockOverviewTitle;

  /// Empty state shown when no ingredients exist yet
  ///
  /// In en, this message translates to:
  /// **'No stock items yet — add ingredients to track stock here.'**
  String get adminStockOverviewEmpty;

  /// Header pill on the stock overview card counting ingredients that need restocking
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 needs restock} other{{count} need restock}}'**
  String adminStockRestockCount(num count);

  /// Approximate servings an ingredient still yields, appended to its stock quantity
  ///
  /// In en, this message translates to:
  /// **'· ~{count, plural, =1{1 serving} other{{count} servings}}'**
  String adminStockServingsLeft(num count);

  /// Status suffix appended to a stock row when the ingredient is out of stock
  ///
  /// In en, this message translates to:
  /// **'· out'**
  String get adminStockBadgeOut;

  /// Status suffix appended to a stock row when the ingredient is low
  ///
  /// In en, this message translates to:
  /// **'· low'**
  String get adminStockBadgeLow;

  /// Title of the shift status card
  ///
  /// In en, this message translates to:
  /// **'Shift status'**
  String get adminShiftStatusTitle;

  /// Green status pill confirming the signed-in admin's session is live
  ///
  /// In en, this message translates to:
  /// **'On shift'**
  String get adminShiftStatusOnShift;

  /// Label above the signed-in account name on the shift status card
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get adminShiftStatusSignedInAs;

  /// Error message inside the shift status card
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load shift status.'**
  String get adminShiftStatusError;

  /// Empty state when the check-in roster has no staff
  ///
  /// In en, this message translates to:
  /// **'No staff on the roster yet.'**
  String get adminShiftStatusEmpty;

  /// Status badge for a staff member currently clocked in
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminShiftStatusActive;

  /// Status badge for a staff member who has never clocked in this shift
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get adminShiftStatusIdle;

  /// Status badge for a staff member who clocked out
  ///
  /// In en, this message translates to:
  /// **'Cashed out'**
  String get adminShiftStatusCashedOut;

  /// Status badge for a staff member with no shift history
  ///
  /// In en, this message translates to:
  /// **'No shift yet'**
  String get adminShiftStatusNoShiftYet;

  /// Detail note for a staff member who never signed in
  ///
  /// In en, this message translates to:
  /// **'Never logged in'**
  String get adminShiftStatusNeverLoggedIn;

  /// Detail line showing when a staff member clocked in
  ///
  /// In en, this message translates to:
  /// **'Logged in {time}'**
  String adminShiftLoggedInAt(String time);

  /// Detail line for an idle staff member
  ///
  /// In en, this message translates to:
  /// **'Logged out · last active {time}'**
  String adminShiftLoggedOutLastActive(String time);

  /// Detail line for a staff member who clocked in and later cashed out
  ///
  /// In en, this message translates to:
  /// **'Logged in {checkIn} · Cashed out {cashOut}'**
  String adminShiftDetailCashedOut(String checkIn, String cashOut);

  /// Elapsed time on shift when at least one hour has passed
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String adminShiftDurationLong(num hours, num minutes);

  /// Elapsed time on shift when under an hour
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String adminShiftDurationShort(num minutes);

  /// Title of the top-sellers card
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get adminTopProductsTitle;

  /// Error message inside the top-products card
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load top products.'**
  String get adminTopProductsError;

  /// Empty state for the top products card
  ///
  /// In en, this message translates to:
  /// **'No sales recorded in this period.'**
  String get adminTopProductsEmpty;

  /// Units of a product sold in the period, e.g. '23 sold'
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sold} other{{count} sold}}'**
  String adminTopProductsSold(num count);

  /// Title of the revenue-by-category card
  ///
  /// In en, this message translates to:
  /// **'Category mix'**
  String get adminCategoryMixTitle;

  /// Error message inside the category-mix card
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the mix.'**
  String get adminCategoryMixError;

  /// Title of the per-waiter sales card
  ///
  /// In en, this message translates to:
  /// **'Team performance'**
  String get adminTeamPerformanceTitle;

  /// Error message inside the team-performance card
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load team sales.'**
  String get adminTeamPerformanceError;

  /// Empty state for the team-performance card
  ///
  /// In en, this message translates to:
  /// **'No waiter-attributed sales this period.'**
  String get adminTeamPerformanceEmpty;

  /// Orders attributed to one waiter
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order} other{{count} orders}}'**
  String adminTeamOrders(num count);

  /// Title of the day-x-time heatmap card
  ///
  /// In en, this message translates to:
  /// **'Busiest hours'**
  String get adminBusiestHoursTitle;

  /// Error message inside the busiest-hours card
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the hour data.'**
  String get adminBusiestHoursError;

  /// Total order count heading on the heatmap card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 order} other{{count} orders}}'**
  String adminBusiestHoursTotal(num count);

  /// Tooltip / snackbar label for one heatmap cell showing its day, time bucket and order count
  ///
  /// In en, this message translates to:
  /// **'{day} · {start}–{end} · {count, plural, =1{1 order} other{{count} orders}}'**
  String adminBusiestCellTooltip(
    String day,
    String start,
    String end,
    num count,
  );

  /// Generic edit action label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Generic archive action label
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// Generic delete action label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Overflow menu trigger label
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionActions;

  /// Admin inventory tab heading
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// Subtitle on the inventory tab
  ///
  /// In en, this message translates to:
  /// **'Track raw ingredients and who consumes them.'**
  String get inventorySubtitle;

  /// Button that opens the new-ingredient form
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get inventoryAddIngredient;

  /// Button opening the stock movements ledger
  ///
  /// In en, this message translates to:
  /// **'Stock movements log'**
  String get inventoryStockMovementsLog;

  /// Error message when the ingredient list fails to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load inventory.'**
  String get inventoryError;

  /// Empty state when no ingredients exist
  ///
  /// In en, this message translates to:
  /// **'No ingredients yet. Add one to start tracking stock.'**
  String get inventoryEmpty;

  /// Amount of an ingredient still on hand, with its unit, e.g. '1.2 kg left'
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String stockQuantityWithUnitLeft(String amount);

  /// Badge text when an ingredient has no stock left
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get stockBadgeOut;

  /// Badge text when an ingredient is low on stock
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get stockBadgeLow;

  /// Title of the restock dialog
  ///
  /// In en, this message translates to:
  /// **'Restock {name}'**
  String restockDialogTitle(String name);

  /// Current stock shown in the restock dialog
  ///
  /// In en, this message translates to:
  /// **'Currently {amount} on hand'**
  String restockCurrentlyOnHand(String amount);

  /// Field label for the received quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity received'**
  String get restockQuantityReceived;

  /// Helper explaining how a large-scale entry is stored
  ///
  /// In en, this message translates to:
  /// **'Stored as {amount} {unit}'**
  String restockStoredAs(String amount, String unit);

  /// Validation message for a non-positive restock quantity
  ///
  /// In en, this message translates to:
  /// **'Enter a positive quantity'**
  String get restockEnterPositiveQty;

  /// Field label for the optional restock note
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get restockNoteOptional;

  /// Hint text for the restock note
  ///
  /// In en, this message translates to:
  /// **'e.g. Supplier name, PO #'**
  String get restockNoteHint;

  /// Confirm button on the restock dialog
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get restockAction;

  /// Restock button label while saving
  ///
  /// In en, this message translates to:
  /// **'Restocking…'**
  String get restockProgress;

  /// Confirmation after a successful restock
  ///
  /// In en, this message translates to:
  /// **'{name} restocked (+{amount})'**
  String restockSnackbar(String name, String amount);

  /// Heading of the ingredient form in create mode
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get ingredientAddTitle;

  /// Heading of the ingredient form in edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit ingredient'**
  String get ingredientEditTitle;

  /// Field label for the ingredient name
  ///
  /// In en, this message translates to:
  /// **'Ingredient name'**
  String get ingredientName;

  /// Hint text for the ingredient name
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee beans, Milk, Cups'**
  String get ingredientNameHint;

  /// Validation message for an empty ingredient name
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get ingredientEnterName;

  /// Field label for the reorder threshold
  ///
  /// In en, this message translates to:
  /// **'Low-stock alert below'**
  String get ingredientLowStockBelow;

  /// Helper text explaining the reorder threshold
  ///
  /// In en, this message translates to:
  /// **'Alerts when on hand drops to this level or below'**
  String get ingredientAlertDesc;

  /// Validation message for a non-numeric or negative threshold
  ///
  /// In en, this message translates to:
  /// **'Enter 0 or a positive number'**
  String get ingredientNonNegative;

  /// Label above the ingredient unit picker
  ///
  /// In en, this message translates to:
  /// **'Tracked unit'**
  String get ingredientTrackedUnit;

  /// Option label for the grams unit
  ///
  /// In en, this message translates to:
  /// **'Weight (g)'**
  String get ingredientUnitWeight;

  /// Option label for the millilitres unit
  ///
  /// In en, this message translates to:
  /// **'Volume (ml)'**
  String get ingredientUnitVolume;

  /// Option label for the discrete-units unit
  ///
  /// In en, this message translates to:
  /// **'Whole units'**
  String get ingredientUnitUnits;

  /// Notice shown when the unit picker is disabled
  ///
  /// In en, this message translates to:
  /// **'The unit can\'t change once the ingredient has stock history.'**
  String get ingredientUnitLockedNote;

  /// Submit button on the ingredient form
  ///
  /// In en, this message translates to:
  /// **'Save ingredient'**
  String get ingredientSave;

  /// Ingredient form button label while saving
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get ingredientSaving;

  /// Confirmation after creating an ingredient
  ///
  /// In en, this message translates to:
  /// **'{name} added to inventory'**
  String ingredientAddedSnackbar(String name);

  /// Confirmation after editing an ingredient
  ///
  /// In en, this message translates to:
  /// **'{name} updated'**
  String ingredientUpdatedSnackbar(String name);

  /// Title of the stock movements ledger page
  ///
  /// In en, this message translates to:
  /// **'Stock movements'**
  String get movementsTitle;

  /// Subtitle of the stock movements page
  ///
  /// In en, this message translates to:
  /// **'Every change to an ingredient\'s quantity, newest first.'**
  String get movementsSubtitle;

  /// Error message when the movement ledger fails to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the stock movements.'**
  String get movementsError;

  /// Empty state when no movements match the filters
  ///
  /// In en, this message translates to:
  /// **'No movements match these filters.'**
  String get movementsEmpty;

  /// Heading of the filter card
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get movementsFilters;

  /// Filter field label for the date window
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get movementsDateRange;

  /// Value shown when no date filter is applied
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get movementsAllDates;

  /// Tooltip for the button that clears the date filter
  ///
  /// In en, this message translates to:
  /// **'Clear date filter'**
  String get movementsClearDateFilter;

  /// Helper text for the date range picker
  ///
  /// In en, this message translates to:
  /// **'Filter movements by date'**
  String get movementsDatePickerHelp;

  /// Filter field label for the ingredient
  ///
  /// In en, this message translates to:
  /// **'Ingredient'**
  String get movementsIngredient;

  /// Dropdown option for no ingredient filter
  ///
  /// In en, this message translates to:
  /// **'All ingredients'**
  String get movementsAllIngredients;

  /// Filter field label for the movement reason
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get movementsReason;

  /// Dropdown option for no reason filter
  ///
  /// In en, this message translates to:
  /// **'All reasons'**
  String get movementsAllReasons;

  /// Column header for the movement timestamp
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get movementsWhen;

  /// Column header for the quantity change
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get movementsChange;

  /// Column header for the order reference or note
  ///
  /// In en, this message translates to:
  /// **'Ref / note'**
  String get movementsRefNote;

  /// Cell text referencing the order a movement came from
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId}'**
  String movementsOrderRef(int orderId);

  /// Dropdown label for the sale movement reason
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get movementsReasonSale;

  /// Dropdown label for the refund-restock reason
  ///
  /// In en, this message translates to:
  /// **'Refund / restock'**
  String get movementsReasonRefund;

  /// Dropdown label for the restock reason
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get movementsReasonRestock;

  /// Dropdown label for the manual adjustment reason
  ///
  /// In en, this message translates to:
  /// **'Manual adjustment'**
  String get movementsReasonAdjustment;

  /// Dropdown label for the waste reason
  ///
  /// In en, this message translates to:
  /// **'Waste'**
  String get movementsReasonWaste;

  /// Compact pill label for the refund-restock reason
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get movementsPillRefund;

  /// Compact pill label for the manual adjustment reason
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get movementsPillAdjustment;

  /// Heading of the recipe editor in the product form
  ///
  /// In en, this message translates to:
  /// **'What does it consume per serving?'**
  String get recipeTitle;

  /// Explanation text of the recipe editor
  ///
  /// In en, this message translates to:
  /// **'Bind the product to ingredients you stock — e.g. 1 cup → 12 g beans. This drives the low-stock alerts and how many cups you can still make.'**
  String get recipeSubtitle;

  /// Field label for the ingredient binding dropdown
  ///
  /// In en, this message translates to:
  /// **'Bind an ingredient in stock'**
  String get recipeBindIngredient;

  /// Dropdown hint when ingredients remain to bind
  ///
  /// In en, this message translates to:
  /// **'Select an ingredient…'**
  String get recipeSelectIngredient;

  /// Dropdown label/hint when every ingredient is already bound
  ///
  /// In en, this message translates to:
  /// **'No more ingredients left to add'**
  String get recipeNoMoreIngredients;

  /// Quantity field label in a recipe row
  ///
  /// In en, this message translates to:
  /// **'Per {unit} sold'**
  String recipePerUnitSold(String unit);

  /// Tooltip for removing an ingredient binding
  ///
  /// In en, this message translates to:
  /// **'Remove binding'**
  String get recipeRemoveBinding;

  /// Bulk-purchase yield estimate in a recipe row
  ///
  /// In en, this message translates to:
  /// **'{bulk} → about {count, plural, =1{1 serving} other{{count} servings}}'**
  String recipeYieldHint(String bulk, num count);

  /// Admin menu & products tab heading
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get menuCatalogTitle;

  /// Subtitle on the menu tab
  ///
  /// In en, this message translates to:
  /// **'Manage prices, stock and availability across the menu.'**
  String get menuSubtitle;

  /// Button that opens the new-product form
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get menuAddProduct;

  /// Error message when the product catalog fails to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the catalog.'**
  String get productTableError;

  /// Empty state when the catalog has no products
  ///
  /// In en, this message translates to:
  /// **'No products yet — add your first one.'**
  String get productTableEmpty;

  /// Label shown when a product has no category
  ///
  /// In en, this message translates to:
  /// **'Uncategorised'**
  String get productUncategorised;

  /// Stock line when the product is not available for sale
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get productStockSoldOut;

  /// Stock line when a product has no ingredient binding
  ///
  /// In en, this message translates to:
  /// **'Stock not tracked yet'**
  String get productStockNotTracked;

  /// Stock line when a product's ingredients are exhausted
  ///
  /// In en, this message translates to:
  /// **'Out of stock — restock'**
  String get productStockOutRestock;

  /// Stock line when a product is low, e.g. 'Low · ~12 left'
  ///
  /// In en, this message translates to:
  /// **'Low · ~{count, plural, =1{1 left} other{{count} left}}'**
  String productStockLow(num count);

  /// Stock line with the number of servings still sellable
  ///
  /// In en, this message translates to:
  /// **'~{count, plural, =1{1 serving} other{{count} servings}} left'**
  String productStockServingsLeft(num count);

  /// Tooltip for the product overflow menu
  ///
  /// In en, this message translates to:
  /// **'Product actions'**
  String get productActionsTooltip;

  /// Title of the delete-product confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String productDeleteTitle(String name);

  /// Explanation in the delete-product confirmation
  ///
  /// In en, this message translates to:
  /// **'Removes it from the menu and stock tracking. Past orders keep their own snapshots and stay in the reports.'**
  String get productDeleteBody;

  /// Confirmation after deleting a product
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String productDeletedSnackbar(String name);

  /// Heading of the product form in create mode
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productAddTitle;

  /// Heading of the product form in edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productEditTitle;

  /// Field label for the product name
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productName;

  /// Validation message for an empty product name
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get productEnterName;

  /// Field label for the price in dirhams
  ///
  /// In en, this message translates to:
  /// **'Price (DH)'**
  String get productPrice;

  /// Validation message for a non-positive price
  ///
  /// In en, this message translates to:
  /// **'Must be positive'**
  String get productMustBePositive;

  /// Field label for the category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productCategory;

  /// Hint text for the category
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee, Soft drinks'**
  String get productCategoryHint;

  /// Label above the product image picker
  ///
  /// In en, this message translates to:
  /// **'Menu photo'**
  String get productMenuPhoto;

  /// Tooltip for the gallery upload tile
  ///
  /// In en, this message translates to:
  /// **'Import from gallery'**
  String get productImportFromGallery;

  /// Toggle label for product availability
  ///
  /// In en, this message translates to:
  /// **'Available on the menu'**
  String get productAvailableOnMenu;

  /// Toggle subtitle explaining availability
  ///
  /// In en, this message translates to:
  /// **'Hides the product from waiters when off'**
  String get productHideFromWaiters;

  /// Submit button in the product form edit mode
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get productSaveChanges;

  /// Submit button in the product form create mode
  ///
  /// In en, this message translates to:
  /// **'Add to menu'**
  String get productAddToMenu;

  /// Product form button label while saving
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get productSaving;

  /// Confirmation after creating a product
  ///
  /// In en, this message translates to:
  /// **'{name} added to the menu'**
  String productAddedSnackbar(String name);

  /// Confirmation after editing a product
  ///
  /// In en, this message translates to:
  /// **'{name} updated'**
  String productUpdatedSnackbar(String name);

  /// Error message when the system image picker fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the gallery.'**
  String get productGalleryError;

  /// Waiter navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get waiterNavOrders;

  /// Waiter navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get waiterNavMenu;

  /// Waiter navigation destination label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get waiterNavSettings;

  /// Nav shell slot that folds extra destinations into a sheet on compact screens
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get shellMore;

  /// Section header on the waiter menu page
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// Error message when the waiter menu fails to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the menu.'**
  String get menuError;

  /// Empty state when the catalog has no available products
  ///
  /// In en, this message translates to:
  /// **'No products on the menu yet.'**
  String get menuEmpty;

  /// Orders tab header when it holds line items
  ///
  /// In en, this message translates to:
  /// **'Order #{number} · {count, plural, =1{1 item} other{{count} items}}'**
  String ordersTitleWithItems(int number, num count);

  /// Orders tab header for a fresh (empty ticket) order
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String ordersTitle(int number);

  /// Snackbar shown after the cart is cleared
  ///
  /// In en, this message translates to:
  /// **'Order cleared'**
  String get ordersCleared;

  /// Snackbar action that restores a cleared cart
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get ordersUndo;

  /// Empty-state title when the cart is empty
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get ordersEmpty;

  /// Empty-state hint pointing waiters to the menu tab
  ///
  /// In en, this message translates to:
  /// **'Tap products in Menu to add them here.'**
  String get ordersEmptyHint;

  /// Label above the running order total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ordersTotal;

  /// Button that settles the order, showing the amount
  ///
  /// In en, this message translates to:
  /// **'Charge {amount}'**
  String ordersCharge(String amount);

  /// Button that empties the cart without charging
  ///
  /// In en, this message translates to:
  /// **'Clear order'**
  String get ordersClearOrder;

  /// Tooltip on the remove-line action
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get ordersRemoveItem;

  /// Section eyebrow label grouping the language + theme controls
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// Section eyebrow label grouping account/session actions
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get settingsSession;

  /// Section eyebrow label grouping receipt printing toggles
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get settingsReceipts;

  /// Admin settings section eyebrow above the account card
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// Admin settings section eyebrow above the printer card
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get settingsHardware;

  /// Waiter settings account section title
  ///
  /// In en, this message translates to:
  /// **'Account profile'**
  String get settingsAccountProfile;

  /// Waiter settings account section subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your session and shift reports'**
  String get settingsAccountProfileSubtitle;

  /// Live status label in the settings profile header
  ///
  /// In en, this message translates to:
  /// **'On shift'**
  String get settingsOnShift;

  /// Title of the language + appearance settings section
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneralTitle;

  /// Subtitle of the language + appearance settings section
  ///
  /// In en, this message translates to:
  /// **'Language and appearance'**
  String get settingsGeneralSubtitle;

  /// Settings row label for the interface language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Settings row subtitle explaining the language picker
  ///
  /// In en, this message translates to:
  /// **'Interface language for this device'**
  String get settingsLanguageSubtitle;

  /// Settings row opening the change-PIN dialog
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePasswordTitle;

  /// Settings row subtitle for the change-PIN action
  ///
  /// In en, this message translates to:
  /// **'Update your login credentials'**
  String get settingsChangePasswordSubtitle;

  /// Settings row subtitle for logout
  ///
  /// In en, this message translates to:
  /// **'End this session on the device'**
  String get settingsLogoutSubtitle;

  /// Waiter settings printing section title
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get settingsPrintingTitle;

  /// Waiter settings printing section subtitle
  ///
  /// In en, this message translates to:
  /// **'Receipts printed with each order'**
  String get settingsPrintingSubtitle;

  /// Toggle row for the kitchen receipt copy
  ///
  /// In en, this message translates to:
  /// **'Kitchen receipt'**
  String get settingsKitchenReceiptTitle;

  /// Toggle row subtitle for the kitchen receipt
  ///
  /// In en, this message translates to:
  /// **'Send a copy to the kitchen printer'**
  String get settingsKitchenReceiptSubtitle;

  /// Toggle row for the client receipt copy
  ///
  /// In en, this message translates to:
  /// **'Client receipt'**
  String get settingsClientReceiptTitle;

  /// Toggle row subtitle for the client receipt
  ///
  /// In en, this message translates to:
  /// **'Hand the guest their printed copy'**
  String get settingsClientReceiptSubtitle;

  /// Settings row label for the theme control
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeTitle;

  /// Settings row subtitle explaining the theme control
  ///
  /// In en, this message translates to:
  /// **'Match your light / dark preference'**
  String get settingsThemeSubtitle;

  /// Theme option that follows the operating system
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Theme option for the light scheme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Theme option for the dark scheme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Admin settings account section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountTitle;

  /// Admin settings account section subtitle
  ///
  /// In en, this message translates to:
  /// **'Your sign-in and session'**
  String get settingsAccountSubtitle;

  /// Label above the signed-in account name
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get settingsSignedInAs;

  /// Destructive settings action that wipes the business database
  ///
  /// In en, this message translates to:
  /// **'Reset business data'**
  String get settingsResetTitle;

  /// Settings row subtitle for the destructive reset
  ///
  /// In en, this message translates to:
  /// **'Delete everything and return to setup'**
  String get settingsResetSubtitle;

  /// Title of the destructive reset confirmation
  ///
  /// In en, this message translates to:
  /// **'Reset business data?'**
  String get settingsResetConfirmTitle;

  /// Explanation in the destructive reset confirmation
  ///
  /// In en, this message translates to:
  /// **'This deletes the admin account and all business data (orders, staff, products) and returns you to the setup screen.'**
  String get settingsResetConfirmBody;

  /// Label of the confirmation field in the reset dialog
  ///
  /// In en, this message translates to:
  /// **'Type RESET to confirm'**
  String get settingsResetFieldLabel;

  /// Helper under the reset confirmation field
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone'**
  String get settingsResetFieldHelper;

  /// Confirm button in the reset dialog
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsResetButton;

  /// Localized label for the admin role
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// Localized label for the waiter role
  ///
  /// In en, this message translates to:
  /// **'Waiter'**
  String get roleWaiter;

  /// Alternative localized label for a non-admin account
  ///
  /// In en, this message translates to:
  /// **'Staff member'**
  String get roleStaffMember;

  /// Title of the printer settings section
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get printerTitle;

  /// Subtitle of the printer settings section
  ///
  /// In en, this message translates to:
  /// **'Which receipt printer this terminal uses'**
  String get printerSubtitle;

  /// Printer transport option: directly attached USB
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get printerUsb;

  /// Printer transport option: TCP network printer
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get printerNetwork;

  /// Field label for the network printer address
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get printerIpAddress;

  /// Example address shown in the IP field
  ///
  /// In en, this message translates to:
  /// **'192.168.1.50'**
  String get printerIpHint;

  /// Field label for the printer port
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get printerPort;

  /// Helper text under the port field
  ///
  /// In en, this message translates to:
  /// **'Raw ESC/POS port (default 9100, JetDirect)'**
  String get printerPortHelper;

  /// Button that persists the printer network address
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get printerSave;

  /// Validation error for an out-of-range port
  ///
  /// In en, this message translates to:
  /// **'Port must be a number between 1 and 65535'**
  String get printerInvalidPort;

  /// Confirmation after saving printer settings
  ///
  /// In en, this message translates to:
  /// **'Printer settings saved'**
  String get printerSaved;

  /// Explanation shown while the USB transport is selected
  ///
  /// In en, this message translates to:
  /// **'The USB printer is detected automatically. Switch to Network to set an address.'**
  String get printerUsbInfo;

  /// Label for the receipt-language dropdown in Printer settings
  ///
  /// In en, this message translates to:
  /// **'Receipt language'**
  String get printerReceiptLanguageLabel;

  /// Helper explaining the receipt language is separate from the UI language
  ///
  /// In en, this message translates to:
  /// **'The language printed receipts are in, independent of the app language. Defaults to French.'**
  String get printerReceiptLanguageHelper;

  /// Title of the change-PIN dialog
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// Label of the current-PIN field
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get changePasswordCurrentPin;

  /// Label of the new-PIN field
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get changePasswordNewPin;

  /// Helper text under the new-PIN field
  ///
  /// In en, this message translates to:
  /// **'4 digits, keeps hashed at rest'**
  String get changePasswordNewPinHint;

  /// Label of the confirm-PIN field
  ///
  /// In en, this message translates to:
  /// **'Confirm new PIN'**
  String get changePasswordConfirmPin;

  /// Validation error when the confirm PIN differs
  ///
  /// In en, this message translates to:
  /// **'PINs do not match'**
  String get changePasswordMismatch;

  /// Eye-toggle button revealing the PIN fields
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get changePasswordShow;

  /// Eye-toggle button masking the PIN fields
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get changePasswordHide;

  /// Change-PIN button label while saving
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get changePasswordUpdating;

  /// Change-PIN confirm button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get changePasswordUpdate;

  /// Error surfaced when the dialog finds no signed-in session
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get changePasswordNoSession;

  /// Error when the entered current PIN is wrong
  ///
  /// In en, this message translates to:
  /// **'The current PIN doesn\'t match this account.'**
  String get changePasswordWrongPin;

  /// Confirmation after a successful PIN change
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get changePasswordUpdated;

  /// Validation error for a PIN with the wrong digit count
  ///
  /// In en, this message translates to:
  /// **'Use exactly {count} digits'**
  String changePasswordPinLength(int count);

  /// Error when the new PIN already belongs to another account
  ///
  /// In en, this message translates to:
  /// **'That PIN is already in use — pick a different one'**
  String get changePasswordPinTaken;

  /// Copyright line at the bottom of the settings pages
  ///
  /// In en, this message translates to:
  /// **'© {year} BrewLine'**
  String settingsFooterCopyright(int year);

  /// Error message in the app info sheet
  ///
  /// In en, this message translates to:
  /// **'Could not load app info'**
  String get appInfoError;

  /// App info row label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get appInfoName;

  /// App info row label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appInfoVersion;

  /// App info row label
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get appInfoBuild;

  /// App info row label
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get appInfoPackage;

  /// Button opening the license page
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get appInfoLicenses;

  /// Product availability label when available
  ///
  /// In en, this message translates to:
  /// **'On menu'**
  String get availabilityOnMenu;

  /// Product availability label when unavailable
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get availabilitySoldOut;

  /// Field label on the shared date window filter
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateFilterRange;

  /// Value shown when no date window is applied
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get dateFilterAllDates;

  /// Shortcut button resetting the filter to today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateFilterToday;

  /// Tooltip for clearing the date filter
  ///
  /// In en, this message translates to:
  /// **'Show all dates'**
  String get dateFilterClearTooltip;

  /// Heading of a filter card
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// Subtitle under the sales log heading
  ///
  /// In en, this message translates to:
  /// **'Every product line sold, filterable by date, product or waiter.'**
  String get salesLogSubtitle;

  /// Error message when the sales log fails to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the sales log.'**
  String get salesLogError;

  /// Empty state when no sales match the filters
  ///
  /// In en, this message translates to:
  /// **'No sales match these filters.'**
  String get salesLogEmpty;

  /// Helper text on the sales log date range picker
  ///
  /// In en, this message translates to:
  /// **'Filter sales by date'**
  String get salesLogDatePickerHelp;

  /// Sales filter field label
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get salesLogProductLabel;

  /// Dropdown option for no product filter
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get salesLogAllProducts;

  /// Sales filter field label
  ///
  /// In en, this message translates to:
  /// **'Waiter'**
  String get salesLogWaiterLabel;

  /// Sales table column header
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get salesLogColDate;

  /// Sales table column header
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get salesLogColOrder;

  /// Sales table column header
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get salesLogColProduct;

  /// Sales table column header
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get salesLogColQty;

  /// Sales table column header
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get salesLogColTotal;

  /// Label before the net total of the visible sales rows
  ///
  /// In en, this message translates to:
  /// **'Total: '**
  String get salesLogTotal;

  /// Tooltip on the refund action per row
  ///
  /// In en, this message translates to:
  /// **'Refund this order'**
  String get salesLogRefundTooltip;

  /// Badge on a voided sales row
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get salesLogBadgeVoided;

  /// Badge on a partially refunded sales row
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get salesLogBadgeRefunded;

  /// Heading of the staff management page
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get staffTitle;

  /// Button that opens the add-staff form
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get staffAdd;

  /// Error message when the roster fails to load
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the staff roster.'**
  String get staffTableError;

  /// Empty state when the roster has no members
  ///
  /// In en, this message translates to:
  /// **'No staff yet — add your first member.'**
  String get staffTableEmpty;

  /// Tooltip on the staff row overflow menu
  ///
  /// In en, this message translates to:
  /// **'Staff actions'**
  String get staffActionsTooltip;

  /// Action that blocks an account from signing in
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get staffDeactivate;

  /// Action that re-enables a deactivated account
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get staffActivate;

  /// Title of the deactivate confirmation
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String staffDeactivateTitle(String name);

  /// Explanation in the deactivate confirmation
  ///
  /// In en, this message translates to:
  /// **'They can no longer sign in, but their sales history stays on record.'**
  String get staffDeactivateBody;

  /// Title of the delete-staff confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String staffDeleteTitle(String name);

  /// Explanation in the delete-staff confirmation
  ///
  /// In en, this message translates to:
  /// **'This removes the account permanently and detaches their sales from a named waiter. Prefer deactivating so history keeps its attribution.'**
  String get staffDeleteBody;

  /// Confirmation after deleting a staff member
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String staffDeletedSnackbar(String name);

  /// Status badge for a deactivated member
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get staffInactive;

  /// Status badge for an active member
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get staffActive;

  /// Staff table column header
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get staffColName;

  /// Staff table column header
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get staffColUsername;

  /// Staff table column header
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get staffColStatus;

  /// Pill counting active members over the roster size
  ///
  /// In en, this message translates to:
  /// **'{active} of {total} active'**
  String staffSummaryActive(num active, num total);

  /// Summary line when the roster has no members
  ///
  /// In en, this message translates to:
  /// **'Team is empty — add your first member'**
  String get staffSummaryEmpty;

  /// Summary line while the roster loads
  ///
  /// In en, this message translates to:
  /// **'Loading team…'**
  String get staffSummaryLoading;

  /// Heading of the staff form in create mode
  ///
  /// In en, this message translates to:
  /// **'Add staff member'**
  String get staffFormAddTitle;

  /// Heading of the staff form in edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit staff member'**
  String get staffFormEditTitle;

  /// Field label for the member's display name
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get staffFormName;

  /// Helper text for the display name
  ///
  /// In en, this message translates to:
  /// **'Shown on shift and performance views'**
  String get staffFormNameHint;

  /// Validation message for an empty display name
  ///
  /// In en, this message translates to:
  /// **'Enter a display name'**
  String get staffFormNameRequired;

  /// Field label for the login username
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get staffFormUsername;

  /// Helper text for the username
  ///
  /// In en, this message translates to:
  /// **'Used to sign in on the POS'**
  String get staffFormUsernameHint;

  /// Validation message for an empty username
  ///
  /// In en, this message translates to:
  /// **'Enter a username'**
  String get staffFormUsernameRequired;

  /// Validation message for a too-short username
  ///
  /// In en, this message translates to:
  /// **'At least 3 characters'**
  String get staffFormUsernameTooShort;

  /// Validation message for a username with unsupported characters
  ///
  /// In en, this message translates to:
  /// **'Letters, numbers and underscores only'**
  String get staffFormUsernameInvalid;

  /// Field label for the PIN in create mode
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get staffFormPin;

  /// Field label for the optional PIN in edit mode
  ///
  /// In en, this message translates to:
  /// **'New PIN (blank keeps current)'**
  String get staffFormNewPin;

  /// Note in edit mode clarifying the PIN field
  ///
  /// In en, this message translates to:
  /// **'Account stays active. Deactivate instead to block sign-in.'**
  String get staffFormEditNote;

  /// Submit button in edit mode
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get staffFormSaveChanges;

  /// Submit button in create mode
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get staffFormAddMember;

  /// Staff form button label while saving
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get staffFormSaving;

  /// Confirmation after creating a staff member
  ///
  /// In en, this message translates to:
  /// **'{name} added to staff'**
  String staffFormAddedSnackbar(String name);

  /// Confirmation after editing a staff member
  ///
  /// In en, this message translates to:
  /// **'{name} updated'**
  String staffFormUpdatedSnackbar(String name);

  /// Staff form PIN field validation error
  ///
  /// In en, this message translates to:
  /// **'Use exactly {count} digits'**
  String staffFormErrorPinLength(int count);

  /// Header of the fatal-startup error screen
  ///
  /// In en, this message translates to:
  /// **'brewline failed to start'**
  String get appStartupTitle;

  /// Button copying the startup error to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy error'**
  String get appStartupCopy;

  /// Snackbar confirming the error was copied
  ///
  /// In en, this message translates to:
  /// **'Error copied'**
  String get appStartupCopied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
