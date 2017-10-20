


--exec xautos.[dbo].[Pr_Carga_XPolizas_Imputacion] '20161025 13:12:00'

CREATE procedure [dbo].[Pr_Carga_XPolizas_Imputacion] @UltimaFcargaX smalldatetime='19010101'
AS 


/*----------------------------------------------------------------------------
DESCRIPCION:
 
------------------------------------------------------------------------------
CREADO POR: Jgomez 12/12/2008

------------------------------------------------------------------------------
MODIFICADO POR:	
			20090217	M.Nieves Sanchez-M. Se añade las columnas Ocupantes y AñoPenalizaci¢n
			20090428	Ivan Alonso. Se añade una verificacion para saber si las verificaciones de las
						tablas dependientes del proceso han pasado las validaciones correctamente.
			20091007	Añadido tipoveh y sacadas a tmp las temporales
			20091018	Lo dejo en total en vez de en incremental
			20100107	Jgomez añadida correcion al calcular @ayer para los festivos
			20100115	Jgomez añadido parametro @Sincronizacion total y cruce con marcas
			20100325	Jgomez añadido cambio para que la desaparici¢n de una p¢liza de xpolizas no provoque error en las comprobaciones. 
						La carga siempre se hace con sincronizaci¢n total ya que hay que detectar los borrados
			20100819	Añadido que no se puedan colar p¢lizas del dia en curso	y solucionado problema por el que algunas p¢lizas se quedaban sin actualizar campos nulos			
			20110521	Jgomez Añadida Garantia Mecanica
			20110630	Añadido VehiculoNuevo y updateada en toda la tabla la fecha de construcción a la existente este dia en xvehiculo
			20111017    Gemma Pérez. Inclusión del campo IdNegocio.
						Tratamiento del campo IdNegocio hacia atrás en la fecha de subida a producción: 
						    El campo se rellena con el valor de los campos Colectivo / Flota de Xpolizas_imputacion para
						    todos los registros (se obtiene el valor por imputación).
						    En el caso de los negocios de los tipos Agregador(AG) y Marketing Online(MK), el campo se 
						    completa en el presente y pasado con el valor actual del negocio en la tabla Xpolizas_comun
						    (se obtiene el valor por efecto).
			20111101   Gemma Pérez. Inclusión de los nuevos campos.
							UsoVehiculo
							Tarifa
							VersionTarifa						    
			
			Criterio de carga de estos tres nuevos campos a pasado:
						
							-- Dato antiguo						
							update x
							 set tarifa = b.tarifa,
								versiontarifa = b.versiontarifa,
								usovehiculo = b.usovehiculo
							from xautos..xpolizas_imputacion x inner join
							xautos..xpolizas b on
								x.apolclav = b.apolclav 
							where
								x.fecimpfin between b.fechamovini  and b.fechamovfin 
		
							-- Ajuste para los movimientos a futuro. 
							update x
							 set tarifa = c.tarifa,
								versiontarifa = c.versiontarifa,
								usovehiculo = c.usovehiculo
							from xautos..xpolizas_imputacion x inner join
							xautos..xpolizas b on
								x.apolclav = b.apolclav 
							inner join	xautos..xpolizas c on
								x.apolclav = c.apolclav 
							where
							    b.fechamovini > convert(date, getdate() -1) and
								x.fecimpfin = '20501230' and
								x.sitpoliza <> 'F' and
								x.fecimpini between c.fechamovini  and c.fechamovfin 
		
		
							-- Dato actual	-- Ya contemplado en caso 1. No necesario.
							--update x
							-- set tarifa = b.tarifa,
							--	versiontarifa = b.versiontarifa,
							--	usovehiculo = b.usovehiculo
							--from xautos..xpolizas_imputacion x inner join
							--xautos..xpolizas b on
							--	x.apolclav = b.apolclav 
							--	where
							--	x.fecimpfin = '20501230' and
							--	b.fechamovfin = '20501230'
						
			20120227   Gemma Pérez. Inclusión de los nuevos campos.
							codCoefBonificacion
							NivelBonificacion 
							
						update xautos..xpolizas_imputacion set codCoefBonificacion = '' 							
						update xautos..xpolizas_imputacion set NivelBonificacion = 0
			Gemma Pérez  29/02/2012 Cambiado cálculo de FechaImputacion para evitar efecto 29/02/2012:
							Las pólizas con efecto 01/03/2012 se imputan a 29/02/2012
			Gemma Pérez  01/03/2012 Comentado parche para 29/02/2012
			Gemma Pérez  31/07/2012 Se cambia el cálculo de la fecha de imputación de las pólizas a futuro 
									en el caso de que la fecha de contratación sea mayor que el día de ayer.
			Luis Arroyo 04/01/2013 Añadido campo de Asistencia (S,N)
			Gemma Pérez 23/07/2013 Eliminado campo Lortad de la tabla XPOLIZAS_IMPUTACION
			
			Sergio Álvaro 24/07/2013 Añadido campo IdOficina
			Adela Gutiérrez 16/09/2012 Se modifica la forma de detectar las pólizas modificadas para eliminar el checksum 
			
			Sergio Álvaro 22/01/2015 (Buscar: salpa1d22012015)
				Modificado campo IdOficina para que si el idnegocio es null o 0 ponga No aplica
				
			Angel Cañas		14/04/2015	Añadidos campos idSolicitud e id15PuntosCarnet 
			Gemma Pérez     13/06/2016  Incidencia D-186922. Se actualizan los registros a mano con segmento = 99 (Negocio Genérico) a segmento 4 (Flota)
			                con carácter retroactivo. Hablado con usuario de Producción (Cristina Casal) y Francisco Martínez Nájera.
							Se actualiza en XPOLIZAS_IMPUTACION la información del negocio de esas pólizas para asignarles 
							el negocio actual a los movimientos que tienen asignado un negocio de tipo GENÉRICO.
							Son 9 pólizas.

							select A.* 
							--into TMP.XAUTOS_DBO.XPOLIZAS_IMPUTACION_GENERICO_20160613
							from xautos..xpolizas_imputacion a (NOLOCK) inner join xdim.autos.negocios b (NOLOCK) on
										a.idnegocio = b.cod_negocio
							where 
										b.cod_tiposubnegocio = 'GE' 
							begin tran
							update a 
								set idnegocio = c.idnegocio, f_carga = getdate()
							from xautos..xpolizas_imputacion a inner join xdim.autos.negocios b on
									a.idnegocio = b.cod_negocio
								inner join xautos..xpolizas_imputacion c on
									a.apolclav = c.apolclav
							where 
								b.cod_tiposubnegocio = 'GE' AND
								c.fecimpfin = '20501230' AND
								a.apolclav in (6159214, 
												6277002,
												6277491,
												6277980,
												6279287,
												6279480,
												6279885,
												6280274,
												6280596)
							update B 
								set idnegocio = c.idnegocio, f_carga = getdate()
							from [BI_PRODUCCION].[dbo].[PROD_DIM_POLIZAS_MOV] B INNER JOIN TMP.XAUTOS_DBO.XPOLIZAS_IMPUTACION_GENERICO_20160613 a ON 
								B.APOLCLAV = A.APOLCLAV AND
								B.IDNEGOCIO = A.IDNEGOCIO
							INNER JOIN XAUTOS..XPOLIZAS_IMPUTACION C (NOLOCK) ON
								B.APOLCLAV = C.APOLCLAV 
							where 
								c.fecimpfin = '20501230' AND
								a.apolclav in (6159214, 
												6277002,
												6277491,
												6277980,
												6279287,
												6279480,
												6279885,
												6280274,
												6280596)
							COMMIT
			
			Gemma Pérez 26/10/2016  Inclusión del campo FechaVencimiento.  

			Alvaro Roldán 09/02/2017 Añadimos los campos:	Telefono
															AñoAdquisicion
															KMAño
															LugarAparcamiento
															NPlazasAseg
															EstadoCivil
															UsoVehiculoAct
															DescuentoObligatorio
															DescuentoVoluntario
															DescuentoOcupantes
			Raquel Humanes 16/03/2017 Temporalmente al final de la carga de la temporal actualizamos el idnegocio 
			y la idnegociocierre de las pólizas de agregadores que cambian

------------------------------------------------------------------------------
ENTRADAS:
		@UltimaFcargaX
		@SincronizacionTotal: indica si la comparaci¢n con xpolizas debe realizarse para
							todas las p¢lizas o s¢lo para la parte incremental
------------------------------------------------------------------------------
SALIDAS:
------------------------------------------------------------------------------
OBSERVACIONES:	TRUNCATE TABLE XAUTOS.dbo.XPolizas_Imputacion
				EXEC COMUN..GESTORCARGAX 'XAUTOS..XPolizas_Imputacion',0,1

/* CODIGO PARA ELIMINAR UNA CARGA

1.Realizar un backup de la tabla
exec comun..eliminatabla 'TMP.Xautos_dbo.Xpolizas_Imputacion_bck'
Select * into TMP.Xautos_dbo.Xpolizas_Imputacion_bck From Xautos..Xpolizas_Imputacion 

2. Eliminamos registros generados en incremental siempre que la siguiente consulta devuelva movimientos
con el valor del campo fecimpini a un d¡a anterior a la fecha actual de carga. 
Si no fuera as¡, abstenerse de continuar este guion y realizar la carga en modo test pasando la fecha '19010101'

	-- select * from xautos..xpolizaS_imputacion where f_carga>='20111106' and fecimpfin='20501230'

	-- delete xautos..xpolizaS_imputacion where f_carga>='20111106' and fecimpfin='20501230'
	-- update xautos..xpolizas_imputacion set fecimpfin='20501230' where f_carga>'20091015' and fecimpfin<>'20501230'
	
	--Verificar que no hay duplicados, en cuyo caso eliminar el generado para el día de carga a eliminar
	
	--1.-select coun(*) from XAUTOS.dbo.xpolizas_imputacion where fecimpini='2011-11-05' and FecImpFin='2050-12-30' and F_carga>'20111106' 
	
	--2.delete from XAUTOS.dbo.xpolizas_imputacion where fecimpini='20111105' and FecImpFin='20501230' and F_carga>'20111106' 

3. Si la el paso anterior es satisfactorio, inicializamos la fechaimpfin de los movimientos actualizados a '20501230':

	-- select * from xautos..xpolizaS_imputacion where f_carga>'20091015' and fecimpfin<>'20501230'

	-- update xautos..xpolizas_imputacion set fecimpfin='20501230' where f_carga>'20091015' and fecimpfin<>'20501230'

select apolclav from  xautos..xpolizaS_imputacion  group by apolclav having max(fecimpfin)<>'20501230' and sum(cast(primermovimiento as int))<>1

*/				
----------------------------------------------------------------------------*/


