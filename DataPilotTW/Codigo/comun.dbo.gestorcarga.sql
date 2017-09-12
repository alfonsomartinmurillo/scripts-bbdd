


CREATE PROCEDURE [dbo].[GestorCarga]
		@BdArEnt varchar(300),
		@Nfilas int=0,
		@MascaraCarga varchar(15)=null,
		@TiempoEspera int=null,
		@ParamComodin varchar(4000) = '',
		@StgParamComodin varchar(1000) = '',
		@ModoLogar int = 1,
		@Test int=0
AS

/*-------------------------------------------------------------------------------
DESCRIPCION:
Realiza la carga al staging y al dwh de la base de datos, area, entidad
o tabla pasada por parametros.
-------------------------------------------------------------------------------
CREADO POR: Jesus Gomez 10/08/2004 
-------------------------------------------------------------------------------
MODIFICADO POR:
		Jesus Gomez 10/08/2005 Añadido el parametro TiempoEspera
		Jesus Gomez 07/11/2005 Sacado fuera del procedimiento el calculo 
			de entidades a cargar.
		Ivan Alonso 27/01/2009 Se modifica porque el el tiempo de espera
			no lo calcula este procedimiento sino que es el propio gestorcargastg
			quien determina el tiempo de espera ya que es este el que saber realmente
			el tiempo empleado en la espera de la existencia del fichero.
	   Ivan Alonso 29/09/2011 Se modifica para crear un parametro Comodin que sera
	      pasado al gestorCargaDwh tal cual
	   Ivan Alonso 20/04/2015 Se modifica para crar un parametro comodin que sera
	      pasado al gestorcargastg tal cual.
	   Ivan Alono 04/06/2015 Se modifica para quitar el pathindex cuando se busca
	      la tabla stg en cfg_staging basado en la lista de tablas staging escrita
	      en la tabla cfg_datawarehouse
      Ivan Alonso 21/06/2017 Se modifica para incluir control en el cursor cr_dwh
         ya que cuando se crea dicho cursor siempre deberia tener datos y, de vez en cuando,
         este cursor queda vacio y provoca que no se cargue ninguna entidad y la carga
         finaliza OK. Se revisa que el primer fetch ha finalizado OK (@@error = 0) y despues 
         que este primer fetch devuelve datos, en el caso en que el primer fetch no finalize
         OK o bien este primer fetch no devuelva datos se finaliza con error la ejecucion.
-------------------------------------------------------------------------------
ENTRADAS:
@BdArEnt: BaseDatos,area y/o entidad que cargar separados por puntos
	BaseDatos{.BaseDatos|.Area|..Entidad|..Tabla}[-ModoCarga]
	Ej: 'dw_mma': carga la base de datos dw_mma
	Ej: 'dw_mma.siniestros,D': carga el area de siniestros segun el modo D (0 para aquellas entidades sin modo D)
	Ej: 'dw_mma..polizas': carga la entidad polizas
	Ej: 'dw_mma..poliza_fija': carga la tabla poliza_fija de la entidad polizas
	El modo de carga especifica de que manera de las especificadas en cfg_datawarehouse
	queremos cargar. En caso de ser una llamada multiple se intentará cargar
	segun el modo especificado, el procedimiento considera modo por defecto el mas bajo
	de la llamada.
@Nfilas: Modo de carga
	-1: Realiza una carga de prueba sin logar nada por pantalla
	 0: Realiza la carga normal logando por pantalla y tabla
	 N: Carga N filas solamente tanto al Staging como al Dwh logando por pantalla
	 
@MascaraCarga(opcional): mascara de ocho unos y ceros, pasos a seguir en la carga
	bit 1: traspaso a la Statig
	bit 2: traspaso a la tmp
	bit 3: ejecucion de los parches en la tmp
	bit 4: checkeo de codigos
	bit 5: checkeo de Integridad referencial
	bit 6: traspaso a la checkerror
	bit 7: traspaso a las tablas finales
	bit 8: truncado de las tmps
@TiempoEspera: Tiempo maximo que el procedimiento esperará a que aparezcan todos los
	ficheros necesarios para la carga en sus correspondientes directorios
	(null o cero no espera nada).
@ParamComodin: Parametro que es pasado al gestorcargadwh.
@StgParamComodin: Parametro que es pasado al gestorcargastg
@Test: Imprime la cadena a ejecutar en vez de ejecutarla
-------------------------------------------------------------------------------
SALIDAS:
-------------------------------------------------------------------------------
OBSERVACIONES:
Si se ejecuta para cargar una sola tabla no se tiene en cuenta el activo o forzar
Comprueba los ficheros de carga antes de la ejecución si esta especificado en cfg_general
-------------------------------------------------------------------------------*/
/*
DECLARE @BdArEnt varchar(300),@Nfilas int,@MascaraCarga varchar(15),@Test int,@TiempoEspera  int
set @BDARENT='DW_MUTUACTIVOS.FONDOS'
set @MascaraCarga=null
set @Nfilas=null
set @TiempoEspera=1800
set @test=1
*/


