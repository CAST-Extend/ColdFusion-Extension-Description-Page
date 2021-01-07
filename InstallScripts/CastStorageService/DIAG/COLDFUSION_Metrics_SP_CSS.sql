/**  
 *  Set the following search_path to your LOCAL schema.
 *  In the following example, the name of the Local schema (KB) is 'coldfusion_local'
 *       SET search_path TO coldfusion_local, public;
**/

/******************************************************************************/
/** FUNCTION:    bitand                                                       */
/**   BITAND computes an AND operation on the bits of expr1 and expr2, both   */ 
/**   of which must resolve to nonnegative integers, and returns result       */
/** This functions was added because unlike Oracle, bitand() is not           */
/** a standard Postgres function                                              */
/** from: orafce 3.01                                                         */
/**                                                                           */
/******************************************************************************/
CREATE OR REPLACE FUNCTION bitand(bigint, bigint)
RETURNS bigint
AS $$ SELECT $1 & $2; $$
LANGUAGE sql IMMUTABLE STRICT; 


/******************************************************************************/
/** FUNCTION COLDFUSION_APPLICATION_TOTAL      * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_APPLICATION_TOTAL (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_VALUE_INDEX integer
)
Returns integer as $$
DECLARE
	ERRORCODE	int := 0;
Begin
    Insert Into DSS_METRIC_RESULTS
		(METRIC_NUM_VALUE, METRIC_OBJECT_ID, OBJECT_ID, METRIC_ID, METRIC_VALUE_INDEX, SNAPSHOT_ID)
    Select 
    	Count(T1.OBJECT_ID), 0, SC.OBJECT_PARENT_ID, I_METRIC_ID, I_METRIC_VALUE_INDEX, I_SNAPSHOT_ID
    From
    	CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES MO, DSS_METRIC_SCOPES SC
    Where
	    SC.SNAPSHOT_ID            			= I_SNAPSHOT_ID
	    And SC.METRIC_PARENT_ID    			= I_METRIC_PARENT_ID
	    And SC.METRIC_ID           			= I_METRIC_ID
 		And SC.COMPUTE_VALUE				= 0
		And MO.TECHNO_TYPE					= 2351000   			-- Technologic Coldfusion object
		And MO.MODULE_ID					= SC.OBJECT_ID
  		And T1.APPLICATION_ID      			= SC.OBJECT_ID

		And T1.OBJECT_TYPE					= 2351099 				-- Technology CF Application - does not exist...
		And bitand(T1.PROPERTIES, 1) 		= 0 					-- Application's Object

		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)

    Group By SC.OBJECT_PARENT_ID, SC.OBJECT_ID
	;
Return ERRORCODE;
End; -- COLDFUSION_APPLICATION_TOTAL;
$$ LANGUAGE plpgsql;



/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_COUNT         * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_COUNT (
	I_SNAPSHOT_ID integer,		-- the SNAPSHOT id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,			-- the metric id
	I_METRIC_CHILD_ID integer	-- the metric child id
)
Returns integer as $$
DECLARE
	ERRORCODE		INT := 0;
	
Begin
/* Insert items matching category inside scope */
	Insert Into DSS_METRIC_SCOPES
		( METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, OBJECT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, COMPUTE_VALUE )
	Select 
		I_METRIC_ID, I_METRIC_CHILD_ID, C.APPLICATION_ID, C.OBJECT_ID, I_SNAPSHOT_ID, 0, 1
	From 
		CTT_OBJECT_APPLICATIONS C
	Where 
		C.PROPERTIES					= 0
		And C.OBJECT_TYPE				IN (2351010) -- CF Function
		
		;


Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_COUNT;
$$ LANGUAGE plpgsql;

/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_COUP001      * OBJECT FROM DATA DICTIONARY  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_COUP001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
	PARAM_INIT INT	:= 0;
Begin
--<<NAME>>TECHNO_XXX_COUP001<</NAME>>
--<<COMMENT>> TEMPLATE NAME   = DSSAPPARTIFACTS. <</COMMENT>>
--<<COMMENT>> DIAGNOSTIC NAME = AVOID FUNCTIONS WITH HIGH FAN-IN (FAN-IN > 5). <</COMMENT>>
--<<COMMENT>> DEFINITION      = AVOID <FUNCTIONS> WITH HIGH FAN-IN (FAN-IN > 5). <</COMMENT>>
--<<COMMENT>> ACTION          = LISTS ALL <FUNCTIONS> WITH HIGH FAN-IN. <</COMMENT>>
--<<COMMENT>> VALUE           = FAN-IN VALUE. <</COMMENT>>

	INSERT INTO DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
		SELECT
		T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T1.FAN_IN, 0, 0
	FROM
		  DSSAPP_ARTIFACTS T1, DSSAPP_MODULES SC
	WHERE
		SC.TECHNO_TYPE					= 2351000   	-- TECHNOLOGIC XXX
		AND T1.OBJECT_TYPE 				IN (2351010) 	    -- XXX ARTIFACTS
		AND T1.APPLICATION_ID			= SC.MODULE_ID
		AND NOT EXISTS
		(
			SELECT 1
			FROM
				DSS_OBJECT_EXCEPTIONS E
			WHERE
				E.METRIC_ID		= I_METRIC_ID
				AND E.OBJECT_ID	= T1.OBJECT_ID
		)
		AND T1.FAN_IN >
		(
			SELECT PARAM_NUM_VALUE
			FROM
				DSS_METRIC_PARAM_VALUES MTP
			WHERE
				MTP.METRIC_ID		= I_METRIC_CHILD_ID
				AND MTP.PARAM_INDEX	= 1
		)

 	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_COUP001;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_COUP002       * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_COUP002 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
	PARAM_INIT INT	:= 0;
Begin
--<<NAME>>TECHNO_XXX_COUP001<</NAME>>
--<<COMMENT>> Template name   = DSSAPPARTIFACTS. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid Functions with High Fan-In (Fan-In > 5). <</COMMENT>>
--<<COMMENT>> Definition      = Avoid <Functions> with High Fan-In (Fan-In > 5). <</COMMENT>>
--<<COMMENT>> Action          = Lists all <Functions> with High Fan-In. <</COMMENT>>
--<<COMMENT>> Value           = Fan-in value. <</COMMENT>>

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
		Select
		T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T1.FAN_OUT, 0, 0
	From
		  DSSAPP_ARTIFACTS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE					= 2351000   	-- Technologic XXX
		And T1.OBJECT_TYPE 				IN (2351010) 	    -- XXX Artifacts
		And T1.APPLICATION_ID			= SC.MODULE_ID
		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
		And T1.FAN_OUT >
		(
			Select PARAM_NUM_VALUE
			From
				DSS_METRIC_PARAM_VALUES MTP
			Where
				MTP.METRIC_ID		= I_METRIC_CHILD_ID
				And MTP.PARAM_INDEX	= 1
		)

 	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_COUP002;
