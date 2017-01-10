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
```ruby
Levenshtein.recursive(_a, _b)
```

### Wagner-Fischer
Simple implementation of Wagner-Fischer algorithm based on the complete distance matrix.
```ruby
Levenshtein.wagner_fischer(_a, _b)
```

### Wagner-Fischer advanced
Like wagner_fischer but with reduced need for memory.
```ruby
Levenshtein.wagner_fischer_advanced(_a, _b)
```

### Allison
Allisons improvement of the Wagner-Fischer algorithm:
* always as fast as Wagner-Fischer, usual faster
* long texts might lead to *SystemStackError: stack level too deep*
```ruby
Levenshtein.allison(_a, _b)
```

### Damerau
Calculates the Damerau–Levenshtein distance (i.e. transpositions allowed)
* additional parameter *_costs* for costumizing the costs
```ruby
Levenshtein.damerau(_a, _b, _costs = nil)
```

### Run all algorithms
Run all algorithms and show distance, running time and edit-script
* additional parameter *_script* to hide the edit-script
```ruby
Levenshtein.every(_a, _b, _script = true)
```