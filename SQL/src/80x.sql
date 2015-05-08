

--Hozzunk l�tre csomagot, amelynek a seg�ts�g�vel az el?z? feladat k�t t�bl�j�t haszn�lni tudjuk.

--A csomag tartalmazzon egy beszur_konyv nev? publikus elj�r�st, egy t�r�l k�nyv nev? publikus f�ggv�nyt,
--egy list�z nev? publikus elj�r�st, �s nincs_ilyen_konyv, nem_megfelelo_konyv, letezo_raktari_szam nev? kiv�teleket.

--A beszur_konyv nev? elj�r�s param�terk�nt kapjon ISBN, c�m, kiad�, kiad�s �ve, rakt�ri sz�m �rt�keket.
--El?sz�r a k�nyv t�bl�ba pr�b�ljon besz�rni, ha ott a k�nyv megtal�lhat�, �s az �rt�kek megfelelnek, akkor �r�l�nk,
--ha nem felelnek meg az �rt�kek, akkor a nem_megfelelo_konyv kiv�telt dobjuk, ha nincs ilyen k�nyv, akkor besz�rjuk.
--Majd a megfelel? �rt�keket besz�rjuk a p�ld�ny t�bl�ba. Ha az adott rakt�ri sz�mon m�r l�tezik a k�nyv,
--akkor dobjunk letezo_raktari_szam kivetelt.

 --A t�r�l k�nyv nev? f�ggv�ny param�terk�nt egy rakt�ri sz�mot kapjon,
--�s t�r�lje ki csak a p�ld�ny t�bl�b�l az adott k�nyvet, majd visszat�r�si �rt�kk�nt adja vissza,
--hogy h�ny p�ld�ny van m�g a kit�r�lt k�nyvb?l ugyanazzal az ISBN sz�mmal. Ha a rakt�ri sz�m nem l�tezik,
--akkor ne t�rt�njen semmi.

--A list�z nev? elj�r�shoz defini�ljunk egy priv�t kurzort,
--amely param�terk�nt kapott ISBN sz�mhoz list�zza a rakt�ri sz�mokat, a k�nyv c�meket, a k�nyv kiad�kat
--�s a kiad�s �v�t. Az elj�r�s megnyitja a kurzort, ha m�g nincs nyitva, egy sort felolvas, majd param�terk�nt
--visszaadja az eredm�nyeket. (Ezt egy publikus rekort�pusban tegy�k meg.) Ha a kurzorban nem tal�lnuk t�bb sort,
--akkor null �rt�ket adjunk vissza. Ha nem tal�l ilyen ISBN sz�m� k0�nyvet, akkor nincs ilyen k�nyv kiv�telt dob.

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

--Pr�b�ljuk ki az el?z? feladat csomagj�nak az esz�zeit. Vegy�nk fel a t�bl�ba sorokat, ugyanolyan ISBN sz�mmal rendelkez?eket is, pr�b�ljuk ki a lehets�ges kiv�teleket.
--T�r�lj�nk k�nyvet, n�zz�k meg a f�ggv�ny visszat�r�si �rt�k�t, pr�b�ljuk ki a lehets�ges kiv�telt, kapjuk el.
--A list�zd pr�b�ljuk ki �gy, hogy adott ISBN sz�mhoz minden l�tez? p�ld�nyt list�zzunk ki. Pr�b�ljuk ki itt is a kiv�telt, kapjuk el


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
        then DBMS_Output.Put_Line(''Dobtam egy nem megfelel? k�nyv kiv�telt'');
    end;
    begin
        P_FIRST_PACKAGE.BESZUR_KONYV(11111111110, ''A kis kutya'', ''Kiado kft'', 2000, 1);
        exception when P_FIRST_PACKAGE.letezo_raktari_szam
        then DBMS_OUTPUT.PUT_LINE(''L�TEZ? RAKT�RI SZ�M KIV�TELT DOBTAM'');
    end;

    DBMS_OUTPUT.PUT_LINE(''T�R�L: ''||P_FIRST_PACKAGE.TOROL_KONYV(3));

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

