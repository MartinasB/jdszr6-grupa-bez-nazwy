select * from county_facts

select * from county_facts_dictionary
where column_name like 'AGE%'

/* tworzenie tabeli pomocniczej zawieraj�cej wszystkie dane potrzebne do analizy*/
create temp table dane_wiekowe as 
select state,county,  party, candidate, votes,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
AGE135214 as osoby_poni�ej_5_hr,
round(avg(AGE135214) over (partition by state), 2) as osoby_poni�ej_5_stan,
AGE295214 as osoby_poni�ej_18_hr, 
round(avg(AGE295214) over (partition by state), 2) as osoby_poni�ej_18_stan,
AGE775214 as osoby_min_65_hr,
round(avg(AGE775214 ) over (partition by state), 2) as osoby_min_65_stan,
100 - (AGE295214 + AGE775214) as osoby_18_do_65_hr,
round(avg(100 - (AGE295214 + AGE775214)) over (partition by state), 2) as osoby_18_do_65_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips



/*Zestawienie sumaryczne - kandydat ze wzgl�du na wygrane stany*/

with pon_5 as 
(select distinct candidate, round(avg(osoby_poni�ej_5_stan),  2) as prct_pon_5, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_poni�ej_5_stan
from
(select distinct state, candidate, prct_g�_stan_all,  osoby_poni�ej_5_stan
from dane_wiekowe
)dem
group by candidate, state, osoby_poni�ej_5_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
pon_18 as 
(select distinct candidate, round(avg(osoby_poni�ej_18_stan), 2) as prct_pon_18, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_poni�ej_18_stan
from
(select distinct state, candidate, prct_g�_stan_all,  osoby_poni�ej_18_stan
from dane_wiekowe
)dem
group by candidate, state, osoby_poni�ej_18_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
pom_18_65 as 
( select distinct candidate, round(avg(osoby_18_do_65_stan), 2) as prct_18_do_65, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_18_do_65_stan
from
(select distinct state, candidate, prct_g�_stan_all,  osoby_18_do_65_stan
from dane_wiekowe
)dem
group by candidate, state, osoby_18_do_65_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
min_65 as 
( select distinct candidate, round(avg(osoby_min_65_stan), 2) as prct_min_65, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_min_65_stan
from
(select distinct state, candidate, prct_g�_stan_all,  osoby_min_65_stan
from dane_wiekowe
)dem
group by candidate, state, osoby_min_65_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate)
select pon_5.candidate, prct_pon_5, prct_pon_18, prct_18_do_65, prct_min_65, pon_5.liczba_wygranych
from pon_5
join pon_18
on pon_5.candidate = pon_18.candidate
join pom_18_65
on pon_5.candidate = pom_18_65.candidate
join min_65
on pon_5.candidate = min_65.candidate


/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/

with pon_5 as 
(select distinct party, round(avg(osoby_poni�ej_5_stan),  2) as prct_pon_5, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_poni�ej_5_stan
from
(select distinct state, party, prct_g�_stan_all,  osoby_poni�ej_5_stan
from dane_wiekowe
)dem
group by party, state, osoby_poni�ej_5_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
pon_18 as 
(select distinct party, round(avg(osoby_poni�ej_18_stan), 2) as prct_pon_18, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_poni�ej_18_stan
from
(select distinct state, party, prct_g�_stan_all,  osoby_poni�ej_18_stan
from dane_wiekowe
)dem
group by party, state, osoby_poni�ej_18_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
pom_18_65 as 
( select distinct party, round(avg(osoby_18_do_65_stan), 2) as prct_18_do_65, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_18_do_65_stan
from
(select distinct state, party, prct_g�_stan_all,  osoby_18_do_65_stan
from dane_wiekowe
)dem
group by party, state, osoby_18_do_65_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
min_65 as 
( select distinct party, round(avg(osoby_min_65_stan), 2) as prct_min_65, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_min_65_stan
from
(select distinct state, party, prct_g�_stan_all,  osoby_min_65_stan
from dane_wiekowe
)dem
group by party, state, osoby_min_65_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party)
select pon_5.party, prct_pon_5, prct_pon_18, prct_18_do_65, prct_min_65, pon_5.liczba_wygranych
from pon_5
join pon_18
on pon_5.party = pon_18.party
join pom_18_65
on pon_5.party = pom_18_65.party
join min_65
on pon_5.party = min_65.party

--- analiza stan�w : w kt�rych stanach wygra�  T.Cruz (najm�odsze spo�ecze�stwo) ---

select distinct state, candidate 
from  
(select candidate, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_poni�ej_5_stan
from
(select distinct state, candidate, prct_g�_stan_all,  osoby_poni�ej_5_stan
from dane_wiekowe
)dem
group by candidate, state, osoby_poni�ej_5_stan
order by state) miejs
where miejsce = 1 and candidate ='Ted Cruz'/*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate, state;

------ og�lne ----

/*sprawdzanie zale�no�ci:
 a) zale�no�� - g� na kandydata - poni�ej 5 lat (u�rednione wyniki ca�o�ciowe)*/
 

select distinct candidate, sum(votes) over (partition by candidate) as liczba_g�_kandydat, 
round(avg(osoby_poni�ej_5_hr) over (partition by candidate), 2) as �r_prct_pon_5,
round(avg(osoby_poni�ej_18_hr) over (partition by candidate), 2) as �r_prct_pon_18,
round(avg(osoby_18_do_65_hr) over (partition by candidate), 2) as �r_prct_pom_18_65,
round(avg(osoby_min_65_hr) over (partition by candidate), 2) as �r_prct_min_65
from dane_wiekowe
group by candidate, votes, osoby_poni�ej_5_hr, osoby_poni�ej_18_hr, osoby_18_do_65_hr, osoby_min_65_hr
order by sum(votes) over (partition by candidate) desc


 /*a) zale�no�� - g� na kandydata - poni�ej 5 lat (u�rednione wyniki ca�o�ciowe)*/
 

select distinct candidate, sum(votes) over (partition by candidate) as liczba_g�_kandydat, 
round(avg(osoby_poni�ej_5_hr) over (partition by candidate), 2) as �r_prct_pon_5,
round(avg(osoby_poni�ej_18_hr) over (partition by candidate), 2) as �r_prct_pon_18,
round(avg(osoby_18_do_65_hr) over (partition by candidate), 2) as �r_prct_pom_18_65,
round(avg(osoby_min_65_hr) over (partition by candidate), 2) as �r_prct_min_65
from dane_wiekowe
group by candidate, votes, osoby_poni�ej_5_hr, osoby_poni�ej_18_hr, osoby_18_do_65_hr, osoby_min_65_hr
order by sum(votes) over (partition by candidate) desc

 /*a) zale�no�� - g� na parti� - poni�ej 5 lat (u�rednione wyniki ca�o�ciowe)*/
 

select distinct party, sum(votes) over (partition by party) as liczba_g�_kandydat, 
round(avg(osoby_poni�ej_5_hr) over (partition by party), 2) as �r_prct_pon_5,
round(avg(osoby_poni�ej_18_hr) over (partition by party), 2) as �r_prct_pon_18,
round(avg(osoby_18_do_65_hr) over (partition by party), 2) as �r_prct_pom_18_65,
round(avg(osoby_min_65_hr) over (partition by party), 2) as �r_prct_min_65
from dane_wiekowe
group by party, votes, osoby_poni�ej_5_hr, osoby_poni�ej_18_hr, osoby_18_do_65_hr, osoby_min_65_hr
order by sum(votes) over (partition by party) desc



-- analiza wzgl�dem wygranych hrabstw --

/*a) wyb�r kandydata*/
with pon_5 as 
(select distinct candidate, round(avg(osoby_poni�ej_5_hr),  2) as prct_pon_5, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, osoby_poni�ej_5_hr
from
(select distinct county, candidate, prct_g�_hrabstwo_all,  osoby_poni�ej_5_hr
from dane_wiekowe
)dem
group by candidate, county, osoby_poni�ej_5_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
pon_18 as 
(select distinct candidate, round(avg(osoby_poni�ej_18_hr),  2) as prct_pon_18, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, osoby_poni�ej_18_hr
from
(select distinct county, candidate, prct_g�_hrabstwo_all,  osoby_poni�ej_18_hr
from dane_wiekowe
)dem
group by candidate, county, osoby_poni�ej_18_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
pom_18_65 as 
(select distinct candidate, round(avg(osoby_18_do_65_hr),  2) as prct_od_18_do_65, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, osoby_18_do_65_hr
from
(select distinct county, candidate, prct_g�_hrabstwo_all,  osoby_18_do_65_hr
from dane_wiekowe
)dem
group by candidate, county, osoby_18_do_65_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
min_65 as 
(select distinct candidate, round(avg(osoby_min_65_hr),  2) as prct_min_65, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, osoby_min_65_hr
from
(select distinct county, candidate, prct_g�_hrabstwo_all,  osoby_min_65_hr
from dane_wiekowe
)dem
group by candidate, county, osoby_min_65_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate)
select pon_5.candidate, prct_pon_5, prct_pon_18, prct_od_18_do_65, prct_min_65, pon_5.liczba_wygranych
from pon_5
join pon_18
on pon_5.candidate = pon_18.candidate
join pom_18_65
on pon_5.candidate = pom_18_65.candidate
join min_65
on pon_5.candidate = min_65.candidate


/*b) wyb�r partii*/
with pon_5 as 
(select distinct party, round(avg(osoby_poni�ej_5_hr),  2) as prct_pon_5, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, osoby_poni�ej_5_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  osoby_poni�ej_5_hr
from dane_wiekowe
)dem
group by party, county, osoby_poni�ej_5_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
pon_18 as 
(select distinct party, round(avg(osoby_poni�ej_18_hr),  2) as prct_pon_18, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, osoby_poni�ej_18_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  osoby_poni�ej_18_hr
from dane_wiekowe
)dem
group by party, county, osoby_poni�ej_18_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
pom_18_65 as 
(select distinct party, round(avg(osoby_18_do_65_hr),  2) as prct_od_18_do_65, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, osoby_18_do_65_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  osoby_18_do_65_hr
from dane_wiekowe
)dem
group by party, county, osoby_18_do_65_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
min_65 as 
(select distinct party, round(avg(osoby_min_65_hr),  2) as prct_min_65, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, osoby_min_65_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  osoby_min_65_hr
from dane_wiekowe
)dem
group by party, county, osoby_min_65_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party)
select pon_5.party, prct_pon_5, prct_pon_18, prct_od_18_do_65, prct_min_65, pon_5.liczba_wygranych
from pon_5
join pon_18
on pon_5.party = pon_18.party
join pom_18_65
on pon_5.party = pom_18_65.party
join min_65
on pon_5.party = min_65.party

-- badanie korelacji pomi�dzy g�osami danej grupy wiekowej, a kandydatem 

select candidate, 
corr(votes, osoby_poni�ej_5_hr) as korelacja_pon_5,
corr(votes, osoby_poni�ej_18_hr) as korelacja_pon_18,
corr(votes, osoby_18_do_65_hr) as korelacja_18_do_65,
corr(votes, osoby_min_65_hr) as korelacja_min_65
from dane_wiekowe
group by candidate

-- badanie korelacji pomi�dzy g�osami danej grupy wiekowej, a kandydatem  - podzia� na stany
select candidate, state,
corr(votes, osoby_poni�ej_5_hr) as korelacja_pon_5,
corr(votes, osoby_poni�ej_18_hr) as korelacja_pon_18,
corr(votes, osoby_18_do_65_hr) as korelacja_18_do_65,
corr(votes, osoby_min_65_hr) as korelacja_min_65
from dane_wiekowe
group by candidate, state



-- badanie korelacji pomi�dzy g�osami danej grupy wiekowej, a parti�

select party, 
corr(votes, osoby_poni�ej_5_hr) as korelacja_pon_5,
corr(votes, osoby_poni�ej_18_hr) as korelacja_pon_18,
corr(votes, osoby_18_do_65_hr) as korelacja_18_do_65,
corr(votes, osoby_min_65_hr) as korelacja_min_65
from dane_wiekowe
group by party

-- badanie korelacji pomi�dzy g�osami danej grupy wiekowej, a parti�  - podzia� na stany
select party, state,
corr(votes, osoby_poni�ej_5_hr) as korelacja_pon_5,
corr(votes, osoby_poni�ej_18_hr) as korelacja_pon_18,
corr(votes, osoby_18_do_65_hr) as korelacja_18_do_65,
corr(votes, osoby_min_65_hr) as korelacja_min_65
from dane_wiekowe
group by party, state

