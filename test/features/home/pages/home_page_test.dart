import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_fin/core/repositories/category_repository.dart';
import 'package:personal_fin/core/repositories/monthly_transaction_repository.dart';
import 'package:personal_fin/core/repositories/transaction_repository.dart';
import 'package:personal_fin/core/services/auth_service.dart';
import 'package:personal_fin/core/services/profile_service.dart';
import 'package:personal_fin/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:personal_fin/features/dashboard/view_models/quick_stats_view_model.dart';
import 'package:personal_fin/features/dashboard/view_models/recent_transactions_view_model.dart';
import 'package:personal_fin/features/home/pages/home_page.dart';
import 'package:personal_fin/features/dashboard/pages/dashboard_page.dart';
import 'package:personal_fin/features/profile/view_models/profile_view_model.dart';
import 'package:personal_fin/models/category.dart';
import 'package:personal_fin/models/transaction.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import '../../../helpers/test_nav_helpers.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockMonthlyTransactionRepo extends Mock implements MonthlyTransactionRepository {}
class MockCategoryRepo extends Mock implements CategoryRepository {}
class MockDashboardViewModel extends Mock implements DashboardViewModel {}
class MockQuickStatsViewModel extends Mock implements QuickStatsViewModel {}
class MockRecentTransactionsViewModel extends Mock implements RecentTransactionsViewModel {}
class MockProfileViewModel extends Mock implements ProfileViewModel {}
class MockAuthService extends Mock implements AuthService {}
class MockProfileService extends Mock implements ProfileService {}
class MockUser extends Mock implements User {}

