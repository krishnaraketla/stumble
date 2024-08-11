--
-- PostgreSQL database dump
--

-- Dumped from database version 11.22
-- Dumped by pg_dump version 11.22

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
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION dblink IS 'connect to other PostgreSQL databases from within a database';


--
-- Name: swipe; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.swipe AS ENUM (
    'Connect',
    'Ignore',
    'Already know'
);


ALTER TYPE public.swipe OWNER TO postgres;

--
-- Name: create_user_table(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_user_table() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_table_name TEXT;
BEGIN
    -- Define the name of the new table
    new_table_name := 'user_' || NEW.userid;
    
    -- Create the new table in the other database without a primary key
    PERFORM dblink_exec('host=localhost port=5433 dbname=User_history user=postgres password=@Inferno112', 'CREATE TABLE ' || quote_ident(new_table_name) || ' (
        location INT ,
        intersection_start_time time,
		intersection_end_time time,				
        user_swiped int,
		interaction swipe,
		PRIMARY KEY(user_swiped,location)
    )');
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.create_user_table() OWNER TO postgres;

--
-- Name: findoverlappingusers(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.findoverlappingusers(target_user_id integer) RETURNS TABLE(room integer, overlappingusername character varying, overlappingstarttime time without time zone, overlappingendtime time without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e1.location AS room,
        ui2.username as overlappingusername,
        e2.starttime AS overlappingstarttime,
        e2.endtime AS overlappingendtime
    FROM master e1
    JOIN master e2
        ON e1.location = e2.location
        AND e1.starttime < e2.endtime
        AND e1.endtime > e2.starttime
    LEFT JOIN user_interaction ui 
        ON (ui.userid1 = e1.userid AND ui.userid2 = e2.userid)
        OR (ui.userid1 = e2.userid AND ui.userid2 = e1.userid)
	Join user_info ui2
	on e2.userid=ui2.userid
    WHERE e1.userid = target_user_id
        AND e2.userid <> target_user_id
        AND ui.interaction_id IS NULL  -- Ensures we only return users with no interaction
    ORDER BY e1.location, e2.starttime;
END;
$$;


ALTER FUNCTION public.findoverlappingusers(target_user_id integer) OWNER TO postgres;

--
-- Name: get_connections(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_connections(user_id integer) RETURNS TABLE(user2 integer, username character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT ui1.userid2,ui3.username
    FROM user_interaction ui1
    JOIN user_interaction ui2
    ON ui1.userid1 = ui2.userid2
    AND ui1.userid2 = ui2.userid1
    AND ui1.interaction = ui2.interaction
    AND ui1.interaction = 'Connect'
    JOIN user_info ui3
        ON ui1.userid2 = ui3.userid
    WHERE ui1.userid1 = user_id;
END;
$$;


ALTER FUNCTION public.get_connections(user_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: master; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.master (
    userid integer NOT NULL,
    location integer NOT NULL,
    starttime time without time zone NOT NULL,
    endtime time without time zone
);


ALTER TABLE public.master OWNER TO postgres;

--
-- Name: user_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_info (
    userid integer NOT NULL,
    username character varying(30),
    profile_picture bytea
);


ALTER TABLE public.user_info OWNER TO postgres;

--
-- Name: user_interaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_interaction (
    userid1 integer,
    userid2 integer,
    interaction_id integer NOT NULL,
    interaction public.swipe
);


ALTER TABLE public.user_interaction OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    userid integer NOT NULL,
    username character varying(30),
    password character varying(30),
    email character varying(30)
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: master example_table_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master
    ADD CONSTRAINT example_table_pkey PRIMARY KEY (userid, starttime);


--
-- Name: user_info user_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_info
    ADD CONSTRAINT user_info_pkey PRIMARY KEY (userid);


--
-- Name: user_interaction user_interaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_interaction
    ADD CONSTRAINT user_interaction_pkey PRIMARY KEY (interaction_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (userid);


--
-- Name: users after_user_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER after_user_insert AFTER INSERT ON public.users FOR EACH ROW EXECUTE PROCEDURE public.create_user_table();


--
-- Name: master fk_user_info; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master
    ADD CONSTRAINT fk_user_info FOREIGN KEY (userid) REFERENCES public.user_info(userid);


--
-- Name: user_interaction user_interaction_userid1_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_interaction
    ADD CONSTRAINT user_interaction_userid1_fkey FOREIGN KEY (userid1) REFERENCES public.user_info(userid);


--
-- Name: user_interaction user_interaction_userid2_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_interaction
    ADD CONSTRAINT user_interaction_userid2_fkey FOREIGN KEY (userid2) REFERENCES public.user_info(userid);


--
-- PostgreSQL database dump complete
--

