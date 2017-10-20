
--select distinct f_carga from xautos..xVERIFICACIONES where f_carga > '20161022'
--exec [xautos].[dbo].[pr_Carga_XVERIFICACIONES] '20161024 03:53:00'

CREATE procedure   [dbo].[pr_Carga_XVerificaciones] @UltimaFcargaX datetime
as

/*----------------------------------------------------------------------------
Devuelve datos de las Tasaciones de Producción (Verificaciones):		
Se utiliza para la carga de XVerificaciones_Inc

------------------------------------------------------------------------------
CREADO POR/FECHA: Amalia del Río 26-11-2007
------------------------------------------------------------------------------
MODIFICADO POR/FECHA:   
		Jgomez 10/12/2009 cambiado nif, colectivo, pasado a TMP e incrementalizado 
		
		GPérez 09/02/2010 Para el cálculo incremental, vamos a considerar todos los 
			 cambios realizados en dw_autos..operativa y tambien en dw_autos..presupuestos.
			 Atención: Si se cambia el filtro para la subconsulta de la tabla dw_autos..operativa 
			 en la carga de xverificaciones, habría que cambiarlo tambien en la carga de 
			 xverificaciones_incremental.
			 
	    GPérez 28/04/2010 Incluimos el campo IdEmpresa aunque aún con valor fijo.
	    
	    GPérez 09/12/2010 Modificamos el algoritmo de cálculo de la Fecha de construcción y 
						  utilizamos el que ya estaba en la carga de XPresupuestos. 
						  Motivo: Ha ocurrido un error en la carga porque el año de construcción es nulo
						  y este nuevo algoritmo considera esa posibilidad. 
	    Nieves migrado a datamirror dw_autos..colectivos por dw_autos..tuccolec 20101223                      
	    
	    GPérez 03/06/2011 En la carga del colectivo, no se consideran los tipos 'AG' ni 'FL'
	    
	    GPérez 10/06/2011 Inclusión del sexo del conductor, garantía mecánica y TasacionGarantiaMecanica. Peticiones:
								DJAP11QGDGMC
								DJGA11SECOH
								
						   Modificada la eliminación de duplicados: se utiliza el orden directamente 
						   en la consulta y no se hace un Delete.	
						   
		GPérez 13/07/2011 Inclusión de la nota de tasación.
		GPérez 13/09/2011 Referencia a TAUPOLIP en lugar de TAUPOLIP
		GPérez 06/10/2011 Incluido campo Negocio en Tabla.
		GPérez 08/11/2011 Considerado nuevo tipo de descuento Z (Sin descuento APOLRELD) en la consulta.
		GPérez 09/05/2012 Vamos a considerar todas las tablas utilizadas en la consulta para la carga
			              incremental.
		GPérez 01/08/2012 El servidor no responde (como otras veces): dividimos la última consulta y 
		creamos la nueva tabla tmp.xautos_dbo.XVerificaciones_1
		GPérez 05/10/2012 Inclusión de información de Asnef.
		Luis Arroyo 05/03/2013 Actualización del Canal de Entrada a MOBILE para el negocio AGRE0021
		David Alarcón 11/04/2013 Incluida carga de campos "Apertura" que reflejan Fecha, Operador y Producto en el momento de asignarse el primer périto válido
			Los campos Fecha y Operador se informan para verificaciones emitidas a partir del 12/12/2012 ya que es la fecha a partir de la cual se empieza a auditar la tabla TAUINSVE_H
			El campo Producto se informa para verificaciones emitidas a partir del 28/01/2013 ya que es la fecha a partir de la cual se empieza a auditar la tabla TAUPOLIP_H
		Gemma Pérez		18/09/2013	Incluido tratamiento de tipo de negocio / colectivo IN Individual (Dimnesión obsoleta Colectivos)
		David Alarcón	17/10/2013	Sustituida DW_AUTOS.dbo.PERCEPTORES por xautos.dbo.V_xPerceptores
		Gemma Pérez		23/04/2014	Incluido campo IdOficina (Punto de red)
		Gemma Pérez		16/07/2014	Cambiado el uso de xautos.dbo.V_xPerceptores por xautos.dbo.xPerceptores. Incluida dependencia BI0101XD035.
	 	Óscar Sánchez	24/02/2015	Se pone en funcionamiento la función tipo tabla del cálculo de tipo de persona. (D-113149)
	    Gemma Pérez		31/03/2015	Se modifica el uso de Union por Union All+Distinct debido al bajo rendimiento
									tras el borrado de presupuestos
									Añadidos NOLOCK.
        Angel Cañas		14/04/2015	Añadidos campos  idSolicitud e id15PuntosCarnet
        Angel Cañas		16/04/2015	Se cambia tabla dbo.TAUDACOP de DW_MUTUA a DW_AUTOS
        Gemma Pérez 28/10/2015 Eliminamos el uso de XVehiculo (se calculaba la fecha de construcción cuando en XVehículo no
			                       se guardan presupuestos).
		Gemma Pérez 04/01/2016 Sustituido el uso de la tabla XAUTOS..XPERCEPTORES por la tabla DW_AUTOS.dbo.TSIPERCE.
		                       Con ésto eliminamos la dependencia actual que la cadena BI0101XD045 tiene de la cadena de 
		                       prestaciones BI0101XD035.
		Alvaro Roldán	21/09/2016 Introducimos los campos referentes a la compañía de procedencia: CompañiaProcedencia, NAñosCompProcedencia,
								   NSiniCompProcedencia y OrigenCompProc
		
		Gemma Pérez 25/10/2016  Ampliación Marca en AMMO. Cálculo del campo IdModelo a través de los campos Marca, Modelo, Submodelo, Terminación y Anualidad.
		Alvaro Roldán	04/11/2016 Incluimos el número de teléfono.
		Gemma Pérez 22/01/2017 Ampliación Marca en AMMO. Cálculo del campo IdModelo a través de los campos Marca, Modelo, Submodelo, Terminación y Anualidad.
		                       Corrección de cálculo de dato idModelo.
		Alvaro Roldán. - 06/02/2017 Añadimos Descuentos (Obligatorio, Voluntario y Ocupantes)
		Adela Gutiérrez 07/06/2017 Cuando hay más de un regidtro para el mismo presupuesto/verificación en DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS
									se estaba haciendo mal la ordenación de manera que se asignaba a todos los registro la misma fecha por la que ordenar, 
									resultando en que en cada ejecución, la sentencia devolvía un registro u otro aleatoriamente.
									Se añade la misma condición que hay enla carga de xpresupuestos, para que el registro devuelto por DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS
									sea único: 				
									and not exists (select * from DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS pt2  WITH(NOLOCK) where alogrpol = pt2.AINSPOLI and pt2.ainsfcon>alogfemi)

------------------------------------------------------------------------------

ENTRADAS:
------------------------------------------------------------------------------
SALIDAS:
------------------------------------------------------------------------------
OBSERVACIONES:	
Sexo Conductor: se ha optado por el criterio de que cualquier valor <> Hombre, Mujer es "No Aplica / No Informado".


		- Para la carga total de la tabla:

			TRUNCATE TABLE XAUTOS..XVerificaciones_Inc
			EXEC COMUN..GESTORCARGAX 'XAUTOS..XVerificaciones_Inc',0,1

Descripción de Situación de la verificación:	
			A ANULADO                           
			D INSPECCIONADO CON DANOS            
			I INCIDENCIA 
			P PENDIENTE      
			R RECIBIDA                           
			S <-- No tenemos información sobre qué significa ni de negocio ni de desarrollo Host.
			T TERMINADO (CONTRATADA POLIZA)      
			Z Tasación de Provincia
			Nulo  Error al grabar la situación del presupuesto o no disponemos de esa información.

----------------------------------------------------------------------------*/

	--declare @UltimaFcargaX datetime='20150414 00:00:00'
	
	declare @Nregistros int
	
	exec comun..eliminatabla 'tmp.xautos_dbo.xverificaciones_incremental_0'	 
	
	SELECT  
				alogrpol as Presupuesto,
				f_carga
			INTO tmp.xautos_dbo.xverificaciones_incremental_0
			FROM
				dw_autos.dbo.operativa WITH(NOLOCK)
			WHERE 
				(
					(alogtipo='I' and alogactu='R')  --presupuestos de PN 
					or 
					(alogtipo='I' and alogactu='F' and exists (select 1 from dw_autos..presupuestos_y_tasaciones_polizas where (ainsctal<>0 or ainsperi<>0 or ainsswob='T'	or ainstall is not null) and ainspoli=alogrpol)) --presupuestos que han pasado a tasaciones
				)	
				and Alogfemi >= '20070101'		
				and alogrpol>9000000
				and alogrpol not in (9733512)

	exec comun..eliminatabla 'tmp.xautos_dbo.xverificaciones_incremental_1'	 

		-- Grabamos todas los presupuestos que han cambiado en la tabla temporal
	SELECT  
				Presupuesto
			INTO tmp.xautos_dbo.xverificaciones_incremental_1
			FROM tmp.xautos_dbo.xverificaciones_incremental_0 WITH(NOLOCK)
			WHERE
				f_carga>@UltimaFcargaX
			UNION ALL
			SELECT p.APOLCLAV as Presupuesto
			FROM
				tmp.xautos_dbo.xverificaciones_incremental_0 ope WITH(NOLOCK) INNER JOIN dw_autos..presupuestos p  WITH(NOLOCK) ON
					ope.Presupuesto=p.APOLCLAV 
			WHERE
				p.F_carga>@UltimaFcargaX	 
			UNION ALL
			--SELECT p.APOLCLAV as Presupuesto
			--FROM
			--	tmp.xautos_dbo.xverificaciones_incremental_0 ope WITH(NOLOCK) INNER JOIN dw_autos..presupuestos p  WITH(NOLOCK) ON
			--		ope.Presupuesto=p.APOLCLAV 
			--WHERE
			--	p.F_carga>@UltimaFcargaX	 
			--UNION David Alarcón 11/04/2013 Está duplicada esta consulta
			SELECT ope.Presupuesto
			FROM
				tmp.xautos_dbo.xverificaciones_incremental_0 ope WITH(NOLOCK) INNER JOIN DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS p  WITH(NOLOCK) ON
					ope.Presupuesto=p.ainspoli 
			WHERE
				p.F_carga>@UltimaFcargaX	 
			UNION ALL
			SELECT ope.Presupuesto
			FROM
				tmp.xautos_dbo.xverificaciones_incremental_0 ope WITH(NOLOCK) INNER JOIN DW_AUTOS.dbo.TAUPOLIP p  WITH(NOLOCK) ON
					ope.Presupuesto=p.aupopclav 
			WHERE
				p.F_carga>@UltimaFcargaX	 
			/*
			UNION ALL
			SELECT ope.presupuesto as Presupuesto
			FROM
				tmp.xautos_dbo.xverificaciones_incremental_0 ope WITH(NOLOCK) INNER JOIN dw_autos..presupuestos p WITH(NOLOCK) ON		
					ope.presupuesto=p.APOLCLAV 
				INNER JOIN XAUTOS.DBO.XVEHICULO T WITH(NOLOCK) ON 
					p.apolmatr = T.matricula AND
					p.apolclav = T.apolclav
			WHERE
					T.F_carga>@UltimaFcargaX					
			*/
			UNION ALL
			SELECT ope.presupuesto as Presupuesto
			FROM
				tmp.xautos_dbo.xverificaciones_incremental_0 ope WITH(NOLOCK) INNER JOIN dw_autos..presupuestos p WITH(NOLOCK) ON		
					ope.presupuesto=p.APOLCLAV 
				INNER JOIN DW_AUTOS..TUCCOLEC T WITH(NOLOCK) ON 
					p.APOLIDCO = T.UCCOIDCO
			WHERE
					T.F_carga>@UltimaFcargaX
			UNION ALL					
			select 
				AUPOPCLAV
			from
				DW_AUTOS.dbo.TAUPOLIP		LIP with(nolock)
			inner join 
				tmp.xautos_dbo.xverificaciones_incremental_0 ope WITH(NOLOCK)
				on 
					ope.Presupuesto = LIP.AUPOPCLAV 				
			inner join			
				DW_AUTOS.dbo.TAUDACOP		COP with(nolock)
				on
					COP.AUDACOP_ID_RAMO	= LIP.AUPOPPEREFRAMO
				and	COP.AUDACOP_ID_EMPRESA = LIP.AUPOPPEREFEMPP
				and	COP.AUDACOP_ID_SOLICIT = LIP.AUPOPIDSOLIC
				and	COP.AUDACOP_ID_RIESGO = 1
				and	COP.F_CARGA > @UltimaFCargaX
