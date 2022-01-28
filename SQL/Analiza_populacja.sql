select * from county_facts

select * from county_facts_dictionary
where column_name = 'PST045214' or column_name = 'POP010210' or column_name = 'POP060210'


create temp table dane_populacja as 
select state,county,  party, candidate, votes, fraction_votes , 
round(votes * 100 / sum(votes) over (partition by county), 2) as prct_g�_hrabstwo_all,
round(fraction_votes * 100, 2) as prct_g�_hrabstwo_partia, 
sum(votes) over (partition by candidate, state)  as liczba_g�_stan,
round(sum(votes) over (partition by candidate, state) *100 / sum(votes) over (partition by state), 2 ) as prct_g�_stan_all,
round(sum(votes) over (partition by candidate, party, state) *100 / sum(votes) over (partition by state, party), 2 ) prct_g�_stan_partia,
PST045214 as estymacyjna_pop_2014_hr, 
round(sum(PST045214) over (partition by state), 2) as estymacyjna_pop_2014_stan,
POP010210 as pop_2010_real_hr,
round(sum(POP010210) over (partition by state), 2) as pop_2010_real_stan,
POP060210 as zageszczenie_2010_hr,
round(avg(POP060210 ) over (partition by state), 2) as zageszczenie_2010_stan
from primary_results_usa pr
join county_facts cf 
on pr.fips_no = cf.fips
order by PST045214 desc

-- dana do wszystkich analiz --
with dem as
(select sum(votes) as suma_g�_Demokraci, party
from primary_results_usa pru
where party = 'Democrat'
group by party),
rep as
(select sum(votes) as suma_g�_Republikan, party
from primary_results_usa pru
where party = 'Republican'
group by party),
suma as
(select sum(votes) as suma
from primary_results_usa pru)
select 
round(suma_g�_Demokraci*100 / suma, 2) as prct_Demokraci,
round(suma_g�_Republikan*100 / suma, 2) as prct_Republikan
from rep
cross join suma
cross join dem



--WOE i IV dla populacji w 2010 roku --

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/


select wielko��_hrabstwa,  count(*) from /*OK*/
(select distinct county, state,
case when pop_2010_real_hr < 10000 then '0 - 10 ty�'
when pop_2010_real_hr < 30000 then '10 - 30 ty�'
when pop_2010_real_hr < 50000 then '30 - 50 ty�'
when pop_2010_real_hr < 100000 then '50 - 100 ty�'
when pop_2010_real_hr < 300000 then '100 - 300 ty�'
else 'powy�ej 300 ty�'
end as wielko��_hrabstwa
from dane_populacja)x
group by wielko��_hrabstwa

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_populacj_ as
with rep as
(select distinct party, wielko��_hrabstwa, sum(votes) over (partition by party, wielko��_hrabstwa) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when pop_2010_real_hr < 10000 then '0 - 10 ty�'
when pop_2010_real_hr < 30000 then '10 - 30 ty�'
when pop_2010_real_hr < 50000 then '30 - 50 ty�'
when pop_2010_real_hr < 100000 then '50 - 100 ty�'
when pop_2010_real_hr < 300000 then '100 - 300 ty�'
else 'powy�ej 300 ty�'
end as wielko��_hrabstwa
from dane_populacja
group by party, votes, pop_2010_real_hr
order by wielko��_hrabstwa)m
where party = 'Republican'),
dem as
(select distinct party, wielko��_hrabstwa, sum(votes) over (partition by party, wielko��_hrabstwa) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when pop_2010_real_hr < 10000 then '0 - 10 ty�'
when pop_2010_real_hr < 30000 then '10 - 30 ty�'
when pop_2010_real_hr < 50000 then '30 - 50 ty�'
when pop_2010_real_hr < 100000 then '50 - 100 ty�'
when pop_2010_real_hr < 300000 then '100 - 300 ty�'
else 'powy�ej 300 ty�'
end as wielko��_hrabstwa
from dane_populacja
group by party, votes, pop_2010_real_hr
order by wielko��_hrabstwa)m
where party = 'Democrat')
select rep.wielko��_hrabstwa, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.wielko��_hrabstwa = dem.wielko��_hrabstwa



