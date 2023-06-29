-- 1. Wyznacz ranking na pracownika miesiąca dla każdego miesiąca, w którym sklep prowadził sprzedaż. -----------

SELECT id_pracownika, imię_pracownika, nazwisko_pracownika, MONTH(data_wynajmu), SUM(cena_wynajem) AS "przychód - wynajem"
FROM wynajem
LEFT JOIN pracownicy USING(id_pracownika)
GROUP BY id_pracownika, MONTH(data_wynajmu)
ORDER BY MONTH(data_wynajmu), SUM(cena_wynajem) DESC;

SELECT id_pracownika, imię_pracownika, nazwisko_pracownika, MONTH(wizyta), SUM(cena_kupno) AS "przychód - sprzedaż"
FROM sklep
LEFT JOIN pracownicy USING(id_pracownika)
GROUP BY id_pracownika, MONTH(wizyta)
ORDER BY MONTH(wizyta), SUM(cena_kupno) DESC;

SELECT id_pracownika, imię_pracownika, nazwisko_pracownika, MONTH(wizyta), SUM(cena_outlet) AS "przychód - outlet"
FROM outlet
LEFT JOIN pracownicy USING(id_pracownika)
GROUP BY id_pracownika, MONTH(wizyta)
ORDER BY MONTH(wizyta), SUM(cena_outlet) DESC;


-- łącznie 
WITH sss AS (

SELECT id_pracownika, MONTH(data_wynajmu) AS miesiąc, SUM(cena_wynajem) AS "przychód", "WYNAJEM"
FROM wynajem
GROUP BY id_pracownika, MONTH(data_wynajmu)

UNION ALL

SELECT id_pracownika, MONTH(data_zakupu) AS miesiąc, SUM(cena_kupno) AS "przychód", "KUPNO"
FROM sklep
GROUP BY id_pracownika, MONTH(data_zakupu)

UNION ALL

SELECT id_pracownika, MONTH(data_zakupu) AS miesiąc, SUM(cena_outlet) AS "przychód", "OUTLET"
FROM outlet
GROUP BY id_pracownika, MONTH(data_zakupu)
)

SELECT id_pracownika, imię_pracownika, nazwisko_pracownika, miesiąc, SUM(przychód) AS "przychody"
FROM sss
JOIN pracownicy USING(id_pracownika)
GROUP BY id_pracownika, miesiąc
ORDER BY miesiąc, SUM(przychód) DESC;

-- 2. te turnieje coś tam (work in progress)

-- cisowianka

-- 3. Ustal, które gry przynoszą największy dochód ze sprzedaży, a które z wypożyczeń. --------------
-- just suma po tytule gry
-- i teeż średni przychód względem ilości gier w inventory
-- liczę sobie ile jest gier w spichlerzu i robię średni dochód na grę

WITH ilość AS (SELECT id_gry, COUNT(id_gry) AS "ile_gier"
					FROM spichlerz_wynajem
					GROUP BY id_gry)

SELECT id_gry, tytuł, COUNT(id_transakcji_wynajem) AS "ile_gier_wynajem", SUM(cena_wynajem) AS "dochód gry wynajem", 
			ile_gier, ROUND(SUM(cena_wynajem)/ile_gier, 2) AS "średni dochód gry wynajem",
			ROUND(SUM(cena_wynajem)/ile_gier/cena_wynajem, 2) AS "znormalizowany średni dochód"
FROM wynajem
LEFT JOIN spichlerz_wynajem USING(id_spichlerz_wynajem)
JOIN gra USING(id_gry)
JOIN ilość USING(id_gry)
GROUP BY id_gry
ORDER BY SUM(cena_wynajem)/ile_gier/cena_wynajem DESC;


-- SELECT id_gry, tytuł, SUM(cena_kupno) AS "dochód gry sklep", COUNT(id_gry)
-- FROM sklep
-- LEFT JOIN spichlerz_sklep USING(id_spichlerz_sklep)
-- JOIN gry USING(id_gry)
-- GROUP BY id_gry
-- ORDER BY SUM(cena_kupno) DESC;

