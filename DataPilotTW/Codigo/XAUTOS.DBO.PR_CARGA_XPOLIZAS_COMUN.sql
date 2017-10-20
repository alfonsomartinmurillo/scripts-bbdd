


--EXEC xautos..pr_carga_xpolizas_comun_TAUDACON '20170606 12:00:00:000'
CREATE procedure [dbo].[pr_Carga_XPolizas_Comun] @UltimaFcargaX datetime
AS

/*----------------------------------------------------------------------------
Carga una tabla con los datos invariantes de una poliza
------------------------------------------------------------------------------
CREADO POR/FECHA: J‚s£s G¢mez 17-03-2004
------------------------------------------------------------------------------
MODIFICADO POR/FECHA:   
Hugo Tamashiro 29 Noviembre del 2004.Introducido campo canal de entrada.

Jes£s Gomez 13-01-2005Añadido calculo de la Fecha de entrada desde recibos, 
	no desde xpolizas.Añadido calculo de descuentos desde las
	cuotas de voluntario en vez de apolpdes

Jes£s Gomez 29-04-2005 Añadido calculo de descuentos desde las cuotas de 
	voluntario en vez de apolpdes

Jes£s Gomez 25-10-2005 Añadido el campo de delegacion

Jes£s Gomez 07-12-2005 Se agrupa en el calculo de delegacion por alogdele

Jes£s Gomez 14-03-2006 La fecha de entrada es la del primer recibo de cualquier situacion (antes solo pagado o pendiente)

Jes£s Gomez 03-04-2006 La fecha de entrada de las polizas de renting no se pilla del recibo (hay errores)

Jes£s Gomez 21-04-2006 Cogemos como fecha de entrada el minimo efecto de todos los recibos
		        Separamos el calculo de descuentos iniciales del calculo de fecha de entrada

Jes£s Gomez 21-04-2006 Añadida Fecha de vencimiento
Jes£s Gomez 21-04-2006 Añadido campo producto
Jes£s Gomez 13-02-2007 Rehecho para incremental
Jes£s Gomez 21-08-2007 La fecha de contrataci¢n pasa a tomarse de la tauxpoli
Jes£s Gomez 21-12-2007 Añadido campo de operador
Jes£s Gomez 06-03-2008 Se toman los descuentos del primer movimiento de mov_polizas
Jes£s Gomez 07-04-2008 La delegaci¢n 0000 pasa a ser 2800
Jes£s Gomez 25-06-2008 Añadida fecha de imputacion
Jes£s Gomez 12/08/2008 La fecha de emision de la p¢liza se coje de la tabla de fechas de contratacion de host
Jesus Gomez 28/10/2008 La fecha de emision de la p¢liza se coje de la tabla polizas_situacion_mensual
Mario Sánchez 13/03/2009 Modificado campo Colectivo para permitir "TICKET21" y Castellana Wagon
MªNieves Sanchez-M. 14/1272009 Modificado campo HoraEmision a varchar(15) con formato hora completo
Jesus Gomez 25/03/2010 Añadida la tabla de colectivos en el incremental y mejorado el algoritmo de fechaentrada
Gemma Pérez 22/04/2010 Añadida extracción real de IdEmpresa.
23/12/2010 Nieves  - Cambian a los origenes dw_autos tablas datamirror dw_autos..tuccolec            

Jesus Gomez 31/05/2011 CAmbiado algoritmo de calculo del colectivo

Gemma Pérez 13/07/2011 Cambiadas referencias a DW_MUTUA en la parte de recibos por DW_RECIBOS

GPérez 06/10/2011 Incluido campo Negocio en Tabla.

GPérez 08/11/2011 Considerado nuevo tipo de descuento Z (Sin descuento APOLRELD) en la consulta.
Gemma Pérez  05/01/2012 Incluido parche para pólizas de Globalis con 2 Operativas de Tipo P
                        Quitar cuando nos lo expliquen desde Host (Francisco Martínez Nájera)
Gemma Pérez  29/02/2012 Cambiado cálculo de FechaImputacion para evitar efecto 29/02/2012:
						Las pólizas con efecto 01/03/2012 se imputan a 29/02/2012

Gemma Pérez  21/05/2012 Parche para cambiar la fecha de efecto de las pólizas de renting migradas 
						de Mutua a Globalis. (APOLAINI)
Gemma Pérez  22/05/2012 Parche para que se caigan todas las pólizas migradas (paso a  estado futuro) la próxima
					    vez que pase la cinta.Atención: ésto no está funcionando bien a causa del checksum (ActualizaTabla).

Gemma Pérez  13/06/2012 Se cambia el cálculo del campo FechaEntrada:
						Antes:
						..coalesce(FecEfectoAlta1,FecEfectoAlta2,I.FECIMPINI,o.alogfefe,cast(cast(pf.apolaini2 as varchar(4))+right(convert(varchar(8),pf.apolfvto,112),4) as date)) 
						
						Ahora:
						..coalesce(FecEfectoAlta1,FecEfectoAlta2,o.alogfefe,cast(cast(pf.apolaini2 as varchar(4))+right(convert(varchar(8),pf.apolfvto,112),4) as date),I.FECIMPINI) 
						
Adela Gutiérrez 25/10/2012 Arreglo de los casos en los que se borran pólizas de POLIZA_FIJA.
						   Borramos todas las pólizas que no estén en POLIZA_FIJA

Luis Arroyo 05/03/2013  Actualización de los canales de entrada MOBILE para AGRE0021		

Jgomez 20/03/2013 Adaptado a DB2 por problemas de rendimiento				 

Gemma Pérez 26/03/2013  Modificado el cálculo de desxuentos ya que entraban valores Z :: valor 0

Adela Gutiérrez 16/04/2013 FrecuenciaPago='A' cuando viene a 0

Gemma Pérez 12/08/2013 Eliminado campo lortad

Gemma Pérez 18/09/2013 Incluido tratamiento de tipo de negocio / colectivo IN Individual (Dimnesión obsoleta Colectivos)

Sergio Alvaro Panizo 30/10/2014 Incluido el negocio en el momento de la contratación y la oficina en ese mismo momento

Sergio Alvaro Panizo 21/01/2015 (Buscar salpa1d21012015)
	Modifico el IdOficinaContratacion e IdNegocioContratacion para que lo coja del primer movimiento
	de XPOLIZAS_IMPUTACION
	
Sergio Alvaro Panizo 23/01/2015 (Buscar salpa1d23012015)
	Incluyo XPOLIZAS_IMPUTACION en el cálculo de F_Carga para que en la segunda pasada detecte las pólizas
	de nueva producción y actualice los campos IdNegocioContratacion e IdOficinaContratacion que en la primera
	pasada quedan vacíos por no estar aún en XPOLIZAS_IMPUTACION

Luis Arroyo 22/04/2015 (Buscar larpa5s)
   Se incluyen los campos idNegocioAux y NegocioEntradaAgregador, para dar soporte al proyecto Clientes Agregadores.
   El documento tiene los detalles.	
  
 Adela Gutiérrez 07/05/2015 
	Se incluye el campo FechaFinContratoRenting 

 Adela Gutiérrez 14/10/2015 
	Para el campo FechaFinContratoRenting, se consulta el campo TipoSubNegocio para decidir si una póliza es de Renting, 
	en lugar de TipoNegocio que es el que se usaba hasta ahora (en realidad TipoNegocio es el tipo de Negocio del negocio matriz)
	
 Luis Arroyo 19/02/2016
    Optimizamos la consulta primera que consume 30 minutos.

 Gemma Pérez 29/02/2016
    Hablado con el usuario: se decide no aplicar ningún parche relacionado con el hecho de que en el sistema operacional
    los recibos con fecha de efecto 29/02 se están moviendo al 01/03, de esta manera el operacional y BI están alineados.
    Ésto significa que la nueva producción imputada del día 29/02 será más baja de lo habitual y la nueva producción imputada 
    del día 01/03 será más alta de lo habitual, no se distribuye como se hizo en 2012.
	
 Alvaro Roldán 10/03/2016 
	Añadimos los campos referentes a la compañía de procedencia

 Alvaro Roldán 19/12/2016
	Añadimos el campo AñoInicioContrato (afecta al cálculo de la antigüedad del mutualista - Tablón Ratios de Conversión)

Raquel Humanes 18/02/2017
	Cambiamos el calculo del campo idnegociocierre. Ahora sale del campo AUSOLIC_ID_NEGO_FIN de la tabla TAUSOLIC

Adela Gutierrez 17/07/2017
	Quitamos las dependencias de esta carga con la tabla XDIM.negocios.NEGOCIOS_HISTORICO, que se actualiza después.
	Metemos en el incremental las pólizas de los negocios que cambian de IdTipoSubNegocio, ( UCCOTIPC de DW_AUTOS..TUCCOLEC)
	,porque dicho cambio implica un cambio en los datos de renting que se insertan en las tablas de pólizas.

18/07/2017 - Javier Torres
	· A la hora de obtener la duración del contrato renting solo contamos los estados VIGOR
	· Existe otro estado (menos registros) que es PENDIENTE que debemos tenerlos en cuenta tambíen
	· Cambiamos el filtro solo descargando registros ANULADOS (AMMOVRE_ESTADO <> 'A')
	· Tocamos en la creación de las siguientes tablas TMP que obtienen datos de TAMMOVRE:
		tmp.xautos_dbo.carga_polizas_comun_1_1_1_TAMMOVRE
		tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE0
	


------------------------------------------------------------------------------
ENTRADAS:
------------------------------------------------------------------------------
SALIDAS:
------------------------------------------------------------------------------
OBSERVACIONES:
Se utilizan la tabla de operatoria de data_diario

No cargamos las polizas con tipo de seguro solo ocupantes

Definicion de conceptos y codificaci¢n:

				      case CanalEntrada
					   when 'C' then 'Cisc - Sin especificar'
					   when 'M' THEN 'Sala'
					   when 'T' THEN 'Tel‚fono'
					   when 'D' THEN 'Documento'
					   when 'E' THEN 'Externo'
					   when 'O' THEN 'Otros'
					   when 'W' THEN 'Web'
					   when 'B' THEN 'Bathc'
					   when 'F' THEN 'Financiero'
					   else  'Sin codificar'
				       end as CanalEntrada
Subcanal de entrada: B-Bansalease				

Canal de informacion: Canal por el cual antes de contratar la poliza se conoce a MMA


Campo: DESCUENTOS 0 no, 1 Si

La fecha de inicio de cada poliza la tomamos del primer recibo que encontremos, en caso de que no encontremos dicho 
recibo utilizamos lo especificado en poliza_fija. Esto solo es así para las polizas posteriores al 97 que no sean de renting


----------------------------------------------------------------------------*/


	--declare  @UltimaFcargaX smalldatetime= '19010101'


	set nocount on

	declare @Msg varchar(1000)
	declare @Nregistros int
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--genero una tabla con las polizas que han sufrido algun cambio en los origenes de datos

    set @Msg='Iniciamos carga de xpolizas_comun desde : '+cast(@UltimaFcargaX as varchar)+ ' '
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'

	exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun1'
	if @UltimaFCargaX='19010101'
	
		select
			aupolclav as apolclav
		into
			tmp.xautos_dbo.carga_polizas_comun1 
		from
			dw_autos..taupoliz WITH(NOLOCK)
			
	else begin
