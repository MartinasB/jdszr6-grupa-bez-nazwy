select * from county_facts

select * from county_facts_dictionary
where column_name like 'AGE%'

/* tworzenie tabeli pomocniczej zawieraj�cej wszystkie dane potrzebne do analizy*/
create table dane_wiekowe as 
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



--WOE i IV dla udzia�u wieku �redniego  --

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/

select procent_wiek_�redni,  count(*) from /*OK*/
(select distinct county, state,
case when osoby_18_do_65_hr < 55 then '0 - 55 %'
when osoby_18_do_65_hr < 58 then '55 - 58 %'
when osoby_18_do_65_hr < 60 then '58 - 60 %'
when osoby_18_do_65_hr < 63 then '60 - 65 %'
else 'powy�ej 65 %'
end as procent_wiek_�redni
from dane_wiekowe)x
group by procent_wiek_�redni

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_wiek_18_65 as
with rep as
(select distinct party, procent_wiek_�redni, sum(votes) over (partition by party, procent_wiek_�redni) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when osoby_18_do_65_hr < 55 then '0 - 55 %'
when osoby_18_do_65_hr < 58 then '55 - 58 %'
when osoby_18_do_65_hr < 60 then '58 - 60 %'
when osoby_18_do_65_hr < 63 then '60 - 65 %'
else 'powy�ej 65 %'
end as procent_wiek_�redni
from dane_wiekowe
group by party, votes, osoby_18_do_65_hr)m
where party = 'Republican'),
dem as
(select distinct party, procent_wiek_�redni, sum(votes) over (partition by party, procent_wiek_�redni) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when osoby_18_do_65_hr < 55 then '0 - 55 %'
when osoby_18_do_65_hr < 58 then '55 - 58 %'
when osoby_18_do_65_hr < 60 then '58 - 60 %'
when osoby_18_do_65_hr < 63 then '60 - 65 %'
else 'powy�ej 65 %'
end as procent_wiek_�redni
from dane_wiekowe
group by party, votes, osoby_18_do_65_hr)m
where party = 'Democrat')
select rep.procent_wiek_�redni, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as dr_dd,
(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_wiek_�redni = dem.procent_wiek_�redni



select *
from v_iv_wiek_18_65;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_wiek_18_65 /*�redni predyktor - 0.193*/

/* zestawienie harbstw - do pokazania na mapie */
with stany as
(select county, state, party, procent_wiek_�redni from
(select  distinct county, state, party,
case when osoby_18_do_65_hr < 55 then '0 - 55 %'
when osoby_18_do_65_hr < 58 then '55 - 58 %'
when osoby_18_do_65_hr < 60 then '58 - 60 %'
when osoby_18_do_65_hr < 63 then '60 - 65 %'
else 'powy�ej 65 %'
end as procent_wiek_�redni
from dane_wiekowe)x) 
select county, state, party, stany.procent_wiek_�redni,
liczba_g�_republikanie, liczba_g�_demokraci,
case when liczba_g�_republikanie  > liczba_g�_demokraci
then 'Republikanie'
when liczba_g�_republikanie  < liczba_g�_demokraci
then 'Demokraci'
end as winner
from stany
join v_iv_wiek_18_65 vi�
on stany.procent_wiek_�redni = vi�.procent_wiek_�redni /*poprawne*/

/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/



select distinct party, round(avg(osoby_18_do_65_stan),  2) as �r_procent_18_do_65, 
count(*) as liczba_wygranych
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
group by party



 /*b) zale�no�� - g� na parti� - (u�rednione wyniki ca�o�ciowe) - statystyka nic nie znacz�ca*//
 
select distinct party, sum(votes) over (partition by party) as �r_liczba_g�_partia, 
round(avg(osoby_18_do_65_hr) over (partition by party), 2) as �r_procent_18_do_65
from dane_wiekowe
group by party, votes, osoby_18_do_65_hr
order by sum(votes) over (partition by party) desc



/*b) wyb�r partii, wygrane hrabstwa*/



select party, round(avg(osoby_18_do_65_hr),  2) as �redni_udzia�_18_do_65, count (*) as liczba_wygranych from
(select state, county,liczba_g�os�w_partia, party, osoby_18_do_65_hr,
dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking from
(select distinct state, county, party, 
sum(votes) as liczba_g�os�w_partia, 
osoby_18_do_65_hr
from dane_wiekowe
group by party, county, osoby_18_do_65_hr, state
order by county)rkg)naj
where ranking = 1
group by  party




-- badanie korelacji pomi�dzy g�osami danej grupy wiekowej, a parti�

select party, 
corr(votes, osoby_18_do_65_hr) as korelacja_18_do_65
from dane_wiekowe
group by party

-- badanie korelacji pomi�dzy g�osami danej grupy wiekowej, a parti�  - podzia� na stany
select party, state,
corr(votes, osoby_18_do_65_hr) as korelacja_18_do_65
from dane_wiekowe
group by party, state

-----------------------------------------------------------------------------------------

/*-WOE i IV dla udzia�u senior�w  --*/

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/

select procent_wiek_senior,  count(*) from /*OK*/
(select distinct county, state,
case when osoby_min_65_hr < 12 then '0 - 12 %'
when osoby_min_65_hr < 16 then '12 - 16 %'
when osoby_min_65_hr < 18 then '16 - 18 %'
when osoby_min_65_hr < 20 then '18 - 20 %'
when osoby_min_65_hr < 25 then '20 - 25 %'
else 'powy�ej 25 %'
end as procent_wiek_senior
from dane_wiekowe)x
group by procent_wiek_senior

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_min_65 as
with rep as
(select distinct party, procent_wiek_senior, sum(votes) over (partition by party, procent_wiek_senior) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when osoby_min_65_hr < 12 then '0 - 12 %'
when osoby_min_65_hr < 16 then '12 - 16 %'
when osoby_min_65_hr < 18 then '16 - 18 %'
when osoby_min_65_hr < 20 then '18 - 20 %'
when osoby_min_65_hr < 25 then '20 - 25 %'
else 'powy�ej 25 %'
end as procent_wiek_senior
from dane_wiekowe
group by party, votes, osoby_min_65_hr)m
where party = 'Republican'),
dem as
(select distinct party, procent_wiek_senior, sum(votes) over (partition by party, procent_wiek_senior) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when osoby_min_65_hr < 12 then '0 - 12 %'
when osoby_min_65_hr < 16 then '12 - 16 %'
when osoby_min_65_hr < 18 then '16 - 18 %'
when osoby_min_65_hr < 20 then '18 - 20 %'
when osoby_min_65_hr < 25 then '20 - 25 %'
else 'powy�ej 25 %'
end as procent_wiek_senior
from dane_wiekowe
group by party, votes, osoby_min_65_hr)m
where party = 'Democrat')
select rep.procent_wiek_senior, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as dr_dd,
(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_wiek_senior = dem.procent_wiek_senior



select *
from v_iv_min_65;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_min_65 /*s�aby predyktor - 0.058 - zmienna nie brana pod uwag� w celu dalszej analizy*/

/*-WOE i IV dla udzia�u grupy okre�lonej jako wiek do 5 lat  --*/


/* sprawdzenie ile wynik�w b�dzie w danej grupie*/

select procent_wiek_do_5,  count(*) from /*OK*/
(select distinct county, state,
case when osoby_poni�ej_5_hr < 5 then '0 - 5 %'
when osoby_poni�ej_5_hr < 6 then '5 - 6 %'
when osoby_poni�ej_5_hr < 7 then '6 - 7 %'
when osoby_poni�ej_5_hr < 8 then '7 - 8 %'
else 'powy�ej 8 %'
end as procent_wiek_do_5
from dane_wiekowe)x
group by procent_wiek_do_5

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_do_5 as
with rep as
(select distinct party, procent_wiek_do_5, sum(votes) over (partition by party, procent_wiek_do_5) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when osoby_poni�ej_5_hr < 5 then '0 - 5 %'
when osoby_poni�ej_5_hr < 6 then '5 - 6 %'
when osoby_poni�ej_5_hr < 7 then '6 - 7 %'
when osoby_poni�ej_5_hr < 8 then '7 - 8 %'
else 'powy�ej 8 %'
end as procent_wiek_do_5
from dane_wiekowe
group by party, votes, osoby_poni�ej_5_hr)m
where party = 'Republican'),
dem as
(select distinct party, procent_wiek_do_5, sum(votes) over (partition by party, procent_wiek_do_5) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when osoby_poni�ej_5_hr < 5 then '0 - 5 %'
when osoby_poni�ej_5_hr < 6 then '5 - 6 %'
when osoby_poni�ej_5_hr < 7 then '6 - 7 %'
when osoby_poni�ej_5_hr < 8 then '7 - 8 %'
else 'powy�ej 8 %'
end as procent_wiek_do_5
from dane_wiekowe
group by party, votes, osoby_poni�ej_5_hr)m
where party = 'Democrat')
select rep.procent_wiek_do_5, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as dr_dd,
(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_wiek_do_5 = dem.procent_wiek_do_5



select *
from v_iv_do_5;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_do_5 /*nieu�yteczny predyktor - 0.015 - zmienna nie brana pod uwag� w celu dalszej analizy*/

/*-WOE i IV dla udzia�u grupy okre�lonej jako wiek do 18 lat  --*/

select osoby_poni�ej_18_hr
from dane_wiekowe dw 
order by osoby_poni�ej_18_hr 

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/

select procent_wiek_do_18,  count(*) from /*OK*/
(select distinct county, state,
case when osoby_poni�ej_18_hr < 20 then '0 - 20 %'
when osoby_poni�ej_18_hr < 23 then '20 - 23 %'
when osoby_poni�ej_18_hr < 25 then '23 - 25 %'
when osoby_poni�ej_18_hr < 27 then '25 - 27 %'
else 'powy�ej 27 %'
end as procent_wiek_do_18
from dane_wiekowe)x
group by procent_wiek_do_18

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_do_18 as
with rep as
(select distinct party, procent_wiek_do_18, sum(votes) over (partition by party, procent_wiek_do_18) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when osoby_poni�ej_18_hr < 20 then '0 - 20 %'
when osoby_poni�ej_18_hr < 23 then '20 - 23 %'
when osoby_poni�ej_18_hr < 25 then '23 - 25 %'
when osoby_poni�ej_18_hr < 27 then '25 - 27 %'
else 'powy�ej 27 %'
end as procent_wiek_do_18
from dane_wiekowe
group by party, votes, osoby_poni�ej_18_hr)m
where party = 'Republican'),
dem as
(select distinct party, procent_wiek_do_18, sum(votes) over (partition by party, procent_wiek_do_18) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when osoby_poni�ej_18_hr < 20 then '0 - 20 %'
when osoby_poni�ej_18_hr < 23 then '20 - 23 %'
when osoby_poni�ej_18_hr < 25 then '23 - 25 %'
when osoby_poni�ej_18_hr < 27 then '25 - 27 %'
else 'powy�ej 27 %'
end as procent_wiek_do_18
from dane_wiekowe
group by party, votes, osoby_poni�ej_18_hr)m
where party = 'Democrat')
select rep.procent_wiek_do_18, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as dr_dd,
(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_wiek_do_18 = dem.procent_wiek_do_18



select *
from v_iv_do_18;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_do_18 /*s�aby predyktor - 0.028 - zmienna nie brana pod uwag� w celu dalszej analizy*/


