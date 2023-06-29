import pandas as pd
import numpy as np
import random
import matplotlib.pyplot as plt
import datetime
from sqlalchemy import create_engine, inspect
from sqlalchemy import URL
from sqlalchemy import text


t = 10000 ##żeby wykluczyć mało znane imiona i nazwiska

##imiona męskie i kobiece
im = pd.read_csv("IM.csv")
im = im[im["LICZBA WYSTĄPIEŃ"] > t] 
ik = pd.read_csv("IK.csv")
ik = ik[ik["LICZBA_WYSTĄPIEŃ"] > t]
ik = ik["IMIĘ_PIERWSZE"]
im = im["IMIĘ PIERWSZE"]

##nazwiska męskie i kobiece
nm = pd.read_csv("NM.csv")
nm = nm[nm["Liczba"] > t]
nk = pd.read_csv("NK.csv")
nk = nk[nk["Liczba"] > t]
nk = nk["Nazwisko aktualne"]
nm = nm["Nazwisko aktualne"]

ulice = pd.read_csv("ULIC.csv", sep=";")
ulice_jaworze = ulice.query('WOJ == 24 & POW == 2 & GMI == 6 & RODZ_GMI == 2') ##bo kod terytorialny jaworza to 24.2.6.2
ulice_jaworze = np.array(ulice_jaworze["NAZWA_1"]) ##i bierzemy ulice

##gry
gry = pd.read_csv("GRY.csv")
gry = gry.rename(columns={"ID":"id_gry", "NAZWA":"tytuł", "RODZAJ":"rodzaj", "CENA":"cena", "CZAS_GRY":"czas_gry", 
                         "MIN_GRACZY":"min_graczy", "MAX_GRACZY":"max_graczy", "MIN_WIEK":"min_wiek", "TURNIEJOWE":"turniejowe"})

def ludzie(mi, ki, mn, kn, ul, pk= 0.516, N=7349 ):
    """
    Funkcja do generowania ludności z Jaworza
    pk = 0.516 - procent kobiet w społeczeństwie
    N = 7349 - (w miarę) aktualny stan ludności w tej urokliwej wsi
    
    """
    
    imie = []
    nazwisko = []
    wiek = []
    adres = []
    tel = []
    
    for n in range(N):
        
        p = random.random()
        
        if p < pk: ##losujemy kobietę
            imie.append(random.choice(ki).title()) ##title z AAAA robi Aaaa (a taką formę imion mamy)
            nazwisko.append(random.choice(kn).title())
        
        else: #losujemy mężczyznę
            imie.append(random.choice(mi).title())
            nazwisko.append(random.choice(mn).title())
        
        p = random.random()
        
        if p < 0.575: ##dane statystyczne - 57.5% osób jest w wieku produkcyjnym
            wiek.append(random.randint(18,60))
        elif p < 0.77:
            wiek.append(random.randint(8, 18)) ##19.4% w przedprodukcyjnym
        else:
            wiek.append(random.randint(60,99)) ##reszta starsza
            
            
        p = random.random()   
        if p< 0.90:
            adres.append(random.choice(ul) + " " + str(random.randint(1,100)))
            
            p = random.random()
            if p< 0.90:
                tel.append(random.randint(500000000, 999999999))
            else:
                tel.append("NULL")
                
        else:
            adres.append("NULL")
            tel.append(random.randint(500000000, 999999999))
    
    return pd.DataFrame({"id_mieszkańca": range(1,N+1), "imię": imie, "nazwisko": nazwisko, 
                         "wiek": wiek, "adres": adres, "telefon": tel})

def transform_wiek(wiek): 
    """
    Funkcja zwracająca częstość z jaką dana osoba na podstawie wieku mogłaby nas odwiedzać. 
    Im większa wartość tym większe prawdopodobieństwo wizyty.
    
    """
    
    if wiek < 10:
        return 1
    elif wiek < 12:
        return 2
    elif wiek < 16:
        return 3
    elif wiek < 20:
        return 5
    elif wiek < 30:
        return 6
    elif wiek < 38:
        return 5
    elif wiek < 45:
        return 4
    elif wiek < 55:
        return 3
    elif wiek < 70:
        return 2
    else:
        return 1

def inven(n = 100):
    """
    Funkcja tworząca prosty magazyn (wynajem/sklep). Zwraca ile gier o danym tytule (id_tytułu) jest u nas dostępna na półce.
    n = 100 - bo tyle różnych gier (i takich id) mamy w asortymencie
    """
    
    ilosc = np.random.randint(20, 30, n) ## od 20 do 30 każdego z tytułów
    ids = range(1, (n+1))
    ilosci = [ids[x] for x in range(len(ids)) for i in range(ilosc[x])]
    
    return pd.DataFrame({"id_inv": range(1, (len(ilosci)+1)),"id_tytuł": ilosci })

