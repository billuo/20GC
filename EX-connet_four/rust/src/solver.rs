use crate::position::Position;

#[derive(Default)]
pub(crate) struct Solver {
    tt: crate::transposition::TranspositionTable,
}

impl Solver {
    fn negamax(&mut self, position: &Position, mut alpha: i32, mut beta: i32) -> i32 {
        let possible_non_losing_moves = position.possible_non_losing_moves();
        if possible_non_losing_moves == 0 {
            return -((Position::WIDTH * Position::HEIGHT - position.n_moves()) as i32) / 2;
        }
        if position.n_moves() >= Position::WIDTH * Position::HEIGHT - 2 {
            return 0;
        }
        let min = -((Position::WIDTH * Position::HEIGHT - 2 - position.n_moves()) as i32) / 2;
        if alpha < min {
            alpha = min;
            if alpha >= beta {
                return alpha;
            }
        }
        let max = if let Some(v) = self.tt.get(position.key()) {
            v as i32
        } else {
            (Position::WIDTH * Position::HEIGHT - 1 - position.n_moves()) as i32 / 2
        };
        if beta > max {
            beta = max;
            if alpha >= beta {
                return beta;
            }
        }
        for x in [3, 2, 4, 1, 5, 0, 6] {
            if possible_non_losing_moves & Position::column_mask(x) != 0 {
                let mut new_position = *position;
                new_position.play(x);
                let score = -self.negamax(&new_position, -beta, -alpha);
                if score >= beta {
                    return score;
                }
                if score > alpha {
                    alpha = score;
                }
            }
        }
        self.tt.put(position.key(), alpha as i8);
        alpha
    }
    pub(crate) fn solve(&mut self, position: &Position, weak: bool) -> i32 {
        if position.can_win_next() {
            return (Position::WIDTH * Position::HEIGHT + 1 - position.n_moves()) as i32 / 2;
        }
        let (mut min, mut max) = if weak {
            (-1, 1)
        } else {
            let n = (Position::WIDTH * Position::HEIGHT - position.n_moves()) as i32;
            (-n / 2, (n + 1) / 2)
        };
        while min < max {
            let mut m = min + (max - min) / 2;
            if m <= 0 && m > min / 2 {
                m = min / 2;
            } else if m >= 0 && m < max / 2 {
                m = max / 2
            };
            let score = self.negamax(position, m, m + 1);
            if score <= m {
                max = score;
            } else {
                min = score;
            }
        }
        min
    }
}

#[cfg(test)]
mod test {
    use super::*;
    #[test]
    fn solve() {
        let mut solver = Solver::default();
        let mut test_case = |code: &str| {
            let mut p = Position::default();
            p.apply_str(code);
            eprintln!("{code} solve={}", solver.solve(&p, false));
        };
        for i in 0..24 {
            test_case(&"01234560123456012345610325406214365"[0..35 - i]);
        }
    }
}
