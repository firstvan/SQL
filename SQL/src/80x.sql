

--Hozzunk létre csomagot, amelynek a segítségével az el?z? feladat két tábláját használni tudjuk.

--A csomag tartalmazzon egy beszur_konyv nev? publikus eljárást, egy töröl könyv nev? publikus függvényt,
--egy listáz nev? publikus eljárást, és nincs_ilyen_konyv, nem_megfelelo_konyv, letezo_raktari_szam nev? kivételeket.

--A beszur_konyv nev? eljárás paraméterként kapjon ISBN, cím, kiadó, kiadás éve, raktári szám értékeket.
--El?ször a könyv táblába próbáljon beszúrni, ha ott a könyv megtalálható, és az értékek megfelelnek, akkor örülünk,
--ha nem felelnek meg az értékek, akkor a nem_megfelelo_konyv kivételt dobjuk, ha nincs ilyen könyv, akkor beszúrjuk.
--Majd a megfelel? értékeket beszúrjuk a példány táblába. Ha az adott raktári számon már létezik a könyv,
--akkor dobjunk letezo_raktari_szam kivetelt.

 --A töröl könyv nev? függvény paraméterként egy raktári számot kapjon,
--és törölje ki csak a példány táblából az adott könyvet, majd visszatérési értékként adja vissza,
--hogy hány példány van még a kitörölt könyvb?l ugyanazzal az ISBN számmal. Ha a raktári szám nem létezik,
--akkor ne történjen semmi.

--A listáz nev? eljáráshoz definiáljunk egy privát kurzort,
--amely paraméterként kapott ISBN számhoz listázza a raktári számokat, a könyv címeket, a könyv kiadókat
--és a kiadás évét. Az eljárás megnyitja a kurzort, ha még nincs nyitva, egy sort felolvas, majd paraméterként
--visszaadja az eredményeket. (Ezt egy publikus rekortípusban tegyük meg.) Ha a kurzorban nem találnuk több sort,
--akkor null értéket adjunk vissza. Ha nem talál ilyen ISBN számú k0önyvet, akkor nincs ilyen könyv kivételt dob.

