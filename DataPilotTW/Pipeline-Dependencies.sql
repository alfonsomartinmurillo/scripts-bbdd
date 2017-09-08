--select top 100 * from dbo.rutascontencion
select 
 	-- OBJ_BUSCADOS.ID_OBJETO_BUSCADO,
	obj_buscados.RUTA_OBJETO_BUSCADO AS OBJETO_ANALIZADO, --obj_buscados.RUTA_TIPADA_OBJETO_BUSCADO,
	obj_buscados.NOMBRE_OBJETO as NOMBRE_OBJETO_ANALIZADO,
	case
		when obj_buscados.RUTA_OBJETO_BUSCADO = RCOBJA.rutaContencion then RCOBJB.rutaContencion
		else RCOBJA.rutaContencion
	end as OBJETO_DEPENDIENTE,
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
			'Entorno::Producción//SubEntorno::SRDWPRO1//Base de Datos::BI_PRODUCCION//Esquema::dbo//Procedimiento Almacenado::Rc_carga_ratios_conv_en_srspss'
			)
	) OBJ_BUSCADOS
ON
	((RO.idobjeto=OBJ_BUSCADOS.Id_Objeto_buscado) OR (RO.IdObjetoRelacionado=OBJ_BUSCADOS.id_objeto_buscado))
WHERE
	-- LISTADO DE RELACIONES QUE EXCLUYO
	RT.TipoRelacion NOT IN ('CONTENCION', 'DEPENDENCIA')
	-- OBJETOS QUE ME INTERESA EXCLUIR
	-- EXCLUYO LAS RELACIONES CONMIGO MISMO
	AND
		RCOBJA.idobjeto <> RCOBJB.idobjeto
	AND
		RCOBJA.TipoObjeto NOT IN ('Cadena de Control-M') 
	AND 
		RCOBJB.TipoObjeto NOT IN ('Cadena de Control-M')
