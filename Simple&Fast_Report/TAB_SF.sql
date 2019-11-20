create table TAB_SF
(
  s300fec         DATE,
  s300tip         VARCHAR2(5),
  s300age         VARCHAR2(20),
  s300rzs         VARCHAR2(200),
  s300usr         VARCHAR2(100),
  s300mes         VARCHAR2(10),
  s300ano         VARCHAR2(10),
  s300out_tot     NUMBER(12),
  s300out_int     NUMBER(12),
  s300inb_tot     NUMBER(12),
  s300inb_int     NUMBER(12),
  s300tot         NUMBER(12),
  s300out_tot_csc NUMBER(12),
  s300out_int_csc NUMBER(12),
  s300inb_tot_csc NUMBER(12),
  s300inb_int_csc NUMBER(12),
  s300out_tot_ts  NUMBER(12),
  s300out_int_ts  NUMBER(12),
  s300inb_tot_ts  NUMBER(12),
  s300inb_int_ts  NUMBER(12)
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
