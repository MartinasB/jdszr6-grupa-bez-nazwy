select * from county_facts

select * from county_facts_dictionary
where column_name  like 'SEX%'


/* tworzenie tabeli pomocniczej zawieraj�cej wszystkie dane potrzebne do analizy*/
create table dane_p�e� as 
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


--WOE i IV kobiety--

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/


select procent_kobiet,  count(*) from /*OK*/
(select distinct county, state,
case when kobiety_hr < 48 then '0 - 48 %'
when kobiety_hr < 49 then '48 - 49 %'
when kobiety_hr < 50 then '49 - 50 %'
when kobiety_hr < 51 then '50 - 51 %'
when kobiety_hr < 52 then '51 - 52 %'
else 'powy�ej 52%'
end as procent_kobiet
from dane_p�e�)x
group by procent_kobiet

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_kobiety_ as
with rep as
(select distinct party, procent_kobiet, sum(votes) over (partition by party, procent_kobiet) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when kobiety_hr < 48 then '0 - 48 %'
when kobiety_hr < 49 then '48 - 49 %'
when kobiety_hr < 50 then '49 - 50 %'
when kobiety_hr < 51 then '50 - 51 %'
when kobiety_hr < 52 then '51 - 52 %'
else 'powy�ej 52%'
end as procent_kobiet
from dane_p�e�
group by party, votes, kobiety_hr
order by procent_kobiet)m
where party = 'Republican'),
dem as
(select distinct party, procent_kobiet, sum(votes) over (partition by party, procent_kobiet) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when kobiety_hr < 48 then '0 - 48 %'
when kobiety_hr < 49 then '48 - 49 %'
when kobiety_hr < 50 then '49 - 50 %'
when kobiety_hr < 51 then '50 - 51 %'
when kobiety_hr < 52 then '51 - 52 %'
else 'powy�ej 52%'
end as procent_kobiet
from dane_p�e�
group by party, votes, kobiety_hr
order by procent_kobiet)m
where party = 'Democrat')
select rep.procent_kobiet, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_kobiet = dem.procent_kobiet



select *
from v_iv_kobiety_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_kobiety_ /*s�aby predyktor - 0.098*/


--WOE i IV m�czy�ni--

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/


select procent_m�czyzn,  count(*) from /*OK*/
(select distinct county, state,
case when m�czy�ni_hr < 48 then '0 - 48 %'
when m�czy�ni_hr < 49 then '48 - 49 %'
when m�czy�ni_hr < 50 then '49 - 50 %'
when m�czy�ni_hr < 51 then '50 - 51 %'
when m�czy�ni_hr < 52 then '51 - 52 %'
else 'powy�ej 52%'
end as procent_m�czyzn
from dane_p�e�)x
group by procent_m�czyzn

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_mezczyzni_ as
with rep as
(select distinct party, procent_m�czyzn, sum(votes) over (partition by party, procent_m�czyzn) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when m�czy�ni_hr < 48 then '0 - 48 %'
when m�czy�ni_hr < 49 then '48 - 49 %'
when m�czy�ni_hr < 50 then '49 - 50 %'
when m�czy�ni_hr < 51 then '50 - 51 %'
when m�czy�ni_hr < 52 then '51 - 52 %'
else 'powy�ej 52%'
end as procent_m�czyzn
from dane_p�e�
group by party, votes, m�czy�ni_hr
order by procent_m�czyzn)m
where party = 'Republican'),
dem as
(select distinct party, procent_m�czyzn, sum(votes) over (partition by party, procent_m�czyzn) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when m�czy�ni_hr < 48 then '0 - 48 %'
when m�czy�ni_hr < 49 then '48 - 49 %'
when m�czy�ni_hr < 50 then '49 - 50 %'
when m�czy�ni_hr < 51 then '50 - 51 %'
when m�czy�ni_hr < 52 then '51 - 52 %'
else 'powy�ej 52%'
end as procent_m�czyzn
from dane_p�e�
group by party, votes, m�czy�ni_hr
order by procent_m�czyzn)m
where party = 'Democrat')
select rep.procent_m�czyzn, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.procent_m�czyzn = dem.procent_m�czyzn



select *
from v_iv_mezczyzni_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_mezczyzni_ /*s�aby predyktor (jako, �e wynik u biet jest por�wnywarny) - 0.100*/


/*zar�wno w�r�d m�czyzn jak i kobiet wsp�cznik iV jest s�abym predyktorem - nie przeprowadzono dalszej analizy*/


