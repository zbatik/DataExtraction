:Class DataExtraction
⍝ This class provides a platform in which the developer can write
⍝ easy to read, SQL-esque import functions for data stored in a
⍝ database.


⍝ ~~~
⍝ :With ImportData←⎕NEW DataExtraction DSN
⍝
⍝   Select'*'From'File1'                  ⍝ Read and store the whole file File1.csv
⍝   Run                                   ⍝ Execute the SELECT
⍝
⍝   Select'Column1' 'Column2'From'File2'  ⍝ Only read in the columns labled 'Column1' and 'Column2'
⍝   Where'Column3'Equals'Hat'             ⍝ And only save the rows in 'Column1' and 'Column2' where
⍝   Run                                   ⍝ 'Column3' has the entry 'Hat'
⍝
⍝   Select 1 2 3 From'File3'              ⍝ Read in the first, second and third columns
⍝   Where 5 Is'<' 3                       ⍝ and filter by where column 5 is greater than 3
⍝   And 6 Is'Less Than' 90                ⍝ and column 6 is less than 90
⍝   Run
⍝
⍝   Select'Column10'From'File4'           ⍝ Select the column headed 'Column10'
⍝   Apply'{+\⍵}'To'Column10'              ⍝ and apply {+\⍵} before saving it
⍝   Run
⍝
⍝ :EndWith
⍝ ~~~

    :Include Utilities

    :Field Private DSN                 ⍝ Data Source Name: ⍴=3 [1] Name, [2] Username, [3] Password
    :Field Public all_table_names     ⍝ A list of all the avalible tables in the db
    :Field Private root                ⍝ The ns name where the db data is stored
    :Field Private conn_string         ⍝ Holds the name of the connection string used to access the db

    :Field Private table_name          ⍝ The name of the table that is being currently built up
    :Field Private table_name_internal ⍝ The internal Dyalog name with which to reference the table
    :Field Private field_names         ⍝ The fields that are to be loaded into the ws
    :Field Private field_name_internal ⍝ The internal names that the field data will be assigned

    :Field Private sql_select          ⍝ Holds the SELECT statement
    :Field Private sql_where ← ''      ⍝ Holds any build up of AND/WHERE sql statments
    :Field Private sql_order_by ←''
    :Field Private execute_strings ←''

    :Field Private save_as_matrix ← 0  ⍝ Boolean that declares whether a table is stored as a matrix or as a namespace
    :Field Private is_case_sensitive ← 1

    ∇ make1 dsn;rootname
      :Access Public
      :Implements Constructor
      ⍝ Defaults the name of the database root to _data
      rootname←'_data'
      Initialise dsn rootname
    ∇

    ∇ make2(dsn rootname)
      :Access Public
      :Implements Constructor
      Initialise dsn rootname
    ∇

    :Property RootNamespace
    :Access Public
        ∇ r←get
          r←root
        ∇

        ∇ set rootns
          root←(base∘,⍣('#'≠⊃⍕rootns))⍕rootns
        ∇
    :EndProperty

    :Property SQLFrom
    :Access Public Overridable
        ∇ r←get
          r←' FROM '
        ∇
    :EndProperty


    ∇ Initialise(dsn rootname);resp;default_base;baseroot
     
      DSN←dsn                          ⍝ Set a global datasource name
      ⍝ Allows user to diffine the root.
      ⍝ The user can pass an existing ns or
      ⍝       a valid string for use in ⎕NS
      default_base←'##'
      baseroot←⍕rootname            ⍝ If rootnamespace is turn it into a string
      :If '#'≠1⊃baseroot       ⍝ If it's beginning is not defined then a
          baseroot←default_base,'.',baseroot
      :EndIf
     
      :If 9≠⎕NC'rootname'       ⍝ If rootname is 9 it already exists and there is no need to run ⎕ns
          root←baseroot ⎕NS''
      :Else
          root←baseroot
      :EndIf
      :If 9≠⎕NC '#.SQA'                 ⍝ Bring in copy of SQAPL if not present
          '#.SQA'⎕CY'SQAPL'
      :EndIf
      resp←#.SQA.Init''                ⍝ Initialise the SQA
      :If 0≠1⊃resp                     ⍝ Check it worked
          (2⊃resp)⎕SIGNAL 500
      :EndIf
      Connect                          ⍝ Connect to database
      all_table_names←GetTableNames    ⍝ Get a list of tables in the database
    ∇  

    ∇ r←field Equals value;ap
      :Access Public
      ⍝ Creates the SQL condition string for a WHERE, AND or OR statement
      ap←''''⍴⍨~isNumber value
      r←field,' = ',ap,(⍕value),ap
    ∇
    ∇ r←field Is(operation value);ap;compare
      :Access Public
      ⍝ Creates the SQL condition string for a WHERE, AND or OR statement. <<br>>
      ⍝ `Is` is a generalisation on `Equals` as it allows the user to difine
      ⍝ a greater number of comparisons.<<br>>
      ⍝ The input operation can be:
      ⍝ * Equals                (=)
      ⍝ * Greater Than          (>)
      ⍝ * Greater Than Equal To (≥)
      ⍝ * Less Than             (<)
      ⍝ * Less Than Equal To    (≤)
      ⍝ * Not Equal             (≠) <<br>>
      ⍝ The operation string is evaluated as lower case and without spaces.
      ap←''''⍴⍨~isNumber value
      :Select ' '~⍨toLowerCase operation
      :CaseList 'equals' '=' ⋄ compare←'='
      :CaseList 'greaterthan' '>' ⋄ compare←'>'
      :CaseList 'grearterthanequalto' '≥' '>=' ⋄ compare←'>='
      :CaseList 'lessthan' '<' ⋄ compare←'<'
      :CaseList 'lessthanequal' '≤' '<=' ⋄ compare←'<='
      :CaseList 'notequal' '≠' '<>' ⋄ compare←'<>'
      :EndSelect
      r←field,' ',compare,' ',ap,(⍕value),ap
    ∇

    ∇ Where sql
      :Access Public
      ⍝ Starts a WHERE SQL statment
      sql_where←' WHERE ',sql
    ∇
    ∇ And sql
      :Access Public
      ⍝ Adds an AND statement to an existing WHERE statement
      sql_where,←' AND ',sql
    ∇
    ∇ Or sql
      :Access Public
      ⍝ Adds an OR statement to an existing WHERE statement
      sql_where,←' OR ',sql
    ∇

    ∇ {is_asc}OrderBy field;order;len;options;order_by
      :Access Public
      ⍝ Creates an ORDER BY statement. The left argument is a field or list of
      ⍝ fields and and the right arg is a boolean or a boolean vector. 1 is for
      ⍝ ascending order and 0 is for descending order.
     
      field←,⊆field       ⍝ enlclose if empty
      len←⍴field          ⍝ capture the length
     
      :If 0=⎕NC'is_asc'   ⍝ if the right arg is undefined
          order←len⍴⊂''   ⍝ then set the option to empty (which defaults to ASC)
      :Else
          options←' DESC' ' ASC'
          order←options[1+is_asc]           ⍝ Select the appropriate suffix
      :EndIf
      order_by←2↓⊃,/(⊂', '),¨field,¨order   ⍝ Add commas and disclose
     
      sql_order_by←' ORDER BY ',order_by    ⍝ Finalise statement
    ∇

    ∇ Select from
      :Access Public
      ⍝ Formats and stores a SQL SELECT statment for use in the Run function
      sql_select←'SELECT ',from
    ∇
    ∇ r←fields From table;fields_in_table;bin;msg;errorfields;list_fields
      :Access Public
      ⍝ Checks that the relevant tables and fields exist in the db
      ⍝ and does a partial SQL formatting. The resulting string to
      ⍝ be passed directly into the Select function.
      table_name←,⊂table_name_internal←table    ⍝ store enclosed table name
      field_names←field_name_internal←,⊆,fields  ⍝ store an enclosed list of fields
     
         ⍝ Check table name exists
      :If ~table_name∊all_table_names
         ⍝ Do a quick comparrison to see if it is close to any existing name
         ⍝ and throw error with a 'Did you mean...'
          'Table does not exist'⎕SIGNAL 543
      :EndIf
     
      fields_in_table←GetFieldNames table_name ⍝ get a list of all the fields in the selected table
     
      :If field_names≡,⊆,'*'                           ⍝ if all columns are selected
          save_as_matrix←1                     ⍝ then automatically store as a matrix
      :ElseIf 1∊bin←~field_names∊fields_in_table    ⍝ otherwise check to see that the indicated fields exist
         ⍝ Do a quick comparrison to see if it is close to any existing name
         ⍝ and throw error with a 'Did you mean...'
          errorfields←bin/field_names
          msg←'Could not find ',CommaAndList errorfields
          msg ⎕SIGNAL 544
      :EndIf
      list_fields←2↓⊃,/(⊂', '),¨field_names
      r←list_fields,SQLFrom,⊃table_name
    ∇

    ∇ Apply execute
      :Access Public
      ⍝ Stores the execute string prepared in `To`
      execute_strings,←⊂execute
    ∇

    ∇ execute←function To field;ind;changevar;msg;base;hash
      :Access Public
      ⍝ The right arg is a field as specified in the database and the fnunction of the right
      ⍝ is a string either representing a dfn ie `function←'{+\⍵}` or is the name of a function.
      ⍝ Currently localised function in the calling funtion can't be accessed. Funtion must
      ⍝ represent a globably accessable function. <<br>>
      ⍝ If the data is being saved as matix then the funtion is limited to operations that do
      ⍝ not change the shape of the data.
      function←{⍵,⍨'##.'⍴⍨3×⍨⊃('#'≠1↑⍵)∧('}{'≢¯2↑1⌽⍵)}function ⍝ add a ##. if it is not a dfn or if it does not already have a root ns defined
      :If ('}{'≢¯2↑1⌽function)∧3≠⎕NC function
          msg←'Problem with function ',function
          msg ⎕SIGNAL 799
      :EndIf
      base←root,'.',table_name_internal
      ind←field_names⍳⊆field
      :If save_as_matrix
          changevar←base,'[;',(⍕ind),']'
      :Else
          changevar←base,'.',⊃field_name_internal[ind]
      :EndIf
      execute←changevar,'←',function,changevar
    ∇

    ∇ {matrix}StoreTableAs internal_name
      :Access Public
       ⍝ The left argument if present determines whether the
       ⍝ table being imported will be stores as a matrix
       ⍝ or as a set of variables inside a namesapce. The defualt
       ⍝ is 0 - to save as vars in a ns. The right argumnet is the
       ⍝ name that this table is to be stored as (either the name
       ⍝ of a ns or the name of a variable containing a matrix)
      :If 2=⎕NC'matrix'
          save_as_matrix←matrix
      :EndIf
      table_name_internal←internal_name
    ∇
    ∇ StoreFieldsAs internal_names
      :Access Public
      ⍝ define the name of variable to store the imported fields in
     
      :If ~(⍴field_names)=⍴,internal_names
          'Inconsistent number of field names'⎕SIGNAL 600
      :EndIf
      field_name_internal←,⊆,internal_names
    ∇

    ∇ Run;data;sql;disclose
      :Access Public
      ⍝ Applies all the SQL select statement and stores the data in the form
      ⍝ spesified by the previouse proceedures.
     
      ⍝ Run SQL
      sql←sql_select,sql_where,sql_order_by
      data←Read sql
      ⍝ Store Data
      :If save_as_matrix
          ⍎root,'.',table_name_internal,'← data'
      :Else
          table_name_internal ⎕NS''
          root ⎕NS table_name_internal
          disclose←(1=2⊃⍴data)⍴'⊃'
          ⍎(1↓⊃,/(⊂' ',root,'.',table_name_internal,'.'),¨field_name_internal),' ← ',disclose,'↓⍉data'
      :EndIf
      ⍝ Execute Additional Code
      :If execute_strings≢''
          :Trap 0
              ⍎¨execute_strings
          :Else
              'Execution error'⎕SIGNAL 567
          :EndTrap
      :EndIf
      Reset
    ∇

    ∇ Reset
      ⎕EX'sql_select' 'table_name' 'internal_table_name' 'field_names' 'internal_field_name'
      sql_where←''
      sql_order_by←''
      execute_strings←''
      save_as_matrix←0
    ∇


    :Section SQAHandling

    ∇ Connect;conn;newconn;response
      conn←⊃¨2 2⊃#.SQA.Tree'.'                      ⍝ list existing connections
      conn_string←1⊃((⊂'SQAPL'),¨⍕¨⍳1+⍴conn)~conn   ⍝ pick the next unique name for this connection
      response←#.SQA.Connect(⊂conn_string),DSN
      :If 0<1⊃response
          conn_string←⍬
          (3⊃response)⎕SIGNAL 501
      :EndIf
    ∇

    ∇ res←Read sql;response
      :Access Public
      response←#.SQA.Do conn_string sql
      :If 0=1⊃response
          res←⊃3⊃response
      :Else
          (3⊃response)⎕SIGNAL 502
      :EndIf
    ∇

    ∇ r←GetTableNames;table;bin;r
      :Access Public
      table←2⊃#.SQA.Tables conn_string
      bin←table[;4]∊⊂'TABLE'
      r←bin/table[;3]
    ∇
    ∇ r←GetFieldNames table
      :Access Public
      r←1↓(2⊃#.SQA.Columns conn_string table)[;4]
    ∇

    ∇ Close;dummy
      :Implements Destructor
      dummy←#.SQA.Close conn_string
    ∇

    :EndSection

    ∇ r←Test_OrderBy_001
      :Access Public Shared
      r←⍬
      OrderBy'Col1'
      r,←sql_order_by≡' ORDER BY Col1'
     
      OrderBy'Col2'
      r,←sql_order_by≡' ORDER BY Col2'
     
      OrderBy'Col1' 'Col2'
      r,←sql_order_by≡' ORDER BY Col1, Col2'
     
      1 OrderBy'Col1'
      r,←sql_order_by≡' ORDER BY Col1 ASC'
     
      0 OrderBy'Col1'
      r,←sql_order_by≡' ORDER BY Col1 DESC'
     
      1 OrderBy'Col1' 'Col2'
      r,←sql_order_by≡' ORDER BY Col1 ASC, Col2 ASC'
     
      0 OrderBy'Col1' 'Col2'
      r,←sql_order_by≡' ORDER BY Col1 DESC, Col2 DESC'
     
      0 1 OrderBy'Col1' 'Col2'
      r,←sql_order_by≡' ORDER BY Col1 DESC, Col2 ASC'
     
      1 0 OrderBy'Col1' 'Col2'
      r,←sql_order_by≡' ORDER BY Col1 ASC, Col2 DESC'
     
    ∇

:EndClass