--declare @SincronizacionTotal bit =0
--declare @UltimaFcargaX datetime='19010101'
--declare @UltimaFcargaX datetime= (select max(f_carga) from xautos..xpolizas_imputacion)


	set nocount on 
	


--declaracion de variables
	declare @msg varchar(1000),@ayer date

	set @Ayer=(select convert(varchar(8),DATEADD(DD,-1,max(fec_generacion)),112) from dw_autos..mov_polizas where fec_generacion<'20501230')
	--para la carga de los lunes	
	
	if datepart(dw,@Ayer)=6 and exists(select * from xautos..xpolizas_imputacion where fecimpini=@ayer) set  @ayer=dateadd(dd,1,@Ayer) -- es la carga del lunes
	--para la carga de festivos
	if @ayer<cast(getdate()-1 as date) and exists(select 1 from xautos..xpolizas_imputacion where fecimpini=cast(getdate()-2 as date)) set @ayer=cast(getdate()-1 as date)
	
--logo el inicio
	set @Msg='Iniciada Carga - @Ayer= '+convert(varchar(100),@Ayer,103)--+',@UltimaFcargaX='+convert(varchar(100),@UltimaFcargaX,109)
	exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','I',1	
	

/*
-- Comprobamos que todas las tablas de las que necesitamos datos han pasado las validaciones

	if exists (select * from sysobjects where name = 'AUX_xpolizas_imputacion' and uid = (select schema_id from sys.schemas where name = 'dbo')) drop table AUX_xpolizas_imputacion
	select *
	  into dbo.AUX_xpolizas_imputacion
	  from (
		select row_number() over (partition by basedatos, tabla, consulta order by basedatos, tabla, consulta, fecha desc) as ID, 
			   BaseDatos, Tabla, Consulta, Fecha,
			   Resultado,
			   CamposError, DuracionSeg
		  from comun..comprobaciones_resultados
		 where basedatos = 'xautos'
		   and tabla = 'xpolizas'
		   and floor(convert(float,fecha)) = floor(convert(float, getdate()))
		   )S1
		where id = 1

	if @@rowcount = 0
	begin
		set @Msg='############ ERROR No se han pasado las validaciones para xpolizas para hoy'
		exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','E',1
		raiserror(@Msg,18,1)
		return
	end

	insert into AUX_xpolizas_imputacion
	select *
	  from (
		select row_number() over (partition by basedatos, tabla, consulta order by basedatos, tabla, consulta, fecha desc) as ID, 
			   BaseDatos, Tabla, Consulta, Fecha,
			   Resultado,
			   CamposError, DuracionSeg
		  from comun..comprobaciones_resultados
		 where basedatos = 'xautos'
		   and tabla = 'xpolizas_comun'
		   and floor(convert(float,fecha)) = floor(convert(float, getdate()))
		   )S1
		where id = 1
	if @@rowcount = 0
	begin
		set @Msg='############ ERROR No se han pasado las validaciones para xpolizas_comun para hoy'
		exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','E',1	
		raiserror(@Msg,18,1)
		return
	end

	insert into AUX_xpolizas_imputacion
	select *
	  from (
		select row_number() over (partition by basedatos, tabla, consulta order by basedatos, tabla, consulta, fecha desc) as ID, 
			   BaseDatos, Tabla, Consulta, Fecha,
			   Resultado,
			   CamposError, DuracionSeg
		  from comun..comprobaciones_resultados
		 where basedatos = 'xautos'
		   and tabla in ('xpolizas_imputacion')
		   and fecha < getdate()
		   )S1
		where id = 1
	if @@rowcount = 0
	begin
		set @Msg='############ ERROR No se han pasado las validaciones para xpolizas_imputacion para ayer'
		exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','E',1	
		raiserror(@Msg,18,1)
		return
	end

	if exists ( select * from AUX_xpolizas_imputacion where Resultado = 'Error')
	begin
		set @Msg='############ ERROR Aguna de las validaciones son erroneas para: xpolizas o xpolizas_comun de hoy; o xpolizas_imputacion de ayer'
		exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','E',1	
		raiserror(@Msg,18,1)
		return
	end

*/

-- Vamos a buscar las pólizas que tienen un movimiento que empieza el día 01/03/2012 emitidas el día 29/02/2012.
-- Después del día 01/03/2012 COMENTAR !!!!
/*exec comun..eliminatabla 'TMP.XAUTOS_DBO.XPOLIZAS_EFECTO_29022012'

SELECT 
	CAST(APOLCLAV AS INT) AS APOLCLAV
INTO TMP.XAUTOS_DBO.XPOLIZAS_EFECTO_29022012
FROM (
SELECT 
	xpol.APOLCLAV, 
	CONVERT(date, ISNULL(MOV_ANT.APOLFEMI, xpc.FechaContratacion)) AS FechaEmision
FROM 
	xautos.dbo.xpolizas_comun xpc inner join xautos.dbo.xpolizas xpol on
		xpc.apolclav = xpol.apolclav
	inner join DW_AUTOS.DBO.MOV_POLIZAS MOV ON
		xpol.apolclav = MOV.APOLCLAV AND
		xpol.idMovPoliza = MOV.ID	
	left join DW_AUTOS.DBO.MOV_POLIZAS MOV_ANT ON
		MOV.APOLCLAV = MOV_ANT.APOLCLAV AND
		MOV.APOLFUSP = MOV_ANT.APOLFEFE AND
		MOV_ANT.APOLSHIS <> 'A' 
WHERE
	xpol.FechaMovIni = '20120301' AND
	MOV.APOLSHIS <> 'A' AND
	-- Sólo obtenemos dato para el día 01/03
	convert(date, getdate()) = '20120301'
)TMP
WHERE
	TMP.FechaEmision = '20120229'
*/
-- Fin de luego comentar


