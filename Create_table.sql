DROP TABLE gra;
        
CREATE TABLE gra
(
  id_gry     INT   NOT NULL PRIMARY KEY UNIQUE AUTO_INCREMENT,
  tytuł      VARCHAR(255)  NOT NULL,
  rodzaj     VARCHAR(255)  NULL    ,
  cena       FLOAT NULL    ,
  czas_gry   INT   NULL    ,
  min_graczy INT   NULL    ,
  max_graczy INT   NULL    ,
  min_wiek   INT   NULL    ,
  turniejowe FLOAT NULL     
);

ALTER TABLE gra
  ADD CONSTRAINT UQ_tytuł UNIQUE (tytuł);

DROP TABLE klienci;

CREATE TABLE klienci
(
  id_klienta INT      NOT NULL PRIMARY KEY UNIQUE AUTO_INCREMENT,
  wizyta     DATETIME NULL    ,
  imię       VARCHAR(255)  NOT NULL,
  nazwisko   VARCHAR(255)  NOT NULL,
  wiek       INT      NOT NULL,
  ulica      VARCHAR(255)  NOT NULL,
  nr_domu    VARCHAR(255)  NULL    ,
  telefon    VARCHAR(255)     NULL    
);

DROP TABLE outlet;

CREATE TABLE outlet
(
  id_transakcji_outlet  INT      NOT NULL PRIMARY KEY  UNIQUE AUTO_INCREMENT,
  id_spichlerz_wynajem INT      NOT NULL,
  cena_outlet           FLOAT    NULL    ,
  wizyta                DATETIME NULL    ,
  id_klienta            INT      NOT NULL,
  id_pracownika         INT      NOT NULL
);

DROP TABLE pracownicy;

CREATE TABLE pracownicy
(
  id_pracownika INT     NOT NULL PRIMARY KEY  UNIQUE AUTO_INCREMENT,
  imię          VARCHAR(255) NOT NULL,
  nazwisko      VARCHAR(255) NOT NULL,
  wiek          INT     NOT NULL,
  adres         VARCHAR(255) NULL    ,
  telefon       INT         NULL,
  rola          VARCHAR(255) NULL    ,
  pensja        INT     NULL    
);

DROP TABLE rodzaj_turnieji;

CREATE TABLE rodzaj_turnieji
(
  id_rodzaj       INT NOT NULL PRIMARY KEY  UNIQUE AUTO_INCREMENT,
  id_gry          INT NOT NULL,
  średnia_punktów INT NULL    ,
  ilość_gier      INT NULL    ,
  max_graczy      INT NULL    ,
  min_graczy      INT NULL    
);

DROP TABLE spichlerz_outlet;

CREATE TABLE spichlerz_outlet
(
  id_outlet            INT NOT NULL PRIMARY KEY  UNIQUE AUTO_INCREMENT,
  id_spichlerz_wynajem INT NOT NULL ,
  data_zwrotu          DATETIME    NULL  
);

DROP TABLE spichlerz_sklep;

CREATE TABLE spichlerz_sklep
(
  id_spichlerz_sklep INT      NOT NULL PRIMARY KEY  UNIQUE AUTO_INCREMENT,
  id_gry            INT      NOT NULL,
  ostatni_update   DATETIME NULL    
);

DROP TABLE spichlerz_wynajem;

CREATE TABLE spichlerz_wynajem
(
  id_spichlerz_wynajem INT      NOT NULL PRIMARY KEY  UNIQUE AUTO_INCREMENT COMMENT 'finish him',
  id_gry               INT      NOT NULL,
  ostatni_update      DATETIME NULL   
);

DROP TABLE sklep;


CREATE TABLE sklep
(
  id_transakcji     INT      NOT NULL PRIMARY KEY  UNIQUE AUTO_INCREMENT,
  id_spicherz_sklep INT      NOT NULL,
  id_pracownika     INT      NOT NULL,
  id_klienta        INT      NOT NULL,
  czas_kupna        DATETIME NULL   
);

DROP TABLE turnieje;

CREATE TABLE turnieje
(
  id_turniej INT      NOT NULL PRIMARY KEY  UNIQUE AUTO_INCREMENT,
  id_rodzaj  INT      NOT NULL,
  data       DATE NULL   
);

DROP TABLE wynajem;

