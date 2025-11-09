use std::hint::unreachable_unchecked;

use crate::position::Position;

struct Bound(u8);
impl Bound {
    fn new_upper(v: i32) -> Self {
        let v = ((v as i8) << 1) as u8;
        Self(v)
    }
    fn new_lower(v: i32) -> Self {
        let v = ((v as i8) << 1) as u8;
        Self(v | 1)
    }
    fn value(&self) -> i32 {
        ((self.0 as i8) >> 1) as i32
    }
    fn is_lower(&self) -> bool {
        self.0 & 1 == 1
    }
    fn is_upper(&self) -> bool {
        self.0 & 1 == 0
    }
}

#[derive(Default)]
pub struct Solver {
    table: crate::lookup::MRUTable<u64, u32, u8>,
    book: crate::lookup::OpeningBook,
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

        let bound = self.table.get(position.key()).map(Bound);
        let (min, max) = match bound {
            None => (
                -((position.remaining_moves() - 2) as i32) / 2,
                (position.remaining_moves() - 1) as i32 / 2,
            ),
            Some(b) if b.is_lower() => (b.value(), (position.remaining_moves() - 1) as i32 / 2),
            Some(b) if b.is_upper() => (-((position.remaining_moves() - 2) as i32) / 2, b.value()),
            // safety: is_lower() || is_upper() === true
            _ => unsafe { unreachable_unchecked() },
        };
        if alpha < min {
            alpha = min;
            if alpha >= beta {
                return alpha;
            }
        }
        if beta > max {
            beta = max;
            if alpha >= beta {
                return beta;
            }
        }

        if let Some(score) = self.book.get(position) {
            return score;
        }

        let sort_moves = position.n_moves() <= Position::AREA / 3;
        let mut moves = crate::position::SortedMoves::default();
        for col in [3, 2, 4, 1, 5, 0, 6] {
            let move_bit = possible_non_losing_moves & Position::column_mask(col);
            if move_bit != 0 {
                if sort_moves {
                    moves.insert_sorted(col, position.score_move(move_bit));
                } else {
                    moves.insert(col);
                }
            }
        }
        for col in moves.iter() {
            let score = -self.negamax(&position.played(col), -beta, -alpha);
            if score >= beta {
                self.table.put(position.key(), Bound::new_lower(score).0);
                return score;
            }
            if score > alpha {
                alpha = score;
            }
        }

        self.table.put(position.key(), Bound::new_upper(alpha).0);
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

    pub fn analyze(&mut self, position: &Position, weak: bool) -> [Option<i32>; Position::WIDTH] {
        let mut scores = [None; Position::WIDTH];
        for col in 0..Position::WIDTH {
            if position.can_play(col) {
                let score = if position.is_winning_move(col) {
                    (position.remaining_moves() + 1) as i32 / 2
                } else {
                    self.solve(&position.played(col), weak)
                };
                scores[col] = Some(score);
            }
        }
        scores
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
        eprint!("{code} ");
        let answer = solver.solve(&p, false);
        let reference = negamax_reference(&p, -100, 100);
        eprintln!("{answer} {reference}");
        assert_eq!(answer, reference);
    }

    #[test]
    fn random_endgame() {
        use rand::prelude::*;
        let rng = &mut rand::rng();
        let mut solver = Solver::default();
        let mut all_moves = all_moves();
        for _ in 0..100 {
            all_moves.shuffle(rng);
            let min = Position::AREA / 3 * 2;
            let max = Position::AREA;
            let range = min..max;
            let moves = &all_moves[0..rng.random_range(range)];
            test_correctness(&mut solver, moves);
        }
    }

    #[test]
    #[ignore = "slow"]
    fn random_midgame() {
        use rand::prelude::*;
        let rng = &mut rand::rng();
        let mut solver = Solver::default();
        let mut all_moves = all_moves();
        for _ in 0..10 {
            all_moves.shuffle(rng);
            let min = Position::AREA / 3;
            let max = Position::AREA / 3 * 2;
            let range = min..max;
            let moves = &all_moves[0..rng.random_range(range)];
            test_correctness(&mut solver, moves);
        }
    }

    #[test]
    #[ignore = "slow"]
    fn random_earlygame() {
        use rand::prelude::*;
        let rng = &mut rand::rng();
        let mut solver = Solver::default();
        let mut all_moves = all_moves();
        for _ in 0..1 {
            all_moves.shuffle(rng);
            let min = Position::AREA / 6;
            let max = Position::AREA / 3;
            let range = min..max;
            let moves = &all_moves[0..rng.random_range(range)];
            let mut p = Position::default();
            let code = moves
                .iter()
                .copied()
                .map(|c| char::from_digit(c as u32, 10).unwrap())
                .collect::<String>();
            p.apply_moves(moves.iter().copied());
            eprint!("{code} ");
            let answer = solver.solve(&p, false);
            eprintln!("{answer}");
        }
    }

    fn test_against_data(data: &str) {
        let mut solver = Solver::default();
        for line in data.lines() {
            let (moves, score) = line.split_once(' ').unwrap();
            let score = score.parse::<i32>().unwrap();
            let mut p = Position::default();
            p.apply_str(moves);
            let solved_score = solver.solve(&p, false);
            eprintln!("{moves}");
            assert_eq!(score, solved_score);
        }
    }

    #[test]
    fn data_l1r1() {
        test_against_data(include_str!("Test_L1_R1"));
    }
    #[test]
    #[ignore = "slow"]
    fn data_l1r2() {
        test_against_data(include_str!("Test_L1_R2"));
    }
    #[test]
    #[ignore = "slow"]
    fn data_l1r3() {
        test_against_data(include_str!("Test_L1_R3"));
    }
    #[test]
    fn data_l2r1() {
        test_against_data(include_str!("Test_L2_R1"));
    }
    #[test]
    #[ignore = "slow"]
    fn data_l2r2() {
        test_against_data(include_str!("Test_L2_R2"));
    }
    #[test]
    fn data_l3r1() {
        test_against_data(include_str!("Test_L3_R1"));
    }

    #[test]
    #[ignore = "not a test"]
    fn data_strip() {
        let s = include_str!("Test_L1_R2");
        for line in s.lines() {
            let moves = line.split_once(' ').unwrap().0;
            eprintln!("{moves}");
        }
    }
}
