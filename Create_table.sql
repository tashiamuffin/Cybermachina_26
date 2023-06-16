-- DROP TABLE gra;

        
CREATE TABLE gra
(
  id_gry           INT     NOT NULL AUTO_INCREMENT,
  tytuł            CHAR    NOT NULL,
  min_ilosc_graczy INT     NULL    ,
  max_ilosc_graczy INT     NULL    ,
  wiek             INT     NULL    ,
  cena             FLOAT   NULL    ,
  rodzaj           CHAR    NULL    ,
  turniejowa       BOOLEAN NULL     DEFAULT FALSE,
  PRIMARY KEY (id_gry)
);

ALTER TABLE gra
  ADD CONSTRAINT UQ_id_gry UNIQUE (id_gry);

ALTER TABLE gra
  ADD CONSTRAINT UQ_tytuł UNIQUE (tytuł);

CREATE TABLE klienici
(
  id_klienta INT     NOT NULL AUTO_INCREMENT,
  imie       CHAR    NOT NULL,
  nazwisko   CHAR    NOT NULL,
  wiek       INT     NOT NULL,
  adres      VARCHAR(255) NOT NULL,
  PRIMARY KEY (id_klienta)
);

ALTER TABLE klienici
  ADD CONSTRAINT UQ_id_klienta UNIQUE (id_klienta);

CREATE TABLE outlet
(
  id_outlet     INT      NOT NULL AUTO_INCREMENT,
  id_spichlerz  INT      NOT NULL COMMENT 'finish him',
  id_sprzedawcy INT      NOT NULL,
  id_klienta    INT      NOT NULL,
  czas_kupna    DATETIME NULL    ,
  kwota         FLOAT    NULL    ,
  PRIMARY KEY (id_outlet)
);

ALTER TABLE outlet
  ADD CONSTRAINT UQ_id_outlet UNIQUE (id_outlet);

CREATE TABLE rozgrywka
(
  id_rozgrywka INT      NOT NULL AUTO_INCREMENT,
  id_turnieju  INT      NOT NULL,
  kiedy        DATETIME NULL    ,
  PRIMARY KEY (id_rozgrywka)
);

ALTER TABLE rozgrywka
  ADD CONSTRAINT UQ_id_rozgrywka UNIQUE (id_rozgrywka);

CREATE TABLE sale
(
  id_sale           INT      NOT NULL AUTO_INCREMENT,
  id_spicherz_sklep INT      NOT NULL,
  id_sprzedawcy     INT      NOT NULL,
  id_klienta        INT      NOT NULL,
  czas_kupna        DATETIME NULL    ,
  PRIMARY KEY (id_sale)
);

ALTER TABLE sale
  ADD CONSTRAINT UQ_id_sale UNIQUE (id_sale);

CREATE TABLE spichlerz
(
  id_spichlerz    INT      NOT NULL AUTO_INCREMENT COMMENT 'finish him',
  id_gry          INT      NOT NULL,
  ilość           INT      NOT NULL,
  kompletna       BOOLEAN  NOT NULL DEFAULT TRUE COMMENT 'nie wiem jak nzwac ',
  turniejowa      BOOLEAN  NOT NULL DEFAULT TRUE,
  cena_wynajmu    FLOAT    NULL    ,
  ostatani_update DATETIME NULL    ,
  PRIMARY KEY (id_spichlerz)
);

ALTER TABLE spichlerz
  ADD CONSTRAINT UQ_id_spichlerz UNIQUE (id_spichlerz);

CREATE TABLE spichlerz_sklep
(
  id_spicherz_sklep INT      NOT NULL AUTO_INCREMENT,
  id_gry            INT      NOT NULL,
  ilość             INT      NULL    ,
  cena              FLOAT    NULL    ,
  ostatni_update   DATETIME NULL    ,
  PRIMARY KEY (id_spicherz_sklep)
);

ALTER TABLE spichlerz_sklep
  ADD CONSTRAINT UQ_id_spicherz_sklep UNIQUE (id_spicherz_sklep);

CREATE TABLE sprzedawcy
(
  id_sprzedawcy    INT     NOT NULL AUTO_INCREMENT,
  imie             CHAR    NOT NULL,
  nazwisko         CHAR    NOT NULL,
  wiek             INT     NOT NULL,
  adres            VARCHAR(255) NULL    ,
  rok_zatrudnienie DATE    NOT NULL,
  rok_odejścia     DATE    NULL    ,
  PRIMARY KEY (id_sprzedawcy)
);