select *
from v_iv_populacj_ 
order by wielko��_hrabstwa;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_populacj_ /*�redni predyktor - 0.206*/



-- analiza w podziale na podgrupy -- dane do u�ycia

/* wykaz hrabstw stosunek procentowy g�os�w na dan� pati� (w podziale na grupy ilo�ciowe) - do pokazania na mapie*/

with stany as
(select county, state, party, wielko��_hrabstwa from
(select  distinct county, state, party,
case when pop_2010_real_hr < 10000 then '0 - 10 ty�'
when pop_2010_real_hr < 30000 then '10 - 30 ty�'
when pop_2010_real_hr < 50000 then '30 - 50 ty�'
when pop_2010_real_hr < 100000 then '50 - 100 ty�'
when pop_2010_real_hr < 300000 then '100 - 300 ty�'
else 'powy�ej 300 ty�'
end as wielko��_hrabstwa
from dane_populacja)x) 
select county, state, party, stany.wielko��_hrabstwa,
liczba_g�_republikanie, liczba_g�_demokraci
from stany
join v_iv_populacj vip
on stany.wielko��_hrabstwa = vip.wielko��_hrabstwa /*poprawne*/



--WOE i IV dla zag�szczenia w 2010 roku --

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/


select zag�szczenie_hrabstwa, count(*) from
(select distinct county, state,
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zag�szczenie_hrabstwa
from dane_populacja)x
group by zag�szczenie_hrabstwa


/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_zageszczenie_ as
with rep as
(select distinct party, zag�szczenie_hrabstwa, sum(votes) over (partition by party, zag�szczenie_hrabstwa) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zag�szczenie_hrabstwa
from dane_populacja
group by party, votes, zageszczenie_2010_hr
order by zag�szczenie_hrabstwa)m
where party = 'Republican'),
dem as
(select distinct party, zag�szczenie_hrabstwa, sum(votes) over (partition by party, zag�szczenie_hrabstwa) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zag�szczenie_hrabstwa
from dane_populacja
group by party, votes, zageszczenie_2010_hr
order by zag�szczenie_hrabstwa)m
where party = 'Democrat')
select rep.zag�szczenie_hrabstwa, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.zag�szczenie_hrabstwa = dem.zag�szczenie_hrabstwa


select *
from v_iv_zageszczenie_
order by zag�szczenie_hrabstwa;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_zageszczenie_ /*�redni predyktor - 0.246*/

/* wykaz hrabstw stosunek procentowy g�os�w na dan� pati� (w podziale na grupy ilo�ciowe)*/

with stany as
(select county, state, party, zag�szczenie_hrabstwa from
(select  distinct county, state, party,
case when zageszczenie_2010_hr < 50 then '0 - 50'
when zageszczenie_2010_hr < 100 then '50 - 100'
when zageszczenie_2010_hr < 200 then '100 - 200'
when zageszczenie_2010_hr < 500 then '200 - 500'
when zageszczenie_2010_hr< 1000 then '500 - 1000'
else '1000 +'
end as zag�szczenie_hrabstwa
from dane_populacja)x) 
select county, state, party, stany.zag�szczenie_hrabstwa,
liczba_g�_republikanie, liczba_g�_demokraci
from stany
join v_iv_zageszczenie vig
on stany.zag�szczenie_hrabstwa = vig.zag�szczenie_hrabstwa /*poprawne*/



/*Zestawienie sumaryczne - partia ze wzgl�du na wygrane stany*/


