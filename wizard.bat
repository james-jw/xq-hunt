:: This batch wizard will index a directory recusively into trigrams for rapid file searching

@echo off
setlocal enableextensions enabledelayedexpansion
set /a "x = 1"
set /p source="Enter the source directory to hunt: "
set /p db="Enter the database name to create the index in: "
set /p skip="Enter the skip expression: "
set /p pages="Enter how many pages it will take: "
set /p sizes="Enter trigram sizes, seperated by commas: "
cls
start /b /wait basex -q "(db:create('%db%'), db:output('Created Hunt database %db% succesfully!'))"
:while1
if %x% leq %pages% (
    start /b /wait basex -bsource=%source% -bdb="%db%" -bskip=%skip% -bpage=%x% -bsizes="%sizes%" hunt-directory.xq
    
    set /a "x = x + 1"
    goto :while1
)

start /b /wait basex -q "(db:optimize('%db%'))"
echo Hunting Trigrams
start /b /wait basex -q "import module namespace index = 'hunt' at 'src/xq-hunt.xqm'; hunt:database('%db%')"
start /b /wait basex -bdb="%db%" index-hunt-database.xq
start /b /wait basex -q "(db:optimize('%db%'))"
echo Hunting %source% into database %db% Complete!
endlocal
