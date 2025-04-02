--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

-- Started on 2025-03-12 08:06:02

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 18061)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5804 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 395 (class 1255 OID 18333)
-- Name: decrypt_text(bytea, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.decrypt_text(data bytea, secret text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN pgp_sym_decrypt(data, secret);
EXCEPTION
    WHEN others THEN
        RETURN 'Error al desencriptar';
END;
$$;


ALTER FUNCTION public.decrypt_text(data bytea, secret text) OWNER TO postgres;

--
-- TOC entry 394 (class 1255 OID 18332)
-- Name: encrypt_text(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.encrypt_text(data text, secret text) RETURNS bytea
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN pgp_sym_encrypt(data, secret);
END;
$$;


ALTER FUNCTION public.encrypt_text(data text, secret text) OWNER TO postgres;

--
-- TOC entry 357 (class 1255 OID 17457)
-- Name: iff(boolean, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.iff(boolean, double precision, double precision) RETURNS double precision
    LANGUAGE sql
    AS $_$
select CASE when $1 then $2 else $3 end
$_$;


ALTER FUNCTION public.iff(boolean, double precision, double precision) OWNER TO postgres;

--
-- TOC entry 407 (class 1255 OID 17808)
-- Name: log_changes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    primary_key_column TEXT;
    primary_key_value TEXT;
BEGIN
    IF TG_TABLE_NAME = 'log_table' OR TG_TABLE_NAME = 'encrypted_log_table' THEN
        RETURN NEW;
    END IF;

    SELECT column_name INTO primary_key_column
    FROM information_schema.columns
    WHERE table_name = TG_TABLE_NAME
    ORDER BY ordinal_position
    LIMIT 1;

    IF TG_OP = 'INSERT' THEN
        EXECUTE format('SELECT ($1).%I::text', primary_key_column) INTO primary_key_value USING NEW;
        INSERT INTO log_table (table_name, id_registro_tabla_modificada, action, date)
        VALUES (TG_TABLE_NAME, primary_key_value::int, 'CREATED ' || row_to_json(NEW)::text || ' in table ' || TG_TABLE_NAME, CURRENT_TIMESTAMP);
        INSERT INTO encrypted_log_table (table_name, id_registro_tabla_modificada, action, date)
        VALUES (encrypt_text(TG_TABLE_NAME, 'maquina'), encrypt_text(primary_key_value::text, 'maquina'), encrypt_text('CREATED ' || row_to_json(NEW)::text || ' in table ' || TG_TABLE_NAME, 'maquina'), encrypt_text(CURRENT_TIMESTAMP::text, 'maquina'));
    ELSIF TG_OP = 'UPDATE' THEN
        EXECUTE format('SELECT ($1).%I::text', primary_key_column) INTO primary_key_value USING NEW;
        INSERT INTO log_table (table_name, id_registro_tabla_modificada, action, date)
        VALUES (TG_TABLE_NAME, primary_key_value::int, 'UPDATED to ' || row_to_json(NEW)::text, CURRENT_TIMESTAMP);
        INSERT INTO encrypted_log_table (table_name, id_registro_tabla_modificada, action, date)
        VALUES (encrypt_text(TG_TABLE_NAME, 'maquina'), encrypt_text(primary_key_value::text, 'maquina'), encrypt_text('UPDATED to ' || row_to_json(NEW)::text, 'maquina'), encrypt_text(CURRENT_TIMESTAMP::text, 'maquina'));
    ELSIF TG_OP = 'DELETE' THEN
        EXECUTE format('SELECT ($1).%I::text', primary_key_column) INTO primary_key_value USING OLD;
        INSERT INTO log_table (table_name, id_registro_tabla_modificada, action, date)
        VALUES (TG_TABLE_NAME, primary_key_value::int, 'DELETED from table ' || TG_TABLE_NAME, CURRENT_TIMESTAMP);
        INSERT INTO encrypted_log_table (table_name, id_registro_tabla_modificada, action, date)
        VALUES (encrypt_text(TG_TABLE_NAME, 'maquina'), encrypt_text(primary_key_value::text, 'maquina'), encrypt_text('DELETED from table ' || TG_TABLE_NAME, 'maquina'), encrypt_text(CURRENT_TIMESTAMP::text, 'maquina'));
    END IF;

    RETURN NEW;
END;
$_$;


ALTER FUNCTION public.log_changes() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 248 (class 1259 OID 16600)
-- Name: ambientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ambientes (
    id_ambiente integer NOT NULL,
    id_piso_bloque integer,
    id_tipo_ambiente integer,
    nombre character varying(30),
    codigo character varying(30),
    capacidad integer,
    metro_cuadrado double precision,
    imagen_exterior character varying(255),
    imagen_interior character varying(255),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.ambientes OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 16599)
-- Name: ambientes_id_ambiente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ambientes_id_ambiente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ambientes_id_ambiente_seq OWNER TO postgres;

--
-- TOC entry 5805 (class 0 OID 0)
-- Dependencies: 247
-- Name: ambientes_id_ambiente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ambientes_id_ambiente_seq OWNED BY public.ambientes.id_ambiente;


--
-- TOC entry 221 (class 1259 OID 16422)
-- Name: areas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.areas (
    id_area integer NOT NULL,
    id_universidad integer NOT NULL,
    nombre character varying(150),
    nombre_abreviado character varying(100),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.areas OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16421)
-- Name: areas_id_area_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.areas_id_area_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.areas_id_area_seq OWNER TO postgres;

--
-- TOC entry 5806 (class 0 OID 0)
-- Dependencies: 220
-- Name: areas_id_area_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.areas_id_area_seq OWNED BY public.areas.id_area;


--
-- TOC entry 241 (class 1259 OID 16553)
-- Name: bloques; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bloques (
    id_bloque integer NOT NULL,
    id_edificio integer,
    nombre character varying(70),
    imagen character varying(255),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.bloques OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16552)
-- Name: bloques_id_bloque_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bloques_id_bloque_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bloques_id_bloque_seq OWNER TO postgres;

--
-- TOC entry 5807 (class 0 OID 0)
-- Dependencies: 240
-- Name: bloques_id_bloque_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bloques_id_bloque_seq OWNED BY public.bloques.id_bloque;


--
-- TOC entry 235 (class 1259 OID 16512)
-- Name: campus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campus (
    id_campu integer NOT NULL,
    nombre character varying(70),
    direccion character varying(255),
    poligono character varying(5000),
    latitud character varying(30),
    longitud character varying(30),
    imagen character varying(255),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.campus OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16511)
-- Name: campus_id_campu_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campus_id_campu_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.campus_id_campu_seq OWNER TO postgres;

--
-- TOC entry 5808 (class 0 OID 0)
-- Dependencies: 234
-- Name: campus_id_campu_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campus_id_campu_seq OWNED BY public.campus.id_campu;


--
-- TOC entry 278 (class 1259 OID 16783)
-- Name: carreras; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.carreras (
    id_carrera integer NOT NULL,
    id_facultad integer NOT NULL,
    id_modalidad integer NOT NULL,
    id_carrera_nivel_academico integer NOT NULL,
    id_sede integer NOT NULL,
    nombre character varying(50) NOT NULL,
    nombre_abreviado character varying(50),
    fecha_aprobacion_curriculo date,
    fecha_creacion date,
    resolucion character varying(255),
    direccion character varying(150),
    latitud character varying(50),
    longitud character varying(50),
    fax character varying(20),
    telefono character varying(20),
    telefono_interno character varying(100),
    casilla character varying(12),
    email character varying(30),
    sitio_web character varying(50),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.carreras OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 16782)
-- Name: carreras_id_carrera_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.carreras_id_carrera_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.carreras_id_carrera_seq OWNER TO postgres;

--
-- TOC entry 5809 (class 0 OID 0)
-- Dependencies: 277
-- Name: carreras_id_carrera_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.carreras_id_carrera_seq OWNED BY public.carreras.id_carrera;


--
-- TOC entry 270 (class 1259 OID 16751)
-- Name: carreras_niveles_academicos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.carreras_niveles_academicos (
    id_carrera_nivel_academico integer NOT NULL,
    nombre character varying(35),
    descripcion character varying(350),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.carreras_niveles_academicos OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 16750)
-- Name: carreras_niveles_academicos_id_carrera_nivel_academico_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.carreras_niveles_academicos_id_carrera_nivel_academico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.carreras_niveles_academicos_id_carrera_nivel_academico_seq OWNER TO postgres;

--
-- TOC entry 5810 (class 0 OID 0)
-- Dependencies: 269
-- Name: carreras_niveles_academicos_id_carrera_nivel_academico_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.carreras_niveles_academicos_id_carrera_nivel_academico_seq OWNED BY public.carreras_niveles_academicos.id_carrera_nivel_academico;


--
-- TOC entry 219 (class 1259 OID 16407)
-- Name: configuraciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuraciones (
    id_configuracion integer NOT NULL,
    id_universidad integer NOT NULL,
    tipo character varying(200),
    descripcion character varying(500),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.configuraciones OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16406)
-- Name: configuraciones_id_configuracion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.configuraciones_id_configuracion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.configuraciones_id_configuracion_seq OWNER TO postgres;

--
-- TOC entry 5811 (class 0 OID 0)
-- Dependencies: 218
-- Name: configuraciones_id_configuracion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.configuraciones_id_configuracion_seq OWNED BY public.configuraciones.id_configuracion;


--
-- TOC entry 316 (class 1259 OID 17085)
-- Name: cuentas_cargos_conceptos_posgrados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cuentas_cargos_conceptos_posgrados (
    id_cuenta_cargo_concepto_posgrado integer NOT NULL,
    id_cuenta_cargo_posgrado_concepto integer NOT NULL,
    costo double precision,
    porcentaje integer,
    descuento double precision,
    monto_pagar double precision,
    fecha date,
    desglose boolean,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.cuentas_cargos_conceptos_posgrados OWNER TO postgres;

--
-- TOC entry 315 (class 1259 OID 17084)
-- Name: cuentas_cargos_conceptos_posg_id_cuenta_cargo_concepto_posg_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cuentas_cargos_conceptos_posg_id_cuenta_cargo_concepto_posg_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cuentas_cargos_conceptos_posg_id_cuenta_cargo_concepto_posg_seq OWNER TO postgres;

--
-- TOC entry 5812 (class 0 OID 0)
-- Dependencies: 315
-- Name: cuentas_cargos_conceptos_posg_id_cuenta_cargo_concepto_posg_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cuentas_cargos_conceptos_posg_id_cuenta_cargo_concepto_posg_seq OWNED BY public.cuentas_cargos_conceptos_posgrados.id_cuenta_cargo_concepto_posgrado;


--
-- TOC entry 312 (class 1259 OID 17052)
-- Name: cuentas_cargos_posgrados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cuentas_cargos_posgrados (
    id_cuenta_cargo_posgrado integer NOT NULL,
    id_posgrado_programa integer NOT NULL,
    nombre character varying(250),
    numero_formulario character varying(250),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.cuentas_cargos_posgrados OWNER TO postgres;

--
-- TOC entry 314 (class 1259 OID 17067)
-- Name: cuentas_cargos_posgrados_conceptos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cuentas_cargos_posgrados_conceptos (
    id_cuenta_cargo_posgrado_concepto integer NOT NULL,
    id_cuenta_cargo_posgrado integer NOT NULL,
    id_cuenta_concepto integer NOT NULL,
    tiene_descuento character varying(1),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.cuentas_cargos_posgrados_conceptos OWNER TO postgres;

--
-- TOC entry 313 (class 1259 OID 17066)
-- Name: cuentas_cargos_posgrados_conc_id_cuenta_cargo_posgrado_conc_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cuentas_cargos_posgrados_conc_id_cuenta_cargo_posgrado_conc_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cuentas_cargos_posgrados_conc_id_cuenta_cargo_posgrado_conc_seq OWNER TO postgres;

--
-- TOC entry 5813 (class 0 OID 0)
-- Dependencies: 313
-- Name: cuentas_cargos_posgrados_conc_id_cuenta_cargo_posgrado_conc_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cuentas_cargos_posgrados_conc_id_cuenta_cargo_posgrado_conc_seq OWNED BY public.cuentas_cargos_posgrados_conceptos.id_cuenta_cargo_posgrado_concepto;


--
-- TOC entry 311 (class 1259 OID 17051)
-- Name: cuentas_cargos_posgrados_id_cuenta_cargo_posgrado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cuentas_cargos_posgrados_id_cuenta_cargo_posgrado_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cuentas_cargos_posgrados_id_cuenta_cargo_posgrado_seq OWNER TO postgres;

--
-- TOC entry 5814 (class 0 OID 0)
-- Dependencies: 311
-- Name: cuentas_cargos_posgrados_id_cuenta_cargo_posgrado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cuentas_cargos_posgrados_id_cuenta_cargo_posgrado_seq OWNED BY public.cuentas_cargos_posgrados.id_cuenta_cargo_posgrado;


--
-- TOC entry 300 (class 1259 OID 16954)
-- Name: cuentas_conceptos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cuentas_conceptos (
    id_cuenta_concepto integer NOT NULL,
    nombre character varying(150),
    descripcion character varying(350),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.cuentas_conceptos OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 16953)
-- Name: cuentas_conceptos_id_cuenta_concepto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cuentas_conceptos_id_cuenta_concepto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cuentas_conceptos_id_cuenta_concepto_seq OWNER TO postgres;

--
-- TOC entry 5815 (class 0 OID 0)
-- Dependencies: 299
-- Name: cuentas_conceptos_id_cuenta_concepto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cuentas_conceptos_id_cuenta_concepto_seq OWNED BY public.cuentas_conceptos.id_cuenta_concepto;


--
-- TOC entry 252 (class 1259 OID 16628)
-- Name: departamentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departamentos (
    id_departamento integer NOT NULL,
    id_pais integer NOT NULL,
    nombre character varying(30),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.departamentos OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 16627)
-- Name: departamentos_id_departamento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.departamentos_id_departamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.departamentos_id_departamento_seq OWNER TO postgres;

--
-- TOC entry 5816 (class 0 OID 0)
-- Dependencies: 251
-- Name: departamentos_id_departamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.departamentos_id_departamento_seq OWNED BY public.departamentos.id_departamento;


--
-- TOC entry 296 (class 1259 OID 16938)
-- Name: dias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dias (
    id_dia integer NOT NULL,
    numero integer,
    nombre character varying(30),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.dias OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 16937)
-- Name: dias_id_dia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dias_id_dia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dias_id_dia_seq OWNER TO postgres;

--
-- TOC entry 5817 (class 0 OID 0)
-- Dependencies: 295
-- Name: dias_id_dia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dias_id_dia_seq OWNED BY public.dias.id_dia;


--
-- TOC entry 237 (class 1259 OID 16522)
-- Name: edificios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.edificios (
    id_edificio integer NOT NULL,
    id_campu integer,
    nombre character varying(70),
    direccion character varying(90),
    latitud character varying(30),
    longitud character varying(30),
    imagen character varying(255),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.edificios OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16521)
-- Name: edificios_id_edificio_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.edificios_id_edificio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.edificios_id_edificio_seq OWNER TO postgres;

--
-- TOC entry 5818 (class 0 OID 0)
-- Dependencies: 236
-- Name: edificios_id_edificio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.edificios_id_edificio_seq OWNED BY public.edificios.id_edificio;


--
-- TOC entry 264 (class 1259 OID 16691)
-- Name: emision_cedulas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.emision_cedulas (
    id_emision_cedula integer NOT NULL,
    nombre character varying(15) NOT NULL,
    descripcion character varying(45),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.emision_cedulas OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 16690)
-- Name: emision_cedulas_id_emision_cedula_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.emision_cedulas_id_emision_cedula_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.emision_cedulas_id_emision_cedula_seq OWNER TO postgres;

--
-- TOC entry 5819 (class 0 OID 0)
-- Dependencies: 263
-- Name: emision_cedulas_id_emision_cedula_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.emision_cedulas_id_emision_cedula_seq OWNED BY public.emision_cedulas.id_emision_cedula;


--
-- TOC entry 356 (class 1259 OID 18251)
-- Name: encrypted_log_table; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.encrypted_log_table (
    id integer NOT NULL,
    table_name bytea NOT NULL,
    id_registro_tabla_modificada bytea NOT NULL,
    action bytea NOT NULL,
    date bytea NOT NULL
);


ALTER TABLE public.encrypted_log_table OWNER TO postgres;

--
-- TOC entry 355 (class 1259 OID 18250)
-- Name: encrypted_log_table_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.encrypted_log_table_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.encrypted_log_table_id_seq OWNER TO postgres;

--
-- TOC entry 5820 (class 0 OID 0)
-- Dependencies: 355
-- Name: encrypted_log_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.encrypted_log_table_id_seq OWNED BY public.encrypted_log_table.id;


--
-- TOC entry 262 (class 1259 OID 16683)
-- Name: estados_civiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estados_civiles (
    id_estado_civil integer NOT NULL,
    nombre character varying(15) NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.estados_civiles OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 16682)
-- Name: estados_civiles_id_estado_civil_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.estados_civiles_id_estado_civil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.estados_civiles_id_estado_civil_seq OWNER TO postgres;

--
-- TOC entry 5821 (class 0 OID 0)
-- Dependencies: 261
-- Name: estados_civiles_id_estado_civil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.estados_civiles_id_estado_civil_seq OWNED BY public.estados_civiles.id_estado_civil;


--
-- TOC entry 338 (class 1259 OID 17278)
-- Name: extractos_bancarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.extractos_bancarios (
    id_extracto_bancario integer NOT NULL,
    nombre_completo character varying(200),
    carnet_identidad character varying(20),
    numero_codigo character varying(50),
    monto double precision,
    fecha date,
    hora time without time zone,
    procesando character varying(1) DEFAULT '0'::character varying,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.extractos_bancarios OWNER TO postgres;

--
-- TOC entry 337 (class 1259 OID 17277)
-- Name: extractos_bancarios_id_extracto_bancario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.extractos_bancarios_id_extracto_bancario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.extractos_bancarios_id_extracto_bancario_seq OWNER TO postgres;

--
-- TOC entry 5822 (class 0 OID 0)
-- Dependencies: 337
-- Name: extractos_bancarios_id_extracto_bancario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.extractos_bancarios_id_extracto_bancario_seq OWNED BY public.extractos_bancarios.id_extracto_bancario;


--
-- TOC entry 223 (class 1259 OID 16435)
-- Name: facultades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.facultades (
    id_facultad integer NOT NULL,
    id_area integer NOT NULL,
    nombre character varying(100) NOT NULL,
    nombre_abreviado character varying(50),
    direccion character varying(100),
    telefono character varying(100),
    telefono_interno character varying(100),
    fax character varying(20),
    email character varying(30),
    latitud character varying(25),
    longitud character varying(25),
    fecha_creacion date,
    escudo character varying(60),
    imagen character varying(60),
    estado_virtual character varying(1),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.facultades OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16535)
-- Name: facultades_edificios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.facultades_edificios (
    id_facultad_edificio integer NOT NULL,
    id_facultad integer,
    id_edificio integer,
    fecha_asignacion date,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.facultades_edificios OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16534)
-- Name: facultades_edificios_id_facultad_edificio_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.facultades_edificios_id_facultad_edificio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.facultades_edificios_id_facultad_edificio_seq OWNER TO postgres;

--
-- TOC entry 5823 (class 0 OID 0)
-- Dependencies: 238
-- Name: facultades_edificios_id_facultad_edificio_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.facultades_edificios_id_facultad_edificio_seq OWNED BY public.facultades_edificios.id_facultad_edificio;


--
-- TOC entry 222 (class 1259 OID 16434)
-- Name: facultades_id_facultad_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.facultades_id_facultad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.facultades_id_facultad_seq OWNER TO postgres;

--
-- TOC entry 5824 (class 0 OID 0)
-- Dependencies: 222
-- Name: facultades_id_facultad_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.facultades_id_facultad_seq OWNED BY public.facultades.id_facultad;


--
-- TOC entry 292 (class 1259 OID 16918)
-- Name: gestiones_periodos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gestiones_periodos (
    id_gestion_periodo integer NOT NULL,
    gestion integer NOT NULL,
    periodo integer NOT NULL,
    tipo character varying(1) NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.gestiones_periodos OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 16917)
-- Name: gestiones_periodos_id_gestion_periodo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gestiones_periodos_id_gestion_periodo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gestiones_periodos_id_gestion_periodo_seq OWNER TO postgres;

--
-- TOC entry 5825 (class 0 OID 0)
-- Dependencies: 291
-- Name: gestiones_periodos_id_gestion_periodo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gestiones_periodos_id_gestion_periodo_seq OWNED BY public.gestiones_periodos.id_gestion_periodo;


--
-- TOC entry 258 (class 1259 OID 16667)
-- Name: grupos_sanguineos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grupos_sanguineos (
    id_grupo_sanguineo integer NOT NULL,
    nombre character varying(15) NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.grupos_sanguineos OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 16666)
-- Name: grupos_sanguineos_id_grupo_sanguineo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grupos_sanguineos_id_grupo_sanguineo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grupos_sanguineos_id_grupo_sanguineo_seq OWNER TO postgres;

--
-- TOC entry 5826 (class 0 OID 0)
-- Dependencies: 257
-- Name: grupos_sanguineos_id_grupo_sanguineo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grupos_sanguineos_id_grupo_sanguineo_seq OWNED BY public.grupos_sanguineos.id_grupo_sanguineo;


--
-- TOC entry 298 (class 1259 OID 16946)
-- Name: horas_clases; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horas_clases (
    id_hora_clase integer NOT NULL,
    numero integer,
    hora_inicio time without time zone,
    hora_fin time without time zone,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.horas_clases OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 16945)
-- Name: horas_clases_id_hora_clase_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.horas_clases_id_hora_clase_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horas_clases_id_hora_clase_seq OWNER TO postgres;

--
-- TOC entry 5827 (class 0 OID 0)
-- Dependencies: 297
-- Name: horas_clases_id_hora_clase_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.horas_clases_id_hora_clase_seq OWNED BY public.horas_clases.id_hora_clase;


--
-- TOC entry 256 (class 1259 OID 16654)
-- Name: localidades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.localidades (
    id_localidad integer NOT NULL,
    id_provincia integer NOT NULL,
    nombre character varying(40) NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.localidades OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 16653)
-- Name: localidades_id_localidad_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.localidades_id_localidad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.localidades_id_localidad_seq OWNER TO postgres;

--
-- TOC entry 5828 (class 0 OID 0)
-- Dependencies: 255
-- Name: localidades_id_localidad_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.localidades_id_localidad_seq OWNED BY public.localidades.id_localidad;


--
-- TOC entry 354 (class 1259 OID 18241)
-- Name: log_table; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_table (
    id integer NOT NULL,
    table_name character varying(255) NOT NULL,
    id_registro_tabla_modificada integer NOT NULL,
    action text NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.log_table OWNER TO postgres;

--
-- TOC entry 353 (class 1259 OID 18240)
-- Name: log_table_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_table_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_table_id_seq OWNER TO postgres;

--
-- TOC entry 5829 (class 0 OID 0)
-- Dependencies: 353
-- Name: log_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_table_id_seq OWNED BY public.log_table.id;


--
-- TOC entry 229 (class 1259 OID 16471)
-- Name: menus; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menus (
    id_menu integer NOT NULL,
    id_menu_principal integer NOT NULL,
    nombre character varying(250) NOT NULL,
    directorio character varying(350) NOT NULL,
    icono character varying(70),
    imagen character varying(150),
    color character varying(25),
    orden integer,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.menus OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16470)
-- Name: menus_id_menu_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menus_id_menu_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menus_id_menu_seq OWNER TO postgres;

--
-- TOC entry 5830 (class 0 OID 0)
-- Dependencies: 228
-- Name: menus_id_menu_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menus_id_menu_seq OWNED BY public.menus.id_menu;


--
-- TOC entry 227 (class 1259 OID 16458)
-- Name: menus_principales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.menus_principales (
    id_menu_principal integer NOT NULL,
    id_modulo integer NOT NULL,
    nombre character varying(250) NOT NULL,
    icono character varying(70),
    orden integer,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.menus_principales OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16457)
-- Name: menus_principales_id_menu_principal_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.menus_principales_id_menu_principal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.menus_principales_id_menu_principal_seq OWNER TO postgres;

--
-- TOC entry 5831 (class 0 OID 0)
-- Dependencies: 226
-- Name: menus_principales_id_menu_principal_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.menus_principales_id_menu_principal_seq OWNED BY public.menus_principales.id_menu_principal;


--
-- TOC entry 276 (class 1259 OID 16775)
-- Name: modalidades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modalidades (
    id_modalidad integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion character varying(100),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.modalidades OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 16774)
-- Name: modalidades_id_modalidad_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modalidades_id_modalidad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.modalidades_id_modalidad_seq OWNER TO postgres;

--
-- TOC entry 5832 (class 0 OID 0)
-- Dependencies: 275
-- Name: modalidades_id_modalidad_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modalidades_id_modalidad_seq OWNED BY public.modalidades.id_modalidad;


--
-- TOC entry 225 (class 1259 OID 16450)
-- Name: modulos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modulos (
    id_modulo integer NOT NULL,
    nombre character varying(50) NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.modulos OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16449)
-- Name: modulos_id_modulo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modulos_id_modulo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.modulos_id_modulo_seq OWNER TO postgres;

--
-- TOC entry 5833 (class 0 OID 0)
-- Dependencies: 224
-- Name: modulos_id_modulo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modulos_id_modulo_seq OWNED BY public.modulos.id_modulo;


--
-- TOC entry 330 (class 1259 OID 17217)
-- Name: montos_excedentes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.montos_excedentes (
    id_monto_exedente integer NOT NULL,
    id_posgrado_transaccion_detalle integer NOT NULL,
    monto_excedente double precision,
    procesando character varying(1) DEFAULT '0'::character varying,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.montos_excedentes OWNER TO postgres;

--
-- TOC entry 329 (class 1259 OID 17216)
-- Name: montos_excedentes_id_monto_exedente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.montos_excedentes_id_monto_exedente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.montos_excedentes_id_monto_exedente_seq OWNER TO postgres;

--
-- TOC entry 5834 (class 0 OID 0)
-- Dependencies: 329
-- Name: montos_excedentes_id_monto_exedente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.montos_excedentes_id_monto_exedente_seq OWNED BY public.montos_excedentes.id_monto_exedente;


--
-- TOC entry 272 (class 1259 OID 16759)
-- Name: niveles_academicos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.niveles_academicos (
    id_nivel_academico integer NOT NULL,
    nombre character varying(35) NOT NULL,
    descripcion character varying(350),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.niveles_academicos OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 16758)
-- Name: niveles_academicos_id_nivel_academico_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.niveles_academicos_id_nivel_academico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.niveles_academicos_id_nivel_academico_seq OWNER TO postgres;

--
-- TOC entry 5835 (class 0 OID 0)
-- Dependencies: 271
-- Name: niveles_academicos_id_nivel_academico_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.niveles_academicos_id_nivel_academico_seq OWNED BY public.niveles_academicos.id_nivel_academico;


--
-- TOC entry 334 (class 1259 OID 17239)
-- Name: niveles_academicos_tramites_documentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.niveles_academicos_tramites_documentos (
    id_nivel_academico_tramite_documento integer NOT NULL,
    id_nivel_academico integer NOT NULL,
    id_tramite_documento integer NOT NULL,
    fecha timestamp without time zone DEFAULT now(),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.niveles_academicos_tramites_documentos OWNER TO postgres;

--
-- TOC entry 333 (class 1259 OID 17238)
-- Name: niveles_academicos_tramites_d_id_nivel_academico_tramite_do_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.niveles_academicos_tramites_d_id_nivel_academico_tramite_do_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.niveles_academicos_tramites_d_id_nivel_academico_tramite_do_seq OWNER TO postgres;

--
-- TOC entry 5836 (class 0 OID 0)
-- Dependencies: 333
-- Name: niveles_academicos_tramites_d_id_nivel_academico_tramite_do_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.niveles_academicos_tramites_d_id_nivel_academico_tramite_do_seq OWNED BY public.niveles_academicos_tramites_documentos.id_nivel_academico_tramite_documento;


--
-- TOC entry 250 (class 1259 OID 16620)
-- Name: paises; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paises (
    id_pais integer NOT NULL,
    nombre character varying(30) NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.paises OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 16619)
-- Name: paises_id_pais_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.paises_id_pais_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.paises_id_pais_seq OWNER TO postgres;

--
-- TOC entry 5837 (class 0 OID 0)
-- Dependencies: 249
-- Name: paises_id_pais_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.paises_id_pais_seq OWNED BY public.paises.id_pais;


--
-- TOC entry 266 (class 1259 OID 16699)
-- Name: personas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas (
    id_persona integer NOT NULL,
    id_localidad integer NOT NULL,
    numero_identificacion_personal character varying(15),
    id_emision_cedula integer NOT NULL,
    paterno character varying(20) NOT NULL,
    materno character varying(20),
    nombres character varying(65) NOT NULL,
    id_sexo integer NOT NULL,
    id_grupo_sanguineo integer NOT NULL,
    fecha_nacimiento date,
    direccion character varying(60),
    latitud character varying(30),
    longitud character varying(30),
    telefono_celular character varying(12),
    telefono_fijo character varying(12),
    zona character varying(50),
    id_estado_civil integer NOT NULL,
    email character varying(50),
    fotografia character varying(255) DEFAULT 'default.jpg'::character varying,
    abreviacion_titulo character varying(10),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 16864)
-- Name: personas_administrativos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas_administrativos (
    id_persona_administrativo integer NOT NULL,
    id_persona integer NOT NULL,
    cargo character varying(150),
    fecha date DEFAULT now(),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas_administrativos OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 16863)
-- Name: personas_administrativos_id_persona_administrativo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_administrativos_id_persona_administrativo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_administrativos_id_persona_administrativo_seq OWNER TO postgres;

--
-- TOC entry 5838 (class 0 OID 0)
-- Dependencies: 285
-- Name: personas_administrativos_id_persona_administrativo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_administrativos_id_persona_administrativo_seq OWNED BY public.personas_administrativos.id_persona_administrativo;


--
-- TOC entry 282 (class 1259 OID 16831)
-- Name: personas_alumnos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas_alumnos (
    id_persona_alumno integer NOT NULL,
    id_persona integer NOT NULL,
    id_carrera integer NOT NULL,
    fecha date DEFAULT now(),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas_alumnos OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 16830)
-- Name: personas_alumnos_id_persona_alumno_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_alumnos_id_persona_alumno_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_alumnos_id_persona_alumno_seq OWNER TO postgres;

--
-- TOC entry 5839 (class 0 OID 0)
-- Dependencies: 281
-- Name: personas_alumnos_id_persona_alumno_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_alumnos_id_persona_alumno_seq OWNED BY public.personas_alumnos.id_persona_alumno;


--
-- TOC entry 310 (class 1259 OID 17033)
-- Name: personas_alumnos_posgrados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas_alumnos_posgrados (
    id_persona_alumno_posgrado integer NOT NULL,
    id_persona integer NOT NULL,
    id_posgrado_programa integer NOT NULL,
    fecha date,
    inscrito character varying(1) DEFAULT '0'::character varying,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas_alumnos_posgrados OWNER TO postgres;

--
-- TOC entry 309 (class 1259 OID 17032)
-- Name: personas_alumnos_posgrados_id_persona_alumno_posgrado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_alumnos_posgrados_id_persona_alumno_posgrado_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_alumnos_posgrados_id_persona_alumno_posgrado_seq OWNER TO postgres;

--
-- TOC entry 5840 (class 0 OID 0)
-- Dependencies: 309
-- Name: personas_alumnos_posgrados_id_persona_alumno_posgrado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_alumnos_posgrados_id_persona_alumno_posgrado_seq OWNED BY public.personas_alumnos_posgrados.id_persona_alumno_posgrado;


--
-- TOC entry 290 (class 1259 OID 16898)
-- Name: personas_decanos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas_decanos (
    id_persona_decano integer NOT NULL,
    id_facultad integer NOT NULL,
    id_persona integer NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    resolucion character varying(255),
    firma_digital character varying(255),
    observacion character varying(255),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas_decanos OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 16897)
-- Name: personas_decanos_id_persona_decano_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_decanos_id_persona_decano_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_decanos_id_persona_decano_seq OWNER TO postgres;

--
-- TOC entry 5841 (class 0 OID 0)
-- Dependencies: 289
-- Name: personas_decanos_id_persona_decano_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_decanos_id_persona_decano_seq OWNED BY public.personas_decanos.id_persona_decano;


--
-- TOC entry 288 (class 1259 OID 16878)
-- Name: personas_directores_carreras; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas_directores_carreras (
    id_persona_director_carrera integer NOT NULL,
    id_carrera integer NOT NULL,
    id_persona integer NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    resolucion character varying(255),
    firma_digital character varying(255),
    observacion character varying(255),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas_directores_carreras OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 16877)
-- Name: personas_directores_carreras_id_persona_director_carrera_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_directores_carreras_id_persona_director_carrera_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_directores_carreras_id_persona_director_carrera_seq OWNER TO postgres;

--
-- TOC entry 5842 (class 0 OID 0)
-- Dependencies: 287
-- Name: personas_directores_carreras_id_persona_director_carrera_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_directores_carreras_id_persona_director_carrera_seq OWNED BY public.personas_directores_carreras.id_persona_director_carrera;


--
-- TOC entry 302 (class 1259 OID 16964)
-- Name: personas_directores_posgrados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas_directores_posgrados (
    id_persona_director_posgrado integer NOT NULL,
    id_persona integer NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    firma_digital character varying(255),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas_directores_posgrados OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 16963)
-- Name: personas_directores_posgrados_id_persona_director_posgrado_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_directores_posgrados_id_persona_director_posgrado_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_directores_posgrados_id_persona_director_posgrado_seq OWNER TO postgres;

--
-- TOC entry 5843 (class 0 OID 0)
-- Dependencies: 301
-- Name: personas_directores_posgrados_id_persona_director_posgrado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_directores_posgrados_id_persona_director_posgrado_seq OWNED BY public.personas_directores_posgrados.id_persona_director_posgrado;


--
-- TOC entry 284 (class 1259 OID 16850)
-- Name: personas_docentes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas_docentes (
    id_persona_docente integer NOT NULL,
    id_persona integer NOT NULL,
    fecha_ingreso date,
    fecha date DEFAULT now(),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas_docentes OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 16849)
-- Name: personas_docentes_id_persona_docente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_docentes_id_persona_docente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_docentes_id_persona_docente_seq OWNER TO postgres;

--
-- TOC entry 5844 (class 0 OID 0)
-- Dependencies: 283
-- Name: personas_docentes_id_persona_docente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_docentes_id_persona_docente_seq OWNED BY public.personas_docentes.id_persona_docente;


--
-- TOC entry 304 (class 1259 OID 16977)
-- Name: personas_facultades_administradores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas_facultades_administradores (
    id_persona_facultad_administrador integer NOT NULL,
    id_persona integer NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    firma_digital character varying(255),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas_facultades_administradores OWNER TO postgres;

--
-- TOC entry 303 (class 1259 OID 16976)
-- Name: personas_facultades_administr_id_persona_facultad_administr_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_facultades_administr_id_persona_facultad_administr_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_facultades_administr_id_persona_facultad_administr_seq OWNER TO postgres;

--
-- TOC entry 5845 (class 0 OID 0)
-- Dependencies: 303
-- Name: personas_facultades_administr_id_persona_facultad_administr_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_facultades_administr_id_persona_facultad_administr_seq OWNED BY public.personas_facultades_administradores.id_persona_facultad_administrador;


--
-- TOC entry 265 (class 1259 OID 16698)
-- Name: personas_id_persona_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_id_persona_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_id_persona_seq OWNER TO postgres;

--
-- TOC entry 5846 (class 0 OID 0)
-- Dependencies: 265
-- Name: personas_id_persona_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_id_persona_seq OWNED BY public.personas.id_persona;


--
-- TOC entry 306 (class 1259 OID 16990)
-- Name: personas_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.personas_roles (
    id_persona_rol integer NOT NULL,
    id_persona integer NOT NULL,
    id_rol integer NOT NULL,
    fecha_asignacion date,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.personas_roles OWNER TO postgres;

--
-- TOC entry 305 (class 1259 OID 16989)
-- Name: personas_roles_id_persona_rol_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.personas_roles_id_persona_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_roles_id_persona_rol_seq OWNER TO postgres;

--
-- TOC entry 5847 (class 0 OID 0)
-- Dependencies: 305
-- Name: personas_roles_id_persona_rol_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.personas_roles_id_persona_rol_seq OWNED BY public.personas_roles.id_persona_rol;


--
-- TOC entry 243 (class 1259 OID 16566)
-- Name: pisos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pisos (
    id_piso integer NOT NULL,
    numero integer,
    nombre character varying(30),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.pisos OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16574)
-- Name: pisos_bloques; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pisos_bloques (
    id_piso_bloque integer NOT NULL,
    id_bloque integer,
    id_piso integer,
    nombre character varying(30),
    cantidad_ambientes integer,
    imagen character varying(200),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.pisos_bloques OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 16573)
-- Name: pisos_bloques_id_piso_bloque_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pisos_bloques_id_piso_bloque_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pisos_bloques_id_piso_bloque_seq OWNER TO postgres;

--
-- TOC entry 5848 (class 0 OID 0)
-- Dependencies: 244
-- Name: pisos_bloques_id_piso_bloque_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pisos_bloques_id_piso_bloque_seq OWNED BY public.pisos_bloques.id_piso_bloque;


--
-- TOC entry 242 (class 1259 OID 16565)
-- Name: pisos_id_piso_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pisos_id_piso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pisos_id_piso_seq OWNER TO postgres;

--
-- TOC entry 5849 (class 0 OID 0)
-- Dependencies: 242
-- Name: pisos_id_piso_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pisos_id_piso_seq OWNED BY public.pisos.id_piso;


--
-- TOC entry 336 (class 1259 OID 17258)
-- Name: posgrado_alumnos_documentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrado_alumnos_documentos (
    id_posgrado_alumno_documento integer NOT NULL,
    id_persona_alumno_posgrado integer NOT NULL,
    id_nivel_academico_tramite_documento integer NOT NULL,
    fecha_subida timestamp without time zone DEFAULT now(),
    archivo character varying(100),
    verificado character varying(1) DEFAULT 'N'::character varying,
    fecha_verificacion timestamp without time zone,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrado_alumnos_documentos OWNER TO postgres;

--
-- TOC entry 335 (class 1259 OID 17257)
-- Name: posgrado_alumnos_documentos_id_posgrado_alumno_documento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrado_alumnos_documentos_id_posgrado_alumno_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrado_alumnos_documentos_id_posgrado_alumno_documento_seq OWNER TO postgres;

--
-- TOC entry 5850 (class 0 OID 0)
-- Dependencies: 335
-- Name: posgrado_alumnos_documentos_id_posgrado_alumno_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrado_alumnos_documentos_id_posgrado_alumno_documento_seq OWNED BY public.posgrado_alumnos_documentos.id_posgrado_alumno_documento;


--
-- TOC entry 346 (class 1259 OID 17332)
-- Name: posgrado_asignaciones_docentes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrado_asignaciones_docentes (
    id_posgrado_asignacion_docente integer NOT NULL,
    id_persona_docente integer NOT NULL,
    id_posgrado_materia integer NOT NULL,
    id_posgrado_tipo_evaluacion_nota integer DEFAULT 0,
    id_gestion_periodo integer NOT NULL,
    tipo_calificacion character varying(3) DEFAULT 'N'::character varying,
    grupo character varying(3),
    cupo_maximo_estudiante integer DEFAULT 0,
    finaliza_planilla_calificacion character varying(1) DEFAULT 'N'::character varying,
    fecha_limite_examen_final timestamp without time zone,
    fecha_limite_nota_2da_instancia timestamp without time zone,
    fecha_limite_nota_examen_mesa timestamp without time zone,
    fecha_finalizacion_planilla timestamp without time zone DEFAULT now(),
    hash character varying(500),
    codigo_barras character varying(500),
    codigo_qr character varying(500),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrado_asignaciones_docentes OWNER TO postgres;

--
-- TOC entry 345 (class 1259 OID 17331)
-- Name: posgrado_asignaciones_docente_id_posgrado_asignacion_docent_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrado_asignaciones_docente_id_posgrado_asignacion_docent_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrado_asignaciones_docente_id_posgrado_asignacion_docent_seq OWNER TO postgres;

--
-- TOC entry 5851 (class 0 OID 0)
-- Dependencies: 345
-- Name: posgrado_asignaciones_docente_id_posgrado_asignacion_docent_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrado_asignaciones_docente_id_posgrado_asignacion_docent_seq OWNED BY public.posgrado_asignaciones_docentes.id_posgrado_asignacion_docente;


--
-- TOC entry 350 (class 1259 OID 17413)
-- Name: posgrado_asignaciones_horarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrado_asignaciones_horarios (
    id_posgrado_asignacion_horario integer NOT NULL,
    id_posgrado_asignacion_docente integer NOT NULL,
    id_ambiente integer NOT NULL,
    id_dia integer NOT NULL,
    id_hora_clase integer NOT NULL,
    clase_link character varying(255),
    clase_descripcion character varying(500),
    fecha_registro date DEFAULT now(),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrado_asignaciones_horarios OWNER TO postgres;

--
-- TOC entry 349 (class 1259 OID 17412)
-- Name: posgrado_asignaciones_horario_id_posgrado_asignacion_horari_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrado_asignaciones_horario_id_posgrado_asignacion_horari_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrado_asignaciones_horario_id_posgrado_asignacion_horari_seq OWNER TO postgres;

--
-- TOC entry 5852 (class 0 OID 0)
-- Dependencies: 349
-- Name: posgrado_asignaciones_horario_id_posgrado_asignacion_horari_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrado_asignaciones_horario_id_posgrado_asignacion_horari_seq OWNED BY public.posgrado_asignaciones_horarios.id_posgrado_asignacion_horario;


--
-- TOC entry 348 (class 1259 OID 17367)
-- Name: posgrado_calificaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrado_calificaciones (
    id_postgrado_calificacion integer NOT NULL,
    id_persona_alumno_posgrado integer NOT NULL,
    id_posgrado_asignacion_docente integer NOT NULL,
    tipo_programacion integer DEFAULT 0,
    control_asistencia jsonb,
    configuracion jsonb,
    calificacion1 double precision DEFAULT 0,
    calificacion2 double precision DEFAULT 0,
    calificacion3 double precision DEFAULT 0,
    calificacion4 double precision DEFAULT 0,
    calificacion5 double precision DEFAULT 0,
    calificacion6 double precision DEFAULT 0,
    calificacion7 double precision DEFAULT 0,
    calificacion8 double precision DEFAULT 0,
    calificacion9 double precision DEFAULT 0,
    calificacion10 double precision DEFAULT 0,
    calificacion11 double precision DEFAULT 0,
    calificacion12 double precision DEFAULT 0,
    calificacion13 double precision DEFAULT 0,
    calificacion14 double precision DEFAULT 0,
    calificacion15 double precision DEFAULT 0,
    calificacion16 double precision DEFAULT 0,
    calificacion17 double precision DEFAULT 0,
    calificacion18 double precision DEFAULT 0,
    calificacion19 double precision DEFAULT 0,
    calificacion20 double precision DEFAULT 0,
    nota_final double precision DEFAULT 0,
    nota_2da_instancia double precision DEFAULT 0,
    nota_examen_mesa double precision DEFAULT 0,
    observacion character varying(1) DEFAULT 'R'::character varying,
    tipo character varying(1) DEFAULT 'N'::character varying,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrado_calificaciones OWNER TO postgres;

--
-- TOC entry 347 (class 1259 OID 17366)
-- Name: posgrado_calificaciones_id_postgrado_calificacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrado_calificaciones_id_postgrado_calificacion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrado_calificaciones_id_postgrado_calificacion_seq OWNER TO postgres;

--
-- TOC entry 5853 (class 0 OID 0)
-- Dependencies: 347
-- Name: posgrado_calificaciones_id_postgrado_calificacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrado_calificaciones_id_postgrado_calificacion_seq OWNED BY public.posgrado_calificaciones.id_postgrado_calificacion;


--
-- TOC entry 352 (class 1259 OID 17444)
-- Name: posgrado_clases_videos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrado_clases_videos (
    id_posgrado_clase_video integer NOT NULL,
    id_posgrado_asignacion_horario integer NOT NULL,
    clase_link character varying(255),
    clase_fecha date,
    clase_hora_inicio timestamp without time zone,
    clase_hora_fin timestamp without time zone,
    clase_duracion timestamp without time zone,
    fecha_registro date DEFAULT now(),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrado_clases_videos OWNER TO postgres;

--
-- TOC entry 351 (class 1259 OID 17443)
-- Name: posgrado_clases_videos_id_posgrado_clase_video_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrado_clases_videos_id_posgrado_clase_video_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrado_clases_videos_id_posgrado_clase_video_seq OWNER TO postgres;

--
-- TOC entry 5854 (class 0 OID 0)
-- Dependencies: 351
-- Name: posgrado_clases_videos_id_posgrado_clase_video_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrado_clases_videos_id_posgrado_clase_video_seq OWNED BY public.posgrado_clases_videos.id_posgrado_clase_video;


--
-- TOC entry 342 (class 1259 OID 17295)
-- Name: posgrado_materias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrado_materias (
    id_posgrado_materia integer NOT NULL,
    id_posgrado_programa integer NOT NULL,
    id_posgrado_nivel integer NOT NULL,
    sigla character varying(6) NOT NULL,
    nombre character varying(100) NOT NULL,
    nivel_curso integer,
    cantidad_hora_teorica integer DEFAULT 0,
    cantidad_hora_practica integer DEFAULT 0,
    cantidad_hora_laboratorio integer DEFAULT 0,
    cantidad_hora_plataforma integer DEFAULT 0,
    cantidad_hora_virtual integer DEFAULT 0,
    cantidad_credito integer DEFAULT 0,
    color character varying(7) DEFAULT '#000000'::character varying,
    icono character varying(35) DEFAULT ''::character varying,
    imagen character varying(250) DEFAULT ''::character varying,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrado_materias OWNER TO postgres;

--
-- TOC entry 341 (class 1259 OID 17294)
-- Name: posgrado_materias_id_posgrado_materia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrado_materias_id_posgrado_materia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrado_materias_id_posgrado_materia_seq OWNER TO postgres;

--
-- TOC entry 5855 (class 0 OID 0)
-- Dependencies: 341
-- Name: posgrado_materias_id_posgrado_materia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrado_materias_id_posgrado_materia_seq OWNED BY public.posgrado_materias.id_posgrado_materia;


--
-- TOC entry 340 (class 1259 OID 17287)
-- Name: posgrado_niveles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrado_niveles (
    id_posgrado_nivel integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion character varying(100),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrado_niveles OWNER TO postgres;

--
-- TOC entry 339 (class 1259 OID 17286)
-- Name: posgrado_niveles_id_posgrado_nivel_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrado_niveles_id_posgrado_nivel_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrado_niveles_id_posgrado_nivel_seq OWNER TO postgres;

--
-- TOC entry 5856 (class 0 OID 0)
-- Dependencies: 339
-- Name: posgrado_niveles_id_posgrado_nivel_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrado_niveles_id_posgrado_nivel_seq OWNED BY public.posgrado_niveles.id_posgrado_nivel;


--
-- TOC entry 344 (class 1259 OID 17322)
-- Name: posgrado_tipos_evaluaciones_notas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrado_tipos_evaluaciones_notas (
    id_posgrado_tipo_evaluacion_nota integer NOT NULL,
    nombre character varying(3) NOT NULL,
    configuracion json NOT NULL,
    nota_minima_aprobacion integer,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrado_tipos_evaluaciones_notas OWNER TO postgres;

--
-- TOC entry 343 (class 1259 OID 17321)
-- Name: posgrado_tipos_evaluaciones_n_id_posgrado_tipo_evaluacion_n_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrado_tipos_evaluaciones_n_id_posgrado_tipo_evaluacion_n_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrado_tipos_evaluaciones_n_id_posgrado_tipo_evaluacion_n_seq OWNER TO postgres;

--
-- TOC entry 5857 (class 0 OID 0)
-- Dependencies: 343
-- Name: posgrado_tipos_evaluaciones_n_id_posgrado_tipo_evaluacion_n_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrado_tipos_evaluaciones_n_id_posgrado_tipo_evaluacion_n_seq OWNED BY public.posgrado_tipos_evaluaciones_notas.id_posgrado_tipo_evaluacion_nota;


--
-- TOC entry 318 (class 1259 OID 17098)
-- Name: posgrados_contratos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrados_contratos (
    id_posgrado_contrato integer NOT NULL,
    id_cuenta_cargo_posgrado integer NOT NULL,
    id_persona_alumno_posgrado integer NOT NULL,
    numero_cuotas integer,
    id_persona_director_posgrado integer NOT NULL,
    id_persona_facultad_administrador integer NOT NULL,
    id_persona_decano integer NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrados_contratos OWNER TO postgres;

--
-- TOC entry 320 (class 1259 OID 17131)
-- Name: posgrados_contratos_detalles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrados_contratos_detalles (
    id_posgrado_contrato_detalle integer NOT NULL,
    id_posgrado_contrato integer NOT NULL,
    id_cuenta_cargo_concepto_posgrado integer NOT NULL,
    pagado boolean,
    monto_pagado double precision,
    monto_adeudado double precision,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrados_contratos_detalles OWNER TO postgres;

--
-- TOC entry 322 (class 1259 OID 17149)
-- Name: posgrados_contratos_detalles_desglose; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrados_contratos_detalles_desglose (
    id_posgrado_desglose integer NOT NULL,
    id_posgrado_contrato_detalle integer NOT NULL,
    monto double precision,
    descripcion character varying(30),
    pagado boolean,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrados_contratos_detalles_desglose OWNER TO postgres;

--
-- TOC entry 321 (class 1259 OID 17148)
-- Name: posgrados_contratos_detalles_desglose_id_posgrado_desglose_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrados_contratos_detalles_desglose_id_posgrado_desglose_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrados_contratos_detalles_desglose_id_posgrado_desglose_seq OWNER TO postgres;

--
-- TOC entry 5858 (class 0 OID 0)
-- Dependencies: 321
-- Name: posgrados_contratos_detalles_desglose_id_posgrado_desglose_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrados_contratos_detalles_desglose_id_posgrado_desglose_seq OWNED BY public.posgrados_contratos_detalles_desglose.id_posgrado_desglose;


--
-- TOC entry 319 (class 1259 OID 17130)
-- Name: posgrados_contratos_detalles_id_posgrado_contrato_detalle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrados_contratos_detalles_id_posgrado_contrato_detalle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrados_contratos_detalles_id_posgrado_contrato_detalle_seq OWNER TO postgres;

--
-- TOC entry 5859 (class 0 OID 0)
-- Dependencies: 319
-- Name: posgrados_contratos_detalles_id_posgrado_contrato_detalle_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrados_contratos_detalles_id_posgrado_contrato_detalle_seq OWNED BY public.posgrados_contratos_detalles.id_posgrado_contrato_detalle;


--
-- TOC entry 317 (class 1259 OID 17097)
-- Name: posgrados_contratos_id_posgrado_contrato_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrados_contratos_id_posgrado_contrato_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrados_contratos_id_posgrado_contrato_seq OWNER TO postgres;

--
-- TOC entry 5860 (class 0 OID 0)
-- Dependencies: 317
-- Name: posgrados_contratos_id_posgrado_contrato_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrados_contratos_id_posgrado_contrato_seq OWNED BY public.posgrados_contratos.id_posgrado_contrato;


--
-- TOC entry 308 (class 1259 OID 17008)
-- Name: posgrados_programas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrados_programas (
    id_posgrado_programa integer NOT NULL,
    id_nivel_academico integer NOT NULL,
    id_carrera integer NOT NULL,
    gestion integer,
    nombre character varying(100),
    id_modalidad integer NOT NULL,
    fecha_inicio date,
    fecha_fin date,
    fecha_inicio_inscrito date,
    fecha_fin_inscrito date,
    numero_max_cuotas integer,
    documento character varying(500),
    costo_total double precision,
    formato_contrato text,
    formato_contrato_docente text,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrados_programas OWNER TO postgres;

--
-- TOC entry 307 (class 1259 OID 17007)
-- Name: posgrados_programas_id_posgrado_programa_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrados_programas_id_posgrado_programa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrados_programas_id_posgrado_programa_seq OWNER TO postgres;

--
-- TOC entry 5861 (class 0 OID 0)
-- Dependencies: 307
-- Name: posgrados_programas_id_posgrado_programa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrados_programas_id_posgrado_programa_seq OWNED BY public.posgrados_programas.id_posgrado_programa;


--
-- TOC entry 324 (class 1259 OID 17162)
-- Name: posgrados_transacciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrados_transacciones (
    id_posgrado_transaccion integer NOT NULL,
    id_posgrado_contrato integer NOT NULL,
    id_persona_alumno_posgrado integer NOT NULL,
    fecha_transaccion date,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrados_transacciones OWNER TO postgres;

--
-- TOC entry 326 (class 1259 OID 17180)
-- Name: posgrados_transacciones_detalles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrados_transacciones_detalles (
    id_posgrado_transaccion_detalle integer NOT NULL,
    id_posgrado_transaccion integer NOT NULL,
    id_posgrado_contrato_detalle integer NOT NULL,
    fecha_deposito date,
    numero_deposito character varying(100),
    monto_deposito double precision,
    fotografia_deposito character varying(255),
    usado_transaccion character varying(1) DEFAULT '0'::character varying,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrados_transacciones_detalles OWNER TO postgres;

--
-- TOC entry 325 (class 1259 OID 17179)
-- Name: posgrados_transacciones_detal_id_posgrado_transaccion_detal_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrados_transacciones_detal_id_posgrado_transaccion_detal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrados_transacciones_detal_id_posgrado_transaccion_detal_seq OWNER TO postgres;

--
-- TOC entry 5862 (class 0 OID 0)
-- Dependencies: 325
-- Name: posgrados_transacciones_detal_id_posgrado_transaccion_detal_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrados_transacciones_detal_id_posgrado_transaccion_detal_seq OWNED BY public.posgrados_transacciones_detalles.id_posgrado_transaccion_detalle;


--
-- TOC entry 328 (class 1259 OID 17199)
-- Name: posgrados_transacciones_detalles_desglose; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posgrados_transacciones_detalles_desglose (
    id_transaccion_desglose integer NOT NULL,
    id_posgrado_contrato_detalle integer NOT NULL,
    id_posgrado_transaccion_detalle integer NOT NULL,
    monto_desglosado double precision,
    descripcion character varying(100),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.posgrados_transacciones_detalles_desglose OWNER TO postgres;

--
-- TOC entry 327 (class 1259 OID 17198)
-- Name: posgrados_transacciones_detalles_de_id_transaccion_desglose_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrados_transacciones_detalles_de_id_transaccion_desglose_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrados_transacciones_detalles_de_id_transaccion_desglose_seq OWNER TO postgres;

--
-- TOC entry 5863 (class 0 OID 0)
-- Dependencies: 327
-- Name: posgrados_transacciones_detalles_de_id_transaccion_desglose_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrados_transacciones_detalles_de_id_transaccion_desglose_seq OWNED BY public.posgrados_transacciones_detalles_desglose.id_transaccion_desglose;


--
-- TOC entry 323 (class 1259 OID 17161)
-- Name: posgrados_transacciones_id_posgrado_transaccion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.posgrados_transacciones_id_posgrado_transaccion_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.posgrados_transacciones_id_posgrado_transaccion_seq OWNER TO postgres;

--
-- TOC entry 5864 (class 0 OID 0)
-- Dependencies: 323
-- Name: posgrados_transacciones_id_posgrado_transaccion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.posgrados_transacciones_id_posgrado_transaccion_seq OWNED BY public.posgrados_transacciones.id_posgrado_transaccion;


--
-- TOC entry 254 (class 1259 OID 16641)
-- Name: provincias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.provincias (
    id_provincia integer NOT NULL,
    id_departamento integer NOT NULL,
    nombre character varying(40),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.provincias OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 16640)
-- Name: provincias_id_provincia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.provincias_id_provincia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.provincias_id_provincia_seq OWNER TO postgres;

--
-- TOC entry 5865 (class 0 OID 0)
-- Dependencies: 253
-- Name: provincias_id_provincia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.provincias_id_provincia_seq OWNED BY public.provincias.id_provincia;


--
-- TOC entry 231 (class 1259 OID 16486)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id_rol integer NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion character varying(200),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16485)
-- Name: roles_id_rol_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_rol_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_rol_seq OWNER TO postgres;

--
-- TOC entry 5866 (class 0 OID 0)
-- Dependencies: 230
-- Name: roles_id_rol_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_rol_seq OWNED BY public.roles.id_rol;


--
-- TOC entry 233 (class 1259 OID 16494)
-- Name: roles_menus_principales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles_menus_principales (
    id_rol_menu_principal integer NOT NULL,
    id_rol integer NOT NULL,
    id_menu_principal integer NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.roles_menus_principales OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16493)
-- Name: roles_menus_principales_id_rol_menu_principal_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_menus_principales_id_rol_menu_principal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_menus_principales_id_rol_menu_principal_seq OWNER TO postgres;

--
-- TOC entry 5867 (class 0 OID 0)
-- Dependencies: 232
-- Name: roles_menus_principales_id_rol_menu_principal_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_menus_principales_id_rol_menu_principal_seq OWNED BY public.roles_menus_principales.id_rol_menu_principal;


--
-- TOC entry 274 (class 1259 OID 16767)
-- Name: sedes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sedes (
    id_sede integer NOT NULL,
    nombre character varying(35) NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.sedes OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 16766)
-- Name: sedes_id_sede_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sedes_id_sede_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sedes_id_sede_seq OWNER TO postgres;

--
-- TOC entry 5868 (class 0 OID 0)
-- Dependencies: 273
-- Name: sedes_id_sede_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sedes_id_sede_seq OWNED BY public.sedes.id_sede;


--
-- TOC entry 260 (class 1259 OID 16675)
-- Name: sexos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sexos (
    id_sexo integer NOT NULL,
    nombre character varying(15) NOT NULL,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.sexos OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 16674)
-- Name: sexos_id_sexo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sexos_id_sexo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sexos_id_sexo_seq OWNER TO postgres;

--
-- TOC entry 5869 (class 0 OID 0)
-- Dependencies: 259
-- Name: sexos_id_sexo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sexos_id_sexo_seq OWNED BY public.sexos.id_sexo;


--
-- TOC entry 246 (class 1259 OID 16592)
-- Name: tipos_ambientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_ambientes (
    id_tipo_ambiente integer NOT NULL,
    nombre character varying,
    estado character varying
);


ALTER TABLE public.tipos_ambientes OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 16926)
-- Name: tipos_evaluaciones_notas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_evaluaciones_notas (
    id_tipo_evaluacion_nota integer NOT NULL,
    nombre character varying(3) NOT NULL,
    parcial integer DEFAULT 0,
    practica integer DEFAULT 0,
    laboratorio integer DEFAULT 0,
    examen_final integer DEFAULT 0,
    nota_minima_aprobacion integer,
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.tipos_evaluaciones_notas OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 16925)
-- Name: tipos_evaluaciones_notas_id_tipo_evaluacion_nota_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipos_evaluaciones_notas_id_tipo_evaluacion_nota_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipos_evaluaciones_notas_id_tipo_evaluacion_nota_seq OWNER TO postgres;

--
-- TOC entry 5870 (class 0 OID 0)
-- Dependencies: 293
-- Name: tipos_evaluaciones_notas_id_tipo_evaluacion_nota_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipos_evaluaciones_notas_id_tipo_evaluacion_nota_seq OWNED BY public.tipos_evaluaciones_notas.id_tipo_evaluacion_nota;


--
-- TOC entry 280 (class 1259 OID 16813)
-- Name: tipos_personas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_personas (
    id_tipo_persona integer NOT NULL,
    id_persona integer NOT NULL,
    id_rol integer NOT NULL,
    tipo character varying(1),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.tipos_personas OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 16812)
-- Name: tipos_personas_id_tipo_persona_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipos_personas_id_tipo_persona_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipos_personas_id_tipo_persona_seq OWNER TO postgres;

--
-- TOC entry 5871 (class 0 OID 0)
-- Dependencies: 279
-- Name: tipos_personas_id_tipo_persona_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipos_personas_id_tipo_persona_seq OWNED BY public.tipos_personas.id_tipo_persona;


--
-- TOC entry 332 (class 1259 OID 17231)
-- Name: tramites_documentos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tramites_documentos (
    id_tramite_documento integer NOT NULL,
    nombre character varying(80),
    descripcion character varying(250),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.tramites_documentos OWNER TO postgres;

--
-- TOC entry 331 (class 1259 OID 17230)
-- Name: tramites_documentos_id_tramite_documento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tramites_documentos_id_tramite_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tramites_documentos_id_tramite_documento_seq OWNER TO postgres;

--
-- TOC entry 5872 (class 0 OID 0)
-- Dependencies: 331
-- Name: tramites_documentos_id_tramite_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tramites_documentos_id_tramite_documento_seq OWNED BY public.tramites_documentos.id_tramite_documento;


--
-- TOC entry 217 (class 1259 OID 16399)
-- Name: universidades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.universidades (
    id_universidad integer NOT NULL,
    nombre character varying(150),
    nombre_abreviado character varying(100),
    inicial character varying(50),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.universidades OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16398)
-- Name: universidades_id_universidad_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.universidades_id_universidad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.universidades_id_universidad_seq OWNER TO postgres;

--
-- TOC entry 5873 (class 0 OID 0)
-- Dependencies: 216
-- Name: universidades_id_universidad_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.universidades_id_universidad_seq OWNED BY public.universidades.id_universidad;


--
-- TOC entry 268 (class 1259 OID 16735)
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id_usuario integer NOT NULL,
    id_persona integer NOT NULL,
    nombreemail character varying(100),
    password character varying(350),
    tipo integer,
    fecha date DEFAULT now(),
    fecha_finalizacion date,
    observacion character varying(255),
    estado character varying(1) DEFAULT 'S'::character varying
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 16734)
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_usuario_seq OWNER TO postgres;

--
-- TOC entry 5874 (class 0 OID 0)
-- Dependencies: 267
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_usuario_seq OWNED BY public.usuarios.id_usuario;


--
-- TOC entry 5054 (class 2604 OID 16603)
-- Name: ambientes id_ambiente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ambientes ALTER COLUMN id_ambiente SET DEFAULT nextval('public.ambientes_id_ambiente_seq'::regclass);


--
-- TOC entry 5028 (class 2604 OID 16425)
-- Name: areas id_area; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.areas ALTER COLUMN id_area SET DEFAULT nextval('public.areas_id_area_seq'::regclass);


--
-- TOC entry 5048 (class 2604 OID 16556)
-- Name: bloques id_bloque; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bloques ALTER COLUMN id_bloque SET DEFAULT nextval('public.bloques_id_bloque_seq'::regclass);


--
-- TOC entry 5042 (class 2604 OID 16515)
-- Name: campus id_campu; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campus ALTER COLUMN id_campu SET DEFAULT nextval('public.campus_id_campu_seq'::regclass);


--
-- TOC entry 5086 (class 2604 OID 16786)
-- Name: carreras id_carrera; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras ALTER COLUMN id_carrera SET DEFAULT nextval('public.carreras_id_carrera_seq'::regclass);


--
-- TOC entry 5078 (class 2604 OID 16754)
-- Name: carreras_niveles_academicos id_carrera_nivel_academico; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_niveles_academicos ALTER COLUMN id_carrera_nivel_academico SET DEFAULT nextval('public.carreras_niveles_academicos_id_carrera_nivel_academico_seq'::regclass);


--
-- TOC entry 5026 (class 2604 OID 16410)
-- Name: configuraciones id_configuracion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuraciones ALTER COLUMN id_configuracion SET DEFAULT nextval('public.configuraciones_id_configuracion_seq'::regclass);


--
-- TOC entry 5132 (class 2604 OID 17088)
-- Name: cuentas_cargos_conceptos_posgrados id_cuenta_cargo_concepto_posgrado; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_conceptos_posgrados ALTER COLUMN id_cuenta_cargo_concepto_posgrado SET DEFAULT nextval('public.cuentas_cargos_conceptos_posg_id_cuenta_cargo_concepto_posg_seq'::regclass);


--
-- TOC entry 5128 (class 2604 OID 17055)
-- Name: cuentas_cargos_posgrados id_cuenta_cargo_posgrado; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_posgrados ALTER COLUMN id_cuenta_cargo_posgrado SET DEFAULT nextval('public.cuentas_cargos_posgrados_id_cuenta_cargo_posgrado_seq'::regclass);


--
-- TOC entry 5130 (class 2604 OID 17070)
-- Name: cuentas_cargos_posgrados_conceptos id_cuenta_cargo_posgrado_concepto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_posgrados_conceptos ALTER COLUMN id_cuenta_cargo_posgrado_concepto SET DEFAULT nextval('public.cuentas_cargos_posgrados_conc_id_cuenta_cargo_posgrado_conc_seq'::regclass);


--
-- TOC entry 5115 (class 2604 OID 16957)
-- Name: cuentas_conceptos id_cuenta_concepto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_conceptos ALTER COLUMN id_cuenta_concepto SET DEFAULT nextval('public.cuentas_conceptos_id_cuenta_concepto_seq'::regclass);


--
-- TOC entry 5058 (class 2604 OID 16631)
-- Name: departamentos id_departamento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departamentos ALTER COLUMN id_departamento SET DEFAULT nextval('public.departamentos_id_departamento_seq'::regclass);


--
-- TOC entry 5111 (class 2604 OID 16941)
-- Name: dias id_dia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dias ALTER COLUMN id_dia SET DEFAULT nextval('public.dias_id_dia_seq'::regclass);


--
-- TOC entry 5044 (class 2604 OID 16525)
-- Name: edificios id_edificio; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edificios ALTER COLUMN id_edificio SET DEFAULT nextval('public.edificios_id_edificio_seq'::regclass);


--
-- TOC entry 5070 (class 2604 OID 16694)
-- Name: emision_cedulas id_emision_cedula; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emision_cedulas ALTER COLUMN id_emision_cedula SET DEFAULT nextval('public.emision_cedulas_id_emision_cedula_seq'::regclass);


--
-- TOC entry 5220 (class 2604 OID 18254)
-- Name: encrypted_log_table id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.encrypted_log_table ALTER COLUMN id SET DEFAULT nextval('public.encrypted_log_table_id_seq'::regclass);


--
-- TOC entry 5068 (class 2604 OID 16686)
-- Name: estados_civiles id_estado_civil; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estados_civiles ALTER COLUMN id_estado_civil SET DEFAULT nextval('public.estados_civiles_id_estado_civil_seq'::regclass);


--
-- TOC entry 5159 (class 2604 OID 17281)
-- Name: extractos_bancarios id_extracto_bancario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.extractos_bancarios ALTER COLUMN id_extracto_bancario SET DEFAULT nextval('public.extractos_bancarios_id_extracto_bancario_seq'::regclass);


--
-- TOC entry 5030 (class 2604 OID 16438)
-- Name: facultades id_facultad; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facultades ALTER COLUMN id_facultad SET DEFAULT nextval('public.facultades_id_facultad_seq'::regclass);


--
-- TOC entry 5046 (class 2604 OID 16538)
-- Name: facultades_edificios id_facultad_edificio; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facultades_edificios ALTER COLUMN id_facultad_edificio SET DEFAULT nextval('public.facultades_edificios_id_facultad_edificio_seq'::regclass);


--
-- TOC entry 5103 (class 2604 OID 16921)
-- Name: gestiones_periodos id_gestion_periodo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gestiones_periodos ALTER COLUMN id_gestion_periodo SET DEFAULT nextval('public.gestiones_periodos_id_gestion_periodo_seq'::regclass);


--
-- TOC entry 5064 (class 2604 OID 16670)
-- Name: grupos_sanguineos id_grupo_sanguineo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupos_sanguineos ALTER COLUMN id_grupo_sanguineo SET DEFAULT nextval('public.grupos_sanguineos_id_grupo_sanguineo_seq'::regclass);


--
-- TOC entry 5113 (class 2604 OID 16949)
-- Name: horas_clases id_hora_clase; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horas_clases ALTER COLUMN id_hora_clase SET DEFAULT nextval('public.horas_clases_id_hora_clase_seq'::regclass);


--
-- TOC entry 5062 (class 2604 OID 16657)
-- Name: localidades id_localidad; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localidades ALTER COLUMN id_localidad SET DEFAULT nextval('public.localidades_id_localidad_seq'::regclass);


--
-- TOC entry 5218 (class 2604 OID 18244)
-- Name: log_table id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_table ALTER COLUMN id SET DEFAULT nextval('public.log_table_id_seq'::regclass);


--
-- TOC entry 5036 (class 2604 OID 16474)
-- Name: menus id_menu; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menus ALTER COLUMN id_menu SET DEFAULT nextval('public.menus_id_menu_seq'::regclass);


--
-- TOC entry 5034 (class 2604 OID 16461)
-- Name: menus_principales id_menu_principal; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menus_principales ALTER COLUMN id_menu_principal SET DEFAULT nextval('public.menus_principales_id_menu_principal_seq'::regclass);


--
-- TOC entry 5084 (class 2604 OID 16778)
-- Name: modalidades id_modalidad; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modalidades ALTER COLUMN id_modalidad SET DEFAULT nextval('public.modalidades_id_modalidad_seq'::regclass);


--
-- TOC entry 5032 (class 2604 OID 16453)
-- Name: modulos id_modulo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modulos ALTER COLUMN id_modulo SET DEFAULT nextval('public.modulos_id_modulo_seq'::regclass);


--
-- TOC entry 5147 (class 2604 OID 17220)
-- Name: montos_excedentes id_monto_exedente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.montos_excedentes ALTER COLUMN id_monto_exedente SET DEFAULT nextval('public.montos_excedentes_id_monto_exedente_seq'::regclass);


--
-- TOC entry 5080 (class 2604 OID 16762)
-- Name: niveles_academicos id_nivel_academico; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveles_academicos ALTER COLUMN id_nivel_academico SET DEFAULT nextval('public.niveles_academicos_id_nivel_academico_seq'::regclass);


--
-- TOC entry 5152 (class 2604 OID 17242)
-- Name: niveles_academicos_tramites_documentos id_nivel_academico_tramite_documento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveles_academicos_tramites_documentos ALTER COLUMN id_nivel_academico_tramite_documento SET DEFAULT nextval('public.niveles_academicos_tramites_d_id_nivel_academico_tramite_do_seq'::regclass);


--
-- TOC entry 5056 (class 2604 OID 16623)
-- Name: paises id_pais; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paises ALTER COLUMN id_pais SET DEFAULT nextval('public.paises_id_pais_seq'::regclass);


--
-- TOC entry 5072 (class 2604 OID 16702)
-- Name: personas id_persona; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas ALTER COLUMN id_persona SET DEFAULT nextval('public.personas_id_persona_seq'::regclass);


--
-- TOC entry 5096 (class 2604 OID 16867)
-- Name: personas_administrativos id_persona_administrativo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_administrativos ALTER COLUMN id_persona_administrativo SET DEFAULT nextval('public.personas_administrativos_id_persona_administrativo_seq'::regclass);


--
-- TOC entry 5090 (class 2604 OID 16834)
-- Name: personas_alumnos id_persona_alumno; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_alumnos ALTER COLUMN id_persona_alumno SET DEFAULT nextval('public.personas_alumnos_id_persona_alumno_seq'::regclass);


--
-- TOC entry 5125 (class 2604 OID 17036)
-- Name: personas_alumnos_posgrados id_persona_alumno_posgrado; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_alumnos_posgrados ALTER COLUMN id_persona_alumno_posgrado SET DEFAULT nextval('public.personas_alumnos_posgrados_id_persona_alumno_posgrado_seq'::regclass);


--
-- TOC entry 5101 (class 2604 OID 16901)
-- Name: personas_decanos id_persona_decano; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_decanos ALTER COLUMN id_persona_decano SET DEFAULT nextval('public.personas_decanos_id_persona_decano_seq'::regclass);


--
-- TOC entry 5099 (class 2604 OID 16881)
-- Name: personas_directores_carreras id_persona_director_carrera; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_directores_carreras ALTER COLUMN id_persona_director_carrera SET DEFAULT nextval('public.personas_directores_carreras_id_persona_director_carrera_seq'::regclass);


--
-- TOC entry 5117 (class 2604 OID 16967)
-- Name: personas_directores_posgrados id_persona_director_posgrado; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_directores_posgrados ALTER COLUMN id_persona_director_posgrado SET DEFAULT nextval('public.personas_directores_posgrados_id_persona_director_posgrado_seq'::regclass);


--
-- TOC entry 5093 (class 2604 OID 16853)
-- Name: personas_docentes id_persona_docente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_docentes ALTER COLUMN id_persona_docente SET DEFAULT nextval('public.personas_docentes_id_persona_docente_seq'::regclass);


--
-- TOC entry 5119 (class 2604 OID 16980)
-- Name: personas_facultades_administradores id_persona_facultad_administrador; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_facultades_administradores ALTER COLUMN id_persona_facultad_administrador SET DEFAULT nextval('public.personas_facultades_administr_id_persona_facultad_administr_seq'::regclass);


--
-- TOC entry 5121 (class 2604 OID 16993)
-- Name: personas_roles id_persona_rol; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_roles ALTER COLUMN id_persona_rol SET DEFAULT nextval('public.personas_roles_id_persona_rol_seq'::regclass);


--
-- TOC entry 5050 (class 2604 OID 16569)
-- Name: pisos id_piso; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pisos ALTER COLUMN id_piso SET DEFAULT nextval('public.pisos_id_piso_seq'::regclass);


--
-- TOC entry 5052 (class 2604 OID 16577)
-- Name: pisos_bloques id_piso_bloque; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pisos_bloques ALTER COLUMN id_piso_bloque SET DEFAULT nextval('public.pisos_bloques_id_piso_bloque_seq'::regclass);


--
-- TOC entry 5155 (class 2604 OID 17261)
-- Name: posgrado_alumnos_documentos id_posgrado_alumno_documento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_alumnos_documentos ALTER COLUMN id_posgrado_alumno_documento SET DEFAULT nextval('public.posgrado_alumnos_documentos_id_posgrado_alumno_documento_seq'::regclass);


--
-- TOC entry 5177 (class 2604 OID 17335)
-- Name: posgrado_asignaciones_docentes id_posgrado_asignacion_docente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_docentes ALTER COLUMN id_posgrado_asignacion_docente SET DEFAULT nextval('public.posgrado_asignaciones_docente_id_posgrado_asignacion_docent_seq'::regclass);


--
-- TOC entry 5212 (class 2604 OID 17416)
-- Name: posgrado_asignaciones_horarios id_posgrado_asignacion_horario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_horarios ALTER COLUMN id_posgrado_asignacion_horario SET DEFAULT nextval('public.posgrado_asignaciones_horario_id_posgrado_asignacion_horari_seq'::regclass);


--
-- TOC entry 5184 (class 2604 OID 17370)
-- Name: posgrado_calificaciones id_postgrado_calificacion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_calificaciones ALTER COLUMN id_postgrado_calificacion SET DEFAULT nextval('public.posgrado_calificaciones_id_postgrado_calificacion_seq'::regclass);


--
-- TOC entry 5215 (class 2604 OID 17447)
-- Name: posgrado_clases_videos id_posgrado_clase_video; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_clases_videos ALTER COLUMN id_posgrado_clase_video SET DEFAULT nextval('public.posgrado_clases_videos_id_posgrado_clase_video_seq'::regclass);


--
-- TOC entry 5164 (class 2604 OID 17298)
-- Name: posgrado_materias id_posgrado_materia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_materias ALTER COLUMN id_posgrado_materia SET DEFAULT nextval('public.posgrado_materias_id_posgrado_materia_seq'::regclass);


--
-- TOC entry 5162 (class 2604 OID 17290)
-- Name: posgrado_niveles id_posgrado_nivel; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_niveles ALTER COLUMN id_posgrado_nivel SET DEFAULT nextval('public.posgrado_niveles_id_posgrado_nivel_seq'::regclass);


--
-- TOC entry 5175 (class 2604 OID 17325)
-- Name: posgrado_tipos_evaluaciones_notas id_posgrado_tipo_evaluacion_nota; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_tipos_evaluaciones_notas ALTER COLUMN id_posgrado_tipo_evaluacion_nota SET DEFAULT nextval('public.posgrado_tipos_evaluaciones_n_id_posgrado_tipo_evaluacion_n_seq'::regclass);


--
-- TOC entry 5134 (class 2604 OID 17101)
-- Name: posgrados_contratos id_posgrado_contrato; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos ALTER COLUMN id_posgrado_contrato SET DEFAULT nextval('public.posgrados_contratos_id_posgrado_contrato_seq'::regclass);


--
-- TOC entry 5136 (class 2604 OID 17134)
-- Name: posgrados_contratos_detalles id_posgrado_contrato_detalle; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos_detalles ALTER COLUMN id_posgrado_contrato_detalle SET DEFAULT nextval('public.posgrados_contratos_detalles_id_posgrado_contrato_detalle_seq'::regclass);


--
-- TOC entry 5138 (class 2604 OID 17152)
-- Name: posgrados_contratos_detalles_desglose id_posgrado_desglose; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos_detalles_desglose ALTER COLUMN id_posgrado_desglose SET DEFAULT nextval('public.posgrados_contratos_detalles_desglose_id_posgrado_desglose_seq'::regclass);


--
-- TOC entry 5123 (class 2604 OID 17011)
-- Name: posgrados_programas id_posgrado_programa; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_programas ALTER COLUMN id_posgrado_programa SET DEFAULT nextval('public.posgrados_programas_id_posgrado_programa_seq'::regclass);


--
-- TOC entry 5140 (class 2604 OID 17165)
-- Name: posgrados_transacciones id_posgrado_transaccion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones ALTER COLUMN id_posgrado_transaccion SET DEFAULT nextval('public.posgrados_transacciones_id_posgrado_transaccion_seq'::regclass);


--
-- TOC entry 5142 (class 2604 OID 17183)
-- Name: posgrados_transacciones_detalles id_posgrado_transaccion_detalle; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones_detalles ALTER COLUMN id_posgrado_transaccion_detalle SET DEFAULT nextval('public.posgrados_transacciones_detal_id_posgrado_transaccion_detal_seq'::regclass);


--
-- TOC entry 5145 (class 2604 OID 17202)
-- Name: posgrados_transacciones_detalles_desglose id_transaccion_desglose; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones_detalles_desglose ALTER COLUMN id_transaccion_desglose SET DEFAULT nextval('public.posgrados_transacciones_detalles_de_id_transaccion_desglose_seq'::regclass);


--
-- TOC entry 5060 (class 2604 OID 16644)
-- Name: provincias id_provincia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provincias ALTER COLUMN id_provincia SET DEFAULT nextval('public.provincias_id_provincia_seq'::regclass);


--
-- TOC entry 5038 (class 2604 OID 16489)
-- Name: roles id_rol; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id_rol SET DEFAULT nextval('public.roles_id_rol_seq'::regclass);


--
-- TOC entry 5040 (class 2604 OID 16497)
-- Name: roles_menus_principales id_rol_menu_principal; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_menus_principales ALTER COLUMN id_rol_menu_principal SET DEFAULT nextval('public.roles_menus_principales_id_rol_menu_principal_seq'::regclass);


--
-- TOC entry 5082 (class 2604 OID 16770)
-- Name: sedes id_sede; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sedes ALTER COLUMN id_sede SET DEFAULT nextval('public.sedes_id_sede_seq'::regclass);


--
-- TOC entry 5066 (class 2604 OID 16678)
-- Name: sexos id_sexo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sexos ALTER COLUMN id_sexo SET DEFAULT nextval('public.sexos_id_sexo_seq'::regclass);


--
-- TOC entry 5105 (class 2604 OID 16929)
-- Name: tipos_evaluaciones_notas id_tipo_evaluacion_nota; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_evaluaciones_notas ALTER COLUMN id_tipo_evaluacion_nota SET DEFAULT nextval('public.tipos_evaluaciones_notas_id_tipo_evaluacion_nota_seq'::regclass);


--
-- TOC entry 5088 (class 2604 OID 16816)
-- Name: tipos_personas id_tipo_persona; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_personas ALTER COLUMN id_tipo_persona SET DEFAULT nextval('public.tipos_personas_id_tipo_persona_seq'::regclass);


--
-- TOC entry 5150 (class 2604 OID 17234)
-- Name: tramites_documentos id_tramite_documento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tramites_documentos ALTER COLUMN id_tramite_documento SET DEFAULT nextval('public.tramites_documentos_id_tramite_documento_seq'::regclass);


--
-- TOC entry 5024 (class 2604 OID 16402)
-- Name: universidades id_universidad; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.universidades ALTER COLUMN id_universidad SET DEFAULT nextval('public.universidades_id_universidad_seq'::regclass);


--
-- TOC entry 5075 (class 2604 OID 16738)
-- Name: usuarios id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuarios_id_usuario_seq'::regclass);


--
-- TOC entry 5690 (class 0 OID 16600)
-- Dependencies: 248
-- Data for Name: ambientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ambientes (id_ambiente, id_piso_bloque, id_tipo_ambiente, nombre, codigo, capacidad, metro_cuadrado, imagen_exterior, imagen_interior, estado) FROM stdin;
\.


--
-- TOC entry 5663 (class 0 OID 16422)
-- Dependencies: 221
-- Data for Name: areas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.areas (id_area, id_universidad, nombre, nombre_abreviado, estado) FROM stdin;
\.


--
-- TOC entry 5683 (class 0 OID 16553)
-- Dependencies: 241
-- Data for Name: bloques; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bloques (id_bloque, id_edificio, nombre, imagen, estado) FROM stdin;
\.


--
-- TOC entry 5677 (class 0 OID 16512)
-- Dependencies: 235
-- Data for Name: campus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.campus (id_campu, nombre, direccion, poligono, latitud, longitud, imagen, estado) FROM stdin;
\.


--
-- TOC entry 5720 (class 0 OID 16783)
-- Dependencies: 278
-- Data for Name: carreras; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.carreras (id_carrera, id_facultad, id_modalidad, id_carrera_nivel_academico, id_sede, nombre, nombre_abreviado, fecha_aprobacion_curriculo, fecha_creacion, resolucion, direccion, latitud, longitud, fax, telefono, telefono_interno, casilla, email, sitio_web, estado) FROM stdin;
\.


--
-- TOC entry 5712 (class 0 OID 16751)
-- Dependencies: 270
-- Data for Name: carreras_niveles_academicos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.carreras_niveles_academicos (id_carrera_nivel_academico, nombre, descripcion, estado) FROM stdin;
\.


--
-- TOC entry 5661 (class 0 OID 16407)
-- Dependencies: 219
-- Data for Name: configuraciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configuraciones (id_configuracion, id_universidad, tipo, descripcion, estado) FROM stdin;
\.


--
-- TOC entry 5758 (class 0 OID 17085)
-- Dependencies: 316
-- Data for Name: cuentas_cargos_conceptos_posgrados; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cuentas_cargos_conceptos_posgrados (id_cuenta_cargo_concepto_posgrado, id_cuenta_cargo_posgrado_concepto, costo, porcentaje, descuento, monto_pagar, fecha, desglose, estado) FROM stdin;
\.


--
-- TOC entry 5754 (class 0 OID 17052)
-- Dependencies: 312
-- Data for Name: cuentas_cargos_posgrados; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cuentas_cargos_posgrados (id_cuenta_cargo_posgrado, id_posgrado_programa, nombre, numero_formulario, estado) FROM stdin;
\.


--
-- TOC entry 5756 (class 0 OID 17067)
-- Dependencies: 314
-- Data for Name: cuentas_cargos_posgrados_conceptos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cuentas_cargos_posgrados_conceptos (id_cuenta_cargo_posgrado_concepto, id_cuenta_cargo_posgrado, id_cuenta_concepto, tiene_descuento, estado) FROM stdin;
\.


--
-- TOC entry 5742 (class 0 OID 16954)
-- Dependencies: 300
-- Data for Name: cuentas_conceptos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cuentas_conceptos (id_cuenta_concepto, nombre, descripcion, estado) FROM stdin;
\.


--
-- TOC entry 5694 (class 0 OID 16628)
-- Dependencies: 252
-- Data for Name: departamentos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.departamentos (id_departamento, id_pais, nombre, estado) FROM stdin;
\.


--
-- TOC entry 5738 (class 0 OID 16938)
-- Dependencies: 296
-- Data for Name: dias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dias (id_dia, numero, nombre, estado) FROM stdin;
\.


--
-- TOC entry 5679 (class 0 OID 16522)
-- Dependencies: 237
-- Data for Name: edificios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.edificios (id_edificio, id_campu, nombre, direccion, latitud, longitud, imagen, estado) FROM stdin;
\.


--
-- TOC entry 5706 (class 0 OID 16691)
-- Dependencies: 264
-- Data for Name: emision_cedulas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.emision_cedulas (id_emision_cedula, nombre, descripcion, estado) FROM stdin;
\.


--
-- TOC entry 5798 (class 0 OID 18251)
-- Dependencies: 356
-- Data for Name: encrypted_log_table; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.encrypted_log_table (id, table_name, id_registro_tabla_modificada, action, date) FROM stdin;
1	\\xea4bcd35bd917686f1157a982a09a00ac30d04090302f7151ce945476c867dd24001d57b181473d656210bd4d742c27dae0b2dbe33858403210f66961ac9132aad77cb7ba4093e31ff09bac0f261fc6885fd2076970468e7b37445dc10e1e76684	\\x27318234383450c4da9eea1b41b0e5d1c30d04090302ee31a8fe1c34771c7bd2330121f5c0303487db072b757e03629dbf66168b82c5abce2a45d7b1123e89d7cf7c23440b73295aae5246ee78009a7076a3a687	\\x578f92b827d144706e97427e7f157538c30d04090302ea2ce4c7ca6d1a7165d284012f051ac6a53624a608e9d6b2fd32734f634f69ec8d32ea6c2321c400a6676fce97d6e73b7d90c2295dd8194829a1cd82bd4168fe11cec523775e8fa8f6b835a7b7afd21be4ca011e13bea97afd20f69cd3adc61d4bebbcf12e71c29c8248d24667b0a7cd7f553ebd38035a080aa9388886fe8d898e2634f10ff0595baea5f5cfa1474d	\\x3db7f8e1745ec97d73222e4270acfac3c30d040903029f36b1209fc9bc8b68d24e01adce751fcfdeb235412e1ad1d698f25d9c6cfb1753dfa8dbcd7e58fb619622f7f2e95a4b4e5e4a094212da5099c921b3e3eb3c1dd0553f4c3f0df0acf7911be65f410d27f247f29fbd9ce271d3
2	\\xdba9567d0de5a2d6cef65d6dfb485113c30d04090302f4c2c0c08116630f7ad240016ced82a7efaff9b4e0af3f0c1579d6bbce58798a1630afe8a3fabab8e9d51ddc77b1894a32c8d642b1437afd15299cb7dbf0d79c63099b7a78283b7495584a	\\xbf9482c6bff2ae1fea20b3ff1ed9470ac30d04090302d88cc47664b3924365d23301a09c8b53fc0697881cb44adfa03a0631bdf27e6206652db0a67f12a2de17376c2ad61903b256a3093aa5d6b18ddcb63fee0d	\\x789d45af4e1a780eb5f50c77102ad2cec30d0409030286d0dd9ef32c4f9378d284018f7cb1760464b305c8f8cb075a2a7d6cbea55ccb7103a4ad9811017910020dffb1bc7b7661e69bf4f8723100d37b6e012ea1b1615988f8b707db8f3dcb25c77265ebe7298b7e6eb6a754872b92b979fca71eac8caa2105a1f39761b10eb3b4e9f6103d24ae01b52d8e7defa95a376bab65389d1d203c0975409d4575ba23b585ea07ff	\\x1fa718c4796ab7c1cd9cf13ab4e37891c30d040903021e0baaa9205a77ea71d24e016ee100e47662523f2760edfe00534d9f10532d140c376712958d3d4650bae42eff7f237b81e291c3093cc77fc96db701caab35bf65030c1e5ac2288bbcae979d3af93b96dfb934dcec84e8b7e2
3	\\xc30d0407030223f5ae6d62a23d4677d24001f42de9b7ee292a2811a7165e43ea8957f387b812ed549a3502e15d4b3178cb9f6fd44755e7ce40a20d31478be3092e50b28f8a42fb918d6512bec1c27f79b6	\\xc30d04070302ccb71b6a74fcec4466d233015851b08de5138d5d362d8dfcb72cc5b465cfe5b9a8e0687edd5e67262b138b9c21c952a5a48cf9a590eb7b7421164ee2703f	\\xc30d04070302f95df4118c66e4a170d284010d1ae2e65e60dc32821ef4c2cbf7e20f146a6f94aabb909c0dd265037e996ded44ca86e23097e632f31293636fc80bff66f39bc9554cdbbb76051b6fe3b3a05774a3111ffc475c6e2802ae508fe1e7200290574669a1cc99834a5eda489dbd301aa879b9ee7b5ddfe826e126f7a3cc6ba34bde7f979337129de512636a564b1db38a42	\\xc30d040703021d6949254083486f70d24e018b78541e26dc0d42208cd9496d5b02bbe8c6a6f7030822d455d6fedc9aac156aa5f52802adb64f03c9e1f6132c21d1fda2a694ebe6847daeaba6a1ff12c4e836f41a5aa4fcafa03097641b399f
4	\\xc30d04070302f281d3d6aebe35ec76d240011157d61539494a3f08a9d5758880908fdfe99653b24239e566033b4f08f4cf161eb5728c8e7168f3ecd50b5c76bab7576a373815f19f20a42c5eb8ac52eb7e	\\xc30d04070302c5ba8177bc6ebbed72d23301641412ab3cb5d93f6206f4a40cc04ec375fcf5c834e81512a5e261ca85703c160fd8d6230e1c5dfbcd9d365fb89feeebfbb5	\\xc30d040703025880767fefd7a23d60d2840141f90c7abe39875113b87b8db1efab53d865bf570ee0f8f429f437b1424d45717f99cdf0a5e84f4f2720e504168ee6fa2238f7402e205d9dc62d09fc322b6dfc6f84a8c80ff7dad050079c39465e835376d376c016416c140dbb91fd68ba4fe57737a69ef2f217386acdccda95af02ccde6cf478de001c26a71c161f58cf40bb694862	\\xc30d040703023ac3253d7c71704871d24e016d3492f6fe4904fc29d4321796366f40e05ddaf6f69778607e86245f2a7dc437e6ae5b4a4ddeacd7e07886824bcc8b72dec81ded8c43fff8b05d6fdae20e278a81998a69e58b9ee5bfd22c342a
5	\\xc30d04070302c158e6147a4c515c63d24001d0a777c6698c31ef85a83e02cbda7b35026bd624a1655b7899965fdec28fbfe61ff08cb9464195d8fd80eb7f68b14da4cceb06e7351826dd1b62ebbe155e8d	\\xc30d04070302c30c8e86fffad43364d23301dd4ccae83db766c1c8e80203be44aba7e3957c559c1ac10c78aec3ab393b31ec2193708a1189c02c09d515fc8313371a716f	\\xc30d040703026c06fef9718ce7477ed28401f80c1a0de083ba4536bb8723aa83e811c5ac0807e2b1d23b31fb3deeb4035ae52d047c270bc9696ad483c41d61ed3cd45b8da4e1c7b7262491a30167bf0dd37f2d86d8cacf2f7c628d8d5e1c63337367a21607dcab41637a9420842a96414c4b0d901a49661d770b94308ad64a8f97613a3dcf8d46429a88c6423e5aae4ee462c4d942	\\xc30d0407030291064f0721394d387ad24e010cbb4deb931daab0fa07a2876d896a2964051d6c047ebee9b7245664086fbad35fcb2daa4ba77f503fc8b9f3c2dbda8e512b389e018e80c002b26249049fb4e97c7bbe0d338f3cfc16538857a5
6	\\xc30d04070302ae7e9df75d4855c368d240011405fefddf9be4de61633621eef5a7b9143a4248d609b9fd10a97b59c0074bc9b462fffca89bb86ec2dd399daae1af21bdb469359369ca00932c02d9e09f03	\\xc30d0407030273f7d878ed6ebe9a67d23301717cb359df7bdac736dcba83886808a40078f4cdd2d6e8e1c2b13a0cb039271e5b49a0e1b212612f45e7a435fb6b62db7297	\\xc30d04070302e247e725faf7fc237ad28401db0d762ca7ab7bc4949bd0f0f49a3ea027ae6509eeea8fb5ff921e1beae216680f0fd2de2b08ee2563361abfd740194c2dd1473d0fa0a5990978bc3e049578721e96ea798148864394b40520b65221826e101afef6b75f2661b6ad534face345c2f2b1dffb8bd8a8bc959e1c31be58a83d2acefee52b578f6f8404c997d7016be69019	\\xc30d040703027f9a2d4ce584e15a79d24e01e932056c04f0bfdeef5fbb5890e508b5570ed8ccb929bff399b2ce64e16bf694dd6ab7932cf4082b31b03cd201e2bec3e22bf1de6ce44da2b36f0d2d714c472f1b9a96190fdb01726a4c9ffa55
7	\\xc30d040703026b4cc652ec6973ce6fd240013a352a345a766cb14fc4e3c91848bdc589fb22fec2f532c0c3fc0968ee9fe4f74633e69fd27fab9acda96c59e9666649c5f64e9d407485f65a8e23370db3d4	\\xc30d04070302d0502c805e58d47d7ed233015a51d0e6f8ba1b6314fccc9d2c2f083b63224ab7e6a87542b5f432ece13e15e1e44022e9d13565a7aa25dca612b45ba4adf5	\\xc30d04070302513872de0c3087ee6fd28401ac2ac27564b5757fbd3e68fc3ddb6f38143bd0def6d88ece580c65f24e9bbaba1b5c2450d21db86ce9fc2c43166a42bb12432af29c37a83635303c003c41b885693d5260025ba265bec41a038de788516944f3275089733334202c82b557d2265f97e2f3c25fd9941a723d880ae1916f8ed1e57bf9a6b187cd0f849dfc26fa50f434bc	\\xc30d04070302a64bcd8b04d1f85d7dd24e0181adaeb38d320db78542378bcdc852a9f1ef80c16f938ce124d574cdc507ba5036110ec877545a06187db24a86c8630074054aeb0770a2940856d9cac4c4fb77bc136994ee2ecfc2f57d08014f
8	\\xc30d0407030251bbaa0b18e9091e65d240019c93647b2e3952de052584fc374f479f06c8726b540d60701dc2b8aff83ccc8743adb6bb92341598f495ef1231e2b28d8fde8b466012d7058c7757e8a06e05	\\xc30d04070302fe007550cb1072ae63d23301bd9cdba4f20ac1d1ed1e4c05fa879e60803e6158cc13efcf28d28347857df43ce9396f9e43e3de6138936c13f75f56818fb3	\\xc30d040703020ff4a6d33c52ac9864d284016c05f34b1c5c7b3557254133cce97006b35c529b6ce7d174576bfb7821181b05e18c17cca5a1888b5edb108e966b4eecffee411966a7e3e2d609ca0ba8eb39fafcc660c07ea6ff309dfc000d46a6b2578cb740e077d9b9e5d307a5293369284417ab556b5c36ecfd5948a1efad9e4db84d78084bc6d6f9de0bec912650e4e9a7a077b1	\\xc30d040703028c0a1ae8f97a0f3473d24e01d891c908d83a51bbbbaf4466af0e4ad34b7029e6ac18e5eafc10405a95bcc94c1a866f1ee55386eb975e709c177963136d4664d23f1295a716af56088982dae5194b61d81366fe3c8804b14e78
9	\\xc30d04070302c4fc981125efe18772d2400179aa6929a136130c19b6f98fe2d6970989b646b89aef6e45d4d2398acecbdf5b6fab69913f587f63778ac5c24d9adeb3af669ac00045f749c7d0500d699045	\\xc30d04070302a8f9fa69a3207eeb6cd2330135db642f2acb8b09e21e07deda0be3b96db012482874498ccfec8f4f4d7392fd67a945a33a084fd84d2277a326c0c1fc27c8	\\xc30d040703028b6bfc3d9085a16c69d25301a3d9f1816760969ccbeac8ac5072655e72a95e59bfe66104939a8a7f5425a1aa3fdddbc4bca3a4aa52a197d555ac6d8b3348d07104bef2d9a3369e4bc83d2f4d926c0ca10f6dcc11ec5f01dfc46b2ce17b3e	\\xc30d040703024cd44d00198730bc6dd24e01e07ba277ca18c15485bc3fb3b776a97dbc26bcb6ce7c905c21958e4906f687e40ebb2c4b48fab539689322e799a24e51b152b20e68de75a1dea74adf391fa1aef09f958dd338194c95407b15b9
10	\\xc30d040703029639017bd1b3464463d240010f4b8751fc095ef0e72be382b9a997c71fa40bb35dd29289c9c0f212f1a5d639a285e12021fa0b9182484c6d071f0e534780fbeb7e8061047d6db54bb44b88	\\xc30d040703020d9dce66e4c109426bd23301e3d584e29b31d273eea7c8f4f7f1f133057e5cfa6052ff8775f34c639ca535b0dded4e929f873d2973db8a43c6b8de8ff418	\\xc30d04070302fd4367ca1f7b3ccc66d253010b8acffc2731f2aaa6895a8c11aaa77c6ae3870418bf6916b703c0fd9914ddb2097ee100c495d96e449928eb47f740c167a7f87e3cac280c7c4c6018feac4b73ce5be7109f1e0cf5a8135c07fa4824263297	\\xc30d040703020fb00a9e9189780767d24e01778ce85595da44bcd7d96143656bcd0240d6709f2065ad320cf59d5d1c2067a5eb4b624c4c7ade184c9e99d484c4752e3d49f6f0b44685d9c670d4d397259422cb6f07eaeb6ce18afebe36f211
11	\\xc30d040703028424c77c22f9729a69d2400114089de100bd2ce7ab38be301bb815613eddc0444810b4b9a7b24eac89fb302602195399bf7eed5870dde9dd0418cfc381344678af6424b35b3c5e2b8f1ddb	\\xc30d04070302278f965ce317735d71d232010366e8a2e4bd9bee2c59bd27fa557ccab3f5d3434e579386270a24fa67862ac8ba42f207523a170b14662f59db2258f8c9	\\xc30d04070302a88bbb34ce45fc1873d25301f8477f887eaa4b7cf1e49716455d21bfdc12d0509d30e05c57b8fb96a509f340a3c245c6c7065ba9aa0048a4434a983587c225a03ce757dc1c2b6ff4e1b5a99816cb3fc2993b1008eb9029b1c4a15a7ef68c	\\xc30d04070302d4744fa8f1833e9d60d24e01b0063e5fb8efb00f2abea99d6e2608b5b052219ce8b7bdb16f0ffbb27f043711b66592bf8dfa0de284d472dddbfb8d10d534ed7b980323673a11e0f3cb0127dbef439fda1242d6a558d9a250a2
12	\\xc30d04070302f20af25a15f46f356fd24001e316d94479d48d083a262dd06493e1817dac439659e17f2cc27d0450b92d59eac8a0290b2ac87f4c0a364b650494565613dab8e16bc201a84fedd747191661	\\xc30d040703026ea257596b5389a265d233013865f89fc4396a62200372759a3252176f8ce255e90216e8ff196f2a44740ac4eb000cbf10df31e32578fd07533516770c94	\\xc30d0407030299f4ee0ab8c7f9e963d28401d6afcf513d7dafe97e1cdbefd3bd86a28a7d5cc92d4afde735cc48acb9066224ba6fb0a2a1d352f772a0255cc740d43ccb923544cee868db84246f4326f6d682b7b53eb5ea6092789d718f555351fb2b8413216231b6b2ac82ce278216a6907b02cc2e71ce74431a03fbd01103126b4a4bcd33857acfa04d9952720445841dc1ae1287	\\xc30d0407030272e9f3ef6c5dba6c75d24e017b64a912a4fa3ad13f3c8aa271dc7c6232d681d9a8ba15eb85786fdd6dc99535048025e823049f18264ee2d7d1972b0b1d841ed03abf64bedaf4ac0aa1a339f25e438f72012245a356a1628b2d
13	\\xc30d040703023c9f0281f3d97f2e6ad23e01fd98fcfe2cc571d509383113d33bb7b87083981a864793050f9be904bcb47c8ee35457332df55e0a802360fc31f5378c6b24369338ffaadee626b9bade	\\xc30d0407030270fd4cd2584eaf3c6bd2320139c91e79d05a148d4c393075c80539eca0a1e4d16f9eea397ece57df101589e9d4b1e5c81dccd96ae35a713cf7621b9f5a	\\xc30d040703024938756cb740fe5f62d2a30140c04b750292c0ed952e407e5383f881e519a5db2564e75caab2763dab09811fb26e8db7e2bd2081de9ac99ae09d07719899a17fe7f95e614098a5f90869257af702ef2c80010c8db4fb93f02d0597d44e904465a84ea9a6fff83c60f53a86539835d0fc311d89897da49764da664003c7ef4a0e6e053932a7dc520118371edc9eeb9becfea7850dfc1d14dfd1f475d9a23491c76dafe8cd04ac0c6737961330cd32	\\xc30d04070302fb197db5132e2f1574d24e016e562db13bcd44e3eb096621f36a4125c0271bdf4ab2930f2627e2a98f9f1a60a4bac340b0d49674b1058cf9c8b906956ef3db92099d292259464f795622388c18c6eefedf6f6ffc1c5d88b660
14	\\xc30d040703027e85cc695e78a9be77d23e01020cbf6df9c8ba110ea954a8b7dcd7017c685c53b8cf28a3327ba64c6fe34aabf01a00b3f0ea8a2a78343ea3c3719cfb6dc0ffae6ab214c577cad9763d	\\xc30d040703022de4dbf1b1d8df9a72d23201f9a9f488620e9f8d76d0f75c76023cdc038c10dbf619dab99ec4808e5bfa4451f62d8110c074c2f6a7c279fc41f55b7a61	\\xc30d04070302a8e49788eae89af37ad2920105344070fca80751e5842f70f613843597c8d1ff81acf83cc7b7eec2250eebdc0f0e00c2b224625393c0b890afb484a561e96d1214feb7af490fd06f089cbc8899b996389667a2895b5a3c92c9eacabf3a48f5060e193aa62e36050fedf48be9364924dc8b746256d21d38a8dc04fd0e65c64827e39a7aff27939a7f320db9b8878e1229080197646b8c0b2dc875ed01bd	\\xc30d04070302339db50b7675fe446ed24e0145bf1015d7f18abb7aa16478e29ea7c245851aaed0a86399c46d8aa691b281a0f20d61b417cfb15314b327c221e4d189715f75976b7d4f04cc173cc8ca7935e15119f32c5286742acaefcaaff5
15	\\xc30d04070302bef3373569b9c77e66d24001f81afdc252a8829e88908bf959a6bd4489632ddb200faf3b1ce9558bbf4ec65ea8817e89c554be40ab3d634e4aba2e7d02ef93989bbd354de51b3c677d64d9	\\xc30d04070302c194d783869edf4868d23301c02268792f03022819890d03c1a45033b297d8f425124ac9aa0de4969964edaddda412026580b52f432bae37d87986e758db	\\xc30d040703027dbd0cebff7df32978d28401072dbe0ddbc51b15a033d426ab8b995d852243ce4b8cc3a9bc8d6141f6c0b9e82da59446858ef729a55705206a18f53e1534f6443b285b360ab0b8cd4207696c46f6c47ec38114c8c528b41dd9cd5edcb5c08fcd8da40019464cdcc250d4f558374bb924827f706345b86f0e1c01802b328f0c4d9e4d4ef5a424fbe89922936d979aa2	\\xc30d040703024bb16ff9e252de6e6fd24d017f3971c64ce639827fc25e64fdd25b9218fa370460be25557dfc967e310386271bf2ff84c8b65a9fe62c49cdf9db764681fd2347fdebf03f69ddd419a89a49e2cf18feb64ce0e5f50c8a694e
16	\\xc30d04070302ea05a9e6f1b704b761d23e01c39efb74dad7d775d4751489ee7ed32b7278359af52c8f02f7a788f436227e367d550bb16a76c04368661242c20a5602d498f8963886255df47aa5cd57	\\xc30d040703021548eb7d0601b1d06ed23201b69f153e10877ade23d6b59098a64830b9085b798ed7710c4cc69306532e526aef5d4f49e0665c3c41fab45680b779866b	\\xc30d040703027f2a2febf0f732fb6ad2a301f030edfe5f9b95c65766bfd62d6c6e68a3ba0c2bbccb6f31570e573146c557fc8e8a4010e26de6eee81ea94df8dbe232344556ab1cbe32fc4bf55a5d6d848700a282296ef271d62749ff67d26907b0e2eec72526681718b423d6c7e2f0f6e3517ec781f6e0a3b1129e6fbbf8930bbd0ea449123e1660c37023932d08cbeb489a883410b14915ce77e423a28bbe8437bfe7dbbe9a943af612daddbf031bcf9c1cd5f5	\\xc30d04070302d4670c163e26b95d66d24e01051c34dbbb453f948d3c3e6f06b6909ae1315c59cd8bc58247a9d4a516fc57590f0f5f9a46abd065f4543f6aeece761a10762c53aa255da236ece889eeeb983b0515943e589789884e5c6c418a
17	\\xc30d04070302641a54637337dd6379d23e012867085b040d3b6a8192e842cd48c976683c89ff739a57be5bf1b75d9aadb045c1d36b3d6eb779f99f50f65897315039ea962324a2506a57ba4a41c15a	\\xc30d04070302d837081bc5300ef67cd23201ddd48ae119141f14dfde39f8bb8c17c447e7d2c66eb2ae207dab33f3fd1e3f6dcd926e1546ab2926a52612550be15184a2	\\xc30d04070302c5f764012a8f8eac60d292019dded9ab32dca8519854131e3486f28944154180494d2a9c9f4a1d951081d97a8a5956dc946ba6c4ffd9a3c299c2b7654f1799b315a404da57b5412aa730e9651c5c3d06892c92ad1498c8296142aedeecfc89f7b4dec320011c085d72da5c7fe00e1a36f8f3525aed44d173fec53268e72fde22170a65dc4e3c35a9a0654c8012b6f7352f7f001ce7a1f64988a40cef08	\\xc30d04070302ab99a9940f22d33174d24e01499aaf99880f261ec1318d37b92f3a6cd7e8f2fa459da54a1484d511032cc068009bed85074406c0f5213206c4d3ce4ce73992a929f6d5133f06c98d2dc4b9a7ba6708124c11f493c965407fbf
18	\\xc30d0407030211d00a2c4d239d8865d23e0114e0af8c79b02c0e6b73375538013f8638b08b187533b7db2fffba9c4c00d6650075ba9b797cef48a328e00e674047f65e6f6750c2bddd52a6393c347f	\\xc30d04070302d86539d68de1a9b07bd2320169b306eef39d6d254db014055145876d60d40986e470616a86fbae635180cce085da1c234f7b6a3fd334b46f64cdc8a642	\\xc30d040703023df18397a2dfe7a468d2a301f30e4c0a7e9578aef67bc44f48f9ed3ede774ff66fde3b2841e04b9e7c538267176c784450181764dd8f6f12978d0f1baac92093ab88fa7f4021edbfa5e6d6373ff0f56b4e5319a03fab8f58bb43a39d799cd9e43c480f2db67d36c29a0e0f414efed857fe264f5ecb3d0cdbb8f0431f5375d01a08f75996e76b501cb9e1a5a633585b9e83c0a54f9e3086cfb52fb1037233b099f6c689a417fbda8f55d07d7507ff	\\xc30d04070302e7ac6246b8fee4fd75d24e01bed82442c12f9b0befd626b16048e1dcab55b14094ef435fe7ce65fbedc80cb61a061a013b7942106310b3dd613ae0ef84150cccdee146ddaf5b2ae982681ab0a11f1dfa4dabbee0e6166828d3
19	\\xc30d0407030299b55f30f82271e266d23e01bddf3d96d47d110388e3e8a203d2a8dfc904fe3666eae02f738b2bae3776ecc4d31bd6678eb575750eba533063ce218fda7d9928ee12b4131424294b1e	\\xc30d0407030249be62ab4f89a73a6cd2320126a1f627932806425d9feb6ba2010fd8a59b2c90e5d636a336e635679ae2a3c619dae5fc7958c69827ef718d021c9170ad	\\xc30d04070302db33bdef7b800b6770d29201cb072233bd12ca41b79d6f623e8da0af55821222c93cd992f8647c16bf1239c6d3ff4bd4edb4bec7dcd58cf215ca279c66ee4cf79893f85e2d2c87813d6a491c4b03899aba135330da9be7842bb4facb83a842ffd70bc6b7e0b99d0f24b45d455950646792d9deafc6fb5ea910782b169b137d7e98ce689542f6e19248325b846b327739e58899b4bd5b03fe034cf76c71	\\xc30d0407030205aab9edbee6338174d24e01d03bc29dd3342cce22617a7da96287d941440573f5680c5e10447c2a6ea15326a541bffc29ad126cc78915faae7b1de09eec323b31e52a0e8133b78974d262ac0cff4fc9f9864d6f1db747a93d
20	\\xc30d04070302873226db51ca850e76d23e01b1f96b98d20d9bb9d7fc21cc287fb30fbde1bff69b29226e8c9d637fdcff6cf3661dd2be07d953767f5e5a5473e1aa961d19cb3ff05e8000a965e159f2	\\xc30d04070302d5e26371b6f8fcd57ed23201d86772ab9620fd23f07edde8cc53479872ca9f0f3315ac7022c0a596a8e4deca8705e3ebc093ba26153ccd3849a63d055e	\\xc30d0407030224bbdb71a35d80db7bd2a301947789a3c2adc9cf4dd0886ed104ce865f7479d015165127b3399025245ba5d892b5969f72c9a261a497954080ead4d3f1a75a86e98359292de71183b9c42230c0e77b534c3b4504175200cb8c8051d1a0812153eb279a9b23f7415123472df9cc91c848f876f39bcf70b3d47b9f6810844a42ac2fd6262100f5aaa0ca8e43ca4a3ebc068ca4e7e69ed487f4834bb000d100aa0f5f699b6c7473895e8957425c835a	\\xc30d04070302f494047b783a718c6cd24e01c1a5217e6e49fcfe396833e5044a474e5e08d79a6609cba15432e53a77ededbff929551ffb742dadb7603c303d143ad75073f8e54595f522b9244b0d3293b86d32dc0b9aa51aeab43727738889
21	\\xc30d040703022be4986fa55b931c6cd23e01854bdf5d0fd89ddb4cb8fdae3fddafccda5f7a064a4b6d1cce0640acaa3a55ba089d76fcbea3381012957e5e1aad9bf8bd459c6084cb816270691db334	\\xc30d04070302dc3295e611240adc64d2320191681c3cb597b9c49a239635617adf9b7a38f2dc3d8c91397911b687ee945991a606050ec3eb796929bc6b2c3e8bd0b42e	\\xc30d040703029781f87f2a02558067d29201743b8b7c2ce21f6f6df39ffe2602d10e5cd62b302631cf207cea8242942d7c4254f39316ed7f42f0391bf5ac0a1f047c2cef066ea66d65291cb89f585dd6fd08ce74a5514c8d025c58ded446ac10b7753ea3e27383892887f92180947c5b9150b8679c99619a90c5f82cdbd828fc46bba83bacfd7f839074cb462b0cc008e0dae1d206ad2945b9c11ba1ca1f8e74f08332	\\xc30d040703023524ed6f30e6067266d24e010045eb9219d76018a91cd7cf275595f1ab1436e5c53da51c8214a905bcae0a42dda455596f1035046133c6100766602eb31dbac5e513b6274b8cc032d99da5fffa020d3b2c4a3f8bc50901ac07
\.


--
-- TOC entry 5704 (class 0 OID 16683)
-- Dependencies: 262
-- Data for Name: estados_civiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.estados_civiles (id_estado_civil, nombre, estado) FROM stdin;
\.


--
-- TOC entry 5780 (class 0 OID 17278)
-- Dependencies: 338
-- Data for Name: extractos_bancarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.extractos_bancarios (id_extracto_bancario, nombre_completo, carnet_identidad, numero_codigo, monto, fecha, hora, procesando, estado) FROM stdin;
\.


--
-- TOC entry 5665 (class 0 OID 16435)
-- Dependencies: 223
-- Data for Name: facultades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.facultades (id_facultad, id_area, nombre, nombre_abreviado, direccion, telefono, telefono_interno, fax, email, latitud, longitud, fecha_creacion, escudo, imagen, estado_virtual, estado) FROM stdin;
\.


--
-- TOC entry 5681 (class 0 OID 16535)
-- Dependencies: 239
-- Data for Name: facultades_edificios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.facultades_edificios (id_facultad_edificio, id_facultad, id_edificio, fecha_asignacion, estado) FROM stdin;
\.


--
-- TOC entry 5734 (class 0 OID 16918)
-- Dependencies: 292
-- Data for Name: gestiones_periodos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gestiones_periodos (id_gestion_periodo, gestion, periodo, tipo, estado) FROM stdin;
\.


--
-- TOC entry 5700 (class 0 OID 16667)
-- Dependencies: 258
-- Data for Name: grupos_sanguineos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grupos_sanguineos (id_grupo_sanguineo, nombre, estado) FROM stdin;
\.


--
-- TOC entry 5740 (class 0 OID 16946)
-- Dependencies: 298
-- Data for Name: horas_clases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horas_clases (id_hora_clase, numero, hora_inicio, hora_fin, estado) FROM stdin;
\.


--
-- TOC entry 5698 (class 0 OID 16654)
-- Dependencies: 256
-- Data for Name: localidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.localidades (id_localidad, id_provincia, nombre, estado) FROM stdin;
\.


--
-- TOC entry 5796 (class 0 OID 18241)
-- Dependencies: 354
-- Data for Name: log_table; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.log_table (id, table_name, id_registro_tabla_modificada, action, date) FROM stdin;
3	tipos_ambientes	15	CREATED {"id_tipo_ambiente":15,"nombre":"15","estado":"1"} in table tipos_ambientes	2025-03-10 20:27:43.492357
4	tipos_ambientes	16	CREATED {"id_tipo_ambiente":16,"nombre":"16","estado":"1"} in table tipos_ambientes	2025-03-10 20:31:20.959116
5	tipos_ambientes	17	CREATED {"id_tipo_ambiente":17,"nombre":"17","estado":"1"} in table tipos_ambientes	2025-03-10 23:27:46.855979
6	tipos_ambientes	18	CREATED {"id_tipo_ambiente":18,"nombre":"18","estado":"1"} in table tipos_ambientes	2025-03-10 23:28:50.277853
7	tipos_ambientes	19	CREATED {"id_tipo_ambiente":19,"nombre":"19","estado":"1"} in table tipos_ambientes	2025-03-10 23:29:05.519751
8	tipos_ambientes	20	CREATED {"id_tipo_ambiente":20,"nombre":"20","estado":"1"} in table tipos_ambientes	2025-03-10 23:33:13.732225
9	tipos_ambientes	21	CREATED {"id_tipo_ambiente":21,"nombre":"21","estado":"1"} in table tipos_ambientes	2025-03-11 19:15:09.545337
10	tipos_ambientes	22	CREATED {"id_tipo_ambiente":22,"nombre":"22","estado":"1"} in table tipos_ambientes	2025-03-11 19:17:28.980532
11	tipos_ambientes	19	DELETED from table tipos_ambientes	2025-03-11 19:18:10.726536
12	tipos_ambientes	18	DELETED from table tipos_ambientes	2025-03-11 19:18:51.078656
13	tipos_ambientes	9	DELETED from table tipos_ambientes	2025-03-11 19:19:28.709273
14	tipos_ambientes	23	CREATED {"id_tipo_ambiente":23,"nombre":"23","estado":"1"} in table tipos_ambientes	2025-03-11 19:22:28.650518
15	universidades	6	CREATED {"id_universidad":6,"nombre":"6","nombre_abreviado":"6","inicial":"6","estado":"1"} in table universidades	2025-03-11 20:25:53.980783
16	universidades	6	UPDATED to {"id_universidad":6,"nombre":"66","nombre_abreviado":"66","inicial":"66","estado":"1"}	2025-03-11 20:26:00.495587
17	tipos_ambientes	24	CREATED {"id_tipo_ambiente":24,"nombre":"24","estado":"1"} in table tipos_ambientes	2025-03-11 21:09:44.21558
18	universidades	7	CREATED {"id_universidad":7,"nombre":"7","nombre_abreviado":"7","inicial":"7","estado":"1"} in table universidades	2025-03-11 21:23:40.867096
19	universidades	7	UPDATED to {"id_universidad":7,"nombre":"77","nombre_abreviado":"77","inicial":"77","estado":"1"}	2025-03-11 21:23:49.453142
20	universidades	8	CREATED {"id_universidad":8,"nombre":"8","nombre_abreviado":"8","inicial":"8","estado":"1"} in table universidades	2025-03-11 21:33:35.215765
21	universidades	8	UPDATED to {"id_universidad":8,"nombre":"88","nombre_abreviado":"88","inicial":"88","estado":"1"}	2025-03-11 21:33:43.379114
22	universidades	9	CREATED {"id_universidad":9,"nombre":"9","nombre_abreviado":"9","inicial":"9","estado":"1"} in table universidades	2025-03-12 07:27:08.932663
23	universidades	9	UPDATED to {"id_universidad":9,"nombre":"99","nombre_abreviado":"99","inicial":"99","estado":"1"}	2025-03-12 07:27:17.464766
\.


--
-- TOC entry 5671 (class 0 OID 16471)
-- Dependencies: 229
-- Data for Name: menus; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.menus (id_menu, id_menu_principal, nombre, directorio, icono, imagen, color, orden, estado) FROM stdin;
\.


--
-- TOC entry 5669 (class 0 OID 16458)
-- Dependencies: 227
-- Data for Name: menus_principales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.menus_principales (id_menu_principal, id_modulo, nombre, icono, orden, estado) FROM stdin;
\.


--
-- TOC entry 5718 (class 0 OID 16775)
-- Dependencies: 276
-- Data for Name: modalidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modalidades (id_modalidad, nombre, descripcion, estado) FROM stdin;
\.


--
-- TOC entry 5667 (class 0 OID 16450)
-- Dependencies: 225
-- Data for Name: modulos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.modulos (id_modulo, nombre, estado) FROM stdin;
\.


--
-- TOC entry 5772 (class 0 OID 17217)
-- Dependencies: 330
-- Data for Name: montos_excedentes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.montos_excedentes (id_monto_exedente, id_posgrado_transaccion_detalle, monto_excedente, procesando, estado) FROM stdin;
\.


--
-- TOC entry 5714 (class 0 OID 16759)
-- Dependencies: 272
-- Data for Name: niveles_academicos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.niveles_academicos (id_nivel_academico, nombre, descripcion, estado) FROM stdin;
\.


--
-- TOC entry 5776 (class 0 OID 17239)
-- Dependencies: 334
-- Data for Name: niveles_academicos_tramites_documentos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.niveles_academicos_tramites_documentos (id_nivel_academico_tramite_documento, id_nivel_academico, id_tramite_documento, fecha, estado) FROM stdin;
\.


--
-- TOC entry 5692 (class 0 OID 16620)
-- Dependencies: 250
-- Data for Name: paises; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.paises (id_pais, nombre, estado) FROM stdin;
\.


--
-- TOC entry 5708 (class 0 OID 16699)
-- Dependencies: 266
-- Data for Name: personas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas (id_persona, id_localidad, numero_identificacion_personal, id_emision_cedula, paterno, materno, nombres, id_sexo, id_grupo_sanguineo, fecha_nacimiento, direccion, latitud, longitud, telefono_celular, telefono_fijo, zona, id_estado_civil, email, fotografia, abreviacion_titulo, estado) FROM stdin;
\.


--
-- TOC entry 5728 (class 0 OID 16864)
-- Dependencies: 286
-- Data for Name: personas_administrativos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas_administrativos (id_persona_administrativo, id_persona, cargo, fecha, estado) FROM stdin;
\.


--
-- TOC entry 5724 (class 0 OID 16831)
-- Dependencies: 282
-- Data for Name: personas_alumnos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas_alumnos (id_persona_alumno, id_persona, id_carrera, fecha, estado) FROM stdin;
\.


--
-- TOC entry 5752 (class 0 OID 17033)
-- Dependencies: 310
-- Data for Name: personas_alumnos_posgrados; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas_alumnos_posgrados (id_persona_alumno_posgrado, id_persona, id_posgrado_programa, fecha, inscrito, estado) FROM stdin;
\.


--
-- TOC entry 5732 (class 0 OID 16898)
-- Dependencies: 290
-- Data for Name: personas_decanos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas_decanos (id_persona_decano, id_facultad, id_persona, fecha_inicio, fecha_fin, resolucion, firma_digital, observacion, estado) FROM stdin;
\.


--
-- TOC entry 5730 (class 0 OID 16878)
-- Dependencies: 288
-- Data for Name: personas_directores_carreras; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas_directores_carreras (id_persona_director_carrera, id_carrera, id_persona, fecha_inicio, fecha_fin, resolucion, firma_digital, observacion, estado) FROM stdin;
\.


--
-- TOC entry 5744 (class 0 OID 16964)
-- Dependencies: 302
-- Data for Name: personas_directores_posgrados; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas_directores_posgrados (id_persona_director_posgrado, id_persona, fecha_inicio, fecha_fin, firma_digital, estado) FROM stdin;
\.


--
-- TOC entry 5726 (class 0 OID 16850)
-- Dependencies: 284
-- Data for Name: personas_docentes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas_docentes (id_persona_docente, id_persona, fecha_ingreso, fecha, estado) FROM stdin;
\.


--
-- TOC entry 5746 (class 0 OID 16977)
-- Dependencies: 304
-- Data for Name: personas_facultades_administradores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas_facultades_administradores (id_persona_facultad_administrador, id_persona, fecha_inicio, fecha_fin, firma_digital, estado) FROM stdin;
\.


--
-- TOC entry 5748 (class 0 OID 16990)
-- Dependencies: 306
-- Data for Name: personas_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.personas_roles (id_persona_rol, id_persona, id_rol, fecha_asignacion, estado) FROM stdin;
\.


--
-- TOC entry 5685 (class 0 OID 16566)
-- Dependencies: 243
-- Data for Name: pisos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pisos (id_piso, numero, nombre, estado) FROM stdin;
\.


--
-- TOC entry 5687 (class 0 OID 16574)
-- Dependencies: 245
-- Data for Name: pisos_bloques; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pisos_bloques (id_piso_bloque, id_bloque, id_piso, nombre, cantidad_ambientes, imagen, estado) FROM stdin;
\.


--
-- TOC entry 5778 (class 0 OID 17258)
-- Dependencies: 336
-- Data for Name: posgrado_alumnos_documentos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrado_alumnos_documentos (id_posgrado_alumno_documento, id_persona_alumno_posgrado, id_nivel_academico_tramite_documento, fecha_subida, archivo, verificado, fecha_verificacion, estado) FROM stdin;
\.


--
-- TOC entry 5788 (class 0 OID 17332)
-- Dependencies: 346
-- Data for Name: posgrado_asignaciones_docentes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrado_asignaciones_docentes (id_posgrado_asignacion_docente, id_persona_docente, id_posgrado_materia, id_posgrado_tipo_evaluacion_nota, id_gestion_periodo, tipo_calificacion, grupo, cupo_maximo_estudiante, finaliza_planilla_calificacion, fecha_limite_examen_final, fecha_limite_nota_2da_instancia, fecha_limite_nota_examen_mesa, fecha_finalizacion_planilla, hash, codigo_barras, codigo_qr, estado) FROM stdin;
\.


--
-- TOC entry 5792 (class 0 OID 17413)
-- Dependencies: 350
-- Data for Name: posgrado_asignaciones_horarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrado_asignaciones_horarios (id_posgrado_asignacion_horario, id_posgrado_asignacion_docente, id_ambiente, id_dia, id_hora_clase, clase_link, clase_descripcion, fecha_registro, estado) FROM stdin;
\.


--
-- TOC entry 5790 (class 0 OID 17367)
-- Dependencies: 348
-- Data for Name: posgrado_calificaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrado_calificaciones (id_postgrado_calificacion, id_persona_alumno_posgrado, id_posgrado_asignacion_docente, tipo_programacion, control_asistencia, configuracion, calificacion1, calificacion2, calificacion3, calificacion4, calificacion5, calificacion6, calificacion7, calificacion8, calificacion9, calificacion10, calificacion11, calificacion12, calificacion13, calificacion14, calificacion15, calificacion16, calificacion17, calificacion18, calificacion19, calificacion20, nota_final, nota_2da_instancia, nota_examen_mesa, observacion, tipo, estado) FROM stdin;
\.


--
-- TOC entry 5794 (class 0 OID 17444)
-- Dependencies: 352
-- Data for Name: posgrado_clases_videos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrado_clases_videos (id_posgrado_clase_video, id_posgrado_asignacion_horario, clase_link, clase_fecha, clase_hora_inicio, clase_hora_fin, clase_duracion, fecha_registro, estado) FROM stdin;
\.


--
-- TOC entry 5784 (class 0 OID 17295)
-- Dependencies: 342
-- Data for Name: posgrado_materias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrado_materias (id_posgrado_materia, id_posgrado_programa, id_posgrado_nivel, sigla, nombre, nivel_curso, cantidad_hora_teorica, cantidad_hora_practica, cantidad_hora_laboratorio, cantidad_hora_plataforma, cantidad_hora_virtual, cantidad_credito, color, icono, imagen, estado) FROM stdin;
\.


--
-- TOC entry 5782 (class 0 OID 17287)
-- Dependencies: 340
-- Data for Name: posgrado_niveles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrado_niveles (id_posgrado_nivel, nombre, descripcion, estado) FROM stdin;
\.


--
-- TOC entry 5786 (class 0 OID 17322)
-- Dependencies: 344
-- Data for Name: posgrado_tipos_evaluaciones_notas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrado_tipos_evaluaciones_notas (id_posgrado_tipo_evaluacion_nota, nombre, configuracion, nota_minima_aprobacion, estado) FROM stdin;
\.


--
-- TOC entry 5760 (class 0 OID 17098)
-- Dependencies: 318
-- Data for Name: posgrados_contratos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrados_contratos (id_posgrado_contrato, id_cuenta_cargo_posgrado, id_persona_alumno_posgrado, numero_cuotas, id_persona_director_posgrado, id_persona_facultad_administrador, id_persona_decano, estado) FROM stdin;
\.


--
-- TOC entry 5762 (class 0 OID 17131)
-- Dependencies: 320
-- Data for Name: posgrados_contratos_detalles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrados_contratos_detalles (id_posgrado_contrato_detalle, id_posgrado_contrato, id_cuenta_cargo_concepto_posgrado, pagado, monto_pagado, monto_adeudado, estado) FROM stdin;
\.


--
-- TOC entry 5764 (class 0 OID 17149)
-- Dependencies: 322
-- Data for Name: posgrados_contratos_detalles_desglose; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrados_contratos_detalles_desglose (id_posgrado_desglose, id_posgrado_contrato_detalle, monto, descripcion, pagado, estado) FROM stdin;
\.


--
-- TOC entry 5750 (class 0 OID 17008)
-- Dependencies: 308
-- Data for Name: posgrados_programas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrados_programas (id_posgrado_programa, id_nivel_academico, id_carrera, gestion, nombre, id_modalidad, fecha_inicio, fecha_fin, fecha_inicio_inscrito, fecha_fin_inscrito, numero_max_cuotas, documento, costo_total, formato_contrato, formato_contrato_docente, estado) FROM stdin;
\.


--
-- TOC entry 5766 (class 0 OID 17162)
-- Dependencies: 324
-- Data for Name: posgrados_transacciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrados_transacciones (id_posgrado_transaccion, id_posgrado_contrato, id_persona_alumno_posgrado, fecha_transaccion, estado) FROM stdin;
\.


--
-- TOC entry 5768 (class 0 OID 17180)
-- Dependencies: 326
-- Data for Name: posgrados_transacciones_detalles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrados_transacciones_detalles (id_posgrado_transaccion_detalle, id_posgrado_transaccion, id_posgrado_contrato_detalle, fecha_deposito, numero_deposito, monto_deposito, fotografia_deposito, usado_transaccion, estado) FROM stdin;
\.


--
-- TOC entry 5770 (class 0 OID 17199)
-- Dependencies: 328
-- Data for Name: posgrados_transacciones_detalles_desglose; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posgrados_transacciones_detalles_desglose (id_transaccion_desglose, id_posgrado_contrato_detalle, id_posgrado_transaccion_detalle, monto_desglosado, descripcion, estado) FROM stdin;
\.


--
-- TOC entry 5696 (class 0 OID 16641)
-- Dependencies: 254
-- Data for Name: provincias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.provincias (id_provincia, id_departamento, nombre, estado) FROM stdin;
\.


--
-- TOC entry 5673 (class 0 OID 16486)
-- Dependencies: 231
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id_rol, nombre, descripcion, estado) FROM stdin;
\.


--
-- TOC entry 5675 (class 0 OID 16494)
-- Dependencies: 233
-- Data for Name: roles_menus_principales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles_menus_principales (id_rol_menu_principal, id_rol, id_menu_principal, estado) FROM stdin;
\.


--
-- TOC entry 5716 (class 0 OID 16767)
-- Dependencies: 274
-- Data for Name: sedes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sedes (id_sede, nombre, estado) FROM stdin;
1	1	1
2	22	0
\.


--
-- TOC entry 5702 (class 0 OID 16675)
-- Dependencies: 260
-- Data for Name: sexos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sexos (id_sexo, nombre, estado) FROM stdin;
1	masculino	1
\.


--
-- TOC entry 5688 (class 0 OID 16592)
-- Dependencies: 246
-- Data for Name: tipos_ambientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_ambientes (id_tipo_ambiente, nombre, estado) FROM stdin;
7	prueba2	1
8	salon grande	1
10	12	1
11	11	1
12	121	1
13	13	1
14	14	1
15	15	1
16	16	1
17	17	1
20	20	1
21	21	1
22	22	1
23	23	1
24	24	1
\.


--
-- TOC entry 5736 (class 0 OID 16926)
-- Dependencies: 294
-- Data for Name: tipos_evaluaciones_notas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_evaluaciones_notas (id_tipo_evaluacion_nota, nombre, parcial, practica, laboratorio, examen_final, nota_minima_aprobacion, estado) FROM stdin;
\.


--
-- TOC entry 5722 (class 0 OID 16813)
-- Dependencies: 280
-- Data for Name: tipos_personas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_personas (id_tipo_persona, id_persona, id_rol, tipo, estado) FROM stdin;
\.


--
-- TOC entry 5774 (class 0 OID 17231)
-- Dependencies: 332
-- Data for Name: tramites_documentos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tramites_documentos (id_tramite_documento, nombre, descripcion, estado) FROM stdin;
2	2	2	1
3	3	3	1
4	44	44	1
5	5	5	1
6	6	6	1
\.


--
-- TOC entry 5659 (class 0 OID 16399)
-- Dependencies: 217
-- Data for Name: universidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.universidades (id_universidad, nombre, nombre_abreviado, inicial, estado) FROM stdin;
2	u2	u2	u2	1
1	u1	u1	u1	S
3	3	3	3	1
4	41	41	44	1
5	55	55	55	1
6	66	66	66	1
7	77	77	77	1
8	88	88	88	1
9	99	99	99	1
\.


--
-- TOC entry 5710 (class 0 OID 16735)
-- Dependencies: 268
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id_usuario, id_persona, nombreemail, password, tipo, fecha, fecha_finalizacion, observacion, estado) FROM stdin;
\.


--
-- TOC entry 5875 (class 0 OID 0)
-- Dependencies: 247
-- Name: ambientes_id_ambiente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ambientes_id_ambiente_seq', 1, false);


--
-- TOC entry 5876 (class 0 OID 0)
-- Dependencies: 220
-- Name: areas_id_area_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.areas_id_area_seq', 1, false);


--
-- TOC entry 5877 (class 0 OID 0)
-- Dependencies: 240
-- Name: bloques_id_bloque_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bloques_id_bloque_seq', 1, false);


--
-- TOC entry 5878 (class 0 OID 0)
-- Dependencies: 234
-- Name: campus_id_campu_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.campus_id_campu_seq', 1, false);


--
-- TOC entry 5879 (class 0 OID 0)
-- Dependencies: 277
-- Name: carreras_id_carrera_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.carreras_id_carrera_seq', 1, false);


--
-- TOC entry 5880 (class 0 OID 0)
-- Dependencies: 269
-- Name: carreras_niveles_academicos_id_carrera_nivel_academico_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.carreras_niveles_academicos_id_carrera_nivel_academico_seq', 1, false);


--
-- TOC entry 5881 (class 0 OID 0)
-- Dependencies: 218
-- Name: configuraciones_id_configuracion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.configuraciones_id_configuracion_seq', 1, false);


--
-- TOC entry 5882 (class 0 OID 0)
-- Dependencies: 315
-- Name: cuentas_cargos_conceptos_posg_id_cuenta_cargo_concepto_posg_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cuentas_cargos_conceptos_posg_id_cuenta_cargo_concepto_posg_seq', 1, false);


--
-- TOC entry 5883 (class 0 OID 0)
-- Dependencies: 313
-- Name: cuentas_cargos_posgrados_conc_id_cuenta_cargo_posgrado_conc_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cuentas_cargos_posgrados_conc_id_cuenta_cargo_posgrado_conc_seq', 1, false);


--
-- TOC entry 5884 (class 0 OID 0)
-- Dependencies: 311
-- Name: cuentas_cargos_posgrados_id_cuenta_cargo_posgrado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cuentas_cargos_posgrados_id_cuenta_cargo_posgrado_seq', 1, false);


--
-- TOC entry 5885 (class 0 OID 0)
-- Dependencies: 299
-- Name: cuentas_conceptos_id_cuenta_concepto_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cuentas_conceptos_id_cuenta_concepto_seq', 1, false);


--
-- TOC entry 5886 (class 0 OID 0)
-- Dependencies: 251
-- Name: departamentos_id_departamento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.departamentos_id_departamento_seq', 1, false);


--
-- TOC entry 5887 (class 0 OID 0)
-- Dependencies: 295
-- Name: dias_id_dia_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dias_id_dia_seq', 1, false);


--
-- TOC entry 5888 (class 0 OID 0)
-- Dependencies: 236
-- Name: edificios_id_edificio_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.edificios_id_edificio_seq', 1, false);


--
-- TOC entry 5889 (class 0 OID 0)
-- Dependencies: 263
-- Name: emision_cedulas_id_emision_cedula_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.emision_cedulas_id_emision_cedula_seq', 1, false);


--
-- TOC entry 5890 (class 0 OID 0)
-- Dependencies: 355
-- Name: encrypted_log_table_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.encrypted_log_table_id_seq', 21, true);


--
-- TOC entry 5891 (class 0 OID 0)
-- Dependencies: 261
-- Name: estados_civiles_id_estado_civil_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estados_civiles_id_estado_civil_seq', 1, false);


--
-- TOC entry 5892 (class 0 OID 0)
-- Dependencies: 337
-- Name: extractos_bancarios_id_extracto_bancario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.extractos_bancarios_id_extracto_bancario_seq', 1, false);


--
-- TOC entry 5893 (class 0 OID 0)
-- Dependencies: 238
-- Name: facultades_edificios_id_facultad_edificio_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.facultades_edificios_id_facultad_edificio_seq', 1, false);


--
-- TOC entry 5894 (class 0 OID 0)
-- Dependencies: 222
-- Name: facultades_id_facultad_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.facultades_id_facultad_seq', 1, false);


--
-- TOC entry 5895 (class 0 OID 0)
-- Dependencies: 291
-- Name: gestiones_periodos_id_gestion_periodo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gestiones_periodos_id_gestion_periodo_seq', 1, false);


--
-- TOC entry 5896 (class 0 OID 0)
-- Dependencies: 257
-- Name: grupos_sanguineos_id_grupo_sanguineo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grupos_sanguineos_id_grupo_sanguineo_seq', 1, false);


--
-- TOC entry 5897 (class 0 OID 0)
-- Dependencies: 297
-- Name: horas_clases_id_hora_clase_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.horas_clases_id_hora_clase_seq', 1, false);


--
-- TOC entry 5898 (class 0 OID 0)
-- Dependencies: 255
-- Name: localidades_id_localidad_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.localidades_id_localidad_seq', 1, false);


--
-- TOC entry 5899 (class 0 OID 0)
-- Dependencies: 353
-- Name: log_table_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_table_id_seq', 23, true);


--
-- TOC entry 5900 (class 0 OID 0)
-- Dependencies: 228
-- Name: menus_id_menu_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.menus_id_menu_seq', 1, false);


--
-- TOC entry 5901 (class 0 OID 0)
-- Dependencies: 226
-- Name: menus_principales_id_menu_principal_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.menus_principales_id_menu_principal_seq', 1, false);


--
-- TOC entry 5902 (class 0 OID 0)
-- Dependencies: 275
-- Name: modalidades_id_modalidad_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.modalidades_id_modalidad_seq', 1, false);


--
-- TOC entry 5903 (class 0 OID 0)
-- Dependencies: 224
-- Name: modulos_id_modulo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.modulos_id_modulo_seq', 1, false);


--
-- TOC entry 5904 (class 0 OID 0)
-- Dependencies: 329
-- Name: montos_excedentes_id_monto_exedente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.montos_excedentes_id_monto_exedente_seq', 1, false);


--
-- TOC entry 5905 (class 0 OID 0)
-- Dependencies: 271
-- Name: niveles_academicos_id_nivel_academico_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.niveles_academicos_id_nivel_academico_seq', 1, false);


--
-- TOC entry 5906 (class 0 OID 0)
-- Dependencies: 333
-- Name: niveles_academicos_tramites_d_id_nivel_academico_tramite_do_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.niveles_academicos_tramites_d_id_nivel_academico_tramite_do_seq', 1, false);


--
-- TOC entry 5907 (class 0 OID 0)
-- Dependencies: 249
-- Name: paises_id_pais_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.paises_id_pais_seq', 1, false);


--
-- TOC entry 5908 (class 0 OID 0)
-- Dependencies: 285
-- Name: personas_administrativos_id_persona_administrativo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_administrativos_id_persona_administrativo_seq', 1, false);


--
-- TOC entry 5909 (class 0 OID 0)
-- Dependencies: 281
-- Name: personas_alumnos_id_persona_alumno_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_alumnos_id_persona_alumno_seq', 1, false);


--
-- TOC entry 5910 (class 0 OID 0)
-- Dependencies: 309
-- Name: personas_alumnos_posgrados_id_persona_alumno_posgrado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_alumnos_posgrados_id_persona_alumno_posgrado_seq', 1, false);


--
-- TOC entry 5911 (class 0 OID 0)
-- Dependencies: 289
-- Name: personas_decanos_id_persona_decano_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_decanos_id_persona_decano_seq', 1, false);


--
-- TOC entry 5912 (class 0 OID 0)
-- Dependencies: 287
-- Name: personas_directores_carreras_id_persona_director_carrera_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_directores_carreras_id_persona_director_carrera_seq', 1, false);


--
-- TOC entry 5913 (class 0 OID 0)
-- Dependencies: 301
-- Name: personas_directores_posgrados_id_persona_director_posgrado_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_directores_posgrados_id_persona_director_posgrado_seq', 1, false);


--
-- TOC entry 5914 (class 0 OID 0)
-- Dependencies: 283
-- Name: personas_docentes_id_persona_docente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_docentes_id_persona_docente_seq', 1, false);


--
-- TOC entry 5915 (class 0 OID 0)
-- Dependencies: 303
-- Name: personas_facultades_administr_id_persona_facultad_administr_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_facultades_administr_id_persona_facultad_administr_seq', 1, false);


--
-- TOC entry 5916 (class 0 OID 0)
-- Dependencies: 265
-- Name: personas_id_persona_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_id_persona_seq', 2, true);


--
-- TOC entry 5917 (class 0 OID 0)
-- Dependencies: 305
-- Name: personas_roles_id_persona_rol_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.personas_roles_id_persona_rol_seq', 1, false);


--
-- TOC entry 5918 (class 0 OID 0)
-- Dependencies: 244
-- Name: pisos_bloques_id_piso_bloque_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pisos_bloques_id_piso_bloque_seq', 1, false);


--
-- TOC entry 5919 (class 0 OID 0)
-- Dependencies: 242
-- Name: pisos_id_piso_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pisos_id_piso_seq', 1, false);


--
-- TOC entry 5920 (class 0 OID 0)
-- Dependencies: 335
-- Name: posgrado_alumnos_documentos_id_posgrado_alumno_documento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrado_alumnos_documentos_id_posgrado_alumno_documento_seq', 1, false);


--
-- TOC entry 5921 (class 0 OID 0)
-- Dependencies: 345
-- Name: posgrado_asignaciones_docente_id_posgrado_asignacion_docent_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrado_asignaciones_docente_id_posgrado_asignacion_docent_seq', 1, false);


--
-- TOC entry 5922 (class 0 OID 0)
-- Dependencies: 349
-- Name: posgrado_asignaciones_horario_id_posgrado_asignacion_horari_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrado_asignaciones_horario_id_posgrado_asignacion_horari_seq', 1, false);


--
-- TOC entry 5923 (class 0 OID 0)
-- Dependencies: 347
-- Name: posgrado_calificaciones_id_postgrado_calificacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrado_calificaciones_id_postgrado_calificacion_seq', 1, false);


--
-- TOC entry 5924 (class 0 OID 0)
-- Dependencies: 351
-- Name: posgrado_clases_videos_id_posgrado_clase_video_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrado_clases_videos_id_posgrado_clase_video_seq', 1, false);


--
-- TOC entry 5925 (class 0 OID 0)
-- Dependencies: 341
-- Name: posgrado_materias_id_posgrado_materia_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrado_materias_id_posgrado_materia_seq', 1, false);


--
-- TOC entry 5926 (class 0 OID 0)
-- Dependencies: 339
-- Name: posgrado_niveles_id_posgrado_nivel_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrado_niveles_id_posgrado_nivel_seq', 1, false);


--
-- TOC entry 5927 (class 0 OID 0)
-- Dependencies: 343
-- Name: posgrado_tipos_evaluaciones_n_id_posgrado_tipo_evaluacion_n_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrado_tipos_evaluaciones_n_id_posgrado_tipo_evaluacion_n_seq', 1, false);


--
-- TOC entry 5928 (class 0 OID 0)
-- Dependencies: 321
-- Name: posgrados_contratos_detalles_desglose_id_posgrado_desglose_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrados_contratos_detalles_desglose_id_posgrado_desglose_seq', 1, false);


--
-- TOC entry 5929 (class 0 OID 0)
-- Dependencies: 319
-- Name: posgrados_contratos_detalles_id_posgrado_contrato_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrados_contratos_detalles_id_posgrado_contrato_detalle_seq', 1, false);


--
-- TOC entry 5930 (class 0 OID 0)
-- Dependencies: 317
-- Name: posgrados_contratos_id_posgrado_contrato_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrados_contratos_id_posgrado_contrato_seq', 1, false);


--
-- TOC entry 5931 (class 0 OID 0)
-- Dependencies: 307
-- Name: posgrados_programas_id_posgrado_programa_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrados_programas_id_posgrado_programa_seq', 1, false);


--
-- TOC entry 5932 (class 0 OID 0)
-- Dependencies: 325
-- Name: posgrados_transacciones_detal_id_posgrado_transaccion_detal_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrados_transacciones_detal_id_posgrado_transaccion_detal_seq', 1, false);


--
-- TOC entry 5933 (class 0 OID 0)
-- Dependencies: 327
-- Name: posgrados_transacciones_detalles_de_id_transaccion_desglose_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrados_transacciones_detalles_de_id_transaccion_desglose_seq', 1, false);


--
-- TOC entry 5934 (class 0 OID 0)
-- Dependencies: 323
-- Name: posgrados_transacciones_id_posgrado_transaccion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posgrados_transacciones_id_posgrado_transaccion_seq', 1, false);


--
-- TOC entry 5935 (class 0 OID 0)
-- Dependencies: 253
-- Name: provincias_id_provincia_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.provincias_id_provincia_seq', 1, false);


--
-- TOC entry 5936 (class 0 OID 0)
-- Dependencies: 230
-- Name: roles_id_rol_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_rol_seq', 1, false);


--
-- TOC entry 5937 (class 0 OID 0)
-- Dependencies: 232
-- Name: roles_menus_principales_id_rol_menu_principal_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_menus_principales_id_rol_menu_principal_seq', 1, false);


--
-- TOC entry 5938 (class 0 OID 0)
-- Dependencies: 273
-- Name: sedes_id_sede_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sedes_id_sede_seq', 1, false);


--
-- TOC entry 5939 (class 0 OID 0)
-- Dependencies: 259
-- Name: sexos_id_sexo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sexos_id_sexo_seq', 11, true);


--
-- TOC entry 5940 (class 0 OID 0)
-- Dependencies: 293
-- Name: tipos_evaluaciones_notas_id_tipo_evaluacion_nota_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_evaluaciones_notas_id_tipo_evaluacion_nota_seq', 1, false);


--
-- TOC entry 5941 (class 0 OID 0)
-- Dependencies: 279
-- Name: tipos_personas_id_tipo_persona_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_personas_id_tipo_persona_seq', 1, false);


--
-- TOC entry 5942 (class 0 OID 0)
-- Dependencies: 331
-- Name: tramites_documentos_id_tramite_documento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tramites_documentos_id_tramite_documento_seq', 1, true);


--
-- TOC entry 5943 (class 0 OID 0)
-- Dependencies: 216
-- Name: universidades_id_universidad_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.universidades_id_universidad_seq', 1, true);


--
-- TOC entry 5944 (class 0 OID 0)
-- Dependencies: 267
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_usuario_seq', 3, true);


--
-- TOC entry 5362 (class 2606 OID 18258)
-- Name: encrypted_log_table encrypted_log_table_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.encrypted_log_table
    ADD CONSTRAINT encrypted_log_table_pkey PRIMARY KEY (id);


--
-- TOC entry 5360 (class 2606 OID 18249)
-- Name: log_table log_table_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_table
    ADD CONSTRAINT log_table_pkey PRIMARY KEY (id);


--
-- TOC entry 5288 (class 2606 OID 16838)
-- Name: personas_alumnos pk_alumnos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_alumnos
    ADD CONSTRAINT pk_alumnos PRIMARY KEY (id_persona_alumno);


--
-- TOC entry 5254 (class 2606 OID 16608)
-- Name: ambientes pk_ambientes; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ambientes
    ADD CONSTRAINT pk_ambientes PRIMARY KEY (id_ambiente);


--
-- TOC entry 5226 (class 2606 OID 16428)
-- Name: areas pk_areas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT pk_areas PRIMARY KEY (id_area);


--
-- TOC entry 5246 (class 2606 OID 16559)
-- Name: bloques pk_bloques; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bloques
    ADD CONSTRAINT pk_bloques PRIMARY KEY (id_bloque);


--
-- TOC entry 5240 (class 2606 OID 16520)
-- Name: campus pk_campus; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campus
    ADD CONSTRAINT pk_campus PRIMARY KEY (id_campu);


--
-- TOC entry 5284 (class 2606 OID 16791)
-- Name: carreras pk_carreras; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras
    ADD CONSTRAINT pk_carreras PRIMARY KEY (id_carrera);


--
-- TOC entry 5276 (class 2606 OID 16757)
-- Name: carreras_niveles_academicos pk_carreras_niveles_academicos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_niveles_academicos
    ADD CONSTRAINT pk_carreras_niveles_academicos PRIMARY KEY (id_carrera_nivel_academico);


--
-- TOC entry 5224 (class 2606 OID 16415)
-- Name: configuraciones pk_configuraciones; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuraciones
    ADD CONSTRAINT pk_configuraciones PRIMARY KEY (id_configuracion);


--
-- TOC entry 5322 (class 2606 OID 17091)
-- Name: cuentas_cargos_conceptos_posgrados pk_cuentas_cargos_conceptos_posgrados; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_conceptos_posgrados
    ADD CONSTRAINT pk_cuentas_cargos_conceptos_posgrados PRIMARY KEY (id_cuenta_cargo_concepto_posgrado);


--
-- TOC entry 5318 (class 2606 OID 17060)
-- Name: cuentas_cargos_posgrados pk_cuentas_cargos_posgrados; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_posgrados
    ADD CONSTRAINT pk_cuentas_cargos_posgrados PRIMARY KEY (id_cuenta_cargo_posgrado);


--
-- TOC entry 5320 (class 2606 OID 17073)
-- Name: cuentas_cargos_posgrados_conceptos pk_cuentas_cargos_posgrados_conceptos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_posgrados_conceptos
    ADD CONSTRAINT pk_cuentas_cargos_posgrados_conceptos PRIMARY KEY (id_cuenta_cargo_posgrado_concepto);


--
-- TOC entry 5306 (class 2606 OID 16962)
-- Name: cuentas_conceptos pk_cuentas_conceptos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_conceptos
    ADD CONSTRAINT pk_cuentas_conceptos PRIMARY KEY (id_cuenta_concepto);


--
-- TOC entry 5258 (class 2606 OID 16634)
-- Name: departamentos pk_departamentos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departamentos
    ADD CONSTRAINT pk_departamentos PRIMARY KEY (id_departamento);


--
-- TOC entry 5302 (class 2606 OID 16944)
-- Name: dias pk_dias; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dias
    ADD CONSTRAINT pk_dias PRIMARY KEY (id_dia);


--
-- TOC entry 5242 (class 2606 OID 16528)
-- Name: edificios pk_edificios; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edificios
    ADD CONSTRAINT pk_edificios PRIMARY KEY (id_edificio);


--
-- TOC entry 5270 (class 2606 OID 16697)
-- Name: emision_cedulas pk_emision_cedulas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.emision_cedulas
    ADD CONSTRAINT pk_emision_cedulas PRIMARY KEY (id_emision_cedula);


--
-- TOC entry 5268 (class 2606 OID 16689)
-- Name: estados_civiles pk_estados_civiles; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estados_civiles
    ADD CONSTRAINT pk_estados_civiles PRIMARY KEY (id_estado_civil);


--
-- TOC entry 5344 (class 2606 OID 17285)
-- Name: extractos_bancarios pk_extractos_bancarios; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.extractos_bancarios
    ADD CONSTRAINT pk_extractos_bancarios PRIMARY KEY (id_extracto_bancario);


--
-- TOC entry 5228 (class 2606 OID 16443)
-- Name: facultades pk_facultades; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facultades
    ADD CONSTRAINT pk_facultades PRIMARY KEY (id_facultad);


--
-- TOC entry 5244 (class 2606 OID 16541)
-- Name: facultades_edificios pk_facultades_edificios; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facultades_edificios
    ADD CONSTRAINT pk_facultades_edificios PRIMARY KEY (id_facultad_edificio);


--
-- TOC entry 5298 (class 2606 OID 16924)
-- Name: gestiones_periodos pk_gestiones_periodos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gestiones_periodos
    ADD CONSTRAINT pk_gestiones_periodos PRIMARY KEY (id_gestion_periodo);


--
-- TOC entry 5264 (class 2606 OID 16673)
-- Name: grupos_sanguineos pk_grupos_sanguineos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupos_sanguineos
    ADD CONSTRAINT pk_grupos_sanguineos PRIMARY KEY (id_grupo_sanguineo);


--
-- TOC entry 5304 (class 2606 OID 16952)
-- Name: horas_clases pk_horas_clases; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horas_clases
    ADD CONSTRAINT pk_horas_clases PRIMARY KEY (id_hora_clase);


--
-- TOC entry 5262 (class 2606 OID 16660)
-- Name: localidades pk_localidades; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT pk_localidades PRIMARY KEY (id_localidad);


--
-- TOC entry 5234 (class 2606 OID 16479)
-- Name: menus pk_menus; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT pk_menus PRIMARY KEY (id_menu);


--
-- TOC entry 5232 (class 2606 OID 16464)
-- Name: menus_principales pk_menus_principales; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menus_principales
    ADD CONSTRAINT pk_menus_principales PRIMARY KEY (id_menu_principal);


--
-- TOC entry 5282 (class 2606 OID 16781)
-- Name: modalidades pk_modalidades; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modalidades
    ADD CONSTRAINT pk_modalidades PRIMARY KEY (id_modalidad);


--
-- TOC entry 5230 (class 2606 OID 16456)
-- Name: modulos pk_modulos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modulos
    ADD CONSTRAINT pk_modulos PRIMARY KEY (id_modulo);


--
-- TOC entry 5336 (class 2606 OID 17224)
-- Name: montos_excedentes pk_montos_excedentes; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.montos_excedentes
    ADD CONSTRAINT pk_montos_excedentes PRIMARY KEY (id_monto_exedente);


--
-- TOC entry 5278 (class 2606 OID 16765)
-- Name: niveles_academicos pk_niveles_academicos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveles_academicos
    ADD CONSTRAINT pk_niveles_academicos PRIMARY KEY (id_nivel_academico);


--
-- TOC entry 5340 (class 2606 OID 17246)
-- Name: niveles_academicos_tramites_documentos pk_niveles_academicos_tramites_documentos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveles_academicos_tramites_documentos
    ADD CONSTRAINT pk_niveles_academicos_tramites_documentos PRIMARY KEY (id_nivel_academico_tramite_documento);


--
-- TOC entry 5256 (class 2606 OID 16626)
-- Name: paises pk_paises; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paises
    ADD CONSTRAINT pk_paises PRIMARY KEY (id_pais);


--
-- TOC entry 5272 (class 2606 OID 16708)
-- Name: personas pk_personas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT pk_personas PRIMARY KEY (id_persona);


--
-- TOC entry 5292 (class 2606 OID 16871)
-- Name: personas_administrativos pk_personas_administrativos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_administrativos
    ADD CONSTRAINT pk_personas_administrativos PRIMARY KEY (id_persona_administrativo);


--
-- TOC entry 5316 (class 2606 OID 17040)
-- Name: personas_alumnos_posgrados pk_personas_alumnos_posgrados; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_alumnos_posgrados
    ADD CONSTRAINT pk_personas_alumnos_posgrados PRIMARY KEY (id_persona_alumno_posgrado);


--
-- TOC entry 5296 (class 2606 OID 16906)
-- Name: personas_decanos pk_personas_decanos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_decanos
    ADD CONSTRAINT pk_personas_decanos PRIMARY KEY (id_persona_decano);


--
-- TOC entry 5294 (class 2606 OID 16886)
-- Name: personas_directores_carreras pk_personas_directores_carreras; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_directores_carreras
    ADD CONSTRAINT pk_personas_directores_carreras PRIMARY KEY (id_persona_director_carrera);


--
-- TOC entry 5308 (class 2606 OID 16970)
-- Name: personas_directores_posgrados pk_personas_directores_posgrados; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_directores_posgrados
    ADD CONSTRAINT pk_personas_directores_posgrados PRIMARY KEY (id_persona_director_posgrado);


--
-- TOC entry 5290 (class 2606 OID 16857)
-- Name: personas_docentes pk_personas_docentes; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_docentes
    ADD CONSTRAINT pk_personas_docentes PRIMARY KEY (id_persona_docente);


--
-- TOC entry 5310 (class 2606 OID 16983)
-- Name: personas_facultades_administradores pk_personas_facultades_administradores; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_facultades_administradores
    ADD CONSTRAINT pk_personas_facultades_administradores PRIMARY KEY (id_persona_facultad_administrador);


--
-- TOC entry 5312 (class 2606 OID 16996)
-- Name: personas_roles pk_personas_roles; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_roles
    ADD CONSTRAINT pk_personas_roles PRIMARY KEY (id_persona_rol);


--
-- TOC entry 5248 (class 2606 OID 16572)
-- Name: pisos pk_pisos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pisos
    ADD CONSTRAINT pk_pisos PRIMARY KEY (id_piso);


--
-- TOC entry 5250 (class 2606 OID 16580)
-- Name: pisos_bloques pk_pisos_bloques; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pisos_bloques
    ADD CONSTRAINT pk_pisos_bloques PRIMARY KEY (id_piso_bloque);


--
-- TOC entry 5342 (class 2606 OID 17266)
-- Name: posgrado_alumnos_documentos pk_posgrado_alumnos_documentos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_alumnos_documentos
    ADD CONSTRAINT pk_posgrado_alumnos_documentos PRIMARY KEY (id_posgrado_alumno_documento);


--
-- TOC entry 5352 (class 2606 OID 17345)
-- Name: posgrado_asignaciones_docentes pk_posgrado_asignaciones_docentes; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_docentes
    ADD CONSTRAINT pk_posgrado_asignaciones_docentes PRIMARY KEY (id_posgrado_asignacion_docente);


--
-- TOC entry 5356 (class 2606 OID 17422)
-- Name: posgrado_asignaciones_horarios pk_posgrado_asignaciones_horarios; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_horarios
    ADD CONSTRAINT pk_posgrado_asignaciones_horarios PRIMARY KEY (id_posgrado_asignacion_horario);


--
-- TOC entry 5354 (class 2606 OID 17401)
-- Name: posgrado_calificaciones pk_posgrado_calificaciones; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_calificaciones
    ADD CONSTRAINT pk_posgrado_calificaciones PRIMARY KEY (id_postgrado_calificacion);


--
-- TOC entry 5358 (class 2606 OID 17451)
-- Name: posgrado_clases_videos pk_posgrado_clases_videos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_clases_videos
    ADD CONSTRAINT pk_posgrado_clases_videos PRIMARY KEY (id_posgrado_clase_video);


--
-- TOC entry 5346 (class 2606 OID 17293)
-- Name: posgrado_niveles pk_posgrado_niveles; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_niveles
    ADD CONSTRAINT pk_posgrado_niveles PRIMARY KEY (id_posgrado_nivel);


--
-- TOC entry 5350 (class 2606 OID 17330)
-- Name: posgrado_tipos_evaluaciones_notas pk_posgrado_tipos_evaluaciones_notas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_tipos_evaluaciones_notas
    ADD CONSTRAINT pk_posgrado_tipos_evaluaciones_notas PRIMARY KEY (id_posgrado_tipo_evaluacion_nota);


--
-- TOC entry 5324 (class 2606 OID 17104)
-- Name: posgrados_contratos pk_posgrados_contratos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos
    ADD CONSTRAINT pk_posgrados_contratos PRIMARY KEY (id_posgrado_contrato);


--
-- TOC entry 5326 (class 2606 OID 17137)
-- Name: posgrados_contratos_detalles pk_posgrados_contratos_detalles; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos_detalles
    ADD CONSTRAINT pk_posgrados_contratos_detalles PRIMARY KEY (id_posgrado_contrato_detalle);


--
-- TOC entry 5328 (class 2606 OID 17155)
-- Name: posgrados_contratos_detalles_desglose pk_posgrados_contratos_detalles_desglose; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos_detalles_desglose
    ADD CONSTRAINT pk_posgrados_contratos_detalles_desglose PRIMARY KEY (id_posgrado_desglose);


--
-- TOC entry 5314 (class 2606 OID 17016)
-- Name: posgrados_programas pk_posgrados_programas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_programas
    ADD CONSTRAINT pk_posgrados_programas PRIMARY KEY (id_posgrado_programa);


--
-- TOC entry 5334 (class 2606 OID 17205)
-- Name: posgrados_transacciones_detalles_desglose pk_posgrados_transaccion_detalles_desglose; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones_detalles_desglose
    ADD CONSTRAINT pk_posgrados_transaccion_detalles_desglose PRIMARY KEY (id_transaccion_desglose);


--
-- TOC entry 5330 (class 2606 OID 17168)
-- Name: posgrados_transacciones pk_posgrados_transacciones; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones
    ADD CONSTRAINT pk_posgrados_transacciones PRIMARY KEY (id_posgrado_transaccion);


--
-- TOC entry 5332 (class 2606 OID 17187)
-- Name: posgrados_transacciones_detalles pk_posgrados_transacciones_detalles; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones_detalles
    ADD CONSTRAINT pk_posgrados_transacciones_detalles PRIMARY KEY (id_posgrado_transaccion_detalle);


--
-- TOC entry 5348 (class 2606 OID 17310)
-- Name: posgrado_materias pk_postgrado_materias; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_materias
    ADD CONSTRAINT pk_postgrado_materias PRIMARY KEY (id_posgrado_materia);


--
-- TOC entry 5260 (class 2606 OID 16647)
-- Name: provincias pk_provincias; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provincias
    ADD CONSTRAINT pk_provincias PRIMARY KEY (id_provincia);


--
-- TOC entry 5236 (class 2606 OID 16492)
-- Name: roles pk_roles; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT pk_roles PRIMARY KEY (id_rol);


--
-- TOC entry 5238 (class 2606 OID 16500)
-- Name: roles_menus_principales pk_roles_menus_principales; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_menus_principales
    ADD CONSTRAINT pk_roles_menus_principales PRIMARY KEY (id_rol_menu_principal);


--
-- TOC entry 5280 (class 2606 OID 16773)
-- Name: sedes pk_sedes; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sedes
    ADD CONSTRAINT pk_sedes PRIMARY KEY (id_sede);


--
-- TOC entry 5266 (class 2606 OID 16681)
-- Name: sexos pk_sexos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sexos
    ADD CONSTRAINT pk_sexos PRIMARY KEY (id_sexo);


--
-- TOC entry 5252 (class 2606 OID 16598)
-- Name: tipos_ambientes pk_tipos_ambientes; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_ambientes
    ADD CONSTRAINT pk_tipos_ambientes PRIMARY KEY (id_tipo_ambiente);


--
-- TOC entry 5300 (class 2606 OID 16936)
-- Name: tipos_evaluaciones_notas pk_tipos_evaluaciones_notas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_evaluaciones_notas
    ADD CONSTRAINT pk_tipos_evaluaciones_notas PRIMARY KEY (id_tipo_evaluacion_nota);


--
-- TOC entry 5286 (class 2606 OID 16819)
-- Name: tipos_personas pk_tipos_personas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_personas
    ADD CONSTRAINT pk_tipos_personas PRIMARY KEY (id_tipo_persona);


--
-- TOC entry 5338 (class 2606 OID 17237)
-- Name: tramites_documentos pk_tramites_documentos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tramites_documentos
    ADD CONSTRAINT pk_tramites_documentos PRIMARY KEY (id_tramite_documento);


--
-- TOC entry 5222 (class 2606 OID 16405)
-- Name: universidades pk_universidades; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.universidades
    ADD CONSTRAINT pk_universidades PRIMARY KEY (id_universidad);


--
-- TOC entry 5274 (class 2606 OID 16744)
-- Name: usuarios pk_usuarios; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT pk_usuarios PRIMARY KEY (id_usuario);


--
-- TOC entry 5462 (class 2620 OID 18274)
-- Name: ambientes log_changes_ambientes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_ambientes AFTER INSERT OR DELETE OR UPDATE ON public.ambientes FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5448 (class 2620 OID 18261)
-- Name: areas log_changes_areas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_areas AFTER INSERT OR DELETE OR UPDATE ON public.areas FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5458 (class 2620 OID 18271)
-- Name: bloques log_changes_bloques; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_bloques AFTER INSERT OR DELETE OR UPDATE ON public.bloques FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5455 (class 2620 OID 18268)
-- Name: campus log_changes_campus; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_campus AFTER INSERT OR DELETE OR UPDATE ON public.campus FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5477 (class 2620 OID 18287)
-- Name: carreras log_changes_carreras; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_carreras AFTER INSERT OR DELETE OR UPDATE ON public.carreras FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5473 (class 2620 OID 18288)
-- Name: carreras_niveles_academicos log_changes_carreras_niveles_academicos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_carreras_niveles_academicos AFTER INSERT OR DELETE OR UPDATE ON public.carreras_niveles_academicos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5447 (class 2620 OID 18260)
-- Name: configuraciones log_changes_configuraciones; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_configuraciones AFTER INSERT OR DELETE OR UPDATE ON public.configuraciones FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5496 (class 2620 OID 18309)
-- Name: cuentas_cargos_conceptos_posgrados log_changes_cuentas_cargos_conceptos_posgrados; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_cuentas_cargos_conceptos_posgrados AFTER INSERT OR DELETE OR UPDATE ON public.cuentas_cargos_conceptos_posgrados FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5494 (class 2620 OID 18303)
-- Name: cuentas_cargos_posgrados log_changes_cuentas_cargos_posgrados; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_cuentas_cargos_posgrados AFTER INSERT OR DELETE OR UPDATE ON public.cuentas_cargos_posgrados FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5495 (class 2620 OID 18304)
-- Name: cuentas_cargos_posgrados_conceptos log_changes_cuentas_cargos_posgrados_conceptos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_cuentas_cargos_posgrados_conceptos AFTER INSERT OR DELETE OR UPDATE ON public.cuentas_cargos_posgrados_conceptos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5488 (class 2620 OID 18308)
-- Name: cuentas_conceptos log_changes_cuentas_conceptos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_cuentas_conceptos AFTER INSERT OR DELETE OR UPDATE ON public.cuentas_conceptos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5464 (class 2620 OID 18276)
-- Name: departamentos log_changes_departamentos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_departamentos AFTER INSERT OR DELETE OR UPDATE ON public.departamentos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5486 (class 2620 OID 18305)
-- Name: dias log_changes_dias; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_dias AFTER INSERT OR DELETE OR UPDATE ON public.dias FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5456 (class 2620 OID 18269)
-- Name: edificios log_changes_edificios; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_edificios AFTER INSERT OR DELETE OR UPDATE ON public.edificios FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5470 (class 2620 OID 18284)
-- Name: emision_cedulas log_changes_emision_cedulas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_emision_cedulas AFTER INSERT OR DELETE OR UPDATE ON public.emision_cedulas FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5469 (class 2620 OID 18283)
-- Name: estados_civiles log_changes_estados_civiles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_estados_civiles AFTER INSERT OR DELETE OR UPDATE ON public.estados_civiles FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5507 (class 2620 OID 18322)
-- Name: extractos_bancarios log_changes_extractos_bancarios; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_extractos_bancarios AFTER INSERT OR DELETE OR UPDATE ON public.extractos_bancarios FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5449 (class 2620 OID 18262)
-- Name: facultades log_changes_facultades; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_facultades AFTER INSERT OR DELETE OR UPDATE ON public.facultades FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5457 (class 2620 OID 18270)
-- Name: facultades_edificios log_changes_facultades_edificios; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_facultades_edificios AFTER INSERT OR DELETE OR UPDATE ON public.facultades_edificios FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5484 (class 2620 OID 18297)
-- Name: gestiones_periodos log_changes_gestiones_periodos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_gestiones_periodos AFTER INSERT OR DELETE OR UPDATE ON public.gestiones_periodos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5467 (class 2620 OID 18282)
-- Name: grupos_sanguineos log_changes_grupos_sanguineos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_grupos_sanguineos AFTER INSERT OR DELETE OR UPDATE ON public.grupos_sanguineos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5487 (class 2620 OID 18306)
-- Name: horas_clases log_changes_horas_clases; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_horas_clases AFTER INSERT OR DELETE OR UPDATE ON public.horas_clases FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5466 (class 2620 OID 18278)
-- Name: localidades log_changes_localidades; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_localidades AFTER INSERT OR DELETE OR UPDATE ON public.localidades FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5452 (class 2620 OID 18265)
-- Name: menus log_changes_menus; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_menus AFTER INSERT OR DELETE OR UPDATE ON public.menus FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5451 (class 2620 OID 18264)
-- Name: menus_principales log_changes_menus_principales; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_menus_principales AFTER INSERT OR DELETE OR UPDATE ON public.menus_principales FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5476 (class 2620 OID 18290)
-- Name: modalidades log_changes_modalidades; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_modalidades AFTER INSERT OR DELETE OR UPDATE ON public.modalidades FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5450 (class 2620 OID 18263)
-- Name: modulos log_changes_modulos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_modulos AFTER INSERT OR DELETE OR UPDATE ON public.modulos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5503 (class 2620 OID 18316)
-- Name: montos_excedentes log_changes_montos_excedentes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_montos_excedentes AFTER INSERT OR DELETE OR UPDATE ON public.montos_excedentes FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5474 (class 2620 OID 18286)
-- Name: niveles_academicos log_changes_niveles_academicos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_niveles_academicos AFTER INSERT OR DELETE OR UPDATE ON public.niveles_academicos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5505 (class 2620 OID 18317)
-- Name: niveles_academicos_tramites_documentos log_changes_niveles_academicos_tramites_documentos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_niveles_academicos_tramites_documentos AFTER INSERT OR DELETE OR UPDATE ON public.niveles_academicos_tramites_documentos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5463 (class 2620 OID 18275)
-- Name: paises log_changes_paises; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_paises AFTER INSERT OR DELETE OR UPDATE ON public.paises FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5471 (class 2620 OID 18279)
-- Name: personas log_changes_personas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas AFTER INSERT OR DELETE OR UPDATE ON public.personas FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5481 (class 2620 OID 18294)
-- Name: personas_administrativos log_changes_personas_administrativos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas_administrativos AFTER INSERT OR DELETE OR UPDATE ON public.personas_administrativos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5479 (class 2620 OID 18292)
-- Name: personas_alumnos log_changes_personas_alumnos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas_alumnos AFTER INSERT OR DELETE OR UPDATE ON public.personas_alumnos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5493 (class 2620 OID 18302)
-- Name: personas_alumnos_posgrados log_changes_personas_alumnos_posgrados; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas_alumnos_posgrados AFTER INSERT OR DELETE OR UPDATE ON public.personas_alumnos_posgrados FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5483 (class 2620 OID 18296)
-- Name: personas_decanos log_changes_personas_decanos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas_decanos AFTER INSERT OR DELETE OR UPDATE ON public.personas_decanos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5482 (class 2620 OID 18295)
-- Name: personas_directores_carreras log_changes_personas_directores_carreras; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas_directores_carreras AFTER INSERT OR DELETE OR UPDATE ON public.personas_directores_carreras FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5489 (class 2620 OID 18298)
-- Name: personas_directores_posgrados log_changes_personas_directores_posgrados; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas_directores_posgrados AFTER INSERT OR DELETE OR UPDATE ON public.personas_directores_posgrados FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5480 (class 2620 OID 18293)
-- Name: personas_docentes log_changes_personas_docentes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas_docentes AFTER INSERT OR DELETE OR UPDATE ON public.personas_docentes FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5490 (class 2620 OID 18299)
-- Name: personas_facultades_administradores log_changes_personas_facultades_administradores; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas_facultades_administradores AFTER INSERT OR DELETE OR UPDATE ON public.personas_facultades_administradores FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5491 (class 2620 OID 18300)
-- Name: personas_roles log_changes_personas_roles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_personas_roles AFTER INSERT OR DELETE OR UPDATE ON public.personas_roles FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5459 (class 2620 OID 18273)
-- Name: pisos log_changes_pisos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_pisos AFTER INSERT OR DELETE OR UPDATE ON public.pisos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5460 (class 2620 OID 18272)
-- Name: pisos_bloques log_changes_pisos_bloques; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_pisos_bloques AFTER INSERT OR DELETE OR UPDATE ON public.pisos_bloques FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5506 (class 2620 OID 18319)
-- Name: posgrado_alumnos_documentos log_changes_posgrado_alumnos_documentos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrado_alumnos_documentos AFTER INSERT OR DELETE OR UPDATE ON public.posgrado_alumnos_documentos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5511 (class 2620 OID 18323)
-- Name: posgrado_asignaciones_docentes log_changes_posgrado_asignaciones_docentes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrado_asignaciones_docentes AFTER INSERT OR DELETE OR UPDATE ON public.posgrado_asignaciones_docentes FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5513 (class 2620 OID 18326)
-- Name: posgrado_asignaciones_horarios log_changes_posgrado_asignaciones_horarios; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrado_asignaciones_horarios AFTER INSERT OR DELETE OR UPDATE ON public.posgrado_asignaciones_horarios FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5512 (class 2620 OID 18325)
-- Name: posgrado_calificaciones log_changes_posgrado_calificaciones; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrado_calificaciones AFTER INSERT OR DELETE OR UPDATE ON public.posgrado_calificaciones FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5514 (class 2620 OID 18327)
-- Name: posgrado_clases_videos log_changes_posgrado_clases_videos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrado_clases_videos AFTER INSERT OR DELETE OR UPDATE ON public.posgrado_clases_videos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5509 (class 2620 OID 18320)
-- Name: posgrado_materias log_changes_posgrado_materias; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrado_materias AFTER INSERT OR DELETE OR UPDATE ON public.posgrado_materias FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5508 (class 2620 OID 18321)
-- Name: posgrado_niveles log_changes_posgrado_niveles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrado_niveles AFTER INSERT OR DELETE OR UPDATE ON public.posgrado_niveles FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5510 (class 2620 OID 18324)
-- Name: posgrado_tipos_evaluaciones_notas log_changes_posgrado_tipos_evaluaciones_notas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrado_tipos_evaluaciones_notas AFTER INSERT OR DELETE OR UPDATE ON public.posgrado_tipos_evaluaciones_notas FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5497 (class 2620 OID 18310)
-- Name: posgrados_contratos log_changes_posgrados_contratos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrados_contratos AFTER INSERT OR DELETE OR UPDATE ON public.posgrados_contratos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5498 (class 2620 OID 18311)
-- Name: posgrados_contratos_detalles log_changes_posgrados_contratos_detalles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrados_contratos_detalles AFTER INSERT OR DELETE OR UPDATE ON public.posgrados_contratos_detalles FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5499 (class 2620 OID 18312)
-- Name: posgrados_contratos_detalles_desglose log_changes_posgrados_contratos_detalles_desglose; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrados_contratos_detalles_desglose AFTER INSERT OR DELETE OR UPDATE ON public.posgrados_contratos_detalles_desglose FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5492 (class 2620 OID 18301)
-- Name: posgrados_programas log_changes_posgrados_programas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrados_programas AFTER INSERT OR DELETE OR UPDATE ON public.posgrados_programas FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5500 (class 2620 OID 18313)
-- Name: posgrados_transacciones log_changes_posgrados_transacciones; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrados_transacciones AFTER INSERT OR DELETE OR UPDATE ON public.posgrados_transacciones FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5501 (class 2620 OID 18314)
-- Name: posgrados_transacciones_detalles log_changes_posgrados_transacciones_detalles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrados_transacciones_detalles AFTER INSERT OR DELETE OR UPDATE ON public.posgrados_transacciones_detalles FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5502 (class 2620 OID 18315)
-- Name: posgrados_transacciones_detalles_desglose log_changes_posgrados_transacciones_detalles_desglose; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_posgrados_transacciones_detalles_desglose AFTER INSERT OR DELETE OR UPDATE ON public.posgrados_transacciones_detalles_desglose FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5465 (class 2620 OID 18277)
-- Name: provincias log_changes_provincias; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_provincias AFTER INSERT OR DELETE OR UPDATE ON public.provincias FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5453 (class 2620 OID 18266)
-- Name: roles log_changes_roles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_roles AFTER INSERT OR DELETE OR UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5454 (class 2620 OID 18267)
-- Name: roles_menus_principales log_changes_roles_menus_principales; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_roles_menus_principales AFTER INSERT OR DELETE OR UPDATE ON public.roles_menus_principales FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5475 (class 2620 OID 18289)
-- Name: sedes log_changes_sedes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_sedes AFTER INSERT OR DELETE OR UPDATE ON public.sedes FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5468 (class 2620 OID 18280)
-- Name: sexos log_changes_sexos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_sexos AFTER INSERT OR DELETE OR UPDATE ON public.sexos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5461 (class 2620 OID 18281)
-- Name: tipos_ambientes log_changes_tipos_ambientes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_tipos_ambientes AFTER INSERT OR DELETE OR UPDATE ON public.tipos_ambientes FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5485 (class 2620 OID 18307)
-- Name: tipos_evaluaciones_notas log_changes_tipos_evaluaciones_notas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_tipos_evaluaciones_notas AFTER INSERT OR DELETE OR UPDATE ON public.tipos_evaluaciones_notas FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5478 (class 2620 OID 18291)
-- Name: tipos_personas log_changes_tipos_personas; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_tipos_personas AFTER INSERT OR DELETE OR UPDATE ON public.tipos_personas FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5504 (class 2620 OID 18318)
-- Name: tramites_documentos log_changes_tramites_documentos; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_tramites_documentos AFTER INSERT OR DELETE OR UPDATE ON public.tramites_documentos FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5446 (class 2620 OID 18259)
-- Name: universidades log_changes_universidades; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_universidades AFTER INSERT OR DELETE OR UPDATE ON public.universidades FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5472 (class 2620 OID 18285)
-- Name: usuarios log_changes_usuarios; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_changes_usuarios AFTER INSERT OR DELETE OR UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.log_changes();


--
-- TOC entry 5441 (class 2606 OID 17428)
-- Name: posgrado_asignaciones_horarios fk_ambientes_posgrado_asignaciones_horarios; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_horarios
    ADD CONSTRAINT fk_ambientes_posgrado_asignaciones_horarios FOREIGN KEY (id_ambiente) REFERENCES public.ambientes(id_ambiente);


--
-- TOC entry 5365 (class 2606 OID 16444)
-- Name: facultades fk_areas_facultades; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facultades
    ADD CONSTRAINT fk_areas_facultades FOREIGN KEY (id_area) REFERENCES public.areas(id_area);


--
-- TOC entry 5374 (class 2606 OID 16581)
-- Name: pisos_bloques fk_bloques_pisos_bloques; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pisos_bloques
    ADD CONSTRAINT fk_bloques_pisos_bloques FOREIGN KEY (id_bloque) REFERENCES public.bloques(id_bloque);


--
-- TOC entry 5370 (class 2606 OID 16529)
-- Name: edificios fk_campus_edificios; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.edificios
    ADD CONSTRAINT fk_campus_edificios FOREIGN KEY (id_campu) REFERENCES public.campus(id_campu);


--
-- TOC entry 5387 (class 2606 OID 16797)
-- Name: carreras fk_carreras_niveles_academicos_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras
    ADD CONSTRAINT fk_carreras_niveles_academicos_carreras FOREIGN KEY (id_carrera_nivel_academico) REFERENCES public.carreras_niveles_academicos(id_carrera_nivel_academico);


--
-- TOC entry 5393 (class 2606 OID 16844)
-- Name: personas_alumnos fk_carreras_personas_alumnos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_alumnos
    ADD CONSTRAINT fk_carreras_personas_alumnos FOREIGN KEY (id_carrera) REFERENCES public.carreras(id_carrera);


--
-- TOC entry 5397 (class 2606 OID 16887)
-- Name: personas_directores_carreras fk_carreras_personas_directores_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_directores_carreras
    ADD CONSTRAINT fk_carreras_personas_directores_carreras FOREIGN KEY (id_carrera) REFERENCES public.carreras(id_carrera);


--
-- TOC entry 5405 (class 2606 OID 17022)
-- Name: posgrados_programas fk_carreras_programa_posgrado; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_programas
    ADD CONSTRAINT fk_carreras_programa_posgrado FOREIGN KEY (id_carrera) REFERENCES public.carreras(id_carrera);


--
-- TOC entry 5414 (class 2606 OID 17105)
-- Name: posgrados_contratos fk_conceptos_cargos_contratos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos
    ADD CONSTRAINT fk_conceptos_cargos_contratos FOREIGN KEY (id_cuenta_cargo_posgrado) REFERENCES public.cuentas_cargos_posgrados(id_cuenta_cargo_posgrado);


--
-- TOC entry 5424 (class 2606 OID 17193)
-- Name: posgrados_transacciones_detalles fk_contrato_detalle_transacciones_detalles; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones_detalles
    ADD CONSTRAINT fk_contrato_detalle_transacciones_detalles FOREIGN KEY (id_posgrado_contrato_detalle) REFERENCES public.posgrados_contratos_detalles(id_posgrado_contrato_detalle);


--
-- TOC entry 5419 (class 2606 OID 17138)
-- Name: posgrados_contratos_detalles fk_contratos_posgrados_contratos_detalles; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos_detalles
    ADD CONSTRAINT fk_contratos_posgrados_contratos_detalles FOREIGN KEY (id_posgrado_contrato) REFERENCES public.posgrados_contratos(id_posgrado_contrato);


--
-- TOC entry 5421 (class 2606 OID 17156)
-- Name: posgrados_contratos_detalles_desglose fk_contratos_posgrados_contratos_detalles_desglose; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos_detalles_desglose
    ADD CONSTRAINT fk_contratos_posgrados_contratos_detalles_desglose FOREIGN KEY (id_posgrado_contrato_detalle) REFERENCES public.posgrados_contratos_detalles(id_posgrado_contrato_detalle);


--
-- TOC entry 5411 (class 2606 OID 17074)
-- Name: cuentas_cargos_posgrados_conceptos fk_cuentas_cargos_posgrados_cargos_conceptos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_posgrados_conceptos
    ADD CONSTRAINT fk_cuentas_cargos_posgrados_cargos_conceptos FOREIGN KEY (id_cuenta_cargo_posgrado) REFERENCES public.cuentas_cargos_posgrados(id_cuenta_cargo_posgrado);


--
-- TOC entry 5420 (class 2606 OID 17143)
-- Name: posgrados_contratos_detalles fk_cuentas_cargos_posgrados_contratos_detalles; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos_detalles
    ADD CONSTRAINT fk_cuentas_cargos_posgrados_contratos_detalles FOREIGN KEY (id_cuenta_cargo_concepto_posgrado) REFERENCES public.cuentas_cargos_conceptos_posgrados(id_cuenta_cargo_concepto_posgrado);


--
-- TOC entry 5412 (class 2606 OID 17079)
-- Name: cuentas_cargos_posgrados_conceptos fk_cuentas_cargos_posgrados_cuentas_cargos_conceptos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_posgrados_conceptos
    ADD CONSTRAINT fk_cuentas_cargos_posgrados_cuentas_cargos_conceptos FOREIGN KEY (id_cuenta_concepto) REFERENCES public.cuentas_conceptos(id_cuenta_concepto);


--
-- TOC entry 5413 (class 2606 OID 17092)
-- Name: cuentas_cargos_conceptos_posgrados fk_cuentas_conceptos_posgrados_conceptos_cargos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_conceptos_posgrados
    ADD CONSTRAINT fk_cuentas_conceptos_posgrados_conceptos_cargos FOREIGN KEY (id_cuenta_cargo_posgrado_concepto) REFERENCES public.cuentas_cargos_posgrados_conceptos(id_cuenta_cargo_posgrado_concepto);


--
-- TOC entry 5379 (class 2606 OID 16648)
-- Name: provincias fk_departamentos_provincias; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.provincias
    ADD CONSTRAINT fk_departamentos_provincias FOREIGN KEY (id_departamento) REFERENCES public.departamentos(id_departamento);


--
-- TOC entry 5442 (class 2606 OID 17433)
-- Name: posgrado_asignaciones_horarios fk_dias_posgrado_asignaciones_horarios; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_horarios
    ADD CONSTRAINT fk_dias_posgrado_asignaciones_horarios FOREIGN KEY (id_dia) REFERENCES public.dias(id_dia);


--
-- TOC entry 5373 (class 2606 OID 16560)
-- Name: bloques fk_edificios_bloques; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bloques
    ADD CONSTRAINT fk_edificios_bloques FOREIGN KEY (id_edificio) REFERENCES public.edificios(id_edificio);


--
-- TOC entry 5371 (class 2606 OID 16547)
-- Name: facultades_edificios fk_edificios_facultades_edificios; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facultades_edificios
    ADD CONSTRAINT fk_edificios_facultades_edificios FOREIGN KEY (id_edificio) REFERENCES public.edificios(id_edificio);


--
-- TOC entry 5381 (class 2606 OID 16729)
-- Name: personas fk_emision_cedulas_personas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_emision_cedulas_personas FOREIGN KEY (id_emision_cedula) REFERENCES public.emision_cedulas(id_emision_cedula);


--
-- TOC entry 5382 (class 2606 OID 16724)
-- Name: personas fk_estados_civiles_personas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_estados_civiles_personas FOREIGN KEY (id_estado_civil) REFERENCES public.estados_civiles(id_estado_civil);


--
-- TOC entry 5388 (class 2606 OID 16792)
-- Name: carreras fk_facultades_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras
    ADD CONSTRAINT fk_facultades_carreras FOREIGN KEY (id_facultad) REFERENCES public.facultades(id_facultad);


--
-- TOC entry 5372 (class 2606 OID 16542)
-- Name: facultades_edificios fk_facultades_facultades_edificios; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facultades_edificios
    ADD CONSTRAINT fk_facultades_facultades_edificios FOREIGN KEY (id_facultad) REFERENCES public.facultades(id_facultad);


--
-- TOC entry 5399 (class 2606 OID 16907)
-- Name: personas_decanos fk_facultades_id_persona_decano; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_decanos
    ADD CONSTRAINT fk_facultades_id_persona_decano FOREIGN KEY (id_facultad) REFERENCES public.facultades(id_facultad);


--
-- TOC entry 5435 (class 2606 OID 17361)
-- Name: posgrado_asignaciones_docentes fk_gestiones_periodos_posgrado_asignaciones_docentes; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_docentes
    ADD CONSTRAINT fk_gestiones_periodos_posgrado_asignaciones_docentes FOREIGN KEY (id_gestion_periodo) REFERENCES public.gestiones_periodos(id_gestion_periodo);


--
-- TOC entry 5383 (class 2606 OID 16719)
-- Name: personas fk_grupos_sanguineos_personas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_grupos_sanguineos_personas FOREIGN KEY (id_grupo_sanguineo) REFERENCES public.grupos_sanguineos(id_grupo_sanguineo);


--
-- TOC entry 5443 (class 2606 OID 17438)
-- Name: posgrado_asignaciones_horarios fk_horas_clases_posgrado_asignaciones_horarios; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_horarios
    ADD CONSTRAINT fk_horas_clases_posgrado_asignaciones_horarios FOREIGN KEY (id_hora_clase) REFERENCES public.horas_clases(id_hora_clase);


--
-- TOC entry 5384 (class 2606 OID 16709)
-- Name: personas fk_localidades_personas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_localidades_personas FOREIGN KEY (id_localidad) REFERENCES public.localidades(id_localidad);


--
-- TOC entry 5367 (class 2606 OID 16480)
-- Name: menus fk_menus_principales_menus; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT fk_menus_principales_menus FOREIGN KEY (id_menu_principal) REFERENCES public.menus_principales(id_menu_principal);


--
-- TOC entry 5368 (class 2606 OID 16506)
-- Name: roles_menus_principales fk_menus_principales_roles_menus_principales; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_menus_principales
    ADD CONSTRAINT fk_menus_principales_roles_menus_principales FOREIGN KEY (id_menu_principal) REFERENCES public.menus_principales(id_menu_principal);


--
-- TOC entry 5389 (class 2606 OID 16807)
-- Name: carreras fk_modalidades_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras
    ADD CONSTRAINT fk_modalidades_carreras FOREIGN KEY (id_modalidad) REFERENCES public.modalidades(id_modalidad);


--
-- TOC entry 5406 (class 2606 OID 17027)
-- Name: posgrados_programas fk_modalidades_programa_posgrado; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_programas
    ADD CONSTRAINT fk_modalidades_programa_posgrado FOREIGN KEY (id_modalidad) REFERENCES public.modalidades(id_modalidad);


--
-- TOC entry 5366 (class 2606 OID 16465)
-- Name: menus_principales fk_modulos_menus_principales; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.menus_principales
    ADD CONSTRAINT fk_modulos_menus_principales FOREIGN KEY (id_modulo) REFERENCES public.modulos(id_modulo);


--
-- TOC entry 5428 (class 2606 OID 17225)
-- Name: montos_excedentes fk_montos_excedentes_posgrados_transacciones; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.montos_excedentes
    ADD CONSTRAINT fk_montos_excedentes_posgrados_transacciones FOREIGN KEY (id_posgrado_transaccion_detalle) REFERENCES public.posgrados_transacciones_detalles(id_posgrado_transaccion_detalle);


--
-- TOC entry 5407 (class 2606 OID 17017)
-- Name: posgrados_programas fk_nivel_academico_programa_posgrado; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_programas
    ADD CONSTRAINT fk_nivel_academico_programa_posgrado FOREIGN KEY (id_nivel_academico) REFERENCES public.niveles_academicos(id_nivel_academico);


--
-- TOC entry 5429 (class 2606 OID 17247)
-- Name: niveles_academicos_tramites_documentos fk_niveles_academicos_niveles_academicos_tramites_documentos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveles_academicos_tramites_documentos
    ADD CONSTRAINT fk_niveles_academicos_niveles_academicos_tramites_documentos FOREIGN KEY (id_nivel_academico) REFERENCES public.niveles_academicos(id_nivel_academico);


--
-- TOC entry 5431 (class 2606 OID 17272)
-- Name: posgrado_alumnos_documentos fk_niveles_academicos_tramites_documentos_documentos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_alumnos_documentos
    ADD CONSTRAINT fk_niveles_academicos_tramites_documentos_documentos FOREIGN KEY (id_nivel_academico_tramite_documento) REFERENCES public.niveles_academicos_tramites_documentos(id_nivel_academico_tramite_documento);


--
-- TOC entry 5378 (class 2606 OID 16635)
-- Name: departamentos fk_paises_departamentos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departamentos
    ADD CONSTRAINT fk_paises_departamentos FOREIGN KEY (id_pais) REFERENCES public.paises(id_pais);


--
-- TOC entry 5432 (class 2606 OID 17267)
-- Name: posgrado_alumnos_documentos fk_personas_alumnos_posgrado_documentos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_alumnos_documentos
    ADD CONSTRAINT fk_personas_alumnos_posgrado_documentos FOREIGN KEY (id_persona_alumno_posgrado) REFERENCES public.personas_alumnos_posgrados(id_persona_alumno_posgrado);


--
-- TOC entry 5415 (class 2606 OID 17110)
-- Name: posgrados_contratos fk_personas_alumnos_posgrados_contratos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos
    ADD CONSTRAINT fk_personas_alumnos_posgrados_contratos FOREIGN KEY (id_persona_alumno_posgrado) REFERENCES public.personas_alumnos_posgrados(id_persona_alumno_posgrado);


--
-- TOC entry 5422 (class 2606 OID 17174)
-- Name: posgrados_transacciones fk_personas_alumnos_posgrados_transacciones; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones
    ADD CONSTRAINT fk_personas_alumnos_posgrados_transacciones FOREIGN KEY (id_persona_alumno_posgrado) REFERENCES public.personas_alumnos_posgrados(id_persona_alumno_posgrado);


--
-- TOC entry 5416 (class 2606 OID 17125)
-- Name: posgrados_contratos fk_personas_decanos_posgrados_contratos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos
    ADD CONSTRAINT fk_personas_decanos_posgrados_contratos FOREIGN KEY (id_persona_decano) REFERENCES public.personas_decanos(id_persona_decano);


--
-- TOC entry 5417 (class 2606 OID 17115)
-- Name: posgrados_contratos fk_personas_diectores_posgrado_posgrados_contratos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos
    ADD CONSTRAINT fk_personas_diectores_posgrado_posgrados_contratos FOREIGN KEY (id_persona_director_posgrado) REFERENCES public.personas_directores_posgrados(id_persona_director_posgrado);


--
-- TOC entry 5436 (class 2606 OID 17346)
-- Name: posgrado_asignaciones_docentes fk_personas_docentes_posgrado_asignaciones_docentes; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_docentes
    ADD CONSTRAINT fk_personas_docentes_posgrado_asignaciones_docentes FOREIGN KEY (id_persona_docente) REFERENCES public.personas_docentes(id_persona_docente);


--
-- TOC entry 5418 (class 2606 OID 17120)
-- Name: posgrados_contratos fk_personas_facultades_adminitradores_posgrados_contratos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_contratos
    ADD CONSTRAINT fk_personas_facultades_adminitradores_posgrados_contratos FOREIGN KEY (id_persona_facultad_administrador) REFERENCES public.personas_facultades_administradores(id_persona_facultad_administrador);


--
-- TOC entry 5400 (class 2606 OID 16912)
-- Name: personas_decanos fk_personas_id_persona_decano; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_decanos
    ADD CONSTRAINT fk_personas_id_persona_decano FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5396 (class 2606 OID 16872)
-- Name: personas_administrativos fk_personas_personas_administrativos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_administrativos
    ADD CONSTRAINT fk_personas_personas_administrativos FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5394 (class 2606 OID 16839)
-- Name: personas_alumnos fk_personas_personas_alumnos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_alumnos
    ADD CONSTRAINT fk_personas_personas_alumnos FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5408 (class 2606 OID 17041)
-- Name: personas_alumnos_posgrados fk_personas_personas_alumnos_posgrados; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_alumnos_posgrados
    ADD CONSTRAINT fk_personas_personas_alumnos_posgrados FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5398 (class 2606 OID 16892)
-- Name: personas_directores_carreras fk_personas_personas_directores_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_directores_carreras
    ADD CONSTRAINT fk_personas_personas_directores_carreras FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5395 (class 2606 OID 16858)
-- Name: personas_docentes fk_personas_personas_docentes; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_docentes
    ADD CONSTRAINT fk_personas_personas_docentes FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5401 (class 2606 OID 16971)
-- Name: personas_directores_posgrados fk_personas_personas_roles; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_directores_posgrados
    ADD CONSTRAINT fk_personas_personas_roles FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5402 (class 2606 OID 16984)
-- Name: personas_facultades_administradores fk_personas_personas_roles; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_facultades_administradores
    ADD CONSTRAINT fk_personas_personas_roles FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5403 (class 2606 OID 16997)
-- Name: personas_roles fk_personas_personas_roles; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_roles
    ADD CONSTRAINT fk_personas_personas_roles FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5391 (class 2606 OID 16820)
-- Name: tipos_personas fk_personas_tipos_personas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_personas
    ADD CONSTRAINT fk_personas_tipos_personas FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5386 (class 2606 OID 16745)
-- Name: usuarios fk_personas_usuarios; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT fk_personas_usuarios FOREIGN KEY (id_persona) REFERENCES public.personas(id_persona);


--
-- TOC entry 5376 (class 2606 OID 16609)
-- Name: ambientes fk_pisos_bloques_ambientes; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ambientes
    ADD CONSTRAINT fk_pisos_bloques_ambientes FOREIGN KEY (id_piso_bloque) REFERENCES public.pisos_bloques(id_piso_bloque);


--
-- TOC entry 5375 (class 2606 OID 16586)
-- Name: pisos_bloques fk_pisos_pisos_bloques; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pisos_bloques
    ADD CONSTRAINT fk_pisos_pisos_bloques FOREIGN KEY (id_piso) REFERENCES public.pisos(id_piso);


--
-- TOC entry 5444 (class 2606 OID 17423)
-- Name: posgrado_asignaciones_horarios fk_posg_asig_doc_posgrado_asig_horarios; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_horarios
    ADD CONSTRAINT fk_posg_asig_doc_posgrado_asig_horarios FOREIGN KEY (id_posgrado_asignacion_docente) REFERENCES public.posgrado_asignaciones_docentes(id_posgrado_asignacion_docente);


--
-- TOC entry 5439 (class 2606 OID 17407)
-- Name: posgrado_calificaciones fk_posgrado_asignaciones_docentes_posgrado_calificaciones; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_calificaciones
    ADD CONSTRAINT fk_posgrado_asignaciones_docentes_posgrado_calificaciones FOREIGN KEY (id_posgrado_asignacion_docente) REFERENCES public.posgrado_asignaciones_docentes(id_posgrado_asignacion_docente);


--
-- TOC entry 5445 (class 2606 OID 17452)
-- Name: posgrado_clases_videos fk_posgrado_asignaciones_horarios_posgrado_clases_videos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_clases_videos
    ADD CONSTRAINT fk_posgrado_asignaciones_horarios_posgrado_clases_videos FOREIGN KEY (id_posgrado_asignacion_horario) REFERENCES public.posgrado_asignaciones_horarios(id_posgrado_asignacion_horario);


--
-- TOC entry 5423 (class 2606 OID 17169)
-- Name: posgrados_transacciones fk_posgrado_contrato_posgrados_transacciones; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones
    ADD CONSTRAINT fk_posgrado_contrato_posgrados_transacciones FOREIGN KEY (id_posgrado_contrato) REFERENCES public.posgrados_contratos(id_posgrado_contrato);


--
-- TOC entry 5437 (class 2606 OID 17351)
-- Name: posgrado_asignaciones_docentes fk_posgrado_materias_posgrado_asignaciones_docentes; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_docentes
    ADD CONSTRAINT fk_posgrado_materias_posgrado_asignaciones_docentes FOREIGN KEY (id_posgrado_materia) REFERENCES public.posgrado_materias(id_posgrado_materia);


--
-- TOC entry 5433 (class 2606 OID 17316)
-- Name: posgrado_materias fk_posgrado_niveles_postgrado_materias; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_materias
    ADD CONSTRAINT fk_posgrado_niveles_postgrado_materias FOREIGN KEY (id_posgrado_nivel) REFERENCES public.posgrado_niveles(id_posgrado_nivel);


--
-- TOC entry 5440 (class 2606 OID 17402)
-- Name: posgrado_calificaciones fk_posgrado_personas_alumnos_posgrado_calificaciones; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_calificaciones
    ADD CONSTRAINT fk_posgrado_personas_alumnos_posgrado_calificaciones FOREIGN KEY (id_persona_alumno_posgrado) REFERENCES public.personas_alumnos_posgrados(id_persona_alumno_posgrado);


--
-- TOC entry 5438 (class 2606 OID 17356)
-- Name: posgrado_asignaciones_docentes fk_posgrado_tipos_evaluaciones_notas_posg_asig_doc; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_asignaciones_docentes
    ADD CONSTRAINT fk_posgrado_tipos_evaluaciones_notas_posg_asig_doc FOREIGN KEY (id_posgrado_tipo_evaluacion_nota) REFERENCES public.posgrado_tipos_evaluaciones_notas(id_posgrado_tipo_evaluacion_nota);


--
-- TOC entry 5410 (class 2606 OID 17061)
-- Name: cuentas_cargos_posgrados fk_posgrados_programas_cuentas_cargos_posgrados; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_cargos_posgrados
    ADD CONSTRAINT fk_posgrados_programas_cuentas_cargos_posgrados FOREIGN KEY (id_posgrado_programa) REFERENCES public.posgrados_programas(id_posgrado_programa);


--
-- TOC entry 5409 (class 2606 OID 17046)
-- Name: personas_alumnos_posgrados fk_posgrados_programas_personas_alumnos_posgrados; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_alumnos_posgrados
    ADD CONSTRAINT fk_posgrados_programas_personas_alumnos_posgrados FOREIGN KEY (id_posgrado_programa) REFERENCES public.posgrados_programas(id_posgrado_programa);


--
-- TOC entry 5434 (class 2606 OID 17311)
-- Name: posgrado_materias fk_posgrados_programas_postgrado_materias; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrado_materias
    ADD CONSTRAINT fk_posgrados_programas_postgrado_materias FOREIGN KEY (id_posgrado_programa) REFERENCES public.posgrados_programas(id_posgrado_programa);


--
-- TOC entry 5380 (class 2606 OID 16661)
-- Name: localidades fk_provincias_localidades; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT fk_provincias_localidades FOREIGN KEY (id_provincia) REFERENCES public.provincias(id_provincia);


--
-- TOC entry 5404 (class 2606 OID 17002)
-- Name: personas_roles fk_roles_personas_roles; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas_roles
    ADD CONSTRAINT fk_roles_personas_roles FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol);


--
-- TOC entry 5369 (class 2606 OID 16501)
-- Name: roles_menus_principales fk_roles_roles_menus_principales; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_menus_principales
    ADD CONSTRAINT fk_roles_roles_menus_principales FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol);


--
-- TOC entry 5392 (class 2606 OID 16825)
-- Name: tipos_personas fk_roles_tipos_personas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_personas
    ADD CONSTRAINT fk_roles_tipos_personas FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol);


--
-- TOC entry 5390 (class 2606 OID 16802)
-- Name: carreras fk_sedes_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras
    ADD CONSTRAINT fk_sedes_carreras FOREIGN KEY (id_sede) REFERENCES public.sedes(id_sede);


--
-- TOC entry 5385 (class 2606 OID 16714)
-- Name: personas fk_sexos_personas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_sexos_personas FOREIGN KEY (id_sexo) REFERENCES public.sexos(id_sexo);


--
-- TOC entry 5377 (class 2606 OID 16614)
-- Name: ambientes fk_tipos_ambientes_ambientes; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ambientes
    ADD CONSTRAINT fk_tipos_ambientes_ambientes FOREIGN KEY (id_tipo_ambiente) REFERENCES public.tipos_ambientes(id_tipo_ambiente);


--
-- TOC entry 5430 (class 2606 OID 17252)
-- Name: niveles_academicos_tramites_documentos fk_tramites_documentos_niveles_academicos_tramites_documentos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.niveles_academicos_tramites_documentos
    ADD CONSTRAINT fk_tramites_documentos_niveles_academicos_tramites_documentos FOREIGN KEY (id_tramite_documento) REFERENCES public.tramites_documentos(id_tramite_documento);


--
-- TOC entry 5426 (class 2606 OID 17206)
-- Name: posgrados_transacciones_detalles_desglose fk_transaccion_posgrados_contratos_detalles_desglose; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones_detalles_desglose
    ADD CONSTRAINT fk_transaccion_posgrados_contratos_detalles_desglose FOREIGN KEY (id_posgrado_contrato_detalle) REFERENCES public.posgrados_contratos_detalles(id_posgrado_contrato_detalle);


--
-- TOC entry 5427 (class 2606 OID 17211)
-- Name: posgrados_transacciones_detalles_desglose fk_transaccion_posgrados_transaccion_detalles_desglose; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones_detalles_desglose
    ADD CONSTRAINT fk_transaccion_posgrados_transaccion_detalles_desglose FOREIGN KEY (id_posgrado_transaccion_detalle) REFERENCES public.posgrados_transacciones_detalles(id_posgrado_transaccion_detalle);


--
-- TOC entry 5425 (class 2606 OID 17188)
-- Name: posgrados_transacciones_detalles fk_transacciones_posgrados_transacciones_detalles; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posgrados_transacciones_detalles
    ADD CONSTRAINT fk_transacciones_posgrados_transacciones_detalles FOREIGN KEY (id_posgrado_transaccion) REFERENCES public.posgrados_transacciones(id_posgrado_transaccion);


--
-- TOC entry 5364 (class 2606 OID 16429)
-- Name: areas fk_universidades_areas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT fk_universidades_areas FOREIGN KEY (id_universidad) REFERENCES public.universidades(id_universidad);


--
-- TOC entry 5363 (class 2606 OID 16416)
-- Name: configuraciones fk_universidades_configuraciones; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuraciones
    ADD CONSTRAINT fk_universidades_configuraciones FOREIGN KEY (id_universidad) REFERENCES public.universidades(id_universidad);


-- Completed on 2025-03-12 08:06:02

--
-- PostgreSQL database dump complete
--