--Debido a procesos CWA area dearrollo produccion Fran Martinez Najera están entrando polizas erróneas que registramos y filtramos 

		    exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun_1_1_1'
			select aupolclav as apolclav 
			into tmp.xautos_dbo.carga_polizas_comun_1_1_1
			from dw_autos..TAUPOLIZ WITH(NOLOCK) where f_carga>@UltimaFCargaX and AUPOLCLAV not in (select APOLCLAV from DW_AUTOS.dbo.PolizasIncorrectas where TipoError=2 and FechaBaja is null)
			union ALL
			select grrecib_num_poliza as apolclav from DW_RECIBOS.autos.TGRRECIB WITH(NOLOCK) where grrecib_ramo=1 and grrecib_tip_reci='001' and f_carga>@UltimaFCargaX
			union ALL
			select aulogrpol as apolclav from dw_autos..TAULOGOP WITH(NOLOCK) where	f_carga>@UltimaFCargaX
			union ALL
			select aupolclav as apolclav from dw_autos..taupoliz WITH(NOLOCK) where aupolidco in (select uccoidco from dw_autos..TUCCOLEC c WITH(NOLOCK) where c.f_carga>@UltimaFCargaX) and AUPOLCLAV not in (select APOLCLAV from DW_AUTOS.dbo.PolizasIncorrectas where TipoError=2 and FechaBaja is null)
			--salpa1d23012015
			union ALL
			select apolclav as apolclav from XAUTOS..XPOLIZAS_IMPUTACION WITH (NOLOCK) WHERE F_carga > @UltimaFcargaX
			--salpa1d23012015
			--union
			-- Parche para que se caigan las pólizas migradas a estado a Futuro..
			--select p.APOLCLAV from 	dw_autos..poliza_fija p WITH(NOLOCK) INNER JOIN DW_AUTOS.dbo.TAUPOLRC TAU WITH(NOLOCK) ON p.APOLCLAV = TAU.AUPOLRC_ID_POLIZA_N WHERE CONVERT(DATE,GETDATE()) = '20120529'
			union ALL
			select aupolclav as apolclav from DW_AUTOS..TUCCOLEC  (NOLOCK) N 
				INNER JOIN dw_autos..taupoliz (NOLOCK) P ON  P.AUPOLIDCO=N.uccoidco  WHERE n.F_carga > @UltimaFcargaX

			--Para el nuevo campo FechaFinContratoRenting y ahora también para obtener taudacon_cd_externo
			--Se comentan en el where condiciones porque hace falta tener en cuenta todos los registros de pólizas de negocios (P.AUPOLIDCO <> ''), no solo flotas como antes para el renting

            EXEC COMUN.DBO.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun_1_1_1_TAUDACON'
			select aupolclav as apolclav 
			INTO tmp.xautos_dbo.carga_polizas_comun_1_1_1_TAUDACON
			from dw_autos..taupoliz P WITH(NOLOCK) 
					INNER JOIN DW_AUTOS..TAUDACON C (nolock) ON P.AUPOLIDSOLIC=C.AUDACON_ID_SOLICIT
					--INNER JOIN XDIM.NEGOCIOS.NEGOCIOS_HISTORICO N ON P.AUPOLIDCO=N.IdNegocio and N.FecHasta='99991231'
				where --C.AUDACON_FFIN_CONTR is not null and YEAR(AUDACON_FFIN_CONTR) not in (1,1900) 
					--and IdTipoSubNegocio = 'FL' 
					P.AUPOLIDCO <> '' and
					C.f_carga>@UltimaFCargaX

            EXEC COMUN.DBO.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun_1_1_1_TAMMOVRE'
			select AMMOVRE_ID_POLIZA as apolclav 
			INTO tmp.xautos_dbo.carga_polizas_comun_1_1_1_TAMMOVRE
			FROM dw_autos..TAMMOVRE (nolock) T
				INNER JOIN dw_autos..taupoliz (NOLOCK) P ON  T.AMMOVRE_ID_POLIZA=P.aupolclav
				INNER JOIN DW_AUTOS..TUCCOLEC  (NOLOCK) N ON P.AUPOLIDCO=N.uccoidco 
				--INNER JOIN XDIM.NEGOCIOS.NEGOCIOS_HISTORICO N ON P.AUPOLIDCO=N.IdNegocio and N.FecHasta='99991231' 
			where T.AMMOVRE_COD_MOVIM in ('ALCN','PRTC','PROG','AMPL') 
				--and AMMOVRE_ESTADO='V'
				and AMMOVRE_ESTADO <> 'A'
				and N.UCCOTIPC='RT' 
				and N.UCCOEMPR=3
				and T.f_carga>@UltimaFCargaX
			option(recompile)
				
		
		set @Msg='Tabla temporal de datos nuevos generada tmp.xautos_dbo.carga_polizas_comun_1_1_1: '+cast(@@rowcount as varchar(9))+' registros'
		exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'
		
		SELECT APOLCLAV
		INTO tmp.xautos_dbo.carga_polizas_comun1
		FROM tmp.xautos_dbo.carga_polizas_comun_1_1_1
		UNION 
		SELECT APOLCLAV
		FROM tmp.xautos_dbo.carga_polizas_comun_1_1_1_TAMMOVRE
		UNION 
		SELECT APOLCLAV
		FROM tmp.xautos_dbo.carga_polizas_comun_1_1_1_TAUDACON
		
		set @Msg='Tabla temporal de datos nuevos generada tmp.xautos_dbo.carga_polizas_comun1: '+cast(@@rowcount as varchar(9))+' registros'
		exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'

		create unique index ix1 on tmp.xautos_dbo.carga_polizas_comun1 (apolclav)

    end