/*Declaracion  de variables*/
	SET LANGUAGE Spanish
	---------------------------------------------------------------
	-- MODIFICADO POR: 
	-- Gabriel Arenovich (Teampro) 22/05/2007
	-- Forzamos que se utilice el formato de fecha DD/MM/YYYY
	----------------------------------------------------------------
	SET DATEFORMAT dmy
	----------------------------------------------------------------
	--set transaction isolation level read uncommitted
	--SET TRANSACTION ISOLATION LEVEL SNAPSHOT
	----------------------------------------------------------------

	set nocount on
	set XACT_ABORT on
	declare @EntidadesCarga table (RutaEntidad varchar(400),TablaStg varchar(1000),ModoCarga tinyint)
	declare @EntidadesCargaOrdenadas table (Orden int,RutaEntidad varchar(200),SubArea varchar(100),TablaStg varchar(1000),ModoCarga varchar(3))
	declare @cad varchar(2000), @logar2 int,@logar1 int,@Msg varchar(500),@NumeroEntidadesCargarDespues int
	declare @HoraInicioGlobal datetime, @HoraInicioSTG datetime, @HoraInicioDWH datetime
	declare @TablaStg varchar(1000),@RutaEntidad varchar(200),@EntidadLogSTG varchar(200),@EntidadLogDWH varchar(200)
	declare @BdStaging varchar(50),@NfilasStr varchar(100),@error int,@error2 int
	declare @Basedatos varchar(100),@SubArea varchar(100),@Entidad varchar(100)
	declare @OrdenarAreas int,@FechaInsertados datetime
	declare @Modocarga varchar(5),@ModoCargaEntidad varchar(3),@TiempoEsperaStg int,@BdArEnt2 varchar(400)
	declare @PrefijoFichero varchar(100),@MoverFichero varchar(1)
/*Inicializacion de variables*/
   set @ParamComodin = ISNULL(@ParamComodin,'')
   set @StgParamComodin = ISNULL(@StgParamComodin,'')
   set @StgParamComodin = ISNULL(@StgParamComodin,'')
   set @ModoLogar = ISNULL(@ModoLogar,1)
	/*Si se ha especificado algun modo de carga en la llamada lo capturamos*/
	if patindex('%-%',@BdArEnt)<>0
	begin
		set @ModoCarga=substring(@BdArEnt,patindex('%-%',@BdArEnt)+1,12)
	 	set @BdArEnt2=left(@BdArEnt,patindex('%-%',@BdArEnt)-1)
	end
	else 
	begin
		set @ModoCarga='0'
		set @BdArEnt2=@BdArEnt
	end
	/*Separamos la ruta pasada como parametros en sus tres componentes	*/
	exec SepararRutaTriple @BdArEnt2,@BaseDatos out,@SubArea out,@Entidad out
	if @SubArea='' set @SubArea='%'
	if @Entidad='' set @Entidad='%'
	/*permitimos algunos parametros nulos o vacios para facilitar la llamada */
	if @MascaraCarga='' or @MascaraCarga is null set @MascaraCarga=dbo.GetVariableCfg('MascaraCargaDefecto')
	if @Nfilas is null set @Nfilas=0
	IF @TiempoEspera is null set @TiempoEspera=0
	set @TiempoEsperaStg = @TiempoEspera
	/*Cargamos la opcion de ordenar areas*/
	if dbo.GetVariableCfg('OrdenarAreas')='SI' 
		set @OrdenarAreas=1
	else 
		set @OrdenarAreas=0
	
	/*Cargamos el nombre de la base de datos de staging*/
	set @BdStaging=dbo.GetVariableCfg('NombreBdStaging')
	
	/*Establecemos dos grupos de log, uno loga siempre y el otro solo logará cuando se trate de una entidad
	Esta diferencia es para pantalla, en tabla se logara todo*/
	
	if @test=1
		begin	
			set @logar2=0
			set @TiempoEspera=0
		end
	else
		begin
			if @Nfilas<0 /*modo prueba silencioso*/
			begin
				set @logar1=-1 /*no loga nada*/
				set @logar2=-1 /*no loga nada*/
			end
			if @Nfilas=0 or @Nfilas is null	/*modo normal*/
			begin	
				set @logar1=isnull(@ModoLogar,1)
				if @ModoLogar = 3 set @Logar2=3
				else if dbo.GetVariableCfg ('LogadoPantallaCargasMinimo')='SI' set @logar2=2 else set @logar2=1
			end
			if @Nfilas>0
			begin
				set @logar1=0
				set @logar2=0
			end
		end
	set @error=0
	set @error2=0
	set @NfilasStr=cast(@Nfilas as varchar(100))
	
	/*Declaramos una variable para la entidad con la que logamos, ya que solo una
	carga total debe logar con GENERAL*/
	if @SubArea='%' and @Entidad='%'
	 begin
		set @EntidadLogSTG='GENERAL-'+@BaseDatos
		set @EntidadLogDWH='GENERAL'
	 end
	else 
	 begin
			set @EntidadLogSTG='CARGA'
			set @EntidadLogDWH='CARGA'
	 end
