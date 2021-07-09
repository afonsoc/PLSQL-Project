/*Dropping tables*/

DROP TABLE logs;
DROP TABLE department;
DROP TABLE crew;
DROP TABLE quarters;
DROP TABLE species;
/*------------------------*/

/*Dropping sequences*/

DROP SEQUENCE species_sequence;
DROP SEQUENCE crew_sequence;
DROP SEQUENCE department_sequence;
/*------------------------*/

/*Creation of tables*/

CREATE TABLE species(
    speciesid number(10) NOT NULL,
    speciesname varchar2(50) NOT NULL,
    speciesplanet varchar2(50) NOT NULL,
    CONSTRAINT species_pk PRIMARY KEY (speciesid)
);

CREATE TABLE quarters(
    quartersid number(10) NOT NULL,
    quartersname varchar2(50)NOT NULL,
    CONSTRAINT quarters_pk PRIMARY KEY (quartersid)
);

CREATE TABLE crew(
    crewid number(10) NOT NULL,
    crewname varchar2(50) NOT NULL,
    crew_speciesid number(10) NOT NULL,
    crewaccesslevel number(5) NOT NULL,
    crewrole varchar2(20) NOT NULL,
    CONSTRAINT crew_pk PRIMARY KEY (crewid),
    CONSTRAINT crew_species_fk FOREIGN KEY (crew_speciesid) REFERENCES species(speciesid)
);

CREATE TABLE department(
    deptid number(10) NOT NULL,
    deptname varchar2(50) NOT NULL,
    nremps number(30) NOT NULL,
    dept_quartersid number(10) NOT NULL,
    CONSTRAINT dept_pk PRIMARY KEY (deptid),
    CONSTRAINT dept_quarters_fk FOREIGN KEY (dept_quartersid) REFERENCES quarters(quartersid)
);

CREATE TABLE logs(
    logs_crewid number(10) NOT NULL,
    logs_deptid number(10) NOT NULL,
    CONSTRAINT logs_crew_fk FOREIGN KEY (logs_crewid) REFERENCES crew(crewid),
    CONSTRAINT logs_dept_fk FOREIGN KEY (logs_deptid) REFERENCES department(deptid)
);

CREATE TABLE species_audit(
    auditid number(10) NOT NULL,
    new_name varchar2(50),
    old_name varchar2(50),
    entrydate varchar2(50),
    operation varchar2(50),
    CONSTRAINT species_audit_PK PRIMARY KEY (auditid)
);

CREATE TABLE schema_audit(
    schema_id number(10),
    ddl_date date,
    object_created varchar2(50),
    object_name varchar2(50),
    ddl_operation varchar2(50),
    CONSTRAINT schema_id_PK PRIMARY KEY (schema_id)
);

/*------------------------*/

/*Creating indexes*/

CREATE INDEX logs_index
ON logs (logs_crewid, logs_deptid)
COMPUTE STATISTICS;

CREATE INDEX crew_index
ON crew (crew_speciesid)
COMPUTE STATISTICS;

CREATE INDEX dept_index
ON department (dept_quartersid)
COMPUTE STATISTICS;


/*------------------------*/

/*creating sequences*/

CREATE SEQUENCE species_sequence;
CREATE SEQUENCE crew_sequence;
CREATE SEQUENCE department_sequence;
CREATE SEQUENCE audit_sequence;
CREATE SEQUENCE schema_sequence;

/*creating the triggers*/

CREATE OR REPLACE TRIGGER species_insert
	BEFORE INSERT ON species
	FOR EACH ROW
BEGIN
	SELECT species_sequence.nextval
	INTO :NEW.speciesid
	FROM dual;
END;
/

CREATE OR REPLACE TRIGGER species_audit_insert
    BEFORE INSERT ON species_audit
    FOR EACH ROW
BEGIN
    SELECT audit_sequence.nextval
    INTO :NEW.auditid
    FROM dual;
END;
/

CREATE OR REPLACE TRIGGER schema_audit_insert
	BEFORE INSERT ON schema_audit
	FOR EACH ROW
BEGIN
	SELECT schema_sequence.nextval
	INTO :NEW.schema_id
	FROM dual;
END;
/

CREATE OR REPLACE TRIGGER crew_insert
	BEFORE INSERT ON crew
	FOR EACH ROW
BEGIN
	SELECT crew_sequence.nextval
	INTO :NEW.crewid
	FROM dual;
END;
/

CREATE OR REPLACE TRIGGER department_insert
	BEFORE INSERT ON department
	FOR EACH ROW
BEGIN
	SELECT department_sequence.nextval
	INTO :NEW.deptid
	FROM dual;
END;
/

CREATE OR REPLACE TRIGGER actual_auditing
BEFORE INSERT OR DELETE OR UPDATE ON species
FOR EACH ROW
ENABLE
DECLARE
    v_date varchar2(50);
