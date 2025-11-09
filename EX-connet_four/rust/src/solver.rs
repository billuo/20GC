use crate::position::Position;

#[derive(Default)]
pub struct Solver {
    tt: crate::transposition::TranspositionTable,
}

impl Solver {
    fn negamax(&mut self, position: &Position, mut alpha: i32, mut beta: i32) -> i32 {
        let possible_non_losing_moves = position.possible_non_losing_moves();
        if possible_non_losing_moves == 0 {
            return -(position.remaining_moves() as i32) / 2;
        }
        if position.remaining_moves() <= 2 {
            return 0;
        }
        let min = -((position.remaining_moves() - 2) as i32) / 2;
        if alpha < min {
            alpha = min;
            if alpha >= beta {
                return alpha;
            }
        }
        let max = if let Some(v) = self.tt.get(position.key()) {
            v as i32
        } else {
            (position.remaining_moves() - 1) as i32 / 2
        };
        if beta > max {
            beta = max;
            if alpha >= beta {
                return beta;
            }
        }
        let mut moves = crate::position::SortedMoves::default();
        for col in [3, 2, 4, 1, 5, 0, 6] {
            let move_bit = possible_non_losing_moves & Position::column_mask(col);
            if move_bit != 0 {
                moves.insert(col, position.score_move(move_bit));
            }
        }
        for col in moves.iter() {
            let mut new_position = *position;
            new_position.play(col);
            let score = -self.negamax(&new_position, -beta, -alpha);
            if score >= beta {
                return score;
            }
            if score > alpha {
                alpha = score;
            }
        }
        self.tt.put(position.key(), alpha as i8);
        alpha
    }
    pub fn solve(&mut self, position: &Position, weak: bool) -> i32 {
        if position.can_win_next() {
            return (position.remaining_moves() + 1) as i32 / 2;
        }
        let (mut min, mut max) = if weak {
            (-1, 1)
        } else {
            let n = position.remaining_moves() as i32;
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

    fn negamax_reference(position: &Position, mut alpha: i32, mut beta: i32) -> i32 {
        if position.remaining_moves() == 0 {
            return 0;
        }
        if position.can_win_next() {
            return (position.remaining_moves() + 1) as i32 / 2;
        }
        let max = (position.remaining_moves() - 1) as i32 / 2;
        if beta > max {
            beta = max;
            if alpha >= beta {
                return beta;
            }
        }
        for col in [3, 2, 4, 1, 5, 0, 6] {
            if position.can_play(col) {
                let mut new_position = *position;
                new_position.play(col);
                let score = -negamax_reference(&new_position, -beta, -alpha);
                if score >= beta {
                    return score;
                }
                if score > alpha {
                    alpha = score;
                }
            }
        }
        alpha
    }

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

    fn all_moves() -> Vec<usize> {
        let mut v = vec![];
        for x in 0..Position::WIDTH {
            for _ in 0..Position::HEIGHT {
                v.push(x)
            }
        }
        v
    }

    fn test_correctness(solver: &mut Solver, moves: &[usize]) {
        let mut p = Position::default();
        let code = moves
            .iter()
            .copied()
            .map(|c| char::from_digit(c as u32, 10).unwrap())
            .collect::<String>();
        p.apply_moves(moves.iter().copied());
        let answer = solver.solve(&p, false);
        let reference = negamax_reference(&p, -100, 100);
        eprintln!("{code} {answer} {reference}");
        assert_eq!(answer, reference);
    }

    #[test]
    fn correctness_endgame() {
        use rand::prelude::*;
        let rng = &mut rand::rng();
        let mut solver = Solver::default();
        let mut all_moves = all_moves();
        for _ in 0..1000 {
            all_moves.shuffle(rng);
            let min = Position::AREA / 3 * 2;
            let max = Position::AREA;
            let range = min..max;
            let moves = &all_moves[0..rng.random_range(range)];
            test_correctness(&mut solver, moves);
        }
    }

    #[test]
    fn correctness_midgame() {
        use rand::prelude::*;
        let rng = &mut rand::rng();
        let mut solver = Solver::default();
        let mut all_moves = all_moves();
        for _ in 0..1000 {
            all_moves.shuffle(rng);
            let min = Position::AREA / 3;
            let max = Position::AREA / 3 * 2;
            let range = min..max;
            let moves = &all_moves[0..rng.random_range(range)];
            test_correctness(&mut solver, moves);
        }
    }
}
