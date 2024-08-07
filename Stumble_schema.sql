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
-- Name: swipe; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.swipe AS ENUM (
    'Connect',
    'Ignore',
    'Already know'
);


ALTER TYPE public.swipe OWNER TO postgres;

--
-- Name: findoverlappingusers(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.findoverlappingusers(target_user_id integer) RETURNS TABLE(room integer, overlappinguserid integer, overlappingstarttime time without time zone, overlappingendtime time without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH UserRooms AS (
        SELECT DISTINCT Location
        FROM master
        WHERE userid = target_user_id
    )
    SELECT 
        ur.Location AS Room,
        e2.userid AS OverlappingUserID,
        e2.starttime AS OverlappingStartTime,
        e2.endtime AS OverlappingEndTime
    FROM master e1
    JOIN master e2
    ON e1.location = e2.location
    AND e1.starttime < e2.endtime
    AND e1.endtime > e2.starttime
    JOIN UserRooms ur ON e1.Location = ur.Location
     LEFT JOIN user_interaction ui 
        ON (ui.userid1 = e1.userid AND ui.userid2 = e2.userid)
        OR (ui.userid1 = e2.userid AND ui.userid2 = e1.userid)
    WHERE e1.userid = target_user_id
        AND e2.userid <> target_user_id
        AND ui.interaction_id IS NULL
    ORDER BY ur.Location, e1.UserID, e2.UserID, e1.StartTime;
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
    starttime time without time zone,
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
-- Name: master master_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.master
    ADD CONSTRAINT master_pkey PRIMARY KEY (userid, location);


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

-- krishna's change

-- this is a test change.
--More test changes.
--Another change
-- Srivathsav
