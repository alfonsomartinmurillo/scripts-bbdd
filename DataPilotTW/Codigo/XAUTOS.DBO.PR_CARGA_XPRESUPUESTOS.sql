
--exec [xautos].[dbo].[pr_Carga_XPresupuestos] @UltimaFcargaX = '20160922'

CREATE procedure   [dbo].[pr_Carga_XPresupuestos] @UltimaFcargaX datetime
as

/*----------------------------------------------------------------------------
Devuelve datos de los presupuestos.
Se utiliza para la carga de Xpresupuestos
Para obtener la información de la poliza contratada nos basamos en nif y matricula, si 
no lo encontramos en nif solo.
------------------------------------------------------------------------------
CREADO POR/FECHA: Jésús Gómez 21-02-2007
------------------------------------------------------------------------------
MODIFICADO POR/FECHA:   
			 Jgomez 10/12/2009 cambiado nif, colectivo, pasado a TMP e incrementalizado 
			 
			 GPérez 09/02/2010 Para el cálculo incremental, vamos a considerar todos los 
			 cambios realizados en dw_autos..operativa y tambien en dw_autos..presupuestos.
			 Atención: Si se cambia el filtro para la subconsulta de la tabla dw_autos..operativa 
			 en la carga de xpresupuestos, habría que cambiarlo tambien en la carga de 
			 xpresupuestos_incremental.
			 
			 GPérez 28/04/2010 Incluimos el campo IdEmpresa aunque aún con valor fijo.
			 
			 GPérez 04/05/2010 Cambiamos / corregimos la forma de calcular la fecha de contratación del 
			                   vehículo.
			 nieves se migra a datamirror dw_autos..coletivos por dw_autos..tuccolec

			 GPérez 03/06/2011 En la carga del colectivo, no se consideran los tipos 'AG' ni 'FL'
			 
			 GPérez 10/06/2011 Inclusión del sexo del conductor y de la garantía mecánica. Peticiones:
								DJAP11QGDGMC
								DJGA11SECOH
							   
							   Modificada la eliminación de duplicados: se utiliza el orden directamente 
							   en la consulta y no se hace un Delete.	
			GPérez 13/09/2011 Referencia a TAUPOLIP en lugar de TAUPOLIP
			GPérez 06/10/2011 Incluido campo Negocio en Tabla.
			GPérez 08/11/2011 Considerado nuevo tipo de descuento Z (Sin descuento APOLRELD) en la consulta.
			GPérez 09/05/2012 Vamos a considerar todas las tablas utilizadas en la consulta para la carga
			                  incremental.
			GPérez 01/08/2012 El servidor no responde (como otras veces): dividimos la última consulta y 
							  creamos la nueva tabla tmp.xautos_dbo.XPresupuestos_1
			GPérez 05/10/2012 Inclusión de información de Asnef.
			Gemma Pérez 18/09/2013 Incluido tratamiento de tipo de negocio / colectivo IN Individual (Dimnesión obsoleta Colectivos)
			Gemma Pérez 23/04/2014  Incluido campo IdOficina (Punto de red)
			Óscar Sánchez 24/02/2015 Se usa la función tabular para el cálculo del tipo de persona. (D-113149)
										Se usa la misma función para el cálculo del campo sexo.
			Gemma Pérez   31/03/2015 Se modifica el uso de Union por Union All+Distinct debido al bajo rendimiento
			                         tras el borrado de presupuestos
			
			Angel Cañas		14/04/2015	Añadidos campos  idSolicitud e id15PuntosCarnet	
			Angel Cañas		16/04/2015	Se cambia tabla dbo.TAUDACOP de DW_MUTUA a DW_AUTOS
			
			Sergio Alvaro	28/04/2015	Se añaden campos nuevos
			
			Raquel Humanes 08/06/2015 El campo IdFrecuenciaPago se cambia para que no sea null siempre. Toma valor de dw_autos..presupuestos
			del campo AUPOPFPGA
				
			Gemma Pérez 28/10/2015 Eliminamos el uso de las tablas XTomador (estaba en Join y no se utilizaba)
			                       y XVehiculo (se calculaba la fecha de construcción cuando en XVehículo no
			                       se guardan presupuestos).

			Alvaro Roldán	21/09/2016  Introducimos los campos referentes a la compañía de procedencia: CompañiaProcedencia, NAñosCompProcedencia,
										NSiniCompProcedencia y OrigenCompProc
			
			Gemma Pérez 25/10/2016  Ampliación Marca en AMMO. Cálculo del campo IdModelo a través de los campos Marca, Modelo, Submodelo, Terminación y Anualidad.

			06/02/2017 - Alvaro Roldán. Añadimos Descuentos (Obligatorio, Voluntario y Ocupantes)
			28/02/2017 - Raquel Humanes Añadimos Cod_Agreg_Cruce

------------------------------------------------------------------------------
ENTRADAS:
------------------------------------------------------------------------------
SALIDAS:
------------------------------------------------------------------------------
OBSERVACIONES:
Los presupuestos normales tienen numeración de AlogRpol mayor de 9 mill. sin embargo las contrataciones de web 24x7 tienen numeración real 
ya que se graban como presupuestos. Ocurren en fiestas donde no se abre centralita  o a partir de las 10.30 de la noche o sábados 
 Se conserva la fecha de efecto y se contratan como póliza nueva por un operador Mutua en el siguiente día laborable (fecha  de emisión).  
Emitiéndose un nuevo alog de póliza nueva. La numeración es real, es decir, no es de 9 millones.

 Sexo Conductor: se ha optado por el criterio de que cualquier valor <> Hombre, Mujer es "No Aplica / No Informado".

	TRUNCATE TABLE XAUTOS..XPRESUPUESTOS
	EXEC COMUN..GESTORCARGAX 'XAUTOS..XPRESUPUESTOS',0,1

20110913 PRODUCCION DE HOST ELIMINA LOS PRESUPUESTOS CON NUMERACION  DE 9.500.187 a 9.999.999

ESTO AFECTA A LAS TABLAS:
VSAM 	      DWH 
APOLIZP     PRESUPUESTOS
AINSVEH     PRESUPUESTOS_Y_TASACIONES_POLIZAS
TAUPOLIP    TAUPOLIP

Se decide renombrar este rango de presupuestos para mantener nuestro histórico 
y pasar a una tabla de TAUPOLIP_ANTIGUOS:
Operaciones aplicadas:
UPDATE dw_autos.dbo.PRESUPUESTOS SET APOLCLAV=10000000+APOLCLAV, F_CARGA=GETDATE() WHERE APOLCLAVBETWEEN 9500187 AND 9999999
UPDATE dw_autos.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS SET AINSPOLI=10000000+APOLCLAV, F_CARGA=GETDATE() WHERE AINSPOLI BETWEEN 9500187 AND 9999999
	
	
Descripción de Situación del presupuesto:	
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

	--declare @UltimaFcargaX  smalldatetime = '20150414 00:00:00'
	
	set nocount on

	declare @Msg varchar(1000)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
	declare @Nregistros int                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
	
	exec comun..eliminatabla 'tmp.xautos_dbo.xpresupuestos_incremental_0'	 

		-- Grabamos primero todos los presupuestos que cumplen las condiciones que "mandan" sobre la consulta general.
			SELECT  
				alogrpol as Presupuesto,
				alogfemi,
				alognift,
				f_carga
			INTO tmp.xautos_dbo.xpresupuestos_incremental_0
			FROM
				dw_autos..operativa WITH(NOLOCK)
			WHERE 
				(
					(alogtipo='I' and alogactu='F')  --presupuestos de PN 
					or 
					(alogtipo='I' and alogactu='R' and exists (select 1 from dw_autos..presupuestos_y_tasaciones_polizas where ainsswob<>'T' and ainspoli=alogrpol)) --tasaciones que han pasado a presupuestos
				)	
				and Alogfemi >= '20070101'		
				and alogrpol>9000000

			
	
	exec comun..eliminatabla 'tmp.xautos_dbo.xpresupuestos_incremental_1'	 

		-- Grabamos todas los presupuestos que han cambiado en la tabla temporal
			SELECT  
				Presupuesto
			INTO tmp.xautos_dbo.xpresupuestos_incremental_1
			FROM tmp.xautos_dbo.xpresupuestos_incremental_0 WITH(NOLOCK)
			WHERE	
				F_carga>@UltimaFcargaX	 
			UNION ALL
			SELECT p.APOLCLAV as Presupuesto
			FROM
				tmp.xautos_dbo.xpresupuestos_incremental_0 ope WITH(NOLOCK) INNER JOIN dw_autos..presupuestos p WITH(NOLOCK) ON		
					ope.presupuesto=p.APOLCLAV 
			WHERE
					p.F_carga>@UltimaFcargaX	 
			UNION ALL
			SELECT p.APOLCLAV as Presupuesto
			FROM
				tmp.xautos_dbo.xpresupuestos_incremental_0 ope WITH(NOLOCK) INNER JOIN dw_autos..presupuestos p WITH(NOLOCK) ON		
					ope.presupuesto=p.APOLCLAV 
				INNER JOIN xautos..marcas m WITH(NOLOCK) ON
					p.APOLNMAR = M.marca        AND
					p.APOLNMOD = M.modelo       AND
					p.APOLNSUB = M.submodelo    AND
					p.APOLNTERM = M.terminacion AND
					p.APOLNANU = M.año  
			WHERE
				m.f_carga >@UltimaFcargaX	 
			UNION ALL
			SELECT p.ainspoli as Presupuesto
			FROM
				tmp.xautos_dbo.xpresupuestos_incremental_0 ope WITH(NOLOCK) INNER JOIN DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS p WITH(NOLOCK) ON		
					ope.presupuesto=p.Ainspoli 
				LEFT JOIN DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS p2 WITH(NOLOCK) ON							
					ope.presupuesto=p2.Ainspoli AND
					p2.ainsfcon > ope.alogfemi
			WHERE
					p2.Ainspoli IS NULL AND
					p.F_carga>@UltimaFcargaX					
			UNION ALL
			SELECT ope.presupuesto as Presupuesto
			FROM
				tmp.xautos_dbo.xpresupuestos_incremental_0 ope WITH(NOLOCK) INNER JOIN DW_AUTOS.dbo.TAUPOLIP TAU WITH(NOLOCK) ON 
					ope.presupuesto=TAU.AUPOPCLAV 
			WHERE
					TAU.F_carga>@UltimaFcargaX					
			/*
			UNION ALL
			SELECT ope.presupuesto as Presupuesto
			FROM
				tmp.xautos_dbo.xpresupuestos_incremental_0 ope WITH(NOLOCK) INNER JOIN XAUTOS.dbo.XTOMADOR T WITH(NOLOCK) ON 
					ope.ALOGNIFT=T.NIF
			WHERE
					T.F_carga>@UltimaFcargaX					
			*/
			/*UNION ALL
			SELECT ope.presupuesto as Presupuesto
			FROM
				tmp.xautos_dbo.xpresupuestos_incremental_0 ope WITH(NOLOCK) INNER JOIN dw_autos..presupuestos p WITH(NOLOCK) ON		
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
				tmp.xautos_dbo.xpresupuestos_incremental_0 ope WITH(NOLOCK) INNER JOIN dw_autos..presupuestos p WITH(NOLOCK) ON		
					ope.presupuesto=p.APOLCLAV 
				INNER JOIN DW_AUTOS..TUCCOLEC T WITH(NOLOCK) ON 
					p.APOLIDCO = T.UCCOIDCO
			WHERE
					T.F_carga>@UltimaFcargaX
			UNION ALL					
			select 
				LIP.AUPOPCLAV
			from
				DW_AUTOS.dbo.TAUPOLIP		LIP with(nolock)
			inner join 
				tmp.xautos_dbo.xpresupuestos_incremental_0 ope with(nolock)
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
		--		and	LIP.AUPOPCLAV > 9000000
															
			--option(recompile)
			
														
			
			
	-- GPM 20150330 Nos quedamos con los distintos
	exec comun..eliminatabla 'tmp.xautos_dbo.xpresupuestos_incremental'
	SELECT  DISTINCT Presupuesto
	INTO tmp.xautos_dbo.xpresupuestos_incremental
	FROM tmp.xautos_dbo.xpresupuestos_incremental_1 WITH(NOLOCK)		
			
	exec comun..eliminatabla 'tmp.xautos_dbo.XPresupuestos_1'
	select  
		ope.alogrpol, ope.alogfemi, ope.aloghora, ope.alogtipo,ope.alogactu, ope.alogfemi2,
		ope.alogcics, ope.alogdele, ope.alognift, ope.alogemai, ope.alogoper
	into tmp.xautos_dbo.XPresupuestos_1
	from
		dw_autos..operativa ope,
		tmp.xautos_dbo.xpresupuestos_incremental PINC with(nolock)
	where 
		alogrpol = PINC.Presupuesto and
		(
			(alogtipo='I' and alogactu='F')  --presupuestos de PN 
			or 
			(alogtipo='I' and alogactu='R' and exists (select 1 from dw_autos..presupuestos_y_tasaciones_polizas with(nolock) where ainsswob<>'T' and ainspoli=alogrpol)) --tasaciones que han pasado a presupuestos
		)	
		and Alogfemi >= '20070101'		
		and alogrpol>9000000



	exec comun..eliminatabla 'tmp.xautos_dbo.xpresupuestos'
	/* Si los datos de un presupuesto aparecen duplicados, nos quedamos con la primera información que entró.*/
	select		  s.IdPresupuesto
				, s.SituacionPresupuesto
				, s.FecEmision
				, s.FechaInicio
				, s.ConCompromiso
				, s.CanalEntrada
				, s.Delegacion 
				, s.NifTomador
				, s.Nombre 
				, s.Apellidos 
				, s.Telefono 
				, s.Email 
				, s.Fax 
				, s.Domicilio 
				, s.TipoPersona 
				, s.Fcarnet
				, s.CodPostal
				, s.Matricula 
				, s.idmodelo 
				, s.TipoVehiculo 
				, s.RelacionPresentador
				, s.producto 
				, s.ocupantes 
				, s.ValorVehiculo
				, s.ValorAccesorios
				, s.AñoConstruccion
				, s.FConstruccion 
				, s.SexoTomador
				, s.FnacConductor
				, s.FnacTomador 
				, s.Operador 
				, s.Colectivo 
				, s.Flota
				, s.Descuentos
				, s.Importe
				, s.Banco
				, s.Procedencia
				, s.IdEmpresa
				, s.SexoConductor
				, s.GarantiaMecanica
				, s.F_carga
				, s.IdNegocio
				, s.SujetoANormativa
				, s.Lunas
				, s.ProProducto
				, s.LunasFP
				, s.PresenciaAsnef
				, s.RiskScore
				, s.SeverityScore
				, s.GarantiaMecanicaFP
				, s.IdOficina
				, s.idSolicitud
				, s.id15PuntosCarnet
				, s.IdFrecuenciaPago
				, s.IdOcupantes
				, s.IdUsoVehiculo
				, s.IdVehiculoNuevo 
				, s.Orden
				--,cast(case when s.TipoPersona='J' then 0 else s.sexotomador2 end as tinyint) as SexoTomador  
				--,cast(NULL as int) as IdOficina
				, s.CompañiaProcedencia
				, s.NAñosCompProcedencia
				, s.NSiniCompProcedencia
				, s.OrigenCompProc
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
		tmp.xautos_dbo.xpresupuestos
	FROM (
		SELECT 
			 tmp.*
			, ROW_NUMBER() OVER (PARTITION BY IdPresupuesto ORDER BY FecEmision) AS Orden
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
			, isnull(solic.AUSOLIC_ID_NEGO_FIN,'ZZZZZZZX') as Cod_Agreg_Cruce
		from
			(
			select 
				case 
					when alogrpol<9000000 then cast(right('00000000'+cast(alogrpol as varchar(8)),7)+right(convert(varchar(8),Alogfemi,112),4)+cast(aloghora as varchar(6)) as int)
					else cast(alogrpol as int)
				end as IdPresupuesto,
				ainssitu as SituacionPresupuesto,
				cast(case 
					when (alogtipo='I' and alogactu='F') then Alogfemi2 
					else isnull((select min(o2.alogfemi2) from dw_autos..operativa o2 where o.alogrpol=o2.alogrpol and o2.alogtipo='F' and o2.alogactu='R'),dateadd(ss,1,Alogfemi2))
				end as datetime) as FecEmision,
				pt1.AinsFins as FechaInicio,
				cast(case when PT1.Ainsswob='C' then 1 else 0 end as bit) as ConCompromiso,
				-- Canal de Entrada Mobile, son los presupuestos del agregador AGRE0021
				case when TAM.AMRGCNT_CODAGR is null then AlogCics else 'L' end as CanalEntrada,
				AlogDele as Delegacion,
				alogNift as NifTomador,
				nullif(rtrim(Apolnomb),'') as Nombre,
				nullif(rtrim(apolapel),'') as Apellidos,
				--Cambiar por:
				--Apoltoma as Nombre
				--NOTA: en XPRESUPUESTOS tenemos que dejar solo un campo con la concatenación de ambos
				apoltfnm as Telefono,
				alogemai as Email,
				pt1.ainsnfax	 as Fax,
				apoldomi as Domicilio,
				--isnull(p.TipoPersona,comun.dbo.fn_TipoPersona(alognift)) as TipoPersona,
				F.Tipopersona as  TipoPersona,
				cast(ApolFcco as date) as Fcarnet, 
				ApolCpos as CodPostal,
				ApolMatr as Matricula,
				m.id as idmodelo, 
				m.TipoVeh AS TipoVehiculo,
				apolRela as RelacionPresentador,
				P.producto as producto,
				cast(case when ApolSpoc='V' then 1 else 0 end as bit) as ocupantes, 
				case 
						when ApolValo = 0 then isnull(nullif(M.valor,10000000),0)
						else ApolValo 
					   end  as ValorVehiculo,
				ApolVacc as ValorAccesorios,
				ApolAcon as AñoConstruccion,
				cast(case 
						--GPM 28/10/2015 Se comenta esta parte, actualmente no encontramos presupuesto en Xvehiculo
						--when v.FechaConstruccion is not null then v.FechaConstruccion
						when ApolAcon>year(getdate())+1 or apolacon<1900 then Null
						else cast(ApolAcon as char(4)) + '0101'
				end as date) as FConstruccion
				--,apolsexo as SexoTomador2
				--,cast(case when isnull(p.TipoPersona,comun.dbo.fn_TipoPersona(alognift))='J' then 0 else apolsexo end as tinyint) as SexoTomador 
				,cast(case when F.TipoPersona ='J' then 0 else apolsexo end as tinyint) as SexoTomador 			
				,cast(case 
					when apolCond=0 and ApolFnat is not null then  apolfnat
					else apolfnac
	  			   end as date) as FnacConductor
				,cast(apolfnat as date) as FnacTomador
				,AlogOper as Operador
				,case 
						when TUC.UCCOTIPC not in ('FL','AG','MK','IN') then TUC.uccoidco
						else '0'
				end as Colectivo
				,case 
						when TUC.UCCOTIPC = 'FL' then TUC.uccoidco
						else '0'
				end as Flota
				,CASE 
					WHEN APOLRELD = 'Z' THEN '0'
					ELSE APOLRELD 
				END as Descuentos						-- Necesario en Cubo Ratios
				,AINSIMRE as Importe
				,APOLCOBA as Banco
				, CASE 
					when alogrpol<9000000 then 'N' -- Presupuestos nuevos
					else 'S' -- Presupuestos de Suplemento
				   END AS Procedencia
			
				,CAST(CASE 
				 WHEN APOLNEMP=3 THEN 3 
				 ELSE 1  
				 END AS smallint) AS IdEmpresa 
				   			
				,CAST(CASE 
					WHEN TAU.AUPOPSEXC IN ('1','2') THEN TAU.AUPOPSEXC
					ELSE '0'
				  END AS CHAR(1)) AS SexoConductor
				, ISNULL(TAU.AUPOPGARM,'') AS GarantiaMecanica
				, getdate() as F_carga
				, ISNULL(TUC.uccoidco, '0') as IdNegocio
				, ISNULL(TAU.AUPOPSNOR,'') AS SujetoANormativa
				, isnull(substring(isnull(PC2.aprogara,PC1.aprogara),4,1),'N') as Lunas
				, isnull(PC2.aproprod,isnull(PC1.aproprod,'ZZ')) as ProProducto
				, case when substring(isnull(PC1.aprogara,isnull(PC2.aprogara,'N')),4,1) in ('N','') then 'C'
					   when ISNULL(LTRIM(RTRIM(TAU.AUPOPLGRA)),'') = '' then 'N'
					   else LTRIM(RTRIM(TAU.AUPOPLGRA))  
				  end  LunasFP
				, CAST(ISNULL(TAU.AUPOPPASNF, 'Y') AS CHAR(1)) AS PresenciaAsnef
				, CAST(ISNULL(TAU.AUPOPRSCOR,'Y') AS CHAR(1)) AS RiskScore
				, CAST(ISNULL(TAU.AUPOPSSCOR,'Y')  AS CHAR(1)) AS SeverityScore
				, case when TAU.AUPOPGARM in ('GM1','GM9') then '3'
					   when TAU.AUPOPGARM = 'GM0' and cast(alogrpol as int) between 9000000 and 9999999 then '2' -- Todos los presupuestos son de Captación
					   else '0'
				  end  GarantiaMecanicaFP
				, isnull(p.aupopconc,0)				as 'IdOficina'
				, isnull(TAU.AUPOPIDSOLIC, 0)		as 'idSolicitud'
				, isnull(COP.AUDACOP_NUM_PUNTOS, 0)	as 'id15PuntosCarnet'
				--, CONVERT ( VARCHAR(1) , NULL )		as 'IdFrecuenciaPago'
				, p.AUPOPFPGA							as 'IdFrecuenciaPago'
				, p.APOLCOMB						AS 'IdOcupantes'
				, LTRIM(RTRIM(TAU.AUPOPUVH1))		AS 'IdUsoVehiculo'
				, TAU.AUPOPCONU						AS 'IdVehiculoNuevo'
				--Campos de certificados de siniestralidad
				, COP.AUDACOP_EMPRES_EST
				, COP.AUDACOP_NUMANO_EST
				, COP.AUDACOP_NUMSIN_EST
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
				tmp.xautos_dbo.XPresupuestos_1	o with(nolock)
			left outer join 
	 			dw_autos..presupuestos			p WITH(NOLOCK)
			on
				alogrpol=p.apolclav
			left outer join 
				xautos..marcas					m WITH(NOLOCK)
			on
				p.APOLNMAR = M.marca        AND
				p.APOLNMOD = M.modelo       AND
				p.APOLNSUB = M.submodelo    AND
				p.APOLNTERM = M.terminacion AND
				p.APOLNANU = M.año  
			left outer join
	 			 DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS pt1  WITH(NOLOCK)
			on
				alogrpol = pt1.AINSPOLI		
				and not exists (select * from DW_AUTOS.dbo.PRESUPUESTOS_Y_TASACIONES_POLIZAS pt2  WITH(NOLOCK) where alogrpol = pt2.AINSPOLI and pt2.ainsfcon>alogfemi)
			left join 
				DW_AUTOS.dbo.TAUPOLIP		TAU WITH(NOLOCK)
			ON 
				alogrpol = TAU.AUPOPCLAV 
			
			left join 						
				DW_AUTOS.dbo.TAUDACOP		COP with(nolock)
				on
					COP.AUDACOP_ID_RAMO	= TAU.AUPOPPEREFRAMO
				and	COP.AUDACOP_ID_EMPRESA = TAU.AUPOPPEREFEMPP
				and	COP.AUDACOP_ID_SOLICIT = TAU.AUPOPIDSOLIC
				and	COP.AUDACOP_ID_RIESGO = 1
			/*			
			left outer join 
				XAUTOS.dbo.XTOMADOR			T WITH(NOLOCK)
			on 
				alogNift = T.NIF
			*/
			/*left outer join
				xautos.dbo.xvehiculo v WITH(NOLOCK)
			on 
				p.apolmatr=v.matricula
				And
				p.apolclav=v.apolclav
			*/
			left join --para asegurar la integridad con colectivos
				dw_autos..tuccolec TUC WITH(NOLOCK)
			on
				APOLIDCO = TUC.uccoidco 
			left join DW_AUTOS..TAPRODUC PC2 on PC2.APROPROD = CAST(P.APOLTSEG AS VARCHAR) + P.APOLSUBP 
			left join DW_AUTOS..TAPRODUC PC1 on PC1.APROPROD = CAST(P.APOLTSEG AS VARCHAR)
			left join dw_autos.dbo.tamrgcnt tam ON AMRGCNT_CODAGR = 'AGRE0021' AND AMRGCNT_CODIGO = cast(alogrpol as int) 
			cross apply comun.dbo.fn_TipoPersona_tbl (isnull(apolnift,alognift)) F			
		)tmp 
		left join XDIM.autos.CS_CertificadoSiniestralidad CS on tmp.IdPresupuesto = CS.AUCDOPOLI
		left JOIN DW_AUTOS..TAUSOLIC solic (nolock)
		on  tmp.idsolicitud=solic.AUSOLIC_ID_SOLICIT	
		and tmp.IdEmpresa =solic.AUSOLIC_ID_EMPRESA		
		and solic.AUSOLIC_ID_RAMO =1	
	) s
	WHERE s.Orden = 1 
	option (recompile)

	set @Nregistros=@@rowcount	
		
	set @Msg='Tabla temporal tmp_xpresupuestos,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XPresupuestos',@Msg,'C','M',2


	create index ix0 on tmp.xautos_dbo.xpresupuestos (idpresupuesto,FecEmision)
	
	set @Nregistros=@Nregistros-@@rowcount


	-- Los nuevos registros ya llevan los campos de certificado de siniestralidad actualizado.
	-- Actualizamos también los registros que no son nuevos pero cuyo certificado ha podido cambiar.
	update pr
	set CompañiaProcedencia = CS.AUCDOCCOM, 
		NAñosCompProcedencia = CS.NAñosProc,
		NSiniCompProcedencia = CS.NSiniProc,
		OrigenCompProc = 'T',
		f_carga = getdate()
	FROM xautos..xpresupuestos pr
	join XDIM.autos.CS_CertificadoSiniestralidad CS 
	on pr.IdPresupuesto = CS.AUCDOPOLI
	where CS.f_carga > @UltimaFcargaX
	-- tiempo ejecución = 7 seg. 

	set @Msg='Cert. de Siniestralidad actualizados para registros antiguos: '+cast(@@rowcount as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XPresupuestos',@Msg,'C','M',2

	
	create unique index ix1 on tmp.xautos_dbo.xpresupuestos(idpresupuesto)
	

	return(@Nregistros)
	



