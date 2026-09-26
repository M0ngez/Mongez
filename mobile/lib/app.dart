import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/locale/localization_cubit.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/core/theme/app_themes.dart';
import 'package:mongez/core/theme/theme_cubit.dart';
import 'package:mongez/features/auth/bloc/auth_cubit.dart';
import 'package:mongez/features/auth/repos/auth_repository.dart';
import 'package:mongez/features/client/favorites/domain/favorites_repository.dart';
import 'package:mongez/features/client/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:mongez/features/client/home/data/repositories/home_repo.dart';
import 'package:mongez/features/client/home/presentation/cubit/categories_cubit.dart';
import 'package:mongez/features/client/home/presentation/cubit/workers_cubit.dart';
import 'package:mongez/features/client/order/domain/order_repository.dart';
import 'package:mongez/features/client/order/presentation/cubit/checkout_cubit.dart';
import 'package:mongez/features/client/order/presentation/cubit/customer_orders_cubit.dart';
import 'package:mongez/features/shared/notifications/domain/notification_repository.dart';
import 'package:mongez/features/shared/notifications/presentation/cubit/notification_cubit.dart';
import 'package:mongez/features/shared/profile/domain/profile_repository.dart';
import 'package:mongez/features/shared/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/shared/unread/presentation/cubit/unread_counts_cubit.dart';
import 'package:mongez/features/shared/workers/domain/worker_repository.dart';
import 'package:mongez/features/splash/app_startup_screen.dart';
import 'package:mongez/features/worker/home/presentation/cubit/worker_stats_cubit.dart';
import 'package:mongez/features/worker/profile_setup/presentation/cubit/create_worker_profile_cubit.dart';
import 'package:mongez/features/worker/requests/presentation/cubit/job_history_cubit.dart';
import 'package:mongez/features/worker/requests/presentation/cubit/technician_orders_cubit.dart';
import 'package:mongez/generated/l10n.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit(context)),
            BlocProvider(create: (_) => LocalizationCubit()),
            BlocProvider(
              create: (context) =>
                  AuthCubit(authRepository: getIt.get<AuthRepository>()),
            ),
            // Categories are fetched lazily by the screens and re-fetched on
            // main via NavigationService._fetchFreshData; not firing here (as
            // a guest) avoids a duplicate pre-auth network request at startup.
            BlocProvider(
              create: (context) =>
                  CategoriesCubit(homeRepo: getIt.get<HomeRepo>()),
            ),
            BlocProvider(
              create: (context) =>
                  WorkersCubit(workerRepository: getIt.get<WorkerRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  ProfileCubit(profileRepository: getIt.get<ProfileRepository>())
                    ..startPolling(),
            ),
            // Order/history/favorites data is loaded on the main screen via
            // NavigationService._fetchFreshData and by the screens themselves,
            // so those cubits are only registered here (their eager, pre-auth
            // loads were duplicated on navigation and just slowed startup).
            BlocProvider(
              create: (context) => CustomerOrdersCubit(
                orderRepository: getIt.get<OrderRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => TechnicianOrdersCubit(
                orderRepository: getIt.get<OrderRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => JobHistoryCubit(
                orderRepository: getIt.get<OrderRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => CheckoutCubit(
                orderRepository: getIt.get<OrderRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => FavoritesCubit(
                favoritesRepository: getIt.get<FavoritesRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => CreateWorkerProfileCubit(
                workerRepository: getIt.get<WorkerRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => WorkerStatsCubit(
                workerRepository: getIt.get<WorkerRepository>(),
              ),
            ),
            BlocProvider(
              create: (context) => NotificationCubit(
                notificationRepository: getIt.get<NotificationRepository>(),
              ),
            ),
            // Bottom-nav unread badges: derives its numbers from the cubits
            // registered above, so it adds no polling and no API call.
            BlocProvider(
              create: (context) => UnreadCountsCubit(
                notificationCubit: context.read<NotificationCubit>(),
                technicianOrdersCubit: context.read<TechnicianOrdersCubit>(),
                profileCubit: context.read<ProfileCubit>(),
                favoritesCubit: context.read<FavoritesCubit>(),
              ),
            ),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<LocalizationCubit, LocalizationState>(
                builder: (context, localeState) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    navigatorKey: NavigationService.navigatorKey,
                    theme: AppThemes.lightTheme,
                    darkTheme: AppThemes.darkTheme,
                    themeMode: themeState.themeMode,
                    locale: localeState.locale,
                    localizationsDelegates: [
                      S.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: S.delegate.supportedLocales,
                    localeResolutionCallback: (
                      Locale? locale,
                      Iterable<Locale> supportedLocales,
                    ) {
                      if (locale != null) {
                        for (final supported in supportedLocales) {
                          if (supported.languageCode == locale.languageCode) {
                            return supported;
                          }
                        }
                      }
                      return const Locale('en');
                    },
                    home: const AppStartupScreen(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
