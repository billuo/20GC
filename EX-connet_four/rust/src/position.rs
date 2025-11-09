#[derive(Default, Clone, Copy)]
pub struct Position {
    position: i64,
    mask: i64,
    moves: usize,
}
impl Position {
    pub const WIDTH: usize = 7;
    pub const HEIGHT: usize = 6;
    pub const AREA: usize = Self::WIDTH * Self::HEIGHT;

    /* bits layout:
     * .  .  .  .  .  .  .
     * 5 12 19 26 33 40 47
     * 4 11 18 25 32 39 46
     * 3 10 17 24 31 38 45
     * 2  9 16 23 30 37 44
     * 1  8 15 22 29 36 43
     * 0  7 14 21 28 35 42
     */

    const BOTTOM_MASK: i64 = Self::bottom_mask(0)
        | Self::bottom_mask(1)
        | Self::bottom_mask(2)
        | Self::bottom_mask(3)
        | Self::bottom_mask(4)
        | Self::bottom_mask(5)
        | Self::bottom_mask(6);
    const BOARD_MASK: i64 = Self::column_mask(0)
        | Self::column_mask(1)
        | Self::column_mask(2)
        | Self::column_mask(3)
        | Self::column_mask(4)
        | Self::column_mask(5)
        | Self::column_mask(6);
    const fn top_mask(col: usize) -> i64 {
        1 << (col * 7 + 5)
    }
    const fn bottom_mask(col: usize) -> i64 {
        1 << (col * 7)
    }
    pub const fn column_mask(col: usize) -> i64 {
        0b111111 << (col * 7)
    }

    // const fn has_wins(pos: i64) -> bool {
    //     let m = pos & (pos >> 7);
    //     if m & (m >> 14) != 0 {
    //         return true;
    //     }
    //     let m = pos & (pos >> 6);
    //     if m & (m >> 12) != 0 {
    //         return true;
    //     }
    //     let m = pos & (pos >> 8);
    //     if m & (m >> 16) != 0 {
    //         return true;
    //     }
    //     let m = pos & (pos >> 1);
    //     if m & (m >> 2) != 0 {
    //         return true;
    //     }
    //     false
    // }

    fn find_winning_moves(pos: i64, mask: i64) -> i64 {
        let h = Self::HEIGHT;

        // vertical;
        let mut r = (pos << 1) & (pos << 2) & (pos << 3);

        //horizontal
        let mut p = (pos << (h + 1)) & (pos << (2 * (h + 1)));
        r |= p & (pos << (3 * (h + 1)));
        r |= p & (pos >> (h + 1));
        p = (pos >> (h + 1)) & (pos >> (2 * (h + 1)));
        r |= p & (pos << (h + 1));
        r |= p & (pos >> (3 * (h + 1)));

        //diagonal 1
        p = (pos << h) & (pos << (2 * h));
        r |= p & (pos << (3 * h));
        r |= p & (pos >> h);
        p = (pos >> h) & (pos >> (2 * h));
        r |= p & (pos << h);
        r |= p & (pos >> (3 * h));

        //diagonal 2
        p = (pos << (h + 2)) & (pos << (2 * (h + 2)));
        r |= p & (pos << (3 * (h + 2)));
        r |= p & (pos >> (h + 2));
        p = (pos >> (h + 2)) & (pos >> (2 * (h + 2)));
        r |= p & (pos << (h + 2));
        r |= p & (pos >> (3 * (h + 2)));

        r & (Self::BOARD_MASK ^ mask)
    }

    pub fn score_move(&self, move_bit: i64) -> i32 {
        let winning_moves = Self::find_winning_moves(self.position | move_bit, self.mask);
        if true {
            winning_moves.count_ones() as i32
        } else {
            let mut x = winning_moves;
            let mut n = 0;
            while x != 0 {
                x &= x - 1;
                n += 1;
            }
            n
        }
    }

    pub fn can_play(&self, col: usize) -> bool {
        self.mask & Self::top_mask(col) == 0
    }

    pub fn play(&mut self, col: usize) {
        self.position ^= self.mask;
        self.mask |= self.mask + Self::bottom_mask(col);
        self.moves += 1;
    }

    pub fn is_winning_move(&self, col: usize) -> bool {
        self.winning_moves() & self.possible_moves() & Self::column_mask(col) != 0
    }

    pub fn n_moves(&self) -> usize {
        self.moves
    }
    pub fn remaining_moves(&self) -> usize {
        Self::AREA - self.n_moves()
    }

    pub fn key(&self) -> u64 {
        (self.position + self.mask) as u64
    }

    pub fn possible_moves(&self) -> i64 {
        (self.mask + Self::BOTTOM_MASK) & Self::BOARD_MASK
    }
    pub fn possible_non_losing_moves(&self) -> i64 {
        let mut possible_moves = self.possible_moves();
        let opponent_winning_moves = self.opponent_winning_moves();
        let forced_moves = possible_moves & opponent_winning_moves;
        if forced_moves != 0 {
            if forced_moves & (forced_moves - 1) != 0 {
                // more than one forced moves, will always lose
                return 0;
            }
            possible_moves = forced_moves;
        }
        possible_moves & !(opponent_winning_moves >> 1)
    }
    pub fn winning_moves(&self) -> i64 {
        Self::find_winning_moves(self.position, self.mask)
    }
    pub fn opponent_winning_moves(&self) -> i64 {
        Self::find_winning_moves(self.position ^ self.mask, self.mask)
    }
    pub fn can_win_next(&self) -> bool {
        self.winning_moves() & self.possible_moves() != 0
    }

    pub fn apply_str(&mut self, s: &str) {
        for c in s.chars() {
            let col = c.to_digit(10).expect("valid digit") as usize;
            assert!(self.can_play(col));
            self.play(col);
        }
    }
    pub fn apply_moves(&mut self, it: impl IntoIterator<Item = usize>) {
        for col in it {
            self.play(col)
        }
    }
}

#[derive(Default)]
pub struct SortedMoves {
    records: [(usize, i32); Position::WIDTH],
    n: usize,
}
impl SortedMoves {
    pub fn insert(&mut self, col: usize, score: i32) {
        let mut pos = self.n;
        self.n += 1;
        while pos > 0 && self.records[pos].1 > score {
            self.records[pos] = self.records[pos - 1];
            pos -= 1;
        }
        self.records[pos] = (col, score);
    }
    pub fn iter(&self) -> impl Iterator<Item = usize> {
        self.records[0..self.n].iter().map(|r| r.0)
    }
}