--calculo cuales son las p¢lizas que han variado desde mi anterior carga	
  exec comun..eliminatabla 'tmp.xautos_dbo.xpolizas_imputacion'
	select
		apolclav
		,producto
		,case 
			when t2apolclav is null then 1 
			else 0 end as 
		primermovimiento
		,case 
			when t2apolclav is null then FechaImputacion 
			else @Ayer 
		end as FecImpIni
		,cast('20501230' as datetime) as FecImpFin
		,sitpoliza,
		causaanulacion,
		frt,
		fnacconductor,
		fnactomador,
		niftomador,
		codpostal,
		sexotomador,
		matricula
		,idmodelo,
		valorvehiculo,
		valoraccesorios,
		fechaconstruccion,
		tipoveh,
		descuentos,
		Ocupantes,
		Añopenalizacion,
		FirmaNuevaRC,
		SaldoActual
		,Flota,
		Colectivo
		,case 
			when t2apolclav is null then 1
			else 0 
		end as NuevaProd		
		,getdate() as F_carga
		,isnull(frecuenciapago,'A') as frecuenciapago
		,FNacCROcasional
		,FRTCROcasional
		,SexoCROcasional
		,RelacionCROConductor
		,GarantiaMecanica
		,VehiculoNuevo
		,IdNegocio
		,UsoVehiculo
		,Tarifa
		,VersionTarifa						    
		,codCoefBonificacion
		,NivelBonificacion
		,SujetoANormativa
		,Lunas
		,ProProducto
		,LunasFP
		,presenciaasnef
		,riskscore
		,severityscore
		,GarantiaMecanicaFP
		,Asistencia
		,AmbitoAsistencia
		,IdOficina
		,idSolicitud
		,id15PuntosCarnet
        ,FechaFinContratoRenting
		--,idNegocioCierre
		,Cod_Agreg_Cruce
		,FechaVencimiento

		,Telefono
		,AñoAdquisicion
		,KMAño
		,LugarAparcamiento
		,NPlazasAseg
		,EstadoCivil
		,UsoVehiculoAct
		,DescuentoObligatorio
		,DescuentoVoluntario
		,DescuentoOcupantes
	into		
		tmp.xautos_dbo.xpolizas_imputacion
	from
	
		(
		select
			isnull(t1.apolclav,t2.apolclav) as Apolclav
			,case 
				when t1.sitpoliza is not null then t1.sitpoliza --caso normal
				when t2.FechaEntrada>@Ayer then 'F' --desaparici¢n de p¢liza, caso raro con flotas
				else 'A'
			end as sitpoliza
			,isnull(t1.causaanulacion,t2.causaanulacion) as causaanulacion
			,case 
				when t1.apolclav is null then t2.fnactomador else t1.fnactomador 
				end as fnactomador --ojo que no vale is null por si pasan el valor a null de un registro existente
			,case 
				when t1.apolclav is null then t2.fnacconductor else t1.fnacconductor 
				end as fnacconductor --ojo que no vale is null por si pasan el valor a null de un registro existente
			,case when t1.apolclav is null then t2.sexotomador else t1.sexotomador end as sexotomador --ojo que no vale is null por si pasan el valor a null de un registro existente
			,isnull(t1.niftomador,t2.niftomador) as niftomador
			,isnull(t1.codpostal,t2.codpostal) as codpostal
			,isnull(t1.producto,t2.producto) as producto
			,case when t1.apolclav is null then t2.frt else t1.frt end as frt --ojo que no vale is null por si pasan el valor a null de un registro existente
			,isnull(t1.idmodelo,t2.idmodelo) as idmodelo
			,isnull(t1.matricula,t2.matricula) as matricula
			,isnull(t1.valorvehiculo,t2.valorvehiculo) as valorvehiculo
			,isnull(t1.valoraccesorios,t2.valoraccesorios) as valoraccesorios
			,case when t1.apolclav is null then t2.fechaconstruccion else t1.fechaconstruccion end as fechaconstruccion --ojo que no vale is null por si pasan el valor a null de un registro existente			
			,isnull(t1.tipoveh,t2.tipoveh) as tipoveh
			,isnull(t1.descuentos,t2.descuentos) as descuentos
			,isnull(t1.Ocupantes,t2.Ocupantes) as  Ocupantes 
			,case when t1.apolclav is null then t2.Añopenalizacion else t1.Añopenalizacion end as Añopenalizacion --ojo que no vale is null por si pasan el valor a null de un registro existente
			,case when t1.apolclav is null then t2.FirmaNuevaRC else t1.FirmaNuevaRC end as FirmaNuevaRC --ojo que no vale is null por si pasan el valor a null de un registro existente			
			,isnull(t1.SaldoActual,t2.SaldoActual) as SaldoActual
			,isnull(t1.Flota,t2.Flota) as Flota
			,isnull(t1.Colectivo,t2.Colectivo) as Colectivo
			,isnull(t1.fechacontratacion,t2.fechacontratacion) as fechacontratacion
			,isnull(t1.fechaimputacion,t2.fechaimputacion) as fechaimputacion
			,t1.apolclav as t1apolclav
			,t2.apolclav as t2apolclav
			,t1.sitpoliza as t1sitpoliza
			,t2.sitpoliza as t2sitpoliza
			,ISNULL(t1.frecuenciapago,t2.frecuenciapago) as frecuenciapago
			,ISNULL(t1.SexoCROcasional,t2.SexoCROcasional) as SexoCROcasional
			,case when t1.apolclav is null then t2.fnacCROcasional else t1.fnacCROcasional end as fnacCROcasional --ojo que no vale is null por si pasan el valor a null de un registro existente			
			,case when t1.apolclav is null then t2.FRTCROcasional else t1.FRTCROcasional end as FRTCROcasional --ojo que no vale is null por si pasan el valor a null de un registro existente			
			,ISNULL(t1.RelacionCROConductor,t2.RelacionCROConductor) as RelacionCROConductor
			,ISNULL(t1.GarantiaMecanica,t2.GarantiaMecanica) as GarantiaMecanica
			,ISNULL(t1.VehiculoNuevo,t2.VehiculoNuevo) as VehiculoNuevo
			,ISNULL(t1.IdNegocio,t2.IdNegocio) as IdNegocio
			,ISNULL(t1.UsoVehiculo,t2.UsoVehiculo) as UsoVehiculo
			,ISNULL(t1.Tarifa,t2.Tarifa) as Tarifa
			,ISNULL(t1.VersionTarifa,t2.VersionTarifa) as VersionTarifa
			,ISNULL(t1.codCoefBonificacion,t2.codCoefBonificacion) as codCoefBonificacion
			,ISNULL(t1.NivelBonificacion,t2.NivelBonificacion) as NivelBonificacion
			,ISNULL(t1.SujetoANormativa,t2.SujetoANormativa) as SujetoANormativa
			,ISNULL(t1.Lunas,t2.Lunas) as Lunas
			,ISNULL(t1.ProProducto,t2.ProProducto) as ProProducto
			,ISNULL(t1.LunasFP,t2.LunasFP) AS LunasFP
			,ISNULL(t1.presenciaasnef,t2.presenciaasnef) as presenciaasnef
			,ISNULL(t1.riskscore,t2.riskscore) as riskscore
			,ISNULL(t1.severityscore,t2.severityscore) AS severityscore
			,ISNULL(t1.GarantiaMecanicaFP,t2.GarantiaMecanicaFP) AS GarantiaMecanicaFP
			,ISNULL(t1.Asistencia,t2.Asistencia) AS Asistencia
			,ISNULL(t1.AmbitoAsistencia,t2.AmbitoAsistencia) AS AmbitoAsistencia
			,case when t1.apolclav is null then t2.IdOficina else t1.IdOficina end as IdOficina --ojo que no vale is null por si pasan el valor a null de un registro existente	
			,ISNULL(t1.idSolicitud,t2.idSolicitud) AS idSolicitud						
			,ISNULL(t1.id15PuntosCarnet,t2.id15PuntosCarnet) AS id15PuntosCarnet
			,ISNULL(t1.FechaFinContratoRenting,t2.FechaFinContratoRenting) AS FechaFinContratoRenting
            --,ISNULL(t1.idNegocioCierre,t2.IdNegocioCierre) AS  idNegocioCierre
			,isnull(t1.Cod_Agreg_Cruce,t2.Cod_Agreg_Cruce) as Cod_Agreg_Cruce
			,ISNULL(t1.FechaVencimiento,t2.FechaVencimiento) AS  FechaVencimiento

			,ISNULL(t1.Telefono,t2.Telefono) AS  Telefono
			,ISNULL(t1.AñoAdquisicion,t2.AñoAdquisicion) AS  AñoAdquisicion
			,ISNULL(t1.KMAño,t2.KMAño) AS  KMAño
			,ISNULL(t1.LugarAparcamiento,t2.LugarAparcamiento) AS  LugarAparcamiento
			,ISNULL(t1.NPlazasAseg,t2.NPlazasAseg) AS  NPlazasAseg
			,ISNULL(t1.EstadoCivil,t2.EstadoCivil) AS  EstadoCivil
			,ISNULL(t1.UsoVehiculoAct,t2.UsoVehiculoAct) AS  UsoVehiculoAct
			,ISNULL(t1.DescuentoObligatorio,t2.DescuentoObligatorio) AS  DescuentoObligatorio
			,ISNULL(t1.DescuentoVoluntario,t2.DescuentoVoluntario) AS  DescuentoVoluntario
			,ISNULL(t1.DescuentoOcupantes,t2.DescuentoOcupantes) AS  DescuentoOcupantes

		from
			(
				select 
				xp.apolclav
				,sitpoliza
				,fnactomador
				,fnacconductor
				,sexotomador
				,niftomador
				,codpostal
				,xpc.fechaimputacion
				,producto
				,causaanulacion
				,frt
				,xp.idmodelo
				,xp.matricula
				,valorvehiculo
				,valoraccesorios
				,xv.fechaconstruccion
				,tipoveh
				,descuentos
				,FechaContratacion
				,Ocupantes
				,Añopenalizacion
				,FirmaNuevaRC
				,SaldoActual	
				,Flota
				,Colectivo
				,frecuenciapago
				,xp.SexoCROcasional
				,xp.FNacCROcasional
				,xp.FRTCROcasional
				,xp.RelacionCROConductor
				,xp.garantiamecanica
				,xv.VehiculoNuevo
				,xpc.IdNegocio
				,xp.UsoVehiculo
				,xp.Tarifa
				,xp.VersionTarifa	
				,xp.codCoefBonificacion
				,xp.NivelBonificacion
				,xp.SujetoANormativa
				,xp.Lunas
				,xp.ProProducto
				,xp.LunasFP
				,xp.presenciaasnef
				,xp.riskscore
				,xp.severityscore
				,xp.GarantiaMecanicaFP
				,xp.Asistencia
				,xp.AmbitoAsistencia
				,xp.IdOficina
				,xp.idSolicitud
				,xp.id15PuntosCarnet
				,xpc.FechaFinContratoRenting
                --,xpc.idNegocioCierre
				,xpc.Cod_Agreg_Cruce
				,xpc.FechaVencimiento

				,xp.Telefono
				,xp.AñoAdquisicion
				,xp.KMAño
				,xp.LugarAparcamiento
				,xp.NPlazasAseg
				,xp.EstadoCivil
				,xp.UsoVehiculoAct
				,xp.DescuentoObligatorio
				,xp.DescuentoVoluntario
				,xp.DescuentoOcupantes
			from 
				xpolizas xp
				inner join
				xpolizas_comun xpc
			on
				xp.apolclav=xpc.apolclav
				and @Ayer between fechamovini and fechamovfin
				and xpc.fechaimputacion<cast(getdate() as date)
			inner join 
				MARCAS mc
			on 
				xp.IdModelo=mc.Id
			inner join	
				xvehiculo xv
			on
				xp.matricula=xv.matricula
				and xp.apolclav=xv.apolclav
		) t1
		
		full outer join
		
		( select 
				xpi.apolclav
				,xpi.sitpoliza
				,xpi.fnactomador
				,xpi.fnacconductor
				,xpi.sexotomador
				,xpi.niftomador
				,xpi.codpostal
				,xpc.FechaContratacion
				,xpc.FechaEntrada
				,xpc.fechaimputacion
				,xpi.producto
				,xpi.causaanulacion
				,xpi.frt
				,xpi.idmodelo
				,xpi.matricula
				,xpi.valorvehiculo
				,xpi.valoraccesorios
				,xpi.fechaconstruccion
				,xpi.tipoveh
				,xpi.descuentos
				,Ocupantes
				,xpi.Añopenalizacion
				,xpi.FirmaNuevaRC
				,xpi.SaldoActual
				,xpi.Flota
				,xpi.Colectivo
				,xpi.frecuenciapago
				,xpi.SexoCROcasional
				,xpi.FNacCROcasional
				,xpi.FRTCROcasional
				,xpi.RelacionCROConductor
				,xpi.garantiamecanica
				,xpi.VehiculoNuevo
				,xpi.IdNegocio
				,xpi.UsoVehiculo
				,xpi.Tarifa
				,xpi.VersionTarifa	
			    ,xpi.codCoefBonificacion
			    ,xpi.NivelBonificacion
			    ,xpi.SujetoANormativa
			    ,xpi.Lunas
			    ,xpi.ProProducto
			    ,xpi.LunasFP
			    ,xpi.presenciaasnef
				,xpi.riskscore
			    ,xpi.severityscore
			    ,xpi.GarantiaMecanicaFP
			    ,xpi.Asistencia
			    ,xpi.AmbitoAsistencia
			    ,xpi.IdOficina
			    ,xpi.idSolicitud 
			    ,xpi.id15puntosCarnet 
			    ,xpi.FechaFinContratoRenting
			    --,xpi.idNegocioCierre
				,xpi.Cod_Agreg_Cruce
				,xpi.FechaVencimiento

				,xpi.Telefono
				,xpi.AñoAdquisicion
				,xpi.KMAño
				,xpi.LugarAparcamiento
				,xpi.NPlazasAseg
				,xpi.EstadoCivil
				,xpi.UsoVehiculoAct
				,xpi.DescuentoObligatorio
				,xpi.DescuentoVoluntario
				,xpi.DescuentoOcupantes
		 from 
			xpolizas_imputacion  xpi
			left join
			xpolizas_comun xpc
			on xpi.apolclav=xpc.apolclav				
		 where 
			fecimpfin='20501230' 
		) t2 
		
		on
			t1.apolclav=t2.apolclav
			
		where
		(  t1.apolclav  is not null and
			not(
				isnull(t1.producto,'') = isnull(t2.producto,'')
				and isnull(t1.Sitpoliza,'') = isnull(t2.Sitpoliza,'')
				and isnull(t1.frt,'19000101') = isnull(t2.frt,'19000101')
				and isnull(t1.FnacConductor,'19000101') = isnull(t2.FnacConductor,'19000101')
				and isnull(t1.FnacTomador,'19000101') = isnull(t2.FnacTomador,'19000101')
				and isnull(t1.niftomador,'') = isnull(t2.niftomador,'')
				and isnull(t1.codpostal,'') = isnull(t2.codpostal,'')
				and isnull(t1.Sexotomador,'') = isnull(t2.Sexotomador,'')
				and isnull(t1.Matricula,'') = isnull(t2.Matricula,'')
				and isnull(t1.idmodelo,0) = isnull(t2.idmodelo,0)
				and isnull(t1.valorvehiculo,0) = isnull(t2.valorvehiculo,0)
				and isnull(t1.ValorAccesorios,0) = isnull(t2.ValorAccesorios,0)
				and isnull(t1.FechaConstruccion,'19000101') = isnull(t2.FechaConstruccion,'19000101')
				and isnull(t1.TipoVeh,'') = isnull(t2.TipoVeh,'')
				and isnull(t1.Descuentos,'') = isnull(t2.Descuentos,'')
				and isnull(t1.Ocupantes,0) = isnull(t2.Ocupantes,0)
				and isnull(t1.AñoPenalizacion,0) = isnull(t2.AñoPenalizacion,0)
				and isnull(t1.FirmaNuevaRC,'') = isnull(t2.FirmaNuevaRC,'')
				and isnull(t1.SaldoActual,0) = isnull(t2.SaldoActual,0)
				and isnull(t1.Flota,'') = isnull(t2.Flota,'')
				and isnull(t1.Colectivo,'') = isnull(t2.Colectivo,'')
				and isnull(t1.FrecuenciaPago,'') = isnull(t2.FrecuenciaPago,'')
				and isnull(t1.FNacCROcasional,'19000101') = isnull(t2.FNacCROcasional,'19000101')
				and isnull(t1.FRTCROcasional,'19000101') = isnull(t2.FRTCROcasional,'19000101')
				and isnull(t1.SexoCROcasional,'') = isnull(t2.SexoCROcasional,'')
				and isnull(t1.RelacionCROConductor,'') = isnull(t2.RelacionCROConductor,'')
				and isnull(t1.GarantiaMecanica,'') = isnull(t2.GarantiaMecanica,'')
				and isnull(t1.VehiculoNuevo,'') = isnull(t2.VehiculoNuevo,'')
				and isnull(t1.IdNegocio,'') = isnull(t2.IdNegocio,'')
				and isnull(t1.UsoVehiculo,'') = isnull(t2.UsoVehiculo,'')
				and isnull(t1.Tarifa,'') = isnull(t2.Tarifa,'')
				and isnull(t1.VersionTarifa,0) = isnull(t2.VersionTarifa,0)
				and isnull(t1.codCoefBonificacion,'') = isnull(t2.codCoefBonificacion,'')
				and isnull(t1.NivelBonificacion,0) = isnull(t2.NivelBonificacion,0)
				and isnull(t1.SujetoANormativa,'') = isnull(t2.SujetoANormativa,'')
				and isnull(t1.Lunas,'') = isnull(t2.Lunas,'')
				and isnull(t1.ProProducto,'') = isnull(t2.ProProducto,'')
				and isnull(t1.LunasFP,'') = isnull(t2.LunasFP,'')
				and isnull(t1.PresenciaAsnef,'') = isnull(t2.PresenciaAsnef,'')
				and isnull(t1.RiskScore,'') = isnull(t2.RiskScore,'')
				and isnull(t1.SeverityScore,'') = isnull(t2.SeverityScore,'')
				and isnull(t1.GarantiaMecanicaFP,'') = isnull(t2.GarantiaMecanicaFP,'')
				and isnull(t1.Asistencia,'') = isnull(t2.Asistencia,'')
				and isnull(t1.AmbitoAsistencia,'') = isnull(t2.AmbitoAsistencia,'')
				and isnull(t1.IdOficina,0) = isnull(t2.IdOficina,0)
				and isnull(t1.idSolicitud,0) = isnull(t2.IdSolicitud,0)
				and isnull(t1.id15PuntosCarnet,0) = isnull(t2.Id15PuntosCarnet, 0)
				--and isnull(t1.IdNegocioCierre,0) = isnull(t2.IdNegocioCierre, 0)
				and isnull(t1.Cod_Agreg_Cruce,'ZZZZZZZX') = isnull(t2.Cod_Agreg_Cruce,'ZZZZZZZX')
				and ISNULL(t1.FechaFinContratoRenting,'19000101') = ISNULL(t2.FechaFinContratoRenting,'19000101')
				and ISNULL(t1.FechaVencimiento,'19000101') = ISNULL(t2.FechaVencimiento,'19000101')

				and ISNULL(t1.Telefono,0) = ISNULL(t2.Telefono,0)
				and ISNULL(t1.AñoAdquisicion,0) = ISNULL(t2.AñoAdquisicion,0)
				and ISNULL(t1.KMAño,0) = ISNULL(t2.KMAño,0)
				and ISNULL(t1.LugarAparcamiento,'') = ISNULL(t2.LugarAparcamiento,'')
				and ISNULL(t1.NPlazasAseg,0) = ISNULL(t2.NPlazasAseg,0)
				and ISNULL(t1.EstadoCivil,'') = ISNULL(t2.EstadoCivil,'')
				and ISNULL(t1.UsoVehiculoAct,'') = ISNULL(t2.UsoVehiculoAct,'')
				and ISNULL(t1.DescuentoObligatorio,0) = ISNULL(t2.DescuentoObligatorio,0)
				and ISNULL(t1.DescuentoVoluntario,0) = ISNULL(t2.DescuentoVoluntario,0)
				and ISNULL(t1.DescuentoOcupantes,0) = ISNULL(t2.DescuentoOcupantes,0)		
			)
		)	
			
		or (t1.apolclav  is null and t2.producto<>'0XXX' and t2.sitpoliza in ('V','S')) 
		or t2.apolclav is null	
		)s
			
			/*select 
				xp.apolclav
				,sitpoliza
				,fnactomador
				,fnacconductor
				,sexotomador
				,niftomador
				,codpostal
				,xpc.fechaimputacion
				,producto
				,causaanulacion
				,frt
				,xp.idmodelo
				,xp.matricula
				,valorvehiculo
				,valoraccesorios
				,xv.fechaconstruccion
				,tipoveh
				,descuentos
				,FechaContratacion
				,Ocupantes
				,Añopenalizacion
				,FirmaNuevaRC
				,SaldoActual	
				,Flota
				,Colectivo
				,frecuenciapago
				,xp.SexoCROcasional
				,xp.FNacCROcasional
				,xp.FRTCROcasional
				,xp.RelacionCROConductor
				,xp.garantiamecanica
				,xv.VehiculoNuevo
				,xpc.IdNegocio
				,xp.UsoVehiculo
				,xp.Tarifa
				,xp.VersionTarifa	
				,xp.codCoefBonificacion
				,xp.NivelBonificacion
				,xp.SujetoANormativa
				,xp.Lunas
				,xp.ProProducto
				,xp.LunasFP
				,xp.presenciaasnef
				,xp.riskscore
				,xp.severityscore
				,xp.GarantiaMecanicaFP
				,xp.Asistencia
				,xp.AmbitoAsistencia
				,xp.IdOficina
				,binary_checksum(
				                  producto,sitpoliza,frt,fnacconductor,fnactomador,niftomador,codpostal,sexotomador,xp.matricula,xp.idmodelo,valorvehiculo,valoraccesorios,xv.fechaconstruccion,tipoveh,descuentos,Ocupantes,Añopenalizacion,FirmaNuevaRC,SaldoActual,Flota,Colectivo
				                  ,frecuenciapago,xp.SexoCROcasional,xp.FNacCROcasional,xp.FRTCROcasional,xp.RelacionCROConductor ,xp.garantiamecanica,xv.VehiculoNuevo,xpc.IdNegocio,xp.UsoVehiculo,xp.Tarifa,xp.VersionTarifa,xp.codCoefBonificacion,xp.NivelBonificacion,xp.SujetoANormativa,xp.Lunas,xp.ProProducto,xp.LunasFP
				                 ,xp.presenciaasnef
				                 ,xp.riskscore
				                 ,xp.severityscore
				                 ,xp.GarantiaMecanicaFP
				                 ,xp.Asistencia
				                 ,xp.AmbitoAsistencia
				                 ,xp.IdOficina
				                 ) as b1
				,checksum(producto,sitpoliza,frt,fnacconductor,fnactomador,niftomador,codpostal,sexotomador,xp.matricula,xp.idmodelo,valorvehiculo,valoraccesorios,xv.fechaconstruccion,tipoveh,descuentos,Ocupantes,Añopenalizacion,FirmaNuevaRC,SaldoActual,Flota,Colectivo
				                   ,frecuenciapago,xp.SexoCROcasional,xp.FNacCROcasional,xp.FRTCROcasional,xp.RelacionCROConductor ,xp.garantiamecanica,xv.VehiculoNuevo,xpc.IdNegocio,xp.UsoVehiculo,xp.Tarifa,xp.VersionTarifa,xp.codCoefBonificacion,xp.NivelBonificacion,xp.SujetoANormativa,xp.Lunas,xp.ProProducto,xp.LunasFP
				                   ,xp.presenciaasnef
				                   ,xp.riskscore
				                   ,xp.severityscore
				                   ,xp.GarantiaMecanicaFP
				                   ,xp.Asistencia
				                   ,xp.AmbitoAsistencia
				                   ,xp.IdOficina
				                   )  as b1a
			from 
				xpolizas xp
				/*(select xp1.*, 
					    case when efe.apolclav is null then 0
					    else 1 end as efe29
					    from xpolizas xp1 left join TMP.XAUTOS_DBO.XPOLIZAS_EFECTO_29022012 efe on 
							xp1.apolclav = efe.apolclav) xp*/
				inner join
				xpolizas_comun xpc
			on
				xp.apolclav=xpc.apolclav
				and @Ayer between fechamovini and fechamovfin
				/*
				( (@Ayer between fechamovini and fechamovfin and xp.efe29=0) OR
				  ('20120301' between fechamovini and fechamovfin and xp.efe29=1))*/
				and xpc.fechaimputacion<cast(getdate() as date) --para que no se cuelen p¢lizas del dia en curso
			inner join 
				MARCAS mc
			on 
				xp.IdModelo=mc.Id
			inner join	
				xvehiculo xv
			on
				xp.matricula=xv.matricula
				and xp.apolclav=xv.apolclav
				/* NO SE PUEDE PONER INCREMENTAL YA QUE SI SE HACE ASI AL SER FULL DETECTA EN LOS INCREMENTALES TODOS COMO BORRADOS*/
			) t1
		full outer join 
			(
			 select 
					xpi.apolclav
					,xpi.sitpoliza
					,xpi.fnactomador
					,xpi.fnacconductor
					,xpi.sexotomador
					,xpi.niftomador
					,xpi.codpostal
					,xpc.FechaContratacion
					,xpc.FechaEntrada
					,xpc.fechaimputacion
					,xpi.producto
					,xpi.causaanulacion
					,xpi.frt
					,xpi.idmodelo
					,xpi.matricula
					,xpi.valorvehiculo
					,xpi.valoraccesorios
					,xpi.fechaconstruccion
					,xpi.tipoveh
					,xpi.descuentos
					,Ocupantes
					,xpi.Añopenalizacion
					,xpi.FirmaNuevaRC
					,xpi.SaldoActual
					,xpi.Flota
					,xpi.Colectivo
					,xpi.frecuenciapago
					,xpi.SexoCROcasional
					,xpi.FNacCROcasional
					,xpi.FRTCROcasional
					,xpi.RelacionCROConductor
					,xpi.garantiamecanica
					,xpi.VehiculoNuevo
					,xpi.IdNegocio
					,xpi.UsoVehiculo
					,xpi.Tarifa
					,xpi.VersionTarifa	
				    ,xpi.codCoefBonificacion
				    ,xpi.NivelBonificacion
				    ,xpi.SujetoANormativa
				    ,xpi.Lunas
				    ,xpi.ProProducto
				    ,xpi.LunasFP
				    ,xpi.presenciaasnef
					,xpi.riskscore
				    ,xpi.severityscore
				    ,xpi.GarantiaMecanicaFP
				    ,xpi.Asistencia
				    ,xpi.AmbitoAsistencia
				    ,xpi.IdOficina
					,binary_checksum(xpi.producto,xpi.sitpoliza,xpi.frt,xpi.fnacconductor,xpi.fnactomador,xpi.niftomador,xpi.codpostal,xpi.sexotomador,xpi.matricula,xpi.idmodelo,xpi.valorvehiculo,xpi.valoraccesorios,xpi.fechaconstruccion,xpi.tipoveh,xpi.descuentos,xpi.Ocupantes,xpi.Añopenalizacion,xpi.FirmaNuevaRC,xpi.SaldoActual,xpi.Flota,xpi.Colectivo
										,xpi.frecuenciapago
										,xpi.SexoCROcasional,xpi.FNacCROcasional,xpi.FRTCROcasional,xpi.RelacionCROConductor,xpi.garantiamecanica,xpi.VehiculoNuevo,xpi.IdNegocio,xpi.UsoVehiculo,xpi.Tarifa,xpi.VersionTarifa,xpi.codCoefBonificacion,xpi.NivelBonificacion,xpi.SujetoANormativa,xpi.Lunas,xpi.ProProducto,xpi.LunasFP
										 ,xpi.presenciaasnef
									     ,xpi.riskscore
				                         ,xpi.severityscore
				                         ,xpi.GarantiaMecanicaFP
				                         ,xpi.Asistencia
				                         ,xpi.AmbitoAsistencia
				                         ,xpi.IdOficina
				                         )  as b2
					,checksum(xpi.producto,xpi.sitpoliza,xpi.frt,xpi.fnacconductor,xpi.fnactomador,xpi.niftomador,xpi.codpostal,xpi.sexotomador,xpi.matricula,xpi.idmodelo,xpi.valorvehiculo,xpi.valoraccesorios,xpi.fechaconstruccion,xpi.tipoveh,xpi.descuentos,xpi.Ocupantes,xpi.Añopenalizacion,xpi.FirmaNuevaRC,xpi.SaldoActual,xpi.Flota,xpi.Colectivo
										,xpi.frecuenciapago
										,xpi.SexoCROcasional,xpi.FNacCROcasional,xpi.FRTCROcasional,xpi.RelacionCROConductor,xpi.garantiamecanica,xpi.VehiculoNuevo,xpi.IdNegocio,xpi.UsoVehiculo,xpi.Tarifa,xpi.VersionTarifa,xpi.codCoefBonificacion,xpi.NivelBonificacion,xpi.SujetoANormativa,xpi.Lunas,xpi.ProProducto,xpi.LunasFP
										,xpi.presenciaasnef
									    ,xpi.riskscore
				                        ,xpi.severityscore
				                        ,xpi.GarantiaMecanicaFP
				                        ,xpi.Asistencia
				                        ,xpi.AmbitoAsistencia
				                        ,xpi.IdOficina
				                        )  as b2a
			 from 
				xpolizas_imputacion  xpi
				left join
				xpolizas_comun xpc
				on xpi.apolclav=xpc.apolclav				
			 where 
				fecimpfin='20501230'
			) t2 
		on
			t1.apolclav=t2.apolclav
		) s
	where
		(b1<>b2 or b1a<>b2a or (t1apolclav  is null and producto<>'0XXX' and t2sitpoliza in ('V','S')) or t2apolclav is null) 
