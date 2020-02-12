create or replace package PACKAGE_NAME is
/*------------------------------------------------------------------------------
    Program:  PACKAGE_NAME
    Author:   Zac Carlson
    Date:     
    For:      
    
    Purpose:
    
      Why was it created?
    
    Documentation:

      How does this work, what does it do?
    
    Installation information:

      Are there any things that need to be done as part of the installation of 
      this package?
    
    Modification History:
    
      v0.1
      By: Zac Carlson
      Date: 
      Description: 
    
------------------------------------------------------------------------------*/

  procedure main;
  
  procedure foo (
    p_input_1 in varchar2,
    p_input_2 in varchar2,
    p_status out varchar2);
  
  function bar (
    p_input_1 in number,
    p_input_2 in number,
    p_result out number)

end PACKAGE_NAME;