$$ LANGUAGE plpgsql;

/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_COUP003       * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_COUP003 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>TECHNO_XXX_COUP003<</NAME>>*/
--<<COMMENT>> Template name   = UNREFERENCED. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid unreferenced Techno XXX. <</COMMENT>>
--<<COMMENT>> Definition      = Unreferenced XXX make the code less readable and maintainable. <</COMMENT>>
--<<COMMENT>> Action          = Avoid unreferenced XXX. <</COMMENT>>
--<<COMMENT>> Value           = 1. <</COMMENT>>
	Insert Into 
		DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select
		 T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, 1, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE					= 2351000   	-- Technologic XXX object
		And T1.OBJECT_TYPE				IN (2351010)	   -- Techno XXX artifacts
		And T1.APPLICATION_ID			= SC.MODULE_ID
    	And	Bitand(T1.PROPERTIES, 1)	= 0		-- Application's Object

        And Not Exists	(	Select 1
                    		From
                    			  CTV_LINKS T2
                    		Where
                    			T2.CALLED_ID = T1.OBJECT_ID

                        )


		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
 	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_COUP003;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_DOC001        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_DOC001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>TECHNO_XXX_DOC001<</NAME>>
--<<COMMENT>> Template name   = UNDOCUMENTED. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid undocumented Siebel Functions<</COMMENT>>
--<<COMMENT>> Definition      = Siebel Functions should have comments. <</COMMENT>>
--<<COMMENT>> Action          = Lists all Siebel Functionsthat have neither heading comments nor inline comments. <</COMMENT>>
--<<COMMENT>> Value           = 1. <</COMMENT>>
  Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select
		distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, 1, 0, 0
    From
    	CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE						= 2351000   	-- Technologic XXX
		And T1.APPLICATION_ID				= SC.MODULE_ID
		  	-- Siebel Project
		And T1.OBJECT_TYPE					IN (2351010) 	-- Techno Function
		And bitand(T1.PROPERTIES, 1)		= 0 		-- Application's Object
		And Exists
		(
			Select 1
			From
				DIAG_OBJECT_METRICS T2, DIAG_OBJECT_METRICS T3
			Where
				T2.OBJECT_ID 		= T1.OBJECT_ID
        		And T2.METRIC_TYPE 		= 'Number of heading comment lines'
        		And T2.METRIC_VALUE 	= 0
        		And T3.OBJECT_ID 		= T1.OBJECT_ID
        		And T3.METRIC_TYPE 		= 'Number of inner comment lines'
        		And T3.METRIC_VALUE 	= 0
		)
		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
 	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_DOC001;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_DOC002        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_DOC002 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
	PARAM_INT	INT := 0;
Begin
--<<NAME>>COLDFUSION_FUNCTION_DOC002<</NAME>>*/
--<<COMMENT>> Template name   = UNDOCUMENTEDRATIO. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid Siebel Functions with a very low comment/code ratio. <</COMMENT>>
--<<COMMENT>> Definition 		     = Avoid Siebel Functions with a very low comment/code ratio. <</COMMENT>>
--<<COMMENT>> Action      			 = Lists all Siebel Functions with a very low comment/code ratio. <</COMMENT>>
--<<COMMENT>> Value       			  = Comment ratio. <</COMMENT>>
    Select PARAM_NUM_VALUE
	Into PARAM_INT
    From
     	DSS_METRIC_PARAM_VALUES MTP
    Where
        MTP.METRIC_ID	= I_METRIC_CHILD_ID
        And PARAM_INDEX	= 1;

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, ( cast ((T2.METRIC_VALUE + T3.METRIC_VALUE) as double precision) / (CASE WHEN  coalesce(T4.METRIC_VALUE,0) = 0 THEN  1 ELSE T4.METRIC_VALUE END) ), 0, 0
	
    From
		DIAG_OBJECT_METRICS T4, DIAG_OBJECT_METRICS T3, DIAG_OBJECT_METRICS T2, CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE						= 2351000   			-- Technologic XXX object
		And T1.APPLICATION_ID				= SC.MODULE_ID
		And T1.OBJECT_TYPE					IN (2351010) 	-- Techno XXX artifact
		And bitand(T1.PROPERTIES, 1)		= 0 					-- Application's Object
        And T2.OBJECT_ID 					= T1.OBJECT_ID
        And T2.METRIC_TYPE 					= 'Number of heading comment lines'
        And T3.OBJECT_ID 					= T1.OBJECT_ID
        And T3.METRIC_TYPE 					= 'Number of inner comment lines'
        And T4.OBJECT_ID 					= T1.OBJECT_ID
        And T4.METRIC_TYPE 					= 'Number of code lines'
        And T4.METRIC_VALUE					> 0
		And (100::INT8*(T2.METRIC_VALUE + T3.METRIC_VALUE) / (CASE WHEN  coalesce(T4.METRIC_VALUE,0) = 0 THEN  1 ELSE T4.METRIC_VALUE END) ) < (PARAM_INT)


		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
 	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_DOC002;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_DOC003        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_DOC003 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>COLDFUSION_TEMPLATE_DOC003<</NAME>>
--<<COMMENT>> Template name   = DSSAPPARTIFACTSNOPARAM. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid Methods with lines of more than 80 characters. <</COMMENT>>
--<<COMMENT>> Definition      = Avoid Methods with lines of more than 80 characters. <</COMMENT>>
--<<COMMENT>> Action          = Lists all Methods with lines of more than 80 characters. <</COMMENT>>
--<<COMMENT>> Value           = Number of lines of more than 80 characters. <</COMMENT>>
	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T1.LONG_LINES, 0, 0
	From
		DSSAPP_ARTIFACTS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE			= 2351000  			-- Technologic xxx object
		And T1.APPLICATION_ID	= SC.MODULE_ID
		AND T1.OBJECT_TYPE		IN (2351010)		-- Techno artifact	
		And T1.LONG_LINES > 0
 	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_DOC003;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_NAM001        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_NAM001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>COLDFUSION_FUNCTION_NAM001<</NAME>>*/