*/

	set @Msg='Polizas con cambios detectados: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','M',1



	/*
	
	EJECUTAR SOLO SI HEMOS SALTADO DIAS DE CARGA DE ESTA TABLA Y SE HA CARGADO TODO EL DW Y EL X YA
	NO ES VALIDO SI NO SE HAN EXTRAIDO LOS FICHEROS DIA A DIA YA  QUE SE BASA EN LA FECHA DE GENERACION
	OPERATIVA TIENE QUE ESTAR CARGADA 


	drop table tmp.xautos_dbo.xpolizas_imputacion_correccion
	select
		*
	into
		tmp.xautos_dbo.xpolizas_imputacion_correccion
	from
		(
		select 
			emision
			,efecto
			,case when emision>efecto then emision else efecto end as imputacion
			,apolclav	
		from
			(		
			select 
				(select cast(fec_generacion-1 as date) as Fec_generacion from dw_autos..mov_polizas mp where mp.apolclav=xpi.apolclav and mp.apolfefe='20501231') as Emision
				,(select max(fechamovini) from xautos..xpolizas xp where xp.apolclav=xpi.apolclav) as Efecto
				,* 
			from 
				tmp.xautos_dbo.xpolizas_imputacion xpi
			where 
				primermovimiento<>1
			) s
		) s2
	where
		imputacion between (select max(fecimpini) from xautos..xpolizas_imputacion) and cast(getdate()-1 as date)
		
	 
	update
		t
	set 
		t.fecimpini=c.imputacion
	from
		tmp.xautos_dbo.xpolizas_imputacion t
	inner join
		tmp.xautos_dbo.xpolizas_imputacion_correccion c
	on
		t.apolclav=c.apolclav
	where
		t.fecimpini<>c.imputacion
	 
	*/	 

	--rhr 17/01/2017 para pruebas
	exec  comun..eliminatabla 'BI_PRODUCCION.dbo.xpolizas_imputacion_pr_antes_movimientos_20501230'
	select *
	into  BI_PRODUCCION.dbo.xpolizas_imputacion_pr_antes_movimientos_20501230
	from tmp.xautos_dbo.xpolizas_imputacion
	 