/*Comprobacion de errores*/
	/*Comprobacion de errores en la mascara*/


	if len(@MascaraCarga)<>10
	begin
		set @msg='ERROR/*-La mascara de carga debe ser de longitud 10'
		exec Logar 'GENERAL' ,'Gestorcarga',@msg,'C','E',@logar1
		raiserror('%s',18,1,@msg)
		return(-1)
	end
/*Creamos una tabla con las entidades que tenemos que cargar*/
	insert into @EntidadesCarga 
	select distinct RutaEntidad,TablaStg,ModoCarga from dbo.GC_ListadoEntidadesCargarDwh(@BdArEnt)
	set @NumeroEntidadesCargarDespues=@@Rowcount
/*Comprobamos si se ha devuelto error en la funcion de ListadoEntidadesCargar*/
	select @Msg=RutaEntidad from @EntidadesCarga
	if @Msg like 'ERROR%' 
	begin
		exec Logar 'GENERAL','GestorCarga',@Msg,'C','E',@logar1
		raiserror('%s',18,1,@msg)
		return(-1)
	end
/*Logado del inicio global*/
	set @Msg='Iniciada carga global de '+@BdArEnt+'('+cast(@NumeroEntidadesCargarDespues as varchar(3))+' Entidades)'
	exec Logar 'GENERAL','CARGA',@Msg,'C','I',@logar1
	set @HoraInicioGlobal=getdate()
/*Comprobamos que los ficheros de entrada son correctos, para ello volvemos a llamar a este
mismo proceso pero indicandole que es una carga de prueba al staging y que no debe logar nada
el proceso esperara lo indicado por parametros, si el proceso sigue una vez hecho esta comprobacion
es pq estan todos los ficheros luego en la llamada real aunque pongamos tiempo de espera no 
sera necesario esperar. 
*/
	if left(@MascaraCarga,1)='1' and @Nfilas=0 and dbo.GetVariableCfg('ComprobarFicherosCarga')='SI' 
		and @NumeroEntidadesCargarDespues>1 and @test=0
	begin
      set @Msg='Iniciada Comprobacion ficheros de '+@BdArEnt+'('+cast(@NumeroEntidadesCargarDespues as varchar(3))+' Entidades)'
      exec Logar 'GENERAL','CARGA',@Msg,'C','I',@logar1
		exec @error=GestorCarga  @BdArEnt,-1,'1000000000',@TiempoEspera,0,@StgParamComodin = @StgParamComodin
		if @error<>0 
		begin 
		 if @error=3 
			set @msg='ERROR -Se sobrepaso el tiempo de espera para los ficheros de entrada'
		 else 
			set @msg='ERROR -La prueba previa no se realizó correctamente ERROR:'+cast(@error as varchar(9))
			 exec Logar 'GENERAL','GestorCarga',@Msg,'C','E',@logar2
		 raiserror('%s',18,1,@msg)
		 return(-1)
		end
	end
/*Llamamos al procedimiento que nos genera el orden y insertamos los datos en nuestra tabla
Este procedimiento nos deja los datos en la tabla OrdenCarga. No podemos coger los datos
con insert exec, ya que no se permite el anidamiento de insert exec y el procedimiento dentro
ya tienen uno*/
   set @Msg='Dando orden a la carga de '+@BdArEnt+'('+cast(@NumeroEntidadesCargarDespues as varchar(3))+' Entidades)'
   exec Logar 'GENERAL','CARGA',@Msg,'C','I',@logar1

	exec OrdenCargaArea @BaseDatos,@SubArea,@Entidad,@OrdenarAreas,0,@FechaInsertados out