--<<COMMENT>> Template name   = NAMINGPREFIXPARAMCHAR. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Tables naming conventions. <</COMMENT>>
--<<COMMENT>> Definition      = All tables should start with a specific prefix (i.e. t_). <</COMMENT>>
--<<COMMENT>> Action          = All tables should start with a specific prefix (i.e. t_). <</COMMENT>>
--<<COMMENT>> Value           = 1. <</COMMENT>>
	Insert Into DSS_METRIC_SCOPES 
		(OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select 
		T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, 1, 0, 0
	From 
    	CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES SC
    Where                    
	    SC.TECHNO_TYPE					= 2351000  -- Technologic SQL Server object
		And T1.APPLICATION_ID			= SC.MODULE_ID
        And T1.OBJECT_TYPE 				IN (2351010) 	-- Function
		And Bitand(T1.PROPERTIES, 1)	= 0 -- Application's Object
		And Not Exists 
		(
			Select 1 
			From 
				DSS_OBJECT_EXCEPTIONS E
			Where 
				E.METRIC_ID		= I_METRIC_ID 
				And E.OBJECT_ID	= T1.OBJECT_ID 
		)
		

    	And not exists
   		(
   			Select 1
   			From
   				CDT_OBJECTS T2, DSS_METRIC_PARAM_VALUES MPV
   			Where
				MPV.METRIC_ID		= I_METRIC_CHILD_ID
				And T2.OBJECT_ID 	= T1.OBJECT_ID
				
				And T2.OBJECT_NAME	like REPLACE(REPLACE(REPLACE(MPV.PARAM_CHAR_VALUE,'/','//'),'_','/_'),'%','/%') || '%' ESCAPE '/'
		)
	; 
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_NAM001;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_TEC001        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_TEC001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>TECHN_XXX_TEC001<</NAME>>
--<<COMMENT>> Template name   = DSSAPPARTIFACTS. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid Siebel Functions with High Cyclomatic Complexity (CC > 20). <</COMMENT>>
--<<COMMENT>> Definition      = Avoid <Siebel Functions > with High Cyclomatic Complexity (CC > 20). <</COMMENT>>
--<<COMMENT>> Action          = Lists all <Siebel Functions > with High Cyclomatic Complexity. <</COMMENT>>
--<<COMMENT>> Value           = Cyclomatic Complexity. <</COMMENT>>
	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select
		distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T1.CYCLOMATIC, 0, 0
	From
		DSSAPP_ARTIFACTS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE						= 2351000   			-- Technologic XXX object
		And T1.OBJECT_TYPE					IN (2351010) 			-- Techno XXX Artifact
		And T1.APPLICATION_ID				= SC.MODULE_ID
		And T1.CYCLOMATIC 					>
		(
			Select PARAM_NUM_VALUE
			From
				DSS_METRIC_PARAM_VALUES MTP
			Where
				MTP.METRIC_ID		= I_METRIC_CHILD_ID
				And MTP.PARAM_INDEX	= 1
		)
		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
 	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_TEC001;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_TOTAL         * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_TOTAL (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_VALUE_INDEX integer
)
Returns integer as $$
DECLARE
	ERRORCODE	int := 0;
Begin
--<<NAME>>SIEBEL_XXX_TOTAL<</NAME>>*/
--<<COMMENT>> Template name   = TOTAL. <</COMMENT>>
--<<COMMENT>> Definition      = Count of XXX Artifacts<</COMMENT>>

    Insert Into DSS_METRIC_RESULTS
		(METRIC_NUM_VALUE, METRIC_OBJECT_ID, OBJECT_ID, METRIC_ID, METRIC_VALUE_INDEX, SNAPSHOT_ID)
    Select 
    	Count(T1.OBJECT_ID), 0, SC.OBJECT_PARENT_ID, I_METRIC_ID, I_METRIC_VALUE_INDEX, I_SNAPSHOT_ID
    From
    	CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES MO, DSS_METRIC_SCOPES SC
    Where
	    SC.SNAPSHOT_ID            			= I_SNAPSHOT_ID
	    And SC.METRIC_PARENT_ID    			= I_METRIC_PARENT_ID
	    And SC.METRIC_ID           			= I_METRIC_ID
 		And SC.COMPUTE_VALUE				= 0
		And MO.TECHNO_TYPE					= 2351000   			-- Technologic Coldfusion object
		And MO.MODULE_ID					= SC.OBJECT_ID
  		And T1.APPLICATION_ID      			= SC.OBJECT_ID

		And T1.OBJECT_TYPE					IN (2351010) 				-- Technology Function
		And bitand(T1.PROPERTIES, 1) 		= 0 					-- Application's Object

		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)

    Group By SC.OBJECT_PARENT_ID, SC.OBJECT_ID
	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_TOTAL;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_VOL001        * Object from Data Dictionary  */
/**  CAST(T2.DESCRIPTION as double precision) */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_VOL001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>COLDFUSION_FUNCTION_VOL001<</NAME>>*/
--<<COMMENT>> Template name   = GENERICPARAMINT. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid long PHHP pages. <</COMMENT>>
--<<COMMENT>> Definition      = PHP pages should not have more than XXX lines of code. <</COMMENT>>
--<<COMMENT>> Action          = Lists PHP pages with more than XXX lines of code. <</COMMENT>>
--<<COMMENT>> Value           = Number of lines of code in the PHP pages. <</COMMENT>>
	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE					= 2351000   			-- Technologic CF object
		And T1.APPLICATION_ID			= SC.MODULE_ID
        And T1.OBJECT_TYPE 				IN (2351010) 	 -- CFFunction 
    	And	Bitand(T1.PROPERTIES, 1)	= 0						-- Application's Object
        And T2.OBJECT_ID 				= T1.OBJECT_ID
        And T2.METRIC_TYPE 				= 'Number of code lines'
		And CAST(T2.METRIC_VALUE as double precision) >
		(
			Select PARAM_NUM_VALUE
			From
				DSS_METRIC_PARAM_VALUES MTP
			Where
				MTP.METRIC_ID	= I_METRIC_CHILD_ID
				And PARAM_INDEX	= 1
		)

	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_VOL001;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_FUNCTION_VOL002        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_FUNCTION_VOL002 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>COLDFUSION_FUNCTION_VOL002<</NAME>>*/
