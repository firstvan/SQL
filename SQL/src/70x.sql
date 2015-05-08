---701
--Írjunk tárolt eljárást, amely paraméterként kapott ügyfél nevéhez képernyőre
--listázza az ügyfél által megrendelt termékek nevét (mindegyiket csak egyszer). 
--Az eljárás végén képernyőre írja az összértéket, amelyért az ügyfél eddig összesen rendelt.
--(A feladat első részét kurzor for ciklussal oldjuk meg.)
begin
HDBMS15.Megoldas_feltolt(701, '
create or replace procedure t_p_ugyfeltermek(nev varchar2) is
s number := 0;
begin
  for i IN (select product_name from OE.PRODUCT_INFORMATION 
            where product_id in (select product_id from OE.ORDER_ITEMS 
            where order_id in (select order_id from OE.ORDERS
            where customer_id = (select customer_id from OE.CUSTOMERS where cust_first_name||'' ''||cust_last_name = nev)))
            group by product_name)
  loop
    DBMS_output.put_line(i.product_name);
  end loop;
  
  select sum(unit_price * quantity) into s from OE.ORDER_ITEMS 
            where order_id in (select order_id from OE.ORDERS 
            where customer_id = (select customer_id from OE.CUSTOMERS where cust_first_name||'' ''||cust_last_name = nev));
  DBMS_OUTPUT.PUT_LINE(''Total price: '' || s);
  
end;/');

end;

begin
  t_p_ugyfeltermek('Gustav Steenburgen');
end;

select * from OE.ORDER_ITEMS 
            where order_id in (select order_id from OE.ORDERS 
            where customer_id = (select customer_id from OE.CUSTOMERS where cust_first_name||' '||cust_last_name = 'Gustav Steenburgen'));



select * from OE.CUSTOMERS;


----702-----
---Írjunk triggert, amely akkor indul el, ha a customer táblába új sor kerül
--be vagy a customer tábla marital_status vagy gender oszlop módosul.
--A trigger vizsgálja meg, hogy a gender-nek megfelel-e a marital_status.
--Nő esetén hajadon, férjes, özvegy lehet a marital_status, férfi esetén nőtlen, 
--nős, özvegy lehet a marital status. Ha nem felel meg a két oszlop egymásnak,
--akkor dobjunk felhasználói kivételt -20010-es kóddal és "Nem megfelelő nem és/vagy családi állapot" üzenettel.

begin
HDBMS15.Megoldas_feltolt(702, '
create or replace trigger trig_nos after Insert or update of marital_status or update of gender on CUSTOMERS
FOR EACH ROW
declare 
v_cust customers%rowtype;
marital varchar2(50);
gender varchar2(50);
begin
  if :NEW.gender = ''Nő'' and not (:new.marital_status = ''hajadon'' or :new.marital_status = ''férjes'' or :new.marital_status = ''özvegy'') 
  then
    raise_application_error(-20010, ''Nem megfelelő nem és/vagy családi állapot'');
  end if;
  
  if :NEW.gender = ''Férfi'' and not (:new.marital_status = ''nőtlen'' or :new.marital_status = ''nős'' or :new.marital_status = ''özvegy'') 
  then
    raise_application_error(-20010, ''Nem megfelelő nem és/vagy családi állapot'');
  end if;
    
end;/');
end;

select *  from customers;


---703

--Az előző feladat triggerét próbáljuk ki beszúrással és módosítással is. A kapott kivételt kapjuk el és kezeljük.
begin
HDBMS15.Megoldas_feltolt(703, '
declare
beszur_kivetel EXCEPTION;
PRAGMA EXCEPTION_INIT(beszur_kivetel, -20010);
begin
begin
  Insert into customers (customer_id, cust_first_name, cust_last_name, marital_status, gender)
  values (997, ''Vago'',''Pista'',''férjes'', ''férfi''); 
  exception 
    when beszur_kivetel then
      dbms_output.put_line(SQLERRM);
end;
begin
  update customers 
  set marital_status = ''hajdon''
  where customer_id= 999;
  exception 
    when beszur_kivetel then
      dbms_output.put_line(SQLERRM);
end;
end;/');
end;



-----704------
select * from HDBMS15.FELADATAIM where AZON = 704;
--Írjunk triggert, amely akkor indul el, amikor új ügyfelet vagy terméket veszünk fel vagy ügyfelet vagy terméket törlünk.
--A trigger egy új, napló nevű táblába írja be, hogy melyik felhasználó, mikor melyik táblábát módosította és milyen műveletet hajtott végre. 

select user from dual; 

begin DBMS_OUTPUT.PUT_LINE(user); end;
drop table product_information;
create table product_information as (select * from OE.PRODUCT_INFORMATION);

create table naplo ( 
felhasznalo varchar2(50),
tabla varchar2(50),
mikor date primary key,
muvelet varchar2(50)
);

begin
HDBMS15.MEGOLDAS_FELTOLT(704, '
create or replace trigger trig_naploz after insert or delete on customers
for each row
begin
if DELETING then
insert into naplo (felhasznalo, tabla, mikor, muvelet)
values (user, ''Customers'', sysdate, ''DELETE'');
end if;

if INSERTING then
insert into naplo (felhasznalo, tabla, mikor, muvelet)
values (user, ''Customers'', sysdate, ''INSERT'');
end if;

end;/

create or replace trigger trig_naploz_pri after insert or delete on product_information
for each row
begin
if DELETING then
insert into naplo (felhasznalo, tabla, mikor, muvelet)
values (user, ''product_information'', sysdate, ''DELETE'');
end if;

if INSERTING then
insert into naplo (felhasznalo, tabla, mikor, muvelet)
values (user, ''product_information'', sysdate, ''INSERT'');
end if;

end;/');
end;

---705
select * from HDBMS15.FELADATAIM where AZON = 705;

--Az előző feladat triggerét próbáljuk ki több művelet segítségével.
select * from PRODUCT_INFORMATION where PRODUCT_ID=9999;

begin
HDBMS15.MEGOLDAS_FELTOLT(705, '
declare
r naplo%rowtype;
begin

insert into product_information (Product_id, product_name) values (9999, ''RAM 1TB'');

delete from product_information where product_id=9999;

for i in (select * into r from naplo)
loop
  DBMS_OUTPUT.PUT_LINE(i.felhasznalo||'' ''|| i.tabla||'' ''||i.mikor||'' ''||i.muvelet);
end loop;

end;/');
end;

---706
select * from HDBMS15.FELADATAIM where AZON = 706;

--Hozzunk létre táblát hallgatok néven. A táblának két oszlop legyen, az egyikben a hallgató nevét,
--a másikban a hallgató neptunkódját tároljuk. Ez utóbbi legyen a tábla elsődleges kulcsa. 
drop table hallgatok;
begin
HDBMS15.MEGOLDAS_FELTOLT(706, '
create table hallgatok (
hallgato_nev varchar2(50),
hallgato_neptunkod varchar2(6),
constraint c_neptunkod PRIMARY KEY (hallgato_neptunkod)
);/');
end;


---707
select * from HDBMS15.FELADATAIM where AZON = 707;

--Írjunk triggereket, amelyek a hallgató táblából való törlésre indul el, rendre utasítás előtt, sor előtt, utasítás után, sor után.
--A triggerek írják ki a képernyőre, hogy ők éppen melyik triggerek, azaz utasítás előtt/után, sor előtt/után.
begin
HDBMS15.MEGOLDAS_FELTOLT(707, '
CREATE OR REPLACE TRIGGER osszetett_trigger
FOR DELETE ON HALLGATOK
COMPOUND TRIGGER

before statement is 
begin
 DBMS_OUTPUT.PUT_LINE(''BEFORE STATEMENT'');
end before statement;

before EACH ROW is 
begin
 DBMS_OUTPUT.PUT_LINE(''BEFORE EACH ROW'');
end before EACH ROW;

after EACH ROW is 
begin
 DBMS_OUTPUT.PUT_LINE(''AFTER EACH ROW'');
end after EACH ROW;

after STATEMENT is
begin
 DBMS_OUTPUT.PUT_LINE(''AFTER STATEMENT'');
end AFTER STATEMENT;

end osszetett_trigger;/');
end;

----708
select * from HDBMS15.FELADATAIM where AZON = 708;

--Töröljünk egyszerre 5 sort a hallgatok táblából, amivel kipróbáljuk az előző triggert. 
--Majd írjunk olyan törlést, amely egyetlen sort sem tötöl. Nézzük meg a triggerek által kiírt eredményt.
begin
INSERT INTO HALLGATOK (HALLGATO_NEV, HALLGATO_NEPTUNKOD) values ('A', 'AAAAAA');
INSERT INTO HALLGATOK (HALLGATO_NEV, HALLGATO_NEPTUNKOD) values ('B', 'AAAAAB');
INSERT INTO HALLGATOK (HALLGATO_NEV, HALLGATO_NEPTUNKOD) values ('C', 'AAAAAC');
INSERT INTO HALLGATOK (HALLGATO_NEV, HALLGATO_NEPTUNKOD) values ('D', 'AAAAAD');
INSERT INTO HALLGATOK (HALLGATO_NEV, HALLGATO_NEPTUNKOD) values ('E', 'AAAAAE');
INSERT INTO HALLGATOK (HALLGATO_NEV, HALLGATO_NEPTUNKOD) values ('F', 'AAAAAF');
end;

select * from HALLGATOK;

begin
HDBMS15.MEGOLDAS_FELTOLT(708, '
DELETE from HALLGATOK where HALLGATO_NEPTUNKOD in (''AAAAAA'',''AAAAAB'',''AAAAAC'',''AAAAAD'',''AAAAAE'');/

DELETE FROM HALLGATOK WHERE HALLGATO_NEPTUNKOD= ''AAAAAA'';
/');
end;

select * from HDBMS15.MEGOLDASAIM;