--Tengo que actualizar los movimientos 2050 que ya tengo en la final, para ello los inserto aqui cerrados para que se sobreescriban

	
	insert into tmp.xautos_dbo.xpolizas_imputacion with (tablock)
	select
		i.apolclav
		,i.producto
		,i.primermovimiento
		,i.FecImpIni
		,dateadd(dd,-1,t.fecimpini) as FecImpFin
		,i.sitpoliza
		,i.CausaAnulacion
		,i.frt,i.fnacconductor,i.fnactomador,i.niftomador,i.codpostal
		,i.sexotomador,i.matricula
		,i.idmodelo,i.valorvehiculo,i.valoraccesorios,i.fechaconstruccion
		,i.tipoveh,i.descuentos,i.Ocupantes,i.Añopenalizacion,i.FirmaNuevaRC,i.SaldoActual
		,i.Flota,i.Colectivo
		,0 as nuevaprod		
		,getdate() as F_carga
		,isnull(i.frecuenciapago,'A') frecuenciapago	
		,i.FNacCROcasional,i.FRTCROcasional,i.SexoCROcasional,i.RelacionCROConductor	
		,i.GarantiaMecanica
		,i.VehiculoNuevo
		,i.IdNegocio
		,i.UsoVehiculo
		,i.Tarifa
		,i.VersionTarifa	
		,i.codCoefBonificacion
		,i.NivelBonificacion
		,i.SujetoANormativa
		,i.Lunas
		,i.ProProducto
		,i.LunasFP
		,i.presenciaasnef
		,i.riskscore
		,i.severityscore
		,i.GarantiaMecanicaFP
		,i.Asistencia
		,i.AmbitoAsistencia
		,i.IdOficina
		,i.idSolicitud 
		,i.id15PuntosCarnet 
		,i.FechaFinContratoRenting
		--,i.idNegocioCierre
		,i.Cod_Agreg_Cruce
	    ,i.FechaVencimiento

		,i.Telefono
		,i.AñoAdquisicion
		,i.KMAño
		,i.LugarAparcamiento
		,i.NPlazasAseg
		,i.EstadoCivil
		,i.UsoVehiculoAct
		,i.DescuentoObligatorio
		,i.DescuentoVoluntario
		,i.DescuentoOcupantes
	from
		xpolizas_imputacion i
		inner join
		tmp.xautos_dbo.xpolizas_imputacion t 
	on
		t.apolclav=i.apolclav	
	where
		i.fecimpfin='20501230'
		and i.FecImpIni<>t.FecImpIni -- esto permite recargar dos veces el mismo dia
	
 
	set @Msg='Movimientos para actualizar de la final: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','M',1



