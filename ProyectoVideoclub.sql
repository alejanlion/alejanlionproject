--Programa Principal
DECLARE
opcion NUMBER:= &opcion;
BEGIN
CASE
    WHEN (opcion=1) THEN
         DBMS_OUTPUT.PUT_LINE('Auditoria de alquileres de peliculas.');
         auditoria_alquiler;
    WHEN (opcion=2) THEN
         DBMS_OUTPUT.PUT_LINE('Alquilar pelicula:  ');
         alquilar_pelicula(1,10,'27/04/2021',100);
    WHEN(opcion=3) THEN
         DBMS_OUTPUT.PUT_LINE('Devolver pelicula: ');
         devolver_pelicula(1,10,30);
    WHEN(opcion=4) THEN
         DBMS_OUTPUT.PUT_LINE('Crear cliente: ');
         IF crear_cliente('232344','Jorge','Calle',3234242) THEN
             DBMS_OUTPUT.PUT_LINE('El cliente ha sido insertado.');
         ELSE
             DBMS_OUTPUT.PUT_LINE('El cliente no ha sido insertado, ya que existe.');
         END IF;
    WHEN(opcion=5) THEN
         DBMS_OUTPUT.PUT_LINE('Listado de peliculas alquiladas: ');
         peliculas_alquiladas_clientes;
     WHEN(opcion=6) THEN
         DBMS_OUTPUT.PUT_LINE('Listado de todas las peliculas: ');
         todas_las_peliculas;
     WHEN(opcion=7) THEN
         DBMS_OUTPUT.PUT_LINE('Insertar una nueva pelicula: ');
         IF inserta_pelicula('Wrath of Man',2021,'Accion',2,1) THEN
             DBMS_OUTPUT.PUT_LINE('La pelicula ha sido insertada');
         ELSE
             DBMS_OUTPUT.PUT_LINE('La pelicula no ha sido insertada, ya que no existe seccion para el genero especificado.');
         END IF;
    ELSE 
         DBMS_OUTPUT.PUT_LINE('La opcion introducida no es valida. ');
    END CASE;
END;


--TRIGGERS
/*Este disparador busca si el alquiler esta se encuentra ya en pendientes, y si no esta, bloquea la tarjeta para que la
tarjeta asociada al alquiler pendiente no pueda alquilar nuevas peliculas.*/
CREATE OR REPLACE TRIGGER bloquear_tarjeta
    BEFORE INSERT ON pendientes
    FOR EACH ROW
DECLARE
--Cursor para obtener los alquileres de peliculas retrasados
CURSOR c_no_entregadas IS 
             SELECT * FROM pendientes;
r_no_entregadas c_no_entregadas%ROWTYPE;
v_esta BOOLEAN:= FALSE;
BEGIN
--Bucle para recorrer los alquileres de peliculas retrasados
OPEN c_no_entregadas;
       LOOP
       FETCH c_no_entregadas INTO r_no_entregadas; 
       EXIT WHEN c_no_entregadas%NOTFOUND OR v_esta=TRUE;
--Para comprobar si el alquiler ya se encuentra introducido en la tabla Pendientes
       IF :NEW.ID_pelicula=r_no_entregadas.ID_pelicula AND :NEW.ID_tarjeta=r_no_entregadas.ID_tarjeta THEN
--Variable para controlar si el alquiler ya se encuentra introducido
           v_esta:= TRUE;
       END IF;
       END LOOP;
CLOSE c_no_entregadas;
--Si el alquiler no se encuentra introducido, restringe la tarjeta asociada al alquiler
IF v_esta=FALSE THEN
   UPDATE tarjeta SET restringida='SI' WHERE ID_tarjeta=:NEW.ID_tarjeta;
END IF;
END bloquear_tarjeta;
/

--Actualiza el atributo de pelicula disponible a 'SI' al ser borrada de alquiler, y por la tanto haber sido devuelta.
CREATE OR REPLACE TRIGGER pelicula_disponible
AFTER DELETE ON alquiler
FOR EACH ROW
BEGIN 
--Actualiza el atributo disponible de pelicula a 'SI'
UPDATE pelicula SET disponible='SI' WHERE ID_pelicula=:OLD.ID_pelicula;
END pelicula_disponible;
/

/*Este disparador busca si la tarjeta asociada al alquiler eliminado no tiene peliculas retrasadas, y en caso de ser asi,
desbloquea la tarjeta, para que pueda alquilar mas peliculas.*/
CREATE OR REPLACE TRIGGER borrar_alquiler_pendientes
AFTER DELETE ON alquiler
FOR EACH ROW
DECLARE
--Cursor para obtener los alquileres de peliculas retrasados
CURSOR c_no_entregadas IS 
             SELECT * FROM pendientes;