BEGIN
SELECT TO_CHAR(sysdate, 'DD/MON/YYYY HH24:MI:SS') INTO v_date FROM dual;
IF INSERTING THEN
    INSERT INTO species_audit(new_name, old_name, entrydate, operation)
    VALUES (:NEW.speciesname, NULL, v_date, 'INSERT');
ELSIF DELETING THEN
    INSERT INTO species_audit(new_name, old_name, entrydate, operation)
    VALUES (NULL, :OLD.speciesname, v_date, 'DELETE');
ELSIF UPDATING THEN
    INSERT INTO species_audit(new_name, old_name, entrydate, operation)
    VALUES (:NEW.speciesname, :OLD.speciesname, v_date, 'UPDATE');
END IF;
END;
/

CREATE OR REPLACE TRIGGER schema_audit_trigger
AFTER DDL ON SCHEMA
BEGIN
    INSERT INTO schema_audit (ddl_date, object_created, object_name, ddl_operation) VALUES(
        sysdate,
        ora_dict_obj_type,
        ora_dict_obj_name,
        ora_sysevent
    );
END;
/

/*------------------------*/

/*populating tables*/

INSERT INTO species (speciesname, speciesplanet) VALUES ('Lotians' ,'Sigma lotia II');
INSERT INTO species (speciesname, speciesplanet) VALUES ('Betazoid' ,'Betazed');
INSERT INTO species (speciesname, speciesplanet) VALUES ('The Trill' ,'Trill');
INSERT INTO species (speciesname, speciesplanet) VALUES ('Bajorans' ,'Bajor');

INSERT INTO quarters (quartersid, quartersname) VALUES (1, 'Medical Quarters');
INSERT INTO quarters (quartersid, quartersname) VALUES (2, 'Kitchen');
INSERT INTO quarters (quartersid, quartersname) VALUES (3, 'Navigation Quarters');
INSERT INTO quarters (quartersid, quartersname) VALUES (4, 'Engineerig Quarters');

INSERT INTO crew (crewname, crew_speciesid, crewaccesslevel, crewrole) VALUES ('Montgomery Scott', 1, 5, 'Captain');
INSERT INTO crew (crewname, crew_speciesid, crewaccesslevel, crewrole) VALUES ('Deanna Troi', 2, 4, 'Vice-Captain');
INSERT INTO crew (crewname, crew_speciesid, crewaccesslevel, crewrole) VALUES ('Jadzia Dax', 3, 2, 'Lieutenant');
INSERT INTO crew (crewname, crew_speciesid, crewaccesslevel, crewrole) VALUES ('Kira Nerys', 4, 1, 'Cadet');

INSERT INTO department (deptname, nremps, dept_quartersid) VALUES ('Medical Department', 2, 1);
INSERT INTO department (deptname, nremps, dept_quartersid) VALUES ('Nutrition Department',2 ,2);
INSERT INTO department (deptname, nremps, dept_quartersid) VALUES ('Navigation Department', 3, 3);
INSERT INTO department (deptname, nremps, dept_quartersid) VALUES ('Engineering Department', 2, 4);

INSERT INTO logs (logs_crewid, logs_deptid) VALUES (1, 3);
INSERT INTO logs (logs_crewid, logs_deptid) VALUES (2, 2);
INSERT INTO logs (logs_crewid, logs_deptid) VALUES (3, 4);
INSERT INTO logs (logs_crewid, logs_deptid) VALUES (4, 1);

/*------------------------*/

/*Creating procedures*/

CREATE OR REPLACE PROCEDURE display_crew
AS
BEGIN
	DBMS_OUTPUT.PUT_LINE('Displaying all crew members: ');
	FOR record IN ( SELECT  species.speciesname, crew.crewname, crew.crewrole, crew.crewaccesslevel
                    FROM    species, crew  
                    WHERE   crew.crew_speciesid = species.speciesid) 
    LOOP
        DBMS_OUTPUT.PUT_LINE('> species: ' || record.speciesname || ', Name: ' || record.crewname || ', Role: ' || record.crewrole || ', Access Level: ' || record.crewaccesslevel);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
END;
/

EXEC display_crew



CREATE OR REPLACE PROCEDURE display_departments
AS
BEGIN
	DBMS_OUTPUT.PUT_LINE('Displaying ship departments: ');
	FOR record IN ( SELECT  department.deptname, department.nremps, quarters.quartersname
                FROM   department, quarters
		WHERE department.dept_quartersid = quarters.quartersid)
    	LOOP
        DBMS_OUTPUT.PUT_LINE ('> Department: ' || record.deptname || ', Number of employees: ' || record.nremps || ', Quarter: ' || record.quartersname);
    	END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('...execution completed!');
    DBMS_OUTPUT.PUT_LINE('');
END;
/

EXEC display_departments

CREATE OR REPLACE PROCEDURE display_species
AS
BEGIN
	DBMS_OUTPUT.PUT_LINE('Displaying species and their planets: ');
	FOR record IN (SELECT speciesname, speciesplanet 
	FROM species)
	LOOP
	   DBMS_OUTPUT.PUT_LINE('>species: ' || record.speciesname || ', Planet of Origin: ' || record.speciesplanet);
	END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
