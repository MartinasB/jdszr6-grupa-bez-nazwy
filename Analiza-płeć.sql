select * from county_facts

select * from county_facts_dictionary
where column_name  like 'SEX%'


/* tworzenie tabeli pomocniczej zawieraj�cej wszystkie dane potrzebne do analizy*/
create temp table dane_p�e� as 
select state,county,  party, candidate, votes, round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,fraction_votes ,
SEX255214 as kobiety_hr,
round(avg(SEX255214)  over (partition by state), 2) as kobiety_stan,
100 - SEX255214 as m�czy�ni_hr,
round(avg(100 - SEX255214) over (partition by state), 2) as m�czy�ni_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips


/*Zestawienie sumaryczne - kandydat ze wzgl�du na wygrane stany*/

with kobiety as 
(select distinct candidate, round(avg(kobiety_stan),  2) as prct_kobiety, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, kobiety_stan
from
(select distinct state, candidate, prct_g�_stan_all,  kobiety_stan
from dane_p�e�
)dem
group by candidate, state, kobiety_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
m�czy�ni as 
(select distinct candidate, round(avg(m�czy�ni_stan),  2) as prct_m�czy�ni, count(*) as liczba_wygranych
from  
(select candidate, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, m�czy�ni_stan
from
(select distinct state, candidate, prct_g�_stan_all,  m�czy�ni_stan
from dane_p�e�
)dem
group by candidate, state, m�czy�ni_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate)
select kobiety.candidate, prct_kobiety, prct_m�czy�ni, kobiety.liczba_wygranych
from kobiety
join m�czy�ni
on kobiety.candidate = m�czy�ni.candidate


/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/

with kobiety as 
(select distinct party, round(avg(kobiety_stan),  2) as prct_kobiety, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, kobiety_stan
from
(select distinct state, party, prct_g�_stan_all,  kobiety_stan
from dane_p�e�
)dem
group by party, state, kobiety_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
m�czy�ni as 
(select distinct party, round(avg(m�czy�ni_stan),  2) as prct_m�czy�ni, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_kandydat_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, m�czy�ni_stan
from
(select distinct state, party, prct_g�_stan_all,  m�czy�ni_stan
from dane_p�e�
)dem
group by party, state, m�czy�ni_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party)
select kobiety.party, prct_kobiety, prct_m�czy�ni, kobiety.liczba_wygranych
from kobiety
join m�czy�ni
on kobiety.party = m�czy�ni.party


/*sprawdzanie zale�no�ci:
 a) zale�no�� - g� na kandydata - (u�rednione wyniki ca�o�ciowe)*/
 
select distinct candidate, sum(votes) over (partition by candidate) as liczba_g�_kandydat, 
round(avg(kobiety_hr) over (partition by candidate), 2) as �r_prct_kobiety,
round(avg(m�czy�ni_hr) over (partition by candidate), 2) as �r_m�czy�ni
from dane_p�e�
group by candidate, votes, kobiety_hr, m�czy�ni_hr
order by sum(votes) over (partition by candidate) desc


 /*b) zale�no�� - g� na parti� - (u�rednione wyniki ca�o�ciowe)*/
 
select distinct party, sum(votes) over (partition by party) as liczba_g�_kandydat, 
round(avg(kobiety_hr) over (partition by party), 2) as �r_prct_kobiety,
round(avg(m�czy�ni_hr) over (partition by party), 2) as �r_m�czy�ni
from dane_p�e�
group by party, votes, kobiety_hr, m�czy�ni_hr
order by sum(votes) over (partition by party) desc

/* Zestawienie ze wzgl�du na wygrane w hrabstwach */

/*a) wyb�r kandydata */

with kobiety as 
(select distinct candidate, round(avg(kobiety_hr),  2) as prct_kobiety, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, kobiety_hr
from
(select distinct county, candidate, prct_g�_hrabstwo_all,  kobiety_hr
from dane_p�e�
)dem
group by candidate, county, kobiety_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate),
m�czy�ni as 
(select distinct candidate, round(avg(m�czy�ni_hr),  2) as prct_m�czy�ni, count(*) as liczba_wygranych
from  
(select candidate, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, m�czy�ni_hr
from
(select distinct county, candidate, prct_g�_hrabstwo_all,  m�czy�ni_hr
from dane_p�e�
)dem
group by candidate, county, m�czy�ni_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by candidate)
select kobiety.candidate, prct_kobiety, prct_m�czy�ni, kobiety.liczba_wygranych
from kobiety
join m�czy�ni
on kobiety.candidate = m�czy�ni.candidate

/*b) wyb�r partii */

with kobiety as 
(select distinct party, round(avg(kobiety_hr),  2) as prct_kobiety, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, kobiety_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  kobiety_hr
from dane_p�e�
)dem
group by party, county, kobiety_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
m�czy�ni as 
(select distinct party, round(avg(m�czy�ni_hr),  2) as prct_m�czy�ni, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, m�czy�ni_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  m�czy�ni_hr
from dane_p�e�
)dem
group by party, county, m�czy�ni_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party)
select kobiety.party, prct_kobiety, prct_m�czy�ni, kobiety.liczba_wygranych
from kobiety
join m�czy�ni
on kobiety.party = m�czy�ni.party

-- badanie korelacji pomi�dzy g�osami danej p�ci, a kandydatem 

select candidate, 
corr(votes, kobiety_hr) as korelacja_g�osy_kobiet,
corr(votes, m�czy�ni_hr) as korelacja_g�osy_m�czyzn
from dane_p�e�
group by candidate
order by corr(votes, kobiety_hr) desc

-- badanie korelacji pomi�dzy g�osami danej p�ci, a kandydatem  - podzia� na stany
select candidate, state,
corr(votes, kobiety_hr) as korelacja_g�osy_kobiet,
corr(votes, m�czy�ni_hr) as korelacja_g�osy_m�czyzn
from dane_p�e�
group by candidate, state
order by corr(votes, kobiety_hr) desc



-- badanie korelacji pomi�dzy g�osami danej p�ci, a parti�

select party, 
corr(votes, kobiety_hr) as korelacja_g�_kobiet,
corr(votes, m�czy�ni_hr) as korelacja_g�_m�czyzn
from dane_p�e�
group by party
order by corr(votes, kobiety_hr) desc

-- badanie korelacji pomi�dzy g�osami danej p�ci, a parti�  - podzia� na stany
select party, state,
corr(votes, kobiety_hr) as korelacja_g�_kobiet,
corr(votes, m�czy�ni_hr) as korelacja_g�_m�czyzn
from dane_p�e�
group by party, state
order by corr(votes, kobiety_hr) desc

-- dodatkowe -- 
/* ilo�� hrabstw wygranych przez danego kandydata, gdzie g�osowali na niego w przewadze m�czy�ni */
select candidate,  count(candidate) as ilo��_hrabstw_wygranych from
(select * , rank() over (partition by county order by fraction_votes desc) as ranking
from
(select *,
case when kobiety_hr > m�czy�ni_hr then 'wi�cej kobiet'
when kobiety_hr = m�czy�ni_hr then 'podzia� p�ci'
else 'wi�cej m�czyzn'
end as p�e�_dominuj�ca
from dane_p�e�)x 
where p�e�_dominuj�ca like '%m�%')p 
where ranking = 1
group by candidate

/* ilo�� hrabstw wygranych przez danego kandydata, gdzie g�osowali na niego w przewadze kobiety */
select candidate,  count(candidate) as ilo��_hrabstw_wygranych from
(select * , rank() over (partition by county order by fraction_votes desc) as ranking
from
(select *,
case when kobiety_hr > m�czy�ni_hr then 'wi�cej kobiet'
when kobiety_hr = m�czy�ni_hr then 'podzia� p�ci'
else 'wi�cej m�czyzn'
end as p�e�_dominuj�ca
from dane_p�e�)x 
where p�e�_dominuj�ca like '%kob%')p 
where ranking = 1
group by candidate


