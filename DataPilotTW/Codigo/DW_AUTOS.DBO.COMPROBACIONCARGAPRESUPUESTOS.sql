









CREATE                  PROCEDURE dbo.ComprobacionCargaPresupuestos as

/*
--------------------------Lista de ejecuciones y comprobaciones-----------------------------------
DESCRIPCION:
------------------------------------------------------------------------------
CREADO POR/FECHA: Mª Nieves Sanchez-M. 27/02/2007
------------------------------------------------------------------------------
MODIFICADOR POR/FECHA: 
------------------------------------------------------------------------------
ENTRADAS:
------------------------------------------------------------------------------
SALIDAS:
------------------------------------------------------------------------------
OBSERVACIONES:
----------------------------------------------------------------------------
*/




--PRESUPUESTOS_Y_TASACIONES_POLIZAS

	EXEC COMUN..GESTORCARGASTG 'STG_AINSVEH'

	select cdcfun, count(*) from staging_Sql..Stg_AINSVEH group by cdcfun


	EXEC COMUN..GESTORCARGADWH 'DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS',0,'11111100',1


	EXEC COMUN..GESTORCARGA 'DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS'
	SELECT  *  FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Ainsveh' --and Left(f_carga,8)='20070404'
	SELECT COUNT(*) FROM DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS WHERE ACTUAL=0

	EXEC COMUN..GESTORCARGA 'DW_AUTOS..PRESUPUESTOS'
	SELECT  *  FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Apolizp' --and Left(f_carga,8)='20070404'
	SELECT COUNT(*) FROM DW_AUTOS..PRESUPUESTOS where contratada=0

--COMPROBACION PRESUPUESTOS_Y_TASACIONES_POLIZAS------------------------------------------------------------------------
	
	SELECT  *  FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Ainsveh' 


	SELECT Sum(total)
	FROM(
		SELECT  CountActual as total  FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Ainsveh' and CountActual=(Select max(CountActual) from COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='AiNsveh')
		UNION ALL
		SELECT   sum(CountDelt) as total FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Ainsveh' 
	) a

	SELECT COUNT(*) FROM DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS
-----------------------------------------------------------------------------------------------------------------
	SELECT  *  FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Ainsveh' and Left(f_carga,8)='20070307'
	SELECT COUNT(*) FROM DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS WHERE ACTUAL=0

	select fec_generacion, count(*) FROM DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS group by fec_generacion



select count(*) from DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS   where  fec_generacion='20070303'

--UPDATE DW_AUTOS..PRESUPUESTOS  SET FEC_GENERACION='20070304'where fec_generacion='20070303'
UPDATE DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS SET FEC_GENERACION='20070304' WHERE FEC_GENERACION='20070303'


---******************************************************************************************************************

--PRESUPUESTOS


	EXEC COMUN..GESTORCARGASTG 'STG_APOLIZP'

	select cdcfun, count(*) from staging_Sql..Stg_APOLIZP group by cdcfun

	EXEC COMUN..GESTORCARGADWH 'DW_AUTOS..PRESUPUESTOS',0,'11111100',1



---------------COMPROBACION PRESUPUESTOS--------------------------------------------------------------
	
	SELECT  *  FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Apolizp' 


	SELECT  CountActual FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Apolizp' and CountActual=(Select max(CountActual) from COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Apolizp')

	SELECT COUNT(*) FROM DW_AUTOS..PRESUPUESTOS where contratada=0
----------------------------------------------------------------------------------------------------------------

	SELECT  *  FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Apolizp' 
	select fec_generacion, count(*) FROM DW_AUTOS..PRESUPUESTOS group by fec_generacion


----------------------------------------------------------------------------------------------------------------






select distinct fec_generacion FROM DW_AUTOS..PRESUPUESTOS 


select count(*) from DW_AUTOS..PRESUPUESTOS  where  fec_generacion='20070303 19:21:00'

--UPDATE DW_AUTOS..PRESUPUESTOS  SET FEC_GENERACION='20070304'where fec_generacion='20070303'
UPDATE DW_AUTOS..PRESUPUESTOS SET FEC_GENERACION='20070304' WHERE FEC_GENERACION='20070303 19:21:00'


SELECT CONVERT(VARCHAR(23), CONVERT(DATETIME,'20070303 19:21:00'),112)
SELECT TOP 10 CONVERT(VARCHAR(23), CONVERT(DATETIME,'20070303 19:21:00'),120)





-------------------------------------CONSULTA LOG DE EJECUCIONES--------------------------

--PRESUPUESTOS

SELECT * FROM COMUN..LOGS WHERE BASEDATOS='STAGING_SQL' AND ENTIDAD='STG_AINSVEH' ORDER BY ID DESC
SELECT * FROM COMUN..LOGS WHERE BASEDATOS='DW_AUTOS' AND ENTIDAD='DW_AUTOS..PRESUPUESTOS' ORDER BY ID DESC


--PRESUPUESTOS_Y_TASACIONES_POLIZAS

SELECT * FROM COMUN..LOGS WHERE BASEDATOS='STAGING_SQL' AND ENTIDAD='STG_APOLIZP' ORDER BY ID DESC
SELECT * FROM COMUN..LOGS WHERE BASEDATOS='DW_AUTOS' AND ENTIDAD='DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS' ORDER BY ID DESC


SELECT * FROM COMUN..LOGS ORDER BY ID DESC


-------------------------------- RESULTADO CARGAS -------------------------
--******************************************************************************--

--PRESUPUESTOS

SELECT * FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Apolizp' and CountActual=(Select max(CountActual) from COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Apolizp')
SELECT COUNT(*) FROM DW_AUTOS..PRESUPUESTOS

--PRESUPUESTOS_Y_TASACIONES_POLIZAS


SELECT * FROM COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Ainsveh' and CountActual=(Select max(CountActual) from COMUN.dbo.COMPROBACIONESDWH where EntidadOrigen='Ahisveh')
SELECT COUNT(*) FROM DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS






--INC 2070223

--PRESUPUESTOS
SELECT DISTINCT FEC_GENERACION FROM DW_AUTOS..PRESUPUESTOS_Y_TASACIONES_POLIZAS


--PRESUPUESTOS_Y_TASACIONES_POLIZAS
--27 Feb 2007 12:09:18:317-->DW_AUTOS.EAINSVEH------Registros transferidos a PRESUPUESTOS_Y_TASACIONES_POLIZAS: 1515 registros(583 registros coincidentes borrados)
--I	932
--D	128  pasan a R y se inserta a la final
--R	455
--Total a insertar 1515
--coincidentes D + R = 583


--INC 2070224

--PRESUPUESTOS
--PRESUPUESTOS_Y_TASACIONES_POLIZAS


--INC 2070225

--PRESUPUESTOS
--PRESUPUESTOS_Y_TASACIONES_POLIZAS







