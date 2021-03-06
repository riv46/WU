create or replace package PCK_BOL_SF is

  -- Author  : 26227341
  -- Created : 20/04/2016 12:45:32 p.m.
  -- Purpose : PCK_BOL_S&F
  

TYPE V_CURSOR IS REF CURSOR;
 Procedure USP_CARGAR_TAB_SF(
  p_mes varchar2,
  p_ano varchar2,
  p_usr varchar2
  );
 Procedure USP_TABLA_SF(
  p_out1 out V_CURSOR,
  p_out2 out V_CURSOR
  );
 Procedure USP_BOL_MT(
   P_OUT1 OUT V_CURSOR
   );
  PROCEDURE USP_BOL_BP(
  P_OUT1 OUT V_CURSOR
  );
  PROCEDURE USP_BOL_AGE(
  P_OUT1 OUT V_CURSOR
  );
  PROCEDURE USP_BOLAGE_VS_BP(
    P_OUT1 OUT V_CURSOR
  );
  PROCEDURE USP_BOL_ECU(
  P_OUT1 OUT V_CURSOR
  );
  PROCEDURE USP_BOL_300(
  P_OUT1 OUT V_CURSOR
  );
end PCK_BOL_SF;
/
create or replace package body PCK_BOL_SF is

procedure USP_CARGAR_TAB_SF(
p_mes varchar2,
p_ano varchar2,
p_usr varchar2
)
as 
v_fec date := to_char(sysdate(),'DD-MON-YYYY');
v_con number(12);
begin

delete from TAB_SF
       where s300mes = p_mes
         and s300ano = p_ano;
commit;


for i in(SELECT s300age "COD_AGE" ,
               UPPER(S300RZS) "NOMBRE_AGENCIA",
               OUT_TOT.OUT_INTERNACIONALES,OUT_TOT.OUT_INTRAS,
               INB_TOT.INB_INTERNACIONALES,INB_TOT.INB_INTRAS
               from scfl300_bp,
                (SELECT S300AGE "COD",SUM(DECODE(trim(S501PAD),'134',0,1)) "OUT_INTERNACIONALES",
                        SUM(DECODE(trim(S501PAD),'134',1,0)) "OUT_INTRAS"
                            FROM scfl300_bp,SCFL501
                            WHERE S501AGE = S300AGE
                              AND to_char(S501FEE,'MMYYYY') = p_mes||p_ano
                              GROUP BY S300AGE) OUT_TOT,
                (SELECT  S300AGE "COD",
                        SUM(DECODE(trim(S500PAR),'134',0,1)) INB_INTERNACIONALES,
                        SUM(DECODE(trim(S500PAR),'134',1,0)) "INB_INTRAS"
                            FROM scfl300_bp,SCFL500
                                  WHERE S500AGE = S300AGE
                                    AND to_char(S500FRE,'MMYYYY') = p_mes||p_ano
                                    GROUP BY S300AGE) INB_TOT
                where  s300age = OUT_TOT.cod
                  and  s300age = INB_TOT.cod) loop
                  
       insert into TAB_SF
         (s300fec, s300tip, s300age, s300rzs,
          s300usr, s300mes,s300ano,
          S300OUT_TOT,S300OUT_INT,
          S300INB_TOT,S300INB_INT,S300TOT)
       values
         (v_fec, '01', i.COD_AGE,i.nombre_agencia,
          p_usr,p_mes,p_ano,
          i.out_internacionales,i.out_intras,
          i.inb_internacionales,i.inb_intras,
          i.out_internacionales+i.out_intras+i.inb_internacionales+i.inb_intras);
                  
end loop;

commit;  


