START ;
  WRITE "Hello World 2!",!
  QUIT
  ;
LOOP ;
  NEW I
  ;
  FOR I=1:1:10 DO
  . WRITE I,!
  ;
  QUIT
  ;
SHOWDATA ;
  NEW IDX SET IDX=0
  FOR  SET IDX=$ORDER(^DIC(19,IDX)) QUIT:+IDX'>0  DO
  . NEW ZN SET ZN=$GET(^DIC(19,IDX,0))
  . WRITE ZN,!
  QUIT