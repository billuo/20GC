use std::fmt::Display;
use std::fmt::Write;
use std::str::FromStr;

pub(crate) trait Position {
    const WIDTH: usize = 7;
    const HEIGHT: usize = 6;
    // NOTE: all columns below are 0-based

    /// Whether a column is playable, i.e. not yet full.
    fn can_play(&self, col: usize) -> bool;
    /// Play at a column, assuming it's playable.
    fn play(&mut self, col: usize);
    /// Whether the current player wins by playing at the given column, assuming it's playable.
    fn is_winning_move(&self, col: usize) -> bool;
    /// Number of moves played since the beginning of the game.
    fn n_moves(&self) -> usize;
    /// Transposition table key
    fn key(&self) -> u64;
}

#[derive(Default, Clone, Copy)]
pub(crate) struct ArrayPosition {
    pieces: [[i8; 6]; 7],
    n: usize,
}
impl Position for ArrayPosition {
    fn can_play(&self, col: usize) -> bool {
        self.pieces[col][5] == 0
    }

    fn play(&mut self, col: usize) {
        let cur = if self.n.is_multiple_of(2) { 1 } else { 2 };
        for x in &mut self.pieces[col] {
            if *x == 0 {
                *x = cur;
                self.n += 1;
                return;
            }
        }
    }

    fn is_winning_move(&self, col: usize) -> bool {
        let cur = if self.n.is_multiple_of(2) { 1 } else { 2 };
        let x = col;
        let y = {
            let mut y = 0usize;
            for i in 0..6 {
                if self.pieces[x][i] == 0 {
                    y = i;
                    break;
                }
            }
            y
        };

        if y >= 3
            && self.pieces[x][y - 1] == cur
            && self.pieces[x][y - 2] == cur
            && self.pieces[x][y - 3] == cur
        {
            return true;
        }

        {
            let mut l = 0;
            for i in 1..4 {
                if x >= i && self.pieces[x - i][y] == cur {
                    l += 1;
                } else {
                    break;
                }
            }
            let mut r = 0;
            for i in 1..4 {
                if x + i < 7 && self.pieces[x + i][y] == cur {
                    r += 1;
                } else {
                    break;
                }
            }
            if l + r >= 3 {
                return true;
            }
        }
        {
            let mut tl = 0;
            for i in 1..4 {
                if x >= i && y + i < 6 && self.pieces[x - i][y + i] == cur {
                    tl += 1;
                } else {
                    break;
                }
            }
            let mut br = 0;
            for i in 1..4 {
                if x + i < 7 && y >= i && self.pieces[x + i][y - i] == cur {
                    br += 1;
                } else {
                    break;
                }
            }
            if tl + br >= 3 {
                return true;
            }
        }
        {
            let mut bl = 0;
            for i in 1..4 {
                if x >= i && y >= i && self.pieces[x - i][y - i] == cur {
                    bl += 1;
                } else {
                    break;
                }
            }
            let mut tr = 0;
            for i in 1..4 {
                if x + i < 7 && y + i < 6 && self.pieces[x + i][y + i] == cur {
                    tr += 1;
                } else {
                    break;
                }
            }
            if bl + tr >= 3 {
                return true;
            }
        }
        false
    }

    fn n_moves(&self) -> usize {
        self.n
    }

    fn key(&self) -> u64 {
        unimplemented!()
    }
}
impl Display for ArrayPosition {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        for y in (0..6).rev() {
            for x in 0..7 {
                let p = self.pieces[x][y];
                let c = match p {
                    0 => ' ',
                    1 => '1',
                    2 => '2',
                    _ => unreachable!(),
                };
                f.write_char(c)?;
            }
            f.write_char('\n')?;
        }
        Ok(())
    }
}
impl FromStr for ArrayPosition {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut ret = Self::default();
        for c in s.chars() {
            let d = c.to_digit(10).ok_or_else(|| "invalid digit".to_string())? as usize;
            if !ret.can_play(d) {
                return Err("invalid play".to_string());
            }
            ret.play(d);
        }
        Ok(ret)
    }
}
impl ArrayPosition {
    pub(crate) fn to_bit_position(self) -> BitPosition {
        let cur = if self.n.is_multiple_of(2) { 1 } else { 2 };
        let mut position = 0i64;
        let mut mask = 0i64;
        for x in 0..7 {
            for y in 0..6 {
                let p = self.pieces[x][y];
                if p != 0 {
                    mask |= 1 << (y + x * 7);
                    if p == cur {
                        position |= 1 << (y + x * 7);
                    }
                }
            }
        }
        let moves = self.n;
        BitPosition {
            position,
            mask,
            moves,
        }
    }
}

/*
 *
 * .  .  .  .  .  .  .
 * 5 12 19 26 33 40 47
 * 4 11 18 25 32 39 46
 * 3 10 17 24 31 38 45
 * 2  9 16 23 30 37 44
 * 1  8 15 22 29 36 43
 * 0  7 14 21 28 35 42
 */
#[derive(Default, Clone, Copy)]
pub(crate) struct BitPosition {
    position: i64,
    mask: i64,
    moves: usize,
}
impl BitPosition {
    // const BOTTOM: i64 = 0b_0000001_0000001_0000001_0000001_0000001_0000001_0000001;
    fn top_mask(col: usize) -> i64 {
        1 << (col * 7 + 5)
    }
    fn bottom_mask(col: usize) -> i64 {
        1 << (col * 7)
    }
    fn column_mask(col: usize) -> i64 {
        0b111111 << (col * 7)
    }
    fn has_wins(pos: i64) -> bool {
        let m = pos & (pos >> 7);
        if m & (m >> 14) != 0 {
            return true;
        }
        let m = pos & (pos >> 6);
        if m & (m >> 12) != 0 {
            return true;
        }
        let m = pos & (pos >> 8);
        if m & (m >> 16) != 0 {
            return true;
        }
        let m = pos & (pos >> 1);
        if m & (m >> 2) != 0 {
            return true;
        }
        false
    }
}
impl Position for BitPosition {
    fn can_play(&self, col: usize) -> bool {
        self.mask & Self::top_mask(col) == 0
    }

    fn play(&mut self, col: usize) {
        self.position ^= self.mask;
        self.mask |= self.mask + Self::bottom_mask(col);
        self.moves += 1;
    }

    fn is_winning_move(&self, col: usize) -> bool {
        let mut p = self.position;
        p |= (self.mask + Self::bottom_mask(col)) & Self::column_mask(col);
        Self::has_wins(p)
    }

    fn n_moves(&self) -> usize {
        self.moves
    }

    fn key(&self) -> u64 {
        (self.position + self.mask) as u64
    }
}