for e in (select S300AGE ,
                SUM(DECODE(trim(G501PAIDES),'PER�',0,1)) "CSC_OUT_INTERNACIONALES",
                SUM(DECODE(trim(G501PAIDES),'PER�',1,0)) "CSC_OUT_INTRAS"
                     from scpi501,scfl300
                       where g501stt = 'C'
                         and g501ageven = s300age
                         and g501usr NOT  in ('CSCUVJ')
                         and g501ageven not in ('038')
                         and to_char(g501uda,'MMYYYY')  = p_mes||p_ano
                         group by S300AGE) loop
                         
    select count(*) into v_con from TAB_SF a
           where trim(a.s300mes) = trim(p_mes)
             and trim(a.s300ano) = trim(p_ano)
             and trim(a.s300age) = trim(e.s300age)
             and trim(a.s300tip) = '01';
         
      if v_con >= 1 then
        
         update TAB_SF a
                set a.S300OUT_TOT_CSC  = e.csc_out_internacionales,
                    a.S300OUT_INT_CSC = e.csc_out_intras
                    where trim(a.s300mes) = trim(p_mes)
                      and trim(a.s300ano) = trim(p_ano)
                      and trim(a.s300age) = trim(e.s300age)
                      and trim(a.s300tip) = '01';
                      commit;         

      end if;                  
                               
end loop;


for o in (select s300age,
             SUM(DECODE(trim(G500PAIENV),'PER�',0,1)) "CSC_INB_INTERNACIONALES",
             SUM(DECODE(trim(G500PAIENV),'PER�',1,0)) "CSC_INB_INTRAS"
               from scpi500,scfl300
                     where g500stt = 'C'
                       and g500ageven = s300age
                       and g500usr not in ('CSCUVJ')
                       and g500ageven not in ('038')
                       and to_char(g500uda,'MMYYYY')  = p_mes||p_ano
                       group by s300age) loop
                       
         select count(*) into v_con from TAB_SF a
           where trim(a.s300mes) = trim(p_mes)
             and trim(a.s300ano) = trim(p_ano)
             and trim(a.s300age) = trim(o.s300age)
             and trim(a.s300tip) = '01';
         
      if v_con >= 1 then
        
         update TAB_SF a
                set a.S300INB_TOT_CSC  = o.csc_inb_internacionales ,
                    a.S300INB_INT_CSC = o.csc_inb_intras
                    where trim(a.s300mes) = trim(p_mes)
                      and trim(a.s300ano) = trim(p_ano)
                      and trim(a.s300age) = trim(o.s300age)
                      and trim(a.s300tip) = '01';
                      commit;         

      end if;          
                       
                       
end loop;

for a in (select S300AGE ,
                SUM(DECODE(trim(G501PAIDES),'PER�',0,1)) "TS_OUT_INTERNACIONALES",
                SUM(DECODE(trim(G501PAIDES),'PER�',1,0)) "TS_OUT_INTRAS"
                     from scpi501,scfl300
                       where g501stt = 'C'
                         and g501ageven = s300age
                         and g501usr  in ('CSCUVJ')
                         and g501ageven  NOT in ('038')
                         and to_char(g501uda,'MMYYYY')  = p_mes||p_ano
                         group by S300AGE) loop
                         
    select count(*) into v_con from TAB_SF j
           where trim(j.s300mes) = trim(p_mes)
             and trim(j.s300ano) = trim(p_ano)
             and trim(j.s300age) = trim(a.s300age)
             and trim(j.s300tip) = '01';
         
      if v_con >= 1 then
        
         update TAB_SF j
                set j.S300OUT_TOT_TS  = a.ts_out_internacionales,
                    j.S300OUT_INT_TS = a.ts_out_intras
                    where trim(j.s300mes) = trim(p_mes)
                      and trim(j.s300ano) = trim(p_ano)
                      and trim(j.s300age) = trim(a.s300age)
                      and trim(j.s300tip) = '01';
                      commit;         

      end if;                  
                               
end loop;



