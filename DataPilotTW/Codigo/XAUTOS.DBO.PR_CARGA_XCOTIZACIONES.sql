
--select distinct f_carga from xautos..xcotizaciones (nolock)where f_carga > '20161022'
 
 -- exec XAUTOS.[dbo].[pr_Carga_XCotizaciones] '20161030 02:50:00'

CREATE procedure [dbo].[pr_Carga_XCotizaciones] @UltimaFcargaX datetime
as

/*----------------------------------------------------------------------------
Devuelve datos de las cotizaciones:
		- Nuevas cotizaciones
		- Cotizaciones que han pasado a presupuesto
		- Cotizaciones que han pasado directamente a póliza 
		- Cotizaciones que han pasado primero a presupuesto y luego a póliza
		- Para varias cotizaciones con el mismo código, se toman TODAS las cotizaciones
		- Cotizaciones WEB (Simulaciones)
Se utiliza para la carga de XCotizaciones        

------------------------------------------------------------------------------
CREADO POR/FECHA: Amalia del Río 21-11-2007
------------------------------------------------------------------------------
MODIFICADO POR/FECHA:   
		Amalia del Río 18/12/2007
			Se toman TODAS las cotizaciones (se incluyen las de Presupuesto a Póliza)
		Jesus Gomez 18/08/2008 Rehecho
		Mario Sánchez 27/08/2008 Comentamos el WHERE(Linea 69) para obtener así TODAS las cotizaciones(Incluyendo así las de tipo='P', que serán filtradas en XCONVERSIONES)
		Mario Sanchez 24/08/2008 Se introduce la columna HoraCotizacion que es la hora de la fecha de emision
		Mario Sánchez 16/06/2009 Añadimos las cotizaciones WEB (Simulaciones)
		Mario Sanchez 3/11/2009 Añadido campo Agregador
		Mario Sanchez 4/11/2009 Los campos FRT y FechaFabricación envian a Nulo los valores Menores de 1901 y 100901 respectivamente.
		Mario Sanchez 5/11/2009 Añadido campo Idmodelo para las parte de Cotizaciones WEB.
		GPérez 28/04/2010 Incluimos el campo IdEmpresa aunque aún con valor fijo.
		Gemma Pérez 06/05/2010 El campo IdEmpresa se carga de la siguiente forma:
		                          a. En el caso de cotizaciones no web de 
							      la tabla PRESUPUESTOS_Y_COTIZACIONES_POLIZAS.
							      b. En el caso de cotizaciones web el valor de la empresa
							      será siempre Mutua Madrileña.
		Gemma Pérez 29/07/2010 En la tabla Autosregsim de origen se ha comenzado
							   a grabar el código 'W' con significado 'Sin agregador' =>
	                           unificamos ese valor con el valor "0-Sin agregador" ya existente.       
	    Gemma Pérez 10/06/2010 En la tabla Autosregsim de origen se ha comenzado
							   a grabar el código 'I001' con significado 'Sin agregador' =>
	                           unificamos ese valor con el valor "0-Sin agregador" ya existente.       
	          
	          Valores de agregador posibles en Web:
	          
						Arpem-->A001
						coches.com-->A002
						seguros.com-->003
						Autodescuento-->A004
						Portalmotos.com-->A005
						Outservico--> C001
						RSM-->M001
						Usuario web-->W  (Sin agregador)
						Usuario web de Autoclub-->I001 (Sin agregador)
						
	 Gemma Pérez  15/10/2010  
				 En un futuro próximo se realizará un cambio en la codificación 
				 del campo Agregador. Este es el cambio
				 
				 Dato antiguo	Dato nuevo	Descripción
					A001	    AGRE0001     	Arpem
					A002		AGRE0002       	coches.com
					A003		AGRE0003       	seguros.es
					C001		AGRE0004       	Outservico
					A004		AGRE0005       	Autodescuento
					W			AGRE0006       	Usuario web
					M001		AGRE0007       	RSM
					I001		AGRE0008       	ACM
					A005		AGRE0009       	Portalmotos.com
					(Cadena 
					vacía)		AGRE0010       	Pruebas
					A006		AGRE0011       	SegurosBroker
					A007		AGRE0012       	Milenari
					A008		AGRE0013       	Qustodian
		16-12-2010:				
								AGRE0014        Campaña Mailing 07-12-2010 Sergio Crespo. Lo consideramos "Sin Agregador".
								AGRE0015        Agregador para Demo (Francisco Martínez Nájera). Parece que luego
									            se pretende borrar en HOST.Lo consideramos "Sin Agregador".
	 						
	             En este procedimiento se cambian las transformaciones para obtener el agregador.              

	Gemma Pérez 12-11-2010 Se introduce un parche en la grabación del agregador, ya que 
						   en origen el agregador AGRE0013 sigue teniendo su valor 
						   antigüo, A008.En cuanto nos avisen que está corregido, se 
						   debe eliminar el parche.
	Gemma Pérez 17-11-2010 Se elimina el parche del 12-11-2010 en la grabacion del agregador A008.
	Gemma Pérez 16-12-2010 Aparecen nuevos agregadores que no son tales y debemos
						   enviarlos a "Sin agregador":
							AGRE0014   Campaña Mailing 07-12-2010 Sergio Crespo.
							AGRE0015   Agregador para Demo (Francisco Martínez Nájera). Parece que luego
									   se pretende borrar.
	Gemma Pérez  03-01-2011 Eludidos los nifs nulos por error en TAULOIPR (AULOINIFT IS NOT NULL)
							Cambio provisional.
	Gemma Pérez  04-01-2011 Los nif nulos para "cotizaciones no web" se tratan. Existen 6 casos en la actualidad.
							Se elimina el filtro del 03-01-2011 para cotizaciones con Nif nulo.
							
	Gemma Pérez  07-04-2011 Los agregadores AGRE0014 y AGRE0015 pasan del valor "Sin definir" a
							mostrarse en el cubo de ratios...(Petición de Sergio Crespo)
	
							AGRE0014	AGRE0014-11811                                    
							AGRE0015	AGRE0015-EL CONFIDENCIAL                          

	Gemma Pérez  08-07-2011 Sólo se consideran los agregadores de tipo Agregador (AG) en la tabla 
						    de Colectivos.
	Gemma Pérez  12-07-2011 Se vuelven a incluir los colectivos de tipo Marketing Online (MK) como
						    agregadores.
	Gemma Pérez  28-09-2011 Se cargan todos los agregadores, independientemente del tipo (colectivos incluidos)
	GPérez       07/10/2011 Incluido campo Negocio en Tabla.
	Gemma Pérez  14/10/2011 Incluido campo Garantía Mecánica.
	GPérez       10/11/2011 Considerado nuevo tipo de descuento Z (Sin descuento APOLRELD) en la consulta.
	Gemma Pérez  03/01/2012 Eliminadas cotizaciones de suplementos.
	Gemma Pérez  14/08/2012 Cambiado Tratamiento del campo IdEmpresa para cotizaciones web y no web 
						    (detectada información con empresa diferente a 1 y 3 en TAULOIPR y TAMRGSIM).
							Cotizaciones web. Cambiado cálculo de campos tras ampliación de la tabla TAMRGSIM.
								Cálculos de campos cambiados:
									Fecha de nacimiento tomador  AMRGSIM_FNAT			
									Fecha de nacimiento Conductor
								    Sexo Tomador				AMRGSIM_SEXT
									Fecha de carnet de conducir AMRGSIM_FCCO
									Relación de descuentos		AMRGSIM_RELD				
									Fecha de construcción	    AMRGSIM_ACON
									Valor vehículo              AMRGSIM_VALO
									Valor accesorios            AMRGSIM_VACC
									Relación presentador        AMRGSIM_RELA
									Importe						AMRGSIM_IMRE
									Empresa						AMRGSIM_EMPR
									Garantía Mecánica			AMRGSIM_GARM	
							Backup antes del cambio: TMP.XAUTOS_DBO.BACKUP_XCOTIZACIONES_20120814			
							
	Gemma Pérez  13/09/2012 Eliminadas cotizaciones hacia atrás en que AMRGSIM_UUMO <> 'WEB'.
						   (Indicado por Guillermo Bazán). No son cotizaciones web realmente, se graban en CICS.
						   (Backup de tabla: TMP.XAUTOS_DBO.BACKUP_XCOTIZACIONES_20120913).
    Luis Arroyo 11/11/2012 Introducidos campos de Forma de Pago Garantía Mecásnica y Asnef.
    Luis Arroyo 05/03/2013 Canal de Entrada Mobile codificado como B, si el agregador es AGRE0021 
    Gemma Pérez 09/07/2013 Logado de consultas para optimización posterior.
    Jgomez 22/07/2013 Eliminados datos de asnef, al confirmar host que no son válidos y cambiado el union por union all
 	Gemma Pérez 23/04/2014  Incluido campo IdOficina (Punto de red)
 	Gemma Pérez 18/06/2014  Cambiado cálculo de FRT para TAMRGSIM: Null para valores de fecha > '20501230'. 
 							Incidencia detectada en carga de ese dato dos veces. 
 							Ya comunicado a Fran Nájera.
 	Eduardo					Se incluye el campo MotivoError cuyo origen es AMRGSIM_CODERR
 	Cuadrado 24/06/2014
 	
 	Angel Cañas 18/07/2014	Se modifica el producto '1XF8' por '9XXX' debido a que el producto es erroneo
 							(idCotizacion = 20140717203009512829 )
 	Gemam Pérez 09/10/2014	Se modifica la carga del campo Motivo Error: Se almacenan sólo los casos de error
 							(si hay prima no es error), se carga el nuevo campo AvisoError.
 	Óscar Sánchez 24/02/2015	Se pone en funcionamiento la función tipo tabla del cálculo de tipo de persona. (D-113149)
 	
 	Angel Cañas	26/02/2015	Se ponen a null fechas de carnet erroneas (11 registros)
 	
 	Angel Cañas 08/04/2015	Añadidos campos IdSolicitud e id15PuntosCarnet
 							(primera compilación a null)
 							
	Angel Cañas 17/04/2015	Informados campos idSolicitud, id15PuntosCarnet e idOficina

	Sergio Alvaro Panizo 24/04/2015	Se incluyen 4 campos nuevos
 	
	Sergio Alvaro Panizo 18/05/2015	Se incluyen IdSesion

 	Gemma Pérez 19/05/2015  Se corrige incidencia en el cálculo de Cotizaciones generada en el desarrollo de 17/04:
							No se estaban incluyendo todas las cotizaciones web en XCotizaciones.
	
	Raquel Humanes 29/07/2015 En las cotizaciones web si están informados los campos de ASNEF (AMRGSIM_PASNF,AMRGSIM_RSCOR y AMRGSIM_SSCOR)
							se cambia para que tome los valores de esos campos en lugar de poner el desconocido. Además se pone un parche
							en el severity score porque viene el valor N que no es correcto.
 	
	Gemma Pérez   31/07/2015  Modificada la carga de las tablas iniciales ya que aparecen registros duplicados 
							  en el cruce entre TAMRGSIM y TAULOIPR
	
	Raquel Humanes 10/08/2015 Se modifica la forma de obtener el Asnef de las cotizaciones no web (antes no informadas) y se informan
							  los campos FechaEfecto y SexoConductor
	Luis Arroyo    24/08/2015 Fecha de Construcción mayores de la fecha actual se ponen a null. Sólo ocurre en cotizaciones web.  
	Gemma Pérez    07/10/2015 Tratamiento de ocupantes = -1 (AMRGSIM_COMB). Hablado con HOST y se trata de un error.
	Raquel Humanes 08/10/2015 Se añade el campo TipoVehiculo
	Adela Gutiérrez 19/10/2015 En lugar de usar el campo Producto calculado en TAULOIPR se hace el cálculo aquí
	Gemma Pérez     22/10/2015 Se cruza la información para la extracción de la tabla TMP.XAUTOS_DBO.COTIZACIONES_TMP
							   a través de los campos del nuevo índice AULOIIDSOLIC y AULOIEMPR.
	Gemma Pérez     28/10/2015 Logamos después de insertar en cada tabla para revisar los tiempos.
	Raquel Humanes  07/04/2016 Cambiamos en los campos Coderrorcotiz y codavisocotiz para que obtenga el error que viene en tamrgsim 
	Raquel Humanes  07/07/2016 Cambiamos el cruce en tauloipr y tamrgsim para los campos AULOISUBP, AULOIFTIP y AULOIPVIP ya que se estaban 
							perdiendo datos de solicitud.
	Alvaro Roldán	21/09/2016 Introducimos los campos referentes a la compañía de procedencia: CompañiaProcedencia, NAñosCompProcedencia ,NSiniCompProcedencia
							,OrigenCompProc y FecEmisionCodigo
	Alvaro Roldán	21/09/2016 Introducimos el campo FecEmisionCodigo, con la fecha de emisión de la simulación (AMRGSIM_CODIGO) sin arrastre, lo que actualmente
							está ocurriendo en AMRGSIM_FECSIMUL.
    Gemma Pérez     10/10/2016  Adaptación I - Ampliación campo marca en AMMO (NEGE16RFFV1USD). Cambio en el cálculo de IdModelo.
	                            Adaptación checksum
	Gemma Pérez     31/10/2016  Ampliación Marca en AMMO. Cálculo del campo IdModelo a través de los 5 campos. Eliminación de checksum.
                                                          En el caso de TAMRGSIM los 5 campos se obtienen de la fragmentación del campo COCLAVE ya
														  que antes se extraía de este campo (coclave)
														  No se trabaja con los 5 campos de TAMRGSIM porque se ha detectado que no son
														  coherentes con el campo COCLAVE y existen valores excluyentes entre 5 campos y COCLAVE.													                               
														  (Informado el grupo Operacional (Vanesa Rodriguez))
	Alvaro Roldán	04/11/2016  Añadimos el campo Telefono (AMRGSIM_TLFN para Web y AUDACOT_TLFN_1 o AUDACOT_TLFN_2 para No Web)
	Gemma Pérez     06/02/2017  Ampliación Marca en AMMO. Se modifica el cálculo del modelo (18 caracteres)
	Raquel Humanes  28/02/2017  Añadimos Cod_Agreg_Cruce
	Alvaro Sambad   02/03/2017  Descomentamos la carga de YYY para ASNEF de las No Web, salen ahora de TAUDACOT
    Gemma Pérez     06/03/2017	Se modifica el cálculo de la Fecha de Construcción debido a incidencia (YEAR)
    Alberto Romero 12/07/2017	  (Operador) ARQ Se cambia el origen a partir de AMRGSIM_FECSIMUL >= 20170621 y siempre que el usuario empiece por CT
------------------------------------------------------------------------------
ENTRADAS:
------------------------------------------------------------------------------
SALIDAS:
------------------------------------------------------------------------------
OBSERVACIONES:	
		- Para la carga total de la tabla:
			use comun
			TRUNCATE TABLE XAUTOS.dbo.XCotizaciones
			EXEC COMUN..GESTORCARGAX 'XAUTOS..XCotizaciones',0,1
			
			SELECT * FROM XAUTOS.DBO.XCotizaciones
----------------------------------------------------------------------------*/


	-- declare @UltimaFcargaX datetime='19010101' 


	declare @Msg varchar(1000)
	declare @Nregistros int              		

 /* 
  -- Cogemos un sólo movimiento de TAMRGSIM para cada cotizacion, esto es para sacar los campos de ASNEF
  set @Msg='Iniciado el procedimiento de carga.'
  exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

  exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.XCotizaciones0'
  select 
	*
  into 
		tmp.xautos_dbo.xcotizaciones0
  from 
    (
	select  
		AMRGSIM_COCOTIZ
	    ,ISNULL(AMRGSIM_PASNF,'Y') AMRGSIM_PASNF
		,ISNULL(AMRGSIM_RSCOR,'Y') AMRGSIM_RSCOR
		,ISNULL(AMRGSIM_SSCOR,'Y') AMRGSIM_SSCOR
		,AMRGSIM_FECSIMUL
		, ROW_NUMBER() OVER (PARTITION BY AULOICCOT ORDER BY [AMRGSIM_FECSIMUL] DESC) N
	FROM 
		DW_AUTOS.dbo.TAULOIPR C1 WITH(NOLOCK) 
	LEFT join 
		DW_AUTOS..TAMRGSIM TAM WITH(NOLOCK) 
	on	
		c1.AULOICCOT = TAM.AMRGSIM_COCOTIZ
	WHERE 
		[AMRGSIM_FECSIMUL]>='20121001' 
		AND ISNULL(AMRGSIM_CANA,'W') != 'W' 
		AND	ISNULL(AMRGSIM_UUMO,'WEB') != 'WEB' 
		And c1.f_carga>@UltimaFcargaX
	) t
  where
	 n = 1

  set @Nregistros=@@rowcount
  
  set @Msg='Tabla temporal tmp.xautos_dbo.XCotizaciones0,generada: '+cast(@Nregistros as varchar(9))+' registros'
  exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

 */ 
 
	-- Obtenemos los idSolicitud en que ha cambiado o bien la tabla TAUDACOP  ó TAULOIPR

	--declare @UltimaFcargaX datetime = '20150417 00:00:00' 

	set @Msg='Inicio de carga XCotizaciones'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

	EXEC comun..ELIMINATABLA 'TMP.XAUTOS_DBO.COTIZACIONES_TMP'
	SELECT 
					AULO.IDCOTIZACION,
					AULO.AULOICCOT,
					--AULO.Producto,
					(select  producto from DW_AUTOS..fn_autos_productos (AULOIEMPR, AULOITSEG, LEFT(AULOIPVIP,1), AULOISUBP, AULOIFTIP, AULOIPTOT, AULOIRCCA, AULOIASIS, AULOIDEFE, AULOILURI, AULOITIPV, AULOIFEMI,AUSOPRO_ID_PROD_BA,AUSOPRO_ID_PROD_PE)) as Producto,
					AULO.AULOICPOS,
					AULO.AULOICOLE,
					AULO.AULOIIDSOLIC,
					AULO.FEC_GENERACION
	INTO TMP.XAUTOS_DBO.COTIZACIONES_TMP
	FROM
		DW_AUTOS.dbo.TAULOIPR AULO with(nolock) 
		inner join	DW_AUTOS.dbo.TAUDACOP COP with(nolock) on
				COP.AUDACOP_ID_RAMO	= 1
				and	COP.AUDACOP_ID_SOLICIT = AULO.AULOIIDSOLIC
				and	COP.AUDACOP_ID_EMPRESA = AULO.AULOIEMPR
				and	COP.AUDACOP_ID_RIESGO = 1
		OUTER APPLY 
		(
			SELECT TOP 1 AUSOPRO_ID_PROD_BA
					,AUSOPRO_ID_PROD_PE
			FROM DW_AUTOS.DBO.TAUSOPRO TAU WITH (NOLOCK)
			WHERE AULO.AULOIIDSOLIC  = TAU.AUSOPRO_ID_SOLICIT
				AND AULO.AULOIEMPR   = TAU.AUSOPRO_ID_EMPRESA
				AND TAU.AUSOPRO_ID_RAMO = 1
		) OA
	
	WHERE			
			COP.F_CARGA > @UltimaFCargaX
	UNION
	SELECT 
					AULO.IDCOTIZACION,
					AULO.AULOICCOT,
					--AULO.Producto,
					(select  producto from DW_AUTOS..fn_autos_productos (AULOIEMPR, AULOITSEG, LEFT(AULOIPVIP,1), AULOISUBP, AULOIFTIP, AULOIPTOT, AULOIRCCA, AULOIASIS, AULOIDEFE, AULOILURI, AULOITIPV, AULOIFEMI,AUSOPRO_ID_PROD_BA,AUSOPRO_ID_PROD_PE)) as Producto,
					AULO.AULOICPOS,
					AULO.AULOICOLE,
					AULO.AULOIIDSOLIC,
					AULO.FEC_GENERACION
	FROM
		DW_AUTOS.dbo.TAULOIPR AULO with(nolock) 
		OUTER APPLY 
		(
			SELECT TOP 1 AUSOPRO_ID_PROD_BA
					,AUSOPRO_ID_PROD_PE
			FROM DW_AUTOS.DBO.TAUSOPRO TAU WITH (NOLOCK)
			WHERE AULO.AULOIIDSOLIC  = TAU.AUSOPRO_ID_SOLICIT
				AND AULO.AULOIEMPR   = TAU.AUSOPRO_ID_EMPRESA
				AND TAU.AUSOPRO_ID_RAMO = 1
		) OA
	WHERE	
		AULO.F_CARGA > @UltimaFCargaX
	-- 1:34 minuto 

	set @Nregistros=@@rowcount
	set @Msg='Tabla temporal TMP.XAUTOS_DBO.COTIZACIONES_TMP,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2


	-- DECLARE @UltimaFCargaX DATETIME = '20150416'
	-- Obtengo las cotizaciones web que han cambiado
	-- Primero las calculadas anteriormente: ha cambiado TAULOIPR o TAUDACOP
	EXEC comun..ELIMINATABLA 'TMP.XAUTOS_DBO.COTIZACIONES_TMP1'
	SELECT 
		AMRGSIM_CODIGO, 
		AULOIIDSOLIC
	INTO TMP.XAUTOS_DBO.COTIZACIONES_TMP1
	FROM (
	SELECT
		AMRGSIM_CODIGO, 
		AULOIIDSOLIC,
		ROW_NUMBER() OVER (PARTITION BY AMRGSIM_CODIGO ORDER BY FEC_GENERACION DESC) AS Orden
	FROM (	
	SELECT 
			RGSIM.AMRGSIM_CODIGO, 
			TMP.AULOIIDSOLIC,
			TMP.FEC_GENERACION
	FROM 
		TMP.XAUTOS_DBO.COTIZACIONES_TMP TMP (NOLOCK) INNER JOIN DW_AUTOS..AUTOSREGSIM RGSIM(NOLOCK) ON
					TMP.AULOICCOT = RGSIM.AMRGSIM_COCOTIZ  AND
					TMP.Producto = RGSIM.Producto AND
					TMP.AULOICPOS = RGSIM.AMRGSIM_CODPOS AND
					TMP.AULOICOLE = RGSIM.AMRGSIM_COAGREG
	UNION				
	-- Segundo Las que ha cambiado TAMRGSIM
	SELECT 
			RGSIM.AMRGSIM_CODIGO, 
			AULO.AULOIIDSOLIC,
			AULO.FEC_GENERACION
	FROM 
		DW_AUTOS..TAULOIPR AULO (NOLOCK) INNER JOIN DW_AUTOS..AUTOSREGSIM RGSIM(NOLOCK) ON
					AULO.AULOICCOT = RGSIM.AMRGSIM_COCOTIZ  AND
					AULO.AULOITSEG = RGSIM.AMRGSIM_TSEG AND
					isnull(AULO.AULOISUBP,0) = isnull(RGSIM.AMRGSIM_SUBP,0) AND
					AULO.AULOIFTIP = isnull(RGSIM.AMRGSIM_FTIP,' ')  AND
					isnull(AULO.AULOIPVIP,0) = isnull(RGSIM.AMRGSIM_PVIP,0) AND
					--AULO.Producto = RGSIM.Producto AND
					AULO.AULOICPOS = RGSIM.AMRGSIM_CODPOS AND
					AULO.AULOICOLE = RGSIM.AMRGSIM_COAGREG
	WHERE
		RGSIM.F_CARGA > @UltimaFCargaX
	)TMP )TMPA
	WHERE 
	   ORDEN = 1
	  -- 1:05 minuto 	

	set @Nregistros=@@rowcount
	set @Msg='Tabla temporal TMP.XAUTOS_DBO.COTIZACIONES_TMP1,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

	-- Para la parte no web se trabajaría después con TMP.XAUTOS_DBO.COTIZACIONES_TMP cruzando de nuevo con el IdSolicitud
	-- Para la parte  web se trabajaría después con TMP.XAUTOS_DBO.COTIZACIONES_TMP1 cruzando de nuevo con el IdSolicitud

	
	-- Obtengo las cotizaciones web que han cambiado aunque no exista relación con TAULOIPR
	-- Primero las calculadas anteriormente: ha cambiado TAULOIPR o TAUDACOP
	EXEC comun..ELIMINATABLA 'TMP.XAUTOS_DBO.COTIZACIONES_TMP2'
	SELECT 
			AMRGSIM_CODIGO, 
			AULOIIDSOLIC
	INTO TMP.XAUTOS_DBO.COTIZACIONES_TMP2
	FROM 
		TMP.XAUTOS_DBO.COTIZACIONES_TMP1
	UNION ALL
	SELECT 
			RGSIM.AMRGSIM_CODIGO, 
			0 AS AULOIIDSOLIC
	FROM 
		DW_AUTOS..AUTOSREGSIM RGSIM(NOLOCK) LEFT JOIN TMP.XAUTOS_DBO.COTIZACIONES_TMP1 TMP (NOLOCK) ON
			RGSIM.AMRGSIM_CODIGO = TMP.AMRGSIM_CODIGO
	WHERE
		-- Las que no hayamos cargado ya
		TMP.AMRGSIM_CODIGO IS NULL AND
		RGSIM.F_CARGA > @UltimaFCargaX
	
	set @Nregistros=@@rowcount
	set @Msg='Tabla temporal TMP.XAUTOS_DBO.COTIZACIONES_TMP2,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

	