with real_2010 as 
(select distinct party, round(avg(pop_2010_real_stan),  2) as �r_populac_2010_real, 
sum(pop_2010_real_stan) as il_ludzi_real_2010,
count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, pop_2010_real_stan
from
(select distinct state, party, prct_g�_stan_all,  pop_2010_real_stan
from dane_populacja
)dem
group by party, state, pop_2010_real_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party),
zageszczenie_2010 as 
(select distinct party, round(avg(zageszczenie_2010_stan),  2) as �r_zageszczenie_2010, count(*) as liczba_wygranych
from  
(select party, state, sum(prct_g�_stan_all) as prct_partia_stan, 
dense_rank() over (partition by state order by sum(prct_g�_stan_all) desc) as miejsce, zageszczenie_2010_stan
from
(select distinct state, party, prct_g�_stan_all,  zageszczenie_2010_stan
from dane_populacja
)dem
group by party, state, zageszczenie_2010_stan
order by state) miejs
where miejsce = 1 /*filtorwanie po stanach, gdzie dana partia wygra�a*/
group by party)
select real_2010.party, �r_populac_2010_real,il_ludzi_real_2010,�r_zageszczenie_2010,  real_2010.liczba_wygranych
from real_2010
join zageszczenie_2010
on real_2010.party = zageszczenie_2010.party




 /*b) zale�no�� - g� na parti� - (u�rednione wyniki ca�o�ciowe) - statystyka nic nie znacz�ca*//
 
select distinct party, sum(votes) over (partition by party) as liczba_g�_partia, 
round(avg(pop_2010_real_hr) over (partition by party), 2) as �r_pop_rzeczywista,
round(avg(zageszczenie_2010_hr) over (partition by party), 2) as �r_zageszczenie_2010
from dane_populacja
group by party, votes, pop_2010_real_hr, zageszczenie_2010_hr
order by sum(votes) over (partition by party) desc



/*b) wyb�r partii, wygrane hrabstwa*/


with wielkosc as
(select party, round(avg(pop_2010_real_hr),  2) as �rednia_wielko��_populacji, count (*) as liczba_wygranych from
(select state, county,liczba_g�os�w_partia, party, pop_2010_real_hr,
dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking from
(select distinct state, county, party, 
sum(votes) as liczba_g�os�w_partia, 
pop_2010_real_hr
from dane_populacja dp 
group by party, county, pop_2010_real_hr, state
order by county)rkg)naj
where ranking = 1
group by  party),
zageszczenie as 
(select party, round(avg(zageszczenie_2010_hr),  2) as �rednia_zageszczenie_populacji, count (*) as liczba_wygranych from
(select state, county,liczba_g�os�w_partia, party, zageszczenie_2010_hr,
dense_rank () over (partition by county, state order by liczba_g�os�w_partia desc) as ranking from
(select distinct state, county, party, 
sum(votes) as liczba_g�os�w_partia, 
zageszczenie_2010_hr
from dane_populacja dp 
group by party, county, zageszczenie_2010_hr, state
order by county)rkg)naj
where ranking = 1
group by  party)
select wielkosc.party, �rednia_wielko��_populacji, �rednia_zageszczenie_populacji, wielkosc.liczba_wygranych
from wielkosc
join zageszczenie
on wielkosc.party = zageszczenie.party



-- badanie korelacji pomi�dzy g�osami populacji, a parti�

select party, 
corr(votes, pop_2010_real_hr) as korelacja_populacja_2010,
corr(votes, zageszczenie_2010_hr) as korelacja_zageszczenie_2010
from dane_populacja
group by party
order by corr(votes, pop_2010_real_hr) desc

-- badanie korelacji pomi�dzy g�osami populacji, a parti� - przeliczneie na stany
select party, state, corr(suma_g�os�w_stan, pop_2010_real_hr) as korelacja_liczebno��,
corr(suma_g�os�w_stan, zageszczenie_2010_hr) as korelacja_zageszczenie
from
(select distinct party, sum(votes) over (partition by party, county) as suma_g�os�w_stan, state, county, pop_2010_real_hr, zageszczenie_2010_hr
from dane_populacja
group by state, state, party, pop_2010_real_hr, votes, county, zageszczenie_2010_hr)x
group by party,state
order by corr(suma_g�os�w_stan, pop_2010_real_hr)  desc