--Inserto las contrataciones a futuro

	--delete from  dbo.xpolizas_imputacion where sitpoliza='F'
	
	
	insert into tmp.xautos_dbo.xpolizas_imputacion
	 select 
		xp.apolclav
		,producto
		,1 as primermovimiento
		,case when FechaContratacion > @Ayer then @Ayer else FechaContratacion end as FecImpIni
		--,FechaContratacion as FecImpIni
		,case --para recargas en las que saltamos dias
			when exists(select * from tmp.xautos_dbo.xpolizas_imputacion i where xp.apolclav=i.apolclav) then (select dateadd(dd,-1,min(fecimpini)) from tmp.xautos_dbo.xpolizas_imputacion i where xp.apolclav=i.apolclav and i.fecimpini>xpc.fechacontratacion) 
			else '20501230' 
		end as FecImpFin
		,'F' as sitpoliza
		,CausaAnulacion
		,frt,fnacconductor,fnactomador,niftomador,codpostal,sexotomador,xp.matricula
		,xp.idmodelo,valorvehiculo,valoraccesorios,xv.fechaconstruccion,tipoveh,descuentos,Ocupantes,Añopenalizacion,FirmaNuevaRC,SaldoActual
		,Flota,Colectivo
		,1 as nuevaprod
		,getdate() as F_carga
		,isnull(frecuenciapago,'A') frecuenciapago
		,xp.FNacCROcasional,xp.FRTCROcasional,xp.SexoCROcasional,xp.RelacionCROConductor
		,GarantiaMecanica
		,VehiculoNuevo
		,xpc.IdNegocio
		,xp.UsoVehiculo
		,xp.Tarifa
		,xp.VersionTarifa	
		,xp.codCoefBonificacion
		,xp.NivelBonificacion
		,xp.SujetoANormativa
		,xp.Lunas
		,xp.ProProducto
		,xp.LunasFP
		,xp.presenciaasnef
		,xp.riskscore
		,xp.severityscore
		,xp.GarantiaMecanicaFP
		,xp.Asistencia
		,xp.AmbitoAsistencia
		, CASE
			WHEN xp.IdNegocio IS NULL OR xp.IdNegocio = '0' THEN 9999999
			WHEN ISNULL ( xp.IdNegocio , '0' ) <> '0' AND ( xp.IdOficina = 0 OR xp.IdOficina IS NULL OR xp.IdOficina = 9999999 ) THEN 9999998
			ELSE xp.IdOficina
		  END					AS 'IdOficina'
		 , idSolicitud 
		 ,id15PuntosCarnet 		 
		 ,xpc.FechaFinContratoRenting
		 --,xpc.idNegocioCierre
		 ,xpc.Cod_Agreg_Cruce
		 ,xpc.FechaVencimiento

		 ,xp.Telefono
		 ,xp.AñoAdquisicion
		 ,xp.KMAño
		 ,xp.LugarAparcamiento
		 ,xp.NPlazasAseg
		 ,xp.EstadoCivil
		 ,xp.UsoVehiculoAct
		 ,xp.DescuentoObligatorio
		 ,xp.DescuentoVoluntario
		 ,xp.DescuentoOcupantes
	 from  
		xpolizas xp
	 inner join
		xpolizas_comun xpc
	 on
		xp.apolclav=xpc.apolclav
		and xp.fechaentrada=xp.fechamovini
	 inner join
	    MARCAS mc
	 on 
		xp.IdModelo=mc.Id
	inner join	
		xvehiculo xv
	on
		xp.matricula=xv.matricula
		and xp.apolclav=xv.apolclav
	 where 
		--xpc.f_carga>@UltimaFcargaX
		--and
		 xpc.fechacontratacion<xpc.fechaentrada
		and not exists(select * from xpolizas_imputacion i where xp.apolclav=i.apolclav)


	set @Msg='Nueva contratacion a futuro: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','M',1

	create unique index ix1 on tmp.xautos_dbo.xpolizas_imputacion(apolclav,fecimpini)
	

	--update xpolizas_imputacion set fecimpini='20091121' where fecimpini='20091122' and apolclav in (select apolclav from tmp.xautos_dbo.xpolizas_imputacion group by apolclav,fecimpini having count(*)>1)	
	--update xpolizas_imputacion set fecimpfin='20091120' where fecimpfin='20091121' and apolclav in (select apolclav from tmp.xautos_dbo.xpolizas_imputacion group by apolclav,fecimpini having count(*)>1)	
	
	
 

