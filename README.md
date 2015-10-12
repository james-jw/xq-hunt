# xq-hunt
Library for indexing directories of documents for quick windowed searching. Targets <a href="http://basex.org/">BaseX</a>

<h3>Usage</h3>

1) Ensure you have basex installed and in your path <br />
2) Clone this repository to your machine <br />
3) If on windows: Run the wizard.bat, follow the prompt, to index a directory <br />
4) If non windows: <br />
4a) Create a database to store the directory index in 
  <code>db:create('demo-hunt')</code> <br />
4b) Call xq-hunt:directory to index a directory. The following call will index the first 1000 files (page 0) of the "c:\demo"  folder into the 'demo-hunt' database using a trigram size of 3, skipping all file paths matching the regex '[.]svn' <br />
  <code>xq-hunt:directory(c:\demo', 'demo-hunt', '[.]svn', 0, 3)</code>  <br /> 

If recursively more than 1000 files are containined within the folder to be indexed, additional calls will need to be made with incrememnting page indexes. See the wizard.bat for an example of how this is accomplished easily.  <br />

5) Now optimize the database: <code>db:optimize('demo-hunt')</code>  <br />
6) Index the trigrams themselves:  <br />
<pre>
import module namespace xq-hunt = 'xq-hunt' at 'src/xq-hunt.xqm';
xq-hunt:database('demo-hunt')</pre> <br />
7) Now optimize the database one more time: <code>db:optimize('demo-hunt')</code>  <br />

8) Complete! Your directory is now indexed and ready to search!

<h3>Searching</h3>

The 'xq-hunt' module includes one method with two overloads to utilize the newly created index. The method is <code>hunt</code>
For example, to search for all files that likely contain the phrase 'Hunting is fun!' you could simply call

<pre>import module namespace xq-hunt = 'xq-hunt' at 'src/xq-hunt.xqm'; 
xq:hunt('demo-hunt', 'Hunting is fun!', 3)
</pre>

The above query would return all the index nodes matching the trigram vector of the input phrase.This does not gurrantee the phrase is in the file, only that it likley could be. <br />

Last but not least, xq-hunt allows for windowed searches. Simply add the window size as an additional paramter.
<code>xq:hunt('demo-hunt', 'Hunting is fun!', 3, 10)</code> <br />

The above query would return a window of size 10 for each instance of the complete phrase.



     
     
      