WITH ilość AS (SELECT id_gry, COUNT(id_gry) AS "ile_gier_inv"
					FROM spichlerz_sklep
					GROUP BY id_gry)

SELECT id_gry, tytuł,  COUNT(id_transakcji_sklep) AS "ile_gier_zakup", ile_gier_inv, 
			SUM(cena_kupno) AS "dochód gry sklep",ROUND(SUM(cena_kupno)/ile_gier_inv, 2) AS "średni dochód gry sklep", 
			ROUND(SUM(cena_kupno)/ile_gier_inv/cena_kupno, 2) AS "znormalizowany średni dochód"
FROM sklep
LEFT JOIN spichlerz_sklep USING(id_spichlerz_sklep)
JOIN gra USING(id_gry)
JOIN ilość USING(id_gry)
GROUP BY id_gry
ORDER BY SUM(cena_kupno)/ile_gier_inv/cena_kupno DESC;

-- dla outletu zwykła suma? (a tutaj to trzeba ogarnąć jeszcze)
SELECT id_gry, tytuł, SUM(cena_outlet), COUNT(id_transakcji_outlet)
FROM outlet
JOIN gra USING(id_gry)
GROUP BY id_gry
ORDER BY SUM(cena_outlet) DESC;


-- PROPOZYCJE DODATKOWYCH PYTAŃ KTÓRYMI MOŻNA SIĘ POBAWIĆ ------------------------------
-- kto wydał u nas najwięcej pieniędzy - kupując, wynajmując i łącznie
SELECT id_klienta, imię, nazwisko, wiek, SUM(cena_wynajem), COUNT(id_transakcji_wynajem)
FROM wynajem
LEFT JOIN klienci USING(id_klienta)
GROUP BY id_klienta
ORDER BY SUM(cena_wynajem) DESC
LIMIT 10;

SELECT id_klienta, imię, nazwisko, wiek, adres, SUM(cena_kupno), COUNT(id_transakcji_sklep)
FROM sklep
LEFT JOIN klienci USING(id_klienta)
GROUP BY id_klienta
ORDER BY SUM(cena_kupno) DESC
LIMIT 10;

SELECT id_klienta, imię, nazwisko, wiek, SUM(cena_outlet), COUNT(id_transakcji_outlet)
FROM outlet
LEFT JOIN klienci USING(id_klienta)
GROUP BY id_klienta
ORDER BY SUM(cena_outlet) DESC
LIMIT 10;

SELECT *
FROM sklep
WHERE id_klienta IN (3671, 3772, 3936); -- żeby nie bylo że ci adamczykowie to stinky cheese jest XD


-- ogólnie:
-- tutaj sobie sprawdzam czy pan czesław faktycznie kupił coś ze sklepu, z outletu i wynajął i czy ceny się zgadzają
SELECT id_klienta, imię, nazwisko, wiek, SUM(cena_wynajem), COUNT(id_transakcji_wynajem)
FROM wynajem
LEFT JOIN klienci USING(id_klienta)
WHERE id_klienta = 2360
GROUP BY id_klienta;

SELECT id_klienta, imię, nazwisko, wiek, SUM(cena_outlet), COUNT(id_transakcji_outlet)
FROM outlet
LEFT JOIN klienci USING(id_klienta)
WHERE id_klienta = 2360
GROUP BY id_klienta;

SELECT id_klienta, imię, nazwisko, wiek, SUM(cena_kupno), COUNT(id_transakcji_sklep)
FROM sklep
LEFT JOIN klienci USING(id_klienta)
WHERE id_klienta = 2360
GROUP BY id_klienta;

