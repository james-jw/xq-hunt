# xq-hunt
XQuery Library for indexing and providing sub second windowed searching accross millions of lines of text. <br />
Targets <a href="http://basex.org/">BaseX</a>

<h3>Dependencies</h3>
<pre>
git@github.com:james-jw/xq-tika
</pre>

<h6>Installing Dependencies</h6>
Clone this repository and all dependencies into the same folder

<h3>How it works </h3>
Hunt uses trigram indexes to query accross millions of lines of text. Trigrams indexes can be of various sizes as specified during their creation and against different sets of text. A trigram is any <code>group of consecutive written letters.</code>. 

Different trigram lengths are useful for different data sets. The examples shown here use a trigram length of size 3; however, any positive length is valid including multiple lengths: (3, 7).

When a document is indexed, its contents are broken up into individual trigrams of the length provided and each unique trigram found is stored in the documents index.

After all documents have been indexed, a second process indexes the trigrams themselves, deteremining their relevancy. The formula is simply the total number of indexed documents divided by the number of documents the trigram occurs in. For example a relevancy of .5 would represent a trigram that is found in 50% of the documents indexed and thus is NOT very useful. The lower the number the more useful the trigram is. 

When a search is performed, the same process is applied to the input search text. The resulting trigrams are then ordered by relevancy and the top 4 relevant trigrams are matched against the document trigrams stored during the indexing process, matching any file index which contains them all. 

The file path returned from the index is then used to search line by line for the queried pattern. (Its important to note that when searching, the trigram length must be specified and match that of available indexes on the database being searched. For example, if you index using trigrams of size 4, you must also search with trigrams of size 4.)

<h3>Use Cases</h3>
Useful for provding quick searches accross code base directories, data sets, apis or other data files.

<h3>Performance</h3>
On a standard desktop (core i5 | 6700,, 8 gigs of ram)
Searching 18,000 files with 3.5 million combined lines of text

Windowed search times: 200 - 1100 ms <br />
Averaging under 500ms
 
<h3>Usage</h3>
<h3>Indexing</h3>

The below steps outline how to index a directory for future searching: <br />
Note Memory: The indexing process can be quite memory intensive. The basex.bat file, found in the Basex\bin directory can be edited to increase the memory allocated. <br />

1) Ensure you have basex installed and in your path <br />
2) Clone this repository to your machine <br />
3) If on windows: Run the wizard.bat, follow the prompt, to index a directory <br />
4) If non windows: <br />
4a) Create a database to store the directory index in 
  <code>db:create('demo-hunt')</code> <br />
4b) Call xq-hunt:directory to index a directory. The following call will index the first 1000 files (page 0) of the "c:\demo"  folder into the 'demo-hunt' database using a trigram size of 3, skipping all file paths matching the regex '[.]svn' <br />
  <code>xq-hunt:directory(c:\demo', 'demo-hunt', '[.]svn', 0, 3)</code>  <br /> 

If recursively more than 1000 files are containined within the folder to be indexed, additional calls will need to be made with incrementing page indexes. See the wizard.bat for an example of how this is accomplished easily.  <br />

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
<pre>let $indexes := xq-hunt:hunt-db('demo-hunt', $phrase, 3)
  for $index in $indexes return
    xq-hunt:hunt-file($index, $phrase, 1)</pre> <br />

Fortunately, the <code>hunt-db</code> method has an overload which does this for you. Simply add the window size as the last paramter to <code>hunt-db</code> in order to return windowed results. The following query would return a set of windows of size 10 for each match in the directory. <br />

<code>xq-hunt:hunt-db('demo-hunt', 'Hunting is fun!', 3, 10)</code> <br />

Happy hunting!




     
     
      