--				and	LIP.AUPOPCLAV > 9000000						
																		
		--option(recompile)
	
	-- GPM 20150330 Nos quedamos con los distintos
	exec comun..eliminatabla 'tmp.xautos_dbo.xverificaciones_incremental'
	SELECT DISTINCT Presupuesto
	INTO tmp.xautos_dbo.xverificaciones_incremental
	FROM tmp.xautos_dbo.xverificaciones_incremental_1 WITH(NOLOCK)
		

	exec comun..eliminatabla 'tmp.xautos_dbo.XVerificaciones_1'
	select 
				ope.alogrpol, ope.alogtipo, ope.alogfemi, ope.alogactu, ope.alogfemi2, ope.alognift, ope.ALOGOPER Operador
	into tmp.xautos_dbo.XVerificaciones_1
			from                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
				dw_autos..operativa ope,
				tmp.xautos_dbo.xverificaciones_incremental PINC  WITH(NOLOCK)
			where 
				alogrpol = PINC.Presupuesto and
				(
					(alogtipo='I' and alogactu='R')  --tasaciones
					or 
					(alogtipo='I' and alogactu='F' and exists (select 1 from dw_autos..presupuestos_y_tasaciones_polizas with(nolock) where (ainsctal<>0 or ainsperi<>0 or ainsswob='T'	or ainstall is not null) and ainspoli=alogrpol)) --presupuestos que han pasado a tasaciones
				)	
				and Alogfemi >= '20070101'		
				and alogrpol>9000000
				and alogrpol not in (9733512)
	
	
	-- 04/01/2016 GPM Cargamos la información de perceptores.
	exec comun..eliminatabla 'tmp.xautos_dbo.XVerificaciones_Perceptores'
	select 
		convert(varchar,Right('000000'+convert(varchar(7),PERCCODI),7)) as Codigo_Perceptor 
	INTO tmp.xautos_dbo.XVerificaciones_Perceptores
	FROM DW_AUTOS.dbo.TSIPERCE PER WITH(NOLOCK) 
	WHERE 
		PER.PERCIDEN ='I' AND
        PER.PERCCODI NOT IN  (0,99999)
	

	exec comun..eliminatabla 'tmp.xautos_dbo.XVerificaciones'
	/* Si los datos de una verificación aparecen duplicados, nos quedamos con la última información que entró.*/	
	select    s.IdVerificacion
			, s.IdPoliza
			, s.FechaInspeccion
			, s.FecEmision
			, s.CanalEntrada
			, s.Solicitud
			, s.Situacion 
			, s.Matricula 
			, s.ValorVehiculo 
			, s.Producto
			, s.TipoVehiculo
			, s.FConstruccion 
			, s.idmodelo
			, s.CodPostal 
			, s.FnacConductor 
			, s.FnacTomador
			, s.Fcarnet
			, s.SexoTomador 
			, s.ValorAccesorios 
			, s.Descuentos 
			, s.NifTomador
			, s.NifDescuentos
			, s.PolDescuentos 
			, s.Operador 
			, s.Prorroga 
			, s.Cambio
			, s.IdPerito
			, s.NModificaciones
			, s.Incidencias
			, s.NBastidor
			, s.Importe
			, s.Cod_Taller
			, s.Imp_DañosIni
			, s.RelacionPresentador 
			, s.TipoPersona 
			, s.Banco
			, s.Colectivo
			, s.Flota 
			, s.IdEmpresa
			, s.SexoConductor
			, s.GarantiaMecanica
			, s.TasacionGarantiaMecanica
			, s.IdNegocio
			, s.SujetoANormativa
			, s.Lunas 
			, s.ProProducto
			, s.LunasFP 
			, s.PresenciaAsnef 
			, s.RiskScore 
			, s.SeverityScore
			, s.GarantiaMecanicaFP
			, s.Apertura_Operador 
			, s.Apertura_Fecha 
			, s.Apertura_Producto 
			, s.idSolicitud
			, s.id15PuntosCarnet 
			, s.Orden
			, getdate() as F_carga
			, cast(NULL as int) as IdOficina		
			, s.CompañiaProcedencia 
			, s.NAñosCompProcedencia 
			, s.NSiniCompProcedencia
			, s.OrigenCompProc
			, s.Telefono
			, s.IdFrecuenciaPago
			, s.IdTarifa
			, s.AñoAdquisicion
			, s.KMAño
			, s.LugarAparcamiento
			, s.FnacCO
			, s.FrtCO
			, s.SexoCO
			, s.RelacionCO
			, s.NPlazasAseg
			, s.EstadoCivil
			, s.UsoVehiculo
		    , s.FechaEfecto
			, s.DescuentoObligatorio
			, s.DescuentoVoluntario
			, s.DescuentoOcupantes
			, s.Cod_Agreg_Cruce
	into
		tmp.xautos_dbo.XVerificaciones
	from (
	select tmp.*
		  , row_number() over (partition by idverificacion order by FecEmision DESC) as Orden
		  -- Campos de certificado de siniestralidad
		  , CASE WHEN CS.AUCDOCCOM is not null THEN CS.AUCDOCCOM
				 ELSE CASE WHEN tmp.AUDACOP_EMPRES_EST IS NOT NULL THEN tmp.AUDACOP_EMPRES_EST
						   ELSE NULL --Sin certificado
					  END
			END CompañiaProcedencia
		  , CASE WHEN CS.AUCDOCCOM is not null THEN CS.NAñosProc
				 ELSE CASE WHEN tmp.AUDACOP_EMPRES_EST IS NOT NULL THEN tmp.AUDACOP_NUMANO_EST
						   ELSE NULL --Sin certificado
					  END
			END NAñosCompProcedencia
		  , CASE WHEN CS.AUCDOCCOM is not null THEN CS.NSiniProc
				 ELSE CASE WHEN tmp.AUDACOP_EMPRES_EST IS NOT NULL THEN tmp.AUDACOP_NUMSIN_EST
						   ELSE NULL --Sin certificado
					  END
			END NSiniCompProcedencia
		  , CASE WHEN CS.AUCDOCCOM is not null THEN 'T'
				 ELSE CASE WHEN tmp.AUDACOP_EMPRES_EST IS NOT NULL THEN 'I'
						   ELSE 'N'   
					  END
			END OrigenCompProc
		,isnull(solic.AUSOLIC_ID_NEGO_FIN,'ZZZZZZZX') as Cod_Agreg_Cruce
	from (
			select 
				case 
					when alogrpol<9000000 then cast('1'+right('0000000'+cast(alogrpol as varchar(8)),7)+convert(varchar(8),alogfemi,112) as int)
					else cast(alogrpol as int)
				end as IdVerificacion
				,Case	
					when alogrpol between 5000000 and 7999999 then cast(alogrpol-5000000 as int) 
					else cast(alogrpol as int)
				end  as IdPoliza,
				--cast(case when pc.apolclav<9000000 then pc.FechaContratacion else 0 end as smalldatetime) as FPoliza ,
				cast(AINSFINS as date) as FechaInspeccion,
				cast(case 
						when (alogtipo='I' and alogactu='R') then Alogfemi2 
						else isnull((select min(o2.alogfemi2) from dw_autos..operativa o2 where op.alogrpol=o2.alogrpol and o2.alogtipo='F' and o2.alogactu='R'),dateadd(ss,1,alogfemi2))
				end as datetime) as FecEmision,
				-- Canal de Entrada Mobile para el Agregador AGRE0021
				case when TAM.AMRGCNT_CODIGO is null then isnull(p.APOLCANA,'X') else 'L' end as CanalEntrada,-- Necesario en Cubo Ratios
				AINSSWOB as Solicitud,
				AINSSITU as Situacion,
				AINSMATR as Matricula,
				case 
					when p.ApolValo = 0 then isnull(nullif(M.valor,10000000),0)			
					else p.ApolValo 
				end as ValorVehiculo,							-- Necesario en Cubo Ratios
				p.producto as Producto,							-- Necesario en Cubo Ratios
				m.TipoVeh as TipoVehiculo,						-- Necesario en Cubo Ratios
				cast(case 
						--when v.FechaConstruccion is not null then v.FechaConstruccion
						when ApolAcon>year(getdate())+1 or apolacon<1900 then Null
						else cast(ApolAcon as char(4)) + '0101'
				end as smalldatetime) as FConstruccion,
				M.id as idmodelo,								-- Necesario en Cubo Ratios
				p.ApolCpos as CodPostal						-- Necesario en Cubo Ratios
				,cast(apolfnac as date) as FnacConductor
				,cast(apolfnat as date) as FnacTomador
				,cast(p.ApolFcco  as date) as Fcarnet,							-- Necesario en Cubo Ratios
				p.apolsexo as SexoTomador,						-- Necesario en Cubo Ratios
				p.ApolVacc as ValorAccesorios,					-- Necesario en Cubo Ratios
				CASE 
					WHEN p.APOLRELD = 'Z' THEN '0'
					ELSE p.APOLRELD 
				END as Descuentos,						-- Necesario en Cubo Ratios
				isnulL(alognift,p.apolnift) as NifTomador,
				AINSNIFD as NifDescuentos,
				AINSPOLD as PolDescuentos,
				-- 20170630 ARQ Cambio de origen a partir de 
				--AINSOPER as Operador,						    -- Necesario en Cubo Ratios
				CASE 
				    WHEN cast(case 
						when (alogtipo='I' and alogactu='R') then Alogfemi2 
						else isnull((select min(o2.alogfemi2) from dw_autos..operativa o2 where op.alogrpol=o2.alogrpol and o2.alogtipo='F' and o2.alogactu='R'),dateadd(ss,1,alogfemi2))
				end as datetime) < '20170621' THEN AINSOPER --FecEmision
				    ELSE op.Operador
				END AS Operador,						    -- Necesario en Cubo Ratios
				AINSPROR as Prorroga,
				AINSCVEH as Cambio,
				AINSPERI as IdPerito,
				AINSNMOD as NModificaciones,
				AINSMASK as Incidencias,
				AINSBAST as NBastidor,
				AINSIMRE as Importe,
				AINSCTAL as Cod_Taller,
				AINSDAIN as Imp_DañosIni,
				AINSRELD as RelacionPresentador,
				--case 
				--	when alognift is not null then comun.dbo.fn_tipopersona(alognift) 
				--	else p.tipopersona
				--end	as TipoPersona,
				F.TipoPersona  as TipoPersona,
				APOLCOBA as Banco,
				case 
						when TUC.UCCOTIPC not in ('FL','AG','MK','IN') then TUC.uccoidco
						else '0'
				end as Colectivo,
				case 
						when TUC.UCCOTIPC = 'FL' then TUC.uccoidco
						else '0'
				end as Flota
				,CAST(CASE 
				 WHEN APOLNEMP=3 THEN 3 
				 ELSE 1  
				 END AS smallint) AS IdEmpresa   		
				,CAST(CASE 
					WHEN TAU.AUPOPSEXC IN ('1','2') THEN TAU.AUPOPSEXC
					ELSE '0'
				  END AS CHAR(1)) AS SexoConductor
				, ISNULL(TAU.AUPOPGARM,'') AS GarantiaMecanica
				, ISNULL(p1.AINSGARM,'') AS TasacionGarantiaMecanica
				, ISNULL(TUC.uccoidco, '0') AS IdNegocio
				, ISNULL(TAU.AUPOPSNOR,'') AS SujetoANormativa
				, isnull(substring(isnull(PC2.aprogara,PC1.aprogara),4,1),'N') as Lunas
				, isnull(PC2.aproprod,isnull(PC1.aproprod,'ZZ')) as ProProducto
				, case when substring(isnull(PC1.aprogara,isnull(PC2.aprogara,'N')),4,1) in ('N','') then 'C'
					   when ISNULL(LTRIM(RTRIM(TAU.AUPOPLGRA)),'') = '' then 'N' 
					   else LTRIM(RTRIM(TAU.AUPOPLGRA))
				  end AS LunasFP
				, CAST(ISNULL(TAU.AUPOPPASNF, 'Y') AS CHAR(1)) AS PresenciaAsnef
				, CAST(ISNULL(TAU.AUPOPRSCOR,'Y') AS CHAR(1)) AS RiskScore
				, CAST(ISNULL(TAU.AUPOPSSCOR,'Y') AS CHAR(1)) AS SeverityScore
				, case when TAU.AUPOPGARM in ('GM1','GM9') then '3'
					   when TAU.AUPOPGARM = 'GM0' and alogrpol between 9000000 and 9999999 then '2'
				  else '0'
			 end  GarantiaMecanicaFP
			 -- David Alarcón 11/04/2013 Añadidos campos _Apertura de la verificación
				, aper.AUINSVE_OPERADOR as 'Apertura_Operador'
				, aper.FEC_GENERACION	as 'Apertura_Fecha'
				, ( SELECT TOP 1 aper_pro.Producto FROM 
						dw_AUTOS.dbo.V_TAUPOLIP_H aper_pro WITH(NOLOCK)
					WHERE op.ALOGRPOL = aper_pro.AUPOPCLAV
						AND 
							( 
								( DATEDIFF(SS,aper_pro.FEC_GENERACION,aper.FEC_GENERACION) between -1 and 1 ) --Cruce por diferencia de 1 segundo
								OR (  DATEDIFF(SS,aper_pro.FEC_GENERACION,aper.FEC_GENERACION) between -60 and 60  --Cruce por diferencia de 1 minuto
										 AND NOT EXISTS ( SELECT '' FROM dw_AUTOS.dbo.V_TAUPOLIP_H aper_pro2 WITH(NOLOCK) WHERE aper_pro2.AUPOPCLAV = op.ALOGRPOL 
																									AND DATEDIFF(SS,aper_pro2.FEC_GENERACION,aper.FEC_GENERACION) between -1 and 1 )
									 )
								OR (  aper_pro.FEC_GENERACION < aper.FEC_GENERACION -- Si no cruza nos quedamos con el inmediatemente anterior
										 AND NOT EXISTS ( SELECT '' FROM dw_AUTOS.dbo.V_TAUPOLIP_H aper_pro2 WITH(NOLOCK) WHERE aper_pro2.AUPOPCLAV = op.ALOGRPOL 
																									AND DATEDIFF(SS,aper_pro2.FEC_GENERACION,aper.FEC_GENERACION) between -60 and 60 )
									 )
							)
					ORDER BY aper_pro.FEC_GENERACION DESC
				  )								    as 'Apertura_Producto'
				, isnull(TAU.AUPOPIDSOLIC, 0)		as 'idSolicitud'
				, isnull(COP.AUDACOP_NUM_PUNTOS, 0)	as 'id15PuntosCarnet'	
				--Campos de certificados de siniestralidad
				, COP.AUDACOP_EMPRES_EST
				, COP.AUDACOP_NUMANO_EST
				, COP.AUDACOP_NUMSIN_EST
				, case when p1.AINSTFND = 0 then null else p1.AINSTFND end as Telefono	
				, p.AUPOPFPGA			as IdFrecuenciaPago
				, p.AUPOPITAR			as IdTarifa
				, p.APOLAADQ			as AñoAdquisicion
				, p.AUPOPKMAACT			as KMAño
				, p.AUPOPLAPACT			as LugarAparcamiento
				, p.AUPOPFNACO			as FNacCO
				, p.AUPOPFCCCO			as FrtCO
				, p.AUPOPSEXCO			as SexoCO
				, p.AUPOPRECO			as RelacionCO
				, p.APOLOPLA			as NPlazasAseg
				, p.AUPOPESCI			as EstadoCivil
				, p.AUPOPUSOACT			as UsoVehiculo
				, TAU.AUPOPFINI			as FechaEfecto
				--Descuentos
				, CASE	WHEN p.APOLOD20>0 THEN 20
						WHEN p.APOLOD30>0 THEN 30
						ELSE 0
				  END					as DescuentoObligatorio
				, CASE WHEN p.APOLVD30>0 THEN 30
					   WHEN p.APOLVD50>0 THEN 50
					   ELSE 0
				  END					as DescuentoVoluntario
				, CASE WHEN p.APOLID40>0 THEN 40
					   WHEN p.APOLID60>0 THEN 60
					   ELSE 0
				  END					as DescuentoOcupantes
			from 
				tmp.xautos_dbo.XVerificaciones_1				op with(nolock)
			
			left join 
				 DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS p1 with(nolock)
				on
					p1.ainspoli=op.alogrpol
					and not exists (select * from DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS pt2  WITH(NOLOCK) where alogrpol = pt2.AINSPOLI and pt2.ainsfcon>alogfemi)
			 -- David Alarcón 11/04/2013 Añadidos campos _Apertura de la verificación
		
			LEFT JOIN 
					( SELECT * FROM 
						(
							SELECT --TOP 20 
								*
								  , ROW_NUMBER() OVER ( PARTITION BY AUINSVE_NUM_POLIZA, AUINSVE_F_GESTION  ORDER BY FEC_GENERACION ) as Orden
							FROM 
								DW_AUTOS.dbo.TAUINSVE_H C WITH(NOLOCK)
							WHERE 
									(
									/*	EXISTS ( SELECT '' FROM DW_AUTOS.DBO.PERCEPTORES PER 
													WHERE PER.SCEPIDEN ='I' AND C.AUINSVE_COD_PERITO = PER.SCEPCODI 
														AND PER.SCEPCODI NOT IN  (0,99999) ) -- 0 y 99999 no son peritos aunque estén en la tabla como tales 
										David Alarcón 17/10/2013 */
									/*04/01/2016 GPM Utilizamos la tabla temporal de perceptores*/	
										EXISTS ( SELECT '' FROM tmp.xautos_dbo.XVerificaciones_Perceptores PER WITH(NOLOCK) 
													WHERE C.AUINSVE_COD_PERITO = PER.Codigo_Perceptor
												) -- 0 y 99999 no son peritos aunque estén en la tabla como tales 
										OR C.AUINSVE_COD_PERITO IN(67777) -- 67777Luneros
									 ) 
								AND EXISTS ( SELECT '' FROM tmp.xautos_dbo.XVerificaciones_1 ver WITH(NOLOCK) WHERE ver.alogrpol = C.AUINSVE_NUM_POLIZA )
						) t
					WHERE t.Orden = 1 
				) aper
			ON
				p1.AINSPOLI = aper.AUINSVE_NUM_POLIZA
				AND p1.AINSFCON = aper.AUINSVE_F_GESTION
			left outer join 
				 dw_autos..presupuestos p WITH(NOLOCK)
			on
				p.apolclav=op.alogrpol
		
			left join 		
				DW_AUTOS.dbo.TAUPOLIP TAU WITH(NOLOCK)
			on
				TAU.AUPOPCLAV = op.alogrpol 
			
			left join 						
				DW_AUTOS.dbo.TAUDACOP		COP with(nolock)
				on
					COP.AUDACOP_ID_RAMO	= TAU.AUPOPPEREFRAMO
				and	COP.AUDACOP_ID_EMPRESA = TAU.AUPOPPEREFEMPP
				and	COP.AUDACOP_ID_SOLICIT = TAU.AUPOPIDSOLIC
				and	COP.AUDACOP_ID_RIESGO = 1			
			
			left outer join xautos..marcas m WITH(NOLOCK) ON
					p.APOLNMAR = M.marca        AND
					p.APOLNMOD = M.modelo       AND
					p.APOLNSUB = M.submodelo    AND
					p.APOLNTERM = M.terminacion AND
					p.APOLNANU = M.año  
			/*
			left outer join
				xautos.dbo.xvehiculo v WITH(NOLOCK)
			on 
				p.apolmatr=v.matricula
				And
				p.apolclav=v.apolclav
			*/
			left join --para asegurar la integridad con colectivos
				dw_autos..TUCCOLEC TUC WITH(NOLOCK)
			on
				APOLIDCO=uccoidco 
			left join DW_AUTOS..TAPRODUC PC2 WITH(NOLOCK) on PC2.APROPROD = CAST(P.APOLTSEG AS VARCHAR) + P.APOLSUBP 
			left join DW_AUTOS..TAPRODUC PC1 WITH(NOLOCK) on PC1.APROPROD = CAST(P.APOLTSEG AS VARCHAR)
			left join dw_autos.dbo.tamrgcnt TAM WITH(NOLOCK) ON AMRGCNT_CODAGR = 'AGRE0021' AND AMRGCNT_CODIGO = cast(alogrpol as int) 
			cross apply comun.dbo.fn_TipoPersona_tbl (ISNULL(alognift,apolnift)) F

		)tmp
		left join XDIM.autos.CS_CertificadoSiniestralidad CS on tmp.IdVerificacion = CS.AUCDOPOLI
		left JOIN DW_AUTOS..TAUSOLIC solic (nolock)
		on  tmp.idsolicitud=solic.AUSOLIC_ID_SOLICIT	
		and tmp.IdEmpresa =solic.AUSOLIC_ID_EMPRESA		
		and solic.AUSOLIC_ID_RAMO =1	
	) s
	WHERE s.Orden = 1
	option (recompile)
	
	set @Nregistros=@@rowcount

	-- David Alarcón 11/04/2013 Actualizamos posteriormente para no penalizar la carga de la tabla ya que la Fecha de Emisón se calcula en la propia consulta
	UPDATE C
	SET 
		  C.Apertura_Fecha = CASE WHEN CONVERT(VARCHAR(8),C.FecEmision,112) < '20121212' THEN NULL ELSE C.Apertura_Fecha END
		, C.Apertura_Operador = CASE WHEN CONVERT(VARCHAR(8),C.FecEmision,112) < '20121212' THEN NULL ELSE C.Apertura_Operador END
		, C.Apertura_Producto = CASE WHEN CONVERT(VARCHAR(8),C.FecEmision,112) < '20130128' THEN NULL ELSE C.Apertura_Producto END
	FROM tmp.xautos_dbo.XVerificaciones C           

	create index ix1 on tmp.xautos_dbo.XVerificaciones	(idverificacion,orden)


	-- Los nuevos registros ya llevan los campos de certificado de siniestralidad actualizado.
	-- Actualizamos también los registros que no son nuevos pero cuyo certificado ha podido cambiar.
	update ve
	set CompañiaProcedencia = CS.AUCDOCCOM, 
		NAñosCompProcedencia = CS.NAñosProc,
		NSiniCompProcedencia = CS.NSiniProc,
		OrigenCompProc = 'T',
		f_carga = getdate()
	FROM xautos..xverificaciones ve
	join XDIM.autos.CS_CertificadoSiniestralidad CS 
	on ve.IdVerificacion = CS.AUCDOPOLI
	where CS.f_carga > @UltimaFcargaX
	-- tiempo ejecución = 7 seg. 

	exec comun..eliminatabla 'tmp.xautos_dbo.xverificaciones_incremental'	
	exec comun..eliminatabla 'tmp.xautos_dbo.xverificaciones_incremental_0'	 
	exec comun..eliminatabla 'tmp.xautos_dbo.XVerificaciones_1'
 
	
	set @Nregistros=@Nregistros-@@rowcount

	return(@Nregistros)
	
	





