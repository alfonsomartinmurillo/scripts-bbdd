

--truncate table xautos..xconversiones
--exec comun..gestorcargax 'xautos..xconversiones',null,1
--exec comun..GestorCargaX 'XAUTOS.dbo.XConversiones',null,0

--select top 10 * from xautos..xcotizaciones
--select top 10 * from xautos..xpresupuestos
--select top 10 * from xautos..xverificaciones

--exec XAUTOS.[dbo].[pr_Carga_XConversiones] '19010101'
--exec XAUTOS.[dbo].[pr_Carga_XConversiones] '20140627'
/*******************************************************************************************
Para ejecutar, comentar Alter y poner DECLARE
*******************************************************************************************/
--
--exec xautos.[dbo].[pr_Carga_XConversiones] '19010101'
CREATE procedure [dbo].[pr_Carga_XConversiones] @UltimaFcargaX datetime
AS
/*----------------------------------------------------------------------------
DESCRIPCION:
Carga la tabla Xconversiones
------------------------------------------------------------------------------
CREADO POR/FECHA: Jgomez 15-09-2008
------------------------------------------------------------------------------
MODIFICADO POR/FECHA:  
Mario Sánchez Muñoz 27-04-2009  Se incluye RENTING (>8000000):
								1JXX	Renting LICO		Renting
								2WXX	Renting GE Basico	Renting
								1IXX	Renting IB 			Renting
								2AXX	Renting Bansalease	Renting

Se modifica la consulta de las tasaciones que no graban tautlink, para que coja
el mayor idpoliza sociado al ainsobs1.

Mario Sánchez Muñoz 19-08-2009 Se modifica la tabla de Duplicados.Se añade la condicion "Fechainicio is not NULL" al Left con Presupuestos para evitar duplicidad.
Mario Sánchez Muñoz 19-08-2009 Se añaden Cotizaciones Web y para  la eliminacion de Duplicados se dejan de utilizar tablas internedias.
Gemma Pérez         20-04-2010 se anade un índice a la tabla XConversiones. Después de la carga total que se hacía 
					           hasta ahora, se realiza la carga del índice.
Gemma Pérez: 11/08/2011  Cambiada consulta e indices para generar la tabla TMP.XAUTOS_dbo.Xconversiones_Cartera
						 para su optimización: cuando hay problemas de servidor o de disco, 
						 la consulta no responde bien.
Gemma Pérez: 13/09/2011	 Cambiada consulta contra XVerificaciones por inclusión de numeración
						 19 millones en las verificaciones.		
Adela Gutiérrez: 18/05/2012: Parche temporal para arreglar el problema de las conversiones perdidas del 18/04/2012 al 18/05/2012.
							 Se quitará cuando se arregle en host.
							 Inlcuimos las conversiones recuperadas que están en la tabla XAUTOS.[dbo].[TAUTLINK_PARCHE20120517]
Adela Gutiérrez: 12/06/2012: Quitado parche XAUTOS.[dbo].[TAUTLINK_PARCHE20120517]. Arreglado en host.					 
Gemma Pérez: 08/07/2013: Optimizaciones en consultas
Gemma Pérez: 03/06/2014  Incidencia D-78982 Cambio en la consulta TAUTLINK para considerar las pólizas de 4.000.000 a 8.000.000
						 (El filtro anterior sólo llegaba a 4.000.000). 
						  El 31 de marzo 2014 entró la primera póliza 4 millones.
						  Atención : Hay pólizas 4 millones anteriores a esa fecha: como en total son 37
						  las consideramos despreciables frente al resto para no meter una ñapa.
Eduardo Cuadrado: 27/06/2014 Se incluye campo Extrapolacion que nos indicara si la poliza ha sido o no extrapolada.
							 **Ver los Cambios por 20140627

Gemma Pérez: 09/10/2014  En el ejercicio de extrapolación de cotizaciones web, se descartan las cotizaciones erróneas cuando lo sean.
						 El campo CodErrorCotiz de la tabla XAUTOS..XCOTIZACIONES ya nos indica ese dato.

Luis Arroyo: 11/05/2015  Se elimina Union final para evitar repeticiones. Se sustituye por UNION ALL y Row_number

Gemma Pérez: 17/03/2016  Comité de crisis BI. Se comentan las líneas Try y Catch para evitar bloqueos con 
                         la carga del generador de la demanda.

Gemma Pérez: 21/03/2016  Comentados option(recompile)
                         Modificado Partition BY para trabajar con IdConversion en lugar de fecha de carga

Gemma Pérez: 21/03/2016  Modificada consulta de carga de TMP.XAUTOS_dbo.Xconversiones_Cartera para optimización de los tiempos. Crisis cargas BI.                         

Gemma Pérez: 29/03/2016  Modificada consulta de carga de TMP.XAUTOS_dbo.Xconversiones para optimización de los tiempos. Crisis cargas BI.                                                  
                         Se divide en dos consultas, TMP.XAUTOS_dbo.Xconversiones_Total y TMP.XAUTOS_dbo.Xconversiones.
Gemma Pérez: 06/04/2016  Creación de índice TMP.XAUTOS_DBO.XCotizaciones_SinError.
Gemma Pérez: 07/04/2016  Modificada consulta de carga de TMP.XAUTOS_dbo.Xconversiones_Cartera para optimización de los tiempos. Crisis cargas BI.                         
Gemma Pérez: 15/04/2016  Se revierte consulta de carga de TMP.XAUTOS_dbo.Xconversiones_Cartera ya que la actual no se comporta según lo esperado.

Gemma Pérez: 07/09/2016  Optimizaciones:
							Eliminación de la última etapa de la carga (TMP.XAUTOS_dbo.Xconversiones) y división de la consulta
							de la tabla TMP.XAUTOS_dbo.Xconversiones_Total
Gemma Pérez: 08/09/2016  Optimizaciones:
							Cambio en la creación del índice de TMP.XAUTOS_DBO.Xconversiones1

Alvaro Roldán 28/11/2016  Modificamos el algorítmo (SD 231833) para separar conversiones por Empresa y Segmento Estratégico

09/02/2017 - Javier Torres
	· Logados detallados en el borrado por errores de IR. Se hacen 8 borrados y ahora loga cada uno de ellos

Gemma Pérez: 20/02/2017  Ampliación Marca en AMMO. Cambio en la extrapolación por las 5 variables para no trabajar con
										           campo calculado chk.
	
							
------------------------------------------------------------------------------

ENTRADAS:
------------------------------------------------------------------------------
SALIDAS:
------------------------------------------------------------------------------
----------------------------------------------------------------------------*/
--BEGIN TRY

	--declare @UltFcargaX datetime='19010101'
	
	set nocount on

	declare @Msg varchar(1000), @Nregistros int, @FechaDesde date

	--if @UltFcargaX='19010101' then set @FechaDesde='20070901' else set @FechaDesde=dateadd(dd,-90,getdate())
	--if @UltFcargaX='19010101' then set @FechaDesde='20070901' else set @FechaDesde=dateadd(dd,-90,getdate())
 
  -- Para guardar el próximo valor de IdConversion
   DECLARE @iIdentidad bigInt, @regTemp bigInt, @regXConv bigInt
   declare @filas int
   
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--TRANSICIONES ENTRE ESTADOS
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

--Provenientes de la tauloipr
	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0'   
	create table TMP.XAUTOS_DBO.Xconversiones0(id bigint identity(1,1),FecOrigen datetime, Eorigen varchar(1) ,origen decimal(20,0),FecDestino datetime,Edestino varchar(1),Destino decimal(20,0),Paso tinyint not null,Extrapolacion varchar(1))--20140627
	--create table TMP.XAUTOS_DBO.Xconversiones0(Eorigen varchar(1) ,origen decimal(20,0),Edestino varchar(1),Destino decimal(20,0),Paso tinyint not null)	

	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0_auxPaso1'   
	select
		null							as FecOrigen
		,'C'							as Eorigen
		,IdCotizacion					as origen
		--,auloifemi
		,null							as FecDestino
		,'P'							as Edestino
		,auloirpol						as Destino
		,1								as Paso
		,'N'							as Extrapolacion --20140627
	into TMP.XAUTOS_DBO.Xconversiones0_auxPaso1
	from dw_autos..TAULOIPR pc WITH(NOLOCK)
	where auloifemi >='20070901' and auloisitu='S' and auloirpol>2850366 --cotizacion a poliza 

	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select FecOrigen, Eorigen, origen, FecDestino, Edestino, Destino, Paso, Extrapolacion 
	from (
		select xconv.*
			 , xc.idEmpresa as idEmpresaOrigen
			 , xpc.idEmpresa as idEmpresaDestino
			 , nc.cod_tiponegocioestrategico as SegmentoOrigen
			 , npi.cod_tiponegocioestrategico as SegmentoDestino
		from TMP.XAUTOS_DBO.Xconversiones0_auxPaso1 xconv WITH(NOLOCK)
		join xautos..xcotizaciones xc WITH(NOLOCK) on xconv.origen = xc.idCotizacion
		left join xdim.autos.negocios nc WITH(NOLOCK) on xc.idNegocio = nc.cod_Negocio
		left join xautos..xpolizas_comun xpc WITH(NOLOCK) on xconv.Destino = xpc.apolclav
		left join xautos..xpolizas_imputacion xpi WITH(NOLOCK) on xconv.Destino = xpi.apolclav and xpi.PrimerMovimiento = 1
		left join xdim.autos.negocios npi WITH(NOLOCK) on xpi.idNegocio = npi.cod_Negocio
	) A
	where A.idEmpresaOrigen = A.idEmpresaDestino and A.SegmentoOrigen = A.SegmentoDestino

	set @Msg='Inserción de Tauloipr(1) en Tabla temporal generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1


	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0_auxPaso1b'   
	select
		null							as FecOrigen
		,'C'							as Eorigen
		,IdCotizacion					as origen
		--,auloifemi
		,null							as FecDestino
		,'R'							as Edestino 				
		,auloirpol						as Destino
		,1								as Paso
		,'N'							as Extrapolacion --20140627
	into TMP.XAUTOS_DBO.Xconversiones0_auxPaso1b
	from dw_autos..TAULOIPR pc WITH(NOLOCK)
	where auloifemi >='20070901' and auloisitu='U' and auloirpol>9000000 --cotizacion a presupuesto		
	 

	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select FecOrigen, Eorigen, origen, FecDestino, Edestino, Destino, Paso, Extrapolacion 
	from (
		select xconv.*
			 , xc.idEmpresa as idEmpresaOrigen
			 , xp.idEmpresa as idEmpresaDestino
			 , nc.cod_tiponegocioestrategico as SegmentoOrigen
			 , np.cod_tiponegocioestrategico as SegmentoDestino
		from TMP.XAUTOS_DBO.Xconversiones0_auxPaso1b xconv WITH(NOLOCK)
		join xautos..xcotizaciones xc WITH(NOLOCK) on xconv.origen = xc.idCotizacion
		left join xdim.autos.negocios nc WITH(NOLOCK) on xc.idNegocio = nc.cod_Negocio
		left join xautos..xpresupuestos xp WITH(NOLOCK) on xconv.Destino = xp.idPresupuesto
		left join xdim.autos.negocios np WITH(NOLOCK) on xp.idNegocio = np.cod_Negocio
	) A
	where A.idEmpresaOrigen = A.idEmpresaDestino and A.SegmentoOrigen = A.SegmentoDestino

	set @Msg='Inserción de Tauloipr(1b) en Tabla temporal generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0_auxPaso1'  
	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0_auxPaso1b'  


