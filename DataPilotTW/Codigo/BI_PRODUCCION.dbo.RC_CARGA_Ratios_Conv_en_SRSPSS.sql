

--exec BI_PRODUCCION.dbo.RC_CARGA_Ratios_Conv_en_SRSPSS

CREATE PROCEDURE [dbo].[RC_CARGA_Ratios_Conv_en_SRSPSS] @odate date = '20170101' /* cualquiera que no sea Jueves */
													 , @fechaInicio datetime = null
AS

/*----------------------------------------------------------------------------------------
DESCRIPCION:
	Procedimiento que actualiza el tablón de Ratios de Conversión de forma incremental
------------------------------------------------------------------------------------------
CREADO POR/FECHA: 

------------------------------------------------------------------------------------------
MODIFICADO POR/FECHA: 	21/03/2017 Raquel Humanes Se añade al tablon el campo Cod_Agreg_Cruce
						13/06/2017 Raquel Humanes Se añaden al tablon los campos 
							SeverityLlamAsnef, RiskLlamAsnef, SeverityLlamExperian y RiskLlamExperian
						16/06/2017 Raquel Humanes Se cambian los nombres de los campos PresenciaAnef, SeverityScore y RiskScore
						por MosoridadGlobal, SeverityGlobal y RiskGlobal
							
------------------------------------------------------------------------------------------
ENTRADAS:
------------------------------------------------------------------------------------------
SALIDAS:
------------------------------------------------------------------------------------------
OBSERVACIONES:
----------------------------------------------------------------------------------------*/

	declare @msg varchar(max)
	declare @UltFCarga datetime

	
--QUERY 0: Establecemos la fecha inicial desde la que se realiza la carga incremental
	if @fechaInicio is not null
		set @UltFCarga = @fechaInicio
	else
		SELECT @UltFCarga = isnull(MAX(f_carga), '20170102'/*cambiar más adelante a '19000101' para reprocesado total si la tabla está vacía*/) 
		FROM BI_PRODUCCION.dbo.Tablon_Ratios_Conversion

	set @msg = 'Inicio carga desde ' + cast(@UltFCarga as varchar)
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

----QUERY 1: seleccionamos los NIFs para los que ha cambiado su antigüedad
--	exec comun..eliminatabla 'tmp.BI_PRODUCCION_dbo.tmp_RC_dim_DatosTomador'
--	SELECT NifTomador
--	INTO tmp.BI_PRODUCCION_dbo.tmp_RC_dim_DatosTomador
--	FROM BI_PRODUCCION.dbo.RC_dim_DatosTomador
--	WHERE f_carga > @UltFCarga

--	set @msg = 'QUERY 1: ' + cast(@@ROWCOUNT as varchar) + ' registros'
--	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

--QUERY 2: conversiones con estado final "póliza" que han cambiado o cuyo NIFTomador ha cambiado
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_pruebas'
	SELECT RATI.*
	INTO  TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_pruebas
	FROM BI_PRODUCCION.dbo.RC_TH_Ratios_Conversion RATI WITH(NOLOCK) 
	--LEFT JOIN tmp.BI_PRODUCCION_dbo.tmp_RC_dim_DatosTomador AM 
	--ON RATI.NIFTomador = AM.NIFTomador
	WHERE f_carga > @UltFCarga --or AM.NIFTomador is not null

	set @msg = 'QUERY 2: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

--QUERY 2b: conversiones con estado final "póliza" que han cambiado o cuyo NIFTomadro ha cambiado
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Polizas_pruebas'
	SELECT RATI.IdConversion, RATI.IdPoliza
	INTO  TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Polizas_pruebas
	FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_pruebas RATI WITH(NOLOCK) 
	WHERE RATI.Cod_estadoFinal IN ('P0','P1') 

	set @msg = 'QUERY 2b: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

--QUERY 3: conversiones con estado final distinto de "póliza" que han cambiado o cuyo NIFTomadro ha cambiado
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_NoPolizas_pruebas'
	SELECT 
		RATI.IdConversion,
		RATI.Cod_estadoFinal AS EstadoFinal, 
		CASE
		WHEN RATI.Cod_estadoFinal = 'C' then RATI.IdCotizacion
		WHEN RATI.Cod_estadoFinal = 'R' then RATI.IdPresupuesto
		WHEN RATI.Cod_estadoFinal = 'V' then RATI.IdVerificacion
		END AS IdPoliza
	INTO  TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_NoPolizas_pruebas
	FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_pruebas RATI WITH(NOLOCK) 
	WHERE RATI.Cod_estadoFinal NOT IN ('P0','P1') 

	set @msg = 'QUERY 3: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