def odwiedziny(start = datetime.datetime(2022, 6, 6, 9, 0, 0), lamb = 4):
    """
    Funkcja symulująca odwiedziny w naszym sklepie - sprzedaże, wynajmy, a także zakup w outlecie. 
    Zwraca godziny wizyt, mieszkańców, co kupili/ wynajęli.
    start - dzień startowy naszego przedsiębiorstwa, niech to będzie 6 czerwca 2022, 9:00
    lamb - lambda - parametr potrzebny do generowania procesu Poissona - zakładamy 4 klientów na godzinę w naszym sklepie
   
    """
    
    mieszkancy = ludzie(im, ik, nm, nk, ulice_jaworze) #baza mieszkańców, którzy mogą nas odwiedzić
    T = 239/30 #7h 58 min bo tyle nasz sklep jest otwarty (z małym buforem, żeby nikt nie kupił czegoś po 1 s od otwarcia)
    
    now = datetime.datetime.now()
    days = (now - start).days ##żeby te daty były do dzisiaj
    
    
    inv_ren = inven() ##startowy magazyn wynajmu
    inv_shop = inven() ##startowy magazyn sklepu
    pp = [transform_wiek(mieszkancy["wiek"][x]) for x in range(len(mieszkancy))] ##wagi dla mieszkancow do losowania
    
    df = pd.DataFrame({}) ##podstawowa tabela, do której dodawane będą wizyty
    rental =  pd.DataFrame({"id_inv": [], "return_date": [], "zniszczona": [], "id_mieszkańca":[]}) ##tabela pomocnicza dla inv rentalowego
    kupno =  pd.DataFrame({"id_inv": [], "kupno": [], "wizyta":[]}) ##dla kupna
    outlet = pd.DataFrame({"id_outlet":[], "id_inv": [], "id_gry": [], "return_date": []}) ##dla outletu 
    arch_outlet =  pd.DataFrame({"id_inv": [], "date": [], "id_mieszkańca": [], "rd" : []})
    
    swieta = [datetime.datetime(2023, 1, 6, 9, 0, 0), datetime.datetime(2023, 4, 9, 9, 0, 0), 
              datetime.datetime(2023, 4, 10, 9, 0, 0), datetime.datetime(2023, 3, 1, 9, 0, 0), 
              datetime.datetime(2023, 3, 3, 9, 0, 0), datetime.datetime(2023, 6, 8, 9, 0, 0), 
              datetime.datetime(2022, 6, 16, 9, 0, 0), datetime.datetime(2022, 8, 15, 9, 0, 0),
              datetime.datetime(2022, 11, 1, 9, 0, 0), datetime.datetime(2022, 11, 11, 9, 0, 0),
              datetime.datetime(2022, 12, 25, 9, 0, 0), datetime.datetime(2022, 12, 26, 9, 0, 0),]
    dd = [(s - start).days + 1 for s in swieta] ##dni jakie minęły od startu do święta (żeby móc je ominąć łatwo)
    
    exp = np.ceil(np.random.exponential(1, 150)) ##z tego będą losowane ilości gier kupionych/wynajętych
    id_out = 1 ##początkowy indeks dla outletu
    
    for d in range(1, days + 1):
        
        if datetime.datetime.weekday(start)== 5 or datetime.datetime.weekday(start) == 6 or (d in dd): ## wyłączenie weekendów oraz świąt
            pass
        
        else:
            ##odwiedziny zgodne z procesem poissona
            lamb = np.random.randint(2,6)
            N = np.random.poisson(T*lamb) ##ilość osób na cały dzień
            ts = sorted(T*np.random.uniform(0,1, N)) ##czasy wizyt (takie surowe)
            t_wizyty = [(start + datetime.timedelta(minutes=1) + datetime.timedelta(
                minutes=round(t*60,1))) for t in ts] #.strftime("%m/%d/%Y %H:%M:%S") for t in ts]
            ##formatka wizyt
            
            for t in t_wizyty:
                ##losowanie klientów z populacji mieszkańców
                klient = random.choices(mieszkancy["id_mieszkańca"], weights=pp , k=1)
            
                #losowanie sprzedawcy (zakładamy, że sprzedawca 1 i 2 obsługują kasy przez te 8 h)
                sprzedawca = random.choices([1,2], k=1)
            
                ##ktoś może chce kupić kilka gier zamiast jednej
                ilosc = random.choices(exp, k = 1)
            
                ##ktoś przychodzi z zamiarem kupna/wynajmu bądź skorzystania z outletu (jeśli może)
                ##ilość dostępnych gier w outlecie musi wynosić min tyle ile ktoś chce tych gier zakupić
                
                if len(outlet[outlet["return_date"] < start]) >= ilosc[0]: 
                    rodzaj = random.choices(["wynajem", "kupno", "outlet"], weights = [24, 6, 2], k = 1)
                    ##ustalamy prawdopodobieństwa skorzystania z outletu na 2:10:10 względem zwykłego kupna i wynajmu
                else:
                    rodzaj = random.choices(["wynajem", "kupno"],weights = [4, 1], k = 1)
                    #jeśli outlet jest za słabo wyposażony zostaje tylko opcja wynajmu / kupna z wagami 1:1
                
                if rodzaj == ["wynajem"]:
                    
                    ##losuje zwrot za 1 lub 2 dni w godzinach otwarcia, bo zakładamy, że tyle mają czasu na zwrot
                    return_date = start + datetime.timedelta(days=random.randint(1,2)) + datetime.timedelta(
                        hours=round(random.uniform(1,T), 2))
                    
                    ##losuje id_gry, które ktoś wypożycza
                    ##szukamy tych id które są dostępne, czyli NIE ma ich w df rental z returndate > dziś
                    
                    not_in_use = np.array(rental[rental["return_date"] > start]["id_inv"]) ##niedostępne
                    ids = np.array(inv_ren["id_inv"]) ##wszystkie
                    in_use = np.setdiff1d(ids, not_in_use) ##różnica między wszystkimi a tymi niedostępnymi
                    gra = random.sample(sorted(in_use), k = int(ilosc[0])) ##z tych dostepnych losowanie gry
                    
                    ##ewentualne zniszczenia zwróconej gry - prawdopodobieństwo ustalamy na 1/100
                    fault = random.choices([0,1], weights = [99,1], k = int(ilosc[0])) 
                    
                    ##wrzucenie informacji do tymczasowej tabeli rental
                    rent_gry =  pd.DataFrame({"id_inv": gra, "return_date": np.repeat(return_date, int(ilosc[0])), 
                                              "zniszczona": fault, "id_mieszkańca": np.repeat(klient, int(ilosc[0]))})
                    rental = pd.concat([rental, rent_gry])
                    
                    ## gra może zostać zniszczona, a więc może trafić do outletu
                    if sum(fault) > 0: ##czy były jakieś zniszczenia - jeśli tak to update outletu
                        
                        idd = rent_gry[rent_gry["zniszczona"] == 1]["id_inv"] ##te zniszczone id_inv
                        for i in idd: ##dla każdej zniszczonej gry
                            ##znajdujemy id_tytułu (bo działaliśmy na inv)
                            id_tyt = inv_ren.loc[inv_ren['id_inv'] == i]["id_tytuł"] 
                
                            f = pd.DataFrame({"id_outlet": id_out, "id_inv": i, "id_gry": id_tyt, 
                                              "return_date": return_date})
                            outlet = pd.concat([outlet, f]) ## i dodajemy gre do outletu
                            id_out += 1
                            ###print("----", outlet, start)
                    
                elif rodzaj == ["kupno"]: 
                    ##to samo co z rentalem, tylko patrzymy na id gry, które ktoś kupił DZISIAJ 
                    ##bo zakładamy, że kupiona dzisiaj gra, dostępna będzie ponownie jutro
                    
                    return_date = None
                    not_in_use2 = np.array(kupno[kupno["kupno"] == start]["id_inv"])
                    ids2 = np.array(inv_shop["id_inv"])
                    in_use2 = np.setdiff1d(ids2, not_in_use2)
                    gra = random.sample(sorted(in_use2), k = int(ilosc[0]))
                
                    kup_gry =  pd.DataFrame({"id_inv": gra, "kupno": np.repeat(start, int(ilosc[0])),
                                             "wizyta": np.repeat(t, int(ilosc[0]))})
                    kupno = pd.concat([kupno, kup_gry])
                    
                else: ##outlet
                    return_date = None
                    in_use = outlet[outlet["return_date"] < start] 
                    ##patrzymy na te już zwrócone i dostepne gry
                    gra = random.sample(sorted(in_use["id_inv"]), k = int(ilosc[0])) ##losowanie z dostepnego outletu
                    ##id_inv odnoszą się na razie do magazynu wynajmu, ale później odnosić się będą do swojego id
                    ##to w formatce tabel
                    
                    for g in gra:
                        ret = outlet[outlet["id_inv"] == g]["return_date"].iloc[0]
                        #return date (czyli ret) dodaje w celach informacyjnych na potem
                        arch = pd.DataFrame({"id_inv": g,"rd" : ret, "date": t, "id_mieszkańca": klient}, index=[0])
                        arch_outlet = pd.concat([arch_outlet, arch]) ##wrzucamy do archiwum transakcji
                        ##usuwanie z outletu kupionych pozycji 
                        outlet = outlet.drop(outlet.index[outlet["id_inv"] == g])
                        
                ##dołączenie danego klienta do df z poprzednich dni
                day = pd.DataFrame({"id_mieszkańca": klient, "wizyta": t,
                                "sprzedawca": sprzedawca, "ilosc": int(ilosc[0]), "id_gry": str(gra)[1:-1], "rodzaj": rodzaj,
                                   "return_date": return_date})
                df = pd.concat([df, day])
                     
        ##przejście z datą na kolejny dzień
        start = start + datetime.timedelta(days=1)
        
    return df, rental, kupno, outlet, inv_ren, inv_shop, mieszkancy, arch_outlet

