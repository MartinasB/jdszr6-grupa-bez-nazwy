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
round(sum(VET605213) over (partition by state), 2) as weterani_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/


select czas_dojazdu, count(*) from
(select party, votes, county,
case  
when weterani_hr < 1000 then '0 - 1 ty�'
when weterani_hr < 2000 then '1 - 2 ty�'
when weterani_hr < 3000 then '2 - 5 ty�'
when weterani_hr < 5000 then '3 - 5 ty�'
when weterani_hr < 10000 then '5 - 10 ty�'
when weterani_hr < 20000 then '10 - 20 ty�'
else 'powy�ej 20 ty�'
end as czas_liczba_weteran�w
from dane_weterani)x
group by czas_dojazdu

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_obliczenia_iv_weterani as
with rep as
(select distinct party, liczba_weteran�w, sum(votes) over (partition by party, liczba_weteran�w) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case  
when weterani_hr < 1000 then '0 - 1 ty�'
when weterani_hr < 2000 then '1 - 2 ty�'
when weterani_hr < 3000 then '2 - 5 ty�'
when weterani_hr < 5000 then '3 - 5 ty�'
when weterani_hr < 10000 then '5 - 10 ty�'
when weterani_hr < 20000 then '10 - 20 ty�'
else 'powy�ej 20 ty�'
end as liczba_weteran�w
from dane_weterani
group by party, votes, weterani_hr
order by liczba_weteran�w)m
where party = 'Republican'),
dem as 
(select distinct party, liczba_weteran�w, sum(votes) over (partition by party, liczba_weteran�w ) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case  
when weterani_hr < 1000 then '0 - 1 ty�'
when weterani_hr < 2000 then '1 - 2 ty�'
when weterani_hr < 3000 then '2 - 5 ty�'
when weterani_hr < 5000 then '3 - 5 ty�'
when weterani_hr < 10000 then '5 - 10 ty�'
when weterani_hr < 20000 then '10 - 20 ty�'
else 'powy�ej 20 ty�'
end as liczba_weteran�w
from dane_weterani
group by party, votes, weterani_hr
order by liczba_weteran�w)m
where party = 'Democrat')
select distinct  dem.liczba_weteran�w, liczba_g�_republikanie, liczba_g�_demokraci, 
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as dr_dd,
(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as dr_dd_woe
from rep 
join dem 
on dem.liczba_weteran�w= rep.liczba_weteran�w


select *
from v_obliczenia_iv_weterani;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_obliczenia_iv_weterani /*�redni predyktor - 0.122*/




/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/

with liczba as
(select distinct party, round(sum(weterani_stan),  2) as liczba_weteran�w, count(*) as liczba_wygranych
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

/*sprawdzanie zale�no�ci:*/
 


 /*b) zale�no�� - g� na parti� - (u�rednione wyniki ca�o�ciowe)*/
 

with liczba as
(select distinct party, sum(votes) over (partition by party) as liczba_g�_kandydat, 
round(sum(weterani_hr) over (partition by party, 2)) as liczba_weteran�w
from dane_weterani
group by party, votes, weterani_hr
order by sum(votes) over (partition by party) desc),
ca�o�� as 
(select sum(liczba_weteran�w) as suma from
liczba)
select party, round(liczba_weteran�w*100/suma, 2) as prct_weteran�w
from liczba 
cross join ca�o��

-- analiza wzgl�dem wygranych hrabstw --


/*b) wyb�r partii*/

with liczba as
(select distinct party, round(sum(weterani_hr),  2) as liczba_weteran�w, count(*) as liczba_wygranych
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



