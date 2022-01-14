select * from county_facts

select * from county_facts_dictionary
where column_name  = 'VET605213'


create temp table dane_weterani as 
select state,county,  party, candidate, votes, fraction_votes ,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
VET605213 as weterani_hr,
round(avg(VET605213) over (partition by state), 2) as weterani_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips


/*Zestawienie sumaryczne - kandydat ze wzgl�du na wygrane stany*/

with liczba as
(select distinct candidate, round(avg(weterani_stan),  2) as liczba_weteran�w, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, weterani_stan
from
(select distinct state, candidate, prct_g�_stan_all,  weterani_stan
from dane_weterani
)dem
group by candidate, state, weterani_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
ca�o�� as 
(select sum(liczba_weteran�w) as suma
from
liczba)
select candidate, round(liczba_weteran�w*100/suma, 2) as prct_weteran�w, liczba_wygranych
from liczba
cross join ca�o��

/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/

with liczba as
(select distinct party, round(avg(weterani_stan),  2) as liczba_weteran�w, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, weterani_stan
from
(select distinct state, party, prct_g�_stan_all,  weterani_stan
from dane_weterani
)dem
group by party, state, weterani_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
ca�o�� as 
(select sum(liczba_weteran�w) as suma
from
liczba)
select party, round(liczba_weteran�w*100/suma, 2) as prct_weteran�w, liczba_wygranych
from liczba
cross join ca�o��

/*sprawdzanie zale�no�ci:
 a) zale�no�� - g� na kandydata - (u�rednione wyniki ca�o�ciowe)*/
 
with liczba as
(select distinct candidate, sum(votes) over (partition by candidate) as liczba_g�_kandydat, 
round(avg(weterani_hr) over (partition by candidate), 2) as �r_liczba_weteran�w
from dane_weterani
group by candidate, votes, weterani_hr
order by sum(votes) over (partition by candidate) desc),
ca�o�� as 
(select sum(�r_liczba_weteran�w) as suma from
liczba)
select candidate, round(�r_liczba_weteran�w*100/suma, 2) as prct_weteran�w
from liczba 
cross join ca�o��


 /*b) zale�no�� - g� na parti� - (u�rednione wyniki ca�o�ciowe)*/
 

with liczba as
(select distinct party, sum(votes) over (partition by party) as liczba_g�_kandydat, 
round(avg(weterani_hr) over (partition by party, 2)) as �r_liczba_weteran�w
from dane_weterani
group by party, votes, weterani_hr
order by sum(votes) over (partition by party) desc),
ca�o�� as 
(select sum(�r_liczba_weteran�w) as suma from
liczba)
select party, round(�r_liczba_weteran�w*100/suma, 2) as prct_weteran�w
from liczba 
cross join ca�o��

-- analiza wzgl�dem wygranych hrabstw --

/*a) wyb�r kandydata*/

with liczba as
(select distinct candidate, round(avg(weterani_hr),  2) as liczba_weteran�w, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, weterani_hr
from
(select distinct county, candidate, prct_g�_hrabstwo_all,  weterani_hr
from dane_weterani
)dem
group by candidate, county, weterani_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
ca�o�� as 
(select sum(liczba_weteran�w) as suma
from
liczba)
select candidate, round(liczba_weteran�w*100/suma, 2) as prct_weteran�w, liczba_wygranych
from liczba
cross join ca�o��

/*b) wyb�r partii*/

with liczba as
(select distinct party, round(avg(weterani_hr),  2) as liczba_weteran�w, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, weterani_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  weterani_hr
from dane_weterani
)dem
group by party, county, weterani_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
ca�o�� as 
(select sum(liczba_weteran�w) as suma
from
liczba)
select party, round(liczba_weteran�w*100/suma, 2) as prct_weteran�w, liczba_wygranych
from liczba
cross join ca�o��

-- badanie korelacji pomi�dzy g�osami weteran�w, a kandydatem 

select candidate, 
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by candidate
order by corr(votes, weterani_hr) desc

-- badanie korelacji pomi�dzy g�osami weteran�w a kandydatem  - podzia� na stany
select candidate, state,
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by candidate, state
order by corr(votes, weterani_hr) desc


-- badanie korelacji pomi�dzy g�osami weteran�w, a parti�

select party, 
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by party
order by corr(votes, weterani_hr) desc

-- badanie korelacji pomi�dzy g�osami weteran�w - podzia� na stany
select party, state,
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by party, state
order by corr(votes, weterani_hr) desc