r_no_entregadas c_no_entregadas%ROWTYPE;
v_esta BOOLEAN:= FALSE;
BEGIN
--Bucle para recorrer los alquileres de peliculas retrasados
OPEN c_no_entregadas;
       LOOP
       FETCH c_no_entregadas INTO r_no_entregadas; 
       EXIT WHEN c_no_entregadas%NOTFOUND OR v_esta=TRUE;
--Para comprobar si la tarjeta se encuentra en la tabla Pendientes
       IF :OLD.ID_tarjeta=r_no_entregadas.ID_tarjeta THEN
--Variable para controlar si la tarjeta esta en la tabla Pendientes
           v_esta:= TRUE;
       END IF;
       END LOOP;
CLOSE c_no_entregadas;
--Si la tarjeta no se encuentra en la tabla Pendientes, desbloque la tarjeta
IF v_esta=FALSE THEN
   UPDATE tarjeta SET restringida='NO' WHERE ID_tarjeta=:OLD.ID_tarjeta;
END IF;
END borrar_alquiler_pendientes;
/

--Actualiza el atributo de pelicula disponible a 'NO? al ser insertada en alquiler, y por la tanto haber sido alquilada.
CREATE OR REPLACE TRIGGER pelicula_nodisponible
AFTER INSERT ON alquiler
FOR EACH ROW
BEGIN 
--Actualiza el atributo disponible de pelicula a 'NO'
UPDATE pelicula SET disponible='NO' WHERE ID_pelicula=:NEW.ID_pelicula;
END pelicula_nodisponible;
/

--Actualiza el atributo de numero de peliculas alquiladas de tarjeta al ser insertado un nuevo alquiler asociado a la tarjeta, y por la tanto haber alquilado una nueva pelicula.
CREATE OR REPLACE TRIGGER peliculasAlquiladasTarjeta
AFTER INSERT ON alquiler
FOR EACH ROW
BEGIN 
--Actualiza el atributo numPelalquiladas de tarjeta.
UPDATE tarjeta SET numPelalquiladas=numPelalquiladas+1 WHERE ID_tarjeta=:NEW.ID_tarjeta;
END peliculasAlquiladasTarjeta;
/

--Crea automaticamente una tarjeta asociada al cliente insertado en la tabla cliente.
CREATE OR REPLACE TRIGGER crear_tarjeta
AFTER INSERT ON CLIENTE
FOR EACH ROW
BEGIN 
--Inserta dentro de la tabla tarjeta una nueva tarjeta asociada al DNI del nuevo cliente introducido
INSERT INTO tarjeta VALUES(tarjeta_seq.nextval, :NEW.DNI, DEFAULT, DEFAULT);
END crear_tarjeta;
/

--Controla que la accion haya sido realizada dentro del horario del videoclub.
CREATE OR REPLACE TRIGGER horario_videoclub_alquiler
BEFORE INSERT OR DELETE OR UPDATE ON alquiler
DECLARE
v_hora NUMBER;
BEGIN
SELECT TO_CHAR(SYSDATE,'HH24') INTO v_hora
FROM DUAL;
--Para comprobar si la hora en la que se ha realizado la accion esta dentro del horario
IF v_hora<9 OR v_hora>22 THEN
RAISE_APPLICATION_ERROR (-20093,'Acción no realizada. El horario del videoclub es de 9:00 a 22:00');
END IF;
END horario_videoclub_alquiler;
/

--Controla que la accion haya sido realizada dentro del horario del videoclub.
CREATE OR REPLACE TRIGGER horario_videoclub_cliente
BEFORE INSERT OR DELETE OR UPDATE ON cliente
DECLARE
v_hora NUMBER;
BEGIN
SELECT TO_CHAR(SYSDATE,'HH24') INTO v_hora
FROM DUAL;
--Para comprobar si la hora en la que se ha realizado la accion esta dentro del horario
IF v_hora<9 OR v_hora>22 THEN
RAISE_APPLICATION_ERROR (-20093,'Acción no realizada. El horario del videoclub es de 9:00 a 22:00');
END IF;
END horario_videoclub_cliente;
/

--FUNCTIONS

/*Devuelve un booleano respecto asi la fecha pasada por parametro, ha superado la de la fecha en la que ha sido lanzada
la funcion.*/
CREATE OR REPLACE FUNCTION fecha_pasada(v_fecha DATE)
     RETURN BOOLEAN IS 
BEGIN 
IF SYSDATE>v_fecha THEN 
    RETURN TRUE;
ELSE
    RETURN FALSE;
END IF;
END fecha_pasada;
/

