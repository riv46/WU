-- Create table
create table BOL_AGE
(
  s300age VARCHAR2(20),
  s300tip VARCHAR2(10),
  s300rzs VARCHAR2(200)
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
