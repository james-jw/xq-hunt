import module namespace index = 'xq-hunt' at 'src/xq-hunt.xqm';
declare variable $source as xs:string external; 
declare variable $db external; 
declare variable $skip external;
declare variable $page external;
declare variable $sizes external;

let $defaultSkip := '|[.](bmp|resx|cur|png|ico|fig|snk|sln|csproj|tlb)' return
(
  index:directory($source || '\', $db, $skip || $defaultSkip, $page, 
    tokenize($sizes, ',') ! xs:integer(.)
  ),
  db:output('Completed succesfully for page ' || $page || "&#10;")
)