--Las tasaciones no graban tauloipr si no han pasado por presupuesto, podemos sacarlo de las 7 primeras posiciones de las observaciones de ains

	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0_auxPaso2'   
	select 
		null						as FecOrigen 
		,'V'						as Eorigen
		,s.idpresupuesto			as origen
		,null						as FecDestino
		,'P'						as Edestino
		,idpoliza					as Destino
		,2							as paso
		,'N'						as Extrapolacion --20140627
	into TMP.XAUTOS_DBO.Xconversiones0_auxPaso2
	from
		(
		select 
			max(ainspoli) as idpresupuesto
			,cast(left(ainsobs1,7) as int) as Idpoliza
		from 
			dw_autos..presupuestos_y_tasaciones_polizas WITH(NOLOCK)
		where 
			ainsobs1 like '[1-4][0-9][0-9][0-9][0-9][0-9][0-9]%'
			and ainspoli>=9000000
			and ainsswob='T'
			and ainssitu<>'A'
			and cast(left(ainsobs1,7) as int) >2850366
		group by 
			cast(left(ainsobs1,7) as int)
		) s

	
	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select FecOrigen, Eorigen, origen, FecDestino, Edestino, Destino, Paso, Extrapolacion  
	from (
		select xconv.*
			 , xv.idEmpresa as idEmpresaOrigen
			 , xpc.idEmpresa as idEmpresaDestino
			 , nv.cod_tiponegocioestrategico as SegmentoOrigen
			 , npi.cod_tiponegocioestrategico as SegmentoDestino
		from TMP.XAUTOS_DBO.Xconversiones0_auxPaso2 xconv WITH(NOLOCK)
		join xautos..xverificaciones xv WITH(NOLOCK) on xconv.origen = xv.idVerificacion
		left join xdim.autos.negocios nv WITH(NOLOCK) on xv.idNegocio = nv.cod_Negocio
		left join xautos..xpolizas_comun xpc WITH(NOLOCK) on xconv.Destino = xpc.apolclav
		left join xautos..xpolizas_imputacion xpi WITH(NOLOCK) on xconv.Destino = xpi.apolclav and xpi.PrimerMovimiento = 1
		left join xdim.autos.negocios npi WITH(NOLOCK) on xpi.idNegocio = npi.cod_Negocio
	) A
	where A.idEmpresaOrigen = A.idEmpresaDestino and A.SegmentoOrigen = A.SegmentoDestino

	set @Msg='Inserción de Tauloipr(2) en Tabla temporal generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0_auxPaso2'   


--cojo los datos de la tautlink (dw_autos..presupuestos_y_peritaje) la cual me define las conversiones de presupuestos o verificaciones a polizas
--en caso de existir duplicados tomamos siempre el que no tiene nota (generado por el sistema)

	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0_auxPaso3'   
	select
		--FechaEmision
		null				as FecOrigen 
		,'R'				as Eorigen
		,idpresupuesto		as origen
		,null				as FecDestino
		,'P'				as Edestino
		,idpoliza			as Destino
		,3					as paso
		,'N'				as Extrapolacion--20140627
	into TMP.XAUTOS_DBO.Xconversiones0_auxPaso3
	from
		(
		select
			 autlprpe as idpresupuesto
			,autlpoli as idpoliza
			,autlfumo as FechaEmision
		from
			dw_autos..TAUTLINK p1 WITH(NOLOCK)
			
		where 
			(autlprpe>=9000000)--9641884
			and autlpoli >= 2850366 and autlpoli < 8000000
			and autlpoli not in(2860633,2844949) -- Codigos de poliza no existentes(hablarlo con produccion)
		) s


	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select FecOrigen, Eorigen, origen, FecDestino, Edestino, Destino, Paso, Extrapolacion  
	from (
		select xconv.*
			 , xp.idEmpresa as idEmpresaOrigen
			 , xpc.idEmpresa as idEmpresaDestino
			 , np.cod_tiponegocioestrategico as SegmentoOrigen
			 , npi.cod_tiponegocioestrategico as SegmentoDestino
		from TMP.XAUTOS_DBO.Xconversiones0_auxPaso3 xconv WITH(NOLOCK)
		join xautos..xPresupuestos xp WITH(NOLOCK) on xconv.origen = xp.idPresupuesto
		left join xdim.autos.negocios np WITH(NOLOCK) on xp.idNegocio = np.cod_Negocio
		left join xautos..xpolizas_comun xpc WITH(NOLOCK) on xconv.Destino = xpc.apolclav
		left join xautos..xpolizas_imputacion xpi WITH(NOLOCK) on xconv.Destino = xpi.apolclav and xpi.PrimerMovimiento = 1
		left join xdim.autos.negocios npi WITH(NOLOCK) on xpi.idNegocio = npi.cod_Negocio
	) A
	where A.idEmpresaOrigen = A.idEmpresaDestino and A.SegmentoOrigen = A.SegmentoDestino

	set @Msg='Inserción de Tautlik en Tabla temporal generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0_auxPaso3'   	


--Las transiciones de presupuesto a verificacion  

	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select
		case when xv.FecEmision<xp.fecemision then xv.FecEmision else xp.fecemision end 
		,case when xv.FecEmision<xp.fecemision then 'V' else 'R' end 
		,idverificacion
		,case when xv.FecEmision<xp.fecemision then xp.FecEmision else xv.fecemision end 
		,case when xv.FecEmision<xp.fecemision then 'R' else 'V' end 
		,idverificacion
		,10 as paso
		,'N' as Extrapolacion--20140627
	from xautos..xverificaciones xv WITH(NOLOCK)
	inner join xautos..xpresupuestos xp WITH(NOLOCK) on xv.idverificacion=xp.idpresupuesto
	left join xdim.autos.Negocios N1 on xv.idNegocio = N1.Cod_Negocio
	left join xdim.autos.Negocios N2 on xp.idNegocio = N2.Cod_Negocio
 	where xv.idEmpresa = xp.idEmpresa and N1.cod_tiponegocioestrategico = N2.cod_tiponegocioestrategico 
		
	set @Msg='Transicciones de presupuesto<-->Verificacion: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	 