--Devuelve falso en caso de que la fecha pasada por parametros, sea anterior a la fecha en que se lanza la funcion.
CREATE OR REPLACE FUNCTION fecha_valida(v_fecha DATE)
RETURN BOOLEAN IS
 v_valida BOOLEAN := TRUE;
BEGIN
    IF v_fecha<=SYSDATE THEN
       v_valida:= FALSE;
    END IF;
    return v_valida;
END fecha_valida;
/

/*Devuelve un booleano indicando si el alquiler asociado a la tarjeta y pelicula pasadas por parametro, se encuentra en la
tabla Pendientes.*/
CREATE OR REPLACE FUNCTION esta_en_pendiente(v_ID_tarjeta NUMBER, v_ID_pelicula NUMBER)
    RETURN BOOLEAN IS
--Cursor para obtener los alquileres de peliculas retrasados
        CURSOR c_no_entregadas IS 
             SELECT * FROM pendientes;
r_no_entregadas c_no_entregadas%ROWTYPE;
v_esta BOOLEAN:= FALSE;
BEGIN
--Bucle para recorrer los alquileres de peliculas retrasados
OPEN c_no_entregadas;
LOOP
FETCH c_no_entregadas INTO r_no_entregadas; 
EXIT WHEN c_no_entregadas%NOTFOUND OR v_esta=TRUE;
--Para comprobar si el alquiler se encuentra en la tabla Pendientes
IF r_no_entregadas.ID_tarjeta=v_ID_tarjeta AND r_no_entregadas.ID_pelicula=v_ID_pelicula THEN
--Variable para controlar si el alquiler esta en la tabla Pendientes
   v_esta:= TRUE;
END IF;
END LOOP;
CLOSE c_no_entregadas;
RETURN v_esta;
END esta_en_pendiente;
/

--Devuelve los dias pasado entre la fecha pasada por parametros y el de la fecha que ha sido lanzada la funcion.
CREATE OR REPLACE FUNCTION dias_pasados(v_fecha DATE) RETURN NUMBER IS
v_dias NUMBER;
BEGIN
--Resta la fecha pasada por parametro a la fecha que ha sido lanzada la funcion para obtener los dias
v_dias:= TRUNC((to_date(v_fecha, 'DD/MM/YYYY')) - (to_date(sysdate, 'DD/MM/YYYY'))) +1;
RETURN v_dias;
END dias_pasados;
/

--Devuelve un booleano indicando si la pelicula pasada por parametro existe o no.
CREATE OR REPLACE FUNCTION existe_pelicula(v_ID_pelicula NUMBER)
    RETURN BOOLEAN IS
--Cursor para obtener todas las peliculas
        CURSOR c_peliculas IS 
             SELECT * FROM pelicula;
r_peliculas c_peliculas%ROWTYPE;
v_esta BOOLEAN:= FALSE;
BEGIN
--Bucle para recorrer todas las peliculas
OPEN c_peliculas;
LOOP
FETCH c_peliculas INTO r_peliculas; 
EXIT WHEN c_peliculas%NOTFOUND OR v_esta=TRUE;
--Para comprobar si la pelicula se encuentra en la tabla Pelicula
IF r_peliculas.ID_pelicula=v_ID_pelicula THEN
--Variable para controlar si la pelicula esta en la tabla Pelicula
   v_esta:= TRUE;
END IF;
END LOOP;
CLOSE c_peliculas;
RETURN v_esta;
END existe_pelicula;
/

--Devuelve un booleano indicando si la tarjeta pasada por parametro existe o no.
CREATE OR REPLACE FUNCTION existe_tarjeta(v_ID_tarjeta NUMBER)
    RETURN BOOLEAN IS
--Cursor para obtener todas las tarjetas
        CURSOR c_tarjetas IS 
             SELECT * FROM tarjeta;
r_tarjetas c_tarjetas%ROWTYPE;
v_esta BOOLEAN:= FALSE;
BEGIN
--Bucle para recorrer todas las tarjetas
OPEN c_tarjetas;
LOOP
FETCH c_tarjetas INTO r_tarjetas; 
EXIT WHEN c_tarjetas%NOTFOUND OR v_esta=TRUE;
--Para comprobar si la tarjeta se encuentra en la tabla Tarjeta
IF r_tarjetas.ID_tarjeta=v_ID_tarjeta THEN
--Variable para controlar si la tarjeta esta en la tabla Tarjeta
   v_esta:= TRUE;
END IF;
END LOOP;
CLOSE c_tarjetas;
RETURN v_esta;
END existe_tarjeta;
/

/*Devuelve un booleano indicando si la tarjeta pasada por parametro esta restringida y por lo tanto no puede alquilar
nuevas pelicula o no.*/
CREATE OR REPLACE FUNCTION esta_restringida(v_ID_tarjeta NUMBER)
    RETURN BOOLEAN IS
    c_tarjeta tarjeta%ROWTYPE;
