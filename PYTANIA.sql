-- 1. Wyznacz ranking na pracownika miesiąca dla każdego miesiąca, w którym sklep prowadził sprzedaż. -----------
SET lc_time_names = 'pl_PL'; ##to sprawia że mamy miesiące po polsku więc proszę to zostawić

SELECT id_pracownika, imię_pracownika, nazwisko_pracownika, DATE_FORMAT(data_wynajmu, '%M') AS miesiąc, YEAR(data_wynajmu) AS rok, SUM(cena_wynajem) AS "przychód - wynajem"
FROM wynajem
LEFT JOIN pracownicy USING(id_pracownika)
GROUP BY id_pracownika, DATE_FORMAT(data_wynajmu, '%M'), YEAR(data_wynajmu)
ORDER BY YEAR(data_wynajmu), MONTH(data_wynajmu), SUM(cena_wynajem) DESC;

SELECT id_pracownika, imię_pracownika, nazwisko_pracownika,  DATE_FORMAT(data_zakupu, '%M') AS miesiąc, YEAR(data_zakupu) AS rok, SUM(cena_kupno) AS "przychód - sprzedaż"
FROM sklep
LEFT JOIN pracownicy USING(id_pracownika)
GROUP BY id_pracownika,  DATE_FORMAT(data_zakupu, '%M'), YEAR(data_zakupu)
ORDER BY YEAR(data_zakupu), MONTH(data_zakupu), SUM(cena_kupno) DESC;

SELECT id_pracownika, imię_pracownika, nazwisko_pracownika, DATE_FORMAT(data_zakupu, '%M') AS miesiąc, YEAR(data_zakupu) AS rok, SUM(cena_outlet) AS "przychód - outlet"
FROM outlet
LEFT JOIN pracownicy USING(id_pracownika)
GROUP BY id_pracownika, DATE_FORMAT(data_zakupu, '%M'), YEAR(data_zakupu)
ORDER BY YEAR(data_zakupu), MONTH(data_zakupu), SUM(cena_outlet) DESC;


-- łącznie 
WITH sss AS (

SELECT id_pracownika, DATE_FORMAT(data_wynajmu, '%M') AS miesiąc,  YEAR(data_wynajmu) AS rok, SUM(cena_wynajem) AS "przychód", "WYNAJEM", MONTH(data_wynajmu) AS msc
FROM wynajem
GROUP BY id_pracownika, DATE_FORMAT(data_wynajmu, '%M'),  YEAR(data_wynajmu)

UNION ALL

SELECT id_pracownika, DATE_FORMAT(data_zakupu, '%M') AS miesiąc,  YEAR(data_zakupu) AS rok, SUM(cena_kupno) AS "przychód", "KUPNO", MONTH(data_zakupu) AS msc
FROM sklep
GROUP BY id_pracownika, DATE_FORMAT(data_zakupu, '%M'),  YEAR(data_zakupu)

UNION ALL

SELECT id_pracownika, DATE_FORMAT(data_zakupu, '%M') AS miesiąc,  YEAR(data_zakupu) AS rok, SUM(cena_outlet) AS "przychód", "OUTLET", MONTH(data_zakupu) AS msc
FROM outlet
GROUP BY id_pracownika, DATE_FORMAT(data_zakupu, '%M'),  YEAR(data_zakupu)
)

SELECT id_pracownika, imię_pracownika, nazwisko_pracownika, miesiąc, msc, rok, SUM(przychód) AS "przychody"
FROM sss
JOIN pracownicy USING(id_pracownika)
GROUP BY id_pracownika, miesiąc, rok
ORDER BY rok, msc, SUM(przychód) DESC;

-- 2. Najlepsi gracze w poszczególnych turniejach (top 10)

-- SELECT id_klienta, imię, nazwisko, SUM(wynik), id_rodzaj
-- FROM wyniki
-- INNER JOIN klienci USING(id_klienta)
-- INNER JOIN turnieje USING(id_turniej)
-- GROUP BY id_rodzaj, id_klienta
-- ORDER BY SUM(wynik) DESC

