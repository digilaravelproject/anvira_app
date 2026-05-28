import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:webinar/app/models/login_history_model.dart';
import 'package:provider/provider.dart';
import 'package:webinar/app/pages/authentication_page/login_page.dart';
import 'package:webinar/app/providers/app_language_provider.dart';
import 'package:webinar/app/providers/user_provider.dart';
import 'package:webinar/app/providers/drawer_provider.dart';
import 'package:webinar/config/assets.dart';
import 'package:webinar/app/services/guest_service/guest_service.dart';
import 'package:webinar/app/services/guest_service/location_service.dart';
import 'package:webinar/app/services/user_service/user_service.dart';
import 'package:webinar/app/widgets/main_widget/setting_widget/setting_widget.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/common/data/app_data.dart';
import 'package:webinar/common/database/app_database.dart';
import 'package:webinar/common/enums/error_enum.dart';
import 'package:webinar/common/utils/app_text.dart';
import 'package:webinar/common/utils/role_translator.dart';
import 'package:webinar/common/utils/object_instance.dart';
import 'package:webinar/config/styles.dart';
import 'package:webinar/locator.dart';

import '../../../../../config/colors.dart';
import '../../../../models/location_model.dart';

class SettingPage extends StatefulWidget {
  static const String pageName = '/profile';
  final bool isTab;
  const SettingPage({super.key, this.isTab = false});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with TickerProviderStateMixin{

  late TabController tabController;

  bool isLocalImage = false;
  File? localImage;



  TextEditingController emailController = TextEditingController();
  FocusNode emailNode = FocusNode();
  TextEditingController nameController = TextEditingController();
  FocusNode nameNode = FocusNode();
  TextEditingController phoneController = TextEditingController();
  FocusNode phoneNode = FocusNode();
  TextEditingController refUrlController = TextEditingController();
  FocusNode refUrlNode = FocusNode();
  TextEditingController languageController = TextEditingController();
  FocusNode languageNode = FocusNode();

  bool newsletter = false;

  TextEditingController currentPasswordController = TextEditingController();
  FocusNode currentPasswordNode = FocusNode();
  TextEditingController newPasswordController = TextEditingController();
  FocusNode newPasswordNode = FocusNode();
  TextEditingController retypePasswordController = TextEditingController();
  FocusNode retypePasswordNode = FocusNode();


  TextEditingController accountTypeController = TextEditingController();
  FocusNode accountTypeNode = FocusNode();
  TextEditingController ibanController = TextEditingController();
  FocusNode ibanNode = FocusNode();
  TextEditingController accountIdController = TextEditingController();
  FocusNode accountIdNode = FocusNode();
  TextEditingController addressController = TextEditingController();
  FocusNode addressNode = FocusNode();

  File? indentityScanImage;
  File? certificateImage;
  bool isApprovedIndentity = false;
  bool isApprovedCertificate = false;

  List<LocationModel> countries = [];
  LocationModel? selectedCountry;
  
  List<String> timeZoneData = [];
  String? timeZoneSelected;

  int? provinceSelectedId;
  int? citySelectedId;
  int? districtSelectedId;


  bool isLoading = false;
  bool isLoadingDeleteAccount = false;
  bool showMoreLoginHistory = false;

  List<LoginHistoryModel> loginHistory = [];


  bool hasLogin = false;
  bool isLoadingToken = true;

  @override
  void initState() {
    super.initState();
    
    tabController = TabController(length: 4, vsync: this);

    AppData.getAccessToken().then((value) {
      hasLogin = value.isNotEmpty;
      if (hasLogin) {
        emailController.text = locator<UserProvider>().profile?.email ?? '';
        nameController.text = locator<UserProvider>().profile?.fullName ?? '';
        phoneController.text = locator<UserProvider>().profile?.mobile ?? '';
        refUrlController.text = locator<UserProvider>().profile?.mobile ?? '';

        newsletter = locator<UserProvider>().profile?.newsletter ?? false;

        addressController.text = locator<UserProvider>().profile?.address ?? '';
        ibanController.text = locator<UserProvider>().profile?.iban ?? '';
        accountIdController.text = locator<UserProvider>().profile?.accountId ?? '';

        timeZoneSelected = locator<UserProvider>().profile?.timezone;
        provinceSelectedId = locator<UserProvider>().profile?.provinceId;
        citySelectedId = locator<UserProvider>().profile?.cityId;
        districtSelectedId = locator<UserProvider>().profile?.districtId;

        LocationService.getCountries().then((value) {
          countries = value;
          if (locator<UserProvider>().profile?.countryId != null) {
            try {
              selectedCountry = countries.singleWhere((element) => element.id == (locator<UserProvider>().profile?.countryId));
            } catch (_) {}
          }
          setState(() {});
        });

        GuestService.getTimeZone().then((value) {
          timeZoneData = value;
          setState(() {});
        });

        UserService.getLoginHistory().then((value){
          loginHistory = value;
          setState(() {});
        });
      }
      setState(() {
        isLoadingToken = false;
      });
    });
  }


  Future<File> compressImage(XFile file) async {
    
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String address = '${appDocDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      address,
      quality: 55,
      minWidth: 550,
    );   

    
    return File(result!.path);
  }



