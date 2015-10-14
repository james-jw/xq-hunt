(: Simple module for indexing a directory of files into a trigram index, targeting BaseX 

   @author James Wright
   @date 10/10/2015   
:)
module namespace index = 'xq-hunt';

declare function index:to-hunt-vector($terms as xs:string*, $sizes as xs:integer*, $skip as xs:string) as xs:string* {
  for $size in $sizes return
    distinct-values(
      for $term in $terms return
          for sliding window $w in fn:string-to-codepoints($term)
          start at $spos when true()
          end $e at $epos when $epos - $spos = $size - 1
          where count($w) = $size
          return lower-case(codepoints-to-string($w))
    )[not(matches(., $skip))]
};

declare function index:to-hunt-vector($terms as xs:string*, $sizes as xs:integer*) {
   index:to-hunt-vector($terms, $sizes, '\s|\W|[|<>=]c|^\d*$')
};

(: Provided a string term, returns a search vector consisting of trigrams :)
declare function index:to-hunt-vector($terms as xs:string*) as xs:string* {
  index:to-hunt-vector($terms, 3)
};

(: Utility function to escape a string for use with a regular expression :)
declare function index:escape-for-regex($terms as xs:string*) as xs:string* {
  for $term in $terms return
    if($term => starts-with('/') and $term => ends-with('/')) then $term
    else $term => replace('([*+?&amp;|\-.\{\}\)\(\$\[\]])', '\\$1')
};

(: Encoding agnostic way to read text-files 
   Supports: UTF, UTF-8, and ISO08859-1 
:)
declare function index:lines-from-file($sourceIn as xs:string) as xs:string* {
    try { file:read-text-lines($sourceIn) } 
    catch * {
       file:read-text-lines($sourceIn, 'ISO-8859-1')
    }
};

(: Adds the provided file index to the database :)
declare updating function index:file($index as node(), $db as xs:string) {
  let $fileName := tokenize($index/@path, '\\')[last()] return
  if(exists(db:open($db, $fileName)/index[@path = $index/@path])) then (
    replace node db:open($db, $fileName)/index[@path = $index/@path] with $index
  ) else (db:add($db, $index, $fileName)) 
};

(: Creates a set an indexes of the source directory in the database provided. 
   @param $skip - regular expression used to skip file paths 
   @param $page - since the operation is intensive, only 1000 recursive files will be process per execution and thus paging is required for any directory containing great than 1000 files recursively.:)
declare updating function index:directory($sourceIn as xs:string, $db as xs:string, $skip as xs:string, $page as xs:integer, $sizes) {
  for $file in (
      for $f in file:list($sourceIn, true())
      where not(matches($sourceIn || $f, $skip)) and not(file:is-dir($sourceIn || $f))
      return $f
  )[position() > ($page * 1000) and position() <= (($page + 1) * 1000)]
  return 
    try {
      let $doc := index:lines-from-file(trace($sourceIn || $file)) return
      let $index := 
         <index path="{$sourceIn || $file}" lines="{count($doc)}">
            {index:to-hunt-vector($doc, $sizes) ! <trigram>{.}</trigram>}
         </index>
      return
        (index:file($index, $db))
    } catch * {
      prof:void(trace('Failed ' || $err:description))
    }
};

(: Indexes the rate of occurance of a trigram in the database for faster processing. :)
declare updating function index:trigram($db, $trigram, $document-count) { 
  let $indexes := db:open($db, 'trigram-index')
  let $count := count($trigram) + 1
  let $new-index := 
  <relevance trigram="{trace($trigram[1])}">
    {if ($trigram[1]/@word) then attribute word {'true'} else ()}
    {$count div $document-count}
  </relevance>
  return
    (
     if(exists($indexes/relevance[@trigram = $trigram[1]])) 
       then (replace node $indexes/relevance[@trigram = $trigram[1]] with $new-index) 
       else (db:add($db, $new-index, 'trigram-index'))
    )
};

(: Indexes the rate of occurance of each trigram in the database for faster processing. :)
declare updating function index:database($dbname) {
  let $db := db:open($dbname)
  let $all-count :=  count(distinct-values($db//index))
  let $trigrams := 
    for $trigram in $db//index/trigram
    group by $value := $trigram[1]
    order by count($trigram) ascending
    return array {$trigram}
  return
    for $trigram in $trigrams return
    index:trigram($dbname, $trigram?*, $all-count)
};

(: Provided a database name and search term returns a set of indexes matching the term
   This requires trigram indexes exist on the database.
:)
declare function index:hunt-db($db as xs:string, $term as xs:string, $size as xs:integer*) as node()* {
  let $search := (
    $term => index:to-hunt-vector($size)
  )
  let $vector := 
   (for $v in db:open($db)/relevance[./@trigram = $search]
      order by $v 
      return $v
   )[position() < 4]/@trigram/data()
   let $trigrams := if(count($vector) gt 0) then $vector else $search
   let $exp := 'db:open("' || $db || '")/index[' || string-join(($trigrams ! ('trigram = "' || . || '"')), ' and ') || ']' 
    return
      xquery:eval($exp)     
};

(: Provided an database index element, term and window size. Returns a set of text windows of the provided size
   containing the term
:)
declare function index:hunt-file($index as node(), $term as xs:string, $window-size as xs:integer) as node()* {
  let $text := index:lines-from-file($index/@path)
  let $lines := for tumbling window $w in $text
       start $s at $spos when lower-case($s) => contains(lower-case($term))
       end at $epos when $epos - $spos = $window-size
       return <window line="{$spos}">{$w ! <line>{.}</line>}</window>
  return
       if(not($lines)) then ()
       else (
         <text path="{$index/@path}" id="{db:node-id($index)}">{
            $lines
         }</text>
       )
};

(: Provided a database name, search term and window size returns a set of textual windows of the size provided
   into the database. This requires index:directory and index:database have been run on the provided database name
   and thus a trigram indexes already exists on the database. 
:)
declare function index:hunt-db($db-name as xs:string, $term as xs:string, $size as xs:integer*, $window-size as xs:integer) as node()* {
  (index:hunt-db($db-name, $term, $size) ! index:hunt-file(., $term, $window-size))[position() = (1 to 5) ]
};

