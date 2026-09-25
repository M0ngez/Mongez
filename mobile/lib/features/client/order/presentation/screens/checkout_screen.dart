import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/core/theme/app_colors.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/network/api_service.dart';
import 'package:mongez/core/widgets/custom_app_bar.dart';
import 'package:mongez/core/widgets/custom_text_form_field.dart';
import 'package:mongez/features/client/address/data/models/address_model.dart';
import 'package:mongez/features/client/address/presentation/screens/addresses_screen.dart';
import 'package:mongez/features/client/order/presentation/cubit/checkout_cubit.dart';
import 'package:mongez/features/client/order/presentation/widgets/address_field.dart';
import 'package:mongez/features/client/order/presentation/widgets/attachment_bundle.dart';
import 'package:mongez/features/client/order/presentation/widgets/attachments_picker.dart';
import 'package:mongez/features/client/order/presentation/widgets/checkout_info_banner.dart';
import 'package:mongez/features/client/order/presentation/widgets/checkout_section.dart';
import 'package:mongez/features/client/order/presentation/widgets/checkout_submit_button.dart';
import 'package:mongez/features/client/order/presentation/widgets/checkout_worker_card.dart';
import 'package:mongez/features/client/order/presentation/widgets/order_placed_dialog.dart';
import 'package:mongez/features/client/order/presentation/widgets/phone_field.dart';
import 'package:mongez/features/shared/profile/presentation/cubit/profile_cubit.dart';
import 'package:mongez/features/shared/workers/data/models/worker_model.dart';
import 'package:mongez/generated/l10n.dart';

class CheckoutScreen extends StatefulWidget {
  final WorkerModel worker;
  const CheckoutScreen({super.key, required this.worker});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _useAccountPhone = true;
  bool _initialized = false;
  AttachmentBundle _attachments = const AttachmentBundle();
  AddressModel? _selectedAddress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (GuestSession.isGuest) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          NavigationService.requireLogin(
            context,
            message: S.of(context).checkoutLoginRequired,
            onLoggedIn: () => NavigationService.navigatorKey.currentState
                ?.push(
              MaterialPageRoute(
                builder: (_) => CheckoutScreen(worker: widget.worker),
              ),
            ),
          );
        });
        return;
      }
      _loadDefaults();
      _loadDefaultAddress();
    }
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final api = getIt<ApiService>();
      final data = await api.get(endPoint: Endpoints.addresses);
      final list = (data as List<dynamic>)
          .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      // Auto-select the default if nothing is selected yet.
      if (list.isNotEmpty) {
        final defaultAddr = list.firstWhere(
          (a) => a.isDefault,
          orElse: () => list.first,
        );
        _selectedAddress = defaultAddr;
        _addressController.text = defaultAddr.shortAddress;
        setState(() {});
      }
    } catch (_) {
      // Silently fail — address is optional for order creation.
    }
  }

  void _loadDefaults() {
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileSuccess) {
      if (_phoneController.text.isEmpty) {
        _phoneController.text = profileState.profile.phone;
      }
      if (_addressController.text.isEmpty) {
        _addressController.text = profileState.profile.address;
      }
    }
  }

  String _getAddressText() {
    if (_selectedAddress != null) {
      return _selectedAddress!.displayAddress;
    }
    return _addressController.text;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;

    final addressId = _selectedAddress?.id;
    final addressText = _getAddressText();

    if (addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).tapToSelectAddress),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    context.read<CheckoutCubit>().createOrder(
      serviceCategory: widget.worker.categoryId ?? 0,
      workerId: widget.worker.userId ?? widget.worker.id,
      description: _descriptionController.text.trim(),
      address: addressText.isNotEmpty ? addressText : null,
      addressId: addressId,
      phone: _useAccountPhone ? null : _phoneController.text.trim(),
      photos: _attachments.photos,
      audioPath: _attachments.audioPath,
      audioDurationSeconds: _attachments.audioDurationSeconds,
    );
  }

  String? _validateRequired(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return S.of(context).thisFieldRequired;
    return null;
  }

  String? _validatePhone(String? value) {
    if (_useAccountPhone) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 20) return S.of(context).phoneTooLong;
    if (!RegExp(r'^\+?[\d\s\-()]{7,20}$').hasMatch(text)) {
      return S.of(context).invalidPhoneNumber;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage)),
          );
        }
        if (state is CheckoutSuccess) {
          showDialog(
            context: context,
            builder: (_) => const OrderPlacedDialog(),
          );
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(title: lang.checkout),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: CheckoutWorkerCard(worker: widget.worker)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: CheckoutSection(
                title: lang.orderDetails,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomFormField(
                      controller: _descriptionController,
                      hintText: lang.enterProblem,
                      keyboardType: TextInputType.multiline,
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      lang.addPhotosOrVoice,
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AttachmentsPicker(
                      onChanged: (b) => _attachments = b,
                    ),
                  ],
                ),
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: CheckoutInfoBanner(text: lang.cancelWithinHour)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: CheckoutSection(
                title: lang.contactInfo,
                child: PhoneField(
                  controller: _phoneController,
                  useAccountPhone: _useAccountPhone,
                  validator: _validatePhone,
                  onToggle: (value) {
                    setState(() {
                      _useAccountPhone = value;
                    });
                  },
                ),
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: CheckoutSection(
                title: lang.deliveryAddress,
                child: AddressField(
                  selectedAddress: _selectedAddress,
                  displayText: _getAddressText(),
                  onTap: () async {
                    final result = await Navigator.push<AddressModel>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SavedAddressPage(
                          initialSelectedId: _selectedAddress?.id,
                          // Picking a delivery address for THIS order
                          // must not move the user's default.
                          setsDefault: false,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedAddress = result;
                        _addressController.text = result.address;
                      });
                    }
                  },
                ),
              )),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                  child: Text(lang.note,
                      style: textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                  child: CheckoutSubmitButton(onPressed: _placeOrder)),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