-- Añadimos las Transiciones de las cotizaciones web a poliza
 
	--calculo todas la nueva producción del periodo con su checksum para simplificar el cruce 
	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones_Web_NP' 
	select 
		niftomador
		,marca
		,modelo
		,convert(char(6),fnactomador, 112) as fnactomador
		,cast(codpostal as int) as codpostal
		,cast(sexotomador as int) as sexotomador
		,xpc.apolclav as Destino
		,cast(convert(varchar(8),xpc.FechaContratacion,112)+ ' '+isnull(nullif(xpc.HoraEmision,'00:00:00.000'),'23:59:59.000') as datetime) as FechaDestino -- en caso de no tener hora las llevamos a ultima hora para no perderlas si se hace la cotizacion el mismo dia
		,CanalEntrada
		,'P' as EDestino
		,case when FnacTomador is null 	or codpostal is null then 0 else 1 end as Comparable
		,xpc.idEmpresa
		,N.cod_tiponegocioestrategico
	into
		TMP.XAUTOS_DBO.Xconversiones_Web_NP
	from
		xautos..xpolizas_comun xpc WITH(NOLOCK)
	inner join
		xautos..xpolizas_imputacion xpi WITH(NOLOCK)
	on
		xpc.apolclav=xpi.apolclav
		and xpi.primermovimiento=1
	inner join 
		xautos..marcas m WITH(NOLOCK)
	on
		xpi.idmodelo=m.id
	inner join
		xdim.autos.productos ap WITH(NOLOCK)
	on
		xpi.producto=ap.producto
	left join xdim.autos.Negocios N on xpi.idNegocio = N.Cod_Negocio
	where
		xpc.Fechacontratacion>='20070901'
		and xpc.apolclav<8000000
		and ap.distribuidor='MM'
		--and xpc.apolclav=3131920 		
	--option(recompile)
	
	
 
 	
	set @Msg='Xconversiones_Web_NP (polizas) generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	
	insert into TMP.XAUTOS_DBO.Xconversiones_Web_NP with (tablock)
	select 
		niftomador
		,marca
		,modelo
		,convert(char(6),fnactomador, 112) as fnactomador
		,cast(codpostal as int) as codpostal
		,cast(sexotomador as int) as sexotomador
		,IdPresupuesto As Destino
		,FecEmision as FechaDestino
		,CanalEntrada
		,'R' as EDestino
		,case when FnacTomador is null 	or codpostal is null then 0 else 1 end as Comparable
		,xp.idEmpresa
		,N.cod_tiponegocioestrategico
	from
		xautos..xpresupuestos xp WITH(NOLOCK)
	inner join 
		xautos..marcas m WITH(NOLOCK)
	on
		xp.idmodelo=m.id		
	left join xdim.autos.Negocios N	on xp.idNegocio = N.Cod_Negocio	
	--option(recompile)

	
	set @Msg='Xconversiones_Web_NP (presupuestos) generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	 

	insert into TMP.XAUTOS_DBO.Xconversiones_Web_NP with (tablock)
	select 
		niftomador
		,marca
		,modelo
		,convert(char(6),fnactomador, 112) as fnactomador
		,cast(codpostal as int) as codpostal
		,cast(sexotomador as int) as sexotomador
		
		,IdVerificacion As Destino
		,FecEmision as FechaDestino
		,CanalEntrada
		,'V' as EDestino
		,case when FnacTomador is null 	or codpostal is null then 0 else 1 end as Comparable
		,xp.idEmpresa
		,N.cod_tiponegocioestrategico
	from
		xautos..xverificaciones xp WITH(NOLOCK)
	inner join 
		xautos..marcas m WITH(NOLOCK)
	on
		xp.idmodelo=m.id		
	left join xdim.autos.Negocios N on xp.idNegocio = N.Cod_Negocio
		
	set @Msg='Xconversiones_Web_NP (verificaciones) generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	create index ix1 on TMP.XAUTOS_DBO.Xconversiones_Web_NP(niftomador,FechaDestino) include (Destino,Edestino)
	create index ix2 on TMP.XAUTOS_DBO.Xconversiones_Web_NP(marca,modelo,fnactomador,codpostal,sexotomador,FechaDestino)  include (Destino,Edestino)
	
	set @Msg='Creación de indices TMP.XAUTOS_DBO.Xconversiones_Web_NP'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	

	-- 09/10/2014. Se descartan en la extrapolación las cotizaciones que 
	-- sean realmente errores. Si se consideran los avisos (errores en los que se alncanza prima).
	-- Vamos a cargar una tabla de Cotizaciones inicial con los datos que necesitamos.
	
	exec comun..eliminatabla 'TMP.XAUTOS_DBO.XCotizaciones_SinError'
	SELECT xc.IdCotizacion
		 , xc.FecEmision
		 , xc.NifTomador
		 , xc.Fnactomador
		 , xc.codpostal
		 , xc.sexotomador
		 , xc.IdModelo
		 , xc.idEmpresa
		 , N.cod_tiponegocioestrategico
	INTO TMP.XAUTOS_DBO.XCotizaciones_SinError
	FROM XAUTOS.dbo.XCOTIZACIONES xc WITH(NOLOCK)	
	left join xdim.autos.Negocios N WITH(NOLOCK) on xc.idNegocio = N.Cod_Negocio
	WHERE CanalEntrada = 'W' AND (CodErrorCotiz = 0  or CodErrorCotiz = 3031)-- No errores. --Marginales
	    	
	create index ix2 on TMP.XAUTOS_DBO.XCotizaciones_SinError(NifTomador,FecEmision)

	set @Msg='Creación de indices TMP.XAUTOS_DBO.XCotizaciones_SinError'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	

	--calculo los cruces por nif directo
	-- 08/07/2013
	-- Vamos a separar el Or y lanzar dos consultas.
	
	-- 02/10/2014. Se descartan en la extrapolación las cotizaciones que 
	-- sean realmente errores. Si se consideran los avisos (errores en los que se alncanza prima).
	
	
	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select
		c.fecEmision 
		,'C' 
		,c.Idcotizacion--codigo
		,xp.FechaDestino		
		,xp.EDestino
		,xp.Destino
		,8 as paso
		,'S' as Extrapolacion--20140627
	from
		TMP.XAUTOS_DBO.XCotizaciones_SinError c WITH(NOLOCK)
	inner join
		TMP.XAUTOS_DBO.Xconversiones_Web_NP xp WITH(NOLOCK)
	on
		xp.niftomador=c.NifTomador --por nif directo
		and xp.FechaDestino between cast(c.FecEmision as datetime) and dateadd(dd,89,c.fecEmision) 
		and xp.CanalEntrada<>'W'
	where
	--ya se ha filtrado en la tabla temporal
	--	c.CanalEntrada='W' and 
		c.niftomador not like '#%'
		and c.idEmpresa = xp.idEmpresa and c.cod_tiponegocioestrategico = xp.cod_tiponegocioestrategico


 	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select
		c.fecEmision 
		,'C'
		,c.Idcotizacion--codigo
		,xp.FechaDestino		
		,xp.EDestino
		,xp.Destino
		,8 as paso
		,'S' as Extrapolacion--20140627
	from
		TMP.XAUTOS_DBO.XCotizaciones_SinError c WITH(NOLOCK)
	inner join
		TMP.XAUTOS_DBO.Xconversiones_Web_NP xp WITH(NOLOCK)
	on
		xp.niftomador=c.NifTomador --por nif directo
		and xp.FechaDestino between cast(c.FecEmision as datetime) and dateadd(dd,7,c.fecEmision) 
		and xp.CanalEntrada='W'
	where
		--ya se ha filtrado en la tabla temporal
		--c.CanalEntrada='W' and 
		c.niftomador not like '#%'
		and c.idEmpresa = xp.idEmpresa and c.cod_tiponegocioestrategico = xp.cod_tiponegocioestrategico
 
/*
 	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select
		c.fecEmision 
		,'C'
		,c.Idcotizacion--codigo
		,xp.FechaDestino		
		,xp.EDestino
		,xp.Destino
		,8 as paso
				
	from
		xautos.dbo.xcotizaciones c WITH(NOLOCK)
	inner join
		TMP.XAUTOS_DBO.Xconversiones_Web_NP xp WITH(NOLOCK)
	on
		(
		xp.niftomador=c.NifTomador --por nif directo
		)
		and 
			(
			(xp.FechaDestino between cast(c.FecEmision as datetime) and dateadd(dd,89,c.fecEmision) and xp.CanalEntrada<>'W')
			or
			(xp.FechaDestino between cast(c.FecEmision as datetime) and dateadd(dd,7,c.fecEmision) and xp.CanalEntrada='W')
			)
	where
		c.CanalEntrada='W'
		and c.niftomador not like '#%'
 */
 
	
	set @Msg='Inserción de conversiones Web(por nif) en Tabla temporal generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

  

	--por comparación	
	-- 08/07/2013
	-- Extraemos la subconsulta inicialmente a una tabla.
	exec comun..EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0_1'
	SELECT 
			idcotizacion
			,FecEmision
			,marca
			,modelo
			,convert(char(6),fnactomador, 112) as fnactomador
			,cast(codpostal as int) as codpostal
			,cast(sexotomador as int) as sexotomador
			,xc.idEmpresa
		    ,xc.cod_tiponegocioestrategico

		INTO TMP.XAUTOS_DBO.Xconversiones0_1
		from
			TMP.XAUTOS_DBO.XCotizaciones_SinError xc WITH(NOLOCK)
		inner join
			xautos.dbo.marcas m WITH(NOLOCK)
		on
			xc.idmodelo=m.id
		--ya se ha filtrado en la tabla temporal
		/*where
			CanalEntrada='W'*/
			
	--1min47
	create index ix1 on TMP.XAUTOS_DBO.Xconversiones0_1(marca,modelo,fnactomador,codpostal,sexotomador,fecEmision) 
	--1min15
	
	-- 08/07/2013
	--Vamos a separar el Or y lanzar dos consultas.		
	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select
		c.fecEmision 
		,'C'
		,c.Idcotizacion--codigo
		,xp.FechaDestino		
		,xp.EDestino
		,xp.Destino
		,9 as paso
		,'S' as Extrapolacion--20140627
	from TMP.XAUTOS_DBO.Xconversiones0_1 c WITH(NOLOCK)	inner join	TMP.XAUTOS_DBO.Xconversiones_Web_NP xp WITH(NOLOCK)
	on
		xp.marca = c.marca
		and xp.modelo = c.modelo
		and xp.fnactomador = c.fnactomador
		and xp.codpostal = c.codpostal
		and xp.sexotomador = c.sexotomador
		and xp.FechaDestino between cast(c.FecEmision as datetime) and dateadd(dd,89,c.fecEmision) 
		and xp.CanalEntrada<>'W'
	 where
	    --si se genera a nulo en marca, modelo, fnactomador, codpostal o sexotomador es que falta algún dato.
		xp.marca is not null
		and xp.modelo is not null
		and xp.fnactomador is not null
		and xp.codpostal is not null
		and xp.sexotomador is not null
		and c.marca is not null
		and c.modelo is not null
		and c.fnactomador is not null
		and c.codpostal is not null
		and c.sexotomador is not null
		and c.idEmpresa = xp.idEmpresa and c.cod_tiponegocioestrategico = xp.cod_tiponegocioestrategico
	--21seg
		
	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select
		c.fecEmision 
		,'C'
		,c.Idcotizacion--codigo
		,xp.FechaDestino		
		,xp.EDestino
		,xp.Destino
		,9 as paso
		,'S' as Extrapolacion--20140627
	from TMP.XAUTOS_DBO.Xconversiones0_1 c WITH(NOLOCK)	inner join	TMP.XAUTOS_DBO.Xconversiones_Web_NP xp WITH(NOLOCK)
	on
		xp.marca = c.marca
		and xp.modelo = c.modelo
		and xp.fnactomador = c.fnactomador
		and xp.codpostal = c.codpostal
		and xp.sexotomador = c.sexotomador
		and xp.FechaDestino between cast(c.FecEmision as datetime) and dateadd(dd,7,c.fecEmision) 
		and xp.CanalEntrada='W'
	 where
	   --si se genera a nulo en marca, modelo, fnactomador, codpostal o sexotomador es que falta algún dato.
		xp.marca is not null
		and xp.modelo is not null
		and xp.fnactomador is not null
		and xp.codpostal is not null
		and xp.sexotomador is not null
		and c.marca is not null
		and c.modelo is not null
		and c.fnactomador is not null
		and c.codpostal is not null
		and c.sexotomador is not null
		and c.idEmpresa = xp.idEmpresa and c.cod_tiponegocioestrategico = xp.cod_tiponegocioestrategico


