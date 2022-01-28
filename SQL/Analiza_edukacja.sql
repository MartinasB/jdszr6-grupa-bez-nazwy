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
create view v_iv_wyk_�rednie_ as
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
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_wykszta�cenie_�rednie = dem.procent_wykszta�cenie_�rednie


select *
from v_iv_wyk_�rednie_ ;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_wyk_�rednie_ /*nieu�yteczny predyktor - 0.067*/



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
create view v_iv_wyk_wyzsze_ as
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
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_wykszta�cenie_wy�sze = dem.procent_wykszta�cenie_wy�sze


select *
from v_iv_wyk_wyzsze_ ;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_wyk_wyzsze_ /*�redni predyktor - 0.135*/

-- analiza w podziale na podgrupy -- dane do u�ycia

/* wykaz hrabstw stosunek procentowy g�os�w na dan� pati� (w podziale na grupy ilo�ciowe) - do pokazania na mapie*/

with stany as
(select county, state,party, procent_wykszta�cenie_wy�sze from
(select  distinct county, state, party,
case when wykszta�cenie_min_wy�sze_hr < 10 then '0 - 10 %'
when wykszta�cenie_min_wy�sze_hr < 15 then '10 - 15 %'
when wykszta�cenie_min_wy�sze_hr < 20 then '15 - 20 %'
when wykszta�cenie_min_wy�sze_hr < 25 then '20 - 25 %'
when wykszta�cenie_min_wy�sze_hr  < 30 then '25 - 30 %'
when wykszta�cenie_min_wy�sze_hr  < 35 then '30 - 35 %'
else 'powy�ej 35%'
end as procent_wykszta�cenie_wy�sze
from dane_edukacj)x) 
select county, state, party, stany.procent_wykszta�cenie_wy�sze,
liczba_g�_republikanie, liczba_g�_demokraci
from stany
join v_iv_wyk_wyzsze_ ive
on stany.procent_wykszta�cenie_wy�sze = ive.procent_wykszta�cenie_wy�sze
order by stany.procent_wykszta�cenie_wy�sze




/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/


select distinct party, round(avg(osoby_wykszta�cenie_wy�sze_stan),  2) as �r_prct_wykszta�cenie_wy�sze,
count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, osoby_wykszta�cenie_wy�sze_stan
from
(select distinct state, party, prct_g�_stan_all,  osoby_wykszta�cenie_wy�sze_stan
from dane_edukacj de
)dem
group by party, state, osoby_wykszta�cenie_wy�sze_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party




/*b) wyb�r partii, wygrane hrabstwa*/


select party, round(avg(wykszta�cenie_min_wy�sze_hr),  2) as �redni_prct_wykszta�cenie_wy�sze, count (*) as liczba_wygranych from
(select state, county,liczba_g�os�w_partia, party, wykszta�cenie_min_wy�sze_hr,
dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking from
(select distinct state, county, party, 
sum(votes) as liczba_g�os�w_partia, 
wykszta�cenie_min_wy�sze_hr
from dane_edukacj
group by party, county, wykszta�cenie_min_wy�sze_hr, state
order by county)rkg)naj
where ranking = 1
group by  party



-- badanie korelacji pomi�dzy g�osami weteran�w, a parti�

select party, 
corr(votes, wykszta�cenie_min_wy�sze_hr) as korelacja_weterani
from dane_edukacj
group by party
order by corr(votes, wykszta�cenie_min_wy�sze_hr) desc


-- badanie korelacji pomi�dzy g�osami weteran�w, a parti� - przeliczenie na stany

select party, state, corr(suma_g�os�w_stan, wykszta�cenie_min_wy�sze_hr) as korelacja_weterani from
(select distinct party, sum(votes) over (partition by party, county) as suma_g�os�w_stan, state, county, wykszta�cenie_min_wy�sze_hr
from dane_edukacj
group by state, state, party, wykszta�cenie_min_wy�sze_hr, votes, county)x
group by party,state
order by corr(suma_g�os�w_stan, wykszta�cenie_min_wy�sze_hr)  desc

--- dodatkowo ---

--WOE i IV dla populacji w 2010 roku -- w pzeliczeniu na stany

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/

