create or replace package PCK_APOLO_SIMPLE_FAST_TEST AS

TYPE V_CURSOR IS REF CURSOR;

procedure usp_Cargar_Simple_Fast_SCPI300(
p_mes varchar2,
p_ano varchar2,
p_usr varchar2
);

procedure Usp_ObtInfor_SimpleFast(
  p_out1 out V_CURSOR,
  p_out2 out V_CURSOR
  );
  
  
procedure usp_Grabar_Error(
p_err_tip varchar2,
p_err_mtcn varchar2,
p_err_usr varchar2,
p_err_age varchar2,
p_err_ser varchar2,
p_err_des varchar2,
p_err_fin varchar2
);
  

--------------------------------------------------------------------------------------------
--------------------------TRABAJANDO CAMBIO DE SIMPLE & FAST--------------------------------
--------------------------------------------------------------------------------------------

procedure Usp_ObtInfor_SimpleFast_test(
  p_out1 out V_CURSOR,
  p_out2 out V_CURSOR,
  p_out3 out V_CURSOR,
  p_out4 out V_CURSOR,
  p_out5 out V_CURSOR
  );
  
end PCK_APOLO_SIMPLE_FAST_TEST;
/
create or replace package body PCK_APOLO_SIMPLE_FAST_TEST is

procedure usp_Cargar_Simple_Fast_SCPI300(
p_mes varchar2,
p_ano varchar2,
p_usr varchar2
)
as 
v_fec date := to_char(sysdate(),'DD-MON-YYYY');
v_con number(12);
begin

delete from scpi300
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
                  
       insert into scpi300
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
                SUM(DECODE(trim(G501PAIDES),'PERÚ',0,1)) "CSC_OUT_INTERNACIONALES",
                SUM(DECODE(trim(G501PAIDES),'PERÚ',1,0)) "CSC_OUT_INTRAS"
                     from scpi501,scfl300
                       where g501stt = 'C'
                         and g501ageven = s300age
                         and g501usr NOT  in ('CSCUVJ')
                         and g501ageven not in ('038')
                         and to_char(g501uda,'MMYYYY')  = p_mes||p_ano
                         group by S300AGE) loop
                         
    select count(*) into v_con from scpi300 a
           where trim(a.s300mes) = trim(p_mes)
             and trim(a.s300ano) = trim(p_ano)
             and trim(a.s300age) = trim(e.s300age)
             and trim(a.s300tip) = '01';
         
      if v_con >= 1 then
        
         update scpi300 a
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
             SUM(DECODE(trim(G500PAIENV),'PERÚ',0,1)) "CSC_INB_INTERNACIONALES",
             SUM(DECODE(trim(G500PAIENV),'PERÚ',1,0)) "CSC_INB_INTRAS"
               from scpi500,scfl300
                     where g500stt = 'C'
                       and g500ageven = s300age
                       and g500usr not in ('CSCUVJ')
                       and g500ageven not in ('038')
                       and to_char(g500uda,'MMYYYY')  = p_mes||p_ano
                       group by s300age) loop
                       
         select count(*) into v_con from scpi300 a
           where trim(a.s300mes) = trim(p_mes)
             and trim(a.s300ano) = trim(p_ano)
             and trim(a.s300age) = trim(o.s300age)
             and trim(a.s300tip) = '01';
         
      if v_con >= 1 then
        
         update scpi300 a
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
                SUM(DECODE(trim(G501PAIDES),'PERÚ',0,1)) "TS_OUT_INTERNACIONALES",
                SUM(DECODE(trim(G501PAIDES),'PERÚ',1,0)) "TS_OUT_INTRAS"
                     from scpi501,scfl300
                       where g501stt = 'C'
                         and g501ageven = s300age
                         and g501usr  in ('CSCUVJ')
                         and g501ageven  NOT in ('038')
                         and to_char(g501uda,'MMYYYY')  = p_mes||p_ano
                         group by S300AGE) loop
                         
    select count(*) into v_con from scpi300 j
           where trim(j.s300mes) = trim(p_mes)
             and trim(j.s300ano) = trim(p_ano)
             and trim(j.s300age) = trim(a.s300age)
             and trim(j.s300tip) = '01';
         
      if v_con >= 1 then
        
         update scpi300 j
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
             SUM(DECODE(trim(G500PAIENV),'PERÚ',0,1)) "TS_INB_INTERNACIONALES",
             SUM(DECODE(trim(G500PAIENV),'PERÚ',1,0)) "TS_INB_INTRAS"
               from scpi500,scfl300
                     where g500stt = 'C'
                       and g500ageven = s300age
                       and g500usr in ('CSCUVJ')
                       and g500ageven not in ('038')
                       and to_char(g500uda,'MMYYYY')  = p_mes||p_ano
                       group by s300age) loop
                       
         select count(*) into v_con from scpi300 a
           where trim(a.s300mes) = trim(p_mes)
             and trim(a.s300ano) = trim(p_ano)
             and trim(a.s300age) = trim(u.s300age)
             and trim(a.s300tip) = '01';
         
      if v_con >= 1 then
        
         update scpi300 a
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
                      
       insert into scpi300
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

 select count(*) into v_con from scpi300 a
           where trim(a.s300mes) = trim(p_mes)
             and trim(a.s300ano) = trim(p_ano)
             and trim(a.s300age) = trim(c.COD_AGE)
             and trim(a.s300tip) = '02';
         
      if v_con >= 1 then
        
         update scpi300 a
                set a.S300INB_TOT  = c.total_Inbound ,
                    a.S300INB_INT = c.total_Inbound_intras
                    where trim(a.s300mes) = trim(p_mes)
                      and trim(a.s300ano) = trim(p_ano)
                      and trim(a.s300age) = trim(c.COD_AGE)
                      and trim(a.s300tip) = '02';
                      
                      
        else      
           insert into scpi300
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
  
    update scpi300
           set S300TOT = d.S300OUT_TOT + d.S300OUT_INT + d.S300INB_TOT + d.S300INB_INT
      WHERE S300MES = d.s300mes
        and s300ano = d.s300ano
        and s300tip = d.s300tip
        and s300age = d.s300age;
           