for u in (select s300age,
             SUM(DECODE(trim(G500PAIENV),'PER�',0,1)) "TS_INB_INTERNACIONALES",
             SUM(DECODE(trim(G500PAIENV),'PER�',1,0)) "TS_INB_INTRAS"
               from scpi500,scfl300
                     where g500stt = 'C'
                       and g500ageven = s300age
                       and g500usr in ('CSCUVJ')
                       and g500ageven not in ('038')
                       and to_char(g500uda,'MMYYYY')  = p_mes||p_ano
                       group by s300age) loop
                       
         select count(*) into v_con from TAB_SF a
           where trim(a.s300mes) = trim(p_mes)
             and trim(a.s300ano) = trim(p_ano)
             and trim(a.s300age) = trim(u.s300age)
             and trim(a.s300tip) = '01';
         
      if v_con >= 1 then
        
         update TAB_SF a
                set a.S300INB_TOT_TS  = u.TS_INB_INTERNACIONALES ,
                    a.S300INB_INT_TS = u.TS_INB_INTRAS
                    where trim(a.s300mes) = trim(p_mes)
                      and trim(a.s300ano) = trim(p_ano)
                      and trim(a.s300age) = trim(u.s300age)
                      and trim(a.s300tip) = '01';
                      commit;         

      end if;          
                       
                       
end loop;



for b in (SELECT  UPPER(S300RZS) nombre_agencia ,S300AGE COD_AGE,
              SUM(DECODE(trim(S501PAD),'134',0,1)) total_outbound_agentes,
              SUM(DECODE(trim(S501PAD),'134',1,0)) total_outbound_intras_agentes
                  FROM SCFL300_AGE_BP,SCFL501
                    WHERE S501AGE = S300AGE
                      AND TO_CHAR(S501FEE ,'MMYYYY') = p_mes||p_ano
                      GROUP BY UPPER(S300RZS),S300AGE) loop
                      
       insert into TAB_SF
         (s300fec, s300tip, s300age, s300rzs,
          s300usr, s300mes,s300ano,
          S300OUT_TOT,S300OUT_INT,
          S300OUT_TOT_CSC,S300OUT_INT_CSC)
       values
         (v_fec, '02', b.COD_AGE,b.nombre_agencia,
          p_usr,p_mes,p_ano,
          b.total_outbound_agentes,b.total_outbound_intras_agentes,
          b.total_outbound_agentes,b.total_outbound_intras_agentes);
                      
                      
end loop;

commit;

for c in (SELECT  UPPER(S300RZS) nombre_agencia ,s300age COD_AGE,
              SUM(DECODE(trim(s500par),'134',0,1)) total_Inbound,
              SUM(DECODE(trim(s500par),'134',1,0)) total_Inbound_intras
                FROM SCFL300_AGE_BP,SCFL500
                  WHERE S500AGE = S300AGE
                    AND TO_CHAR(S500FRE ,'MMYYYY') = p_mes||p_ano
                    GROUP BY UPPER(S300RZS),s300age) loop

 select count(*) into v_con from TAB_SF a
           where trim(a.s300mes) = trim(p_mes)
             and trim(a.s300ano) = trim(p_ano)
             and trim(a.s300age) = trim(c.COD_AGE)
             and trim(a.s300tip) = '02';
         
      if v_con >= 1 then
        
         update TAB_SF a
                set a.S300INB_TOT  = c.total_Inbound ,
                    a.S300INB_INT = c.total_Inbound_intras
                    where trim(a.s300mes) = trim(p_mes)
                      and trim(a.s300ano) = trim(p_ano)
                      and trim(a.s300age) = trim(c.COD_AGE)
                      and trim(a.s300tip) = '02';
                      
                      
        else      
           insert into TAB_SF
             (s300fec, s300tip, s300age, s300rzs,
              s300usr, s300mes,s300ano,
              S300INB_TOT,S300INB_INT)
           values
             (v_fec, '02', c.COD_AGE,c.nombre_agencia,
              p_usr,p_mes,p_ano,
              c.total_Inbound,c.total_Inbound_intras);
       end if; 
       
        commit;                      
                             
end loop;