-- SELECT id_klienta, wynik, id_rodzaj
-- from wyniki
-- INNER JOIN turnieje USING(id_turniej)
-- WHERE id_klienta = "1836"

-- patrzę po wszystkich turniejach osobno

-- "Alchemicy"
SELECT id_klienta, imię, nazwisko, wiek, SUM(wynik) AS wynik, tytuł
FROM wyniki
INNER JOIN klienci USING(id_klienta)
INNER JOIN turnieje USING(id_turniej)
INNER JOIN rodzaje_turniejów USING(id_rodzaj)
INNER JOIN gry USING(id_gry)
WHERE id_rodzaj = "1"
GROUP BY id_klienta
ORDER BY wynik DESC
LIMIT 10;

-- "Palec Boży"
SELECT id_klienta, imię, nazwisko, wiek, SUM(wynik) AS wynik, tytuł
FROM wyniki
INNER JOIN klienci USING(id_klienta)
INNER JOIN turnieje USING(id_turniej)
INNER JOIN rodzaje_turniejów USING(id_rodzaj)
INNER JOIN gry USING(id_gry)
WHERE id_rodzaj = "2"
GROUP BY id_klienta
ORDER BY wynik DESC
LIMIT 10;

-- "Wsiąść do pociągu"
SELECT id_klienta, imię, nazwisko, wiek, SUM(wynik) AS wynik, tytuł
FROM wyniki
INNER JOIN klienci USING(id_klienta)
INNER JOIN turnieje USING(id_turniej)
INNER JOIN rodzaje_turniejów USING(id_rodzaj)
INNER JOIN gry USING(id_gry)
WHERE id_rodzaj = "3"
GROUP BY id_klienta
ORDER BY wynik DESC
LIMIT 10;

-- "Carcassone"
SELECT id_klienta, imię, nazwisko, wiek, SUM(wynik) AS wynik, tytuł
FROM wyniki
INNER JOIN klienci USING(id_klienta)
INNER JOIN turnieje USING(id_turniej)
INNER JOIN rodzaje_turniejów USING(id_rodzaj)
INNER JOIN gry USING(id_gry)
WHERE id_rodzaj = "4"
GROUP BY id_klienta
ORDER BY wynik DESC
LIMIT 10;

-- "Scrabble"
SELECT id_klienta, imię, nazwisko, wiek, SUM(wynik) AS wynik, tytuł
FROM wyniki
INNER JOIN klienci USING(id_klienta)
INNER JOIN turnieje USING(id_turniej)
INNER JOIN rodzaje_turniejów USING(id_rodzaj)
INNER JOIN gry USING(id_gry)
WHERE id_rodzaj = "5"
GROUP BY id_klienta
ORDER BY wynik DESC
LIMIT 10;


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
JOIN gry USING(id_gry)
JOIN ilość USING(id_gry)
GROUP BY id_gry
ORDER BY SUM(cena_wynajem)/ile_gier/cena_wynajem DESC;


WITH ilość AS (SELECT id_gry, COUNT(id_gry) AS "ile_gier_inv"
					FROM spichlerz_sklep
					GROUP BY id_gry)

SELECT id_gry, tytuł,  COUNT(id_transakcji_sklep) AS "ile_gier_zakup", ile_gier_inv, 
			SUM(cena_kupno) AS "dochód gry sklep",ROUND(SUM(cena_kupno)/ile_gier_inv, 2) AS "średni dochód gry sklep", 
			ROUND(SUM(cena_kupno)/ile_gier_inv/cena_kupno, 2) AS "znormalizowany średni dochód"
FROM sklep
LEFT JOIN spichlerz_sklep USING(id_spichlerz_sklep)
JOIN gry USING(id_gry)
JOIN ilość USING(id_gry)
GROUP BY id_gry
ORDER BY SUM(cena_kupno)/ile_gier_inv/cena_kupno DESC;