  @override
  Widget build(BuildContext context) {
    double bottomSpace = widget.isTab ? 120.0 : 30.0;

    Widget buildSaveButton({bool hasHorizontalPadding = false}) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hasHorizontalPadding ? 21.0 : 0.0, vertical: 10.0),
        child: button(
          onTap: () async {
            setState(() {
              isLoading = true;
            });

            bool res = await UserService.updateInfo(
              emailController.text.trim().toEnglishDigit(), 
              nameController.text.trim().toEnglishDigit(), 
              phoneController.text.trim().toEnglishDigit(), 
              timeZoneSelected ?? '', 
              newsletter, 
              ibanController.text.trim().toEnglishDigit(), 
              accountTypeController.text.trim().toEnglishDigit(), 
              accountIdController.text.trim().toEnglishDigit(), 
              addressController.text.trim().toEnglishDigit(), 
              selectedCountry?.id, 
              provinceSelectedId, citySelectedId, districtSelectedId
            );
            
            if(res){
              if(currentPasswordController.text.trim().isNotEmpty && newPasswordController.text.trim().isNotEmpty){
                if(newPasswordController.text.trim().compareTo(retypePasswordController.text.trim()) == 0){
                  await UserService.updatePassword(
                    currentPasswordController.text.trim().toEnglishDigit(), 
                    newPasswordController.text.trim().toEnglishDigit(),
                  ); 
                }else{
                  showSnackBar(ErrorEnum.success, appText.passwordAndRetypePassNotMatch);
                }
              }

              if(localImage != null || indentityScanImage != null || certificateImage != null){
                await UserService.updateImage(localImage, indentityScanImage, certificateImage);
              }

              if(mounted){
                if (widget.isTab) {
                  showSnackBar(ErrorEnum.success, appText.successfulyRequest);
                } else {
                  backRoute();
                }
              }
            }
            
            setState(() {
              isLoading = false;
            });
          }, 
          width: getSize().width, 
          height: 51, 
          text: appText.save, 
          bgColor: green77(), 
          textColor: Colors.white,
          isLoading: isLoading
        ),
      );
    }

    Widget buildBody() {
      return Scaffold(
        appBar: appbar(
          title: appText.settings,
          leftIcon: widget.isTab ? AppAssets.menuSvg : AppAssets.backSvg,
          onTapLeftIcon: widget.isTab ? () {
            drawerController.showDrawer();
          } : backRoute,
        ),
        body: isLoadingToken
            ? loading()
            : !hasLogin
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      emptyState(AppAssets.loginEmptyStateSvg, appText.login, appText.loginDesc, isBottomPadding: false),
                      space(16, width: getSize().width),
                      button(
                        onTap: () {
                          nextRoute(LoginPage.pageName);
                        },
                        width: getSize().width * .65,
                        height: 52,
                        text: appText.login,
                        bgColor: green77(),
                        textColor: Colors.white,
                        raduis: 16,
                      ),
                      space(getSize().height * .15),
                    ],
                  )
                : NestedScrollView(
                physics: const BouncingScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    // image and name
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          space(20),

                          // image
                          Stack(
                            clipBehavior: Clip.none,
                            children: [

                              GestureDetector(
                                onTap: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                                  if(image != null){
                                    localImage = await compressImage(image);

                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  width: 95,
                                  height: 95,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: green77(),
                                      width: 5
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      boxShadow(
                                        green77().withOpacity(.25), blur: 30, y: 2
                                      )
                                    ]
                                  ),
                              
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: ClipRRect(
                                      borderRadius: borderRadius(radius: 120),
                                      child: localImage == null 
                                        ? fadeInImage( (locator<UserProvider>().profile?.avatar) ?? '', 80, 80 )
                                        : Image.file( localImage!, width: 80, height: 80, fit: BoxFit.cover ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          space(20),

                          Text(
                            locator<UserProvider>().profile?.fullName ?? '',
                            style: style20Bold(),
                          ),
                          
                          space(4),
                          
                          Text(
                            roleTranslator(locator<UserProvider>().profile?.roleName ?? ''),
                            style: style12Regular().copyWith(color: greyA5),
                          ),
                        ],
                      ),
                    ),

                    // tabs
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      backgroundColor: backgroundColor,
                      titleSpacing: 0,
                      elevation: 10,
                      shadowColor: Colors.black12,
                      title: tabBar((p0) {}, tabController, [
                        Tab(text: appText.general, height: 32),
                        Tab(text: appText.security, height: 32),
                        Tab(text: appText.financial, height: 32),
                        Tab(text: appText.localization, height: 32),
                      ]),
                    ),

                  ];
                },
                body: TabBarView(
                  controller: tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    
                    SettingWidget.generalPage(
                      emailController, emailNode, nameController, nameNode, phoneController, phoneNode, 
                      refUrlController, refUrlNode, languageController, languageNode, newsletter,
                      (){
                        setState(() {});
                      },
                      (val){
                        newsletter = val;
                        setState(() {});
                      },
                      buildSaveButton(hasHorizontalPadding: false),
                      bottomSpace,
                    ),
                    
                    
                    SettingWidget.securityPage(
                      currentPasswordController, currentPasswordNode,
                      newPasswordController, newPasswordNode, 
                      retypePasswordController, retypePasswordNode,
                      loginHistory,
                      isLoadingDeleteAccount,
                      () async {
                        setState(() {
                          isLoadingDeleteAccount = true;
                        });
                        
                        bool? res = await UserService.deleteAccount();
 
                        if(res){
                          
                          await AppData.saveCurrency('');
                          AppData.saveAccessToken('');
                          AppDataBase.clearBox();
 
                          
                          locator<UserProvider>().clearAll();
                          locator<AppLanguageProvider>().changeState();
                          
                          nextRoute(LoginPage.pageName, isClearBackRoutes: true);
                        }
                        
                        setState(() {
                          isLoadingDeleteAccount = false;
                        });
                      },
                      showMoreLoginHistory,
                      (){
                        showMoreLoginHistory = !showMoreLoginHistory;
                        setState(() {});
                      },
                      buildSaveButton(hasHorizontalPadding: true),
                      bottomSpace,
                    ),
              
              
                    SettingWidget.financialPage(
                      accountTypeController, accountTypeNode, ibanController, ibanNode,
                      accountIdController, accountIdNode, addressController, addressNode, 
                      (){
                        setState(() {});
                      },
                      indentityScanImage,
                      certificateImage,
                      locator<UserProvider>().profile?.identityScan != null,
                      locator<UserProvider>().profile?.certificate != null,
                      (ImageSource source) async { //selectIndentityImage 
                        
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: source);
              
                        if(image != null){
                          indentityScanImage = await compressImage(image);
              
                          setState(() {});
                        }
              
                      },
                      () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              
                        if(image != null){
                          certificateImage = await compressImage(image);
              
                          setState(() {});
                        }
                      },
                      buildSaveButton(hasHorizontalPadding: false),
                      bottomSpace,
                    ),
                    
              
                    SettingWidget.localizationPage(
                      countries,
                      selectedCountry,
                      (data){
                        selectedCountry = data;
                        setState(() {});
                      },
              
                      timeZoneData,
                      timeZoneSelected,
                      (data){
                        timeZoneSelected = data;
                        setState(() {});
                      },
                      
                      provinceSelectedId,
                      (id){
                        provinceSelectedId = id;
                        setState(() {});
                      },
                      
                      citySelectedId,
                      (id){
                        citySelectedId = id;
                        setState(() {});
                      },
                      
                      districtSelectedId,
                      (id){
                        districtSelectedId = id;
                        setState(() {});
                      },
                      buildSaveButton(hasHorizontalPadding: false),
                      bottomSpace,
                    )
                  ]
                ),
              ),
      );
    }

    if (widget.isTab) {
      return directionality(
        child: Consumer<DrawerProvider>(
          builder: (context, drawerProvider, _) {
            return ClipRRect(
              borderRadius: borderRadius(radius: drawerProvider.isOpenDrawer ? 20 : 0),
              child: buildBody(),
            );
          }
        )
      );
    } else {
      return directionality(
        child: buildBody()
      );
    }
  }
}