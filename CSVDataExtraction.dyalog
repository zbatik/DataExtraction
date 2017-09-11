:Class CSVDataExtraction
⍝ This class provides a platform in which the developer can write
⍝ easy to read, SQL-esque queries on data stored in .csv files.

⍝ The framework is initiated with a list of directories which will
⍝ be searched while evaluating the `Select` and `From` functions.

⍝ ~~~
⍝ direcotires←'C:/MyCsv1' 'C:\MyCsv2\'      ⍝ Note that directory naming is resolved
⍝ :With CSVImport←⎕NEW CSVDataExtraction directories
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

    :Field Private ReadOnly ext ← '.csv'
    :Field Private search_directories
    :Field Private csv_column_headers        ⍝ If the selected file has column heading store them here otherwise store ⍬
    :Field Private csv_data                  ⍝ Store the full imported csv file here
    :Field Private sel_cols_index            ⍝ Numeric vector selected column index is the position index of the columns that must be stored
    :Field Private where_bin ← ⍬             ⍝ Boolean vector the length of the number of rows in the csv
    :Field Private data_space_name           ⍝ The name of the namesapce that the column variables will be stored in
    :Field Private data_names                ⍝ The name of the variables to store

    ⍝ General Settings
    :Field Private data_types ← 4
    :Field Public base ← '##.'               ⍝ define the base namespace to put the imported data
    :Field Public root ← '_data'             ⍝ define the name of the namespace to store the imported data
    ⍝ Boolean Settings
    :Field Public remove_empty_cols←1        ⍝ Boolean indicator.<<br>> Indicates whether or not to remove empty columns (if the column has a heading the header must be empty too for the column to be considered empty)
    :Field Public remove_empty_rows←1        ⍝ Boolean indicator.<<br>> Indicates whether or not to seach the file and remove any empty empty rows
    :Field Public save_as_matrix ← 0         ⍝ Boolean indicator.<<br>> Indicates whether or not the .csv file will be stored as a matrix in the root or as a set of variables in root.[name]
    :Field Public has_heading_row ← 1        ⍝ Boolean indicator.<<br>> Indicates whether or not the first row of the .csv file a row of column headings.
    :Field Public strict_file_matching ←0    ⍝ Boolean indicator.<<br>> Indicates whether or not the file names/column headings need to have the right case.
    :Field Public strict_column_matching ← 0 ⍝ Boolean indicator.<<br>> Indicates whether or not to allow soft matching on column names.<<br>> A match will be made so long as the match is unquie and that all the alpha numberics are the same and in the right order (ie Col1 will accept: col1, COL_1, Col 1, etc.)
    :Field Public use_name_mangling ← 0      ⍝ Boolean indicator.<<br>> Indicates whether or not to use name managling to store names that are not propper APL names. If enabled all variable/namespace names that are not valid will be stored under the name provided by the json name mangling algorithm `0(7162⌶)name`
    :Field Private is_vec_indexing           ⍝ Boolean indicator. Indicates whether or not the column selection is done by reference to column headers 0, or by a numeric vector 1. For internal use only (hence Private)
    :Field Public suppress_errors ← 0        ⍝ ~~Boolean indicator.<<br>> On error while matching a file or a column, should the error be thrown or should it be suppressed nothing saved.~~<<br>> Functionality currently not impilmented
    :Field Public keep_columns ← 0           ⍝ ~~Boolean indicator.<<br>> Indicates whether or not to whether to store a copy of the column titles in the data namespace.~~<<br>> Functionality currently not impilmented

    ∇ r←Version
      :Access Public Shared
    ⍝ * 1.0.0
    ⍝   * First stable release, Zack Batik
      r←⎕THIS'1.0.0' '2017/07/14'
    ∇

    ∇ make1 dirs
      :Access Public
      :Implements Constructor
      ⍝ Default root and defult base: ##._data
      search_directories←FmtDirNames¨⊆dirs
      root←(base,root)⎕NS''
    ∇
    ∇ make2(rootname dirs)
      :Access Public
      :Implements Constructor
      ⍝ takes root as weither a existing ns or as a string
      search_directories←FmtDirNames¨⊆dirs
      root←⍕rootname
      root←(base,root)⎕NS''
    ∇
    FmtDirNames← {'\'=¯1↑⍵:⍵ ⋄ ⍵,'\'}∘{('/'⎕R'\\')⍵}

    ∇ validname←NameCheck name;msg
    ⍝ Takes the names of that are to be executed and finds out
    ⍝   if they are valid APL variable/namespace names.
    ⍝ Depending on the use_name_mangling switch either an
    ⍝   exception will be through or the name will be converted
    ⍝   to a valid APL name using the JSON name mangling algorithm
     
      :If ¯1=⎕NC name                         ⍝ if name is invaild
          :If use_name_mangling               ⍝ and if name mangling is enabled
              validname←0(7162⌶)name          ⍝ either change name
          :Else
              msg←name,' is an invalid name'  ⍝ or throw exception
              msg ⎕SIGNAL 782
          :EndIf
      :Else
          validname←name                      ⍝ if it is fine leave it as is
      :EndIf
    ∇

    :Property DataTypes
    :Access Public
⍝ Below copied from documentation on `⎕CSV` <<br>>
⍝ This is a scalar numeric code or vector of numeric codes that specifies the field types from the list below. If Column Types is zilde or omitted, the default is 1 (all fields are character).
⍝ * 0 The field is ignored.
⍝ * 1 The field contains character data.
⍝ * 2 The field is to be interpreted as being numeric. Empty cells and cells which cannot be converted to numeric values are not tolerated and cause an error to be signalled.
⍝ * 3 The field is to be interpreted as being numeric but invalid numeric vales are tolerated. Empty fields and fields which cannot be converted to numeric values are replaced with the Fill variant option (default 0).
⍝ * 4 The field is to be interpreted numeric data but invalid numeric data is tolerated. Empty fields and fields which cannot be converted to numeric values are returned instead as character data; this type is disallowed when variant option Invert is set to 1.
⍝ Note that if Column Types is specified by a scalar 4, all numeric data in all fields will be converted to numbers.
        ∇ r←get
          r←data_types
        ∇
        ∇ set datatypes;ind
          data_types←datatypes
        ∇
    :EndProperty




    ∇ SetDataNames(columns file)
      ⍝ Store the names of the variables and/or namespace that will be
      ⍝ used to store the data is the csv file
      data_space_name←NameCheck file    ⍝ the file name
     
      :If is_vec_indexing               ⍝ if using vector indexing then
          data_names←(⊂⍬)⍴⍨⍴,columns    ⍝ set a vec of ⍬'s as the data names
      :ElseIf columns≡'*'               ⍝ if selecting the whole file to be stored as a matirx,
          data_names←(⊂⍬)⍴⍨2⊃⍴csv_data  ⍝ set a vec of ⍬'s as the data names
      :Else                             ⍝ otherwise if columns as strings are coming though,
          data_names←NameCheck¨⊆columns ⍝ check their names and store
      :EndIf
    ∇

    ∇ CheckIndexingType columns;check;a
      check←isNumber¨⊆columns
      :If (a≠⍴,check)∧0≠a←+/check
          'Mixed formatting'⎕SIGNAL 512 ⍝ if there are stings and numerics in the columns
      :EndIf
      is_vec_indexing←∧/check
    ∇

    ∇ {r}←columns From file;path;csvdata
      :Access Public
      CheckIndexingType columns
     
⍝     Do Tests on Columns
      path←FindFile file         ⍝ Find the file in the set of given directories
      ImportFile path            ⍝ Import the file and store in data in fields
     
      SetDataNames columns file
      :If columns≡'*'
          save_as_matrix←1
          sel_cols_index←⍳2⊃⍴csv_data
      :ElseIf has_heading_row∧~save_as_matrix
      :AndIf ~is_vec_indexing
          sel_cols_index←GetColumnIndex⊆columns
      :ElseIf is_vec_indexing
          save_as_matrix←1
          sel_cols_index←columns
      :Else
          'Problem with column indexing'⎕SIGNAL 900
      :EndIf
      where_bin←1⍴⍨≢csv_data
     ⍝ Check if there is any indexing that must take place
      r←1
    ∇
    ∇ path←FindFile file;dir;existing_files;match_files;lookfor;bin;match
      ⍝ Search for the given file in the set of directories given
      :For dir :In search_directories
          existing_files←2⊃¨⎕NPARTS¨⊃(⎕NINFO⍠1)dir,'*',ext
          match←strict_file_matching Match file existing_files
          :If ⍬≢match
              path←dir,match,ext
              :GoTo DONE
          :EndIf
      :EndFor
      'File not found'⎕SIGNAL 787
     DONE:
    ∇

    ∇ match←strict Match(lookfor lookin);bin;stdlookin;Stdardize
      Stdardize←{toUpperCase ⍵/⍨isAlphaNumeric ⍵}
      :If ~strict
          stdlookin←Stdardize¨lookin
          lookfor←Stdardize lookfor
      :Else
          stdlookin←lookin
      :EndIf
     
      :If ∨/bin←stdlookin∊⊂lookfor
          :If 1<+/bin
              'More than one match'⎕SIGNAL 676
          :EndIf
          match←⊃bin/lookin
      :Else
          match←⍬
      :EndIf
    ∇

    ∇ ind←GetColumnIndex selcols;columnmatch;bin;msg
    ⍝ Take either a vector of indexes or a list of column headings and
    ⍝ return a vector of indexs.
      :If is_vec_indexing         ⍝ if it is already in index form
          ind←selcols             ⍝ then there is nothing to be done
      :Else
          columnmatch←{strict_column_matching∘Match ⍵ csv_column_headers}¨⊆selcols
          :If ∨/bin←columnmatch≡¨⊂⍬
              msg←'The following column titles do not match: ',CommaAndList bin/selcols
              msg ⎕SIGNAL 569
          :EndIf
          ind←csv_column_headers⍳columnmatch
      :EndIf
    ∇

    ∇ ImportFile path;import;column_headers;data;bin;colbin;remind;rowbin;rembin;checkheadbin
      ⍝ Import csv file and store as data and column headers
      ⍝ Defult on data_types is 4 and has_heading is 1
      data column_headers←2↑(⊂⍬),⍨{¯2=≡⍵:,⊂⍵ ⋄ ⍵}⎕CSV path''data_types has_heading_row
      :If 0=⊃⍴data
          csv_data csv_column_headers←⍬ column_headers
          :Return
      :End
      ⍝ A column is considered empty iff all the data points are empty and the corresponding
      ⍝ column heading (where applicable) is also empty.
      :If remove_empty_cols
          checkheadbin←(⊂'')∊⍨(((⊂'')⍴⍨⍴)⍣(~has_heading_row))column_headers
      :AndIf ∨/bin←checkheadbin∧data[1;]∊⊂''          ⍝ look for empty cells on the first row
      :AndIf ∨/colbin←∧⌿(bin/data)∊(⊂'')              ⍝ if there are none it is impossible for there to be any completely empty columns
          remind←colbin/bin/⍳⍴bin
          data←data/⍨rembin←(0@remind)1⍴⍨⍴bin
          column_headers←(rembin∘/⍣has_heading_row)column_headers
      :EndIf
      :If remove_empty_rows      ⍝ use the same logic as with the columns
      :AndIf ∨/bin←data[;1]∊⊂''
      :AndIf ∨/rowbin←∧/(bin⌿data)∊(⊂'')
          remind←rowbin/bin/⍳⍴bin
          data←data⌿⍨(0@remind)1⍴⍨⍴bin
      :EndIf
      csv_data csv_column_headers←data column_headers
    ∇

    ∇ Run;data
      :Access Public
      ⍝ Creats an execute sting based off the information gathered and
      ⍝ saves the csv data data variables in the structure defined.
      :If 0=⊃⍴csv_data
          data←⊂⍬
      :Else
          data←where_and_bin⌿csv_data[;sel_cols_index]
      :EndIf
     
      :If ⍬≡where_bin
          data←csv_data[;sel_cols_index]
      :Else
          data←where_bin⌿csv_data[;sel_cols_index]
      :EndIf
     
      data_space_name←NameCheck data_space_name
     
      :If save_as_matrix
          ⍎root,'.',data_space_name,'← data'
      :Else
          data_name←NameCheck¨data_names
          data_space_name ⎕NS''
          root ⎕NS data_space_name
          ⍎(1↓⊃,/(⊂' ',root,'.',data_space_name,'.'),¨data_names),' ←  ((↓⍉)⍣(⊃1<⍴⍴data))data'
      :EndIf
      Reset
    ∇

    ∇ Reset
    ⍝ Reset all the relivant fields. Called at the end of `Run` so that if there
    ⍝ is a new Select statement there won't be any conflicting data from the
    ⍝ preiviouse selection.
     
     ⍝ Reset Public Fields
      data_types←4
      remove_empty_cols←1
      remove_empty_rows←1
      save_as_matrix←0
      has_heading_row←1
      strict_file_matching←0
      strict_column_matching←0
      use_name_mangling←0
      suppress_errors←0
      keep_columns←0
    ⍝ Erase Private Fields
      ⎕EX'csv_data' 'csv_column_headings' 'where_bin'
      ⎕EX'data_space_name' 'data_names' 'sel_cols_index'
    ∇
    ∇ StoreColumnsAs new_names
      :Access Public
      ⍝ Is is only applicable if the data is not intended to be stored as a matrix.<<br>>
      ⍝ In the defualt case the columns are stored as variables and named by their column
      ⍝ header. This function overrides the defualt names. The incoming new names must be
      ⍝ the same length as the number of columns to be saved since each name incoming is
      ⍝ matched to the indexes/column names put forth in the columns of the `Select columns Form 'File'`
      :If (⍴new_names)≠⍴data_names
          'Incorrect number of names'⎕SIGNAL 988
      :EndIf
      data_names←NameCheck¨⊆new_names
      save_as_matrix←0
    ∇
    ∇ StoreFileAs new_name
      :Access Public
      ⍝ If the data is to be stored as a matrix then the defaut is to name the matrix variable
      ⍝ whatever the file was named. Same goes if the data is not to be stored as a matrix then it
      ⍝ is stored as a set of variables inside a namespace where the namespace has the same name
      ⍝ as the file that the data was read from. This function overwirtes the that default name.
      data_space_name←new_name
    ∇
    ∇ Select arg
      :Access Public
      ⍝ Function actually does nothing...<<br>>
      ⍝ At the moment it is simply here
      ⍝ for that SQL nostalgia.
    ∇

    ∇ Where bin
      :Access Public
      ⍝ Creates a row selection boolean mask
      where_bin←bin
    ∇

    ∇ And bin
      :Access Public
      ⍝ Updates the row selection mask.
      where_bin∧←bin
    ∇
    ∇ Or bin
      :Access Public
      ⍝ Updates the row selection mask
      where_bin∨←bin
      ⍝ Must be run after `Where`
    ∇

    ∇ bin←column Equals value;ind
      :Access Public
      ⍝ Creates a selection index across the rows based off
      ⍝ the specifications given.
      ind←GetColumnIndex column
      bin←csv_data[;ind]∊⊆value
    ∇

    ∇ execute←function To column;ind
      :Access Public
      ⍝ The `Apply {⍵} To 'Col'` is limited to changing the values in a column but not changing the shape
      ⍝ Currently localised function in the calling funtion can't be accessed. Funtion must be
      ⍝ a string representing a globably accessable function.
      ind function←function ApplyTo column
      execute←'csv_data[;',ind,']','←',function,' csv_data[;',ind,']'
    ∇
    ∇ execute←function ToEach column;ind
      :Access Public
      ⍝ The `Apply {⍵} To 'Col'` is limited to changing the values in a column but not changing the shape
      ⍝ Currently localised function in the calling funtion can't be accessed. Funtion must be
      ⍝ a string representing a globably accessable function.
      ind function←function ApplyTo column
      execute←'csv_data[;',ind,']','←',function,'¨ csv_data[;',ind,']'
    ∇

    ∇ Apply execute
      :Access Public
      →(0=⊃⍴csv_data)⍴0 ⍝ If there is no data return
      ⍝ Executes the execute string prepared in `To`
      :Trap 6 ⍝ Value error (will only apply if the function assigned in To cannot be found)
              ⍝ a value error will be thrown if the funtion to be called is localised in the
              ⍝ calling namespace.
          ⍎execute
      :Else
          'Could not find function'⎕SIGNAL 567
      :EndTrap
    ∇

    ∇ (ind function)←function ApplyTo column
      function←{⍵,⍨'##.'⍴⍨3×⍨⊃('#'≠1↑⍵)∧('}{'≢¯2↑1⌽⍵)}function ⍝ add a ##. if it is not a dfn or if it does not already have a root ns defined
      :If ('}{'≢¯2↑1⌽function)∧3≠⎕NC function
          'Could not find function'⎕SIGNAL 567
      :EndIf
      ind←⍕GetColumnIndex column
    ∇

    ∇ bin←column Is(operation value);ind;Compare
      :Access Public
      ⍝ `Is` is a generalisation on `Equals` as it allows the user to difine
      ⍝ a greater number of comparisons.<<br>>
      ⍝ The input operation can be:
      ⍝ * Greater Than          (>)
      ⍝ * Greater Than Equal To (≥)
      ⍝ * Less Than             (<)
      ⍝ * Less Than Equal To    (≤)
      ⍝ * Not Equal             (≠) <<br>>
      ⍝ The operation string is ivaluated as lower case and with out spaces.
      ind←GetColumnIndex column
      :Select ' '~⍨toLowerCase operation
      :CaseList 'greaterthan' '>' ⋄ Compare←>
      :CaseList 'grearterthanequalto' '≥' ⋄ Compare←≥
      :CaseList 'lessthan' '<' ⋄ Compare←<
      :CaseList 'lessthanequal' '≤' ⋄ Compare←≤
      :CaseList 'notequal' '≠' ⋄ Compare←≠
      :EndSelect
      bin←csv_data[;ind]Compare⊆value
    ∇

:EndClass
