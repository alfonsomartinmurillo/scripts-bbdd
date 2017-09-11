--COMUN..GESTORCARGAX 'XAUTOS.Diario_Produccion1',0
--comun.dbo.gestorcarga 'dw_autos.Produccion3'

SELECT 
	* 
FROM 
	CFG_AREAS A
INNER JOIN
	CFG_DATAWAREHOUSE DW
ON
	DW.basedatos=a.basedatos
	and DW.Esquema = a.Esquema
	and DW.tablaDWH=a.tabladwh
where 
	A.basedatos='DW_AUTOS'
	AND
	A.SUBAREA='PRODUCCION3'
	AND 
	A.ENUSO='S'

SELECT * FROM CFG_AREAS -- BASE DE DATOS Y ÁREA

SELECT 
	* 
FROM 
	CFG_AREAS A
INNER JOIN
	CFG_XDATAS X
ON
	x.basedatos=a.basedatos
	and x.Esquema = a.Esquema
	and x.tablax=a.tabladwh
where 
	A.basedatos='XAUTOS'
	AND
	A.SUBAREA='DIARIO_PRODUCCION1'
	AND 
	A.ENUSO='S'


WHERE BASEDATOS='XAUTOS' AND SUBAREA='DIARIO_PRODUCCION1' AND ENUSO='S'
SELECT * FROM Cfg_xdatas

SELECT
	*
FROM
	cfg_xdatas  x
		inner join 
	cfg_areas a

/*
from 
			cfg_xdatas  x
		inner join 
			cfg_areas a
*/