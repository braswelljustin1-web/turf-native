"""Create a bounded source-only transfer ZIP; never uploads or starts CI."""
from pathlib import Path
import hashlib
import json
import re
import zipfile

ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'build/transfer'
ROOT_FILES={'.gitignore','BUILD_STATE.md','REQUIREMENTS.csv'}
ALLOWED_ROOTS={'.github','backend','docs','ios','scripts'}
EXTENSIONS={'.py','.sql','.md','.csv','.json','.swift','.plist','.xcprivacy','.pbxproj','.xcscheme','.yml','.yaml'}
EXCLUDED={'__pycache__','.git','.build','build','DerivedData','xcuserdata','private-data','captures','node_modules'}
def selected(path):
    relative=path.relative_to(ROOT)
    if any(part in EXCLUDED for part in relative.parts): return False
    if path.is_symlink(): return False
    return relative.as_posix() in ROOT_FILES or (relative.parts[0] in ALLOWED_ROOTS and path.suffix in EXTENSIONS and not path.name.startswith('.env'))

def main():
    files=sorted(p for p in ROOT.rglob('*') if p.is_file() and selected(p))
    patterns=[rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',rb'gh[pousr]_[A-Za-z0-9]{30,}',rb'github_pat_[A-Za-z0-9_]{40,}',rb'AKIA[A-Z0-9]{16}']
    manifest=[]
    for path in files:
        data=path.read_bytes()
        if any(re.search(pattern,data) for pattern in patterns):
            raise SystemExit('Potential credential detected; packaging stopped. Inspect '+str(path.relative_to(ROOT)))
        manifest.append({'path':path.relative_to(ROOT).as_posix(),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
    workflow=ROOT/'.github/workflows/ios-build.yml'
    assert workflow in files
    assert 'CLOUD_BUILD_ENABLED' in workflow.read_text() and 'workflow_dispatch:' in workflow.read_text()
    DEST.mkdir(parents=True,exist_ok=True)
    archive=DEST/'turf-native-source.zip'
    with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
        for entry in manifest: z.write(ROOT/entry['path'],arcname='turf-native/'+entry['path'])
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        assert len(z.namelist())==len(files)
        for entry in manifest:
            assert hashlib.sha256(z.read('turf-native/'+entry['path'])).hexdigest()==entry['sha256']
    report={'file_count':len(files),'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),
            'archive_bytes':archive.stat().st_size,'entries':manifest,
            'checks':['allowlisted source files only','excluded runtime/private/build files','basic known credential-pattern scan','ZIP CRC and per-file SHA-256 verification'],
            'limitations':['Pattern scan is not a comprehensive security audit.','No upload, repository or cloud run created.','Source has not been compiled by Xcode.']}
    (DEST/'source-manifest.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='entries'},indent=2))

if __name__=='__main__': main()
