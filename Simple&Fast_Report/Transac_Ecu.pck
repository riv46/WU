create or replace package Transac_Ecu is

  -- Author  : 26227341
  -- Created : 19/04/2016 12:25:30 p.m.
  -- Purpose : Trans_Ecu
  
  TYPE V_CURSOR IS REF CURSOR;
  

 PROCEDURE USP_INSERT_TRA_ECU(         
  p_ageid CHAR,
  p_magent CHAR,
  p_loc CHAR,
  P_ser CHAR,
  P_ano CHAR,
  P_mes CHAR,
  P_can CHAR,
  P_cant NUMBER, 
  P_csc NUMBER, 
  P_touch NUMBER,
  P_OUT1 OUT V_CURSOR
 
  );
  
  
PROCEDURE USP_Eliminar_Transacciones(
  p_ano CHAR,
  p_mes CHAR,
  P_OUT1 OUT V_CURSOR  
  ) ;
  
end Transac_Ecu;
/
create or replace package body Transac_Ecu is

 PROCEDURE USP_INSERT_TRA_ECU
 (         
  p_ageid CHAR,
  p_magent CHAR,
  p_loc CHAR,
  P_ser CHAR,
  P_ano CHAR,
  P_mes CHAR,
  P_can CHAR,
  P_cant NUMBER, 
  P_csc NUMBER, 
  P_touch NUMBER, 
    P_OUT1 OUT V_CURSOR
  )AS
  e_ser exception;
  
  Begin 
   INSERT INTO TRANS_ECU(b300id, b300magent, b300rzs, b300ser, b300ano, b300mes ,b300can2, b300cant,b300csc, b300touch)
  Values (p_ageid, p_magent, p_loc, p_ser, p_ano, p_mes, p_can, p_cant, p_csc, p_touch);
  commit;
  

  
  open P_OUT1 for
  select 1 from dual;
  
   EXCEPTION 
   WHEN e_ser THEN
   OPEN P_OUT1 FOR
   SELECT -1 FROM DUAL;
    
  
 END USP_INSERT_TRA_ECU; 



PROCEDURE USP_Eliminar_Transacciones(
  p_ano CHAR,
  p_mes CHAR,
  P_OUT1 OUT V_CURSOR  
  ) AS BEGIN
  
  
  DELETE FROM TRANS_ECU A 
         WHERE A.B300ANO = p_ano
           AND LPAD(A.B300MES,2,'0') = p_mes;
           
  COMMIT;
  
  open p_out1 for 
  select '1' from dual;
 
  
  END USP_Eliminar_Transacciones;


END Transac_Ecu;
/