--Calculamos los datos de la pólizas que hay que recargar
		
		exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun2'
		
		select 
			DISTINCT case 
				when TAU.aupolrc_id_poliza is not null then apolaini+1
				else apolaini
			end as apolaini2
			,p.*
		into 
			tmp.xautos_dbo.carga_polizas_comun2 
		from 
			dw_autos..poliza_fija p WITH(NOLOCK) 
		LEFT JOIN 
			DW_AUTOS.dbo.TAUPOLRC TAU WITH(NOLOCK) 
		ON
			p.APOLCLAV = TAU.AUPOLRC_ID_POLIZA_N
		where 
			exists(select apolclav from tmp.xautos_dbo.carga_polizas_comun1 t WITH(NOLOCK) where t.apolclav=p.apolclav)
		--	AND APOLCLAV = 6904677
			
			
		set @Msg='Tabla temporal2 de datos nuevos generada: '+cast(@@rowcount as varchar(9))+' registros'
		exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'

		create unique index ix1 on tmp.xautos_dbo.carga_polizas_comun2 (apolclav)with (fillfactor=100)
		
			
		
		
--Calculamos el primer recibo para cada una de las pólizas anteriores
		
		exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun3'
		select 
			poliza
			,nullif(min(case 
				when estado='EM' and situacion in ('PT','PA','IM') then FecEfecto
				else '20501231'
			end),'20501231') as FecEfectoAlta1
			,min(fecefecto) as FecEfectoAlta2
		into 
			tmp.xautos_dbo.carga_polizas_comun3
		from 
			dw_recibos.autos.vm_recibos r WITH(NOLOCK)
		where 
			idramo=1
			and exists(select 1 from tmp.xautos_dbo.carga_polizas_comun1 t WITH(NOLOCK) where t.apolclav=r.poliza)
		group by 
			poliza
					
	set @Msg='Tabla temporal3 de datos nuevos generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'				

	create unique index ix1 on tmp.xautos_dbo.carga_polizas_comun3 (poliza)with (fillfactor=100)					

