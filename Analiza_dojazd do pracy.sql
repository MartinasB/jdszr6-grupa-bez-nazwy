select * from county_facts

select * from county_facts_dictionary
where column_name  = 'LFE305213'


create temp table dane_dojazd as 
select state,county,  party, candidate, votes, fraction_votes ,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
LFE305213 as �redni_czas_dojazdu_min_praca_hr,
round(avg(LFE305213) over (partition by state), 2) as �redni_czas_dojazdu_min_praca_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips

/*Zestawienie sumaryczne - kandydat ze wzgl�du na wygrane stany*/

select distinct candidate, round(avg(�redni_czas_dojazdu_min_praca_stan),  2) as czas_dojazdu_min, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, �redni_czas_dojazdu_min_praca_stan
from
(select distinct state, candidate, prct_g�_stan_all,  �redni_czas_dojazdu_min_praca_stan
from dane_dojazd
)dem
group by candidate, state, �redni_czas_dojazdu_min_praca_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate

/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/

select distinct party, round(avg(�redni_czas_dojazdu_min_praca_stan),  2) as czas_dojazdu_min, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, �redni_czas_dojazdu_min_praca_stan
from
(select distinct state, party, prct_g�_stan_all,  �redni_czas_dojazdu_min_praca_stan
from dane_dojazd
)dem
group by party, state, �redni_czas_dojazdu_min_praca_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party

/*sprawdzanie zale�no�ci:
 a) zale�no�� - g� na kandydata - (u�rednione wyniki ca�o�ciowe)*/
 
select distinct candidate, sum(votes) over (partition by candidate) as liczba_g�_kandydat, 
round(avg(�redni_czas_dojazdu_min_praca_hr) over (partition by candidate), 2) as �r_czas_dojazdu_min
from dane_dojazd
group by candidate, votes, �redni_czas_dojazdu_min_praca_hr
order by sum(votes) over (partition by candidate) desc


 /*b) zale�no�� - g� na parti� - (u�rednione wyniki ca�o�ciowe)*/
 

select distinct party, sum(votes) over (partition by party) as liczba_g�_kandydat, 
round(avg(�redni_czas_dojazdu_min_praca_hr) over (partition by party), 2) as �r_czas_dojazdu_min
from dane_dojazd
group by party, votes, �redni_czas_dojazdu_min_praca_hr
order by sum(votes) over (partition by party) desc

-- analiza wzgl�dem wygranych hrabstw --

/*a) wyb�r kandydata*/

select distinct candidate, round(avg(�redni_czas_dojazdu_min_praca_hr),  2) as �r_czas_dojazdu_min, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, �redni_czas_dojazdu_min_praca_hr
from
(select distinct county, candidate, prct_g�_hrabstwo_all, �redni_czas_dojazdu_min_praca_hr
from dane_dojazd
)dem
group by candidate, county, �redni_czas_dojazdu_min_praca_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate

/*b) wyb�r partii*/

select distinct party, round(avg(�redni_czas_dojazdu_min_praca_hr),  2) as �r_czas_dojazdu_min, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, �redni_czas_dojazdu_min_praca_hr
from
(select distinct county, party, prct_g�_hrabstwo_all, �redni_czas_dojazdu_min_praca_hr
from dane_dojazd
)dem
group by party, county, �redni_czas_dojazdu_min_praca_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party

-- badanie korelacji pomi�dzy dojazd do pracy, a kandydatem 

select candidate, 
corr(votes, �redni_czas_dojazdu_min_praca_hr) as korelacja_weterani
from dane_dojazd
group by candidate
order by corr(votes, �redni_czas_dojazdu_min_praca_hr) desc

-- badanie korelacji pomi�dzy g�osami dojazd do pracy  - podzia� na stany
select candidate, state,
corr(votes, �redni_czas_dojazdu_min_praca_hr) as korelacja_weterani
from dane_dojazd
group by candidate, state
order by corr(votes, �redni_czas_dojazdu_min_praca_hr) desc


-- badanie korelacji pomi�dzy g�osami dojazd do pracy a parti�

select party, 
corr(votes, �redni_czas_dojazdu_min_praca_hr) as korelacja_weterani
from dane_dojazd
group by party
order by corr(votes, �redni_czas_dojazdu_min_praca_hr) desc

-- badanie korelacji pomi�dzy g�osami dojazd do pracy - podzia� na stany
select party, state,
corr(votes, �redni_czas_dojazdu_min_praca_hr) as korelacja_weterani
from dane_dojazd
group by party, state
order by corr(votes, �redni_czas_dojazdu_min_praca_hr) desc






