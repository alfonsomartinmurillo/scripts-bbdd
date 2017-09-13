--select top 100 * from dbo.rutascontencion
--SET STATISTICS IO ON

--SELECT * FROM DBO.OBJETOSTIPOS WHERE TIPOOBJETO='Cadena de Control-M' -- 134
--SELECT * FROM DBO.RUTASCONTENCION
select 
 	-- OBJ_BUSCADOS.ID_OBJETO_BUSCADO,
	obj_buscados.RUTA_OBJETO_BUSCADO AS OBJETO_ANALIZADO, --obj_buscados.RUTA_TIPADA_OBJETO_BUSCADO,
	obj_buscados.NOMBRE_OBJETO as NOMBRE_OBJETO_ANALIZADO,
	case
		when obj_buscados.RUTA_OBJETO_BUSCADO = RCOBJA.rutaContencion then RCOBJB.rutaContencion
		else RCOBJA.rutaContencion
	end as OBJETO_DEPENDIENTE,
	case
		when obj_buscados.RUTA_OBJETO_BUSCADO = RCOBJA.rutaContencion then RCOBJB.Rutacontenciontipada
		else RCOBJA.rutaContenciontipada
	end as OBJETO_DEPENDIENTE_TIPADO,
	case
		when obj_buscados.RUTA_OBJETO_BUSCADO = RCOBJA.rutaContencion then RCOBJB.TipoObjeto
		else RCOBJA.TipoObjeto
	end as TIPO_OBJETO_DEPENDIENTE,
	case
		when obj_buscados.RUTA_OBJETO_BUSCADO = RCOBJA.rutaContencion then 'W'
		else 'R'
	end as ROL_OBJETO_DEPENDIENTE,
	RCOBJA.rutaContencion AS OBJETOA, RCOBJA.TipoObjeto as TipoObjetoA,
	RT.TipoRelacion,RO.IdRelacionObjeto,
	RCOBJB.rutaContencion AS OBJETOB,  RCOBJB.TipoObjeto as TipoObjetoB,
	RO.*, RT.*
from 
	RelacionesObjetos RO
inner join
	RutasContencion RCOBJA
	ON
RO.IdObjeto=RCOBJA.IdObjeto
inner join
	RutasContencion RCOBJB
	ON
RO.IdObjetoRelacionado=RCOBJB.IdObjeto
INNER JOIN
	RelacionesTipos RT
ON
	RT.IdTipoRelacion=RO.IdTipoRelacion
INNER JOIN
	(SELECT 
		idobjeto ID_OBJETO_BUSCADO, objeto as NOMBRE_OBJETO, rutaContencion RUTA_OBJETO_BUSCADO, rutaContencionTipada RUTA_TIPADA_OBJETO_BUSCADO  
	FROM 
		DBO.RutasContencion 
	WHERE 
		rutaContencionTipada IN 
			(
			/*
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Procedimiento Almacenado::pr_Carga_xTalleres_H_EsTallerActual',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::XDIM//Esquema::autos//Procedimiento Almacenado::pr_Carga_Dim_Diario_Comun',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::XDIM//Esquema::autos//Procedimiento Almacenado::pr_carga_dim_diario_certificadosiniestralidad',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::XDIM//Esquema::autos//Procedimiento Almacenado::Pr_carga_dim_diario_produccion',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::BI_PRODUCCION//Esquema::dbo//Procedimiento Almacenado::GESTOR_CARGADIMCOMUNES_PRODUCCION',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::BI_PRODUCCION//Esquema::dbo//Procedimiento Almacenado::Rc_generar_th_ratios_conversion',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::BI_PRODUCCION//Esquema::dbo//Procedimiento Almacenado::Rc_carga_ratios_conv_en_srspss',
			*/
			-- objetos que tienen que ver con el propio proceso de XCONVERSIONES
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Procedimiento Almacenado::Pr_carga_xconversiones',		
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Vista::Xpolizas_comun',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Vista::XPOLIZAS_IMPUTACION',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Vista::Xverificaciones',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::XDIM//Esquema::autos//Tabla::Productos',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Vista::XCONVERSIONES',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Vista::Xcotizaciones',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Vista::Xpresupuestos',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Vista::MARCAS',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::DW_AUTOS//Esquema::dbo//Sinónimo::TAUTLINK',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::DW_AUTOS//Esquema::dbo//Tabla::TAULOIPR',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::DW_AUTOS//Esquema::dbo//Vista::PRESUPUESTOS_Y_TASACIONES_POLIZAS',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::XDIM//Esquema::autos//Tabla::Negocios',
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::xautos//Esquema::dbo//Vista::XCONVERSIONES'
			)
	) OBJ_BUSCADOS
ON
	((RO.idobjeto=OBJ_BUSCADOS.Id_Objeto_buscado) OR (RO.IdObjetoRelacionado=OBJ_BUSCADOS.id_objeto_buscado))
WHERE
	-- LISTADO DE RELACIONES QUE EXCLUYO
	RT.TipoRelacion IN ('Flujo de Datos') --NOT IN ('CONTENCION', 'DEPENDENCIA')
	-- OBJETOS QUE ME INTERESA EXCLUIR
	-- EXCLUYO LAS RELACIONES CONMIGO MISMO
	AND
		RCOBJA.idobjeto <> RCOBJB.idobjeto
	AND
		RCOBJA.IDTipoObjeto NOT IN (134) 
	AND 
		RCOBJB.IDTipoObjeto NOT IN (134)
	and 
		(
		--excluimos las posibles relaciones a tablas temporales
		RCOBJA.RUTACONTENCION NOT LIKE ('Producción//SRDWPRO1//tmp//%')
		and 
		RCOBJB.RUTACONTENCION NOT LIKE 'Producción//SRDWPRO1//tmp//%'
		)


ORDER BY OBJETO_ANALIZADO
--SET STATISTICS IO OFF