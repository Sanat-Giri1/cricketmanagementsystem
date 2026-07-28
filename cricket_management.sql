--
-- PostgreSQL database dump
--

\restrict MdCfpsTZNuPU8dkiG6FgxZ7uSy4UJmeNWmcavz1xvBVshJFtYiBibrgQpKrLOSU

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-07-25 10:07:47

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 226 (class 1259 OID 25111)
-- Name: batting_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.batting_stats (
    batting_id integer NOT NULL,
    match_id integer,
    player_id integer,
    runs integer DEFAULT 0,
    balls integer DEFAULT 0,
    fours integer DEFAULT 0,
    sixes integer DEFAULT 0,
    strike_rate numeric(5,2)
);


ALTER TABLE public.batting_stats OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 25110)
-- Name: batting_stats_batting_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.batting_stats_batting_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.batting_stats_batting_id_seq OWNER TO postgres;

--
-- TOC entry 5082 (class 0 OID 0)
-- Dependencies: 225
-- Name: batting_stats_batting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.batting_stats_batting_id_seq OWNED BY public.batting_stats.batting_id;


--
-- TOC entry 228 (class 1259 OID 25133)
-- Name: bowling_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bowling_stats (
    bowling_id integer NOT NULL,
    match_id integer,
    player_id integer,
    overs numeric(3,1) DEFAULT 0,
    runs_conceded integer DEFAULT 0,
    wickets integer DEFAULT 0,
    economy numeric(4,2)
);


ALTER TABLE public.bowling_stats OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 25132)
-- Name: bowling_stats_bowling_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bowling_stats_bowling_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bowling_stats_bowling_id_seq OWNER TO postgres;

--
-- TOC entry 5083 (class 0 OID 0)
-- Dependencies: 227
-- Name: bowling_stats_bowling_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bowling_stats_bowling_id_seq OWNED BY public.bowling_stats.bowling_id;


--
-- TOC entry 230 (class 1259 OID 25154)
-- Name: match_score; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.match_score (
    score_id integer NOT NULL,
    match_id integer,
    team_id integer,
    runs integer DEFAULT 0,
    wickets integer DEFAULT 0,
    overs numeric(3,1) DEFAULT 0
);


ALTER TABLE public.match_score OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 25153)
-- Name: match_score_score_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.match_score_score_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.match_score_score_id_seq OWNER TO postgres;

--
-- TOC entry 5084 (class 0 OID 0)
-- Dependencies: 229
-- Name: match_score_score_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.match_score_score_id_seq OWNED BY public.match_score.score_id;


--
-- TOC entry 224 (class 1259 OID 25093)
-- Name: matches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.matches (
    match_id integer NOT NULL,
    match_date date,
    team1_id integer,
    team2_id integer,
    venue character varying(100),
    winner character varying(50)
);


ALTER TABLE public.matches OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 25092)
-- Name: matches_match_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.matches_match_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.matches_match_id_seq OWNER TO postgres;

--
-- TOC entry 5085 (class 0 OID 0)
-- Dependencies: 223
-- Name: matches_match_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.matches_match_id_seq OWNED BY public.matches.match_id;


--
-- TOC entry 222 (class 1259 OID 25079)
-- Name: player; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.player (
    player_id integer NOT NULL,
    player_name character varying(50) NOT NULL,
    age integer,
    jersey_no integer,
    role character varying(20),
    team_id integer
);


ALTER TABLE public.player OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 25078)
-- Name: player_player_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.player_player_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.player_player_id_seq OWNER TO postgres;

--
-- TOC entry 5086 (class 0 OID 0)
-- Dependencies: 221
-- Name: player_player_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.player_player_id_seq OWNED BY public.player.player_id;


--
-- TOC entry 220 (class 1259 OID 25070)
-- Name: team; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.team (
    team_id integer NOT NULL,
    team_name character varying(50) NOT NULL,
    captain character varying(50),
    coach character varying(50)
);


ALTER TABLE public.team OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 25069)
-- Name: team_team_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.team_team_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.team_team_id_seq OWNER TO postgres;

--
-- TOC entry 5087 (class 0 OID 0)
-- Dependencies: 219
-- Name: team_team_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.team_team_id_seq OWNED BY public.team.team_id;


--
-- TOC entry 4884 (class 2604 OID 25114)
-- Name: batting_stats batting_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batting_stats ALTER COLUMN batting_id SET DEFAULT nextval('public.batting_stats_batting_id_seq'::regclass);


--
-- TOC entry 4889 (class 2604 OID 25136)
-- Name: bowling_stats bowling_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bowling_stats ALTER COLUMN bowling_id SET DEFAULT nextval('public.bowling_stats_bowling_id_seq'::regclass);


--
-- TOC entry 4893 (class 2604 OID 25157)
-- Name: match_score score_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_score ALTER COLUMN score_id SET DEFAULT nextval('public.match_score_score_id_seq'::regclass);


--
-- TOC entry 4883 (class 2604 OID 25096)
-- Name: matches match_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches ALTER COLUMN match_id SET DEFAULT nextval('public.matches_match_id_seq'::regclass);


--
-- TOC entry 4882 (class 2604 OID 25082)
-- Name: player player_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player ALTER COLUMN player_id SET DEFAULT nextval('public.player_player_id_seq'::regclass);


--
-- TOC entry 4881 (class 2604 OID 25073)
-- Name: team team_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team ALTER COLUMN team_id SET DEFAULT nextval('public.team_team_id_seq'::regclass);


--
-- TOC entry 5072 (class 0 OID 25111)
-- Dependencies: 226
-- Data for Name: batting_stats; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.batting_stats (batting_id, match_id, player_id, runs, balls, fours, sixes, strike_rate) FROM stdin;
1	1	1	82	60	8	2	136.67
2	1	3	45	50	4	1	90.00
\.