/*
--Genero una tabla en la que selecciono para cada póliza cual es su primer recibo válido


	exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun_Recibos'
	select
		apolclav
		,Fechaentrada
	into
		tmp.xautos_dbo.carga_polizas_comun_Recibos	 
	from
		(
		select 
			apolclav
			,(select min(grrecib_fech_efe) from dw_mutua.autos.tgrrecib r2 where pf.apolclav=grrecib_num_poliza and grrecib_ramo=1) as FechaEntrada
		from
			 tmp.xautos_dbo.carga_polizas_comun1 pf
		where 
			apolclav>=2399845
		) s

	set @Msg='Tabla temporal de recibos generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'

	create index ix1 on tmp.xautos_dbo.carga_polizas_comun_Recibos	 (apolclav)

*/


 --Calculamos la relación de descuentos inicial de cada una de las pólizas a recargar
 
 
	
	exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun4'
	
	--si lo tenemos en xpolizas lo tomamos de ella directamente
	select 
		t.apolclav,descuentos
		--salpa1d21012015 Eliminamos filas
		--,idnegocio ,idoficina
		--salpa1d21012015
	into
		tmp.xautos_dbo.carga_polizas_comun4
	from
		xautos..xpolizas_imputacion xpi
	inner join
		tmp.xautos_dbo.carga_polizas_comun2 t
	on
		t.APOLCLAV=xpi.apolclav		
	where
		xpi.primermovimiento=1
		
	
	set @Msg='Tabla temporal4 - Xpol imputacion: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'					
	
	create unique clustered index ix1 on tmp.xautos_dbo.carga_polizas_comun4(apolclav)
	
	--si no lo hemos encontrado lo buscamos en el primer movimiento del historico
	
	
	
 	insert into tmp.xautos_dbo.carga_polizas_comun4
	select 
		AUHISPOLI, 
			CASE
			WHEN ISNULL(AUHISRELD, '') = 'Z' THEN '0'
			ELSE ISNULL(NULLIF(RTRIM(AUHISRELD),''),'0')
		END AS Descuentos
		--salpa1d21012015 quitamos las dos líneas siguientes
		--, cast(AUHISIDCO as varchar(256))			AS 'NegocioEntrada'
		--, cast(AUHISCONC as varchar(256))			AS 'OficinaEntrada'
		--salpa1d21012015
	FROM (
			select	
				AUHISPOLI,
				AUHISRELD,
				--salpa1d21012015 quitamos las dos líneas siguientes
				--AUHISIDCO,
				--AUHISCONC,
				--salpa1d21012015
				ROW_NUMBER() OVER (PARTITION BY AUHISPOLI ORDER BY AUHISFEFE, AUHISORDE) AS Orden
			from
				dw_autos.dbo.tauhisto th
			where
				AUHISPOLI in (select apolclav from tmp.xautos_dbo.carga_polizas_comun2 t1
								where not exists (select 1 from tmp.xautos_dbo.carga_polizas_comun4 t4 where t1.apolclav=t4.apolclav))
		)TMP
	 WHERE ORDEN = 1
		
	set @Msg='Tabla temporal4 - TAUHISTO: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'				

	--si no lo hemos encontrado lo buscamos en el registro actual
	

	
	insert into tmp.xautos_dbo.carga_polizas_comun4
	select	
		aupolclav
		,isnull(nullif(rtrim(case when aupolreld= 'Z' THEN '0' ELSE aupolreld END),''),'0') 
		--salpa1d21012015 quitamos las dos líneas siguientes
		--,aupolidco
		--,aupolconc
		--salpa1d21012015 
	from
		dw_autos.dbo.taupoliz th
	where
		aupolclav in (select apolclav from tmp.xautos_dbo.carga_polizas_comun2 t1
						where not exists (select 1 from tmp.xautos_dbo.carga_polizas_comun4 t4 where t1.apolclav=t4.apolclav))
 
	set @Msg='Tabla temporal4 - TAUPOLIZ: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'	
 


 	--Para obtener Campo TAUDACON.AUDACON_CD_EXTERNO
		exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_taudacon_cd_externo'

		 select P.apolclav, AUDACON_CD_EXTERNO
		 into tmp.xautos_dbo.carga_polizas_taudacon_cd_externo
		 from tmp.xautos_dbo.carga_polizas_comun2 (nolock) P
		 inner join DW_AUTOS..TAUDACON (nolock) C
		 on P.APOLIDSOLIC=C.AUDACON_ID_SOLICIT
		 
	set @Msg='Calculado campo CodExterno.'
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'	

 
 	--Fecha fin contrato renting
 
		 --caso 1:
		 
		 exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun_renting'

		 select P.apolclav, AUDACON_FFIN_CONTR as FechaFinContrato
		 into tmp.xautos_dbo.carga_polizas_comun_renting
		 from tmp.xautos_dbo.carga_polizas_comun2 (nolock) P
		 inner join DW_AUTOS..TAUDACON (nolock) C
		 on P.APOLIDSOLIC=C.AUDACON_ID_SOLICIT
		 INNER JOIN DW_AUTOS..TUCCOLEC  (NOLOCK) N ON P.APOLIDCO=N.uccoidco 
		-- inner join XDIM.NEGOCIOS.NEGOCIOS_HISTORICO N ON P.APOLIDCO=N.IdNegocio and N.FecHasta='99991231'
		 where C.AUDACON_FFIN_CONTR is not null and YEAR(AUDACON_FFIN_CONTR) not in (1,1900) 
			and N.UCCOTIPC = 'FL' 

		 --caso 2:
		 
		 insert into tmp.xautos_dbo.carga_polizas_comun_renting
		 select P.apolclav, DATEADD(YY,P.APOLDURA,P.AUPOLFINI) as FechaFinContrato
			from tmp.xautos_dbo.carga_polizas_comun2 (nolock) P
			--inner join XDIM.NEGOCIOS.NEGOCIOS_HISTORICO N	ON P.APOLIDCO=N.IdNegocio and N.FecHasta='99991231'
			 INNER JOIN DW_AUTOS..TUCCOLEC  (NOLOCK) N ON P.APOLIDCO=N.uccoidco 
			where N.UCCOTIPC ='RT' and N.UCCOEMPR=1 
			
		--caso 3:
		 
		 exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE0'


			select P.apolclav ,P.AUPOLFINI,T.AMMOVRE_DURACION,t.AMMOVRE_F_ALTA
			into tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE0
			FROM tmp.xautos_dbo.carga_polizas_comun2 (nolock) P
			INNER JOIN dw_autos..TAMMOVRE (nolock) T
				ON  T.AMMOVRE_ID_POLIZA=p.apolclav
			--INNER JOIN XDIM.NEGOCIOS.NEGOCIOS_HISTORICO N ON P.APOLIDCO=N.IdNegocio and N.FecHasta='99991231' 
			 INNER JOIN DW_AUTOS..TUCCOLEC  (NOLOCK) N 
				ON P.APOLIDCO=N.uccoidco 
			where T.AMMOVRE_COD_MOVIM in ('ALCN','PRTC','PROG','AMPL') 
				--and T.AMMOVRE_ESTADO='V'
				and T.AMMOVRE_ESTADO <> 'A'
				and N.UCCOTIPC = 'RT' 
				and N.UCCOEMPR = 3
		
		-- exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE1'


		--select m1.apolclav ,m1.AUPOLFINI,M1.AMMOVRE_DURACION,M2.AMMOVRE_DURACION as AMMOVRE_DURACION_2
		--into tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE1	
		--from tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE0 (nolock) M1
		--	left join tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE0 (nolock) M2
		--	on M1.APOLCLAV = M2.APOLCLAV
		--	and M1.AMMOVRE_F_ALTA >= M2.AMMOVRE_F_ALTA 
			
		
		 exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE2'	
			
			
			SELECT apolclav,AUPOLFINI,SUM(AMMOVRE_DURACION) AS AMMOVRE_DURACION_TOTAL
			INTO tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE2
			FROM tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE0
			GROUP BY apolclav,AUPOLFINI 
			
			insert into tmp.xautos_dbo.carga_polizas_comun_renting
			SELECT apolclav,DATEADD(MM,AMMOVRE_DURACION_TOTAL,AUPOLFINI)  as FechaFinContrato
			FROM tmp.xautos_dbo.carga_polizas_comun_rentingTAMMOVRE2

	set @Msg='Calculada Fecha Fin Contrato renting.'
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'	



	exec comun.dbo.eliminatabla 'tmp.xautos_dbo.carga_polizas_comun_compañia'
	select	  pf.apolclav
			, mv.aupolidsolic
			-- Campos de certificado de siniestralidad
			, CASE WHEN CS.AUCDOCCOM is not null THEN CS.AUCDOCCOM
					ELSE CASE WHEN b.AUDACOP_EMPRES_EST IS NOT NULL THEN b.AUDACOP_EMPRES_EST
								ELSE NULL --Sin certificado
						END
				END CompañiaProcedencia
			, CASE WHEN CS.AUCDOCCOM is not null THEN CS.NAñosProc
					ELSE CASE WHEN b.AUDACOP_EMPRES_EST IS NOT NULL THEN b.AUDACOP_NUMANO_EST
								ELSE NULL --Sin certificado
						END
				END NAñosCompProcedencia
			, CASE WHEN CS.AUCDOCCOM is not null THEN CS.NSiniProc
					ELSE CASE WHEN b.AUDACOP_EMPRES_EST IS NOT NULL THEN b.AUDACOP_NUMSIN_EST
								ELSE NULL --Sin certificado
						END
				END NSiniCompProcedencia
			, CASE WHEN CS.AUCDOCCOM is not null THEN 'T'
					ELSE CASE WHEN b.AUDACOP_EMPRES_EST IS NOT NULL THEN 'I'
								ELSE 'N'   
						END
				END OrigenCompProc
	into tmp.xautos_dbo.carga_polizas_comun_compañia
	FROM tmp.xautos_dbo.carga_polizas_comun2 PF 
	join dw_autos..taupoliz mv (NOLOCK)
	on mv.aupolclav=pf.apolclav
	left join XDIM.autos.CS_CertificadoSiniestralidad CS 
	on pf.APOLCLAV = CS.AUCDOPOLI
	left join dw_autos.dbo.TAUDACOP b (NOLOCK)
	on b.AUDACOP_ID_SOLICIT  =  mv.AUPOLIDSOLIC     
	and b.AUDACOP_ID_EMPRESA = APOLNEMP                
	AND b.AUDACOP_ID_RAMO = 1                       
	AND b.AUDACOP_ID_RIESGO = 1                     
	AND b.AUDACOP_NUM_POLIZA > 0          

	-- Los nuevos registros ya llevan los campos de certificado de siniestralidad actualizado.
	-- Actualizamos también los registros que no son nuevos pero cuyo certificado ha podido cambiar.
	update pol
	set CompañiaProcedencia = CS.AUCDOCCOM, 
		NAñosCompProcedencia = CS.NAñosProc,
		NSiniCompProcedencia = CS.NSiniProc,
		OrigenCompProc = 'T',
		f_carga = getdate()
	FROM xautos..xpolizas_comun pol
	join XDIM.autos.CS_CertificadoSiniestralidad CS 
	on pol.apolclav = CS.AUCDOPOLI
	where CS.f_carga > @UltimaFcargaX
	-- tiempo ejecución = 4 seg.

	set @Msg='Calculada Compañía Procedencia.'
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'	

 
 --Generamos la tabla final
