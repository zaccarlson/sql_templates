create or replace package body GPODS.CMS_EDITS_LIB
as
/*------------------------------------------------------------------------------
    Program:  CMS_EDITS_LIB
    Author:   Zac Carlson
    Date:     December 2019
    For:      HealthPartners
    
    Purpose:
    
      This library package was designed to encapsulate logic used in determining
      if a claim is valid to send to CMS. These edits may be used in any 
      permutation by downstream processes
    
    Documentation:
    
      All edits are built in the form of ASK QUESTION then return an answer
      in the form of the literal string TRUE or FALSE so that these edits can
      be used in both PL/SQL and SQL.
      As much as possible the edit function names are written so that a TRUE
      result means that the input is valid but for ease of wording this rule is
      not always true. For example "IS_CLAIM_VOIDED" cannot be easly worded to
      return a TRUE value to mean the claim is not voided.
     
    Modification History:
    
------------------------------------------------------------------------------*/

function IS_NUMERIC (p_string in varchar2) return boolean is
/*------------------------------------------------------------------------------
    Program:  IS_NUMERIC
    Author:   Zac Carlson
    Date:     2 April 2012
    For:      Park Nicollet
    
    Purpose:
    
      Determines if incoming data is numeric or not.
    
    Documentation:
    
      
    
    Input Parameters:
      
      p_string - varchar2 input to compare if it is numeric
      
    Output Parameters:
    
      True or False depending if the input stringis numeric

    Dependencies:
    
      None.
    
    Modification History:
    
------------------------------------------------------------------------------*/
  --
  --Variable definitions
  --
  v_number                        number; 

begin 
  
  --
  --Convert incoming string to number
  --
  v_number := to_number(p_string); 
  
  --
  --If no error return true
  --
  return true;
  
exception
  --
  --On error return false
  --
  when value_error then return false; 

end IS_NUMERIC;

function IS_HCFA_1500 (p_encounter_num in number) return varchar2 is

--
-- This function checks to be sure the encounter was a HCFA 1500
-- it returns a TRUE if so, FALSE if not
-- 

    l_encounter_num                   number;
    l_claim_form_type                 varchar2(30);

begin

l_encounter_num := p_encounter_num;

select
    clmvarclmformtype into l_claim_form_type
from
    cdcods.ENCOUNTERS
where
    ENCOUNTERS.enctrnum = l_encounter_num;

if l_claim_form_type = 'HCFA 1500' then
    return 'TRUE';
else return 'FALSE';
end if;

exception 
    when no_data_found then

        return 'FALSE';

end IS_HCFA_1500;

function IS_VALID_CLAIM (p_claim_num in number) return varchar2 is

--
-- This function checks to be sure the claim exists 
-- it returns a TRUE if so, FALSE if not
-- 

    l_claim_num_to_check              number;
    l_claim_num_lookup                number;

begin

l_claim_num_to_check := p_claim_num;

select
    clmnum into l_claim_num_lookup
from
    cdcods.CLAIMS
where
    CLAIMS.clmnum = l_claim_num_to_check;

return 'TRUE';

exception 
    when no_data_found then

        return 'FALSE';

end IS_VALID_CLAIM;

function IS_VALID_PERSON (p_person_identifier in varchar2, p_identifier_type in varchar2) return varchar2 is

--
-- This function checks to be sure a member (person) exists
-- Because have have multiple ways to identify a member it takes an incoming
-- number and a type. 
-- it returns a TRUE if so, FALSE if not
--
-- The types allowed are : PERSON_NO, EXTERNAL_PERSON_ID
-- 

    l_lookup_column                   varchar2(61);
    l_person_to_check                 number;
    l_person_lookup                   varchar2(30);
    l_sql                             varchar2(4000);

begin

--
-- Check input parameter for person identifier type and set dynamic sql 
-- variables/sanitize inputs
--
if p_identifier_type = 'PERSON_NO'
    then l_lookup_column := 'PERSON_DS.person_no';
elsif p_identifier_type = 'EXTERNAL_PERSON_ID'
    then l_lookup_column := 'PERSON_DS.external_person_id';
else
    raise_application_error(-20101, 'Person indentifier type is not valid (PERSON_NO, EXTERNAL_PERSON_ID): "' || p_identifier_type || '"' );
end if;

--
-- Check to see if person indentifier is numeric (both these values are in 
-- the PERSON_DS table) and if not end and return FALSE otherwise set to a
-- numeric value so we can do the lookup in the table
--
if IS_NUMERIC(p_person_identifier) = FALSE then return 'FALSE'; end if;

l_person_to_check := to_number(p_person_identifier);

--
-- Build dynamic SQL statement  using lookup column name from previous steps
-- Then execute the SQL using a bind variable for the ID value
--
l_sql := 'select person_no from mods.PERSON_DS where ' || l_lookup_column || ' = :id';

