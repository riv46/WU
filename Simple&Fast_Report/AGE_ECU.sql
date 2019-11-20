-- Create table
create table AGE_ECU
(
  age_id    VARCHAR2(20),
  age_rzs   VARCHAR2(200),
  age_canal VARCHAR2(10)
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