v_restringida BOOLEAN:= FALSE;
BEGIN
--Cursor implicito de tipo tabla Tarjeta que recibe la informacion de la tarjeta pasada por parametro
SELECT * INTO c_tarjeta
FROM tarjeta WHERE ID_tarjeta=v_ID_tarjeta;
--Para comprobar si la tarjeta esta restringida
IF c_tarjeta.restringida='SI' THEN 
--Variable para controlar si la tarjeta esta restringida
   v_restringida:= TRUE;
END IF;
RETURN v_restringida;
END esta_restringida;
/

--Devuelve un booleano indicando si la pelicula pasada por parametro se encuentra alquilada o no.
CREATE OR REPLACE FUNCTION esta_alquilada(v_ID_pelicula NUMBER)
    RETURN BOOLEAN IS
--Cursor para obtener todos los alquileres
        CURSOR c_alquiladas IS 
             SELECT * FROM alquiler;
r_alquiladas c_alquiladas%ROWTYPE;
v_esta BOOLEAN:= FALSE;
BEGIN
--Bucle para recorrer todas los alquileres
OPEN c_alquiladas;
LOOP
FETCH c_alquiladas INTO r_alquiladas; 
EXIT WHEN c_alquiladas%NOTFOUND OR v_esta=TRUE;
--Para comprobar si la pelicula se encuentra alquilada
IF r_alquiladas.ID_pelicula=v_ID_pelicula THEN
--Variable para controlar si la pelicula se encuentra alquilada
   v_esta:= TRUE;
END IF;
END LOOP;
CLOSE c_alquiladas;
RETURN v_esta;
END esta_alquilada;
/

--Devuelve un booleano indicando si el cliente pasado por parametro ya existe en nuestra tabla cliente o no.
CREATE OR REPLACE FUNCTION existe_cliente(v_DNI VARCHAR2) RETURN BOOLEAN IS
--Cursor para obtener todos los clientes
CURSOR c_clientes IS 
             SELECT * FROM cliente;
r_clientes c_clientes%ROWTYPE;
v_esta BOOLEAN:= FALSE;
BEGIN
--Bucle para recorrer todas los clientes
OPEN c_clientes;
LOOP
FETCH c_clientes INTO r_clientes; 
EXIT WHEN c_clientes%NOTFOUND OR v_esta=TRUE;
--Para comprobar si el cliente se encuentra en la tabla Cliente
IF r_clientes.DNI=v_DNI THEN
--Variable para controlar si el cliente esta en la tabla Cliente
   v_esta:= TRUE;
END IF;
END LOOP;
CLOSE c_clientes;
RETURN v_esta;
END existe_cliente;
/

--Devuelve un booleano indicando si tenemos una seccion sobre el genero pasado por parametros o no.
CREATE OR REPLACE FUNCTION existe_genero(v_ID_genero VARCHAR2)
    RETURN BOOLEAN IS
--Cursor para obtener todas las secciones
        CURSOR c_generos IS 
             SELECT * FROM seccion;
r_generos c_generos%ROWTYPE;
v_esta BOOLEAN:= FALSE;
BEGIN
--Bucle para recorrer todas las secciones
OPEN c_generos;
LOOP
FETCH c_generos INTO r_generos; 
EXIT WHEN c_generos%NOTFOUND OR v_esta=TRUE;
--Para comprobar si el genero se encuentra en la tabla Seccion
IF r_generos.genero=v_ID_genero THEN
--Variable para controlar si el genero esta en la tabla Seccion
   v_esta:= TRUE;
END IF;
END LOOP;
CLOSE c_generos;
RETURN v_esta;
END existe_genero;
/

--Se encarga de crear un cliente controlando que el cliente introducido no exista, y devuelve si se ha introducido un nuevo cliente.
CREATE OR REPLACE FUNCTION crear_cliente(v_DNI VARCHAR2, v_nombre VARCHAR2, v_direccion VARCHAR, v_telefono NUMBER)
    RETURN BOOLEAN IS
v_cliente_insertado BOOLEAN;
BEGIN 
--Para comprobar si el cliente ya existe
IF existe_cliente(v_DNI) THEN
   v_cliente_insertado:= FALSE;
ELSE 
--Introduce el nuevo cliente
    INSERT INTO cliente VALUES(v_DNI, v_nombre, v_direccion, v_telefono, SYSDATE);
   v_cliente_insertado:= TRUE;
END IF;
--Variable que devuelve si se ha insertado una nueva pelicula o no
return v_cliente_insertado;
END crear_cliente;
/