--QUERY 4: 
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.TMP_MOV_POLIZAS_SRPSS_pruebas'
	/*
	SELECT  TAU.AUPOLCLAV APOLCLAV
			,TAU.AUPOLOD20 APOLOD20
			,TAU.AUPOLOD30 APOLOD30
			,TAU.AUPOLVD30 APOLVD30
			,TAU.AUPOLVD50 APOLVD50
			,TAU.AUPOLID40 APOLID40
			,TAU.AUPOLID60 APOLID60
			,1             APOLORDE
			,'20501231'    APOLFEFE
	INTO TMP.BI_PRODUCCION_DBO.TMP_MOV_POLIZAS_SRPSS_pruebas
	FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Polizas_pruebas P JOIN DW_AUTOS.DBO.TAUPOLIZ TAU (NOLOCK) ON TAU.AUPOLCLAV = P.IdPoliza
	UNION ALL
	SELECT  TAU.AUHISPOLI APOLCLAV
			,TAU.AUHISOD20 APOLOD20
			,TAU.AUHISOD30 APOLOD30
			,TAU.AUHISVD30 APOLVD30
			,TAU.AUHISVD50 APOLVD50
			,TAU.AUHISID40 APOLID40
			,TAU.AUHISID60 APOLID60
			,TAU.AUHISORDE APOLORDE
			,TAU.AUHISFEFE APOLFEFE
	FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Polizas_pruebas P JOIN DW_AUTOS.DBO.TAUHISTO TAU (NOLOCK) ON TAU.AUHISPOLI = P.IdPoliza
	*/
	select apolclav, 
		case when DescuentoObligatorio = 20 then 20
			else 0 end AS APOLOD20
		,case when DescuentoObligatorio = 30 then 30
			else 0 end AS APOLOD30
		,case when DescuentoVoluntario = 30 then 30
		        else 0 end AS APOLVD30
		,case when DescuentoVoluntario = 50 then 50
		        else 0 end AS APOLVD50
		,case when DescuentoOcupantes = 40 then 40
		        else 0 end AS APOLID40
		,case when DescuentoOcupantes = 60 then 60
		        else 0 end AS APOLID60
                ,1 AS apolorde
		, '20501231' AS APOLFEFE                  
	INTO TMP.BI_PRODUCCION_DBO.TMP_MOV_POLIZAS_SRPSS_pruebas
	FROM xautos..XPOLIZAS_IMPUTACION XIM, TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Polizas_pruebas P
        where XIM.apolclav = p.idpoliza
	and PrimerMovimiento = 1

	set @msg = 'QUERY 4: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1	

--QUERY 5: 
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Descuentos_pruebas'
	SELECT * 
	INTO  TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Descuentos_pruebas
	FROM 
	(
	SELECT 
		TMP.IdConversion,
		CAST(TMP.DescuentoObligatorio AS TINYINT) AS DescuentoObligatorio,
		CAST(TMP.DescuentoVoluntario AS TINYINT)  AS DescuentoVoluntario,
		CAST(TMP.DescuentoOcupantes AS TINYINT) AS DescuentoOcupantes,
		ROW_NUMBER() OVER (PARTITION BY TMP.IdPoliza ORDER BY APOLORDE DESC, TMP.ACTUAL ASC) AS ORDEN

	FROM
	(	
		SELECT 
			RATI.IdConversion,
			RATI.IdPoliza, 
			CASE WHEN MOV.APOLOD20>0 THEN 20
				 WHEN MOV.APOLOD30>0 THEN 30
				 ELSE 0
			END AS DescuentoObligatorio,
			CASE WHEN MOV.APOLVD30>0 THEN 30
				 WHEN MOV.APOLVD50>0 THEN 50
				 ELSE 0
			END AS DescuentoVoluntario,
			CASE WHEN MOV.APOLID40>0 THEN 40
				 WHEN MOV.APOLID60>0 THEN 60
				 ELSE 0
			END AS DescuentoOcupantes,
			MOV.APOLORDE,
			1 AS ACTUAL
		FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Polizas_pruebas RATI WITH(NOLOCK) 
		INNER JOIN XAUTOS.dbo.XPOLIZAS XPOL WITH(NOLOCK) 
		ON RATI.IdPoliza = XPOL.apolclav
		INNER JOIN TMP.BI_PRODUCCION_DBO.TMP_MOV_POLIZAS_SRPSS_pruebas MOV WITH(NOLOCK) 
		ON XPOL.APOLCLAV = MOV.APOLCLAV 
		AND XPOL.FechaMovFin = DATEADD(DAY,-1,MOV.APOLFEFE)
		WHERE XPOL.FechaMovIni <= GETDATE() AND XPOL.FechaMovFin >= CAST(GETDATE() AS DATE)

	UNION ALL

		--Unimos los datos de pólizas a futuro que no tienen dato actual
		SELECT 
			RATI.IdConversion,
			RATI.IdPoliza, 
			CASE WHEN MOV.APOLOD20>0 THEN 20
				 WHEN MOV.APOLOD30>0 THEN 30
				 ELSE 0
			END AS DescuentoObligatorio,
			CASE WHEN MOV.APOLVD30>0 THEN 30
				 WHEN MOV.APOLVD50>0 THEN 50
				 ELSE 0
			END AS DescuentoVoluntario,
			CASE WHEN MOV.APOLID40>0 THEN 40
				 WHEN MOV.APOLID60>0 THEN 60
				 ELSE 0
			END AS DescuentoOcupantes,
			MOV.APOLORDE,
			2 AS ACTUAL
		FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Polizas_pruebas RATI WITH(NOLOCK) 
		INNER JOIN XAUTOS.dbo.XPOLIZAS XPOL WITH(NOLOCK) 
		ON RATI.IdPoliza = XPOL.apolclav
		INNER JOIN TMP.BI_PRODUCCION_DBO.TMP_MOV_POLIZAS_SRPSS_pruebas MOV WITH(NOLOCK) 
		ON XPOL.APOLCLAV = MOV.APOLCLAV 
		AND XPOL.FechaMovFin = DATEADD(DAY,-1,MOV.APOLFEFE)
		WHERE XPOL.FechaMovFin >= CAST(GETDATE() AS DATE)

	UNION ALL
	-- Presupuestos
		SELECT 
			RATI.IdConversion,
			RATI.IdPoliza, 
			PRE.DescuentoObligatorio,
			PRE.DescuentoVoluntario,
			PRE.DescuentoOcupantes,
			1 AS APOLORDE,
			3 AS ACTUAL
		FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_NoPolizas_pruebas RATI WITH(NOLOCK) 
		INNER JOIN xautos..xpresupuestos PRE WITH(NOLOCK) 
		ON RATI.Idpoliza = PRE.Idpresupuesto
		WHERE RATI.EstadoFinal IN ('R')
		--Unimos los datos de presupuestos y tasaciones
		/*
		SELECT 
			RATI.IdConversion,
			RATI.IdPoliza, 
			CASE WHEN PRE.APOLOD20>0 THEN 20
				 WHEN PRE.APOLOD30>0 THEN 30
				 ELSE 0
			END AS DescuentoObligatorio,
			CASE WHEN PRE.APOLVD30>0 THEN 30
				 WHEN PRE.APOLVD50>0 THEN 50
				 ELSE 0
			END AS DescuentoVoluntario,
			CASE WHEN PRE.APOLID40>0 THEN 40
				 WHEN PRE.APOLID60>0 THEN 60
				 ELSE 0
			END AS DescuentoOcupantes,
			1 AS APOLORDE,
			3 AS ACTUAL
		FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_NoPolizas_pruebas RATI WITH(NOLOCK) 
		INNER JOIN DW_AUTOS.dbo.PRESUPUESTOS PRE WITH(NOLOCK) 
		ON RATI.IdPoliza = PRE.APOLCLAV 
		WHERE RATI.EstadoFinal IN ('R','V')
		*/
    UNION ALL
	-- Verificaciones
	SELECT 
			RATI.IdConversion,
			RATI.IdPoliza, 
			VER.DescuentoObligatorio,
			VER.DescuentoVoluntario,
			VER.DescuentoOcupantes,
			1 AS APOLORDE,
			3 AS ACTUAL
		FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_NoPolizas_pruebas RATI WITH(NOLOCK) 
		INNER JOIN xautos..xverificaciones VER WITH(NOLOCK) 
		ON RATI.Idpoliza = VER.IdVerificacion
		WHERE RATI.EstadoFinal IN ('V')

	)TMP )TMP1
	WHERE ORDEN = 1	

	set @msg = 'QUERY 5: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