-- ogólna funkcja (czyli w sumie tylko to nas interesuje)
WITH aaa AS (
SELECT id_klienta, imię, nazwisko, wiek, SUM(cena_outlet) AS "suma_trans", COUNT(id_transakcji_outlet) AS "ilość_trans", "OUTLET"
FROM outlet
LEFT JOIN klienci USING(id_klienta)
GROUP BY id_klienta

UNION ALL

SELECT id_klienta, imię, nazwisko, wiek, SUM(cena_wynajem) AS "suma_trans", COUNT(id_transakcji_wynajem) AS "ilość_trans", "WYNAJEM"
FROM wynajem
LEFT JOIN klienci USING(id_klienta)
GROUP BY id_klienta

UNION ALL

SELECT id_klienta, imię, nazwisko, wiek, SUM(cena_kupno) AS "suma_trans", COUNT(id_transakcji_sklep) AS "ilość_trans", "KUPNO"
FROM sklep
LEFT JOIN klienci USING(id_klienta)
GROUP BY id_klienta
)

SELECT id_klienta, imię, nazwisko, wiek, COUNT(*) AS "outlet+wynajem+kupno", SUM(suma_trans) AS "łącznie"
FROM aaa
GROUP BY id_klienta
ORDER BY łącznie DESC
LIMIT 20;

-- Mieszkańcy której ulicy najczęściej wypożyczali, a której najczęściej kupowali nasze gry?
-- tu będzie jeszcze kombinowanie z tymi ulicami żeby mogło być w 1 kolumnie

SELECT ulica, COUNT(*) as zakupione_gry, SUM(cena_kupno) wydane_$
FROM sklep 
INNER JOIN klienci 
USING(id_klienta)
WHERE ulica NOT LIKE "NULL"
GROUP BY ulica
ORDER BY zakupione_gry DESC;

SELECT ulica, COUNT(*) as wypożyczone_gry, SUM(cena_wynajem) wydane_$
FROM wynajem 
INNER JOIN klienci 
USING(id_klienta)
WHERE ulica NOT LIKE "NULL"
GROUP BY ulica
ORDER BY wydane_$ DESC;

-- TOP 3 DNI Z NAJCZĘSTSZYMI ODWIEDZIAMI (kupno+wynajem+outlet)

WITH ulsko AS (
SELECT COUNT(*) as ilość, DATE(wizyta) as dzień, SUM(cena_kupno) as przychód
FROM sklep
GROUP BY dzień

UNION ALL

SELECT COUNT(*) as ilość, DATE(data_wynajmu) as dzień, SUM(cena_wynajem) as przychód
FROM wynajem
GROUP BY dzień

UNION ALL

SELECT COUNT(*) as ilość, DATE(wizyta) as dzień, SUM(cena_outlet) as przychód
FROM outlet
GROUP BY dzień
)

SELECT dzień, SUM(ilość) as "ilość wizyt", SUM(przychód) as przychód
FROM ulsko
GROUP BY dzień
ORDER BY SUM(ilość) DESC
LIMIT 3;

-- Podział na dni tygodnia ??? (gówno jakieś to na razie jest)

WITH ulsko AS (
SELECT COUNT(wizyta), DATE(wizyta) as den, WEEKDAY(wizyta) as den_tygodnia
FROM sklep
GROUP BY den;

UNION ALL

SELECT COUNT(DISTINCT id_klienta), WEEKDAY(data_wynajmu) as den
FROM wynajem
GROUP BY den;

UNION ALL

SELECT COUNT(wizyta), DATE(wizyta) as den
FROM outlet
GROUP BY den

-- TU BĘDZIE JESZCZE 1 PYTANIE (albo więcej bo czemu nie)
-- najczęściej wypożyczana gra (tytuł)/ egzemplarz gry, najczęściej niszczona gra/egzemplarz
-- coś z outletem - najczęściej pojawiająca się tam gra czyli w sumie najczęściej niszczona) - może jaki rodzaj gry
-- które serie gier zarabiają dla nas najwięcej (średnio)/ są najczęściej wypożyczane
-- coś z rodzajami gier (ten outlet?)
-- jakaś analiza wieku - rozkład wieku klientów? XD