def format_tabel(wizyty, gry = gry):
    """
    Funkcja służąca do formatowania otrzymanych wyników z funkcji odwiedziny() w taki sposób, żeby zwracała
    gotowe tabele, które trafią do bazy danych.
    wizyty - wynik z funkcji odwiedziny()
    gry - tabela z grami naszego wykonania
    
    """
    tabela_g = wizyty[0] ##tabela główna
    rental_arch = wizyty[1] ##archiwum wynajmu
    shop_arch = wizyty[2] ##archiwum sprzedaży
    outlet_akt = wizyty[3] ##aktualny outlet
    rent_inv = wizyty[4] ##inventory rental
    shop_inv = wizyty[5] ##inventory shop
    mieszkancy = wizyty[6] ##cała społeczność
    outlet_arch = wizyty[7] ## archiwum outletu

    tabela_g = tabela_g.rename(columns = {"sprzedawca":"id_pracownika"})
    ## ------------- TABELA KLIENCI -------------
    
    #szukamy unikatowych osób, które pojawiły się u nas w sklepie i ich ostatnią wizytę
    klient = tabela_g.drop_duplicates(subset=['id_mieszkańca'], keep="last")[["id_mieszkańca", "wizyta"]]
    klienci = pd.merge(klient, mieszkancy, how = "inner", on = ["id_mieszkańca"]) ##dopasowanie względem id_mieszkanca
    klienci["id_klienta"] = range(1, len(klienci) + 1) ##stworzenie id klienta
    
    klienci_mieszkancy = klienci[["id_klienta", "id_mieszkańca"]] ##tabela pomocnicza z id klienta dopasowanymi do mieszkańca
    
    klienci = klienci[["id_klienta", "wizyta", "imię", "nazwisko", "wiek", "adres", "telefon"]] #końcowa tabela klientów
    
    ## ---------------- TABELA SPICHLERZ_WYNAJEM ---------------
    ceny = gry[["id_gry","cena"]]
    ceny = ceny.rename(columns = {"id_gry": "id_tytuł"}) ##tymczasowa tabela z cenami
    ceny["cena_wynajem"] = np.round(0.15*ceny["cena"], 2 ) ###bo ustalamy, że cena wynajmu gry kosztuje 15% jej ceny rynkowej
    
    one = pd.merge(rent_inv, ceny, on="id_tytuł") ##krok pierwszy - połączenie wynajmu z cenami najmu
    ids = np.array(rental_arch["id_inv"])
    rental_arch["id_inv"] = [int(i) for i in ids]  ##po random sample zostały float jako typ id, więc wracam na int
    two = rental_arch.drop_duplicates(subset=['id_inv'], keep='last') ##biorę pod uwagę tylko ostatnie wypożyczenie danej gry
    
    spichlerz_wynajemt = pd.merge(one,
                             two[["id_inv","return_date"]], 
                             on=["id_inv"], how="left").rename(columns = 
                                                               {"id_inv": "id_spichlerz_wynajem", "id_tytuł": "id_gry", "return_date": "ostatni_update"})
    ##i ostateczna tabela:
    spichlerz_wynajem = spichlerz_wynajemt[["id_spichlerz_wynajem", "id_gry", "ostatni_update"]]
    
    ## ------------------- TABELA SPICHLERZ_SKLEP ---------------
    
    ceny["cena_kupno"] = np.round(1.1*ceny["cena"], 2 ) ###bo ustalamy marżę 10% na zakupie
    raz = pd.merge(shop_inv, ceny, on="id_tytuł")[["id_tytuł", "cena_kupno", "id_inv"]] ##znowu pierwsze merge z cenami
    
    ids2 = np.array(shop_arch["id_inv"])
    shop_arch["id_inv"] = [int(i) for i in ids2] ##znowu zmiana na int
    shop_arch["kupno"] = [d + datetime.timedelta(days=1) for d in shop_arch["kupno"]] ## bo gra jest dostepna 1 dzień po zakupie
    dwa = shop_arch.drop_duplicates(subset=['id_inv'], keep='last') ##znowu patrzymy na ostatnie zakupy
    spichlerz_sklept = pd.merge(raz,
                             dwa[["id_inv","kupno"]], 
                             on=["id_inv"], how="left").rename(columns = 
                                                               {"id_inv": "id_spichlerz_sklep", "id_tytuł": "id_gry", "kupno": "ostatni_update"})
    spichlerz_sklep = spichlerz_sklept[["id_spichlerz_sklep", "id_gry", "ostatni_update"]] ##ostatnia formatka
    
    ## ---------------- TABELA WYNAJEM ---------
    sub = pd.merge(rental_arch, tabela_g, on = ["return_date", "id_mieszkańca"])[["id_inv", "wizyta",
                                                                                  "return_date", "zniszczona", 
                                                                                  "id_mieszkańca", "id_pracownika"]]
    ##łączymy archiwum z główną tabelą - mamy teraz więcej informacji i dodajemy id klienta
    wynajemt = pd.merge(sub, klienci_mieszkancy, how = "left", on = ["id_mieszkańca"]).rename(columns={"id_inv":"id_spichlerz_wynajem"})
    ## i merge tabeli tymczasowej ze spichlerzem, żeby uzyskać cenę
    wynajem = pd.merge(wynajemt, spichlerz_wynajemt[["id_spichlerz_wynajem","cena_wynajem"]], on=["id_spichlerz_wynajem"], how="left")
    ##i ostateczna forma tabeli:
    wynajem =  wynajem.sort_values(by = "wizyta", inplace=False, ascending=True) ##sort po datach
    wynajem = wynajem.rename(columns = {"wizyta": "data_wynajmu", "return_date": "data_zwrotu"}) ##szybki rename
    wynajem["id_transakcji_wynajem"] = range(1, len(wynajem) + 1) ##dodanie id_transakcji
    wynajem = wynajem[["id_transakcji_wynajem", "id_spichlerz_wynajem","cena_wynajem", "data_wynajmu", "data_zwrotu", 
                       "id_pracownika", "id_klienta", "zniszczona"]]
    
    ## ----------- TABELA SKLEP --------------------
    tabela_g = tabela_g.rename(columns = {"wizyta":"data_zakupu"})
    shop_arch = shop_arch.rename(columns = {"wizyta":"data_zakupu"})
    shop_arch['data_zakupu'] = pd.to_datetime(shop_arch['data_zakupu']) ##merge z tabelą główną
    sklept = pd.merge(shop_arch, tabela_g, on="data_zakupu", how="left")[["id_inv", "data_zakupu", "id_mieszkańca", "id_pracownika"]]
    sklep = pd.merge(sklept, klienci_mieszkancy, how="left", on = ["id_mieszkańca"]).rename(columns = {"id_inv": "id_spichlerz_sklep"})
    sklep["id_transakcji_sklep"] = range(1, len(sklep) + 1)
    sklep = pd.merge(sklep, spichlerz_sklept[["id_spichlerz_sklep", "cena_kupno"]], on="id_spichlerz_sklep", how="left")
    sklep = sklep[["id_transakcji_sklep", "id_spichlerz_sklep", "data_zakupu", "cena_kupno", "id_klienta", "id_pracownika"]]
    #sklep = sklep.rename(columns={"wizyta" : "data_zakupu"})
    
    
    ## -------------- TABELA OUTLET ----------------
    
    outlet_arch['date'] = pd.to_datetime(outlet_arch['date'])
    ids = outlet_arch["id_inv"]
    outlet_arch["id_inv"] = [int(i) for i in ids]
    outlet_arch = outlet_arch.rename(columns = {"id_inv":"id_spichlerz_wynajem", "date":"data_zakupu"})
    out = pd.merge(outlet_arch, tabela_g, on=["data_zakupu", "id_mieszkańca"], how="left")[["id_spichlerz_wynajem", "data_zakupu", "id_mieszkańca", "id_pracownika", "rd"]]
    out2 = pd.merge(out, spichlerz_wynajemt[["id_spichlerz_wynajem", "id_gry", "cena_wynajem"]], on="id_spichlerz_wynajem", how="left")
    out2["cena_outlet"] = [3* c for c in out2["cena_wynajem"]] 
    ##bo ustalamy 45% czyli 3* cenę najmu jako cenę kupna outletowej gry
    outlett = pd.merge(out2, klienci_mieszkancy, how="left", on = ["id_mieszkańca"]).rename(columns={"rd":"data_zwrotu"})
    outlett["id_transakcji_outlet"] = range(1, len(outlett) + 1)
    ## i dostajemy się do id_transakcji z wynajmu
    outlett2 = pd.merge(outlett, wynajem[["data_zwrotu", "id_spichlerz_wynajem","id_transakcji_wynajem"]], 
                        on=["data_zwrotu", "id_spichlerz_wynajem"])
    outlet = outlett2[["id_transakcji_outlet", "id_transakcji_wynajem", "id_spichlerz_wynajem", "cena_outlet", 
                      "data_zakupu", "id_klienta", "id_pracownika"]]
    
    ## -------------------TABELA SPICHLERZ_OUTLET --------------
    s_out = outlet_akt.rename(columns={ "id_inv":"id_spichlerz_wynajem", "return_date":"data_zwrotu", 
                                       "id_outlet": "id_spichlerz_outlet"})
    spichlerz_outlet = pd.merge(s_out, wynajem[["data_zwrotu", "id_spichlerz_wynajem","id_transakcji_wynajem"]],
                    on=["data_zwrotu", "id_spichlerz_wynajem"])
    ##szybka zmiana na inty
    ids = spichlerz_outlet["id_spichlerz_wynajem"]
    spichlerz_outlet["id_spichlerz_wynajem"] = [int(i) for i in ids]
    ids = spichlerz_outlet["id_spichlerz_outlet"]
    spichlerz_outlet["id_spichlerz_outlet"] = [int(i) for i in ids]
    spichlerz_outlet = spichlerz_outlet[["id_spichlerz_outlet", "id_transakcji_wynajem"]]
    ##data zwrotu czyli dostępnosci
    
    return klienci, spichlerz_wynajem, spichlerz_sklep, wynajem, sklep, outlet, spichlerz_outlet