/*Unimos la tabla de entidades a cargar con la del orden para seleccionar sólo las entidades
que queremos cargar en orden*/
	insert into @EntidadesCargaOrdenadas
	select distinct 
		O.Orden,O.RutaEntidad,O.SubArea,E.TablaStg,E.ModoCarga
	from 
		@EntidadesCarga E
	inner join 
		(select * from OrdenCarga with (nolock) where FechaInserccion=@FechaInsertados) o
	on 
		E.RutaEntidad=O.RutaEntidad
	order by 
		O.orden
/*Borramos de la tabla de orden carga nuestros registros*/
--	delete from OrdenCarga where FechaInserccion=@FechaInsertados
---	begin try
	   delete from OrdenCarga where FechaInserccion=@FechaInsertados
   --end try
   --begin catch
   --   IF ERROR_NUMBER() = 1205 -- Deadlock Error Number
	  -- BEGIN
		 --  set @Msg='##### WARNING: Despues de haber dado orden a la carga: ' +  @BdArEnt + '(' + @BaseDatos + '.' + @SubArea + '.' + @Entidad + '.' + convert(varchar,@OrdenarAreas) + ') Deadlock en Delete.'
   --      exec Logar 'GENERAL','CARGA',@Msg,'C','W',@logar1
		 --  WAITFOR DELAY '00:00:0.05'
		 --  begin try
		 --     delete from OrdenCarga where FechaInserccion=@FechaInsertados
		 --  end try
		 --  begin catch
		 --     IF ERROR_NUMBER() = 1205
		 --     begin
		 --        set @Msg='##### WARNING: Despues de haber dado orden a la carga: ' +  @BaseDatos + '.' + @SubArea + '.' + @Entidad + '.' + convert(varchar,@OrdenarAreas) + ' por segunda vez Deadlock en Delete y no se vuelve a realizar.'
   --            exec Logar 'GENERAL','CARGA',@Msg,'C','W',@logar1
		 --     end
		 --  end catch
	  -- END
   --end catch
   set transaction isolation level read uncommitted
   set @Msg='Dando orden a la carga de '+@BdArEnt+'('+cast(@NumeroEntidadesCargarDespues as varchar(3))+' Entidades)'
   exec Logar 'GENERAL','CARGA',@Msg,'C','I',@logar1