/*
	insert into TMP.XAUTOS_DBO.Xconversiones0 with (tablock)
	select
		c.fecEmision 
		,'C'
		,c.Idcotizacion--codigo
		,xp.FechaDestino		
		,xp.EDestino
		,xp.Destino
		,9 as paso
	from
		(
		select
			idcotizacion
			,FecEmision
			,						  cast(1000000000000000000 as decimal(30,0))
			+cast(marca as smallint) *cast(1000000000000000 as decimal(30,0))
			+cast(modelo as smallint)*cast(1000000000000  as decimal(30,0))
			+year(fnactomador)       *cast(100000000  as decimal(30,0))
			+month(fnactomador)      *cast(1000000 as decimal(30,0))
			+cast(codpostal as int)  *cast(10  as decimal(30,0))
			+cast(sexotomador as decimal(30,0)) as CHK
		from
			xautos.dbo.xcotizaciones xc WITH(NOLOCK)
		inner join
			xautos.dbo.marcas m WITH(NOLOCK)
		on
			xc.idmodelo=m.id
		where
			CanalEntrada='W'
		) c
	inner join
		TMP.XAUTOS_DBO.Xconversiones_Web_NP xp WITH(NOLOCK)
	on
		xp.[Chk]=c.[Chk] 
		and 
			(
			(xp.FechaDestino between cast(c.FecEmision as datetime) and dateadd(dd,89,c.fecEmision) and xp.CanalEntrada<>'W')
			or
			(xp.FechaDestino between cast(c.FecEmision as datetime) and dateadd(dd,7,c.fecEmision) and xp.CanalEntrada='W')
			)
	 where
		xp.chk is not null and c.chk is not null --si se genera a nulo el chk es que falta algun dato
		
*/
 		
	set @Msg='Inserción de conversiones Web(por comparacion) en Tabla temporal generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

  


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--CORRECCIONES
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
	

--A lo largo del proceso puedo haber insertado como presupuesto verificaciones las corrigo


	update
		t
	set 
		EOrigen='V'
	from
		TMP.XAUTOS_DBO.Xconversiones0 t
	where
		(eorigen in ('R') and not exists(select 1 from xautos.dbo.xpresupuestos xp WITH(NOLOCK) where t.origen=xp.idpresupuesto))
		

	set @Msg='Presupuestos pasados a verificacion en origen: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1		

			
	update
		t
	set 
		Edestino='V'
	from
		TMP.XAUTOS_DBO.Xconversiones0 t
	where
		(Edestino in ('R') and not exists(select 1 from xautos.dbo.xpresupuestos xp WITH(NOLOCK) where t.destino=xp.idpresupuesto))
		
		
	set @Msg='Presupuestos pasados a verificacion en destino: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1		

	
	
	
