/*
exec comun.dbo.GestorCarga 'DW_AUTOS.TARIFICADOR_NEGOCIOS',0,NULL,14400, @test=1
exec comun.dbo.GestorCargaDwh 'DW_AUTOS.DBO.TUTTUSOS-0',0,@ParamComodin = '', @ModoLogar = 0, @test=1
exec comun..pr_AplicadorCambiosAudit 'staging_sql.autos.VT_TUTTUSOS','Dw_Autos.dbo.TUTTUSOS','F_CARGA','',@btest=1

comun.dbo.GestorCarga 'DW_AUTOS.OTROS',0,NULL,14400
COMUN..GESTORCARGA 'DW_AUTOS.SINIESTROS',0,NULL,15000
comun.dbo.GestorCarga 'DW_AUTOS.RDANOS_JUICIOS',0,NULL,14400
COMUN.dbo.GESTORCARGA 'DW_AUTOS.PRODUCCION',0,NULL,28800
comun.dbo.GestorCarga 'DW_AUTOS.PRODUCCION1',0,NULL,14400
comun.dbo.GestorCarga 'DW_AUTOS.PRODUCCION2',0,NULL,14400
COMUN..GESTORCARGA 'DW_AUTOS.PAGOS',@paramcomodin='aaaa-mm-dd hh:mm:ss.nnnnnn'
comun.dbo.GestorCarga 'DW_AUTOS.SOLICITUDES'
comun.dbo.gestorcarga 'dw_autos.Produccion3'
COMUN..GESTORCARGA 'DW_AUTOS.OPERADORES',0,NULL,60
*/
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
	A.ENUSO='S'
	AND
	(
		A.basedatos='DW_AUTOS' AND A.SUBAREA='OTROS' 
		OR
		A.basedatos='DW_AUTOS' AND A.SUBAREA='SINIESTROS' 
		OR
		A.basedatos='DW_AUTOS' AND A.SUBAREA='RDANOS_JUICIOS' 
		OR
		A.basedatos='DW_AUTOS' AND A.SUBAREA='PRODUCCION' 
		OR
		A.basedatos='DW_AUTOS' AND A.SUBAREA='PRODUCCION1' 
		OR
		A.basedatos='DW_AUTOS' AND A.SUBAREA='PRODUCCION2' 
		OR
		A.basedatos='DW_AUTOS' AND A.SUBAREA='PAGOS' 
		OR
		A.basedatos='DW_AUTOS' AND A.SUBAREA='SOLICITUDES' 
		OR
		A.basedatos='DW_AUTOS' AND A.SUBAREA='Produccion3' 
		OR
		A.basedatos='DW_AUTOS' AND A.SUBAREA='OPERADORES' 
	)
	
ORDER BY
	A.BASEDATOS,A.SUBAREA
	

/*
select b.subarea,c.PrefijoFichero,c.rutaFichero, a.* from comun..cfg_datawarehouse a
inner join comun..cfg_areas b
on a.basedatos=b.basedatos and a.tabladwh =b.TablaDwh
left outer join comun..cfg_staging c
on a.tablastg=c.tablastg
where 
a.basedatos='DW_AUTOS' 
and b.enuso='S'
and b.subarea='SINIESTROS_EXCEL'
select distinct RutaEntidad,TablaStg,ModoCarga from dbo.GC_ListadoEntidadesCargarDwh('dw_mutua.DIARIO')
*/