--- dodatkowo ---

--WOE i IV dla populacji w 2010 roku -- w pzeliczeniu na stany

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/


select wielko��_stanu,  count(*) from /*OK*/
(select distinct state,
case when pop_2010_real_stan < 5000000 then '0 - 5 mln'
when pop_2010_real_stan < 10000000 then '5 - 10 mln'
when pop_2010_real_stan < 15000000 then '10 - 15 mln'
when pop_2010_real_stan < 20000000 then '15 - 20 mln'
when pop_2010_real_stan < 30000000 then '20 - 30 mln'
when pop_2010_real_stan < 40000000 then '30 - 40 mln'
else 'powy�ej 40 mln'
end as wielko��_stanu
from dane_populacja)x
group by wielko��_stanu

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_populacja_stan_ as
with rep as
(select distinct party, wielko��_stanu, sum(votes) over (partition by party, wielko��_stanu) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when pop_2010_real_stan < 5000000 then '0 - 5 mln'
when pop_2010_real_stan < 10000000 then '5 - 10 mln'
when pop_2010_real_stan < 15000000 then '10 - 15 mln'
when pop_2010_real_stan < 20000000 then '15 - 20 mln'
when pop_2010_real_stan < 30000000 then '20 - 30 mln'
when pop_2010_real_stan < 40000000 then '30 - 40 mln'
else 'powy�ej 40 mln'
end as wielko��_stanu
from dane_populacja
group by party, votes, pop_2010_real_stan
order by wielko��_stanu)m
where party = 'Republican'),
dem as
(select distinct party, wielko��_stanu, sum(votes) over (partition by party, wielko��_stanu) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when pop_2010_real_stan < 5000000 then '0 - 5 mln'
when pop_2010_real_stan < 10000000 then '5 - 10 mln'
when pop_2010_real_stan < 15000000 then '10 - 15 mln'
when pop_2010_real_stan < 20000000 then '15 - 20 mln'
when pop_2010_real_stan < 30000000 then '20 - 30 mln'
when pop_2010_real_stan < 40000000 then '30 - 40 mln'
else 'powy�ej 40 mln'
end as wielko��_stanu
from dane_populacja
group by party, votes, pop_2010_real_stan
order by wielko��_stanu)m
where party = 'Democrat')
select rep.wielko��_stanu, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.wielko��_stanu = dem.wielko��_stanu



select *
from v_iv_populacja_stan_ ;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_populacja_stan_ /*s�aby predyktor - 0.093 - brak dalszej analizy*/


-- zag�szczenie -- stany --

--WOE i IV dla zag�szczenia w 2010 roku --

/* sprawdzenie ile wynik�w b�dzie w danej grupie*/


select zag�szczenie_stanu, count(*) from
(select distinct state,
case when zageszczenie_2010_stan < 50 then '0 - 50'
when zageszczenie_2010_stan < 100 then '50 - 100'
when zageszczenie_2010_stan < 150 then '100 - 150'
when zageszczenie_2010_stan < 200 then '150 - 200'
when zageszczenie_2010_stan < 500 then '200 - 500'
when zageszczenie_2010_stan < 1000 then '500 - 1000'
else '1000 +'
end as zag�szczenie_stanu
from dane_populacja)x
group by zag�szczenie_stanu

