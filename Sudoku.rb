#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pp'
require 'Logger'


module Sudoku
  class Group < Array
    attr_reader :id
    def initialize(id, *args)
      @id = id
      args.each do |el|
        self << el
      end
    end
  end

  class Cell
    attr_reader   :x, :y
    attr_accessor :value
    attr_accessor :groups
    attr_accessor :candidates
    def initialize(x, y)
      @x = x
      @y = y
      @value = 0
      @groups = []
      @candidates = [1,2,3,4,5,6,7,8,9]
    end
  end

  class Solver
    attr_reader :value_changed

    def initialize
      @logger = Logger.new(STDOUT)

      @cell  = []
      @group = []

      9.times do |y|
        9.times do |x|
          @cell << Cell.new(x, y)
        end
      end

      27.times do |n|
        @group << Group.new(n)
      end

      81.times do |n|
        # row
        @group[n/9]     << @cell[n]
        # col
        @group[9 + n%9] << @cell[n]
      end

      # 3x3 block
      @group[18].push(@cell[ 0], @cell[ 1], @cell[ 2], @cell[ 9], @cell[10], @cell[11], @cell[18], @cell[19], @cell[20])
      @group[19].push(@cell[ 3], @cell[ 4], @cell[ 5], @cell[12], @cell[13], @cell[14], @cell[21], @cell[22], @cell[23])
      @group[20].push(@cell[ 6], @cell[ 7], @cell[ 8], @cell[15], @cell[16], @cell[17], @cell[24], @cell[25], @cell[26])
      @group[21].push(@cell[27], @cell[28], @cell[29], @cell[36], @cell[37], @cell[38], @cell[45], @cell[46], @cell[47])
      @group[22].push(@cell[30], @cell[31], @cell[32], @cell[39], @cell[40], @cell[41], @cell[48], @cell[49], @cell[50])
      @group[23].push(@cell[33], @cell[34], @cell[35], @cell[42], @cell[43], @cell[44], @cell[51], @cell[52], @cell[53])
      @group[24].push(@cell[54], @cell[55], @cell[56], @cell[63], @cell[64], @cell[65], @cell[72], @cell[73], @cell[74])
      @group[25].push(@cell[57], @cell[58], @cell[59], @cell[66], @cell[67], @cell[68], @cell[75], @cell[76], @cell[77])
      @group[26].push(@cell[60], @cell[61], @cell[62], @cell[69], @cell[70], @cell[71], @cell[78], @cell[79], @cell[80])

# pp @group
      @cell.each do |c|
        c.groups = find_groups(c)
      end

      #  debug
#      @group.each do |g|
#        print "#{g.id}: "
#        g.each do |cell|
#          print "(#{cell.x}, #{cell.y}), "
#        end
#        print "\n"
#      end
    end

    # cellが所属しているグループの配列を返す
    def find_groups(cell)
      groups = []
      @group.each do |g|
        if g.include? cell
          groups << g
        end
      end
      groups
    end

    def load(filename)
      File.open(filename, "r") do |f|
        y=0
        while line = f.gets
          line.chomp!
          x=0
          line.each_char do |c|
            cell = @cell[y*9+x]
            if c != '.'
#              puts "#{c}!"
              cell.value      = c.to_i
              cell.candidates = []
            end
            x += 1
          end
          y += 1
        end
      end
    end

    def dump
      n = 0
      @group.each do |g|
        print "group #{n}: "
        g.each do |cell|
          print "#{cell.candidates}, "
        end
        n += 1
        puts ""
      end
    end

    def show
      9.times do |y|
        9.times do |x|
          cell = @cell[y*9+x]
          c = "."
          c = cell.value if cell.value != 0
          print "#{c} "
        end
        puts ""
      end
    end

    def solved?
      @cell.each do |c|
        return FALSE if c.value == 0
      end
      TRUE
    end

    def exec_step
      @value_changed = FALSE

      # 基本フィルタ (確定候補をもとにふるい落とす)
      filter0

      # コンビネーション2のふるい
      @group.each do |g|
        filter_combination2(g)
      end
    end

    # 基本フィルタ。候補が一つだけのセルは確定
    def filter0()
      @cell.each do |cell|
        next if cell.value != 0 # すでに確定しているセルは除外

@logger.debug("cell(#{cell.x}, #{cell.y}), candidates: #{cell.candidates}")

        # cellが所属しているグループの各セルについて、確定していたらそのセルの値を候補から除外
        cell.groups.each do |group|
@logger.debug( " looking group #{group.id}")
          group.each do |c|
            next if c.value == 0
            cell.candidates.delete(c.value)
@logger.debug( "  delete value #{c.value}")
          end
        end

@logger.debug( " updated candidates: #{cell.candidates}")

        # 確定したら更新
        if cell.candidates.count == 1
          cell.value      = cell.candidates[0]
          cell.candidates = []
          @value_changed   = TRUE
@logger.debug( " fixed: #{cell.value}")
        end
      end
    end

    # 同一のn個の候補を持つセル→そのセルがn個ならそれらのセルでその候補値を専有できる。グループ内でその候補値は除外
    def filter_combination2(group)
      pair0 = pair1 = pair2 = nil

      # 最初のセル
      group.each do |cell|
        next if cell.candidates.count != 2
        if pair0 == nil
          pair0 = cell
          next
        end

        if cell.candidates[0] == pair0.candidates[0] && cell.candidates[1] == pair0.candidates[1]
          if pair1 == nil
            pair1 = cell
          else
            pair2 = cell
          end
        end

        if pair2 != nil
          return # 同一候補のセルが3つ以上→対象外
        end

        v0 = pair0.candidates[0]
        v1 = pair0.candidates[1]
        @logger.debug("combination2 found #{v0}, #{v1}")

        group.each do |c|
          next if c == pair0 || c == pair1
          c.candidates.delete(v0)
          c.candidates.delete(v1)
        end

      end
    end

    def filter_last_one(group)
    end


  end
end




if __FILE__ == $0
  # ファイルを直接実行した時のコードをここに
  solver = Sudoku::Solver.new

  solver.load("ex1.sudoku")

  solver.show

  n = 0
  while !solver.solved?
    puts ""
    puts "#{n}"
    puts "--------------------"

    solver.exec_step
    solver.show
    solver.dump
    break if !solver.value_changed
    n += 1
  end

  puts "--------------------\ndone."
  solver.show

end


=begin

combination2の実装

group 2: [], [], [2, 8, 9], [], [], [], [8, 9], [], [8, 9],
group 12: [], [], [], [], [8, 9], [8, 9], [5, 8, 9], [], [],
group 13: [4, 7], [4, 7], [], [3, 4, 6, 8, 9], [1, 2, 4, 6, 8, 9], [2, 3, 6, 8, 9], [8, 9], [6, 9], [8, 9],
group 20: [], [3, 6, 7, 9], [3, 7, 9], [3, 7, 8], [], [], [8, 9], [], [8, 9],
group 22: [], [3, 4, 6, 8, 9], [4, 6], [8, 9], [1, 2, 4, 6, 8, 9], [4, 6], [8, 9], [2, 3, 6, 8, 9], [],
group 25: [5, 8, 9], [8, 9], [], [], [6, 9], [], [], [8, 9], [],

各グループに対して

要素2個のセルを見つける
同じ要素であり、セルが2個なら
その候補はそれらのセルで共有される。他のセルではそれらの候補は除外して良い

cell0 = cell1 = nil

=end