end loop;

commit;
        
end usp_Cargar_Simple_Fast_SCPI300;

                              procedure Usp_ObtInfor_SimpleFast(
  p_out1 out V_CURSOR,
  p_out2 out V_CURSOR
  )
  as 
  v_ano_act char(4) := to_char(sysdate,'YYYY');
  v_mes_act char(2) := to_char(sysdate,'MM');
  
  v_ano_ant char(4) := to_char(sysdate - 2,'YYYY');
  v_mes_ant char(2) := to_char(sysdate - 2,'MM');
  begin 
  

     
  usp_Cargar_Simple_Fast_SCPI300(v_mes_act,v_ano_act,'SYSBME');
  usp_Cargar_Simple_Fast_SCPI300(v_mes_ant,v_ano_ant,'SYSBME');
  
     open p_out1 for
          select upper(trim(to_char(to_date(to_char(s300MES),'mm'),'Month','NLS_DATE_LANGUAGE = SPANISH'))) || '-' || s300ano "Nombre_Meses",
                 SUM(DECODE(S300TIP,'01',1,0)) "Age_Propia" ,SUM(DECODE(S300TIP,'02',1,0)) "Agente" 
                       from scpi300
                       GROUP BY s300MES,s300ano
                       ORDER BY S300MES,S300ANO;
                       
     open p_out2 for 
          select * from scpi300
                 order by s300mes,s300ano,s300tip,s300rzs;  
  
end Usp_ObtInfor_SimpleFast;


procedure usp_Grabar_Error(
p_err_tip varchar2,
p_err_mtcn varchar2,
p_err_usr varchar2,
p_err_age varchar2,
p_err_ser varchar2,
p_err_des varchar2,
p_err_fin varchar2
)as
v_uda date := to_char(sysdate(),'dd-mon-yyyy');
v_con number(10);
begin

select count(*) into v_con from ERROMASIVO8
       where trim(err_mtcn) = trim(p_err_mtcn);
       
       if v_con = 0 then     
       
          insert into ERROMASIVO8
            (err_tip, err_fec, err_mtcn, err_usr,
             err_age, err_ser, err_des,err_fin)
          values
            (p_err_tip, v_uda, p_err_mtcn, p_err_usr,
             p_err_age, p_err_ser, p_err_des,p_err_fin);
             
            
       else 
         
             update ERROMASIVO8
                    set err_fin = p_err_fin,
                        err_ser = p_err_ser,
                        err_des = p_err_des
                   where trim(err_mtcn) = trim(p_err_mtcn)
                     and trim(ERR_FIN) = 'MAL';
       
       end if;

 commit;
 
end usp_Grabar_Error;