-- dla outletu zwykła suma? (a tutaj to trzeba ogarnąć jeszcze)
SELECT id_gry, tytuł, SUM(cena_outlet), COUNT(id_transakcji_outlet)
FROM outlet
JOIN spichlerz_wynajem USING(id_spichlerz_wynajem)
JOIN gry USING(id_gry)
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

-- ogólnie:

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
-- REPLACE REPLACE REPLACE REPLACE REPLACE REPLACE REPLACE REPLACE

SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(adres, "0", ""), "1", ""), "2", ""), "3", ""), "4", ""), "5", ""), "6", ""), "7", ""), "8", ""), "9", "") as ulica, COUNT(*) as zakupione_gry, SUM(cena_kupno) wydane_$
FROM sklep 
INNER JOIN klienci 
USING(id_klienta)
WHERE adres NOT LIKE "NULL"
GROUP BY ulica
ORDER BY zakupione_gry DESC;

SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(adres, "0", ""), "1", ""), "2", ""), "3", ""), "4", ""), "5", ""), "6", ""), "7", ""), "8", ""), "9", "") as ulica, COUNT(*) as wypożyczone_gry, SUM(cena_wynajem) wydane_$
FROM wynajem 
INNER JOIN klienci 
USING(id_klienta)
WHERE adres NOT LIKE "NULL"
GROUP BY ulica
ORDER BY wypożyczone_gry DESC;

-- TOP 3 DNI Z NAJCZĘSTSZYMI ODWIEDZIAMI (kupno+wynajem+outlet)

WITH ulsko AS (
SELECT COUNT(*) as ilość, DATE(data_zakupu) as dzień, SUM(cena_kupno) as przychód
FROM sklep
GROUP BY dzień

UNION ALL

SELECT COUNT(*) as ilość, DATE(data_wynajmu) as dzień, SUM(cena_wynajem) as przychód
FROM wynajem
GROUP BY dzień

UNION ALL

SELECT COUNT(*) as ilość, DATE(data_zakupu) as dzień, SUM(cena_outlet) as przychód
FROM outlet
GROUP BY dzień
)

SELECT dzień, SUM(ilość) as "ilość wizyt", DATE_FORMAT(dzień, '%W') AS dzień_tygodnia, SUM(przychód) as przychód
FROM ulsko
GROUP BY dzień
ORDER BY SUM(ilość) DESC
LIMIT 5;

-- i teraz dane do rozkładu - df z datą i ilością odwiedzin
WITH ulsko AS (
SELECT COUNT(*) as ilość, DATE(data_zakupu) as dzień, SUM(cena_kupno) as przychód
FROM sklep
GROUP BY dzień

UNION ALL

SELECT COUNT(*) as ilość, DATE(data_wynajmu) as dzień, SUM(cena_wynajem) as przychód
FROM wynajem
GROUP BY dzień

UNION ALL

SELECT COUNT(*) as ilość, DATE(data_zakupu) as dzień, SUM(cena_outlet) as przychód
FROM outlet
GROUP BY dzień
)

SELECT dzień, SUM(ilość) as "ilość wizyt", SUM(przychód) as przychód
FROM ulsko
GROUP BY dzień
ORDER BY dzień;

-- Podział na dni tygodnia - który dzień tygodnia najbardziej busy overall

WITH ulsko AS (
SELECT COUNT(*) as ilość, DATE(data_zakupu) as dzień, SUM(cena_kupno) as przychód
FROM sklep
GROUP BY dzień

UNION ALL

SELECT COUNT(*) as ilość, DATE(data_wynajmu) as dzień, SUM(cena_wynajem) as przychód
FROM wynajem
GROUP BY dzień

UNION ALL

SELECT COUNT(*) as ilość, DATE(data_zakupu) as dzień, SUM(cena_outlet) as przychód
FROM outlet
GROUP BY dzień
)

SELECT DATE_FORMAT(dzień, '%W') AS "dzień tygodnia", SUM(ilość) as "ilość wizyt", SUM(przychód) as przychód
FROM ulsko
GROUP BY DATE_FORMAT(dzień, '%W')
ORDER BY WEEKDAY(dzień);

