"""Static project integrity only. Does not compile Swift or validate Xcode."""
from pathlib import Path
import json, plistlib, re, hashlib, platform
from datetime import datetime, timezone
from xml.etree import ElementTree

root=Path(__file__).resolve().parents[1]
ios=root/'ios'
project=ios/'TurfOrnamentalPro.xcodeproj'
text=(project/'project.pbxproj').read_text()
definitions=re.findall(r'"([A-F0-9]{24})" = \{',text)
references=set(re.findall(r'"([A-F0-9]{24})"',text))
assert len(definitions)==len(set(definitions)), 'Duplicate project IDs'
assert references==set(definitions), 'Unresolved project references'
for path in re.findall(r'"path" = "([^"]+)";',text):
    if not path.endswith(('.app','.xctest')): assert (ios/path).is_file(), path
scheme=ElementTree.parse(project/'xcshareddata/xcschemes/TurfOrnamentalPro.xcscheme')
for build in scheme.findall('.//BuildableReference'):
    assert build.attrib['BlueprintIdentifier'] in references
with (ios/'Info.plist').open('rb') as f: info=plistlib.load(f)
with (ios/'PrivacyInfo.xcprivacy').open('rb') as f: privacy=plistlib.load(f)
assert info['LSRequiresIPhoneOS'] is True
assert privacy['NSPrivacyTracking'] is False
assert info.get('NSLocationWhenInUseUsageDescription')
assert info.get('NSCameraUsageDescription')
assert info.get('NSMicrophoneUsageDescription') and info.get('NSSpeechRecognitionUsageDescription')
assert not any(key in info for key in ['NSLocationAlwaysAndWhenInUseUsageDescription','NSPhotoLibraryUsageDescription','UIBackgroundModes'])
evidence={
    'procedure':'python scripts/check_project.py',
    'utc_time':datetime.now(timezone.utc).isoformat(),
    'environment':platform.platform()+'; Python '+platform.python_version(),
    'result':'PASS',
    'checks':['unique and resolved project object IDs','source/resource paths exist','shared scheme target references','valid Info/privacy XML property lists'],
    'project_sha256':hashlib.sha256((project/'project.pbxproj').read_bytes()).hexdigest(),
    'not_tested':['Swift compilation','Xcode project loading','Swift tests','simulator','device','signing','App Store submission']}
output=root/'docs/evidence/project-integrity.json'
output.parent.mkdir(parents=True,exist_ok=True)
output.write_text(json.dumps(evidence,indent=2)+'\n')
print(json.dumps(evidence,indent=2))
