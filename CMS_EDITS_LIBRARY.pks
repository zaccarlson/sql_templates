create or replace package  GPODS.CMS_EDITS_LIB is

    function IS_HCFA_1500 (p_encounter_num in number) return varchar2;

    function IS_VALID_CLAIM (p_claim_num in number) return varchar2;

    function IS_VALID_PERSON (p_person_identifier in varchar2, p_identifier_type in varchar2) return varchar2;

    function IS_RECV_DT_IN_THRESHOLD (p_claim_num in number, p_threshold_num in number, p_threshold_type in varchar2) return varchar2;

    function IS_CMS_CLAIM (p_claim_num in number) return varchar2;

    function IS_CLAIM_VOIDED (p_claim_num in number) return varchar2;

    function IS_CLAIM_DENIED (p_claim_num in number) return varchar2;

    function IS_CLAIM_IN_ENCOUNTER (p_claim_num in number, p_encounter_num in number) return varchar2;

    function IS_VALID_ICD_CODE (p_icd_code in varchar2) return varchar2;

    function IS_CLAIM_FOR_MEMBER (p_claim_num in number, p_person_identifier in varchar2, p_identifier_type in varchar2) return varchar2;

    function HAS_DX_ALREADY_BEEN_SENT(p_encounter_num in number, p_icd_code in varchar2) return varchar2;

end;
/