--Si recargo saltando dias puede darse el caso de que se inserten mas de un primermovimiento=1, los corrijo.

	update 
		t1
	set 
		primermovimiento=0
	from
		tmp.xautos_dbo.xpolizas_imputacion t1
	where
		primermovimiento=1
		and exists(select * from tmp.xautos_dbo.xpolizas_imputacion t2 where t1.apolclav=t2.apolclav and t2.fecimpini<t1.fecimpini)


	
	set @Msg='Corregidos por primermovimiento erroneo: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','M',1
	
----temporalmente hasta que se actualicen en host los registros

--    update XPI 
--  set idNegocio= case when TMP.Id_Negocio_Futuro='' then '0' else TMP.Id_Negocio_Futuro end, 
--  Cod_Agreg_Cruce=case when TMP.Id_Negocio_Cierre_futuro='' then 'ZZZZZZZX' else TMP.Id_Negocio_Cierre_futuro end
--  from tmp.xautos_dbo.xpolizas_imputacion XPI
--  inner join bi_produccion.dbo.Agregadores_polizas_cambio  TMP
--  ON XPI.apolclav=cast(TMP.Id_Poliza as bigint) and criterio<>'Criterio 7'

		
/*****************************************************************************************************************

--Insertamos un movimiento nuevo con SitPoliza='B' (Borrada) en las pólizas que no estén en xpolizas (a partir del 20120101 (FecImpIni)).

insert into tmp.xautos_dbo.xpolizas_imputacion with (tablock)
	select
		i.apolclav
		,i.producto
		,0 as primermovimiento
		,@Ayer as FecImpIni
		,cast('20501230' as datetime) as FecImpFin
		,'B' as sitpoliza
		,i.CausaAnulacion
		,i.frt,i.fnacconductor,i.fnactomador,i.niftomador,i.codpostal
		,i.sexotomador,i.matricula
		,i.idmodelo,i.valorvehiculo,i.valoraccesorios,i.fechaconstruccion
		,i.tipoveh,i.descuentos,i.Ocupantes,i.Añopenalizacion,i.FirmaNuevaRC,i.SaldoActual
		,i.Flota,i.Colectivo
		,0 as nuevaprod		
		,getdate() as F_carga
		,isnull(i.frecuenciapago,'A') frecuenciapago	
		,i.FNacCROcasional,i.FRTCROcasional,i.SexoCROcasional,i.RelacionCROConductor	
		,i.GarantiaMecanica
		,i.VehiculoNuevo
		,i.IdNegocio
		,i.UsoVehiculo
		,i.Tarifa
		,i.VersionTarifa	
		,i.codCoefBonificacion
		,i.NivelBonificacion
		,i.SujetoANormativa
		,i.Lunas
		,i.ProProducto
		,i.LunasFP
	from
		xpolizas_imputacion i
	where  Apolclav not in (select apolclav from xautos..xpolizas) 
	and FecImpIni>='20120101' and FecImpFin='20501230' and Sitpoliza<>'B'
	
--Tengo que actualizar los movimientos 2050 que ya tengo en la final, para ello los inserto aqui cerrados para que se sobreescriban

insert into tmp.xautos_dbo.xpolizas_imputacion with (tablock)
	select
		apolclav
		,producto
		,primermovimiento
		,FecImpIni
		,dateadd(dd,-1,@Ayer) as FecImpFin --solo cambio la FecImpFin
		,sitpoliza
		,CausaAnulacion
		,frt,fnacconductor,fnactomador,niftomador,codpostal
		,sexotomador,matricula
		,idmodelo,valorvehiculo,valoraccesorios,fechaconstruccion
		,tipoveh,descuentos,Ocupantes,Añopenalizacion,FirmaNuevaRC,SaldoActual
		,Flota,Colectivo
		,0 as nuevaprod		
		,getdate() as F_carga
		,frecuenciapago	
		,FNacCROcasional,FRTCROcasional,SexoCROcasional,RelacionCROConductor	
		,GarantiaMecanica
		,VehiculoNuevo
		,IdNegocio
		,UsoVehiculo
		,Tarifa
		,VersionTarifa	
		,codCoefBonificacion
		,NivelBonificacion
		,SujetoANormativa
		,Lunas
		,ProProducto
		,LunasFP
	from
		xpolizas_imputacion
	where  Apolclav not in (select apolclav from xautos..xpolizas) 
	and FecImpIni>='20120101' and FecImpFin='20501230' and Sitpoliza<>'B'
	

		
	set @Msg='Movimientos para actualizar de la final por pólizas borradas: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','xpolizas_imputacion',@Msg,'C','M',1		
************************************************************************************************************************/

