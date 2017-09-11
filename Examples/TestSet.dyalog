:Namespace Test
(⎕IO ⎕ML ⎕WX)←1 1 3

∇ r←Test004;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 :With SQLiteTest←⎕NEW #.DataExtraction(DSN'StorageNS')
     Select'first_name' 'surname'From'Users'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←SQLiteTest.root≡'#.StorageNS'
 r,←StorageNS.Users.first_name≡'Zack' 'Robert'
 r,←StorageNS.Users.surname≡'Batik' 'Sobukwe'
     
      ⍝ Clean Up
 ⎕EX'StorageNS'
∇

∇ r←Test005;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 :With SQLiteTest←⎕NEW #.DataExtraction(DSN'StorageNS')
     Select'first_name' 'surname'From'Users'
     StoreTableAs'overloadtablename'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←SQLiteTest.root≡'#.StorageNS'
 r,←StorageNS.overloadtablename.first_name≡'Zack' 'Robert'
 r,←StorageNS.overloadtablename.surname≡'Batik' 'Sobukwe'
     
      ⍝ Clean Up
 ⎕EX'StorageNS'
∇

∇ r←Test006;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 :With SQLiteTest←⎕NEW #.DataExtraction(DSN'StorageNS')
     Select'first_name' 'surname'From'Users'
     StoreTableAs'overloadtablename'
     StoreFieldsAs,¨'f' 's'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←SQLiteTest.root≡'#.StorageNS'
 r,←StorageNS.overloadtablename.f≡'Zack' 'Robert'
 r,←StorageNS.overloadtablename.s≡'Batik' 'Sobukwe'
     
      ⍝ Clean Up
 ⎕EX'StorageNS'
∇

∇ r←Test007;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 :With SQLiteTest←⎕NEW #.DataExtraction(DSN'StorageNS')
     Select'first_name' 'surname'From'Users'
     Where'first_name'Equals'Zack'
     StoreTableAs'overloadtablename'
     StoreFieldsAs'fn' 'sn'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←SQLiteTest.root≡'#.StorageNS'
 r,←StorageNS.overloadtablename.fn≡,⊂'Zack'
 r,←StorageNS.overloadtablename.sn≡,⊂'Batik'
     
      ⍝ Clean Up
 ⎕EX'StorageNS'
∇

∇ r←Test008;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 'MakeNS'⎕NS''
 SQLiteTest←⎕NEW #.DataExtraction(DSN MakeNS) ⍝ Actually send a ns instead of a string
 :With SQLiteTest
     Select'first_name' 'surname'From'Users'
     Where'first_name'Equals'Zack'
     StoreTableAs'overloadtablename'
     StoreFieldsAs'fn' 's'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←SQLiteTest.root≡'#.MakeNS'
 r,←MakeNS.overloadtablename.fn≡,⊂'Zack'
 r,←MakeNS.overloadtablename.s≡,⊂'Batik'
     
      ⍝ Clean Up
 ⎕EX'MakeNS'
∇

∇ r←Test009;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 SQLiteTest←⎕NEW #.DataExtraction(DSN'StorageNS')
 :With SQLiteTest
     Select'first_name' 'surname'From'Users'
     Where'first_name'Equals'Zack'
     And'd_o_b'Equals'1993/07/08'
     StoreFieldsAs'f' 'sn'
     StoreTableAs'OverloadName'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←SQLiteTest.root≡'#.StorageNS'
 r,←StorageNS.OverloadName.f≡,⊂'Zack'
 r,←StorageNS.OverloadName.sn≡,⊂'Batik'
     
      ⍝ Clean Up
 ⎕EX'StorageNS'
∇

∇ r←Test010;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 SQLiteTest←⎕NEW #.DataExtraction(DSN'StorageNS')
 :With SQLiteTest
     Select'first_name' 'surname'From'Users'
     Where'd_o_b'Equals'1993/07/08'
     1 StoreTableAs'AsMatrix'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←SQLiteTest.root≡'#.StorageNS'
 r,←StorageNS.AsMatrix≡1 2⍴'Zack' 'Batik'
     
      ⍝ Clean Up
 ⎕EX'StorageNS'
∇

∇ r←Test011;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 :With SQLiteTest←⎕NEW #.DataExtraction(DSN'StorageNS')
     Select'*'From'Users'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←SQLiteTest.root≡'#.StorageNS'
 r,←StorageNS.Users≡2 5⍴45 'Zack' 'Batik' 34.45 1993 23 'Robert' 'Sobukwe' 89.89 1924
     
      ⍝ Clean Up
 ⎕EX'StorageNS'
∇

∇ r←Test012;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 :With SQLiteTest←⎕NEW #.DataExtraction(DSN'StorageNS')
     Select'first_name' 'surname'From'Users'
     Run
     Select'*'From'MappingTable'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←#.SQLiteTest.root≡'#.StorageNS'
 r,←StorageNS.Users.first_name≡'Zack' 'Robert'
 r,←StorageNS.Users.surname≡'Batik' 'Sobukwe'
 r,←StorageNS.MappingTable≡3 2⍴23 'Mad Hatter' 24 'Base Jacker' 45 'Cat Snatcher'
     
      ⍝ Clean Up
 ⎕EX'StorageNS'
∇

∇ r←Test013;SQLiteTest;DSN
     
      ⍝ Load data
 DSN←'DataExtractionTestDB' '' ''
 SQLiteTest←⎕NEW #.DataExtraction(DSN'StorageNS')
 :With SQLiteTest
     Select'first_name' 'surname'From'Users'
     Where'first_name'Equals'Zack'
     And'd_o_b'Equals'1993/07/08'
     StoreFieldsAs'f' 'sn'
     StoreTableAs'OverloadName'
     Run
     Select'customer_number'From'MappingTable'
     StoreTableAs'map1'
     Run
 :EndWith
     
      ⍝ Check answers
 r←⍬
     ⍝ r,←SQLiteTest.root≡'#.StorageNS'
 r,←StorageNS.OverloadName.f≡,⊂'Zack'
 r,←StorageNS.OverloadName.sn≡,⊂'Batik'
 r,←StorageNS.map1.customer_number≡,⊂23 24 45
     
      ⍝ Clean Up
 ⎕EX'StorageNS'
∇

:EndNamespace 
