select * from  HDBMS15.MEGOLDASAIM;

select * from HDBMS15.FELADATAIM where azon = 901;

--�rj t�rolt elj�r�st, amely param�terk�nt kap egy sztringet (clob-ot),
--majd a k�perny?re list�zza abc sorrendben, hogy melyik bet?b?l h�ny darab van.
--Csak azokat a bet?ket list�zza, amelyek szerepelnek a sz�vegben. A feladat megold�s�hoz asszociat�v t�mb�t haszn�lj.

begin
HDBMS15.MEGOLDAS_FELTOLT(901,'
create or replace PROCEDURE t_p_betuszamlal (szoveg in CLOB) is
lowerszoveg CLOB;
type tomb is table of integer index by varchar2(1);
characters tomb;
position BINARY_INTEGER:= 1;
size1 BINARY_INTEGER := 1;
asd varchar2(1) := ''0'';
begin
    lowerszoveg := lower(szoveg);
    characters.delete();
    loop
        begin
            DBMS_LOB.READ (lowerszoveg, size1, position, asd);
            position := position + 1;

            if characters.exists(asd) then
                characters(asd) := characters(asd) + 1;
            else
                characters(asd) := 1;
            end if;

            exception
                when no_data_found
                then exit;
        end;
    end loop;

    for i in ascii(''a'')..ascii(''z'')
    loop
        asd := chr(i);
        if characters.exists(asd) then
            DBMS_OUTPUT.PUT_LINE(chr(i) ||'': ''|| characters(asd));
        end if;
    end loop;
end;/');
end;

begin
    T_P_BETUSZAMLAL('HELLO EVERYBODY');
end;


select * from HDBMS15.FELADATAIM where azon = 902;

--H�vd meg az el?z? t�rolt elj�r�st k�l�nb�z? sztringekkel.

begin
HDBMS15.MEGOLDAS_FELTOLT(902, '
begin
    T_P_BETUSZAMLAL(''HELLO EVERYBODY'');
    T_P_BETUSZAMLAL(''KECSKEMET'');
    T_P_BETUSZAMLAL(''KisKutyja nagyKutja'');
end;/');
end;

select * from HDBMS15.FELADATAIM where azon = 903;

--�rj t�rolt elj�r�st, amely param�terk�nt egy sztringet kap, �s amelyr?l felt�telezz�k, hogy egy lek�rdez�st tartalmaz.
--Az elj�r�s vizsg�lja meg, hogy a sztring els? szava select-e, ha nem, akkor dobjon felhaszn�l�i kiv�telt 'Nem lek�rdez�s' �zenettel.
--Ha igen, akkor felt�telezz�k a lek�rdez�sr?l, hogy egy olyan rekorddal t�r vissza, amelynek k�t karaktersorozat t�pus� oszlopa van. Az elj�r�s list�zza a k�perny?re a lek�rdez�s eredm�ny�t.
--Ha a lek�rdez�s nem megfelel?, akkor az elj�r�s felhaszn�l�i kiv�telt adjon 'Nem megfelel? lek�rdez�s' �zenettel kieg�sz�tve a kiv�lt� kiv�tel k�dj�val �s �zenet�vel.
begin
HDBMS15.MEGOLDAS_FELTOLT(903, '
create or replace procedure t_sajatselect(lekerdezes in clob) is
type rec is record(elso varchar2(50), masodik varchar2(50));
type tb is table of rec;
mytb tb;
temp number;
tempstring varchar2(20);
temp2 rec;
begin
    temp := DBMS_LOB.INSTR(lekerdezes, '' '') - 1;
    tempstring := dbms_lob.substr(lekerdezes, temp);
    if lower(tempstring) != ''select'' then
        raise_application_error(-20010, ''Nem lek�rdez�s'');
    end if;

    execute immediate lekerdezes bulk collect into mytb;

    for i in 1..mytb.count
    loop
        DBMS_OUTPUT.PUT_LINE(mytb(i).elso || '' '' ||mytb(i).masodik);
    end loop;

    exception
    when others
    then raise_application_error(-20011, ''Nem megfelel? lek�rdez�s: ''||sqlcode || '' '' || sqlerrm);
end;/');
end;

select * from HDBMS15.FELADATAIM where azon = 904;

--H�vd meg az el?z? feladat elj�r�s�t a k�vetkez? lek�rdez�sekre:
-- - a hr s�ma alap�n melyek azon a r�gi�nevek, �s h�ny orsz�g tartozik hozz�juk, amelyekhez legal�bb 2 orsz�g tartozik
-- - a legfiatalabb menedzserhez tartoz� dolgoz�k neve
-- - select 1,2 from dual
-- - select 1 from dual
-- - update (azaz nem m?k�d? lek�rdez�sre)



begin
HDBMS15.MEGOLDAS_FELTOLT(904, '
begin
    t_sajatselect(''select REGION_NAME, count(*) from HR.REGIONS r, HR.COUNTRIES c
                   where r.REGION_ID=c.REGION_ID
                   group by REGION_NAME
                   having count(*) > 2;'');
    /*t_sajatselect(''select FIRST_NAME, LAST_NAME from hr.EMPLOYEES where JOB_ID in (select JOB_ID from HR.JOBS where lower(JOB_TITLE) like ''%manager%'')
                    and HIRE_DATE = (select max(HIRE_DATE) from hr.EMPLOYEES where JOB_ID in (select JOB_ID from HR.JOBS where lower(JOB_TITLE) like ''%manager%''));
                    '');*/
    t_sajatselect(''select 1,2 from dual'');
    t_sajatselect(''select 1 from dual'');
    t_sajatselect(''update something'');

    exception
    when others
    then DBMS_output.PUT_LINE(sqlcode || '' '' || sqlerrm);
end;/');
end;

create table dummy (
elso varchar2(30),
masodik varchar2(30)
);

select * from dummy;

select REGION_NAME, count(*) from HR.REGIONS r, HR.COUNTRIES c
where r.REGION_ID=c.REGION_ID
group by REGION_NAME
having count(*) > 2;

select count(*) from HR.COUNTRIES
group by REGION_ID
having count(*) > REGION_ID;

select FIRST_NAME, LAST_NAME from hr.EMPLOYEES where JOB_ID in ('FI_MGR', 'AC_MGR', 'SA_MAN', 'PU_MAN', 'ST_MAN', 'MK_MAN')
and HIRE_DATE = (select max(HIRE_DATE) from hr.EMPLOYEES where JOB_ID in ('FI_MGR', 'AC_MGR', 'SA_MAN', 'PU_MAN', 'ST_MAN', 'MK_MAN'));


select JOB_ID from HR.JOBS where lower(JOB_TITLE) like '%manager%';

select * from HDBMS15.FELADATAIM where azon = 905;
--�rjunk t�rolt f�ggv�nyt, amely param�terk�nt kap egy warehouse nevet, �s visszaad egy be�gyazott t�bl�t,
--amely az adott warehouse-ban l�v? �sszes term�k nev�t (product_name a product_descriptionb�l) tartalmazza (mindegyiket csak egyszer).
--A feladatot egy�ttes hozz�rendel�ssel oldd meg.



begin
HDBMS15.MEGOLDAS_FELTOLT(905, '
CREATE OR REPLACE TYPE t_warhouse_termek is table OF VARCHAR2(30);/
create or replace function t_warhouse(warhouse in varchar2) return T_WARHOUSE_TERMEK is
temp T_WARHOUSE_TERMEK;
stmt clob;
begin
    select distinct  PRODUCT_NAME bulk collect into temp from OE.PRODUCT_INFORMATION where PRODUCT_ID in (select PRODUCT_ID from OE.INVENTORIES where WAREHOUSE_ID = (select WAREHOUSE_ID from OE.WAREHOUSES where WAREHOUSE_NAME = warhouse));

    return temp;
end;/');
end;

select distinct  PRODUCT_NAME from OE.PRODUCT_INFORMATION where PRODUCT_ID in (select PRODUCT_ID from OE.INVENTORIES where WAREHOUSE_ID = (select WAREHOUSE_ID from OE.WAREHOUSES where WAREHOUSE_NAME = ''Beijing''));

select * from OE.WAREHOUSES;


select * from HDBMS15.FELADATAIM where azon = 906;
--H�vjuk meg az el?z? t�rolt f�ggv�nyt, �s �rjuk ki a k�perny?re a kapott kollekci� tartalm�t.

begin
HDBMS15.MEGOLDAS_FELTOLT(906, '
declare
temp T_WARHOUSE_TERMEK;
begin
    temp := T_WARHOUSE(''Beijing'');

    for i in temp.first..temp.last
    loop
        DBMS_OUTPUT.PUT_LINE(temp(i));
    end loop;
end;
/');
end;

create or replace function t_warhouse(warhouse in varchar2) return T_WARHOUSE_TERMEK is
temp T_WARHOUSE_TERMEK;
stmt clob;
begin
    select distinct  PRODUCT_NAME bulk collect into temp from OE.PRODUCT_INFORMATION where PRODUCT_ID in (select PRODUCT_ID from OE.INVENTORIES where WAREHOUSE_ID = (select WAREHOUSE_ID from OE.WAREHOUSES where WAREHOUSE_NAME = warhouse));

    return temp;
end;


select * from HDBMS15.FELADATAIM;

--�rj blokkot, amelyben deklar�lsz h�rom be�gyazott t�bl�t, amelynek az elemei rendre job_title-k, min_salary-k �s max_salary-k lesznek.
--Olvasd fel a kollekci�kba a jobs t�bla minden sor�t. Majd t�r�ld ki azokat a job_title-ket, amelyek eset�n a min_salary t�bb, mint a max_salary fele.
--List�zd a megmaradt job_title-ket a k�perny?re. Majd minden olyan dolgoz�nak, akik ebben a kollekci�ban maradt munkak�rben dolgozik, emelj�k meg a fizet�s�t a max_salary 10%-�val.
--A feladatban haszn�ld az egy�ttes hozz�rendel�st (BULK COLLECT, FORALL). Ne feledd v�gleges�teni a tranzakci�t.

begin
HDBMS15.MEGOLDAS_FELTOLT(907, '
declare
type job_t is table of HR.JOBS.JOB_TITLE%type;
type min_s is table of HR.JOBS.MIN_SALARY%type;
type max_s is table of HR.JOBS.MAX_SALARY%type;
job job_t;
mina min_s;
maxa max_s;
begin
    select job_title, min_salary, max_salary bulk collect into job, mina, maxa from HR.JOBS;

    for i in job.first..job.last
    loop
        if mina(i) > maxa(i) then
            job.delete(i);
        end if;
    end loop;

    for i in 1..job.count
    loop
        DBMS_OUTPUT.PUT_LINE(job(i));
    end loop;

    forall i in 1..job.count
        update EMPLOYEES
        set SALARY = SALARY * 1.10
        where job_id in (select JOB_ID from HR.JOBS where JOB_TITLE = job(i));

    exception
    when others
    then null;
end;
/');
end;

select * from hr.EMPLOYEES where job_id in (select JOB_ID from JOBS where JOB_TITLE = job(i));
create table EMPLOYEES as select * from HR.EMPLOYEES;