exec comun.dbo.eliminatabla 'tmp.xautos_dbo.carga_polizas_comun22'
select    pf.apolclav
         ,FecEfectoAlta1
         ,FecEfectoAlta2
         ,pf.apolaini2
         ,pf.apolfvto
         ,i.fecimpini
         ,PF.APOLRELA
         ,PF.APOLLORT
		 ,PF.APOLFIRC
		 ,PF.APOLINFO
         ,APOLCANA
         ,APOLSCAN
         ,UCCOTIPC
         ,can.descuentos
         ,mv.AuPOLSOCU
         ,mv.AuPOLSOBL
         ,mv.AuPOLSAUT 
         ,mv.aupolapen
         ,apolnemp
         ,AUPOLFPGA
         ,mv.aupolidca
        ,c.uccoidco
        ,tam.AMRGCNT_CODIGO
        --salpa1d21012015 Cambiamos para que en vez de coger de la temporal lo haga de XPOLIZAS_IMPUTACION
        -- Antes...
        --,can.IdNegocio AS 'NegocioEntrada'
        --,can.IdOficina AS 'OficinaEntrada'
        -- Ahora...
        ,CASE
			WHEN i.IdNegocio = '' THEN '0'
			ELSE i.IdNegocio
		  END AS 'NegocioEntrada'
        ,CASE
			WHEN i.IdNegocio = '' THEN 9999999
			ELSE i.IdOficina
		  END AS 'OficinaEntrada'
        --salpa1d21012015
        ,isnull(RT.FechaFinContrato,xpc.FechaFinContratoRenting) as FechaFinContratoRenting
        -- larpa5s 20150519
        --,CASE WHEN XPC.IdEmpresa = 1 THEN ISNULL(TAM1.AMRGCNT_CODAGR_INI,'ZZZZZZZX') 
        --      ELSE 'ZZZZZZZY'
        -- END idNegocioCierre
		 --,ISNULL(solic.AUSOLIC_ID_NEGO_FIN,'ZZZZZZZX')  idNegocioCierre
		 ,ISNULL(solic.AUSOLIC_ID_NEGO_FIN,'ZZZZZZZX')  Cod_Agreg_Cruce
        -- larpa5s 20150519
		,comp.CompañiaProcedencia	as CompañiaProcedencia
		,comp.NAñosCompProcedencia	as NAñosCompProcedencia
		,comp.NSiniCompProcedencia	as NSiniCompProcedencia
		,comp.OrigenCompProc		as OrigenCompProc
		,pf.APOLAINI				as AñoInicioContrato
		,TAU_CD_EXT.AUDACON_CD_EXTERNO		as CodExterno
