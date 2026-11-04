"""Loopback-only development API. NOT a public production server.

High-entropy developer tokens come from a private environment mapping.
Production launch is deliberately refused until managed auth/TLS are implemented.
"""
import hashlib, hmac, json, os, re, sqlite3, threading, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from .calculator import calculate, CalculationError

class APIError(Exception):
    def __init__(self, status, code): self.status, self.code = status, code

def identifier(value):
    if not isinstance(value,str) or not re.fullmatch(r'[A-Za-z0-9-]{1,64}',value):
        raise APIError(422,'invalid_identifier')
    return value

class Service:
    def __init__(self, path, tokens):
        if not tokens or any(not isinstance(k,str) or len(k)<32 for k in tokens):
            raise ValueError('At least one high-entropy developer token of 32+ characters is required.')
        if len(set(tokens.values()))!=len(tokens): raise ValueError('One token per account in this development adapter.')
        self.tokens={hashlib.sha256(k.encode()).digest():identifier(v) for k,v in tokens.items()}
        self.db=sqlite3.connect(path,check_same_thread=False)
        self.db.executescript((Path(__file__).parent/'migrations/001_initial.sql').read_text())
        self.lock=threading.RLock(); self.limits={}
    def authenticate(self, header):
        if not header or not header.startswith('Bearer '): raise APIError(401,'unauthorized')
        digest=hashlib.sha256(header[7:].encode()).digest()
        for known, owner in self.tokens.items():
            if hmac.compare_digest(digest,known): return owner
        raise APIError(401,'unauthorized')
    def dispatch(self, method, path, header, body):
        owner=self.authenticate(header)
        with self.lock:
            now=time.monotonic(); times=[t for t in self.limits.get(owner,[]) if now-t<60]
            if len(times)>=120: raise APIError(429,'rate_limit')
            self.limits[owner]=times+[now]
            if method=='GET' and path=='/v1/capabilities':
                return {'mode':'LOCAL_DEVELOPMENT','ai':False,'weather':False,'chemical_verification':False,'billing':False,'publication':False}
            if path=='/v1/properties' and method=='GET':
                rows=self.db.execute('SELECT data FROM properties WHERE owner=? ORDER BY id LIMIT 101',(owner,)).fetchall()
                return {'items':[json.loads(r[0]) for r in rows[:100]],'has_more':len(rows)>100}
            if method=='PUT' and path.startswith('/v1/properties/'):
                pid=identifier(path.rsplit('/',1)[-1])
                if not isinstance(body,dict) or set(body)!={'name','country','locality','time_zone','version'}: raise APIError(422,'invalid_property')
                if any(not isinstance(body[k],str) or not body[k].strip() or len(body[k])>200 for k in ('name','country','locality','time_zone')): raise APIError(422,'invalid_property')
                from zoneinfo import ZoneInfo, ZoneInfoNotFoundError
                try: ZoneInfo(body['time_zone'])
                except (ZoneInfoNotFoundError,ValueError): raise APIError(422,'invalid_time_zone')
                if not re.fullmatch('[A-Z]{2}',body['country']): raise APIError(422,'invalid_country')
                old=self.db.execute('SELECT version FROM properties WHERE owner=? AND id=?',(owner,pid)).fetchone()
                expected=old[0] if old else 0
                if type(body['version']) is not int or body['version']!=expected: raise APIError(409,'version_conflict')
                saved={**body,'id':pid,'version':expected+1}
                with self.db:
                    self.db.execute('INSERT INTO properties VALUES(?,?,?,?) ON CONFLICT(owner,id) DO UPDATE SET version=excluded.version,data=excluded.data',(owner,pid,expected+1,json.dumps(saved)))
                return saved
            if method=='GET' and path.startswith('/v1/calculations/'):
                cid=identifier(path.rsplit('/',1)[-1])
                row=self.db.execute('SELECT snapshot FROM calculations WHERE owner=? AND id=?',(owner,cid)).fetchone()
                if not row: raise APIError(404,'not_found')
                return json.loads(row[0])
            if method=='POST' and path=='/v1/calculations':
                if not isinstance(body,dict) or set(body)!={'id','property_id','kind','inputs'}: raise APIError(422,'invalid_calculation')
                cid=identifier(body['id']); pid=identifier(body['property_id'])
                prop=self.db.execute('SELECT data FROM properties WHERE owner=? AND id=?',(owner,pid)).fetchone()
                if not prop: raise APIError(404,'not_found')
                fingerprint=hashlib.sha256(json.dumps(body,sort_keys=True,separators=(',',':')).encode()).hexdigest()
                old=self.db.execute('SELECT request_hash,snapshot FROM calculations WHERE owner=? AND id=?',(owner,cid)).fetchone()
                if old:
                    if old[0]!=fingerprint: raise APIError(409,'idempotency_conflict')
                    return json.loads(old[1])
                try: result=calculate(body['kind'],body['inputs'])
                except (CalculationError,TypeError,KeyError): raise APIError(422,'invalid_calculation')
                result.update(id=cid,property_snapshot=json.loads(prop[0]))
                with self.db: self.db.execute('INSERT INTO calculations VALUES(?,?,?,?,?)',(owner,cid,pid,fingerprint,json.dumps(result)))
                return result
            raise APIError(404,'not_found')

def make_server(service, port=0):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self,*args): pass  # Never log request content, tokens, or location.
        def handle_request(self):
            self.connection.settimeout(5)
            try:
                if self.headers.get('Transfer-Encoding'): raise APIError(400,'unsupported_transfer_encoding')
                raw_length=self.headers.get('Content-Length','0')
                if not raw_length.isdigit(): raise APIError(400,'invalid_length')
                length=int(raw_length)
                if length>65536: raise APIError(413,'body_too_large')
                body=None
                if length:
                    if self.headers.get_content_type()!='application/json': raise APIError(415,'json_required')
                    try: body=json.loads(self.rfile.read(length))
                    except (ValueError,UnicodeError): raise APIError(400,'invalid_json')
                data=service.dispatch(self.command,self.path,self.headers.get('Authorization'),body); status=200
            except APIError as error: status=error.status; data={'error':{'code':error.code}}
            except Exception: status=500; data={'error':{'code':'internal_error'}}
            output=json.dumps(data).encode()
            self.send_response(status); self.send_header('Content-Type','application/json')
            self.send_header('Content-Length',str(len(output))); self.send_header('Cache-Control','no-store')
            self.send_header('X-Content-Type-Options','nosniff'); self.end_headers(); self.wfile.write(output)
        do_GET=handle_request; do_POST=handle_request; do_PUT=handle_request
    server=ThreadingHTTPServer(('127.0.0.1',port),Handler)
    server.daemon_threads=True
    return server

if __name__=='__main__':
    if os.environ.get('APP_ENV')!='development': raise SystemExit('Only APP_ENV=development is supported. Public deployment is disabled.')
    tokens=json.loads(os.environ.get('DEV_AUTH_TOKENS_JSON','{}'))
    path=Path(os.environ.get('DATABASE_PATH','private-data/development.sqlite'))
    path.parent.mkdir(parents=True,exist_ok=True)
    service=Service(path,tokens)
    print('Local development API listening on 127.0.0.1:8765. No AI, publication, or billing enabled.')
    make_server(service,8765).serve_forever()