execute immediate l_sql into l_person_lookup using l_person_to_check;

return 'TRUE';

exception 
    when no_data_found then

        return 'FALSE';

end IS_VALID_PERSON;

function IS_VALID_ICD_CODE (p_icd_code in varchar2) return varchar2 is

--
-- This function checks to be sure the ICD code exixts in the ICD Dictionary
-- it returns a TRUE if so, FALSE if not
-- 

    l_icd_code_to_check               varchar2(100);
    l_icd_code_lookup                 varchar2(100);

begin

l_icd_code_to_check := p_icd_code;

select
    icdcode into l_icd_code_lookup
from
    cdcods.ICDCODE
where
    icdcode = l_icd_code_to_check and
    icdcodetypenbr = 27;

return 'TRUE';

exception 
    when no_data_found then

        return 'FALSE';

end IS_VALID_ICD_CODE;

function IS_RECV_DT_IN_THRESHOLD (p_claim_num in number, p_threshold_num in number, p_threshold_type in varchar2) return varchar2 is

--
-- This function checks to be sure the claim was received within a specified time period
-- This was built to accept a claim number and the desired threshold time. The threshold
-- type can be days, weeks, months, or years. More grainular time periods don't make sense.
-- Plurals are used to maintain natural english when passing parameters in:
-- 123456, 12, months
-- it returns a TRUE if so, FALSE if not
-- 

    l_threshold_low_date              date;
    l_claim_received_date             date;
    l_claim_num_to_check              number;

begin

--
-- Decode the input parameters to find the appropriate threshold beging date
-- Use trunc dates (00:00:00) since time should not matter
--
if upper(p_threshold_type) = 'YEARS' then
    l_threshold_low_date := add_months(trunc(sysdate),to_number('-' || (p_threshold_num*12)));
elsif upper(p_threshold_type) = 'MONTHS' then 
    l_threshold_low_date := add_months(trunc(sysdate),to_number('-' || p_threshold_num));
elsif upper(p_threshold_type) = 'WEEKS' then 
    l_threshold_low_date := trunc(sysdate) - (7 * p_threshold_num);
elsif upper(p_threshold_type) = 'DAYS' then 
    l_threshold_low_date := trunc(sysdate) - p_threshold_num;
else
    raise_application_error(-20101, 'Threshold type must be (YEARS, MONTHS, WEEKS, or DAYS): "' || p_threshold_type || '"' );
end if;

l_claim_num_to_check := p_claim_num;

select
    max(recv_dt) into l_claim_received_date
from
    cdcods.AP_GL_DAILY_CLAIM_IS
where
    claim_no = l_claim_num_to_check;

if l_claim_received_date >= l_threshold_low_date then 
    return 'TRUE';
else 
    return 'FALSE';
end if;

exception 
    when no_data_found then

        return 'FALSE';

end IS_RECV_DT_IN_THRESHOLD;

function IS_CLAIM_VOIDED (p_claim_num in number) return varchar2 is

--
-- This function checks if a claim has been voided. 
-- it returns a TRUE if so, FALSE if not
-- 

    l_claim_num_to_check              number;
    l_void_status                     cdcods.CLAIMS.voidstatus%type;

begin

l_claim_num_to_check := p_claim_num;

select
    voidstatus into l_void_status
from
    cdcods.CLAIMS
where
    clmnum = l_claim_num_to_check;

if l_void_status = 'V' then 
    return 'TRUE';
else 
    return 'FALSE';
end if;

exception 
    when no_data_found then

        return 'FALSE';

end IS_CLAIM_VOIDED;

function IS_CLAIM_DENIED (p_claim_num in number) return varchar2 is

--
-- This function checks if a claim has been voided. 
-- it returns a TRUE if so, FALSE if not
-- 

    l_claim_num_to_check              number;
    l_acceptance_status               cdcods.CLAIMS.acceptancestatus%type;
    l_claim_line_cnt                  pls_integer;
    l_claim_line_denied_cnt           pls_integer;

begin

l_claim_num_to_check := p_claim_num;

select
    acceptancestatus into l_acceptance_status
from
    cdcods.CLAIMS
where
    clmnum = l_claim_num_to_check;

select
    count(*) all_lines,
    sum(case
        when 
            ADJUDICATEDSVCS.cvrggrpucrexclusioncode +
            ADJUDICATEDSVCS.cvrggrpexclusioncode +
            ADJUDICATEDSVCS.cvrggrpprovexclusioncode +
            ADJUDICATEDSVCS.cvrggrpprovdisallowedcode +
            ADJUDICATEDSVCS.cgbeforeadjothrmbrliabreason > 0
        then 1
        else 0
    end) denied_lines
    into
    l_claim_line_cnt,
    l_claim_line_denied_cnt