-- Añadir f_Carga 
-- WEB
	exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.XCotizaciones_Web'
	select
	 	  IdCotizacion
		, FecEmision
		, Agregador
		,Tipo 
		,NifTomador
		,TipoPersona
		,CodPostal
		,idModelo
		,Producto
		,CanalEntrada
		,FNacTomador
		,FNacConductor
		,case when tipopersona='J' then 0 else SexoTomador end as 'SexoTomador' --las pj no tienen sexo
		,FRT
		,Descuentos
		,FechaConstruccion
		,ValorVehiculo
		,ValorAccesorios
		,Operador
		,RelacionPresentador
		,Importe
		--,checksum(cast(marca as smallint),cast(modelo as smallint),year(fnactomador),month(fnactomador),cast(codpostal as int),cast(sexotomador as tinyint)) as [checksum]
		--,binary_checksum(cast(marca as smallint),cast(modelo as smallint),year(fnactomador),month(fnactomador),cast(codpostal as int),cast(sexotomador as tinyint)) as [binary_checksum]
		,IdEmpresa   		
		,IdNegocio
		,GarantiaMecanica
		,case when GarantiaMecanica in ('GM1','GM9') then '3'
		      else '0'
		 end  GarantiaMecanicaFP		
		--, 'Y' /* ISNULL(AMRGSIM_PASNF,'Y')*/ PresenciaAsnef
		--, 'Y' /*ISNULL(AMRGSIM_RSCOR,'Y')*/  RiskScore
		--, 'Y' /*ISNULL(AMRGSIM_SSCOR,'Y')*/  SeverityScore
		, AMRGSIM_PASNF PresenciaAsnef
		, AMRGSIM_RSCOR RiskScore
		, AMRGSIM_SSCOR SeverityScore
		, Lunas
		, IdOficina
		, CodErrorCotiz
		, CodAvisoCotiz
		, idSolicitud
		, id15PuntosCarnet
		, IdFrecuenciaPago
		, IdOcupantes
		, IdUsoVehiculo
		, IdVehiculoNuevo
		, IdSesion
		, SexoConductor
		, FechaEfecto
		, TipoVehiculo
		,CASE WHEN isnull(s.AMRGSIM_CCIA,0) <> 0 or isnull(s.AMRGSIM_ANAN,0) <> 0 THEN isnull(s.AMRGSIM_CCIA,0)
			  ELSE CASE WHEN s.AUDACOP_NUMANO_EST IS NOT NULL THEN s.AUDACOP_EMPRES_EST
						ELSE s.AMRGSIM_CCIA
				   END
		 END CompañiaProcedencia
		,CASE WHEN isnull(s.AMRGSIM_CCIA,0) <> 0 or isnull(s.AMRGSIM_ANAN,0) <> 0  THEN isnull(s.AMRGSIM_ANAN,0)
			  ELSE CASE WHEN s.AUDACOP_NUMANO_EST IS NOT NULL THEN s.AUDACOP_NUMANO_EST
						ELSE s.AMRGSIM_ANAN
				   END
		 END NAñosCompProcedencia
		,CASE WHEN isnull(s.AMRGSIM_CCIA,0) <> 0 or isnull(s.AMRGSIM_ANAN,0) <> 0  THEN isnull(s.AMRGSIM_NPAR,0)
			  ELSE CASE WHEN s.AUDACOP_NUMANO_EST IS NOT NULL THEN s.AUDACOP_NUMSIN_EST
						ELSE s.AMRGSIM_NPAR
				   END
		 END NSiniCompProcedencia
		,CASE WHEN isnull(s.AMRGSIM_CCIA,0) <> 0 or isnull(s.AMRGSIM_ANAN,0) <> 0  THEN 'T'
			  ELSE CASE WHEN s.AUDACOP_NUMANO_EST IS NOT NULL THEN 'I'
						ELSE CASE WHEN s.AMRGSIM_CCIA IS NOT NULL or s.AMRGSIM_ANAN IS NOT NULL THEN 'T' ELSE 'N' END
				   END
		 END OrigenCompProc
		,FecEmisionCodigo
		,Telefono
		,AñoAdquisicion
		,KMAño
		,LugarAparcamiento
		,FNacCO
		,FrtCO
		,SexoCO
		,RelacionCO
		,EstadoCivil
		,UsoVehiculo
		,Cod_Agreg_Cruce
	into 
		tmp.xautos_dbo.XCotizaciones_Web			
				
	from
		(
		select --cotizaciones web																	
			90000000000000000000 + amrgsim_codigo as IdCotizacion 
			,cast(left(replace(amrgsim_fecsimul,'-',''),20) as datetime)  AS FecEmision
			,NULLIF(s.amrgsim_Coagreg,'') AS Agregador
			, 'N' AS Tipo 
			,cast(case
				when isnull(amrgsim_dni2,'')='' then '#'+cast(amrgsim_codigo as varchar(10))
				when isnumeric(left(amrgsim_dni2,1))=1 then right('000000000'+upper(rtrim(ltrim(amrgsim_dni2))),9) 
				else upper(left(amrgsim_dni2,1)+ right('00000000'+substring(amrgsim_dni2,2,10),9))
			 end as varchar(10)) as NifTomador 
			--,comun.dbo.fn_tipopersona(replace(amrgsim_dni,'0X','X')) as  TipoPersona      -- TIPO DE PERSONA (FISICA,JURIDICA,EXTRANJERO)
			,F.Tipopersona as  TipoPersona      -- TIPO DE PERSONA (FISICA,JURIDICA,EXTRANJERO)			
			,amrgsim_codpos AS CodPostal -- CODIGO POSTAL COTIZACIÓN
			,M.id as [idModelo]
			,Producto
			, CASE WHEN NULLIF(s.amrgsim_Coagreg,'') = 'AGRE0021' THEN 'L' 
			       ELSE 'W' 
			  END AS CanalEntrada -- CANAL DE CONTRATACION
			                      -- Si el Agregador es AGRE0021 el canal de entrada es Canal Mobile.
			,CASE 
					WHEN AMRGSIM_FNAT IS NULL THEN 
						-- Como se estaba grabando anteriormente.
						cast(case when amrgsim_fecnac < '19010101' then null when amrgsim_fecnac > '20501230' then null else amrgsim_fecnac end as datetime)
					WHEN ISDATE(AMRGSIM_FNAT)=1 AND ( LEFT(CONVERT(VARCHAR,AMRGSIM_FNAT),4)<'1901' OR LEFT(CONVERT(VARCHAR,AMRGSIM_FNAT),4)>'2079') THEN NULL
					WHEN ISDATE(AMRGSIM_FNAT)=1 THEN AMRGSIM_FNAT
					ELSE NULL 
				END AS FNacTomador -- FECHA NACIMIENTO TOMADOR
			,CASE 
					WHEN --ISDATE(AMRGSIM_FECNAC)=1 AND 
						( LEFT(CONVERT(VARCHAR,AMRGSIM_FECNAC),4)<'1901' OR LEFT(CONVERT(VARCHAR,AMRGSIM_FECNAC),4)>'2079') THEN NULL
					--WHEN ISDATE(AMRGSIM_FECNAC)=1 THEN AMRGSIM_FECNAC
					ELSE AMRGSIM_FECNAC
				END AS FNacConductor -- FECHA NACIMIENTO CONDUCTOR
		--	,cast(case when amrgsim_fecnac < '19010101' then null when amrgsim_fecnac > '20501230' then null else amrgsim_fecnac end as smalldatetime) as FNacTomador -- FECHA NACIMIENTO TOMADOR
		--	,cast(case when amrgsim_fecnac < '19010101' then null when amrgsim_fecnac > '20501230' then null else amrgsim_fecnac end as smalldatetime) as FNacConductor -- FECHA NACIMIENTO CONDUCTOR
			,CASE 
				WHEN AMRGSIM_SEXT IS NULL THEN 
					-- Como se estaba grabando anteriormente
					cast(case when s.amrgsim_sexo is null then 0 else  s.amrgsim_sexo end as varchar(1)) 
				ELSE AMRGSIM_SEXT
			END	as SexoTomador -- SEXO DE TOMADOR
			,CASE 
				--WHEN AMRGSIM_CODIGO IN (36914773, 36736140,36736141) THEN NULL
				WHEN AMRGSIM_FCCO IS NULL THEN 
					-- Como se estaba grabando anteriormente
					cast(case when amrgsim_feccar < '19010101' then null when amrgsim_feccar > '20501230' then null else amrgsim_feccar end as datetime)
				ELSE
					cast(Case 
						when  AMRGSIM_FCCO is null or  AMRGSIM_FCCO<'190101'  
						Then Null
						when  AMRGSIM_FCCO>'20501230' THEN Null
						else left(convert(varchar, AMRGSIM_FCCO),6)+'15'
					end as date) 
				END AS FRT -- FECHA CARNET DE CONDUCIR
			, CASE 
				WHEN AMRGSIM_RELD = 'Z' THEN '0'
				ELSE AMRGSIM_RELD
			END as Descuentos	-- RELACION DE DESCUENTOS				
			,cast(Case 
					when AMRGSIM_ACON is null or AMRGSIM_ACON<1901 or AMRGSIM_ACON > YEAR(GETDATE()) then Null  
					else cast(AMRGSIM_ACON*10000+ 101 as varchar)
			End as date) AS FechaConstruccion -- FECHA CONSTRUCCION VEHICULO
			,CASE	
					WHEN ISNULL(AMRGSIM_VALO,0) = 0 THEN ISNULL(NULLIF(m.Valor,10000000),0)
					ELSE AMRGSIM_VALO
			  END AS ValorVehiculo
			,AMRGSIM_VACC AS ValorAccesorios -- VALOR DE ACCESORIOS
			-- ARQ Se cambia el origen a partir de AMRGSIM_FECSIMUL >= 20170621 y siempre que el usuario empiece por CT
			,CASE 
				WHEN cast(left(replace(AMRGSIM_FECSIMUL,'-',''),20) as datetime) >= '20170621' THEN
				    CASE 
					   WHEN LEFT(LTRIM(RTRIM(AMRGSIM_USUARIO)), 2) = 'CT' THEN AMRGSIM_USUARIO
					   ELSE AMRGSIM_UUMO
				    END
				ELSE AMRGSIM_UUMO
			END AS Operador
			--,'WEB' AS Operador  -- El campo Ultimo usuario de modificación no es siempre Web, pero la vista AUTOSREGSIM está filtrando para coger sólo 
								-- El caso de Web (hablado con Guillermo Bazán.
			,AMRGSIM_RELA AS RelacionPresentador
			,AMRGSIM_IMRE AS Importe
			,CASE -- Aparte del valor nulo para los registros anteriores a la inclusión de nuevos campos en TAMRGSIM, 
			      -- hemos encontrado empresas con valores distintos a 1 y 3
				WHEN AMRGSIM_EMPR IS NULL THEN 1 
				WHEN AMRGSIM_EMPR = 3 THEN AMRGSIM_EMPR 
				ELSE 1 
			END AS IdEmpresa
			--,m.marca,m.modelo
			,ISNULL(TUC.uccoidco, '0') as IdNegocio
			, AMRGSIM_TSEG
			, AMRGSIM_SUBP
			, isnull(substring(isnull(PC2.aprogara,PC1.aprogara),4,1),'N') as Lunas
			, isnull(PC2.aproprod,isnull(PC1.aproprod,'ZZ')) as ProProducto
			,ISNULL(AMRGSIM_GARM,'') AS GarantiaMecanica
			--,'Y' /*ISNULL(AMRGSIM_PASNF,'Y')*/ AMRGSIM_PASNF
			--,'Y' /*ISNULL(AMRGSIM_RSCOR,'Y')*/ AMRGSIM_RSCOR
			--,'Y' /*ISNULL(AMRGSIM_SSCOR,'Y')*/ AMRGSIM_SSCOR
			--RH 29/07/2015
			,ISNULL(AMRGSIM_PASNF,'Y') AMRGSIM_PASNF
			,ISNULL(AMRGSIM_RSCOR,'Y') AMRGSIM_RSCOR
			,case when ISNULL(AMRGSIM_SSCOR,'Y')='N' THEN 'Y' ELSE ISNULL(AMRGSIM_SSCOR,'Y') END AMRGSIM_SSCOR --el valor N no existe se la asigna desconocido
			, AMRGSIM_PTORED as 'idOficina'
			, CASE 
					-- Solamente consideramos como error los casos en que no hay prima.
					-- Si no encontramos el error en la tabla de errores, lo catalogamos como error.
					WHEN ISNULL(ERR.TipoError,'E') = 'E' AND ISNULL(AMRGSIM_IMRE,0) <=0 THEN
						--ERR.Cod_Error
						AMRGSIM_CODERR
					ELSE 0	
			END as CodErrorCotiz
			, CASE 
					-- Consideramos avisos los errores en que hay prima o los errores de tipo W.
					WHEN ISNULL(ERR.TipoError,'0') = 'W' OR ISNULL(AMRGSIM_IMRE,0) > 0 THEN
						--ERR.Cod_Error
						AMRGSIM_CODERR
					ELSE 0	
			END as CodAvisoCotiz
			, isnull(IdSolicitud, 0) as 'IdSolicitud'
			, isnull(COP.AUDACOP_NUM_PUNTOS, 0) as 'id15PuntosCarnet'
			, AMRGSIM_FPGA		AS 'IdFrecuenciaPago'
			-- 07/10/2015  Error en ocupantes = -1
			, CASE 
				WHEN AMRGSIM_COMB = -1	THEN 0
				ELSE AMRGSIM_COMB
			END AS 'IdOcupantes'
			, AMRGSIM_TUSO		AS 'IdUsoVehiculo'
			, AMRGSIM_WSWNU		AS 'IdVehiculoNuevo'
			, AMRGSIM_COCOTIZ	AS 'IdSesion'
			, isnull(AMRGSIM_SEXO,0) as SexoConductor
			, AMRGSIM_FEFEC as FechaEfecto
			, m.TipoVeh AS TipoVehiculo
			--Campos de compañía de procedencia
			,S.AMRGSIM_CCIA
			,S.AMRGSIM_ANAN
			,S.AMRGSIM_NPAR
			,COP.AUDACOP_EMPRES_EST
			,COP.AUDACOP_NUMANO_EST
			,COP.AUDACOP_NUMSIN_EST
			,cast(left(replace(amrgsim_fumo,'-',''),20) as datetime)  AS FecEmisionCodigo
			,case when isnull(S.AMRGSIM_TLFN, 0) <> 0 then S.AMRGSIM_TLFN
					else null
			 end Telefono
			,S.AMRGSIM_AADQ				as AñoAdquisicion
			,S.AMRGSIM_KMAACT			as KMAño
			,S.AMRGSIM_LAPACT			as LugarAparcamiento
			,S.AMRGSIM_FNACO			as FNacCO
			,S.AMRGSIM_FCCCO			as FrtCO
			,S.AMRGSIM_SEXCO			as SexoCO
			,S.AMRGSIM_RECO				as RelacionCO
			,S.AMRGSIM_ESCI				as EstadoCivil
			,S.AMRGSIM_USOACT			as UsoVehiculo
			,isnull(solic.AUSOLIC_ID_NEGO_FIN,'ZZZZZZZX') as Cod_Agreg_Cruce

		from 
			(
			 select  SIM.*
					,ltrim(rtrim(replace(amrgsim_dni,'0X','X'))) as amrgsim_dni2 
					, left(right('000000000000000000' + amrgsim_coclave,18),5)  as Marca
					, substring(right('000000000000000000' + amrgsim_coclave,18),6,3)  as Modelo
					, substring(right('000000000000000000' + amrgsim_coclave,18),9,3)  as SubModelo
					, substring(right('000000000000000000' + amrgsim_coclave,18),12,3)  as Terminacion
					, right(amrgsim_coclave,4)  as Año
					, PT.AULOIIDSOLIC as 'IdSolicitud'
			 from  dw_autos.dbo.autosregsim SIM WITH(NOLOCK)
			 inner join 
				TMP.XAUTOS_DBO.COTIZACIONES_TMP2 PT with(nolock)
				on 
					PT.AMRGSIM_CODIGO  = SIM.AMRGSIM_CODIGO 
			 ) S
			 
		left join 
			DW_AUTOS.dbo.TAUDACOP COP with(nolock)
			on 
			COP.AUDACOP_ID_RAMO	= 1
			and	COP.AUDACOP_ID_EMPRESA = S.AMRGSIM_EMPR
			and	COP.AUDACOP_ID_SOLICIT = S.IdSolicitud
			and	COP.AUDACOP_ID_RIESGO = 1			
		left join 
			XAUTOS.dbo.MARCAS  m WITH(NOLOCK)	
		on	
				S.Marca = M.marca        AND
				S.Modelo = M.modelo       AND
				S.Submodelo = M.submodelo    AND
				S.Terminacion = M.terminacion AND
				S.Año = M.año  
		left join --para asegurar la integridad con colectivos
			dw_autos..tuccolec TUC WITH(NOLOCK) 
		on	
			s.amrgsim_Coagreg = TUC.uccoidco 
		left join 
			DW_AUTOS..TAPRODUC PC2 
		on 
			PC2.APROPROD = CAST(AMRGSIM_TSEG AS VARCHAR) + AMRGSIM_SUBP 
		left join 
			DW_AUTOS..TAPRODUC PC1 
		on 
			PC1.APROPROD = CAST(AMRGSIM_TSEG AS VARCHAR)
		left join XDIM.autos.ErroresCotizacion ERR (NOLOCK) ON
			AMRGSIM_CODERR = ERR.Cod_Error 
		cross apply comun.dbo.fn_TipoPersona_tbl (amrgsim_dni) F			
		left JOIN DW_AUTOS..TAUSOLIC solic (nolock)
			on  s.idsolicitud=solic.AUSOLIC_ID_SOLICIT	
				and S.AMRGSIM_EMPR =solic.AUSOLIC_ID_EMPRESA		
				and solic.AUSOLIC_ID_RAMO =1		
		) s	

	set @Nregistros=@@rowcount
	set @Msg='Tabla temporal tmp.xautos_dbo.XCotizaciones_Web,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

--		option (recompile)		
	-- 24"
	-- (63955 row(s) affected)
--	select * from tmp.xautos_dbo.XCotizaciones_Web
	
	-- RESTO
	 -- Cotizaciones no web	
	exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.XCotizaciones_Resto'
	
	select 	
	 	  IdCotizacion
		, FecEmision
		, Agregador
		,Tipo 
		,NifTomador
		,TipoPersona
		,CodPostal
		,idModelo
		,Producto
		,CanalEntrada
		,FNacTomador
		,FNacConductor
		,case when tipopersona='J' then 0 else SexoTomador end as 'SexoTomador' --las pj no tienen sexo
		,FRT
		,Descuentos
		,FechaConstruccion
		,ValorVehiculo
		,ValorAccesorios
		,Operador
		,RelacionPresentador
		,Importe
		--,checksum(cast(marca as smallint),cast(modelo as smallint),year(fnactomador),month(fnactomador),cast(codpostal as int),cast(sexotomador as tinyint)) as [checksum]
		--,binary_checksum(cast(marca as smallint),cast(modelo as smallint),year(fnactomador),month(fnactomador),cast(codpostal as int),cast(sexotomador as tinyint)) as [binary_checksum]
		,IdEmpresa   		
		,IdNegocio	
		,GarantiaMecanica
		,case when GarantiaMecanica in ('GM1','GM9') then '3'
		      else '0'
		 end  GarantiaMecanicaFP		
		,ISNULL(AMRGSIM_PASNF,'Y')  PresenciaAsnef
		,ISNULL(AMRGSIM_RSCOR,'Y')  RiskScore
		,ISNULL(AMRGSIM_SSCOR,'Y')  SeverityScore
		--, 'Y' /*ISNULL(AMRGSIM_PASNF,'Y')*/  PresenciaAsnef
		--, 'Y' /*ISNULL(AMRGSIM_RSCOR,'Y')*/  RiskScore
		--, 'Y' /*ISNULL(AMRGSIM_SSCOR,'Y')*/  SeverityScore
		, Lunas
		, IdOficina
		, CodErrorCotiz
		, CodAvisoCotiz
		, idSolicitud
		, id15PuntosCarnet	
		, IdFrecuenciaPago
		, IdOcupantes
		, IdUsoVehiculo
		, IdVehiculoNuevo
		, IdSesion
		, SexoConductor
		, FechaEfecto
		, TipoVehiculo
		, CASE WHEN isnull(A.AULOICCIA,0) <> 0 or isnull(A.AULOIANAN,0) <> 0 THEN isnull(A.AULOICCIA,0)
			   ELSE CASE WHEN A.AUDACOP_NUMANO_EST IS NOT NULL THEN A.AUDACOP_EMPRES_EST
						 ELSE A.AULOICCIA
			   END
		  END CompañiaProcedencia
		, CASE WHEN isnull(A.AULOICCIA,0) <> 0 or isnull(A.AULOIANAN,0) <> 0 THEN isnull(A.AULOIANAN,0)
			   ELSE CASE WHEN A.AUDACOP_NUMANO_EST IS NOT NULL THEN A.AUDACOP_NUMANO_EST
						 ELSE A.AULOIANAN
					END
		  END NAñosCompProcedencia
		, CASE WHEN isnull(A.AULOICCIA,0) <> 0 or isnull(A.AULOIANAN,0) <> 0 THEN isnull(A.AULOINPAR,0)
			   ELSE CASE WHEN A.AUDACOP_NUMANO_EST IS NOT NULL THEN A.AUDACOP_NUMSIN_EST
						 ELSE A.AULOINPAR
				    END
		  END NSiniCompProcedencia
		, CASE WHEN isnull(A.AULOICCIA,0) <> 0 or isnull(A.AULOIANAN,0) <> 0 THEN 'T'
			   ELSE CASE WHEN A.AUDACOP_NUMANO_EST IS NOT NULL THEN 'I'
				 		 ELSE CASE WHEN A.AULOICCIA IS NOT NULL or A.AULOIANAN IS NOT NULL THEN 'T' ELSE 'N' END
				    END
		  END OrigenCompProc
		, FecEmision as FecEmisionCodigo
		, Telefono
		, AñoAdquisicion
		, KMAño
		, LugarAparcamiento
		, FNacCO
		, FrtCO
		, SexoCO
		, RelacionCO
		, EstadoCivil
		, UsoVehiculo
		, Cod_Agreg_Cruce
	into 	
		tmp.xautos_dbo.XCotizaciones_Resto			
	
	from 
		(
	
	select 																
		 C1.IdCotizacion 
		,cast(left(replace(C1.AULOIFEMI,'-',''),20) as datetime) as FecEmision
		,cast(NULL  as varchar(10))as Agregador
		, C1.AULOISITU AS Tipo -- N=>Nueva cotización, U=>Cotización a Presupuesto, S=>Cotización a Póliza, P=> Presupuesto a Póliza
		, CAST(CASE
				WHEN C1.AULOINIFT IS NULL THEN
					CASE WHEN C1.AULOIRPOL > 0 THEN '#'+LEFT(CAST(C1.AULOIRPOL AS VARCHAR), 9)
					ELSE '#'+LEFT(CAST(C1.ID AS VARCHAR), 9)
					END
				ELSE C1.AULOINIFT
			END AS VARCHAR(10)) AS NifTomador -- NIF DEL TOMADOR COTIZACIÓN
			--,comun.dbo.fn_TipoPersona(C1.AULOINIFT)  as TipoPersona      --
		, F.TipoPersona  as TipoPersona
		, CAST(C1.AULOICPOS AS VARCHAR(5))AS CodPostal -- CODIGO POSTAL COTIZACIÓN
		, M.Id as Idmodelo
		--, C1.Producto		
		,(select  producto from DW_AUTOS..fn_autos_productos (AULOIEMPR, AULOITSEG, LEFT(AULOIPVIP,1), AULOISUBP, AULOIFTIP, AULOIPTOT, AULOIRCCA, AULOIASIS, AULOIDEFE, AULOILURI, AULOITIPV, AULOIFEMI,AUSOPRO_ID_PROD_BA,AUSOPRO_ID_PROD_PE)) as Producto
		, CASE WHEN C1.AULOICOLE = 'AGRE0021' THEN 'L' 
		       ELSE C1.AULOICANA 
		  END AS CanalEntrada -- CANAL DE CONTRATACION
		                      -- Canal MOBILE para el negocio AGRE0021
		,CASE 
				WHEN ISDATE(C1.AULOIFNAT)=1 AND ( LEFT(CONVERT(VARCHAR,C1.AULOIFNAT),4)<'1901' OR LEFT(CONVERT(VARCHAR,C1.AULOIFNAT),4)>'2079') THEN NULL
				WHEN ISDATE(C1.AULOIFNAT)=1 THEN C1.AULOIFNAT
				ELSE NULL 
			END AS FNacTomador -- FECHA NACIMIENTO TOMADOR
		, CASE 		
				WHEN ISDATE(C1.AULOIFNAC)=1 AND (LEFT(CONVERT(VARCHAR,C1.AULOIFNAC),4)<'1901'or LEFT(CONVERT(VARCHAR,C1.AULOIFNAC),4)>'2079') THEN NULL 
				WHEN ISDATE(C1.AULOIFNAC)=1 THEN C1.AULOIFNAC
			ELSE NULL
			END AS FNacConductor -- FECHA NACIMIENTO CONDUCTOR
		, C1.AULOISEXT AS SexoTomador -- SEXO DE TOMADOR
		,cast(Case 
			when C1.AULOIFCCO is null or C1.AULOIFCCO<190101 Then Null
			else left(convert(varchar,C1.AULOIFCCO),6)+'15'
		end as date) AS FRT -- FECHA CARNET DE CONDUCIR
		, CASE 
			WHEN C1.AULOIRELD = 'Z' THEN '0'
			ELSE C1.AULOIRELD
		END as Descuentos	-- RELACION DE DESCUENTOS				
		,cast(Case 
				when C1.AULOIACON is null or C1.AULOIACON<1901 then Null
				else cast(C1.AULOIACON*10000+ 101 as varchar)
			End as date) AS FechaConstruccion -- FECHA CONSTRUCCION VEHICULO
		
		,	 CASE	
			--WHEN C1.AULOIVALO = 0 THEN ISNULL(NULLIF((select M.valor from XAutos.dbo.marcas m WITH(NOLOCK) where C1.IdMarca = M.Id)  ,10000000),0)
			WHEN C1.AULOIVALO = 0 THEN ISNULL(NULLIF(M.valor,10000000),0)
			ELSE C1.AULOIVALO 
		  END AS ValorVehiculo
		, C1.AULOIVACC AS ValorAccesorios -- VALOR DE ACCESORIOS
		, C1.AULOIUUMO AS Operador
		, C1.AULOIRELA AS RelacionPresentador
		, C1.AULOIIMRE AS Importe
		, CASE C1.AULOIEMPR  -- Hemos encontrado empresas con valores distintos a 1 y 3
			WHEN 3 THEN C1.AULOIEMPR
			ELSE 1 
		  END AS IdEmpresa

		, isnull(substring(isnull(PC2.aprogara,PC1.aprogara),4,1),'N') as Lunas
		, isnull(PC2.aproprod,isnull(PC1.aproprod,'ZZ')) as ProProducto
		, ISNULL(TUC.uccoidco, '0') as IdNegocio
		, ISNULL(C1.AULOIGARM,'') AS GarantiaMecanica
		, CASE WHEN ISNULL(AUDACOT_ASNEF,'Y')='0' THEN 'Y' ELSE ISNULL(AUDACOT_ASNEF,'Y') END AMRGSIM_PASNF
		, case when ISNULL(AUDACOT_RISK_SCORE,'Y')='' then 'Y' else ISNULL(AUDACOT_RISK_SCORE,'Y') END AMRGSIM_RSCOR
		, CASE WHEN ISNULL(AUDACOT_SEVERITY_CODE,'Y')in ('N','0','00') THEN 'Y' ELSE ISNULL(AUDACOT_SEVERITY_CODE,'Y') END AMRGSIM_SSCOR
		, AULOIPTORED						as 'idOficina'
		, 0									as 'CodErrorCotiz'
		, 0									as 'CodAvisoCotiz'
		, isnull(C1.AULOIIDSOLIC, 0)		as 'idSolicitud'
		, isnull(COP.AUDACOP_NUM_PUNTOS, 0)	as 'id15PuntosCarnet'
		, AULOIFPGA		AS 'IdFrecuenciaPago'
		, AULOICOMB		AS 'IdOcupantes'
		, AULOITUSO		AS 'IdUsoVehiculo'
		, AULOIWSWNU	AS 'IdVehiculoNuevo'
		, C1.AULOICCOT	AS 'IdSesion'
		, case when isnull(AULOISEXC,0) IN (5,6) then 0 else isnull(AULOISEXC,0)end as SexoConductor
		, AULOIFEFE as FechaEfecto 
		, m.TipoVeh AS TipoVehiculo
		--Campos compañía de procedencia
		,C1.AULOICCIA
		,C1.AULOIANAN
		,C1.AULOINPAR 
		,COP.AUDACOP_EMPRES_EST
		,COP.AUDACOP_NUMANO_EST
		,COP.AUDACOP_NUMSIN_EST		
		,case when isnull(TCO.AUDACOT_TLFN_1, 0) <> 0 then TCO.AUDACOT_TLFN_1
			  when isnull(TCO.AUDACOT_TLFN_2, 0) <> 0 then TCO.AUDACOT_TLFN_2
			  else null
		 end Telefono
		,C1.AULOIAADQ		as AñoAdquisicion
		,C1.AULOIKMAACT		as KMAño
		,C1.AULOILAPACT		as LugarAparcamiento
		,C1.AULOIFNACO		as FNacCO
		,C1.AULOIFCCCO		as FrtCO
		--,C1.AULOISEXCO		as SexoCO
		--rhr 03/03/2017
		,CASE 
			WHEN C1.AULOISEXCO='M' THEN '2'
			WHEN C1.AULOISEXCO='H' THEN '1' 
			WHEN C1.AULOISEXCO IS NULL THEN '0'
			ELSE C1.AULOISEXCO 
		END AS SexoCO
		,C1.AULOIRECO		as RelacionCO
		,C1.AULOIESCI		as EstadoCivil
		,C1.AULOIUSOACT		as UsoVehiculo
		,isnull(solic.AUSOLIC_ID_NEGO_FIN,'ZZZZZZZX') as Cod_Agreg_Cruce

	from
		DW_AUTOS.dbo.TAULOIPR			 C1 WITH(NOLOCK) 
		OUTER APPLY 
		(
			SELECT TOP 1 AUSOPRO_ID_PROD_BA
						,AUSOPRO_ID_PROD_PE
			FROM DW_AUTOS.DBO.TAUSOPRO TAU WITH (NOLOCK)
			WHERE C1.AULOIIDSOLIC  = TAU.AUSOPRO_ID_SOLICIT
			AND C1.AULOIEMPR   = TAU.AUSOPRO_ID_EMPRESA
			AND TAU.AUSOPRO_ID_RAMO = 1
		) OA
	inner join
		TMP.XAUTOS_DBO.COTIZACIONES_TMP  PT with(nolock)
		on
			PT.IDCOTIZACION = C1.IDCOTIZACION
			/*
		left join 
			tmp.xautos_dbo.XCotizaciones0 xc0 
		on 
			c1.AULOICCOT = xc0.AMRGSIM_COCOTIZ
			*/
		left join 
			DW_AUTOS.dbo.TAUDACOP COP with(nolock)
			on 
			COP.AUDACOP_ID_RAMO	= 1
			and	COP.AUDACOP_ID_EMPRESA = C1.AULOIEMPR
			and	COP.AUDACOP_ID_SOLICIT = C1.AULOIIDSOLIC
			and	COP.AUDACOP_ID_RIESGO = 1			
		LEFT OUTER JOIN 
			XAUTOS.dbo.MARCAS M WITH(NOLOCK) 
		ON 
				C1.AULOINMAR = M.marca        AND
				C1.AULOINMOD = M.modelo       AND
				C1.AULOINSUB = M.submodelo    AND
				C1.AULOINTER = M.terminacion AND
				C1.AULOINANU = M.año  
		left join --para asegurar la integridad con colectivos
			dw_autos..tuccolec TUC WITH(NOLOCK) 
		on 
			C1.AULOICOLE = TUC.uccoidco 
		left join 
			DW_AUTOS..TAPRODUC PC2 
		on 
			PC2.APROPROD = CAST(AULOITSEG AS VARCHAR) + AULOISUBP 
		left join 
			DW_AUTOS..TAPRODUC PC1 
		on 
			PC1.APROPROD = CAST(AULOITSEG AS VARCHAR)
		cross apply comun.dbo.fn_TipoPersona_tbl (C1.AULOINIFT) F
		
		--campos ASNEF
		left join 
			dw_autos.dbo.TAUDACOT TCO WITH(NOLOCK) 
		ON C1.AULOIIDSOLIC =TCO.AUDACOT_ID_SOLICIT
			AND C1.AULOIEMPR =TCO.AUDACOT_ID_EMPRESA
			AND TCO.AUDACOT_ID_RAMO=1
		left JOIN DW_AUTOS..TAUSOLIC solic (nolock)
			on  TCO.AUDACOT_ID_SOLICIT=solic.AUSOLIC_ID_SOLICIT	
				and TCO.AUDACOT_ID_EMPRESA =solic.AUSOLIC_ID_EMPRESA		
				and solic.AUSOLIC_ID_RAMO =1	
	Where 
			-- Las cotizaciones nuevas pueden tener situación = 'N', 'S' ó 'U' y la póliza (AULOIRPOL) sin informar.
			-- Las cotizaciones de suplementos tienen situación = 'N' ó 'M' y la póliza  (AULOIRPOL)  informada.
			-- 'N' => COTIZACION NUEVA,'S' => PASO DE COTIZACIÓN A POLIZA,'U' => PASO DE COTIZACIÓN A PRESUPUESTO , 'P'=> Presupuesto a Póliza ----- los U y los S se hace update sobre el N
			(c1.AULOISITU IN ('S','U') OR (c1.AULOISITU = 'N' AND c1.AULOIRPOL = 0))
			and AULOICANA <>'W'		
		) A
		
	set @Nregistros=@@rowcount
	set @Msg='Tabla temporal tmp.xautos_dbo.XCotizaciones_Resto,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

		exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.XCotizaciones'
		
		select 
			A.*
		 , getdate() as 'F_carga'
		
		into 
		
				TMP.xautos_dbo.XCotizaciones		 		 
		from 
			(		
			select  
				* 			
	
			from 
				TMP.xautos_dbo.XCotizaciones_Web with(nolock)			
			union all 		
			select
			*
			from 
				TMP.xautos_dbo.XCotizaciones_Resto with(nolock)			
			) A

   set @Nregistros=@@rowcount


	set @Msg='Tabla temporal tmp.xautos_dbo.XCotizaciones,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2
	
	/*
	 
	-- WEB
	exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.XCotizaciones_Web'
	select
	 	  IdCotizacion
		, FecEmision
		, Agregador
		,Tipo 
		,NifTomador
		,TipoPersona
		,CodPostal
		,idModelo
		,Producto
		,CanalEntrada
		,FNacTomador
		,FNacConductor
		,case when tipopersona='J' then 0 else SexoTomador end as 'SexoTomador' --las pj no tienen sexo
		,FRT
		,Descuentos
		,FechaConstruccion
		,ValorVehiculo
		,ValorAccesorios
		,Operador
		,RelacionPresentador
		,Importe
		--,checksum(cast(marca as smallint),cast(modelo as smallint),year(fnactomador),month(fnactomador),cast(codpostal as int),cast(sexotomador as tinyint)) as [checksum]
		--,binary_checksum(cast(marca as smallint),cast(modelo as smallint),year(fnactomador),month(fnactomador),cast(codpostal as int),cast(sexotomador as tinyint)) as [binary_checksum]
		,IdEmpresa   		
		,IdNegocio
		,GarantiaMecanica
		,case when GarantiaMecanica in ('GM1','GM9') then '3'
		      else '0'
		 end  GarantiaMecanicaFP		
		--, 'Y' /* ISNULL(AMRGSIM_PASNF,'Y')*/ PresenciaAsnef
		--, 'Y' /*ISNULL(AMRGSIM_RSCOR,'Y')*/  RiskScore
		--, 'Y' /*ISNULL(AMRGSIM_SSCOR,'Y')*/  SeverityScore
		, AMRGSIM_PASNF PresenciaAsnef
		, AMRGSIM_RSCOR RiskScore
		, AMRGSIM_SSCOR SeverityScore
		, Lunas
		, IdOficina
		, CodErrorCotiz
		, CodAvisoCotiz
		, idSolicitud
		, id15PuntosCarnet
		, IdFrecuenciaPago
		, IdOcupantes
		, IdUsoVehiculo
		, IdVehiculoNuevo
		, IdSesion
		, SexoConductor
		, FechaEfecto
		, TipoVehiculo
		,CASE WHEN isnull(s.AMRGSIM_CCIA,0) <> 0 or isnull(s.AMRGSIM_ANAN,0) <> 0 THEN isnull(s.AMRGSIM_CCIA,0)
			  ELSE CASE WHEN s.AUDACOP_NUMANO_EST IS NOT NULL THEN s.AUDACOP_EMPRES_EST
						ELSE s.AMRGSIM_CCIA
				   END
		 END CompañiaProcedencia
		,CASE WHEN isnull(s.AMRGSIM_CCIA,0) <> 0 or isnull(s.AMRGSIM_ANAN,0) <> 0  THEN isnull(s.AMRGSIM_ANAN,0)
			  ELSE CASE WHEN s.AUDACOP_NUMANO_EST IS NOT NULL THEN s.AUDACOP_NUMANO_EST
						ELSE s.AMRGSIM_ANAN
				   END
		 END NAñosCompProcedencia
		,CASE WHEN isnull(s.AMRGSIM_CCIA,0) <> 0 or isnull(s.AMRGSIM_ANAN,0) <> 0  THEN isnull(s.AMRGSIM_NPAR,0)
			  ELSE CASE WHEN s.AUDACOP_NUMANO_EST IS NOT NULL THEN s.AUDACOP_NUMSIN_EST
						ELSE s.AMRGSIM_NPAR
				   END
		 END NSiniCompProcedencia
		,CASE WHEN isnull(s.AMRGSIM_CCIA,0) <> 0 or isnull(s.AMRGSIM_ANAN,0) <> 0  THEN 'T'
			  ELSE CASE WHEN s.AUDACOP_NUMANO_EST IS NOT NULL THEN 'I'
						ELSE CASE WHEN s.AMRGSIM_CCIA IS NOT NULL or s.AMRGSIM_ANAN IS NOT NULL THEN 'T' ELSE 'N' END
				   END
		 END OrigenCompProc
		,FecEmisionCodigo
		,Telefono
	into 
		tmp.xautos_dbo.XCotizaciones_Web				
				
	from
		(
		select --cotizaciones web																
			90000000000000000000 + amrgsim_codigo as IdCotizacion 
			,cast(left(replace(amrgsim_fecsimul,'-',''),20) as datetime)  AS FecEmision
			,NULLIF(s.amrgsim_Coagreg,'') AS Agregador
			, 'N' AS Tipo 
			,cast(case
				when isnull(amrgsim_dni2,'')='' then '#'+cast(amrgsim_codigo as varchar(10))
				when isnumeric(left(amrgsim_dni2,1))=1 then right('000000000'+upper(rtrim(ltrim(amrgsim_dni2))),9) 
				else upper(left(amrgsim_dni2,1)+ right('00000000'+substring(amrgsim_dni2,2,10),9))
			 end as varchar(10)) as NifTomador 
			--,comun.dbo.fn_tipopersona(replace(amrgsim_dni,'0X','X')) as  TipoPersona      -- TIPO DE PERSONA (FISICA,JURIDICA,EXTRANJERO)
			,F.Tipopersona as  TipoPersona      -- TIPO DE PERSONA (FISICA,JURIDICA,EXTRANJERO)			
			,amrgsim_codpos AS CodPostal -- CODIGO POSTAL COTIZACIÓN
			,M.id as [idModelo]
			,Producto
			, CASE WHEN NULLIF(s.amrgsim_Coagreg,'') = 'AGRE0021' THEN 'L' 
			       ELSE 'W' 
			  END AS CanalEntrada -- CANAL DE CONTRATACION
			                      -- Si el Agregador es AGRE0021 el canal de entrada es Canal Mobile.
			,CASE 
					WHEN AMRGSIM_FNAT IS NULL THEN 
						-- Como se estaba grabando anteriormente.
						cast(case when amrgsim_fecnac < '19010101' then null when amrgsim_fecnac > '20501230' then null else amrgsim_fecnac end as datetime)
					WHEN ISDATE(AMRGSIM_FNAT)=1 AND ( LEFT(CONVERT(VARCHAR,AMRGSIM_FNAT),4)<'1901' OR LEFT(CONVERT(VARCHAR,AMRGSIM_FNAT),4)>'2079') THEN NULL
					WHEN ISDATE(AMRGSIM_FNAT)=1 THEN AMRGSIM_FNAT
					ELSE NULL 
				END AS FNacTomador -- FECHA NACIMIENTO TOMADOR
			,CASE 
					WHEN --ISDATE(AMRGSIM_FECNAC)=1 AND 
						( LEFT(CONVERT(VARCHAR,AMRGSIM_FECNAC),4)<'1901' OR LEFT(CONVERT(VARCHAR,AMRGSIM_FECNAC),4)>'2079') THEN NULL
					--WHEN ISDATE(AMRGSIM_FECNAC)=1 THEN AMRGSIM_FECNAC
					ELSE AMRGSIM_FECNAC
				END AS FNacConductor -- FECHA NACIMIENTO CONDUCTOR
		--	,cast(case when amrgsim_fecnac < '19010101' then null when amrgsim_fecnac > '20501230' then null else amrgsim_fecnac end as smalldatetime) as FNacTomador -- FECHA NACIMIENTO TOMADOR
		--	,cast(case when amrgsim_fecnac < '19010101' then null when amrgsim_fecnac > '20501230' then null else amrgsim_fecnac end as smalldatetime) as FNacConductor -- FECHA NACIMIENTO CONDUCTOR
			,CASE 
				WHEN AMRGSIM_SEXT IS NULL THEN 
					-- Como se estaba grabando anteriormente
					cast(case when s.amrgsim_sexo is null then 0 else  s.amrgsim_sexo end as varchar(1)) 
				ELSE AMRGSIM_SEXT
			END	as SexoTomador -- SEXO DE TOMADOR
			,CASE 
				--WHEN AMRGSIM_CODIGO IN (36914773, 36736140,36736141) THEN NULL
				WHEN AMRGSIM_FCCO IS NULL THEN 
					-- Como se estaba grabando anteriormente
					cast(case when amrgsim_feccar < '19010101' then null when amrgsim_feccar > '20501230' then null else amrgsim_feccar end as datetime)
				ELSE
					cast(Case 
						when  AMRGSIM_FCCO is null or  AMRGSIM_FCCO<'190101'  
						Then Null
						when  AMRGSIM_FCCO>'20501230' THEN Null
						else left(convert(varchar, AMRGSIM_FCCO),6)+'15'
					end as date) 
				END AS FRT -- FECHA CARNET DE CONDUCIR
			, CASE 
				WHEN AMRGSIM_RELD = 'Z' THEN '0'
				ELSE AMRGSIM_RELD
			END as Descuentos	-- RELACION DE DESCUENTOS				
			,cast(Case 
					when AMRGSIM_ACON is null or AMRGSIM_ACON<1901 or AMRGSIM_ACON > GETDATE() then Null  
					else cast(AMRGSIM_ACON*10000+ 101 as varchar)
			End as date) AS FechaConstruccion -- FECHA CONSTRUCCION VEHICULO
			,CASE	
					WHEN ISNULL(AMRGSIM_VALO,0) = 0 THEN ISNULL(NULLIF(m.Valor,10000000),0)
					ELSE AMRGSIM_VALO
			  END AS ValorVehiculo
			,AMRGSIM_VACC AS ValorAccesorios -- VALOR DE ACCESORIOS
			,'WEB' AS Operador  -- El campo Ultimo usuario de modificación no es siempre Web, pero la vista AUTOSREGSIM está filtrando para coger sólo 
								-- El caso de Web (hablado con Guillermo Bazán.
			,AMRGSIM_RELA AS RelacionPresentador
			,AMRGSIM_IMRE AS Importe
			,CASE -- Aparte del valor nulo para los registros anteriores a la inclusión de nuevos campos en TAMRGSIM, 
			      -- hemos encontrado empresas con valores distintos a 1 y 3
				WHEN AMRGSIM_EMPR IS NULL THEN 1 
				WHEN AMRGSIM_EMPR = 3 THEN AMRGSIM_EMPR 
				ELSE 1 
			END AS IdEmpresa
			--,m.marca,m.modelo
			,ISNULL(TUC.uccoidco, '0') as IdNegocio
			, AMRGSIM_TSEG
			, AMRGSIM_SUBP
			, isnull(substring(isnull(PC2.aprogara,PC1.aprogara),4,1),'N') as Lunas
			, isnull(PC2.aproprod,isnull(PC1.aproprod,'ZZ')) as ProProducto
			,ISNULL(AMRGSIM_GARM,'') AS GarantiaMecanica
			--,'Y' /*ISNULL(AMRGSIM_PASNF,'Y')*/ AMRGSIM_PASNF
			--,'Y' /*ISNULL(AMRGSIM_RSCOR,'Y')*/ AMRGSIM_RSCOR
			--,'Y' /*ISNULL(AMRGSIM_SSCOR,'Y')*/ AMRGSIM_SSCOR
			--RH 29/07/2015
			,ISNULL(AMRGSIM_PASNF,'Y') AMRGSIM_PASNF
			,ISNULL(AMRGSIM_RSCOR,'Y') AMRGSIM_RSCOR
			,case when ISNULL(AMRGSIM_SSCOR,'Y')='N' THEN 'Y' ELSE ISNULL(AMRGSIM_SSCOR,'Y') END AMRGSIM_SSCOR --el valor N no existe se la asigna desconocido
			, AMRGSIM_PTORED as 'idOficina'
			, CASE 
					-- Solamente consideramos como error los casos en que no hay prima.
					-- Si no encontramos el error en la tabla de errores, lo catalogamos como error.
					WHEN ISNULL(ERR.TipoError,'E') = 'E' AND ISNULL(AMRGSIM_IMRE,0) <=0 THEN
						--ERR.Cod_Error
						AMRGSIM_CODERR
					ELSE 0	
			END as CodErrorCotiz
			, CASE 
					-- Consideramos avisos los errores en que hay prima o los errores de tipo W.
					WHEN ISNULL(ERR.TipoError,'0') = 'W' OR ISNULL(AMRGSIM_IMRE,0) > 0 THEN
						--ERR.Cod_Error
						AMRGSIM_CODERR
					ELSE 0	
			END as CodAvisoCotiz
			, isnull(IdSolicitud, 0) as 'IdSolicitud'
			, isnull(COP.AUDACOP_NUM_PUNTOS, 0) as 'id15PuntosCarnet'
			, AMRGSIM_FPGA		AS 'IdFrecuenciaPago'
			-- 07/10/2015  Error en ocupantes = -1
			, CASE 
				WHEN AMRGSIM_COMB = -1	THEN 0
				ELSE AMRGSIM_COMB
			END AS 'IdOcupantes'
			, AMRGSIM_TUSO		AS 'IdUsoVehiculo'
			, AMRGSIM_WSWNU		AS 'IdVehiculoNuevo'
			, AMRGSIM_COCOTIZ	AS 'IdSesion'
			, isnull(AMRGSIM_SEXO,0) as SexoConductor
			, AMRGSIM_FEFEC as FechaEfecto
			, m.TipoVeh AS TipoVehiculo
			--Campos de compañía de procedencia
			,S.AMRGSIM_CCIA
			,S.AMRGSIM_ANAN
			,S.AMRGSIM_NPAR
			,COP.AUDACOP_EMPRES_EST
			,COP.AUDACOP_NUMANO_EST
			,COP.AUDACOP_NUMSIN_EST
			,cast(left(replace(amrgsim_fumo,'-',''),20) as datetime)  AS FecEmisionCodigo
			,case when isnull(S.AMRGSIM_TLFN, 0) <> 0 then S.AMRGSIM_TLFN
					else null
			 end Telefono
		from 
			(
			 select  SIM.*
					,ltrim(rtrim(replace(amrgsim_dni,'0X','X'))) as amrgsim_dni2 
					, left(right(amrgsim_coclave,16),3)  as Marca
					, substring(right(amrgsim_coclave,16),4,3)  as Modelo
					, substring(right(amrgsim_coclave,16),7,3)  as SubModelo
					, substring(right(amrgsim_coclave,16),10,3)  as Terminacion
					, right(amrgsim_coclave,4)  as Año
					, PT.AULOIIDSOLIC as 'IdSolicitud'
			 from  dw_autos.dbo.autosregsim SIM WITH(NOLOCK)
			 inner join 
				TMP.XAUTOS_DBO.COTIZACIONES_TMP2 PT with(nolock)
				on 
					PT.AMRGSIM_CODIGO  = SIM.AMRGSIM_CODIGO 
			 ) S
			 
		left join 
			DW_AUTOS.dbo.TAUDACOP COP with(nolock)
			on 
			COP.AUDACOP_ID_RAMO	= 1
			and	COP.AUDACOP_ID_EMPRESA = S.AMRGSIM_EMPR
			and	COP.AUDACOP_ID_SOLICIT = S.IdSolicitud
			and	COP.AUDACOP_ID_RIESGO = 1			
		left join 
			XAUTOS.dbo.MARCAS  m WITH(NOLOCK)	
		on	
				S.Marca = M.marca        AND
				S.Modelo = M.modelo       AND
				S.Submodelo = M.submodelo    AND
				S.Terminacion = M.terminacion AND
				S.Año = M.año  
		left join --para asegurar la integridad con colectivos
			dw_autos..tuccolec TUC WITH(NOLOCK) 
		on	
			s.amrgsim_Coagreg = TUC.uccoidco 
		left join 
			DW_AUTOS..TAPRODUC PC2 
		on 
			PC2.APROPROD = CAST(AMRGSIM_TSEG AS VARCHAR) + AMRGSIM_SUBP 
		left join 
			DW_AUTOS..TAPRODUC PC1 
		on 
			PC1.APROPROD = CAST(AMRGSIM_TSEG AS VARCHAR)
		left join XDIM.autos.ErroresCotizacion ERR (NOLOCK) ON
			AMRGSIM_CODERR = ERR.Cod_Error 
		cross apply comun.dbo.fn_TipoPersona_tbl (amrgsim_dni) F			
			
		) s	

	set @Nregistros=@@rowcount
	set @Msg='Tabla temporal tmp.xautos_dbo.XCotizaciones_Web,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

--		option (recompile)		
	-- 24"
	-- (63955 row(s) affected)
--	select * from tmp.xautos_dbo.XCotizaciones_Web
	
	-- RESTO
	 -- Cotizaciones no web	
	exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.XCotizaciones_Resto'
	
	select 	
	 	  IdCotizacion
		, FecEmision
		, Agregador
		,Tipo 
		,NifTomador
		,TipoPersona
		,CodPostal
		,idModelo
		,Producto
		,CanalEntrada
		,FNacTomador
		,FNacConductor
		,case when tipopersona='J' then 0 else SexoTomador end as 'SexoTomador' --las pj no tienen sexo
		,FRT
		,Descuentos
		,FechaConstruccion
		,ValorVehiculo
		,ValorAccesorios
		,Operador
		,RelacionPresentador
		,Importe
		--,checksum(cast(marca as smallint),cast(modelo as smallint),year(fnactomador),month(fnactomador),cast(codpostal as int),cast(sexotomador as tinyint)) as [checksum]
		--,binary_checksum(cast(marca as smallint),cast(modelo as smallint),year(fnactomador),month(fnactomador),cast(codpostal as int),cast(sexotomador as tinyint)) as [binary_checksum]
		,IdEmpresa   		
		,IdNegocio	
		,GarantiaMecanica
		,case when GarantiaMecanica in ('GM1','GM9') then '3'
		      else '0'
		 end  GarantiaMecanicaFP		
		, 'Y' /*ISNULL(AMRGSIM_PASNF,'Y')*/  PresenciaAsnef
		, 'Y' /*ISNULL(AMRGSIM_RSCOR,'Y')*/  RiskScore
		, 'Y' /*ISNULL(AMRGSIM_SSCOR,'Y')*/  SeverityScore
		, Lunas
		, IdOficina
		, CodErrorCotiz
		, CodAvisoCotiz
		, idSolicitud
		, id15PuntosCarnet	
		, IdFrecuenciaPago
		, IdOcupantes
		, IdUsoVehiculo
		, IdVehiculoNuevo
		, IdSesion
		, SexoConductor
		, FechaEfecto
		, TipoVehiculo
		, CASE WHEN isnull(A.AULOICCIA,0) <> 0 or isnull(A.AULOIANAN,0) <> 0 THEN isnull(A.AULOICCIA,0)
			   ELSE CASE WHEN A.AUDACOP_NUMANO_EST IS NOT NULL THEN A.AUDACOP_EMPRES_EST
						 ELSE A.AULOICCIA
			   END
		  END CompañiaProcedencia
		, CASE WHEN isnull(A.AULOICCIA,0) <> 0 or isnull(A.AULOIANAN,0) <> 0 THEN isnull(A.AULOIANAN,0)
			   ELSE CASE WHEN A.AUDACOP_NUMANO_EST IS NOT NULL THEN A.AUDACOP_NUMANO_EST
						 ELSE A.AULOIANAN
					END
		  END NAñosCompProcedencia
		, CASE WHEN isnull(A.AULOICCIA,0) <> 0 or isnull(A.AULOIANAN,0) <> 0 THEN isnull(A.AULOINPAR,0)
			   ELSE CASE WHEN A.AUDACOP_NUMANO_EST IS NOT NULL THEN A.AUDACOP_NUMSIN_EST
						 ELSE A.AULOINPAR
				    END
		  END NSiniCompProcedencia
		, CASE WHEN isnull(A.AULOICCIA,0) <> 0 or isnull(A.AULOIANAN,0) <> 0 THEN 'T'
			   ELSE CASE WHEN A.AUDACOP_NUMANO_EST IS NOT NULL THEN 'I'
				 		 ELSE CASE WHEN A.AULOICCIA IS NOT NULL or A.AULOIANAN IS NOT NULL THEN 'T' ELSE 'N' END
				    END
		  END OrigenCompProc
		, FecEmision as FecEmisionCodigo
		, Telefono
	into 	
		tmp.xautos_dbo.XCotizaciones_Resto				
	
	from 
		(
	
	select 																
		 C1.IdCotizacion 
		,cast(left(replace(C1.AULOIFEMI,'-',''),20) as datetime) as FecEmision
		,cast(NULL  as varchar(10))as Agregador
		, C1.AULOISITU AS Tipo -- N=>Nueva cotización, U=>Cotización a Presupuesto, S=>Cotización a Póliza, P=> Presupuesto a Póliza
		, CAST(CASE
				WHEN C1.AULOINIFT IS NULL THEN
					CASE WHEN C1.AULOIRPOL > 0 THEN '#'+LEFT(CAST(C1.AULOIRPOL AS VARCHAR), 9)
					ELSE '#'+LEFT(CAST(C1.ID AS VARCHAR), 9)
					END
				ELSE C1.AULOINIFT
			END AS VARCHAR(10)) AS NifTomador -- NIF DEL TOMADOR COTIZACIÓN
			--,comun.dbo.fn_TipoPersona(C1.AULOINIFT)  as TipoPersona      --
		, F.TipoPersona  as TipoPersona
		, CAST(C1.AULOICPOS AS VARCHAR(5))AS CodPostal -- CODIGO POSTAL COTIZACIÓN
		, M.Id as Idmodelo
		--, C1.Producto		
		,(select  producto from DW_AUTOS..fn_autos_productos (AULOIEMPR, AULOITSEG, LEFT(AULOIPVIP,1), AULOISUBP, AULOIFTIP, AULOIPTOT, AULOIRCCA, AULOIASIS, AULOIDEFE, AULOILURI, AULOITIPV, AULOIFEMI,AUSOPRO_ID_PROD_BA,AUSOPRO_ID_PROD_PE)) as Producto
		, CASE WHEN C1.AULOICOLE = 'AGRE0021' THEN 'L' 
		       ELSE C1.AULOICANA 
		  END AS CanalEntrada -- CANAL DE CONTRATACION
		                      -- Canal MOBILE para el negocio AGRE0021
		,CASE 
				WHEN ISDATE(C1.AULOIFNAT)=1 AND ( LEFT(CONVERT(VARCHAR,C1.AULOIFNAT),4)<'1901' OR LEFT(CONVERT(VARCHAR,C1.AULOIFNAT),4)>'2079') THEN NULL
				WHEN ISDATE(C1.AULOIFNAT)=1 THEN C1.AULOIFNAT
				ELSE NULL 
			END AS FNacTomador -- FECHA NACIMIENTO TOMADOR
		, CASE 		
				WHEN ISDATE(C1.AULOIFNAC)=1 AND (LEFT(CONVERT(VARCHAR,C1.AULOIFNAC),4)<'1901'or LEFT(CONVERT(VARCHAR,C1.AULOIFNAC),4)>'2079') THEN NULL 
				WHEN ISDATE(C1.AULOIFNAC)=1 THEN C1.AULOIFNAC
			ELSE NULL
			END AS FNacConductor -- FECHA NACIMIENTO CONDUCTOR
		, C1.AULOISEXT AS SexoTomador -- SEXO DE TOMADOR
		,cast(Case 
			when C1.AULOIFCCO is null or C1.AULOIFCCO<190101 Then Null
			else left(convert(varchar,C1.AULOIFCCO),6)+'15'
		end as date) AS FRT -- FECHA CARNET DE CONDUCIR
		, CASE 
			WHEN C1.AULOIRELD = 'Z' THEN '0'
			ELSE C1.AULOIRELD
		END as Descuentos	-- RELACION DE DESCUENTOS				
		,cast(Case 
				when C1.AULOIACON is null or C1.AULOIACON<1901 then Null
				else cast(C1.AULOIACON*10000+ 101 as varchar)
			End as date) AS FechaConstruccion -- FECHA CONSTRUCCION VEHICULO
		
		,	 CASE	
			--WHEN C1.AULOIVALO = 0 THEN ISNULL(NULLIF((select M.valor from XAutos.dbo.marcas m WITH(NOLOCK) where C1.IdMarca = M.Id)  ,10000000),0)
			WHEN C1.AULOIVALO = 0 THEN ISNULL(NULLIF(M.valor,10000000),0)
			ELSE C1.AULOIVALO 
		  END AS ValorVehiculo
		, C1.AULOIVACC AS ValorAccesorios -- VALOR DE ACCESORIOS
		, C1.AULOIUUMO AS Operador
		, C1.AULOIRELA AS RelacionPresentador
		, C1.AULOIIMRE AS Importe
		, CASE C1.AULOIEMPR  -- Hemos encontrado empresas con valores distintos a 1 y 3
			WHEN 3 THEN C1.AULOIEMPR
			ELSE 1 
		  END AS IdEmpresa

		, isnull(substring(isnull(PC2.aprogara,PC1.aprogara),4,1),'N') as Lunas
		, isnull(PC2.aproprod,isnull(PC1.aproprod,'ZZ')) as ProProducto
		, ISNULL(TUC.uccoidco, '0') as IdNegocio
		, ISNULL(C1.AULOIGARM,'') AS GarantiaMecanica
		, CASE WHEN ISNULL(AUDACOT_ASNEF,'Y')='0' THEN 'Y' ELSE ISNULL(AUDACOT_ASNEF,'Y') END AMRGSIM_PASNF
		, case when ISNULL(AUDACOT_RISK_SCORE,'Y')='' then 'Y' else ISNULL(AUDACOT_RISK_SCORE,'Y') END AMRGSIM_RSCOR
		, CASE WHEN ISNULL(AUDACOT_SEVERITY_CODE,'Y')in ('N','0','00') THEN 'Y' ELSE ISNULL(AUDACOT_SEVERITY_CODE,'Y') END AMRGSIM_SSCOR
		, AULOIPTORED						as 'idOficina'
		, 0									as 'CodErrorCotiz'
		, 0									as 'CodAvisoCotiz'
		, isnull(C1.AULOIIDSOLIC, 0)		as 'idSolicitud'
		, isnull(COP.AUDACOP_NUM_PUNTOS, 0)	as 'id15PuntosCarnet'
		, AULOIFPGA		AS 'IdFrecuenciaPago'
		, AULOICOMB		AS 'IdOcupantes'
		, AULOITUSO		AS 'IdUsoVehiculo'
		, AULOIWSWNU	AS 'IdVehiculoNuevo'
		, C1.AULOICCOT	AS 'IdSesion'
		, case when isnull(AULOISEXC,0) IN (5,6) then 0 else isnull(AULOISEXC,0)end as SexoConductor
		, AULOIFEFE as FechaEfecto 
		, m.TipoVeh AS TipoVehiculo
		--Campos compañía de procedencia
		,C1.AULOICCIA
		,C1.AULOIANAN
		,C1.AULOINPAR 
		,COP.AUDACOP_EMPRES_EST
		,COP.AUDACOP_NUMANO_EST
		,COP.AUDACOP_NUMSIN_EST		
		,case when isnull(TCO.AUDACOT_TLFN_1, 0) <> 0 then TCO.AUDACOT_TLFN_1
			  when isnull(TCO.AUDACOT_TLFN_2, 0) <> 0 then TCO.AUDACOT_TLFN_2
			  else null
		 end Telefono

	from
		DW_AUTOS.dbo.TAULOIPR			 C1 WITH(NOLOCK) 
		OUTER APPLY 
		(
			SELECT TOP 1 AUSOPRO_ID_PROD_BA
						,AUSOPRO_ID_PROD_PE
			FROM DW_AUTOS.DBO.TAUSOPRO TAU WITH (NOLOCK)
			WHERE C1.AULOIIDSOLIC  = TAU.AUSOPRO_ID_SOLICIT
			AND C1.AULOIEMPR   = TAU.AUSOPRO_ID_EMPRESA
			AND TAU.AUSOPRO_ID_RAMO = 1
		) OA
	inner join
		TMP.XAUTOS_DBO.COTIZACIONES_TMP  PT with(nolock)
		on
			PT.IDCOTIZACION = C1.IDCOTIZACION
			/*
		left join 
			tmp.xautos_dbo.XCotizaciones0 xc0 
		on 
			c1.AULOICCOT = xc0.AMRGSIM_COCOTIZ
			*/
		left join 
			DW_AUTOS.dbo.TAUDACOP COP with(nolock)
			on 
			COP.AUDACOP_ID_RAMO	= 1
			and	COP.AUDACOP_ID_EMPRESA = C1.AULOIEMPR
			and	COP.AUDACOP_ID_SOLICIT = C1.AULOIIDSOLIC
			and	COP.AUDACOP_ID_RIESGO = 1			
		LEFT OUTER JOIN 
			XAUTOS.dbo.MARCAS M WITH(NOLOCK) 
		ON 
				C1.AULOINMAR = M.marca        AND
				C1.AULOINMOD = M.modelo       AND
				C1.AULOINSUB = M.submodelo    AND
				C1.AULOINTER = M.terminacion AND
				C1.AULOINANU = M.año  
		left join --para asegurar la integridad con colectivos
			dw_autos..tuccolec TUC WITH(NOLOCK) 
		on 
			C1.AULOICOLE = TUC.uccoidco 
		left join 
			DW_AUTOS..TAPRODUC PC2 
		on 
			PC2.APROPROD = CAST(AULOITSEG AS VARCHAR) + AULOISUBP 
		left join 
			DW_AUTOS..TAPRODUC PC1 
		on 
			PC1.APROPROD = CAST(AULOITSEG AS VARCHAR)
		cross apply comun.dbo.fn_TipoPersona_tbl (C1.AULOINIFT) F
		
		--campos ASNEF
		left join 
			dw_autos.dbo.TAUDACOT TCO WITH(NOLOCK) 
		ON C1.AULOIIDSOLIC =TCO.AUDACOT_ID_SOLICIT
			AND C1.AULOIEMPR =TCO.AUDACOT_ID_EMPRESA
			AND TCO.AUDACOT_ID_RAMO=1
	Where 
			-- Las cotizaciones nuevas pueden tener situación = 'N', 'S' ó 'U' y la póliza (AULOIRPOL) sin informar.
			-- Las cotizaciones de suplementos tienen situación = 'N' ó 'M' y la póliza  (AULOIRPOL)  informada.
			-- 'N' => COTIZACION NUEVA,'S' => PASO DE COTIZACIÓN A POLIZA,'U' => PASO DE COTIZACIÓN A PRESUPUESTO , 'P'=> Presupuesto a Póliza ----- los U y los S se hace update sobre el N
			(c1.AULOISITU IN ('S','U') OR (c1.AULOISITU = 'N' AND c1.AULOIRPOL = 0))
			and AULOICANA <>'W'		
		) A
		
	set @Nregistros=@@rowcount
	set @Msg='Tabla temporal tmp.xautos_dbo.XCotizaciones_Resto,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

		exec comun.dbo.EliminaTabla 'tmp.xautos_dbo.XCotizaciones'
		
		select 
			A.*
		 , getdate() as 'F_carga'
		
		into 
		
				TMP.xautos_dbo.XCotizaciones		 		 
		from 
			(		
			select  
				* 			
	
			from 
				TMP.xautos_dbo.XCotizaciones_Web with(nolock)			
			union all 		
			select
			*
			from 
				TMP.xautos_dbo.XCotizaciones_Resto with(nolock)			
			) A


   set @Nregistros=@@rowcount


	set @Msg='Tabla temporal tmp.xautos_dbo.XCotizaciones,generada: '+cast(@nregistros as varchar(9))+' registros'
	exec Comun..Logar 'XAUTOS','XCotizaciones',@Msg,'C','M',2

--64460

*/
 	
	--create unique index ix1 on TMP.xautos_dbo.XCotizaciones222(idcotizacion)


 	return(@@rowcount)
	
	

	