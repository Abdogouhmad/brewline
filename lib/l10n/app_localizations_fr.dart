// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'BrewLine';

  @override
  String get brandTagline => 'pour la gestion';

  @override
  String get settingsLanguageSystemDefault => 'Par défaut du système';

  @override
  String get settingsLanguageChooseTooltip => 'Choisir la langue';

  @override
  String get logoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get logoutConfirmBody =>
      'Vous devrez vous identifier à nouveau pour prendre des commandes.';

  @override
  String get logoutCancel => 'Annuler';

  @override
  String get logoutAction => 'Se déconnecter';

  @override
  String get logoutTooltip => 'Se déconnecter';

  @override
  String get logoutListSubtitle =>
      'Mettre fin à cette session sur l\'appareil.';

  @override
  String get onboardingSetupHeadline => 'Configurez votre café';

  @override
  String get onboardingUsernameLabel => 'Nom d\'utilisateur';

  @override
  String get onboardingUsernameHint => 'Choisissez un nom d\'utilisateur';

  @override
  String get onboardingSetPin => 'Définissez votre code PIN';

  @override
  String get onboardingConfirmPin => 'Confirmez votre code PIN';

  @override
  String get onboardingFinishSetup => 'Terminer la configuration';

  @override
  String get onboardingUsernameInvalid =>
      '3 à 24 caractères, lettres, chiffres ou _';

  @override
  String onboardingPinLength(num count) {
    return 'Le code PIN doit contenir exactement $count chiffres';
  }

  @override
  String get onboardingPinMismatch => 'Les codes PIN ne correspondent pas';

  @override
  String get onboardingPinTaken =>
      'Ce code PIN est déjà utilisé — choisissez-en un autre';

  @override
  String get onboardingSetupFailed =>
      'Échec de la configuration. Veuillez réessayer.';

  @override
  String get loginWelcomeBack => 'Bon retour !';

  @override
  String get loginEnterPin => 'Saisissez votre code PIN';

  @override
  String get loginIncorrectPin => 'Code PIN incorrect';

  @override
  String loginLockedOut(num seconds) {
    return 'Trop de tentatives. Réessayez dans ${seconds}s';
  }

  @override
  String get loginButton => 'Se connecter';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionLoadMore => 'Charger plus';

  @override
  String get actionAllWaiters => 'Tous les serveurs';

  @override
  String get walletCashoutSmsTitle =>
      'Clôturer la caisse et imprimer le rapport';

  @override
  String get walletCashoutSmsSubtitle =>
      'Clore le service, imprimer un récapitulatif et vous déconnecter';

  @override
  String walletCashoutPrintFailed(Object error) {
    return 'Service clôturé, mais le rapport n\'a pas pu être imprimé — vérifiez l\'imprimante ($error)';
  }

  @override
  String get walletCashoutPrinted =>
      'Service clôturé — rapport envoyé à l\'imprimante';

  @override
  String get walletReportPrinted => 'Rapport imprimé';

  @override
  String walletPrintRetryFailed(Object error) {
    return 'Nouvelle tentative échouée — vérifiez l\'imprimante ($error)';
  }

  @override
  String get walletCashoutConfirmTitle =>
      'Clôturer la caisse et imprimer le rapport ?';

  @override
  String get walletCashoutConfirmBody =>
      'Cela clora votre service, imprimera le rapport final et vous déconnectera. Vous devrez vous reconnecter pour prendre des commandes.';

  @override
  String get walletCashOutAction => 'Clôturer';

  @override
  String get walletCashoutDialogTitle => 'Encaissement';

  @override
  String get walletCashoutDrawerLabel => 'Argent dans le tiroir';

  @override
  String get walletCashoutHelper =>
      'La somme en espèces que vous pouvez remettre à la fin.';

  @override
  String get walletCashoutInvalidAmount => 'Saisissez un montant valide';

  @override
  String walletCashoutExpected(Object amount) {
    return 'Attendu : $amount — l\'écart est calculé par rapport à ce montant.';
  }

  @override
  String get walletCashoutConfirmButton => 'Confirmer la clôture';

  @override
  String get printReportSmsTitle => 'Imprimer le rapport';

  @override
  String get printReportSmsSubtitle =>
      'Imprimer un aperçu de votre service, sans le clôturer';

  @override
  String printReportPrintFailed(Object error) {
    return 'Impossible d\'imprimer le rapport — vérifiez l\'imprimante ($error)';
  }

  @override
  String get printReportEmpty =>
      'Aucune commande pour l\'instant — le rapport est un espace réservé';

  @override
  String get printReportSent =>
      'Rapport envoyé à l\'imprimante — service toujours ouvert';

  @override
  String get updateTitle => 'Mise à jour de l\'application';

  @override
  String get updateCheckingPill => 'Vérification des mises à jour…';

  @override
  String get updateCheckFailedPill => 'Échec de la vérification';

  @override
  String get updateAvailablePill => 'Nouvelle mise à jour disponible';

  @override
  String get updateUpToDatePill => 'Vous êtes à jour';

  @override
  String get updateCheckingCard => 'Connexion au serveur de mise à jour…';

  @override
  String get updateCheckFailedMessage =>
      'Impossible de vérifier les mises à jour. Vérifiez la connexion réseau et réessayez.';

  @override
  String get updateErrorGeneric =>
      'Une erreur est survenue lors de la vérification des mises à jour.';

  @override
  String get updateErrorNoBuild =>
      'Cette version ne propose pas de build installable pour cet appareil.';

  @override
  String updateErrorDownloadFailed(Object detail) {
    return 'Échec du téléchargement : $detail';
  }

  @override
  String updateErrorIntegrity(Object detail) {
    return 'La vérification de la somme de contrôle a échoué : $detail';
  }

  @override
  String updateErrorInstall(Object detail) {
    return 'La mise à jour n\'a pas pu être installée : $detail';
  }

  @override
  String get updateVersionDetails => 'Détails de la version';

  @override
  String get updateCurrentVersion => 'Version actuelle';

  @override
  String get updateLatestVersion => 'Dernière version';

  @override
  String get updateDownloadSize => 'Taille du téléchargement';

  @override
  String get updateLastChecked => 'Dernière vérification';

  @override
  String get updateNever => 'Jamais';

  @override
  String get updateLastResult => 'Dernier résultat';

  @override
  String get updateResultUpToDate => 'À jour';

  @override
  String get updateResultAvailable => 'Mise à jour disponible';

  @override
  String get updateResultMandatory => 'Mise à jour requise';

  @override
  String get updateResultFailed => 'Vérification échouée';

  @override
  String get updateResultNeverChecked => 'Jamais vérifié';

  @override
  String get updateUnknown => 'Inconnu';

  @override
  String get updateWhatsNew => 'Nouveautés';

  @override
  String get updateNoReleaseNotes =>
      'Aucune note de version disponible pour cette version.';

  @override
  String get updateDownloadingCardTitle => 'Téléchargement de la mise à jour…';

  @override
  String get updateDownloadInProgress => 'Téléchargement en cours';

  @override
  String get updateDownloadingNote =>
      'La mise à jour est vérifiée par somme de contrôle avant installation. Ne fermez pas l\'application.';

  @override
  String get updateReadyBody =>
      'Téléchargement terminé. L\'application va se fermer et redémarrer pour installer.';

  @override
  String get updateInstallNow => 'Installer maintenant';

  @override
  String get updateNow => 'Mettre à jour maintenant';

  @override
  String get updateTryAgain => 'Réessayer';

  @override
  String get updateCheckNow => 'Vérifier les mises à jour';

  @override
  String get updateAutoCheckTitle => 'Vérifier automatiquement';

  @override
  String get updateAutoCheckSubtitle =>
      'Rechercher les mises à jour au démarrage de l\'application';

  @override
  String get updateSectionSystem => 'Système';

  @override
  String get updateSectionTitle => 'Mise à jour';

  @override
  String get updateSectionSubtitle => 'Gardez ce terminal à jour';

  @override
  String get updateSoftwareUpdate => 'Mise à jour du logiciel';

  @override
  String get updateSummaryAvailable => 'Une mise à jour est disponible';

  @override
  String get updateSummaryDownloading => 'Téléchargement…';

  @override
  String get updateSummaryReady => 'Prêt à installer';

  @override
  String get updateRequiredTitle => 'Mise à niveau requise';

  @override
  String get updateRequiredBody =>
      'BrewLine doit être mis à jour avant de continuer. Cette version n\'est plus prise en charge.';

  @override
  String get updateRequiredChecking => 'Vérification…';

  @override
  String get updateRequiredChecksumNote =>
      'Votre mise à jour est vérifiée par somme de contrôle avant application.';

  @override
  String get updateRequiredReady =>
      'Prêt à installer. L\'application va se fermer puis redémarrer.';

  @override
  String get updateRequiredDownloadFailedNote =>
      'Vérifiez votre connexion internet et réessayez.';

  @override
  String get updateRequiredDownloadButton => 'Télécharger la mise à jour';

  @override
  String get adminCashoutLogTitle => 'Journal des caisses';

  @override
  String get adminCashoutLogSubtitle =>
      'Chaque clôture de service finalisée, filtrable par date ou serveur.';

  @override
  String get adminCashoutLogError =>
      'Impossible de charger le journal des caisses.';

  @override
  String get adminCashoutLogEmpty =>
      'Aucune clôture ne correspond à ces filtres.';

  @override
  String get adminCashoutLogFilters => 'Filtres';

  @override
  String get adminCashoutLogWaiterLabel => 'Serveur';

  @override
  String get adminCashoutLogPickRangeHelp => 'Filtrer les clôtures par date';

  @override
  String get adminCashoutColDateTime => 'Date & Heure';

  @override
  String get adminCashoutColOrders => 'Commandes';

  @override
  String get adminCashoutColWaiter => 'Nom du serveur';

  @override
  String get adminCashoutColTotal => 'Total';

  @override
  String get adminCashoutColCashCounted => 'Encaissé';

  @override
  String get adminCashoutColVariance => 'Écart';

  @override
  String get refundReceiptPrinted =>
      'Reçu de remboursement envoyé à l\'imprimante';

  @override
  String refundReceiptPrintFailed(Object error) {
    return 'Échec de l\'impression : $error';
  }

  @override
  String get refundSuccessVoided => 'Commande annulée';

  @override
  String get refundSuccess => 'Remboursement réussi';

  @override
  String get refundBodyVoided => 'Annulée et remboursée';

  @override
  String get refundBodyPartial => 'Remboursée';

  @override
  String refundBodyOnOrder(Object orderId) {
    return 'sur la commande #$orderId';
  }

  @override
  String get refundPrintReceipt => 'Imprimer le reçu de remboursement';

  @override
  String get refundDone => 'Terminé';

  @override
  String get refundFormLoadFailed => 'Impossible de charger cette commande.';

  @override
  String get refundFormReasonLabel => 'Motif (obligatoire)';

  @override
  String get refundFormReasonHint => 'ex. mauvaise commande saisie';

  @override
  String get refundFormTitle => 'Rembourser la commande';

  @override
  String get refundFormModeCorrect => 'Corriger la commande';

  @override
  String get refundFormModeVoid => 'Annuler la commande';

  @override
  String get refundFormLineItems => 'Lignes';

  @override
  String get refundFormCurrentTotal => 'Total actuel';

  @override
  String get refundFormRefundAmount => 'Montant du remboursement';

  @override
  String get refundFormVoidEntireOrder => 'Annuler toute la commande';

  @override
  String get refundFormOriginalTotal => 'Total d\'origine';

  @override
  String get refundFormVoidNote =>
      'La commande est marquée comme annulée mais conservée pour l\'audit. Rien n\'est supprimé.';

  @override
  String refundFormConfirmVoid(Object amount) {
    return 'Annuler et rembourser $amount';
  }

  @override
  String refundFormConfirmPartial(Object amount) {
    return 'Rembourser $amount';
  }

  @override
  String get refundFormProcessing => 'Traitement…';

  @override
  String refundFormOrder(Object orderNumber) {
    return 'Commande $orderNumber';
  }

  @override
  String get refundFormTotal => 'Total';

  @override
  String get refundFormRemoveItem => 'Retirer l\'article';

  @override
  String get refundFormReduceQty => 'Réduire la quantité';

  @override
  String refundFormFailed(Object error) {
    return 'Échec du remboursement : $error';
  }

  @override
  String get adminNavDashboard => 'Tableau de bord';

  @override
  String get adminNavReports => 'Rapports';

  @override
  String get adminNavMenu => 'Menu';

  @override
  String get adminNavInventory => 'Stock';

  @override
  String get adminNavStaff => 'Équipe';

  @override
  String get adminNavSalesLog => 'Journal des ventes';

  @override
  String get adminNavCashoutLog => 'Journal des caisses';

  @override
  String get adminNavSettings => 'Paramètres';

  @override
  String get adminDashboardRevenue => 'Chiffre d\'affaires';

  @override
  String get adminDashboardOrders => 'Commandes';

  @override
  String get adminDashboardItemsSold => 'Articles vendus';

  @override
  String get adminDashboardAvgOrder => 'Panier moyen';

  @override
  String get adminDashboardGreetingMorning => 'Bonjour';

  @override
  String get adminDashboardGreetingAfternoon => 'Bon après-midi';

  @override
  String get adminDashboardGreetingEvening => 'Bonsoir';

  @override
  String get adminDashboardPeriodToday => 'Aujourd\'hui';

  @override
  String get adminDashboardPeriodWeek => '7 derniers jours';

  @override
  String get adminDashboardPeriodMonth => '30 derniers jours';

  @override
  String get adminRevenueOverviewTitle => 'Évolution du chiffre d\'affaires';

  @override
  String get adminRevenueOverTimeTitle => 'Chiffre d\'affaires dans le temps';

  @override
  String get adminRevenueTrendError =>
      'Impossible de charger la tendance du chiffre d\'affaires.';

  @override
  String get adminReportTitle => 'Performances';

  @override
  String get adminReportSubtitle =>
      'Le chiffre d\'affaires, ce qui se vend et quand.';

  @override
  String get adminDashboardQuickActions => 'Actions rapides';

  @override
  String get adminDashboardQuickAddStaff => 'Ajouter un membre';

  @override
  String get adminDashboardQuickAddStaffDesc =>
      'Inviter un membre de l\'équipe';

  @override
  String get adminDashboardQuickViewReports => 'Voir les rapports';

  @override
  String get adminDashboardQuickViewReportsDesc =>
      'Chiffre d\'affaires et performances';

  @override
  String get adminDashboardQuickAddProduct => 'Ajouter un produit';

  @override
  String get adminDashboardQuickAddProductDesc => 'Développer le menu';

  @override
  String get adminLowStockTitle => 'Stock faible';

  @override
  String get adminLowStockError =>
      'Impossible de charger les niveaux de stock.';

  @override
  String get adminLowStockHealthy =>
      'Les stocks semblent en bonne santé — aucune alerte.';

  @override
  String adminStockQuantityLeft(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count restants',
      one: '1 restant',
    );
    return '$_temp0';
  }

  @override
  String adminStockQuantityLeftAmount(Object amount) {
    return '$amount restants';
  }

  @override
  String get adminRestockShort => '+ Réappro.';

  @override
  String get adminStockOverviewTitle => 'Aperçu du stock';

  @override
  String get adminStockOverviewEmpty =>
      'Aucun ingrédient pour l\'instant — ajoutez-en pour suivre le stock ici.';

  @override
  String adminStockRestockCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count à réapprovisionner',
      one: '1 à réapprovisionner',
    );
    return '$_temp0';
  }

  @override
  String adminStockServingsLeft(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portions',
      one: '1 portion',
    );
    return '· ~$_temp0';
  }

  @override
  String get adminStockBadgeOut => '· épuisé';

  @override
  String get adminStockBadgeLow => '· faible';

  @override
  String get adminShiftStatusTitle => 'État des services';

  @override
  String get adminShiftStatusOnShift => 'En service';

  @override
  String get adminShiftStatusSignedInAs => 'Connecté en tant que';

  @override
  String get adminShiftStatusError =>
      'Impossible de charger l\'état des services.';

  @override
  String get adminShiftStatusEmpty => 'Aucun membre inscrit pour l\'instant.';

  @override
  String get adminShiftStatusActive => 'Actif';

  @override
  String get adminShiftStatusIdle => 'En attente';

  @override
  String get adminShiftStatusCashedOut => 'Caisse clôturée';

  @override
  String get adminShiftStatusNoShiftYet => 'Aucun service';

  @override
  String get adminShiftStatusNeverLoggedIn => 'Jamais connecté';

  @override
  String adminShiftLoggedInAt(String time) {
    return 'Connecté à $time';
  }

  @override
  String adminShiftLoggedOutLastActive(String time) {
    return 'Déconnecté · dernière activité à $time';
  }

  @override
  String adminShiftDetailCashedOut(String checkIn, String cashOut) {
    return 'Connecté à $checkIn · Caisse clôturée à $cashOut';
  }

  @override
  String adminShiftDurationLong(num hours, num minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String adminShiftDurationShort(num minutes) {
    return '${minutes}min';
  }

  @override
  String get adminTopProductsTitle => 'Produits les plus vendus';

  @override
  String get adminTopProductsError =>
      'Impossible de charger les meilleures ventes.';

  @override
  String get adminTopProductsEmpty =>
      'Aucune vente enregistrée sur cette période.';

  @override
  String adminTopProductsSold(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vendus',
      one: '1 vendu',
    );
    return '$_temp0';
  }

  @override
  String get adminCategoryMixTitle => 'Répartition par catégorie';

  @override
  String get adminCategoryMixError => 'Impossible de charger la répartition.';

  @override
  String get adminTeamPerformanceTitle => 'Performance de l\'équipe';

  @override
  String get adminTeamPerformanceError =>
      'Impossible de charger les ventes de l\'équipe.';

  @override
  String get adminTeamPerformanceEmpty =>
      'Aucune vente attribuée à un serveur sur cette période.';

  @override
  String adminTeamOrders(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commandes',
      one: '1 commande',
    );
    return '$_temp0';
  }

  @override
  String get adminBusiestHoursTitle => 'Heures les plus chargées';

  @override
  String get adminBusiestHoursError =>
      'Impossible de charger les données horaires.';

  @override
  String adminBusiestHoursTotal(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commandes',
      one: '1 commande',
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
      other: '$count commandes',
      one: '1 commande',
    );
    return '$day · $start–$end · $_temp0';
  }

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionArchive => 'Archiver';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionActions => 'Actions';

  @override
  String get inventoryTitle => 'Inventaire';

  @override
  String get inventorySubtitle =>
      'Suivez les matières premières et qui les consomme.';

  @override
  String get inventoryAddIngredient => 'Ajouter un ingrédient';

  @override
  String get inventoryStockMovementsLog => 'Journal des mouvements de stock';

  @override
  String get inventoryError => 'Impossible de charger l\'inventaire.';

  @override
  String get inventoryEmpty =>
      'Aucun ingrédient pour l\'instant. Ajoutez-en un pour suivre le stock.';

  @override
  String stockQuantityWithUnitLeft(String amount) {
    return '$amount restants';
  }

  @override
  String get stockBadgeOut => 'Rupture';

  @override
  String get stockBadgeLow => 'Faible';

  @override
  String restockDialogTitle(String name) {
    return 'Réapprovisionner $name';
  }

  @override
  String restockCurrentlyOnHand(String amount) {
    return 'Actuellement $amount en stock';
  }

  @override
  String get restockQuantityReceived => 'Quantité reçue';

  @override
  String restockStoredAs(String amount, String unit) {
    return 'Stocké comme $amount $unit';
  }

  @override
  String get restockEnterPositiveQty => 'Saisissez une quantité positive';

  @override
  String get restockNoteOptional => 'Note (optionnelle)';

  @override
  String get restockNoteHint => 'ex. Nom du fournisseur, N° de commande';

  @override
  String get restockAction => 'Réapprovisionner';

  @override
  String get restockProgress => 'Réapprovisionnement…';

  @override
  String restockSnackbar(String name, String amount) {
    return '$name réapprovisionné (+$amount)';
  }

  @override
  String get ingredientAddTitle => 'Ajouter un ingrédient';

  @override
  String get ingredientEditTitle => 'Modifier l\'ingrédient';

  @override
  String get ingredientName => 'Nom de l\'ingrédient';

  @override
  String get ingredientNameHint => 'ex. Grains de café, Lait, Tasses';

  @override
  String get ingredientEnterName => 'Saisissez un nom';

  @override
  String get ingredientLowStockBelow => 'Alerte de stock bas en dessous de';

  @override
  String get ingredientAlertDesc =>
      'Alerte lorsque le stock tombe à ce niveau ou en dessous';

  @override
  String get ingredientNonNegative => 'Saisissez 0 ou un nombre positif';

  @override
  String get ingredientTrackedUnit => 'Unité de suivi';

  @override
  String get ingredientUnitWeight => 'Poids (g)';

  @override
  String get ingredientUnitVolume => 'Volume (ml)';

  @override
  String get ingredientUnitUnits => 'Unités entières';

  @override
  String get ingredientUnitLockedNote =>
      'L\'unité ne peut plus changer une fois que l\'ingrédient a un historique de stock.';

  @override
  String get ingredientSave => 'Enregistrer l\'ingrédient';

  @override
  String get ingredientSaving => 'Enregistrement…';

  @override
  String ingredientAddedSnackbar(String name) {
    return '$name ajouté à l\'inventaire';
  }

  @override
  String ingredientUpdatedSnackbar(String name) {
    return '$name mis à jour';
  }

  @override
  String get movementsTitle => 'Mouvements de stock';

  @override
  String get movementsSubtitle =>
      'Chaque modification de la quantité d\'un ingrédient, la plus récente en premier.';

  @override
  String get movementsError => 'Impossible de charger les mouvements de stock.';

  @override
  String get movementsEmpty => 'Aucun mouvement ne correspond à ces filtres.';

  @override
  String get movementsFilters => 'Filtres';

  @override
  String get movementsDateRange => 'Période';

  @override
  String get movementsAllDates => 'Toutes les dates';

  @override
  String get movementsClearDateFilter => 'Effacer le filtre de date';

  @override
  String get movementsDatePickerHelp => 'Filtrer les mouvements par date';

  @override
  String get movementsIngredient => 'Ingrédient';

  @override
  String get movementsAllIngredients => 'Tous les ingrédients';

  @override
  String get movementsReason => 'Motif';

  @override
  String get movementsAllReasons => 'Tous les motifs';

  @override
  String get movementsWhen => 'Quand';

  @override
  String get movementsChange => 'Variation';

  @override
  String get movementsRefNote => 'Réf. / note';

  @override
  String movementsOrderRef(int orderId) {
    return 'Commande n° $orderId';
  }

  @override
  String get movementsReasonSale => 'Vente';

  @override
  String get movementsReasonRefund => 'Remboursement / réappro';

  @override
  String get movementsReasonRestock => 'Réapprovisionnement';

  @override
  String get movementsReasonAdjustment => 'Ajustement manuel';

  @override
  String get movementsReasonWaste => 'Perte';

  @override
  String get movementsPillRefund => 'Remb.';

  @override
  String get movementsPillAdjustment => 'Ajust.';

  @override
  String get recipeTitle => 'Qu\'est-ce qui est consommé par portion ?';

  @override
  String get recipeSubtitle =>
      'Reliez le produit aux ingrédients que vous stockez — ex. 1 tasse → 12 g de grains. Cela alimente les alertes de stock bas et le nombre de tasses encore réalisables.';

  @override
  String get recipeBindIngredient => 'Relier un ingrédient en stock';

  @override
  String get recipeSelectIngredient => 'Sélectionnez un ingrédient…';

  @override
  String get recipeNoMoreIngredients => 'Plus aucun ingrédient à ajouter';

  @override
  String recipePerUnitSold(String unit) {
    return 'Par $unit vendu';
  }

  @override
  String get recipeRemoveBinding => 'Retirer le lien';

  @override
  String recipeYieldHint(String bulk, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portions',
      one: '1 portion',
    );
    return '$bulk → environ $_temp0';
  }

  @override
  String get menuCatalogTitle => 'Catalogue';

  @override
  String get menuSubtitle =>
      'Gérez les prix, le stock et la disponibilité de tout le menu.';

  @override
  String get menuAddProduct => 'Ajouter un produit';

  @override
  String get productTableError => 'Impossible de charger le catalogue.';

  @override
  String get productTableEmpty =>
      'Aucun produit pour l\'instant — ajoutez votre premier produit.';

  @override
  String get productUncategorised => 'Sans catégorie';

  @override
  String get productStockSoldOut => 'Épuisé';

  @override
  String get productStockNotTracked => 'Stock non suivi';

  @override
  String get productStockOutRestock => 'Rupture de stock — réapprovisionner';

  @override
  String productStockLow(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count restants',
      one: '1 restant',
    );
    return 'Faible · ~$_temp0';
  }

  @override
  String productStockServingsLeft(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count portions',
      one: '1 portion',
    );
    return '~$_temp0 restantes';
  }

  @override
  String get productActionsTooltip => 'Actions produit';

  @override
  String productDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get productDeleteBody =>
      'Le retire du menu et du suivi de stock. Les commandes passées conservent leurs propres instantanés et restent dans les rapports.';

  @override
  String productDeletedSnackbar(String name) {
    return '$name supprimé';
  }

  @override
  String get productAddTitle => 'Ajouter un produit';

  @override
  String get productEditTitle => 'Modifier le produit';

  @override
  String get productName => 'Nom du produit';

  @override
  String get productEnterName => 'Saisissez un nom';

  @override
  String get productPrice => 'Prix (DH)';

  @override
  String get productMustBePositive => 'Doit être positif';

  @override
  String get productCategory => 'Catégorie';

  @override
  String get productCategoryHint => 'ex. Café, Boissons';

  @override
  String get productMenuPhoto => 'Photo du menu';

  @override
  String get productImportFromGallery => 'Importer depuis la galerie';

  @override
  String get productAvailableOnMenu => 'Disponible au menu';

  @override
  String get productHideFromWaiters =>
      'Masque le produit aux serveurs lorsqu\'il est désactivé';

  @override
  String get productSaveChanges => 'Enregistrer les modifications';

  @override
  String get productAddToMenu => 'Ajouter au menu';

  @override
  String get productSaving => 'Enregistrement…';

  @override
  String productAddedSnackbar(String name) {
    return '$name ajouté au menu';
  }

  @override
  String productUpdatedSnackbar(String name) {
    return '$name mis à jour';
  }

  @override
  String get productGalleryError => 'Impossible d\'ouvrir la galerie.';

  @override
  String get waiterNavOrders => 'Commandes';

  @override
  String get waiterNavMenu => 'Menu';

  @override
  String get waiterNavSettings => 'Réglages';

  @override
  String get shellMore => 'Plus';

  @override
  String get menuTitle => 'Menu';

  @override
  String get menuError => 'Impossible de charger le menu.';

  @override
  String get menuEmpty => 'Aucun produit au menu pour l\'instant.';

  @override
  String ordersTitleWithItems(int number, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return 'Commande n° $number · $_temp0';
  }

  @override
  String ordersTitle(int number) {
    return 'Commande n° $number';
  }

  @override
  String get ordersCleared => 'Commande effacée';

  @override
  String get ordersUndo => 'Annuler';

  @override
  String get ordersEmpty => 'Aucun article';

  @override
  String get ordersEmptyHint =>
      'Touchez des produits dans Menu pour les ajouter ici.';

  @override
  String get ordersTotal => 'Total';

  @override
  String ordersCharge(String amount) {
    return 'Encaisser $amount';
  }

  @override
  String get ordersClearOrder => 'Effacer la commande';

  @override
  String get ordersRemoveItem => 'Retirer l\'article';

  @override
  String get settingsPreferences => 'Préférences';

  @override
  String get settingsSession => 'Session';

  @override
  String get settingsReceipts => 'Reçus';

  @override
  String get settingsSecurity => 'Sécurité';

  @override
  String get settingsHardware => 'Matériel';

  @override
  String get settingsAccountProfile => 'Profil du compte';

  @override
  String get settingsAccountProfileSubtitle =>
      'Gérez votre session et les rapports de service';

  @override
  String get settingsOnShift => 'En service';

  @override
  String get settingsGeneralTitle => 'Général';

  @override
  String get settingsGeneralSubtitle => 'Langue et apparence';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSubtitle => 'Langue d\'interface de cet appareil';

  @override
  String get settingsChangePasswordTitle => 'Changer le code PIN';

  @override
  String get settingsChangePasswordSubtitle =>
      'Modifiez vos identifiants de connexion';

  @override
  String get settingsLogoutSubtitle => 'Terminer cette session sur l\'appareil';

  @override
  String get settingsPrintingTitle => 'Impression';

  @override
  String get settingsPrintingSubtitle => 'Reçus imprimés avec chaque commande';

  @override
  String get settingsKitchenReceiptTitle => 'Ticket cuisine';

  @override
  String get settingsKitchenReceiptSubtitle =>
      'Envoyer une copie à l\'imprimante de cuisine';

  @override
  String get settingsClientReceiptTitle => 'Reçu client';

  @override
  String get settingsClientReceiptSubtitle =>
      'Remettre au client sa copie imprimée';

  @override
  String get settingsThemeTitle => 'Thème';

  @override
  String get settingsThemeSubtitle => 'Choisissez clair ou sombre';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsAccountTitle => 'Compte';

  @override
  String get settingsAccountSubtitle => 'Votre connexion et votre session';

  @override
  String get settingsSignedInAs => 'Connecté en tant que';

  @override
  String get settingsResetTitle => 'Réinitialiser les données';

  @override
  String get settingsResetSubtitle =>
      'Tout effacer et revenir à la configuration';

  @override
  String get settingsResetConfirmTitle => 'Réinitialiser les données ?';

  @override
  String get settingsResetConfirmBody =>
      'Ceci supprime le compte administrateur et toutes les données (commandes, personnel, produits) et vous ramène à l\'écran de configuration.';

  @override
  String get settingsResetFieldLabel => 'Saisissez RESET pour confirmer';

  @override
  String get settingsResetFieldHelper => 'Action irréversible';

  @override
  String get settingsResetButton => 'Réinitialiser';

  @override
  String get roleAdmin => 'Administrateur';

  @override
  String get roleWaiter => 'Serveur';

  @override
  String get roleStaffMember => 'Membre du personnel';

  @override
  String get printerTitle => 'Imprimante';

  @override
  String get printerSubtitle =>
      'L\'imprimante de reçus utilisée par ce terminal';

  @override
  String get printerUsb => 'USB';

  @override
  String get printerNetwork => 'Réseau';

  @override
  String get printerIpAddress => 'Adresse IP';

  @override
  String get printerIpHint => '192.168.1.50';

  @override
  String get printerPort => 'Port';

  @override
  String get printerPortHelper => 'Port ESC/POS brut (défaut 9100, JetDirect)';

  @override
  String get printerSave => 'Enregistrer';

  @override
  String get printerInvalidPort =>
      'Le port doit être un nombre entre 1 et 65535';

  @override
  String get printerSaved => 'Réglages d\'imprimante enregistrés';

  @override
  String get printerUsbInfo =>
      'L\'imprimante USB est détectée automatiquement. Passez sur Réseau pour définir une adresse.';

  @override
  String get printerReceiptLanguageLabel => 'Langue des reçus';

  @override
  String get printerReceiptLanguageHelper =>
      'La langue des reçus imprimés, indépendante de la langue de l\'application. Français par défaut.';

  @override
  String get changePasswordTitle => 'Changer le code PIN';

  @override
  String get changePasswordCurrentPin => 'Code PIN actuel';

  @override
  String get changePasswordNewPin => 'Nouveau code PIN';

  @override
  String get changePasswordNewPinHint => '4 chiffres, stocké haché';

  @override
  String get changePasswordConfirmPin => 'Confirmer le nouveau code PIN';

  @override
  String get changePasswordMismatch => 'Les codes PIN ne correspondent pas';

  @override
  String get changePasswordShow => 'Afficher';

  @override
  String get changePasswordHide => 'Masquer';

  @override
  String get changePasswordUpdating => 'Mise à jour…';

  @override
  String get changePasswordUpdate => 'Mettre à jour';

  @override
  String get changePasswordNoSession => 'Aucune session active';

  @override
  String get changePasswordWrongPin =>
      'Le code PIN actuel ne correspond pas à ce compte.';

  @override
  String get changePasswordUpdated => 'Mot de passe mis à jour';

  @override
  String changePasswordPinLength(int count) {
    return 'Utilisez exactement $count chiffres';
  }

  @override
  String get changePasswordPinTaken =>
      'Ce code PIN est déjà utilisé — choisissez-en un autre';

  @override
  String settingsFooterCopyright(int year) {
    return '© $year BrewLine';
  }

  @override
  String get appInfoError =>
      'Impossible de charger les informations de l\'application';

  @override
  String get appInfoName => 'Nom';

  @override
  String get appInfoVersion => 'Version';

  @override
  String get appInfoBuild => 'Build';

  @override
  String get appInfoPackage => 'Package';

  @override
  String get appInfoLicenses => 'Licences open source';

  @override
  String get availabilityOnMenu => 'Au menu';

  @override
  String get availabilitySoldOut => 'Épuisé';

  @override
  String get dateFilterRange => 'Période';

  @override
  String get dateFilterAllDates => 'Toutes les dates';

  @override
  String get dateFilterToday => 'Aujourd\'hui';

  @override
  String get dateFilterClearTooltip => 'Afficher toutes les dates';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get salesLogSubtitle =>
      'Chaque ligne de produit vendue, filtrable par date, produit ou serveur.';

  @override
  String get salesLogError => 'Impossible de charger le journal des ventes.';

  @override
  String get salesLogEmpty => 'Aucune vente ne correspond à ces filtres.';

  @override
  String get salesLogDatePickerHelp => 'Filtrer les ventes par date';

  @override
  String get salesLogProductLabel => 'Produit';

  @override
  String get salesLogAllProducts => 'Tous les produits';

  @override
  String get salesLogWaiterLabel => 'Serveur';

  @override
  String get salesLogColDate => 'Date';

  @override
  String get salesLogColOrder => 'Commande n°';

  @override
  String get salesLogColProduct => 'Produit';

  @override
  String get salesLogColQty => 'Qté';

  @override
  String get salesLogColTotal => 'Total';

  @override
  String get salesLogTotal => 'Total : ';

  @override
  String get salesLogRefundTooltip => 'Rembourser cette commande';

  @override
  String get salesLogBadgeVoided => 'Annulée';

  @override
  String get salesLogBadgeRefunded => 'Remboursée';

  @override
  String get staffTitle => 'Équipe';

  @override
  String get staffAdd => 'Ajouter un membre';

  @override
  String get staffTableError => 'Impossible de charger la liste du personnel.';

  @override
  String get staffTableEmpty =>
      'Aucun membre pour l\'instant — ajoutez le premier.';

  @override
  String get staffActionsTooltip => 'Actions personnel';

  @override
  String get staffDeactivate => 'Désactiver';

  @override
  String get staffActivate => 'Activer';

  @override
  String staffDeactivateTitle(String name) {
    return 'Désactiver $name ?';
  }

  @override
  String get staffDeactivateBody =>
      'Il ne pourra plus se connecter, mais son historique de ventes reste conservé.';

  @override
  String staffDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get staffDeleteBody =>
      'Ceci supprime définitivement le compte et détache ses ventes d\'un serveur nommé. Privilégiez la désactivation pour conserver l\'attribution dans l\'historique.';

  @override
  String staffDeletedSnackbar(String name) {
    return '$name supprimé';
  }

  @override
  String get staffInactive => 'Inactif';

  @override
  String get staffActive => 'Actif';

  @override
  String get staffColName => 'Nom';

  @override
  String get staffColUsername => 'Identifiant';

  @override
  String get staffColStatus => 'Statut';

  @override
  String staffSummaryActive(num active, num total) {
    return '$active sur $total actifs';
  }

  @override
  String get staffSummaryEmpty =>
      'L\'équipe est vide — ajoutez le premier membre';

  @override
  String get staffSummaryLoading => 'Chargement de l\'équipe…';

  @override
  String get staffFormAddTitle => 'Ajouter un membre';

  @override
  String get staffFormEditTitle => 'Modifier le membre';

  @override
  String get staffFormName => 'Nom affiché';

  @override
  String get staffFormNameHint =>
      'Affiché sur les vues de service et de performances';

  @override
  String get staffFormNameRequired => 'Saisissez un nom affiché';

  @override
  String get staffFormUsername => 'Identifiant';

  @override
  String get staffFormUsernameHint => 'Utilisé pour se connecter au POS';

  @override
  String get staffFormUsernameRequired => 'Saisissez un identifiant';

  @override
  String get staffFormUsernameTooShort => 'Au moins 3 caractères';

  @override
  String get staffFormUsernameInvalid =>
      'Lettres, chiffres et tirets bas uniquement';

  @override
  String get staffFormPin => 'Code PIN';

  @override
  String get staffFormNewPin => 'Nouveau code PIN (vide = conserver)';

  @override
  String get staffFormEditNote =>
      'Le compte reste actif. Désactivez-le plutôt pour bloquer la connexion.';

  @override
  String get staffFormSaveChanges => 'Enregistrer les modifications';

  @override
  String get staffFormAddMember => 'Ajouter le membre';

  @override
  String get staffFormSaving => 'Enregistrement…';

  @override
  String staffFormAddedSnackbar(String name) {
    return '$name ajouté au personnel';
  }

  @override
  String staffFormUpdatedSnackbar(String name) {
    return '$name mis à jour';
  }

  @override
  String staffFormErrorPinLength(int count) {
    return 'Utilisez exactement $count chiffres';
  }

  @override
  String get appStartupTitle => 'brewline n\'a pas pu démarrer';

  @override
  String get appStartupCopy => 'Copier l\'erreur';

  @override
  String get appStartupCopied => 'Erreur copiée';
}