for d in (select * from scpi300 where s300mes = p_mes and s300ano = p_ano and s300tip = '02') loop
  
    update TAB_SF
           set S300TOT = d.S300OUT_TOT + d.S300OUT_INT + d.S300INB_TOT + d.S300INB_INT
      WHERE S300MES = d.s300mes
        and s300ano = d.s300ano
        and s300tip = d.s300tip
        and s300age = d.s300age;
           

end loop;

commit;
        
END USP_CARGAR_TAB_SF;

Procedure USP_TABLA_SF(
  p_out1 out V_CURSOR,
  p_out2 out V_CURSOR
  )
  as 
  v_ano_act char(4) := to_char(sysdate,'YYYY');
  v_mes_act char(2) := to_char(sysdate,'MM');
  
  v_ano_ant char(4) := to_char(sysdate - 2,'YYYY');
  v_mes_ant char(2) := to_char(sysdate - 2,'MM');
  begin 
  
     
 USP_CARGAR_TAB_SF(v_mes_act,v_ano_act,'SYSBME');
  USP_CARGAR_TAB_SF(v_mes_ant,v_ano_ant,'SYSBME');
  
     open p_out1 for
          select upper(trim(to_char(to_date(to_char(s300MES),'mm'),'Month','NLS_DATE_LANGUAGE = SPANISH'))) || '-' || s300ano "Nombre_Meses",
                 SUM(DECODE(S300TIP,'01',1,0)) "Age_Propia" ,SUM(DECODE(S300TIP,'02',1,0)) "Agente" 
                       from TAB_SF
                       GROUP BY s300MES,s300ano
                       ORDER BY S300MES,S300ANO;
                       
     open p_out2 for 
          select * from TAB_SF
                 order by s300mes,s300ano,s300tip,s300rzs;  
  
END USP_TABLA_SF;

PROCEDURE USP_BOL_MT(
  P_OUT1 OUT V_CURSOR
  )AS 
  BEGIN
  
  -------------------------------------------------------------------------------------------------------------------------
  ------------------------------------FRONT DESK---------------------------------------------------------------------------          
  -------------------------------------------------------------------------------------------------------------------------
  Delete BOL_300;
  commit;
  ----OUTBOUND
  

  
Insert into BOL_300(B300TIP, B300PAI, B300FEC, B300CAN, B300RZS, B300SER, B300ANO, B300MES, B300CAN2, B300CANT) 

  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent_Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
          tb.s300MES || '-' ||tb.s300ano "DATE",
         'Front Desk'Channel ,
          initcap(lower(trim(tb.s300rzs))) Agent, 
         'OB' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'Front Desk' Channel,
          tb.s300out_tot- DECODE(tb.s300out_tot_csc,'',0,tb.s300out_tot_csc) - Decode(tb.s300out_tot_ts,'',0, tb.s300out_tot_ts) Amount        
  From TAB_SF tb
  Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
  And tb.s300tip<>'02'
   
  ----OUTBOUND_DMT 
  UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",
         'Front Desk'Channel, 
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'OB_DMT' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'Front Desk' Channel,
          tb.s300out_int - DECODE(tb.s300out_int_csc,'',0,tb.s300out_int_csc) - Decode(tb.s300out_int_ts,'',0, tb.s300out_int_ts) Amount
  From TAB_SF tb
   Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
  And tb.s300tip<>'02'
  
  ----INBOUND
UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'Front Desk'Channel, 
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'IB' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'Front Desk' Channel,
         tb.s300inb_tot - DECODE(tb.s300inb_tot_csc,'',0,tb.s300inb_tot_csc) - Decode(tb.s300inb_tot_ts,'',0, tb.s300inb_tot_ts) Amount
  From TAB_SF tb
  Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
  
  ----INBOUND_DMT 
UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'Front Desk'Channel,
         initcap(lower(tb.s300rzs)) Agent, 
         'IB_DMT' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'Front Desk' Channel,
         tb.s300inb_int - DECODE(tb.s300inb_int_csc,'',0,tb.s300inb_int_csc) - Decode(tb.s300inb_int_ts,'',0, tb.s300inb_int_ts) Amount
  From TAB_SF tb
   Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
   -------------------------------------------------------------------------------------------------------------------------
   -------------------------CSC---------------------------------------------------------------------------------------------            
   -------------------------------------------------------------------------------------------------------------------------
  
  
  ----OUTBOUND CSC 

  UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'S&F'Channel,
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'OB' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'CSC' Channel,
         tb.s300out_tot_csc Amount
  From TAB_SF tb
   Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
  ----OUTBOUND_DMT CSC 
  
  UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'S&F'Channel,
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'OB_DMT' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'CSC' Channel,
         tb.s300out_int_csc Amount
       From TAB_SF tb  
   Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
   ----INBOUND CSC 
  
  UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'S&F'Channel, 
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'IB' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'CSC' Channel,
         tb.s300INB_tot_csc Amount
  From TAB_SF tb
   Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
     ----INBOUND_DMT CSC 
  
  UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'S&F'Channel,
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'IB_DMT' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'CSC' Channel,
         tb.s300INB_int_csc Amount
  From TAB_SF tb
   Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
   -------------------------------------------------------------------------------------------------------------------------
   ---------------------------TOUCH-----------------------------------------------------------------------------------------        
   -------------------------------------------------------------------------------------------------------------------------
  
  ----OUTBOUND TOUCH
  
  UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'S&F'Channel,
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'OB' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'Touch' Channel,
         tb.s300OUT_TOT_TS Amount
  From TAB_SF tb
  Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
   ----OUTBOUND_DMT TOUCH
   
  UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'S&F'Channel,
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'OB_DMT' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'Touch' Channel,
         tb.s300OUT_INT_TS Amount
  From TAB_SF tb
  Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
     ----INBOUND TOUCH
   
  UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'S&F'Channel,
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'IB' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'Touch' Channel,
         tb.s300INB_TOT_TS Amount
  From TAB_SF tb
  Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027'
  
    ----INBOUND_DMT TOUCH
   
  UNION 
  Select DECODE(tb.S300TIP, '01', 'Own Agency',
                       '02', 'Independent Channel' ) "Agent Type",
         DECODE(tb.S300TIP, '01','PE',
                        '02', 'PE') "Country",
         tb.s300MES || '-' ||tb.s300ano "DATE",'S&F'Channel,
         initcap(lower(trim(tb.s300rzs))) Agent, 
         'IB_DMT' Service,
         tb.s300ano Year,
         tb.s300mes Month,
         'Touch' Channel,
         tb.s300INB_INT_TS Amount
  From TAB_SF tb
   Where trim(tb.s300age)<>'063'
  And trim(tb.s300age)<>'027';
  commit;
  
   OPEN P_OUT1 FOR
   Select*
   From BOL_300;
   COMMIT;
   
END USP_BOL_MT;  

-------------------------------------------------------------------------------------------------------------

PROCEDURE USP_BOL_BP(
  P_OUT1 OUT V_CURSOR
  )AS 
  BEGIN
    
  Delete BOL_BP
COMMIT;
  

Insert into BOL_BP (B300AGE, B300TIP, B300PAI, B300FEC, B300CAN, B300RZS, B300SER, B300ANO, B300MES, B300CAN2, B300CANT) 
          
