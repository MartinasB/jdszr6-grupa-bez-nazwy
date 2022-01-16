select * from county_facts

select * from county_facts_dictionary
where column_name  like 'EDU%'

/* tworzenie tabeli pomocniczej zawieraj�cej wszystkie dane potrzebne do analizy*/
create temp table dane_edukacj as 
select state,county,  party, candidate, votes, fraction_votes ,
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
EDU635213 as wykszta�cenie_min_�rednie_hr,
round(avg(EDU635213) over (partition by state), 2) as osoby_wykszta�cenie_�rednie_stan,
EDU685213 as wykszta�cenie_min_wy�sze_hr, 
round(avg(EDU685213) over (partition by state), 2) as osoby_wykszta�cenie_wy�sze_stan,
100 - EDU635213 as brak_wykszta�cenia_hr,
round(avg(100 - EDU635213) over (partition by state), 2) as osoby_bez_wykszta�cenia_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips




/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/

with �rednie as 
(select distinct party, round(avg(osoby_wykszta�cenie_�rednie_stan),  2) as prct_wykszta�cenie_�rednie, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_wykszta�cenie_�rednie_stan
from
(select distinct party, state, prct_g�_stan_all,  osoby_wykszta�cenie_�rednie_stan
from dane_edukacj
)dem
group by party, state, osoby_wykszta�cenie_�rednie_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
wy�sze as 
(select distinct party, round(avg(osoby_wykszta�cenie_wy�sze_stan), 2) as prct_wykszta�cenie_wy�sze, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_wykszta�cenie_wy�sze_stan
from
(select distinct state, party, prct_g�_stan_all,  osoby_wykszta�cenie_wy�sze_stan
from dane_edukacj
)dem
group by party, state, osoby_wykszta�cenie_wy�sze_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
bez_wykszta�cenia as 
( select distinct party, round(avg(osoby_bez_wykszta�cenia_stan), 2) as prct_bez_wykszta�cenia, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_bez_wykszta�cenia_stan
from
(select distinct state, party, prct_g�_stan_all,  osoby_bez_wykszta�cenia_stan
from dane_edukacj
)dem
group by party, state, osoby_bez_wykszta�cenia_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party)
select �rednie.party, prct_wykszta�cenie_�rednie, prct_wykszta�cenie_wy�sze, prct_bez_wykszta�cenia,  �rednie.liczba_wygranych
from �rednie
join wy�sze
on �rednie.party = wy�sze.party
join bez_wykszta�cenia
on �rednie.party = bez_wykszta�cenia.party





 /*b) zale�no�� - g� na parti� - (u�rednione wyniki ca�o�ciowe)*/
 

select distinct party, sum(votes) over (partition by party) as liczba_g�_kandydat, 
round(avg(wykszta�cenie_min_�rednie_hr) over (partition by party), 2) as �r_prct_min_�rednie,
round(avg(wykszta�cenie_min_wy�sze_hr) over (partition by party), 2) as �r_prct_min_wy�sze,
round(avg(brak_wykszta�cenia_hr) over (partition by party), 2) as �r_prct_brak_wykszta�cenia
from dane_edukacj
group by party, votes, wykszta�cenie_min_�rednie_hr, wykszta�cenie_min_wy�sze_hr, brak_wykszta�cenia_hr
order by sum(votes) over (partition by party) desc


-- analiza wzgl�dem wygranych hrabstw --







---

/*b) wyb�r partii*/

with �rednie as 
(select distinct party, round(avg(wykszta�cenie_min_�rednie_hr),  2) as prct_wykszta�cenie_�rednie, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, wykszta�cenie_min_�rednie_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  wykszta�cenie_min_�rednie_hr
from dane_edukacj
)dem
group by party, county, wykszta�cenie_min_�rednie_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
wy�sze as 
(select distinct party, round(avg(wykszta�cenie_min_wy�sze_hr), 2) as prct_wykszta�cenie_wy�sze, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, wykszta�cenie_min_wy�sze_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  wykszta�cenie_min_wy�sze_hr
from dane_edukacj
)dem
group by party, county, wykszta�cenie_min_wy�sze_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
bez_wykszta�cenia as 
( select distinct party, round(avg(brak_wykszta�cenia_hr), 2) as prct_bez_wykszta�cenia, count(*) as liczba_wygranych
from  
(select party, county, sum(prct_g�_hrabstwo_all) as prct_kandydat_hrabstwo, 
dense_rank() over (partition by county order by sum(prct_g�_hrabstwo_all) desc) as miejsce, brak_wykszta�cenia_hr
from
(select distinct county, party, prct_g�_hrabstwo_all,  brak_wykszta�cenia_hr
from dane_edukacj
)dem
group by party, county, brak_wykszta�cenia_hr
order by county) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party)
select �rednie.party, prct_wykszta�cenie_�rednie, prct_wykszta�cenie_wy�sze, prct_bez_wykszta�cenia,  �rednie.liczba_wygranych
from �rednie
join wy�sze
on �rednie.party = wy�sze.party
join bez_wykszta�cenia
on �rednie.party = bez_wykszta�cenia.party




-- badanie korelacji pomi�dzy g�osami danej grupy wiekowej, a parti�

select party, 
corr(votes, wykszta�cenie_min_�rednie_hr) as korelacja_�rednie,
corr(votes, wykszta�cenie_min_wy�sze_hr) as korelacja_wy�sze,
corr(votes, brak_wykszta�cenia_hr) as korelacja_brak_wykszta�cenia
from dane_edukacj
group by party

-- badanie korelacji pomi�dzy g�osami danej grupy wiekowej, a parti�  - podzia� na stany
select party, state,
corr(votes, wykszta�cenie_min_�rednie_hr) as korelacja_�rednie,
corr(votes, wykszta�cenie_min_wy�sze_hr) as korelacja_wy�sze,
corr(votes, brak_wykszta�cenia_hr) as korelacja_brak_wykszta�cenia
from dane_edukacj
group by party, state
order by corr(votes, wykszta�cenie_min_wy�sze_hr) desc