into tmp.xautos_dbo.carga_polizas_comun22
FROM tmp.xautos_dbo.carga_polizas_comun2 PF left join tmp.xautos_dbo.carga_polizas_comun4 can
													on pf.APOLCLAV=can.APOLCLAV 
											left join dw_autos..taupoliz mv (NOLOCK)
													on mv.aupolclav=pf.apolclav
											left join xautos..xpolizas_imputacion i (NOLOCK)
													on i.apolclav=pf.apolclav and i.primermovimiento=1
											left join dw_autos..tuccolec c (NOLOCK)
													on uccoidco=pf.apolidco
											left join tmp.xautos_dbo.carga_polizas_comun3 r
													on pf.apolclav=r.poliza
											left join dw_autos.dbo.tamrgcnt TAM 
													ON AMRGCNT_CODAGR = 'AGRE0021' AND tam.AMRGCNT_CODIGO = pf.APOLCLAV 
											left join dw_autos.dbo.TAMRGCNT TAM1 WITH (NOLOCK) 
											        ON TAM1.AMRGCNT_CODIGO = pf.APOLCLAV --AND c.UCCOTIPC = 'AG'
											left join tmp.xautos_dbo.carga_polizas_comun_renting RT
													on pf.APOLCLAV=rt.APOLCLAV
											left join tmp.xautos_dbo.carga_polizas_taudacon_cd_externo as TAU_CD_EXT
													on TAU_CD_EXT.APOLCLAV = pf.APOLCLAV
											left join xautos..xpolizas_comun xpc (NOLOCK)
													on  pf.APOLCLAV=xpc.APOLCLAV
											left join tmp.xautos_dbo.carga_polizas_comun_compañia comp
													on comp.apolclav = pf.apolclav	
											left join dw_autos..TAUSOLIC solic (nolock)
													on  mv.aupolidsolic=solic.AUSOLIC_ID_SOLICIT	
													and mv.AuPOLNEMP =solic.AUSOLIC_ID_EMPRESA		
													and solic.AUSOLIC_ID_RAMO =1		