select procent_wykszta�cenie_wy�sze, count(*) from
(select distinct state,
case when osoby_wykszta�cenie_wy�sze_stan < 15 then '0 - 15 %'
when osoby_wykszta�cenie_wy�sze_stan < 17 then '15 - 17 %'
when osoby_wykszta�cenie_wy�sze_stan < 19 then '17 - 19 %'
when osoby_wykszta�cenie_wy�sze_stan < 21 then '19 - 21 %'
when osoby_wykszta�cenie_wy�sze_stan  < 23 then '21 - 23 %'
when osoby_wykszta�cenie_wy�sze_stan  < 25 then '23 - 25 %'
else 'powy�ej 25%'
end as procent_wykszta�cenie_wy�sze
from dane_edukacj)x
group by procent_wykszta�cenie_wy�sze

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_obliczenia_iv_wy�sze_stan_ as
with rep as
(select distinct party, procent_wykszta�cenie_wy�sze, sum(votes) over (partition by party, procent_wykszta�cenie_wy�sze) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when osoby_wykszta�cenie_wy�sze_stan < 15 then '0 - 15 %'
when osoby_wykszta�cenie_wy�sze_stan < 17 then '15 - 17 %'
when osoby_wykszta�cenie_wy�sze_stan < 19 then '17 - 19 %'
when osoby_wykszta�cenie_wy�sze_stan < 21 then '19 - 21 %'
when osoby_wykszta�cenie_wy�sze_stan  < 23 then '21 - 23 %'
when osoby_wykszta�cenie_wy�sze_stan  < 25 then '23 - 25 %'
else 'powy�ej 25%'
end as procent_wykszta�cenie_wy�sze
from dane_edukacj
group by party, votes, osoby_wykszta�cenie_wy�sze_stan
order by procent_wykszta�cenie_wy�sze)m
where party = 'Republican'),
dem as 
(select distinct party, procent_wykszta�cenie_wy�sze, sum(votes) over (partition by party, procent_wykszta�cenie_wy�sze ) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when osoby_wykszta�cenie_wy�sze_stan < 15 then '0 - 15 %'
when osoby_wykszta�cenie_wy�sze_stan < 17 then '15 - 17 %'
when osoby_wykszta�cenie_wy�sze_stan < 19 then '17 - 19 %'
when osoby_wykszta�cenie_wy�sze_stan < 21 then '19 - 21 %'
when osoby_wykszta�cenie_wy�sze_stan  < 23 then '21 - 23 %'
when osoby_wykszta�cenie_wy�sze_stan  < 25 then '23 - 25 %'
else 'powy�ej 25%'
end as procent_wykszta�cenie_wy�sze
from dane_edukacj
group by party, votes, osoby_wykszta�cenie_wy�sze_stan
order by procent_wykszta�cenie_wy�sze)m
where party = 'Democrat')
select distinct  dem.procent_wykszta�cenie_wy�sze, liczba_g�_republikanie, liczba_g�_demokraci, 
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep 
join dem 
on dem.procent_wykszta�cenie_wy�sze= rep.procent_wykszta�cenie_wy�sze

select *
from v_obliczenia_iv_wy�sze_stan_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_obliczenia_iv_wy�sze_stan_ /*�redni predyktor (do�� mocny) - 0.286*/

-- wykaz stan�w -- 

with stany as
(select  state, party, procent_wykszta�cenie_wy�sze from
(select  distinct state, party,
case when osoby_wykszta�cenie_wy�sze_stan < 15 then '0 - 15 %'
when osoby_wykszta�cenie_wy�sze_stan < 17 then '15 - 17 %'
when osoby_wykszta�cenie_wy�sze_stan < 19 then '17 - 19 %'
when osoby_wykszta�cenie_wy�sze_stan < 21 then '19 - 21 %'
when osoby_wykszta�cenie_wy�sze_stan  < 23 then '21 - 23 %'
when osoby_wykszta�cenie_wy�sze_stan  < 25 then '23 - 25 %'
else 'powy�ej 25%'
end as procent_wykszta�cenie_wy�sze
from dane_edukacj)x) 
select  state, party, stany.procent_wykszta�cenie_wy�sze,
liczba_g�_republikanie, liczba_g�_demokraci
from stany
join v_obliczenia_iv_wy�sze_stan_ vos
on stany.procent_wykszta�cenie_wy�sze = vos.procent_wykszta�cenie_wy�sze /*poprawne*/



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
create view v_iv_brak_wyk_ as
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
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_brak_wykszta�cenia = dem.procent_brak_wykszta�cenia


select *
from v_iv_brak_wyk_ ;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_brak_wyk_ /*nieu�yteczny predyktor - 0.066*/