--<<COMMENT>> Template name   = GENERICHAVINGPARAMINTPARENT. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid programs with too many Subroutines. <</COMMENT>>
--<<COMMENT>> Definition      = Avoid programs with more than XXX Subroutines (XXX=30). <</COMMENT>>

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.PARENT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, Count(T1.OBJECT_ID), 0, 0
	From
		  CTT_OBJECT_PARENTS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE					= 2351000   	-- Technologic CF object
		And T1.APPLICATION_ID			= SC.MODULE_ID
		And T1.OBJECT_TYPE				IN (2351010) 		-- CF Function and JFunction\
      And T1.PARENT_TYPE              = 2351004  -- CF Template
    	
		And Not Exists 
		(
			Select 1 
			From 
				DSS_OBJECT_EXCEPTIONS E
			Where 
				E.METRIC_ID		= I_METRIC_ID 
				And E.OBJECT_ID	= T1.OBJECT_ID 
		)
		Group By T1.PARENT_ID, SC.MODULE_ID
		Having Count(T1.OBJECT_ID) >
		(
    	   	Select PARAM_NUM_VALUE
     		From
     	    	DSS_METRIC_PARAM_VALUES MTP
        	Where
          		MTP.METRIC_ID	= I_METRIC_CHILD_ID
          		And PARAM_INDEX	= 1
    	)
    	

 	;
Return ERRORCODE;
End; -- COLDFUSION_FUNCTION_VOL002;
$$ LANGUAGE plpgsql;



/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_COUNT            * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_COUNT (
	I_SNAPSHOT_ID integer,	-- the SNAPSHOT id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer	-- the metric child id
)
Returns integer as $$
DECLARE
	ERRORCODE		INT := 0;
	L_OBJECT_TYPE	INT := 2351005;	/* ColdFusion Query */
Begin

	ERRORCODE := APM_SCOPE_OBJECT_TYPE( I_SNAPSHOT_ID, I_METRIC_PARENT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, L_OBJECT_TYPE );

Return ERRORCODE;
End; -- COLDFUSION_QUERY_COUNT;
$$ LANGUAGE plpgsql;

/******************************************************************************/
/** FUNCTION COLDFUSION_COMPONENT_COUNT            * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_COMPONENT_COUNT (
	I_SNAPSHOT_ID integer,	-- the SNAPSHOT id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer	-- the metric child id
)
Returns integer as $$
DECLARE
	ERRORCODE		INT := 0;
	L_OBJECT_TYPE	INT := 2351012;	/* ColdFusion Component */
Begin

	ERRORCODE := APM_SCOPE_OBJECT_TYPE( I_SNAPSHOT_ID, I_METRIC_PARENT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, L_OBJECT_TYPE );

Return ERRORCODE;
End; -- COLDFUSION_COMPONENT_COUNT;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_NAM001           * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_NAM001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>COLDFUSION_FUNCTION_NAM001<</NAME>>*/
--<<COMMENT>> Template name   = NAMINGPREFIXPARAMCHAR. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Tables naming conventions. <</COMMENT>>
--<<COMMENT>> Definition      = All tables should start with a specific prefix (i.e. t_). <</COMMENT>>
--<<COMMENT>> Action          = All tables should start with a specific prefix (i.e. t_). <</COMMENT>>
--<<COMMENT>> Value           = 1. <</COMMENT>>
	Insert Into DSS_METRIC_SCOPES 
		(OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select 
		T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, 1, 0, 0
	From 
    	CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES SC
    Where                    
	    SC.TECHNO_TYPE					= 2351000  -- Technologic SQL Server object
		And T1.APPLICATION_ID			= SC.MODULE_ID
        And T1.OBJECT_TYPE 				= 2351005 	-- Query
		And Bitand(T1.PROPERTIES, 1)	= 0 -- Application's Object
		And Not Exists 
		(
			Select 1 
			From 
				DSS_OBJECT_EXCEPTIONS E
			Where 
				E.METRIC_ID		= I_METRIC_ID 
				And E.OBJECT_ID	= T1.OBJECT_ID 
		)
		

    	And not exists
   		(
   			Select 1
   			From
   				CDT_OBJECTS T2, DSS_METRIC_PARAM_VALUES MPV
   			Where
				MPV.METRIC_ID		= I_METRIC_CHILD_ID
				And T2.OBJECT_ID 	= T1.OBJECT_ID
				
				And T2.OBJECT_NAME	like REPLACE(REPLACE(REPLACE(MPV.PARAM_CHAR_VALUE,'/','//'),'_','/_'),'%','/%') || '%' ESCAPE '/'
		)
	; 
Return ERRORCODE;
End; -- COLDFUSION_QUERY_NAM001;
$$ LANGUAGE plpgsql;


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_TOTAL            * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_TOTAL (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_VALUE_INDEX integer
)
Returns integer as $$
DECLARE
	ERRORCODE	int := 0;
Begin
--<<NAME>>SIEBEL_XXX_TOTAL<</NAME>>*/
--<<COMMENT>> Template name   = TOTAL. <</COMMENT>>
--<<COMMENT>> Definition      = Count of XXX Artifacts<</COMMENT>>

    Insert Into DSS_METRIC_RESULTS
		(METRIC_NUM_VALUE, METRIC_OBJECT_ID, OBJECT_ID, METRIC_ID, METRIC_VALUE_INDEX, SNAPSHOT_ID)
    Select 
    	Count(T1.OBJECT_ID), 0, SC.OBJECT_PARENT_ID, I_METRIC_ID, I_METRIC_VALUE_INDEX, I_SNAPSHOT_ID
    From
    	CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES MO, DSS_METRIC_SCOPES SC
    Where
	    SC.SNAPSHOT_ID            			= I_SNAPSHOT_ID
	    And SC.METRIC_PARENT_ID    			= I_METRIC_PARENT_ID
	    And SC.METRIC_ID           			= I_METRIC_ID
 		And SC.COMPUTE_VALUE				= 0
		And MO.TECHNO_TYPE					= 2351000   			-- Technologic Coldfusion object
		And MO.MODULE_ID					= SC.OBJECT_ID
  		And T1.APPLICATION_ID      			= SC.OBJECT_ID

		And T1.OBJECT_TYPE					= 2351005				-- Technology Query
		And bitand(T1.PROPERTIES, 1) 		= 0 					-- Application's Object

		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)

    Group By SC.OBJECT_PARENT_ID, SC.OBJECT_ID
	;
Return ERRORCODE;
End; -- COLDFUSION_QUERY_TOTAL;
$$ LANGUAGE plpgsql;



/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_COUNT        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_COUNT (
	I_SNAPSHOT_ID integer,	-- the SNAPSHOT id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer	-- the metric child id
)
Returns integer as $$
DECLARE
	ERRORCODE		INT := 0;
	L_OBJECT_TYPE	INT := 2351004;	/* ColdFusion Template */
Begin

	ERRORCODE := APM_SCOPE_OBJECT_TYPE( I_SNAPSHOT_ID, I_METRIC_PARENT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, L_OBJECT_TYPE );

Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_COUNT;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_COUP002       * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_COUP002 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
	PARAM_INIT INT	:= 0;