def payment(rola):
    if rola == "sprzedawca":
        return random.randint(3700, 4300)
    elif rola == "logistyk":
        return random.randint(5000, 6000)
    else:
        return random.randint(6000, 7000)
    
def sales(ul = ulice_jaworze):
    role = ["sprzedawca", "sprzedawca", "manager", "logistyk"]
    id_pracownika = [1,2,3,4]
    pay_s = payment("sprzedawca")
    pay_m = payment("manager")
    pay_l = payment("logistyk")
    pensje = [pay_s, pay_s, pay_m, pay_l]
    
    imiona = ["Misio", "Nati", "Alutka", "Fifol"]
    nazwiska = ["Bresiński", "Lach", "Myśliwiec", "Oszczepaliński"]
    wiek = [22, 22, 21, 21]
    r = random.sample(id_pracownika, k=4)
    
    adresy = [random.choice(ul) + ' ' + str(random.randint(1,100)) for _ in range(4)]
    telefony = [random.randint(500000000, 999999999) for _ in range(4)]
    
    one = pd.DataFrame({"id_pracownika" : r, "imię_pracownika" : imiona, 
                        "nazwisko_pracownika" : nazwiska, "wiek_pracownika": wiek,
                       "adres_pracownika" : adresy, "telefon_pracownika" : telefony})
    two = pd.DataFrame({"id_pracownika": id_pracownika, "rola": role, "pensja":pensje})
    
    pracownicy = pd.merge(one, two, on="id_pracownika")
    pracownicy = pracownicy.sort_values(by="id_pracownika")
    
    return pracownicy