/*Se encarga de insertar nuevas peliculas, controlando que disponamos seccion del genero especificado por parametros, y devuelve
si se ha insertado una nueva pelicula o no.*/
CREATE OR REPLACE FUNCTION inserta_pelicula(v_titulo VARCHAR2, v_ano NUMBER, v_genero VARCHAR2, v_penalizacion_por_dia NUMBER, v_coste_por_dia NUMBER)
    RETURN BOOLEAN IS
v_pelicula_insertada BOOLEAN;
BEGIN
--Para comprobar si el genero existe
IF existe_genero(v_genero) THEN
--Introduce una nueva pelicula
INSERT INTO pelicula VALUES(pelicula_seq.nextval, v_titulo, v_ano, v_genero, DEFAULT, v_penalizacion_por_dia, v_coste_por_dia);
v_pelicula_insertada:= TRUE;
ELSE
v_pelicula_insertada:= FALSE;
END IF;
--Variable que controla si se ha insertado una nueva pelicula
return v_pelicula_insertada;
END inserta_pelicula;
/



--PROCEDURES

/*Recibe por parametro un alquiler, y en caso de que la fecha de devolucion del alquiler, haya sido superada, y el alquiler
no se encuentre actualmente en la tabla pendientes, inserta el alquiler en la tabla pendientes.*/
CREATE OR REPLACE PROCEDURE no_devueltas(c_alquilada alquiler%ROWTYPE) IS
--Cursor para obtener todos los alquileres de peliculas retrasados
        CURSOR c_no_entregadas IS 
             SELECT * FROM pendientes;
r_no_entregadas c_no_entregadas%ROWTYPE;
v_esta BOOLEAN:= FALSE;
BEGIN
--Para comprobar si la fecha de devolucion ha sido superada
  IF fecha_pasada(c_alquilada.fecha_de_devolucion) THEN
--Bucle para recorrer todos los alquileres de peliculas retrasados
       OPEN c_no_entregadas;
       LOOP
       FETCH c_no_entregadas INTO r_no_entregadas; 
       EXIT WHEN c_no_entregadas%NOTFOUND OR v_esta=TRUE;
--Para comprobar si el alquiler pasado se encuentra en la tabla Pendiente
       IF c_alquilada.ID_pelicula=r_no_entregadas.ID_pelicula THEN
--Variable para controlar si el alquiler esta en la tabla Pendiente
           v_esta:= TRUE;
       END IF;
       END LOOP;
       CLOSE c_no_entregadas;
--Si el alquiler no se encuentra en la tabla Pendiente, lo introduce
       IF v_esta=FALSE THEN
           INSERT INTO pendientes VALUES(c_alquilada.ID_tarjeta, c_alquilada.ID_pelicula, c_alquilada.fecha_de_devolucion);
       END IF;
  END IF;
END no_devueltas;
/


/*Recorre todos los alquileres que estan en curso, y apoyandose en el procedimiento No_devueltas, inserta en la tabla 
pendientes aquellos alquileres cuya fecha de devolucion haya sido superada.*/
CREATE OR REPLACE PROCEDURE auditoria_Alquiler IS
--Cursor para obtener todos los alquileres
        CURSOR c_alquiladas IS 
             SELECT * FROM alquiler;
r_alquiladas c_alquiladas%ROWTYPE;
v_hay_registro BOOLEAN:= FALSE;
no_hay_alquiladas EXCEPTION;
BEGIN 
--Bucle para recorrer todos los alquileres
OPEN c_alquiladas;
LOOP
FETCH c_alquiladas INTO r_alquiladas;
EXIT WHEN c_alquiladas%NOTFOUND;
--Variable para controlar que hay registro de peliculas alquiladas
v_hay_registro:= TRUE;
--Le envia por parametro cada alquiler que contiene el cursor al metodo no_devueltas
no_devueltas(r_alquiladas);
END LOOP;
CLOSE c_alquiladas;

IF v_hay_registro=FALSE THEN
raise no_hay_alquiladas;
END IF;

EXCEPTION
WHEN no_hay_alquiladas THEN
DBMS_OUTPUT.PUT_LINE ('Error -20001: Actualmente no existen registros de peliculas alquiladas.');
END auditoria_Alquiler;
/


