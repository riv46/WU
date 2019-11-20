-- Create table
create table TRANS_ECU
(
  b300id     VARCHAR2(20),
  b300magent VARCHAR2(200),
  b300rzs    VARCHAR2(200),
  b300ser    VARCHAR2(10),
  b300ano    VARCHAR2(10),
  b300mes    VARCHAR2(10),
  b300can2   VARCHAR2(10),
  b300cant   NUMBER(12),
  b300csc    NUMBER(15,2),
  b300touch  NUMBER(15,2)
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