END;
/

EXEC display_species

CREATE OR REPLACE PROCEDURE display_crew_dept
AS
BEGIN
	DBMS_OUTPUT.PUT_LINE('Displaying all crew members: ');
	FOR record IN ( SELECT crew.crewname, crew.crewrole, crew.crewaccesslevel, department.deptname 
                    FROM    crew, department, logs 
                    WHERE   logs.logs_crewid = crew.crewid
                    AND  logs.logs_deptid = department.deptid)
    LOOP
        DBMS_OUTPUT.PUT_LINE('>Name: ' || record.crewname || ', Role: ' || record.crewrole || ', Access Level: ' || record.crewaccesslevel || ', Department: ' || record.deptname);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
END;
/

EXEC display_crew_dept

CREATE OR REPLACE PROCEDURE display_full_crew_details
AS
BEGIN
	DBMS_OUTPUT.PUT_LINE('Displaying full crew member details: ');
	FOR record IN (SELECT species.speciesname, crew.crewname, crew.crewrole, crew.crewaccesslevel, department.deptname, quarters.quartersname 
                    FROM    crew, department, logs, quarters, species
                    WHERE   logs.logs_crewid = crew.crewid
                    AND  logs.logs_deptid = department.deptid
                    AND  department.dept_quartersid = quarters.quartersid
                    AND  crew.crew_speciesid = species.speciesid)
	LOOP
	   DBMS_OUTPUT.PUT_LINE('>Species: ' || record.speciesname || ' Name: ' || record.crewname || ' Role: ' || record.crewrole || 'Access Level: ' || record.crewaccesslevel || ' Department: ' || record.deptname || ' Quarters: ' || record.quartersname);
	END LOOP;

	DBMS_OUTPUT.PUT_LINE('');
END;
/

EXEC display_full_crew_details


/*------------------------*/


/*creating functions*/

CREATE OR REPLACE FUNCTION retrieve_crew_species(crew_id_in IN crew.crewid%TYPE)
RETURN NCHAR
IS
    species_name_out species.speciesname%TYPE;
BEGIN
    SELECT  species.speciesname 
    INTO    species_name_out
    FROM    species, crew  
    WHERE   crew.crew_speciesid = species.speciesid 
    AND     crew.crewid = crew_id_in;
    
    RETURN species_name_out;
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Executing function retrieve_crew_species...');
    DBMS_OUTPUT.PUT_LINE('> retrieved species is: ' || retrieve_crew_species(1));
    DBMS_OUTPUT.PUT_LINE('...execution completed!');
    DBMS_OUTPUT.PUT_LINE('');
END;
/


CREATE OR REPLACE FUNCTION retrieve_crew_species2(crew_id_in IN crew.crewid%TYPE)
RETURN NCHAR
IS
    species_name_out species.speciesname%TYPE;
BEGIN
    SELECT  species.speciesname 
    INTO    species_name_out
    FROM    species, crew  
    WHERE   crew.crew_speciesid = species.speciesid 
    AND     crew.crewid = crew_id_in;
    
    RETURN species_name_out;
    
    EXCEPTION 
        WHEN no_data_found THEN
        species_name_out := 'ERROR! NO DATA FOUND!';
        RETURN species_name_out;
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Executing function retrieve_crew_species...');
    DBMS_OUTPUT.PUT_LINE('> retrieved species is: ' || retrieve_crew_species2(5));
    DBMS_OUTPUT.PUT_LINE('...execution completed!');
    DBMS_OUTPUT.PUT_LINE('');
END;
/









CREATE OR REPLACE PROCEDURE display_list
IS
        choice CHAR := 'E';
BEGIN

    DBMS_OUTPUT.PUT_LINE('List of precedures: ');
    DBMS_OUTPUT.PUT_LINE('>A: Display Crew');
    DBMS_OUTPUT.PUT_LINE('>B: Display Departments');
    DBMS_OUTPUT.PUT_LINE('>C: Display Species');
    DBMS_OUTPUT.PUT_LINE('>D: Display Crew Departments');
    DBMS_OUTPUT.PUT_LINE('>E: Display Crew full details');
   
    IF choice = 'A' THEN
        DBMS_OUTPUT.PUT_LINE(display_crew());
    ELSIF choice = 'B' THEN
        DBMS_OUTPUT.PUT_LINE(display_departments());
    ELSIF choice = 'C' THEN
        DBMS_OUTPUT.PUT_LINE(display_species());
    ELSIF choice = 'D' THEN
         DBMS_OUTPUT.PUT_LINE(display_crew_dept());
    ELSIF choice = 'E' THEN
         DBMS_OUTPUT.PUT_LINE(display_full_crew_details());
    ELSE
        DBMS_OUTPUT.PUT_LINE('Error!');
    END IF;
   
END;
/