create index ix1 on tmp.xautos_dbo.carga_polizas_comun22(apolclav)

exec comun.dbo.eliminatabla 'tmp.xautos_dbo.carga_polizas_comun222'
select *
into tmp.xautos_dbo.carga_polizas_comun222
from 
	(SELECT pf.*
       ,o.ID id_alog
       ,aulogrpol
       ,aulogtipo
       ,AULOGFEFE
       ,AULOGFEMI
       ,AULOGDELE
       ,AULOGOPER
       ,ROW_NUMBER() over (PARTITION by pf.apolclav order by o.id) n1
       ,ROW_NUMBER() over (PARTITION by pf.apolclav order by o.id desc) n3
	FROM tmp.xautos_dbo.carga_polizas_comun22 pf left join dw_autos..taulogop o (nolock)
													   on o.aulogrpol=pf.apolclav 
															and aulogtipo='P' 
															and aulogrpol<>0
   ) t
where 
 1 = case when apolnemp = 1 then n1 when apolnemp = 3 then n3 end										




exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.xpolizas_comun'
select	 apolclav
		,FechaContratacion
		,FechaEntrada
		,RelacionPresentador
		,FirmaNuevaRC
		,CanalInformacion
		,CanalEntrada
		,SubCanalEntrada
		,Colectivo
		,Flota
		,Descuentos
		,Delegacion
		,Operador
		,HoraEmision
		,FechaVencimiento
		,SaldoActual
		,AñoPenalizacion
		,IdEmpresa
		,FrecuenciaPago
		,CodigoCampaña
		,IdNegocio
		,IdNegocioContratacion
		,IdOficinaContratacion
		,FechaFinContratoRenting
		--,idNegocioCierre
		,Cod_Agreg_Cruce
		,cast(case  when fechaentrada = '20120301' and fechacontratacion = '20120229' then fechacontratacion
					when fechaentrada>fechacontratacion then fechaentrada 
					else fechacontratacion 
			  end as date) as FechaImputacion 
		,cast(getdate() as smalldatetime) as F_carga
		,CompañiaProcedencia
		,NAñosCompProcedencia
		,NSiniCompProcedencia
		,OrigenCompProc
		,AñoInicioContrato
		,CodExterno