Begin
--<<NAME>>TECHNO_XXX_COUP001<</NAME>>
--<<COMMENT>> Template name   = DSSAPPARTIFACTS. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid Functions with High Fan-In (Fan-In > 5). <</COMMENT>>
--<<COMMENT>> Definition      = Avoid <Functions> with High Fan-In (Fan-In > 5). <</COMMENT>>
--<<COMMENT>> Action          = Lists all <Functions> with High Fan-In. <</COMMENT>>
--<<COMMENT>> Value           = Fan-in value. <</COMMENT>>

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
		Select
		T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T1.FAN_OUT, 0, 0
	From
		  DSSAPP_ARTIFACTS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE					= 2351000   	-- Technologic Coldfusion
		And T1.OBJECT_TYPE 				= 2351004 	    -- Coldfusion Template
		And T1.APPLICATION_ID			= SC.MODULE_ID
		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
		And T1.FAN_OUT >
		(
			Select PARAM_NUM_VALUE
			From
				DSS_METRIC_PARAM_VALUES MTP
			Where
				MTP.METRIC_ID		= I_METRIC_CHILD_ID
				And MTP.PARAM_INDEX	= 1
		)

 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_COUP002;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_COUP001       * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_COUP001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
	PARAM_INIT INT	:= 0;
Begin
--<<NAME>>TECHNO_XXX_COUP001<</NAME>>
--<<COMMENT>> Template name   = DSSAPPARTIFACTS. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid Functions with High Fan-In (Fan-In > 5). <</COMMENT>>
--<<COMMENT>> Definition      = Avoid <Functions> with High Fan-In (Fan-In > 5). <</COMMENT>>
--<<COMMENT>> Action          = Lists all <Functions> with High Fan-In. <</COMMENT>>
--<<COMMENT>> Value           = Fan-in value. <</COMMENT>>

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
		Select
		T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T1.FAN_IN, 0, 0
	From
		  DSSAPP_ARTIFACTS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE					= 2351000   	-- Technologic XXX
		And T1.OBJECT_TYPE 				= 2351004 	    -- Coldfusion Template
		And T1.APPLICATION_ID			= SC.MODULE_ID
		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
		And T1.FAN_IN >
		(
			Select PARAM_NUM_VALUE
			From
				DSS_METRIC_PARAM_VALUES MTP
			Where
				MTP.METRIC_ID		= I_METRIC_CHILD_ID
				And MTP.PARAM_INDEX	= 1
		)

 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_COUP001;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_COUP003       * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_COUP003 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>TECHNO_XXX_COUP003<</NAME>>*/
--<<COMMENT>> Template name   = UNREFERENCED. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid unreferenced Techno XXX. <</COMMENT>>
--<<COMMENT>> Definition      = Unreferenced XXX make the code less readable and maintainable. <</COMMENT>>
--<<COMMENT>> Action          = Avoid unreferenced XXX. <</COMMENT>>
--<<COMMENT>> Value           = 1. <</COMMENT>>
	Insert Into 
		DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select
		 T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, 1, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE					= 2351000   	-- Technologic CF object
		And T1.OBJECT_TYPE				= 2351004	   -- Techno CF Template
		And T1.APPLICATION_ID			= SC.MODULE_ID
    	And	Bitand(T1.PROPERTIES, 1)	= 0		-- Application's Object

        And Not Exists	(	Select 1
                    		From
                    			  CTV_LINKS T2
                    		Where
                    			T2.CALLED_ID = T1.OBJECT_ID

                        )


		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_COUP003;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_DOC001        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_DOC001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>TECHNO_XXX_DOC001<</NAME>>
--<<COMMENT>> Template name   = UNDOCUMENTED. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid undocumented Siebel Functions<</COMMENT>>
--<<COMMENT>> Definition      = Siebel Functions should have comments. <</COMMENT>>
--<<COMMENT>> Action          = Lists all Siebel Functionsthat have neither heading comments nor inline comments. <</COMMENT>>
--<<COMMENT>> Value           = 1. <</COMMENT>>
  Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select
		distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, 1, 0, 0
    From
    	CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE						= 2351000   	-- Technologic CF
		And T1.APPLICATION_ID				= SC.MODULE_ID
		  	-- Siebel Project
		And T1.OBJECT_TYPE					= 2351004 	-- CF Template
		And bitand(T1.PROPERTIES, 1)		= 0 -- Application's Object
		And Exists
		(
			Select 1
			From
				DIAG_OBJECT_METRICS T2, DIAG_OBJECT_METRICS T3
			Where
				T2.OBJECT_ID 		= T1.OBJECT_ID
        		And T2.METRIC_TYPE 		= 'Number of heading comment lines'
        		And T2.METRIC_VALUE 	= 0
        		And T3.OBJECT_ID 		= T1.OBJECT_ID
        		And T3.METRIC_TYPE 		= 'Number of inner comment lines'
        		And T3.METRIC_VALUE 	= 0
		)
		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_DOC001;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_DOC002        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_DOC002 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
	PARAM_INT	INT := 0;
Begin
--<<NAME>>COLDFUSION_TEMPLATE_DOC002<</NAME>>*/
--<<COMMENT>> Template name   = UNDOCUMENTEDRATIO. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid Siebel Functions with a very low comment/code ratio. <</COMMENT>>
--<<COMMENT>> Definition 		     = Avoid Siebel Functions with a very low comment/code ratio. <</COMMENT>>
--<<COMMENT>> Action      			 = Lists all Siebel Functions with a very low comment/code ratio. <</COMMENT>>
--<<COMMENT>> Value       			  = Comment ratio. <</COMMENT>>
    Select PARAM_NUM_VALUE
	Into PARAM_INT
    From
     	DSS_METRIC_PARAM_VALUES MTP
    Where
        MTP.METRIC_ID	= I_METRIC_CHILD_ID
        And PARAM_INDEX	= 1;

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, ( cast ((T2.METRIC_VALUE + T3.METRIC_VALUE) as double precision) / (CASE WHEN  coalesce(T4.METRIC_VALUE,0) = 0 THEN  1 ELSE T4.METRIC_VALUE END) ), 0, 0

    From
		DIAG_OBJECT_METRICS T4, DIAG_OBJECT_METRICS T3, DIAG_OBJECT_METRICS T2, CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE						= 2351000   	-- Technologic XXX object
		And T1.APPLICATION_ID			= SC.MODULE_ID
		  	-- Siebel Project
		And T1.OBJECT_TYPE					= 2351004 	-- Techno XXX artifact
		And bitand(T1.PROPERTIES, 1)	= 0 -- Application's Object
        And T2.OBJECT_ID 						= T1.OBJECT_ID
        And T2.METRIC_TYPE 				= 'Number of heading comment lines'
        And T3.OBJECT_ID 						= T1.OBJECT_ID
        And T3.METRIC_TYPE 				= 'Number of inner comment lines'
        And T4.OBJECT_ID 						= T1.OBJECT_ID
        And T4.METRIC_TYPE 				= 'Number of code lines'
        And T4.METRIC_VALUE				> 0
		And (100::INT8*(T2.METRIC_VALUE + T3.METRIC_VALUE) / (CASE WHEN  coalesce(T4.METRIC_VALUE,0) = 0 THEN  1 ELSE T4.METRIC_VALUE END) ) < (PARAM_INT)

		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_DOC002;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_DOC003        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_DOC003 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>COLDFUSION_TEMPLATE_DOC003<</NAME>>