--------------------------------------------------------------------------------------------
--------------------------TRABAJANDO CAMBIO DE SIMPLE & FAST--------------------------------
--------------------------------------------------------------------------------------------

procedure Usp_ObtInfor_SimpleFast_test(
  p_out1 out V_CURSOR,
  p_out2 out V_CURSOR,
  p_out3 out V_CURSOR,
  p_out4 out V_CURSOR,
  p_out5 out V_CURSOR
  )
  as 
  v_ano_act char(4) := to_char(sysdate,'YYYY');
  v_mes_act char(2) := to_char(sysdate,'MM');
  
  v_ano_ant char(4) := to_char(sysdate - 2,'YYYY');
  v_mes_ant char(2) := to_char(sysdate - 2,'MM');
  begin 
  
  UPDATE SCPI501
       SET G501USR = 'CSCUVJ'
       WHERE TRIM(G501USR) IS NULL;
       
  UPDATE SCPI500
         SET G500USR = 'CSCUVJ'
         WHERE TRIM(G500USR) IS NULL;
         
         COMMIT;
  
  
  PCK_BOL_SF.USP_CARGAR_TAB_SF(v_mes_act,v_ano_act,'SYSBME');
    PCK_BOL_SF.USP_CARGAR_TAB_SF(v_mes_ant,v_ano_ant,'SYSBME');
  usp_Cargar_Simple_Fast_SCPI300(v_mes_act,v_ano_act,'SYSBME');
  usp_Cargar_Simple_Fast_SCPI300(v_mes_ant,v_ano_ant,'SYSBME');
  
     open p_out1 for
          select upper(trim(to_char(to_date(to_char(s300MES),'mm'),'Month','NLS_DATE_LANGUAGE = SPANISH'))) || '-' || s300ano "Nombre_Meses",
                 SUM(DECODE(S300TIP,'01',1,0)) "Age_Propia" ,SUM(DECODE(S300TIP,'02',1,0)) "Agente" 
                       from scpi300
                       GROUP BY s300MES,s300ano
                       ORDER BY S300MES,S300ANO;
                       
     open p_out2 for 
          select * from scpi300
                 order by s300mes,s300ano,s300tip,s300rzs;  
                 
     open p_out3 for 
          select distinct(s300age) s300age,s300tip,s300rzs
          from scpi300               
          UNION ALL
          select s300age,'02' "S300TIP", S300RZS 
                 from scfl300_age_bp
                      where s300age not in (select distinct(s300age) from scpi300)
          order by s300rzs,s300tip;
                 
     open p_out4 for             
             select upper(trim(to_char(to_date(to_char(s300MES),'mm'),'Month','NLS_DATE_LANGUAGE = SPANISH'))) || '-' || s300ano "Nombre_Meses",
                 SUM(DECODE(S300TIP,'01',1,0)) "Age_Propia" ,SUM(DECODE(S300TIP,'02',1,0)) "Agente" 
                       from scpi300
                       GROUP BY s300MES,s300ano
                       ORDER BY S300ANO,S300MES;
                       
     open p_out5 for           
             select s300ano,s300mes,upper(trim(to_char(to_date(to_char(s300MES),'mm'),'Month','NLS_DATE_LANGUAGE = SPANISH'))) || '-' || s300ano "Nombre_Meses",
                   s300tip,s300age,s300rzs, 
                         decode(trim(a.S300OUT_TOT_CSC),'',0,a.S300OUT_TOT_CSC) + decode(trim(a.S300OUT_INT_CSC),'',0,a.S300OUT_INT_CSC)  + 
                         decode(trim(a.S300INB_TOT_CSC),'',0,a.S300INB_TOT_CSC) + decode(trim(a.S300INB_INT_CSC),'',0,a.S300INB_INT_CSC)  + 
                         decode(trim(a.S300OUT_TOT_TS),'',0,a.S300OUT_TOT_TS)   + decode(trim(a.S300OUT_INT_TS),'',0,a.S300OUT_INT_TS)    + 
                         decode(trim(a.S300INB_TOT_TS),'',0,a.S300INB_TOT_TS)   + decode(trim(a.S300INB_INT_TS),'',0,a.S300INB_INT_TS) "Totales"
                      from scpi300 a
                          order by s300ano,s300mes,s300tip,s300rzs;
  
end Usp_ObtInfor_SimpleFast_test;


end PCK_APOLO_SIMPLE_FAST_TEST;
/