--QUERY 6: 
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.CR_RATIOS_ampliacion_DATOS_XAUTOS_pruebas'
	SELECT 	
			  RATI.IdConversion
			, PRE.Desc_PresenciaAsnef AS 'PresenciaAsnef'
			, SE.Desc_SeverityScore as 'SeverityScore'
			, rs.Desc_RiskScore as 'RiskScore'
	into TMP.BI_PRODUCCION_dbo.CR_RATIOS_ampliacion_DATOS_XAUTOS_pruebas	
 	FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_pruebas  RATI (NOLOCK) 
	LEFT JOIN XDIM.autos.MorosidadPuente MO WITH (NOLOCK) ON RATI.idMorosidad=MO.cod_morosidadpuente
	LEFT JOIN XDIM.AUTOS.PresenciaAsnef PRE WITH (NOLOCK) ON MO.cod_presenciaasnef=pre.cod_PresenciaAsnef
	LEFT JOIN XDIM.autos.SeverityScore SE WITH (NOLOCK) ON MO.cod_severityscore=SE.cod_SeverityScore
	LEFT JOIN XDIM.autos.RiskScore RS WITH (NOLOCK) ON MO.cod_riskscore=RS.cod_RiskScore

	set @msg = 'QUERY 6: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

--QUERY 7:
    exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.CR_RATIOS_SEGMENTO_CRM'
    SELECT CRM_P.nif					as NifTomador
			 , CRM_SG.FecEmiIni				as FecEmiIniSegCRM
			 , CRM_SG.FecEmiFin				as FecEmiFinSegCRM
			 , CRM_SG.Segmento				as SegmentoCRM
			 , CRM_SG_DES.Segmento			as SegmentoCRM_Des
		INTO TMP.BI_PRODUCCION_dbo.CR_RATIOS_SEGMENTO_CRM
		FROM [CRM_SNP].[autos].[Personas] CRM_P  with(nolock)
		INNER JOIN
		  TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_pruebas RAT
		  ON CRM_P.Nif = RAT.NifTomador
		LEFT JOIN [CRM_SNP].[autos].[PersonasInformacion] CRM_PI  with(nolock)
		ON CRM_P.IdPersona=CRM_PI.IdPersona	
		LEFT JOIN CRM_SNP.autos.PersonasSegmentos CRM_SG  with(nolock)	
		ON CRM_P.IdPersona = CRM_SG.IdPersona
		and CRM_SG.IdEmpresa = 1 
		LEFT JOIN CRM_SNP.comun.Segmentos CRM_SG_DES  with(nolock)	
		on CRM_SG.Segmento = CRM_SG_DES.IdSegmento	
		WHERE 
		  CRM_P.SwOrdenNif=1

	set @msg = 'QUERY 7: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1