/*przygotowanie danych do obliczenia WOE i IV*/
create view v_iv_zageszczenie_stan_ as
with rep as
(select distinct party, zag�szczenie_stanu, sum(votes) over (partition by party, zag�szczenie_stanu) as liczba_g�_republikanie,
sum (votes) over (partition by party) as suma_ca�kowita_partia_rep from
(select party, votes, 
case when zageszczenie_2010_stan < 50 then '0 - 50'
when zageszczenie_2010_stan < 100 then '50 - 100'
when zageszczenie_2010_stan < 150 then '100 - 150'
when zageszczenie_2010_stan < 200 then '150 - 200'
when zageszczenie_2010_stan < 500 then '200 - 500'
when zageszczenie_2010_stan < 1000 then '500 - 1000'
else '1000 +'
end as zag�szczenie_stanu
from dane_populacja
group by party, votes, zageszczenie_2010_stan
order by zag�szczenie_stanu)m
where party = 'Republican'),
dem as
(select distinct party, zag�szczenie_stanu, sum(votes) over (partition by party, zag�szczenie_stanu) as liczba_g�_demokraci,
sum (votes) over (partition by party) as suma_ca�kowita_partia_dem from
(select party, votes, 
case when zageszczenie_2010_stan < 50 then '0 - 50'
when zageszczenie_2010_stan < 100 then '50 - 100'
when zageszczenie_2010_stan < 150 then '100 - 150'
when zageszczenie_2010_stan < 200 then '150 - 200'
when zageszczenie_2010_stan < 500 then '200 - 500'
when zageszczenie_2010_stan < 1000 then '500 - 1000'
else '1000 +'
end as zag�szczenie_stanu
from dane_populacja
group by party, votes, zageszczenie_2010_stan
order by zag�szczenie_stanu)m
where party = 'Democrat')
select rep.zag�szczenie_stanu, liczba_g�_republikanie, liczba_g�_demokraci,
round(liczba_g�_republikanie/suma_ca�kowita_partia_rep, 3) as distribution_rep_dr,
round(liczba_g�_demokraci/suma_ca�kowita_partia_dem, 3) as distribution_dem_dd,
ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as WOE,
round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3) as dd_dr,
(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3) - round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) * ln(round(liczba_g�_demokraci/suma_ca�kowita_partia_rep, 3)/round(liczba_g�_republikanie/suma_ca�kowita_partia_dem, 3)) as dd_dr_woe
from rep
join dem
on rep.zag�szczenie_stanu = dem.zag�szczenie_stanu


select *
from v_iv_zageszczenie_stan_;
select sum(dd_dr_woe) as information_value /*wyliczenie IV*/
from v_iv_zageszczenie_stan_ /*�redni predyktor - 0.204*/


-- wykaz stan�w -- 

with stany as
(select  state, party, zag�szczenie_stanu from
(select  distinct state, party,
case when zageszczenie_2010_stan < 50 then '0 - 50'
when zageszczenie_2010_stan < 100 then '50 - 100'
when zageszczenie_2010_stan < 150 then '100 - 150'
when zageszczenie_2010_stan < 200 then '150 - 200'
when zageszczenie_2010_stan < 500 then '200 - 500'
when zageszczenie_2010_stan < 1000 then '500 - 1000'
else '1000 +'
end as zag�szczenie_stanu
from dane_populacja)x) 
select  state, party, stany.zag�szczenie_stanu,
liczba_g�_republikanie, liczba_g�_demokraci
from stany
join v_iv_zageszczenie_stan vis
on stany.zag�szczenie_stanu = vis.zag�szczenie_stanu /*poprawne*/

-- hrabstwa vs wielko�� vs zag�szczenie --

select state, county, party, pop_2010_real_hr, zageszczenie_2010_hr,
sum(votes) as liczba_glosow
from dane_populacja dp 
where party = 'Republican'
group by state, county, party, pop_2010_real_hr, zageszczenie_2010_hr

select state, county, party, pop_2010_real_hr, zageszczenie_2010_hr,
sum(votes) as liczba_glosow
from dane_populacja dp 
where party = 'Democrat'
group by state, county, party, pop_2010_real_hr, zageszczenie_2010_hr