CREATE TABLE wynajem
(
  id_transakcji_wynajem INT   NOT NULL PRIMARY KEY  UNIQUE AUTO_INCREMENT,
  id_spichlerz_wynajem  INT   NOT NULL COMMENT 'finish him',
  cena_wynajem          FLOAT NULL    ,
  data_wynajmu          DATETIME  NULL    ,
  data_zwrotu           DATETIME  NULL    ,
  id_pracownika         INT   NOT NULL,
  id_klienta            INT   NOT NULL,
  zniszczona            FLOAT NULL  
);

DROP TABLE wyniki;

CREATE TABLE wyniki
(
  id_turniej     INT NOT NULL,
  id_klienta     INT NOT NULL,
  wynik          INT NULL    ,
  czas_rozgrywki INT NULL    
);
--  relacje, nie dotykać
ALTER TABLE spichlerz_wynajem
  ADD CONSTRAINT FK_gra_TO_spichlerz_wynajem
    FOREIGN KEY (id_gry)
    REFERENCES gra (id_gry);

ALTER TABLE spichlerz_sklep
  ADD CONSTRAINT FK_gra_TO_spichlerz_sklep
    FOREIGN KEY (id_gry)
    REFERENCES gra (id_gry);

-- bład
ALTER TABLE sklep
  ADD CONSTRAINT FK_klienici_TO_sklep
    FOREIGN KEY (id_klienta)
    REFERENCES klienci (id_klienta);

ALTER TABLE rodzaj_turnieji
  ADD CONSTRAINT FK_gra_TO_rodzaj_turnieji
    FOREIGN KEY (id_gry)
    REFERENCES gra (id_gry);

ALTER TABLE wyniki
  ADD CONSTRAINT FK_turnieje_TO_wyniki
    FOREIGN KEY (id_turniej)
    REFERENCES turnieje (id_turniej);

-- błąd
ALTER TABLE wyniki
  ADD CONSTRAINT FK_klienici_TO_wyniki
    FOREIGN KEY (id_klienta)
    REFERENCES klienci (id_klienta);

ALTER TABLE outlet
  ADD CONSTRAINT FK_klienici_TO_outlet
    FOREIGN KEY (id_klienta)
    REFERENCES klienci (id_klienta);

ALTER TABLE sklep
  ADD CONSTRAINT FK_pracownicy_TO_sklep
    FOREIGN KEY (id_sprzedawcy)
    REFERENCES pracownicy (id_pracownika);

ALTER TABLE sklep
  ADD CONSTRAINT FK_spichlerz_sklep_TO_sklep
    FOREIGN KEY (id_spicherz_sklep)
    REFERENCES spichlerz_sklep (id_spicherz_sklep);

ALTER TABLE outlet
  ADD CONSTRAINT FK_pracownicy_TO_outlet
    FOREIGN KEY (id_pracownika)
    REFERENCES pracownicy (id_pracownika);

ALTER TABLE wynajem
  ADD CONSTRAINT FK_spichlerz_wynajem_TO_wynajem
    FOREIGN KEY (id_spichlerz_wynajem)
    REFERENCES spichlerz_wynajem (id_spichlerz_wynajem);

ALTER TABLE wynajem
  ADD CONSTRAINT FK_pracownicy_TO_wynajem
    FOREIGN KEY (id_pracownika)
    REFERENCES pracownicy (id_pracownika);

ALTER TABLE wynajem
  ADD CONSTRAINT FK_klienici_TO_wynajem
    FOREIGN KEY (id_klienta)
    REFERENCES klienci (id_klienta);

ALTER TABLE spichlerz_outlet
  ADD CONSTRAINT FK_spichlerz_wynajem_TO_spichlerz_outlet
    FOREIGN KEY (id_spichlerz_wynajem)
    REFERENCES spichlerz_wynajem (id_spichlerz_wynajem);

ALTER TABLE outlet
  ADD CONSTRAINT FK_wynajem_TO_outlet
    FOREIGN KEY (id_transakcji_wynajem)
    REFERENCES wynajem (id_transakcji_wynajem);

ALTER TABLE turnieje
  ADD CONSTRAINT FK_rodzaj_turnieji_TO_turnieje
    FOREIGN KEY (id_rozdaj)
    REFERENCES rodzaj_turnieji (id_rodzaj);

        
      