-- Guardamos la tabla Tmp intermedia para evaluar porqu‚ devuelve error la comprobaci¢n de movimientos coherentes existente sobre los datos de la tmp

	--Truncate table dbo.xpolizas_imputacion_bis
	--Insert 	into dbo.xpolizas_imputacion_bis Select * From dbo.xpolizas_imputacion
	--Select * into dbo.xpolizas_imputacion_bis From dbo.xpolizas_imputacion





/*
declare @FiltroInser varchar(100),@FiltroBorrado varchar(100)
if exists(select * from TMP.sys.columns sc inner join TMP.sys.tables st on sc.object_id=st.object_id where sc.name='dw_check_ir' and st.name='XPOLIZAS_IMPUTACION') begin set @FiltroInser='Dw_check_ir is null' set @FiltroBorrado='(dw_check_ir like ''B%'' or dw_check_ir is null)' end else begin set @FiltroBorrado='' set @FiltroInser='' end
exec comun.dbo.CopiarTablasDiferentesCampos 'TMP.XAUTOS_dbo.XPOLIZAS_IMPUTACION','XAUTOS.dbo.XPOLIZAS_IMPUTACION',@FiltroBorrado,@FiltroInser,null,0,1,null,null,null 
exec comun..GestorComprobaciones 'XAUTOS..XPOLIZAS_IMPUTACION',0
update comun..cfg_xdatas set Resultado='OK' where basedatos='XAUTOS' and TablaX='XPOLIZAS_IMPUTACION'

exec REPORTING.prod.Produccion_Diario_Pr_Carga 'I'
exec reporting.comun.Subida_Produccion_Reports 'prod.produccion_diario',0,0,1

--delete prod.produccion_diario_datos2 where cod_fecha>=20091120
*/


/*
/* CODIGO PARA ELIMINAR UNA CARGA

1.Realizar un backup de la tabla
exec comun..eliminatabla 'TMP.Xautos_dbo.Xpolizas_Imputacion_bck'
Select * into TMP.Xautos_dbo.Xpolizas_Imputacion_bck From Xautos..Xpolizas_Imputacion 

2. Eliminamos registros generados en incremental siempre que la siguiente consulta devuelva movimientos
con el valor del campo fecimpini a un d¡a anterior a la fecha actual de carga. 
Si no fuera as¡, abstenerse de continuar este guion y realizar la carga en modo test pasando la fecha '19010101'

	-- select * from xautos..xpolizaS_imputacion where f_carga>='20130403' and fecimpfin='20501230'

	
	-- delete xautos..xpolizaS_imputacion where f_carga>='20130403' and fecimpfin='20501230'

3. Si la el paso anterior es satisfactorio, inicializamos la fechaimpfin de los movimientos actualizados a '20501230':

	-- select * from xautos..xpolizaS_imputacion where f_carga>='20091015' and fecimpfin<>'20501230'

	-- update xautos..xpolizas_imputacion set fecimpfin='20501230' where f_carga>='20091015' and fecimpfin<>'20501230'

select apolclav from  xautos..xpolizaS_imputacion  group by apolclav having max(fecimpfin)<>'20501230' and sum(cast(primermovimiento as int))<>1

*/

 

begin transaction

update 
	x
set 
	fecimpfin='20100518'
--select *	
from
	xautos..xpolizas_imputacion x
inner join
	tmp..xpi z
on
	x.apolclav=z.apolclav
	and fecimpfin='20100519'

update 
	x
set 
	fecimpini='20100519'
--select *
from
	xautos..xpolizas_imputacion x
inner join
	tmp..xpi z
on
	x.apolclav=z.apolclav
	and fecimpini='20100520'
	
commit transaction


exec reporting.[PROD].[produccion_diario_pr_carga]


select fecimpini,count(*) from xautos..xpolizas_imputacion where fecimpini>='20100519' group by fecimpini order by 1
exec comun..gestorcomprobaciones 'xautos..xpolizas_imputacion'
*/

/*

Modificación de los tramos de las pólizas que deben estar en un día particular y por errores en la carga se han pasado al día siguiente.
DROP TABLE TMP.PETICIONES_DBO.XPOLIZAS_IMP
select * 
INTO TMP.PETICIONES_DBO.XPOLIZAS_IMP
from xautos..xpolizas_imputacion xpi (nolock)
where FecImpIni='20130825'
and 
	(
	exists(select 1 from xautos..xpolizas xp (NOLOCK) where fechamovini='20130824' and xp.apolclav=xpi.apolclav)

	or	
	exists(select 1 from dw_autos..mov_polizas xp (NOLOCK) where (apolfemi='20130824' or APOLFUSP='20130824')  and xp.apolclav=xpi.apolclav)
	or 
	exists(select 1 from dw_autos..TAULOGOP t (NOLOCK) where t.AULOGRPOL=xpi.apolclav and t.AULOGFEMI between  '20130824' and '20130825' and AULOGTIPO<>'C')
	or
	exists(select 1 from dw_recibos.dbo.tgrrecib t (NOLOCK) where t.GRRECIB_NUM_POLIZA=xpi.apolclav and (GRRECIB_FECH_EMIS='20130824' or GRRECIB_FECH_EFE='20130824'  ))
	)

*/

