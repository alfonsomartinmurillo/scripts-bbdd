/*
COMUN..GESTORCARGAX 'XAUTOS.Diario_Produccion1',0
COMUN..GESTORCARGAX 'XAUTOS.Diario_Talleres_H',0
COMUN..GESTORCARGAX 'XAUTOS.Diario_Produccion8',0
COMUN..GESTORCARGAX 'XAUTOS.Diario_Produccion9',0
COMUN.dbo.GESTORCARGAX 'XAUTOS.Diario_Perceptores',0
COMUN..GESTORCARGAX 'XAUTOS.Diario_Produccion2',0
COMUN..GESTORCARGAX 'XAUTOS.Diario_PromocionesOfertas',0
comun..GestorcargaX 'XAUTOS..XPOLIZAS_COMUN',null,0
COMUN..GESTORCARGAX 'XAUTOS.Diario_Produccion4',0
comun..GestorCargaX 'XAUTOS.GENERADOR_DEMANDA'
COMUN..GESTORCARGAX 'XAUTOS.Diario_Produccion5',0
COMUN..GESTORCARGAX 'BI_PRODUCCION..Oper_TH_Operativa_Diaria'

select * from cfg_areas where basedatos='xautos' and tabladwh='xpolizas_comun' and enuso='s' order by basedatos, SUBAREA
select * from cfg_xdatas where basedatos='xautos' order by basedatos
*/


-- CONSULTA QUE ME MUESTRA TODAS LAS DEPENDENCIAS ASOCIADAS A LLAMADAS A SUBAREAS.
SELECT 
	* 
FROM 	
	CFG_AREAS A 
INNER JOIN 
	CFG_XDATAS X 
ON 
	x.basedatos=a.basedatos and x.Esquema = a.Esquema and x.tablax=a.tabladwh 
where
	A.ENUSO='S'
	AND
	-- LISTADO DE SUBAREAS A CARGAR
	(
		(A.basedatos='XAUTOS' AND A.SUBAREA='DIARIO_PRODUCCION1')
		OR
		(A.basedatos='XAUTOS' AND A.SUBAREA='DIARIO_TALLERES_H')
		OR
		(A.basedatos='XAUTOS' AND A.SUBAREA='DIARIO_PRODUCCION8')
		OR
		(A.basedatos='XAUTOS' AND A.SUBAREA='DIARIO_PRODUCCION9')
		OR
		(A.basedatos='XAUTOS' AND A.SUBAREA='DIARIO_PERCEPTORES')
		OR
		(A.basedatos='XAUTOS' AND A.SUBAREA='DIARIO_PRODUCCION2')
		OR
		(A.basedatos='XAUTOS' AND A.SUBAREA='DIARIO_PROMOCIONESOFERTAS')
		OR
		(A.basedatos='XAUTOS' AND A.SUBAREA='DIARIO_PRODUCCION4')
		OR
		(A.basedatos='XAUTOS' AND A.SUBAREA='GENERADOR_DEMANDA')
		OR
		(A.basedatos='XAUTOS' AND A.SUBAREA='DIARIO_PRODUCCION5')
	)
	UNION

-- CONSULTA QUE ME MUESTRA TODAS LAS DEPENDENCIAS ASOCIADAS A LLAMADAS A SUBAREAS.
SELECT 
	* 
FROM 	
	CFG_AREAS A 
INNER JOIN 
	CFG_XDATAS X 
ON 
	x.basedatos=a.basedatos and x.Esquema = a.Esquema and x.tablax=a.tabladwh 
where
	A.ENUSO='S'
	AND
	(
		(A.basedatos='XAUTOS' AND A.TABLADWH='XPOLIZAS_COMUN')
		OR
		(A.basedatos='BI_PRODUCCION' AND A.TABLADWH='Oper_TH_Operativa_Diaria')
	)
ORDER BY
	a.BASEDATOS, a.SUBAREA, a.ENTIDAD