--QUERY 8:
    exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.CR_RATIOS_ANTIGUEDAD_MUTUALISTA'
    SELECT
		  XPOL.NifTomador
	    ,  MIN(FechaContratacion) FechaEntrada
    INTO TMP.BI_PRODUCCION_dbo.CR_RATIOS_ANTIGUEDAD_MUTUALISTA
    FROM
	    xautos.dbo.xpolizas_imputacion XPOL WITH(NOLOCK)
	    INNER JOIN
		  TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_pruebas RAT
		  ON XPOL.NifTomador = RAT.NifTomador
	    JOIN
	    xautos.dbo.xpolizas_comun XPC WITH(NOLOCK)
		  ON
		  XPOL.apolclav = XPC.apolclav
    GROUP BY
	    XPOL.niftomador

	set @msg = 'QUERY 8: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

--QUERY 9:
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_Ratios_Conversion_Competitividad_pruebas'
	SELECT distinct
		   RAT.[IdConversion]
		  ,RAT.[IdCotizacion]
		  ,RAT.[Idpresupuesto]
		  ,RAT.[IdVerificacion]
		  ,RAT.[IdPoliza]
		  ,RAT.[Cod_FechaInicial]
		  ,RAT.[Cod_FechaFinal]
		  ,RAT.[Cod_Producto]
		  ,RAT.[Cod_Provincia]
		  ,RAT.[Cod_TipoPersona]
		  ,RAT.[Cod_TipoVehiculo]
		  ,RAT.[cod_AntiguedadVehiculo]
		  ,RAT.[Cod_Marca]
		  ,RAT.[cod_EdadTomador]
		  ,RAT.[Cod_EdadConductor]
		  ,RAT.[Cod_FRT]
		  ,RAT.[Cod_SexoTomador]
		  ,RAT.[Cod_CanalEntradaInicial]
		  ,RAT.[Cod_CanalEntradaFinal]
		  ,RAT.[Cod_CapitalAsegurado]
		  ,RAT.[Cod_Descuento]
		  ,RAT.[Cod_AgenteInicial]
		  ,RAT.[Cod_AgenteFinal]
		  ,RAT.[Cod_EstadoInicial]
		  ,RAT.[Cod_EstadoFinal]
		  ,RAT.[HoraInicial]
		  ,RAT.[Cod_Presentador]
		  ,RAT.[IdCompañia]
		  ,RAT.[Cod_Banco]
		  ,RAT.[cod_postal]
		  ,RAT.[Agregador]
		  ,RAT.[Cod_Negocio]
		  ,RAT.[Cod_FechaConstruccion]
		  ,RAT.[Cod_FechaConstruccionTablon]
		  ,RAT.[NumConversiones]
		  ,RAT.[IdEmpresa]
		  ,RAT.[GarantiaMecanica]
		  ,RAT.[SujetoANormativa]
		  ,RAT.[Lunas]
		  ,RAT.[ProProducto]
		  ,RAT.[LunasFP]
		  ,RAT.[garantiamecanicaFP]
		  ,RAT.[idCobertura]
		  ,RAT.[idMorosidad]
		  ,YEAR(RAT.Cod_FechaFinalEfecto) * 10000 + MONTH(RAT.Cod_FechaFinalEfecto) * 100 + DAY(RAT.Cod_FechaFinalEfecto) as Cod_FechaEfecto
		  ,RAT.[cod_generadorDemanda]
		  ,getdate() as f_carga
		  ,RAT.[Extrapolacion]
		  ,RAT.[cod_PromocionCaptacionInicial]
		  ,RAT.[cod_PromocionCaptacionFinal]
		  ,RAT.[FNACTomador]
		  ,RAT.[FNACConductor]
		  ,RAT.[FRT]
		  ,RAT.[id15PuntosCarnet]
		  --,RAT.[cod_NegocioCierre]
		  ,rat.Cod_Agreg_Cruce
		  ,RAT.[PrimaInicial]
		  ,RAT.[idSolicitudFinal]
		  ,RAT.[Prima]
		  ,RAT.[IDSEGMENTONM]
		  ,RAT.[IDTIPOMERCADO]
		  ,RAT.Score_Siniestralidad
		  ,RAT.Score_Competitividad
		  ,RAT.Score_GC_Siniestralidad
		  ,RAT.Score_GC_Competitividad
		  ,RAT.Score_Agregadores
		  ,RAT.Score_Agregadores_His
		  ,RAT.Marginal
		  ,RAT.Marginal_Fecha_Ini
		  ,RAT.Marginal_Fecha_Fin
		  ,CASE 
		   when ANT.FechaEntrada is null then  0
		   when (YEAR(ANT.FechaEntrada) * 10000 + MONTH(ANT.FechaEntrada) * 100 + DAY(ANT.FechaEntrada) > rat.Cod_FechaFinal) then 0
		   else  (rat.Cod_FechaFinal - (YEAR(ANT.FechaEntrada) * 10000 + MONTH(ANT.FechaEntrada) * 100 + DAY(ANT.FechaEntrada)))/10000 
		  end 
		  as Cod_AntiguedadMutualista
		  ,YEAR(ANT.FechaEntrada) * 10000 + MONTH(ANT.FechaEntrada) * 100 + DAY(ANT.FechaEntrada) AS FechaEfectoMutualista	
		  ,CIA.NAñosProc AS Cod_AñosOtraCompañia
		  ,CIA.NSiniProc AS Cod_SiniestrosOtraCompañia 
		  ,CAST(ISNULL(DESCU.DescuentoObligatorio, 255) AS TINYINT) AS DescObligatorio
		  ,CAST(ISNULL(DESCU.DescuentoVoluntario, 255) AS TINYINT) AS DescVoluntario
		  ,CAST(ISNULL(DESCU.DescuentoOcupantes, 255) AS TINYINT) AS DescOcupantes
		  ,isnull(CIA.Cod_Compañia,0) as IdCompañiaAnterior
		  ,TipoGenerador TipoGenerador
		  ,TipoNegocio   TipoNegocioProveedor
		  ,Negocio       NegocioProveedor
		  ,SEG.[segmento n1] + ' ' + SEG.[segmento n2] AS SegmentoEstrategico
		  ,DEL.Delegacion AS [DelegacionGestora]
		  ,POI.Promocion [Promoción Inicial]
		  ,POF.Promocion [Promoción Final]
		  ,RAT.FnacTomadorTablon as FecNacTomador
		  ,RAT.FNacConductorTablon AS FecNacConductor
		  ,RAT.FRTTablon as FRTConductor
		  ,RAT.FnacConductorOcasional
		  ,RAT.FrtConductorOcasional
		  ,isnull(s.Sexo,'No Aplica') as SexoConductorOcasional 
		  ,REL.descripcion AS RelacionCROConductor
		  ,RAT.Kilometros
		  ,case when RAT.Garaje='CA' then 'CALLE'
				when   RAT.Garaje='GC' then 'G.COLECTIVO'
				when   RAT.Garaje='GI' then 'G.INDIVIDUAL'
				else   RAT.Garaje end as Garaje
		  ,COALESCE(usoact.TCDATDESDAT, usomot.TCDATDESDAT, 'No informado') as UsoVehiculo
		  ,RAT.NumOcupantesContratado    
		  ,RAT.YearAdquisicion
		  ,RAT.Tarifa
		  ,case when RAT.FrecuenciaPago IS null or RAT.FrecuenciaPago='0' then 'Anual' else FR.Nombre END AS FrecuenciaPago
		  ,isnull(SEGSRM.SegmentoCRM_Des,'No Informado') as SegmentoCRM
		  ,CASE WHEN RAT.EstadoCivil='S' then 'Soltero'
				WHEN RAT.EstadoCivil='C' then 'Casado'
				WHEN RAT.EstadoCivil='D' then 'Divorciado'
				WHEN RAT.EstadoCivil='V' then 'viudo'
				WHEN RAT.EstadoCivil='P' then 'Pareja de Hecho'
				WHEN RAT.EstadoCivil='X' then 'Separado'
				WHEN RAT.EstadoCivil='O' then 'Otros'
				ELSE 'No informado' 
		   END as EstadoCivil
		  ,xa.PresenciaAsnef AS MosoridadGlobal
		  ,xa.SeverityScore AS SeverityGlobal
		  ,xa.RiskScore AS RiskGlobal
		  ,RAT.idSolicitudFinal idSolicitud
		  ,RAT.NIFTomador			
		  ,RAT.Telefono			
		  ,RAT.IdNegocioInicial as Cod_NegocioInicial

		  --Notas llamadas
		  ,Equi.Severity as SeverityLlamAsnef
		  ,Equi.Risk as RiskLlamAsnef
		  ,Expe.Severity as SeverityLlamExperian
		  ,Expe.Risk as RiskLlamExperian
		  
	INTO  TMP.BI_PRODUCCION_dbo.RC_TH_Ratios_Conversion_Competitividad_pruebas
	FROM TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_pruebas RAT WITH(NOLOCK) 
	LEFT JOIN TMP.BI_PRODUCCION_dbo.CR_RATIOS_SEGMENTO_CRM SEGSRM ON RAT.NifTomador = SEGSRM.NifTomador AND LEFT(RAT.Cod_FechaFinal, 8) BETWEEN SEGSRM.FecEmiIniSegCRM AND SEGSRM.FecEmiFinSegCRM
	LEFT JOIN TMP.BI_PRODUCCION_dbo.CR_RATIOS_ANTIGUEDAD_MUTUALISTA ANT ON RAT.NifTomador = ANT.NifTomador
	LEFT JOIN BI_PRODUCCION.dbo.RC_DIM_CompañiaProcedencia CIA WITH(NOLOCK) ON RAT.IdCompañiaProc = CIA.Id_Certificado
	-- único inconveniente, todavía saca datos de DW
	LEFT JOIN TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Descuentos_pruebas DESCU  WITH(NOLOCK) ON RAT.IdConversion = DESCU.IdConversion
	LEFT JOIN TMP.BI_PRODUCCION_dbo.CR_RATIOS_ampliacion_DATOS_XAUTOS_pruebas XA WITH(NOLOCK) ON RAT.IdConversion=XA.IdConversion
	LEFT JOIN XDIM.AUTOS.Negocios NEG (NOLOCK) ON RAT.Cod_Negocio = NEG.Cod_Negocio
	LEFT JOIN XDIM.NEGOCIOS.SEGMENTOESTRATEGICO SEG (NOLOCK) ON NEG.cod_tiponegocioestrategico = SEG.cod_segmentoEstrategico
	LEFT JOIN XDIM.AUTOS.DELEGACIONES DEL (NOLOCK) ON NEG.Cod_DelegacionGestora = DEL.Cod_operador
	LEFT JOIN XDIM.AUTOS.GeneradorDemandaTransformado XGDT  with(nolock) ON XGDT.idGeneradorTrans = RAT.cod_generadorDemanda
	LEFT JOIN XDIM.AUTOS.PROMOCIONES POI  with(nolock) ON POI.IDPROMOCION = RAT.COD_PROMOCIONCAPTACIONINICIAL 
	LEFT JOIN XDIM.AUTOS.PROMOCIONES POF  with(nolock) ON POF.IDPROMOCION = RAT.COD_PROMOCIONCAPTACIONFINAL 
	LEFT JOIN XDIM.AUTOS.RelacionCROConductor rel  with(nolock) on RAT.RelacionConductores=rel.cod_relacion
	LEFT JOIN XDIM.AUTOS.Sexo s with (nolock) on (case when RAT.SexoConductorOcasional='H' then 1 when RAT.SexoConductorOcasional='M' then 2 else RAT.SexoConductorOcasional end)=s.cod_sexo
	LEFT JOIN XDIM.AUTOS.FrecuenciaPago FR WITH (NOLOCK) ON RAT.FrecuenciaPago=FR.cod_frecPago
	LEFT JOIN COMUN.DBO.TTCDATOS usoact with(nolock) on RAT.UsoVehiculoAct=usoact.TCDATCODDAT and usoact.TCDATCODTBL='TABUSOACT'
	LEFT JOIN COMUN.DBO.TTCDATOS usomot with(nolock) on RAT.UsoVehiculoAct=usomot.TCDATCODDAT and usomot.TCDATCODTBL='TABUSOMOT'
	--Notas llamadas experian y asnef 
	LEFT JOIN Reporting.autos.Notas_Llamadas_Proveedores Expe with(nolock) on RAT.idSolicitudFinal  = Expe.idsolicitud and expe.llamada='Experian'
	LEFT JOIN Reporting.autos.Notas_Llamadas_Proveedores Equi with(nolock) on RAT.idSolicitudFinal  = Equi.idsolicitud and equi.llamada='Equifax'



	set @msg = 'QUERY 9: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1