Into tmp.xautos_dbo.xpolizas_comun
from
(
	select
		PF.apolclav ,
		cast(coalesce(pf.fecimpini,pf.aulogfemi,convert(varchar(8),getdate()-1,112)) as date) as FechaContratacion,
		cast(case 
					when pf.apolclav<2399845 then pf.fecimpini -- las polizas anteriores al 97 no la puedo calcular por recibos, antes fechaentrada=fechacontracion
					when pf.apolclav=3025986 then '20090428' --error en recibos
					when pf.apolclav between 6000000 and 6000706 then '20100501' --Inicio de Globalis 
					else coalesce(FecEfectoAlta1,FecEfectoAlta2,pf.aulogfefe,cast(cast(pf.apolaini2 as varchar(4))+right(convert(varchar(8),pf.apolfvto,112),4) as date),pf.fecimpini) 
					--el alogfefe solo se da en flotas en las que generan la poliza antes que el recibo
		    end as date) as FechaEntrada --La de su primer recibo no anulado
		,case when PF.APOLRELA in ('C','H','M','O','P') then PF.APOLRELA
				else 'O'
		 end as RelacionPresentador,
		PF.APOLFIRC as FirmaNuevaRC,
		PF.APOLINFO as CanalInformacion,
		-- Canal de entrada Mobile para el agregador AGRE0021
		CASE WHEN AMRGCNT_CODIGO IS NULL THEN PF.APOLCANA ELSE 'L' END as CanalEntrada,
				PF.APOLSCAN as SubCanalEntrada,
		case when pf.UCCOTIPC not in ('FL','AG','MK','IN') then pf.uccoidco
			 else '0'
		end as Colectivo,
		case when pf.UCCOTIPC like 'FL' then pf.uccoidco
			 else '0'
		end as Flota,
		coalesce(pf.descuentos,'0') as Descuentos, --para coger los descuentos del primer movimiento (pueden cogerse descuentos en un suplemento
		case When pf.aulogdele in ('','0000') then '2800'
			 when pf.aulogdele is null then '2800'
			 when isnumeric(pf.aulogdele)=0 then '2800'
			 when pf.aulogdele='0316' then '4100'
			 when pf.aulogdele='2802' then '2801'
			 else pf.aulogdele
		end as Delegacion,
		nullif(pf.aulogoper,'0000') as Operador,
		isnull(left(right(convert(varchar(27),pf.aulogfemi,113),15),12),'00:00:00.000') as HoraEmision,
		cast(pf.APOLFVTO as date)as FechaVencimiento,
		isnull(pf.AuPOLSOCU+pf.AuPOLSOBL+pf.AuPOLSAUT,0) as SaldoActual,
		convert(smallint,case when isnull(pf.aupolapen,0)between 1 and 1900 then 0 else isnull(pf.aupolapen,0) end)as AñoPenalizacion,
		cast(PF.apolnemp as tinyint) as IdEmpresa
		,case when pf.AUPOLFPGA is null OR pf.AUPOLFPGA='0' then 'A' else pf.AUPOLFPGA end FrecuenciaPago
		,isnull(nullif(pf.aupolidca,''),'ZZ') CodigoCampaña
		,ISNULL(pf.uccoidco, '0') as IdNegocio	
		,ISNULL(pf.NegocioEntrada, '0')		as IdNegocioContratacion
		,pf.OficinaEntrada					as IdOficinaContratacion
		,pf.FechaFinContratoRenting  as FechaFinContratoRenting 
		--,CASE WHEN PF.apolnemp = 1 THEN isnull(pf.idNegocioCierre,'ZZZZZZZX') ELSE 'ZZZZZZZY' END as idNegocioCierre
		--,isnull(pf.idNegocioCierre,'ZZZZZZZX') as idNegocioCierre
		,isnull(pf.Cod_Agreg_Cruce,'ZZZZZZZX') as Cod_Agreg_Cruce
		,pf.CompañiaProcedencia
		,pf.NAñosCompProcedencia
		,pf.NSiniCompProcedencia
		,pf.OrigenCompProc
		,pf.AñoInicioContrato
		,pf.CodExterno
from tmp.xautos_dbo.carga_polizas_comun222 pf 
			) t												


	
	set @Msg='Tabla temporal generada: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'
	
	
	--Borramos todas las pólizas que no estén en POLIZA_FIJA
	--insert into tmp.xautos_dbo.XPOLIZAS_COMUN
	--select [apolclav],[FechaContratacion],[FechaEntrada],[RelacionPresentador],[LORTAD],[FirmaNuevaRC],[CanalInformacion],[CanalEntrada]
	--		,[SubCanalEntrada],[Colectivo],[Flota],[Descuentos],[Delegacion],[Operador],[HoraEmision],[FechaVencimiento],[SaldoActual]
	--		,[AñoPenalizacion],[IdEmpresa],[FrecuenciaPago],[CodigoCampaña],[IdNegocio],[FechaImputacion],[F_carga]
	--		,'B' as dw_check_ir
	-- from xautos..xpolizas_comun
	-- where apolclav not in (select apolclav from dw_autos..POLIZA_FIJA)
	
	--delete from xautos..xpolizas_comun
	--where apolclav not in (select apolclav from dw_autos..POLIZA_FIJA)
	
	--set @Msg='Pólizas borradas por haber desaparecido de POLIZA_FIJA: '+cast(@@rowcount as varchar(9))+' registros'
	--exec Comun..Logar 'XAUTOS','DBO.XPOLIZAS_COMUN',@Msg,'C','M'
	

	--exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun1'
	--exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun2'
	--exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun3'
	--exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun4'
	--exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun222'
	--exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.carga_polizas_comun22'

	