void main() {
  late MockTransactionRepository mockTransRepo;
  late MockMonthlyTransactionRepo mockMonthlyTransRepo;
  late MockCategoryRepo mockCatRepo;
  late TestNavigationDependencyManager tdm;
  late MockDashboardViewModel mockDashboardVM;
  late MockQuickStatsViewModel mockQuickStatsVM;
  late MockRecentTransactionsViewModel mockRecentTransactionsVM;
  late MockProfileViewModel mockProfileVM;
  late MockAuthService mockAuth;
  late MockProfileService mockProfile;
  late MockUser mockUser;

  late BehaviorSubject<List<Transaction>> transactionsSubject;
  late BehaviorSubject<List<Category>> categoriesSubject;

  setUp(() {
    mockTransRepo = MockTransactionRepository();
    mockMonthlyTransRepo = MockMonthlyTransactionRepo();
    mockCatRepo = MockCategoryRepo();
    tdm = TestNavigationDependencyManager();
    mockDashboardVM = MockDashboardViewModel();
    mockQuickStatsVM = MockQuickStatsViewModel();
    mockRecentTransactionsVM = MockRecentTransactionsViewModel();
    mockProfileVM = MockProfileViewModel();
    mockAuth = MockAuthService();
    mockProfile = MockProfileService();
    mockUser = MockUser();

    transactionsSubject = BehaviorSubject<List<Transaction>>();
    categoriesSubject = BehaviorSubject<List<Category>>();

    when(() => mockMonthlyTransRepo.stream).thenAnswer((_) => transactionsSubject.stream);
    when(() => mockCatRepo.categoriesStream).thenAnswer((_) => categoriesSubject.stream);

    when(() => mockTransRepo.transactionsStream).thenAnswer((_) => Stream.value([]));

    // Stub DashboardViewModel with default values
    when(() => mockDashboardVM.isLoading).thenReturn(false);
    when(() => mockDashboardVM.currentMonthData).thenReturn(null);
    when(() => mockDashboardVM.previousMonthData).thenReturn(null);
    when(() => mockDashboardVM.errorMessage).thenReturn(null);

    // Stub QuickStatsViewModel with default values
    when(() => mockQuickStatsVM.currentMonthExpenses).thenReturn(0);
    when(() => mockQuickStatsVM.currentMonthIncome).thenReturn(0);
    when(() => mockQuickStatsVM.lastMonthExpenses).thenReturn(0);
    when(() => mockQuickStatsVM.lastMonthIncome).thenReturn(0);
    when(() => mockQuickStatsVM.isLoading).thenReturn(false);

    //Stub RecentTransactionsViewModel 
    when(() => mockRecentTransactionsVM.isLoading).thenReturn(false);
    when(() => mockRecentTransactionsVM.recentTransactions).thenReturn([]);

     // Standard User Stubs
    when(() => mockUser.uid).thenReturn('user_123');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.displayName).thenReturn('Original Name');
    when(() => mockUser.photoURL).thenReturn('https://photo.com/1');

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    // Stubs for ProfileViewModel
    when(() => mockProfileVM.isLoading).thenReturn(false);
    when(() => mockProfileVM.fullName).thenReturn('Test User');
    when(() => mockProfileVM.bio).thenReturn('Hello from tests');
    when(() => mockProfileVM.authEmail).thenReturn('test@example.com');
    when(() => mockProfileVM.photoUrl).thenReturn(null);
    when(() => mockProfileVM.signOut()).thenAnswer((_) async {});
    
    // Stub the stream to return an empty stream by default to prevent init hanging
    when(() => mockProfile.getProfileStream(any()))
        .thenAnswer((_) => const Stream.empty());
    
  });

    group('HomePage UI Tests', () {
    testWidgets('renders DashboardPage by default and displays user info in Drawer', (tester) async {
      when(() => mockDashboardVM.isLoading).thenReturn(true);
      await tester.pumpWidget(tdm.wrap(
        HomePage(
          profileViewModel: mockProfileVM,
          dashboardViewModel: mockDashboardVM,
          quickStatsViewModel: mockQuickStatsVM,
          recentTransactionsViewModel: mockRecentTransactionsVM,
        ),
        extraProviders: [
          Provider<TransactionRepository>.value(value: mockTransRepo),
          Provider<MonthlyTransactionRepository>.value(value: mockMonthlyTransRepo),
          Provider<CategoryRepository>.value(value: mockCatRepo),
          ChangeNotifierProvider<DashboardViewModel>.value(value: mockDashboardVM),
          ChangeNotifierProvider<QuickStatsViewModel>.value(value: mockQuickStatsVM),
          ChangeNotifierProvider<RecentTransactionsViewModel>.value(value: mockRecentTransactionsVM),
          ChangeNotifierProvider<ProfileViewModel>.value(value: mockProfileVM),
        ],
      ));
      
      await tester.pump(const Duration(milliseconds: 100));
      
      // Verify initial page is Dashboard
      expect(find.byType(DashboardPage), findsOneWidget);

      // Open Drawer
      final finder = find.byIcon(Icons.menu); 
      expect(finder, findsOneWidget);
      await tester.tap(finder);
      debugDumpApp();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify user data from HomeViewModel is displayed
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('BottomNavigationBar tap updates NavigationProvider', (tester) async {
      await tester.pumpWidget(tdm.wrap(
        HomePage(
          profileViewModel: mockProfileVM,
          dashboardViewModel: mockDashboardVM,
          quickStatsViewModel: mockQuickStatsVM,
          recentTransactionsViewModel: mockRecentTransactionsVM,
        ),
        extraProviders: [
          Provider<TransactionRepository>.value(value: mockTransRepo),
          Provider<MonthlyTransactionRepository>.value(value: mockMonthlyTransRepo),
          Provider<CategoryRepository>.value(value: mockCatRepo),
          ChangeNotifierProvider<DashboardViewModel>.value(value: mockDashboardVM),
          ChangeNotifierProvider<QuickStatsViewModel>.value(value: mockQuickStatsVM),
          ChangeNotifierProvider<RecentTransactionsViewModel>.value(value: mockRecentTransactionsVM),
          ChangeNotifierProvider<ProfileViewModel>.value(value: mockProfileVM),
        ],
      ));

      // Tap the Transactions icon (Index 1)
      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pump();

      // Verify the UI asked the NavProvider to change the page
      verify(() => tdm.mockNav.setPage(1)).called(1);
    });

    testWidgets('successful logout shows success snackbar and navigates', (tester) async {
      // Setup: Mock successful logout
      when(() => tdm.mockHomeVM.signOut()).thenAnswer((_) async => true);
      
      await tester.pumpWidget(tdm.wrap(
        HomePage(
          profileViewModel: mockProfileVM,
          dashboardViewModel: mockDashboardVM,
          quickStatsViewModel: mockQuickStatsVM,
          recentTransactionsViewModel: mockRecentTransactionsVM,
        ),
        extraProviders: [
          Provider<TransactionRepository>.value(value: mockTransRepo),
          Provider<MonthlyTransactionRepository>.value(value: mockMonthlyTransRepo),
          Provider<CategoryRepository>.value(value: mockCatRepo),
          ChangeNotifierProvider<DashboardViewModel>.value(value: mockDashboardVM),
          ChangeNotifierProvider<QuickStatsViewModel>.value(value: mockQuickStatsVM),
          ChangeNotifierProvider<RecentTransactionsViewModel>.value(value: mockRecentTransactionsVM),
          ChangeNotifierProvider<ProfileViewModel>.value(value: mockProfileVM),
        ],
      ));

      // Open Drawer
      await tester.dragFrom(const Offset(0, 300), const Offset(300, 300));
      await tester.pump(const Duration(milliseconds: 300));

      final drawer = find.byType(Drawer);
      final profileTile = find.descendant(
        of: drawer,
        matching: find.widgetWithText(ExpansionTile, 'profile'),
      );
      expect(profileTile, findsOneWidget);
      await tester.tap(profileTile);
      await tester.pump(const Duration(milliseconds: 500));

      final logoutTile = find.widgetWithText(ListTile, 'logout');
      await tester.ensureVisible(logoutTile);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      await tester.tap(find.descendant(of: logoutTile, matching: find.text('logout')));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify ViewModel was called
      verify(() => tdm.mockHomeVM.signOut()).called(1);

      // Verify Success Snackbar
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('logout_successful'), findsOneWidget);
    });

    testWidgets('failed logout shows error snackbar', (tester) async {
      // Setup: Mock failed logout
      when(() => tdm.mockHomeVM.signOut()).thenAnswer((_) async => false);
      
      await tester.pumpWidget(tdm.wrap(
        HomePage(
          profileViewModel: mockProfileVM,
          dashboardViewModel: mockDashboardVM,
          quickStatsViewModel: mockQuickStatsVM,
          recentTransactionsViewModel: mockRecentTransactionsVM,
        ),
        extraProviders: [
          Provider<TransactionRepository>.value(value: mockTransRepo),
          Provider<MonthlyTransactionRepository>.value(value: mockMonthlyTransRepo),
          Provider<CategoryRepository>.value(value: mockCatRepo),
          ChangeNotifierProvider<DashboardViewModel>.value(value: mockDashboardVM),
          ChangeNotifierProvider<QuickStatsViewModel>.value(value: mockQuickStatsVM),
          ChangeNotifierProvider<RecentTransactionsViewModel>.value(value: mockRecentTransactionsVM),
          ChangeNotifierProvider<ProfileViewModel>.value(value: mockProfileVM),
        ],
      ));

      // Open Drawer and Tap Logout
      await tester.dragFrom(const Offset(0, 300), const Offset(300, 300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('logout'));
      await tester.pumpAndSettle();

      // Verify Error Snackbar
      expect(find.text('logout_failed'), findsOneWidget);
    });
  });
}