ALTER TABLE sprzedawcy
  ADD CONSTRAINT UQ_id_sprzedawcy UNIQUE (id_sprzedawcy);

CREATE TABLE turnieje
(
  id_turnieju INT     NOT NULL AUTO_INCREMENT,
  id_gry      INT     NOT NULL,
  reguły      VARCHAR(255) NULL    ,
  PRIMARY KEY (id_turnieju)
);

ALTER TABLE turnieje
  ADD CONSTRAINT UQ_id_turnieju UNIQUE (id_turnieju);

CREATE TABLE wynajem
(
  id_wynaje     INT     NOT NULL AUTO_INCREMENT,
  id_spichlerz  INT     NOT NULL COMMENT 'finish him',
  id_klienta    INT     NOT NULL,
  id_sprzedawcy INT     NOT NULL,
  od_kiedy      DATE    NULL    ,
  do_kiedy      DATE    NULL    ,
  usterki       BOOLEAN NULL     DEFAULT FALSE,
  kwota         FLOAT   NULL    ,
  PRIMARY KEY (id_wynaje)
);

ALTER TABLE wynajem
  ADD CONSTRAINT UQ_id_wynaje UNIQUE (id_wynaje);

CREATE TABLE wyniki
(
  id_rozgrywka INT   NOT NULL,
  id_klienta   INT   NOT NULL,
  wynik        FLOAT NULL    ,
  start        TIME  NULL    ,
  koniec       TIME  NULL    
);

ALTER TABLE spichlerz
  ADD CONSTRAINT FK_gra_TO_spichlerz
    FOREIGN KEY (id_gry)
    REFERENCES gra (id_gry);

ALTER TABLE wynajem
  ADD CONSTRAINT FK_klienici_TO_wynajem
    FOREIGN KEY (id_klienta)
    REFERENCES klienici (id_klienta);

ALTER TABLE wynajem
  ADD CONSTRAINT FK_sprzedawcy_TO_wynajem
    FOREIGN KEY (id_sprzedawcy)
    REFERENCES sprzedawcy (id_sprzedawcy);

ALTER TABLE spichlerz_sklep
  ADD CONSTRAINT FK_gra_TO_spichlerz_sklep
    FOREIGN KEY (id_gry)
    REFERENCES gra (id_gry);

ALTER TABLE sale
  ADD CONSTRAINT FK_klienici_TO_sale
    FOREIGN KEY (id_klienta)
    REFERENCES klienici (id_klienta);

ALTER TABLE turnieje
  ADD CONSTRAINT FK_gra_TO_turnieje
    FOREIGN KEY (id_gry)
    REFERENCES gra (id_gry);

ALTER TABLE rozgrywka
  ADD CONSTRAINT FK_turnieje_TO_rozgrywka
    FOREIGN KEY (id_turnieju)
    REFERENCES turnieje (id_turnieju);

ALTER TABLE wyniki
  ADD CONSTRAINT FK_rozgrywka_TO_wyniki
    FOREIGN KEY (id_rozgrywka)
    REFERENCES rozgrywka (id_rozgrywka);

ALTER TABLE wyniki
  ADD CONSTRAINT FK_klienici_TO_wyniki
    FOREIGN KEY (id_klienta)
    REFERENCES klienici (id_klienta);

ALTER TABLE outlet
  ADD CONSTRAINT FK_klienici_TO_outlet
    FOREIGN KEY (id_klienta)
    REFERENCES klienici (id_klienta);

ALTER TABLE sale
  ADD CONSTRAINT FK_sprzedawcy_TO_sale
    FOREIGN KEY (id_sprzedawcy)
    REFERENCES sprzedawcy (id_sprzedawcy);

ALTER TABLE sale
  ADD CONSTRAINT FK_spichlerz_sklep_TO_sale
    FOREIGN KEY (id_spicherz_sklep)
    REFERENCES spichlerz_sklep (id_spicherz_sklep);

ALTER TABLE outlet
  ADD CONSTRAINT FK_sprzedawcy_TO_outlet
    FOREIGN KEY (id_sprzedawcy)
    REFERENCES sprzedawcy (id_sprzedawcy);

ALTER TABLE outlet
  ADD CONSTRAINT FK_spichlerz_TO_outlet
    FOREIGN KEY (id_spichlerz)
    REFERENCES spichlerz (id_spichlerz);

ALTER TABLE wynajem
  ADD CONSTRAINT FK_spichlerz_TO_wynajem
    FOREIGN KEY (id_spichlerz)
    REFERENCES spichlerz (id_spichlerz);

        
      