/*Se encarga de la tarea de alquilar una pelicula apoyandose en funciones para controlar que todos los datos introducidos
son validos, y otros detalles como que la tarjeta pasada por parametro no este restrigida o que la pelicula no se 
encuentre alquilada.*/
CREATE OR REPLACE PROCEDURE alquilar_pelicula(v_ID_tarjeta NUMBER, v_ID_pelicula NUMBER, v_fecha_devolucion DATE, v_dinero NUMBER) IS
v_coste_por_dia pelicula.coste_por_dia%TYPE;
v_pago NUMBER;
v_dias NUMBER;
v_numPelalquiladas NUMBER;
fecha_invalida EXCEPTION;
tar EXCEPTION;
pel EXCEPTION;
tarjeta_pelicula EXCEPTION;
BEGIN
--Se encarga de controlar la excepcion de que la pelicula y tarjeta pasadas por parametro existen
IF existe_pelicula(v_ID_pelicula)=FALSE AND existe_tarjeta(v_ID_tarjeta)=FALSE THEN
 raise tarjeta_pelicula;
END IF;
--Se encargan de controlar la excepcion de que la tarjeta pasada por parametro existe
IF existe_tarjeta(v_ID_tarjeta)=FALSE THEN
 raise tar;
END IF;
--Se encargan de controlar la excepcion de que la pelicula pasada por parametro existe
IF existe_pelicula(v_ID_pelicula)=FALSE THEN
 raise pel;
END IF;
--Se encargan de controlar la excepcion de que la fecha pasada por parametro es valida
IF fecha_valida(v_fecha_devolucion)=FALSE THEN
 raise fecha_invalida;
END IF;

--Para comprobar si la tarjeta pasada esta restringida
   IF esta_restringida(v_ID_tarjeta) THEN
      DBMS_OUTPUT.PUT_LINE ('La tarjeta esta restringida. Tiene pelicula por devolver, y no puede alquilar nuevas peliculas');
   ELSE
--Para comprobar si la pelicula pasada se encuentra alquilada
      IF esta_alquilada(v_ID_pelicula)=FALSE THEN
--Introduce en la variable el coste por dia de la pelicula pasada
          SELECT coste_por_dia INTO v_coste_por_dia 
          FROM pelicula WHERE ID_pelicula=v_ID_pelicula;
--Introduce en la variable el numero de peliculas que ha alquilado
          SELECT numPelalquiladas INTO v_numPelalquiladas
          FROM tarjeta WHERE ID_tarjeta=v_ID_tarjeta;
--Introduce en la variable los dias entre la fecha del alquiler y la fecha de devolucion
          v_dias:= (dias_pasados(v_fecha_devolucion));
          DBMS_OUTPUT.PUT_LINE ('Dias: '||v_dias);
--Introduce en la variable el pago necesario para alquilar la pelicula
          v_pago:= v_dias * v_coste_por_dia;
          DBMS_OUTPUT.PUT_LINE ('Pago: '||v_pago);
--Para comprobar si es aplicable un descuento por haber alquilado mas de 10 peliculas
          IF v_numPelalquiladas>10 THEN
              v_pago := v_pago - v_pago*(10/100);
              DBMS_OUTPUT.PUT_LINE ('Se ha aplicado un descuento del 10%.');
              DBMS_OUTPUT.PUT_LINE ('El pago despues de aplicar el descuento es: '||v_pago);
          END IF;
--Para comprobar si el dinero pasado es suficiente para alquilar la pelicula
          IF v_dinero>=v_pago THEN
            INSERT INTO alquiler VALUES(v_ID_tarjeta , v_ID_pelicula, SYSDATE, v_fecha_devolucion);
            DBMS_OUTPUT.PUT_LINE('La pelicula ha sido alquilada.');
          ELSE
            DBMS_OUTPUT.PUT_LINE('El dinero es insuficiente.');
          END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('La pelicula se encuentra alquilada.');
    END IF;
 END IF;
 

EXCEPTION
WHEN tarjeta_pelicula THEN
DBMS_OUTPUT.PUT_LINE ('Error -20003: El cliente y pelicula introducidas no existen.');
WHEN tar THEN
DBMS_OUTPUT.PUT_LINE ('Error -20004: La tarjeta introducida no existe.');
WHEN pel THEN
DBMS_OUTPUT.PUT_LINE ('Error -20004: La pelicula introducida no existe.');
WHEN fecha_invalida THEN
DBMS_OUTPUT.PUT_LINE ('Error -20002: La fecha introducida no es valida.');
END alquilar_pelicula;
/


/*Se encarga de eliminar de la tabla pendientes aquellos alquileres cuya fecha de devolucion fue superada, siempre que
el dinero pasado por parametros sea suficiente para pagar el coste de penalizacion por los dias sin devolver la pelicula.*/
CREATE OR REPLACE PROCEDURE eliminar_pendiente(v_ID_tarjeta NUMBER, v_ID_pelicula NUMBER, v_dinero NUMBER) IS
   v_pago NUMBER;
   v_dias NUMBER;
   v_fecha_pendiente DATE;
   v_penalizacion_dias NUMBER;