/*Vamos a cargar el Staging completo*/
	if left(@MascaraCarga,1)='1' and (select count(*) from @EntidadesCargaOrdenadas where TablaStg is not null)>0
	begin
	/*Logado del inicio del staging*/
		set @Msg='Iniciada carga al Staging de '+@BdArEnt+'('+cast(@NumeroEntidadesCargarDespues as varchar(3))+' Entidades)'
		exec Logar @BdStaging,@EntidadLogSTG,@Msg,'C','I',@logar2
		set @HoraInicioSTG=getdate()
		set @Cad=''
	/*Para los access o excel necesitamos saber cuando se carga la ultima tabla del mismo origen, para
	decirle al gestorcargastg que lo mueva. Almacenaremos en una tabla que ficheros se necesitan para
	cargar, y solo la ultima llamada para cada fichero de entrada le dira al gestor de carga que debe
	mover el fichero*/

	declare @PrefijosFichero table(TablaStg varchar(128),PrefijoFichero varchar(4000),orden int,cargado bit)
	insert into @PrefijosFichero
	select s.tablastg,left(s.PrefijoFichero,case when s.prefijofichero like '%(%)%' then charindex('(',s.prefijofichero)-1 else len(s.prefijofichero) end),min(orden),0
	from @EntidadesCargaOrdenadas  e
   outer APPLY (SELECT ltrim(rtrim(valor)) as TablaStg from comun.dbo.ConvertirCadenaATabla(e.tablastg,',')) b -- Se incluye este cross apply para separar tablastg de @EntidadesCargaOrdenadas en sus distintas tablas
   inner join cfg_staging s
	--on patindex('%'+s.tablastg+',%',e.TablaStg+',')<>0
	on isnull(b.tablastg,e.TablaStg)= s.TablaStg -- quiamos el pahindex por la igualdad ya que la en cg_datawaehouse se escriben las tablas staging (nombre clompleto) de las que depende por lo que una vez separada la lista de tablas staging escrita en cfg_datawarehouse debe ser igual a cfg_staging una a una.
	--on patindex('%'+isnull(b.tablastg,e.TablaStg)+',%',s.TablaStg+',')<>0 -- Con este cambio la que manda es @EntidadesCargaOrdenadas ya que se busca en cfg_staging la tabla que coincida con tablastg de @EntidadesCargaOrdenadas y se deja comentada la linea anterior que es la original
	where e.TablaStg is not null
	group by s.tablastg,s.prefijofichero
	order by min(orden)
 
	/*Creamos un cursor que compondrá una cadena con todas las llamadas al gestorCargaStg
	no llamamos directamente para poder comprobar antes si existen todos los ficheros a cargar*/
		declare cr_stg cursor for 
			select tablaSTG,PrefijoFichero
			from @PrefijosFichero
			order by orden,tablaSTG 
		open cr_stg
		
		/*Recorremos el cursor	*/
		fetch next from cr_stg into @TablaStg,@PrefijoFichero
		while @@fetch_status<>-1 
		begin
			/*Ejecutamos el gestor de carga al staging, pasamos el tiempo de espera siempre, ya que 
			pueden ocurrir dos situaciones: 1 que se esperó ya en la prueba y se pasó con lo que 
			ahora aunque pasemos tiempo de espera no se esperará realmente ya que estan todos los 
			ficheros, y 2 que no se hiciera la prueba por lo que debemos esperar aqui.
			*/
			--Calculamos si el fichero necesario para esta tabla se necesitara luego para decirle
			--al gestorcargastg que no lo mueva
			if @Nfilas<>0 or exists(select * from @PrefijosFichero where cargado=0 and PrefijoFichero=@PrefijoFichero and tablastg<>@TablaStg) 
				set @MoverFichero='0'
			else 
				set @MoverFichero='1'
			if @Test=0 
			begin		
				--decrementamos el tiempo permitido de espera para cada fichero en lo ya 
				--esperado anteriormente
				/*
				** Modificacion IAM - 27/01/2009
				** El tiempo de espera, como es para esperar a la existencia del fichero a cargar, ya no se calcula
				** en estas lineas, el tiempo de espera que queda lo determina el propio gestorcargastg y lo decrementa
				** en el tiempo real que ha estado esperando a la existencia de dicho fichero
				*/
