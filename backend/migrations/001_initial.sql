PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS properties (
 owner TEXT NOT NULL, id TEXT NOT NULL, version INTEGER NOT NULL,
 data TEXT NOT NULL, PRIMARY KEY(owner,id)
);
CREATE TABLE IF NOT EXISTS calculations (
 owner TEXT NOT NULL, id TEXT NOT NULL, property_id TEXT NOT NULL,
 request_hash TEXT NOT NULL, snapshot TEXT NOT NULL,
 PRIMARY KEY(owner,id),
 FOREIGN KEY(owner,property_id) REFERENCES properties(owner,id)
);
PRAGMA user_version = 1;