-------------Enero------------------------------------------------
SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'01-2014' "DATE",'BP' Channel, initcap(lower( trim(Comercial))) Comercial,
       'BP' SERVICE,'2014' Year,'01' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M01_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m01_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
      Union 
 ------------Febrero------------------------------------------------------ 
  SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'02-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial, 'BP' SERVICE,
       '2014' Year,'02' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M02_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m02_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
   Union   
  ------------Marzo------------------------------------------------------     
   SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'03-2014' "DATE",'BP' Channel, initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'03' Month,'BP' Channel, Sum(decode(S500Tip, 'B',  M03_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m03_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union   
  ------------Abril------------------------------------------------------   
  SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'04-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'04' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M04_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m04_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
      Union
  ------------Mayo------------------------------------------------------     
  SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'05-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'05' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M05_14, 0)) AS  Amount
        FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m05_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
  ------------Junio------------------------------------------------------     
  SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'06-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'06' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M06_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m06_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
  ------------Julio------------------------------------------------------     
  SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'07-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'07' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M07_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m07_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
      Union    
  ------------Agosto------------------------------------------------------     
  SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'08-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'08' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M08_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m08_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
  ------------Septiembre------------------------------------------------------ 
   SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'09-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'09' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M09_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m09_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
   Union    
  ------------Octubre------------------------------------------------------ 
  SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'10-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'10' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M10_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m10_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
  ------------Noviembre------------------------------------------------------ 
  SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'11-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'11' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M11_14, 0)) AS  Amount
       FROM
            ( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m11_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
  ------------Diciembre------------------------------------------------------   
  SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'12-2014' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2014' Year,'12' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M12_14, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m12_14
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union     
----------------------------------------------------------------
----------------------2015--------------------------------------
----------------------------------------------------------------
   
------------Enero------------------------------------------------------ 
   SELECT 
       trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'01-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
       '2015' Year,'01' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M01_15, 0)) AS  Amount
       FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                     u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m01_15
                     FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                     where S300Gne = G91Esp 
                     And G91STT='A' 
                     AND G91IDT='TIPGIR'
                     and b.s300age = s.s300age
                     and b.s300age = bp.s300age
                     And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
             ) 
      GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
  ------------Febrero------------------------------------------------------    
  SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'02-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'02' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M02_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m02_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
  ------------Marzo------------------------------------------------------  
  SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'03-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'03' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M03_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m03_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
 Union    
  ------------Abril------------------------------------------------------ 
  SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'04-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'04' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M04_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m04_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
   Union    
  ------------Mayo------------------------------------------------------ 
  SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'05-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'05' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M05_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m05_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
  ------------Junio------------------------------------------------------ 
   SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'06-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'06' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M06_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m06_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
 ------------Julio------------------------------------------------------  
   SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'07-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'07' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M07_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m07_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
  Union    
 ------------Agosto------------------------------------------------------ 
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'08-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'08' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M08_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m08_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
     Union    
 ------------Septiembre------------------------------------------------------  
   SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'09-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'09' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M09_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m09_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
    Union    
 ------------Octubre------------------------------------------------------  
   SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'10-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'10' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M10_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m10_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
     Union    
 ------------Noviembre------------------------------------------------------                       
      SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'11-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'11' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M11_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m11_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
    Union    
 ------------Diciembre------------------------------------------------------    
  SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'12-2015' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2015' Year,'12' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M12_15, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m12_15
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
    Union   