begin
HDBMS15.MEGOLDAS_FELTOLT(805, '
create or replace package P_FIRST_PACKAGE is
procedure beszur_konyv(
p_isbn KONYVEK.ISBN%type,
p_cim KONYVEK.CIM%type,
p_kiado KONYVEK.KIADO%type,
p_kiadas_eve KONYVEK.KIADAS_EVE%type,
p_raktari_szam PELDANY.RAKTARI_SZAM%type);

function torol_konyv(p_raktari_szam PELDANY.RAKTARI_SZAM%type) return number;

type returnType is record
(RAKTARI_SZAM PELDANY.RAKTARI_SZAM%type,
 KONYV_CIM KONYVEK.CIM%type,
 KONYV_KIADO KONYVEK.KIADO%type,
 KONYVKIADAS_EVE KONYVEK.KIADAS_EVE%type);

procedure listaz(P_ISBN KONYVEK.ISBN%TYPE, visszaad out returntype);

nincs_ilyen_konyv exception;
pragma exception_init(nincs_ilyen_konyv, -20010);
nem_megfelelo_konyv exception;
pragma exception_init(nem_megfelelo_konyv, -20011);
letezo_raktari_szam exception;
pragma exception_init(letezo_raktari_szam, -20012);

end;/

create or replace package body P_FIRST_PACKAGE as
cursor listazo (P_isbn KONYVEK.ISBN%type) return returntype is
(select p.raktari_szam, k.cim, k.kiado, k.kiadas_eve from konyvek k inner join peldany p on(k.isbn=p.isbn) where k.isbn = p_isbn);
procedure beszur_konyv(
p_isbn KONYVEK.ISBN%type,
p_cim KONYVEK.CIM%type,
p_kiado KONYVEK.KIADO%type,
p_kiadas_eve KONYVEK.KIADAS_EVE%type,
p_raktari_szam PELDANY.RAKTARI_SZAM%type) is
r KONYVEK%rowtype;
begin
    begin
        select * into r from KONYVEK where ISBN = p_isbn;

        if r.cim <> p_cim or r.KIADAS_EVE <> p_kiadas_eve or r.KIADO <> p_kiado then
            raise nem_megfelelo_konyv;
            return;
        end if;

        exception
        when no_data_found then
            insert into KONYVEK (ISBN, KIADAS_EVE, KIADO, CIM ) values (p_isbn, p_kiadas_eve, p_kiado, p_cim);

    end;
    begin
        insert into PELDANY (RAKTARI_SZAM, ISBN) values (p_raktari_szam, p_isbn);

        exception
            when dup_val_on_index
            then raise letezo_raktari_szam;
    end;
end;

function torol_konyv(p_raktari_szam PELDANY.RAKTARI_SZAM%type) return number is
m_isbn PELDANY.ISBN%type;
ret number;
begin
    delete from PELDANY where raktari_szam = P_RAKTARI_SZAM returning ISBN into m_isbn;

    select count(*) into ret from PELDANY where ISBN = m_isbn;

    return ret;
    exception
        when no_data_found
        then null;
end;

procedure listaz(P_ISBN KONYVEK.ISBN%TYPE, visszaad out returntype) is
begin
    if not listazo%isopen then
        open listazo(P_ISBN);
    end if;

    fetch listazo into visszaad;

    if listazo%rowcount = 0 then
        raise nincs_ilyen_konyv;
    end if;

    if listazo%notfound then
       visszaad := null;
    end if;
end;
end;/');
end;

select * from HDBMS15.FELADATAIM where azon = 806;

--Próbáljuk ki az el?z? feladat csomagjának az eszözeit. Vegyünk fel a táblába sorokat, ugyanolyan ISBN számmal rendelkez?eket is, próbáljuk ki a lehetséges kivételeket.
--Töröljünk könyvet, nézzük meg a függvény visszatérési értékét, próbáljuk ki a lehetséges kivételt, kapjuk el.
--A listázd próbáljuk ki úgy, hogy adott ISBN számhoz minden létez? példányt listázzunk ki. Próbáljuk ki itt is a kivételt, kapjuk el


ALTER PACKAGE P_FIRST_PACKAGE COMPILE package;
begin
HDBMS15.MEGOLDAS_FELTOLT(806, '
declare
ret P_FIRST_PACKAGE.RETURNTYPE;
begin
    P_FIRST_PACKAGE.BESZUR_KONYV(11111111119, ''A kis kutya'', ''Kiado kft'', 2000, 1);
    P_FIRST_PACKAGE.BESZUR_KONYV(11111111112, ''A kis kutya2'', ''Kiado kft'', 2001, 2);
    P_FIRST_PACKAGE.BESZUR_KONYV(11111111113, ''A kis kutya3'', ''Kiado kft'', 2002, 3);
    P_FIRST_PACKAGE.BESZUR_KONYV(11111111113, ''A kis kutya3'', ''Kiado kft'', 2002, 4);
        P_FIRST_PACKAGE.BESZUR_KONYV(11111111114, ''A kis kutya4'', ''Kiado kft'', 2003, 7);
    begin
        P_FIRST_PACKAGE.BESZUR_KONYV(11111111111, ''A kis kutya5'', ''Kiado kft'', 2002, 5);
        exception when P_FIRST_PACKAGE.nem_megfelelo_konyv
        then DBMS_Output.Put_Line(''Dobtam egy nem megfelel? könyv kivételt'');
    end;
    begin
        P_FIRST_PACKAGE.BESZUR_KONYV(11111111110, ''A kis kutya'', ''Kiado kft'', 2000, 1);
        exception when P_FIRST_PACKAGE.letezo_raktari_szam
        then DBMS_OUTPUT.PUT_LINE(''LÉTEZ? RAKTÁRI SZÁM KIVÉTELT DOBTAM'');
    end;

    DBMS_OUTPUT.PUT_LINE(''TÖRÖL: ''||P_FIRST_PACKAGE.TOROL_KONYV(3));

        P_FIRST_PACKAGE.LISTAZ(11111111119, ret);
        DBMS_OUTPUT.PUT_LINE(ret.KONYV_CIM|| '' '' ||ret.raktari_szam);
        P_FIRST_PACKAGE.LISTAZ(11111111119, ret);
        DBMS_OUTPUT.PUT_LINE(ret.KONYV_CIM|| '' '' ||ret.raktari_szam);
        P_FIRST_PACKAGE.LISTAZ(11111111119, ret);
        DBMS_OUTPUT.PUT_LINE(ret.KONYV_CIM|| '' '' ||ret.raktari_szam);
    exception
    when others then dbms_output.PUT_LINE(sqlcode||sqlerrm);
end;/');
end;

select * from KONYVEK;
select * from PELDANY;

CREATE TABLE PELDANY(
RAKTARI_SZAM NUMBER,
ISBN NUMBER(13),
CONSTRAINT PELDANY_PRIMARY_KEY PRIMARY KEY (RAKTARI_SZAM),
CONSTRAINT PELDANY_FOREIGN_KEY FOREIGN KEY (ISBN) REFERENCES KONYVEK(ISBN)
);

delete from KONYVEK;
delete from PELDANY;

select * from p_vasarlok;


------901 ----------------------
select * from HDBMS15.MEGOLDASAIM;

select * from HDBMS15.FELADATAIM;

