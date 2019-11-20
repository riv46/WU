-- Create table
create table BOL_300
(
  b300tip  VARCHAR2(50),
  b300pai  VARCHAR2(5),
  b300fec  VARCHAR2(10),
  b300can  VARCHAR2(10),
  b300rzs  VARCHAR2(200),
  b300ser  VARCHAR2(10),
  b300ano  VARCHAR2(10),
  b300mes  VARCHAR2(10),
  b300can2 VARCHAR2(10),
  b300cant NUMBER(12)
)
tablespace SERVIBAND
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
