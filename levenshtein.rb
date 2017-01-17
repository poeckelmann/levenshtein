#!/usr/bin/ruby
# encoding: utf-8

#####
# collection of algorithms for calculating the edit-distance, i.e.:
# - Levenshtein distance
# - Damerau–Levenshtein distance
# author: Marcus Pöckelmann
#####

module Levenshtein
  #---------------------------------------------------------------------------------------------------------------------
  # Overview
  #   all algorithms take two parameters:
  #     string _a: first text
  #     string _b: second text
  #   → _a will be transformed to _b
  #
  #   algorithms/functions:
	#     Levenshtein.recursive					         → simple recursive algorithm - really slow with strings > 8 characters
	#     Levenshtein.wagner_fischer      		   → simple implementation of Wagner Fischer algorithm based on the complete distance matrix
	#     Levenshtein.wagner_fischer_advanced	   → wagner_fischer with reduced need for memory
	#     Levenshtein.allison					           → Allisons improvement of Wagner Fischer algorithm:
  #                                             - always as fast as Wagner Fischer, usual faster
  #                                             - long texts might lead to SystemStackError: stack level too deep
  #     Levenshtein.damerau                    → calculates the Damerau–Levenshtein distance (i.e. transpositions allowed)
  #                                             - additional parameter _costs for costumizing the costs
	#     Levenshtein.every                      → run all algorithms and show distance, running time and edit-script
  #                                             - additional parameter _script to hide the edit-script
  #
	#   all algorithms return a hash with:
	#     :dist     Levenshtein distance
	#     :script   array of operations used to get from _a to _b
  #     :time     running time in seconds

  #---------------------------------------------------------------------------------------------------------------------
	# Levenshtein distance via simple recursive algorithm
	# !extremly slow
	# implementation follows Wikibooks: http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#Ruby
	def self.recursive(_a, _b)
		time = Time.now
		dist = recursion(_a, _b)

    # distance, edit-script, running time
		return {:dist => dist, :script => '-', :time => (Time.now - time)}
	end
	#
	def self.recursion(_a, _b)
		case
			when _a.empty? then _b.length
			when _b.empty? then _a.length
      else [
          (_a[0] == _b[0] ? 0 : 1) + recursion(_a[1..-1], _b[1..-1]),
					1 + recursion(_a[1..-1], _b),
					1 + recursion(_a, _b[1..-1])
      ].min
		end
	end
	private_class_method :recursion

  #---------------------------------------------------------------------------------------------------------------------
	# simple implementation of Wagner-Fischer Algorithm
	# adopted from http://en.wikipedia.org/wiki/Wagner%E2%80%93Fischer_edit_distance#Calculating_distance
  def self.wagner_fischer(_a, _b)
    time = Time.now
    n = _a.length
    m = _b.length
    array = Array.new(n + 1) { Array.new(m + 1) { 0 }}
    script = Array.new(n + 1) { Array.new(m + 1) { [] }}

    # initialize first row and column (comparision with an empty string)
    1.upto(n) do |i|
      array[i][0] = i
      script[i][0] = script[i-1][0].clone << [:del, i-1, _a[i-1], 0, _b[0]]
    end
    1.upto(m) do |j|
      array[0][j] = j
      script[0][j] = script[0][j-1].clone << [:add, 0, _a[0], j-1, _b[j-1]]
    end

    # main loop where the distance-matrix and the edit-script is build
    1.upto(m) do |j|
      1.upto(n) do |i|
        if _a[i-1] == _b[j-1] # copy
          array[i][j] = array[i-1][j-1]
          script[i][j] = script[i-1][j-1].clone << [:copy, i-1, _a[i-1], j-1, _b[j-1]]
        else
          # possible operations with their costs
          cases = [array[i-1][j] + 1, array[i][j-1] + 1, array[i-1][j-1] + 1]
          case cases.min
            when cases[0] then		# delete
              array[i][j] = cases[0]
              script[i][j] = script[i-1][j].clone <<  [:del, i-1, _a[i-1], j-1, _b[j-1]]
            when cases[1] then		# insert
              array[i][j] = cases[1]
              script[i][j] = script[i][j-1].clone <<  [:add, i-1, _a[i-1], j-1, _b[j-1]]
            when cases[2] then		# substitute
              array[i][j] = cases[2]
              script[i][j] = script[i-1][j-1].clone <<  [:sub, i-1, _a[i-1], j-1, _b[j-1]]
          end
        end
      end
    end

    # distance, edit-script, running time
    return {:dist => array[n][m], :script => script[n][m], :time => (Time.now - time)}
  end

  #---------------------------------------------------------------------------------------------------------------------
	# advanced implementation of Wagner-Fischer algorithm for Levenshtein distance,
	# reduced use of memory: O(mn) → O(m)
	#	by just saving the current and the last column instead of the whole matrix
	#	has a little overhead, but is faster than wagner_fischer for longer text
	def self.wagner_fischer_advanced(_a, _b)
		time = Time.now
		n = _a.length
		m = _b.length
		array = Array.new(n + 1) { Array.new(2) { 0 }}
		script = Array.new(n + 1) { Array.new(2) { [] }}

		# initialize first column (comparision with an empty string)
    1.upto(n) do |i|
      array[i][1] = i
      script[i][1] = script[i-1][1].clone << [:del, i-1, _a[i-1], 0, _b[0]]
    end

		# main loop where the distance-matrix with the editScript is build completely
    1.upto(m) do |j|
			# save the results of the last step
			0.upto(n) do |i|
				array[i][0] = array[i][1]
				script[i][0] = script[i][1]
			end
			# generate first row (comparision with an empty string)
			array[0][1] = j
      script[0][1] = script[0][0].clone << [:add, 0, _a[0], j-1, _b[j-1]]

      1.upto(n) do |i|
				if _a[i-1] == _b[j-1]
					array[i][1] = array[i-1][0]	# copy
          script[i][1] = script[i-1][0].clone << [:copy, i-1, _a[i-1], j-1, _b[j-1]]
				else
					# posible operations with their costs
					cases = [array[i-1][1] + 1, array[i][0] + 1, array[i-1][0] + 1]
					case cases.min
						when cases[0]	then # delete
								array[i][1] = cases[0]
                script[i][1] = script[i-1][1].clone <<  [:del, i-1, _a[i-1], j-1, _b[j-1]]
						when cases[1]	then		# insert
								array[i][1] = cases[1]
                script[i][1] = script[i][0].clone <<  [:add, i-1, _a[i-1], j-1, _b[j-1]]
						when cases[2] then		# substitute
								array[i][1] = cases[2]
                script[i][1] = script[i-1][0].clone <<  [:sub, i-1, _a[i-1], j-1, _b[j-1]]
					end
				end
			end
		end

		# distance, edit-script, running time
		return {:dist => array[n][1], :script => script[n][1], :time => (Time.now - time)}
  end

  #---------------------------------------------------------------------------------------------------------------------
	# Allisons advanced implementation of Wagner-Fischers algorithm for Levenshtein distance,
	# reduced running time: O(mn) → O(m * (1 + Levenshtein distance))		see L. Allison Lazy Dynamic-Programming can be Eager. 1992
	# 	Java-version of Allisons algorithm was created by Xuan Luo http://www.ocf.berkeley.edu/~xuanluo/
	#		the following implementation in Ruby is based on that Java-version
	def self.allison(_a, _b)
		time = Time.now
		# diagonal from the top-left element
		main_diag = Diagonal.new(_a, _b, nil, 0)

		# which is the diagonal containing the bottom R.H. elt?
		lba = _b.length - _a.length

		if lba >= 0
			diag = main_diag
			i = 0
			lba.times do
				diag = diag.get_above
				i += 1
			end
		else
	 		diag = main_diag.get_below
      i = 0
			(~lba).times do
				diag = diag.get_above
				i += 1
			end
		end

		dist = diag.get([_a.length, _b.length].min)

		#--------------------------
		# compute alignment by backtracking through structure
		alignment = Array.new
		i = [_a.length, _b.length].min

		# adds operations in reverse order
		op = diag.get_op(i)
		while op[0] != :start		# != Start
			case op[0]
				when :start then	# Start
				when :add then	# Insert
						alignment << [:add, op[1], op[2], op[3], op[4]]
						if diag.offset == 0
							diag = diag.prev
							i -= 1
						elsif diag.offset >= 0
							diag = diag.prev
						else
							diag = diag.next
							i -= 1
						end
				when :del then	# Delete
						alignment << [:del, op[1], op[2], op[3], op[4]]
						if diag.offset == 0
							diag = diag.next
							i -= 1
						elsif diag.offset >= 0
							diag = diag.next
							i -= 1
						else
							diag = diag.prev
						end
				when :copy then	# Match
						alignment << [:copy, op[1], op[2], op[3], op[4]]
						i -= 1
				when :sub then	# Change
						alignment << [:sub, op[1], op[2], op[3], op[4]]
						i -= 1
				else
					Rails.logger.error "Lvensthein: unknown operation: #{op[0]}"
					i -= 1
			end
			op = diag.get_op(i)
		end

		# distance, editScript, running time
		return {:dist => dist, :script => alignment.reverse, :time => (Time.now - time)}
	end
  #
	# class for diagonals within the matrix used by Wagner-Fischers algorithm
	class Diagonal
		# diagonal starts at a[0], b[abs(offset)]
		# lower half has negative offset
		attr_accessor	:offset
		@a 				# left string
		@b				# top string
		attr_accessor	:prev		# below-left diagonal
		attr_accessor	:next		# above-right diagonal
		@elements			# list of elements
	
		def initialize(_a, _b, _prev, _o)
			# assert Math.abs(o) <= _b.length;
			#if !(_o.abs <= _b.length)
			#	puts("Warning: Initialize.assert")
			#end
			@offset = _o		
			@a = _a
			@b = _b
			@prev = _prev
			@next = nil
			@elements = [@offset.abs]		
		end

		# returns below diagonal, creating it if necessary
		def get_below
			if(@prev == nil)
				# assert offset == 0;
				#if !(@offset == 0)
				#	puts("Warning: getBelow.assert")
				#end
				# lower half has a, b switched, so see themselves
				# as the upper half of the transpose
				@prev = Diagonal.new(@b, @a, self, -1)
			end
			return @prev
		end

		# returns above diagonal, creating it if necessary
		def get_above
			if(@next == nil)
				o = @offset + 1;
				if(@offset < 0)
					o = @offset - 1
				end
				@next = Diagonal.new(@a, @b, self, o)
			end
			return @next
		end

		# get entry to the left
		def get_w(_i)
			# assert i >= 0 && (offset != 0 || i > 0);
			#if !(i >= 0 && (@offset != 0 || i > 0))
			#	puts("Warning: getW.assert")
			#end
			# if this is main diagonal, then left diagonal is 1 shorter
			o = _i-1
			if @offset != 0
				o = _i
			end
			return get_below.get(o)
		end

		# get entry above
		def get_n(_i)
			# assert i > 0;
			#if !(i > 0)
			#	puts("Warning: getN.assert")
			#end
			# above diagonal is 1 shorter
		    	return get_above.get(_i-1)
		end
	
		# compute element j of this diagonal
		def get(_j)
			# assert j >= 0 && j <= b.length-Math.abs(offset) && j <= a.length;
			#if !(j >= 0 && j <= @b.length-@offset.abs && j <= @a.length)
			#	puts("Warning: get.assert")
			#end
			if _j < @elements.length
				return @elements[_j]
			end

			me = @elements[-1]

			while @elements.length <= _j
				nw = me
				i = @elements.length

				# \   \   \
				#  \   \   \
				#   \  nw   n
				#    \   \
				#      w   me
				# according to dynamic programming algorithm,
				# if characters are equal, me = nw
				# otherwise, me = 1 + min3 (w, nw, n)
				if @a[i - 1] == @b[@offset.abs + i - 1]
					me = nw
				else
					# see L. Allison, Lazy Dynamic-Programming can be Eager
					#     Inf. Proc. Letters 43(4) pp207-212, Sept' 1992
					# computes min3 (w, nw, n)
					# but does not always evaluate n
					# this makes it O(|a|*D(a,b))
					w = get_w(i)
						
					if w < nw
						# if w < nw, then w <= n
						me = 1 + w
					else
						n = get_n(i)
						me = 1 + [nw, n].min
					end
				end
				# me = 1 + [w, nw, n].min would make it O(|a|*|b|)
				@elements << me
			end
			return me
		end

		# get the last operation used to get to a certain element
		def get_op(_i)
			pos_a = _i-1
			pos_b = @offset.abs + _i - 1
			if _i == 0
				if @offset == 0
					return [:start, pos_a, @a[pos_a], pos_b, @b[pos_b]]		# Operation: Start
				elsif offset > 0
					#return [:add, pos_a, @a[pos_a], pos_b, @b[pos_b]]		
					return [:add, 0, @a[0], pos_b, @b[pos_b]]			# Operation: Insert
				else
					return [:del,  pos_b, @b[pos_b], pos_a+1, @a[pos_a+1]]	# Operation: Delete (REVERSE)
				end
			elsif @a[pos_a] == @b[pos_b]
				if @offset >= 0
					return [:copy, pos_a, @a[pos_a], pos_b, @b[pos_b]]		# Operation: Match (Copy)
				else
					return [:copy, pos_b, @b[pos_b], pos_a, @a[pos_a]]		# Operation: Match (Copy) (REVERSE)
				end
			else
				me = get(_i)
				w = get_w(_i)
				nw = get(_i-1)
				if me == 1 + w
					# Below-Left-Diagonal was used
					if @offset >= 0
						return [:add,  pos_a, @a[pos_a], pos_b, @b[pos_b]]	# Operation: Insert
					else
						#return [:del, i, @offset.abs + i]
						return [:del,  pos_b, @b[pos_b], pos_a, @a[pos_a]]	# Operation: Delete (REVERSE)
					end
				elsif me == 1 + nw
					# Main-Diagonal was used
					if @offset >= 0
						return [:sub, pos_a, @a[pos_a], pos_b, @b[pos_b]]		# Operation: Change (Substitution)
					else
						return [:sub, pos_b, @b[pos_b], pos_a, @a[pos_a]]		# Operation: Change (Substitution) (REVERSE)
					end
				else
					# Upper-Right-Diagonal was used
					if @offset >= 0
						return [:del, pos_a, @a[pos_a], pos_b, @b[pos_b]]	# Operation: Delete
					else
						return [:add,  pos_b, @b[pos_b], pos_a, @a[pos_a]]	# Operation: Insert (REVERSE)
					end
				end
			end
		end
  end

  #---------------------------------------------------------------------------------------------------------------------
	# for calculating the Damerau–Levenshtein distance, see http://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
	#	i.e. the Levenshtein distance with the additional operation: transposition of two adjacent characters
	# the algorithm extends the advanced implementation of Wagner-Fischers algorithm
  # the costs can be customized by parameter _costs, e.g. {:copy => 0, :add => 2, :del => 2, :sub => 2, :trans => 0}
	def self.damerau(_a, _b, _costs = nil)
		algo = Damerau.new(_costs)
	
		return algo.compute(_a, _b)
  end
  #
	class Damerau
    attr_accessor :costs
	
		@array
		@script
		@n
		@m
		@a
		@b

		def initialize(_costs = nil)
      # default costs
      @costs = {:copy => 0, :add => 1, :del => 1, :sub => 1, :trans => 1}
      # custom costs
      if _costs.is_a?(Hash)
        [:copy, :add, :del, :sub, :trans].each do |op|
          @costs[op] = _costs[op] if _costs.has_key?(op)
        end
      end
		end
	
		def compute(_a, _b)
			time = Time.now
			@a = _a
			@b = _b
			@n = @a.length
			@m = @b.length
			@array = Array.new(@n + 1) { Array.new(3) { 0 }}
			@script = Array.new(@n + 1) { Array.new(3) { []}}

			# initialize first column (comparision with an empty string)
      1.upto(@n) do |i|
        @array[i][2] = i * @costs[:del]
        @script[i][2] = @script[i-1][2].clone << [:del, i-1, @a[i-1], 0, @b[0]]
      end

			# main loop where the distance-matrix with the editScript is build completely
			j = 1
				shift(j)
				i = 1
				@n.times do
					add_del_sub(i, j)
					if @a[i-1] == @b[j-1]
						if @array[i-1][1] + @costs[:copy] < @array[i][2]
							@array[i][2] = @array[i-1][1] + @costs[:copy]
              @script[i][2] = @script[i-1][1].clone << [:copy, i-1, @a[i-1], j-1, @b[j-1]]
						end
					end
					i += 1
				end
			j = 2
			(@m-1).times do
				shift(j)
				i = 1
				@n.times do
					add_del_sub(i, j)
					if @a[i-1] == @b[j-1]
						if @array[i-1][1] + @costs[:copy] < @array[i][2]
							@array[i][2] = @array[i-1][1] + @costs[:copy]
              @script[i][2] = @script[i-1][1].clone << [:copy, i-1, @a[i-1], j-1, @b[j-1]]
						end
					end
					if @a[i-1] == @b[j-2] && @a[i-2] == @b[j-1]
						if @array[i-2][0] + @costs[:trans] < @array[i][2]
							#puts("\t\t yeah")
							@array[i][2] = @array[i-2][0] + @costs[:trans]
              @script[i][2] = @script[i-2][0].clone << [:trans, i-2, "(#{@a[i-2]}#{@a[i-1]})", j-2, "(#{@b[j-2]}#{@b[j-1]})"]
						end
					end
					i += 1
				end
				j += 1
			end

			# distance, editScript, running time
			return {:dist => @array[@n][2], :script => @script[@n][2], :time => (Time.now - time)}
		end

		def shift(j)
			# save the results of the last step
			i = 0
			(@n+1).times do
				@array[i][0] = @array[i][1]
				@array[i][1] = @array[i][2]
				@script[i][0] = @script[i][1]
				@script[i][1] = @script[i][2]
				i += 1
			end
			# generate first row (comparision with an empty string)
			@array[0][2] = j * @costs[:add]
      @script[0][2] = @script[0][1].clone << [:add, 0, @a[0], j-1, @b[j-1]]
		end

		def add_del_sub(i, j)
			# posible operations with their costs
			cases = [@array[i-1][2] + @costs[:del], @array[i][1] + @costs[:add], @array[i-1][1] + @costs[:sub]]
			case cases.min
				when cases[0]	then	# delete
						@array[i][2] = cases[0]
            @script[i][2] = @script[i-1][2].clone << [:del, i-1, @a[i-1], j-1, @b[j-1]]
				when cases[1] then		# insert
						@array[i][2] = cases[1]
            @script[i][2] = @script[i][1].clone << [:add, i-1, @a[i-1], j-1, @b[j-1]]
				when cases[2] then		# substitute
						@array[i][2] = cases[2]
            @script[i][2] = @script[i-1][1].clone << [:sub, i-1, @a[i-1], j-1, @b[j-1]]
			end
		end
  end

  #---------------------------------------------------------------------------------------------------------------------
  # run all algorithms and show distance, running time and edit-script
  # hide the edit-script by setting the parameter _script to false
	def self.every(_a, _b, _script = true)
    [
        {:name => 'Recursiv'}.merge((_a.length + _b.length < 16) ? recursive(_a, _b) : {}),
        {:name => 'Wagner-Fischer'}.merge(wagner_fischer(_a, _b)),
        {:name => 'Wagner-Fischer advanced'}.merge(wagner_fischer_advanced(_a, _b)),
        {:name => 'Allison'}.merge(allison(_a, _b)),
        {:name => 'Damerau'}.merge(damerau(_a, _b)),
    ].each do |result|
      puts "#{result[:name]}:"
      if result.keys.length == 4
        puts "\t\t#{result[:dist]}\t#{result[:time]}s\t#{_script ? result[:script] : '-'}"
      else
        puts "\t\tstrings to long algorithm"
      end
    end
    return true
  end
end
