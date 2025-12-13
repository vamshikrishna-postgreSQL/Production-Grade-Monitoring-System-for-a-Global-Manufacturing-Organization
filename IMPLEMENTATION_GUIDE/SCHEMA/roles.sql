CREATE ROLE readonly;
CREATE ROLE engineer;
CREATE ROLE auditor;
CREATE ROLE admin SUPERUSER;
GRANT CONNECT ON DATABASE monitoring TO readonly, engineer, auditor;
