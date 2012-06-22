create or replace procedure PROC_NAME (
  p_input_1 in varchar2,
  p_input_2 in varchar2,
  p_status out varchar2) as
/*------------------------------------------------------------------------------
    Program:  PROC_NAME
    Author:   Zac Carlson
    Date:     
    For:      
    
    Purpose:
    
      Why was it created?
    
    Documentation:

      How does this work, what does it do?
    
    Input Parameters:
      
      p_input_1 - What is this input for?
      p_input_2 - What is this input for?
      
    Output Parameters:
    
      p_status - Indicates success (OK), warnings (OK_WITH_WARNINGS), or failure (FAILURE)

    Dependencies:
    
      List all dependencie
      
    Modification History:
    
      v0.1
      By: Zac Carlson
      Date: 
      Description: 
      
------------------------------------------------------------------------------*/

--
--------------------------------------------------------------------------------
-- Exception definitions
--------------------------------------------------------------------------------
--
  
--
--------------------------------------------------------------------------------
-- Local variables
--------------------------------------------------------------------------------
--
  v_classname                     varchar2(30)     := ''; --class name of program object
  
  v_sqlcode                       number        := 0;     -- SQL error code buffer.
  v_sqlmsg                        varchar2(255) := null;  -- Error message buffer.
  v_errmsg                        varchar2(255) := null;  -- Error message buffer.
  v_errstack                      varchar2(4000):= null;  -- Error backtrace stack.


--
--------------------------------------------------------------------------------
-- Cursor definitions
--------------------------------------------------------------------------------
--

--
--------------------------------------------------------------------------------
-- Function Body
--------------------------------------------------------------------------------
--

begin

--
-- Initialize variables and perform admin type tasks
--



  --
  -- Begin work
  --
  begin
  
    dbms_output.put_line('Hello world');
  
  exception
    
    when ZERO_DIVIDE then
      
      null;
      p_status := 'OK_WITH_WARNINGS';
    
  end;



--
--------------------------------------------------------------------------------
-- Procedure Closing
--------------------------------------------------------------------------------
--

  p_status := 'OK';

--
--------------------------------------------------------------------------------
-- Exception Handling
--------------------------------------------------------------------------------
--
exception
  
  when others then
  
    p_status := 'FAILURE';
  
    v_sqlcode := sqlcode;
    v_sqlmsg  := sqlerrm;
    v_errstack:= dbms_utility.format_error_backtrace();
    v_errstack:= v_errstack || ' SQLCODE: ' || to_char(v_sqlcode);
    v_errstack:= v_errstack || ' - ' || v_sqlmsg;
  
    dbms_output.put_line(v_classname,v_sqlcode,'Fail message', v_errstack );

end;