-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


DROP TABLE IF EXISTS testers CASCADE;
CREATE TABLE testers (
	id		      UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
	name	      VARCHAR NOT NULL,
	location	  VARCHAR NOT NULL,
	vps_provider  VARCHAR NOT NULL,
	config		  JSONB
);
-- CREATE INDEX ON testers (id);

DROP TABLE IF EXISTS servers CASCADE;
CREATE TABLE servers (
	id		      UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
	ip_addr       inet NOT NULL UNIQUE, -- IP address
	name	      VARCHAR,
	location	  VARCHAR,
	config		  JSONB
);
--CREATE INDEX ON servers (ip_addr);

DROP TABLE IF EXISTS ping_results CASCADE;
CREATE TABLE ping_results (
	id		          UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
	tester_id		  UUID NOT NULL REFERENCES testers (id), -- ON DELETE RESTRICT ON UPDATE RESTRICT,
	server_requested  VARCHAR NOT NULL, -- hostname or IP address
	server_contacted  inet NOT NULL REFERENCES servers (ip_addr), -- IP address
	ping_timestamp	  timestamp NOT NULL,
	ping_count	      integer NOT NULL,
	ping_nack	      integer NOT NULL,
	ping_time	      real NOT NULL, -- average of ping_count - ping_nack
	raw	              JSONB
);
CREATE INDEX ON ping_results (server_contacted);
CREATE INDEX ON ping_results (ping_timestamp);
CREATE INDEX ON ping_results (ping_nack);
CREATE INDEX ON ping_results (ping_time);


CREATE ROLE dlg WITH LOGIN PASSWORD 'hR+WT7CG';
GRANT ALL ON ALL TABLES IN SCHEMA PUBLIC TO dlg;
VACUUM FULL;
