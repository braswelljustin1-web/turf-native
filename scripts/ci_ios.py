"""Unsigned simulator CI. No signing, upload-to-Apple or deployment path."""
from pathlib import Path
import datetime
import json
import os
import platform
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

def select_iphone(payload):
    candidates=[]
    for runtime, devices in payload.get('devices',{}).items():
        match=re.search(r'\.iOS-(\d+)(?:-(\d+))?',runtime)
        if not match or int(match[1])<17: continue
        version=(int(match[1]),int(match[2] or 0))
        for device in devices:
            if device.get('isAvailable') is True and device.get('name','').startswith('iPhone'):
                candidates.append((version,device['name'],device['udid']))
    if not candidates:
        raise RuntimeError('No available iPhone simulator with iOS 17+ is installed. No runtime will be downloaded automatically.')
    return sorted(candidates,reverse=True)[0][2]

def self_test():
    sample={'devices':{
        'com.apple.CoreSimulator.SimRuntime.iOS-16-4':[{'name':'iPhone Old','udid':'old','isAvailable':True}],
        'com.apple.CoreSimulator.SimRuntime.iOS-26-0':[
            {'name':'iPhone Test','udid':'usable','isAvailable':True},
            {'name':'iPhone Missing','udid':'missing','isAvailable':False},
            {'name':'iPad Test','udid':'tablet','isAvailable':True}],
        'com.apple.CoreSimulator.SimRuntime.tvOS-26-0':[{'name':'iPhone Wrong Platform','udid':'wrong','isAvailable':True}]}}
    assert select_iphone(sample)=='usable'
    for value in ({},{'devices':{'com.apple.CoreSimulator.SimRuntime.iOS-26-0':[{'name':'iPad','udid':'tablet','isAvailable':True}]}}):
        try: select_iphone(value)
        except RuntimeError: pass
        else: raise AssertionError('Missing iPhone must fail closed')
    print('PASS: synthetic simulator selection and no-compatible-device failure. No cloud or Xcode execution.')

def main():
    if sys.argv[1:]==['--self-test']:
        self_test(); return
    if platform.system()!='Darwin':
        raise SystemExit('Actual CI requires macOS. On Windows use --self-test for helper checks only.')
    output=ROOT/'build/ci'
    output.mkdir(parents=True,exist_ok=True)
    report={'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'platform':platform.platform(),'commit':os.environ.get('GITHUB_SHA','local-uncommitted'),
            'run_id':os.environ.get('GITHUB_RUN_ID'),'signing':False,'publication':False,'commands':[],
            'status':'RUNNING','limitations':['Simulator only; camera and microphone hardware not verified.','No signed device build or App Store archive.']}
    def record():
        (output/'run.json').write_text(json.dumps(report,indent=2)+'\n')
    def run(args, name):
        logfile=output/(name+'.txt')
        entry={'argv':args,'log':logfile.name,'status':'RUNNING'}
        report['commands'].append(entry); record()
        print('Running: '+' '.join(args),flush=True)
        with logfile.open('w',encoding='utf-8') as log:
            result=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,text=True)
        entry.update(exit_code=result.returncode,status='PASS' if result.returncode==0 else 'FAIL'); record()
        if result.returncode:
            print(logfile.read_text(errors='replace')[-12000:])
            raise RuntimeError(name+' failed; see saved log.')
        return logfile.read_text(errors='replace')
    try:
        version=run(['xcodebuild','-version'],'xcode-version')
        match=re.search(r'Xcode (\d+)',version)
        if not match or int(match[1])<26: raise RuntimeError('Xcode 26+ required; configure the runner image before retrying.')
        run(['xcrun','--sdk','iphonesimulator','--show-sdk-version'],'simulator-sdk')
        run([sys.executable,'scripts/generate_xcode.py'],'project-generation')
        run([sys.executable,'scripts/check_project.py'],'project-integrity')
        run([sys.executable,'-m','unittest','backend.test_calculator','-v'],'backend-calculator-tests')
        run(['xcodebuild','-list','-project','ios/TurfOrnamentalPro.xcodeproj'],'xcode-project')
        devices=json.loads(run(['xcrun','simctl','list','devices','available','--json'],'simulators'))
        device=select_iphone(devices); report['simulator_udid']=device; record()
        result_bundle=output/'PhaseA.xcresult'
        if result_bundle.exists(): raise RuntimeError('Result bundle already exists. Preserve it and use a fresh workspace; no evidence is overwritten.')
        run(['xcodebuild','test','-project','ios/TurfOrnamentalPro.xcodeproj','-scheme','TurfOrnamentalPro',
             '-destination','platform=iOS Simulator,id='+device,'-destination-timeout','120',
             '-parallel-testing-enabled','NO','-maximum-concurrent-test-simulator-destinations','1',
             '-derivedDataPath',str(ROOT/'build/DerivedData'),'-resultBundlePath',str(result_bundle),
             'CODE_SIGNING_ALLOWED=NO','CODE_SIGNING_REQUIRED=NO'],'xcode-tests')
        report['status']='PASS'
    except Exception as error:
        report['status']='FAIL'; report['error']=str(error)
        raise
    finally:
        report['finished_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat(); record()

if __name__=='__main__': main()