--
-- TOC entry 5074 (class 0 OID 25133)
-- Dependencies: 228
-- Data for Name: bowling_stats; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.bowling_stats (bowling_id, match_id, player_id, overs, runs_conceded, wickets, economy) FROM stdin;
1	1	2	10.0	45	3	4.50
\.


--
-- TOC entry 5076 (class 0 OID 25154)
-- Dependencies: 230
-- Data for Name: match_score; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.match_score (score_id, match_id, team_id, runs, wickets, overs) FROM stdin;
1	1	1	245	6	50.0
2	1	2	210	10	48.3
\.


--
-- TOC entry 5070 (class 0 OID 25093)
-- Dependencies: 224
-- Data for Name: matches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.matches (match_id, match_date, team1_id, team2_id, venue, winner) FROM stdin;
1	2026-07-20	1	2	Melbourne Cricket Ground	India
\.


--
-- TOC entry 5068 (class 0 OID 25079)
-- Dependencies: 222
-- Data for Name: player; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.player (player_id, player_name, age, jersey_no, role, team_id) FROM stdin;
1	Virat Kohli	36	18	Batsman	1
2	Jasprit Bumrah	31	93	Bowler	1
3	Steve Smith	36	49	Batsman	2
4	Mitchell Starc	35	56	Bowler	2
\.


--
-- TOC entry 5066 (class 0 OID 25070)
-- Dependencies: 220
-- Data for Name: team; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.team (team_id, team_name, captain, coach) FROM stdin;
1	India	Rohit Sharma	Gautam Gambhir
2	Australia	Pat Cummins	Andrew McDonald
\.


--
-- TOC entry 5088 (class 0 OID 0)
-- Dependencies: 225
-- Name: batting_stats_batting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.batting_stats_batting_id_seq', 2, true);


--
-- TOC entry 5089 (class 0 OID 0)
-- Dependencies: 227
-- Name: bowling_stats_bowling_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bowling_stats_bowling_id_seq', 1, true);


--
-- TOC entry 5090 (class 0 OID 0)
-- Dependencies: 229
-- Name: match_score_score_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.match_score_score_id_seq', 2, true);


--
-- TOC entry 5091 (class 0 OID 0)
-- Dependencies: 223
-- Name: matches_match_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.matches_match_id_seq', 1, true);


--
-- TOC entry 5092 (class 0 OID 0)
-- Dependencies: 221
-- Name: player_player_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.player_player_id_seq', 5, true);


--
-- TOC entry 5093 (class 0 OID 0)
-- Dependencies: 219
-- Name: team_team_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.team_team_id_seq', 2, true);


--
-- TOC entry 4904 (class 2606 OID 25121)
-- Name: batting_stats batting_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batting_stats
    ADD CONSTRAINT batting_stats_pkey PRIMARY KEY (batting_id);


--
-- TOC entry 4906 (class 2606 OID 25142)
-- Name: bowling_stats bowling_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bowling_stats
    ADD CONSTRAINT bowling_stats_pkey PRIMARY KEY (bowling_id);


--
-- TOC entry 4908 (class 2606 OID 25163)
-- Name: match_score match_score_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_score
    ADD CONSTRAINT match_score_pkey PRIMARY KEY (score_id);


--
-- TOC entry 4902 (class 2606 OID 25099)
-- Name: matches matches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_pkey PRIMARY KEY (match_id);


--
-- TOC entry 4900 (class 2606 OID 25086)
-- Name: player player_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_pkey PRIMARY KEY (player_id);


--
-- TOC entry 4898 (class 2606 OID 25077)
-- Name: team team_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_pkey PRIMARY KEY (team_id);


--
-- TOC entry 4912 (class 2606 OID 25122)
-- Name: batting_stats batting_stats_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batting_stats
    ADD CONSTRAINT batting_stats_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(match_id);


--
-- TOC entry 4913 (class 2606 OID 25127)
-- Name: batting_stats batting_stats_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batting_stats
    ADD CONSTRAINT batting_stats_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.player(player_id);


--
-- TOC entry 4914 (class 2606 OID 25143)
-- Name: bowling_stats bowling_stats_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bowling_stats
    ADD CONSTRAINT bowling_stats_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(match_id);


--
-- TOC entry 4915 (class 2606 OID 25148)
-- Name: bowling_stats bowling_stats_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bowling_stats
    ADD CONSTRAINT bowling_stats_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.player(player_id);


--
-- TOC entry 4916 (class 2606 OID 25164)
-- Name: match_score match_score_match_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_score
    ADD CONSTRAINT match_score_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.matches(match_id);


--
-- TOC entry 4917 (class 2606 OID 25169)
-- Name: match_score match_score_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.match_score
    ADD CONSTRAINT match_score_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.team(team_id);


--
-- TOC entry 4910 (class 2606 OID 25100)
-- Name: matches matches_team1_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_team1_id_fkey FOREIGN KEY (team1_id) REFERENCES public.team(team_id);


--
-- TOC entry 4911 (class 2606 OID 25105)
-- Name: matches matches_team2_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.matches
    ADD CONSTRAINT matches_team2_id_fkey FOREIGN KEY (team2_id) REFERENCES public.team(team_id);


--
-- TOC entry 4909 (class 2606 OID 25087)
-- Name: player player_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.team(team_id);


-- Completed on 2026-07-25 10:07:47

--
-- PostgreSQL database dump complete
--

\unrestrict MdCfpsTZNuPU8dkiG6FgxZ7uSy4UJmeNWmcavz1xvBVshJFtYiBibrgQpKrLOSU