BEGIN 
--Introduce en la variable la fecha de devolucion del alquiler pasado por parametro
   SELECT fecha_de_devolucion INTO v_fecha_pendiente 
FROM pendientes WHERE ID_tarjeta=v_ID_tarjeta AND ID_pelicula=v_ID_pelicula;
--Introduce en la variable la penalizacion por dia de la pelicula pasada por parametro
   SELECT penalizacion_por_dia INTO v_penalizacion_dias
FROM pelicula WHERE ID_pelicula=v_ID_pelicula;
--Introduce los dias y el pago a las variables
v_dias:= (-1)*dias_pasados(v_fecha_pendiente); --Multiplico por (-1) porque al ser fecha_pendiente una fecha anterior a la de la fecha que ha sido lanzado el procedimiento devuelve un numero negativo.
v_pago:= v_dias*v_penalizacion_dias;
DBMS_OUTPUT.PUT_LINE ('Debe pagar '||v_pago);
--Para comprobar si el dinero es suficiente para realizar el pago
IF v_dinero>=v_pago THEN 
--Borra el registro del alquiler
   DELETE pendientes WHERE ID_tarjeta=v_ID_tarjeta AND ID_pelicula=v_ID_pelicula;
   DELETE alquiler WHERE ID_tarjeta=v_ID_tarjeta AND ID_pelicula=v_ID_pelicula;
   DBMS_OUTPUT.PUT_LINE('La pelicula ha sido devuelta.');
ELSE
  DBMS_OUTPUT.PUT_LINE('Dinero insuficiente.');
END IF;
END eliminar_pendiente;
/

/*Se encarga de devolver la pelicula alquilada pasada por parametro, controlando que los datos introducidos correspondan correctamente
a un alquiler existente.*/
CREATE OR REPLACE PROCEDURE devolver_pelicula(v_ID_tarjeta NUMBER, v_ID_pelicula NUMBER, v_dinero NUMBER) IS
--Cursor para obtener todos los alquileres    
     CURSOR c_alquiladas IS 
             SELECT * FROM alquiler;
v_hay_registro BOOLEAN:= FALSE;
no_hay_alquiladas EXCEPTION;
r_alquiladas c_alquiladas%ROWTYPE;
v_esta BOOLEAN:=FALSE;
v_pago NUMBER;
BEGIN
--Bucle para recorrer todos los alquileres
OPEN c_alquiladas;
LOOP
FETCH c_alquiladas INTO r_alquiladas; 
EXIT WHEN c_alquiladas%NOTFOUND OR v_esta=TRUE;
--Variable para controlar que hay registro de peliculas alquiladas
v_hay_registro:= TRUE;
--Para comprobar si el alquiler pasado se encuentra en la tabla Alquiler
IF r_alquiladas.ID_tarjeta=v_ID_tarjeta AND r_alquiladas.ID_pelicula=v_ID_pelicula THEN
--Variable para controlar si el alquiler esta en la tabla Alquiler
   v_esta:= TRUE;
END IF;
END LOOP;
CLOSE c_alquiladas;
--Si no hay registro lanza la excepcion
IF v_hay_registro=FALSE THEN
raise no_hay_alquiladas;
END IF;
--Para comprobar si el alquiler existe
IF v_esta=TRUE THEN
--Para comprobar si el alquiler se encuentra en la tabla Pendiente
   IF esta_en_pendiente(v_ID_tarjeta, v_ID_pelicula) THEN
       eliminar_pendiente(v_ID_tarjeta, v_ID_pelicula, v_dinero);
   ELSE 
--Elimina el alquiler pasado por parametro
      DELETE alquiler WHERE ID_tarjeta=v_ID_tarjeta AND ID_pelicula=v_ID_pelicula;
      DBMS_OUTPUT.PUT_LINE('La pelicula ha sido devuelta.');
   END IF;
--Si no hay ningun registro con los datos pasados por parametro lanza una excepcion
ELSE
   raise_application_error(-20111,'No se ha encontrado el registro introducido');
END IF;

EXCEPTION
WHEN no_hay_alquiladas THEN
DBMS_OUTPUT.PUT_LINE ('Error -20001: Actualmente no existen registros de peliculas alquiladas.');

END devolver_pelicula;
/



--Se encarga de generar un listado de todos los cliente, y las peliculas que tienen alquilada en se momento.
CREATE OR REPLACE PROCEDURE peliculas_alquiladas_clientes IS
--Cursor para obtener los alquileres asociados a la tarjeta pasada por parametro
      CURSOR c_alquiladas(v_ID_tarjeta NUMBER) IS
           SELECT ID_tarjeta, ID_pelicula
           FROM alquiler
           WHERE ID_tarjeta=v_ID_tarjeta;