-- Najpopularniejszy rodzaj (też osobno, ale może da się ładnie w jednym)

WITH grr AS(
	SELECT tytuł, COUNT(id_transakcji_sklep) as ilość
	FROM gry
	INNER JOIN spichlerz_sklep USING(id_gry)
	INNER JOIN sklep USING(id_spichlerz_sklep)
	GROUP BY tytuł

	UNION ALL

	SELECT tytuł, COUNT(id_transakcji_wynajem) as ilość
	FROM gry
	INNER JOIN spichlerz_wynajem USING(id_gry)
	INNER JOIN wynajem USING(id_spichlerz_wynajem)
	GROUP BY tytuł
)

-- Monopoly
SELECT tytuł, SUM(ilość) as "kupno+wynajem" FROM grr
WHERE tytuł LIKE "Monopoly%"
GROUP BY tytuł
ORDER BY SUM(ilość) DESC;

-- Dobble
WITH grr AS(
	SELECT tytuł, COUNT(id_transakcji_sklep) as ilość
	FROM gry
	INNER JOIN spichlerz_sklep USING(id_gry)
	INNER JOIN sklep USING(id_spichlerz_sklep)
	GROUP BY tytuł

	UNION ALL

	SELECT tytuł, COUNT(id_transakcji_wynajem) as ilość
	FROM gry
	INNER JOIN spichlerz_wynajem USING(id_gry)
	INNER JOIN wynajem USING(id_spichlerz_wynajem)
	GROUP BY tytuł
)

SELECT tytuł, SUM(ilość) as "kupno+wynajem" FROM grr
WHERE tytuł LIKE "Dobble%"
GROUP BY tytuł
ORDER BY SUM(ilość) DESC;

-- Wsiąść do pociągu
WITH grr AS(
	SELECT tytuł, COUNT(id_transakcji_sklep) as ilość
	FROM gry
	INNER JOIN spichlerz_sklep USING(id_gry)
	INNER JOIN sklep USING(id_spichlerz_sklep)
	GROUP BY tytuł

	UNION ALL

	SELECT tytuł, COUNT(id_transakcji_wynajem) as ilość
	FROM gry
	INNER JOIN spichlerz_wynajem USING(id_gry)
	INNER JOIN wynajem USING(id_spichlerz_wynajem)
	GROUP BY tytuł
)
SELECT tytuł, SUM(ilość) as "kupno+wynajem" FROM grr
WHERE tytuł LIKE "Wsiąść%"
GROUP BY tytuł
ORDER BY SUM(ilość) DESC;

-- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA - te średnie z serii

WITH grr AS(
	SELECT tytuł, COUNT(id_transakcji_sklep) as ilość
	FROM gry
	INNER JOIN spichlerz_sklep USING(id_gry)
	INNER JOIN sklep USING(id_spichlerz_sklep)
	GROUP BY tytuł

	UNION ALL

	SELECT tytuł, COUNT(id_transakcji_wynajem) as ilość
	FROM gry
	INNER JOIN spichlerz_wynajem USING(id_gry)
	INNER JOIN wynajem USING(id_spichlerz_wynajem)
	GROUP BY tytuł
)
SELECT CASE WHEN tytuł LIKE "Wsiąść%" THEN "Wsiąść do Pociągu" 
				WHEN tytuł LIKE "Monopoly%" THEN "Monopoly"
				WHEN tytuł LIKE "Dobble%" THEN "Dobble" 
				END AS seria, AVG(ilość)*2 AS średnia FROM grr
WHERE CASE WHEN tytuł LIKE "Wsiąść%" THEN "Wsiąść do Pociągu" 
			  WHEN tytuł LIKE "Monopoly%" THEN "Monopoly"
			  WHEN tytuł LIKE "Dobble%" THEN "Dobble" 
			  END NOT LIKE "NULL"
GROUP BY seria
ORDER BY średnia DESC;