--Elimino los registros que no tiene IR correcta con las xpolizas,xpresupuestos, etc (son muy pocos)
	
	set @Msg='Inicio borrados por errores de IR.'--: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	declare @TotalEliminados as int = 0

	--08/07/2013
 	--Separamos los borrados

	--***Origen Presupuestos
 	delete t
	--select count(*)		
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where (eorigen = 'R' and  not exists(select 1 from xautos.dbo.xpresupuestos xp WITH(NOLOCK) where t.origen=xp.idpresupuesto))

	/*
	select count(*)		
	--select top 1 *
	from TMP.XAUTOS_DBO.Xconversiones0 t
		left join xautos.dbo.xpresupuestos xp
			on t.origen=xp.idpresupuesto
	where t.eorigen in ('R') 
		and xp.idpresupuesto is null
		--and  not exists(select 1 from xautos.dbo.xpresupuestos xp WITH(NOLOCK) where t.origen=xp.idpresupuesto)
	*/
	set @filas = @@rowcount
	set @TotalEliminados = @TotalEliminados + @filas
	set @Msg='···Eliminamos <eOrigen=R>: '+cast(@filas as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	--***Origen Verificaciones
	delete t
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where (eorigen = 'V' and not exists(select 1 from xautos.dbo.xverificaciones xv WITH(NOLOCK) where t.origen=xv.idverificacion) )

	set @filas = @@rowcount
	set @TotalEliminados = @TotalEliminados + @filas
	set @Msg='···Eliminamos <eOrigen=V>: '+cast(@filas as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	--***Origen CotizaciRones
	delete t
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where (eorigen = 'C' and not exists(select 1 from xautos.dbo.xcotizaciones xc WITH(NOLOCK) where t.origen=xc.idcotizacion))

	set @filas = @@rowcount
	set @TotalEliminados = @TotalEliminados + @filas
	set @Msg='···Eliminamos <eOrigen=C>: '+cast(@filas as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	--***Origen Pólizas
	delete t
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where (eorigen = 'P' and not exists(select 1 from xautos.dbo.xpolizas_comun xp WITH(NOLOCK) where t.origen=xp.apolclav))

	set @filas = @@rowcount
	set @TotalEliminados = @TotalEliminados + @filas
	set @Msg='···Eliminamos <eOrigen=P>: '+cast(@filas as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	--***Destino Presupuestos
	delete t
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where (edestino = 'R' and  not exists(select 1 from xautos.dbo.xpresupuestos xp WITH(NOLOCK) where t.destino=xp.idpresupuesto))
	
	set @filas = @@rowcount
	set @TotalEliminados = @TotalEliminados + @filas
	set @Msg='···Eliminamos <eDestino=R>: '+cast(@filas as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	--***Destino Verificaciones
	delete t
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where (edestino = 'V' and not exists(select 1 from xautos.dbo.xverificaciones xv WITH(NOLOCK) where t.destino=xv.idverificacion) )

	set @filas = @@rowcount
	set @TotalEliminados = @TotalEliminados + @filas
	set @Msg='···Eliminamos <eDestino=V>: '+cast(@filas as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	--***Destino Cotizaciones
	delete t
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where (edestino = 'C' and not exists(select 1 from xautos.dbo.xcotizaciones xc WITH(NOLOCK) where t.destino=xc.idcotizacion))
	
	set @filas = @@rowcount
	set @TotalEliminados = @TotalEliminados + @filas
	set @Msg='···Eliminamos <eDestino=C>: '+cast(@filas as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	--***Destino Pólizas
	delete t
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where (edestino = 'P' and not exists(select 1 from xautos.dbo.xpolizas_comun xp WITH(NOLOCK) where t.destino=xp.apolclav))

	set @filas = @@rowcount
	set @TotalEliminados = @TotalEliminados + @filas
	set @Msg='···Eliminamos <eDestino=P>: '+cast(@filas as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
				 
 	/*	
	delete 
		t
	from
		TMP.XAUTOS_DBO.Xconversiones0 t
	where
		(eorigen in ('R') and  not exists(select 1 from xautos.dbo.xpresupuestos xp WITH(NOLOCK) where t.origen=xp.idpresupuesto))
		or		
		(eorigen in ('V') and not exists(select 1 from xautos.dbo.xverificaciones xv WITH(NOLOCK) where t.origen=xv.idverificacion) )
		or 
		(eorigen='C' and not exists(select 1 from xautos.dbo.xcotizaciones xc WITH(NOLOCK) where t.origen=xc.idcotizacion))
		or
		(eorigen='P' and not exists(select 1 from xautos.dbo.xpolizas_comun xp WITH(NOLOCK) where t.origen=xp.apolclav))
		or
		(edestino in ('R') and  not exists(select 1 from xautos.dbo.xpresupuestos xp WITH(NOLOCK) where t.destino=xp.idpresupuesto))
		or 
		(edestino in ('V') and not exists(select 1 from xautos.dbo.xverificaciones xv WITH(NOLOCK) where t.destino=xv.idverificacion) )
		or
		(edestino='C' and not exists(select 1 from xautos.dbo.xcotizaciones xc WITH(NOLOCK) where t.destino=xc.idcotizacion))
		or
		(edestino='P' and not exists(select 1 from xautos.dbo.xpolizas_comun xp WITH(NOLOCK) where t.destino=xp.apolclav))
	*/
		
	set @Msg='Registros eliminados por errores de IR: '+cast(@TotalEliminados as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
	
	
	

--Para simplificar los procesos de insercción hemos permitido fechas a null, las rellenamos ahora

	update t set
		t.FecOrigen=case 
							when Eorigen='C' then (select FecEmision from xautos.dbo.xcotizaciones s WITH(NOLOCK) where s.idcotizacion=t.origen)
							when Eorigen in('V','R') then comun.dbo.menorFecha((select FecEmision from xautos.dbo.xverificaciones s WITH(NOLOCK) where s.idverificacion=t.origen),(select FecEmision from xautos.dbo.xpresupuestos s WITH(NOLOCK) where s.idpresupuesto=t.origen))
							when Eorigen='P' then (select  convert(varchar(8),fechacontratacion,112)+' '+HoraEmision from xautos.dbo.xpolizas_comun s WITH(NOLOCK) where s.apolclav=t.origen)
					 end
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where FecOrigen is null
		and EOrigen is not null
				
	set @Msg='Fechas de origen rellenadas: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
		
 
						
	update t set
		t.FecDestino=case 
							when Edestino='C' then (select FecEmision from xautos.dbo.xcotizaciones s WITH(NOLOCK) where s.idcotizacion=t.destino)
							when Edestino in('V','R') then comun.dbo.menorFecha((select FecEmision from xautos.dbo.xverificaciones s WITH(NOLOCK) where s.idverificacion=t.destino),(select FecEmision from xautos.dbo.xpresupuestos s WITH(NOLOCK) where s.idpresupuesto=t.destino))
							when Edestino='P' then (select convert(varchar(8),fechacontratacion,112)+' '+HoraEmision from xautos.dbo.xpolizas_comun s WITH(NOLOCK) where s.apolclav=t.destino)
					 end
	from TMP.XAUTOS_DBO.Xconversiones0 t
	where FecDestino is null
		and EDestino is not null
		
	
		
		
	set @Msg='Fechas de destino rellenadas: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1		

	--select * from TMP.XAUTOS_DBO.Xconversiones0  where fecdestino is null or fecorigen is null
	
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--Comienzo a elimar duplicados y a priorizar por fecha
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	create index ix1 on TMP.XAUTOS_DBO.Xconversiones0 (origen,eorigen,destino,edestino,FecOrigen,FecDestino,id)
	create index ix2 on TMP.XAUTOS_DBO.Xconversiones0 (destino,edestino)


--si dos pasos han generado la misma linea borro una de ellas
	delete t1
 	from TMP.XAUTOS_DBO.Xconversiones0 t1
	where exists (select 1 
					from TMP.XAUTOS_DBO.Xconversiones0 t2 WITH(NOLOCK)
					where t1.Eorigen	= t2.Eorigen
						and t1.origen	= t2.origen
						and t1.edestino	= t2.edestino
						and t1.destino	= t2.destino
						and t2.id		< t1.id
				)  
				
	set @Msg='Eliminados por duplicados totales: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1	
	
 
--cuando un origen tiene mas de un destino me quedo con el primero ( esto provoca que la cotización muera en presupuesto, verif. o póliza
	delete t1
	from TMP.XAUTOS_DBO.Xconversiones0 t1
	where origen is not null
		and exists (select 1 
					from TMP.XAUTOS_DBO.Xconversiones0 t2 WITH(NOLOCK)
					where 
						t1.id			<> t2.id
						and t1.Eorigen	=  t2.Eorigen
						and t1.origen	=  t2.origen
						and 
							(
							isnuLL(t2.fecdestino,'20501231')<isnuLL(t1.fecdestino,'20501231')
							or 
								(
								isnuLL(t2.fecdestino,'20501231')=isnuLL(t1.fecdestino,'20501231')
								and
									(
									t2.edestino<t1.edestino --me sirve usar < al ser el orden P,R,V
									or 
									(t2.edestino=t1.edestino and t2.destino<t1.destino)
									)	
								)
							)
					)  
		 	
					
	set @Msg='Eliminados por duplicados para el mismo origen: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1	

	
--cuando un destino tiene mas de un origen del mismo tipo me quedo con el primero
	delete
		t1
	from
		TMP.XAUTOS_DBO.Xconversiones0 t1
	where
		destino is not null
		and exists (select 
						1 
					from 
						TMP.XAUTOS_DBO.Xconversiones0 t2 WITH(NOLOCK)
					where 
						t1.id<>t2.id
						and t1.EDestino=t2.Edestino 
						and t1.destino=t2.destino 
						and 
							(
							isnuLL(t2.fecorigen,'20501231')<isnuLL(t1.fecorigen,'20501231')
							or 
								(
								isnuLL(t2.fecorigen,'20501231')=isnuLL(t1.fecorigen,'20501231')
								and
									(
									t2.eorigen<t1.eorigen --me sirve usar < al ser el orden C,P,R,V
									or 
									(t2.eorigen=t1.eorigen and t2.origen<t1.origen)
									)	
								)
							)						
						
				)  
				
	set @Msg='Eliminados por duplicados para el mismo destino: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1	


	--para garantizar la unicidad de la clave
	create unique index ixu1 on TMP.XAUTOS_DBO.Xconversiones0 (eorigen,origen)
	create unique index ixu2 on TMP.XAUTOS_DBO.Xconversiones0 (edestino,destino)
	
 
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--Genero la tabla Intermedia
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

--cruces entre estados (todo lo que hemos estado haciendo)
	exec comun..eliminatabla 'TMP.XAUTOS_DBO.Xconversiones1'
	
/*******************************************************************************************************************
GEMMA:
IdConversion es de tipo bigInt, no Int
*******************************************************************************************************************/	
	create table TMP.XAUTOS_DBO.Xconversiones1 (IdConversion bigint identity(1,1),IdCotizacion decimal(20,0),IdPresupuesto int,IdVerificacion int,IdPoliza int,EstadoInicial varchar(1),EstadoFinal varchar(1),Extrapolacion varchar(1),F_carga smalldatetime)

	insert into TMP.XAUTOS_DBO.Xconversiones1 with (tablock)
	select
		case 
			when t1.EOrigen='C' then t1.Origen
			when t1.EDestino='C' then t1.Destino
			when t2.EOrigen='C' then t2.Origen
			when t2.EDestino='C' then t2.Destino
			when t3.EOrigen='C' then t3.Origen
			when t3.EDestino='C' then t3.Destino
			when t4.EOrigen='C' then t4.Origen
			when t4.EDestino='C' then t4.Destino
			else null
		end as IdCotizacion
		,case 
			when t1.EOrigen='R' then t1.Origen
			when t1.EDestino='R' then t1.Destino
			when t2.EOrigen='R' then t2.Origen
			when t2.EDestino='R' then t2.Destino
			when t3.EOrigen='R' then t3.Origen
			when t3.EDestino='R' then t3.Destino
			when t4.EOrigen='R' then t4.Origen
			when t4.EDestino='R' then t4.Destino
			else null
		end as IdPresupuesto
		,case 
			when t1.EOrigen='V' then t1.Origen
			when t1.EDestino='V' then t1.Destino
			when t2.EOrigen='V' then t2.Origen
			when t2.EDestino='V' then t2.Destino
			when t3.EOrigen='V' then t3.Origen
			when t3.EDestino='V' then t3.Destino
			when t4.EOrigen='V' then t4.Origen
			when t4.EDestino='V' then t4.Destino
			else null
		end as IdVerificacion
		,case 
			when t1.EOrigen='P' then t1.Origen
			when t1.EDestino='P' then t1.Destino
			when t2.EOrigen='P' then t2.Origen
			when t2.EDestino='P' then t2.Destino
			when t3.EOrigen='P' then t3.Origen
			when t3.EDestino='P' then t3.Destino
			when t4.EOrigen='P' then t4.Origen
			when t4.EDestino='P' then t4.Destino
			else null
		end as IdPoliza
		,t1.eorigen as EstadoInicial
		,coalesce(t4.edestino,t4.eorigen,t3.edestino,t3.eorigen,t2.edestino,t2.eorigen,t1.edestino,t1.eorigen) as EstadoFinal
		,case 	
			when (t1.Extrapolacion='S' and t1.EDestino ='P')
			or (t2.Extrapolacion='S' and t2.EDestino ='P')
			or (t3.Extrapolacion='S' and t3.EDestino ='P')
			or (t4.Extrapolacion='S' and t4.EDestino ='P')
			then 'S'
			else 'N'
		end as Extrapolacion -- 20140627
		,getdate() as F_carga
	from
		TMP.XAUTOS_DBO.Xconversiones0 t1   WITH(NOLOCK)
	left join
		TMP.XAUTOS_DBO.Xconversiones0 t2  WITH(NOLOCK)
	on
		t1.edestino=t2.eorigen
		and t1.destino=t2.origen
	left join
		TMP.XAUTOS_DBO.Xconversiones0 t3  	WITH(NOLOCK)
	on
		t2.edestino=t3.eorigen
		and t2.destino=t3.origen
	left join
		TMP.XAUTOS_DBO.Xconversiones0 t4  	WITH(NOLOCK)
	on
		t3.edestino=t4.eorigen
		and t3.destino=t4.origen
	where
		not exists(select 1 from TMP.XAUTOS_DBO.Xconversiones0 tx WITH(NOLOCK) where tx.edestino=t1.eorigen and tx.destino=t1.origen) -- sólo el movimiento inicial
		
	set @Msg='Tabla Final Generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	
-- cojo los datos de presupuestos que no han tenido conversion

	insert into TMP.XAUTOS_DBO.Xconversiones1 with (tablock)
	select 
		null as IdCotizacion
		,IdPresupuesto
		,null as IdVerificacion
		,null as IdPoliza
		,'R'
		,'R'
		,'N' -- 20140627
		,getdate() as F_carga
	from 
		xautos..XPresupuestos xp WITH(NOLOCK)
	where 
		FecEmision>='20070901'
		and not exists(select 1 from TMP.XAUTOS_DBO.Xconversiones1 t WITH(NOLOCK) where t.idpresupuesto=xp.idpresupuesto)

	set @Msg='Inserción de Xpresupuestos en Tabla Final: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1



-- cojo los datos de polizas que no han tenido conversion
	
	insert into TMP.XAUTOS_DBO.Xconversiones1 with (tablock)
	select 
		null as IdCotizacion
		,null as IdPresupuesto
		,null as IdVerificacion
		,apolclav as IdPoliza
		,'P'
		,'P'
		,'N' -- 20140627
		,getdate() as F_carga
	from 
		xautos..XPolizas_comun XP WITH(NOLOCK)
	where 
		fechacontratacion>='20070901'
		and not exists(select 1 from TMP.XAUTOS_DBO.Xconversiones1 t WITH(NOLOCK) where t.idpoliza=xp.apolclav)
	
	set @Msg='Inserción de Xpolizas_comun en Tabla Final: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1


-- cojo los datos de verificaciones que no han tenido conversion
	
	insert into TMP.XAUTOS_DBO.Xconversiones1 with (tablock)
	select 
		null as IdCotizacion
		,null as IdPresupuesto
		,IdVerificacion as IdVerificacion
		,null as IdPoliza
		,'V'
		,'V'
		,'N' -- 20140627
		,getdate() as F_carga
	from 
		xautos..XVerificaciones xv WITH(NOLOCK)
	where 
		fecEmision>='20070901' 
		and	idverificacion > 9000000
		--and	idverificacion between 9000000 and 11000000 
		and not exists(select 1 from TMP.XAUTOS_DBO.Xconversiones1 t WITH(NOLOCK) where t.idverificacion=xv.idverificacion)

	set @Msg='Inserción de XVerificaciones en Tabla Final: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	

--cojo los datos de cotizaciones que no han tenido conversion

-- 02/10/2014. Vamos a grabar en XConversiones tambien las cotizaciones con error, pero siempre
-- deberían aparecer como sin conversión (si el algoritmo está bien realizado).

	insert into TMP.XAUTOS_DBO.Xconversiones1 with (tablock)
	select 	
		IdCotizacion
		,null as IdPresupuesto
		,null as IdVerificacion
		,null as IdPoliza
		,'C'
		,'C'
		,'N' -- 20140627
		,getdate() as F_carga
	from 
		xautos.dbo.xcotizaciones xc WITH(NOLOCK)
	where 
		fecEmision>='20070901' 
		and not exists(select 1 from TMP.XAUTOS_DBO.Xconversiones1 t WITH(NOLOCK) where t.idcotizacion=xc.idcotizacion)
		
	set @Msg='Inserción de Xcotizaciones en Tabla Final: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
			
		
/*--------------------------------------------------------------------------------------------------------------------
Creamos los índices de la tabla temporal para optimizar las consultas en busca de la nueva clave.
-- 11/08/2011 Cambiada la creación de estos índices. 
--------------------------------------------------------------------------------------------------------------------*/

	-- 08/09/2016 Quitamos include de la creación de índices y estudiaremos si mejora el rendimiento
	/*
	create index ix1 on  TMP.XAUTOS_DBO.Xconversiones1	(IDcotizacion)	include (IDCONVERSION)
	create index ix2 on  TMP.XAUTOS_DBO.Xconversiones1	(idpresupuesto)	include (IDCONVERSION)
	create index ix3 on  TMP.XAUTOS_DBO.Xconversiones1	(idverificacion)	include (IDCONVERSION)
	create index ix4 on  TMP.XAUTOS_DBO.Xconversiones1	(idpoliza)	include (IDCONVERSION)
	*/
	
	create index ix1 on  TMP.XAUTOS_DBO.Xconversiones1	(IDcotizacion) WITH (SORT_IN_TEMPDB = ON)
	create index ix2 on  TMP.XAUTOS_DBO.Xconversiones1	(idpresupuesto)	
	create index ix3 on  TMP.XAUTOS_DBO.Xconversiones1	(idverificacion)
	create index ix4 on  TMP.XAUTOS_DBO.Xconversiones1	(idpoliza)	
	
	set @Msg='Indices creados en Tabla Final'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- Ya tenemos los datos completos, vamos a asignarles la clave que les corresponde: 
--    La que tenían ayer
--    Una nueva si no tenían
--    Una marca para borrar el registro.
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- Creamos la tabla de cartera : los datos a actualizar. Tenemos que buscar la clave actual para los datos a actualizar.
-- ATENCION : Esta consulta ha dado algún problema si el disco que aloja TMP está fragmentado: en ese caso se puede 
-- optar por modificar la consulta por una de este tipo: (Resumen)
-- 1. SELECT .. into TMP.XAUTOS_dbo.Xconversiones_Cartera from XAUTOS..XConversiones XCLA CROSS APPLY (TMP.XAUTOS_DBO.Xconversiones1 TMPA WHERE XCLA.IDCOTIZACION = TMPA.IDCOTIZACION)
-- 2. UPDATE TMP.XAUTOS_dbo.Xconversiones_Cartera XCLA INNER JOIN/CROSS APPLY TMP.XAUTOS_DBO.Xconversiones1 TMPB WITH(NOLOCK) ON	XCLA.IDPRESUPUESTO = TMPB.IDPRESUPUESTO WHERE XCLA.IDCOTIZACION IS NULL 
-- 3. UPDATE TMP.XAUTOS_dbo.Xconversiones_Cartera XCLA INNER JOIN/CROSS APPLY TMP.XAUTOS_DBO.Xconversiones1 TMPB WITH(NOLOCK) ON	XCLA.IDVERIFICACION = TMPB.IDVERIFICACION WHERE XCLA.IDCOTIZACION IS NULL 
-- 4. UPDATE TMP.XAUTOS_dbo.Xconversiones_Cartera XCLA INNER JOIN/CROSS APPLY TMP.XAUTOS_DBO.Xconversiones1 TMPB WITH(NOLOCK) ON	XCLA.IDPOLIZA = TMPB.IDPOLIZA WHERE XCLA.IDCOTIZACION IS NULL 

--11/08/2011 Incluido option(recompile)

-- 28/03/2016  GPM  Modificada consulta para optimización de los tiempos. Crisis cargas BI.
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	/*
	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Cartera'   	
	SELECT 
		XCLA.IDCONVERSION, 
		COALESCE(TMPA.IDCONVERSION,TMPB.IDCONVERSION,TMPC.IDCONVERSION,TMPD.IDCONVERSION) AS IdConversion_Aux
	INTO TMP.XAUTOS_dbo.Xconversiones_Cartera
	FROM
		[XAUTOS].[dbo].[Xconversiones]  XCLA WITH(NOLOCK) LEFT JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPA WITH(NOLOCK) ON
			XCLA.IDCOTIZACION = TMPA.IDCOTIZACION
		LEFT JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPB WITH(NOLOCK) ON
			XCLA.IDPRESUPUESTO = TMPB.IDPRESUPUESTO
		LEFT JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPC WITH(NOLOCK) ON
			XCLA.IDVERIFICACION = TMPC.IDVERIFICACION
		LEFT JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPD WITH(NOLOCK) ON
			XCLA.IDPOLIZA = TMPD.IDPOLIZA
	--option(recompile)	
	*/
    /*
	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Cartera'   
	SELECT 
		XCLA.IDCONVERSION, 
		TMPA.IDCONVERSION  AS IdConversion_Aux
	INTO TMP.XAUTOS_dbo.Xconversiones_Cartera
	FROM
		[XAUTOS].[dbo].[Xconversiones]  XCLA WITH(NOLOCK) INNER JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPA WITH(NOLOCK) ON
			XCLA.IDCOTIZACION = TMPA.IDCOTIZACION
	
    INSERT TMP.XAUTOS_dbo.Xconversiones_Cartera
		(IDCONVERSION, IdConversion_Aux)
	SELECT
		XCLA.IDCONVERSION, 
		TMPB.IdConversion  AS IdConversion_Aux
	FROM 
		[XAUTOS].[dbo].[Xconversiones] XCLA WITH(NOLOCK) INNER JOIN	TMP.XAUTOS_DBO.Xconversiones1 TMPB WITH(NOLOCK) ON	
			XCLA.IDPRESUPUESTO = TMPB.IDPRESUPUESTO 
		LEFT JOIN TMP.XAUTOS_dbo.Xconversiones_Cartera XCLA_1  WITH(NOLOCK) ON
			XCLA.IDCONVERSION = XCLA_1.IDCONVERSION
	WHERE 
		XCLA_1.IDCONVERSION IS NULL 
		
	INSERT TMP.XAUTOS_dbo.Xconversiones_Cartera
		(IDCONVERSION, IdConversion_Aux)
	SELECT
		XCLA.IDCONVERSION, 
		TMPB.IdConversion  AS IdConversion_Aux
	FROM 
		[XAUTOS].[dbo].[Xconversiones] XCLA WITH(NOLOCK) INNER JOIN	TMP.XAUTOS_DBO.Xconversiones1 TMPB WITH(NOLOCK) ON	
			XCLA.IDVERIFICACION = TMPB.IDVERIFICACION
		LEFT JOIN TMP.XAUTOS_dbo.Xconversiones_Cartera XCLA_1  WITH(NOLOCK) ON
			XCLA.IDCONVERSION = XCLA_1.IDCONVERSION
	WHERE 
		XCLA_1.IDCONVERSION IS NULL 

	INSERT TMP.XAUTOS_dbo.Xconversiones_Cartera
		(IDCONVERSION, IdConversion_Aux)
	SELECT
		XCLA.IDCONVERSION, 
		TMPB.IdConversion  AS IdConversion_Aux
	FROM 
		[XAUTOS].[dbo].[Xconversiones] XCLA WITH(NOLOCK) INNER JOIN	TMP.XAUTOS_DBO.Xconversiones1 TMPB WITH(NOLOCK) ON	
			XCLA.IDPOLIZA = TMPB.IDPOLIZA
		LEFT JOIN TMP.XAUTOS_dbo.Xconversiones_Cartera XCLA_1  WITH(NOLOCK) ON
			XCLA.IDCONVERSION = XCLA_1.IDCONVERSION
	WHERE 
		XCLA_1.IDCONVERSION IS NULL 
*/

/*
	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Cartera'   
	SELECT 
		IDCONVERSION, 
		IdConversion_Aux
	INTO TMP.XAUTOS_dbo.Xconversiones_Cartera
	FROM (
	SELECT
		IDCONVERSION, 
		IdConversion_Aux,
		ROW_NUMBER() OVER (PARTITION BY IDCONVERSION ORDER BY ORDEN) ORDEN1
    FROM (		
	SELECT 
		XCLA.IDCONVERSION, 
		TMPA.IDCONVERSION AS IdConversion_Aux,
		1 AS Orden
	FROM
		[XAUTOS].[dbo].[Xconversiones]  XCLA WITH(NOLOCK) INNER JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPA WITH(NOLOCK) ON
			XCLA.IDCOTIZACION = TMPA.IDCOTIZACION
	UNION ALL	
	SELECT 
		XCLA.IDCONVERSION, 
		TMPB.IDCONVERSION AS IdConversion_Aux,
		2 AS Orden
	FROM
		[XAUTOS].[dbo].[Xconversiones]  XCLA WITH(NOLOCK) INNER JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPB WITH(NOLOCK) ON
			XCLA.IDPRESUPUESTO = TMPB.IDPRESUPUESTO
	UNION ALL	
	SELECT 
		XCLA.IDCONVERSION, 
		TMPC.IDCONVERSION AS IdConversion_Aux,
		3 AS Orden
	FROM
		[XAUTOS].[dbo].[Xconversiones]  XCLA WITH(NOLOCK) INNER JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPC WITH(NOLOCK) ON
			XCLA.IDVERIFICACION = TMPC.IDVERIFICACION
	UNION ALL	
	SELECT 
		XCLA.IDCONVERSION, 
		TMPD.IDCONVERSION AS IdConversion_Aux,
		4 AS Orden
	FROM
		[XAUTOS].[dbo].[Xconversiones]  XCLA WITH(NOLOCK) INNER JOIN  TMP.XAUTOS_DBO.Xconversiones1 TMPD WITH(NOLOCK) ON
			XCLA.IDPOLIZA = TMPD.IDPOLIZA			
	)TMP)TMPA
    WHERE
		ORDEN1 = 1
	
	set @Msg='Xconversiones_Cartera generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1
rhr*/

	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Cartera'   
	SELECT XCLA.IDCONVERSION
	, TMPA.IDCONVERSION AS IdConversion_Aux
	INTO TMP.XAUTOS_dbo.Xconversiones_Cartera
	FROM [XAUTOS].[dbo].[Xconversiones] XCLA WITH (NOLOCK)
	INNER JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPA WITH (NOLOCK)
	ON XCLA.IDCOTIZACION = TMPA.IDCOTIZACION

	set @Msg='Xconversiones_Cartera generada (Cotización): '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	INSERT INTO TMP.XAUTOS_dbo.Xconversiones_Cartera
	SELECT XCLA.IDCONVERSION
		, TMPB.IDCONVERSION AS IdConversion_Aux
	FROM [XAUTOS].[dbo].[Xconversiones] XCLA WITH (NOLOCK)
	INNER JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPB WITH (NOLOCK)
	ON XCLA.IDPRESUPUESTO = TMPB.IDPRESUPUESTO
	LEFT JOIN TMP.XAUTOS_dbo.Xconversiones_Cartera C
	ON C.IdConversion = XCLA.IDCONVERSION
	WHERE C.IdConversion IS NULL

	set @Msg='Xconversiones_Cartera generada (Presupuesto): '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	INSERT INTO TMP.XAUTOS_dbo.Xconversiones_Cartera
	SELECT XCLA.IDCONVERSION
		, TMPC.IDCONVERSION AS IdConversion_Aux
	FROM [XAUTOS].[dbo].[Xconversiones] XCLA WITH (NOLOCK)
	INNER JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPC WITH (NOLOCK)
	ON XCLA.IDVERIFICACION = TMPC.IDVERIFICACION
	LEFT JOIN TMP.XAUTOS_dbo.Xconversiones_Cartera C
	ON C.IdConversion = XCLA.IDCONVERSION
	WHERE C.IdConversion IS NULL

	set @Msg='Xconversiones_Cartera generada (Verificación): '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	INSERT INTO TMP.XAUTOS_dbo.Xconversiones_Cartera
	SELECT XCLA.IDCONVERSION
		, TMPD.IDCONVERSION AS IdConversion_Aux
	FROM [XAUTOS].[dbo].[Xconversiones] XCLA WITH (NOLOCK)
	INNER JOIN TMP.XAUTOS_DBO.Xconversiones1 TMPD WITH (NOLOCK)
	ON XCLA.IDPOLIZA = TMPD.IDPOLIZA
	LEFT JOIN TMP.XAUTOS_dbo.Xconversiones_Cartera C
	ON C.IdConversion = XCLA.IDCONVERSION
	WHERE C.IdConversion IS NULL

	set @Msg='Xconversiones_Cartera generada (Póliza): '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- Creamos la tabla de datos borrados
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Borrados'   

	SELECT 
		CART.IdConversion_Aux,
		MAX(CART.IdConversion) AS IdConversion
	INTO TMP.XAUTOS_dbo.Xconversiones_Borrados
	FROM TMP.XAUTOS_dbo.Xconversiones_Cartera CART WITH(NOLOCK) INNER JOIN
		(SELECT IdConversion_Aux
		 FROM 
			TMP.XAUTOS_dbo.Xconversiones_Cartera
		 GROUP BY IdConversion_Aux
		 HAVING COUNT(*) > 1) REPE ON
	 		CART.IdConversion_Aux = REPE.IdConversion_Aux
	GROUP BY CART.IdConversion_Aux

	set @Msg='Xconversiones_Borrados generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- Creamos la tabla de datos nuevos. 
-- Aprovechamos para calcular la semilla que corresponde a los datos nuevos.
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
	exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Nueva'   
	CREATE TABLE TMP.XAUTOS_dbo.Xconversiones_Nueva(id bigint identity(1,1),idConversion bigInt not null)

--------------------------------------------------------------------------------------------------------------------
-- Primero calculamos el proximo valor de IdConversion
--------------------------------------------------------------------------------------------------------------------
	SET @iIdentidad = (SELECT ISNULL(MAX(idConversion),0)+ 1 FROM [XAUTOS].[dbo].[Xconversiones] )

	--Vamos a cambiar la semilla de la tabla al valor de identidad que le corresponde
	DBCC CHECKIDENT ('TMP.XAUTOS_dbo.Xconversiones_Nueva', 'RESEED', @iIdentidad)

	INSERT INTO TMP.XAUTOS_dbo.Xconversiones_Nueva WITH(TABLOCK)
		(IdConversion)
	SELECT 
		XCON.IdConversion
	FROM 			
		TMP.XAUTOS_DBO.Xconversiones1 XCON WITH(NOLOCK) LEFT JOIN TMP.XAUTOS_DBO.Xconversiones_Cartera XCAR WITH(NOLOCK) on
			XCON.IdConversion = XCAR.IdConversion_Aux
	WHERE 
		XCAR.IdConversion_Aux IS NULL

	set @Msg='Xconversiones_Nueva generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- Calculamos la suma de Cartera + Nuevos - A borrar
-- Separamos la consulta en dos
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

/************************************************************************
07/09/2016  Dividimos esta consulta en dos eliminando el UNION ALL
            Cambiamos el NOT IN por un LEFT JOIN
*************************************************************************/
-- exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Total' 
 exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones' 

 SELECT
		CART.IDCONVERSION,
		TMP.IDCOTIZACION,
		TMP.IDPRESUPUESTO,
		TMP.IDVERIFICACION,
		TMP.IDPOLIZA,
		TMP.ESTADOINICIAL,
		TMP.ESTADOFINAL,
		TMP.EXTRAPOLACION --20140627 Se añade campo Nuevo 
       	,getdate() as F_CARGA
	--INTO TMP.XAUTOS_dbo.Xconversiones_Total
    INTO TMP.XAUTOS_dbo.Xconversiones
	FROM 
		TMP.XAUTOS_dbo.Xconversiones_Cartera CART WITH(NOLOCK) INNER JOIN TMP.XAUTOS_dbo.Xconversiones1 TMP WITH(NOLOCK) ON
			CART.IdConversion_Aux = TMP.IDCONVERSION
	    LEFT JOIN TMP.XAUTOS_dbo.Xconversiones_Borrados BORR WITH(NOLOCK) ON 
			CART.IDCONVERSION = BORR.IdConversion
    WHERE
		BORR.IdConversion IS NULL
	
	/*WHERE
		CART.IDCONVERSION NOT IN (SELECT IdConversion 
								  FROM
								  TMP.XAUTOS_dbo.Xconversiones_Borrados WITH(NOLOCK))
	*/
	--UNION ALL
	
	set @filas = @@rowcount

	set @Msg='Xconversiones Total 01 generada: '+cast(@filas as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1

	INSERT INTO TMP.XAUTOS_dbo.Xconversiones WITH (TABLOCK)
	SELECT
		ID as IdConversion,
		TMP.IDCOTIZACION,
		TMP.IDPRESUPUESTO,
		TMP.IDVERIFICACION,
		TMP.IDPOLIZA,
		TMP.ESTADOINICIAL,
		TMP.ESTADOFINAL,
		TMP.EXTRAPOLACION --20140627 Se añade campo Nuevo 
		,getdate() as F_CARGA
	FROM 
		TMP.XAUTOS_dbo.Xconversiones_Nueva CART WITH(NOLOCK) INNER JOIN TMP.XAUTOS_dbo.Xconversiones1 TMP WITH(NOLOCK) ON
			CART.IdConversion = TMP.IDCONVERSION

	set @filas = @@rowcount

	set @Msg='Xconversiones Total 02 generada: '+cast(@filas as varchar(9))+' registros'

	--Adela 20170608
	--De forma temporal, volcamos la tabla TMP.XAUTOS_dbo.Xconversiones a otra para las comprobaciones
	--del proyecto Datamart Autos (la original la elimina el GestorCargaX tras actualizar la final)

	 exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_bk' 
	SELECT * INTO TMP.XAUTOS_dbo.Xconversiones_bk FROM TMP.XAUTOS_dbo.Xconversiones 
	
/********************************************************************************
07/09/2016  Comentamos esta carga. En los últimos 3 meses no ha aportado la criba de ningún registro respecto a
            la tabla TMP.XAUTOS_dbo.Xconversiones_Total.

 exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones' 
 SELECT   IDCONVERSION
         ,IDCOTIZACION
         ,IDPRESUPUESTO
         ,IDVERIFICACION
         ,IDPOLIZA
         ,ESTADOINICIAL
         ,ESTADOFINAL
         ,EXTRAPOLACION
       	 ,getdate() as F_CARGA
 INTO TMP.XAUTOS_dbo.Xconversiones
 FROM (
  SELECT IDCONVERSION
         ,IDCOTIZACION
         ,IDPRESUPUESTO
         ,IDVERIFICACION
         ,IDPOLIZA
         ,ESTADOINICIAL
         ,ESTADOFINAL
         ,EXTRAPOLACION
         --,ROW_NUMBER() OVER (PARTITION BY ISNULL(IDCOTIZACION,0),ISNULL(IDPRESUPUESTO,0),ISNULL(IDVERIFICACION,0),ISNULL(IDPOLIZA,0) ORDER BY F_CARGA DESC) N
         ,ROW_NUMBER() OVER (PARTITION BY ISNULL(IDCOTIZACION,0),ISNULL(IDPRESUPUESTO,0),ISNULL(IDVERIFICACION,0),ISNULL(IDPOLIZA,0) ORDER BY IDCONVERSION DESC) N
  FROM TMP.XAUTOS_dbo.Xconversiones_Total WITH(NOLOCK)
  ) TT	
  WHERE N = 1
			
	set @filas = @@rowcount
	set @Msg='Xconversiones Final generada: '+cast(@filas as varchar(9))+' registros'
*/
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- Creación de índices. Sólo la clave
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
	--create unique index ix1 on TMP.XAUTOS_DBO.Xconversiones(IdCotizacion) where idcotizacion is not null
	--create unique index ix2 on TMP.XAUTOS_DBO.Xconversiones(IdPresupuesto) where IdPresupuesto is not null
	--create unique index ix3 on TMP.XAUTOS_DBO.Xconversiones(IdVerificacion) where IdVerificacion is not null
	--create unique index ix4 on TMP.XAUTOS_DBO.Xconversiones(IdPoliza) where IdPoliza is not null
	create unique index ix5 on TMP.XAUTOS_DBO.Xconversiones(IdConversion) 
	exec Comun..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','M',1


--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
-- Comprobaciones: EL Nº de registros de XConversiones y XConversiones1 deben coincidir.
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
/*	SET @regTemp  = (SELECT COUNT(*) FROM TMP.XAUTOS_DBO.Xconversiones1)
	SET @regXConv  = (SELECT COUNT(*) FROM TMP.XAUTOS_DBO.Xconversiones)
	
	IF (@regTemp <> @regXConv)
		BEGIN
			Set @Msg = 'ERROR CARGA XCONVERSIONES : EL Nº DE REGISTROS PARA XCONVERSIONES Y XCONVERSIONES1 NO COINCIDEN'
			EXEC COMUN..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','E',1	
			--Subimos el error para que se entere el gestor de carga
			RaisError(@Msg,18,1)
			RETURN
		END
*/
	--elimino las temporales 
	--exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones_Web_NP'
	--exec comun.dbo.EliminaTabla 'TMP.XAUTOS_DBO.Xconversiones0'   
	--exec comun.dbo.Eliminatabla 'TMP.XAUTOS_DBO.Xconversiones1'
	--exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Cartera'
	--exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Borrados' 
	--exec comun.dbo.EliminaTabla 'TMP.XAUTOS_dbo.Xconversiones_Nueva'        
	
	
	return(@filas)
/*	
END TRY
BEGIN CATCH
	
	Set @Msg = 'ERROR Gestor Carga: ' + convert(varchar,isnull(ERROR_NUMBER(),0)) + '. ' + isnull(ERROR_MESSAGE(),'n/a') + ' --> ' + convert(varchar(50), getdate(),108)
	EXEC COMUN..Logar 'XAUTOS','XCONVERSIONES',@Msg,'C','E',1	
	
	--Subimos el error para que se entere el gestor de carga
	RaisError(@Msg,18,1)

END CATCH;
*/
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--DAR 
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

	/*
	
	 
	 --conversion arpem
	select
		year(FechaContratacion),Month(FechaContratacion),Agregador,CanalEntrada,count(*)
	from
		(
		select 
			t.*,FechaContratacion,agregador,c.canalentrada
			,datediff(dd,c.fecemision,FechaContratacion) as LapsoDias
		from 
			TMP.XAUTOS_dbo.XCONVERSIONES  t
		inner join
			xautos..xcotizaciones c
		on
			t.idcotizacion=c.idcotizacion
		inner join	
			xautos..xpolizas_comun xpc
		on
			t.idpoliza=xpc.apolclav
		where 
			t.idcotizacion is not null
			and t.idpoliza is not null
			and c.canalentrada='W' 
			and c.agregador is not null
--order by FechaContratacion			
		) s
	group by 
		year(FechaContratacion),Month(FechaContratacion),Agregador,CanalEntrada 
	order by 
		1,2
		
	--	
	select year(FecEmision),Month(FecEmision),count(*) from xautos..xcotizaciones where canalentrada='W' group by year(FecEmision),Month(FecEmision) order by 1,2
	
	select year(FecEmision),Month(FecEmision),count(*) from xautos..xcotizaciones where canalentrada='W' and agregador='a001' group by year(FecEmision),Month(FecEmision) order by 1,2
		
		
	--polizas web sin cotizacion (errores)
	
	select 	*
	from xautos..xpolizas_comun xpc 
	inner join xautos..xpolizas_imputacion xpi on xpi.apolclav=xpc.apolclav and xpi.primermovimiento=1
	inner join marcas m on xpi.idmodelo=m.id and m.tipoveh='tu'
	where fechacontratacion>='20081101' and canalentrada='W' 
	and not exists(select 1 from TMP.XAUTOS_DBO.Xconversiones  t where xpc.apolclav=t.idpoliza and t.idpoliza is not null and t.idcotizacion is not null)
	 
		
select * from xautos..xpolizas_comun where apolclav=3074552
select * from xautos..marcas where id=2045401922
select * from xautos..xpolizas_imputacion where apolclav=3074552
select * from xcotizaciones where codpostal='13670' and /*fecemision between '20090601' and '20090929' and */ year(fnactomador)=1979 and month(fnactomador)=10 and sexotomador=2 order by FecEmision
select * from xautos..xconversiones where idpoliza=3131920
select * from  TMP.XAUTOS_DBO.Xconversiones0 where origen=90000000000001486854

select * from xautos..xcotizaciones where idcotizacion=90000000000001486854

select * from xautos..xpolizas_comun where apolclav=3124148
select * from xautos..xpolizas where apolclav=3124148
select * from dw_autos..mov_polizas where apolclav=3124148
select * from dw_autos_M..mov_polizas where apolclav=3124148
select * from xautos..xcotizaciones where fechaemision between '20091111'and '20091202' and codpostal='28025' and year(fnactomador)=1969 and month(fnactomador)=10 and sexotomador=1

	select 
		year(FecDestino),Month(FecDestino),Agregador,CanalEntrada,count(*)
	from 
		
	inner join
		xautos..xcotizaciones c
	on
		t.origen=c.idcotizacion
	where 
		edestino='P' and eorigen<>'C' 
	group by 
		year(FecDestino),Month(FecDestino),Agregador,CanalEntrada 
			
		
		
		

select * from TMP.XAUTOS_DBO.Xconversiones0 t1 where edestino is null

select * from TMP.XAUTOS_DBO.Xconversiones0 t1 where origen=89999999999998602805 --or destino=9955008

select * from TMP.XAUTOS_DBO.Xconversiones0 where origen=9040792


select top 100 origen,eorigen from TMP.XAUTOS_DBO.Xconversiones0 group by origen,eorigen having count(*)>1



*/


/*

Sin duplicados (deben salir solo los NULL)
-------------------
select idcotizacion,count(*) from TMP.XAUTOS_dbo.Xconversiones group by idcotizacion having count(*)>1  order by count(*) desc
select idverificacion,count(*) from TMP.XAUTOS_dbo.Xconversiones_sim group by idverificacion having count(*)>1 order by count(*) desc
select idpoliza,count(*) from TMP.XAUTOS_dbo.Xconversiones_sim group by idpoliza having count(*)>1 order by count(*) desc
select idpresupuesto,count(*) from TMP.XAUTOS_dbo.Xconversiones_sim group by idpresupuesto having count(*)>1 order by count(*) desc

Integridades referenciales
-------------------
select * from TMP.XAUTOS_dbo.Xconversiones_sim xc  where idcotizacion is not null and not exists(select * from xautos.dbo.xcotizacionesxp where xp.idcotizacion=xc.idcotizacion)
select * from TMP.XAUTOS_dbo.Xconversiones_sim xc  where idpresupuesto is not null and not exists(select * from xautos.dbo.xpresupuestos xp where xp.idpresupuesto=xc.idpresupuesto)
select * from TMP.XAUTOS_dbo.Xconversiones_sim xc  where idverificacion is not null and not exists(select * from xautos.dbo.xverificaciones xp where xp.idverificacion=xc.idverificacion)
select * from TMP.XAUTOS_dbo.Xconversiones_sim xc  where idpoliza is not null and not exists(select * from xautos.dbo.xpolizas_comun xp where xp.apolclav=xc.idpoliza)

*/

--select COUNT(*) from tmp.xautos_dbo.XCONVERSIONES_SIM where IdCotizacion not like '9%' and IdCotizacion is not null
--select COUNT(*) from tmp.xautos_dbo.XCONVERSIONES_SIM where IdCotizacion like '9%' and IdCotizacion is not null
--select COUNT(*) from tmp.xautos_dbo.XCONVERSIONES_SIM where IdCotizacion is null



