 --DROP TABLES
 DROP TABLE pendientes;
 DROP TABLE alquiler;
 DROP TABLE pelicula;
 DROP TABLE seccion;
 DROP TABLE tarjeta;
 DROP TABLE cliente;


--CREATE TABLES--
CREATE TABLE cliente(
  DNI VARCHAR2(9) CONSTRAINT cliente_ID_PK PRIMARY KEY,
  nombre VARCHAR2(40),
  direccion VARCHAR2(50),
  telefono NUMBER,
  fecha_registro DATE
  );
  
  CREATE TABLE tarjeta(
  ID_tarjeta NUMBER CONSTRAINT tar_ID_PK PRIMARY KEY,
  DNI VARCHAR2(9),
  restringida VARCHAR2(2) DEFAULT 'NO',
  numPelalquiladas NUMBER DEFAULT 0,
  CONSTRAINT tar_res_ck CHECK (UPPER(restringida) IN ('SI','NO')),
  CONSTRAINT tar_cli_fk FOREIGN KEY(DNI) REFERENCES cliente
  );


  
CREATE TABLE seccion(
  genero VARCHAR2(20) CONSTRAINT gen_est_pk PRIMARY KEY,
  pasillo NUMBER CONSTRAINT pas_est_uk UNIQUE
  );
  
CREATE TABLE pelicula(
  ID_pelicula NUMBER CONSTRAINT pel_ID_PK PRIMARY KEY,
  titulo VARCHAR2(50),
  ano NUMBER,
  genero VARCHAR2(20),
  disponible VARCHAR2(2) DEFAULT 'SI',
  penalizacion_por_dia NUMBER(10,2),
  coste_por_dia NUMBER(10,2),
  CONSTRAINT pel_dis_ck CHECK (UPPER(disponible) IN ('SI','NO')),
  CONSTRAINT pel_gen_fk FOREIGN KEY(genero) REFERENCES seccion
  );
  

CREATE TABLE alquiler(
  ID_tarjeta NUMBER,
  ID_pelicula NUMBER,
  fecha_de_alquiler DATE,
  fecha_de_devolucion DATE,
  CONSTRAINT alq_PK PRIMARY KEY (ID_tarjeta,ID_pelicula),
  CONSTRAINT alq_tar_fk FOREIGN KEY (ID_tarjeta) REFERENCES tarjeta,
  CONSTRAINT alq_pel_fk FOREIGN KEY (ID_pelicula) REFERENCES pelicula
  );
  
  CREATE TABLE pendientes(
  ID_tarjeta NUMBER,
  ID_pelicula NUMBER,
  fecha_de_devolucion DATE,
  CONSTRAINT pen_PK PRIMARY KEY (ID_tarjeta,ID_pelicula),
  CONSTRAINT pen_FK FOREIGN KEY (ID_tarjeta,ID_pelicula) REFERENCES alquiler
  );
  

 ALTER SESSION SET nls_date_format='dd/mm/yyyy';
 

--CREATE SEQUENCE
  CREATE SEQUENCE tarjeta_seq
  START WITH 1 INCREMENT BY 1;
  
  CREATE SEQUENCE pelicula_seq
  START WITH 1 INCREMENT BY 1;

  
  --INSERTS
INSERT INTO seccion VALUES ('Accion',1);
INSERT INTO seccion VALUES ('Comedia',2);
INSERT INTO seccion VALUES ('Ciencia ficcion',3);
INSERT INTO seccion VALUES ('Dramaticas',4);
INSERT INTO seccion VALUES ('Infantiles',5);
INSERT INTO seccion VALUES ('Terror',6);
INSERT INTO seccion VALUES ('Adultos',7);

INSERT INTO pelicula VALUES (pelicula_seq.nextval,'El padrino',1972,'Dramaticas','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Taxi Driver',1976,'Dramaticas','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Cinema Paradiso',1988,'Dramaticas','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Forrest Gump',1994,'Dramaticas','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Ciudad de Dios',2002,'Dramaticas','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'En busca de la felicidad',2006,'Dramaticas','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Doce años de esclavitud',2013,'Dramaticas','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Mi vecino Tororo',1988,'Infantiles','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'El rey leon',1994,'Infantiles','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Toy Story 1',1995,'Infantiles','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Shrek 1',2001,'Infantiles','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'La novia cadaver',2005,'Infantiles','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Ratatuille',2007,'Infantiles','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Up',2009,'Infantiles','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'La vida de Brian',1979,'Comedia','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Top Secret',1984,'Comedia','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'La mascara',1994,'Comedia','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Algo pasa con Mary',1998,'Comedia','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'American pie',1999,'Comedia','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Scary Movie',2000,'Comedia','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Borat',2006,'Comedia','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Metropolis',1927,'Ciencia ficcion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'2001: Odisea en el espacio',1968,'Ciencia ficcion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'E.T. el extaterrestre',1982,'Ciencia ficcion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Blade Runner',1982,'Ciencia ficcion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Terminator',1984,'Ciencia ficcion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Regreso al Futuro 1',1985,'Ciencia ficcion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Matrix',1999,'Ciencia ficcion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Psicosis',1960,'Terror','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'El resplandor',1980,'Terror','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Scream',1996,'Terror','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'El sexto sentido',1999,'Terror','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'It',2017,'Terror','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Paranormal Activity',2007,'Terror','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Repulsion',1965,'Terror','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Contacto Sangriento',1988,'Accion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Los Mercenarios 2',2012,'Accion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'El caso Bourne',2002,'Accion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Venganza',2008,'Accion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Mision Imposible',1996,'Accion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Acorralado',1982,'Accion','SI',2,1.20);
INSERT INTO pelicula VALUES (pelicula_seq.nextval,'Commando',1985,'Accion','SI',2,1.20);

INSERT INTO cliente VALUES('22434','Alejandro','Calle',2323442,SYSDATE);
INSERT INTO tarjeta VALUES(tarjeta_seq.nextval,'22434',DEFAULT,DEFAULT);