--				if @TiempoEspera<>0
--					set @TiempoEsperaStg=@TiempoEspera-datediff(second,@HoraInicioSTG,getdate())
--				else 
--					set @TiempoEsperaStg=0
				
				if @TiempoEsperaStg>=0
				begin
					set @Msg='LLamamos a al gestorcargastg ' +@TablaStg + ',' + convert(varchar,@nfilas) + ',' + convert(varchar,@TiempoEsperaStg) + ',' + convert(varchar,@MoverFichero)
					exec Logar @BdStaging,@EntidadLogSTG,@Msg,'C','M',@logar2
					exec @error2=GestorCargaStg @TablaStg,@nfilas,@TiempoEsperaStg output,@MoverFichero,@ModoLogar=@ModoLogar,@StgParamComodin = @StgParamComodin
					--set @TiempoEsperaStg=@TiempoEspera
					if @error2>@Error set @Error=@Error2 --devolvemos el mayor de los errores encontrados
				end
				else
				begin
					set @Msg=' ################### ERROR: Se ha excedido el tiempo de espera para llamar al siguiente fichero ###################'
					exec Logar @BdStaging,@EntidadLogSTG,@Msg,'C','M',@logar2
				end
			end
			else 
				print('exec GestorCargaStg '''+@TablaStg+''','+@nfilasStr+','+cast(@TiempoEspera as varchar(5))+','+@MoverFichero + ',@ModoLogar=' + convert(varchar,@ModoLogar)) + ',@StgParamComodin = ''' + replace(@StgParamComodin,'''','''''') + ''''
			
			--Actualizamos la tabla de prefijos para marcar la entidad cargada
			update @PrefijosFichero set cargado=1 where tablastg=@TablaStg
		
			/*Avanzamos el cursor*/
			fetch next from cr_stg into @TablaStg,@PrefijoFichero
			-- Comprobamos si se ha ejecutado correctamente el fetch, en caso contrario logamos el error
			if @@error <> 0
			begin
				set @Msg='##############################  ERROR - Imposible ir al Siguiente registro del cursor cr_stg. Ultimos valores Leidos -> @TablaStg: ''' + @TablaStg + ''', @PrefijoFichero: ''' + @PrefijoFichero + '''  ##############################'
				exec Logar @BdStaging,@EntidadLogSTG,@Msg,'C','E',@logar2
			end	
		end	
	/*Eliminamos el cursor del staging*/
		close cr_stg
		deallocate cr_stg
	/*Logado del fin del staging*/
		set @Msg='Finalizada carga al Staging de '+@BdArEnt+'('+cast(@NumeroEntidadesCargarDespues as varchar(3))+' Entidades) en '+dbo.TimeToStr(datediff(second,@HoraInicioSTG,getdate()))
		exec Logar @BdStaging,@EntidadLogSTG,@Msg,'C','F',@logar1
	end
/*Vamos a cargar el Datawarehouse*/
	if cast(right(@MascaraCarga,9) as int)>0 and @error=0
	begin
	/*Logado del inicio del DWH*/
		set @Msg='Iniciada carga a DWH de '+@BdArEnt+'('+cast(@NumeroEntidadesCargarDespues as varchar(3))+' Entidades)'
		exec Logar @BaseDatos,@EntidadLogDwh,@Msg,'C','I',@logar2
		set @HoraInicioDWH=getdate()
	/*Declaramos un cursor para ir cargando una a una cada entidad al DWH*/
		declare cr_dwh cursor for 
			select RutaEntidad,ModoCarga
			from @EntidadesCargaOrdenadas 
			order by orden
		open cr_dwh
	/*Recorremos el cursor	*/
      -- En este punto el cursor deberia estar lleno ya que se supone que se han detectado tablas a cargar al dwh, si al hacer
      -- fech resulta que el cursor esta vacio provocamos error. Primero comprobamos errores en el fecth (@@error) y despues
      -- verificamos que el primer fetch devuelve datos.
		fetch next from cr_dwh into @RutaEntidad,@ModoCargaEntidad
      if @@error != 0
      begin
	      close cr_dwh
	      deallocate cr_dwh
         set @Msg = 'No ha sido posible hacer fech al cursor utilizado para la llamada al gestorcargadwh (cr_dwh).'
		   exec Logar @BaseDatos,@EntidadLogDwh,@Msg,'C','E',@logar2
         raiserror(@Msg,18,1)
         return(-1)
      end
      if @@fetch_status = -1
      begin
         close cr_dwh
	      deallocate cr_dwh
         set @Msg = 'No se han detectado entidades a cargar para llamar al gestorcargadwh (cr_dwh).'
		   exec Logar @BaseDatos,@EntidadLogDwh,@Msg,'C','E',@logar2
         raiserror(@Msg,18,1)
         return(-1)
      end
	
		while @@fetch_status<>-1 
			begin
				/*Llamamos al gestor de carga al Dwh*/
				set @cad='exec GestorCargaDwh '''+@RutaEntidad+'-'+@ModoCargaEntidad+''','+@nfilasStr+ ',@ParamComodin = ''' + @ParamComodin + ''', @ModoLogar = ' + CONVERT(varchar,@ModoLogar)--+','''+right(@MascaraCarga,9)+''''
				if @Test=0 exec(@cad) else print(@cad)
				/*Avanzamos el cursor*/
				fetch next from cr_dwh into @RutaEntidad,@ModoCargaEntidad
			end	
	
		/*Eliminamos el cursor del dwh*/
		close cr_dwh
		deallocate cr_dwh
		/*Logado del fin del dwh*/
		set @Msg='Finalizada carga a DWH de '+@BdArEnt+'('+cast(@NumeroEntidadesCargarDespues as varchar(3))+' Entidades) en '+dbo.TimeToStr(datediff(second,@HoraInicioDWH,getdate()))
		exec Logar @BaseDatos,@EntidadLogDwh,@Msg,'C','F',@logar1
	end
/*Logado del final de la carga global*/
	set @Msg='Finalizada carga global de '+@BdArEnt+'('+cast(@NumeroEntidadesCargarDespues as varchar(3))+' Entidades) en '+dbo.TimeToStr(datediff(second,@HoraInicioGlobal,getdate()))
	exec Logar 'GENERAL','CARGA',@Msg,'C','F',@logar1
/*Devolvemos si hay error*/
	set @Msg='Return (@error), @error = ' + CONVERT(varchar,@error)
	exec Logar 'GENERAL','CARGA',@Msg,'C','F',@logar1
	return(@error)