----------------------------------------------------------------
----------------------2016--------------------------------------
----------------------------------------------------------------
    
 ------------Enero------------------------------------------------------    
  SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'01-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'01' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M01_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m01_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
    Union    
 ------------Febrero------------------------------------------------------     
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'02-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'02' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M02_16, 0)) AS  Amount
         FROM(SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m02_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
   Union    
 ------------Marzo------------------------------------------------------ 
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'03-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'03' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M03_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m03_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
 Union    
 ------------Abril------------------------------------------------------   
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'04-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'04' Month,'BP' Channel,Sum(decode(S500Tip, 'B',  M04_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m04_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
    Union    
 
 ------------Mayo------------------------------------------------------   
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'05-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'05' Month,
         'BP' Channel,
         Sum(decode(S500Tip, 'B',  M05_16, 0)) AS  Amount
         FROM(SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m05_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
 Union    
 ------------Junio------------------------------------------------------
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'06-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'06' Month,
         'BP' Channel,
         Sum(decode(S500Tip, 'B',  M06_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m06_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
 Union    
 ------------Julio------------------------------------------------------  
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'07-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'07' Month,
         'BP' Channel,
         Sum(decode(S500Tip, 'B',  M07_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m07_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
 Union    
 ------------Agosto------------------------------------------------------
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'08-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'08' Month,
         'BP' Channel,
         Sum(decode(S500Tip, 'B',  M08_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m08_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
 Union    
 ------------Septiembre------------------------------------------------------  
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'09-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'09' Month,
         'BP' Channel,
         Sum(decode(S500Tip, 'B',  M09_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m09_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
 Union    
 ------------Octubre------------------------------------------------------   
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'10-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'10' Month,
         'BP' Channel,
         Sum(decode(S500Tip, 'B',  M10_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m10_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
 Union   
 
 ------------Noviembre------------------------------------------------------   
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'11-2016' "DATE",'BP' Channel,initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'11' Month,
         'BP' Channel,
         Sum(decode(S500Tip, 'B',  M11_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m11_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency')
 Union   
 ------------Diciembre------------------------------------------------------   
 SELECT 
         trim(S300AGE) S300AGE,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency') Tipo_Agencia,'PE' COUNTRY,'12-2016' "DATE",'BP' Channel, initcap(lower( trim(Comercial))) Comercial,'BP' SERVICE,
         '2016' Year,'12' Month,
         'BP' Channel,
         Sum(decode(S500Tip, 'B',  M12_16, 0)) AS  Amount
         FROM( SELECT trim(b.s300age) s300age,  trim(s.s300rzs) Comercial, trim(bp.S300tip) Tipo,G91Dsl giro_negocio, s.s300tca, 
                       u.s400dpt Dep, u.s400prv prv, u.s400dis dis, trim(tipo_pro) S500Tip ,m12_16
                       FROM detalle_age_bp b, gpfl091,scfl300 s, SCFL400 u,Bp_Scfl300 bp
                       where S300Gne = G91Esp 
                       And G91STT='A' 
                       AND G91IDT='TIPGIR'
                       and b.s300age = s.s300age
                       and b.s300age = bp.s300age
                       And s.S300dep||s.s300prv||s.s300dis=u.s400ubc(+)
               ) 
        GROUP BY trim(S300AGE), trim(Comercial), trim(Tipo) ,Decode(Tipo, '1', 'Independent Channel', '2','Independent Channel','3','Independent Channel','0','Own Agency');

 commit;   
                                                                                                                                                                                                                                    
OPEN P_OUT1 FOR
   Select*
   From BOL_BP;
   COMMIT;
   
   END USP_BOL_BP;
 ------------------------------------------------------------------------------------------------------------------------
 PROCEDURE USP_BOL_AGE(
   P_OUT1 OUT V_CURSOR
  )AS 
  BEGIN
    Delete BOL_AGE
 COMMIT;
 
 Insert into BOL_AGE (S300AGE, S300TIP, S300RZS)
 select distinct(s300age) s300age,s300tip,s300rzs
          From TAB_SF               
          UNION ALL
          select s300age,'02' "S300TIP", S300RZS 
                 from scfl300_age_bp
                      where s300age not in (select distinct(s300age) from TAB_SF)
          order by s300rzs,s300tip;
          
          commit;
 OPEN P_OUT1 FOR
   Select*
   From BOL_AGE;
   COMMIT;
 END USP_BOL_AGE;
----------------------------------------------------------------------------------------------------------------------------

 PROCEDURE USP_BOLAGE_VS_BP(
    P_OUT1 OUT V_CURSOR
  )AS 
  BEGIN
Insert into BOL_300 (B300TIP, B300PAI, B300FEC, B300CAN, B300RZS, B300SER, B300ANO, B300MES, B300CAN2, B300CANT) 
Select B.B300TIP, B.B300PAI, B.B300FEC, B.B300CAN, B.B300RZS, B.B300SER, B.B300ANO, B.B300MES, B.B300CAN2, B.B300CANT
    From BOL_bp B, BOL_AGE bol
    Where trim(b.b300age)= trim(bol.s300age)
    And B.B300AGE<>'027';
    COMMIT;
    
    COMMIT;
    
 OPEN P_OUT1 FOR
   Select*
   From BOL_300;
   COMMIT;
   
   END USP_BOLAGE_VS_BP;
   
   
---------------------------------------------------------------------------------------------------------------------------
  PROCEDURE USP_BOL_ECU(
    P_OUT1 OUT V_CURSOR
  )AS 
  BEGIN
        
  Insert into BOL_300 ( B300TIP, B300PAI, B300FEC, B300CAN, B300RZS, B300SER, B300ANO, B300MES, B300CAN2, B300CANT)  
  ----------Front Desk
  Select        
        'Independent Channel' "AGENT TYPE",  
        'ECU' Country, 
        b.b300MES || '-' ||b.b300ano "DATE",
        'Front Desk' Channel,
        initcap(lower(b300rzs)) Agent, 
        b.b300ser Service,
        b.b300ano Year,
        b.b300mes Month,
        'Front Desk' Channel,
        sum(b300cant) Amount
    From TRANS_ECU b, AGE_ECU ag
    Where trim(b300can2)='Front Desk'
    And trim(ag.age_id) = trim(b.b300id)
    Group by b.b300rzs, b.b300ser, b.b300mes,b.b300ano 
    
  UNION  
  ------------CSC

    Select         
        'Independent Channel' "AGENT TYPE",  
        'ECU' Country, 
       b300MES || '-' ||b300ano "DATE",
        'S&F' Channel,
        initcap(lower(b.b300rzs)) Agent, 
        b.b300ser Service,
        b.b300ano Year,
        b.b300mes Month,
        'CSC' Channel,
        sum(b.b300csc) Amount
    From TRANS_ECU b, AGE_ECU ag
    Where trim(b.b300can2)='S&F'
    And b300touch+b300csc=b300cant
    And trim(ag.age_id) = trim (b.b300id)
    Group by b.b300rzs, b.b300ser, b.b300mes,b.b300ano 

 UNION  
----------Touch Screan

 Select         
        'Independent Channel' "AGENT TYPE",  
        'ECU' Country, 
        b300MES||'-' ||b300ano "DATE",
        'S&F' Channel,
        initcap(lower(b.b300rzs)) Agent, 
        b.b300ser Service,
        b.b300ano Year,
        b.b300mes Month,
        'Touch' Channel,
        sum(b.b300touch) Amount
    From TRANS_ECU b, AGE_ECU ag
    Where trim(b.b300can2)='S&F'
    And b300touch <>0
    And trim(ag.age_id) = trim (b.b300id)
    Group by b.b300rzs, b.b300ser, b.b300mes,b.b300ano ;
 Commit;
 
   OPEN P_OUT1 FOR
   Select*
   From BOL_300;
   COMMIT;

End USP_BOL_ECU;

-------------------------------------------------------------------------------------------------------------------


PROCEDURE USP_BOL_300(
    P_OUT1 OUT V_CURSOR
  )AS 
  Begin
    
 USP_BOL_MT (P_OUT1);
 USP_BOL_BP(P_OUT1) ;
 USP_BOL_AGE(P_OUT1) ;
 USP_BOLAGE_VS_BP(P_OUT1) ;
 USP_BOL_ECU (p_out1);
 
    OPEN P_OUT1 FOR
    Select b300tip, b300pai, b300fec, b300can, trim(b300rzs), b300ser, b300ano, b300mes, b300can2, b300cant
     From BOL_300
     Where b300cant <>0
     And b300cant>0
     Order by b300rzs, b300ser, b300ano, b300mes;
               
    COMMIT;

End USP_BOL_300;
END PCK_BOL_SF;

   
/