from
    cdcods.ADJUDICATEDSVCS
where
    clmnum = l_claim_num_to_check;

if l_acceptance_status != 'A' or (l_claim_line_denied_cnt = l_claim_line_cnt) then 
    return 'TRUE';
else 
    return 'FALSE';
end if;

exception 
    when no_data_found then

        return 'FALSE';

end IS_CLAIM_DENIED;

function IS_CMS_CLAIM (p_claim_num in number) return varchar2 is

--
-- This function checks to be sure the claim exists 
-- it returns a TRUE if so, FALSE if not
-- 

    l_claim_num_to_check              number;
    l_result_count                    number;

begin

l_claim_num_to_check := p_claim_num;

select
    count(*) into l_result_count
from
    cdcods.AP_GL_DAILY_CLAIM_IS
    inner join adw.PROD_DS
        on AP_GL_DAILY_CLAIM_IS.prod_id = PROD_DS.prod_id
    inner join gpods.GP_PRODUCT_LIST_UMT
        on PROD_DS.purch_sub_tp_nm = GP_PRODUCT_LIST_UMT.purch_sub_tp_nm
where
    GP_PRODUCT_LIST_UMT.system_nm = 'CMS' and
    claim_no = l_claim_num_to_check;

if l_result_count > 0 then
    return 'TRUE';
else
    return 'FALSE';
end if;

exception 
    when no_data_found then

        return 'FALSE';

end IS_CMS_CLAIM;

function IS_CLAIM_IN_ENCOUNTER (p_claim_num in number, p_encounter_num in number) return varchar2 is

--
-- This function checks if a given claim belongs to the 
-- it returns a TRUE if so, FALSE if not
-- 

    l_claim_num_to_check              number;
    l_encounter_num                   number;
    l_enc_lookup                      number;

begin

l_claim_num_to_check := p_claim_num;

select
    enctrnum into l_enc_lookup
from
    cdcods.CLAIMS
where
    clmnum = l_claim_num_to_check;

if l_enc_lookup = p_encounter_num then 
    return 'TRUE';
else 
    return 'FALSE';
end if;

exception 
    when no_data_found then

        return 'FALSE';

end IS_CLAIM_IN_ENCOUNTER;

function IS_CLAIM_FOR_MEMBER (p_claim_num in number, p_person_identifier in varchar2, p_identifier_type in varchar2) return varchar2 is

--
-- This function checks to be sure a claim belongs to a member (person)
-- Because have have multiple ways to identify a member it takes an incoming
-- number and a type. 
-- it returns a TRUE if so, FALSE if not
--
-- The types allowed are : PERSON_NO, EXTERNAL_PERSON_ID
-- 

    l_claim_num_to_check              number;
    l_claim_person_no                 number;
    l_claim_ext_person_id             number;

begin


select
    PERSON_DS.person_no,
    PERSON_DS.external_person_id
    into
    l_claim_person_no,
    l_claim_ext_person_id
from
    cdcods.CLAIMS
    join cdcods.ENCOUNTERS
        on CLAIMS.enctrnum = ENCOUNTERS.enctrnum
    join adw.PERSON_DS
        on ENCOUNTERS.personnum = PERSON_DS.person_no
where
    CLAIMS.clmnum = p_claim_num;

--
-- Check input parameter for person identifier type then compare input values
--
if p_identifier_type = 'PERSON_NO' then
    if p_person_identifier = l_claim_person_no then
        return 'TRUE';
    else return 'FALSE';
    end if;
elsif p_identifier_type = 'EXTERNAL_PERSON_ID' then
    if p_person_identifier = l_claim_ext_person_id then
        return 'TRUE';
    else return 'FALSE';
    end if;
else
    raise_application_error(-20101, 'Person indentifier type is not valid (PERSON_NO, EXTERNAL_PERSON_ID): "' || p_identifier_type || '"' );
end if;

exception 
    when no_data_found then

        return 'FALSE';

end IS_CLAIM_FOR_MEMBER;

function HAS_DX_ALREADY_BEEN_SENT(p_encounter_num in number, p_icd_code in varchar2) return varchar2 is

--
-- This function checks if an ICD code on the encounter has already
-- been sent. 
-- it returns a TRUE if so, FALSE if not
-- 

    l_enc_num_to_check                number;
    l_icd_match                       number;

begin

select
    count(*) into l_icd_match
from
    cdcods.ENCTRDIAGNOSES
where
    ENCTRDIAGNOSES.enctrnum = p_encounter_num and
    ENCTRDIAGNOSES.dxcode = p_icd_code;

if l_icd_match > 0 then 
    return 'TRUE';
else 
    return 'FALSE';
end if;

exception 
    when no_data_found then

        return 'FALSE';

end HAS_DX_ALREADY_BEEN_SENT;

end CMS_EDITS_LIB;
/
