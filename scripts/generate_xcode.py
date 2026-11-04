"""Generate a dependency-free Xcode app + XCTest project deterministically."""
from pathlib import Path
import hashlib, json, plistlib
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / 'ios'
objects = {}
def uid(key): return hashlib.sha256(key.encode()).hexdigest()[:24].upper()
def add(key, **fields):
    ident=uid(key); objects[ident]=fields; return ident
def serialize(value, level=0):
    if isinstance(value, dict):
        return '{\n'+''.join('\t'*(level+1)+json.dumps(str(k))+' = '+serialize(v,level+1)+';\n' for k,v in value.items())+'\t'*level+'}'
    if isinstance(value, list): return '('+', '.join(serialize(v,level) for v in value)+')'
    return json.dumps(str(value))
def configs(key, settings):
    ids=[]
    for mode in ['Debug','Release']:
        configured=dict(settings)
        configured.update(SWIFT_OPTIMIZATION_LEVEL='-Onone' if mode=='Debug' else '-O', DEBUG_INFORMATION_FORMAT='dwarf' if mode=='Debug' else 'dwarf-with-dsym')
        if mode=='Debug': configured.update(ENABLE_TESTABILITY='YES', SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG')
        ids.append(add(key+mode,isa='XCBuildConfiguration',name=mode,buildSettings=configured))
    return add(key+'configs',isa='XCConfigurationList',buildConfigurations=ids,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')

app_files=sorted([*IOS.glob('App/*.swift'),*IOS.glob('Core/*.swift')])
test_files=sorted(IOS.glob('Tests/*.swift'))
refs=[]
def phase(key, paths, isa):
    builds=[]
    for path in paths:
        relative=path.relative_to(IOS).as_posix()
        ref=add('file:'+relative,isa='PBXFileReference',lastKnownFileType='sourcecode.swift' if path.suffix=='.swift' else 'text.xml',path=relative,sourceTree='<group>')
        refs.append(ref)
        builds.append(add('build:'+relative,isa='PBXBuildFile',fileRef=ref))
    return add(key,isa=isa,buildActionMask=2147483647,files=builds,runOnlyForDeploymentPostprocessing=0)
app_sources=phase('appSources',app_files,'PBXSourcesBuildPhase')
test_sources=phase('testSources',test_files,'PBXSourcesBuildPhase')
resources=phase('resources',[IOS/'PrivacyInfo.xcprivacy'],'PBXResourcesBuildPhase')
app_product=add('appProduct',isa='PBXFileReference',explicitFileType='wrapper.application',path='TurfOrnamentalPro.app',sourceTree='BUILT_PRODUCTS_DIR',includeInIndex=0)
test_product=add('testProduct',isa='PBXFileReference',explicitFileType='wrapper.cfbundle',path='TurfOrnamentalProTests.xctest',sourceTree='BUILT_PRODUCTS_DIR',includeInIndex=0)
products=add('products',isa='PBXGroup',children=[app_product,test_product],name='Products',sourceTree='<group>')
group=add('mainGroup',isa='PBXGroup',children=refs+[products],sourceTree='<group>')
base=dict(SWIFT_VERSION='5.0',IPHONEOS_DEPLOYMENT_TARGET='17.0',SDKROOT='iphoneos',SUPPORTED_PLATFORMS='iphoneos iphonesimulator',TARGETED_DEVICE_FAMILY='1',CODE_SIGN_STYLE='Automatic',GENERATE_INFOPLIST_FILE='NO',CURRENT_PROJECT_VERSION='1',MARKETING_VERSION='0.1.0',PRODUCT_NAME='$(TARGET_NAME)',SWIFT_EMIT_LOC_STRINGS='YES')
app_config=configs('app',dict(base,PRODUCT_BUNDLE_IDENTIFIER='com.example.TurfOrnamentalPro',INFOPLIST_FILE='Info.plist'))
app_target=add('appTarget',isa='PBXNativeTarget',buildConfigurationList=app_config,buildPhases=[app_sources,resources],buildRules=[],dependencies=[],name='TurfOrnamentalPro',productName='TurfOrnamentalPro',productReference=app_product,productType='com.apple.product-type.application')
proxy=add('testProxy',isa='PBXContainerItemProxy',containerPortal=uid('project'),proxyType=1,remoteGlobalIDString=app_target,remoteInfo='TurfOrnamentalPro')
dependency=add('testDependency',isa='PBXTargetDependency',target=app_target,targetProxy=proxy)
test_settings=dict(base,PRODUCT_BUNDLE_IDENTIFIER='com.example.TurfOrnamentalProTests',GENERATE_INFOPLIST_FILE='YES',TEST_HOST='$(BUILT_PRODUCTS_DIR)/TurfOrnamentalPro.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TurfOrnamentalPro',BUNDLE_LOADER='$(TEST_HOST)')
test_target=add('testTarget',isa='PBXNativeTarget',buildConfigurationList=configs('tests',test_settings),buildPhases=[test_sources],buildRules=[],dependencies=[dependency],name='TurfOrnamentalProTests',productName='TurfOrnamentalProTests',productReference=test_product,productType='com.apple.product-type.bundle.unit-test')
project=add('project',isa='PBXProject',attributes=dict(BuildIndependentTargetsInParallel='YES',LastUpgradeCheck='2600'),buildConfigurationList=configs('project',dict(CLANG_ENABLE_MODULES='YES')),compatibilityVersion='Xcode 14.0',developmentRegion='en',knownRegions=['en','Base'],mainGroup=group,productRefGroup=products,projectDirPath='',projectRoot='',targets=[app_target,test_target])
bundle=IOS/'TurfOrnamentalPro.xcodeproj'
bundle.mkdir(exist_ok=True)
payload=dict(archiveVersion=1,classes={},objectVersion=56,objects=objects,rootObject=project)
(bundle/'project.pbxproj').write_text('// !$*UTF8*$!\n'+serialize(payload)+'\n',encoding='utf-8')
info=dict(CFBundleDevelopmentRegion='en',CFBundleDisplayName='Turf & Ornamental Pro',CFBundleExecutable='$(EXECUTABLE_NAME)',CFBundleIdentifier='$(PRODUCT_BUNDLE_IDENTIFIER)',CFBundleInfoDictionaryVersion='6.0',CFBundleName='$(PRODUCT_NAME)',CFBundlePackageType='APPL',CFBundleShortVersionString='$(MARKETING_VERSION)',CFBundleVersion='$(CURRENT_PROJECT_VERSION)',LSRequiresIPhoneOS=True,UILaunchScreen={},UISupportedInterfaceOrientations=['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],UIApplicationSceneManifest={'UIApplicationSupportsMultipleScenes':False})
(IOS/'Info.plist').write_bytes(plistlib.dumps(info,sort_keys=True))
info['NSLocationWhenInUseUsageDescription']='Use your location to set up a property when you request it. Confirm the property before saving.'
info['NSCameraUsageDescription']='Take still photos of turf, plants, pests and labels to save privately with your selected property.'
info['NSMicrophoneUsageDescription']='Use the microphone only when you start dictating a field note. Recording stops when you leave or background the app.'
info['NSSpeechRecognitionUsageDescription']='Convert your spoken English field notes to editable text using on-device recognition when available.'
(IOS/'Info.plist').write_bytes(plistlib.dumps(info,sort_keys=True))
(IOS/'PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps(dict(NSPrivacyTracking=False,NSPrivacyTrackingDomains=[],NSPrivacyCollectedDataTypes=[],NSPrivacyAccessedAPITypes=[]),sort_keys=True))
scheme_dir=bundle/'xcshareddata/xcschemes'; scheme_dir.mkdir(parents=True,exist_ok=True)
def reference(ident,name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ident}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:TurfOrnamentalPro.xcodeproj"/>'
app_ref=reference(app_target,'TurfOrnamentalPro.app'); test_ref=reference(test_target,'TurfOrnamentalProTests.xctest')
scheme=f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
(scheme_dir/'TurfOrnamentalPro.xcscheme').write_text(scheme,encoding='utf-8')
# Structural generation checks only; these do not establish an Xcode build.
assert len(app_files)>=4 and len(test_files)>=1
assert len(objects)==len(set(objects))
assert all(p.exists() for p in app_files+test_files)
print(f'Generated {bundle}: {len(app_files)} app/core sources, {len(test_files)} test source, two targets, shared scheme.')