def turniej(gracze, stoly, gry, inv, rental):
    '''
    Funkcja, która symuluje przebieg turniejów odbywających się planowo co 2 tygodnie w naszym sklepie, a następnie 
    zwraca 3 tabele (df.dataframe) zawierające kolejno:
    
    - spis_turniej: Informacje na temat logistyki przeprowadzania turniejów ze względu na daną grę, tj. ilość punktów
                    możliwych do zdobycia, liczba rozgrywek, minimalna i maksymalna liczba graczy.
    - rozgrywka: Informacje o datach kolejnych turniejów oraz grze, w której rywalizowali uczestnicy.
    - wyniki: Informacje o wynikach poszczególnych graczy, tj. id_gracza, liczba zdobytych punktów, długość rozgrywki.
    
    Argumenty wejściowe:
    
    - gracze [pd.dataframe]: populacja, z której losowani będą uczestnicy poszczególnych rozgrywek
    - stoly [int]: liczba stołów, na których będą rozgrywane turnieje
    - gry [pd.dataframe]: tabela z grami, w które będzie można zorganizować turnieje
    '''
    
    # turnieje startują od 09.06.2022 i odbywają się do dzisiaj
    start = datetime.datetime(2022, 6, 9, 18, 0, 0)
    now = datetime.datetime.now()
    days = (now - start).days
    two_weeks = datetime.timedelta(weeks = 2)
    future = now + two_weeks*6
    
    # ================ resztę na dole też ładnie uporządkuję ale to na końcu
    
    # generowanie dat turniejów
    all_date_tournament = np.array([start])
    while all_date_tournament[-1]<future:
        next_tournament = all_date_tournament[-1]+two_weeks
        all_date_tournament = np.append(all_date_tournament,next_tournament)

    # sprawdzamy czy daty kolidują z dniami wolnymi
    swieta = [
              datetime.datetime(2023, 1, 6, 18, 0, 0), datetime.datetime(2023, 4, 18, 9, 0, 0), 
              datetime.datetime(2023, 4, 10, 18, 0, 0), datetime.datetime(2023, 3, 1, 18, 0, 0), 
              datetime.datetime(2023, 3, 3, 18, 0, 0), datetime.datetime(2023, 6, 8, 18, 0, 0), 
              datetime.datetime(2022, 6, 16, 18, 0, 0), datetime.datetime(2022, 8, 15, 18, 0, 0),
              datetime.datetime(2022, 11, 1, 18, 0, 0), datetime.datetime(2022, 11, 11, 18, 0, 0),
              datetime.datetime(2022, 12, 25, 18, 0, 0), datetime.datetime(2022, 12, 26, 18, 0, 0),]

    all_date_tournament = np.delete(all_date_tournament,np.isin(all_date_tournament,swieta))

    date_tournament = all_date_tournament[all_date_tournament<now]

    
    # spis_turnieju
    gra_tournament = gry[gry['turniejowe'] == 1]
    id_spis = [i for i in range(1,len(gra_tournament)+1)]
    # zakładam, iz czas dodatkowy to 0.3
    # sprawdzić czy na stanie jest wystarczająca ilość gier
    amount = np.floor(240/(np.array(gra_tournament[['czas_gry']])+np.array(gra_tournament[['czas_gry']])*0.3))*stoly
    amount = amount.transpose()
    # graczy
    min_graczy = np.array(gra_tournament['max_graczy'])/2*amount.astype(int)
    max_graczy = np.array(gra_tournament['max_graczy'])*amount.astype(int)

    # średnia z punktów dla poszczególnych gier
    mean_point = np.array([110, 50, 150, 69, 62])
    # tworzenie dataframe
    spis_turniej = pd.DataFrame({'id_spis':id_spis,'id_gry':gra_tournament['id_gry'],'średnia_punktów' : mean_point,
                            'ilosc_gier' : amount[0], 'min_graczy': min_graczy[0], 'max_graczy':max_graczy[0]})
    # turniej
    id_turniej = [i for i in range(1,len(all_date_tournament)+1)]
    kind_tournament = random.choices(np.array(id_spis),k=len(all_date_tournament)) # losowanie typu turnieju
    date_date = [dt.date() for dt in all_date_tournament] # tylko daty
    rozgrywka = pd.DataFrame({'id_turnieju':id_turniej, 'id_rodzaj':kind_tournament,'data':date_date})
    # wyniki

    id_turnieji = np.array([])
    id_klientow = np.array([])
    wyniki = np.array([])
    czas_rozrywki = np.array([])
    for _ in range(len(date_tournament)):

        kt = kind_tournament[_]
        idgry = np.array(spis_turniej[spis_turniej['id_spis']==kt][['id_gry']].iloc[0])[0]
        # sprawdzam czy jest wystarczająca ilosc gier
        id_wynajem = np.array(inv[inv['id_gry']==idgry]['id_spichlerz_wynajem'])
        przedzial = rental[np.isin(rental['id_spichlerz_wynajem'],id_wynajem)][['data_wynajmu','data_zwrotu']]
        i = 0
        for j in range(len(przedzial)):
            if przedzial.iloc[j]['data_wynajmu'] < date_tournament[_] < przedzial.iloc[j]['data_zwrotu']:
                i=+1
        
        if id_wynajem.shape[0] - i < np.array(spis_turniej[spis_turniej['id_spis']==kt][['ilosc_gier']].iloc[0])[0]:
            raise ValueError('No to chop na gałąź')

        ig = np.array(spis_turniej[spis_turniej['id_spis']==kt][['min_graczy','max_graczy']].iloc[0]) # wczytywanie min max graczy

        # ilość graczy na turnieju
        il = random.randint(ig[0],ig[1])

        # znajdowanie max graczy w grze(planszy)
        max_g = np.array(gra_tournament[gra_tournament['id_gry']==idgry]['max_graczy'])[0]
        
        if il%(max_g) == 0 :
            for n_ in range(int(il/(max_g))):
                
                id_rozgrywki_s = np.round(np.array([id_turniej[_]]*(max_g)),0) # powtarzamy id_turnieju 
                id_turnieji = np.append(id_turnieji,id_rozgrywki_s)

                id_klienta = random.sample(list(gracze['id_klienta']),k = max_g) # losujemy graczy bez zwracania
                id_klientow = np.append(id_klientow,id_klienta)

                wynik = [spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]]*max_g + np.random.normal(
                        scale=spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]*0.15,size=max_g)
                wyniki = np.append(wyniki,wynik) # losujemy wynik
                
                czas = np.round([gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0] + np.random.normal(
                           scale= gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0])*0.1]*max_g,0)

                czas_rozrywki = np.append(czas_rozrywki,czas)
        elif il%max_g == 1 or il%max_g == 2:
            vec = range(np.ceil(il/max_g).astype(int))
            for _n in vec:
                if _n in vec[:-2]:
                    id_rozgrywki_s = np.round(np.array([id_turniej[_]]*(max_g)),0) # powtarzamy id_turnieju 
                    id_turnieji = np.append(id_turnieji,id_rozgrywki_s)

                    id_klienta = random.sample(list(gracze[gracze["wiek"] > 15]['id_klienta']),k = max_g) # losujemy graczy bez zwracania
                    id_klientow = np.append(id_klientow,id_klienta)

                    wynik = [spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]]*max_g + np.random.normal(
                            scale=spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]*0.15,size=max_g) # losujemy wynik
                    wyniki = np.append(wyniki,wynik) 

                    # czas rozgrywki jest wyznaczamy dla graczy przy jednej planszy
                    czas = np.round([gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0] + np.random.normal(
                           scale= gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0])*0.1]*max_g,0) 
                    czas_rozrywki = np.append(czas_rozrywki,czas)

                elif _n == vec[-1]:
                    pass
                else:
                    gracze_1 = np.floor((il-max_g*(_n))/2).astype(int) # ilosc graczy przy 1 planszy
                    gracze_2 = (il-max_g*(_n)-gracze_1).astype(int) # ilosc graczy przy 2 planszy

                    id_rozgrywki_s = np.round(np.array([id_turniej[_]]*(il-max_g*(_n))),0) # powtarzamy id_turnieju 
                    id_turnieji = np.append(id_turnieji,id_rozgrywki_s)

                    id_klienta = random.sample(list(gracze[gracze["wiek"] > 15]['id_klienta']),k = (il-max_g*(_n))) # losujemy graczy bez zwracania
                    id_klientow = np.append(id_klientow,id_klienta)

                    wynik = [spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]]*(il-max_g*(_n)) + np.random.normal(
                            scale=spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]*0.15,size=(il-max_g*(_n)))
                    wyniki = np.append(wyniki,wynik) # losujemy wynik

                    czas_1 = np.round([gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0] + np.random.normal(
                           scale= gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0])*0.1]*gracze_1,0)
                    czas_2 = np.round([gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0] + np.random.normal(
                           scale= gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0])*0.1]*gracze_2,0)

                    czas = np.append(czas_1,czas_2)
                    czas_rozrywki = np.append(czas_rozrywki,czas)
        else:
            vec = range(np.ceil(il/max_g).astype(int))
            for _n in vec:
                if _n in vec[:-1]:
                    id_rozgrywki_s = np.round(np.array([id_turniej[_]]*(max_g)),0) # powtarzamy id_turnieju 
                    id_turnieji = np.append(id_turnieji,id_rozgrywki_s)
                    
                    id_klienta = random.sample(list(gracze[gracze["wiek"] > 15]['id_klienta']),k = max_g) # losujemy graczy bez zwracania
                    id_klientow = np.append(id_klientow,id_klienta)

                    wynik = [spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]]*max_g + np.random.normal(
                            scale=spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]*0.15,size=max_g)
                    wyniki = np.append(wyniki,wynik) # losujemy wynik

                    czas = np.round([gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0] + np.random.normal(
                           scale= gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0])*0.1]*max_g,0)
                    czas_rozrywki = np.append(czas_rozrywki,czas)
                else:

                    id_rozgrywki_s = np.round(np.array([id_turniej[_]]*(il-max_g*(_n))),0) # powtarzamy id_turnieju 
                    id_turnieji = np.append(id_turnieji,id_rozgrywki_s)
                    
                    id_klienta = random.sample(list(gracze[gracze["wiek"] > 15]['id_klienta']),k = (il-max_g*(_n))) # losujemy graczy bez zwracania
                    id_klientow = np.append(id_klientow,id_klienta)

                    wynik = [spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]]*(il-max_g*(_n)) + np.random.normal(
                            scale=spis_turniej[spis_turniej['id_spis']==kt]['średnia_punktów'].iloc[0]*0.15,size=(il-max_g*(_n)))
                    wyniki = np.append(wyniki,wynik) # losujemy wynik

                    czas = np.round([gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0] + np.random.normal(
                           scale= gra_tournament[gra_tournament['id_gry']==idgry]['czas_gry'].iloc[0])*0.1]*(il-max_g*_n),0)
                    czas_rozrywki = np.append(czas_rozrywki,czas)

    df_wynik = pd.DataFrame({'id_turniej':id_turnieji.astype(int),'id_klienta':id_klientow.astype(int),'wynik':np.ceil(wyniki).astype(int),'czas_rozgrywki':czas_rozrywki.astype(int)})    
    spis_turniej = spis_turniej.rename(columns={'id_spis':'id_rodzaj','id_gry':'id_gry','średnia_punktów' :'średnia_punktów' ,
                            'ilosc_gier' : 'ilość_gier', 'min_graczy':'min_graczy', 'max_graczy':'max_graczy'})
    rozgrywka = rozgrywka.rename(columns={'id_turnieju':'id_turniej', 'id_rodzaj':'id_rodzaj','data':'data'})
    return spis_turniej, rozgrywka, df_wynik  

