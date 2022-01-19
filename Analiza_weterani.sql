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


-- analiza w podziale na podgrupy -- dane do u�ycia

/* wykaz hrabstw stosunek procentowy g�os�w na dan� pati� (w podziale na grupy ilo�ciowe) - do pokazania na mapie*/

with stany as
(select county, state, liczba_weteran�w from
(select  distinct county, state, 
case  
when weterani_hr < 1000 then '0 - 1 ty�'
when weterani_hr < 2000 then '1 - 2 ty�'
when weterani_hr < 3000 then '2 - 5 ty�'
when weterani_hr < 5000 then '3 - 5 ty�'
when weterani_hr < 10000 then '5 - 10 ty�'
when weterani_hr < 20000 then '10 - 20 ty�'
else 'powy�ej 20 ty�'
end as liczba_weteran�w
from dane_weterani)x) 
select county, state, stany.liczba_weteran�w,
round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2) as prct_g�os�w_republikanie,
100 - round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2) as prct_g�os�w_demokraci,
case when round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2) > 100 - round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2)
then 'Republikanie'
when round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2) < 100 - round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2)
then 'Demokraci'
end as winner
from stany
join v_obliczenia_iv_weterani viw
on stany.liczba_weteran�w = viw.liczba_weteran�w
order by stany.liczba_weteran�w





/* wykaz hrabstw stosunek procentowy g�os�w na dan� pati� (w podziale na grupy ilo�ciowe)*/

with stany as
(select county, state, zag�szczenie_hrabstwa from
(select  distinct county, state, 
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zag�szczenie_hrabstwa
from dane_populacja)x) 
select county, state, stany.zag�szczenie_hrabstwa,
round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2) as prct_g�os�w_republikanie,
100 - round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2) as prct_g�os�w_demokraci,
case when round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2) > 100 - round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2)
then 'Republikanie'
when round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2) < 100 - round(liczba_g�_republikanie * 100 / (liczba_g�_republikanie + liczba_g�_demokraci), 2)
then 'Demokraci'
end as winner
from stany
join v_iv_zageszczenie vig
on stany.zag�szczenie_hrabstwa = vig.zag�szczenie_hrabstwa



/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/


select distinct party, round(avg(weterani_stan),  2) as �r_liczba_weteran�w_na_stan, 
sum(weterani_stan) as liczba_wszystkich_weteran�w_w_stanie,
count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, weterani_stan
from
(select distinct state, party, prct_g�_stan_all,  weterani_stan
from dane_weterani dw 
)dem
group by party, state, weterani_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party




 /*b) zale�no�� - g� na parti� - (u�rednione wyniki ca�o�ciowe) - statystyka nic nie znacz�ca*//
 
select distinct party, sum(votes) over (partition by party) as liczba_g�_partia, 
round(avg(weterani_hr) over (partition by party), 2) as �r_liczba_weteran�w
from dane_weterani
group by party, votes, weterani_hr
order by sum(votes) over (partition by party) desc



/*b) wyb�r partii, wygrane hrabstwa*/


select party, round(avg(weterani_hr),  2) as �rednia_liczba_weteran�w, count (*) as liczba_wygranych from
(select state, county,liczba_g�os�w_partia, party, weterani_hr,
dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking from
(select distinct state, county, party, 
sum(votes) as liczba_g�os�w_partia, 
weterani_hr
from dane_weterani 
group by party, county, weterani_hr, state
order by county)rkg)naj
where ranking = 1
group by  party



-- badanie korelacji pomi�dzy g�osami weteran�w, a parti�

select party, 
corr(votes, weterani_hr) as korelacja_weterani
from dane_weterani
group by party
order by corr(votes, weterani_hr) desc



