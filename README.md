# Levenshtein
A collection of algorithms in Ruby for calculating the Levenshtein distance and the Damerau–Levenshtein distance respectively between two input texts.

## Algorithms/Functions
All algorithms take two parameters:
* string *_a*: first text
* string *_b*: second text

The algorithms meassure, how many and which operations are necessary to transform *_a* into *_b*.

All algorithms return a hash with:
* :dist     Levenshtein distance
* :script   array of operations used to transform *_a* to *_b*
* :time     running time in seconds

### Recursive
The simple recursive algorithm, which is really slow with strings with more than 8 characters.
The implementation follows Wikibooks: http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#Ruby
```ruby
Levenshtein.recursive(_a, _b)
```

### Wagner-Fischer
Simple implementation of Wagner-Fischer algorithm based on the complete distance matrix.
Adopted from http://en.wikipedia.org/wiki/Wagner%E2%80%93Fischer_edit_distance#Calculating_distance
```ruby
Levenshtein.wagner_fischer(_a, _b)
```

### Wagner-Fischer advanced
Advanced implementation of Wagner-Fischer algorithm for Levenshtein distance with reduced use of memory: O(mn) → O(m)
by just saving the current and the last column instead of the whole matrix.
This produces a little overhead, but it's faster than wagner_fischer for longer texts.
```ruby
Levenshtein.wagner_fischer_advanced(_a, _b)
```

### Allison
Allisons improved implementation of Wagner-Fischer algorithm for Levenshtein distance
with reduced running time: O(mn) → O(m * (1 + Levenshtein distance)), see **L. Allison** *Lazy Dynamic-Programming can be Eager* (1992).
This implementation in Ruby is based on the Java-version of Allisons algorithm, created by **Xuan Luo**, see http://www.ocf.berkeley.edu/~xuanluo/
Allisons algorithm is always as fast as Wagner-Fischer, usual faster. Long texts might lead to *SystemStackError: stack level too deep*.
```ruby
Levenshtein.allison(_a, _b)
```

### Damerau
Calculates the Damerau–Levenshtein distance, see http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
i.e. the Levenshtein distance with the additional operation: transposition of two adjacent characters.
* the algorithm extends the advanced implementation of Wagner-Fischers algorithm
* the costs can be customized by parameter *_costs*, e.g. {:copy => 0, :add => 2, :del => 2, :sub => 2, :trans => 0}
```ruby
Levenshtein.damerau(_a, _b, _costs = nil)
```

### Run all algorithms
Run all algorithms and show distance, running time and edit-script
* hide the edit-script by setting the parameter *_script* to false
```ruby
Levenshtein.every(_a, _b, _script = true)
```