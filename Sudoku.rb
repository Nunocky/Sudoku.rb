#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

module Sudoku
  class Cell
    attr_accessor :value
    attr_accessor :candidates
    def initialize
      @value = 0
      @candidates = [1,2,3,4,5,6,7,8,9]
    end
  end

  class Solver
    attr_reader :value_changed

    def initialize
      @cell  = Array.new(81)
      @group = Array.new(9+9+9)

      81.times do |n|
        @cell[n] = Cell.new
      end

      # row
      @group[ 0] = [@cell[ 0], @cell[ 1], @cell[ 2], @cell[ 3], @cell[ 4], @cell[ 5], @cell[ 6], @cell[ 7], @cell[ 8]]
      @group[ 1] = [@cell[ 9], @cell[10], @cell[11], @cell[12], @cell[13], @cell[14], @cell[15], @cell[16], @cell[17]]
      @group[ 2] = [@cell[18], @cell[19], @cell[20], @cell[21], @cell[22], @cell[23], @cell[24], @cell[25], @cell[26]]
      @group[ 3] = [@cell[27], @cell[28], @cell[29], @cell[30], @cell[31], @cell[32], @cell[33], @cell[34], @cell[35]]
      @group[ 4] = [@cell[36], @cell[37], @cell[38], @cell[39], @cell[40], @cell[41], @cell[42], @cell[43], @cell[44]]
      @group[ 5] = [@cell[45], @cell[46], @cell[47], @cell[48], @cell[49], @cell[50], @cell[51], @cell[52], @cell[53]]
      @group[ 6] = [@cell[54], @cell[55], @cell[56], @cell[57], @cell[58], @cell[59], @cell[60], @cell[61], @cell[62]]
      @group[ 7] = [@cell[63], @cell[64], @cell[65], @cell[66], @cell[67], @cell[68], @cell[69], @cell[70], @cell[71]]
      @group[ 8] = [@cell[72], @cell[73], @cell[74], @cell[75], @cell[76], @cell[77], @cell[78], @cell[79], @cell[80]]

      # col
      @group[ 9] = [@cell[ 0], @cell[ 9], @cell[18], @cell[27], @cell[36], @cell[45], @cell[54], @cell[63], @cell[72]]
      @group[10] = [@cell[ 1], @cell[10], @cell[19], @cell[28], @cell[37], @cell[46], @cell[55], @cell[64], @cell[73]]
      @group[11] = [@cell[ 2], @cell[11], @cell[20], @cell[29], @cell[38], @cell[47], @cell[56], @cell[65], @cell[74]]
      @group[12] = [@cell[ 3], @cell[12], @cell[21], @cell[30], @cell[39], @cell[48], @cell[57], @cell[66], @cell[75]]
      @group[13] = [@cell[ 4], @cell[13], @cell[22], @cell[31], @cell[40], @cell[49], @cell[58], @cell[67], @cell[76]]
      @group[14] = [@cell[ 5], @cell[14], @cell[23], @cell[32], @cell[41], @cell[50], @cell[59], @cell[68], @cell[77]]
      @group[15] = [@cell[ 6], @cell[15], @cell[24], @cell[33], @cell[42], @cell[51], @cell[60], @cell[69], @cell[78]]
      @group[16] = [@cell[ 7], @cell[16], @cell[25], @cell[34], @cell[43], @cell[52], @cell[61], @cell[70], @cell[79]]
      @group[17] = [@cell[ 8], @cell[17], @cell[26], @cell[35], @cell[44], @cell[53], @cell[62], @cell[71], @cell[80]]

      # 3x3 block
      @group[18] = [@cell[ 0], @cell[ 1], @cell[ 2], @cell[ 9], @cell[10], @cell[11], @cell[18], @cell[19], @cell[20]]
      @group[19] = [@cell[ 3], @cell[ 4], @cell[ 5], @cell[12], @cell[13], @cell[14], @cell[21], @cell[22], @cell[23]]
      @group[20] = [@cell[ 6], @cell[ 7], @cell[ 8], @cell[15], @cell[16], @cell[17], @cell[24], @cell[25], @cell[26]]
      @group[21] = [@cell[27], @cell[28], @cell[29], @cell[36], @cell[37], @cell[38], @cell[45], @cell[46], @cell[47]]
      @group[22] = [@cell[30], @cell[31], @cell[32], @cell[39], @cell[40], @cell[41], @cell[48], @cell[49], @cell[50]]
      @group[23] = [@cell[33], @cell[34], @cell[35], @cell[42], @cell[43], @cell[44], @cell[51], @cell[52], @cell[53]]
      @group[24] = [@cell[54], @cell[55], @cell[56], @cell[63], @cell[64], @cell[65], @cell[72], @cell[73], @cell[74]]
      @group[25] = [@cell[57], @cell[58], @cell[59], @cell[66], @cell[67], @cell[68], @cell[75], @cell[76], @cell[77]]
      @group[26] = [@cell[60], @cell[61], @cell[62], @cell[69], @cell[70], @cell[71], @cell[78], @cell[79], @cell[80]]
    end

    def load(filename)
      File.open(filename, "r") do |f|
        y=0
        while line = f.gets
          x=0
          line.each_char do |c|
            cell = @cell[y*9+x]
            if c != '.'
              cell.value = c.to_i
              cell.candidates = []
            end
            x += 1
          end
          y += 1
        end
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

      n = 0
      @group.each do |g|
        puts n
        g.each do |cell|
          print "  #{cell.candidates}\n"
        end
        n += 1
      end



    end

    def solved?
      @cell.each do |c|
        return FALSE if c.value == 0
      end
      TRUE
    end

    def exec_step
      value_changed = false

      @group.each do |g|
        scan_group(g)
      end
    end

    def scan_group(base_group)

      # 基本フィルタ。候補が一つだけのセルは確定
      base_group.each do |c|
        next if c.candidates.count == 0

        candidates = [1,2,3,4,5,6,7,8,9]
        find_groups(c).each do |g|
          g.each do |cell|
            next if cell.value == 0
            candidates.delete(cell.value)
          end
        end

        c.candidates = candidates

        if candidates.count == 1
          # 確定
          c.value = candidates[0]
          c.candidates = []
          value_changed = TRUE
        end
      end

      # コンビネーション2のふるい
#      filter_combination2(group)
      # 候補1のセルを確定とする
    end

    # base_cellが所属しているグループの配列を返す
    def find_groups(base_cell)
      groups = []
      @group.each do |g|
        if g.include? base_cell
          groups << g
        end
      end
      groups
    end

    def filter_combination2(base_group)
    end

  end
end




if __FILE__ == $0
  # ファイルを直接実行した時のコードをここに
  solver = Sudoku::Solver.new

  solver.load("ex1.sudoku")

  while TRUE
    puts "----"
    solver.show
    solver.exec_step
    break unless solver.value_changed
  end

  puts "----\n done"
  solver.show

end