r_alquiladas c_alquiladas%ROWTYPE;
--Cursor para obtener los datos asociados a la pelicula pasada por parametro
      CURSOR c_pelis(v_ID_pelicula NUMBER) IS 
           SELECT ID_pelicula, titulo, ano, genero
           FROM pelicula
           WHERE ID_pelicula=v_ID_pelicula;
r_pelis c_pelis%ROWTYPE;
--Cursor para obtener todos los clientes
CURSOR c_clientes IS
           SELECT DNI, nombre, direccion, telefono, fecha_registro
           FROM cliente;
r_clientes c_clientes%ROWTYPE;
v_tarjeta tarjeta.id_tarjeta%TYPE;

BEGIN
--Trabajamos con el primer cursor que obtendrá todos los clientes
OPEN c_clientes;
 LOOP
        FETCH c_clientes INTO r_clientes;
        EXIT WHEN c_clientes%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('#############################################################################################');
        DBMS_OUTPUT.PUT_LINE('DNI: '||r_clientes.DNI);
        DBMS_OUTPUT.PUT_LINE('Nombre: '||r_clientes.nombre);
        DBMS_OUTPUT.PUT_LINE('Direccion: '||r_clientes.direccion);
        DBMS_OUTPUT.PUT_LINE('Telefono: '||r_clientes.telefono);
        DBMS_OUTPUT.PUT_LINE('Fecha de Registro: '||r_clientes.fecha_registro);
--Introducimos dentro de la variable la tarjeta asociada al cliente     
        SELECT ID_tarjeta INTO v_tarjeta
        FROM tarjeta WHERE DNI=r_clientes.DNI;
        DBMS_OUTPUT.PUT_LINE('Peliculas alquiladas: ');
--Trabajamos con el segundo cursor que obtendrá todos los alquileres del cliente pasado por parametro en un bucle
        FOR r_alquiladas IN c_alquiladas(v_tarjeta) LOOP
--Trabajamos con el tercero cursor que obtendrá la informacion de la pelicula pasada por parametro en un bucle
           FOR r_pelis IN c_pelis(r_alquiladas.ID_pelicula) LOOP
              DBMS_OUTPUT.PUT_LINE('');
              DBMS_OUTPUT.PUT_LINE('ID Pelicula: '||r_pelis.ID_pelicula);
              DBMS_OUTPUT.PUT_LINE('Titulo: '||r_pelis.titulo);
              DBMS_OUTPUT.PUT_LINE('Año: '||r_pelis.ano);
              DBMS_OUTPUT.PUT_LINE('Genero: '||r_pelis.genero);
              DBMS_OUTPUT.PUT_LINE('');
            END LOOP;
    END LOOP;
DBMS_OUTPUT.PUT_LINE('#############################################################################################');
END LOOP;
CLOSE c_clientes;
END peliculas_alquiladas_clientes;
/

--Se encarga de generar un listado de todas las peliculas clasificadas por genero.
CREATE OR REPLACE PROCEDURE todas_las_peliculas IS
--Cursor para obtener todas las secciones
     CURSOR c_generos IS 
             SELECT * FROM seccion;
--Cursor para obtener todas las pelicula del genero pasado por parametro
CURSOR c_peliculas(v_genero VARCHAR2) IS 
         SELECT * FROM pelicula WHERE genero=v_genero;
r_generos c_generos%ROWTYPE;
r_peliculas c_peliculas%ROWTYPE;
BEGIN
--Trabajamos con el primer cursor que obtendrá todas las secciones en un bucle
FOR r_generos IN c_generos LOOP
         DBMS_OUTPUT.PUT_LINE (r_generos.genero||':  ');
--Trabajamos con el segundo cursor que obtendrá todas las peliculas del genero pasado por parametro en un bucle
         FOR r_peliculas IN c_peliculas(r_generos.genero) LOOP
DBMS_OUTPUT.PUT_LINE ('ID pelicula: ' || r_peliculas.ID_pelicula);
DBMS_OUTPUT.PUT_LINE ('Titulo: ' || r_peliculas.titulo);
DBMS_OUTPUT.PUT_LINE (' Año:' || r_peliculas.ano);
DBMS_OUTPUT.PUT_LINE (' Genero:' || r_peliculas.genero);
DBMS_OUTPUT.PUT_LINE (' Disponible:' || r_peliculas.disponible);
DBMS_OUTPUT.PUT_LINE (' Coste por dia:' || r_peliculas.coste_por_dia);
DBMS_OUTPUT.PUT_LINE (' Penalizacion por dia:' || r_peliculas.penalizacion_por_dia);
DBMS_OUTPUT.PUT_LINE ('-');
END LOOP;
END LOOP;
END todas_las_peliculas;
/
