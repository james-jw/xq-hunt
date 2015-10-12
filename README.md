# xq-hunt
Library for indexing directories of documents for quick windowed searching. Targets <a href="http://basex.org/">BaseX</a>

<h2>How it works</h2>
Hunt is a simple module. It creates a trigram index for each text file found in the directory. When an index is created a trigram size can be selected. For clarification, a trigram is <code>any group of consecutive written units such as letters, syllables or words.</code>. 

Different trigram lengths are useful for different data sets. The examples here us a trigram length of size 3; however, any positive length is valid including multiple lengths: (3, 7).

When a document is indexed, its contents are broken up into individual trigrams of the length provided and stored in a database document. 

When a search is performed, the same process is applied to the input text, resulting in a set of trigrams. These trigrams are then searched against the database indexes, matching any index which contains all of them. The result of this search is merely the index itself which contains the file path and a full set of trigrams found withing the file. 

The file path returned from the index can be used to search line by line for the queried pattern. (Its important to note that when searching, the trigram length must be specified and match that of available indexes on the database being searched.)

<h3>Use Cases</h3>
Useful for provding quick searches accross code base directories, data sets, apis or other data files
Coupled with RESTXQ, allows for powerful service configurations

<h2>Usage</h2>
<h3>Indexing</h3>

The below steps outline how to index a directory for future searching: <br />

1) Ensure you have basex installed and in your path <br />
2) Clone this repository to your machine <br />
3) If on windows: Run the wizard.bat, follow the prompt, to index a directory <br />
4) If non windows: <br />
4a) Create a database to store the directory index in 
  <code>db:create('demo-hunt')</code> <br />
4b) Call xq-hunt:directory to index a directory. The following call will index the first 1000 files (page 0) of the "c:\demo"  folder into the 'demo-hunt' database using a trigram size of 3, skipping all file paths matching the regex '[.]svn' <br />
  <code>xq-hunt:directory(c:\demo', 'demo-hunt', '[.]svn', 0, 3)</code>  <br /> 

If recursively more than 1000 files are containined within the folder to be indexed, additional calls will need to be made with incrememnting page indexes. See the wizard.bat for an example of how this is accomplished easily.  <br />

4c) Now optimize the database: <code>db:optimize('demo-hunt')</code>  <br />
4d) Index the trigrams themselves:  <br />
<pre>
import module namespace xq-hunt = 'xq-hunt' at 'src/xq-hunt.xqm';
xq-hunt:database('demo-hunt')</pre> <br />
4e) Now optimize the database one more time: <code>db:optimize('demo-hunt')</code>  <br />

5) Complete! Your directory is now indexed and ready to search!

<h3>Searching</h3>

The 'xq-hunt' module includes two methods with overloads to utilize the newly created index. The methods are <code>hunt-file</code> and <code>hunt-db</code>

For example, to search for all files that likely contain the phrase 'Hunting is fun!' in your entire directory (recursively) you could simply call

<pre>import module namespace xq-hunt = 'xq-hunt' at 'src/xq-hunt.xqm'; 
xq-hunt:hunt-db('demo-hunt', 'Hunting is fun!', 3)
</pre>

The above query would return all the index nodes matching the trigram vector of the input phrase.This does not gurrantee the phrase is in the file referenced by the index, only that it likley could be. <br />

To return the actual lines containing the phrase. Call <code>hunt-file</code> pasing in the index provided from hunt-db call above, plus the phrase itself and lastly a windows size of 1. <br />

For example to return all lines from any index returned by hunt-db you could simply use the xquery map operator <code>!</code>: <br />
<code>xq-hunt:hunt-db('demo-hunt', $phrase, 3) ! xq-hunt:hunt-file(., $phrase, 1)</code> <br />

Fortunately, the <code>hunt-db</code> method has an overload which does this for you. Simply add the window size as the last paramter to <code>hunt-db</code> in order to return windowed results. The following query would return a set of windows of size 10 for each match in the directory. <br />

<code>xq-hunt:hunt-db('demo-hunt', 'Hunting is fun!', 3, 10)</code> <br />

Happy hunting!




     
     
      