def drop_foreign_key(engine,table, key):

    connection = engine.connect()
    drop_constraint_statement = "ALTER TABLE " + table + ' DROP CONSTRAINT ' +key +" ; "
    connection.execute(text(drop_constraint_statement))
    connection.close()

def add_foreign_key(engine,table, fk, key, end):
    connection = engine.connect()
    add_constraint_statement = "ALTER TABLE "+ table + " ADD CONSTRAINT "+fk+" FOREIGN KEY ("+ key +") REFERENCES "+end+ " ;"
    connection.execute(text(add_constraint_statement))
    connection.close()

if __name__ == "__main__":
    print("wait for it")
    ##tworzenie tabel
    tt = odwiedziny() ##wykonanie symulacji
    tab = format_tabel(tt) ##format tabel z symulacji
    klienci = tab[0]
    spichlerz_wynajem = tab[1]
    spichlerz_sklep = tab[2]
    wynajem = tab[3]
    sklep = tab[4]
    outlet = tab[5]
    spichlerz_outlet = tab[6]
    pracownicy = sales()
    n, m, p = turniej(klienci, 2, gry, spichlerz_wynajem, wynajem)
    ##n - rodzaj_turniejów
    ##m - turniej
    ##p - wyniki

    print("almost done")
    
    ##wrzucenie tabel do bazy
    url_object = URL.create(
        "mysql+pymysql",
        username="team26",
        password="te@mzg",  # tu wpisać hasło i go nie commitować bo gitguardian was zje
        host="giniewicz.it",
        database="team26",
    )
    engine = create_engine(url_object)
    conn = engine.connect()

    drop_foreign_key(engine,'rodzaje_turniejów','FK_id_gry')
    drop_foreign_key(engine,'spichlerz_outlet','FK_id_transakcji_wynajem')
    drop_foreign_key(engine,'spichlerz_sklep','FK_id_gry2')
    drop_foreign_key(engine,'spichlerz_wynajem','FK_id_gry1')
    drop_foreign_key(engine,'sklep','FK_id_spichlerz_sklep')
    drop_foreign_key(engine,'sklep','FK_id_pracownika1')
    drop_foreign_key(engine,'sklep','FK_id_klienta1')
    drop_foreign_key(engine,'turnieje','FK_id_rodzaj')
    drop_foreign_key(engine,'wynajem','FK_id_spichlerz_wynajem')
    drop_foreign_key(engine,'wynajem','FK_id_pracownika2')
    drop_foreign_key(engine,'wynajem','FK_id_klienta2')
    drop_foreign_key(engine,'wyniki','FK_id_turniej')
    drop_foreign_key(engine,'wyniki','FK_id_klienta3')
    drop_foreign_key(engine,'outlet','FK_id_klienta')
    drop_foreign_key(engine,'outlet','FK_id_pracownika')

    conn.execute(text('TRUNCATE TABLE rodzaje_turniejów'))
    conn.execute(text('TRUNCATE TABLE gry'))
    conn.execute(text('TRUNCATE TABLE pracownicy'))
    conn.execute(text('TRUNCATE TABLE klienci'))
    conn.execute(text('TRUNCATE TABLE outlet'))
    conn.execute(text('TRUNCATE TABLE spichlerz_wynajem'))
    conn.execute(text('TRUNCATE TABLE wynajem'))
    conn.execute(text('TRUNCATE TABLE sklep'))
    conn.execute(text('TRUNCATE TABLE spichlerz_sklep'))
    conn.execute(text('TRUNCATE TABLE spichlerz_outlet'))
    conn.execute(text('TRUNCATE TABLE wyniki'))
    conn.execute(text('TRUNCATE TABLE turnieje'))

    gry.to_sql("gry", engine, if_exists="append", index = False)
    pracownicy.to_sql("pracownicy", engine, if_exists="append", index = False)
    klienci.to_sql("klienci", engine, if_exists="append", index=False)
    outlet.to_sql("outlet", engine, if_exists="append", index=False)
    spichlerz_wynajem.to_sql("spichlerz_wynajem", engine, if_exists="append", index=False)
    wynajem.to_sql("wynajem", engine, if_exists="append", index=False)
    sklep.to_sql("sklep", engine, if_exists="append", index=False)
    spichlerz_sklep.to_sql("spichlerz_sklep", engine, if_exists="append", index=False)
    spichlerz_outlet.to_sql("spichlerz_outlet", engine, if_exists="append", index=False)
    n.to_sql("rodzaje_turniejów", engine, if_exists="append", index=False)
    m.to_sql("turnieje", engine, if_exists="append", index=False)
    p.to_sql("wyniki", engine, if_exists="append", index=False)

    add_foreign_key(engine,'outlet','FK_id_klienta','id_klienta','klienci(id_klienta)')
    add_foreign_key(engine,'outlet','FK_id_pracownika','id_pracownika','pracownicy(id_pracownika)')
    add_foreign_key(engine,'rodzaje_turniejów','FK_id_gry','id_gry','gry(id_gry)')
    add_foreign_key(engine,'spichlerz_outlet','FK_id_transakcji_wynajem','id_transakcji_wynajem',
    'wynajem(id_transakcji_wynajem)')
    add_foreign_key(engine,'spichlerz_sklep','FK_id_gry2','id_gry','gry(id_gry)')
    add_foreign_key(engine,'spichlerz_wynajem','FK_id_gry1','id_gry','gry(id_gry)')
    add_foreign_key(engine,'sklep','FK_id_spichlerz_sklep','id_spichlerz_sklep',
    'spichlerz_sklep(id_spichlerz_sklep)')
    add_foreign_key(engine,'sklep','FK_id_pracownika1','id_pracownika','pracownicy(id_pracownika)')
    add_foreign_key(engine,'sklep','FK_id_klienta1','id_klienta','klienci(id_klienta)')
    add_foreign_key(engine,'turnieje','FK_id_rodzaj','id_rodzaj','rodzaje_turniejów(id_rodzaj)')
    add_foreign_key(engine,'wynajem','FK_id_spichlerz_wynajem','id_spichlerz_wynajem','spichlerz_wynajem(id_spichlerz_wynajem)')
    add_foreign_key(engine,'wynajem','FK_id_pracownika2','id_pracownika','pracownicy(id_pracownika)')
    add_foreign_key(engine,'wynajem','FK_id_klienta2','id_klienta','klienci(id_klienta)')
    add_foreign_key(engine,'wyniki','FK_id_turniej','id_turniej','turnieje(id_turniej)')
    add_foreign_key(engine,'wyniki','FK_id_klienta3','id_klienta','klienci(id_klienta)')

    conn.close()
    print("hura")

