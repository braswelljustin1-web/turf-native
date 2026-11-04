"""Emit allowlisted current source for the connected GitHub tree API; no credentials."""
import json
from package_source import ROOT, selected

entries=[{'path':p.relative_to(ROOT).as_posix(),'mode':'100644','type':'blob','content':p.read_text(encoding='utf-8-sig')}
         for p in sorted(ROOT.rglob('*')) if p.is_file() and selected(p)]
entries.append({'path':'README.md','mode':'100644','type':'blob','content':'# turf-native\nNative iPhone turf and ornamental field tools — source development and unsigned build tests.\n\nSource prepared; native build and device tests remain unverified. See docs/BUILD_STATE.md and docs/CLOUD_BUILD.md. Cloud builds are manual and disabled until explicitly configured.\n'})
print(json.dumps(entries,ensure_ascii=True))