--<<COMMENT>> Template name   = DSSAPPARTIFACTSNOPARAM. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid Methods with lines of more than 80 characters. <</COMMENT>>
--<<COMMENT>> Definition      = Avoid Methods with lines of more than 80 characters. <</COMMENT>>
--<<COMMENT>> Action          = Lists all Methods with lines of more than 80 characters. <</COMMENT>>
--<<COMMENT>> Value           = Number of lines of more than 80 characters. <</COMMENT>>
	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T1.LONG_LINES, 0, 0
	From
		DSSAPP_ARTIFACTS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE			= 2351000  			-- Technologic ColdFusion object
		And T1.APPLICATION_ID	= SC.MODULE_ID
		AND T1.OBJECT_TYPE		= 2351004		-- Coldfusion Template
		And T1.LONG_LINES > 0
 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_DOC003;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_NAM001        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_NAM001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>COLDFUSION_TEMPLATE_NAM001<</NAME>>*/
--<<COMMENT>> Template name   = NAMINGPREFIXPARAMCHAR. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Template naming conventions. <</COMMENT>>
--<<COMMENT>> Definition      = All templates should start with a specific prefix (i.e. t_). <</COMMENT>>
--<<COMMENT>> Action          = All templates should start with a specific prefix (i.e. t_). <</COMMENT>>
--<<COMMENT>> Value           = 1. <</COMMENT>>
	Insert Into DSS_METRIC_SCOPES 
		(OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select 
		T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, 1, 0, 0
	From 
    	CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES SC
    Where                    
	    SC.TECHNO_TYPE					= 2351000  -- Technologic SQL Server object
		And T1.APPLICATION_ID			= SC.MODULE_ID
        And T1.OBJECT_TYPE 				= 2351004 	-- CF Template
		And Bitand(T1.PROPERTIES, 1)	= 0 		-- Application's Object
		And Not Exists 
		(
			Select 1 
			From 
				DSS_OBJECT_EXCEPTIONS E
			Where 
				E.METRIC_ID		= I_METRIC_ID 
				And E.OBJECT_ID	= T1.OBJECT_ID 
		)
		

    	And not exists
   		(
   			Select 1
   			From
   				CDT_OBJECTS T2, DSS_METRIC_PARAM_VALUES MPV
   			Where
				MPV.METRIC_ID		= I_METRIC_CHILD_ID
				And T2.OBJECT_ID 	= T1.OBJECT_ID
				
				And T2.OBJECT_NAME	like REPLACE(REPLACE(REPLACE(MPV.PARAM_CHAR_VALUE,'/','//'),'_','/_'),'%','/%') || '%' ESCAPE '/'
		)
	; 
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_NAM001;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_SQL001           * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_SQL001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
		
	Where
		SC.TECHNO_TYPE							= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID				    = SC.MODULE_ID
		And T1.OBJECT_TYPE						= 2351005 	     -- Coldfusion Query
		And Bitand(T1.PROPERTIES, 1)		    = 0 -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Number of Subqueries'
		And T2.METRIC_VALUE							> 0

 	;
Return ERRORCODE;
End; --COLDFUSION_QUERY_SQL001;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_SQL002           * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_SQL002 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
		
	Where
		SC.TECHNO_TYPE							= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID				    = SC.MODULE_ID
		And T1.OBJECT_TYPE						= 2351005 	     -- Coldfusion Query
		And Bitand(T1.PROPERTIES, 1)		    = 0 -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Number of GROUP BY'
		And T2.METRIC_VALUE							> 0

 	;
Return ERRORCODE;
End; --COLDFUSION_QUERY_SQL002;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_SQL003           * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_SQL003 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE	, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
		
	Where
		SC.TECHNO_TYPE							= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID				    = SC.MODULE_ID
		And T1.OBJECT_TYPE						= 2351005 	     -- Coldfusion Query
		And Bitand(T1.PROPERTIES, 1)		    = 0 -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Use of NOT EXISTS'
		And T2.METRIC_VALUE							> 0

 	;
Return ERRORCODE;
End; --COLDFUSION_QUERY_SQL003;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_SQL004           * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_SQL004 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
		
	Where
		SC.TECHNO_TYPE							= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID				    = SC.MODULE_ID
		And T1.OBJECT_TYPE						= 2351005 	     -- Coldfusion Query
		And Bitand(T1.PROPERTIES, 1)		    = 0 -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Joins on more than 4 Tables'
		And T2.METRIC_VALUE							> 0

 	;
Return ERRORCODE;
End; --COLDFUSION_QUERY_SQL004;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_SQL005           * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_SQL005 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
		
	Where
		SC.TECHNO_TYPE							= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID				    = SC.MODULE_ID
		And T1.OBJECT_TYPE						= 2351005 	     -- Coldfusion Query
		And Bitand(T1.PROPERTIES, 1)		    = 0 -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Avoid using SELECT * statement in SQL'
		And T2.METRIC_VALUE							> 0

 	;
Return ERRORCODE;
End; --COLDFUSION_QUERY_SQL005;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_SQL006           * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_SQL006 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
		
	Where
		SC.TECHNO_TYPE							= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID				    = SC.MODULE_ID
		And T1.OBJECT_TYPE						= 2351005 	     -- Coldfusion Query
		And Bitand(T1.PROPERTIES, 1)		    = 0 -- Application's Object
		And T1.OBJECT_ID						= T2.OBJECT_ID
		And T2.METRIC_TYPE						= 'Avoid using COUNT(*)'
		And T2.METRIC_VALUE						> 0

 	;
Return ERRORCODE;
End; --COLDFUSION_QUERY_SQL006;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_SQL007        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_SQL007 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE								= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID						= SC.MODULE_ID
		And T1.OBJECT_TYPE							= 2351005 	     -- Coldfusion Query
		And Bitand(T1.PROPERTIES, 1)				= 0              -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Avoid using UNION'
		And T2.METRIC_VALUE							> 0
 	;
Return ERRORCODE;
End; --COLDFUSION_QUERY_SQL007;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_QUERY_SQL008           * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_SQL008 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE								= 2351000   	 -- Technologic ColdFusion object
		And T1.APPLICATION_ID						= SC.MODULE_ID
		And T1.OBJECT_TYPE							= 2351005 	     -- Coldfusion Query
		And Bitand(T1.PROPERTIES, 1)				= 0              -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Use of NOT IN'
		And T2.METRIC_VALUE							> 0
 	;
	
Return ERRORCODE;
End; --COLDFUSION_QUERY_SQL008;
$$ LANGUAGE plpgsql;  

/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_TEC001        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_TEC001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>TECHN_XXX_TEC001<</NAME>>
--<<COMMENT>> Template name   = DSSAPPARTIFACTS. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid Siebel Functions with High Cyclomatic Complexity (CC > 20). <</COMMENT>>
--<<COMMENT>> Definition      = Avoid <Siebel Functions > with High Cyclomatic Complexity (CC > 20). <</COMMENT>>
--<<COMMENT>> Action          = Lists all <Siebel Functions > with High Cyclomatic Complexity. <</COMMENT>>
--<<COMMENT>> Value           = Cyclomatic Complexity. <</COMMENT>>
	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select
		distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T1.CYCLOMATIC, 0, 0
	From
		DSSAPP_ARTIFACTS T1, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE						= 2351000   		-- Technologic Coldfusion object
		And T1.OBJECT_TYPE					= 2351004 			-- Coldfusion Template
		And T1.APPLICATION_ID				= SC.MODULE_ID
		And T1.CYCLOMATIC 					>
		(
			Select PARAM_NUM_VALUE
			From
				DSS_METRIC_PARAM_VALUES MTP
			Where
				MTP.METRIC_ID		= I_METRIC_CHILD_ID
				And MTP.PARAM_INDEX	= 1
		)
		And Not Exists
		(
			Select 1
			From
				DSS_OBJECT_EXCEPTIONS E
			Where
				E.METRIC_ID		= I_METRIC_ID
				And E.OBJECT_ID	= T1.OBJECT_ID
		)
 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_TEC001;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_TOTAL         * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_TOTAL (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_VALUE_INDEX integer
)
Returns integer as $$
DECLARE
	ERRORCODE	int := 0;
Begin
--<<NAME>>SIEBEL_XXX_TOTAL<</NAME>>*/
--<<COMMENT>> Template name   = TOTAL. <</COMMENT>>
--<<COMMENT>> Definition      = Count of XXX Artifacts<</COMMENT>>

    Insert Into DSS_METRIC_RESULTS
		(METRIC_NUM_VALUE, METRIC_OBJECT_ID, OBJECT_ID, METRIC_ID, METRIC_VALUE_INDEX, SNAPSHOT_ID)
    Select 
    	Count(T1.OBJECT_ID), 0, SC.OBJECT_PARENT_ID, I_METRIC_ID, I_METRIC_VALUE_INDEX, I_SNAPSHOT_ID
    From
    	CTT_OBJECT_APPLICATIONS T1, DSSAPP_MODULES MO, DSS_METRIC_SCOPES SC
    Where
	    SC.SNAPSHOT_ID            			= I_SNAPSHOT_ID
	    And SC.METRIC_PARENT_ID    			= I_METRIC_PARENT_ID
	    And SC.METRIC_ID           			= I_METRIC_ID
 		And SC.COMPUTE_VALUE				= 0
		And MO.TECHNO_TYPE					= 2351000   			-- Technologic Coldfusion object
		And MO.MODULE_ID					= SC.OBJECT_ID
  		And T1.APPLICATION_ID      			= SC.OBJECT_ID

		And T1.OBJECT_TYPE					= 2351004 				-- Coldfusion Template
		And bitand(T1.PROPERTIES, 1) 		= 0 					-- Application's Object

		And Not Exists 
		(
			Select 1 
			From 
				DSS_OBJECT_EXCEPTIONS E
			Where 
				E.METRIC_ID		= I_METRIC_ID 
				And E.OBJECT_ID	= T1.OBJECT_ID 
		)
    Group By SC.OBJECT_PARENT_ID, SC.OBJECT_ID
	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_TOTAL;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_VOL001        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_VOL001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>COLDFUSION_TEMPLATE_VOL001<</NAME>>*/
--<<COMMENT>> Template name   = GENERICPARAMINT. <</COMMENT>>
--<<COMMENT>> Diagnostic name = Avoid long PHHP pages. <</COMMENT>>
--<<COMMENT>> Definition      = PHP pages should not have more than XXX lines of code. <</COMMENT>>
--<<COMMENT>> Action          = Lists PHP pages with more than XXX lines of code. <</COMMENT>>
--<<COMMENT>> Value           = Number of lines of code in the PHP pages. <</COMMENT>>
	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE					= 2351000   		-- Technologic CF object
		And T1.APPLICATION_ID			= SC.MODULE_ID
        And T1.OBJECT_TYPE 				= 2351004 	  		-- Artifact : CF Template
		And	Bitand(T1.PROPERTIES, 1)	= 0					-- Application's Object
        And T2.OBJECT_ID 				= T1.OBJECT_ID
        And T2.METRIC_TYPE	 			= 'Number of code lines'
		And CAST(T2.METRIC_VALUE as double precision)   >
		(
			Select PARAM_NUM_VALUE
			From
				DSS_METRIC_PARAM_VALUES MTP
			Where
				MTP.METRIC_ID	= I_METRIC_CHILD_ID
				And PARAM_INDEX	= 1
		)

	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_VOL001;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** PROCEDURE COLDFUSION_QUERY_RECORD        * OBJECT FROM DATA DICTIONARY  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_QUERY_RECORD (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin
--<<NAME>>COLDFUSION_QUERY_RECORD<<GONAME>>

--<<COMMENT>> VALUE           = 1. <<GOCOMMENT>>

	INSERT INTO DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	SELECT DISTINCT T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, CAST(T2.DESCRIPTION as double precision), 0, 0
	FROM
		CTT_OBJECT_APPLICATIONS T1, CSV_OBJECT_DESCRIPTIONS T2, DSSAPP_MODULES SC
		
	WHERE
		SC.TECHNO_TYPE							= 2351000   	-- TECHNOLOGIC COLDFUSION OBJECT
		AND T1.APPLICATION_ID				= SC.MODULE_ID
		AND T1.OBJECT_TYPE						= 2351005 	-- COLDFUSION QUERY
		AND Bitand(T1.PROPERTIES, 1)		= 0 -- APPLICATION'S OBJECT
		AND T1.OBJECT_ID							= T2.OBJECT_ID
		AND T2.DESC_TYPE							= 'COUNT OF SELECT STATEMENT IN CFQUERY'
		AND CAST(T2.DESCRIPTION as double precision) > '0'
		AND NOT EXISTS (
						  SELECT V1.OBJECT_ID 
						  FROM  CSV_CALLER_OBJECTS V1, CDT_OBJECTS V2 
						  WHERE V1.OBJECT_ID = V2.OBJECT_ID
								AND V1.CALLER_OBJECT_NAME = V2.OBJECT_NAME
								AND V1.OBJECT_ID=T1.OBJECT_ID
						)
 	;
Return ERRORCODE;
End; --COLDFUSION_QUERY_RECORD;
$$ LANGUAGE plpgsql;  


/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_EFF001        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_EFF001 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE								= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID						= SC.MODULE_ID
		And T1.OBJECT_TYPE							= 2351004 		-- Coldfusion Template
		And Bitand(T1.PROPERTIES, 1)				= 0 			-- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Count of cffile'
		And T2.METRIC_VALUE 						> 0

 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_EFF001;
$$ LANGUAGE plpgsql; 

/******************************************************************************/
/** FUNCTION COLDFUSION_INT_DIFF_METRIC        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_INT_DIFF_METRIC (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer,
	I_METRIC_TYPE_REFERENCE varchar(255),
	I_METRIC_TYPE_SECONDARY varchar(255)
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, coalesce(T2. METRIC_VALUE, 0) - coalesce(T3.METRIC_VALUE) , 0, 0	
	From
		CTT_OBJECT_APPLICATIONS T1
		left outer join (SELECT T2.OBJECT_ID, METRIC_VALUE
				FROM DIAG_OBJECT_METRICS T2
				WHERE T2.METRIC_TYPE = I_METRIC_TYPE_REFERENCE
				) T2 
		on T2.OBJECT_ID = T1.OBJECT_ID
		left outer join (
				SELECT T3.OBJECT_ID, METRIC_VALUE
				FROM DIAG_OBJECT_METRICS T3
				WHERE T3.METRIC_TYPE = I_METRIC_TYPE_SECONDARY
				) T3				
		on T3.OBJECT_ID = T1.OBJECT_ID
		, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE						= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID				= SC.MODULE_ID
		And T1.OBJECT_TYPE					= 2351004 		-- Coldfusion Template
		And Bitand(T1.PROPERTIES, 1)		= 0 			-- Application's Object
		And T1.OBJECT_ID					= T2.OBJECT_ID
		And coalesce(T2. METRIC_VALUE, 0) 	> coalesce(T3.METRIC_VALUE)
		And Not Exists
				(
					select 1
					from
						DSS_OBJECT_EXCEPTIONS E
					where
						E.METRIC_ID		= I_METRIC_ID
						and E.OBJECT_ID	= T1.OBJECT_ID
				)
 	;
Return ERRORCODE;
End; 
$$ LANGUAGE plpgsql; 

/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_EFF002        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_EFF002 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	ERRORCODE := COLDFUSION_INT_DIFF_METRIC(I_SNAPSHOT_ID,	I_METRIC_PARENT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, 'Count of cfdump', 'Count of isDebugMode')
	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_EFF002;
$$ LANGUAGE plpgsql; 

/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_PP002        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_PP002 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	ERRORCODE := COLDFUSION_INT_DIFF_METRIC(I_SNAPSHOT_ID,	I_METRIC_PARENT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, 'Count of cfswitch', 'Count of cfdefaultcase')
	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_PP002;
$$ LANGUAGE plpgsql; 

/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_EFF003        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_EFF003 (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE								= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID						= SC.MODULE_ID
		And T1.OBJECT_TYPE							= 2351004 	-- Coldfusion Template
		And Bitand(T1.PROPERTIES, 1)				= 0 -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Count of iif'    
		And T2.METRIC_VALUE 						> 0
 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_EFF003;
$$ LANGUAGE plpgsql; 

/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_SQLLOOP        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_SQLLOOP (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE								= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID						= SC.MODULE_ID
		And T1.OBJECT_TYPE							= 2351004 	-- Coldfusion Template
		And Bitand(T1.PROPERTIES, 1)				= 0 -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Number of SQL Queries Inside Loop'    
		And T2.METRIC_VALUE 						> 0
 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_SQLLOOP;
$$ LANGUAGE plpgsql; 

/******************************************************************************/
/** FUNCTION COLDFUSION_TEMPLATE_INSTLOOP        * Object from Data Dictionary  */
/******************************************************************************/

CREATE OR REPLACE FUNCTION COLDFUSION_TEMPLATE_INSTLOOP (
	I_SNAPSHOT_ID integer,	-- the metric snapshot id
	I_METRIC_PARENT_ID integer,	-- the metric parent id
	I_METRIC_ID integer,	-- the metric id
	I_METRIC_CHILD_ID integer
)
Returns integer as $$
DECLARE
	ERRORCODE	INT := 0;
Begin

	Insert Into DSS_METRIC_SCOPES (OBJECT_ID, METRIC_PARENT_ID, METRIC_ID, OBJECT_PARENT_ID, SNAPSHOT_ID, METRIC_NUM_VALUE, METRIC_OBJECT_ID, COMPUTE_VALUE)
	Select distinct T1.OBJECT_ID, I_METRIC_ID, I_METRIC_CHILD_ID, SC.MODULE_ID, I_SNAPSHOT_ID, T2.METRIC_VALUE, 0, 0
	From
		CTT_OBJECT_APPLICATIONS T1, DIAG_OBJECT_METRICS T2, DSSAPP_MODULES SC
	Where
		SC.TECHNO_TYPE								= 2351000   	-- Technologic ColdFusion object
		And T1.APPLICATION_ID						= SC.MODULE_ID
		And T1.OBJECT_TYPE							= 2351004 	-- Coldfusion Template
		And Bitand(T1.PROPERTIES, 1)				= 0 -- Application's Object
		And T1.OBJECT_ID							= T2.OBJECT_ID
		And T2.METRIC_TYPE							= 'Number of Instanciation Inside Loop'    
		And T2.METRIC_VALUE 						> 0
 	;
Return ERRORCODE;
End; --COLDFUSION_TEMPLATE_INSTLOOP;
$$ LANGUAGE plpgsql; 

