select * from county_facts

select * from county_facts_dictionary
where column_name  like 'EDU%'

/* tworzenie tabeli pomocniczej zawieraj�cej wszystkie dane potrzebne do analizy*/
create table dane_edukacj as 
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


--WOE i IV dla edukacji - wykszta�cenie �rednie --

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/


select procent_wykszta�cenie_�rednie,  count(*) from /*OK*/
(select distinct county, state,
case when wykszta�cenie_min_�rednie_hr < 75 then '0 - 75 %'
when wykszta�cenie_min_�rednie_hr < 80 then '75 - 80 %'
when wykszta�cenie_min_�rednie_hr < 85 then '80 - 85 %'
when wykszta�cenie_min_�rednie_hr < 90 then '85 - 90 %'
else 'powy�ej 90%'
end as procent_wykszta�cenie_�rednie
from dane_edukacj)x
group by procent_wykszta�cenie_�rednie

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_wyk_�rednie as
with rep as
(select distinct party, procent_wykszta�cenie_�rednie, sum(votes) over (partition by party, procent_wykszta�cenie_�rednie) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when wykszta�cenie_min_�rednie_hr < 75 then '0 - 75 %'
when wykszta�cenie_min_�rednie_hr < 80 then '75 - 80 %'
when wykszta�cenie_min_�rednie_hr < 85 then '80 - 85 %'
when wykszta�cenie_min_�rednie_hr < 90 then '85 - 90 %'
else 'powy�ej 90%'
end as procent_wykszta�cenie_�rednie
from dane_edukacj
group by party, votes, wykszta�cenie_min_�rednie_hr
order by procent_wykszta�cenie_�rednie)m
where party = 'Republican'),
dem as
(select distinct party, procent_wykszta�cenie_�rednie, sum(votes) over (partition by party, procent_wykszta�cenie_�rednie) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when wykszta�cenie_min_�rednie_hr < 75 then '0 - 75 %'
when wykszta�cenie_min_�rednie_hr < 80 then '75 - 80 %'
when wykszta�cenie_min_�rednie_hr < 85 then '80 - 85 %'
when wykszta�cenie_min_�rednie_hr < 90 then '85 - 90 %'
else 'powy�ej 90%'
end as procent_wykszta�cenie_�rednie
from dane_edukacj
group by party, votes, wykszta�cenie_min_�rednie_hr
order by procent_wykszta�cenie_�rednie)m
where party = 'Democrat')
select rep.procent_wykszta�cenie_�rednie, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as dr_dd,
(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_wykszta�cenie_�rednie = dem.procent_wykszta�cenie_�rednie


select *
from v_iv_wyk_�rednie ;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_wyk_�rednie /*nieu�yteczny predyktor - 0.015*/



--WOE i IV dla edukacji - wykszta�cenie wy�sze --

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/


select procent_wykszta�cenie_wy�sze,  count(*) from /*OK*/
(select distinct county, state,
case when wykszta�cenie_min_wy�sze_hr < 10 then '0 - 10 %'
when wykszta�cenie_min_wy�sze_hr < 15 then '10 - 15 %'
when wykszta�cenie_min_wy�sze_hr < 20 then '15 - 20 %'
when wykszta�cenie_min_wy�sze_hr < 25 then '20 - 25 %'
when wykszta�cenie_min_wy�sze_hr  < 30 then '25 - 30 %'
when wykszta�cenie_min_wy�sze_hr  < 35 then '30 - 35 %'
else 'powy�ej 35%'
end as procent_wykszta�cenie_wy�sze
from dane_edukacj)x
group by procent_wykszta�cenie_wy�sze

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_wyk_wyzsze as
with rep as
(select distinct party, procent_wykszta�cenie_wy�sze, sum(votes) over (partition by party, procent_wykszta�cenie_wy�sze) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when wykszta�cenie_min_wy�sze_hr < 10 then '0 - 10 %'
when wykszta�cenie_min_wy�sze_hr < 15 then '10 - 15 %'
when wykszta�cenie_min_wy�sze_hr < 20 then '15 - 20 %'
when wykszta�cenie_min_wy�sze_hr < 25 then '20 - 25 %'
when wykszta�cenie_min_wy�sze_hr  < 30 then '25 - 30 %'
when wykszta�cenie_min_wy�sze_hr  < 35 then '30 - 35 %'
else 'powy�ej 35%'
end as procent_wykszta�cenie_wy�sze
from dane_edukacj
group by party, votes, wykszta�cenie_min_wy�sze_hr
order by procent_wykszta�cenie_wy�sze)m
where party = 'Republican'),
dem as
(select distinct party, procent_wykszta�cenie_wy�sze, sum(votes) over (partition by party, procent_wykszta�cenie_wy�sze) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when wykszta�cenie_min_wy�sze_hr < 10 then '0 - 10 %'
when wykszta�cenie_min_wy�sze_hr < 15 then '10 - 15 %'
when wykszta�cenie_min_wy�sze_hr < 20 then '15 - 20 %'
when wykszta�cenie_min_wy�sze_hr < 25 then '20 - 25 %'
when wykszta�cenie_min_wy�sze_hr  < 30 then '25 - 30 %'
when wykszta�cenie_min_wy�sze_hr  < 35 then '30 - 35 %'
else 'powy�ej 35%'
end as procent_wykszta�cenie_wy�sze
from dane_edukacj
group by party, votes, wykszta�cenie_min_wy�sze_hr
order by procent_wykszta�cenie_wy�sze)m
where party = 'Democrat')
select rep.procent_wykszta�cenie_wy�sze, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as dr_dd,
(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_wykszta�cenie_wy�sze = dem.procent_wykszta�cenie_wy�sze


select *
from v_iv_wyk_wyzsze ;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_wyk_wyzsze /*s�aby predyktor - 0.083*/


--WOE i IV dla edukacji - brak wykszta�cenia --

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/



select procent_brak_wykszta�cenia,  count(*) from /*OK*/
(select distinct county, state,
case when brak_wykszta�cenia_hr < 10 then '0 - 10 %'
when brak_wykszta�cenia_hr < 15 then '10 - 15 %'
when brak_wykszta�cenia_hr < 20 then '15 - 20 %'
when brak_wykszta�cenia_hr < 25 then '20 - 25 %'
else 'powy�ej 25%'
end as procent_brak_wykszta�cenia
from dane_edukacj)x
group by procent_brak_wykszta�cenia

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_brak_wyk as
with rep as
(select distinct party, procent_brak_wykszta�cenia, sum(votes) over (partition by party, procent_brak_wykszta�cenia) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when brak_wykszta�cenia_hr < 10 then '0 - 10 %'
when brak_wykszta�cenia_hr < 15 then '10 - 15 %'
when brak_wykszta�cenia_hr < 20 then '15 - 20 %'
when brak_wykszta�cenia_hr < 25 then '20 - 25 %'
else 'powy�ej 25%'
end as procent_brak_wykszta�cenia
from dane_edukacj
group by party, votes, brak_wykszta�cenia_hr
order by procent_brak_wykszta�cenia)m
where party = 'Republican'),
dem as
(select distinct party, procent_brak_wykszta�cenia, sum(votes) over (partition by party, procent_brak_wykszta�cenia) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when brak_wykszta�cenia_hr < 10 then '0 - 10 %'
when brak_wykszta�cenia_hr < 15 then '10 - 15 %'
when brak_wykszta�cenia_hr < 20 then '15 - 20 %'
when brak_wykszta�cenia_hr < 25 then '20 - 25 %'
else 'powy�ej 25%'
end as procent_brak_wykszta�cenia
from dane_edukacj
group by party, votes, brak_wykszta�cenia_hr
order by procent_brak_wykszta�cenia)m
where party = 'Democrat')
select rep.procent_brak_wykszta�cenia, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as dr_dd,
(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3)) as dr_dd_woe
from rep
join dem
on rep.procent_brak_wykszta�cenia = dem.procent_brak_wykszta�cenia


select *
from v_iv_brak_wyk ;
select sum(dr_dd_woe) as information_value /*wyliczenie IV*/
from v_iv_brak_wyk /*nieu�yteczny predyktor - 0.014*/