/** Código ActualizaTablaDiferentesCampos 'S' con algunas modificaciones **/	

	delete from BI_PRODUCCION.dbo.Tablon_Ratios_Conversion with (tablock)
	output
		'dbo',
		'Tablon_Ratios_Conversion',
		CONVERT(VARCHAR(max),DELETED.IdConversion),
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		'DL',
		GETDATE(),
		GETDATE()
	into BI_PRODUCCION.CARGAS.BORRADOS
	from BI_PRODUCCION.dbo.Tablon_Ratios_Conversion f
	left join BI_PRODUCCION.dbo.RC_TH_Ratios_Conversion t
	on f.IdConversion = t.IdConversion
	where t.IdConversion is null
		
	set @msg = 'QUERY Borrados: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

	Update BI_PRODUCCION.dbo.Tablon_Ratios_Conversion with (tablock)
	set 
		IdCotizacion = t.IdCotizacion,
		Idpresupuesto = t.Idpresupuesto,
		IdVerificacion = t.IdVerificacion,
		IdPoliza = t.IdPoliza,
		Cod_FechaInicial = t.Cod_FechaInicial,
		Cod_FechaFinal = t.Cod_FechaFinal,
		Cod_Producto = t.Cod_Producto,
		Cod_Provincia = t.Cod_Provincia,
		Cod_TipoPersona = t.Cod_TipoPersona,
		Cod_TipoVehiculo = t.Cod_TipoVehiculo,
		cod_AntiguedadVehiculo = t.cod_AntiguedadVehiculo,
		Cod_FechaConstruccion = t.[Cod_FechaConstruccionTablon],
		Cod_Marca = t.Cod_Marca,
		cod_EdadTomador = t.cod_EdadTomador,
		Cod_EdadConductor = t.Cod_EdadConductor,
		Cod_FRT = t.Cod_FRT,
		Cod_SexoTomador = t.Cod_SexoTomador,
		Cod_CanalEntradaInicial = t.Cod_CanalEntradaInicial,
		Cod_CanalEntradaFinal = t.Cod_CanalEntradaFinal,
		Cod_CapitalAsegurado = t.Cod_CapitalAsegurado,
		Cod_Descuento = t.Cod_Descuento,
		Cod_AgenteInicial = t.Cod_AgenteInicial,
		Cod_AgenteFinal = t.Cod_AgenteFinal,
		Cod_EstadoInicial = t.Cod_EstadoInicial,
		Cod_EstadoFinal = t.Cod_EstadoFinal,
		HoraInicial = t.HoraInicial,
		Cod_Presentador = t.Cod_Presentador,
		IdCompañia = t.IdCompañia,
		Cod_Banco = t.Cod_Banco,
		cod_postal = t.cod_postal,
		Agregador = t.Agregador,
		Cod_Negocio = t.Cod_Negocio,
		Prima = t.Prima,
		PrimaInicial = t.PrimaInicial,
		NumConversiones = t.NumConversiones,
		IdEmpresa = t.IdEmpresa,
		Cod_AntiguedadMutualista = t.Cod_AntiguedadMutualista,
		FechaEfectoMutualista = t.FechaEfectoMutualista,
		Cod_AñosOtraCompañia = t.Cod_AñosOtraCompañia,
		Cod_SiniestrosOtraCompañia = t.Cod_SiniestrosOtraCompañia,
		DescObligatorio = t.DescObligatorio,
		DescVoluntario = t.DescVoluntario,
		DescOcupantes = t.DescOcupantes,
		IdCompañiaAnterior = t.IdCompañiaAnterior,
		TipoGenerador = t.TipoGenerador,
		TipoNegocioProveedor = t.TipoNegocioProveedor,
		NegocioProveedor = t.NegocioProveedor,
		SegmentoEstrategico = t.SegmentoEstrategico,
		DelegacionGestora = t.DelegacionGestora,
		Promocion_Inicial = t.[Promoción Inicial],
		Promocion_Final = t.[Promoción Final],
		id15PuntosCarnet = t.id15PuntosCarnet,
		FecNacTomador = t.FecNacTomador,
		FecNacConductor = t.FecNacConductor,
		FRTConductor = t.FRTConductor,
		FnacConductorOcasional = t.FnacConductorOcasional,
		FrtConductorOcasional = t.FrtConductorOcasional,
		SexoConductorOcasional = t.SexoConductorOcasional,
		RelacionCROConductor = t.RelacionCROConductor,
		Kilometros = t.Kilometros,
		Garaje = t.Garaje,
		UsoVehiculo = t.UsoVehiculo,
		NumOcupantesContratado = t.NumOcupantesContratado,
		YearAdquisicion = t.YearAdquisicion,
		Tarifa = t.Tarifa,
		FrecuenciaPago = t.FrecuenciaPago,
		SegmentoCRM = t.SegmentoCRM,
		EstadoCivil = t.EstadoCivil,
		MorosidadGlobal = t.MosoridadGlobal,
		SeverityGlobal = t.SeverityGlobal,
		RiskGlobal = t.RiskGlobal,
		f_carga = t.f_carga,
		idSolicitud = t.idSolicitud,
		Score_Siniestralidad = t.Score_Siniestralidad,
		Score_Competitividad = t.Score_Competitividad,
		Score_GC_Siniestralidad = t.Score_GC_Siniestralidad,
		Score_GC_Competitividad = t.Score_GC_Competitividad,
		Score_Agregadores = t.Score_Agregadores,
		Score_Agregadores_His = t.Score_Agregadores_His,
		Marginal = t.Marginal,
		Marginal_Fecha_Ini = t.Marginal_Fecha_Ini,
		Marginal_Fecha_Fin = t.Marginal_Fecha_Fin,
		NIF_Tomador = t.NIFTomador,
		Telefono = t.Telefono,
		Cod_NegocioInicial = t.Cod_NegocioInicial,
		Cod_FechaEfecto = t.Cod_FechaEfecto,
		Cod_Agreg_Cruce =t.Cod_Agreg_Cruce,
		--Notas llamadas
		SeverityLlamAsnef=t.SeverityLlamAsnef,
		RiskLlamAsnef=t.RiskLlamAsnef,
		SeverityLlamExperian=t.SeverityLlamExperian,
		RiskLlamExperian=t.RiskLlamExperian
	from BI_PRODUCCION.dbo.Tablon_Ratios_Conversion f
	inner join TMP.BI_PRODUCCION_dbo.RC_TH_Ratios_Conversion_Competitividad_pruebas t
	on f.IdConversion = t.IdConversion

	set @msg = 'QUERY Actualizados: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1	

	insert into BI_PRODUCCION.dbo.Tablon_Ratios_Conversion with (tablock,Holdlock)
		(IdConversion,IdCotizacion,Idpresupuesto,IdVerificacion,IdPoliza,Cod_FechaInicial,Cod_FechaFinal,Cod_Producto,Cod_Provincia,Cod_TipoPersona,Cod_TipoVehiculo,cod_AntiguedadVehiculo,Cod_FechaConstruccion,Cod_Marca,cod_EdadTomador,Cod_EdadConductor,Cod_FRT,Cod_SexoTomador,Cod_CanalEntradaInicial,Cod_CanalEntradaFinal,Cod_CapitalAsegurado,Cod_Descuento,Cod_AgenteInicial,Cod_AgenteFinal,Cod_EstadoInicial,Cod_EstadoFinal,HoraInicial,Cod_Presentador,IdCompañia,Cod_Banco,cod_postal,Agregador,Cod_Negocio,Prima,PrimaInicial,NumConversiones,IdEmpresa,Cod_AntiguedadMutualista,FechaEfectoMutualista,Cod_AñosOtraCompañia,Cod_SiniestrosOtraCompañia,DescObligatorio,DescVoluntario,DescOcupantes,IdCompañiaAnterior,TipoGenerador,TipoNegocioProveedor,NegocioProveedor,SegmentoEstrategico,DelegacionGestora,Promocion_Inicial,Promocion_Final,id15PuntosCarnet,FecNacTomador,FecNacConductor,FRTConductor,FnacConductorOcasional,FrtConductorOcasional,SexoConductorOcasional,RelacionCROConductor,Kilometros,Garaje,UsoVehiculo,NumOcupantesContratado,YearAdquisicion,Tarifa,FrecuenciaPago,SegmentoCRM,EstadoCivil,MorosidadGlobal,SeverityGlobal,RiskGlobal,f_carga,idSolicitud,Score_Siniestralidad,Score_Competitividad,Score_GC_Siniestralidad,Score_GC_Competitividad,Score_Agregadores,Score_Agregadores_His,Marginal,Marginal_Fecha_Ini,Marginal_Fecha_Fin,NIF_Tomador,Telefono,Cod_NegocioInicial,Cod_FechaEfecto,Cod_Agreg_Cruce,SeverityLlamAsnef,RiskLlamAsnef,SeverityLlamExperian,RiskLlamExperian)
	select 
		t.IdConversion,t.IdCotizacion,t.Idpresupuesto,t.IdVerificacion,t.IdPoliza,t.Cod_FechaInicial,t.Cod_FechaFinal,t.Cod_Producto,t.Cod_Provincia,t.Cod_TipoPersona,t.Cod_TipoVehiculo,t.cod_AntiguedadVehiculo,t.[Cod_FechaConstruccionTablon],t.Cod_Marca,t.cod_EdadTomador,t.Cod_EdadConductor,t.Cod_FRT,t.Cod_SexoTomador,t.Cod_CanalEntradaInicial,t.Cod_CanalEntradaFinal,t.Cod_CapitalAsegurado,t.Cod_Descuento,t.Cod_AgenteInicial,t.Cod_AgenteFinal,t.Cod_EstadoInicial,t.Cod_EstadoFinal,t.HoraInicial,t.Cod_Presentador,t.IdCompañia,t.Cod_Banco,t.cod_postal,t.Agregador,t.Cod_Negocio,t.Prima,t.PrimaInicial,t.NumConversiones,t.IdEmpresa,t.Cod_AntiguedadMutualista,t.FechaEfectoMutualista,t.Cod_AñosOtraCompañia,t.Cod_SiniestrosOtraCompañia,t.DescObligatorio,t.DescVoluntario,t.DescOcupantes,t.IdCompañiaAnterior,t.TipoGenerador,t.TipoNegocioProveedor,t.NegocioProveedor,t.SegmentoEstrategico,t.DelegacionGestora,t.[Promoción Inicial],t.[Promoción Final],t.id15PuntosCarnet,t.FecNacTomador,t.FecNacConductor,t.FRTConductor,t.FnacConductorOcasional,t.FrtConductorOcasional,t.SexoConductorOcasional,t.RelacionCROConductor,t.Kilometros,t.Garaje,t.UsoVehiculo,t.NumOcupantesContratado,t.YearAdquisicion,t.Tarifa,t.FrecuenciaPago,t.SegmentoCRM,t.EstadoCivil,t.MosoridadGlobal,t.SeverityGlobal,t.RiskGlobal,t.f_carga,t.idSolicitud,t.Score_Siniestralidad,t.Score_Competitividad,t.Score_GC_Siniestralidad,t.Score_GC_Competitividad,t.Score_Agregadores,t.Score_Agregadores_His,t.Marginal,t.Marginal_Fecha_Ini,t.Marginal_Fecha_Fin,t.NIFTomador,t.Telefono,t.Cod_NegocioInicial,t.Cod_FechaEfecto,t.Cod_Agreg_Cruce,t.SeverityLlamAsnef,t.RiskLlamAsnef,t.SeverityLlamExperian,t.RiskLlamExperian
	from TMP.BI_PRODUCCION_dbo.RC_TH_Ratios_Conversion_Competitividad_pruebas t
	left join BI_PRODUCCION.dbo.Tablon_Ratios_Conversion f
	on t.IdConversion = f.IdConversion
	where f.IdConversion is null

	set @msg = 'QUERY Insertados: ' + cast(@@ROWCOUNT as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

/** Fin carga ActualizaTablaDiferentesCampos *******************************************/

/** Iniciamos Comprobaciones ***********************************************************/


	declare   @registros00 int
			, @registros01 int

	select @registros00 = count(*) from bi_produccion..rc_th_ratios_conversion

	set @msg = 'Total conversiones en TH: ' + cast(@registros00 as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

	select @registros01 = count(*) from bi_produccion..tablon_ratios_conversion

	set @msg = 'Total conversiones en Tablón: ' + cast(@registros01 as varchar) + ' registros'
	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc',@msg,'C','F',1

	if (@registros00 <> @registros01)
	begin
		-- Error comprobaciones
		EXEC Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc','Error comprobaciones, el número de conversiones no coincide entre la TH y el tablón','C','M'	
		raiserror('Error comprobaciones, el número de operaciones no coinciden entre la tabla origen y la tabla TMP final',18,1)
		return(-1)
	end

	EXEC Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc','Fin comprobaciones OK','C','M'	

/** Fin Comprobaciones *****************************************************************/

	exec comun..eliminatabla 'tmp.BI_PRODUCCION_dbo.tmp_RC_dim_DatosTomador'	
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_pruebas'
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Polizas_pruebas'
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_NoPolizas_pruebas'
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.TMP_MOV_POLIZAS_SRPSS_pruebas'
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_DatosCompttvdd_Descuentos_pruebas'
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.CR_RATIOS_ampliacion_DATOS_XAUTOS_pruebas'
	exec comun..eliminatabla 'TMP.BI_PRODUCCION_dbo.RC_TH_Ratios_Conversion_Competitividad_pruebas'

	exec Comun..Logar 'BI_PRODUCCION','RC_CARGA_Ratios_Conv_en_SRSPSS_inc','Fin carga','C','F',1


	/*Si el odate es Jueves (ejecuta viernes por la noche) entonces lanza también el proceso total */
	--IF DATENAME(weekday,@odate) = 'Jueves' EXEC BI_PRODUCCION.dbo.RC_CARGA_Ratios_Conv_en_SRSPSS_total